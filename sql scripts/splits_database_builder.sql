--#region INITIAL SETUP

/* Importing the entire contents of the original .lss file. */

DROP TABLE IF EXISTS stg_splits_file_runner;
CREATE TABLE stg_splits_file_runner(line_number SERIAL, file_line TEXT);
COPY stg_splits_file_runner(file_line)
FROM 'path'
WITH DELIMITER ','; /* NOTE: The path to the splits file needs to be public, so that Postgres can access it. */

/* Adding the line number to each line of the file. */

DROP TABLE IF EXISTS stg_splits_file_indexed_runner;
CREATE TABLE stg_splits_file_indexed_runner AS
SELECT
    file_line,
    line_number
FROM stg_splits_file_runner
ORDER BY line_number;

/* Adding the line number + 1 to each line of the file. */

DROP TABLE IF EXISTS stg_splits_file_indexed_offset_runner;
CREATE TABLE stg_splits_file_indexed_offset_runner AS
SELECT
    file_line,
    line_number + 1 AS line_number_offset
FROM stg_splits_file_indexed_runner
ORDER BY line_number;

--#endregion

--#region SEGMENTS

/* Getting all the data about the Segment History (from the opening tag <Segments> all the way to the closing tag </Segments>). */

DROP TABLE IF EXISTS stg_segments_data1_runner;
CREATE TABLE stg_segments_data1_runner AS
SELECT
    LTRIM(file_line, ' ') AS file_line_stripped
FROM stg_splits_file_indexed_runner
WHERE line_number >
(
    SELECT
        line_number_offset
    FROM stg_splits_file_indexed_offset_runner
    WHERE file_line LIKE '%</AttemptHistory>%'
)
AND line_number <
(
    SELECT
        line_number
    FROM stg_splits_file_indexed_runner
    WHERE file_line LIKE '%<AutoSplitterSettings%'
);

/* Extracting the run id, the split name, the LRT time and the RTA time for the whole segment history of each segment.

For the run ids, we need to find the lines that have the format <Time id="integer">.
For the split names, we need to find the lines that have the format <Name>...</Name>.
For the LRT time, we need to find the lines that have the format <GameTime>...</GameTime>.
For the RTA time, we need to find the lines that have the format <RealTime>...</RealTime>.

We can achieve each one of these cases by using a regular expression. In the first case, ="(.*?)"> which catches everything between =" and "> and in the other cases >(.*?)</ which catches everything between > and </. In that first case, it's very important to end the regex with "> and NOT "/>, since we do not want the Time tags that close their tag immediately, because that means that run id has no LRT nor RTA times associated with it which is a bug that happens when runners delete their splits/golds manually etc. */

DROP TABLE IF EXISTS stg_segments_data2_runner;
CREATE TABLE stg_segments_data2_runner AS
SELECT
    COALESCE(SUBSTRING(file_line_stripped FROM '<Time id="(.*?)">'), '') AS run_id,
    COALESCE(SUBSTRING(file_line_stripped FROM '<Name>(.*?)</Name>'), '') AS split_name,
    COALESCE(SUBSTRING(file_line_stripped FROM '<GameTime>(.*?)</GameTime>'), '') AS lrt_time,
    COALESCE(SUBSTRING(file_line_stripped FROM '<RealTime>(.*?)</RealTime>'), '') AS rta_time,
    file_line_stripped,
    ROW_NUMBER() OVER() AS line_number
FROM stg_segments_data1_runner;


/* Converting the run id to INT. If the row doesn't have a valid run id (it's an empty string) then we force it to 0. This doesn't cause any issues because run ids always start from 1 and never from 0 in the file.

The LRT time of each split name is 2 rows below the row that has the run id of that time. Since we want everything on the same row we use the LEAD function, we want the information from 2 rows below the run id but also 1 row below run id because some rare Time tags that have negative run ids don't have any RTA time and only LRT, so in this edge case we take the next row and not the one after it. */

DROP TABLE IF EXISTS stg_segments_data3_runner;
CREATE TABLE stg_segments_data3_runner AS
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
FROM stg_segments_data2_runner;

/* Now putting back the LRT times that are 2 rows below the row we want (or 1 row below if negative run id) in the same row as the other info (run id, etc.) and ignoring the other intermediate unnecessary columns. */

DROP TABLE IF EXISTS stg_segments_data4_runner;
CREATE TABLE stg_segments_data4_runner AS
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
FROM stg_segments_data3_runner;

/* Now that we have the run ids and the LRT + RTA times in the same row, we just need to get the split names on this same row too. For this we select the minimum row number for each split_name using the line_number column, which tells us on which row the new split starts. The previous split ends 1 row before that. */

DROP TABLE IF EXISTS stg_split_names_data1_runner;
CREATE TABLE stg_split_names_data1_runner AS
SELECT DISTINCT
    split_name,
    split_name_instance,
    MIN(line_number) AS starts_at_row
FROM
(
    SELECT DISTINCT
        split_name,
        ROW_NUMBER() OVER(PARTITION BY split_name) AS split_name_instance,
        line_number
    FROM stg_segments_data4_runner
    WHERE split_name <> ''
)
GROUP BY split_name, split_name_instance
ORDER BY starts_at_row;

/* Now that we have the min row for each split name, it's easy to get the max, it's just the min of the next split -1. We also create a split_index column which also uses a ROW_NUMBER function but this time only with the 123 rows of the 123 unique splits (and not the whole LiveSplit history rows), this will be useful to create the chapters and areas. */

DROP TABLE IF EXISTS stg_split_names_data2_runner;
CREATE TABLE stg_split_names_data2_runner AS
SELECT
    ROW_NUMBER() OVER() AS split_index,
    split_name,
    starts_at_row,
    LEAD(starts_at_row) OVER(ORDER BY starts_at_row) - 1 AS ends_at_row
FROM stg_split_names_data1_runner;

/* We assign the chapter name and area name to each split based on the index of that split. For example, we know that 1-1 only has 4 splits (1 2 3 4), so if split_index is between 1 and 4, we know it belongs to chapter 1-1. This same logic is applied to assign the area name to each split. Note that this is quite brittle and has to be adjusted on a per-game or even per-category basis, as each game and/or category can have a varying amount of splits per chapter and per area.

Besides being able to identify the chapter name and area name, having the split number as a column is very useful as it allows us to 1) have a unique key to identify each split, regardless of if a split name is duplicated on the splits file or not and 2) convert each split name to default split names through their id, to standardize and simplify the output when exporting the final data. 3) allow each split to have any name (except containing commas) and not specific ones for the script to work properly. */

DROP TABLE IF EXISTS split_names_data3_runner;
CREATE TABLE split_names_data3_runner AS
SELECT
    split_index,
    split_name,
    ft.chapter,
    ft.area,
    starts_at_row,
    ends_at_row
FROM stg_split_names_data2_runner sn

LEFT JOIN cfg_chapter_area_splits_from_to ft
ON sn.split_index BETWEEN ft.from_split_index AND ft.to_split_index;

/* We join the split names table with the segments data table that has run ids and LRT times on the same row, so now it will have the split, chapter, area names on that same row too, because as explained before, the split name on the original file only shows once at the top and then just lists the entire history of that split name without displaying the split name again, so we need that for each row.

Just like we did for run ids and LRT times, we make the split name empty on the rows we don't want (there are a lot of unnecessary rows in the original file since all the data has 1 info per row, for example split name, LRT time and run id will show on 3 different rows on the original file, but since here we put everything on the same row, we only keep 1 row out of the 3 and the other 2 are useless, so we delete them). */

DROP TABLE IF EXISTS stg_segments_data5_runner;
CREATE TABLE stg_segments_data5_runner AS
SELECT
    run_id,
    split_index,
    CASE
        WHEN lrt_time = '' THEN
            ''
        ELSE
            splits.split_name
    END AS split_name,
    chapter,
    area,
    lrt_time,
    rta_time,
    file_line_stripped,
    line_number
FROM stg_segments_data4_runner segs

LEFT JOIN split_names_data3_runner splits
ON segs.line_number >= splits.starts_at_row
AND segs.line_number <= CASE
                            WHEN splits.ends_at_row IS NULL THEN
                                10000000
                            ELSE
                                splits.ends_at_row
                        END
ORDER BY line_number;

/* Converting the LRT and RTA times from text to INTERVAL types. At this point we only keep the rows that have useful information and we already have everything on the same row (run id, lrt time and split name) so we can delete the rest. We also get rid of all zero (since they start from 1) and negative run_ids as they can cause problems in calculations later on. */

DROP TABLE IF EXISTS stg_segments_data6_runner;
CREATE TABLE stg_segments_data6_runner AS
SELECT
    run_id,
    split_index,
    split_name,
    chapter,
    area,
    lrt_time::INTERVAL,
    CASE
        WHEN rta_time = '' THEN -- Rare but possible negative time ids don't have the RTA time.
            '0'::INTERVAL
        ELSE
            rta_time::INTERVAL
    END AS rta_time,
    file_line_stripped,
    line_number
FROM stg_segments_data5_runner
WHERE split_name <> '' AND run_id > 0;

/* Also adding the LRT and RTA time with the same format as in LiveSplit (Edit Splits window), not used for calculations but it's nicer to read. */

