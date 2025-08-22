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
        WHEN run_id = ''
            THEN 0
        ELSE run_id::INT
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
        WHEN run_id_int = 0
            THEN ''
        WHEN run_id_int < 0
            THEN lrt_time_negative_run_id
        ELSE lrt_time_normal
    END AS lrt_time,
    CASE
        WHEN run_id_int <= 0
            THEN ''
        ELSE rta_time_normal
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
        WHEN lrt_time = '' THEN ''
        ELSE splits.split_name
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
                            ELSE splits.ends_at_row
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

/* Also adding the LRT time with the same format as in LiveSplit (Edit Splits window), not used for calculations but it's nicer to read. */

DROP TABLE IF EXISTS segments_data7_runner;
CREATE TABLE segments_data7_runner AS
SELECT
    run_id,
    split_number,
    split_name,
    chapter,
    _section,
    lrt_time,
    LTRIM(lrt_time::TEXT, '0:') AS lrt_time_formatted,
    rta_time,
    LTRIM(rta_time::TEXT, '0:') AS rta_time_formatted,
    file_line_stripped,
    line_number
FROM segments_data6_runner;

/* Adding padding on the decimals for LRT (.000, .X00 or .XX0). */

DROP TABLE IF EXISTS segments_data8_runner;
CREATE TABLE segments_data8_runner AS
SELECT
    run_id,
    split_number,
    split_name,
    chapter,
    _section,
    lrt_time,
    CASE
        WHEN lrt_time_formatted NOT LIKE '%.%' THEN
            lrt_time_formatted || '.000'
        WHEN LENGTH(SUBSTRING(lrt_time_formatted, STRPOS(lrt_time_formatted, '.') + 1)) = 1 THEN
            lrt_time_formatted || '00'
        WHEN LENGTH(SUBSTRING(lrt_time_formatted, STRPOS(lrt_time_formatted, '.') + 1)) = 2 THEN
            lrt_time_formatted || '0'
        ELSE
            lrt_time_formatted
    END AS lrt_time_formatted,
    rta_time,
    rta_time_formatted,
    file_line_stripped,
    line_number
FROM segments_data7_runner;

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

/* Main table that will be used to get the interesting stats (chapter golds, section golds, best paces, etc). We combine the attempts data with the segments data and we also convert the dates of the runs into date objects. */

DROP TABLE IF EXISTS splits_overview1_runner;
CREATE TABLE splits_overview1_runner AS
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
FROM segments_data8_runner segments
LEFT JOIN attempts_data5_runner attempts
ON segments.run_id = attempts.run_id;

/* Getting the cumulative RTA for each run_id, split by split, for as long as that run went (obviously some runs last until split 1, others split 2, others split 8, others until the end, etc). */

DROP TABLE IF EXISTS cumulative_rta_runner;
CREATE TABLE cumulative_rta_runner AS
SELECT
    overview.run_id,
    overview.split_number,
    SUM(durations.rta_time) AS run_cumulative_rta
FROM splits_overview1_runner overview

LEFT JOIN
(
    SELECT DISTINCT
        run_id,
        split_number,
        rta_time
    FROM splits_overview1_runner
) durations
ON overview.split_number >= durations.split_number AND overview.run_id = durations.run_id
GROUP BY overview.run_id, overview.split_number
ORDER BY overview.run_id, overview.split_number;

/* ??? */

DROP TABLE IF EXISTS splits_overview2_runner;
CREATE TABLE splits_overview2_runner AS
SELECT
    overview.run_id,
    overview.split_number,
    overview.split_name,
    overview.chapter,
    overview._section,
    overview.lrt_time,
    overview.lrt_time_formatted,
    overview.rta_time,
    overview.rta_time_formatted,
    overview.finished_run,
    overview.pb,
    overview.final_lrt_time,
    overview.final_rta_time,
    overview.run_started_at,
    overview.run_ended_at,
    overview.run_duration,
    run_cumulative_rta,
    LAG(run_cumulative_rta) OVER(PARTITION BY overview.run_id ORDER BY overview.split_number) AS run_cumulative_rta_lag
FROM splits_overview1_runner overview

LEFT JOIN cumulative_rta_runner cumulative
ON overview.run_id = cumulative.run_id AND overview.split_number = cumulative.split_number;

/* ??? */

DROP TABLE IF EXISTS splits_overview3_runner;
CREATE TABLE splits_overview3_runner AS
SELECT
    run_id,
    default_split_name AS split_name,
    chapter,
    _section,
    lrt_time_dec,
    lrt_time_readable,
    date_run_started,
    finished_run,
    final_lrt_time,
    pb,
    split_number,
    final_rta_time,
    date_run_ended,
    time_run_started,
    time_run_ended,
    run_duration,
    rta_time_dec,
    rta_time_readable,
    cumulative_rta,
    lag_rta,
    time_started_numeric,
    time_ended_numeric,
    time_start_numeric2,
    time_end_numeric2,
    CASE WHEN split_number = 1 THEN time_run_started ELSE
    CASE WHEN FLOOR(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END)<10
    THEN '0'||FLOOR(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END)
    ELSE ''||FLOOR(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END) END
    ||':'||
    CASE WHEN FLOOR(60*(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END
    - FLOOR(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END)))<10
    THEN '0'||FLOOR(60*(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END
    - FLOOR(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END)))
    ELSE ''||FLOOR(60*(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END
    - FLOOR(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END))) END
    ||':'||
    CASE WHEN FLOOR(60*(60*(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END
    - FLOOR(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END))-
    FLOOR(60*(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END
    - FLOOR(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END)))))<10
    THEN '0'||FLOOR(60*(60*(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END
    - FLOOR(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END))-
    FLOOR(60*(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END
    - FLOOR(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END)))))
    ELSE ''||FLOOR(60*(60*(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END
    - FLOOR(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END))-
    FLOOR(60*(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END
    - FLOOR(CASE WHEN time_start_numeric2/3600>=24 THEN time_start_numeric2/3600-24 ELSE time_start_numeric2/3600 END))))) END END AS time_start_numeric3,
    CASE WHEN split_number = 123 THEN time_run_ended ELSE
CASE WHEN FLOOR(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END)<10
THEN '0'||FLOOR(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END)
ELSE ''||FLOOR(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END) END
||':'||
CASE WHEN FLOOR(60*(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END
- FLOOR(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END)))<10
THEN '0'||FLOOR(60*(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END
- FLOOR(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END)))
ELSE ''||FLOOR(60*(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END
- FLOOR(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END))) END
||':'||
CASE WHEN FLOOR(60*(60*(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END
- FLOOR(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END))-
FLOOR(60*(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END
- FLOOR(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END)))))<10
THEN '0'||FLOOR(60*(60*(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END
- FLOOR(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END))-
FLOOR(60*(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END
- FLOOR(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END)))))
ELSE ''||FLOOR(60*(60*(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END
- FLOOR(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END))-
FLOOR(60*(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END
- FLOOR(CASE WHEN time_end_numeric2/3600>=24 THEN time_end_numeric2/3600-24 ELSE time_end_numeric2/3600 END))))) END END AS time_end_numeric3
FROM
(
    SELECT
        overview.*,
        defaults.split_name AS default_split_name,
        CASE
            WHEN overview.split_number = 1
                THEN time_started_numeric
            WHEN time_started_numeric < 86400 AND time_started_numeric + lag_rta >= 86400
                THEN time_started_numeric + lag_rta - 86400
            ELSE time_started_numeric + lag_rta
        END AS time_start_numeric2,
        CASE
            WHEN time_started_numeric < 86400 AND time_started_numeric + cumulative_rta >= 86400
                THEN time_started_numeric + cumulative_rta - 86400
            ELSE time_started_numeric + cumulative_rta
        END AS time_end_numeric2
    FROM splits_overview2_runner overview
    LEFT JOIN default_split_names defaults
    ON overview.split_number = defaults.split_number
);

--#region DOORS

/* All golds */

DROP TABLE IF EXISTS doorsplit_golds1_runner;
CREATE TABLE doorsplit_golds1_runner AS
SELECT
    aa.*,
    bb.run_id,
    date_run_started,
    finished_run,
    final_lrt_time,
    pb,
    CASE
        WHEN gold < 10
            THEN TO_CHAR(gold, 'FM0.000')
        WHEN gold < 60
            THEN TO_CHAR(gold, 'FM00.000')
        ELSE
            FLOOR(gold / 60) || ':' || TO_CHAR(gold % 60, 'FM00.000')
    END AS gold2,
    door_avg::DECIMAL AS door_avg,
    door_median::DECIMAL AS door_median
    FROM (
SELECT split_number, split_name, MIN(split_time) AS gold
FROM(SELECT split_name, run_id, split_number, SUM(lrt_time_dec) AS split_time
FROM splits_overview3_runner
GROUP BY split_name, run_id, split_number) a
GROUP BY split_name, split_number) aa
LEFT JOIN (SELECT *
FROM(SELECT split_name, run_id, split_number, date_run_started, finished_run, final_lrt_time, pb, SUM(lrt_time_dec) AS split_time
FROM splits_overview3_runner
GROUP BY split_name, run_id, split_number, date_run_started, finished_run, final_lrt_time, pb) a) bb ON aa.gold=bb.split_time AND aa.split_number=bb.split_number
LEFT JOIN (SELECT split_number, AVG(lrt_time) AS door_avg
FROM(
SELECT a.*
FROM(
SELECT split_number, run_id, date_run_started, finished_run, final_lrt_time, pb, SUM(lrt_time_dec) AS lrt_time
FROM splits_overview3_runner
GROUP BY split_number, run_id, date_run_started, finished_run, final_lrt_time, pb) a)
GROUP BY 1
ORDER BY 1) door_avg ON door_avg.split_number=aa.split_number
LEFT JOIN (SELECT split_number, PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY lrt_time) AS door_median
FROM(
SELECT a.*
FROM(
SELECT split_number, run_id, date_run_started, finished_run, final_lrt_time, pb, SUM(lrt_time_dec) AS lrt_time
FROM splits_overview3_runner
GROUP BY split_number, run_id, date_run_started, finished_run, final_lrt_time, pb) a)
GROUP BY 1
ORDER BY 1) door_med ON door_med.split_number=aa.split_number
ORDER BY split_number;

/* ??? */

