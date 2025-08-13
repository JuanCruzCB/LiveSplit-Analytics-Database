/* Importing the original splits file */

DROP TABLE IF EXISTS splits_runner;
CREATE TABLE splits_runner (notepad_info VARCHAR (255));

COPY splits_runner FROM 'path' WITH DELIMITER ','; /* NOTE: The path to the splits file needs to be public, so that Postgres can access it */

/* Creating a table with default split names */

DROP TABLE IF EXISTS default_split_names_runner;
CREATE TABLE default_split_names_runner (split VARCHAR(255), cle2 INTEGER);

INSERT INTO default_split_names_runner (split, cle2)
VALUES
	('-Start', 1),
	('-Village', 2),
	('-Farm', 3),
	('{1-1} Boulder', 4),
	('-Canyon', 5),
	('-Factory', 6),
	('{1-2} Enter House', 7),
	('-Exit House', 8),
	('-Village 2', 9),
	('-Underground', 10),
	('-Graveyard', 11),
	('-Crows', 12),
	('-Swamp', 13),
	('{1-3} Del Lago', 14),
	('-Wake Up', 15),
	('-Waterfall', 16),
	('-Boat Ride', 17),
	('-El Gigante', 18),
	('-Dogs', 19),
	('{2-1} Church', 20),
	('-Ashley', 21),
	('-Graveyard 2', 22),
	('-Underground 2', 23),
	('-Village 3', 24),
	('-Farm 2', 25),
	('{2-2} Cabin', 26),
	('-Lever', 27),
	('-El Gigante 2', 28),
	('-Gondola', 29),
	('-Mendez', 30),
	('-Gondola 2', 31),
	('{2-3} Truck', 32),
	('-Enter Castle', 33),
	('-Catapults', 34),
	('-Swords Room', 35),
	('-Castle Key', 36),
	('-Garrador', 37),
	('-Water Hall', 38),
	('{3-1} Ceremony Room', 39),
	('-Ceremony Room', 40),
	('-Novistadors 1', 41),
	('-Ceremony Room 2', 42),
	('-Gallery', 43),
	('-Fountain', 44),
	('{3-2} Maze', 45),
	('-Bedroom', 46),
	('-Cage', 47),
	('{3-3} Bridge', 48),
	('-Save Ashley', 49),
	('-Cranks', 50),
	('-Puzzle', 51),
	('{3-4} Exit', 52),
	('-Reunited', 53),
	('-Cart Room', 54),
	('-Lava Room', 55),
	('-Cart Room 2', 56),
	('-Chimera Wall', 57),
	('-Cart Room 3', 58),
	('-Hallway', 59),
	('-Queen''s Grail', 60),
	('-Hallway 2', 61),
	('-King''s Grail', 62),
	('-Hallway 3', 63),
	('-Novistadors 2', 64),
	('-Catapults 2', 65),
	('-Clock Tower', 66),
	('-Bridge', 67),
	('-Garradors', 68),
	('-Striker', 69),
	('{4-1} Verdugo', 70),
	('-Merchant', 71),
	('-Boulder', 72),
	('-El Gigantes', 73),
	('{4-2} Novistadors 3', 74),
	('-Ruins', 75),
	('-Enter Mines', 76),
	('-Minecart', 77),
	('{4-3} Emblem', 78),
	('-Salazar Statue', 79),
	('-Elevator', 80),
	('-Salazar', 81),
	('{4-4} Exit', 82),
	('-Enter Island', 83),
	('-Outside Facility', 84),
	('-Oven Man', 85),
	('-Monitor Room', 86),
	('-Garage Door', 87),
	('-Hallway 4', 88),
	('-Regenerator', 89),
	('-Hallway 5', 90),
	('-Freezer', 91),
	('-Hallway 6', 92),
	('-Trash Room', 93),
	('-Cell', 94),
	('-Stairs Room', 95),
	('-Iron Maiden', 96),
	('-Stairs Room 2', 97),
	('{5-1} Cell', 98),
	('-Ashley''s Back', 99),
	('-Observation Room', 100),
	('-Iron Maidens', 101),
	('-Wrecking Ball', 102),
	('-Regenerators', 103),
	('-Truck', 104),
	('{5-2} Merchant', 105),
	('-Ceremony Room 3', 106),
	('-Krauser', 107),
	('-Lasers', 108),
	('-Cave', 109),
	('-U-3', 110),
	('-Tents', 111),
	('{5-3} Krauser', 112),
	('-Military Area', 113),
	('-RIP Mike', 114),
	('-Ruins 2', 115),
	('-Jail', 116),
	('-Key Card', 117),
	('-Ashley Again', 118),
	('{5-4} Plaga Removal', 119),
	('-Exit', 120),
	('-Construction Site', 121),
	('-Saddler', 122),
	('{End} Jetski', 123);

/* Creating the rng names for each pattern */

DROP TABLE IF EXISTS rng;
CREATE TABLE rng (pattern VARCHAR(255));

INSERT INTO rng (pattern)
VALUES
	('1-a No dive'),
	('1-b Late dive'),
	('1-c Early dive'),
	('2-a Fast Mendez'),
	('2-b Medium Mendez'),
	('2-c Slow Mendez'),
	('3-a Perfect catapult'),
	('3-b Stagger catapult'),
	('3-c Boulder catapult'),
	('4-a Great cabin'),
	('4-b Good cabin'),
	('4-c Average cabin'),
	('4-d Bad cabin'),
	('4-e Shitty cabin'),
	('5-a Great water hall'),
	('5-b Good water hall'),
	('5-c Average water hall'),
	('5-d Bad water hall'),
	('5-e Shitty water hall'),
	('6-a Great novis 1'),
	('6-b Good novis 1'),
	('6-c Average novis 1'),
	('6-d Bad novis 1'),
	('6-e Shitty novis 1'),
	('7-a Great gallery'),
	('7-b Good gallery'),
	('7-c Average gallery'),
	('7-d Bad gallery'),
	('7-e Shitty gallery'),
	('8-a Great novis 2'),
	('8-b Good novis 2'),
	('8-c Average novis 2'),
	('8-d Bad novis 2'),
	('8-e Shitty novis 2'),
	('9-a Great novis 3'),
	('9-b Good novis 3'),
	('9-c Average novis 3'),
	('9-d Bad novis 3'),
	('9-e Shitty novis 3'),
	('90-a Great u3'),
	('90-b Good u3'),
	('90-c Average u3'),
	('90-d Bad u3'),
	('90-e Shitty u3'),
	('91-a Great Krauser'),
	('91-b Good Krauser'),
	('91-c Average Krauser'),
	('91-d Bad Krauser'),
	('91-e Shitty Krauser'),
	('92-a Great war room'),
	('92-b Good war room'),
	('92-c Average war room'),
	('92-d Bad war room'),
	('92-e Shitty war room'),
	('93-a Great key card'),
	('93-b Good key card'),
	('93-c Average key card'),
	('93-d Bad key card'),
	('93-e Shitty key card');

/* Creating a table with all the decimals (2 digits) FROM 0 to 1 */

DROP TABLE IF EXISTS decimals_table_runner;
CREATE TABLE decimals_table_runner (numb DECIMAL);

INSERT INTO decimals_table_runner (numb)
VALUES
	(0.01),
	(0.02),
	(0.03),
	(0.04),
	(0.05),
	(0.06),
	(0.07),
	(0.08),
	(0.09),
	(0.1),
	(0.11),
	(0.12),
	(0.13),
	(0.14),
	(0.15),
	(0.16),
	(0.17),
	(0.18),
	(0.19),
	(0.2),
	(0.21),
	(0.22),
	(0.23),
	(0.24),
	(0.25),
	(0.26),
	(0.27),
	(0.28),
	(0.29),
	(0.3),
	(0.31),
	(0.32),
	(0.33),
	(0.34),
	(0.35),
	(0.36),
	(0.37),
	(0.38),
	(0.39),
	(0.4),
	(0.41),
	(0.42),
	(0.43),
	(0.44),
	(0.45),
	(0.46),
	(0.47),
	(0.48),
	(0.49),
	(0.5),
	(0.51),
	(0.52),
	(0.53),
	(0.54),
	(0.55),
	(0.56),
	(0.57),
	(0.58),
	(0.59),
	(0.6),
	(0.61),
	(0.62),
	(0.63),
	(0.64),
	(0.65),
	(0.66),
	(0.67),
	(0.68),
	(0.69),
	(0.7),
	(0.71),
	(0.72),
	(0.73),
	(0.74),
	(0.75),
	(0.76),
	(0.77),
	(0.78),
	(0.79),
	(0.8),
	(0.81),
	(0.82),
	(0.83),
	(0.84),
	(0.85),
	(0.86),
	(0.87),
	(0.88),
	(0.89),
	(0.9),
	(0.91),
	(0.92),
	(0.93),
	(0.94),
	(0.95),
	(0.96),
	(0.97),
	(0.98),
	(0.99);

/* We imported the whole splits including the LiveSplit settings AND stuff, now we want to only keep the part with the segments history (to get the golds, best paces, etc.)=part 1 */

DROP TABLE IF EXISTS notepad_splits_runner;
CREATE TABLE notepad_splits_runner AS
SELECT ltrim(notepad_info, ' ') AS notepad_info
FROM (SELECT *, ROW_NUMBER() OVER () AS cle
FROM splits_runner) a
WHERE cle >
(SELECT cle
FROM (SELECT *, ROW_NUMBER() OVER ()+1 AS cle
FROM splits_runner) a
WHERE notepad_info LIKE '%</AttemptHistory>%')
AND cle<
(SELECT cle
FROM (SELECT *, ROW_NUMBER() OVER () AS cle
FROM splits_runner) a
WHERE notepad_info LIKE '%<AutoSplitterSettings%');

/* We do the same for the attempts (to get the date of the run, if the run was finished, if it was a PB, etc.)=part 2*/

DROP TABLE IF EXISTS notepad_attempts_runner;
CREATE TABLE notepad_attempts_runner AS
SELECT ltrim(notepad_info, ' ') AS notepad_info, 'runner' AS runner_name
FROM (SELECT *, ROW_NUMBER() OVER () AS cle
FROM splits_runner) a
WHERE cle >
(SELECT cle
FROM (SELECT *, ROW_NUMBER() OVER () AS cle
FROM splits_runner) a
WHERE notepad_info LIKE '%<AttemptHistory>%')
AND cle<
(SELECT cle
FROM (SELECT *, ROW_NUMBER() OVER () AS cle
FROM splits_runner) a
WHERE notepad_info LIKE '%</AttemptHistory>%');

DROP TABLE IF EXISTS splits_treatment_runner;
CREATE TABLE splits_treatment_runner AS
SELECT

/* Retrieving the run id FROM the notepad info, it's only present WHERE the row contains <Time id="4">, this means it's the run id number 4, for the parts that don't contain that, we simply leave it blank, for the rest, it will depend ON the length of the variable, if it's run id = 150 the length will be 1 extra compared to run id = 50 because there's obviously one more digit, so depending ON that, there's different cases, I went up to 6 digits, so until run id = 999999. */

CASE WHEN notepad_info NOT LIKE '%Time id%' THEN ''
WHEN LENGTH(notepad_info)=13 THEN substr(substr(notepad_info, 11, 1), 1, 1)
WHEN LENGTH(notepad_info)=14 THEN substr(substr(notepad_info, 11, 2), 1, 2)
WHEN LENGTH(notepad_info)=15 THEN substr(substr(notepad_info, 11, 3), 1, 3)
WHEN LENGTH(notepad_info)=16 THEN substr(substr(notepad_info, 11, 4), 1, 4)
WHEN LENGTH(notepad_info)=17 THEN substr(substr(notepad_info, 11, 5), 1, 5)
WHEN LENGTH(notepad_info)=18 THEN substr(substr(notepad_info, 11, 6), 1, 6)
ELSE '' END AS run_id,

/* Retrieving the split name, this one will only show once at the top for each split THEN will list of the times for each run for this specific split */

CASE WHEN notepad_info NOT LIKE '%<Name>%' THEN ''
ELSE substr(substr(notepad_info, 7, LENGTH(notepad_info)-6), 1, LENGTH(notepad_info)-13) END AS split_name,

/* Retrieving the lrt time of the split */

CASE WHEN notepad_info NOT LIKE '%<GameTime>%' THEN ''
ELSE substr(substr(notepad_info, 11, LENGTH(notepad_info)-10), 1, LENGTH(notepad_info)-21) END AS lrt,
CASE WHEN notepad_info NOT LIKE '%<RealTime>%' THEN ''
ELSE substr(substr(notepad_info, 11, LENGTH(notepad_info)-10), 1, LENGTH(notepad_info)-21) END AS rta_split,
notepad_info AS info, ROW_NUMBER() OVER () AS cle /* This ROW_NUMBER can be useful to have a unique key for each row */
FROM notepad_splits_runner;

DROP TABLE IF EXISTS splits_treatment2_runner;
CREATE TABLE splits_treatment2_runner AS
SELECT *,

/* Converting the run id AS an INTEGER, sometimes (rare) there are some run ids with no time for a specific split (because it was deleted by the runner) so it will show just id without a time AND THEN the run id IN this case will NOT be for example 100 but 100" so it will mess up the INTEGER conversion, so for these rare cases we force them AS 0 AS done IN this CASE WHEN, we also force the other blank rows to 0 */

CASE WHEN (info LIKE '%<Time id=%' AND info LIKE '% />%') OR run_id='' THEN 0
ELSE CAST(run_id AS INTEGER) END AS run_id2,

/* The LRT times for each split are showing 2 rows after the run id, we want everything ON the same row so we just do the lead function, we want the information FROM 2 rows after the run id but also 1 row after run id because sometimes the RTA is NOT showing (negative runs) AND it just has the LRT available, so IN that case we just take the next row AND NOT the one after it */

LEAD(lrt) OVER(ORDER BY cle) AS lead,
LEAD(lrt, 2) OVER (ORDER BY cle) AS lead2,
LEAD(rta_split) OVER(ORDER BY cle) AS lead_rta
FROM splits_treatment_runner;

/* Now putting back the LRT times that are 2 rows below the row we want (OR 1 row below if no RTA time) IN the same row AS the other info (run id, etc.) AND removing the other intermediate unnecessary columns */

DROP TABLE IF EXISTS splits_treatment3_runner;
CREATE TABLE splits_treatment3_runner AS
SELECT split_name, info, cle, run_id2,
CASE WHEN run_id2=0 THEN '' WHEN run_id2<0 THEN lead ELSE lead2 END AS lrt2,
CASE WHEN run_id2<=0 THEN '' ELSE lead_rta END AS rta2
FROM splits_treatment2_runner;

/* Now that we have the run ids AND the LRT times IN the same row, we just need to get the split names ON the same row too, for that we SELECT the minimum row number for each split (using the "cle" variable we created with the ROW_NUMBER function) which tells us at which row starts the new split (so the previous split ends 1 row before that) */

DROP TABLE IF EXISTS split_name_info_runner;
CREATE TABLE split_name_info_runner AS
SELECT DISTINCT split_name, rang, MIN(cle) AS min
FROM(
SELECT DISTINCT split_name, ROW_NUMBER() OVER (PARTITION BY split_name ORDER BY cle) AS rang, cle
FROM splits_treatment3_runner
WHERE split_name<>'') a
GROUP BY 1, 2
ORDER BY 3;

DROP TABLE IF EXISTS split_name_info2_runner;
CREATE TABLE split_name_info2_runner AS
SELECT *,

/* Now that we have the min row for each split name, it's easy to get the max, it's just the min of the next split-1, we also create a second "cle" variable "cle2" which also uses a ROW_NUMBER function but this time only with the 123 rows of the 123 unique splits (AND NOT the whole LiveSplit history rows), this will be useful to create the chapters AND sections */

LEAD(min) OVER(ORDER BY min)-1 AS max, ROW_NUMBER() OVER() AS cle2
FROM split_name_info_runner;

