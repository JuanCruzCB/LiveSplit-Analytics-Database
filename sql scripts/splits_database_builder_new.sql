--#region INITIAL SETUP

/* Importing the entire contents of the original .lss file. */

DROP TABLE IF EXISTS splits_file_runner;
CREATE TABLE splits_file_runner(line_number SERIAL, file_line TEXT);
COPY splits_file_runner(file_line)
FROM 'H:\Juan\4. Speedrunning\LiveSplit\Splits\RE4 Steam\Stats Sheet Google Drive\splits luis.lss'
WITH DELIMITER ','; /* NOTE: The path to the splits file needs to be public, so that Postgres can access it. */

/* Adding the line number to each line of the file. */

DROP TABLE IF EXISTS splits_file_indexed;
CREATE TABLE splits_file_indexed AS
SELECT
    file_line,
    line_number
FROM splits_file_runner
ORDER BY line_number;

/* Adding the line number + 1 to each line of the file. */

DROP TABLE IF EXISTS splits_file_indexed_offset;
CREATE TABLE splits_file_indexed_offset AS
SELECT
    file_line,
    line_number + 1 AS line_number_offset
FROM splits_file_runner
ORDER BY line_number;

--#endregion

--#region SEGMENTS

/* Getting all the data about the Segment History (from the opening tag <Segments> all the way to the closing tag </Segments>). */

DROP TABLE IF EXISTS segments_data1_runner;
CREATE TABLE segments_data1_runner AS
SELECT
    LTRIM(file_line, ' ') AS file_line_stripped
FROM splits_file_indexed
WHERE line_number >
(
    SELECT
        line_number_offset
    FROM splits_file_indexed_offset
    WHERE file_line LIKE '%</AttemptHistory>%'
)
AND line_number <
(
    SELECT
        line_number
    FROM splits_file_indexed
    WHERE file_line LIKE '%<AutoSplitterSettings%'
);

/* Extracting the run id, the split name, the LRT time and the RTA time for the whole segment history of each segment.

For the run ids, we need to find the lines that have the format <Time id="integer">.
For the split names, we need to find the lines that have the format <Name>...</Name>.
For the LRT time, we need to find the lines that have the format <GameTime>...</GameTime>.
For the RTA time, we need to find the lines that have the format <RealTime>...</RealTime>.

We can achieve each one of these cases by using a regular expression. In the first case, ="(.*?)"> which catches everything between =" and "> and in the other cases >(.*?)</ which catches everything between > and </. In that first case, it's very important to end the regex with "> and NOT "/>, since we do not want the Time tags that close their tag immediately, because that means that run id has no LRT nor RTA times associated with it which is a bug that happens when runners delete their splits/golds manually etc. */

DROP TABLE IF EXISTS segments_data2_runner;
CREATE TABLE segments_data2_runner AS
SELECT
    COALESCE(SUBSTRING(file_line_stripped FROM '<Time id="(.*?)">'), '') AS run_id,
    COALESCE(SUBSTRING(file_line_stripped FROM '<Name>(.*?)</Name>'), '') AS split_name,
    COALESCE(SUBSTRING(file_line_stripped FROM '<GameTime>(.*?)</GameTime>'), '') AS lrt_time,
    COALESCE(SUBSTRING(file_line_stripped FROM '<RealTime>(.*?)</RealTime>'), '') AS rta_time,
    file_line_stripped,
    ROW_NUMBER() OVER() AS line_number
FROM segments_data1_runner;


/* Converting the run id to INT. If the row doesn't have a valid run id (it's an empty string) then we force it to 0. This doesn't cause any issues because run ids always start from 1 and never from 0 in the file.

The LRT time of each split name is 2 rows below the row that has the run id of that time. Since we want everything on the same row we use the LEAD function, we want the information from 2 rows below the run id but also 1 row below run id because some rare Time tags that have negative run ids don't have any RTA time and only LRT, so in this edge case we take the next row and not the one after it. */

DROP TABLE IF EXISTS segments_data3_runner;
CREATE TABLE segments_data3_runner AS
SELECT
    run_id,
    CASE
        WHEN run_id = '' THEN
            0
        ELSE
            run_id::INT
    END AS run_id_int,
    split_name,
    lrt_time,
    LEAD(lrt_time) OVER(ORDER BY line_number) AS lrt_time_negative_run_id,
    LEAD(lrt_time, 2) OVER(ORDER BY line_number) AS lrt_time_normal,
    rta_time,
    LEAD(rta_time) OVER(ORDER BY line_number) AS rta_time_normal,
    file_line_stripped,
    line_number
FROM segments_data2_runner;

/* Now putting back the LRT times that are 2 rows below the row we want (or 1 row below if negative run id) in the same row as the other info (run id, etc.) and ignoring the other intermediate unnecessary columns. */

DROP TABLE IF EXISTS segments_data4_runner;
CREATE TABLE segments_data4_runner AS
SELECT
    run_id_int AS run_id,
    split_name,
    CASE
        WHEN run_id_int = 0 THEN
            ''
        WHEN run_id_int < 0 THEN
            lrt_time_negative_run_id
        ELSE
            lrt_time_normal
    END AS lrt_time,
    CASE
        WHEN run_id_int <= 0 THEN
            ''
        ELSE
            rta_time_normal
    END AS rta_time,
    file_line_stripped,
    line_number
FROM segments_data3_runner;

/* Now that we have the run ids and the LRT + RTA times in the same row, we just need to get the split names on this same row too. For this we select the minimum row number for each split_name using the line_number column, which tells us on which row the new split starts. The previous split ends 1 row before that. */

DROP TABLE IF EXISTS split_names_data1_runner;
CREATE TABLE split_names_data1_runner AS
SELECT DISTINCT
    split_name,
    split_name_occurrence,
    MIN(line_number) AS starts_at_row
FROM
(
    SELECT DISTINCT
        split_name,
        ROW_NUMBER() OVER(PARTITION BY split_name) AS split_name_occurrence,
        line_number
    FROM segments_data4_runner
    WHERE split_name <> ''
)
GROUP BY split_name, split_name_occurrence
ORDER BY starts_at_row;

/* Now that we have the min row for each split name, it's easy to get the max, it's just the min of the next split -1. We also create a split_number column which also uses a ROW_NUMBER function but this time only with the 123 rows of the 123 unique splits (and not the whole LiveSplit history rows), this will be useful to create the chapters and sections. */

DROP TABLE IF EXISTS split_names_data2_runner;
CREATE TABLE split_names_data2_runner AS
SELECT
    ROW_NUMBER() OVER() AS split_number,
    split_name,
    starts_at_row,
    LEAD(starts_at_row) OVER(ORDER BY starts_at_row) - 1 AS ends_at_row
FROM split_names_data1_runner;

/* We assign the chapter name and section name to each split based on the index of that split. For example, we know that 1-1 only has 4 splits (1 2 3 4), so if split_number is between 1 and 4, we know it belongs to chapter 1-1. This same logic is applied to assign the section name to each split. Note that this is quite brittle and has to be adjusted on a per-game or even per-category basis, as each game and/or category can have a varying amount of splits per chapter and per section.

Besides being able to identify the chapter name and section name, having the split number as a column is very useful as it allows us to 1) have a unique key to identify each split, regardless of if a split name is duplicated on the splits file or not and 2) convert each split name to default split names through their id, to standardize and simplify the output when exporting the final data. 3) allow each split to have any name (except containing commas) and not specific ones for the script to work properly. */

DROP TABLE IF EXISTS split_names_data3_runner;
CREATE TABLE split_names_data3_runner AS
SELECT
    split_number,
    split_name,
    CASE
        WHEN split_number <= 4 THEN '1-1'
        WHEN split_number <= 7 THEN '1-2'
        WHEN split_number <= 14 THEN '1-3'
        WHEN split_number <= 20 THEN '2-1'
        WHEN split_number <= 26 THEN '2-2'
        WHEN split_number <= 32 THEN '2-3'
        WHEN split_number <= 39 THEN '3-1'
        WHEN split_number <= 45 THEN '3-2'
        WHEN split_number <= 48 THEN '3-3'
        WHEN split_number <= 52 THEN '3-4'
        WHEN split_number <= 70 THEN '4-1'
        WHEN split_number <= 74 THEN '4-2'
        WHEN split_number <= 78 THEN '4-3'
        WHEN split_number <= 82 THEN '4-4'
        WHEN split_number <= 98 THEN '5-1'
        WHEN split_number <= 105 THEN '5-2'
        WHEN split_number <= 112 THEN '5-3'
        WHEN split_number <= 119 THEN '5-4'
        ELSE '6-1'
    END AS chapter,
    CASE
        WHEN split_number <= 32 THEN 'Village'
        WHEN split_number <= 82 THEN 'Castle'
        ELSE 'Island'
    END AS _section,
    starts_at_row,
    ends_at_row
FROM split_names_data2_runner;

/* We join the split names table with the segments data table that has run ids and LRT times on the same row, so now it will have the split, chapter, section names on that same row too, because as explained before, the split name on the original file only shows once at the top and then just lists the entire history of that split name without displaying the split name again, so we need that for each row.

Just like we did for run ids and LRT times, we make the split name empty on the rows we don't want (there are a lot of unnecessary rows in the original file since all the data has 1 info per row, for example split name, LRT time and run id will show on 3 different rows on the original file, but since here we put everything on the same row, we only keep 1 row out of the 3 and the other 2 are useless, so we delete them). */

DROP TABLE IF EXISTS segments_data5_runner;
CREATE TABLE segments_data5_runner AS
SELECT
    run_id,
    split_number,
    CASE
        WHEN lrt_time = '' THEN
            ''
        ELSE
            splits.split_name
    END AS split_name,
    chapter,
    _section,
    lrt_time,
    rta_time,
    file_line_stripped,
    line_number
FROM segments_data4_runner segs

LEFT JOIN split_names_data3_runner splits
ON segs.line_number >= splits.starts_at_row
AND segs.line_number <= CASE
                            WHEN splits.ends_at_row IS NULL THEN
                                10000000
                            ELSE
                                splits.ends_at_row
                        END
ORDER BY line_number;

/* Converting the LRT and RTA times from text to INTERVAL types. At this point we only keep the rows that have useful information and we already have everything on the same row (run id, lrt time and split name) so we can delete the rest. */