DROP TABLE IF EXISTS doorsplit_golds2_runner;
CREATE TABLE doorsplit_golds2_runner AS
SELECT
    split_number,
    run_id,
    date_run_started,
    final_lrt_time,
    pb,
    gold,
    gold2,
    door_avg,
    door_median,
    CASE
        WHEN cumulative_chapter_gold < 10
            THEN TO_CHAR(cumulative_chapter_gold, 'FM0.000')
        WHEN cumulative_chapter_gold < 60
            THEN TO_CHAR(cumulative_chapter_gold, 'FM00.000')
        WHEN cumulative_chapter_gold < 3600
            THEN FLOOR(cumulative_chapter_gold / 60) || ':' || TO_CHAR(cumulative_chapter_gold % 60, 'FM00.000')
        ELSE
            FLOOR(cumulative_chapter_gold / 3600) || ':' || FLOOR((cumulative_chapter_gold - 3600) / 60) || ':' || TO_CHAR(cumulative_chapter_gold % 60, 'FM00.000')
    END AS cumulative_door_gold,
    cumulative_chapter_gold AS cumulative_door_gold_num,
    CASE
        WHEN door_avg < 10
            THEN TO_CHAR(door_avg, 'FM0.000')
        WHEN door_avg < 60
            THEN TO_CHAR(door_avg, 'FM00.000')
        WHEN door_avg < 3600
            THEN FLOOR(door_avg / 60) || ':' || TO_CHAR(door_avg % 60, 'FM00.000')
        ELSE
            FLOOR(door_avg / 3600) || ':' || FLOOR((door_avg - 3600) / 60) || ':' || TO_CHAR(door_avg % 60, 'FM00.000')
    END AS door_avg2,
    CASE
        WHEN door_median < 10
            THEN TO_CHAR(door_median, 'FM0.000')
        WHEN door_median < 60
            THEN TO_CHAR(door_median, 'FM00.000')
        WHEN door_median < 3600
            THEN FLOOR(door_median / 60) || ':' || TO_CHAR(door_median % 60, 'FM00.000')
        ELSE
            FLOOR(door_median / 3600) || ':' || FLOOR((door_median - 3600) / 60) || ':' || TO_CHAR(door_median % 60, 'FM00.000')
    END AS door_median2
FROM(
SELECT a.split_number, a.split_name, a.gold, a.run_id, a.date_run_started, a.finished_run, a.final_lrt_time, a.pb, a.gold2, a.door_avg, a.door_median,
    SUM(b.gold) AS cumulative_chapter_gold
FROM doorsplit_golds1_runner a
LEFT JOIN (SELECT DISTINCT split_number, gold FROM doorsplit_golds1_runner) b ON a.split_number>=b.split_number
GROUP BY a.split_number, a.split_name, a.gold, a.run_id, a.date_run_started, a.finished_run, a.final_lrt_time, a.pb, a.gold2, a.door_avg, a.door_median
ORDER BY a.split_number) a
ORDER BY split_number;

/* ??? */

DROP TABLE IF EXISTS doorsplit_golds_history1_runner;
CREATE TABLE doorsplit_golds_history1_runner AS
SELECT
    split_number,
    split_name,
    gold,
    run_id,
    date_run_started,
    finished_run,
    final_lrt_time,
    pb,
    gold2,
    CASE
        WHEN lrt_time_dec <= min OR min IS NULL
            THEN 1
        ELSE 0
    END AS golded_split,
    CASE
        WHEN min < 10
            THEN TO_CHAR(min, 'FM0.000')
        WHEN min < 60
            THEN TO_CHAR(min, 'FM00.000')
        ELSE
            FLOOR(min / 60) || ':' || TO_CHAR(min % 60, 'FM00.000')
    END AS gold_at_that_time, lrt_time_dec AS lrt_number8, RANK() OVER (PARTITION BY split_number ORDER BY lrt_time_dec) AS rank_split
FROM (SELECT a.split_number, a.split_name, c.gold, c.gold2, a.lrt_time_dec, a.run_id, a.date_run_started, a.finished_run, a.final_lrt_time, a.pb, a.lrt_time_readable, MIN(b.lrt_time_dec) AS min,
MIN(b.lrt_time_readable) AS min2
FROM splits_overview3_runner a
LEFT JOIN splits_overview3_runner b ON a.split_number=b.split_number AND a.run_id>b.run_id
LEFT JOIN (SELECT DISTINCT split_number, split_name, gold, gold2 FROM doorsplit_golds1_runner) c ON a.split_number=c.split_number
GROUP BY a.split_number, a.split_name, c.gold, c.gold2, a.lrt_time_dec, a.run_id, a.date_run_started, a.finished_run, a.final_lrt_time, a.pb, a.lrt_time_readable) a;

/* ??? */

DROP TABLE IF EXISTS doorsplit_golds_history2_runner;
CREATE TABLE doorsplit_golds_history2_runner AS
SELECT a.*, split_rank_at_that_time, finished_splits, finished_splits_at_that_time
FROM doorsplit_golds_history1_runner a
LEFT JOIN (SELECT split_number, COUNT(*) AS finished_splits FROM doorsplit_golds_history1_runner GROUP BY 1) c ON a.split_number=c.split_number
LEFT JOIN (SELECT *
FROM (SELECT a.*, b.lrt_number8 AS split_time3, b.run_id AS id2,
RANK() OVER (PARTITION BY a.split_number, a.run_id ORDER BY b.lrt_number8) AS split_rank_at_that_time
FROM doorsplit_golds_history1_runner a
JOIN doorsplit_golds_history1_runner b ON a.split_number=b.split_number AND a.run_id>=b.run_id) a
WHERE run_id=id2) d ON a.split_number=d.split_number AND a.run_id=d.run_id

LEFT JOIN (

SELECT a.split_number, a.run_id, COUNT(*) AS finished_splits_at_that_time
FROM doorsplit_golds_history1_runner a
JOIN doorsplit_golds_history1_runner b ON a.split_number=b.split_number AND a.run_id>=b.run_id
GROUP BY 1, 2) e ON a.split_number=e.split_number AND a.run_id=e.run_id;

--#endregion DOORS

--#region CHAPTERS

/* Chapter times of all the attempts */

DROP TABLE IF EXISTS chapter_history1_runner;
CREATE TABLE chapter_history1_runner AS
SELECT
    chapter,
    run_id,
    date_run_started,
    finished_run,
    final_lrt_time,
    pb,
    SUM(chapter_time) AS chapter_time
FROM
(
    SELECT a.*
    FROM
    (
        SELECT
            chapter,
            run_id,
            date_run_started,
            finished_run,
            final_lrt_time,
            pb,
            SUM(lrt_time_dec) AS chapter_time,
            COUNT(*) AS number_of_splits
        FROM splits_overview3_runner
        GROUP BY
            chapter,
            run_id,
            date_run_started,
            finished_run,
            final_lrt_time,
            pb
    ) a
    JOIN splits_per_chapter b
    ON a.chapter = b.chapter AND a.number_of_splits = b.number_of_splits
)
GROUP BY
    chapter,
    run_id,
    date_run_started,
    finished_run,
    final_lrt_time,
    pb
ORDER BY 1;

/* Putting the chapter golds in LiveSplit format (previously numbers) */

DROP TABLE IF EXISTS chapter_history2_runner;
CREATE TABLE chapter_history2_runner AS
SELECT
    *,
    CASE
        WHEN chapter_time < 60
            THEN TO_CHAR(chapter_time, 'FM00.000')
        ELSE
            FLOOR(chapter_time / 60) || ':' || TO_CHAR(chapter_time % 60, 'FM00.000')
    END AS chapter_time2,
    RANK() OVER (PARTITION BY chapter ORDER BY chapter_time) AS rank_chapter
FROM chapter_history1_runner
ORDER BY chapter, chapter_time;

/* ??? */

DROP TABLE IF EXISTS chapter_history3_runner;
CREATE TABLE chapter_history3_runner AS
SELECT
    chapter,
    run_id,
    date_run_started,
    finished_run,
    pb,
    chapter_time,
    chapter_time2,
    CASE
        WHEN chapter_time <= min OR min IS NULL
            THEN 1
        ELSE 0
    END AS golded_chapter,
    CASE
        WHEN min < 60
            THEN TO_CHAR(min, 'FM00.000')
        ELSE
            FLOOR(min / 60) || ':' || TO_CHAR(min % 60, 'FM00.000')
    END AS chapter_gold_at_that_time,
    rank_chapter,
    chapter_rank_at_that_time,
    finished_chapters,
    finished_chapters_at_that_time
FROM
(
    SELECT
        a.rank_chapter,
        a.chapter,
        a.run_id,
        a.date_run_started,
        a.finished_run,
        a.pb,
        a.chapter_time,
        a.chapter_time2,
        MIN(b.chapter_time) AS min,
        MIN(b.chapter_time2) AS min2,
        finished_chapters,
        chapter_rank_at_that_time,
        finished_chapters_at_that_time
    FROM chapter_history2_runner a
    LEFT JOIN chapter_history2_runner b
    ON a.chapter = b.chapter AND a.run_id > b.run_id

    LEFT JOIN
    (
        SELECT
            chapter,
            COUNT(*) AS finished_chapters
        FROM chapter_history2_runner
        GROUP BY 1
    ) c ON a.chapter = c.chapter

    LEFT JOIN
    (
        SELECT *
        FROM
        (
            SELECT
                a.*,
                b.chapter_time AS chapter_time3,
                b.run_id AS id2,
                RANK() OVER (PARTITION BY a.chapter, a.run_id ORDER BY b.chapter_time) AS chapter_rank_at_that_time
            FROM chapter_history2_runner a
            JOIN chapter_history2_runner b
            ON a.chapter = b.chapter AND a.run_id >= b.run_id
        ) a
        WHERE run_id = id2
    ) d ON a.chapter = d.chapter AND a.run_id = d.run_id
    LEFT JOIN
    (
        SELECT
            a.chapter,
            a.run_id,
            COUNT(*) AS finished_chapters_at_that_time
        FROM chapter_history2_runner a
        JOIN chapter_history2_runner b
        ON a.chapter = b.chapter AND a.run_id >= b.run_id
        GROUP BY 1, 2
    ) e ON a.chapter = e.chapter AND a.run_id = e.run_id
GROUP BY
    finished_chapters_at_that_time,
    chapter_rank_at_that_time,
    finished_chapters,
    a.rank_chapter,
    a.chapter,
    a.run_id,
    a.date_run_started,
    a.finished_run,
    a.pb,
    a.chapter_time,
    a.chapter_time2
) a;