DROP TABLE IF EXISTS segments_data7_runner;
CREATE TABLE segments_data7_runner AS
SELECT
    run_id,
    split_index,
    split_name,
    chapter,
    area,
    lrt_time,
    LTRIM(TO_CHAR(lrt_time, 'HH24:MI:SS.FF3'), '0:') AS lrt_time_fmt,
    rta_time,
    LTRIM(TO_CHAR(rta_time, 'HH24:MI:SS.FF3'), '0:') AS rta_time_fmt,
    file_line_stripped,
    line_number
FROM stg_segments_data6_runner;

--#endregion

--#region ATTEMPTS

/* Getting all the data about the Attempts History (from the opening tag <AttemptHistory> all the way to the closing tag </AttemptHistory>). */

DROP TABLE IF EXISTS stg_attempts_data1_runner;
CREATE TABLE stg_attempts_data1_runner AS
SELECT
    LTRIM(file_line, ' ') AS file_line_stripped
FROM stg_splits_file_indexed_runner
WHERE line_number >
(
    SELECT
        line_number
    FROM stg_splits_file_indexed_runner
    WHERE file_line LIKE '%<AttemptHistory>%'
)
AND line_number <
(
    SELECT
        line_number
    FROM stg_splits_file_indexed_runner
    WHERE file_line LIKE '%</AttemptHistory>%'
);


/* For each attempt in the Attempt History raw data we obtain:

- The run id.
- The date and time of the start and end of the run.
- Whether the attempt ended up as a finished run or not.
- If the run was finished, its final LRT and RTA time excluding milliseconds. */

DROP TABLE IF EXISTS stg_attempts_data2_runner;
CREATE TABLE stg_attempts_data2_runner AS
SELECT
    COALESCE(SUBSTRING(file_line_stripped FROM 'id="(.*?)" started'), '') AS run_id,
    COALESCE(SUBSTRING(file_line_stripped FROM '<GameTime>(.*?)</GameTime>'), '') AS final_lrt_time,
    COALESCE(SUBSTRING(file_line_stripped FROM '<RealTime>(.*?)</RealTime>'), '') AS final_rta_time,
    SUBSTRING(file_line_stripped FROM 'started="(.*?)"') AS run_started_at,
    SUBSTRING(file_line_stripped FROM 'ended="(.*?)"') AS run_ended_at
FROM stg_attempts_data1_runner;

/* The finished runs will have their LRT time 2 rows after the run id, so need to put everything on the same row as done before for the Segments. Also remove useless rows and remove data from runs that are "too old" (this will be customizable eventually, but also optional). */

DROP TABLE IF EXISTS stg_attempts_data3_runner;
CREATE TABLE stg_attempts_data3_runner AS
SELECT
    run_id,
    LEAD(final_lrt_time, 2) OVER () AS final_lrt_time,
    LEAD(final_rta_time, 1) OVER () AS final_rta_time,
    TO_TIMESTAMP(run_started_at, 'MM/DD/YYYY HH24:MI:SS') AS run_started_at,
    TO_TIMESTAMP(run_ended_at, 'MM/DD/YYYY HH24:MI:SS') AS run_ended_at
FROM stg_attempts_data2_runner;

/* Remove rows where the run_id isn't present. Also remove rows from runs that are "too old". Convert run_id to INT. */

DROP TABLE IF EXISTS stg_attempts_data4_runner;
CREATE TABLE stg_attempts_data4_runner AS
SELECT
    run_id::INT,
    final_lrt_time,
    final_rta_time,
    COALESCE(final_lrt_time <> '' OR final_rta_time <> '', FALSE) AS finished_run,
    run_started_at,
    run_ended_at,
    run_ended_at - run_started_at AS run_duration
FROM stg_attempts_data3_runner
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
FROM stg_attempts_data4_runner
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
FROM stg_attempts_data4_runner attempts

LEFT JOIN finished_runs_runner finished
ON attempts.run_id = finished.run_id;

/* Getting the list of all PBs. */

DROP TABLE IF EXISTS pb_history_runner;
CREATE TABLE pb_history_runner AS
SELECT
    finished.run_id,
    finished.run_started_at,
    lrt_pb,
    run_started_at - COALESCE(LAG(run_started_at) OVER(ORDER BY finished.run_id), run_started_at) AS days_it_took,
    finished.run_id - COALESCE(LAG(finished.run_id) OVER(ORDER BY finished.run_id), 0) attempts_it_took,
    total_playtime - COALESCE(LAG(total_playtime) OVER(ORDER BY finished.run_id), '0'::INTERVAL) total_playtime_it_took,
    days_attempts - COALESCE(LAG(days_attempts) OVER(ORDER BY finished.run_id), 0) AS days_of_attempts_it_took
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

/* We combine the attempts data with the segments data to obtain as a result the entire doorsplit history of the splits. This is the main table that will be used to get the interesting stats (chapter golds, area golds, best paces, etc). */

DROP TABLE IF EXISTS stg_doorsplit_history1_runner;
CREATE TABLE stg_doorsplit_history1_runner AS
SELECT
    segments.run_id,
    split_index,
    split_name,
    chapter,
    area,
    lrt_time,
    lrt_time_fmt,
    rta_time,
    rta_time_fmt,
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

/* Add cumulative RTA data to each run, this will be useful to calculate the start and end timestamp of each segment.

The cumulative RTA for each run is calculated split by split, for as long as that run went on (obviously some runs last until split 1, others until split 2, others until split 8, others until the end, etc). */

DROP TABLE IF EXISTS stg_doorsplit_history2_runner;
CREATE TABLE stg_doorsplit_history2_runner AS
SELECT
    ds.run_id,
    ds.split_index,
    ds.split_name,
    ds.chapter,
    ds.area,
    ds.lrt_time,
    ds.lrt_time_fmt,
    ds.rta_time,
    ds.rta_time_fmt,
    ds.finished_run,
    ds.pb,
    ds.final_lrt_time,
    ds.final_rta_time,
    ds.run_started_at,
    ds.run_ended_at,
    ds.run_duration,
    cumulative_rta.run_cumulative_rta,
    LAG(cumulative_rta.run_cumulative_rta) OVER(PARTITION BY ds.run_id ORDER BY ds.split_index) AS run_cumulative_rta_lag
FROM stg_doorsplit_history1_runner ds

LEFT JOIN
(
    SELECT
        run_id,
        split_index,
        SUM(rta_time) OVER(PARTITION BY run_id ORDER BY split_index) AS run_cumulative_rta
    FROM stg_doorsplit_history1_runner
) cumulative_rta
ON ds.run_id = cumulative_rta.run_id AND ds.split_index = cumulative_rta.split_index;

/* Adds the date and time at which each individual segment in the history began and ended. Also swaps all split names (which may be customized) by default split names for readability. */

DROP TABLE IF EXISTS stg_doorsplit_history3_runner;
CREATE TABLE stg_doorsplit_history3_runner AS
SELECT
    run_id,
    ds1.split_index,
    defs.split_name,
    chapter,
    area,
    (
         SELECT
            COUNT(*)
         FROM stg_doorsplit_history2_runner ds2
         WHERE ds2.split_index = ds1.split_index
            AND ds2.run_id <= ds1.run_id
            AND ds2.lrt_time < ds1.lrt_time
    ) + 1 AS doorsplit_rank_at_that_time,
    RANK() OVER (PARTITION BY ds1.split_index ORDER BY lrt_time) AS doorsplit_rank,
    MIN(lrt_time) OVER(PARTITION BY ds1.split_index ORDER BY run_id) AS doorsplit_gold_at_that_time,
    lrt_time,
    lrt_time_fmt,
    rta_time,
    rta_time_fmt,
    finished_run,
    pb,
    final_lrt_time,
    final_rta_time,
    run_started_at,
    run_ended_at,
    run_duration,
    CASE
        WHEN ds1.split_index = 1 THEN
            run_started_at
        ELSE
            run_started_at + run_cumulative_rta_lag
    END AS split_started_at,
    CASE
        WHEN ds1.split_index = 123 THEN
            run_ended_at
        ELSE
            run_started_at + run_cumulative_rta
    END AS split_ended_at
FROM stg_doorsplit_history2_runner ds1

LEFT JOIN cfg_default_split_names defs
ON ds1.split_index = defs.split_index;

/* Add the number of the split where the run reset, which is NULL if the run was finished. Add the duration of the split where the run reset. Add the day of the week it was when the run was started. */

DROP TABLE IF EXISTS stg_doorsplit_history4_runner;
CREATE TABLE stg_doorsplit_history4_runner AS
SELECT
    run_id,
    split_index,
    split_name,
    chapter,
    area,
    doorsplit_rank_at_that_time,
    doorsplit_rank,
    doorsplit_gold_at_that_time,
    lrt_time,
    lrt_time_fmt,
    rta_time,
    rta_time_fmt,
    finished_run,
    pb,
    final_lrt_time,
    final_rta_time,
    EXTRACT(ISODOW FROM run_started_at) AS run_started_on_weekday,
    run_started_at,
    run_ended_at,
    run_duration,
    split_started_at,
    split_ended_at,
    CASE
        WHEN MAX(split_index) OVER(PARTITION BY run_id) <> 123 THEN
            MAX(split_index) OVER(PARTITION BY run_id) + 1
        ELSE
            NULL
    END AS split_index_reset,
    CASE
        WHEN MIN(run_ended_at::TIMESTAMP(0) - split_ended_at::TIMESTAMP(0)) OVER(PARTITION BY run_id) > '0'::INTERVAL THEN
            MIN(run_ended_at::TIMESTAMP(0) - split_ended_at::TIMESTAMP(0)) OVER(PARTITION BY run_id)
        ELSE
            NULL
    END AS split_reset_duration