DROP TABLE IF EXISTS segments_data6_runner;
CREATE TABLE segments_data6_runner AS
SELECT
    run_id,
    split_number,
    split_name,
    chapter,
    _section,
    lrt_time::INTERVAL,
    CASE
        WHEN rta_time = '' THEN -- Rare but possible negative time ids don't have the RTA time.
            '0'::INTERVAL
        ELSE
            rta_time::INTERVAL
    END AS rta_time,
    file_line_stripped,
    line_number
FROM segments_data5_runner
WHERE split_name <> '';

/* Also adding the LRT and RTA time with the same format as in LiveSplit (Edit Splits window), not used for calculations but it's nicer to read. */

DROP TABLE IF EXISTS segments_data7_runner;
CREATE TABLE segments_data7_runner AS
SELECT
    run_id,
    split_number,
    split_name,
    chapter,
    _section,
    lrt_time,
    LTRIM(TO_CHAR(lrt_time, 'HH24:MI:SS.FF3'), '0:') AS lrt_time_formatted,
    rta_time,
    LTRIM(TO_CHAR(rta_time, 'HH24:MI:SS.FF3'), '0:') AS rta_time_formatted,
    file_line_stripped,
    line_number
FROM segments_data6_runner;

--#endregion

--#region ATTEMPTS

/* Getting all the data about the Attempts History (from the opening tag <AttemptHistory> all the way to the closing tag </AttemptHistory>). */

DROP TABLE IF EXISTS attempts_data1_runner;
CREATE TABLE attempts_data1_runner AS
SELECT
    LTRIM(file_line, ' ') AS file_line_stripped
FROM splits_file_indexed
WHERE line_number >
(
    SELECT
        line_number
    FROM splits_file_indexed
    WHERE file_line LIKE '%<AttemptHistory>%'
)
AND line_number <
(
    SELECT
        line_number
    FROM splits_file_indexed
    WHERE file_line LIKE '%</AttemptHistory>%'
);


/* For each attempt in the Attempt History raw data we obtain:

- The run id.
- The date and time of the start and end of the run.
- Whether the attempt ended up as a finished run or not.
- If the run was finished, its final LRT and RTA time excluding milliseconds. */

DROP TABLE IF EXISTS attempts_data2_runner;
CREATE TABLE attempts_data2_runner AS
SELECT
    COALESCE(SUBSTRING(file_line_stripped FROM 'id="(.*?)" started'), '') AS run_id,
    COALESCE(SUBSTRING(file_line_stripped FROM '<GameTime>(.*?)</GameTime>'), '') AS final_lrt_time,
    COALESCE(SUBSTRING(file_line_stripped FROM '<RealTime>(.*?)</RealTime>'), '') AS final_rta_time,
    file_line_stripped LIKE '%">' AS finished_run,
    SUBSTRING(file_line_stripped FROM 'started="(.*?)"') AS run_started_at,
    SUBSTRING(file_line_stripped FROM 'ended="(.*?)"') AS run_ended_at
FROM attempts_data1_runner;

/* The finished runs will have their LRT time 2 rows after the run id, so need to put everything on the same row as done before for the Segments. Also remove useless rows and remove data from runs that are "too old" (this will be customizable eventually, but also optional). */

DROP TABLE IF EXISTS attempts_data3_runner;
CREATE TABLE attempts_data3_runner AS
SELECT
    run_id,
    LEAD(final_lrt_time, 2) OVER () AS final_lrt_time,
    LEAD(final_rta_time, 1) OVER () AS final_rta_time,
    finished_run,
    TO_TIMESTAMP(run_started_at, 'MM/DD/YYYY HH24:MI:SS') AS run_started_at,
    TO_TIMESTAMP(run_ended_at, 'MM/DD/YYYY HH24:MI:SS') AS run_ended_at
FROM attempts_data2_runner;

/* Remove rows where the run_id isn't present. Also remove rows from runs that are "too old". Convert run_id to INT. */

DROP TABLE IF EXISTS attempts_data4_runner;
CREATE TABLE attempts_data4_runner AS
SELECT
    run_id::INT,
    final_lrt_time,
    final_rta_time,
    finished_run,
    run_started_at,
    run_ended_at,
    run_ended_at - run_started_at AS run_duration
FROM attempts_data3_runner
WHERE run_id IS NOT NULL AND DATE(run_started_at) >= '2024-10-15'; -- TODO: This date needs to be customizable

/* Getting the list of all finished runs and for each finished run, if it was a PB when it was done or not (which also means getting the LRT PB at that time too). */

DROP TABLE IF EXISTS finished_runs_runner;
CREATE TABLE finished_runs_runner AS
SELECT
    run_id,
    run_started_at,
    final_lrt_time,
    MIN(final_lrt_time) OVER(ORDER BY run_id) AS lrt_pb,
    final_lrt_time = MIN(final_lrt_time) OVER(ORDER BY run_id) AS pb
FROM attempts_data4_runner
WHERE finished_run;

/* We now join the attempts history (with dates and run id on the same row) with the finished runs information to have everything in the same table. As earlier, only keeping the good rows and deleting the rest (since we put everything in the same row, a lot of rows are now useless). */

DROP TABLE IF EXISTS attempts_data5_runner;
CREATE TABLE attempts_data5_runner AS
SELECT
    attempts.run_id,
    attempts.final_lrt_time,
    final_rta_time,
    finished_run,
    pb,
    attempts.run_started_at,
    run_ended_at,
    run_duration,
    'runner' AS runner_name
FROM attempts_data4_runner attempts

LEFT JOIN finished_runs_runner finished
ON attempts.run_id = finished.run_id;

/* Getting the list of all PBs. */

DROP TABLE IF EXISTS pb_history_runner;
CREATE TABLE pb_history_runner AS
SELECT
    finished.run_id,
    finished.run_started_at,
    final_lrt_time,
    run_started_at - COALESCE(LAG(run_started_at) OVER(ORDER BY finished.run_id), run_started_at) AS days_it_took,
    finished.run_id - COALESCE(LAG(finished.run_id) OVER(ORDER BY finished.run_id), 0) attempts_it_took,
    total_playtime - COALESCE(LAG(total_playtime) OVER(ORDER BY finished.run_id), '0'::INTERVAL) total_playtime_it_took,
    days_attempts - COALESCE(LAG(days_attempts) OVER(ORDER BY finished.run_id), 0) AS days_of_attempts_it_took,
    lrt_pb
FROM finished_runs_runner finished

LEFT JOIN
(
    SELECT
        run_id,
        run_duration,
        SUM(run_duration) OVER(ORDER BY run_id) AS total_playtime
    FROM attempts_data5_runner
) cumulative_playtime
ON finished.run_id = cumulative_playtime.run_id

LEFT JOIN
(
    SELECT
        finished.run_id,
        COUNT(DISTINCT DATE(cumulative_playtime.run_started_at)) - 1 AS days_attempts
    FROM attempts_data5_runner finished

    LEFT JOIN attempts_data5_runner cumulative_playtime
    ON finished.run_id >= cumulative_playtime.run_id
    GROUP BY finished.run_id
    ORDER BY finished.run_id
) cumulative_days
ON finished.run_id = cumulative_days.run_id
WHERE pb;

--#endregion

--#region DOORS

/* We combine the attempts data with the segments data to obtain as a result the entire doorsplit history of the splits. This is the main table that will be used to get the interesting stats (chapter golds, section golds, best paces, etc). */

DROP TABLE IF EXISTS doorsplit_history1_runner;
CREATE TABLE doorsplit_history1_runner AS
SELECT
    segments.run_id,
    split_number,
    split_name,
    chapter,
    _section,
    lrt_time,
    lrt_time_formatted,
    rta_time,
    rta_time_formatted,
    finished_run,
    COALESCE(pb, FALSE) AS pb,
    final_lrt_time,
    final_rta_time,
    run_started_at,
    run_ended_at,
    run_duration
FROM segments_data7_runner segments

LEFT JOIN attempts_data5_runner attempts
ON segments.run_id = attempts.run_id;

/* Getting the cumulative RTA for each run, split by split, for as long as that run went on (obviously some runs last until split 1, others until split 2, others until split 8, others until the end, etc). */

DROP TABLE IF EXISTS cumulative_rta_runner;
CREATE TABLE cumulative_rta_runner AS
SELECT
    run_id,
    split_number,
    SUM(rta_time) OVER(PARTITION BY run_id ORDER BY split_number) AS run_cumulative_rta
FROM doorsplit_history1_runner
ORDER BY
    run_id,
    split_number;

/* Add cumulative RTA data to each run, this will be useful to calculate the start and end timestamp of each segment. */

DROP TABLE IF EXISTS doorsplit_history2_runner;
CREATE TABLE doorsplit_history2_runner AS
SELECT
    ds.run_id,
    ds.split_number,
    ds.split_name,
    ds.chapter,
    ds._section,
    ds.lrt_time,
    ds.lrt_time_formatted,
    ds.rta_time,
    ds.rta_time_formatted,
    ds.finished_run,
    ds.pb,
    ds.final_lrt_time,
    ds.final_rta_time,
    ds.run_started_at,
    ds.run_ended_at,
    ds.run_duration,
    crta.run_cumulative_rta,
    LAG(crta.run_cumulative_rta) OVER(PARTITION BY ds.run_id ORDER BY ds.split_number) AS run_cumulative_rta_lag
FROM doorsplit_history1_runner ds

LEFT JOIN cumulative_rta_runner crta
ON ds.run_id = crta.run_id AND ds.split_number = crta.split_number;

/* Adds the date and time at which each individual segment in the history began and ended. Also swaps all split names (which may be customized) by default split names for readability. */

DROP TABLE IF EXISTS doorsplit_history3_runner;
CREATE TABLE doorsplit_history3_runner AS
SELECT
    run_id,
    ds1.split_number,
    defs.split_name,
    chapter,
    _section,
    (
         SELECT
            COUNT(*)
         FROM doorsplit_history2_runner ds2
         WHERE ds2.split_number = ds1.split_number
            AND ds2.run_id <= ds1.run_id
            AND ds2.lrt_time < ds1.lrt_time
    ) + 1 AS lrt_time_rank_at_that_time,
    RANK() OVER (PARTITION BY ds1.split_number ORDER BY lrt_time) AS lrt_time_rank,
    lrt_time,
    lrt_time_formatted,
    rta_time,
    rta_time_formatted,
    finished_run,
    pb,
    final_lrt_time,
    final_rta_time,
    run_started_at,
    run_ended_at,
    run_duration,
    CASE
        WHEN ds1.split_number = 1 THEN
            run_started_at
        ELSE
            run_started_at + run_cumulative_rta_lag
    END AS split_started_at,
    CASE
        WHEN ds1.split_number = 123 THEN
            run_ended_at
        ELSE
            run_started_at + run_cumulative_rta
    END AS split_ended_at