/* Getting the chapter golds AND chapter averages */

DROP TABLE IF EXISTS chapter_golds1_runner;
CREATE TABLE chapter_golds1_runner AS
SELECT
    ch_golds.*,
    avg_chapter_time,
    median_chapter_time::DECIMAL AS median_chapter_time
FROM
(
    SELECT
        aa.*,
        bb.run_id,
        date_run_started,
        finished_run,
        final_lrt_time,
        pb
    FROM
    (
        SELECT
            chapter,
            MIN(chapter_time) AS chapter_gold
        FROM
        (
            SELECT a.*
            FROM
            (
                SELECT
                    chapter,
                    run_id,
                    SUM(lrt_time_dec) AS chapter_time,
                    COUNT(*) AS number_of_splits
                FROM splits_overview3_runner
                GROUP BY chapter, run_id
                ORDER BY 1
            ) a
            JOIN splits_per_chapter b
            ON a.chapter = b.chapter AND a.number_of_splits = b.number_of_splits
        )
        GROUP BY 1
        ORDER BY 1
    ) aa
    LEFT JOIN
    (
        SELECT *
        FROM
        (
            SELECT a.*
            FROM
            (
                SELECT
                    chapter,
                    run_id,
                    date_run_started,
                    finished_run,
                    final_lrt_time,
                    pb,
                    SUM(lrt_time_dec) AS chapter_time,
                    COUNT(*) AS number_of_splits
                FROM splits_overview3_runner
                GROUP BY
                    chapter,
                    run_id,
                    date_run_started,
                    finished_run,
                    final_lrt_time,
                    pb
                ORDER BY 1
            ) a
            JOIN splits_per_chapter b
            ON a.chapter = b.chapter AND a.number_of_splits = b.number_of_splits
        )
    ) bb
    ON aa.chapter_gold = bb.chapter_time
) ch_golds
LEFT JOIN
(
    SELECT
        chapter,
        AVG(chapter_time) AS avg_chapter_time
    FROM
    (
        SELECT a.*
        FROM
        (
            SELECT
                chapter,
                run_id,
                date_run_started,
                finished_run,
                final_lrt_time,
                pb,
                SUM(lrt_time_dec) AS chapter_time,
                COUNT(*) AS number_of_splits
            FROM splits_overview3_runner
            GROUP BY
                chapter,
                run_id,
                date_run_started,
                finished_run,
                final_lrt_time,
                pb
        ) a
        JOIN splits_per_chapter b
        ON a.chapter = b.chapter AND a.number_of_splits = b.number_of_splits
    )
    GROUP BY 1
    ORDER BY 1
) ch_average
ON ch_golds.chapter = ch_average.chapter
LEFT JOIN
(
    SELECT
        chapter,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY chapter_time) AS median_chapter_time
    FROM
    (
        SELECT a.*
        FROM
        (
            SELECT
                chapter,
                run_id,
                date_run_started,
                finished_run,
                final_lrt_time,
                pb,
                SUM(lrt_time_dec) AS chapter_time,
                COUNT(*) AS number_of_splits
            FROM splits_overview3_runner
            GROUP BY
                chapter,
                run_id,
                date_run_started,
                finished_run,
                final_lrt_time,
                pb
        ) a
        JOIN splits_per_chapter b
        ON a.chapter = b.chapter AND a.number_of_splits = b.number_of_splits
    )
    GROUP BY 1
    ORDER BY 1
) ch_median
ON ch_golds.chapter = ch_median.chapter;

/* Putting the chapter golds AND averages IN LiveSplit format (previously numbers) */

DROP TABLE IF EXISTS chapter_golds2_runner;
CREATE TABLE chapter_golds2_runner AS
SELECT
    *,
    CASE
        WHEN chapter_gold < 60
            THEN TO_CHAR(chapter_gold, 'FM00.000')
        ELSE
            FLOOR(chapter_gold / 60) || ':' || TO_CHAR(chapter_gold % 60, 'FM00.000')
    END AS chapter_gold2,
    CASE
        WHEN avg_chapter_time < 60
            THEN TO_CHAR(avg_chapter_time, 'FM00.000')
        ELSE
            FLOOR(avg_chapter_time / 60) || ':' || TO_CHAR(avg_chapter_time % 60, 'FM00.000')
    END AS avg_chapter_time2,
    CASE
        WHEN median_chapter_time < 60
            THEN TO_CHAR(median_chapter_time, 'FM00.000')
        ELSE
            FLOOR(median_chapter_time / 60) || ':' || TO_CHAR(median_chapter_time % 60, 'FM00.000')
    END AS median_chapter_time2
FROM chapter_golds1_runner;

/* ??? */

DROP TABLE IF EXISTS chapter_golds3_runner;
CREATE TABLE chapter_golds3_runner AS
SELECT
    chapter,
    run_id,
    date_run_started,
    final_lrt_time,
    pb,
    chapter_gold,
    chapter_gold2,
CASE
    WHEN cumulative_chapter_gold < 10
        THEN TO_CHAR(cumulative_chapter_gold, 'FM0.000')
    WHEN cumulative_chapter_gold < 60
        THEN TO_CHAR(cumulative_chapter_gold, 'FM00.000')
    WHEN cumulative_chapter_gold < 3600
        THEN FLOOR(cumulative_chapter_gold / 60) || ':' || TO_CHAR(cumulative_chapter_gold % 60, 'FM00.000')
    ELSE
        FLOOR(cumulative_chapter_gold / 3600) || ':' || FLOOR((cumulative_chapter_gold - 3600) / 60) || ':' || TO_CHAR(cumulative_chapter_gold % 60, 'FM00.000')
END AS cumulative_chapter_gold, cumulative_chapter_gold AS cumulative_chapter_gold_num, avg_chapter_time,
median_chapter_time, avg_chapter_time2, median_chapter_time2
FROM(
SELECT a.chapter, a.chapter_gold, a.run_id, a.date_run_started, a.finished_run, a.final_lrt_time, a.pb, a.avg_chapter_time, a.chapter_gold2,
a.median_chapter_time, a.avg_chapter_time2, a.median_chapter_time2, SUM(b.chapter_gold) AS cumulative_chapter_gold
FROM chapter_golds2_runner a
LEFT JOIN (SELECT DISTINCT chapter, chapter_gold FROM chapter_golds2_runner) b ON a.chapter>=b.chapter
GROUP BY a.chapter, a.chapter_gold, a.run_id, a.date_run_started, a.finished_run, a.final_lrt_time, a.pb, a.avg_chapter_time, a.chapter_gold2,
a.median_chapter_time, a.avg_chapter_time2, a.median_chapter_time2) a
ORDER BY chapter;

--#endregion

--#region SECTIONS

/* Sections golds AND averages */

DROP TABLE IF EXISTS section_golds1_runner;
CREATE TABLE section_golds1_runner AS
SELECT section_golds.*, section_avg, section_median::DECIMAL AS section_median
FROM(
SELECT aa.*, bb.run_id, date_run_started, finished_run, final_lrt_time, pb
FROM (
SELECT _section, MIN(section_time) AS section_gold
FROM(
SELECT a.*
FROM(
SELECT _section, run_id, SUM(lrt_time_dec) AS section_time, COUNT(*) AS number_of_splits
FROM splits_overview3_runner
GROUP BY _section, run_id
ORDER BY 1) a
JOIN splits_per_section b ON a._section=b._section AND a.number_of_splits=b.number_of_splits)
GROUP BY 1) aa
LEFT JOIN (
SELECT *
FROM(
SELECT a.*
FROM(
SELECT _section, run_id, date_run_started, finished_run, final_lrt_time, pb, SUM(lrt_time_dec) AS section_time, COUNT(*) AS number_of_splits
FROM splits_overview3_runner
GROUP BY _section, run_id, date_run_started, finished_run, final_lrt_time, pb
ORDER BY 1) a
JOIN splits_per_section b ON a._section=b._section AND a.number_of_splits=b.number_of_splits)) bb
ON aa.section_gold=bb.section_time
ORDER BY CASE WHEN aa._section='Village' THEN 1 WHEN aa._section='Castle' THEN 2 ELSE 3 END) section_golds
LEFT JOIN (SELECT _section, AVG(section_time) AS section_avg
FROM(
SELECT a.*
FROM(
SELECT _section, run_id, date_run_started, finished_run, final_lrt_time, pb, SUM(lrt_time_dec) AS section_time, COUNT(*) AS number_of_splits
FROM splits_overview3_runner
GROUP BY _section, run_id, date_run_started, finished_run, final_lrt_time, pb) a
JOIN splits_per_section b ON a._section=b._section AND a.number_of_splits=b.number_of_splits)
GROUP BY 1
ORDER BY 1) section_avg ON section_golds._section=section_avg._section
LEFT JOIN (SELECT _section, PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY section_time) AS section_median
FROM(
SELECT a.*
FROM(
SELECT _section, run_id, date_run_started, finished_run, final_lrt_time, pb, SUM(lrt_time_dec) AS section_time, COUNT(*) AS number_of_splits
FROM splits_overview3_runner
GROUP BY _section, run_id, date_run_started, finished_run, final_lrt_time, pb) a
JOIN splits_per_section b ON a._section=b._section AND a.number_of_splits=b.number_of_splits)
GROUP BY 1
ORDER BY 1) section_med ON section_golds._section=section_med._section;

/* Putting the _section golds AND averages IN LiveSplit format (previously numbers) */