FROM stg_doorsplit_history3_runner
ORDER BY
    run_id,
    split_index;

/* Add the name of the split where the run reset. */

DROP TABLE IF EXISTS doorsplit_history5_runner;
CREATE TABLE doorsplit_history5_runner AS
SELECT
    run_id,
    ds.split_index,
    ds.split_name,
    chapter,
    area,
    doorsplit_rank_at_that_time,
    doorsplit_rank,
    doorsplit_gold_at_that_time,
    lrt_time,
    lrt_time_fmt,
    rta_time,
    rta_time_fmt,
    finished_run,
    pb,
    final_lrt_time,
    final_rta_time,
    run_started_on_weekday,
    run_started_at,
    run_ended_at,
    run_duration,
    split_started_at,
    split_ended_at,
    split_index_reset,
    dsn.split_name AS split_name_reset,
    split_reset_duration
FROM stg_doorsplit_history4_runner ds

LEFT JOIN cfg_default_split_names dsn
ON ds.split_index_reset = dsn.split_index
ORDER BY
    run_id,
    split_index;

/* Total number of times each doorsplit has been finished and has been golded in the history. */

DROP TABLE IF EXISTS doorsplits_finished_runner;
CREATE TABLE doorsplits_finished_runner AS
SELECT DISTINCT
    split_index,
    split_name,
    chapter,
    area,
    COUNT(*) OVER(PARTITION BY split_index) AS times_finished,
    SUM(CASE WHEN doorsplit_rank_at_that_time = 1 THEN 1 ELSE 0 END) OVER(PARTITION BY split_index) AS times_golded
FROM doorsplit_history5_runner
ORDER BY split_index;

/* The average and median times for each doorsplit, along with well formatted versions. Also cumulative average and median times. */

DROP TABLE IF EXISTS doorsplits_avg_med_runner;
CREATE TABLE doorsplits_avg_med_runner AS
WITH avg_med AS
(
    SELECT
        split_index,
        split_name,
        chapter,
        area,
        AVG(lrt_time) AS lrt_time_avg,
        LTRIM(TO_CHAR(AVG(lrt_time), 'HH24:MI:SS.FF3'), '0:') AS lrt_time_avg_fmt,
        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY lrt_time) AS lrt_time_med,
        LTRIM(TO_CHAR(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY lrt_time), 'HH24:MI:SS.FF3'), '0:') AS lrt_time_med_fmt
    FROM doorsplit_history5_runner
    GROUP BY
        split_index,
        split_name,
        chapter,
        area
),
avg_med_cumulative AS
(
    SELECT
        split_index,
        split_name,
        chapter,
        area,
        lrt_time_avg,
        lrt_time_avg_fmt,
        SUM(lrt_time_avg) OVER (ORDER BY split_index) AS sum_of_avg,
        lrt_time_med,
        lrt_time_med_fmt,
        SUM(lrt_time_med) OVER (ORDER BY split_index) AS sum_of_med
    FROM avg_med
    ORDER BY split_index
)

SELECT
    split_index,
    split_name,
    chapter,
    area,
    lrt_time_avg,
    lrt_time_avg_fmt,
    sum_of_avg,
    LTRIM(TO_CHAR(sum_of_avg, 'HH24:MI:SS.FF3'), '0:') AS sum_of_avg_fmt,
    lrt_time_med,
    lrt_time_med_fmt,
    sum_of_med,
    LTRIM(TO_CHAR(sum_of_med, 'HH24:MI:SS.FF3'), '0:') AS sum_of_med_fmt
FROM avg_med_cumulative;

/* For each individual segment, we get the gold (fastest time ever on that segment) with ties if there are any. */

DROP TABLE IF EXISTS stg_doorsplit_golds1_runner;
CREATE TABLE stg_doorsplit_golds1_runner AS
SELECT
    run_id,
    split_index,
    split_name,
    chapter,
    area,
    ROW_NUMBER(*) OVER(PARTITION BY split_index, lrt_time) AS lrt_time_instance,
    lrt_time,
    lrt_time_fmt,
    rta_time,
    rta_time_fmt,
    finished_run,
    pb,
    final_lrt_time,
    final_rta_time,
    run_started_at,
    run_ended_at,
    run_duration,
    split_started_at,
    split_ended_at
FROM doorsplit_history5_runner
WHERE doorsplit_rank = 1
ORDER BY
    split_index,
    lrt_time_instance;

/* Add the sum of best and sum of best formatted. */

DROP TABLE IF EXISTS doorsplit_golds2_runner;
CREATE TABLE doorsplit_golds2_runner AS
SELECT
    golds.run_id,
    golds.split_index,
    golds.split_name,
    golds.chapter,
    golds.area,
    golds.lrt_time_instance,
    golds.lrt_time,
    golds.lrt_time_fmt,
    cumulative.sum_of_best,
    LTRIM(TO_CHAR(cumulative.sum_of_best, 'HH24:MI:SS.FF3'), '0:') AS sum_of_best_fmt,
    golds.rta_time,
    golds.rta_time_fmt,
    golds.finished_run,
    golds.pb,
    golds.final_lrt_time,
    golds.final_rta_time,
    golds.run_started_at,
    golds.run_ended_at,
    golds.run_duration,
    golds.split_started_at,
    golds.split_ended_at
FROM stg_doorsplit_golds1_runner golds

LEFT JOIN
(
    SELECT
        split_index,
        SUM(lrt_time) OVER(ORDER BY split_index) AS sum_of_best
    FROM
    (
        SELECT DISTINCT
            split_index,
            lrt_time
        FROM stg_doorsplit_golds1_runner
    )
) cumulative
ON golds.split_index = cumulative.split_index;

/* The history of all golds ever obtained for each split, chronologically. */

DROP TABLE IF EXISTS doorsplit_golds_history_runner;
CREATE TABLE doorsplit_golds_history_runner AS
SELECT
    run_id,
    split_index,
    split_name,
    chapter,
    area,
    doorsplit_rank,
    lrt_time,
    lrt_time_fmt,
    rta_time,
    rta_time_fmt,
    finished_run,
    pb,
    final_lrt_time,
    final_rta_time,
    run_started_at,
    run_ended_at,
    run_duration,
    split_started_at,
    split_ended_at
FROM doorsplit_history5_runner
WHERE doorsplit_rank_at_that_time = 1
ORDER BY
    split_index,
    run_id;

--#endregion DOORS

--#region CHAPTERS

/* All the chapter times ever obtained for each chapter, along with their rank relative to that chapter. */

DROP TABLE IF EXISTS stg_chapter_history1_runner;
CREATE TABLE stg_chapter_history1_runner AS
SELECT DISTINCT
    ds.run_id,
    ds.chapter,
    ds.area,
    MIN(ds.chapter_time) OVER(PARTITION BY ds.chapter ORDER BY run_id) AS chapter_gold_at_that_time,
    ds.chapter_time,
    LTRIM(TO_CHAR(ds.chapter_time, 'HH24:MI:SS.FF3'), '0:') AS chapter_time_fmt,
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
    FROM doorsplit_history5_runner
) ds

INNER JOIN cfg_chapter_area_splits_from_to per
ON per.chapter = ds.chapter AND (per.to_split_index - per.from_split_index) + 1 = ds.num_splits
ORDER BY
    chapter,
    run_id;

/* Adding the chapter time rank relative to when the chapter was done. */

DROP TABLE IF EXISTS chapter_history2_runner;
CREATE TABLE chapter_history2_runner AS
SELECT
    run_id,
    chapter,
    area,
    (
         SELECT
            COUNT(*)
         FROM stg_chapter_history1_runner ch2
         WHERE ch2.chapter = ch1.chapter
            AND ch2.run_id <= ch1.run_id
            AND ch2.chapter_time < ch1.chapter_time
    ) + 1 AS chapter_rank_at_that_time,
    RANK() OVER (PARTITION BY chapter ORDER BY chapter_time) AS chapter_rank,
    chapter_gold_at_that_time,
    chapter_time,
    chapter_time_fmt,
    finished_run,
    pb,
    final_lrt_time,
    final_rta_time,
    run_started_at,
    run_ended_at,
    run_duration,
    chapter_started_at,
    chapter_ended_at
FROM stg_chapter_history1_runner ch1;

/* Total number of times each chapter has been finished and has been golded in the history. */

DROP TABLE IF EXISTS chapters_finished_runner;
CREATE TABLE chapters_finished_runner AS
SELECT DISTINCT
    chapter,
    COUNT(*) OVER(PARTITION BY chapter) AS times_finished,
    SUM(CASE WHEN chapter_rank_at_that_time = 1 THEN 1 ELSE 0 END) OVER(PARTITION BY chapter) AS times_golded
FROM chapter_history2_runner
ORDER BY chapter;

/* The average and median times for each chapter, along with well formatted versions. Also cumulative average and median times. */