FROM doorsplit_history2_runner ds1

LEFT JOIN default_split_names defs
ON ds1.split_number = defs.split_number
ORDER BY
    ds1.split_number,
    run_id;

/* Total number of times each doorsplit has been finished and has been golded in the history. */

DROP TABLE IF EXISTS finished_doorsplits_runner;
CREATE TABLE finished_doorsplits_runner AS
SELECT DISTINCT
    split_number,
    split_name,
    chapter,
    _section,
    COUNT(*) OVER(PARTITION BY split_number) AS times_finished,
    SUM(CASE WHEN lrt_time_rank_at_that_time = 1 THEN 1 ELSE 0 END) OVER(PARTITION BY split_number) AS times_golded
FROM doorsplit_history3_runner
ORDER BY split_number;

/* The average and median times for each doorsplit, along with well formatted versions. Also cumulative average and median times. */

DROP TABLE IF EXISTS avg_med_doorsplits_runner;
CREATE TABLE avg_med_doorsplits_runner AS
WITH avg_med AS
(
    SELECT
        split_number,
        split_name,
        chapter,
        _section,
        AVG(lrt_time) AS lrt_time_avg,
        LTRIM(TO_CHAR(AVG(lrt_time), 'HH24:MI:SS.FF3'), '0:') AS lrt_time_avg_formatted,
        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY lrt_time) AS lrt_time_med,
        LTRIM(TO_CHAR(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY lrt_time), 'HH24:MI:SS.FF3'), '0:') AS lrt_time_med_formatted
    FROM doorsplit_history3_runner
    GROUP BY
        split_number,
        split_name,
        chapter,
        _section
),
avg_med_cumulative AS
(
    SELECT
        split_number,
        split_name,
        chapter,
        _section,
        lrt_time_avg,
        lrt_time_avg_formatted,
        SUM(lrt_time_avg) OVER (ORDER BY split_number) AS sum_of_avg,
        lrt_time_med,
        lrt_time_med_formatted,
        SUM(lrt_time_med) OVER (ORDER BY split_number) AS sum_of_med
    FROM avg_med
    ORDER BY split_number
)

SELECT
    split_number,
    split_name,
    chapter,
    _section,
    lrt_time_avg,
    lrt_time_avg_formatted,
    sum_of_avg,
    LTRIM(TO_CHAR(sum_of_avg, 'HH24:MI:SS.FF3'), '0:') AS sum_of_avg_formatted,
    lrt_time_med,
    lrt_time_med_formatted,
    sum_of_med,
    LTRIM(TO_CHAR(sum_of_med, 'HH24:MI:SS.FF3'), '0:') AS sum_of_med_formatted
FROM avg_med_cumulative;

/* For each individual segment, we get the gold (fastest time ever on that segment) with ties if there are any. */

DROP TABLE IF EXISTS doorsplit_golds1_runner;
CREATE TABLE doorsplit_golds1_runner AS
SELECT
    run_id,
    split_number,
    split_name,
    chapter,
    _section,
    ROW_NUMBER(*) OVER(PARTITION BY lrt_time) AS lrt_time_occurrence,
    lrt_time,
    lrt_time_formatted,
    rta_time,
    rta_time_formatted,
    finished_run,
    pb,
    final_lrt_time,
    final_rta_time,
    run_started_at,
    run_ended_at,
    run_duration,
    split_started_at,
    split_ended_at
FROM doorsplit_history3_runner
WHERE lrt_time_rank = 1
ORDER BY
    split_number,
    lrt_time_occurrence;

/* Add the sum of best and sum of best formatted. */

DROP TABLE IF EXISTS doorsplit_golds2_runner;
CREATE TABLE doorsplit_golds2_runner AS
SELECT
    golds.run_id,
    golds.split_number,
    golds.split_name,
    golds.chapter,
    golds._section,
    golds.lrt_time_occurrence,
    golds.lrt_time,
    golds.lrt_time_formatted,
    cumulative.sum_of_best,
    LTRIM(TO_CHAR(cumulative.sum_of_best, 'HH24:MI:SS.FF3'), '0:') AS sum_of_best_formatted,
    golds.rta_time,
    golds.rta_time_formatted,
    golds.finished_run,
    golds.pb,
    golds.final_lrt_time,
    golds.final_rta_time,
    golds.run_started_at,
    golds.run_ended_at,
    golds.run_duration,
    golds.split_started_at,
    golds.split_ended_at
FROM doorsplit_golds1_runner golds

LEFT JOIN
(
    SELECT
        split_number,
        SUM(lrt_time) OVER(ORDER BY split_number) AS sum_of_best
    FROM
    (
        SELECT DISTINCT
            split_number,
            lrt_time
        FROM doorsplit_golds1_runner
    )
) cumulative
ON golds.split_number = cumulative.split_number;

/* The history of all golds ever obtained for each split, chronologically. */

DROP TABLE IF EXISTS doorsplit_golds_history_runner;
CREATE TABLE doorsplit_golds_history_runner AS
SELECT
    run_id,
    split_number,
    split_name,
    chapter,
    _section,
    lrt_time_rank,
    lrt_time,
    lrt_time_formatted,
    rta_time,
    rta_time_formatted,
    finished_run,
    pb,
    final_lrt_time,
    final_rta_time,
    run_started_at,
    run_ended_at,
    run_duration,
    split_started_at,
    split_ended_at
FROM doorsplit_history3_runner
WHERE lrt_time_rank_at_that_time = 1
ORDER BY
    split_number,
    run_id;

--#endregion DOORS

--#region CHAPTERS

/* All the chapter times ever obtained for each chapter, along with their rank relative to that chapter. */

DROP TABLE IF EXISTS chapter_history1_runner;
CREATE TABLE chapter_history1_runner AS
SELECT DISTINCT
    ds.run_id,
    ds.chapter,
    ds._section,
    RANK() OVER (PARTITION BY ds.chapter ORDER BY ds.chapter_time) AS chapter_time_rank,
    ds.chapter_time,
    LTRIM(TO_CHAR(ds.chapter_time, 'HH24:MI:SS.FF3'), '0:') AS chapter_time_formatted,
    ds.finished_run,
    ds.pb,
    ds.final_lrt_time,
    ds.final_rta_time,
    ds.run_started_at,
    ds.run_ended_at,
    ds.run_duration,
    ds.chapter_started_at,
    ds.chapter_ended_at
FROM
(
    SELECT
        COUNT(*) OVER(PARTITION BY run_id, chapter) AS num_splits,
        MIN(split_started_at) OVER(PARTITION BY run_id, chapter) AS chapter_started_at,
        MAX(split_ended_at) OVER(PARTITION BY run_id, chapter) AS chapter_ended_at,
        SUM(lrt_time) OVER(PARTITION BY run_id, chapter) AS chapter_time,
        *
    FROM doorsplit_history3_runner
) ds
INNER JOIN splits_per_chapter per
ON per.chapter = ds.chapter AND per.number_of_splits = ds.num_splits
ORDER BY
    chapter,
    run_id;

/* Adding the chapter time rank relative to when the chapter was done. */

DROP TABLE IF EXISTS chapter_history2_runner;
CREATE TABLE chapter_history2_runner AS
SELECT
    run_id,
    chapter,
    _section,
    (
         SELECT
            COUNT(*)
         FROM chapter_history1_runner ch2
         WHERE ch2.chapter = ch1.chapter
            AND ch2.run_id <= ch1.run_id
            AND ch2.chapter_time < ch1.chapter_time
    ) + 1 AS chapter_time_rank_at_that_time,
    chapter_time_rank,
    chapter_time,
    chapter_time_formatted,
    finished_run,
    pb,
    final_lrt_time,
    final_rta_time,
    run_started_at,
    run_ended_at,
    run_duration,
    chapter_started_at,
    chapter_ended_at
FROM chapter_history1_runner ch1;

/* Total number of times each chapter has been finished and has been golded in the history. */

DROP TABLE IF EXISTS finished_chapters_runner;
CREATE TABLE finished_chapters_runner AS
SELECT DISTINCT
    chapter,
    COUNT(*) OVER(PARTITION BY chapter) AS times_finished,
    SUM(CASE WHEN chapter_time_rank_at_that_time = 1 THEN 1 ELSE 0 END) OVER(PARTITION BY chapter) AS times_golded
FROM chapter_history2_runner
ORDER BY chapter;

/* The average and median times for each chapter, along with well formatted versions. Also cumulative average and median times. */

DROP TABLE IF EXISTS avg_med_chapters_runner;
CREATE TABLE avg_med_chapters_runner AS
WITH avg_med AS
(
    SELECT
        chapter,
        _section,
        AVG(chapter_time) AS chapter_time_avg,
        LTRIM(TO_CHAR(AVG(chapter_time), 'HH24:MI:SS.FF3'), '0:') AS chapter_time_avg_formatted,
        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY chapter_time) AS chapter_time_med,
        LTRIM(TO_CHAR(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY chapter_time), 'HH24:MI:SS.FF3'), '0:') AS chapter_time_med_formatted
    FROM chapter_history2_runner
    GROUP BY
        chapter,
        _section
),
avg_med_cumulative AS
(
    SELECT
        chapter,
        _section,
        chapter_time_avg,
        chapter_time_avg_formatted,
        SUM(chapter_time_avg) OVER (ORDER BY chapter) AS sum_of_avg,
        chapter_time_med,
        chapter_time_med_formatted,
        SUM(chapter_time_med) OVER (ORDER BY chapter) AS sum_of_med
    FROM avg_med
    ORDER BY chapter
)

SELECT
    chapter,
    _section,
    chapter_time_avg,
    chapter_time_avg_formatted,
    sum_of_avg,
    LTRIM(TO_CHAR(sum_of_avg, 'HH24:MI:SS.FF3'), '0:') AS sum_of_avg_formatted,
    chapter_time_med,
    chapter_time_med_formatted,
    sum_of_med,
    LTRIM(TO_CHAR(sum_of_med, 'HH24:MI:SS.FF3'), '0:') AS sum_of_med_formatted
FROM avg_med_cumulative;

/* For each individual chapter, we get the gold (fastest time ever on that chapter) with ties if there are any. */