DROP TABLE IF EXISTS section_golds2_runner;
CREATE TABLE section_golds2_runner AS
SELECT *, FLOOR(section_gold / 60) || ':' ||
CASE WHEN LENGTH(TO_CHAR(TRUNC(section_gold, 3) % 60, 'FM00.999'))=3
THEN TO_CHAR(TRUNC(section_gold, 3) % 60, 'FM00.999')||'000'
WHEN LENGTH(TO_CHAR(TRUNC(section_gold, 3) % 60, 'FM00.999'))=4
THEN TO_CHAR(TRUNC(section_gold, 3) % 60, 'FM00.999')||'00'
WHEN LENGTH(TO_CHAR(TRUNC(section_gold, 3) % 60, 'FM00.999'))=5
THEN TO_CHAR(TRUNC(section_gold, 3) % 60, 'FM00.999')||'0' ELSE
TO_CHAR(TRUNC(section_gold, 3) % 60, 'FM00.999') END AS section_gold2,
FLOOR(section_avg / 60) || ':' ||
CASE WHEN LENGTH(TO_CHAR(TRUNC(section_avg, 3) % 60, 'FM00.999'))=3
THEN TO_CHAR(TRUNC(section_avg, 3) % 60, 'FM00.999')||'000'
WHEN LENGTH(TO_CHAR(TRUNC(section_avg, 3) % 60, 'FM00.999'))=4
THEN TO_CHAR(TRUNC(section_avg, 3) % 60, 'FM00.999')||'00'
WHEN LENGTH(TO_CHAR(TRUNC(section_avg, 3) % 60, 'FM00.999'))=5
THEN TO_CHAR(TRUNC(section_avg, 3) % 60, 'FM00.999')||'0' ELSE
TO_CHAR(TRUNC(section_avg, 3) % 60, 'FM00.999') END AS section_avg2,
FLOOR(section_median / 60) || ':' ||
CASE WHEN LENGTH(TO_CHAR(TRUNC(section_median, 3) % 60, 'FM00.999'))=3
THEN TO_CHAR(TRUNC(section_median, 3) % 60, 'FM00.999')||'000'
WHEN LENGTH(TO_CHAR(TRUNC(section_median, 3) % 60, 'FM00.999'))=4
THEN TO_CHAR(TRUNC(section_median, 3) % 60, 'FM00.999')||'00'
WHEN LENGTH(TO_CHAR(TRUNC(section_median, 3) % 60, 'FM00.999'))=5
THEN TO_CHAR(TRUNC(section_median, 3) % 60, 'FM00.999')||'0' ELSE
TO_CHAR(TRUNC(section_median, 3) % 60, 'FM00.999') END AS section_median2
FROM section_golds1_runner;

/* ??? */

DROP TABLE IF EXISTS section_golds3_runner;
CREATE TABLE section_golds3_runner AS
SELECT _section, run_id, date_run_started, final_lrt_time, pb, section_gold, section_gold2,
CASE
    WHEN cumulative_chapter_gold < 10
        THEN TO_CHAR(cumulative_chapter_gold, 'FM0.000')
    WHEN cumulative_chapter_gold < 60
        THEN TO_CHAR(cumulative_chapter_gold, 'FM00.000')
    WHEN cumulative_chapter_gold < 3600
        THEN FLOOR(cumulative_chapter_gold / 60) || ':' || TO_CHAR(cumulative_chapter_gold % 60, 'FM00.000')
    ELSE
        FLOOR(cumulative_chapter_gold / 3600) || ':' || FLOOR((cumulative_chapter_gold - 3600) / 60) || ':' || TO_CHAR(cumulative_chapter_gold % 60, 'FM00.000')
END AS cumulative_section_gold, section_avg, section_median,
section_avg2, section_median2
FROM(
SELECT a._section, a.section_gold, a.run_id, a.date_run_started, a.finished_run, a.final_lrt_time, a.pb, a.section_avg, a.section_gold2,
a.section_avg2, a.section_median, a.section_median2, SUM(b.section_gold) AS cumulative_chapter_gold
FROM section_golds2_runner a
LEFT JOIN (SELECT DISTINCT _section, section_gold FROM section_golds2_runner) b ON CASE WHEN a._section='Village' THEN 1 WHEN a._section='Castle' THEN 2 ELSE 3 END>=
    CASE WHEN b._section='Village' THEN 1 WHEN b._section='Castle' THEN 2 ELSE 3 END
GROUP BY a._section, a.section_gold, a.run_id, a.date_run_started, a.finished_run, a.final_lrt_time, a.pb, a.section_avg, a.section_gold2,
a.section_avg2, a.section_median, a.section_median2) a
ORDER BY CASE WHEN _section='Village' THEN 1 WHEN _section='Castle' THEN 2 ELSE 3 END;

/* Section times of all the attempts */

DROP TABLE IF EXISTS section_history1_runner;
CREATE TABLE section_history1_runner AS
SELECT
    _section,
    run_id,
    date_run_started,
    finished_run,
    final_lrt_time,
    pb,
    SUM(section_time) AS section_time
FROM
(
    SELECT a.*
    FROM
    (
        SELECT
            _section,
            run_id,
            date_run_started,
            finished_run,
            final_lrt_time,
            pb,
            SUM(lrt_time_dec) AS section_time,
            COUNT(*) AS number_of_splits
        FROM splits_overview3_runner
        GROUP BY
            _section,
            run_id,
            date_run_started,
            finished_run,
            final_lrt_time,
            pb
    ) a
    JOIN splits_per_section b
    ON a._section = b._section AND a.number_of_splits = b.number_of_splits
)
GROUP BY
    1,
    2,
    date_run_started,
    finished_run,
    final_lrt_time,
    pb
ORDER BY 1;

/* Putting the section golds in LiveSplit format (previously numbers) */

DROP TABLE IF EXISTS section_history2_runner;
CREATE TABLE section_history2_runner AS
SELECT *,

CASE
    WHEN section_time < 10
        THEN TO_CHAR(section_time, 'FM0.000')
    WHEN section_time < 60
        THEN TO_CHAR(section_time, 'FM00.000')
    WHEN section_time < 3600
        THEN FLOOR(section_time / 60) || ':' || TO_CHAR(section_time % 60, 'FM00.000')
    ELSE
        FLOOR(section_time / 3600) || ':' || FLOOR((section_time - 3600) / 60) || ':' || TO_CHAR(section_time % 60, 'FM00.000')

END AS section_time2, RANK() OVER (PARTITION BY _section ORDER BY section_time) AS rank_section
FROM section_history1_runner
ORDER BY CASE WHEN _section='Village' THEN 1 WHEN _section='Castle' THEN 2 ELSE 3 END, section_time;

/* ??? */