DROP TABLE IF EXISTS chapters_avg_med_runner;
CREATE TABLE chapters_avg_med_runner AS
WITH avg_med AS
(
    SELECT
        chapter,
        area,
        AVG(chapter_time) AS chapter_time_avg,
        LTRIM(TO_CHAR(AVG(chapter_time), 'HH24:MI:SS.FF3'), '0:') AS chapter_time_avg_fmt,
        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY chapter_time) AS chapter_time_med,
        LTRIM(TO_CHAR(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY chapter_time), 'HH24:MI:SS.FF3'), '0:') AS chapter_time_med_fmt
    FROM chapter_history2_runner
    GROUP BY
        chapter,
        area
),
avg_med_cumulative AS
(
    SELECT
        chapter,
        area,
        chapter_time_avg,
        chapter_time_avg_fmt,
        SUM(chapter_time_avg) OVER (ORDER BY chapter) AS sum_of_avg,
        chapter_time_med,
        chapter_time_med_fmt,
        SUM(chapter_time_med) OVER (ORDER BY chapter) AS sum_of_med
    FROM avg_med
    ORDER BY chapter
)

SELECT
    chapter,
    area,
    chapter_time_avg,
    chapter_time_avg_fmt,
    sum_of_avg,
    LTRIM(TO_CHAR(sum_of_avg, 'HH24:MI:SS.FF3'), '0:') AS sum_of_avg_fmt,
    chapter_time_med,
    chapter_time_med_fmt,
    sum_of_med,
    LTRIM(TO_CHAR(sum_of_med, 'HH24:MI:SS.FF3'), '0:') AS sum_of_med_fmt
FROM avg_med_cumulative;

/* For each individual chapter, we get the gold (fastest time ever on that chapter) with ties if there are any. */

DROP TABLE IF EXISTS stg_chapter_golds1_runner;
CREATE TABLE stg_chapter_golds1_runner AS
SELECT
    run_id,
    chapter,
    area,
    ROW_NUMBER(*) OVER(PARTITION BY chapter, chapter_time) AS chapter_time_instance,
    chapter_time,
    chapter_time_fmt,
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
WHERE chapter_rank = 1
ORDER BY
    chapter,
    run_id;

/* Add the cumulative sum of best by chapters. */

DROP TABLE IF EXISTS chapter_golds2_runner;
CREATE TABLE chapter_golds2_runner AS
SELECT
    golds.run_id,
    golds.chapter,
    golds.area,
    golds.chapter_time_instance,
    golds.chapter_time,
    golds.chapter_time_fmt,
    cumulative.sum_of_best,
    LTRIM(TO_CHAR(cumulative.sum_of_best, 'HH24:MI:SS.FF3'), '0:') AS sum_of_best_fmt,
    golds.finished_run,
    golds.pb,
    golds.final_lrt_time,
    golds.final_rta_time,
    golds.run_started_at,
    golds.run_ended_at,
    golds.run_duration,
    golds.chapter_started_at,
    golds.chapter_ended_at
FROM stg_chapter_golds1_runner golds

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
        FROM stg_chapter_golds1_runner
    )
) cumulative
ON golds.chapter = cumulative.chapter;

/* Chapter golds but calculated in a different way: summing up all the doorsplit golds that belong to each chapter. */

DROP TABLE IF EXISTS chapter_golds_by_doors_runner;
CREATE TABLE chapter_golds_by_doors_runner AS
SELECT
    chapter,
    chapter_gold_by_doors,
    LTRIM(TO_CHAR(chapter_gold_by_doors, 'HH24:MI:SS.FF3'), '0:') AS chapter_gold_by_doors_fmt,
    SUM(chapter_gold_by_doors) OVER(ORDER BY chapter) AS sum_of_best,
    LTRIM(TO_CHAR(SUM(chapter_gold_by_doors) OVER(ORDER BY chapter), 'HH24:MI:SS.FF3'), '0:') AS sum_of_best_fmt
FROM
(
    SELECT
        chapter,
        SUM(lrt_time) AS chapter_gold_by_doors
    FROM doorsplit_golds2_runner
    WHERE lrt_time_instance = 1
    GROUP BY chapter
    ORDER BY chapter
)
ORDER BY chapter;

--#endregion

--#region AREAS

/* All the area times ever obtained for each area, along with their rank relative to that area. */

DROP TABLE IF EXISTS stg_area_history1_runner;
CREATE TABLE stg_area_history1_runner AS
SELECT DISTINCT
    ds.run_id,
    ds.area,
    MIN(ds.area_time) OVER(PARTITION BY ds.area ORDER BY run_id) AS area_gold_at_that_time,
    ds.area_time,
    LTRIM(TO_CHAR(ds.area_time, 'HH24:MI:SS.FF3'), '0:') AS area_time_fmt,
    ds.finished_run,
    ds.pb,
    ds.final_lrt_time,
    ds.final_rta_time,
    ds.run_started_at,
    ds.run_ended_at,
    ds.run_duration,
    ds.area_started_at,
    ds.area_ended_at,
    per.sort
FROM
(
    SELECT
        COUNT(*) OVER(PARTITION BY run_id, area) AS num_splits,
        MIN(split_started_at) OVER(PARTITION BY run_id, area) AS area_started_at,
        MAX(split_ended_at) OVER(PARTITION BY run_id, area) AS area_ended_at,
        SUM(lrt_time) OVER(PARTITION BY run_id, area) AS area_time,
        *
    FROM doorsplit_history5_runner
) ds

INNER JOIN cfg_splits_per_area per
ON per.area = ds.area AND per.number_of_splits = ds.num_splits
ORDER BY
    per.sort,
    ds.run_id;

/* Adding the area time rank relative to when the area was done. */

DROP TABLE IF EXISTS area_history2_runner;
CREATE TABLE area_history2_runner AS
SELECT
    run_id,
    area,
    (
        SELECT
            COUNT(*)
        FROM stg_area_history1_runner sec2
        WHERE sec2.area = sec1.area
            AND sec2.run_id <= sec1.run_id
            AND sec2.area_time < sec1.area_time
    ) + 1 AS area_rank_at_that_time,
    RANK() OVER(PARTITION BY area ORDER BY area_time) AS area_rank,
    area_gold_at_that_time,
    area_time,
    area_time_fmt,
    finished_run,
    pb,
    final_lrt_time,
    final_rta_time,
    run_started_at,
    run_ended_at,
    run_duration,
    area_started_at,
    area_ended_at,
    sort
FROM stg_area_history1_runner sec1;

/* Total number of times each area has been finished and has been golded in the history. */

DROP TABLE IF EXISTS areas_finished_runner;
CREATE TABLE areas_finished_runner AS
SELECT DISTINCT
    area,
    COUNT(*) OVER(PARTITION BY area) AS times_finished,
    SUM(CASE WHEN area_rank_at_that_time = 1 THEN 1 ELSE 0 END) OVER(PARTITION BY area) AS times_golded,
    sort
FROM area_history2_runner
ORDER BY sort;

/* The average and median times for each chapter, along with well formatted versions. Also cumulative average and median times. */

DROP TABLE IF EXISTS areas_avg_med_runner;
CREATE TABLE areas_avg_med_runner AS
WITH avg_med AS
(
    SELECT
        area,
        AVG(area_time) AS area_time_avg,
        LTRIM(TO_CHAR(AVG(area_time), 'HH24:MI:SS.FF3'), '0:') AS area_time_avg_fmt,
        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY area_time) AS area_time_med,
        LTRIM(TO_CHAR(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY area_time), 'HH24:MI:SS.FF3'), '0:') AS area_time_med_fmt,
        sort
    FROM area_history2_runner
    GROUP BY
        area, sort
),
avg_med_cumulative AS
(
    SELECT
        area,
        area_time_avg,
        area_time_avg_fmt,
        SUM(area_time_avg) OVER (ORDER BY sort) AS sum_of_avg,
        area_time_med,
        area_time_med_fmt,
        SUM(area_time_med) OVER (ORDER BY sort) AS sum_of_med
    FROM avg_med
    ORDER BY sort
)

SELECT
    area,
    area_time_avg,
    area_time_avg_fmt,
    sum_of_avg,
    LTRIM(TO_CHAR(sum_of_avg, 'HH24:MI:SS.FF3'), '0:') AS sum_of_avg_fmt,
    area_time_med,
    area_time_med_fmt,
    sum_of_med,
    LTRIM(TO_CHAR(sum_of_med, 'HH24:MI:SS.FF3'), '0:') AS sum_of_med_fmt
FROM avg_med_cumulative;

/* For each individual area, we get the gold (fastest time ever on that area) with ties if there are any. */

DROP TABLE IF EXISTS stg_area_golds1_runner;
CREATE TABLE stg_area_golds1_runner AS
SELECT
    run_id,
    area,
    ROW_NUMBER(*) OVER(PARTITION BY area, area_time) AS area_time_instance,
    area_time,
    area_time_fmt,
    finished_run,
    pb,
    final_lrt_time,
    final_rta_time,
    run_started_at,
    run_ended_at,
    run_duration,
    area_started_at,
    area_ended_at,
    sort
FROM area_history2_runner
WHERE area_rank = 1
ORDER BY
    sort,
    run_id;