DROP TABLE IF EXISTS chapter_golds1_runner;
CREATE TABLE chapter_golds1_runner AS
SELECT
    run_id,
    chapter,
    _section,
    ROW_NUMBER(*) OVER(PARTITION BY chapter_time) AS chapter_time_occurrence,
    chapter_time,
    chapter_time_formatted,
    finished_run,
    pb,
    final_lrt_time,
    final_rta_time,
    run_started_at,
    run_ended_at,
    run_duration,
    chapter_started_at,
    chapter_ended_at
FROM chapter_history2_runner
WHERE chapter_time_rank = 1
ORDER BY
    chapter,
    run_id;

/* Add the cumulative sum of best by chapters. */

DROP TABLE IF EXISTS chapter_golds2_runner;
CREATE TABLE chapter_golds2_runner AS
SELECT
    golds.run_id,
    golds.chapter,
    golds._section,
    golds.chapter_time_occurrence,
    golds.chapter_time,
    golds.chapter_time_formatted,
    cumulative.sum_of_best,
    LTRIM(TO_CHAR(cumulative.sum_of_best, 'HH24:MI:SS.FF3'), '0:') AS sum_of_best_formatted,
    golds.finished_run,
    golds.pb,
    golds.final_lrt_time,
    golds.final_rta_time,
    golds.run_started_at,
    golds.run_ended_at,
    golds.run_duration,
    golds.chapter_started_at,
    golds.chapter_ended_at
FROM chapter_golds1_runner golds

LEFT JOIN
(
    SELECT
        chapter,
        SUM(chapter_time) OVER(ORDER BY chapter) AS sum_of_best
    FROM
    (
        SELECT DISTINCT
            chapter,
            chapter_time
        FROM chapter_golds1_runner
    )
) cumulative
ON golds.chapter = cumulative.chapter;

--#endregion

--#region SECTIONS

/* All the section times ever obtained for each section, along with their rank relative to that section. */

DROP TABLE IF EXISTS section_history1_runner;
CREATE TABLE section_history1_runner AS
SELECT DISTINCT
    ds.run_id,
    ds._section,
    RANK() OVER (PARTITION BY ds._section ORDER BY ds.section_time) AS section_time_rank,
    ds.section_time,
    LTRIM(TO_CHAR(ds.section_time, 'HH24:MI:SS.FF3'), '0:') AS section_time_formatted,
    ds.finished_run,
    ds.pb,
    ds.final_lrt_time,
    ds.final_rta_time,
    ds.run_started_at,
    ds.run_ended_at,
    ds.run_duration,
    ds.section_started_at,
    ds.section_ended_at,
    per.sort
FROM
(
    SELECT
        COUNT(*) OVER(PARTITION BY run_id, _section) AS num_splits,
        MIN(split_started_at) OVER(PARTITION BY run_id, _section) AS section_started_at,
        MAX(split_ended_at) OVER(PARTITION BY run_id, _section) AS section_ended_at,
        SUM(lrt_time) OVER(PARTITION BY run_id, _section) AS section_time,
        *
    FROM doorsplit_history3_runner
) ds
INNER JOIN splits_per_section per
ON per._section = ds._section AND per.number_of_splits = ds.num_splits
ORDER BY
    per.sort,
    ds.run_id;

/* Adding the section time rank relative to when the section was done. */

DROP TABLE IF EXISTS section_history2_runner;
CREATE TABLE section_history2_runner AS
SELECT
    run_id,
    _section,
    (
        SELECT
            COUNT(*)
        FROM section_history1_runner sec2
        WHERE sec2._section = sec1._section
            AND sec2.run_id <= sec1.run_id
            AND sec2.section_time < sec1.section_time
    ) + 1 AS section_time_rank_at_that_time,
    section_time_rank,
    section_time,
    section_time_formatted,
    finished_run,
    pb,
    final_lrt_time,
    final_rta_time,
    run_started_at,
    run_ended_at,
    run_duration,
    section_started_at,
    section_ended_at,
    sort
FROM section_history1_runner sec1;

/* Total number of times each section has been finished and has been golded in the history. */

DROP TABLE IF EXISTS finished_sections_runner;
CREATE TABLE finished_sections_runner AS
SELECT DISTINCT
    _section,
    COUNT(*) OVER(PARTITION BY _section) AS times_finished,
    SUM(CASE WHEN section_time_rank_at_that_time = 1 THEN 1 ELSE 0 END) OVER(PARTITION BY _section) AS times_golded,
    sort
FROM section_history2_runner
ORDER BY sort;

/* The average and median times for each chapter, along with well formatted versions. Also cumulative average and median times. */

DROP TABLE IF EXISTS avg_med_sections_runner;
CREATE TABLE avg_med_sections_runner AS
WITH avg_med AS
(
    SELECT
        _section,
        AVG(section_time) AS section_time_avg,
        LTRIM(TO_CHAR(AVG(section_time), 'HH24:MI:SS.FF3'), '0:') AS section_time_avg_formatted,
        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY section_time) AS section_time_med,
        LTRIM(TO_CHAR(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY section_time), 'HH24:MI:SS.FF3'), '0:') AS section_time_med_formatted,
        sort
    FROM section_history2_runner
    GROUP BY
        _section, sort
),
avg_med_cumulative AS
(
    SELECT
        _section,
        section_time_avg,
        section_time_avg_formatted,
        SUM(section_time_avg) OVER (ORDER BY sort) AS sum_of_avg,
        section_time_med,
        section_time_med_formatted,
        SUM(section_time_med) OVER (ORDER BY sort) AS sum_of_med
    FROM avg_med
    ORDER BY sort
)

SELECT
    _section,
    section_time_avg,
    section_time_avg_formatted,
    sum_of_avg,
    LTRIM(TO_CHAR(sum_of_avg, 'HH24:MI:SS.FF3'), '0:') AS sum_of_avg_formatted,
    section_time_med,
    section_time_med_formatted,
    sum_of_med,
    LTRIM(TO_CHAR(sum_of_med, 'HH24:MI:SS.FF3'), '0:') AS sum_of_med_formatted
FROM avg_med_cumulative;

/* For each individual section, we get the gold (fastest time ever on that section) with ties if there are any. */

DROP TABLE IF EXISTS section_golds1_runner;
CREATE TABLE section_golds1_runner AS
SELECT
    run_id,
    _section,
    ROW_NUMBER(*) OVER(PARTITION BY section_time) AS section_time_occurrence,
    section_time,
    section_time_formatted,
    finished_run,
    pb,
    final_lrt_time,
    final_rta_time,
    run_started_at,
    run_ended_at,
    run_duration,
    section_started_at,
    section_ended_at,
    sort
FROM section_history2_runner
WHERE section_time_rank = 1
ORDER BY
    sort,
    run_id;

/* Add the cumulative sum of best by sections. */

DROP TABLE IF EXISTS section_golds2_runner;
CREATE TABLE section_golds2_runner AS
SELECT
    golds.run_id,
    golds._section,
    golds.section_time_occurrence,
    golds.section_time,
    golds.section_time_formatted,
    cumulative.sum_of_best,
    LTRIM(TO_CHAR(cumulative.sum_of_best, 'HH24:MI:SS.FF3'), '0:') AS sum_of_best_formatted,
    golds.finished_run,
    golds.pb,
    golds.final_lrt_time,
    golds.final_rta_time,
    golds.run_started_at,
    golds.run_ended_at,
    golds.run_duration,
    golds.section_started_at,
    golds.section_ended_at
FROM section_golds1_runner golds

LEFT JOIN
(
    SELECT
        _section,
        SUM(section_time) OVER(ORDER BY sort) AS sum_of_best
    FROM
    (
        SELECT DISTINCT
            _section,
            section_time,
            sort
        FROM section_golds1_runner
    )
) cumulative
ON golds._section = cumulative._section;

--#endregion

--#region PACES

/* History of all paces of all runs, for as long as each run lasted. The pace is simply the cumulative sum of the LRT/RTA time split per split. */

DROP TABLE IF EXISTS pace_history1_runner;
CREATE TABLE pace_history1_runner AS
SELECT
    run_id,
    split_number,
    split_name,
    chapter,
    _section,
    SUM(lrt_time) OVER(PARTITION BY run_id ORDER BY split_number) AS lrt_pace,
    SUM(rta_time) OVER(PARTITION BY run_id ORDER BY split_number) AS rta_pace
FROM doorsplit_history3_runner
ORDER BY
    run_id,
    split_number;

/* Add the rank of each pace from the history relative to that split. Also add readable LRT and RTA pace. */

DROP TABLE IF EXISTS pace_history2_runner;
CREATE TABLE pace_history2_runner AS
SELECT
    run_id,
    split_number,
    split_name,
    chapter,
    _section,
    RANK() OVER(PARTITION BY split_number ORDER BY lrt_pace) AS lrt_pace_rank,
    lrt_pace,
    LTRIM(TO_CHAR(lrt_pace, 'HH24:MI:SS.FF3'), '0:') AS lrt_pace_formatted,
    rta_pace,
    LTRIM(TO_CHAR(rta_pace, 'HH24:MI:SS.FF3'), '0:') AS rta_pace_formatted
FROM pace_history1_runner
ORDER BY
    run_id,
    split_number;

/* Best overall pace for each split. */

DROP TABLE IF EXISTS best_paces_runner;
CREATE TABLE best_paces_runner AS
SELECT
    run_id,
    split_number,
    split_name,
    chapter,
    _section,
    lrt_pace,
    lrt_pace_formatted,
    rta_pace,
    rta_pace_formatted
FROM pace_history2_runner
WHERE lrt_pace_rank = 1
ORDER BY split_number;

/* The average and median paces for each doorsplit, along with well formatted versions. */

DROP TABLE IF EXISTS avg_med_paces_runner;
CREATE TABLE avg_med_paces_runner AS
SELECT
    split_number,
    split_name,
    chapter,
    _section,
    AVG(lrt_pace) AS lrt_pace_avg,
    LTRIM(TO_CHAR(AVG(lrt_pace), 'HH24:MI:SS.FF3'), '0:') AS lrt_pace_avg_formatted,
    PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY lrt_pace) AS lrt_pace_med,
    LTRIM(TO_CHAR(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY lrt_pace), 'HH24:MI:SS.FF3'), '0:') AS lrt_pace_med_formatted
FROM pace_history2_runner
GROUP BY
    split_number,
    split_name,
    chapter,
    _section;

--#endregion

--#region RESETS

/* Getting the total number of times each doorsplit was finished as well as the total attempts overall. */