DROP TABLE IF EXISTS section_history3_runner;
CREATE TABLE section_history3_runner AS
SELECT _section, run_id, date_run_started, finished_run, final_lrt_time, pb, section_time, section_time2, CASE WHEN section_time<=min OR min IS NULL
THEN 1 ELSE 0 END AS golded_section,
FLOOR(min / 60) || ':' ||
CASE WHEN LENGTH(TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999'))=3
THEN TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'000'
WHEN LENGTH(TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999'))=4
THEN TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'00'
WHEN LENGTH(TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999'))=5
THEN TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'0' ELSE
TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999') END AS section_gold_at_that_time, rank_section, section_rank_at_that_time, finished_sections, finished_sections_at_that_time
FROM (SELECT a._section, a.run_id, a.date_run_started, a.finished_run, a.final_lrt_time, a.pb, a.section_time, a.section_time2, MIN(b.section_time) AS min,
MIN(b.section_time2) AS min2, a.rank_section, finished_sections, finished_sections_at_that_time, section_rank_at_that_time
FROM section_history2_runner a
LEFT JOIN section_history2_runner b ON a._section=b._section AND a.run_id>b.run_id
LEFT JOIN (SELECT _section, COUNT(*) AS finished_sections FROM section_history2_runner GROUP BY 1) c ON a._section=c._section
LEFT JOIN (SELECT *
FROM (SELECT a.*, b.section_time AS section_time3, b.run_id AS id2,
RANK() OVER (PARTITION BY a._section, a.run_id ORDER BY b.section_time) AS section_rank_at_that_time
FROM section_history2_runner a
JOIN section_history2_runner b ON a._section=b._section AND a.run_id>=b.run_id) a
WHERE run_id=id2) d ON a._section=d._section AND a.run_id=d.run_id

LEFT JOIN (

SELECT a._section, a.run_id, COUNT(*) AS finished_sections_at_that_time
FROM section_history2_runner a
JOIN section_history2_runner b ON a._section=b._section AND a.run_id>=b.run_id
GROUP BY 1, 2) e ON a._section=e._section AND a.run_id=e.run_id
GROUP BY a.rank_section, finished_sections, finished_sections_at_that_time, section_rank_at_that_time, a._section, a.run_id, a.date_run_started, a.finished_run, a.final_lrt_time, a.pb, a.section_time, a.section_time2) a;

--#endregion

--#region PACES

/* Getting the pace (AND best pace) of each run after each split_name */

DROP TABLE IF EXISTS best_paces_runner;
CREATE TABLE best_paces_runner AS
SELECT pace.*, best_pace, --avg_pace, median_pace,
CASE
    WHEN pace < 10
        THEN TO_CHAR(pace, 'FM0.000')
    WHEN pace < 60
        THEN TO_CHAR(pace, 'FM00.000')
    WHEN pace < 3600
        THEN FLOOR(pace / 60) || ':' || TO_CHAR(pace % 60, 'FM00.000')
    ELSE
        FLOOR(pace / 3600) || ':' || FLOOR((pace - 3600) / 60) || ':' || TO_CHAR(pace % 60, 'FM00.000')
END AS pace2,
CASE
    WHEN best_pace < 10
        THEN TO_CHAR(best_pace, 'FM0.000')
    WHEN best_pace < 60
        THEN TO_CHAR(best_pace, 'FM00.000')
    WHEN best_pace < 3600
        THEN FLOOR(best_pace / 60) || ':' || TO_CHAR(best_pace % 60, 'FM00.000')
    ELSE
        FLOOR(best_pace / 3600) || ':' || FLOOR((best_pace - 3600) / 60) || ':' || TO_CHAR(best_pace % 60, 'FM00.000')
END AS best_pace2/*,
CASE
    WHEN avg_pace < 10
        THEN TO_CHAR(avg_pace , 'FM0.000')
    WHEN avg_pace  < 60
        THEN TO_CHAR(avg_pace , 'FM00.000')
    WHEN avg_pace  < 3600
        THEN FLOOR(avg_pace  / 60) || ':' || TO_CHAR(avg_pace  % 60, 'FM00.000')
    ELSE
        FLOOR(avg_pace  / 3600) || ':' || FLOOR((avg_pace  - 3600) / 60) || ':' || TO_CHAR(avg_pace  % 60, 'FM00.000')
END AS avg_pace2,
CASE
    WHEN median_pace < 10
        THEN TO_CHAR(median_pace, 'FM0.000')
    WHEN median_pace < 60
        THEN TO_CHAR(median_pace, 'FM00.000')
    WHEN median_pace < 3600
        THEN FLOOR(median_pace / 60) || ':' || TO_CHAR(median_pace % 60, 'FM00.000')
    ELSE
        FLOOR(median_pace / 3600) || ':' || FLOOR((median_pace - 3600) / 60) || ':' || TO_CHAR(median_pace % 60, 'FM00.000')
END AS median_pace2*/
FROM (SELECT aa.split_number, aa.run_id, aa.split_name, COUNT(*) AS number_of_splits, SUM(bb.lrt_time_dec) AS pace
FROM
(SELECT *
FROM splits_overview3_runner a) aa
JOIN
(SELECT *
FROM splits_overview3_runner a) bb ON aa.split_number>=bb.split_number AND aa.run_id=bb.run_id
GROUP BY aa.run_id, aa.split_name, aa.split_number
having COUNT(*)=aa.split_number
ORDER BY aa.run_id, aa.split_number) pace
LEFT JOIN (
SELECT split_name, split_number, MIN(pace) AS best_pace--, AVG(pace)::DECIMAL AS avg_pace, CAST(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY pace) AS DECIMAL) AS median_pace
FROM(
SELECT aa.split_number, aa.run_id, aa.split_name, COUNT(*) AS number_of_splits, SUM(bb.lrt_time_dec) AS pace
FROM
(SELECT *
FROM splits_overview3_runner a) aa
JOIN
(SELECT *
FROM splits_overview3_runner a) bb ON aa.split_number>=bb.split_number AND aa.run_id=bb.run_id
GROUP BY aa.run_id, aa.split_name, aa.split_number
ORDER BY aa.run_id, aa.split_number)
WHERE run_id>0
AND number_of_splits=split_number
GROUP BY split_name, split_number
ORDER BY split_number) best_pace ON pace.split_number=best_pace.split_number;

/* ??? */

DROP TABLE IF EXISTS best_paces_history1_runner;
CREATE TABLE best_paces_history1_runner AS
SELECT split_number, run_id, split_name, number_of_splits, pace, best_pace, pace2, best_pace2, CASE WHEN pace<=min OR min IS NULL THEN 1 ELSE 0
END AS was_best_pace,
CASE
    WHEN min < 10
        THEN TO_CHAR(min, 'FM0.000')
    WHEN min < 60
        THEN TO_CHAR(min, 'FM00.000')
    WHEN min < 3600
        THEN FLOOR(min / 60) || ':' || TO_CHAR(min % 60, 'FM00.000')
    ELSE
        FLOOR(min / 3600) || ':' || FLOOR((min - 3600) / 60) || ':' || TO_CHAR(min % 60, 'FM00.000')
END AS best_pace_at_that_time, min AS best_pace_at_that_time2/*,
avg_pace, median_pace, avg_pace2, median_pace2*/, RANK() OVER (PARTITION BY split_number ORDER BY pace) AS rank_pace
FROM (SELECT a.split_number, a.run_id, a.split_name, a.number_of_splits, a.pace, a.best_pace, a.pace2, a.best_pace2, /*a.avg_pace, a.median_pace,
a.avg_pace2, a.median_pace2,*/ MIN(b.pace) AS min,
MIN(b.pace2) AS min2
FROM best_paces_runner a
LEFT JOIN best_paces_runner b ON a.split_number=b.split_number AND a.run_id>b.run_id
GROUP BY a.split_number, a.run_id, a.split_name, a.number_of_splits, a.pace, a.best_pace, a.pace2, a.best_pace2/*, a.avg_pace, a.median_pace,
a.avg_pace2, a.median_pace2*/) a
ORDER BY split_number DESC, run_id;

/* ??? */

DROP TABLE IF EXISTS best_paces_history2_runner;
CREATE TABLE best_paces_history2_runner AS
SELECT a.*, pace_rank_at_that_time, finished_paces, finished_paces_at_that_time
FROM best_paces_history1_runner a
LEFT JOIN (SELECT split_number, COUNT(*) AS finished_paces FROM best_paces_history1_runner GROUP BY 1) c ON a.split_number=c.split_number
LEFT JOIN (SELECT *
FROM (SELECT a.*, b.pace AS pace_time3, b.run_id AS id2,
RANK() OVER (PARTITION BY a.split_number, a.run_id ORDER BY b.pace) AS pace_rank_at_that_time
FROM best_paces_history1_runner a
JOIN best_paces_history1_runner b ON a.split_number=b.split_number AND a.run_id>=b.run_id) a
WHERE run_id=id2) d ON a.split_number=d.split_number AND a.run_id=d.run_id

LEFT JOIN (

SELECT a.split_number, a.run_id, COUNT(*) AS finished_paces_at_that_time
FROM best_paces_history1_runner a
JOIN best_paces_history1_runner b ON a.split_number=b.split_number AND a.run_id>=b.run_id
GROUP BY 1, 2) e ON a.split_number=e.split_number AND a.run_id=e.run_id;

--#endregion

/* Checking is a gold was done ON a gold hunt (bad run) by checking the delta between the pace of that run AND the best pace for each split_name */

DROP TABLE IF EXISTS gold_hunt_detector_runner;
CREATE TABLE gold_hunt_detector_runner AS
SELECT split_number, split_name, gold, gold2, run_id, date_run_started, finished_run, final_lrt_time, pb, pace, pace2, best_pace, best_pace2,
best_pace_delta
FROM(
SELECT a.*, pace, best_pace, pace-best_pace AS best_pace_delta, pace2, best_pace2,
ROW_NUMBER () OVER (PARTITION BY a.split_number ORDER BY pace-best_pace) AS rang
FROM doorsplit_golds1_runner a
LEFT JOIN best_paces_history2_runner b ON a.run_id=b.run_id AND a.split_number=b.split_number) a
WHERE rang=1
ORDER BY split_number;

--#region RESETS

/* Resets history to get the % of resets for each split_name */

DROP TABLE IF EXISTS resets_history1_runner;
CREATE TABLE resets_history1_runner AS
SELECT a.*, attempts
FROM(
SELECT split_number, split_name, COUNT(*) AS runs
FROM splits_overview3_runner
GROUP BY split_number, split_name
ORDER BY split_number) a CROSS JOIN (SELECT COUNT(*) AS attempts
FROM attempts_data5_runner
GROUP BY runner_name) b;

/* ??? */

DROP TABLE IF EXISTS resets_history2_runner;
CREATE TABLE resets_history2_runner AS
SELECT split_number, split_name, runs, resets, (ROUND(resets)/ROUND(CASE WHEN lag IS NULL THEN runs+resets ELSE lag END))*100
AS percentage_resets
FROM(
SELECT *, LAG(runs) OVER() AS lag
FROM(
SELECT split_number, split_name, runs, CASE WHEN LAG(runs) OVER ()-runs IS NULL THEN attempts-runs ELSE LAG(runs) OVER ()-runs END AS resets
FROM resets_history1_runner));

--#endregion

/* Final main table that has everything */

DROP TABLE IF EXISTS splits_overview_runner;
CREATE TABLE splits_overview_runner AS
SELECT *
FROM (SELECT a.run_id, a.split_name, a.chapter, a._section, a.lrt_time_dec, a.lrt_time_readable, a.date_run_started, a.finished_run, a.final_lrt_time, a.pb, a.split_number, a.final_rta_time,
a.date_run_ended, a.time_start_numeric3 AS time_start, a.time_end_numeric3 AS time_end, a.run_duration, a.rta_time_dec, a.rta_time_readable, e.gold2, e.gold, pace,
pace2, best_pace, best_pace2, chapter_time, chapter_time2, section_time, section_time2,
chapter_gold, chapter_gold2, section_gold, section_gold2,
CASE WHEN a.finished_run=1 THEN NULL ELSE split_of_reset END AS split_of_reset,
CASE WHEN a.finished_run=1 THEN NULL ELSE cle2_reset END AS cle2_reset,
CASE WHEN a.split_number=30 AND lrt_time_dec<=54.5 THEN '2-a Fast Mendez'
WHEN a.split_number=30 AND lrt_time_dec<=57 THEN '2-b Medium Mendez'
WHEN a.split_number=30 THEN '2-c Slow Mendez'
ELSE '' END AS mendez_pattern,
CASE WHEN a.split_number=14 AND lrt_time_dec<=96 THEN '1-a No dive'
WHEN a.split_number=14 AND lrt_time_dec<=102 THEN '1-b Late dive'
WHEN a.split_number=14 OR (a.split_number=13 AND cle2_reset=14) THEN '1-c Early dive'
ELSE '' END AS lago_pattern,
CASE WHEN a.split_number=65 AND lrt_time_dec<=31 THEN '3-a Perfect catapult'
WHEN a.split_number=65 AND lrt_time_dec<=33 THEN '3-b Stagger catapult'
WHEN a.split_number=65 THEN '3-c Boulder catapult'
ELSE '' END AS catapult_pattern,
CASE WHEN a.split_number=26 AND lrt_time_dec<=113 THEN '4-a Great cabin'
WHEN a.split_number=26 AND lrt_time_dec<=118 THEN '4-b Good cabin'
WHEN a.split_number=26 AND lrt_time_dec<=123 THEN '4-c Average cabin'
WHEN a.split_number=26 AND lrt_time_dec<=130 THEN '4-d Bad cabin'
WHEN a.split_number=26 THEN '4-e Terrible cabin'
ELSE '' END AS cabin_pattern,
CASE WHEN a.split_number=38 AND lrt_time_dec<=196 THEN '5-a Great water hall'
WHEN a.split_number=38 AND lrt_time_dec<=199 THEN '5-b Good water hall'
WHEN a.split_number=38 AND lrt_time_dec<=202 THEN '5-c Average water hall'
WHEN a.split_number=38 AND lrt_time_dec<=205 THEN '5-d Bad water hall'
WHEN a.split_number=38 THEN '5-e Terrible water hall'
ELSE '' END AS water_hall_pattern,
CASE WHEN a.split_number=41 AND lrt_time_dec<=82 THEN '6-a Great novis 1'
WHEN a.split_number=41 AND lrt_time_dec<=84 THEN '6-b Good novis 1'
WHEN a.split_number=41 AND lrt_time_dec<=86 THEN '6-c Average novis 1'
WHEN a.split_number=41 AND lrt_time_dec<=88 THEN '6-d Bad novis 1'
WHEN a.split_number=41 THEN '6-e Terrible novis 1'
ELSE '' END AS novis1_pattern,
CASE WHEN a.split_number=43 AND lrt_time_dec<=102 THEN '7-a Great gallery'
WHEN a.split_number=43 AND lrt_time_dec<=105 THEN '7-b Good gallery'
WHEN a.split_number=43 AND lrt_time_dec<=108 THEN '7-c Average gallery'
WHEN a.split_number=43 AND lrt_time_dec<=110 THEN '7-d Bad gallery'
WHEN a.split_number=43 THEN '7-e Terrible gallery'
ELSE '' END AS gallery_pattern,
CASE WHEN a.split_number=64 AND lrt_time_dec<=33.5 THEN '8-a Great novis 2'
WHEN a.split_number=64 AND lrt_time_dec<=35 THEN '8-b Good novis 2'
WHEN a.split_number=64 AND lrt_time_dec<=38 THEN '8-c Average novis 2'
WHEN a.split_number=64 AND lrt_time_dec<=40 THEN '8-d Bad novis 2'
WHEN a.split_number=64 THEN '8-e Terrible novis 2'
ELSE '' END AS novis2_pattern,
CASE WHEN a.split_number=74 AND lrt_time_dec<=77 THEN '9-a Great novis 3'
WHEN a.split_number=74 AND lrt_time_dec<=79 THEN '9-b Good novis 3'
WHEN a.split_number=74 AND lrt_time_dec<=82 THEN '9-c Average novis 3'
WHEN a.split_number=74 AND lrt_time_dec<=85 THEN '9-d Bad novis 3'
WHEN a.split_number=74 THEN '9-e Terrible novis 3'
ELSE '' END AS novis3_pattern,
CASE WHEN a.split_number=110 AND lrt_time_dec<=95.5 THEN '90-a Great u3'
WHEN a.split_number=110 AND lrt_time_dec<=99 THEN '90-b Good u3'
WHEN a.split_number=110 AND lrt_time_dec<=101 THEN '90-c Average u3'
WHEN a.split_number=110 AND lrt_time_dec<=103 THEN '90-d Bad u3'
WHEN a.split_number=110 THEN '90-e Terrible u3'
ELSE '' END AS u3_pattern,
CASE WHEN a.split_number=112 AND lrt_time_dec<=139 THEN '91-a Great Krauser'
WHEN a.split_number=112 AND lrt_time_dec<=142 THEN '91-b Good Krauser'
WHEN a.split_number=112 AND lrt_time_dec<=145 THEN '91-c Average Krauser'
WHEN a.split_number=112 AND lrt_time_dec<=148 THEN '91-d Bad Krauser'
WHEN a.split_number=112 THEN '91-e Terrible Krauser'
ELSE '' END AS krauser_pattern,
CASE WHEN a.split_number=113 AND lrt_time_dec<=111 THEN '92-a Great war room'
WHEN a.split_number=113 AND lrt_time_dec<=114 THEN '92-b Good war room'
WHEN a.split_number=113 AND lrt_time_dec<=117 THEN '92-c Average war room'
WHEN a.split_number=113 AND lrt_time_dec<=120 THEN '92-d Bad war room'
WHEN a.split_number=113 THEN '92-e Terrible war room'
ELSE '' END AS war_room_pattern,
CASE WHEN a.split_number=117 AND lrt_time_dec<=55 THEN '93-a Great key card'
WHEN a.split_number=117 AND lrt_time_dec<=57 THEN '93-b Good key card'
WHEN a.split_number=117 AND lrt_time_dec<=59 THEN '93-c Average key card'
WHEN a.split_number=117 AND lrt_time_dec<=61 THEN '93-d Bad key card'
WHEN a.split_number=117 THEN '93-e Terrible key card'
ELSE '' END AS key_card_pattern,
CASE WHEN extract(DOW FROM a.date_run_started)=0 THEN 7 ELSE extract(DOW FROM a.date_run_started) END AS weekday,
h.lrt_pb AS pb_at_that_time, golded_split, golded_chapter, golded_section, was_best_pace, cumulative_chapter_gold, cumulative_chapter_gold_num, cumulative_section_gold,
cumulative_door_gold, cumulative_door_gold_num, gold_at_that_time, chapter_gold_at_that_time, section_gold_at_that_time, best_pace_at_that_time,
best_pace_at_that_time2,
CASE
    WHEN SUBSTR(a.time_run_started, 1, 2)::DECIMAL > SUBSTR(a.time_start_numeric3, 1, 2)::DECIMAL
        THEN a.date_run_started+1
    ELSE a.date_run_started
END AS date_started2,
CASE
    WHEN SUBSTR(a.time_run_ended, 1, 2)::DECIMAL < SUBSTR(a.time_end_numeric3, 1, 2)::DECIMAL
        THEN a.date_run_ended-1
    ELSE a.date_run_ended
END AS date_end2,
door_avg, door_median, door_avg2, door_median2, median_chapter_time, median_chapter_time2,
/*avg_pace, median_pace, avg_pace2, median_pace2,*/ section_median, section_median2, section_avg2, avg_chapter_time2, 'runner' AS runner_name, rank_chapter, chapter_rank_at_that_time, finished_chapters,
finished_chapters_at_that_time, rank_section, section_rank_at_that_time, finished_sections, finished_sections_at_that_time, rank_split, split_rank_at_that_time, finished_splits, finished_splits_at_that_time,
rank_pace, pace_rank_at_that_time, finished_paces, finished_paces_at_that_time,
ROW_NUMBER() OVER (PARTITION BY a.run_id, a.split_number ORDER BY id2 DESC) AS rang
FROM splits_overview3_runner a
LEFT JOIN best_paces_history2_runner b ON a.run_id=b.run_id AND a.split_number=b.split_number
LEFT JOIN (SELECT split_number, gold2, gold, door_avg, door_median, door_avg2, door_median2, MIN(cumulative_door_gold) AS cumulative_door_gold, MIN(cumulative_door_gold_num) AS cumulative_door_gold_num
           FROM doorsplit_golds2_runner
           GROUP BY split_number, gold2, gold, door_avg, door_median, door_avg2, door_median2) e ON a.split_number=e.split_number
LEFT JOIN doorsplit_golds_history2_runner ee ON a.split_number=ee.split_number AND a.run_id=ee.run_id
LEFT JOIN chapter_history3_runner c ON a.run_id=c.run_id AND a.chapter=c.chapter
LEFT JOIN section_history3_runner d ON a.run_id=d.run_id AND a._section=d._section
LEFT JOIN chapter_golds3_runner f ON a.chapter=f.chapter
LEFT JOIN section_golds3_runner g ON a._section=g._section
LEFT JOIN (SELECT a.run_id, b.split_name AS split_of_reset, b.split_number AS cle2_reset
FROM (SELECT run_id, MAX(split_number)+1 AS max
FROM splits_overview3_runner
GROUP BY run_id) a
LEFT JOIN (SELECT DISTINCT split_number, split_name FROM splits_overview3_runner) b ON a.max=b.split_number) resets ON resets.run_id=a.run_id
LEFT JOIN (SELECT *, run_id::DECIMAL AS id2 FROM pb_history_runner) h ON a.run_id>h.id2) aa
WHERE rang=1
ORDER BY run_id, split_number;

--#region RNG

/* RNG splits (LIKE Lago) to get the % of patterns (LIKE % of early dives, etc.) */

DROP TABLE IF EXISTS rng_splits_runner;
CREATE TABLE rng_splits_runner AS
SELECT pattern, SUBSTR(pattern, 4, LENGTH(pattern)-3) AS pattern2, runs, total, percentage
FROM(SELECT pattern, runs, total, percentage
FROM (SELECT a.*, total, ROUND(runs)/ROUND(total)*100 AS percentage
FROM(
SELECT lago_pattern AS pattern, COUNT(*) AS runs
FROM splits_overview_runner a
LEFT JOIN splits_overview3_runner b ON a.run_id=b.run_id AND a.split_number=b.split_number
WHERE (a.split_number=14 AND a.lrt_time_dec<117) OR (a.split_number=13 AND cle2_reset=14 AND
CASE WHEN time_end_numeric2>time_ended_numeric AND b.time_run_ended<>time_end_numeric3 THEN time_ended_numeric-time_end_numeric2+86400 ELSE time_ended_numeric-time_end_numeric2 END>=CASE WHEN runner_name LIKE '%lu%'
AND runner_name LIKE '%is%' THEN 59 ELSE 56 END)
GROUP BY 1) a
CROSS JOIN (
SELECT COUNT(*) AS total
FROM splits_overview_runner a
LEFT JOIN splits_overview3_runner b ON a.run_id=b.run_id AND a.split_number=b.split_number
WHERE (a.split_number=14 AND a.lrt_time_dec<117) OR (a.split_number=13 AND cle2_reset=14 AND
CASE WHEN time_end_numeric2>time_ended_numeric AND b.time_run_ended<>time_end_numeric3 THEN time_ended_numeric-time_end_numeric2+86400 ELSE time_ended_numeric-time_end_numeric2 END>=CASE WHEN runner_name LIKE '%lu%'
AND runner_name LIKE '%is%' THEN 59 ELSE 56 END)) b)
UNION
(SELECT a.*, total, ROUND(runs)/ROUND(total)*100 AS percentage
FROM(
SELECT mendez_pattern AS pattern, COUNT(*) AS runs
FROM splits_overview_runner
WHERE mendez_pattern<>'' AND lrt_time_dec<60
GROUP BY 1) a
CROSS JOIN (
SELECT COUNT(*) AS total
FROM splits_overview_runner
WHERE split_number=30 AND lrt_time_dec<60) b)
UNION
(SELECT a.*, total, ROUND(runs)/ROUND(total)*100 AS percentage
FROM(
SELECT catapult_pattern AS pattern, COUNT(*) AS runs
FROM splits_overview_runner
WHERE catapult_pattern<>'' AND lrt_time_dec<40
GROUP BY 1) a
CROSS JOIN (
SELECT COUNT(*) AS total
FROM splits_overview_runner
WHERE split_number=65 AND lrt_time_dec<40) b)
UNION
(SELECT a.*, total, ROUND(runs)/ROUND(total)*100 AS percentage
FROM(
SELECT cabin_pattern AS pattern, COUNT(*) AS runs
FROM splits_overview_runner
WHERE cabin_pattern<>''
GROUP BY 1) a
CROSS JOIN (
SELECT COUNT(*) AS total
FROM splits_overview_runner
WHERE split_number=26
) b)
UNION
(SELECT a.*, total, ROUND(runs)/ROUND(total)*100 AS percentage
FROM(
SELECT water_hall_pattern AS pattern, COUNT(*) AS runs
FROM splits_overview_runner
WHERE water_hall_pattern<>''
GROUP BY 1) a
CROSS JOIN (
SELECT COUNT(*) AS total
FROM splits_overview_runner
WHERE split_number=38
) b)
UNION
(SELECT a.*, total, ROUND(runs)/ROUND(total)*100 AS percentage
FROM(
SELECT novis1_pattern AS pattern, COUNT(*) AS runs
FROM splits_overview_runner
WHERE novis1_pattern<>''
GROUP BY 1) a
CROSS JOIN (
SELECT COUNT(*) AS total
FROM splits_overview_runner
WHERE split_number=41
) b)
UNION
(SELECT a.*, total, ROUND(runs)/ROUND(total)*100 AS percentage
FROM(
SELECT gallery_pattern AS pattern, COUNT(*) AS runs
FROM splits_overview_runner
WHERE gallery_pattern<>''
GROUP BY 1) a
CROSS JOIN (
SELECT COUNT(*) AS total
FROM splits_overview_runner
WHERE split_number=43
) b)
UNION
(SELECT a.*, total, ROUND(runs)/ROUND(total)*100 AS percentage
FROM(
SELECT novis2_pattern AS pattern, COUNT(*) AS runs
FROM splits_overview_runner
WHERE novis2_pattern<>''
GROUP BY 1) a
CROSS JOIN (
SELECT COUNT(*) AS total
FROM splits_overview_runner
WHERE split_number=64
) b)
UNION
(SELECT a.*, total, ROUND(runs)/ROUND(total)*100 AS percentage
FROM(
SELECT novis3_pattern AS pattern, COUNT(*) AS runs
FROM splits_overview_runner
WHERE novis3_pattern<>''
GROUP BY 1) a
CROSS JOIN (
SELECT COUNT(*) AS total
FROM splits_overview_runner
WHERE split_number=74
) b)
UNION
(SELECT a.*, total, ROUND(runs)/ROUND(total)*100 AS percentage
FROM(
SELECT u3_pattern AS pattern, COUNT(*) AS runs
FROM splits_overview_runner
WHERE u3_pattern<>''
GROUP BY 1) a
CROSS JOIN (
SELECT COUNT(*) AS total
FROM splits_overview_runner
WHERE split_number=110
) b)
UNION
(SELECT a.*, total, ROUND(runs)/ROUND(total)*100 AS percentage
FROM(
SELECT krauser_pattern AS pattern, COUNT(*) AS runs
FROM splits_overview_runner
WHERE krauser_pattern<>''
GROUP BY 1) a
CROSS JOIN (
SELECT COUNT(*) AS total
FROM splits_overview_runner
WHERE split_number=112
) b)
UNION
(SELECT a.*, total, ROUND(runs)/ROUND(total)*100 AS percentage
FROM(
SELECT war_room_pattern AS pattern, COUNT(*) AS runs
FROM splits_overview_runner
WHERE war_room_pattern<>''
GROUP BY 1) a
CROSS JOIN (
SELECT COUNT(*) AS total
FROM splits_overview_runner
WHERE split_number=113
) b)
UNION
(SELECT a.*, total, ROUND(runs)/ROUND(total)*100 AS percentage
FROM(
SELECT key_card_pattern AS pattern, COUNT(*) AS runs
FROM splits_overview_runner
WHERE key_card_pattern<>''
GROUP BY 1) a
CROSS JOIN (
SELECT COUNT(*) AS total
FROM splits_overview_runner
WHERE split_number=117
) b)
ORDER BY pattern);

/* Same but to get the consecutive patterns (LIKE how many early dives IN a row */

DROP TABLE IF EXISTS consecutive_patterns_runner;
CREATE TABLE consecutive_patterns_runner AS
SELECT *
FROM (
SELECT lago_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT run_id, lago_pattern, ROW_NUMBER() OVER (PARTITION BY lago_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
FROM(
SELECT DISTINCT a.run_id, lago_pattern,
ROW_NUMBER() OVER (ORDER BY a.run_id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY lago_pattern ORDER BY a.run_id) AS row_number2
FROM splits_overview_runner a
LEFT JOIN splits_overview3_runner b ON a.run_id=b.run_id AND a.split_number=b.split_number
WHERE (a.split_number=14 AND a.lrt_time_dec<117) OR (a.split_number=13 AND cle2_reset=14 AND
CASE WHEN time_end_numeric2>time_ended_numeric AND b.time_run_ended<>time_end_numeric3 THEN time_ended_numeric-time_end_numeric2+86400 ELSE time_ended_numeric-time_end_numeric2 END>=CASE WHEN runner_name LIKE '%lu%'
AND runner_name LIKE '%is%' THEN 59 ELSE 56 END))
ORDER BY run_id)
GROUP BY 1
UNION
SELECT mendez_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT run_id, mendez_pattern, ROW_NUMBER() OVER (PARTITION BY mendez_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
FROM(
SELECT DISTINCT run_id, mendez_pattern,
ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY mendez_pattern ORDER BY run_id) AS row_number2
FROM splits_overview_runner
WHERE mendez_pattern<>'' AND lrt_time_dec<60)
ORDER BY run_id)
GROUP BY 1
UNION
SELECT catapult_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT run_id, catapult_pattern, ROW_NUMBER() OVER (PARTITION BY catapult_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
FROM(
SELECT DISTINCT run_id, catapult_pattern,
ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY catapult_pattern ORDER BY run_id) AS row_number2
FROM splits_overview_runner
WHERE catapult_pattern<>'' AND lrt_time_dec<40)
ORDER BY run_id)
GROUP BY 1
UNION
SELECT cabin_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT run_id, cabin_pattern, ROW_NUMBER() OVER (PARTITION BY cabin_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
FROM(
SELECT DISTINCT run_id, cabin_pattern,
ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY cabin_pattern ORDER BY run_id) AS row_number2
FROM splits_overview_runner
WHERE cabin_pattern<>''
)
ORDER BY run_id)
GROUP BY 1
UNION
SELECT water_hall_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT run_id, water_hall_pattern, ROW_NUMBER() OVER (PARTITION BY water_hall_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
FROM(
SELECT DISTINCT run_id, water_hall_pattern,
ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY water_hall_pattern ORDER BY run_id) AS row_number2
FROM splits_overview_runner
WHERE water_hall_pattern<>''
)
ORDER BY run_id)
GROUP BY 1
UNION
SELECT novis1_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT run_id, novis1_pattern, ROW_NUMBER() OVER (PARTITION BY novis1_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
FROM(
SELECT DISTINCT run_id, novis1_pattern,
ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY novis1_pattern ORDER BY run_id) AS row_number2
FROM splits_overview_runner
WHERE novis1_pattern<>''
)
ORDER BY run_id)
GROUP BY 1
UNION
SELECT gallery_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT run_id, gallery_pattern, ROW_NUMBER() OVER (PARTITION BY gallery_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
FROM(
SELECT DISTINCT run_id, gallery_pattern,
ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY gallery_pattern ORDER BY run_id) AS row_number2
FROM splits_overview_runner
WHERE gallery_pattern<>''
)
ORDER BY run_id)
GROUP BY 1
UNION
SELECT novis2_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT run_id, novis2_pattern, ROW_NUMBER() OVER (PARTITION BY novis2_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
FROM(
SELECT DISTINCT run_id, novis2_pattern,
ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY novis2_pattern ORDER BY run_id) AS row_number2
FROM splits_overview_runner
WHERE novis2_pattern<>''
)
ORDER BY run_id)
GROUP BY 1
UNION
SELECT novis3_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT run_id, novis3_pattern, ROW_NUMBER() OVER (PARTITION BY novis3_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
FROM(
SELECT DISTINCT run_id, novis3_pattern,
ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY novis3_pattern ORDER BY run_id) AS row_number2
FROM splits_overview_runner
WHERE novis3_pattern<>''
)
ORDER BY run_id)
GROUP BY 1
UNION
SELECT u3_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT run_id, u3_pattern, ROW_NUMBER() OVER (PARTITION BY u3_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
FROM(
SELECT DISTINCT run_id, u3_pattern,
ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY u3_pattern ORDER BY run_id) AS row_number2
FROM splits_overview_runner
WHERE u3_pattern<>''
)
ORDER BY run_id)
GROUP BY 1
UNION
SELECT krauser_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT run_id, krauser_pattern, ROW_NUMBER() OVER (PARTITION BY krauser_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
FROM(
SELECT DISTINCT run_id, krauser_pattern,
ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY krauser_pattern ORDER BY run_id) AS row_number2
FROM splits_overview_runner
WHERE krauser_pattern<>''
)
ORDER BY run_id)
GROUP BY 1
UNION
SELECT war_room_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT run_id, war_room_pattern, ROW_NUMBER() OVER (PARTITION BY war_room_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
FROM(
SELECT DISTINCT run_id, war_room_pattern,
ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY war_room_pattern ORDER BY run_id) AS row_number2
FROM splits_overview_runner
WHERE war_room_pattern<>''
)
ORDER BY run_id)
GROUP BY 1
UNION
SELECT key_card_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT run_id, key_card_pattern, ROW_NUMBER() OVER (PARTITION BY key_card_pattern, ROW_NUMBER - row_number2 ORDER BY run_id) AS rank
FROM(
SELECT DISTINCT run_id, key_card_pattern,
ROW_NUMBER() OVER (ORDER BY run_id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY key_card_pattern ORDER BY run_id) AS row_number2
FROM splits_overview_runner
WHERE key_card_pattern<>''
)
ORDER BY run_id)
GROUP BY 1

)
ORDER BY lago_pattern;