/* Add the cumulative sum of best by areas. */

DROP TABLE IF EXISTS area_golds2_runner;
CREATE TABLE area_golds2_runner AS
SELECT
    golds.run_id,
    golds.area,
    golds.area_time_instance,
    golds.area_time,
    golds.area_time_fmt,
    cumulative.sum_of_best,
    LTRIM(TO_CHAR(cumulative.sum_of_best, 'HH24:MI:SS.FF3'), '0:') AS sum_of_best_fmt,
    golds.finished_run,
    golds.pb,
    golds.final_lrt_time,
    golds.final_rta_time,
    golds.run_started_at,
    golds.run_ended_at,
    golds.run_duration,
    golds.area_started_at,
    golds.area_ended_at
FROM stg_area_golds1_runner golds

LEFT JOIN
(
    SELECT
        area,
        SUM(area_time) OVER(ORDER BY sort) AS sum_of_best
    FROM
    (
        SELECT DISTINCT
            area,
            area_time,
            sort
        FROM stg_area_golds1_runner
    )
) cumulative
ON golds.area = cumulative.area;

/* area golds but calculated in a different way: summing up all the doorsplit golds that belong to each area. */

DROP TABLE IF EXISTS area_golds_by_doors_runner;
CREATE TABLE area_golds_by_doors_runner AS
SELECT
    area,
    area_gold_by_doors,
    LTRIM(TO_CHAR(area_gold_by_doors, 'HH24:MI:SS.FF3'), '0:') AS area_gold_by_doors_fmt,
    SUM(area_gold_by_doors) OVER(ORDER BY sort) AS sum_of_best,
    LTRIM(TO_CHAR(SUM(area_gold_by_doors) OVER(ORDER BY sort), 'HH24:MI:SS.FF3'), '0:') AS sum_of_best_fmt
FROM
(
    SELECT
        dg.area,
        SUM(dg.lrt_time) AS area_gold_by_doors,
        sps.sort
    FROM doorsplit_golds2_runner dg

    LEFT JOIN cfg_splits_per_area sps
    ON dg.area = sps.area

    WHERE dg.lrt_time_instance = 1
    GROUP BY
        dg.area,
        sps.sort
)
ORDER BY sort;

/* area golds but calculated in a different way: summing up all the chapter golds that belong to each area. */

DROP TABLE IF EXISTS area_golds_by_chapters_runner;
CREATE TABLE area_golds_by_chapters_runner AS
SELECT
    area,
    area_gold_by_chapters,
    LTRIM(TO_CHAR(area_gold_by_chapters, 'HH24:MI:SS.FF3'), '0:') AS area_gold_by_chapters_fmt,
    SUM(area_gold_by_chapters) OVER(ORDER BY sort) AS sum_of_best,
    LTRIM(TO_CHAR(SUM(area_gold_by_chapters) OVER(ORDER BY sort), 'HH24:MI:SS.FF3'), '0:') AS sum_of_best_fmt
FROM
(
    SELECT
        ch.area,
        SUM(ch.chapter_time) AS area_gold_by_chapters,
        sps.sort
    FROM chapter_golds2_runner ch

    LEFT JOIN cfg_splits_per_area sps
    ON ch.area = sps.area

    WHERE ch.chapter_time_instance = 1
    GROUP BY
        ch.area,
        sps.sort
)
ORDER BY sort;

--#endregion

--#region PACES

/* History of all paces of all runs, for as long as each run lasted. The pace is simply the cumulative sum of the LRT/RTA time split per split. */

DROP TABLE IF EXISTS stg_pace_history1_runner;
CREATE TABLE stg_pace_history1_runner AS
SELECT
    run_id,
    split_index,
    split_name,
    chapter,
    area,
    SUM(lrt_time) OVER(PARTITION BY run_id ORDER BY split_index) AS lrt_pace,
    SUM(rta_time) OVER(PARTITION BY run_id ORDER BY split_index) AS rta_pace
FROM doorsplit_history5_runner
ORDER BY
    run_id,
    split_index;

/* Add the overall rank of each pace from the history relative to that split, and also the relative pace rank relative to when that pace was obtained. Also add readable LRT and RTA pace. */

DROP TABLE IF EXISTS pace_history2_runner;
CREATE TABLE pace_history2_runner AS
SELECT
    run_id,
    split_index,
    split_name,
    chapter,
    area,
    (
        SELECT
            COUNT(*)
        FROM stg_pace_history1_runner p2
        WHERE p2.split_index = p1.split_index
            AND p2.run_id <= p1.run_id
            AND p2.lrt_pace < p1.lrt_pace
    ) + 1 AS pace_rank_at_that_time,
    RANK() OVER(PARTITION BY split_index ORDER BY lrt_pace) AS pace_rank,
    MIN(lrt_pace) OVER(PARTITION BY split_index ORDER BY run_id) AS best_pace_at_that_time,
    lrt_pace,
    LTRIM(TO_CHAR(lrt_pace, 'HH24:MI:SS.FF3'), '0:') AS lrt_pace_fmt,
    rta_pace,
    LTRIM(TO_CHAR(rta_pace, 'HH24:MI:SS.FF3'), '0:') AS rta_pace_fmt
FROM stg_pace_history1_runner p1
ORDER BY
    run_id,
    split_index;

/* Best overall pace for each split. */

DROP TABLE IF EXISTS paces_best_runner;
CREATE TABLE paces_best_runner AS
SELECT
    run_id,
    split_index,
    split_name,
    chapter,
    area,
    lrt_pace,
    lrt_pace_fmt,
    rta_pace,
    rta_pace_fmt
FROM pace_history2_runner
WHERE pace_rank = 1
ORDER BY split_index;

/* The average and median paces for each doorsplit, along with well formatted versions. */

DROP TABLE IF EXISTS paces_avg_med_runner;
CREATE TABLE paces_avg_med_runner AS
SELECT
    split_index,
    split_name,
    chapter,
    area,
    AVG(lrt_pace) AS lrt_pace_avg,
    LTRIM(TO_CHAR(AVG(lrt_pace), 'HH24:MI:SS.FF3'), '0:') AS lrt_pace_avg_fmt,
    PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY lrt_pace) AS lrt_pace_med,
    LTRIM(TO_CHAR(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY lrt_pace), 'HH24:MI:SS.FF3'), '0:') AS lrt_pace_med_fmt
FROM pace_history2_runner
GROUP BY
    split_index,
    split_name,
    chapter,
    area;

--#endregion

--#region RESETS

/* For each doorsplit, get:

- The total number of times it was finished
- The total number of resets: this is the number of times we started the split but didn't finish it. It is obtained by doing:
    'number of times we finished the previous split' - 'number of times we finished the current split'.

    except for the very first split where we do:

    'total attempts' - 'number of times we finished the first split'.
- The total attempts overall.
*/

DROP TABLE IF EXISTS stg_resets1_runner;
CREATE TABLE stg_resets1_runner AS
SELECT
    split_index,
    split_name,
    chapter,
    area,
    times_finished,
    LAG(times_finished) OVER () AS times_finished_prev,
    COALESCE(LAG(times_finished) OVER () - times_finished, total_attempts - times_finished) AS times_reset,
    attempts.total_attempts
FROM doorsplits_finished_runner

CROSS JOIN
(
    SELECT
        COUNT(*) AS total_attempts
    FROM attempts_data5_runner
) attempts;

/* Getting the percentage of times we reset on each doorsplit. */

DROP TABLE IF EXISTS resets2_runner;
CREATE TABLE resets2_runner AS
SELECT
    split_index,
    split_name,
    chapter,
    area,
    times_finished,
    times_reset,
    ROUND((times_reset * 100.0) / COALESCE(times_finished_prev,  times_reset + times_finished), 4) AS percentage_reset,
    total_attempts
FROM stg_resets1_runner;

--#endregion

--#region RNG

/* Categorize the times obtained in certain splits into different RNG patterns. */

DROP TABLE IF EXISTS rng_patterns_categories_runner;
CREATE TABLE rng_patterns_categories_runner AS
SELECT
    run_id,
    MAX(CASE WHEN pattern_type = 'Del Lago' THEN pattern_name END) AS lago_pattern,
    MAX(CASE WHEN pattern_type = 'Cabin' THEN pattern_name END) AS cabin_pattern,
    MAX(CASE WHEN pattern_type = 'Mendez' THEN pattern_name END) AS mendez_pattern,
    MAX(CASE WHEN pattern_type = 'Water Hall' THEN pattern_name END) AS water_hall_pattern,
    MAX(CASE WHEN pattern_type = 'Novis 1' THEN pattern_name END) AS novis1_pattern,
    MAX(CASE WHEN pattern_type = 'Gallery' THEN pattern_name END) AS gallery_pattern,
    MAX(CASE WHEN pattern_type = 'Novis 2' THEN pattern_name END) AS novis2_pattern,
    MAX(CASE WHEN pattern_type = 'Catapult' THEN pattern_name END) AS catapult_pattern,
    MAX(CASE WHEN pattern_type = 'Novis 3' THEN pattern_name END) AS novis3_pattern,
    MAX(CASE WHEN pattern_type = 'U3' THEN pattern_name END) AS u3_pattern,
    MAX(CASE WHEN pattern_type = 'Krauser' THEN pattern_name END) AS krauser_pattern,
    MAX(CASE WHEN pattern_type = 'War Room' THEN pattern_name END) AS war_room_pattern,
    MAX(CASE WHEN pattern_type = 'Key Card' THEN pattern_name END) AS key_card_pattern