DROP TABLE IF EXISTS resets1_runner;
CREATE TABLE resets1_runner AS
SELECT
    split_number,
    split_name,
    chapter,
    _section,
    times_finished,
    attempts.total_attempts
FROM finished_doorsplits_runner fin
CROSS JOIN
(
    SELECT
        COUNT(*) AS total_attempts
    FROM attempts_data5_runner
) attempts;

/* Getting the percentage of times we reset on each doorsplit.
This is calculated by doing A / (A + B) where:

A = 'The number of times we started the split but never finished it'
B = 'The number of times we finished the split'

The number of times we started a split but never finished it is obtained by doing:

'number of times we finished the previous split' - 'number of times we finished the current split'

except for the very first split where we do:

'total attempts' - 'number of times we finished the first split'. */

DROP TABLE IF EXISTS resets2_runner;
CREATE TABLE resets2_runner AS
SELECT
    split_number,
    split_name,
    chapter,
    _section,
    times_finished,
    times_reset,
    ROUND((times_reset * 100.0) / COALESCE(times_finished_prev,  times_reset + times_finished), 4) AS percentage_reset,
    total_attempts
FROM (
    SELECT
        split_number,
        split_name,
        chapter,
        _section,
        times_finished,
        total_attempts,
        LAG(times_finished) OVER () AS times_finished_prev,
        COALESCE(LAG(times_finished) OVER () - times_finished, total_attempts - times_finished) AS times_reset
    FROM resets1_runner
);

--#endregion

--#region MAIN TABLE

/* Final main table that has everything */

DROP TABLE IF EXISTS splits_overview_runner;
CREATE TABLE splits_overview_runner AS
SELECT
    *
FROM
(
    SELECT
        a.run_id,
        a.split_name,
        a.chapter,
        a._section,
        a.lrt_time,
        a.lrt_time_formatted,
        a.run_started_at,
        a.finished_run,
        a.final_lrt_time,
        a.pb,
        a.split_number,
        a.final_rta_time,
        a.run_ended_at,
        a.run_duration,
        a.rta_time,
        a.rta_time_formatted,
        e.lrt_time AS ds_gold,
        e.lrt_time_formatted AS ds_gold_formatted,
        lrt_pace,
        lrt_pace_formatted,
        best_pace,
        best_pace2,
        chapter_time,
        chapter_time_formatted,
        section_time,
        section_time2,
        chapter_gold,
        section_gold,
        CASE
            WHEN a.finished_run THEN
                NULL
            ELSE
                split_of_reset
        END AS split_of_reset,
        CASE
            WHEN a.finished_run THEN
                NULL
            ELSE
                cle2_reset
        END AS cle2_reset,
        CASE
            WHEN a.split_number = 30 AND a.lrt_time <= '54.5'::INTERVAL THEN
                '2-a Fast Mendez'
            WHEN a.split_number = 30 AND a.lrt_time <= '57'::INTERVAL THEN
                '2-b Medium Mendez'
            WHEN a.split_number = 30 THEN
                '2-c Slow Mendez'
            ELSE
                ''
        END AS mendez_pattern,
        CASE
            WHEN a.split_number = 14 AND a.lrt_time <= '96'::INTERVAL THEN
                '1-a No dive'
            WHEN a.split_number = 14 AND a.lrt_time <= '102'::INTERVAL THEN
                '1-b Late dive'
            WHEN a.split_number = 14 OR (a.split_number = 13 AND cle2_reset = 14) THEN
                '1-c Early dive'
            ELSE
                ''
        END AS lago_pattern,
        CASE
            WHEN a.split_number = 65 AND a.lrt_time <= '31'::INTERVAL THEN
                '3-a Perfect catapult'
            WHEN a.split_number = 65 AND a.lrt_time <= '33'::INTERVAL THEN
                '3-b Stagger catapult'
            WHEN a.split_number = 65 THEN
                '3-c Boulder catapult'
            ELSE
                ''
        END AS catapult_pattern,
        CASE
            WHEN a.split_number = 26 AND a.lrt_time <= '113'::INTERVAL THEN
                '4-a Great cabin'
            WHEN a.split_number = 26 AND a.lrt_time <= '118'::INTERVAL THEN
                '4-b Good cabin'
            WHEN a.split_number = 26 AND a.lrt_time <= '123'::INTERVAL THEN
                '4-c Average cabin'
            WHEN a.split_number = 26 AND a.lrt_time <= '130'::INTERVAL THEN
                '4-d Bad cabin'
            WHEN a.split_number = 26 THEN
                '4-e Terrible cabin'
            ELSE
                ''
        END AS cabin_pattern,
        CASE
            WHEN a.split_number=38 AND a.lrt_time<='196'::INTERVAL THEN
                '5-a Great water hall'
            WHEN a.split_number=38 AND a.lrt_time<='199'::INTERVAL THEN
                '5-b Good water hall'
            WHEN a.split_number=38 AND a.lrt_time<='202'::INTERVAL THEN
                '5-c Average water hall'
            WHEN a.split_number=38 AND a.lrt_time<='205'::INTERVAL THEN
                '5-d Bad water hall'
            WHEN a.split_number=38 THEN
                '5-e Terrible water hall'
            ELSE
                ''
        END AS water_hall_pattern,
        CASE
            WHEN a.split_number=41 AND a.lrt_time<='82'::INTERVAL THEN
                '6-a Great novis 1'
            WHEN a.split_number=41 AND a.lrt_time<='84'::INTERVAL THEN
                '6-b Good novis 1'
            WHEN a.split_number=41 AND a.lrt_time<='86'::INTERVAL THEN
                '6-c Average novis 1'
            WHEN a.split_number=41 AND a.lrt_time<='88'::INTERVAL THEN
                '6-d Bad novis 1'
            WHEN a.split_number=41 THEN
                '6-e Terrible novis 1'
            ELSE
                ''
        END AS novis1_pattern,
        CASE
            WHEN a.split_number=43 AND a.lrt_time<='102'::INTERVAL THEN
                '7-a Great gallery'
            WHEN a.split_number=43 AND a.lrt_time<='105'::INTERVAL THEN
                '7-b Good gallery'
            WHEN a.split_number=43 AND a.lrt_time<='108'::INTERVAL THEN
                '7-c Average gallery'
            WHEN a.split_number=43 AND a.lrt_time<='110'::INTERVAL THEN
                '7-d Bad gallery'
            WHEN a.split_number=43 THEN
                '7-e Terrible gallery'
            ELSE
                ''
        END AS gallery_pattern,
        CASE
            WHEN a.split_number=64 AND a.lrt_time<='33.5'::INTERVAL THEN
                '8-a Great novis 2'
            WHEN a.split_number=64 AND a.lrt_time<='35'::INTERVAL THEN
                '8-b Good novis 2'
            WHEN a.split_number=64 AND a.lrt_time<='38'::INTERVAL THEN
                '8-c Average novis 2'
            WHEN a.split_number=64 AND a.lrt_time<='40'::INTERVAL THEN
                '8-d Bad novis 2'
            WHEN a.split_number=64 THEN
                '8-e Terrible novis 2'
            ELSE
                ''
        END AS novis2_pattern,
        CASE
            WHEN a.split_number=74 AND a.lrt_time<='77'::INTERVAL THEN
                '9-a Great novis 3'
            WHEN a.split_number=74 AND a.lrt_time<='79'::INTERVAL THEN
                '9-b Good novis 3'
            WHEN a.split_number=74 AND a.lrt_time<='82'::INTERVAL THEN
                '9-c Average novis 3'
            WHEN a.split_number=74 AND a.lrt_time<='85'::INTERVAL THEN
                '9-d Bad novis 3'
            WHEN a.split_number=74 THEN
                '9-e Terrible novis 3'
            ELSE
                ''
        END AS novis3_pattern,
        CASE
            WHEN a.split_number=110 AND a.lrt_time<='95.5'::INTERVAL THEN
                '90-a Great u3'
            WHEN a.split_number=110 AND a.lrt_time<='99'::INTERVAL THEN
                '90-b Good u3'
            WHEN a.split_number=110 AND a.lrt_time<='101'::INTERVAL THEN
                '90-c Average u3'
            WHEN a.split_number=110 AND a.lrt_time<='103'::INTERVAL THEN
                '90-d Bad u3'
            WHEN a.split_number=110 THEN
                '90-e Terrible u3'
            ELSE
                ''
        END AS u3_pattern,
        CASE
            WHEN a.split_number=112 AND a.lrt_time<='139'::INTERVAL THEN
                '91-a Great Krauser'
            WHEN a.split_number=112 AND a.lrt_time<='142'::INTERVAL THEN
                '91-b Good Krauser'
            WHEN a.split_number=112 AND a.lrt_time<='145'::INTERVAL THEN
                '91-c Average Krauser'
            WHEN a.split_number=112 AND a.lrt_time<='148'::INTERVAL THEN
                '91-d Bad Krauser'
            WHEN a.split_number=112 THEN
                '91-e Terrible Krauser'
            ELSE
                ''
        END AS krauser_pattern,
        CASE
            WHEN a.split_number=113 AND a.lrt_time<='111'::INTERVAL THEN
                '92-a Great war room'
            WHEN a.split_number=113 AND a.lrt_time<='114'::INTERVAL THEN
                '92-b Good war room'
            WHEN a.split_number=113 AND a.lrt_time<='117'::INTERVAL THEN
                '92-c Average war room'
            WHEN a.split_number=113 AND a.lrt_time<='120'::INTERVAL THEN
                '92-d Bad war room'
            WHEN a.split_number=113 THEN
                '92-e Terrible war room'
            ELSE
                ''
        END AS war_room_pattern,
        CASE
            WHEN a.split_number=117 AND a.lrt_time<='55'::INTERVAL THEN
                '93-a Great key card'
            WHEN a.split_number=117 AND a.lrt_time<='57'::INTERVAL THEN
                '93-b Good key card'
            WHEN a.split_number=117 AND a.lrt_time<='59'::INTERVAL THEN
                '93-c Average key card'
            WHEN a.split_number=117 AND a.lrt_time<='61'::INTERVAL THEN
                '93-d Bad key card'
            WHEN a.split_number=117 THEN
                '93-e Terrible key card'
            ELSE
                ''
        END AS key_card_pattern,
        CASE
            WHEN extract(DOW FROM a.run_started_at) = 0 THEN
                7
            ELSE
                extract(DOW FROM a.run_started_at)
        END AS weekday, -- Can probably be simplified using the MOD function
        h.lrt_pb AS pb_at_that_time,
        /* TODO: Put this back after doorsplit_golds_history2_runner gets fixed */ --golded_split,
        golded_chapter,
        golded_section,
        was_best_pace,
        cumulative_chapter_gold,
        cumulative_section_gold,
        cumulative_door_gold,
        /* TODO: Put this back after doorsplit_golds_history2_runner gets fixed */ --gold_at_that_time,
        chapter_gold_at_that_time,
        section_gold_at_that_time,
        best_pace_at_that_time,
        best_pace_at_that_time2,
        --door_avg,
        --door_median,
        --door_avg2,
        --door_median2,
        median_chapter_time,
        --avg_pace,
        --median_pace,
        --avg_pace2,
        --median_pace2,
        section_median,
        'runner' AS runner_name,
        rank_chapter,
        chapter_rank_at_that_time,
        finished_chapters,
        finished_chapters_at_that_time,
        rank_section,
        section_rank_at_that_time,
        finished_sections,
        finished_sections_at_that_time,
        /* TODO: Put this back after doorsplit_golds_history2_runner gets fixed */ -- rank_split,
        /* TODO: Put this back after doorsplit_golds_history2_runner gets fixed */ -- split_rank_at_that_time,
        /* TODO: Put this back after doorsplit_golds_history2_runner gets fixed */ -- finished_splits,
        /* TODO: Put this back after doorsplit_golds_history2_runner gets fixed */ -- finished_splits_at_that_time,
        rank_pace,
        pace_rank_at_that_time,
        finished_paces,
        finished_paces_at_that_time,
        ROW_NUMBER() OVER (PARTITION BY a.run_id, a.split_number ORDER BY id2 DESC) AS rang
    FROM doorsplit_history3_runner a

    LEFT JOIN pace_history2_runner b
    ON a.run_id = b.run_id AND a.split_number = b.split_number

    LEFT JOIN
    (
        SELECT
            split_number,
            lrt_time_formatted,
            lrt_time,
            MIN(sum_of_best) AS cumulative_door_gold
        FROM doorsplit_golds2_runner
        GROUP BY
            split_number,
            lrt_time_formatted,
            lrt_time
    ) e
    ON a.split_number = e.split_number

    /* TODO: Put this back after doorsplit_golds_history2_runner gets fixed
    LEFT JOIN doorsplit_golds_history2_runner ee
    ON a.split_number = ee.split_number AND a.run_id = ee.run_id */

    LEFT JOIN chapter_history2_runner c
    ON a.run_id = c.run_id AND a.chapter = c.chapter

    LEFT JOIN section_history2_runner d
    ON a.run_id = d.run_id AND a._section = d._section

    LEFT JOIN chapter_golds2_runner f
    ON a.chapter = f.chapter

    LEFT JOIN section_golds2_runner g
    ON a._section = g._section

    LEFT JOIN
    (
        SELECT
            a.run_id,
            b.split_name AS split_of_reset,
            b.split_number AS cle2_reset
        FROM
        (
            SELECT
                run_id,
                MAX(split_number) + 1 AS max
            FROM doorsplit_history3_runner
            GROUP BY run_id
        ) a

        LEFT JOIN
        (
            SELECT DISTINCT
                split_number,
                split_name
            FROM doorsplit_history3_runner
        ) b
        ON a.max = b.split_number
    ) resets
    ON resets.run_id = a.run_id

    LEFT JOIN
    (
        SELECT
            *,
            run_id::DECIMAL AS id2
        FROM pb_history_runner
    ) h
    ON a.run_id > h.id2
) aa
WHERE rang = 1
ORDER BY
    run_id,
    split_number;