--#endregion

--#region USEFUL QUERIES

/* Script is finished, here we have some useful queries */

/* All chapter golds with doorsplits golds combined per chapter */

DROP TABLE IF EXISTS chapter_golds_sheet_runner;
CREATE TABLE chapter_golds_sheet_runner AS
SELECT
    a.chapter,
    a.run_id,
    a.date_run_started,
    a.final_lrt_time,
    a.pb,
    a.chapter_gold2,
    CASE
        WHEN cumulative_chapter_gold2 < 60
            THEN TO_CHAR(cumulative_chapter_gold2, 'FM00.000')
        ELSE
            FLOOR(cumulative_chapter_gold2 / 60) || ':' || TO_CHAR(cumulative_chapter_gold2 % 60, 'FM00.000')
    END AS doorsplit_combined_gold,
    cumulative_chapter_gold2 AS doorsplit_combined_gold2,
    a.cumulative_chapter_gold,
    cumulative_door_gold,
    cumulative_door_gold_num,
    avg_chapter_time2,
    chapter_gold_at_that_time AS previous_chapter_gold
FROM chapter_golds3_runner a
LEFT JOIN (SELECT chapter, SUM(gold) AS cumulative_chapter_gold2
           FROM(
SELECT chapter, a.gold, a.gold2, a.split_number, MIN(cumulative_door_gold) AS cumulative_door_gold
FROM doorsplit_golds2_runner a
LEFT JOIN (SELECT DISTINCT split_number, chapter FROM splits_overview_runner) b ON a.split_number=b.split_number
               GROUP BY chapter, a.gold, a.gold2, a.split_number ORDER BY a.split_number) b
          GROUP BY chapter) bb ON a.chapter=bb.chapter