FROM
(
    SELECT
        dh.run_id,
        rules.pattern_type,
        rules.pattern_name
    FROM doorsplit_history5_runner dh

    INNER JOIN cfg_rng_pattern_rules rules
    ON dh.split_index = rules.split_index
    AND dh.lrt_time BETWEEN rules.min_time AND rules.max_time
    WHERE dh.split_index IN(SELECT DISTINCT split_index FROM cfg_rng_pattern_rules) OR dh.split_index_reset = 13

    UNION ALL

    -- Special case for lago pattern with early dive (split 13 reset)
    SELECT
        dh.run_id,
        'Del Lago' AS pattern_type,
        '3. Early Dive' AS pattern_name
    FROM doorsplit_history5_runner dh
    WHERE dh.split_index = 13 AND dh.split_index_reset = 14 AND dh.split_reset_duration >= '56'::INTERVAL -- Could be 59 for some runners
) patterns
GROUP BY run_id
ORDER BY run_id;

/* Get the percentage of each RNG pattern for the categorized RNG patterns, as well as the maximum instances in a row for each. */

DROP TABLE IF EXISTS rng_patterns_stats_runner;
CREATE TABLE rng_patterns_stats_runner AS
SELECT
    cfg.pattern_type,
    cfg.pattern_name,
    COALESCE(rng_stats.pattern_instances, 0) AS pattern_instances,
    SUM(rng_stats.pattern_instances) OVER(PARTITION BY cfg.pattern_type)::INT AS pattern_total,
    COALESCE(ROUND(rng_stats.pattern_instances * 100.0 / SUM(rng_stats.pattern_instances) OVER(PARTITION BY cfg.pattern_type), 6), 0) AS pattern_percentage,
    COALESCE(max_patterns_in_a_row, 0) AS max_patterns_in_a_row
FROM cfg_rng_pattern_rules cfg

LEFT JOIN
(
    SELECT
        lago_pattern AS pattern,
        pattern_instances,
        MAX(current_consecutive_count) AS max_patterns_in_a_row
    FROM
    (
        SELECT
            lago_pattern,
            pattern_instances,
            COUNT(*) AS current_consecutive_count
        FROM
        (
            SELECT
                run_id,
                lago_pattern,
                COUNT(*) OVER(PARTITION BY lago_pattern) AS pattern_instances,
                ROW_NUMBER() OVER (ORDER BY run_id) AS rn_overall,
                ROW_NUMBER() OVER (PARTITION BY lago_pattern ORDER BY run_id) AS rn_by_pattern
            FROM rng_patterns_categories_runner
        )
        GROUP BY
            lago_pattern,
            (rn_overall - rn_by_pattern),
            pattern_instances
    )
    GROUP BY lago_pattern, pattern_instances

    UNION

    SELECT
        cabin_pattern AS pattern,
        pattern_instances,
        MAX(current_consecutive_count) AS max_patterns_in_a_row
    FROM
    (
        SELECT
            cabin_pattern,
            pattern_instances,
            COUNT(*) AS current_consecutive_count
        FROM
        (
            SELECT
                run_id,
                cabin_pattern,
                COUNT(*) OVER(PARTITION BY cabin_pattern) AS pattern_instances,
                ROW_NUMBER() OVER (ORDER BY run_id) AS rn_overall,
                ROW_NUMBER() OVER (PARTITION BY cabin_pattern ORDER BY run_id) AS rn_by_pattern
            FROM rng_patterns_categories_runner
        )
        GROUP BY
            cabin_pattern,
            (rn_overall - rn_by_pattern),
            pattern_instances
    )
    GROUP BY cabin_pattern, pattern_instances

    UNION

    SELECT
        mendez_pattern AS pattern,
        pattern_instances,
        MAX(current_consecutive_count) AS max_patterns_in_a_row
    FROM
    (
        SELECT
            mendez_pattern,
            pattern_instances,
            COUNT(*) AS current_consecutive_count
        FROM
        (
            SELECT
                run_id,
                mendez_pattern,
                COUNT(*) OVER(PARTITION BY mendez_pattern) AS pattern_instances,
                ROW_NUMBER() OVER (ORDER BY run_id) AS rn_overall,
                ROW_NUMBER() OVER (PARTITION BY mendez_pattern ORDER BY run_id) AS rn_by_pattern
            FROM rng_patterns_categories_runner
        )
        GROUP BY
            mendez_pattern,
            (rn_overall - rn_by_pattern),
            pattern_instances
    )
    GROUP BY mendez_pattern, pattern_instances

    UNION

    SELECT
        water_hall_pattern AS pattern,
        pattern_instances,
        MAX(current_consecutive_count) AS max_patterns_in_a_row
    FROM
    (
        SELECT
            water_hall_pattern,
            pattern_instances,
            COUNT(*) AS current_consecutive_count
        FROM
        (
            SELECT
                run_id,
                water_hall_pattern,
                COUNT(*) OVER(PARTITION BY water_hall_pattern) AS pattern_instances,
                ROW_NUMBER() OVER (ORDER BY run_id) AS rn_overall,
                ROW_NUMBER() OVER (PARTITION BY water_hall_pattern ORDER BY run_id) AS rn_by_pattern
            FROM rng_patterns_categories_runner
        )
        GROUP BY
            water_hall_pattern,
            (rn_overall - rn_by_pattern),
            pattern_instances
    )
    GROUP BY water_hall_pattern, pattern_instances

    UNION

    SELECT
        novis1_pattern AS pattern,
        pattern_instances,
        MAX(current_consecutive_count) AS max_patterns_in_a_row
    FROM
    (
        SELECT
            novis1_pattern,
            pattern_instances,
            COUNT(*) AS current_consecutive_count
        FROM
        (
            SELECT
                run_id,
                novis1_pattern,
                COUNT(*) OVER(PARTITION BY novis1_pattern) AS pattern_instances,
                ROW_NUMBER() OVER (ORDER BY run_id) AS rn_overall,
                ROW_NUMBER() OVER (PARTITION BY novis1_pattern ORDER BY run_id) AS rn_by_pattern
            FROM rng_patterns_categories_runner
        )
        GROUP BY
            novis1_pattern,
            (rn_overall - rn_by_pattern),
            pattern_instances
    )
    GROUP BY novis1_pattern, pattern_instances

    UNION

    SELECT
        gallery_pattern AS pattern,
        pattern_instances,
        MAX(current_consecutive_count) AS max_patterns_in_a_row
    FROM
    (
        SELECT
            gallery_pattern,
            pattern_instances,
            COUNT(*) AS current_consecutive_count
        FROM
        (
            SELECT
                run_id,
                gallery_pattern,
                COUNT(*) OVER(PARTITION BY gallery_pattern) AS pattern_instances,
                ROW_NUMBER() OVER (ORDER BY run_id) AS rn_overall,
                ROW_NUMBER() OVER (PARTITION BY gallery_pattern ORDER BY run_id) AS rn_by_pattern
            FROM rng_patterns_categories_runner
        )
        GROUP BY
            gallery_pattern,
            (rn_overall - rn_by_pattern),
            pattern_instances
    )
    GROUP BY gallery_pattern, pattern_instances

    UNION

    SELECT
        novis2_pattern AS pattern,
        pattern_instances,
        MAX(current_consecutive_count) AS max_patterns_in_a_row
    FROM
    (
        SELECT
            novis2_pattern,
            pattern_instances,
            COUNT(*) AS current_consecutive_count
        FROM
        (
            SELECT
                run_id,
                novis2_pattern,
                COUNT(*) OVER(PARTITION BY novis2_pattern) AS pattern_instances,
                ROW_NUMBER() OVER (ORDER BY run_id) AS rn_overall,
                ROW_NUMBER() OVER (PARTITION BY novis2_pattern ORDER BY run_id) AS rn_by_pattern
            FROM rng_patterns_categories_runner
        )
        GROUP BY
            novis2_pattern,
            (rn_overall - rn_by_pattern),
            pattern_instances
    )
    GROUP BY novis2_pattern, pattern_instances

    UNION

    SELECT
        catapult_pattern AS pattern,
        pattern_instances,
        MAX(current_consecutive_count) AS max_patterns_in_a_row
    FROM
    (
        SELECT
            catapult_pattern,
            pattern_instances,
            COUNT(*) AS current_consecutive_count
        FROM
        (
            SELECT
                run_id,
                catapult_pattern,
                COUNT(*) OVER(PARTITION BY catapult_pattern) AS pattern_instances,
                ROW_NUMBER() OVER (ORDER BY run_id) AS rn_overall,
                ROW_NUMBER() OVER (PARTITION BY catapult_pattern ORDER BY run_id) AS rn_by_pattern
            FROM rng_patterns_categories_runner
        )
        GROUP BY
            catapult_pattern,
            (rn_overall - rn_by_pattern),
            pattern_instances
    )
    GROUP BY catapult_pattern, pattern_instances

    UNION

    SELECT
        novis3_pattern AS pattern,
        pattern_instances,
        MAX(current_consecutive_count) AS max_patterns_in_a_row
    FROM
    (
        SELECT
            novis3_pattern,
            pattern_instances,
            COUNT(*) AS current_consecutive_count
        FROM
        (
            SELECT
                run_id,
                novis3_pattern,
                COUNT(*) OVER(PARTITION BY novis3_pattern) AS pattern_instances,
                ROW_NUMBER() OVER (ORDER BY run_id) AS rn_overall,
                ROW_NUMBER() OVER (PARTITION BY novis3_pattern ORDER BY run_id) AS rn_by_pattern
            FROM rng_patterns_categories_runner
        )
        GROUP BY
            novis3_pattern,
            (rn_overall - rn_by_pattern),
            pattern_instances
    )
    GROUP BY novis3_pattern, pattern_instances

    UNION

    SELECT
        u3_pattern AS pattern,
        pattern_instances,
        MAX(current_consecutive_count) AS max_patterns_in_a_row
    FROM
    (
        SELECT
            u3_pattern,
            pattern_instances,
            COUNT(*) AS current_consecutive_count
        FROM
        (
            SELECT
                run_id,
                u3_pattern,
                COUNT(*) OVER(PARTITION BY u3_pattern) AS pattern_instances,
                ROW_NUMBER() OVER (ORDER BY run_id) AS rn_overall,
                ROW_NUMBER() OVER (PARTITION BY u3_pattern ORDER BY run_id) AS rn_by_pattern
            FROM rng_patterns_categories_runner
        )
        GROUP BY
            u3_pattern,
            (rn_overall - rn_by_pattern),
            pattern_instances
    )
    GROUP BY u3_pattern, pattern_instances

    UNION

    SELECT
        krauser_pattern AS pattern,
        pattern_instances,
        MAX(current_consecutive_count) AS max_patterns_in_a_row
    FROM
    (
        SELECT
            krauser_pattern,
            pattern_instances,
            COUNT(*) AS current_consecutive_count
        FROM
        (
            SELECT
                run_id,
                krauser_pattern,
                COUNT(*) OVER(PARTITION BY krauser_pattern) AS pattern_instances,
                ROW_NUMBER() OVER (ORDER BY run_id) AS rn_overall,
                ROW_NUMBER() OVER (PARTITION BY krauser_pattern ORDER BY run_id) AS rn_by_pattern
            FROM rng_patterns_categories_runner
        )
        GROUP BY
            krauser_pattern,
            (rn_overall - rn_by_pattern),
            pattern_instances
    )
    GROUP BY krauser_pattern, pattern_instances

    UNION

    SELECT
        war_room_pattern AS pattern,
        pattern_instances,
        MAX(current_consecutive_count) AS max_patterns_in_a_row
    FROM
    (
        SELECT
            war_room_pattern,
            pattern_instances,
            COUNT(*) AS current_consecutive_count
        FROM
        (
            SELECT
                run_id,
                war_room_pattern,
                COUNT(*) OVER(PARTITION BY war_room_pattern) AS pattern_instances,
                ROW_NUMBER() OVER (ORDER BY run_id) AS rn_overall,
                ROW_NUMBER() OVER (PARTITION BY war_room_pattern ORDER BY run_id) AS rn_by_pattern
            FROM rng_patterns_categories_runner
        )
        GROUP BY
            war_room_pattern,
            (rn_overall - rn_by_pattern),
            pattern_instances
    )
    GROUP BY war_room_pattern, pattern_instances

    UNION

    SELECT
        key_card_pattern AS pattern,
        pattern_instances,
        MAX(current_consecutive_count) AS max_patterns_in_a_row
    FROM
    (
        SELECT
            key_card_pattern,
            pattern_instances,
            COUNT(*) AS current_consecutive_count
        FROM
        (
            SELECT
                run_id,
                key_card_pattern,
                COUNT(*) OVER(PARTITION BY key_card_pattern) AS pattern_instances,
                ROW_NUMBER() OVER (ORDER BY run_id) AS rn_overall,
                ROW_NUMBER() OVER (PARTITION BY key_card_pattern ORDER BY run_id) AS rn_by_pattern
            FROM rng_patterns_categories_runner
        )
        GROUP BY
            key_card_pattern,
            (rn_overall - rn_by_pattern),
            pattern_instances
    )
    GROUP BY key_card_pattern, pattern_instances
) rng_stats
ON cfg.pattern_name = rng_stats.pattern
ORDER BY
    cfg.split_index,
    cfg.pattern_name;