DROP TABLE IF EXISTS split_name_info3_runner;
CREATE TABLE split_name_info3_runner AS
SELECT *,

/* Getting the chapter AND section for each split using the "cle2" variable created just above, we know that 1-1 has only 4 splits if cle2 is between 1 AND 4, we know it's one of the first 4 splits AND therefore it's 1-1, etc.
THEN doing the same for sections, technically we didn't need to created a cle2 variable, the original cle variable was already enough, but it would have been a bit harder to create the chapter AND section names since it depends ON each runners splits, for example a runner could have 10K rows of 1-1 THEN 8K rows of 1-2, etc. so we'd have to identify the chapters using the split names AND stuff, here it's easy since it's the same for everyone, everyone has 4 splits IN 1-1, etc. (NOT to mention cle2 is actually a very useful variable AND had to be created anyway, since it's the split number, so cle2=1 means it's the first split of the run, etc. It's better to use the id of the split instead of its name, since NOT all the runners have the same split names (this also skips the part WHERE everyone needs to have the same split names for the script to work) */

CASE WHEN cle2<=4 THEN '1-1'
WHEN cle2<=7 THEN '1-2'
WHEN cle2<=14 THEN '1-3'
WHEN cle2<=20 THEN '2-1'
WHEN cle2<=26 THEN '2-2'
WHEN cle2<=32 THEN '2-3'
WHEN cle2<=39 THEN '3-1'
WHEN cle2<=45 THEN '3-2'
WHEN cle2<=48 THEN '3-3'
WHEN cle2<=52 THEN '3-4'
WHEN cle2<=70 THEN '4-1'
WHEN cle2<=74 THEN '4-2'
WHEN cle2<=78 THEN '4-3'
WHEN cle2<=82 THEN '4-4'
WHEN cle2<=98 THEN '5-1'
WHEN cle2<=105 THEN '5-2'
WHEN cle2<=112 THEN '5-3'
WHEN cle2<=119 THEN '5-4'
ELSE '6-1' END AS chapter,
CASE WHEN cle2<=32 THEN 'Village'
WHEN cle2<=82 THEN 'Castle'
ELSE 'Island' END AS section
FROM split_name_info2_runner;

DROP TABLE IF EXISTS splits_treatment4_runner;
CREATE TABLE splits_treatment4_runner AS

/* Now that the split names are finished (+chapter AND section names added) we JOIN that table with the table we had that has run ids AND LRT times ON the same row, now it will have the split names (+chapter AND section names) ON the same row too, because AS explained above, the split name ON the original file only shows once at the top AND THEN just lists the times history without displaying the split name, so we need that for each row

Just LIKE we did for run ids AND LRT times, we make the split name empty ON the rows we don't want (there are a lot of unnecessary rows IN the original file since all the data has 1 info per row (for example split name, LRT time AND run id will show ON 3 different rows ON the original file, but since here we put everything IN the same row, we only keep one row out of the 3 AND the other 2 are useless, so we delete them, it also makes the file a bit lighter since we now have much less rows to work with */

SELECT info, cle, run_id2, lrt2, CASE WHEN lrt2='' THEN '' ELSE b.split_name END AS split_name2, chapter, section, cle2, rta2
FROM splits_treatment3_runner a
LEFT JOIN split_name_info3_runner b ON a.cle>=b.min AND a.cle<=CASE WHEN b.max IS NULL THEN 10000000 ELSE b.max END
ORDER BY cle;

DROP TABLE IF EXISTS splits_treatment5_runner;
CREATE TABLE splits_treatment5_runner AS
SELECT info, cle, run_id2, lrt2, split_name2, chapter, section, cle2,
ROUND(hours*3600+minutes*60+seconds+milliseconds/10000000, 7) AS lrt3,
rta2, ROUND(hours_rta*3600+minutes_rta*60+seconds_rta+milliseconds_rta/10000000, 7) AS rta3
FROM(
SELECT *,

/* Converting the LRT times FROM character (wrong format) to numbers */

CASE WHEN lrt2='' THEN 0 ELSE CAST(substr(lrt2, 1, 2) AS INTEGER) END AS hours,
CASE WHEN lrt2='' THEN 0 ELSE CAST(substr(lrt2, 4, 2) AS INTEGER) END AS minutes,
CASE WHEN lrt2='' THEN 0 ELSE CAST(substr(lrt2, 7, 2) AS INTEGER) END AS seconds,
CASE WHEN lrt2='' OR LENGTH(lrt2)=8 THEN 0 ELSE CAST(substr(lrt2, 10, 7) AS DECIMAL) END AS milliseconds,

CASE WHEN rta2='' THEN 0 ELSE CAST(substr(rta2, 1, 2) AS INTEGER) END AS hours_rta,
CASE WHEN rta2='' THEN 0 ELSE CAST(substr(rta2, 4, 2) AS INTEGER) END AS minutes_rta,
CASE WHEN rta2='' THEN 0 ELSE CAST(substr(rta2, 7, 2) AS INTEGER) END AS seconds_rta,
CASE WHEN rta2='' OR LENGTH(rta2)=8 THEN 0 ELSE CAST(substr(rta2, 10, 7) AS DECIMAL) END AS milliseconds_rta
FROM splits_treatment4_runner

/* At this point we only keep the rows that have the information AND we already have everything IN the same row (run id, lrt time AND split name) so we can delete all the rest */

WHERE split_name2<>'');

DROP TABLE IF EXISTS splits_treatment6_runner;
CREATE TABLE splits_treatment6_runner AS
SELECT *,

/* Also adding the LRT time with the same format AS IN LiveSplit, NOT used for calculations (for that we use the number format create IN the table above) but it's just easier to read */

CASE WHEN lrt3-TRUNC(lrt3)=0 THEN (CASE WHEN lrt3<10 THEN substr(lrt2, 8, 5)||'.000'
WHEN lrt3<60 THEN substr(lrt2, 7, 6)||'.000'
WHEN lrt3<600 THEN substr(lrt2, 5, 8)||'.000'
WHEN lrt3<3600 THEN substr(lrt2, 4, 9)||'.000'
WHEN lrt3<36000 THEN lrt2
ELSE '' END)
ELSE (CASE WHEN lrt3<10 THEN substr(lrt2, 8, 5)
WHEN lrt3<60 THEN substr(lrt2, 7, 6)
WHEN lrt3<600 THEN substr(lrt2, 5, 8)
WHEN lrt3<3600 THEN substr(lrt2, 4, 9)
WHEN lrt3<36000 THEN lrt2
ELSE '' END) END AS lrt4,

CASE WHEN rta3-TRUNC(rta3)=0 THEN (CASE WHEN rta3<10 THEN substr(rta2, 8, 5)||'.000'
WHEN rta3<60 THEN substr(rta2, 7, 6)||'.000'
WHEN rta3<600 THEN substr(rta2, 5, 8)||'.000'
WHEN rta3<3600 THEN substr(rta2, 4, 9)||'.000'
WHEN rta3<36000 THEN rta2
ELSE '' END)
ELSE (CASE WHEN rta3<10 THEN substr(rta2, 8, 5)
WHEN rta3<60 THEN substr(rta2, 7, 6)
WHEN rta3<600 THEN substr(rta2, 5, 8)
WHEN rta3<3600 THEN substr(rta2, 4, 9)
WHEN rta3<36000 THEN rta2
ELSE '' END) END AS rta4
FROM splits_treatment5_runner;

/* Treatment of part 1 (segments history) is done, now we need to work ON part 2 (attempts history) with the run ids AND the dates */

DROP TABLE IF EXISTS attempts_treatment_runner;
CREATE TABLE attempts_treatment_runner AS
SELECT *,

/* Retrieving the run id */
CASE WHEN position ('started' IN notepad_info)=17 THEN substr(substr(notepad_info, 1, 14), 14, 1)
WHEN position ('started' IN notepad_info)=18 THEN substr(substr(notepad_info, 1, 15), 14, 2)
WHEN position ('started' IN notepad_info)=19 THEN substr(substr(notepad_info, 1, 16), 14, 3)
WHEN position ('started' IN notepad_info)=20 THEN substr(substr(notepad_info, 1, 17), 14, 4)
WHEN position ('started' IN notepad_info)=21 THEN substr(substr(notepad_info, 1, 18), 14, 5)
ELSE '' END AS run_id,

/* Getting the dates */

substr(substr(notepad_info, position('started' IN notepad_info), 19), 10) AS date,
substr(substr(notepad_info, position('ended' IN notepad_info), 17), 8) AS date_end,
substr(substr(notepad_info, position('started' IN notepad_info), 28), 21) AS time_start,
substr(substr(notepad_info, position('ended' IN notepad_info), 26), 19) AS time_end,

/* Finished run OR NOT for each run id */

CASE WHEN substr(notepad_info, LENGTH(notepad_info)-1, 2)='">' THEN 1 ELSE 0 END AS finished_run,

/* Getting the LRT for each finished run */

CASE WHEN substr(notepad_info, 1, 2)='<G' THEN substr(notepad_info, 11, 8) ELSE '' END AS lrt,
CASE WHEN substr(notepad_info, 1, 2)='<R' THEN substr(notepad_info, 11, 8) ELSE '' END AS rta
FROM notepad_attempts_runner;

/* The finished runs will have their LRT time 2 rows after the run id, so need to put everything IN the same row AS done earlier */

DROP TABLE IF EXISTS attempts_treatment2_runner_old;
CREATE TABLE attempts_treatment2_runner_old AS
SELECT run_id AS id, date AS date_started, finished_run, LEAD(rta, 1) OVER () AS final_rta, LEAD(lrt, 2) OVER () AS final_lrt,
date_end, time_start, time_end, runner_name
FROM attempts_treatment_runner;

DROP TABLE IF EXISTS attempts_treatment2_runner;
CREATE TABLE attempts_treatment2_runner AS
SELECT *
FROM attempts_treatment2_runner_old
WHERE id <> '' AND to_date(substr(date_started, 7, 4) || '-' || substr(date_started, 1, 2) || '-' || substr(date_started, 4, 2), 'YYYY-MM-DD') >= '2024-10-15'; -- TODO: This date needs to be customizable

/* Getting the list of all finished runs AND for each finished run, was it a PB WHEN it was done OR NOT? (which also means getting the LRT PB at that time too) */

DROP TABLE IF EXISTS pb_history_runner_old;
CREATE TABLE pb_history_runner_old AS
SELECT finished_runs.id, finished_runs.final_lrt, MIN(pbs.final_lrt) AS lrt_pb,
CASE WHEN finished_runs.final_lrt=MIN(pbs.final_lrt) THEN 1 ELSE 0 END AS pb
FROM (SELECT *
FROM attempts_treatment2_runner
WHERE final_lrt<>'') finished_runs
JOIN (SELECT *
FROM attempts_treatment2_runner
WHERE final_lrt<>'') pbs ON CAST(finished_runs.id AS INTEGER)>=CAST(pbs.id AS INTEGER)
GROUP BY finished_runs.id, finished_runs.final_lrt
ORDER BY CAST(finished_runs.id AS INTEGER);

/* We now JOIN the attempts history (with dates AND run id ON the same row) with the finished runs information (was it a PB, etc.) to have everything IN the same table. AS earlier, only keeping the good rows AND deleting the rest (since we put everything IN the same row, a lot of rows are now useless. Treatment of part2 is now done */

DROP TABLE IF EXISTS attempts_treatment3_old_runner;
CREATE TABLE attempts_treatment3_old_runner AS
SELECT CAST(a.id AS INTEGER) AS id, finished_run, a.final_lrt, pb, final_rta,
CASE WHEN final_rta='' OR final_rta IS NULL THEN 0 ELSE
CAST(substr(final_rta, 1, 2) AS INTEGER)*3600+CAST(substr(final_rta, 4, 2) AS INTEGER)*60+
CAST(substr(final_rta, 7, 2) AS INTEGER) END AS rta_number,
to_date(substr(date_started, 7, 4)||'-'||substr(date_started, 1, 2)||'-'||substr(date_started, 4, 2), 'YYYY-MM-DD') AS
date_started_livesplit,
to_date(substr(date_end, 7, 4)||'-'||substr(date_end, 1, 2)||'-'||substr(date_end, 4, 2), 'YYYY-MM-DD') AS
date_end_livesplit, time_start AS time_start_livesplit, time_end AS time_end_livesplit,
CAST(substr(time_start, 1, 2) AS INTEGER)*3600+CAST(substr(time_start, 4, 2) AS INTEGER)*60+
CAST(substr(time_start, 7, 2) AS INTEGER) AS time_start_number,
CAST(substr(time_end, 1, 2) AS INTEGER)*3600+CAST(substr(time_end, 4, 2) AS INTEGER)*60+
CAST(substr(time_end, 7, 2) AS INTEGER) AS time_end_number,
CASE WHEN date_started<>date_end THEN 86400+CAST(substr(time_end, 1, 2) AS INTEGER)*3600+CAST(substr(time_end, 4, 2) AS INTEGER)*60+
CAST(substr(time_end, 7, 2) AS INTEGER)-(CAST(substr(time_start, 1, 2) AS INTEGER)*3600+CAST(substr(time_start, 4, 2) AS INTEGER)*60+
CAST(substr(time_start, 7, 2) AS INTEGER)) ELSE
CAST(substr(time_end, 1, 2) AS INTEGER)*3600+CAST(substr(time_end, 4, 2) AS INTEGER)*60+
CAST(substr(time_end, 7, 2) AS INTEGER)-(CAST(substr(time_start, 1, 2) AS INTEGER)*3600+CAST(substr(time_start, 4, 2) AS INTEGER)*60+
CAST(substr(time_start, 7, 2) AS INTEGER)) END AS playtime, 'runner' AS runner_name
FROM attempts_treatment2_runner a
LEFT JOIN pb_history_runner_old b ON a.id=b.id
WHERE a.id<>'';

DROP TABLE IF EXISTS attempts_treatment3_runner;
CREATE TABLE attempts_treatment3_runner AS
SELECT
	*,
	date_started_livesplit AS date_started,
	time_start_livesplit AS time_start,
	date_end_livesplit AS date_end,
	time_end_livesplit AS time_end
FROM attempts_treatment3_old_runner;

/* Getting the list of all PBs, also converting the PBs into number format, can be used for calculations (OR graphs, etc.) */

DROP TABLE IF EXISTS pb_history_runner;
CREATE TABLE pb_history_runner AS
SELECT a.*, CAST(substr(lrt_pb, 1, 2) AS INTEGER)*3600+CAST(substr(lrt_pb, 4, 2) AS INTEGER)*60+
CAST(substr(lrt_pb, 7, 2) AS INTEGER) AS pb_lrt, date_started-COALESCE(LAG(date_started) OVER(ORDER BY CAST(a.id AS INTEGER)), date_started)
AS days_it_took, CAST(a.id AS INTEGER)-COALESCE(LAG(CAST(a.id AS INTEGER)) OVER(ORDER BY CAST(a.id AS INTEGER)),0) attempts_it_took,
total_playtime-COALESCE(LAG(total_playtime) OVER(ORDER BY CAST(a.id AS INTEGER)), 0) total_playtime_it_took,
days_attempts-COALESCE(LAG(days_attempts) OVER(ORDER BY CAST (a.id AS INTEGER)), 0) AS days_of_attempts_it_took
FROM(
SELECT finished_runs.id, finished_runs.final_lrt, finished_runs.date_started, MIN(pbs.final_lrt) AS lrt_pb,
CASE WHEN finished_runs.final_lrt=MIN(pbs.final_lrt) THEN 1 ELSE 0 END AS pb
FROM (SELECT *
FROM attempts_treatment3_runner
WHERE final_lrt<>''
AND date_started>='2024-10-14') finished_runs
JOIN (SELECT *
FROM attempts_treatment3_runner
WHERE final_lrt<>''
AND date_started>='2024-10-14') pbs ON CAST(finished_runs.id AS INTEGER)>=CAST(pbs.id AS INTEGER)
GROUP BY finished_runs.id, finished_runs.final_lrt, finished_runs.date_started
ORDER BY CAST(finished_runs.id AS INTEGER)) a
LEFT JOIN (SELECT a.id, a.playtime, SUM(b.playtime) AS total_playtime
FROM attempts_treatment3_runner a
LEFT JOIN attempts_treatment3_runner b ON a.id>=b.id
GROUP BY a.id, a.playtime
ORDER BY a.id) b ON a.id=b.id
LEFT JOIN (SELECT a.id, COUNT(DISTINCT b.date_started)-1 AS days_attempts
FROM attempts_treatment3_runner a
LEFT JOIN attempts_treatment3_runner b ON a.id>=b.id
GROUP BY a.id
ORDER BY a.id) c ON a.id=c.id
WHERE pb=1;