--#endregion

--#region RNG

/* RNG splits (LIKE Lago) to get the % of patterns (LIKE % of early dives, etc.) */

DROP TABLE IF EXISTS rng_splits_runner;
CREATE TABLE rng_splits_runner AS
SELECT
    pattern,
    SUBSTR(pattern, 4, LENGTH(pattern) - 3) AS pattern2,
    runs,
    total,
    percentage
FROM
(
    SELECT
        pattern,
        runs,
        total,
        percentage
    FROM
    (
        SELECT
            a.*,
            total,
            ROUND(runs) / ROUND(total) * 100 AS percentage
        FROM
        (
            SELECT
                lago_pattern AS pattern,
                COUNT(*) AS runs
            FROM splits_overview_runner a

            LEFT JOIN doorsplit_history3_runner b
            ON a.run_id = b.run_id AND a.split_number = b.split_number
            WHERE
            (a.split_number = 14 AND a.lrt_time < '117'::INTERVAL) OR
            (a.split_number = 13 AND cle2_reset = 14 /* TODO: Fix this AND
            CASE
                WHEN time_end_numeric2 > time_ended_numeric AND b.time_run_ended <> time_end_numeric3 THEN
                    time_ended_numeric - time_end_numeric2 + 86400
                ELSE
                    time_ended_numeric - time_end_numeric2
                END
            >=
            CASE
                WHEN runner_name LIKE '%lu%' AND runner_name LIKE '%is%' THEN
                    59
                ELSE
                    56
            END*/)
            GROUP BY 1
        ) a

        CROSS JOIN
        (
            SELECT
                COUNT(*) AS total
            FROM splits_overview_runner a

            LEFT JOIN doorsplit_history3_runner b
            ON a.run_id = b.run_id AND a.split_number = b.split_number
            WHERE
            (a.split_number = 14 AND a.lrt_time < '117'::INTERVAL) OR
            (a.split_number = 13 AND cle2_reset = 14 /* TODO: Fix this AND
            CASE
                WHEN time_end_numeric2 > time_ended_numeric AND b.time_run_ended <> time_end_numeric3 THEN
                    time_ended_numeric - time_end_numeric2 + 86400
                ELSE
                    time_ended_numeric - time_end_numeric2
            END
            >=
            CASE
                WHEN runner_name LIKE '%lu%' AND runner_name LIKE '%is%' THEN
                    59
                ELSE
                    56
            END */)
        ) b
    )
    UNION
    (
        SELECT
            a.*,
            total,
            ROUND(runs) / ROUND(total) * 100 AS percentage
        FROM
        (
            SELECT
                mendez_pattern AS pattern,
                COUNT(*) AS runs
            FROM splits_overview_runner
            WHERE mendez_pattern <> '' AND lrt_time < '60'::INTERVAL
            GROUP BY 1
        ) a

        CROSS JOIN
        (
            SELECT
                COUNT(*) AS total
            FROM splits_overview_runner
            WHERE split_number = 30 AND lrt_time < '60'::INTERVAL
        ) b
    )
    UNION
    (
        SELECT
            a.*,
            total,
            ROUND(runs) / ROUND(total) * 100 AS percentage
        FROM
        (
            SELECT
                catapult_pattern AS pattern,
                COUNT(*) AS runs
            FROM splits_overview_runner
            WHERE catapult_pattern <> '' AND lrt_time < '40'::INTERVAL
            GROUP BY 1
        ) a

        CROSS JOIN
        (
            SELECT
                COUNT(*) AS total
            FROM splits_overview_runner
            WHERE split_number = 65 AND lrt_time < '40'::INTERVAL
        ) b
    )
    UNION
    (
        SELECT
            a.*,
            total,
            ROUND(runs) / ROUND(total) * 100 AS percentage
        FROM
        (
            SELECT
                cabin_pattern AS pattern,
                COUNT(*) AS runs
            FROM splits_overview_runner
            WHERE cabin_pattern <> ''
            GROUP BY 1
        ) a
        CROSS JOIN
        (
            SELECT
                COUNT(*) AS total
            FROM splits_overview_runner
            WHERE split_number = 26
        ) b
    )
    UNION
    (
        SELECT
            a.*,
            total,
            ROUND(runs) / ROUND(total) * 100 AS percentage
        FROM
        (
            SELECT
                water_hall_pattern AS pattern,
                COUNT(*) AS runs
            FROM splits_overview_runner
            WHERE water_hall_pattern <> ''
            GROUP BY 1
        ) a
        CROSS JOIN
        (
            SELECT
                COUNT(*) AS total
            FROM splits_overview_runner
            WHERE split_number = 38
        ) b
    )
    UNION
    (
        SELECT
            a.*,
            total,
            ROUND(runs) / ROUND(total) * 100 AS percentage
        FROM
        (
            SELECT
                novis1_pattern AS pattern,
                COUNT(*) AS runs
            FROM splits_overview_runner
            WHERE novis1_pattern <> ''
            GROUP BY 1
        ) a
        CROSS JOIN
        (
            SELECT
                COUNT(*) AS total
            FROM splits_overview_runner
            WHERE split_number = 41
        ) b
    )
    UNION
    (
        SELECT
            a.*,
            total,
            ROUND(runs) / ROUND(total) * 100 AS percentage
        FROM
        (
            SELECT
                gallery_pattern AS pattern,
                COUNT(*) AS runs
            FROM splits_overview_runner
            WHERE gallery_pattern <> ''
            GROUP BY 1
        ) a
        CROSS JOIN
        (
            SELECT
                COUNT(*) AS total
            FROM splits_overview_runner
            WHERE split_number = 43
        ) b
    )
    UNION
    (
        SELECT
            a.*,
            total,
            ROUND(runs) / ROUND(total) * 100 AS percentage
        FROM
        (
            SELECT
                novis2_pattern AS pattern,
                COUNT(*) AS runs
            FROM splits_overview_runner
            WHERE novis2_pattern <> ''
            GROUP BY 1
        ) a
        CROSS JOIN
        (
            SELECT
                COUNT(*) AS total
            FROM splits_overview_runner
            WHERE split_number = 64
        ) b
    )
    UNION
    (
        SELECT
            a.*,
            total,
            ROUND(runs) / ROUND(total) * 100 AS percentage
        FROM
        (
            SELECT
                novis3_pattern AS pattern,
                COUNT(*) AS runs
            FROM splits_overview_runner
            WHERE novis3_pattern <> ''
            GROUP BY 1
        ) a
        CROSS JOIN
        (
            SELECT
                COUNT(*) AS total
            FROM splits_overview_runner
            WHERE split_number = 74
        ) b
    )
    UNION
    (
        SELECT
            a.*,
            total,
            ROUND(runs) / ROUND(total) * 100 AS percentage
        FROM
        (
            SELECT
                u3_pattern AS pattern,
                COUNT(*) AS runs
            FROM splits_overview_runner
            WHERE u3_pattern <> ''
            GROUP BY 1
        ) a
        CROSS JOIN
        (
            SELECT
                COUNT(*) AS total
            FROM splits_overview_runner
            WHERE split_number = 110
        ) b
    )
    UNION
    (
        SELECT
            a.*,
            total,
            ROUND(runs) / ROUND(total) * 100 AS percentage
        FROM
        (
            SELECT
                krauser_pattern AS pattern,
                COUNT(*) AS runs
            FROM splits_overview_runner
            WHERE krauser_pattern <> ''
            GROUP BY 1
        ) a
        CROSS JOIN
        (
            SELECT
                COUNT(*) AS total
            FROM splits_overview_runner
            WHERE split_number = 112
        ) b
    )
    UNION
    (
        SELECT
            a.*,
            total,
            ROUND(runs) / ROUND(total) * 100 AS percentage
        FROM
        (
            SELECT
                war_room_pattern AS pattern,
                COUNT(*) AS runs
            FROM splits_overview_runner
            WHERE war_room_pattern <> ''
            GROUP BY 1
        ) a
        CROSS JOIN
        (
            SELECT
                COUNT(*) AS total
            FROM splits_overview_runner
            WHERE split_number = 113
        ) b
    )
    UNION
    (
        SELECT
            a.*,
            total,
            ROUND(runs) / ROUND(total) * 100 AS percentage
        FROM
        (
            SELECT
                key_card_pattern AS pattern,
                COUNT(*) AS runs
            FROM splits_overview_runner
            WHERE key_card_pattern <> ''
            GROUP BY 1
        ) a
        CROSS JOIN
        (
            SELECT
                COUNT(*) AS total
            FROM splits_overview_runner
            WHERE split_number = 117
        ) b
    )
    ORDER BY pattern
);