LEFT JOIN (SELECT *
           FROM (SELECT split_number, chapter, cumulative_door_gold, cumulative_door_gold_num, ROW_NUMBER() OVER(PARTITION BY chapter
ORDER BY split_number DESC) AS rang FROM splits_overview_runner) a WHERE rang=1) c ON a.chapter=c.chapter
LEFT JOIN (SELECT DISTINCT run_id, chapter, chapter_gold_at_that_time
           FROM splits_overview_runner WHERE chapter_time2=chapter_gold2) d ON a.chapter=d.chapter AND a.run_id=d.run_id;

/* All _section golds with doorsplits golds combined per _section + chapter golds combined per _section */

DROP TABLE IF EXISTS section_golds_sheet_runner;
CREATE TABLE section_golds_sheet_runner AS
SELECT a._section, a.run_id, a.date_run_started, a.final_lrt_time, a.pb, a.section_gold2,
CASE

    WHEN cumulative_chapter_gold3 < 10
        THEN TO_CHAR(cumulative_chapter_gold3, 'FM0.000')
    WHEN cumulative_chapter_gold3 < 60
        THEN TO_CHAR(cumulative_chapter_gold3, 'FM00.000')
    WHEN cumulative_chapter_gold3 < 3600
        THEN FLOOR(cumulative_chapter_gold3 / 60) || ':' || TO_CHAR(cumulative_chapter_gold3 % 60, 'FM00.000')
    ELSE
        FLOOR(cumulative_chapter_gold3 / 3600) || ':' || FLOOR((cumulative_chapter_gold3 - 3600) / 60) || ':' || TO_CHAR(cumulative_chapter_gold3 % 60, 'FM00.000')