--#endregion

--#region MAIN TABLE

/* Final main table that has everything */

DROP TABLE IF EXISTS splits_overview_runner;
CREATE TABLE splits_overview_runner AS
SELECT
    dsh.run_id,
    dsh.split_index,
    dsh.split_name,
    dsh.chapter,
    dsh.area,
    dsh.doorsplit_rank_at_that_time,
    dsh.doorsplit_rank_at_that_time = 1 AS golded_doorsplit,
    dsh.doorsplit_rank,
    dsh.doorsplit_gold_at_that_time,
    dsh.lrt_time,
    dsh.lrt_time_fmt,
    dsh.rta_time,
    dsh.rta_time_fmt,
    dsh.finished_run,
    dsh.pb,
    dsh.final_lrt_time,
    dsh.final_rta_time,
    dsh.run_started_on_weekday,
    dsh.run_started_at,
    dsh.run_ended_at,
    dsh.run_duration,
    dsh.split_started_at,
    dsh.split_ended_at,
    dsh.split_index_reset,
    dsh.split_name_reset,
    dsh.split_reset_duration,

    ph.pace_rank_at_that_time,
    ph.pace_rank_at_that_time = 1 AS was_best_pace,
    ph.pace_rank,
    ph.best_pace_at_that_time,
    ph.lrt_pace,
    ph.lrt_pace_fmt,
    ph.rta_pace,
    ph.rta_pace_fmt,

    bp.lrt_pace AS best_pace,
    bp.lrt_pace_fmt AS best_pace_fmt,

    dsg.lrt_time AS ds_gold,
    dsg.lrt_time_fmt AS ds_gold_fmt,
    dsg.cumulative_door_gold AS ds_sum_of_best,

    ch.chapter_rank_at_that_time,
    ch.chapter_rank_at_that_time = 1 AS golded_chapter,
    ch.chapter_rank,
    ch.chapter_gold_at_that_time,
    ch.chapter_time,
    ch.chapter_time_fmt,
    ch.chapter_started_at,
    ch.chapter_ended_at,

    sh.area_rank_at_that_time,
    sh.area_rank_at_that_time = 1 AS golded_area,
    sh.area_rank,
    sh.area_gold_at_that_time,
    sh.area_time,
    sh.area_time_fmt,
    sh.area_started_at,
    sh.area_ended_at,

    cg.chapter_time AS chapter_gold,
    cg.chapter_time_fmt AS chapter_gold_fmt,
    cg.sum_of_best AS chapter_sum_of_best,
    cg.sum_of_best_fmt AS chapter_sum_of_best_fmt,

    sg.area_time AS area_gold,
    sg.area_time_fmt AS area_gold_fmt,
    sg.sum_of_best AS area_sum_of_best,
    sg.sum_of_best_fmt AS area_sum_of_best_fmt,

    pbh.lrt_pb,
    pbh.days_it_took,
    pbh.attempts_it_took,
    pbh.total_playtime_it_took,
    pbh.days_of_attempts_it_took,

    dsam.lrt_time_avg AS ds_time_avg,
    dsam.lrt_time_avg_fmt AS ds_time_avg_fmt,
    dsam.sum_of_avg AS ds_sum_of_avg,
    dsam.sum_of_avg_fmt AS ds_sum_of_avg_fmt,
    dsam.lrt_time_med AS ds_time_med,
    dsam.lrt_time_med_fmt AS ds_time_med_fmt,
    dsam.sum_of_med AS ds_sum_of_med,
    dsam.sum_of_med_fmt AS ds_sum_of_med_fmt,

    pam.lrt_pace_avg AS pace_avg,
    pam.lrt_pace_avg_fmt AS pace_avg_fmt,
    pam.lrt_pace_med AS pace_med,
    pam.lrt_pace_med_fmt AS pace_med_fmt,

    cam.chapter_time_avg,
    cam.chapter_time_avg_fmt,
    cam.sum_of_avg AS chapter_sum_of_avg,
    cam.sum_of_avg_fmt AS chapter_sum_of_avg_fmt,
    cam.chapter_time_med,
    cam.chapter_time_med_fmt,
    cam.sum_of_med AS chapter_sum_of_med,
    cam.sum_of_med_fmt AS chapter_sum_of_med_fmt,

    sam.area_time_avg,
    sam.area_time_avg_fmt,
    sam.sum_of_avg AS area_sum_of_avg,
    sam.sum_of_avg_fmt AS area_sum_of_avg_fmt,
    sam.area_time_med,
    sam.area_time_med_fmt,
    sam.sum_of_med AS area_sum_of_med,
    sam.sum_of_med_fmt AS area_sum_of_med_fmt,

    fds.times_finished AS ds_times_finished,
    fds.times_golded AS ds_times_golded,

    fc.times_finished AS chapter_times_finished,
    fc.times_golded AS chapter_times_golded,

    fs.times_finished AS area_times_finished,
    fs.times_golded AS area_times_golded,

    rpc.lago_pattern,
    rpc.cabin_pattern,
    rpc.mendez_pattern,
    rpc.water_hall_pattern,
    rpc.novis1_pattern,
    rpc.gallery_pattern,
    rpc.novis2_pattern,
    rpc.catapult_pattern,
    rpc.novis3_pattern,
    rpc.u3_pattern,
    rpc.krauser_pattern,
    rpc.war_room_pattern,
    rpc.key_card_pattern,

    'runner' AS runner_name
    -- Not sure if this is necessary: ROW_NUMBER() OVER (PARTITION BY a.run_id, a.split_index ORDER BY id2 DESC) AS rang