/* Same but to get the consecutive patterns (LIKE how many early dives IN a row */

DROP TABLE IF EXISTS consecutive_patterns_runner;
CREATE TABLE consecutive_patterns_runner AS
SELECT
    *
FROM
(
    SELECT
        lago_pattern,
        MAX(rank) AS maximum_consecutive_patterns
    FROM
    (
        SELECT
            run_id,
            lago_pattern,
            ROW_NUMBER() OVER (PARTITION BY lago_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
        FROM
        (
            SELECT DISTINCT
                a.run_id,
                lago_pattern,
                ROW_NUMBER() OVER (ORDER BY a.run_id) AS ROW_NUMBER,
                ROW_NUMBER() OVER (PARTITION BY lago_pattern ORDER BY a.run_id) AS row_number2
            FROM splits_overview_runner a

            LEFT JOIN doorsplit_history3_runner b
            ON a.run_id = b.run_id AND a.split_number = b.split_number
            WHERE
            (a.split_number = 14 AND a.lrt_time < '117'::INTERVAL) OR
            (a.split_number = 13 AND cle2_reset = 14) /* TODO: Fix this AND
            CASE
                WHEN time_end_numeric2 > time_ended_numeric AND b.time_run_ended <> time_end_numeric3 THEN
                    time_ended_numeric - time_end_numeric2 + 86400
                ELSE
                    time_ended_numeric - time_end_numeric2
                END
            >=
            CASE
                WHEN runner_name LIKE '%lu%' AND runner_name LIKE '%is%' THEN
                    59
                ELSE
                    56
            END*/
        )
        ORDER BY run_id
    )
    GROUP BY 1

    UNION

    SELECT
        mendez_pattern,
        MAX(rank) AS maximum_consecutive_patterns
    FROM
    (
        SELECT
            run_id,
            mendez_pattern,
            ROW_NUMBER() OVER (PARTITION BY mendez_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
        FROM
        (
            SELECT DISTINCT
                run_id,
                mendez_pattern,
                ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
                ROW_NUMBER() OVER (PARTITION BY mendez_pattern ORDER BY run_id) AS row_number2
            FROM splits_overview_runner
            WHERE mendez_pattern <> '' AND lrt_time < '60'::INTERVAL
        )
        ORDER BY run_id
    )
    GROUP BY 1

    UNION

    SELECT
        catapult_pattern,
        MAX(rank) AS maximum_consecutive_patterns
    FROM
    (
        SELECT
            run_id,
            catapult_pattern,
            ROW_NUMBER() OVER (PARTITION BY catapult_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
        FROM
        (
            SELECT DISTINCT
                run_id,
                catapult_pattern,
                ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
                ROW_NUMBER() OVER (PARTITION BY catapult_pattern ORDER BY run_id) AS row_number2
            FROM splits_overview_runner
            WHERE catapult_pattern <> '' AND lrt_time < '40'::INTERVAL
        )
        ORDER BY run_id
    )
    GROUP BY 1

    UNION

    SELECT
        cabin_pattern,
        MAX(rank) AS maximum_consecutive_patterns
    FROM
    (
        SELECT
            run_id,
            cabin_pattern,
            ROW_NUMBER() OVER (PARTITION BY cabin_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
        FROM
        (
            SELECT DISTINCT
                run_id,
                cabin_pattern,
                ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
                ROW_NUMBER() OVER (PARTITION BY cabin_pattern ORDER BY run_id) AS row_number2
            FROM splits_overview_runner
            WHERE cabin_pattern <> ''
        )
        ORDER BY run_id
    )
    GROUP BY 1

    UNION

    SELECT
        water_hall_pattern,
        MAX(rank) AS maximum_consecutive_patterns
    FROM
    (
        SELECT
            run_id,
            water_hall_pattern,
            ROW_NUMBER() OVER (PARTITION BY water_hall_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
        FROM
        (
            SELECT DISTINCT
                run_id,
                water_hall_pattern,
                ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
                ROW_NUMBER() OVER (PARTITION BY water_hall_pattern ORDER BY run_id) AS row_number2
            FROM splits_overview_runner
            WHERE water_hall_pattern <> ''
        )
        ORDER BY run_id
    )
    GROUP BY 1

    UNION

    SELECT
        novis1_pattern,
        MAX(rank) AS maximum_consecutive_patterns
    FROM
    (
        SELECT
            run_id,
            novis1_pattern,
            ROW_NUMBER() OVER (PARTITION BY novis1_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
        FROM
        (
            SELECT DISTINCT
                run_id,
                novis1_pattern,
                ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
                ROW_NUMBER() OVER (PARTITION BY novis1_pattern ORDER BY run_id) AS row_number2
            FROM splits_overview_runner
            WHERE novis1_pattern <> ''
        )
        ORDER BY run_id
    )
    GROUP BY 1

    UNION

    SELECT
        gallery_pattern,
        MAX(rank) AS maximum_consecutive_patterns
    FROM
    (
        SELECT
            run_id,
            gallery_pattern,
            ROW_NUMBER() OVER (PARTITION BY gallery_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
        FROM
        (
            SELECT DISTINCT
                run_id,
                gallery_pattern,
                ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
                ROW_NUMBER() OVER (PARTITION BY gallery_pattern ORDER BY run_id) AS row_number2
            FROM splits_overview_runner
            WHERE gallery_pattern <> ''
        )
        ORDER BY run_id
    )
    GROUP BY 1

    UNION

    SELECT
        novis2_pattern,
        MAX(rank) AS maximum_consecutive_patterns
    FROM
    (
        SELECT
            run_id,
            novis2_pattern,
            ROW_NUMBER() OVER (PARTITION BY novis2_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
        FROM
        (
            SELECT DISTINCT
                run_id,
                novis2_pattern,
                ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
                ROW_NUMBER() OVER (PARTITION BY novis2_pattern ORDER BY run_id) AS row_number2
            FROM splits_overview_runner
            WHERE novis2_pattern <> ''
        )
        ORDER BY run_id
    )
    GROUP BY 1

    UNION

    SELECT
        novis3_pattern,
        MAX(rank) AS maximum_consecutive_patterns
    FROM
    (
        SELECT
            run_id,
            novis3_pattern,
            ROW_NUMBER() OVER (PARTITION BY novis3_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
        FROM
        (
            SELECT DISTINCT
                run_id,
                novis3_pattern,
                ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
                ROW_NUMBER() OVER (PARTITION BY novis3_pattern ORDER BY run_id) AS row_number2
            FROM splits_overview_runner
            WHERE novis3_pattern <> ''
        )
        ORDER BY run_id
    )
    GROUP BY 1

    UNION

    SELECT
        u3_pattern,
        MAX(rank) AS maximum_consecutive_patterns
    FROM
    (
        SELECT
            run_id,
            u3_pattern,
            ROW_NUMBER() OVER (PARTITION BY u3_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
        FROM
        (
            SELECT DISTINCT
                run_id,
                u3_pattern,
                ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
                ROW_NUMBER() OVER (PARTITION BY u3_pattern ORDER BY run_id) AS row_number2
            FROM splits_overview_runner
            WHERE u3_pattern <> ''
        )
        ORDER BY run_id
    )
    GROUP BY 1

    UNION

    SELECT
        krauser_pattern,
        MAX(rank) AS maximum_consecutive_patterns
    FROM
    (
        SELECT
            run_id,
            krauser_pattern,
            ROW_NUMBER() OVER (PARTITION BY krauser_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
        FROM
        (
            SELECT DISTINCT
                run_id,
                krauser_pattern,
                ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
                ROW_NUMBER() OVER (PARTITION BY krauser_pattern ORDER BY run_id) AS row_number2
            FROM splits_overview_runner
            WHERE krauser_pattern <> ''
        )
        ORDER BY run_id
    )
    GROUP BY 1

    UNION

    SELECT
        war_room_pattern,
        MAX(rank) AS maximum_consecutive_patterns
    FROM
    (
        SELECT
            run_id,
            war_room_pattern,
            ROW_NUMBER() OVER (PARTITION BY war_room_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
        FROM
        (
            SELECT DISTINCT
                run_id,
                war_room_pattern,
                ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
                ROW_NUMBER() OVER (PARTITION BY war_room_pattern ORDER BY run_id) AS row_number2
            FROM splits_overview_runner
            WHERE war_room_pattern <> ''
        )
        ORDER BY run_id
    )
    GROUP BY 1

    UNION

    SELECT
        key_card_pattern,
        MAX(rank) AS maximum_consecutive_patterns
    FROM
    (
        SELECT
            run_id,
            key_card_pattern,
            ROW_NUMBER() OVER (PARTITION BY key_card_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
        FROM
        (
            SELECT DISTINCT
                run_id,
                key_card_pattern,
                ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
                ROW_NUMBER() OVER (PARTITION BY key_card_pattern ORDER BY run_id) AS row_number2
            FROM splits_overview_runner WHERE key_card_pattern<>''
        )
        ORDER BY run_id
    )
    GROUP BY 1
)
ORDER BY lago_pattern;

--#endregion

--#region USEFUL QUERIES

/* Script is finished, here we have some useful queries */

/* Checking is a gold was done ON a gold hunt (bad run) by checking the delta between the pace of that run AND the best pace for each split_name */

DROP TABLE IF EXISTS gold_hunt_detector_runner;
CREATE TABLE gold_hunt_detector_runner AS
SELECT
    split_number,
    split_name,
    lrt_time,
    lrt_time_formatted,
    run_id,
    run_started_at,
    final_lrt_time,
    pace,
    pace2,
    best_pace,
    best_pace2,
    best_pace_delta
FROM
(
    SELECT
        a.*,
        pace,
        best_pace,
        pace - best_pace AS best_pace_delta,
        pace2,
        best_pace2,
        ROW_NUMBER () OVER (PARTITION BY a.split_number ORDER BY pace - best_pace) AS rang
    FROM doorsplit_golds1_runner a

    LEFT JOIN best_paces_history2_runner b
    ON a.run_id = b.run_id AND a.split_number = b.split_number
) a
WHERE rang = 1
ORDER BY split_number;

/* All chapter golds with doorsplits golds combined per chapter */

DROP TABLE IF EXISTS chapter_golds_sheet_runner;
CREATE TABLE chapter_golds_sheet_runner AS
SELECT
    a.chapter,
    a.run_id,
    a.run_started_at,
    a.final_lrt_time,
    a.pb,
    cumulative_chapter_gold2 AS doorsplit_combined_gold,
    a.cumulative_chapter_gold,
    cumulative_door_gold,
    chapter_gold_at_that_time AS previous_chapter_gold
FROM chapter_golds2_runner a

LEFT JOIN
(
    SELECT
        chapter,
        SUM(lrt_time) AS cumulative_chapter_gold2
    FROM
    (
        SELECT
            a.chapter,
            a.lrt_time,
            a.lrt_time_formatted,
            a.split_number,
            MIN(sum_of_best) AS cumulative_door_gold
        FROM doorsplit_golds2_runner a
        LEFT JOIN
        (
            SELECT DISTINCT
                split_number,
                chapter
            FROM splits_overview_runner
        ) b ON a.split_number = b.split_number
        GROUP BY
            a.chapter,
            a.lrt_time,
            a.lrt_time_formatted,
            a.split_number
        ORDER BY a.split_number
    ) b
    GROUP BY chapter
) bb
ON a.chapter = bb.chapter

LEFT JOIN
(
    SELECT
        *
    FROM
    (
        SELECT
            split_number,
            chapter,
            cumulative_door_gold,
            ROW_NUMBER() OVER(PARTITION BY chapter ORDER BY split_number DESC) AS rang
        FROM splits_overview_runner
    ) a
    WHERE rang = 1
) c
ON a.chapter = c.chapter

LEFT JOIN
(
    SELECT DISTINCT
        run_id,
        chapter,
        chapter_gold_at_that_time
    FROM splits_overview_runner
    WHERE chapter_time = chapter_gold
) d
ON a.chapter = d.chapter AND a.run_id = d.run_id;

/* All _section golds with doorsplits golds combined per _section + chapter golds combined per _section */

DROP TABLE IF EXISTS section_golds_sheet_runner;
CREATE TABLE section_golds_sheet_runner AS
SELECT
    a.run_id,
    a._section,
    a.run_started_at,
    a.final_lrt_time,
    a.pb,
    cumulative_chapter_gold3 AS chapter_combined_gold,
    cumulative_chapter_gold2 AS doorsplit_combined_gold,
    a.cumulative_section_gold,
    cumulative_chapter_gold,
    cumulative_door_gold,
    section_gold_at_that_time AS previous_section_gold
FROM section_golds2_runner a

LEFT JOIN
(
    SELECT
        _section,
        SUM(lrt_time) AS cumulative_chapter_gold2
    FROM
    (
        SELECT DISTINCT
            a._section,
            a.lrt_time,
            a.lrt_time_formatted,
            a.split_number
        FROM doorsplit_golds2_runner a

        LEFT JOIN
        (
            SELECT DISTINCT
                split_number,
                _section
            FROM splits_overview_runner
        ) b
        ON a.split_number = b.split_number
    ) b
    GROUP BY _section
) bb
ON a._section = bb._section

LEFT JOIN
(
    SELECT *
    FROM
    (
        SELECT
            split_number,
            _section,
            cumulative_door_gold,
            ROW_NUMBER() OVER(PARTITION BY _section ORDER BY split_number DESC) AS rang
        FROM splits_overview_runner
    ) a
    WHERE rang = 1
) c
ON a._section = c._section

LEFT JOIN
(
    SELECT
        _section,
        SUM(chapter_gold) AS cumulative_chapter_gold3
    FROM
    (
        SELECT
            _section,
            a.chapter_gold,
            a.chapter,
            MIN(cumulative_chapter_gold) AS cumulative_chapter_gold
        FROM chapter_golds2_runner a

        LEFT JOIN
        (
            SELECT DISTINCT
                chapter,
                _section
            FROM splits_overview_runner
        ) b
        ON a.chapter = b.chapter
        GROUP BY
            _section,
            a.chapter_gold,
            a.chapter
        ORDER BY a.chapter
    ) b
    GROUP BY _section
) d
ON a._section = d._section

LEFT JOIN
(
    SELECT
        *
    FROM
    (
        SELECT
            chapter,
            _section,
            cumulative_chapter_gold,
            ROW_NUMBER() OVER(PARTITION BY _section ORDER BY chapter DESC) AS rang
        FROM splits_overview_runner
    ) a
    WHERE rang = 1
) e ON a._section = e._section

LEFT JOIN
(
    SELECT DISTINCT
        run_id,
        _section,
        section_gold_at_that_time
    FROM splits_overview_runner
    WHERE section_time = section_gold
) f
ON a._section = f._section AND a.run_id = f.run_id
ORDER BY
    CASE
        WHEN a._section = 'Village' THEN
            1
        WHEN a._section = 'Castle' THEN
            2
        ELSE
            3
    END;

/* TODO: Put this back after doorsplit_golds_history2_runner gets fixed Getting the history of PBs by the day of the week */


DROP TABLE IF EXISTS weekday_data_runner;
CREATE TABLE weekday_data_runner AS
SELECT
    a.*,
    /* TODO: Put this back after doorsplit_golds_history2_runner gets fixed */
    --golds,
    chapter_golds,
    section_golds,
    best_paces,
    attempts /
        CASE
            WHEN number_of_pbs = 0 THEN
                NULL
            ELSE
                number_of_pbs
        END AS attempts_to_get_a_pb,
    /* TODO: Put this back after doorsplit_golds_history2_runner gets fixed */
    --ROUND((ROUND(golds, 4) / ROUND(attempts, 4))*100, 2) || '%' AS golds_ratio,
    ROUND((ROUND(chapter_golds, 4) / ROUND(attempts, 4))*100, 2) || '%' AS chapter_golds_ratio,
    ROUND((ROUND(section_golds, 4) / ROUND(attempts, 4))*100, 2) || '%' AS section_golds_ratio,
    ROUND((ROUND(best_paces, 4) / ROUND(attempts, 4))*100, 2) || '%' AS best_paces_ratio,
    /* TODO: Put this back after doorsplit_golds_history2_runner gets fixed */
    --ROUND(ROUND(attempts, 2) / CASE WHEN golds = 0 THEN NULL ELSE golds END, 2) AS attempts_to_get_a_gold,
    ROUND(ROUND(attempts, 2) / CASE WHEN chapter_golds = 0 THEN NULL ELSE chapter_golds END, 2) AS attempts_to_get_a_chapter_gold,
    ROUND(ROUND(attempts, 2) / CASE WHEN section_golds = 0 THEN NULL ELSE section_golds END, 2) AS attempts_to_get_a_section_gold,
    ROUND(ROUND(attempts, 2) / CASE WHEN best_paces = 0 THEN NULL ELSE best_paces END, 2) AS attempts_to_get_a_best_pace,
    /* TODO: Put this back after doorsplit_golds_history2_runner gets fixed */
    --playtime / CASE WHEN golds = 0 THEN NULL ELSE golds END AS playtime_to_get_a_gold,
    playtime / CASE WHEN chapter_golds = 0 THEN NULL ELSE chapter_golds END AS playtime_to_get_a_chapter_gold,
    playtime / CASE WHEN section_golds = 0 THEN NULL ELSE section_golds END AS playtime_to_get_a_section_gold,
    playtime / CASE WHEN best_paces = 0 THEN NULL ELSE best_paces END AS playtime_to_get_a_best_pace
FROM
(
    SELECT
        CASE
            WHEN extract(DOW FROM run_started_at) = 0 THEN
                7
            ELSE
                extract(DOW FROM run_started_at)
        END AS weekday,
        SUM(run_duration) AS playtime,
        COUNT(DISTINCT run_id) AS attempts,
        COUNT(DISTINCT CASE WHEN pb THEN run_id ELSE NULL END) AS number_of_pbs,
        ROUND(ROUND(ROUND(COUNT(DISTINCT CASE WHEN pb THEN run_id ELSE NULL END), 4)/ROUND(COUNT(DISTINCT run_id), 4), 4) * 100, 2) || '%' AS pb_ratio--,
        /* TODO: Fix this
        ROUND(SUM(run_duration))/CASE WHEN ROUND(COUNT(DISTINCT CASE WHEN pb THEN run_id ELSE NULL END)) = 0 THEN NULL ELSE
        ROUND(COUNT(DISTINCT CASE WHEN pb THEN run_id ELSE NULL END)) END playtime_to_get_a_pb*/
    FROM attempts_data5_runner
    GROUP BY 1
) a

LEFT JOIN
(
    SELECT
        CASE
            WHEN extract(DOW FROM run_started_at) = 0 THEN
                7
            ELSE
                extract(DOW FROM run_started_at)
        END AS weekday,
        /* TODO: Put this back after doorsplit_golds_history2_runner gets fixed */
        --SUM(golded_split::INT) AS golds,
        SUM(golded_chapter::INT) AS chapter_golds,
        SUM(golded_section::INT) AS section_golds,
        SUM(was_best_pace::INT) AS best_paces
    FROM splits_overview_runner
    GROUP BY 1
) b
ON a.weekday = b.weekday
ORDER BY a.weekday;

--#endregion