/* Final table that is going to be used to get the actual data (chapter golds, etc.), we combine the 2 cleaned tables after treatments (splits history AND attempts history, so part 1 AND 2) Also converting the dates of the runs FROM part2 into date format */

DROP TABLE IF EXISTS splits_cleaned_runner_old;
CREATE TABLE splits_cleaned_runner_old AS
SELECT run_id2 AS id, split_name2 AS split, chapter, section, lrt3 AS lrt_number, lrt4 AS lrt_split,
date_started_livesplit, finished_run, final_lrt, pb, cle2, final_rta, date_end_livesplit, time_start_livesplit, time_end_livesplit, playtime,
date_started, time_start, date_end,
time_end, rta3 AS rta_numeric, rta4 AS rta_split
FROM splits_treatment6_runner a
LEFT JOIN attempts_treatment3_runner b ON a.run_id2=b.id;

DROP TABLE IF EXISTS rta_cumulative_runner;
CREATE TABLE rta_cumulative_runner AS
SELECT a.id, a.cle2, SUM(b.rta_numeric) AS cumulative_rta
FROM splits_cleaned_runner_old a
LEFT JOIN (SELECT DISTINCT id, cle2, rta_numeric FROM splits_cleaned_runner_old) b ON a.cle2>=b.cle2 AND a.id=b.id
GROUP BY 1, 2
ORDER BY 1, 2;

DROP TABLE IF EXISTS splits_cleaned_runner_old2;
CREATE TABLE splits_cleaned_runner_old2 AS
SELECT a.*, cumulative_rta, LAG(cumulative_rta) OVER(PARTITION BY a.id ORDER BY a.cle2) AS lag_rta, CAST(substr(time_start, 1, 2) AS NUMERIC)*3600
+CAST(substr(time_start, 4, 2) AS NUMERIC)*60+CAST(substr(time_start, 7, 2) AS NUMERIC) AS time_start_numeric,
CAST(substr(time_end, 1, 2) AS NUMERIC)*3600
+CAST(substr(time_end, 4, 2) AS NUMERIC)*60+CAST(substr(time_end, 7, 2) AS NUMERIC) AS time_end_numeric, 'runner' AS runner_name
FROM splits_cleaned_runner_old a
LEFT JOIN rta_cumulative_runner b ON a.id=b.id AND a.cle2=b.cle2;

DROP TABLE IF EXISTS splits_cleaned_runner;
CREATE TABLE splits_cleaned_runner AS
SELECT id, default_split AS split, chapter, section, lrt_number, lrt_split, date_started_livesplit, finished_run, final_lrt, pb, cle2,
final_rta, date_end_livesplit, time_start_livesplit, time_end_livesplit, playtime, date_started, time_start, date_end, time_end,
rta_numeric, rta_split, cumulative_rta, lag_rta, time_start_numeric, time_end_numeric, time_start_numeric2, time_end_numeric2,
CASE WHEN cle2=1 THEN time_start ELSE
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
CASE WHEN cle2=123 THEN time_end ELSE
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
FROM(
SELECT a.*, b.split AS default_split, CASE WHEN a.cle2=1 THEN time_start_numeric WHEN time_start_numeric<86400 AND time_start_numeric+lag_rta>=86400 THEN time_start_numeric+lag_rta-86400
ELSE time_start_numeric+lag_rta END AS time_start_numeric2, CASE WHEN time_start_numeric<86400 AND time_start_numeric+cumulative_rta>=86400 THEN time_start_numeric+cumulative_rta-86400
ELSE time_start_numeric+cumulative_rta END AS time_end_numeric2
FROM splits_cleaned_runner_old2 a
LEFT JOIN default_split_names_runner b ON a.cle2=b.cle2);

/* Chapter golds part
Here we define for each chapter, how many splits we have, so we know if a run has finished a chapter OR NOT (obviously to count the chapter golds, we need to count only the chapter that are finished, because a chapter that only did the first split AND reset is gonna be faster than a full chapter */

DROP TABLE IF EXISTS chapter_splits_runner;
CREATE TABLE chapter_splits_runner (chapter VARCHAR(255), number_of_splits INTEGER);

INSERT INTO chapter_splits_runner (chapter, number_of_splits)
VALUES
('1-1', 4),
('1-2', 3),
('1-3', 7),
('2-1', 6),
('2-2', 6),
('2-3', 6),
('3-1', 7),
('3-2', 6),
('3-3', 3),
('3-4', 4),
('4-1', 18),
('4-2', 4),
('4-3', 4),
('4-4', 4),
('5-1', 16),
('5-2', 7),
('5-3', 7),
('5-4', 7),
('6-1', 4);

/* Getting the chapter golds AND chapter averages */

DROP TABLE IF EXISTS chapter_golds_runner;
CREATE TABLE chapter_golds_runner AS
SELECT ch_golds.*, avg_chapter_time, CAST(median_chapter_time AS NUMERIC) AS median_chapter_time
FROM (
SELECT aa.*, bb.id, date_started, finished_run, final_lrt, pb
FROM(
SELECT chapter, MIN(chapter_time) AS chapter_gold
FROM(
SELECT a.*
FROM(
SELECT chapter, id, SUM(lrt_number) AS chapter_time, COUNT(*) AS number_of_splits
FROM splits_cleaned_runner
GROUP BY chapter, id
ORDER BY 1) a
JOIN chapter_splits_runner b ON a.chapter=b.chapter AND a.number_of_splits=b.number_of_splits)
GROUP BY 1
ORDER BY 1) aa
LEFT JOIN (
SELECT *
FROM(
SELECT a.*
FROM(
SELECT chapter, id, date_started, finished_run, final_lrt, pb, SUM(lrt_number) AS chapter_time, COUNT(*) AS number_of_splits
FROM splits_cleaned_runner
GROUP BY chapter, id, date_started, finished_run, final_lrt, pb
ORDER BY 1) a
JOIN chapter_splits_runner b ON a.chapter=b.chapter AND a.number_of_splits=b.number_of_splits)) bb
ON aa.chapter_gold=bb.chapter_time) ch_golds
LEFT JOIN (SELECT chapter, AVG(chapter_time) AS avg_chapter_time
FROM(
SELECT a.*
FROM(
SELECT chapter, id, date_started, finished_run, final_lrt, pb, SUM(lrt_number) AS chapter_time, COUNT(*) AS number_of_splits
FROM splits_cleaned_runner
GROUP BY chapter, id, date_started, finished_run, final_lrt, pb) a
JOIN chapter_splits_runner b ON a.chapter=b.chapter AND a.number_of_splits=b.number_of_splits)
/*WHERE id>=10500*/
GROUP BY 1
ORDER BY 1) ch_avg ON ch_golds.chapter=ch_avg.chapter
LEFT JOIN (SELECT chapter, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY chapter_time) AS median_chapter_time
FROM(
SELECT a.*
FROM(
SELECT chapter, id, date_started, finished_run, final_lrt, pb, SUM(lrt_number) AS chapter_time, COUNT(*) AS number_of_splits
FROM splits_cleaned_runner
GROUP BY chapter, id, date_started, finished_run, final_lrt, pb) a
JOIN chapter_splits_runner b ON a.chapter=b.chapter AND a.number_of_splits=b.number_of_splits)
/*WHERE id>=10500*/
GROUP BY 1
ORDER BY 1) ch_med ON ch_golds.chapter=ch_med.chapter;

/* Putting the chapter golds AND averages IN LiveSplit format (previously numbers) */