FROM doorsplit_history5_runner dsh

LEFT JOIN pace_history2_runner ph
ON dsh.run_id = ph.run_id AND dsh.split_index = ph.split_index

LEFT JOIN paces_best_runner bp
ON dsh.split_index = bp.split_index

LEFT JOIN
(
    SELECT
        split_index,
        lrt_time_fmt,
        lrt_time,
        MIN(sum_of_best) AS cumulative_door_gold
    FROM doorsplit_golds2_runner
    GROUP BY
        split_index,
        lrt_time_fmt,
        lrt_time
) dsg
ON dsh.split_index = dsg.split_index

LEFT JOIN chapter_history2_runner ch
ON dsh.run_id = ch.run_id AND dsh.chapter = ch.chapter

LEFT JOIN area_history2_runner sh
ON dsh.run_id = sh.run_id AND dsh.area = sh.area

LEFT JOIN chapter_golds2_runner cg
ON dsh.chapter = cg.chapter

LEFT JOIN area_golds2_runner sg
ON dsh.area = sg.area

LEFT JOIN finished_runs_runner fr
ON dsh.run_id = fr.run_id

LEFT JOIN pb_history_runner pbh
ON dsh.run_id = pbh.run_id

LEFT JOIN doorsplits_avg_med_runner dsam
ON dsh.split_index = dsam.split_index

LEFT JOIN paces_avg_med_runner pam
ON dsh.split_index = pam.split_index

LEFT JOIN chapters_avg_med_runner cam
ON dsh.chapter = cam.chapter

LEFT JOIN areas_avg_med_runner sam
ON dsh.area = sam.area

LEFT JOIN doorsplits_finished_runner fds
ON dsh.split_index = fds.split_index

LEFT JOIN chapters_finished_runner fc
ON dsh.chapter = fc.chapter

LEFT JOIN areas_finished_runner fs
ON dsh.area = fs.area

LEFT JOIN rng_patterns_categories_runner rpc
ON dsh.run_id = rpc.run_id

ORDER BY
    run_id,
    split_index;

--#endregion

--#region USEFUL QUERIES

/* Basic stats: latest date in which the splits were updated, the PB, the total number of attempts, and the total playtime in 'X days HH:MM:SS' format. */

DROP TABLE IF EXISTS general_stats_runner;
CREATE TABLE general_stats_runner AS
SELECT
    att.last_update,
    pbs.lrt_pb AS pb,
    att.attempts,
    JUSTIFY_DAYS(JUSTIFY_HOURS(att.total_playtime))::TEXT AS total_playtime
FROM
(
    SELECT
        DATE(MAX(run_ended_at)) AS last_update,
        COUNT(*) AS attempts,
        SUM(run_duration) AS total_playtime
    FROM attempts_data5_runner
) att

CROSS JOIN
(
    SELECT
        LTRIM(TO_CHAR(lrt_pb::INTERVAL, 'HH24:MI:SS.FF3'), '0:') AS lrt_pb
    FROM pb_history_runner
    ORDER BY run_id DESC
    LIMIT 1
) pbs;

/* Checking if a doorsplit gold was done on a bad run (gold hunt) by checking the delta between the pace of that run and the best pace for each split. */

DROP TABLE IF EXISTS gold_hunt_detector_runner;
CREATE TABLE gold_hunt_detector_runner AS
SELECT
    run_id,
    split_index,
    split_name,
    lrt_time AS ds_gold,
    lrt_time_fmt AS ds_gold_fmt,
    run_started_at,
    split_started_at,
    final_lrt_time,
    lrt_pace AS pace,
    best_pace,
    best_pace_delta
FROM
(
    SELECT
        dg.run_id,
        dg.split_index,
        dg.split_name,
        dg.lrt_time,
        dg.lrt_time_fmt,
        dg.run_started_at,
        dg.split_started_at,
        dg.final_lrt_time,
        ph.lrt_pace,
        bp.lrt_pace AS best_pace,
        ph.lrt_pace - bp.lrt_pace AS best_pace_delta,
        ROW_NUMBER () OVER (PARTITION BY dg.split_index ORDER BY ph.lrt_pace - bp.lrt_pace) AS ds_gold_instance
    FROM doorsplit_golds2_runner dg

    LEFT JOIN pace_history2_runner ph
    ON dg.run_id = ph.run_id AND dg.split_index = ph.split_index

    LEFT JOIN paces_best_runner bp
    ON dg.split_index = bp.split_index
)
WHERE ds_gold_instance = 1
ORDER BY split_index;

/* Getting the history of achievements by the day of the week. */

DROP TABLE IF EXISTS weekday_stats_runner;
CREATE TABLE weekday_stats_runner AS
SELECT
    pbs.iso_weekday,
    TO_CHAR(DATE '2000-01-03' + (pbs.iso_weekday - 1) * INTERVAL '1 day', 'Day') AS weekday_fmt,
    pbs.playtime,
    pbs.attempts,
    pbs.number_of_pbs,
    pbs.pb_ratio,
    attempts /
        CASE
            WHEN number_of_pbs = 0 THEN
                NULL
            ELSE
                number_of_pbs
        END AS attempts_to_get_a_pb,
    pbs.playtime_to_get_a_pb,

    golds.doorsplit_golds,
    golds.chapter_golds,
    golds.area_golds,
    golds.best_paces,

    ROUND(golds.doorsplit_golds * 100.0 / attempts, 4) AS doorsplit_golds_ratio,
    ROUND(golds.chapter_golds * 100.0 / attempts, 4) AS chapter_golds_ratio,
    ROUND(golds.area_golds * 100.0 / attempts, 4) AS area_golds_ratio,
    ROUND(golds.best_paces * 100.0 / attempts, 4) AS best_paces_ratio,

    ROUND(attempts / CASE WHEN golds.doorsplit_golds = 0 THEN NULL ELSE golds.doorsplit_golds::DECIMAL END, 4) AS attempts_to_get_a_doorsplit_gold,
    ROUND(attempts / CASE WHEN golds.chapter_golds = 0 THEN NULL ELSE golds.chapter_golds::DECIMAL END, 4) AS attempts_to_get_a_chapter_gold,
    ROUND(attempts / CASE WHEN golds.area_golds = 0 THEN NULL ELSE golds.area_golds::DECIMAL END, 4) AS attempts_to_get_a_area_gold,
    ROUND(attempts / CASE WHEN golds.best_paces = 0 THEN NULL ELSE golds.best_paces::DECIMAL END, 4) AS attempts_to_get_a_best_pace,

    playtime / CASE WHEN golds.doorsplit_golds = 0 THEN NULL ELSE golds.doorsplit_golds END AS playtime_to_get_a_doorsplit_gold,
    playtime / CASE WHEN golds.chapter_golds = 0 THEN NULL ELSE golds.chapter_golds END AS playtime_to_get_a_chapter_gold,
    playtime / CASE WHEN golds.area_golds = 0 THEN NULL ELSE golds.area_golds END AS playtime_to_get_a_area_gold,
    playtime / CASE WHEN golds.best_paces = 0 THEN NULL ELSE golds.best_paces END AS playtime_to_get_a_best_pace
FROM
(
    SELECT
        EXTRACT(ISODOW FROM run_started_at) AS iso_weekday,
        SUM(run_duration) AS playtime,
        COUNT(DISTINCT run_id) AS attempts,
        COUNT(DISTINCT CASE WHEN pb THEN run_id ELSE NULL END) AS number_of_pbs,
        ROUND(COUNT(DISTINCT CASE WHEN pb THEN run_id ELSE NULL END) * 100.0 / COUNT(DISTINCT run_id), 4) AS pb_ratio,
        SUM(run_duration) /
            CASE
                WHEN ROUND(COUNT(DISTINCT CASE WHEN pb THEN run_id ELSE NULL END)) = 0 THEN
                    NULL
                ELSE
                    ROUND(COUNT(DISTINCT CASE WHEN pb THEN run_id ELSE NULL END))
            END playtime_to_get_a_pb
    FROM attempts_data5_runner
    GROUP BY iso_weekday
) pbs

LEFT JOIN
(
    SELECT
        run_started_on_weekday,
        SUM(golded_doorsplit::INT) AS doorsplit_golds,
        SUM(golded_chapter::INT) AS chapter_golds,
        SUM(golded_area::INT) AS area_golds,
        SUM(was_best_pace::INT) AS best_paces
    FROM splits_overview_runner
    GROUP BY run_started_on_weekday
) golds
ON pbs.iso_weekday = golds.run_started_on_weekday
ORDER BY pbs.iso_weekday;

--#endregion