END AS chapter_combined_gold, cumulative_chapter_gold3 AS chapter_combined_gold2,

CASE
    WHEN cumulative_chapter_gold2 < 10
        THEN TO_CHAR(cumulative_chapter_gold2, 'FM0.000')
    WHEN cumulative_chapter_gold2 < 60
        THEN TO_CHAR(cumulative_chapter_gold2, 'FM00.000')
    WHEN cumulative_chapter_gold2 < 3600
        THEN FLOOR(cumulative_chapter_gold2 / 60) || ':' || TO_CHAR(cumulative_chapter_gold2 % 60, 'FM00.000')
    ELSE
        FLOOR(cumulative_chapter_gold2 / 3600) || ':' || FLOOR((cumulative_chapter_gold2 - 3600) / 60) || ':' || TO_CHAR(cumulative_chapter_gold2 % 60, 'FM00.000')

END AS doorsplit_combined_gold, cumulative_chapter_gold2 AS doorsplit_combined_gold2, a.cumulative_section_gold,
cumulative_chapter_gold, cumulative_chapter_gold_num, cumulative_door_gold, cumulative_door_gold_num, a.section_avg2, section_gold_at_that_time AS previous_section_gold
FROM section_golds3_runner a
LEFT JOIN (SELECT _section, SUM(gold) AS cumulative_chapter_gold2
           FROM(
SELECT DISTINCT _section, a.gold, a.gold2, a.split_number
FROM doorsplit_golds2_runner a
LEFT JOIN (SELECT DISTINCT split_number, _section FROM splits_overview_runner) b ON a.split_number=b.split_number) b
          GROUP BY _section) bb ON a._section=bb._section
LEFT JOIN (SELECT *
           FROM (SELECT split_number, _section, cumulative_door_gold, cumulative_door_gold_num, ROW_NUMBER() OVER(PARTITION BY _section
ORDER BY split_number DESC) AS rang FROM splits_overview_runner) a WHERE rang=1) c ON a._section=c._section

LEFT JOIN (SELECT _section, SUM(chapter_gold) AS cumulative_chapter_gold3
           FROM(
SELECT _section, a.chapter_gold, a.chapter_gold2, a.chapter, MIN(cumulative_chapter_gold) AS cumulative_chapter_gold
FROM chapter_golds3_runner a
LEFT JOIN (SELECT DISTINCT chapter, _section FROM splits_overview_runner) b ON a.chapter=b.chapter
               GROUP BY _section, a.chapter_gold, a.chapter_gold2, a.chapter ORDER BY a.chapter) b
          GROUP BY _section) d ON a._section=d._section
LEFT JOIN (SELECT *
           FROM (SELECT chapter, _section, cumulative_chapter_gold, cumulative_chapter_gold_num, ROW_NUMBER() OVER(PARTITION BY _section
ORDER BY chapter DESC) AS rang FROM splits_overview_runner) a WHERE rang=1) e ON a._section=e._section
LEFT JOIN (SELECT DISTINCT run_id, _section, section_gold_at_that_time
           FROM splits_overview_runner WHERE section_time2=section_gold2) f ON a._section=f._section AND a.run_id=f.run_id
ORDER BY CASE WHEN a._section='Village' THEN 1 WHEN a._section='Castle' THEN 2 ELSE 3 END;

/* Getting the history of PBs by the day of the week */

DROP TABLE IF EXISTS weekday_data_runner;
CREATE TABLE weekday_data_runner AS
SELECT a.*, golds, chapter_golds, section_golds, best_paces,
attempts/CASE WHEN number_of_pbs=0 THEN NULL ELSE number_of_pbs END AS attempts_to_get_a_pb,
ROUND((ROUND(golds, 4)/ROUND(attempts, 4))*100, 2)||'%' AS golds_ratio,
ROUND((ROUND(chapter_golds, 4)/ROUND(attempts, 4))*100, 2)||'%' AS chapter_golds_ratio,
ROUND((ROUND(section_golds, 4)/ROUND(attempts, 4))*100, 2)||'%' AS section_golds_ratio,
ROUND((ROUND(best_paces, 4)/ROUND(attempts, 4))*100, 2)||'%' AS best_paces_ratio,
ROUND(ROUND(attempts, 2)/CASE WHEN golds=0 THEN NULL ELSE golds END, 2) AS attempts_to_get_a_gold,
ROUND(ROUND(attempts, 2)/CASE WHEN chapter_golds=0 THEN NULL ELSE chapter_golds END, 2) AS attempts_to_get_a_chapter_gold,
ROUND(ROUND(attempts, 2)/CASE WHEN section_golds=0 THEN NULL ELSE section_golds END, 2) AS attempts_to_get_a_section_gold,
ROUND(ROUND(attempts, 2)/CASE WHEN best_paces=0 THEN NULL ELSE best_paces END, 2) AS attempts_to_get_a_best_pace,
playtime/CASE WHEN golds=0 THEN NULL ELSE golds END AS playtime_to_get_a_gold,
playtime/CASE WHEN chapter_golds=0 THEN NULL ELSE chapter_golds END AS playtime_to_get_a_chapter_gold,
playtime/CASE WHEN section_golds=0 THEN NULL ELSE section_golds END AS playtime_to_get_a_section_gold,
playtime/CASE WHEN best_paces=0 THEN NULL ELSE best_paces END AS playtime_to_get_a_best_pace
FROM (SELECT CASE WHEN extract(DOW FROM date_run_started)=0 THEN 7 ELSE extract(DOW FROM date_run_started) END AS weekday,
SUM(run_duration) AS playtime, COUNT(DISTINCT run_id) AS attempts, COUNT(DISTINCT CASE WHEN pb=1 THEN run_id ELSE NULL END) AS number_of_pbs,
ROUND(ROUND(ROUND(COUNT(DISTINCT CASE WHEN pb=1 THEN run_id ELSE NULL END), 4)/ROUND(COUNT(DISTINCT run_id), 4), 4)*100, 2)||'%' AS pb_ratio,
ROUND(SUM(run_duration))/CASE WHEN ROUND(COUNT(DISTINCT CASE WHEN pb=1 THEN run_id ELSE NULL END))=0 THEN NULL ELSE
ROUND(COUNT(DISTINCT CASE WHEN pb=1 THEN run_id ELSE NULL END)) END playtime_to_get_a_pb
FROM attempts_data5_runner
GROUP BY 1) a
LEFT JOIN (
SELECT CASE WHEN extract(DOW FROM date_run_started)=0 THEN 7 ELSE extract(DOW FROM date_run_started) END AS weekday, SUM(golded_split) AS golds,
SUM(golded_chapter) AS chapter_golds, SUM(golded_section) AS section_golds, SUM(was_best_pace) AS best_paces
FROM splits_overview_runner
GROUP BY 1) b ON a.weekday=b.weekday
ORDER BY a.weekday;

--#endregion