DROP TABLE IF EXISTS chapter_golds2_runner;
CREATE TABLE chapter_golds2_runner AS
SELECT *, CASE WHEN chapter_gold<60 THEN (CASE WHEN TRUNC(chapter_gold-TRUNC(chapter_gold), 3) =0 THEN
TO_CHAR(TRUNC(chapter_gold, 3) % 60, 'FM00.999')||'000'
WHEN TRUNC(chapter_gold-TRUNC(chapter_gold), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN TO_CHAR(TRUNC(chapter_gold, 3) % 60, 'FM00.999')||'00'
WHEN TRUNC(chapter_gold-TRUNC(chapter_gold), 3) IN (SELECT numb FROM decimals_table_runner)
THEN TO_CHAR(TRUNC(chapter_gold, 3) % 60, 'FM00.999')||'0'
ELSE
TO_CHAR(TRUNC(chapter_gold, 3) % 60, 'FM00.999') END)
ELSE (CASE WHEN TRUNC(chapter_gold-TRUNC(chapter_gold), 3) =0
THEN FLOOR(chapter_gold / 60) || ':' ||
TO_CHAR(TRUNC(chapter_gold, 3) % 60, 'FM00.999')||'000'
WHEN TRUNC(chapter_gold-TRUNC(chapter_gold), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN FLOOR(chapter_gold / 60) || ':' ||
TO_CHAR(TRUNC(chapter_gold, 3) % 60, 'FM00.999')||'00'
WHEN TRUNC(chapter_gold-TRUNC(chapter_gold), 3) IN (SELECT numb FROM decimals_table_runner)
THEN FLOOR(chapter_gold / 60) || ':' ||
TO_CHAR(TRUNC(chapter_gold, 3) % 60, 'FM00.999')||'0'
ELSE
FLOOR(chapter_gold / 60) || ':' ||
TO_CHAR(TRUNC(chapter_gold, 3) % 60, 'FM00.999') END) END AS chapter_gold2,
CASE WHEN avg_chapter_time<60 THEN (CASE WHEN TRUNC(avg_chapter_time-TRUNC(avg_chapter_time), 3) =0 THEN
TO_CHAR(TRUNC(avg_chapter_time, 3) % 60, 'FM00.999')||'000'
WHEN TRUNC(avg_chapter_time-TRUNC(avg_chapter_time), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN TO_CHAR(TRUNC(avg_chapter_time, 3) % 60, 'FM00.999')||'00'
WHEN TRUNC(avg_chapter_time-TRUNC(avg_chapter_time), 3) IN (SELECT numb FROM decimals_table_runner)
THEN TO_CHAR(TRUNC(avg_chapter_time, 3) % 60, 'FM00.999')||'0'
ELSE
TO_CHAR(TRUNC(avg_chapter_time, 3) % 60, 'FM00.999') END)
ELSE (CASE WHEN TRUNC(avg_chapter_time-TRUNC(avg_chapter_time), 3) =0
THEN FLOOR(avg_chapter_time / 60) || ':' ||
TO_CHAR(TRUNC(avg_chapter_time, 3) % 60, 'FM00.999')||'000'
WHEN TRUNC(avg_chapter_time-TRUNC(avg_chapter_time), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN FLOOR(avg_chapter_time / 60) || ':' ||
TO_CHAR(TRUNC(avg_chapter_time, 3) % 60, 'FM00.999')||'00'
WHEN TRUNC(avg_chapter_time-TRUNC(avg_chapter_time), 3) IN (SELECT numb FROM decimals_table_runner)
THEN FLOOR(avg_chapter_time / 60) || ':' ||
TO_CHAR(TRUNC(avg_chapter_time, 3) % 60, 'FM00.999')||'0'
ELSE
FLOOR(avg_chapter_time / 60) || ':' ||
TO_CHAR(TRUNC(avg_chapter_time, 3) % 60, 'FM00.999') END) END AS avg_chapter_time2,
CASE WHEN median_chapter_time<60 THEN (CASE WHEN TRUNC(median_chapter_time-TRUNC(median_chapter_time), 3) =0 THEN
TO_CHAR(TRUNC(median_chapter_time, 3) % 60, 'FM00.999')||'000'
WHEN TRUNC(median_chapter_time-TRUNC(median_chapter_time), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN TO_CHAR(TRUNC(median_chapter_time, 3) % 60, 'FM00.999')||'00'
WHEN TRUNC(median_chapter_time-TRUNC(median_chapter_time), 3) IN (SELECT numb FROM decimals_table_runner)
THEN TO_CHAR(TRUNC(median_chapter_time, 3) % 60, 'FM00.999')||'0'
ELSE
TO_CHAR(TRUNC(median_chapter_time, 3) % 60, 'FM00.999') END)
ELSE (CASE WHEN TRUNC(median_chapter_time-TRUNC(median_chapter_time), 3) =0
THEN FLOOR(median_chapter_time / 60) || ':' ||
TO_CHAR(TRUNC(median_chapter_time, 3) % 60, 'FM00.999')||'000'
WHEN TRUNC(median_chapter_time-TRUNC(median_chapter_time), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN FLOOR(median_chapter_time / 60) || ':' ||
TO_CHAR(TRUNC(median_chapter_time, 3) % 60, 'FM00.999')||'00'
WHEN TRUNC(median_chapter_time-TRUNC(median_chapter_time), 3) IN (SELECT numb FROM decimals_table_runner)
THEN FLOOR(median_chapter_time / 60) || ':' ||
TO_CHAR(TRUNC(median_chapter_time, 3) % 60, 'FM00.999')||'0'
ELSE
FLOOR(median_chapter_time / 60) || ':' ||
TO_CHAR(TRUNC(median_chapter_time, 3) % 60, 'FM00.999') END) END AS median_chapter_time2
FROM chapter_golds_runner;

DROP TABLE IF EXISTS chapter_golds3_runner;
CREATE TABLE chapter_golds3_runner AS
SELECT chapter, id, date_started, final_lrt, pb, chapter_gold, chapter_gold2,
CASE WHEN TRUNC(cumulative_chapter_gold-TRUNC(cumulative_chapter_gold), 3)=0 THEN (CASE WHEN cumulative_chapter_gold>=3600 THEN
FLOOR(cumulative_chapter_gold / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'000'
ELSE FLOOR(cumulative_chapter_gold / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'000' END)
WHEN TRUNC(cumulative_chapter_gold-TRUNC(cumulative_chapter_gold), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN (CASE WHEN cumulative_chapter_gold>=3600 THEN
FLOOR(cumulative_chapter_gold / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'00'
ELSE FLOOR(cumulative_chapter_gold / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'00' END)
WHEN TRUNC(cumulative_chapter_gold-TRUNC(cumulative_chapter_gold), 3) IN (SELECT numb FROM decimals_table_runner)
THEN (CASE WHEN cumulative_chapter_gold>=3600 THEN
FLOOR(cumulative_chapter_gold / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60)<10 THEN '0' ELSE '' END ||
          FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'0'
ELSE FLOOR(cumulative_chapter_gold / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'0' END)
ELSE (CASE WHEN cumulative_chapter_gold>=3600 THEN
FLOOR(cumulative_chapter_gold / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')
ELSE FLOOR(cumulative_chapter_gold / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999') END) END AS cumulative_chapter_gold, cumulative_chapter_gold AS cumulative_chapter_gold_num, avg_chapter_time,
median_chapter_time, avg_chapter_time2, median_chapter_time2
FROM(
SELECT a.chapter, a.chapter_gold, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.avg_chapter_time, a.chapter_gold2,
a.median_chapter_time, a.avg_chapter_time2, a.median_chapter_time2, SUM(b.chapter_gold) AS cumulative_chapter_gold
FROM chapter_golds2_runner a
LEFT JOIN (SELECT DISTINCT chapter, chapter_gold FROM chapter_golds2_runner) b ON a.chapter>=b.chapter
GROUP BY a.chapter, a.chapter_gold, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.avg_chapter_time, a.chapter_gold2,
a.median_chapter_time, a.avg_chapter_time2, a.median_chapter_time2) a
ORDER BY chapter;

/* Chapter times of all the attempts */

DROP TABLE IF EXISTS chapter_history_runner;
CREATE TABLE chapter_history_runner AS
SELECT chapter, id, date_started, finished_run, final_lrt, pb, SUM(chapter_time) AS chapter_time
FROM(
SELECT a.*
FROM(
SELECT chapter, id, date_started, finished_run, final_lrt, pb, SUM(lrt_number) AS chapter_time, COUNT(*) AS number_of_splits
FROM splits_cleaned_runner
GROUP BY chapter, id, date_started, finished_run, final_lrt, pb) a
JOIN chapter_splits_runner b ON a.chapter=b.chapter AND a.number_of_splits=b.number_of_splits)
GROUP BY 1, 2, date_started, finished_run, final_lrt, pb
ORDER BY 1;

/* Putting the chapter golds IN LiveSplit format (previously numbers) */

DROP TABLE IF EXISTS chapter_history2_runner;
CREATE TABLE chapter_history2_runner AS
SELECT *, CASE WHEN chapter_time<60 THEN (CASE WHEN TRUNC(chapter_time-TRUNC(chapter_time), 3) =0 THEN
TO_CHAR(TRUNC(chapter_time, 3) % 60, 'FM00.999')||'000'
WHEN TRUNC(chapter_time-TRUNC(chapter_time), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN TO_CHAR(TRUNC(chapter_time, 3) % 60, 'FM00.999')||'00'
WHEN TRUNC(chapter_time-TRUNC(chapter_time), 3) IN (SELECT numb FROM decimals_table_runner)
THEN TO_CHAR(TRUNC(chapter_time, 3) % 60, 'FM00.999')||'0'
ELSE
TO_CHAR(TRUNC(chapter_time, 3) % 60, 'FM00.999') END)
ELSE (CASE WHEN TRUNC(chapter_time-TRUNC(chapter_time), 3) =0
THEN FLOOR(chapter_time / 60) || ':' ||
TO_CHAR(TRUNC(chapter_time, 3) % 60, 'FM00.999')||'000'
WHEN TRUNC(chapter_time-TRUNC(chapter_time), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN FLOOR(chapter_time / 60) || ':' ||
TO_CHAR(TRUNC(chapter_time, 3) % 60, 'FM00.999')||'00'
WHEN TRUNC(chapter_time-TRUNC(chapter_time), 3) IN (SELECT numb FROM decimals_table_runner)
THEN FLOOR(chapter_time / 60) || ':' ||
TO_CHAR(TRUNC(chapter_time, 3) % 60, 'FM00.999')||'0'
ELSE
FLOOR(chapter_time / 60) || ':' ||
TO_CHAR(TRUNC(chapter_time, 3) % 60, 'FM00.999') END) END AS chapter_time2, RANK() OVER (PARTITION BY chapter ORDER BY chapter_time) AS rank_chapter
FROM chapter_history_runner
ORDER BY chapter, chapter_time;

DROP TABLE IF EXISTS chapter_history3_runner;
CREATE TABLE chapter_history3_runner AS
SELECT chapter, id, date_started, finished_run, pb, chapter_time, chapter_time2, CASE WHEN chapter_time<=min OR min IS NULL THEN 1 ELSE 0
END AS golded_chapter,
CASE WHEN min<60 THEN (CASE WHEN TRUNC(min-TRUNC(min), 3) =0 THEN
TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'000'
WHEN TRUNC(min-TRUNC(min), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'00'
WHEN TRUNC(min-TRUNC(min), 3) IN (SELECT numb FROM decimals_table_runner)
THEN TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'0'
ELSE
TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999') END)
ELSE (CASE WHEN TRUNC(min-TRUNC(min), 3) =0
THEN FLOOR(min / 60) || ':' ||
TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'000'
WHEN TRUNC(min-TRUNC(min), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN FLOOR(min / 60) || ':' ||
TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'00'
WHEN TRUNC(min-TRUNC(min), 3) IN (SELECT numb FROM decimals_table_runner)
THEN FLOOR(min / 60) || ':' ||
TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'0'
ELSE
FLOOR(min / 60) || ':' ||
TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999') END) END AS chapter_gold_at_that_time, rank_chapter, chapter_rank_at_that_time, finished_chapters, finished_chapters_at_that_time
FROM (SELECT a.rank_chapter, a.chapter, a.id, a.date_started, a.finished_run, a.pb, a.chapter_time, a.chapter_time2, MIN(b.chapter_time) AS min,
MIN(b.chapter_time2) AS min2, finished_chapters, chapter_rank_at_that_time, finished_chapters_at_that_time
FROM chapter_history2_runner a
LEFT JOIN chapter_history2_runner b ON a.chapter=b.chapter AND a.id>b.id
LEFT JOIN (SELECT chapter, COUNT(*) AS finished_chapters FROM chapter_history2_runner GROUP BY 1) c ON a.chapter=c.chapter
LEFT JOIN (SELECT *
FROM (SELECT a.*, b.chapter_time AS chapter_time3, b.id AS id2,
RANK() OVER (PARTITION BY a.chapter, a.id ORDER BY b.chapter_time) AS chapter_rank_at_that_time
FROM chapter_history2_runner a
JOIN chapter_history2_runner b ON a.chapter=b.chapter AND a.id>=b.id) a
WHERE id=id2) d ON a.chapter=d.chapter AND a.id=d.id

LEFT JOIN (

SELECT a.chapter, a.id, COUNT(*) AS finished_chapters_at_that_time
FROM chapter_history2_runner a
JOIN chapter_history2_runner b ON a.chapter=b.chapter AND a.id>=b.id
GROUP BY 1, 2) e ON a.chapter=e.chapter AND a.id=e.id
GROUP BY finished_chapters_at_that_time, chapter_rank_at_that_time, finished_chapters, a.rank_chapter, a.chapter, a.id, a.date_started, a.finished_run, a.pb, a.chapter_time, a.chapter_time2) a;

/* Section golds, same AS chapters, we count the number of splits per section to only count finished sections */

DROP TABLE IF EXISTS section_splits_runner;
CREATE TABLE section_splits_runner (section VARCHAR(255), number_of_splits INTEGER, sort INTEGER);

INSERT INTO section_splits_runner (section, number_of_splits, sort)
VALUES
('Village', 32, 1),
('Castle', 50, 2),
('Island', 41, 3);

/* Sections golds AND averages */

DROP TABLE IF EXISTS section_golds_runner;
CREATE TABLE section_golds_runner AS
SELECT section_golds.*, section_avg, CAST(section_median AS NUMERIC) AS section_median
FROM(
SELECT aa.*, bb.id, date_started, finished_run, final_lrt, pb
FROM (
SELECT section, MIN(section_time) AS section_gold
FROM(
SELECT a.*
FROM(
SELECT section, id, SUM(lrt_number) AS section_time, COUNT(*) AS number_of_splits
FROM splits_cleaned_runner
GROUP BY section, id
ORDER BY 1) a
JOIN section_splits_runner b ON a.section=b.section AND a.number_of_splits=b.number_of_splits)
GROUP BY 1) aa
LEFT JOIN (
SELECT *
FROM(
SELECT a.*
FROM(
SELECT section, id, date_started, finished_run, final_lrt, pb, SUM(lrt_number) AS section_time, COUNT(*) AS number_of_splits
FROM splits_cleaned_runner
GROUP BY section, id, date_started, finished_run, final_lrt, pb
ORDER BY 1) a
JOIN section_splits_runner b ON a.section=b.section AND a.number_of_splits=b.number_of_splits)) bb
ON aa.section_gold=bb.section_time
ORDER BY CASE WHEN aa.section='Village' THEN 1 WHEN aa.section='Castle' THEN 2 ELSE 3 END) section_golds
LEFT JOIN (SELECT section, AVG(section_time) AS section_avg
FROM(
SELECT a.*
FROM(
SELECT section, id, date_started, finished_run, final_lrt, pb, SUM(lrt_number) AS section_time, COUNT(*) AS number_of_splits
FROM splits_cleaned_runner
GROUP BY section, id, date_started, finished_run, final_lrt, pb) a
JOIN section_splits_runner b ON a.section=b.section AND a.number_of_splits=b.number_of_splits)
--WHERE id>=10500
GROUP BY 1
ORDER BY 1) section_avg ON section_golds.section=section_avg.section
LEFT JOIN (SELECT section, PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY section_time) AS section_median
FROM(
SELECT a.*
FROM(
SELECT section, id, date_started, finished_run, final_lrt, pb, SUM(lrt_number) AS section_time, COUNT(*) AS number_of_splits
FROM splits_cleaned_runner
GROUP BY section, id, date_started, finished_run, final_lrt, pb) a
JOIN section_splits_runner b ON a.section=b.section AND a.number_of_splits=b.number_of_splits)
--WHERE id>=10500
GROUP BY 1
ORDER BY 1) section_med ON section_golds.section=section_med.section;

/* Putting the section golds AND averages IN LiveSplit format (previously numbers) */

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
FROM section_golds_runner;

DROP TABLE IF EXISTS section_golds3_runner;
CREATE TABLE section_golds3_runner AS
SELECT section, id, date_started, final_lrt, pb, section_gold, section_gold2,
CASE WHEN TRUNC(cumulative_chapter_gold-TRUNC(cumulative_chapter_gold), 3)=0 THEN (CASE WHEN cumulative_chapter_gold>=3600 THEN
FLOOR(cumulative_chapter_gold / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'000'
ELSE FLOOR(cumulative_chapter_gold / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'000' END)
WHEN TRUNC(cumulative_chapter_gold-TRUNC(cumulative_chapter_gold), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN (CASE WHEN cumulative_chapter_gold>=3600 THEN
FLOOR(cumulative_chapter_gold / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'00'
ELSE FLOOR(cumulative_chapter_gold / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'00' END)
WHEN TRUNC(cumulative_chapter_gold-TRUNC(cumulative_chapter_gold), 3) IN (SELECT numb FROM decimals_table_runner)
THEN (CASE WHEN cumulative_chapter_gold>=3600 THEN
FLOOR(cumulative_chapter_gold / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60)<10 THEN '0' ELSE '' END ||
          FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'0'
ELSE FLOOR(cumulative_chapter_gold / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'0' END)
ELSE (CASE WHEN cumulative_chapter_gold>=3600 THEN
FLOOR(cumulative_chapter_gold / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')
ELSE FLOOR(cumulative_chapter_gold / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999') END) END AS cumulative_section_gold, section_avg, section_median,
section_avg2, section_median2
FROM(
SELECT a.section, a.section_gold, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.section_avg, a.section_gold2,
a.section_avg2, a.section_median, a.section_median2, SUM(b.section_gold) AS cumulative_chapter_gold
FROM section_golds2_runner a
LEFT JOIN (SELECT DISTINCT section, section_gold FROM section_golds2_runner) b ON CASE WHEN a.section='Village' THEN 1 WHEN a.section='Castle' THEN 2 ELSE 3 END>=
	CASE WHEN b.section='Village' THEN 1 WHEN b.section='Castle' THEN 2 ELSE 3 END
GROUP BY a.section, a.section_gold, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.section_avg, a.section_gold2,
a.section_avg2, a.section_median, a.section_median2) a
ORDER BY CASE WHEN section='Village' THEN 1 WHEN section='Castle' THEN 2 ELSE 3 END;

/* Section times of all the attempts */

DROP TABLE IF EXISTS section_history_runner;
CREATE TABLE section_history_runner AS
SELECT section, id, date_started, finished_run, final_lrt, pb, SUM(section_time) AS section_time
FROM(
SELECT a.*
FROM(
SELECT section, id, date_started, finished_run, final_lrt, pb, SUM(lrt_number) AS section_time, COUNT(*) AS number_of_splits
FROM splits_cleaned_runner
GROUP BY section, id, date_started, finished_run, final_lrt, pb) a
JOIN section_splits_runner b ON a.section=b.section AND a.number_of_splits=b.number_of_splits)
GROUP BY 1, 2, date_started, finished_run, final_lrt, pb
ORDER BY 1;

/* Putting the section golds IN LiveSplit format (previously numbers) */

DROP TABLE IF EXISTS section_history2_runner;
CREATE TABLE section_history2_runner AS
SELECT *, CASE WHEN TRUNC(section_time-TRUNC(section_time), 3) =0
THEN FLOOR(section_time / 60) || ':' ||
TO_CHAR(TRUNC(section_time, 3) % 60, 'FM00.999')||'000'
WHEN TRUNC(section_time-TRUNC(section_time), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN FLOOR(section_time / 60) || ':' ||
TO_CHAR(TRUNC(section_time, 3) % 60, 'FM00.999')||'00'
WHEN TRUNC(section_time-TRUNC(section_time), 3) IN (SELECT numb FROM decimals_table_runner)
THEN FLOOR(section_time / 60) || ':' ||
TO_CHAR(TRUNC(section_time, 3) % 60, 'FM00.999')||'0'
ELSE
FLOOR(section_time / 60) || ':' ||
TO_CHAR(TRUNC(section_time, 3) % 60, 'FM00.999') END AS section_time2, RANK() OVER (PARTITION BY section ORDER BY section_time) AS rank_section
FROM section_history_runner
ORDER BY CASE WHEN section='Village' THEN 1 WHEN section='Castle' THEN 2 ELSE 3 END, section_time;

DROP TABLE IF EXISTS section_history3_runner;
CREATE TABLE section_history3_runner AS
SELECT section, id, date_started, finished_run, final_lrt, pb, section_time, section_time2, CASE WHEN section_time<=min OR min IS NULL
THEN 1 ELSE 0 END AS golded_section,
FLOOR(min / 60) || ':' ||
CASE WHEN LENGTH(TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999'))=3
THEN TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'000'
WHEN LENGTH(TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999'))=4
THEN TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'00'
WHEN LENGTH(TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999'))=5
THEN TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'0' ELSE
TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999') END AS section_gold_at_that_time, rank_section, section_rank_at_that_time, finished_sections, finished_sections_at_that_time
FROM (SELECT a.section, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.section_time, a.section_time2, MIN(b.section_time) AS min,
MIN(b.section_time2) AS min2, a.rank_section, finished_sections, finished_sections_at_that_time, section_rank_at_that_time
FROM section_history2_runner a
LEFT JOIN section_history2_runner b ON a.section=b.section AND a.id>b.id
LEFT JOIN (SELECT section, COUNT(*) AS finished_sections FROM section_history2_runner GROUP BY 1) c ON a.section=c.section
LEFT JOIN (SELECT *
FROM (SELECT a.*, b.section_time AS section_time3, b.id AS id2,
RANK() OVER (PARTITION BY a.section, a.id ORDER BY b.section_time) AS section_rank_at_that_time
FROM section_history2_runner a
JOIN section_history2_runner b ON a.section=b.section AND a.id>=b.id) a
WHERE id=id2) d ON a.section=d.section AND a.id=d.id

LEFT JOIN (

SELECT a.section, a.id, COUNT(*) AS finished_sections_at_that_time
FROM section_history2_runner a
JOIN section_history2_runner b ON a.section=b.section AND a.id>=b.id
GROUP BY 1, 2) e ON a.section=e.section AND a.id=e.id
GROUP BY a.rank_section, finished_sections, finished_sections_at_that_time, section_rank_at_that_time, a.section, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.section_time, a.section_time2) a;

/* All golds */

DROP TABLE IF EXISTS doorsplits_golds_runner;
CREATE TABLE doorsplits_golds_runner AS
SELECT aa.*, bb.id, date_started, finished_run, final_lrt, pb,
CASE WHEN TRUNC(gold-TRUNC(gold), 3)=0 THEN
(CASE WHEN gold<10 THEN TO_CHAR(TRUNC(gold, 3) % 60, 'FM0.999')||'000'
WHEN gold<60 THEN TO_CHAR(TRUNC(gold, 3) % 60, 'FM00.999')||'000'
ELSE FLOOR(gold / 60) || ':' || TO_CHAR(TRUNC(gold, 3) % 60, 'FM00.999')||'000' END)
WHEN TRUNC(gold-TRUNC(gold), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN (CASE WHEN gold<10 THEN TO_CHAR(TRUNC(gold, 3) % 60, 'FM0.999')||'00'
WHEN gold<60 THEN TO_CHAR(TRUNC(gold, 3) % 60, 'FM00.999')||'00'
ELSE FLOOR(gold / 60) || ':' || TO_CHAR(TRUNC(gold, 3) % 60, 'FM00.999')||'00' END)
WHEN TRUNC(gold-TRUNC(gold), 3) IN (SELECT numb FROM decimals_table_runner)
THEN (CASE WHEN gold<10 THEN TO_CHAR(TRUNC(gold, 3) % 60, 'FM0.999')||'0'
WHEN gold<60 THEN TO_CHAR(TRUNC(gold, 3) % 60, 'FM00.999')||'0'
ELSE FLOOR(gold / 60) || ':' || TO_CHAR(TRUNC(gold, 3) % 60, 'FM00.999')||'0' END)
ELSE (CASE WHEN gold<10 THEN TO_CHAR(TRUNC(gold, 3) % 60, 'FM0.999')
WHEN gold<60 THEN TO_CHAR(TRUNC(gold, 3) % 60, 'FM00.999')
ELSE FLOOR(gold / 60) || ':' || TO_CHAR(TRUNC(gold, 3) % 60, 'FM00.999') END) END AS gold2, CAST(door_avg AS NUMERIC) AS door_avg,
CAST(door_median AS NUMERIC) AS door_median
FROM (
SELECT cle2, split, MIN(split_time) AS gold
FROM(SELECT split, id, cle2, SUM(lrt_number) AS split_time
FROM splits_cleaned_runner
GROUP BY split, id, cle2) a
GROUP BY split, cle2) aa
LEFT JOIN (SELECT *
FROM(SELECT split, id, cle2, date_started, finished_run, final_lrt, pb, SUM(lrt_number) AS split_time
FROM splits_cleaned_runner
GROUP BY split, id, cle2, date_started, finished_run, final_lrt, pb) a) bb ON aa.gold=bb.split_time AND aa.cle2=bb.cle2
LEFT JOIN (SELECT cle2, AVG(lrt_time) AS door_avg
FROM(
SELECT a.*
FROM(
SELECT cle2, id, date_started, finished_run, final_lrt, pb, SUM(lrt_number) AS lrt_time
FROM splits_cleaned_runner
GROUP BY cle2, id, date_started, finished_run, final_lrt, pb) a)
--WHERE id>=10500
GROUP BY 1
ORDER BY 1) door_avg ON door_avg.cle2=aa.cle2
LEFT JOIN (SELECT cle2, PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY lrt_time) AS door_median
FROM(
SELECT a.*
FROM(
SELECT cle2, id, date_started, finished_run, final_lrt, pb, SUM(lrt_number) AS lrt_time
FROM splits_cleaned_runner
GROUP BY cle2, id, date_started, finished_run, final_lrt, pb) a)
--WHERE id>=10500
GROUP BY 1
ORDER BY 1) door_med ON door_med.cle2=aa.cle2
ORDER BY cle2;

DROP TABLE IF EXISTS doorsplits_golds2_runner;
CREATE TABLE doorsplits_golds2_runner AS
SELECT cle2, id, date_started, final_lrt, pb, gold, gold2, door_avg, door_median,
CASE WHEN TRUNC(cumulative_chapter_gold-TRUNC(cumulative_chapter_gold), 3)=0 THEN (CASE WHEN cumulative_chapter_gold>=3600 THEN
FLOOR(cumulative_chapter_gold / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'000'
ELSE FLOOR(cumulative_chapter_gold / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'000' END)
WHEN TRUNC(cumulative_chapter_gold-TRUNC(cumulative_chapter_gold), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN (CASE WHEN cumulative_chapter_gold>=3600 THEN
FLOOR(cumulative_chapter_gold / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'00'
ELSE FLOOR(cumulative_chapter_gold / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'00' END)
WHEN TRUNC(cumulative_chapter_gold-TRUNC(cumulative_chapter_gold), 3) IN (SELECT numb FROM decimals_table_runner)
THEN (CASE WHEN cumulative_chapter_gold>=3600 THEN
FLOOR(cumulative_chapter_gold / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60)<10 THEN '0' ELSE '' END ||
          FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'0'
ELSE FLOOR(cumulative_chapter_gold / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'0' END)
ELSE (CASE WHEN cumulative_chapter_gold>=3600 THEN
FLOOR(cumulative_chapter_gold / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(cumulative_chapter_gold / 60)-(FLOOR(cumulative_chapter_gold/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999')
ELSE FLOOR(cumulative_chapter_gold / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold, 3) % 60, 'FM00.999') END) END AS cumulative_door_gold, cumulative_chapter_gold AS cumulative_door_gold_num,
CASE WHEN TRUNC(door_avg-TRUNC(door_avg), 3)=0 THEN
(CASE WHEN door_avg<10 THEN TO_CHAR(TRUNC(door_avg, 3) % 60, 'FM0.999')||'000'
WHEN door_avg<60 THEN TO_CHAR(TRUNC(door_avg, 3) % 60, 'FM00.999')||'000'
ELSE FLOOR(door_avg / 60) || ':' || TO_CHAR(TRUNC(door_avg, 3) % 60, 'FM00.999')||'000' END)
WHEN TRUNC(door_avg-TRUNC(door_avg), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN (CASE WHEN door_avg<10 THEN TO_CHAR(TRUNC(door_avg, 3) % 60, 'FM0.999')||'00'
WHEN door_avg<60 THEN TO_CHAR(TRUNC(door_avg, 3) % 60, 'FM00.999')||'00'
ELSE FLOOR(door_avg / 60) || ':' || TO_CHAR(TRUNC(door_avg, 3) % 60, 'FM00.999')||'00' END)
WHEN TRUNC(door_avg-TRUNC(door_avg), 3) IN (SELECT numb FROM decimals_table_runner)
THEN (CASE WHEN door_avg<10 THEN TO_CHAR(TRUNC(door_avg, 3) % 60, 'FM0.999')||'0'
WHEN door_avg<60 THEN TO_CHAR(TRUNC(door_avg, 3) % 60, 'FM00.999')||'0'
ELSE FLOOR(door_avg / 60) || ':' || TO_CHAR(TRUNC(door_avg, 3) % 60, 'FM00.999')||'0' END)
ELSE (CASE WHEN door_avg<10 THEN TO_CHAR(TRUNC(door_avg, 3) % 60, 'FM0.999')
WHEN door_avg<60 THEN TO_CHAR(TRUNC(door_avg, 3) % 60, 'FM00.999')
ELSE FLOOR(door_avg / 60) || ':' || TO_CHAR(TRUNC(door_avg, 3) % 60, 'FM00.999') END) END AS door_avg2,
CASE WHEN TRUNC(door_median-TRUNC(door_median), 3)=0 THEN
(CASE WHEN door_median<10 THEN TO_CHAR(TRUNC(door_median, 3) % 60, 'FM0.999')||'000'
WHEN door_median<60 THEN TO_CHAR(TRUNC(door_median, 3) % 60, 'FM00.999')||'000'
ELSE FLOOR(door_median / 60) || ':' || TO_CHAR(TRUNC(door_median, 3) % 60, 'FM00.999')||'000' END)
WHEN TRUNC(door_median-TRUNC(door_median), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN (CASE WHEN door_median<10 THEN TO_CHAR(TRUNC(door_median, 3) % 60, 'FM0.999')||'00'
WHEN door_median<60 THEN TO_CHAR(TRUNC(door_median, 3) % 60, 'FM00.999')||'00'
ELSE FLOOR(door_median / 60) || ':' || TO_CHAR(TRUNC(door_median, 3) % 60, 'FM00.999')||'00' END)
WHEN TRUNC(door_median-TRUNC(door_median), 3) IN (SELECT numb FROM decimals_table_runner)
THEN (CASE WHEN door_median<10 THEN TO_CHAR(TRUNC(door_median, 3) % 60, 'FM0.999')||'0'
WHEN door_median<60 THEN TO_CHAR(TRUNC(door_median, 3) % 60, 'FM00.999')||'0'
ELSE FLOOR(door_median / 60) || ':' || TO_CHAR(TRUNC(door_median, 3) % 60, 'FM00.999')||'0' END)
ELSE (CASE WHEN door_median<10 THEN TO_CHAR(TRUNC(door_median, 3) % 60, 'FM0.999')
WHEN door_median<60 THEN TO_CHAR(TRUNC(door_median, 3) % 60, 'FM00.999')
ELSE FLOOR(door_median / 60) || ':' || TO_CHAR(TRUNC(door_median, 3) % 60, 'FM00.999') END) END AS door_median2
FROM(
SELECT a.cle2, a.split, a.gold, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.gold2, a.door_avg, a.door_median,
	SUM(b.gold) AS cumulative_chapter_gold
FROM doorsplits_golds_runner a
LEFT JOIN (SELECT DISTINCT cle2, gold FROM doorsplits_golds_runner) b ON a.cle2>=b.cle2
GROUP BY a.cle2, a.split, a.gold, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.gold2, a.door_avg, a.door_median
ORDER BY a.cle2) a
ORDER BY cle2;

DROP TABLE IF EXISTS doorsplits_golds_history_runner;
CREATE TABLE doorsplits_golds_history_runner AS
SELECT cle2, split, gold, id, date_started, finished_run, final_lrt, pb, gold2, CASE WHEN lrt_number<=min OR min IS NULL THEN 1 ELSE 0
END AS golded_split,
CASE WHEN TRUNC(min-TRUNC(min), 3)=0 THEN
(CASE WHEN min<10 THEN TO_CHAR(TRUNC(min, 3) % 60, 'FM0.999')||'000'
WHEN min<60 THEN TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'000'
ELSE FLOOR(min / 60) || ':' || TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'000' END)
WHEN TRUNC(min-TRUNC(min), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN (CASE WHEN min<10 THEN TO_CHAR(TRUNC(min, 3) % 60, 'FM0.999')||'00'
WHEN min<60 THEN TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'00'
ELSE FLOOR(min / 60) || ':' || TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'00' END)
WHEN TRUNC(min-TRUNC(min), 3) IN (SELECT numb FROM decimals_table_runner)
THEN (CASE WHEN min<10 THEN TO_CHAR(TRUNC(min, 3) % 60, 'FM0.999')||'0'
WHEN min<60 THEN TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'0'
ELSE FLOOR(min / 60) || ':' || TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'0' END)
ELSE (CASE WHEN min<10 THEN TO_CHAR(TRUNC(min, 3) % 60, 'FM0.999')
WHEN min<60 THEN TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')
ELSE FLOOR(min / 60) || ':' || TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999') END) END AS gold_at_that_time, lrt_number AS lrt_number8, RANK() OVER (PARTITION BY cle2 ORDER BY lrt_number) AS rank_split
FROM (SELECT a.cle2, a.split, c.gold, c.gold2, a.lrt_number, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.lrt_split, MIN(b.lrt_number) AS min,
MIN(b.lrt_split) AS min2
FROM splits_cleaned_runner a
LEFT JOIN splits_cleaned_runner b ON a.cle2=b.cle2 AND a.id>b.id
LEFT JOIN (SELECT DISTINCT cle2, split, gold, gold2 FROM doorsplits_golds_runner) c ON a.cle2=c.cle2
GROUP BY a.cle2, a.split, c.gold, c.gold2, a.lrt_number, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.lrt_split) a;

DROP TABLE IF EXISTS doorsplits_golds_history_runner2;
CREATE TABLE doorsplits_golds_history_runner2 AS
SELECT a.*, split_rank_at_that_time, finished_splits, finished_splits_at_that_time
FROM doorsplits_golds_history_runner a
LEFT JOIN (SELECT cle2, COUNT(*) AS finished_splits FROM doorsplits_golds_history_runner GROUP BY 1) c ON a.cle2=c.cle2
LEFT JOIN (SELECT *
FROM (SELECT a.*, b.lrt_number8 AS split_time3, b.id AS id2,
RANK() OVER (PARTITION BY a.cle2, a.id ORDER BY b.lrt_number8) AS split_rank_at_that_time
FROM doorsplits_golds_history_runner a
JOIN doorsplits_golds_history_runner b ON a.cle2=b.cle2 AND a.id>=b.id) a
WHERE id=id2) d ON a.cle2=d.cle2 AND a.id=d.id

LEFT JOIN (

SELECT a.cle2, a.id, COUNT(*) AS finished_splits_at_that_time
FROM doorsplits_golds_history_runner a
JOIN doorsplits_golds_history_runner b ON a.cle2=b.cle2 AND a.id>=b.id
GROUP BY 1, 2) e ON a.cle2=e.cle2 AND a.id=e.id;

/* Getting the pace (AND best pace) of each run after each split */

DROP TABLE IF EXISTS best_paces_runner;
CREATE TABLE best_paces_runner AS
SELECT pace.*, best_pace, /*avg_pace, median_pace,*/
CASE WHEN TRUNC(pace-TRUNC(pace), 3)=0 THEN (CASE WHEN pace<3600 THEN FLOOR(pace / 60) || ':' ||
TO_CHAR(TRUNC(pace, 3) % 60, 'FM00.999')||'000'
ELSE FLOOR(pace / 3600) || ':' || CASE WHEN FLOOR(pace / 60)-(FLOOR(pace/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(pace / 60)-(FLOOR(pace/3600)*60) || ':' ||
TO_CHAR(TRUNC(pace, 3) % 60, 'FM00.999')||'000' END)
WHEN TRUNC(pace-TRUNC(pace), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN (CASE WHEN pace<3600 THEN FLOOR(pace / 60) || ':' ||
TO_CHAR(TRUNC(pace, 3) % 60, 'FM00.999')||'00'
ELSE FLOOR(pace / 3600) || ':' || CASE WHEN FLOOR(pace / 60)-(FLOOR(pace/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(pace / 60)-(FLOOR(pace/3600)*60) || ':' ||
TO_CHAR(TRUNC(pace, 3) % 60, 'FM00.999')||'00' END)
WHEN TRUNC(pace-TRUNC(pace), 3) IN (SELECT numb FROM decimals_table_runner)
THEN (CASE WHEN pace<3600 THEN FLOOR(pace / 60) || ':' ||
TO_CHAR(TRUNC(pace, 3) % 60, 'FM00.999')||'0'
ELSE FLOOR(pace / 3600) || ':' || CASE WHEN FLOOR(pace / 60)-(FLOOR(pace/3600)*60)<10 THEN '0' ELSE '' END ||
          FLOOR(pace / 60)-(FLOOR(pace/3600)*60) || ':' ||
TO_CHAR(TRUNC(pace, 3) % 60, 'FM00.999')||'0' END)
ELSE (CASE WHEN pace<3600 THEN FLOOR(pace / 60) || ':' ||
TO_CHAR(TRUNC(pace, 3) % 60, 'FM00.999')
ELSE FLOOR(pace / 3600) || ':' || CASE WHEN FLOOR(pace / 60)-(FLOOR(pace/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(pace / 60)-(FLOOR(pace/3600)*60)|| ':' ||
TO_CHAR(TRUNC(pace, 3) % 60, 'FM00.999') END) END AS pace2,
CASE WHEN TRUNC(best_pace-TRUNC(best_pace), 3)=0 THEN (CASE WHEN best_pace>=3600 THEN
FLOOR(best_pace / 3600) || ':' || CASE WHEN FLOOR(best_pace / 60)-(FLOOR(best_pace/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(best_pace / 60)-(FLOOR(best_pace/3600)*60) || ':' ||
TO_CHAR(TRUNC(best_pace, 3) % 60, 'FM00.999')||'000'
ELSE FLOOR(best_pace / 60) || ':' ||
TO_CHAR(TRUNC(best_pace, 3) % 60, 'FM00.999')||'000' END)
WHEN TRUNC(best_pace-TRUNC(best_pace), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN (CASE WHEN best_pace>=3600 THEN
FLOOR(best_pace / 3600) || ':' || CASE WHEN FLOOR(best_pace / 60)-(FLOOR(best_pace/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(best_pace / 60)-(FLOOR(best_pace/3600)*60) || ':' ||
TO_CHAR(TRUNC(best_pace, 3) % 60, 'FM00.999')||'00'
ELSE FLOOR(best_pace / 60) || ':' ||
TO_CHAR(TRUNC(best_pace, 3) % 60, 'FM00.999')||'00' END)
WHEN TRUNC(best_pace-TRUNC(best_pace), 3) IN (SELECT numb FROM decimals_table_runner)
THEN (CASE WHEN best_pace>=3600 THEN
FLOOR(best_pace / 3600) || ':' || CASE WHEN FLOOR(best_pace / 60)-(FLOOR(best_pace/3600)*60)<10 THEN '0' ELSE '' END ||
          FLOOR(best_pace / 60)-(FLOOR(best_pace/3600)*60) || ':' ||
TO_CHAR(TRUNC(best_pace, 3) % 60, 'FM00.999')||'0'
ELSE FLOOR(best_pace / 60) || ':' ||
TO_CHAR(TRUNC(best_pace, 3) % 60, 'FM00.999')||'0' END)
ELSE (CASE WHEN best_pace>=3600 THEN
FLOOR(best_pace / 3600) || ':' || CASE WHEN FLOOR(best_pace / 60)-(FLOOR(best_pace/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(best_pace / 60)-(FLOOR(best_pace/3600)*60) || ':' ||
TO_CHAR(TRUNC(best_pace, 3) % 60, 'FM00.999')
ELSE FLOOR(best_pace / 60) || ':' ||
TO_CHAR(TRUNC(best_pace, 3) % 60, 'FM00.999') END) END AS best_pace2/*,
CASE WHEN TRUNC(avg_pace-TRUNC(avg_pace), 3)=0 THEN (CASE WHEN avg_pace>=3600 THEN
FLOOR(avg_pace / 3600) || ':' || CASE WHEN FLOOR(avg_pace / 60)-(FLOOR(avg_pace/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(avg_pace / 60)-(FLOOR(avg_pace/3600)*60) || ':' ||
TO_CHAR(TRUNC(avg_pace, 3) % 60, 'FM00.999')||'000'
ELSE FLOOR(avg_pace / 60) || ':' ||
TO_CHAR(TRUNC(avg_pace, 3) % 60, 'FM00.999')||'000' END)
WHEN TRUNC(avg_pace-TRUNC(avg_pace), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN (CASE WHEN avg_pace>=3600 THEN
FLOOR(avg_pace / 3600) || ':' || CASE WHEN FLOOR(avg_pace / 60)-(FLOOR(avg_pace/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(avg_pace / 60)-(FLOOR(avg_pace/3600)*60) || ':' ||
TO_CHAR(TRUNC(avg_pace, 3) % 60, 'FM00.999')||'00'
ELSE FLOOR(avg_pace / 60) || ':' ||
TO_CHAR(TRUNC(avg_pace, 3) % 60, 'FM00.999')||'00' END)
WHEN TRUNC(avg_pace-TRUNC(avg_pace), 3) IN (SELECT numb FROM decimals_table_runner)
THEN (CASE WHEN avg_pace>=3600 THEN
FLOOR(avg_pace / 3600) || ':' || CASE WHEN FLOOR(avg_pace / 60)-(FLOOR(avg_pace/3600)*60)<10 THEN '0' ELSE '' END ||
          FLOOR(avg_pace / 60)-(FLOOR(avg_pace/3600)*60) || ':' ||
TO_CHAR(TRUNC(avg_pace, 3) % 60, 'FM00.999')||'0'
ELSE FLOOR(avg_pace / 60) || ':' ||
TO_CHAR(TRUNC(avg_pace, 3) % 60, 'FM00.999')||'0' END)
ELSE (CASE WHEN avg_pace>=3600 THEN
FLOOR(avg_pace / 3600) || ':' || CASE WHEN FLOOR(avg_pace / 60)-(FLOOR(avg_pace/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(avg_pace / 60)-(FLOOR(avg_pace/3600)*60) || ':' ||
TO_CHAR(TRUNC(avg_pace, 3) % 60, 'FM00.999')
ELSE FLOOR(avg_pace / 60) || ':' ||
TO_CHAR(TRUNC(avg_pace, 3) % 60, 'FM00.999') END) END AS avg_pace2,
CASE WHEN TRUNC(median_pace-TRUNC(median_pace), 3)=0 THEN (CASE WHEN median_pace>=3600 THEN
FLOOR(median_pace / 3600) || ':' || CASE WHEN FLOOR(median_pace / 60)-(FLOOR(median_pace/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(median_pace / 60)-(FLOOR(median_pace/3600)*60) || ':' ||
TO_CHAR(TRUNC(median_pace, 3) % 60, 'FM00.999')||'000'
ELSE FLOOR(median_pace / 60) || ':' ||
TO_CHAR(TRUNC(median_pace, 3) % 60, 'FM00.999')||'000' END)
WHEN TRUNC(median_pace-TRUNC(median_pace), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN (CASE WHEN median_pace>=3600 THEN
FLOOR(median_pace / 3600) || ':' || CASE WHEN FLOOR(median_pace / 60)-(FLOOR(median_pace/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(median_pace / 60)-(FLOOR(median_pace/3600)*60) || ':' ||
TO_CHAR(TRUNC(median_pace, 3) % 60, 'FM00.999')||'00'
ELSE FLOOR(median_pace / 60) || ':' ||
TO_CHAR(TRUNC(median_pace, 3) % 60, 'FM00.999')||'00' END)
WHEN TRUNC(median_pace-TRUNC(median_pace), 3) IN (SELECT numb FROM decimals_table_runner)
THEN (CASE WHEN median_pace>=3600 THEN
FLOOR(median_pace / 3600) || ':' || CASE WHEN FLOOR(median_pace / 60)-(FLOOR(median_pace/3600)*60)<10 THEN '0' ELSE '' END ||
          FLOOR(median_pace / 60)-(FLOOR(median_pace/3600)*60) || ':' ||
TO_CHAR(TRUNC(median_pace, 3) % 60, 'FM00.999')||'0'
ELSE FLOOR(median_pace / 60) || ':' ||
TO_CHAR(TRUNC(median_pace, 3) % 60, 'FM00.999')||'0' END)
ELSE (CASE WHEN median_pace>=3600 THEN
FLOOR(median_pace / 3600) || ':' || CASE WHEN FLOOR(median_pace / 60)-(FLOOR(median_pace/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(median_pace / 60)-(FLOOR(median_pace/3600)*60) || ':' ||
TO_CHAR(TRUNC(median_pace, 3) % 60, 'FM00.999')
ELSE FLOOR(median_pace / 60) || ':' ||
TO_CHAR(TRUNC(median_pace, 3) % 60, 'FM00.999') END) END AS median_pace2*/
FROM (SELECT aa.cle2, aa.id, aa.split, COUNT(*) AS number_of_splits, SUM(bb.lrt_number) AS pace
FROM
(SELECT *
FROM splits_cleaned_runner a) aa
JOIN
(SELECT *
FROM splits_cleaned_runner a) bb ON aa.cle2>=bb.cle2 AND aa.id=bb.id
GROUP BY aa.id, aa.split, aa.cle2
having COUNT(*)=aa.cle2
ORDER BY aa.id, aa.cle2) pace
LEFT JOIN (
SELECT split, cle2, MIN(pace) AS best_pace/*, CAST(AVG(pace) AS NUMERIC) AS avg_pace,
CAST(PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY pace) AS NUMERIC) AS median_pace*/
FROM(
SELECT aa.cle2, aa.id, aa.split, COUNT(*) AS number_of_splits, SUM(bb.lrt_number) AS pace
FROM
(SELECT *
FROM splits_cleaned_runner a) aa
JOIN
(SELECT *
FROM splits_cleaned_runner a) bb ON aa.cle2>=bb.cle2 AND aa.id=bb.id
GROUP BY aa.id, aa.split, aa.cle2
ORDER BY aa.id, aa.cle2)
WHERE id>0
AND number_of_splits=cle2
GROUP BY split, cle2
ORDER BY cle2) best_pace ON pace.cle2=best_pace.cle2;

DROP TABLE IF EXISTS best_paces_history_runner;
CREATE TABLE best_paces_history_runner AS
SELECT cle2, id, split, number_of_splits, pace, best_pace, pace2, best_pace2, CASE WHEN pace<=min OR min IS NULL THEN 1 ELSE 0
END AS was_best_pace,
CASE WHEN TRUNC(min-TRUNC(min), 3)=0 THEN (CASE WHEN min<3600 THEN FLOOR(min / 60) || ':' ||
TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'000'
ELSE FLOOR(min / 3600) || ':' || CASE WHEN FLOOR(min / 60)-(FLOOR(min/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(min / 60)-(FLOOR(min/3600)*60) || ':' ||
TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'000' END)
WHEN TRUNC(min-TRUNC(min), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN (CASE WHEN min<3600 THEN FLOOR(min / 60) || ':' ||
TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'00'
ELSE FLOOR(min / 3600) || ':' || CASE WHEN FLOOR(min / 60)-(FLOOR(min/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(min / 60)-(FLOOR(min/3600)*60) || ':' ||
TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'00' END)
WHEN TRUNC(min-TRUNC(min), 3) IN (SELECT numb FROM decimals_table_runner)
THEN (CASE WHEN min<3600 THEN FLOOR(min / 60) || ':' ||
TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'0'
ELSE FLOOR(min / 3600) || ':' || CASE WHEN FLOOR(min / 60)-(FLOOR(min/3600)*60)<10 THEN '0' ELSE '' END ||
          FLOOR(min / 60)-(FLOOR(min/3600)*60) || ':' ||
TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')||'0' END)
ELSE (CASE WHEN min<3600 THEN FLOOR(min / 60) || ':' ||
TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999')
ELSE FLOOR(min / 3600) || ':' || CASE WHEN FLOOR(min / 60)-(FLOOR(min/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(min / 60)-(FLOOR(min/3600)*60)|| ':' ||
TO_CHAR(TRUNC(min, 3) % 60, 'FM00.999') END) END AS best_pace_at_that_time, min AS best_pace_at_that_time2/*,
avg_pace, median_pace, avg_pace2, median_pace2*/, RANK() OVER (PARTITION BY cle2 ORDER BY pace) AS rank_pace
FROM (SELECT a.cle2, a.id, a.split, a.number_of_splits, a.pace, a.best_pace, a.pace2, a.best_pace2, /*a.avg_pace, a.median_pace,
a.avg_pace2, a.median_pace2,*/ MIN(b.pace) AS min,
MIN(b.pace2) AS min2
FROM best_paces_runner a
LEFT JOIN best_paces_runner b ON a.cle2=b.cle2 AND a.id>b.id
GROUP BY a.cle2, a.id, a.split, a.number_of_splits, a.pace, a.best_pace, a.pace2, a.best_pace2/*, a.avg_pace, a.median_pace,
a.avg_pace2, a.median_pace2*/) a
ORDER BY cle2 DESC, id;

DROP TABLE IF EXISTS best_paces_history_runner2;
CREATE TABLE best_paces_history_runner2 AS
SELECT a.*, pace_rank_at_that_time, finished_paces, finished_paces_at_that_time
FROM best_paces_history_runner a
LEFT JOIN (SELECT cle2, COUNT(*) AS finished_paces FROM best_paces_history_runner GROUP BY 1) c ON a.cle2=c.cle2
LEFT JOIN (SELECT *
FROM (SELECT a.*, b.pace AS pace_time3, b.id AS id2,
RANK() OVER (PARTITION BY a.cle2, a.id ORDER BY b.pace) AS pace_rank_at_that_time
FROM best_paces_history_runner a
JOIN best_paces_history_runner b ON a.cle2=b.cle2 AND a.id>=b.id) a
WHERE id=id2) d ON a.cle2=d.cle2 AND a.id=d.id

LEFT JOIN (

SELECT a.cle2, a.id, COUNT(*) AS finished_paces_at_that_time
FROM best_paces_history_runner a
JOIN best_paces_history_runner b ON a.cle2=b.cle2 AND a.id>=b.id
GROUP BY 1, 2) e ON a.cle2=e.cle2 AND a.id=e.id;

/* Checking is a gold was done ON a gold hunt (bad run) by checking the delta between the pace of that run AND the best pace for each split */

DROP TABLE IF EXISTS gold_hunt_detector_runner;
CREATE TABLE gold_hunt_detector_runner AS
SELECT cle2, split, gold, gold2, id, date_started, finished_run, final_lrt, pb, pace, pace2, best_pace, best_pace2,
best_pace_delta
FROM(
SELECT a.*, pace, best_pace, pace-best_pace AS best_pace_delta, pace2, best_pace2,
ROW_NUMBER () OVER (PARTITION BY a.cle2 ORDER BY pace-best_pace) AS rang
FROM doorsplits_golds_runner a
LEFT JOIN best_paces_history_runner2 b ON a.id=b.id AND a.cle2=b.cle2) a
WHERE rang=1
ORDER BY cle2;

/* Resets history to get the % of resets for each split */

DROP TABLE IF EXISTS resets_history_runner;
CREATE TABLE resets_history_runner AS
SELECT a.*, attempts
FROM(
SELECT cle2, split, COUNT(*) AS runs
FROM splits_cleaned_runner
GROUP BY cle2, split
ORDER BY cle2) a CROSS JOIN (SELECT COUNT(*) AS attempts
FROM attempts_treatment3_runner
GROUP BY runner_name) b;

DROP TABLE IF EXISTS resets_history2_runner;
CREATE TABLE resets_history2_runner AS
SELECT cle2, split, runs, resets, (ROUND(resets)/ROUND(CASE WHEN lag IS NULL THEN runs+resets ELSE lag END))*100
AS percentage_resets
FROM(
SELECT *, LAG(runs) OVER() AS lag
FROM(
SELECT cle2, split, runs, CASE WHEN LAG(runs) OVER ()-runs IS NULL THEN attempts-runs ELSE LAG(runs) OVER ()-runs END AS resets
FROM resets_history_runner));

/* Final main table that has everything */

DROP TABLE IF EXISTS splits_overview_runner;
CREATE TABLE splits_overview_runner AS
SELECT *
FROM (SELECT a.id, a.split, a.chapter, a.section, a.lrt_number, a.lrt_split, a.date_started, a.finished_run, a.final_lrt, a.pb, a.cle2, a.final_rta,
a.date_end, a.time_start_numeric3 AS time_start, a.time_end_numeric3 AS time_end, a.playtime, a.rta_numeric, a.rta_split, e.gold2, e.gold, pace,
pace2, best_pace, best_pace2, chapter_time, chapter_time2, section_time, section_time2,
chapter_gold, chapter_gold2, section_gold, section_gold2,
CASE WHEN a.finished_run=1 THEN NULL ELSE split_of_reset END AS split_of_reset,
CASE WHEN a.finished_run=1 THEN NULL ELSE cle2_reset END AS cle2_reset,
CASE WHEN a.cle2=30 AND lrt_number<=54.5 THEN '2-a Fast Mendez'
WHEN a.cle2=30 AND lrt_number<=57 THEN '2-b Medium Mendez'
WHEN a.cle2=30 THEN '2-c Slow Mendez'
ELSE '' END AS mendez_pattern,
CASE WHEN a.cle2=14 AND lrt_number<=96 THEN '1-a No dive'
WHEN a.cle2=14 AND lrt_number<=102 THEN '1-b Late dive'
WHEN a.cle2=14 OR (a.cle2=13 AND cle2_reset=14) THEN '1-c Early dive'
ELSE '' END AS lago_pattern,
CASE WHEN a.cle2=65 AND lrt_number<=31 THEN '3-a Perfect catapult'
WHEN a.cle2=65 AND lrt_number<=33 THEN '3-b Stagger catapult'
WHEN a.cle2=65 THEN '3-c Boulder catapult'
ELSE '' END AS catapult_pattern,
CASE WHEN a.cle2=26 AND lrt_number<=113 THEN '4-a Great cabin'
WHEN a.cle2=26 AND lrt_number<=118 THEN '4-b Good cabin'
WHEN a.cle2=26 AND lrt_number<=123 THEN '4-c Average cabin'
WHEN a.cle2=26 AND lrt_number<=130 THEN '4-d Bad cabin'
WHEN a.cle2=26 THEN '4-e Shitty cabin'
ELSE '' END AS cabin_pattern,
CASE WHEN a.cle2=38 AND lrt_number<=196 THEN '5-a Great water hall'
WHEN a.cle2=38 AND lrt_number<=199 THEN '5-b Good water hall'
WHEN a.cle2=38 AND lrt_number<=202 THEN '5-c Average water hall'
WHEN a.cle2=38 AND lrt_number<=205 THEN '5-d Bad water hall'
WHEN a.cle2=38 THEN '5-e Shitty water hall'
ELSE '' END AS water_hall_pattern,
CASE WHEN a.cle2=41 AND lrt_number<=82 THEN '6-a Great novis 1'
WHEN a.cle2=41 AND lrt_number<=84 THEN '6-b Good novis 1'
WHEN a.cle2=41 AND lrt_number<=86 THEN '6-c Average novis 1'
WHEN a.cle2=41 AND lrt_number<=88 THEN '6-d Bad novis 1'
WHEN a.cle2=41 THEN '6-e Shitty novis 1'
ELSE '' END AS novis1_pattern,
CASE WHEN a.cle2=43 AND lrt_number<=102 THEN '7-a Great gallery'
WHEN a.cle2=43 AND lrt_number<=105 THEN '7-b Good gallery'
WHEN a.cle2=43 AND lrt_number<=108 THEN '7-c Average gallery'
WHEN a.cle2=43 AND lrt_number<=110 THEN '7-d Bad gallery'
WHEN a.cle2=43 THEN '7-e Shitty gallery'
ELSE '' END AS gallery_pattern,
CASE WHEN a.cle2=64 AND lrt_number<=33.5 THEN '8-a Great novis 2'
WHEN a.cle2=64 AND lrt_number<=35 THEN '8-b Good novis 2'
WHEN a.cle2=64 AND lrt_number<=38 THEN '8-c Average novis 2'
WHEN a.cle2=64 AND lrt_number<=40 THEN '8-d Bad novis 2'
WHEN a.cle2=64 THEN '8-e Shitty novis 2'
ELSE '' END AS novis2_pattern,
CASE WHEN a.cle2=74 AND lrt_number<=77 THEN '9-a Great novis 3'
WHEN a.cle2=74 AND lrt_number<=79 THEN '9-b Good novis 3'
WHEN a.cle2=74 AND lrt_number<=82 THEN '9-c Average novis 3'
WHEN a.cle2=74 AND lrt_number<=85 THEN '9-d Bad novis 3'
WHEN a.cle2=74 THEN '9-e Shitty novis 3'
ELSE '' END AS novis3_pattern,
CASE WHEN a.cle2=110 AND lrt_number<=95.5 THEN '90-a Great u3'
WHEN a.cle2=110 AND lrt_number<=99 THEN '90-b Good u3'
WHEN a.cle2=110 AND lrt_number<=101 THEN '90-c Average u3'
WHEN a.cle2=110 AND lrt_number<=103 THEN '90-d Bad u3'
WHEN a.cle2=110 THEN '90-e Shitty u3'
ELSE '' END AS u3_pattern,
CASE WHEN a.cle2=112 AND lrt_number<=139 THEN '91-a Great Krauser'
WHEN a.cle2=112 AND lrt_number<=142 THEN '91-b Good Krauser'
WHEN a.cle2=112 AND lrt_number<=145 THEN '91-c Average Krauser'
WHEN a.cle2=112 AND lrt_number<=148 THEN '91-d Bad Krauser'
WHEN a.cle2=112 THEN '91-e Shitty Krauser'
ELSE '' END AS krauser_pattern,
CASE WHEN a.cle2=113 AND lrt_number<=111 THEN '92-a Great war room'
WHEN a.cle2=113 AND lrt_number<=114 THEN '92-b Good war room'
WHEN a.cle2=113 AND lrt_number<=117 THEN '92-c Average war room'
WHEN a.cle2=113 AND lrt_number<=120 THEN '92-d Bad war room'
WHEN a.cle2=113 THEN '92-e Shitty war room'
ELSE '' END AS war_room_pattern,
CASE WHEN a.cle2=117 AND lrt_number<=55 THEN '93-a Great key card'
WHEN a.cle2=117 AND lrt_number<=57 THEN '93-b Good key card'
WHEN a.cle2=117 AND lrt_number<=59 THEN '93-c Average key card'
WHEN a.cle2=117 AND lrt_number<=61 THEN '93-d Bad key card'
WHEN a.cle2=117 THEN '93-e Shitty key card'
ELSE '' END AS key_card_pattern,
CASE WHEN extract(dow FROM a.date_started)=0 THEN 7 ELSE extract(dow FROM a.date_started) END AS weekday,
h.lrt_pb AS pb_at_that_time, golded_split, golded_chapter, golded_section, was_best_pace, cumulative_chapter_gold, cumulative_chapter_gold_num, cumulative_section_gold,
cumulative_door_gold, cumulative_door_gold_num, gold_at_that_time, chapter_gold_at_that_time, section_gold_at_that_time, best_pace_at_that_time,
best_pace_at_that_time2, CASE WHEN CAST(substr(a.time_start, 1, 2) AS NUMERIC)>CAST(substr(a.time_start_numeric3, 1, 2) AS NUMERIC)
THEN a.date_started+1 ELSE a.date_started END AS date_started2,
CASE WHEN CAST(substr(a.time_end, 1, 2) AS NUMERIC)<CAST(substr(a.time_end_numeric3, 1, 2) AS NUMERIC)
THEN a.date_end-1 ELSE a.date_end END AS date_end2, door_avg, door_median, door_avg2, door_median2, median_chapter_time, median_chapter_time2,
/*avg_pace, median_pace, avg_pace2, median_pace2,*/ section_median, section_median2, section_avg2, avg_chapter_time2, 'runner' AS runner_name, rank_chapter, chapter_rank_at_that_time, finished_chapters,
finished_chapters_at_that_time, rank_section, section_rank_at_that_time, finished_sections, finished_sections_at_that_time, rank_split, split_rank_at_that_time, finished_splits, finished_splits_at_that_time,
rank_pace, pace_rank_at_that_time, finished_paces, finished_paces_at_that_time,
ROW_NUMBER() OVER (PARTITION BY a.id, a.cle2 ORDER BY id2 DESC) AS rang
FROM splits_cleaned_runner a
LEFT JOIN best_paces_history_runner2 b ON a.id=b.id AND a.cle2=b.cle2
LEFT JOIN (SELECT cle2, gold2, gold, door_avg, door_median, door_avg2, door_median2, MIN(cumulative_door_gold) AS cumulative_door_gold, MIN(cumulative_door_gold_num) AS cumulative_door_gold_num
		   FROM doorsplits_golds2_runner
		   GROUP BY cle2, gold2, gold, door_avg, door_median, door_avg2, door_median2) e ON a.cle2=e.cle2
LEFT JOIN doorsplits_golds_history_runner2 ee ON a.cle2=ee.cle2 AND a.id=ee.id
LEFT JOIN chapter_history3_runner c ON a.id=c.id AND a.chapter=c.chapter
LEFT JOIN section_history3_runner d ON a.id=d.id AND a.section=d.section
LEFT JOIN chapter_golds3_runner f ON a.chapter=f.chapter
LEFT JOIN section_golds3_runner g ON a.section=g.section
LEFT JOIN (SELECT a.id, b.split AS split_of_reset, b.cle2 AS cle2_reset
FROM (SELECT id, MAX(cle2)+1 AS max
FROM splits_cleaned_runner
GROUP BY id) a
LEFT JOIN (SELECT DISTINCT cle2, split FROM splits_cleaned_runner) b ON a.max=b.cle2) resets ON resets.id=a.id
LEFT JOIN (SELECT *, CAST (id AS NUMERIC) AS id2 FROM pb_history_runner) h ON a.id>h.id2) aa
WHERE rang=1
ORDER BY id, cle2;

/* RNG splits (LIKE Lago) to get the % of patterns (LIKE % of early dives, etc.) */

DROP TABLE IF EXISTS rng_splits_runner;
CREATE TABLE rng_splits_runner AS
SELECT pattern, substr(pattern, 4, LENGTH(pattern)-3) AS pattern2, runs, total, percentage
FROM(SELECT pattern, runs, total, percentage
FROM (SELECT a.*, total, ROUND(runs)/ROUND(total)*100 AS percentage
FROM(
SELECT lago_pattern AS pattern, COUNT(*) AS runs
FROM splits_overview_runner a
LEFT JOIN splits_cleaned_runner b ON a.id=b.id AND a.cle2=b.cle2
WHERE (a.cle2=14 AND a.lrt_number<117) OR (a.cle2=13 AND cle2_reset=14 AND
CASE WHEN time_end_numeric2>time_end_numeric AND b.time_end<>time_end_numeric3 THEN time_end_numeric-time_end_numeric2+86400 ELSE time_end_numeric-time_end_numeric2 END>=CASE WHEN runner_name LIKE '%lu%'
AND runner_name LIKE '%is%' THEN 59 ELSE 56 END)
GROUP BY 1) a
CROSS JOIN (
SELECT COUNT(*) AS total
FROM splits_overview_runner a
LEFT JOIN splits_cleaned_runner b ON a.id=b.id AND a.cle2=b.cle2
WHERE (a.cle2=14 AND a.lrt_number<117) OR (a.cle2=13 AND cle2_reset=14 AND
CASE WHEN time_end_numeric2>time_end_numeric AND b.time_end<>time_end_numeric3 THEN time_end_numeric-time_end_numeric2+86400 ELSE time_end_numeric-time_end_numeric2 END>=CASE WHEN runner_name LIKE '%lu%'
AND runner_name LIKE '%is%' THEN 59 ELSE 56 END)) b)
UNION
(SELECT a.*, total, ROUND(runs)/ROUND(total)*100 AS percentage
FROM(
SELECT mendez_pattern AS pattern, COUNT(*) AS runs
FROM splits_overview_runner
WHERE mendez_pattern<>'' AND lrt_number<60
GROUP BY 1) a
CROSS JOIN (
SELECT COUNT(*) AS total
FROM splits_overview_runner
WHERE cle2=30 AND lrt_number<60) b)
UNION
(SELECT a.*, total, ROUND(runs)/ROUND(total)*100 AS percentage
FROM(
SELECT catapult_pattern AS pattern, COUNT(*) AS runs
FROM splits_overview_runner
WHERE catapult_pattern<>'' AND lrt_number<40
GROUP BY 1) a
CROSS JOIN (
SELECT COUNT(*) AS total
FROM splits_overview_runner
WHERE cle2=65 AND lrt_number<40) b)
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
WHERE cle2=26
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
WHERE cle2=38
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
WHERE cle2=41
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
WHERE cle2=43
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
WHERE cle2=64
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
WHERE cle2=74
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
WHERE cle2=110
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
WHERE cle2=112
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
WHERE cle2=113
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
WHERE cle2=117
) b)
ORDER BY pattern);

/* Same but to get the consecutive patterns (LIKE how many early dives IN a row */

DROP TABLE IF EXISTS consecutive_patterns_runner;
CREATE TABLE consecutive_patterns_runner AS
SELECT *
FROM (
SELECT lago_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT id, lago_pattern, ROW_NUMBER() OVER (PARTITION BY lago_pattern, ROW_NUMBER - row_number2 ORDER BY id) AS rank
FROM(
SELECT DISTINCT a.id, lago_pattern,
ROW_NUMBER() OVER (ORDER BY a.id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY lago_pattern ORDER BY a.id) AS row_number2
FROM splits_overview_runner a
LEFT JOIN splits_cleaned_runner b ON a.id=b.id AND a.cle2=b.cle2
WHERE (a.cle2=14 AND a.lrt_number<117) OR (a.cle2=13 AND cle2_reset=14 AND
CASE WHEN time_end_numeric2>time_end_numeric AND b.time_end<>time_end_numeric3 THEN time_end_numeric-time_end_numeric2+86400 ELSE time_end_numeric-time_end_numeric2 END>=CASE WHEN runner_name LIKE '%lu%'
AND runner_name LIKE '%is%' THEN 59 ELSE 56 END))
ORDER BY id)
GROUP BY 1
UNION
SELECT mendez_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT id, mendez_pattern, ROW_NUMBER() OVER (PARTITION BY mendez_pattern, ROW_NUMBER - row_number2 ORDER BY id) AS rank
FROM(
SELECT DISTINCT id, mendez_pattern,
ROW_NUMBER() OVER (ORDER BY id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY mendez_pattern ORDER BY id) AS row_number2
FROM splits_overview_runner
WHERE mendez_pattern<>'' AND lrt_number<60)
ORDER BY id)
GROUP BY 1
UNION
SELECT catapult_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT id, catapult_pattern, ROW_NUMBER() OVER (PARTITION BY catapult_pattern, ROW_NUMBER - row_number2 ORDER BY id) AS rank
FROM(
SELECT DISTINCT id, catapult_pattern,
ROW_NUMBER() OVER (ORDER BY id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY catapult_pattern ORDER BY id) AS row_number2
FROM splits_overview_runner
WHERE catapult_pattern<>'' AND lrt_number<40)
ORDER BY id)
GROUP BY 1
UNION
SELECT cabin_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT id, cabin_pattern, ROW_NUMBER() OVER (PARTITION BY cabin_pattern, ROW_NUMBER - row_number2 ORDER BY id) AS rank
FROM(
SELECT DISTINCT id, cabin_pattern,
ROW_NUMBER() OVER (ORDER BY id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY cabin_pattern ORDER BY id) AS row_number2
FROM splits_overview_runner
WHERE cabin_pattern<>''
)
ORDER BY id)
GROUP BY 1
UNION
SELECT water_hall_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT id, water_hall_pattern, ROW_NUMBER() OVER (PARTITION BY water_hall_pattern, ROW_NUMBER - row_number2 ORDER BY id) AS rank
FROM(
SELECT DISTINCT id, water_hall_pattern,
ROW_NUMBER() OVER (ORDER BY id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY water_hall_pattern ORDER BY id) AS row_number2
FROM splits_overview_runner
WHERE water_hall_pattern<>''
)
ORDER BY id)
GROUP BY 1
UNION
SELECT novis1_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT id, novis1_pattern, ROW_NUMBER() OVER (PARTITION BY novis1_pattern, ROW_NUMBER - row_number2 ORDER BY id) AS rank
FROM(
SELECT DISTINCT id, novis1_pattern,
ROW_NUMBER() OVER (ORDER BY id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY novis1_pattern ORDER BY id) AS row_number2
FROM splits_overview_runner
WHERE novis1_pattern<>''
)
ORDER BY id)
GROUP BY 1
UNION
SELECT gallery_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT id, gallery_pattern, ROW_NUMBER() OVER (PARTITION BY gallery_pattern, ROW_NUMBER - row_number2 ORDER BY id) AS rank
FROM(
SELECT DISTINCT id, gallery_pattern,
ROW_NUMBER() OVER (ORDER BY id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY gallery_pattern ORDER BY id) AS row_number2
FROM splits_overview_runner
WHERE gallery_pattern<>''
)
ORDER BY id)
GROUP BY 1
UNION
SELECT novis2_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT id, novis2_pattern, ROW_NUMBER() OVER (PARTITION BY novis2_pattern, ROW_NUMBER - row_number2 ORDER BY id) AS rank
FROM(
SELECT DISTINCT id, novis2_pattern,
ROW_NUMBER() OVER (ORDER BY id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY novis2_pattern ORDER BY id) AS row_number2
FROM splits_overview_runner
WHERE novis2_pattern<>''
)
ORDER BY id)
GROUP BY 1
UNION
SELECT novis3_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT id, novis3_pattern, ROW_NUMBER() OVER (PARTITION BY novis3_pattern, ROW_NUMBER - row_number2 ORDER BY id) AS rank
FROM(
SELECT DISTINCT id, novis3_pattern,
ROW_NUMBER() OVER (ORDER BY id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY novis3_pattern ORDER BY id) AS row_number2
FROM splits_overview_runner
WHERE novis3_pattern<>''
)
ORDER BY id)
GROUP BY 1
UNION
SELECT u3_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT id, u3_pattern, ROW_NUMBER() OVER (PARTITION BY u3_pattern, ROW_NUMBER - row_number2 ORDER BY id) AS rank
FROM(
SELECT DISTINCT id, u3_pattern,
ROW_NUMBER() OVER (ORDER BY id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY u3_pattern ORDER BY id) AS row_number2
FROM splits_overview_runner
WHERE u3_pattern<>''
)
ORDER BY id)
GROUP BY 1
UNION
SELECT krauser_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT id, krauser_pattern, ROW_NUMBER() OVER (PARTITION BY krauser_pattern, ROW_NUMBER - row_number2 ORDER BY id) AS rank
FROM(
SELECT DISTINCT id, krauser_pattern,
ROW_NUMBER() OVER (ORDER BY id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY krauser_pattern ORDER BY id) AS row_number2
FROM splits_overview_runner
WHERE krauser_pattern<>''
)
ORDER BY id)
GROUP BY 1
UNION
SELECT war_room_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT id, war_room_pattern, ROW_NUMBER() OVER (PARTITION BY war_room_pattern, ROW_NUMBER - row_number2 ORDER BY id) AS rank
FROM(
SELECT DISTINCT id, war_room_pattern,
ROW_NUMBER() OVER (ORDER BY id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY war_room_pattern ORDER BY id) AS row_number2
FROM splits_overview_runner
WHERE war_room_pattern<>''
)
ORDER BY id)
GROUP BY 1
UNION
SELECT key_card_pattern, MAX(rank) AS maximum_consecutive_patterns
FROM(
SELECT id, key_card_pattern, ROW_NUMBER() OVER (PARTITION BY key_card_pattern, ROW_NUMBER - row_number2 ORDER BY id) AS rank
FROM(
SELECT DISTINCT id, key_card_pattern,
ROW_NUMBER() OVER (ORDER BY id) AS ROW_NUMBER,
ROW_NUMBER() OVER (PARTITION BY key_card_pattern ORDER BY id) AS row_number2
FROM splits_overview_runner
WHERE key_card_pattern<>''
)
ORDER BY id)
GROUP BY 1

)
ORDER BY lago_pattern;

/* Script is finished, here we have some useful queries */

/* All chapter golds with doorsplits golds combined per chapter */

DROP TABLE IF EXISTS chapter_golds_sheet_runner;
CREATE TABLE chapter_golds_sheet_runner AS
SELECT a.chapter, a.id, a.date_started, a.final_lrt, a.pb, a.chapter_gold2,
CASE WHEN cumulative_chapter_gold2<60 THEN (CASE WHEN TRUNC(cumulative_chapter_gold2-TRUNC(cumulative_chapter_gold2), 3) =0 THEN
TO_CHAR(TRUNC(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'000'
WHEN TRUNC(cumulative_chapter_gold2-TRUNC(cumulative_chapter_gold2), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN TO_CHAR(TRUNC(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'00'
WHEN TRUNC(cumulative_chapter_gold2-TRUNC(cumulative_chapter_gold2), 3) IN (SELECT numb FROM decimals_table_runner)
THEN TO_CHAR(TRUNC(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'0'
ELSE
TO_CHAR(TRUNC(cumulative_chapter_gold2, 3) % 60, 'FM00.999') END)
ELSE (CASE WHEN TRUNC(cumulative_chapter_gold2-TRUNC(cumulative_chapter_gold2), 3) =0
THEN FLOOR(cumulative_chapter_gold2 / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'000'
WHEN TRUNC(cumulative_chapter_gold2-TRUNC(cumulative_chapter_gold2), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN FLOOR(cumulative_chapter_gold2 / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'00'
WHEN TRUNC(cumulative_chapter_gold2-TRUNC(cumulative_chapter_gold2), 3) IN (SELECT numb FROM decimals_table_runner)
THEN FLOOR(cumulative_chapter_gold2 / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'0'
ELSE
FLOOR(cumulative_chapter_gold2 / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold2, 3) % 60, 'FM00.999') END) END AS doorsplit_combined_gold, cumulative_chapter_gold2 AS doorsplit_combined_gold2, a.cumulative_chapter_gold,
cumulative_door_gold, cumulative_door_gold_num, avg_chapter_time2, chapter_gold_at_that_time AS previous_chapter_gold
FROM chapter_golds3_runner a
LEFT JOIN (SELECT chapter, SUM(gold) AS cumulative_chapter_gold2
		   FROM(
SELECT chapter, a.gold, a.gold2, a.cle2, MIN(cumulative_door_gold) AS cumulative_door_gold
FROM doorsplits_golds2_runner a
LEFT JOIN (SELECT DISTINCT cle2, chapter FROM splits_overview_runner) b ON a.cle2=b.cle2
			   GROUP BY chapter, a.gold, a.gold2, a.cle2 ORDER BY a.cle2) b
		  GROUP BY chapter) bb ON a.chapter=bb.chapter
LEFT JOIN (SELECT *
		   FROM (SELECT cle2, chapter, cumulative_door_gold, cumulative_door_gold_num, ROW_NUMBER() OVER(PARTITION BY chapter
ORDER BY cle2 DESC) AS rang FROM splits_overview_runner) a WHERE rang=1) c ON a.chapter=c.chapter
LEFT JOIN (SELECT DISTINCT id, chapter, chapter_gold_at_that_time
		   FROM splits_overview_runner WHERE chapter_time2=chapter_gold2) d ON a.chapter=d.chapter AND a.id=d.id;

/* All section golds with doorsplits golds combined per section + chapter golds combined per section */

DROP TABLE IF EXISTS section_golds_sheet_runner;
CREATE TABLE section_golds_sheet_runner AS
SELECT a.section, a.id, a.date_started, a.final_lrt, a.pb, a.section_gold2,
CASE WHEN TRUNC(cumulative_chapter_gold3-TRUNC(cumulative_chapter_gold3), 3)=0 THEN (CASE WHEN cumulative_chapter_gold3>=3600 THEN
FLOOR(cumulative_chapter_gold3 / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold3 / 60)-(FLOOR(cumulative_chapter_gold3/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(cumulative_chapter_gold3 / 60)-(FLOOR(cumulative_chapter_gold3/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold3, 3) % 60, 'FM00.999')||'000'
ELSE FLOOR(cumulative_chapter_gold3 / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold3, 3) % 60, 'FM00.999')||'000' END)
WHEN TRUNC(cumulative_chapter_gold3-TRUNC(cumulative_chapter_gold3), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN (CASE WHEN cumulative_chapter_gold3>=3600 THEN
FLOOR(cumulative_chapter_gold3 / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold3 / 60)-(FLOOR(cumulative_chapter_gold3/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(cumulative_chapter_gold3 / 60)-(FLOOR(cumulative_chapter_gold3/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold3, 3) % 60, 'FM00.999')||'00'
ELSE FLOOR(cumulative_chapter_gold3 / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold3, 3) % 60, 'FM00.999')||'00' END)
WHEN TRUNC(cumulative_chapter_gold3-TRUNC(cumulative_chapter_gold3), 3) IN (SELECT numb FROM decimals_table_runner)
THEN (CASE WHEN cumulative_chapter_gold3>=3600 THEN
FLOOR(cumulative_chapter_gold3 / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold3 / 60)-(FLOOR(cumulative_chapter_gold3/3600)*60)<10 THEN '0' ELSE '' END ||
          FLOOR(cumulative_chapter_gold3 / 60)-(FLOOR(cumulative_chapter_gold3/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold3, 3) % 60, 'FM00.999')||'0'
ELSE FLOOR(cumulative_chapter_gold3 / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold3, 3) % 60, 'FM00.999')||'0' END)
ELSE (CASE WHEN cumulative_chapter_gold3>=3600 THEN
FLOOR(cumulative_chapter_gold3 / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold3 / 60)-(FLOOR(cumulative_chapter_gold3/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(cumulative_chapter_gold3 / 60)-(FLOOR(cumulative_chapter_gold3/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold3, 3) % 60, 'FM00.999')
ELSE FLOOR(cumulative_chapter_gold3 / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold3, 3) % 60, 'FM00.999') END) END AS chapter_combined_gold, cumulative_chapter_gold3 AS chapter_combined_gold2,

CASE WHEN TRUNC(cumulative_chapter_gold2-TRUNC(cumulative_chapter_gold2), 3)=0 THEN (CASE WHEN cumulative_chapter_gold2>=3600 THEN
FLOOR(cumulative_chapter_gold2 / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold2 / 60)-(FLOOR(cumulative_chapter_gold2/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(cumulative_chapter_gold2 / 60)-(FLOOR(cumulative_chapter_gold2/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'000'
ELSE FLOOR(cumulative_chapter_gold2 / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'000' END)
WHEN TRUNC(cumulative_chapter_gold2-TRUNC(cumulative_chapter_gold2), 3) IN (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
THEN (CASE WHEN cumulative_chapter_gold2>=3600 THEN
FLOOR(cumulative_chapter_gold2 / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold2 / 60)-(FLOOR(cumulative_chapter_gold2/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(cumulative_chapter_gold2 / 60)-(FLOOR(cumulative_chapter_gold2/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'00'
ELSE FLOOR(cumulative_chapter_gold2 / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'00' END)
WHEN TRUNC(cumulative_chapter_gold2-TRUNC(cumulative_chapter_gold2), 3) IN (SELECT numb FROM decimals_table_runner)
THEN (CASE WHEN cumulative_chapter_gold2>=3600 THEN
FLOOR(cumulative_chapter_gold2 / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold2 / 60)-(FLOOR(cumulative_chapter_gold2/3600)*60)<10 THEN '0' ELSE '' END ||
          FLOOR(cumulative_chapter_gold2 / 60)-(FLOOR(cumulative_chapter_gold2/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'0'
ELSE FLOOR(cumulative_chapter_gold2 / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'0' END)
ELSE (CASE WHEN cumulative_chapter_gold2>=3600 THEN
FLOOR(cumulative_chapter_gold2 / 3600) || ':' || CASE WHEN FLOOR(cumulative_chapter_gold2 / 60)-(FLOOR(cumulative_chapter_gold2/3600)*60)<10 THEN '0' ELSE '' END ||
	  FLOOR(cumulative_chapter_gold2 / 60)-(FLOOR(cumulative_chapter_gold2/3600)*60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold2, 3) % 60, 'FM00.999')
ELSE FLOOR(cumulative_chapter_gold2 / 60) || ':' ||
TO_CHAR(TRUNC(cumulative_chapter_gold2, 3) % 60, 'FM00.999') END) END AS doorsplit_combined_gold, cumulative_chapter_gold2 AS doorsplit_combined_gold2, a.cumulative_section_gold,
cumulative_chapter_gold, cumulative_chapter_gold_num, cumulative_door_gold, cumulative_door_gold_num, a.section_avg2, section_gold_at_that_time AS previous_section_gold
FROM section_golds3_runner a
LEFT JOIN (SELECT section, SUM(gold) AS cumulative_chapter_gold2
		   FROM(
SELECT DISTINCT section, a.gold, a.gold2, a.cle2
FROM doorsplits_golds2_runner a
LEFT JOIN (SELECT DISTINCT cle2, section FROM splits_overview_runner) b ON a.cle2=b.cle2) b
		  GROUP BY section) bb ON a.section=bb.section
LEFT JOIN (SELECT *
		   FROM (SELECT cle2, section, cumulative_door_gold, cumulative_door_gold_num, ROW_NUMBER() OVER(PARTITION BY section
ORDER BY cle2 DESC) AS rang FROM splits_overview_runner) a WHERE rang=1) c ON a.section=c.section

LEFT JOIN (SELECT section, SUM(chapter_gold) AS cumulative_chapter_gold3
		   FROM(
SELECT section, a.chapter_gold, a.chapter_gold2, a.chapter, MIN(cumulative_chapter_gold) AS cumulative_chapter_gold
FROM chapter_golds3_runner a
LEFT JOIN (SELECT DISTINCT chapter, section FROM splits_overview_runner) b ON a.chapter=b.chapter
			   GROUP BY section, a.chapter_gold, a.chapter_gold2, a.chapter ORDER BY a.chapter) b
		  GROUP BY section) d ON a.section=d.section
LEFT JOIN (SELECT *
		   FROM (SELECT chapter, section, cumulative_chapter_gold, cumulative_chapter_gold_num, ROW_NUMBER() OVER(PARTITION BY section
ORDER BY chapter DESC) AS rang FROM splits_overview_runner) a WHERE rang=1) e ON a.section=e.section
LEFT JOIN (SELECT DISTINCT id, section, section_gold_at_that_time
		   FROM splits_overview_runner WHERE section_time2=section_gold2) f ON a.section=f.section AND a.id=f.id
ORDER BY CASE WHEN a.section='Village' THEN 1 WHEN a.section='Castle' THEN 2 ELSE 3 END;

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
FROM (SELECT CASE WHEN extract(dow FROM date_started)=0 THEN 7 ELSE extract(dow FROM date_started) END AS weekday,
SUM(playtime) AS playtime, COUNT(DISTINCT id) AS attempts, COUNT(DISTINCT CASE WHEN pb=1 THEN id ELSE NULL END) AS number_of_pbs,
ROUND(ROUND(ROUND(COUNT(DISTINCT CASE WHEN pb=1 THEN id ELSE NULL END), 4)/ROUND(COUNT(DISTINCT id), 4), 4)*100, 2)||'%' AS pb_ratio,
ROUND(SUM(playtime))/CASE WHEN ROUND(COUNT(DISTINCT CASE WHEN pb=1 THEN id ELSE NULL END))=0 THEN NULL ELSE
ROUND(COUNT(DISTINCT CASE WHEN pb=1 THEN id ELSE NULL END)) END playtime_to_get_a_pb
FROM attempts_treatment3_runner
GROUP BY 1) a
LEFT JOIN (
SELECT CASE WHEN extract(dow FROM date_started)=0 THEN 7 ELSE extract(dow FROM date_started) END AS weekday, SUM(golded_split) AS golds,
SUM(golded_chapter) AS chapter_golds, SUM(golded_section) AS section_golds, SUM(was_best_pace) AS best_paces
FROM splits_overview_runner
GROUP BY 1) b ON a.weekday=b.weekday
ORDER BY a.weekday;
