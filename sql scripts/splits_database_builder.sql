/* Before running the code there is 1 thing you need to do:

- You need to put your splits file in a folder on your PC where everyone has access, otherwise Postgres won't
have access to it and you'll get the permission denied error message when trying to import the .lss file, for that I suggest
you put the splits file in 'C:\Users\Public, if you don't want it to be here, you can change it but make sure it's a folder
where Postgres can access it (and change the folder path in the code right below).
This can be done only once and never again if you decide to keep your splits in that public folder everytime, but if not,
you'll have to manually move the splits file from where you usually keep it to the public folder everytime you want to run this script
with your last attempts. */

/* Importing the original splits file */

drop table if exists splits_runner;
create table splits_runner (notepad_info varchar (255));

copy splits_runner from 'path' with delimiter ','; /* Change path here + splits name */

/* Creating a table with default split names */

drop table if exists default_split_names_runner;
create table default_split_names_runner (split varchar(255), cle2 integer);

insert into default_split_names_runner (split, cle2)
values
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

/* Creating the table with runner names and their respective UTC time zones to chang ethe date and time of each attempt (by default it's set to UTC on LiveSplit no matter where you live) */

drop table if exists time_zone_runners;
create table time_zone_runners (name1 varchar(255), name2 varchar(255), utc integer);

insert into time_zone_runners (name1, name2, utc)
values
('saw', 'ken', 3),
('lu', 'is', -1),
('jo', 'ker', 3),
('ma', 'teo', 3),
('arca', 'dan', 3),
('ri', 'chy', 6),
('de', 'rek', 0);

drop table if exists time_zone_runners2;
create table time_zone_runners2 as
select name1||name2 as runner_name, utc
from time_zone_runners;

/* Creating the rng names for each pattern */

drop table if exists rng;
create table rng (pattern varchar(255));

insert into rng (pattern)
values
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

/* Creating a table with all the decimals (2 digits) from 0 to 1 */

drop table if exists decimals_table_runner;
create table decimals_table_runner (numb decimal);

insert into decimals_table_runner (numb)
values
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

/* We imported the whole splits including the LiveSplit settings and stuff, now we want to only keep the part with the segments history
(to get the golds, best paces, etc.)=part 1 */

drop table if exists notepad_splits_runner;
create table notepad_splits_runner as
select ltrim(notepad_info, ' ') as notepad_info
from (select *, row_number() over () as cle
from splits_runner) a
where cle >
(select cle
from (select *, row_number() over ()+1 as cle
from splits_runner) a
where notepad_info like '%</AttemptHistory>%')
and cle<
(select cle
from (select *, row_number() over () as cle
from splits_runner) a
where notepad_info like '%<AutoSplitterSettings%');

/* We do the same for the attempts (to get the date of the run, if the run was finished, if it was a PB, etc.)=part 2*/

drop table if exists notepad_attempts_runner;
create table notepad_attempts_runner as
select ltrim(notepad_info, ' ') as notepad_info, 'runner' as runner_name
from (select *, row_number() over () as cle
from splits_runner) a
where cle >
(select cle
from (select *, row_number() over () as cle
from splits_runner) a
where notepad_info like '%<AttemptHistory>%')
and cle<
(select cle
from (select *, row_number() over () as cle
from splits_runner) a
where notepad_info like '%</AttemptHistory>%');

drop table if exists splits_treatment_runner;
create table splits_treatment_runner as
select

/* Retrieving the run id from the notepad info, it's only present where the row contains <Time id="4">, this means it's the
run id number 4, for the parts that don't contain that, we simply leave it blank, for the rest, it will depend on the length
of the variable, if it's run id = 150 the length will be 1 extra compared to run id = 50 because there's obviously one
more digit, so depending on that, there's different cases, I went up to 6 digits, so until run id = 999999. */

case when notepad_info not like '%Time id%' then ''
when length(notepad_info)=13 then substr(substr(notepad_info, 11, 1), 1, 1)
when length(notepad_info)=14 then substr(substr(notepad_info, 11, 2), 1, 2)
when length(notepad_info)=15 then substr(substr(notepad_info, 11, 3), 1, 3)
when length(notepad_info)=16 then substr(substr(notepad_info, 11, 4), 1, 4)
when length(notepad_info)=17 then substr(substr(notepad_info, 11, 5), 1, 5)
when length(notepad_info)=18 then substr(substr(notepad_info, 11, 6), 1, 6)
else '' end as run_id,

/* Retrieving the split name, this one will only show once at the top for each split then will list of the times for each
run for this specific split */

case when notepad_info not like '%<Name>%' then ''
else substr(substr(notepad_info, 7, length(notepad_info)-6), 1, length(notepad_info)-13) end as split_name,

/* Retrieving the lrt time of the split */

case when notepad_info not like '%<GameTime>%' then ''
else substr(substr(notepad_info, 11, length(notepad_info)-10), 1, length(notepad_info)-21) end as lrt,
case when notepad_info not like '%<RealTime>%' then ''
else substr(substr(notepad_info, 11, length(notepad_info)-10), 1, length(notepad_info)-21) end as rta_split,
notepad_info as info, row_number() over () as cle /* This row_number can be useful to have a unique key for each row */
from notepad_splits_runner;

drop table if exists splits_treatment2_runner;
create table splits_treatment2_runner as
select *,

/* Converting the run id as an integer, sometimes (rare) there are some run ids with no time for a specific split (because it
was deleted by the runner) so it will show just id without a time and then the run id in this case will not be for example
100 but 100" so it will mess up the integer conversion, so for these rare cases we force them as 0 as done in this case when,
we also force the other blank rows to 0 */

case when (info like '%<Time id=%' and info like '% />%') or run_id='' then 0
else cast(run_id as integer) end as run_id2,

/* The LRT times for each split are showing 2 rows after the run id, we want everything on the same row so we just do the lead
function, we want the information from 2 rows after the run id but also 1 row after run id because sometimes the RTA is not
showing (negative runs) and it just has the LRT available, so in that case we just take the next row and not the one after it */

lead(lrt) over(order by cle) as lead,
lead(lrt, 2) over (order by cle) as lead2,
lead(rta_split) over(order by cle) as lead_rta
from splits_treatment_runner;

/* Now putting back the LRT times that are 2 rows below the row we want (or 1 row below if no RTA time) in the same row as the other info
(run id, etc.) and removing the other intermediate unnecessary columns */

drop table if exists splits_treatment3_runner;
create table splits_treatment3_runner as
select split_name, info, cle, run_id2,
case when run_id2=0 then '' when run_id2<0 then lead else lead2 end as lrt2,
case when run_id2<=0 then '' else lead_rta end as rta2
from splits_treatment2_runner;

/* Now that we have the run ids and the LRT times in the same row, we just need to get the split names on the same row too,
for that we select the minimum row number for each split (using the "cle" variable we created with the row_number function) which tells
us at which row starts the new split (so the previous split ends 1 row before that) */

drop table if exists split_name_info_runner;
create table split_name_info_runner as
select distinct split_name, rang, min(cle) as min
from(
select distinct split_name, row_number() over (partition by split_name order by cle) as rang, cle
from splits_treatment3_runner
where split_name<>'') a
group by 1, 2
order by 3;

drop table if exists split_name_info2_runner;
create table split_name_info2_runner as
select *,

/* Now that we have the min row for each split name, it's easy to get the max, it's just the min of the next split-1,
we also create a second "cle" variable "cle2" which also uses a row_number function but this time only with the 123 rows of the 123 unique
splits (and not the whole LiveSplit history rows), this will be useful to create the chapters and sections */

lead(min) over(order by min)-1 as max, row_number() over() as cle2
from split_name_info_runner;

drop table if exists split_name_info3_runner;
create table split_name_info3_runner as
select *,

/* Getting the chapter and section for each split using the "cle2" variable created just above, we know that 1-1 has only 4 splits if cle2
is between 1 and 4, we know it's one of the first 4 splits and therefore it's 1-1, etc.
Then doing the same for sections, technically we didn't need to created a cle2 variable, the original cle variable was already enough,
but it would have been a bit harder to create the chapter and section names since it depends on each runners splits, for example a runner
could have 10K rows of 1-1 then 8K rows of 1-2, etc. so we'd have to identify the chapters using the split names and stuff, here it's easy
since it's the same for everyone, everyone has 4 splits in 1-1, etc. (not to mention cle2 is actually a very useful variable and had to be
created anyway, since it's the split number, so cle2=1 means it's the first split of the run, etc.
It's better to use the id of the split instead of its name, since not all the runners have the same split names (this also skips the part
where everyone needs to have the same split names for the script to work) */

case when cle2<=4 then '1-1'
when cle2<=7 then '1-2'
when cle2<=14 then '1-3'
when cle2<=20 then '2-1'
when cle2<=26 then '2-2'
when cle2<=32 then '2-3'
when cle2<=39 then '3-1'
when cle2<=45 then '3-2'
when cle2<=48 then '3-3'
when cle2<=52 then '3-4'
when cle2<=70 then '4-1'
when cle2<=74 then '4-2'
when cle2<=78 then '4-3'
when cle2<=82 then '4-4'
when cle2<=98 then '5-1'
when cle2<=105 then '5-2'
when cle2<=112 then '5-3'
when cle2<=119 then '5-4'
else '6-1' end as chapter,
case when cle2<=32 then 'Village'
when cle2<=82 then 'Castle'
else 'Island' end as section
from split_name_info2_runner;

drop table if exists splits_treatment4_runner;
create table splits_treatment4_runner as

/* Now that the split names are finished (+chapter and section names added) we join that table with the table we had that has run ids and
LRT times on the same row, now it will have the split names (+chapter and section names) on the same row too, because as explained above,
the split name on the original file only shows once at the top and then just lists the times history without displaying the split name,
so we need that for each row
Just like we did for run ids and LRT times, we make the split name empty on the rows we don't want (there are a lot of unnecessary rows
in the original file since all the data has 1 info per row (for example split name, LRT time and run id will show on 3 different rows on
the original file, but since here we put everything in the same row, we only keep one row out of the 3 and the other 2 are useless,
so we delete them, it also makes the file a bit lighter since we now have much less rows to work with */

select info, cle, run_id2, lrt2, case when lrt2='' then '' else b.split_name end as split_name2, chapter, section, cle2, rta2
from splits_treatment3_runner a
left join split_name_info3_runner b on a.cle>=b.min and a.cle<=case when b.max is null then 10000000 else b.max end
order by cle;

drop table if exists splits_treatment5_runner;
create table splits_treatment5_runner as
select info, cle, run_id2, lrt2, split_name2, chapter, section, cle2,
round(hours*3600+minutes*60+seconds+milliseconds/10000000, 7) as lrt3,
rta2, round(hours_rta*3600+minutes_rta*60+seconds_rta+milliseconds_rta/10000000, 7) as rta3
from(
select *,

/* Converting the LRT times from character (wrong format) to numbers */

case when lrt2='' then 0 else cast(substr(lrt2, 1, 2) as integer) end as hours,
case when lrt2='' then 0 else cast(substr(lrt2, 4, 2) as integer) end as minutes,
case when lrt2='' then 0 else cast(substr(lrt2, 7, 2) as integer) end as seconds,
case when lrt2='' or length(lrt2)=8 then 0 else cast(substr(lrt2, 10, 7) as decimal) end as milliseconds,

case when rta2='' then 0 else cast(substr(rta2, 1, 2) as integer) end as hours_rta,
case when rta2='' then 0 else cast(substr(rta2, 4, 2) as integer) end as minutes_rta,
case when rta2='' then 0 else cast(substr(rta2, 7, 2) as integer) end as seconds_rta,
case when rta2='' or length(rta2)=8 then 0 else cast(substr(rta2, 10, 7) as decimal) end as milliseconds_rta
from splits_treatment4_runner

/* At this point we only keep the rows that have the information and we already have everything in the same row (run id,
lrt time and split name) so we can delete all the rest */

where split_name2<>'');

drop table if exists splits_treatment6_runner;
create table splits_treatment6_runner as
select *,

/* Also adding the LRT time with the same format as in LiveSplit, not used for calculations (for that we use the number format create in
the table above) but it's just easier to read */

case when lrt3-trunc(lrt3)=0 then (case when lrt3<10 then substr(lrt2, 8, 5)||'.000'
when lrt3<60 then substr(lrt2, 7, 6)||'.000'
when lrt3<600 then substr(lrt2, 5, 8)||'.000'
when lrt3<3600 then substr(lrt2, 4, 9)||'.000'
when lrt3<36000 then lrt2
else '' end)
else (case when lrt3<10 then substr(lrt2, 8, 5)
when lrt3<60 then substr(lrt2, 7, 6)
when lrt3<600 then substr(lrt2, 5, 8)
when lrt3<3600 then substr(lrt2, 4, 9)
when lrt3<36000 then lrt2
else '' end) end as lrt4,

case when rta3-trunc(rta3)=0 then (case when rta3<10 then substr(rta2, 8, 5)||'.000'
when rta3<60 then substr(rta2, 7, 6)||'.000'
when rta3<600 then substr(rta2, 5, 8)||'.000'
when rta3<3600 then substr(rta2, 4, 9)||'.000'
when rta3<36000 then rta2
else '' end)
else (case when rta3<10 then substr(rta2, 8, 5)
when rta3<60 then substr(rta2, 7, 6)
when rta3<600 then substr(rta2, 5, 8)
when rta3<3600 then substr(rta2, 4, 9)
when rta3<36000 then rta2
else '' end) end as rta4
from splits_treatment5_runner;

/* Treatment of part 1 (segments history) is done, now we need to work on part 2 (attempts history) with the run ids and the dates */

drop table if exists attempts_treatment_runner;
create table attempts_treatment_runner as
select *,

/* Retrieving the run id */
case when position ('started' in notepad_info)=17 then substr(substr(notepad_info, 1, 14), 14, 1)
when position ('started' in notepad_info)=18 then substr(substr(notepad_info, 1, 15), 14, 2)
when position ('started' in notepad_info)=19 then substr(substr(notepad_info, 1, 16), 14, 3)
when position ('started' in notepad_info)=20 then substr(substr(notepad_info, 1, 17), 14, 4)
when position ('started' in notepad_info)=21 then substr(substr(notepad_info, 1, 18), 14, 5)
else '' end as run_id,

/* Getting the dates */

substr(substr(notepad_info, position('started' in notepad_info), 19), 10) as date,
substr(substr(notepad_info, position('ended' in notepad_info), 17), 8) as date_end,
substr(substr(notepad_info, position('started' in notepad_info), 28), 21) as time_start,
substr(substr(notepad_info, position('ended' in notepad_info), 26), 19) as time_end,

/* Finished run or not for each run id */

case when substr(notepad_info, length(notepad_info)-1, 2)='">' then 1 else 0 end as finished_run,

/* Getting the LRT for each finished run */

case when substr(notepad_info, 1, 2)='<G' then substr(notepad_info, 11, 8) else '' end as lrt,
case when substr(notepad_info, 1, 2)='<R' then substr(notepad_info, 11, 8) else '' end as rta
from notepad_attempts_runner;

/* The finished runs will have their LRT time 2 rows after the run id, so need to put everything in the same row as done
earlier */

drop table if exists attempts_treatment2_runner_old;
create table attempts_treatment2_runner_old as
select run_id as id, date as date_started, finished_run, lead(rta, 1) over () as final_rta, lead(lrt, 2) over () as final_lrt,
date_end, time_start, time_end, runner_name
from attempts_treatment_runner;

drop table if exists attempts_treatment2_runner;
create table attempts_treatment2_runner as
select *
from attempts_treatment2_runner_old
where id <> '' and to_date(substr(date_started, 7, 4) || '-' || substr(date_started, 1, 2) || '-' || substr(date_started, 4, 2), 'YYYY-MM-DD') >= '2024-10-15' -- This date needs to be customizable

/* Getting the list of all finished runs and for each finished run, was it a PB when it was done or not? (which also means getting the LRT
PB at that time too) */

drop table if exists pb_history_runner_old;
create table pb_history_runner_old as
select finished_runs.id, finished_runs.final_lrt, min(pbs.final_lrt) as lrt_pb,
case when finished_runs.final_lrt=min(pbs.final_lrt) then 1 else 0 end as pb
from (select *
from attempts_treatment2_runner
where final_lrt<>'') finished_runs
join (select *
from attempts_treatment2_runner
where final_lrt<>'') pbs on cast(finished_runs.id as integer)>=cast(pbs.id as integer)
group by finished_runs.id, finished_runs.final_lrt
order by cast(finished_runs.id as integer);

/* We now join the attempts history (with dates and run id on the same row) with the finished runs information (was it a PB, etc.)
to have everything in the same table.
As earlier, only keeping the good rows and deleting the rest (since we put everything in the same row, a lot of rows are now useless.
Treatment of part2 is now done */

drop table if exists attempts_treatment3_old_runner;
create table attempts_treatment3_old_runner as
select cast(a.id as integer) as id, finished_run, a.final_lrt, pb, final_rta,
case when final_rta='' or final_rta is null then 0 else
cast(substr(final_rta, 1, 2) as integer)*3600+cast(substr(final_rta, 4, 2) as integer)*60+
cast(substr(final_rta, 7, 2) as integer) end as rta_number,
to_date(substr(date_started, 7, 4)||'-'||substr(date_started, 1, 2)||'-'||substr(date_started, 4, 2), 'YYYY-MM-DD') as
date_started_livesplit,
to_date(substr(date_end, 7, 4)||'-'||substr(date_end, 1, 2)||'-'||substr(date_end, 4, 2), 'YYYY-MM-DD') as
date_end_livesplit, time_start as time_start_livesplit, time_end as time_end_livesplit,
cast(substr(time_start, 1, 2) as integer)*3600+cast(substr(time_start, 4, 2) as integer)*60+
cast(substr(time_start, 7, 2) as integer) as time_start_number,
cast(substr(time_end, 1, 2) as integer)*3600+cast(substr(time_end, 4, 2) as integer)*60+
cast(substr(time_end, 7, 2) as integer) as time_end_number,
case when date_started<>date_end then 86400+cast(substr(time_end, 1, 2) as integer)*3600+cast(substr(time_end, 4, 2) as integer)*60+
cast(substr(time_end, 7, 2) as integer)-(cast(substr(time_start, 1, 2) as integer)*3600+cast(substr(time_start, 4, 2) as integer)*60+
cast(substr(time_start, 7, 2) as integer)) else
cast(substr(time_end, 1, 2) as integer)*3600+cast(substr(time_end, 4, 2) as integer)*60+
cast(substr(time_end, 7, 2) as integer)-(cast(substr(time_start, 1, 2) as integer)*3600+cast(substr(time_start, 4, 2) as integer)*60+
cast(substr(time_start, 7, 2) as integer)) end as playtime, 'runner' as runner_name
from attempts_treatment2_runner a
left join pb_history_runner_old b on a.id=b.id
where a.id<>'';

drop table if exists attempts_treatment3_runner;
create table attempts_treatment3_runner as
select a.*,
case when utc>0 and cast(substr(time_start_livesplit, 1, 2) as numeric)<utc then date_started_livesplit-1 when utc<0 and cast(substr(time_start_livesplit, 1, 2) as numeric)>=24+utc then date_started_livesplit+1
else date_started_livesplit end as date_started,
case when utc>0 and cast(substr(time_start_livesplit, 1, 2) as numeric)<utc then cast(substr(time_start_livesplit, 1, 2)as numeric)+24-utc||substr(time_start_livesplit, 3, 6)
when utc>0 and cast(substr(time_start_livesplit, 1, 2) as numeric)<10+utc then '0'||cast(substr(time_start_livesplit, 1, 2)as numeric)-utc||substr(time_start_livesplit, 3, 6)
when utc>0 then cast(substr(time_start_livesplit, 1, 2)as numeric)-utc||substr(time_start_livesplit, 3, 6)
when utc<0 and cast(substr(time_start_livesplit, 1, 2) as numeric)>=24+utc
then '0'||cast(substr(time_start_livesplit, 1, 2)as numeric)-24-utc||substr(time_start_livesplit, 3, 6)
when utc<0 and cast(substr(time_start_livesplit, 1, 2) as numeric)<10+utc
then '0'||cast(substr(time_start_livesplit, 1, 2)as numeric)-utc||substr(time_start_livesplit, 3, 6)
when utc<0 then cast(substr(time_start_livesplit, 1, 2)as numeric)-utc||substr(time_start_livesplit, 3, 6) else time_start_livesplit end as time_start,
case when utc>0 and cast(substr(time_end_livesplit, 1, 2) as numeric)<utc then date_end_livesplit-1 when utc<0 and cast(substr(time_end_livesplit, 1, 2) as numeric)>=24+utc then date_end_livesplit+1 else
date_end_livesplit end as date_end,
case when utc>0 and cast(substr(time_end_livesplit, 1, 2) as numeric)<utc then cast(substr(time_end_livesplit, 1, 2)as numeric)+24-utc||substr(time_end_livesplit, 3, 6)
when utc>0 and cast(substr(time_end_livesplit, 1, 2) as numeric)<10+utc then '0'||cast(substr(time_end_livesplit, 1, 2)as numeric)-utc||substr(time_end_livesplit, 3, 6)
when utc>0 then cast(substr(time_end_livesplit, 1, 2)as numeric)-utc||substr(time_end_livesplit, 3, 6)
when utc<0 and cast(substr(time_end_livesplit, 1, 2) as numeric)>=24+utc
then '0'||cast(substr(time_end_livesplit, 1, 2)as numeric)-24-utc||substr(time_end_livesplit, 3, 6)
when utc<0 and cast(substr(time_end_livesplit, 1, 2) as numeric)<10+utc
then '0'||cast(substr(time_end_livesplit, 1, 2)as numeric)-utc||substr(time_end_livesplit, 3, 6)
when utc<0 then cast(substr(time_end_livesplit, 1, 2)as numeric)-utc||substr(time_end_livesplit, 3, 6) else time_end_livesplit end as time_end
from attempts_treatment3_old_runner a
left join time_zone_runners2 b on a.runner_name=b.runner_name;

/* Getting the list of all PBs, also converting the PBs into number format, can be used for calculations (or graphs, etc.) */

drop table if exists pb_history_runner;
create table pb_history_runner as
select a.*, cast(substr(lrt_pb, 1, 2) as integer)*3600+cast(substr(lrt_pb, 4, 2) as integer)*60+
cast(substr(lrt_pb, 7, 2) as integer) as pb_lrt, date_started-coalesce(lag(date_started) over(order by cast(a.id as integer)), date_started)
as days_it_took, cast(a.id as integer)-coalesce(lag(cast(a.id as integer)) over(order by cast(a.id as integer)),0) attempts_it_took,
total_playtime-coalesce(lag(total_playtime) over(order by cast(a.id as integer)), 0) total_playtime_it_took,
days_attempts-coalesce(lag(days_attempts) over(order by cast (a.id as integer)), 0) as days_of_attempts_it_took
from(
select finished_runs.id, finished_runs.final_lrt, finished_runs.date_started, min(pbs.final_lrt) as lrt_pb,
case when finished_runs.final_lrt=min(pbs.final_lrt) then 1 else 0 end as pb
from (select *
from attempts_treatment3_runner
where final_lrt<>''
and date_started>='2024-10-14') finished_runs
join (select *
from attempts_treatment3_runner
where final_lrt<>''
and date_started>='2024-10-14') pbs on cast(finished_runs.id as integer)>=cast(pbs.id as integer)
group by finished_runs.id, finished_runs.final_lrt, finished_runs.date_started
order by cast(finished_runs.id as integer)) a
left join (select a.id, a.playtime, sum(b.playtime) as total_playtime
from attempts_treatment3_runner a
left join attempts_treatment3_runner b on a.id>=b.id
group by a.id, a.playtime
order by a.id) b on a.id=b.id
left join (select a.id, count(distinct b.date_started)-1 as days_attempts
from attempts_treatment3_runner a
left join attempts_treatment3_runner b on a.id>=b.id
group by a.id
order by a.id) c on a.id=c.id
where pb=1;

/* Final table that is going to be used to get the actual data (chapter golds, etc.), we combine the 2 cleaned tables after
treatments (splits history and attempts history, so part 1 and 2)
Also converting the dates of the runs from part2 into date format */

drop table if exists splits_cleaned_runner_old;
create table splits_cleaned_runner_old as
select run_id2 as id, split_name2 as split, chapter, section, lrt3 as lrt_number, lrt4 as lrt_split,
date_started_livesplit, finished_run, final_lrt, pb, cle2, final_rta, date_end_livesplit, time_start_livesplit, time_end_livesplit, playtime,
date_started, time_start, date_end,
time_end, rta3 as rta_numeric, rta4 as rta_split
from splits_treatment6_runner a
left join attempts_treatment3_runner b on a.run_id2=b.id;

drop table if exists rta_cumulative_runner;
create table rta_cumulative_runner as
select a.id, a.cle2, sum(b.rta_numeric) as cumulative_rta
from splits_cleaned_runner_old a
left join (select distinct id, cle2, rta_numeric from splits_cleaned_runner_old) b on a.cle2>=b.cle2 and a.id=b.id
group by 1, 2
order by 1, 2;

drop table if exists splits_cleaned_runner_old2;
create table splits_cleaned_runner_old2 as
select a.*, cumulative_rta, lag(cumulative_rta) over(partition by a.id order by a.cle2) as lag_rta, cast(substr(time_start, 1, 2) as numeric)*3600
+cast(substr(time_start, 4, 2) as numeric)*60+cast(substr(time_start, 7, 2) as numeric) as time_start_numeric,
cast(substr(time_end, 1, 2) as numeric)*3600
+cast(substr(time_end, 4, 2) as numeric)*60+cast(substr(time_end, 7, 2) as numeric) as time_end_numeric, 'runner' as runner_name
from splits_cleaned_runner_old a
left join rta_cumulative_runner b on a.id=b.id and a.cle2=b.cle2;

drop table if exists splits_cleaned_runner;
create table splits_cleaned_runner as
select id, default_split as split, chapter, section, lrt_number, lrt_split, date_started_livesplit, finished_run, final_lrt, pb, cle2,
final_rta, date_end_livesplit, time_start_livesplit, time_end_livesplit, playtime, date_started, time_start, date_end, time_end,
rta_numeric, rta_split, cumulative_rta, lag_rta, time_start_numeric, time_end_numeric, time_start_numeric2, time_end_numeric2,
case when cle2=1 then time_start else
case when floor(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end)<10
then '0'||floor(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end)
else ''||floor(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end) end
||':'||
case when floor(60*(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end
- floor(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end)))<10
then '0'||floor(60*(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end
- floor(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end)))
else ''||floor(60*(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end
- floor(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end))) end
||':'||
case when floor(60*(60*(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end
- floor(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end))-
floor(60*(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end
- floor(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end)))))<10
then '0'||floor(60*(60*(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end
- floor(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end))-
floor(60*(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end
- floor(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end)))))
else ''||floor(60*(60*(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end
- floor(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end))-
floor(60*(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end
- floor(case when time_start_numeric2/3600>=24 then time_start_numeric2/3600-24 else time_start_numeric2/3600 end))))) end end as time_start_numeric3,
case when cle2=123 then time_end else
case when floor(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end)<10
then '0'||floor(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end)
else ''||floor(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end) end
||':'||
case when floor(60*(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end
- floor(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end)))<10
then '0'||floor(60*(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end
- floor(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end)))
else ''||floor(60*(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end
- floor(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end))) end
||':'||
case when floor(60*(60*(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end
- floor(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end))-
floor(60*(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end
- floor(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end)))))<10
then '0'||floor(60*(60*(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end
- floor(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end))-
floor(60*(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end
- floor(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end)))))
else ''||floor(60*(60*(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end
- floor(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end))-
floor(60*(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end
- floor(case when time_end_numeric2/3600>=24 then time_end_numeric2/3600-24 else time_end_numeric2/3600 end))))) end end as time_end_numeric3
from(
select a.*, b.split as default_split, case when a.cle2=1 then time_start_numeric when time_start_numeric<86400 and time_start_numeric+lag_rta>=86400 then time_start_numeric+lag_rta-86400
else time_start_numeric+lag_rta end as time_start_numeric2, case when time_start_numeric<86400 and time_start_numeric+cumulative_rta>=86400 then time_start_numeric+cumulative_rta-86400
else time_start_numeric+cumulative_rta end as time_end_numeric2
from splits_cleaned_runner_old2 a
left join default_split_names_runner b on a.cle2=b.cle2);

/*drop table if exists splits_treatment;
drop table if exists splits_treatment2;
drop table if exists splits_treatment3;
drop table if exists splits_treatment4;
drop table if exists splits_treatment5;
drop table if exists splits_treatment6;
drop table if exists attempts_treatment;
drop table if exists attempts_treatment2;
drop table if exists attempts_treatment3;
drop table if exists split_name_info;
drop table if exists split_name_info2;
drop table if exists split_name_info3;
drop table if exists pb_history;*/

/* Chapter golds part
Here we define for each chapter, how many splits we have, so we know if a run has finished a chapter or not (obviously to count the chapter
golds, we need to count only the chapter that are finished, because a chapter that only did the first split and reset is gonna be faster
than a full chapter */

drop table if exists chapter_splits_runner;
create table chapter_splits_runner (chapter varchar(255), number_of_splits integer);

insert into chapter_splits_runner (chapter, number_of_splits)
values
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

/* Getting the chapter golds and chapter averages */

drop table if exists chapter_golds_runner;
create table chapter_golds_runner as
select ch_golds.*, avg_chapter_time, cast(median_chapter_time as numeric) as median_chapter_time
from (
select aa.*, bb.id, date_started, finished_run, final_lrt, pb
from(
select chapter, min(chapter_time) as chapter_gold
from(
select a.*
from(
select chapter, id, sum(lrt_number) as chapter_time, count(*) as number_of_splits
from splits_cleaned_runner
group by chapter, id
order by 1) a
join chapter_splits_runner b on a.chapter=b.chapter and a.number_of_splits=b.number_of_splits)
group by 1
order by 1) aa
left join (
select *
from(
select a.*
from(
select chapter, id, date_started, finished_run, final_lrt, pb, sum(lrt_number) as chapter_time, count(*) as number_of_splits
from splits_cleaned_runner
group by chapter, id, date_started, finished_run, final_lrt, pb
order by 1) a
join chapter_splits_runner b on a.chapter=b.chapter and a.number_of_splits=b.number_of_splits)) bb
on aa.chapter_gold=bb.chapter_time) ch_golds
left join (select chapter, avg(chapter_time) as avg_chapter_time
from(
select a.*
from(
select chapter, id, date_started, finished_run, final_lrt, pb, sum(lrt_number) as chapter_time, count(*) as number_of_splits
from splits_cleaned_runner
group by chapter, id, date_started, finished_run, final_lrt, pb) a
join chapter_splits_runner b on a.chapter=b.chapter and a.number_of_splits=b.number_of_splits)
/*where id>=10500*/
group by 1
order by 1) ch_avg on ch_golds.chapter=ch_avg.chapter
left join (select chapter, percentile_cont(0.5) within group (order by chapter_time) as median_chapter_time
from(
select a.*
from(
select chapter, id, date_started, finished_run, final_lrt, pb, sum(lrt_number) as chapter_time, count(*) as number_of_splits
from splits_cleaned_runner
group by chapter, id, date_started, finished_run, final_lrt, pb) a
join chapter_splits_runner b on a.chapter=b.chapter and a.number_of_splits=b.number_of_splits)
/*where id>=10500*/
group by 1
order by 1) ch_med on ch_golds.chapter=ch_med.chapter;

/* Putting the chapter golds and averages in LiveSplit format (previously numbers) */

drop table if exists chapter_golds2_runner;
create table chapter_golds2_runner as
select *, case when chapter_gold<60 then (case when trunc(chapter_gold-trunc(chapter_gold), 3) =0 then
to_char(trunc(chapter_gold, 3) % 60, 'FM00.999')||'000'
when trunc(chapter_gold-trunc(chapter_gold), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then to_char(trunc(chapter_gold, 3) % 60, 'FM00.999')||'00'
when trunc(chapter_gold-trunc(chapter_gold), 3) in (select numb from decimals_table_runner)
then to_char(trunc(chapter_gold, 3) % 60, 'FM00.999')||'0'
else
to_char(trunc(chapter_gold, 3) % 60, 'FM00.999') end)
else (case when trunc(chapter_gold-trunc(chapter_gold), 3) =0
then floor(chapter_gold / 60) || ':' ||
to_char(trunc(chapter_gold, 3) % 60, 'FM00.999')||'000'
when trunc(chapter_gold-trunc(chapter_gold), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then floor(chapter_gold / 60) || ':' ||
to_char(trunc(chapter_gold, 3) % 60, 'FM00.999')||'00'
when trunc(chapter_gold-trunc(chapter_gold), 3) in (select numb from decimals_table_runner)
then floor(chapter_gold / 60) || ':' ||
to_char(trunc(chapter_gold, 3) % 60, 'FM00.999')||'0'
else
floor(chapter_gold / 60) || ':' ||
to_char(trunc(chapter_gold, 3) % 60, 'FM00.999') end) end AS chapter_gold2,
case when avg_chapter_time<60 then (case when trunc(avg_chapter_time-trunc(avg_chapter_time), 3) =0 then
to_char(trunc(avg_chapter_time, 3) % 60, 'FM00.999')||'000'
when trunc(avg_chapter_time-trunc(avg_chapter_time), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then to_char(trunc(avg_chapter_time, 3) % 60, 'FM00.999')||'00'
when trunc(avg_chapter_time-trunc(avg_chapter_time), 3) in (select numb from decimals_table_runner)
then to_char(trunc(avg_chapter_time, 3) % 60, 'FM00.999')||'0'
else
to_char(trunc(avg_chapter_time, 3) % 60, 'FM00.999') end)
else (case when trunc(avg_chapter_time-trunc(avg_chapter_time), 3) =0
then floor(avg_chapter_time / 60) || ':' ||
to_char(trunc(avg_chapter_time, 3) % 60, 'FM00.999')||'000'
when trunc(avg_chapter_time-trunc(avg_chapter_time), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then floor(avg_chapter_time / 60) || ':' ||
to_char(trunc(avg_chapter_time, 3) % 60, 'FM00.999')||'00'
when trunc(avg_chapter_time-trunc(avg_chapter_time), 3) in (select numb from decimals_table_runner)
then floor(avg_chapter_time / 60) || ':' ||
to_char(trunc(avg_chapter_time, 3) % 60, 'FM00.999')||'0'
else
floor(avg_chapter_time / 60) || ':' ||
to_char(trunc(avg_chapter_time, 3) % 60, 'FM00.999') end) end AS avg_chapter_time2,
case when median_chapter_time<60 then (case when trunc(median_chapter_time-trunc(median_chapter_time), 3) =0 then
to_char(trunc(median_chapter_time, 3) % 60, 'FM00.999')||'000'
when trunc(median_chapter_time-trunc(median_chapter_time), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then to_char(trunc(median_chapter_time, 3) % 60, 'FM00.999')||'00'
when trunc(median_chapter_time-trunc(median_chapter_time), 3) in (select numb from decimals_table_runner)
then to_char(trunc(median_chapter_time, 3) % 60, 'FM00.999')||'0'
else
to_char(trunc(median_chapter_time, 3) % 60, 'FM00.999') end)
else (case when trunc(median_chapter_time-trunc(median_chapter_time), 3) =0
then floor(median_chapter_time / 60) || ':' ||
to_char(trunc(median_chapter_time, 3) % 60, 'FM00.999')||'000'
when trunc(median_chapter_time-trunc(median_chapter_time), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then floor(median_chapter_time / 60) || ':' ||
to_char(trunc(median_chapter_time, 3) % 60, 'FM00.999')||'00'
when trunc(median_chapter_time-trunc(median_chapter_time), 3) in (select numb from decimals_table_runner)
then floor(median_chapter_time / 60) || ':' ||
to_char(trunc(median_chapter_time, 3) % 60, 'FM00.999')||'0'
else
floor(median_chapter_time / 60) || ':' ||
to_char(trunc(median_chapter_time, 3) % 60, 'FM00.999') end) end AS median_chapter_time2
from chapter_golds_runner;

drop table if exists chapter_golds3_runner;
create table chapter_golds3_runner as
select chapter, id, date_started, final_lrt, pb, chapter_gold, chapter_gold2,
case when trunc(cumulative_chapter_gold-trunc(cumulative_chapter_gold), 3)=0 then (case when cumulative_chapter_gold>=3600 then
floor(cumulative_chapter_gold / 3600) || ':' || case when floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60)<10 then '0' else '' end ||
	  floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'000'
else floor(cumulative_chapter_gold / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'000' end)
when trunc(cumulative_chapter_gold-trunc(cumulative_chapter_gold), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then (case when cumulative_chapter_gold>=3600 then
floor(cumulative_chapter_gold / 3600) || ':' || case when floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60)<10 then '0' else '' end ||
	  floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'00'
else floor(cumulative_chapter_gold / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'00' end)
when trunc(cumulative_chapter_gold-trunc(cumulative_chapter_gold), 3) in (select numb from decimals_table_runner)
then (case when cumulative_chapter_gold>=3600 then
floor(cumulative_chapter_gold / 3600) || ':' || case when floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60)<10 then '0' else '' end ||
          floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'0'
else floor(cumulative_chapter_gold / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'0' end)
else (case when cumulative_chapter_gold>=3600 then
floor(cumulative_chapter_gold / 3600) || ':' || case when floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60)<10 then '0' else '' end ||
	  floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')
else floor(cumulative_chapter_gold / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999') end) end as cumulative_chapter_gold, cumulative_chapter_gold as cumulative_chapter_gold_num, avg_chapter_time,
median_chapter_time, avg_chapter_time2, median_chapter_time2
from(
select a.chapter, a.chapter_gold, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.avg_chapter_time, a.chapter_gold2,
a.median_chapter_time, a.avg_chapter_time2, a.median_chapter_time2, sum(b.chapter_gold) as cumulative_chapter_gold
from chapter_golds2_runner a
left join (select distinct chapter, chapter_gold from chapter_golds2_runner) b on a.chapter>=b.chapter
group by a.chapter, a.chapter_gold, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.avg_chapter_time, a.chapter_gold2,
a.median_chapter_time, a.avg_chapter_time2, a.median_chapter_time2) a
order by chapter;

/*drop table if exists chapter_golds;*/

/* Chapter times of all the attempts */

drop table if exists chapter_history_runner;
create table chapter_history_runner as
select chapter, id, date_started, finished_run, final_lrt, pb, sum(chapter_time) as chapter_time
from(
select a.*
from(
select chapter, id, date_started, finished_run, final_lrt, pb, sum(lrt_number) as chapter_time, count(*) as number_of_splits
from splits_cleaned_runner
group by chapter, id, date_started, finished_run, final_lrt, pb) a
join chapter_splits_runner b on a.chapter=b.chapter and a.number_of_splits=b.number_of_splits)
group by 1, 2, date_started, finished_run, final_lrt, pb
order by 1;

/* Putting the chapter golds in LiveSplit format (previously numbers) */

drop table if exists chapter_history2_runner;
create table chapter_history2_runner as
select *, case when chapter_time<60 then (case when trunc(chapter_time-trunc(chapter_time), 3) =0 then
to_char(trunc(chapter_time, 3) % 60, 'FM00.999')||'000'
when trunc(chapter_time-trunc(chapter_time), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then to_char(trunc(chapter_time, 3) % 60, 'FM00.999')||'00'
when trunc(chapter_time-trunc(chapter_time), 3) in (select numb from decimals_table_runner)
then to_char(trunc(chapter_time, 3) % 60, 'FM00.999')||'0'
else
to_char(trunc(chapter_time, 3) % 60, 'FM00.999') end)
else (case when trunc(chapter_time-trunc(chapter_time), 3) =0
then floor(chapter_time / 60) || ':' ||
to_char(trunc(chapter_time, 3) % 60, 'FM00.999')||'000'
when trunc(chapter_time-trunc(chapter_time), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then floor(chapter_time / 60) || ':' ||
to_char(trunc(chapter_time, 3) % 60, 'FM00.999')||'00'
when trunc(chapter_time-trunc(chapter_time), 3) in (select numb from decimals_table_runner)
then floor(chapter_time / 60) || ':' ||
to_char(trunc(chapter_time, 3) % 60, 'FM00.999')||'0'
else
floor(chapter_time / 60) || ':' ||
to_char(trunc(chapter_time, 3) % 60, 'FM00.999') end) end AS chapter_time2, rank() over (partition by chapter order by chapter_time) as rank_chapter
from chapter_history_runner
order by chapter, chapter_time;

drop table if exists chapter_history3_runner;
create table chapter_history3_runner as
select chapter, id, date_started, finished_run, pb, chapter_time, chapter_time2, case when chapter_time<=min or min is null then 1 else 0
end as golded_chapter,
case when min<60 then (case when trunc(min-trunc(min), 3) =0 then
to_char(trunc(min, 3) % 60, 'FM00.999')||'000'
when trunc(min-trunc(min), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then to_char(trunc(min, 3) % 60, 'FM00.999')||'00'
when trunc(min-trunc(min), 3) in (select numb from decimals_table_runner)
then to_char(trunc(min, 3) % 60, 'FM00.999')||'0'
else
to_char(trunc(min, 3) % 60, 'FM00.999') end)
else (case when trunc(min-trunc(min), 3) =0
then floor(min / 60) || ':' ||
to_char(trunc(min, 3) % 60, 'FM00.999')||'000'
when trunc(min-trunc(min), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then floor(min / 60) || ':' ||
to_char(trunc(min, 3) % 60, 'FM00.999')||'00'
when trunc(min-trunc(min), 3) in (select numb from decimals_table_runner)
then floor(min / 60) || ':' ||
to_char(trunc(min, 3) % 60, 'FM00.999')||'0'
else
floor(min / 60) || ':' ||
to_char(trunc(min, 3) % 60, 'FM00.999') end) end as chapter_gold_at_that_time, rank_chapter, chapter_rank_at_that_time, finished_chapters, finished_chapters_at_that_time
from (select a.rank_chapter, a.chapter, a.id, a.date_started, a.finished_run, a.pb, a.chapter_time, a.chapter_time2, min(b.chapter_time) as min,
min(b.chapter_time2) as min2, finished_chapters, chapter_rank_at_that_time, finished_chapters_at_that_time
from chapter_history2_runner a
left join chapter_history2_runner b on a.chapter=b.chapter and a.id>b.id
left join (select chapter, count(*) as finished_chapters from chapter_history2_runner group by 1) c on a.chapter=c.chapter
left join (select *
from (select a.*, b.chapter_time as chapter_time3, b.id as id2,
rank() over (partition by a.chapter, a.id order by b.chapter_time) as chapter_rank_at_that_time
from chapter_history2_runner a
join chapter_history2_runner b on a.chapter=b.chapter and a.id>=b.id) a
where id=id2) d on a.chapter=d.chapter and a.id=d.id

left join (

select a.chapter, a.id, count(*) as finished_chapters_at_that_time
from chapter_history2_runner a
join chapter_history2_runner b on a.chapter=b.chapter and a.id>=b.id
group by 1, 2) e on a.chapter=e.chapter and a.id=e.id
group by finished_chapters_at_that_time, chapter_rank_at_that_time, finished_chapters, a.rank_chapter, a.chapter, a.id, a.date_started, a.finished_run, a.pb, a.chapter_time, a.chapter_time2) a;

/*drop table if exists chapter_history;
drop table if exists chapter_splits_runner;*/

/* Section golds, same as chapters, we count the number of splits per section to only count finished sections */

drop table if exists section_splits_runner;
create table section_splits_runner (section varchar(255), number_of_splits integer, sort integer);

insert into section_splits_runner (section, number_of_splits, sort)
values
('Village', 32, 1),
('Castle', 50, 2),
('Island', 41, 3);

/* Sections golds and averages */

drop table if exists section_golds_runner;
create table section_golds_runner as
select section_golds.*, section_avg, cast(section_median as numeric) as section_median
from(
select aa.*, bb.id, date_started, finished_run, final_lrt, pb
from (
select section, min(section_time) as section_gold
from(
select a.*
from(
select section, id, sum(lrt_number) as section_time, count(*) as number_of_splits
from splits_cleaned_runner
group by section, id
order by 1) a
join section_splits_runner b on a.section=b.section and a.number_of_splits=b.number_of_splits)
group by 1) aa
left join (
select *
from(
select a.*
from(
select section, id, date_started, finished_run, final_lrt, pb, sum(lrt_number) as section_time, count(*) as number_of_splits
from splits_cleaned_runner
group by section, id, date_started, finished_run, final_lrt, pb
order by 1) a
join section_splits_runner b on a.section=b.section and a.number_of_splits=b.number_of_splits)) bb
on aa.section_gold=bb.section_time
order by case when aa.section='Village' then 1 when aa.section='Castle' then 2 else 3 end) section_golds
left join (select section, avg(section_time) as section_avg
from(
select a.*
from(
select section, id, date_started, finished_run, final_lrt, pb, sum(lrt_number) as section_time, count(*) as number_of_splits
from splits_cleaned_runner
group by section, id, date_started, finished_run, final_lrt, pb) a
join section_splits_runner b on a.section=b.section and a.number_of_splits=b.number_of_splits)
--where id>=10500
group by 1
order by 1) section_avg on section_golds.section=section_avg.section
left join (select section, percentile_cont(0.5) within group(order by section_time) as section_median
from(
select a.*
from(
select section, id, date_started, finished_run, final_lrt, pb, sum(lrt_number) as section_time, count(*) as number_of_splits
from splits_cleaned_runner
group by section, id, date_started, finished_run, final_lrt, pb) a
join section_splits_runner b on a.section=b.section and a.number_of_splits=b.number_of_splits)
--where id>=10500
group by 1
order by 1) section_med on section_golds.section=section_med.section;

/* Putting the section golds and averages in LiveSplit format (previously numbers) */

drop table if exists section_golds2_runner;
create table section_golds2_runner as
select *, floor(section_gold / 60) || ':' ||
case when length(to_char(trunc(section_gold, 3) % 60, 'FM00.999'))=3
then to_char(trunc(section_gold, 3) % 60, 'FM00.999')||'000'
when length(to_char(trunc(section_gold, 3) % 60, 'FM00.999'))=4
then to_char(trunc(section_gold, 3) % 60, 'FM00.999')||'00'
when length(to_char(trunc(section_gold, 3) % 60, 'FM00.999'))=5
then to_char(trunc(section_gold, 3) % 60, 'FM00.999')||'0' else
to_char(trunc(section_gold, 3) % 60, 'FM00.999') end AS section_gold2,
floor(section_avg / 60) || ':' ||
case when length(to_char(trunc(section_avg, 3) % 60, 'FM00.999'))=3
then to_char(trunc(section_avg, 3) % 60, 'FM00.999')||'000'
when length(to_char(trunc(section_avg, 3) % 60, 'FM00.999'))=4
then to_char(trunc(section_avg, 3) % 60, 'FM00.999')||'00'
when length(to_char(trunc(section_avg, 3) % 60, 'FM00.999'))=5
then to_char(trunc(section_avg, 3) % 60, 'FM00.999')||'0' else
to_char(trunc(section_avg, 3) % 60, 'FM00.999') end AS section_avg2,
floor(section_median / 60) || ':' ||
case when length(to_char(trunc(section_median, 3) % 60, 'FM00.999'))=3
then to_char(trunc(section_median, 3) % 60, 'FM00.999')||'000'
when length(to_char(trunc(section_median, 3) % 60, 'FM00.999'))=4
then to_char(trunc(section_median, 3) % 60, 'FM00.999')||'00'
when length(to_char(trunc(section_median, 3) % 60, 'FM00.999'))=5
then to_char(trunc(section_median, 3) % 60, 'FM00.999')||'0' else
to_char(trunc(section_median, 3) % 60, 'FM00.999') end AS section_median2
from section_golds_runner;

drop table if exists section_golds3_runner;
create table section_golds3_runner as
select section, id, date_started, final_lrt, pb, section_gold, section_gold2,
case when trunc(cumulative_chapter_gold-trunc(cumulative_chapter_gold), 3)=0 then (case when cumulative_chapter_gold>=3600 then
floor(cumulative_chapter_gold / 3600) || ':' || case when floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60)<10 then '0' else '' end ||
	  floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'000'
else floor(cumulative_chapter_gold / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'000' end)
when trunc(cumulative_chapter_gold-trunc(cumulative_chapter_gold), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then (case when cumulative_chapter_gold>=3600 then
floor(cumulative_chapter_gold / 3600) || ':' || case when floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60)<10 then '0' else '' end ||
	  floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'00'
else floor(cumulative_chapter_gold / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'00' end)
when trunc(cumulative_chapter_gold-trunc(cumulative_chapter_gold), 3) in (select numb from decimals_table_runner)
then (case when cumulative_chapter_gold>=3600 then
floor(cumulative_chapter_gold / 3600) || ':' || case when floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60)<10 then '0' else '' end ||
          floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'0'
else floor(cumulative_chapter_gold / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'0' end)
else (case when cumulative_chapter_gold>=3600 then
floor(cumulative_chapter_gold / 3600) || ':' || case when floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60)<10 then '0' else '' end ||
	  floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')
else floor(cumulative_chapter_gold / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999') end) end as cumulative_section_gold, section_avg, section_median,
section_avg2, section_median2
from(
select a.section, a.section_gold, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.section_avg, a.section_gold2,
a.section_avg2, a.section_median, a.section_median2, sum(b.section_gold) as cumulative_chapter_gold
from section_golds2_runner a
left join (select distinct section, section_gold from section_golds2_runner) b on case when a.section='Village' then 1 when a.section='Castle' then 2 else 3 end>=
	case when b.section='Village' then 1 when b.section='Castle' then 2 else 3 end
group by a.section, a.section_gold, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.section_avg, a.section_gold2,
a.section_avg2, a.section_median, a.section_median2) a
order by case when section='Village' then 1 when section='Castle' then 2 else 3 end;

/*drop table if exists section_golds;*/

/* Section times of all the attempts */

drop table if exists section_history_runner;
create table section_history_runner as
select section, id, date_started, finished_run, final_lrt, pb, sum(section_time) as section_time
from(
select a.*
from(
select section, id, date_started, finished_run, final_lrt, pb, sum(lrt_number) as section_time, count(*) as number_of_splits
from splits_cleaned_runner
group by section, id, date_started, finished_run, final_lrt, pb) a
join section_splits_runner b on a.section=b.section and a.number_of_splits=b.number_of_splits)
group by 1, 2, date_started, finished_run, final_lrt, pb
order by 1;

/* Putting the section golds in LiveSplit format (previously numbers) */

drop table if exists section_history2_runner;
create table section_history2_runner as
select *, case when trunc(section_time-trunc(section_time), 3) =0
then floor(section_time / 60) || ':' ||
to_char(trunc(section_time, 3) % 60, 'FM00.999')||'000'
when trunc(section_time-trunc(section_time), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then floor(section_time / 60) || ':' ||
to_char(trunc(section_time, 3) % 60, 'FM00.999')||'00'
when trunc(section_time-trunc(section_time), 3) in (select numb from decimals_table_runner)
then floor(section_time / 60) || ':' ||
to_char(trunc(section_time, 3) % 60, 'FM00.999')||'0'
else
floor(section_time / 60) || ':' ||
to_char(trunc(section_time, 3) % 60, 'FM00.999') end AS section_time2, rank() over (partition by section order by section_time) as rank_section
from section_history_runner
order by case when section='Village' then 1 when section='Castle' then 2 else 3 end, section_time;

drop table if exists section_history3_runner;
create table section_history3_runner as
select section, id, date_started, finished_run, final_lrt, pb, section_time, section_time2, case when section_time<=min or min is null
then 1 else 0 end as golded_section,
floor(min / 60) || ':' ||
case when length(to_char(trunc(min, 3) % 60, 'FM00.999'))=3
then to_char(trunc(min, 3) % 60, 'FM00.999')||'000'
when length(to_char(trunc(min, 3) % 60, 'FM00.999'))=4
then to_char(trunc(min, 3) % 60, 'FM00.999')||'00'
when length(to_char(trunc(min, 3) % 60, 'FM00.999'))=5
then to_char(trunc(min, 3) % 60, 'FM00.999')||'0' else
to_char(trunc(min, 3) % 60, 'FM00.999') end AS section_gold_at_that_time, rank_section, section_rank_at_that_time, finished_sections, finished_sections_at_that_time
from (select a.section, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.section_time, a.section_time2, min(b.section_time) as min,
min(b.section_time2) as min2, a.rank_section, finished_sections, finished_sections_at_that_time, section_rank_at_that_time
from section_history2_runner a
left join section_history2_runner b on a.section=b.section and a.id>b.id
left join (select section, count(*) as finished_sections from section_history2_runner group by 1) c on a.section=c.section
left join (select *
from (select a.*, b.section_time as section_time3, b.id as id2,
rank() over (partition by a.section, a.id order by b.section_time) as section_rank_at_that_time
from section_history2_runner a
join section_history2_runner b on a.section=b.section and a.id>=b.id) a
where id=id2) d on a.section=d.section and a.id=d.id

left join (

select a.section, a.id, count(*) as finished_sections_at_that_time
from section_history2_runner a
join section_history2_runner b on a.section=b.section and a.id>=b.id
group by 1, 2) e on a.section=e.section and a.id=e.id
group by a.rank_section, finished_sections, finished_sections_at_that_time, section_rank_at_that_time, a.section, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.section_time, a.section_time2) a;

/*drop table if exists section_history;
drop table if exists section_splits_runner;*/

/* All golds */

drop table if exists doorsplits_golds_runner;
create table doorsplits_golds_runner as
select aa.*, bb.id, date_started, finished_run, final_lrt, pb,
case when trunc(gold-trunc(gold), 3)=0 then
(case when gold<10 then to_char(trunc(gold, 3) % 60, 'FM0.999')||'000'
when gold<60 then to_char(trunc(gold, 3) % 60, 'FM00.999')||'000'
else floor(gold / 60) || ':' || to_char(trunc(gold, 3) % 60, 'FM00.999')||'000' end)
when trunc(gold-trunc(gold), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then (case when gold<10 then to_char(trunc(gold, 3) % 60, 'FM0.999')||'00'
when gold<60 then to_char(trunc(gold, 3) % 60, 'FM00.999')||'00'
else floor(gold / 60) || ':' || to_char(trunc(gold, 3) % 60, 'FM00.999')||'00' end)
when trunc(gold-trunc(gold), 3) in (select numb from decimals_table_runner)
then (case when gold<10 then to_char(trunc(gold, 3) % 60, 'FM0.999')||'0'
when gold<60 then to_char(trunc(gold, 3) % 60, 'FM00.999')||'0'
else floor(gold / 60) || ':' || to_char(trunc(gold, 3) % 60, 'FM00.999')||'0' end)
else (case when gold<10 then to_char(trunc(gold, 3) % 60, 'FM0.999')
when gold<60 then to_char(trunc(gold, 3) % 60, 'FM00.999')
else floor(gold / 60) || ':' || to_char(trunc(gold, 3) % 60, 'FM00.999') end) end as gold2, cast(door_avg as numeric) as door_avg,
cast(door_median as numeric) as door_median
from (
select cle2, split, min(split_time) as gold
from(select split, id, cle2, sum(lrt_number) as split_time
from splits_cleaned_runner
group by split, id, cle2) a
group by split, cle2) aa
left join (select *
from(select split, id, cle2, date_started, finished_run, final_lrt, pb, sum(lrt_number) as split_time
from splits_cleaned_runner
group by split, id, cle2, date_started, finished_run, final_lrt, pb) a) bb on aa.gold=bb.split_time and aa.cle2=bb.cle2
left join (select cle2, avg(lrt_time) as door_avg
from(
select a.*
from(
select cle2, id, date_started, finished_run, final_lrt, pb, sum(lrt_number) as lrt_time
from splits_cleaned_runner
group by cle2, id, date_started, finished_run, final_lrt, pb) a)
--where id>=10500
group by 1
order by 1) door_avg on door_avg.cle2=aa.cle2
left join (select cle2, percentile_cont(0.5) within group(order by lrt_time) as door_median
from(
select a.*
from(
select cle2, id, date_started, finished_run, final_lrt, pb, sum(lrt_number) as lrt_time
from splits_cleaned_runner
group by cle2, id, date_started, finished_run, final_lrt, pb) a)
--where id>=10500
group by 1
order by 1) door_med on door_med.cle2=aa.cle2
order by cle2;

drop table if exists doorsplits_golds2_runner;
create table doorsplits_golds2_runner as
select cle2, id, date_started, final_lrt, pb, gold, gold2, door_avg, door_median,
case when trunc(cumulative_chapter_gold-trunc(cumulative_chapter_gold), 3)=0 then (case when cumulative_chapter_gold>=3600 then
floor(cumulative_chapter_gold / 3600) || ':' || case when floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60)<10 then '0' else '' end ||
	  floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'000'
else floor(cumulative_chapter_gold / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'000' end)
when trunc(cumulative_chapter_gold-trunc(cumulative_chapter_gold), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then (case when cumulative_chapter_gold>=3600 then
floor(cumulative_chapter_gold / 3600) || ':' || case when floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60)<10 then '0' else '' end ||
	  floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'00'
else floor(cumulative_chapter_gold / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'00' end)
when trunc(cumulative_chapter_gold-trunc(cumulative_chapter_gold), 3) in (select numb from decimals_table_runner)
then (case when cumulative_chapter_gold>=3600 then
floor(cumulative_chapter_gold / 3600) || ':' || case when floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60)<10 then '0' else '' end ||
          floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'0'
else floor(cumulative_chapter_gold / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')||'0' end)
else (case when cumulative_chapter_gold>=3600 then
floor(cumulative_chapter_gold / 3600) || ':' || case when floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60)<10 then '0' else '' end ||
	  floor(cumulative_chapter_gold / 60)-(floor(cumulative_chapter_gold/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999')
else floor(cumulative_chapter_gold / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold, 3) % 60, 'FM00.999') end) end as cumulative_door_gold, cumulative_chapter_gold as cumulative_door_gold_num,
case when trunc(door_avg-trunc(door_avg), 3)=0 then
(case when door_avg<10 then to_char(trunc(door_avg, 3) % 60, 'FM0.999')||'000'
when door_avg<60 then to_char(trunc(door_avg, 3) % 60, 'FM00.999')||'000'
else floor(door_avg / 60) || ':' || to_char(trunc(door_avg, 3) % 60, 'FM00.999')||'000' end)
when trunc(door_avg-trunc(door_avg), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then (case when door_avg<10 then to_char(trunc(door_avg, 3) % 60, 'FM0.999')||'00'
when door_avg<60 then to_char(trunc(door_avg, 3) % 60, 'FM00.999')||'00'
else floor(door_avg / 60) || ':' || to_char(trunc(door_avg, 3) % 60, 'FM00.999')||'00' end)
when trunc(door_avg-trunc(door_avg), 3) in (select numb from decimals_table_runner)
then (case when door_avg<10 then to_char(trunc(door_avg, 3) % 60, 'FM0.999')||'0'
when door_avg<60 then to_char(trunc(door_avg, 3) % 60, 'FM00.999')||'0'
else floor(door_avg / 60) || ':' || to_char(trunc(door_avg, 3) % 60, 'FM00.999')||'0' end)
else (case when door_avg<10 then to_char(trunc(door_avg, 3) % 60, 'FM0.999')
when door_avg<60 then to_char(trunc(door_avg, 3) % 60, 'FM00.999')
else floor(door_avg / 60) || ':' || to_char(trunc(door_avg, 3) % 60, 'FM00.999') end) end as door_avg2,
case when trunc(door_median-trunc(door_median), 3)=0 then
(case when door_median<10 then to_char(trunc(door_median, 3) % 60, 'FM0.999')||'000'
when door_median<60 then to_char(trunc(door_median, 3) % 60, 'FM00.999')||'000'
else floor(door_median / 60) || ':' || to_char(trunc(door_median, 3) % 60, 'FM00.999')||'000' end)
when trunc(door_median-trunc(door_median), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then (case when door_median<10 then to_char(trunc(door_median, 3) % 60, 'FM0.999')||'00'
when door_median<60 then to_char(trunc(door_median, 3) % 60, 'FM00.999')||'00'
else floor(door_median / 60) || ':' || to_char(trunc(door_median, 3) % 60, 'FM00.999')||'00' end)
when trunc(door_median-trunc(door_median), 3) in (select numb from decimals_table_runner)
then (case when door_median<10 then to_char(trunc(door_median, 3) % 60, 'FM0.999')||'0'
when door_median<60 then to_char(trunc(door_median, 3) % 60, 'FM00.999')||'0'
else floor(door_median / 60) || ':' || to_char(trunc(door_median, 3) % 60, 'FM00.999')||'0' end)
else (case when door_median<10 then to_char(trunc(door_median, 3) % 60, 'FM0.999')
when door_median<60 then to_char(trunc(door_median, 3) % 60, 'FM00.999')
else floor(door_median / 60) || ':' || to_char(trunc(door_median, 3) % 60, 'FM00.999') end) end as door_median2
from(
select a.cle2, a.split, a.gold, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.gold2, a.door_avg, a.door_median,
	sum(b.gold) as cumulative_chapter_gold
from doorsplits_golds_runner a
left join (select distinct cle2, gold from doorsplits_golds_runner) b on a.cle2>=b.cle2
group by a.cle2, a.split, a.gold, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.gold2, a.door_avg, a.door_median
order by a.cle2) a
order by cle2;

drop table if exists doorsplits_golds_history_runner;
create table doorsplits_golds_history_runner as
select cle2, split, gold, id, date_started, finished_run, final_lrt, pb, gold2, case when lrt_number<=min or min is null then 1 else 0
end as golded_split,
case when trunc(min-trunc(min), 3)=0 then
(case when min<10 then to_char(trunc(min, 3) % 60, 'FM0.999')||'000'
when min<60 then to_char(trunc(min, 3) % 60, 'FM00.999')||'000'
else floor(min / 60) || ':' || to_char(trunc(min, 3) % 60, 'FM00.999')||'000' end)
when trunc(min-trunc(min), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then (case when min<10 then to_char(trunc(min, 3) % 60, 'FM0.999')||'00'
when min<60 then to_char(trunc(min, 3) % 60, 'FM00.999')||'00'
else floor(min / 60) || ':' || to_char(trunc(min, 3) % 60, 'FM00.999')||'00' end)
when trunc(min-trunc(min), 3) in (select numb from decimals_table_runner)
then (case when min<10 then to_char(trunc(min, 3) % 60, 'FM0.999')||'0'
when min<60 then to_char(trunc(min, 3) % 60, 'FM00.999')||'0'
else floor(min / 60) || ':' || to_char(trunc(min, 3) % 60, 'FM00.999')||'0' end)
else (case when min<10 then to_char(trunc(min, 3) % 60, 'FM0.999')
when min<60 then to_char(trunc(min, 3) % 60, 'FM00.999')
else floor(min / 60) || ':' || to_char(trunc(min, 3) % 60, 'FM00.999') end) end as gold_at_that_time, lrt_number as lrt_number8, rank() over (partition by cle2 order by lrt_number) as rank_split
from (select a.cle2, a.split, c.gold, c.gold2, a.lrt_number, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.lrt_split, min(b.lrt_number) as min,
min(b.lrt_split) as min2
from splits_cleaned_runner a
left join splits_cleaned_runner b on a.cle2=b.cle2 and a.id>b.id
left join (select distinct cle2, split, gold, gold2 from doorsplits_golds_runner) c on a.cle2=c.cle2
group by a.cle2, a.split, c.gold, c.gold2, a.lrt_number, a.id, a.date_started, a.finished_run, a.final_lrt, a.pb, a.lrt_split) a;

drop table if exists doorsplits_golds_history_runner2;
create table doorsplits_golds_history_runner2 as
select a.*, split_rank_at_that_time, finished_splits, finished_splits_at_that_time
from doorsplits_golds_history_runner a
left join (select cle2, count(*) as finished_splits from doorsplits_golds_history_runner group by 1) c on a.cle2=c.cle2
left join (select *
from (select a.*, b.lrt_number8 as split_time3, b.id as id2,
rank() over (partition by a.cle2, a.id order by b.lrt_number8) as split_rank_at_that_time
from doorsplits_golds_history_runner a
join doorsplits_golds_history_runner b on a.cle2=b.cle2 and a.id>=b.id) a
where id=id2) d on a.cle2=d.cle2 and a.id=d.id

left join (

select a.cle2, a.id, count(*) as finished_splits_at_that_time
from doorsplits_golds_history_runner a
join doorsplits_golds_history_runner b on a.cle2=b.cle2 and a.id>=b.id
group by 1, 2) e on a.cle2=e.cle2 and a.id=e.id;

/* Getting the pace (and best pace) of each run after each split */

drop table if exists best_paces_runner;
create table best_paces_runner as
select pace.*, best_pace, /*avg_pace, median_pace,*/
case when trunc(pace-trunc(pace), 3)=0 then (case when pace<3600 then floor(pace / 60) || ':' ||
to_char(trunc(pace, 3) % 60, 'FM00.999')||'000'
else floor(pace / 3600) || ':' || case when floor(pace / 60)-(floor(pace/3600)*60)<10 then '0' else '' end ||
	  floor(pace / 60)-(floor(pace/3600)*60) || ':' ||
to_char(trunc(pace, 3) % 60, 'FM00.999')||'000' end)
when trunc(pace-trunc(pace), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then (case when pace<3600 then floor(pace / 60) || ':' ||
to_char(trunc(pace, 3) % 60, 'FM00.999')||'00'
else floor(pace / 3600) || ':' || case when floor(pace / 60)-(floor(pace/3600)*60)<10 then '0' else '' end ||
	  floor(pace / 60)-(floor(pace/3600)*60) || ':' ||
to_char(trunc(pace, 3) % 60, 'FM00.999')||'00' end)
when trunc(pace-trunc(pace), 3) in (select numb from decimals_table_runner)
then (case when pace<3600 then floor(pace / 60) || ':' ||
to_char(trunc(pace, 3) % 60, 'FM00.999')||'0'
else floor(pace / 3600) || ':' || case when floor(pace / 60)-(floor(pace/3600)*60)<10 then '0' else '' end ||
          floor(pace / 60)-(floor(pace/3600)*60) || ':' ||
to_char(trunc(pace, 3) % 60, 'FM00.999')||'0' end)
else (case when pace<3600 then floor(pace / 60) || ':' ||
to_char(trunc(pace, 3) % 60, 'FM00.999')
else floor(pace / 3600) || ':' || case when floor(pace / 60)-(floor(pace/3600)*60)<10 then '0' else '' end ||
	  floor(pace / 60)-(floor(pace/3600)*60)|| ':' ||
to_char(trunc(pace, 3) % 60, 'FM00.999') end) end as pace2,
case when trunc(best_pace-trunc(best_pace), 3)=0 then (case when best_pace>=3600 then
floor(best_pace / 3600) || ':' || case when floor(best_pace / 60)-(floor(best_pace/3600)*60)<10 then '0' else '' end ||
	  floor(best_pace / 60)-(floor(best_pace/3600)*60) || ':' ||
to_char(trunc(best_pace, 3) % 60, 'FM00.999')||'000'
else floor(best_pace / 60) || ':' ||
to_char(trunc(best_pace, 3) % 60, 'FM00.999')||'000' end)
when trunc(best_pace-trunc(best_pace), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then (case when best_pace>=3600 then
floor(best_pace / 3600) || ':' || case when floor(best_pace / 60)-(floor(best_pace/3600)*60)<10 then '0' else '' end ||
	  floor(best_pace / 60)-(floor(best_pace/3600)*60) || ':' ||
to_char(trunc(best_pace, 3) % 60, 'FM00.999')||'00'
else floor(best_pace / 60) || ':' ||
to_char(trunc(best_pace, 3) % 60, 'FM00.999')||'00' end)
when trunc(best_pace-trunc(best_pace), 3) in (select numb from decimals_table_runner)
then (case when best_pace>=3600 then
floor(best_pace / 3600) || ':' || case when floor(best_pace / 60)-(floor(best_pace/3600)*60)<10 then '0' else '' end ||
          floor(best_pace / 60)-(floor(best_pace/3600)*60) || ':' ||
to_char(trunc(best_pace, 3) % 60, 'FM00.999')||'0'
else floor(best_pace / 60) || ':' ||
to_char(trunc(best_pace, 3) % 60, 'FM00.999')||'0' end)
else (case when best_pace>=3600 then
floor(best_pace / 3600) || ':' || case when floor(best_pace / 60)-(floor(best_pace/3600)*60)<10 then '0' else '' end ||
	  floor(best_pace / 60)-(floor(best_pace/3600)*60) || ':' ||
to_char(trunc(best_pace, 3) % 60, 'FM00.999')
else floor(best_pace / 60) || ':' ||
to_char(trunc(best_pace, 3) % 60, 'FM00.999') end) end as best_pace2/*,
case when trunc(avg_pace-trunc(avg_pace), 3)=0 then (case when avg_pace>=3600 then
floor(avg_pace / 3600) || ':' || case when floor(avg_pace / 60)-(floor(avg_pace/3600)*60)<10 then '0' else '' end ||
	  floor(avg_pace / 60)-(floor(avg_pace/3600)*60) || ':' ||
to_char(trunc(avg_pace, 3) % 60, 'FM00.999')||'000'
else floor(avg_pace / 60) || ':' ||
to_char(trunc(avg_pace, 3) % 60, 'FM00.999')||'000' end)
when trunc(avg_pace-trunc(avg_pace), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then (case when avg_pace>=3600 then
floor(avg_pace / 3600) || ':' || case when floor(avg_pace / 60)-(floor(avg_pace/3600)*60)<10 then '0' else '' end ||
	  floor(avg_pace / 60)-(floor(avg_pace/3600)*60) || ':' ||
to_char(trunc(avg_pace, 3) % 60, 'FM00.999')||'00'
else floor(avg_pace / 60) || ':' ||
to_char(trunc(avg_pace, 3) % 60, 'FM00.999')||'00' end)
when trunc(avg_pace-trunc(avg_pace), 3) in (select numb from decimals_table_runner)
then (case when avg_pace>=3600 then
floor(avg_pace / 3600) || ':' || case when floor(avg_pace / 60)-(floor(avg_pace/3600)*60)<10 then '0' else '' end ||
          floor(avg_pace / 60)-(floor(avg_pace/3600)*60) || ':' ||
to_char(trunc(avg_pace, 3) % 60, 'FM00.999')||'0'
else floor(avg_pace / 60) || ':' ||
to_char(trunc(avg_pace, 3) % 60, 'FM00.999')||'0' end)
else (case when avg_pace>=3600 then
floor(avg_pace / 3600) || ':' || case when floor(avg_pace / 60)-(floor(avg_pace/3600)*60)<10 then '0' else '' end ||
	  floor(avg_pace / 60)-(floor(avg_pace/3600)*60) || ':' ||
to_char(trunc(avg_pace, 3) % 60, 'FM00.999')
else floor(avg_pace / 60) || ':' ||
to_char(trunc(avg_pace, 3) % 60, 'FM00.999') end) end as avg_pace2,
case when trunc(median_pace-trunc(median_pace), 3)=0 then (case when median_pace>=3600 then
floor(median_pace / 3600) || ':' || case when floor(median_pace / 60)-(floor(median_pace/3600)*60)<10 then '0' else '' end ||
	  floor(median_pace / 60)-(floor(median_pace/3600)*60) || ':' ||
to_char(trunc(median_pace, 3) % 60, 'FM00.999')||'000'
else floor(median_pace / 60) || ':' ||
to_char(trunc(median_pace, 3) % 60, 'FM00.999')||'000' end)
when trunc(median_pace-trunc(median_pace), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then (case when median_pace>=3600 then
floor(median_pace / 3600) || ':' || case when floor(median_pace / 60)-(floor(median_pace/3600)*60)<10 then '0' else '' end ||
	  floor(median_pace / 60)-(floor(median_pace/3600)*60) || ':' ||
to_char(trunc(median_pace, 3) % 60, 'FM00.999')||'00'
else floor(median_pace / 60) || ':' ||
to_char(trunc(median_pace, 3) % 60, 'FM00.999')||'00' end)
when trunc(median_pace-trunc(median_pace), 3) in (select numb from decimals_table_runner)
then (case when median_pace>=3600 then
floor(median_pace / 3600) || ':' || case when floor(median_pace / 60)-(floor(median_pace/3600)*60)<10 then '0' else '' end ||
          floor(median_pace / 60)-(floor(median_pace/3600)*60) || ':' ||
to_char(trunc(median_pace, 3) % 60, 'FM00.999')||'0'
else floor(median_pace / 60) || ':' ||
to_char(trunc(median_pace, 3) % 60, 'FM00.999')||'0' end)
else (case when median_pace>=3600 then
floor(median_pace / 3600) || ':' || case when floor(median_pace / 60)-(floor(median_pace/3600)*60)<10 then '0' else '' end ||
	  floor(median_pace / 60)-(floor(median_pace/3600)*60) || ':' ||
to_char(trunc(median_pace, 3) % 60, 'FM00.999')
else floor(median_pace / 60) || ':' ||
to_char(trunc(median_pace, 3) % 60, 'FM00.999') end) end as median_pace2*/
from (select aa.cle2, aa.id, aa.split, count(*) as number_of_splits, sum(bb.lrt_number) as pace
from
(select *
from splits_cleaned_runner a) aa
join
(select *
from splits_cleaned_runner a) bb on aa.cle2>=bb.cle2 and aa.id=bb.id
group by aa.id, aa.split, aa.cle2
having count(*)=aa.cle2
order by aa.id, aa.cle2) pace
left join (
select split, cle2, min(pace) as best_pace/*, cast(avg(pace) as numeric) as avg_pace,
cast(percentile_cont(0.5) within group(order by pace) as numeric) as median_pace*/
from(
select aa.cle2, aa.id, aa.split, count(*) as number_of_splits, sum(bb.lrt_number) as pace
from
(select *
from splits_cleaned_runner a) aa
join
(select *
from splits_cleaned_runner a) bb on aa.cle2>=bb.cle2 and aa.id=bb.id
group by aa.id, aa.split, aa.cle2
order by aa.id, aa.cle2)
where id>0
and number_of_splits=cle2
group by split, cle2
order by cle2) best_pace on pace.cle2=best_pace.cle2;

drop table if exists best_paces_history_runner;
create table best_paces_history_runner as
select cle2, id, split, number_of_splits, pace, best_pace, pace2, best_pace2, case when pace<=min or min is null then 1 else 0
end as was_best_pace,
case when trunc(min-trunc(min), 3)=0 then (case when min<3600 then floor(min / 60) || ':' ||
to_char(trunc(min, 3) % 60, 'FM00.999')||'000'
else floor(min / 3600) || ':' || case when floor(min / 60)-(floor(min/3600)*60)<10 then '0' else '' end ||
	  floor(min / 60)-(floor(min/3600)*60) || ':' ||
to_char(trunc(min, 3) % 60, 'FM00.999')||'000' end)
when trunc(min-trunc(min), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then (case when min<3600 then floor(min / 60) || ':' ||
to_char(trunc(min, 3) % 60, 'FM00.999')||'00'
else floor(min / 3600) || ':' || case when floor(min / 60)-(floor(min/3600)*60)<10 then '0' else '' end ||
	  floor(min / 60)-(floor(min/3600)*60) || ':' ||
to_char(trunc(min, 3) % 60, 'FM00.999')||'00' end)
when trunc(min-trunc(min), 3) in (select numb from decimals_table_runner)
then (case when min<3600 then floor(min / 60) || ':' ||
to_char(trunc(min, 3) % 60, 'FM00.999')||'0'
else floor(min / 3600) || ':' || case when floor(min / 60)-(floor(min/3600)*60)<10 then '0' else '' end ||
          floor(min / 60)-(floor(min/3600)*60) || ':' ||
to_char(trunc(min, 3) % 60, 'FM00.999')||'0' end)
else (case when min<3600 then floor(min / 60) || ':' ||
to_char(trunc(min, 3) % 60, 'FM00.999')
else floor(min / 3600) || ':' || case when floor(min / 60)-(floor(min/3600)*60)<10 then '0' else '' end ||
	  floor(min / 60)-(floor(min/3600)*60)|| ':' ||
to_char(trunc(min, 3) % 60, 'FM00.999') end) end as best_pace_at_that_time, min as best_pace_at_that_time2/*,
avg_pace, median_pace, avg_pace2, median_pace2*/, rank() over (partition by cle2 order by pace) as rank_pace
from (select a.cle2, a.id, a.split, a.number_of_splits, a.pace, a.best_pace, a.pace2, a.best_pace2, /*a.avg_pace, a.median_pace,
a.avg_pace2, a.median_pace2,*/ min(b.pace) as min,
min(b.pace2) as min2
from best_paces_runner a
left join best_paces_runner b on a.cle2=b.cle2 and a.id>b.id
group by a.cle2, a.id, a.split, a.number_of_splits, a.pace, a.best_pace, a.pace2, a.best_pace2/*, a.avg_pace, a.median_pace,
a.avg_pace2, a.median_pace2*/) a
order by cle2 desc, id;

drop table if exists best_paces_history_runner2;
create table best_paces_history_runner2 as
select a.*, pace_rank_at_that_time, finished_paces, finished_paces_at_that_time
from best_paces_history_runner a
left join (select cle2, count(*) as finished_paces from best_paces_history_runner group by 1) c on a.cle2=c.cle2
left join (select *
from (select a.*, b.pace as pace_time3, b.id as id2,
rank() over (partition by a.cle2, a.id order by b.pace) as pace_rank_at_that_time
from best_paces_history_runner a
join best_paces_history_runner b on a.cle2=b.cle2 and a.id>=b.id) a
where id=id2) d on a.cle2=d.cle2 and a.id=d.id

left join (

select a.cle2, a.id, count(*) as finished_paces_at_that_time
from best_paces_history_runner a
join best_paces_history_runner b on a.cle2=b.cle2 and a.id>=b.id
group by 1, 2) e on a.cle2=e.cle2 and a.id=e.id;

/* Checking is a gold was done on a gold hunt (bad run) by checking the delta between the pace of that run and the best pace for each
split */

drop table if exists gold_hunt_detector_runner;
create table gold_hunt_detector_runner as
select cle2, split, gold, gold2, id, date_started, finished_run, final_lrt, pb, pace, pace2, best_pace, best_pace2,
best_pace_delta
from(
select a.*, pace, best_pace, pace-best_pace as best_pace_delta, pace2, best_pace2,
row_number () over (partition by a.cle2 order by pace-best_pace) as rang
from doorsplits_golds_runner a
left join best_paces_history_runner2 b on a.id=b.id and a.cle2=b.cle2) a
where rang=1
order by cle2;

/* Resets history to get the % of resets for each split */

drop table if exists resets_history_runner;
create table resets_history_runner as
select a.*, attempts
from(
select cle2, split, count(*) as runs
from splits_cleaned_runner
group by cle2, split
order by cle2) a cross join (select max(id) as attempts
from attempts_treatment3_runner
group by runner_name) b;

drop table if exists resets_history2_runner;
create table resets_history2_runner as
select cle2, split, runs, resets, (round(resets)/round(case when lag is null then runs+resets else lag end))*100
as percentage_resets
from(
select *, lag(runs) over() as lag
from(
select cle2, split, runs, case when lag(runs) over ()-runs is null then attempts-runs else lag(runs) over ()-runs end as resets
from resets_history_runner));

/*drop table if exists resets_history;*/

/* Final main table that has everything */

drop table if exists splits_overview_runner;
create table splits_overview_runner as
select *
from (select a.id, a.split, a.chapter, a.section, a.lrt_number, a.lrt_split, a.date_started, a.finished_run, a.final_lrt, a.pb, a.cle2, a.final_rta,
a.date_end, a.time_start_numeric3 as time_start, a.time_end_numeric3 as time_end, a.playtime, a.rta_numeric, a.rta_split, e.gold2, e.gold, pace,
pace2, best_pace, best_pace2, chapter_time, chapter_time2, section_time, section_time2,
chapter_gold, chapter_gold2, section_gold, section_gold2,
case when a.finished_run=1 then null else split_of_reset end as split_of_reset,
case when a.finished_run=1 then null else cle2_reset end as cle2_reset,
case when a.cle2=30 and lrt_number<=54.5 then '2-a Fast Mendez'
when a.cle2=30 and lrt_number<=57 then '2-b Medium Mendez'
when a.cle2=30 then '2-c Slow Mendez'
else '' end as mendez_pattern,
case when a.cle2=14 and lrt_number<=96 then '1-a No dive'
when a.cle2=14 and lrt_number<=102 then '1-b Late dive'
when a.cle2=14 or (a.cle2=13 and cle2_reset=14) then '1-c Early dive'
else '' end as lago_pattern,
case when a.cle2=65 and lrt_number<=31 then '3-a Perfect catapult'
when a.cle2=65 and lrt_number<=33 then '3-b Stagger catapult'
when a.cle2=65 then '3-c Boulder catapult'
else '' end as catapult_pattern,
case when a.cle2=26 and lrt_number<=113 then '4-a Great cabin'
when a.cle2=26 and lrt_number<=118 then '4-b Good cabin'
when a.cle2=26 and lrt_number<=123 then '4-c Average cabin'
when a.cle2=26 and lrt_number<=130 then '4-d Bad cabin'
when a.cle2=26 then '4-e Shitty cabin'
else '' end as cabin_pattern,
case when a.cle2=38 and lrt_number<=196 then '5-a Great water hall'
when a.cle2=38 and lrt_number<=199 then '5-b Good water hall'
when a.cle2=38 and lrt_number<=202 then '5-c Average water hall'
when a.cle2=38 and lrt_number<=205 then '5-d Bad water hall'
when a.cle2=38 then '5-e Shitty water hall'
else '' end as water_hall_pattern,
case when a.cle2=41 and lrt_number<=82 then '6-a Great novis 1'
when a.cle2=41 and lrt_number<=84 then '6-b Good novis 1'
when a.cle2=41 and lrt_number<=86 then '6-c Average novis 1'
when a.cle2=41 and lrt_number<=88 then '6-d Bad novis 1'
when a.cle2=41 then '6-e Shitty novis 1'
else '' end as novis1_pattern,
case when a.cle2=43 and lrt_number<=102 then '7-a Great gallery'
when a.cle2=43 and lrt_number<=105 then '7-b Good gallery'
when a.cle2=43 and lrt_number<=108 then '7-c Average gallery'
when a.cle2=43 and lrt_number<=110 then '7-d Bad gallery'
when a.cle2=43 then '7-e Shitty gallery'
else '' end as gallery_pattern,
case when a.cle2=64 and lrt_number<=33.5 then '8-a Great novis 2'
when a.cle2=64 and lrt_number<=35 then '8-b Good novis 2'
when a.cle2=64 and lrt_number<=38 then '8-c Average novis 2'
when a.cle2=64 and lrt_number<=40 then '8-d Bad novis 2'
when a.cle2=64 then '8-e Shitty novis 2'
else '' end as novis2_pattern,
case when a.cle2=74 and lrt_number<=77 then '9-a Great novis 3'
when a.cle2=74 and lrt_number<=79 then '9-b Good novis 3'
when a.cle2=74 and lrt_number<=82 then '9-c Average novis 3'
when a.cle2=74 and lrt_number<=85 then '9-d Bad novis 3'
when a.cle2=74 then '9-e Shitty novis 3'
else '' end as novis3_pattern,
case when a.cle2=110 and lrt_number<=95.5 then '90-a Great u3'
when a.cle2=110 and lrt_number<=99 then '90-b Good u3'
when a.cle2=110 and lrt_number<=101 then '90-c Average u3'
when a.cle2=110 and lrt_number<=103 then '90-d Bad u3'
when a.cle2=110 then '90-e Shitty u3'
else '' end as u3_pattern,
case when a.cle2=112 and lrt_number<=139 then '91-a Great Krauser'
when a.cle2=112 and lrt_number<=142 then '91-b Good Krauser'
when a.cle2=112 and lrt_number<=145 then '91-c Average Krauser'
when a.cle2=112 and lrt_number<=148 then '91-d Bad Krauser'
when a.cle2=112 then '91-e Shitty Krauser'
else '' end as krauser_pattern,
case when a.cle2=113 and lrt_number<=111 then '92-a Great war room'
when a.cle2=113 and lrt_number<=114 then '92-b Good war room'
when a.cle2=113 and lrt_number<=117 then '92-c Average war room'
when a.cle2=113 and lrt_number<=120 then '92-d Bad war room'
when a.cle2=113 then '92-e Shitty war room'
else '' end as war_room_pattern,
case when a.cle2=117 and lrt_number<=55 then '93-a Great key card'
when a.cle2=117 and lrt_number<=57 then '93-b Good key card'
when a.cle2=117 and lrt_number<=59 then '93-c Average key card'
when a.cle2=117 and lrt_number<=61 then '93-d Bad key card'
when a.cle2=117 then '93-e Shitty key card'
else '' end as key_card_pattern,
case when extract(dow from a.date_started)=0 then 7 else extract(dow from a.date_started) end as weekday,
h.lrt_pb as pb_at_that_time, golded_split, golded_chapter, golded_section, was_best_pace, cumulative_chapter_gold, cumulative_chapter_gold_num, cumulative_section_gold,
cumulative_door_gold, cumulative_door_gold_num, gold_at_that_time, chapter_gold_at_that_time, section_gold_at_that_time, best_pace_at_that_time,
best_pace_at_that_time2, case when cast(substr(a.time_start, 1, 2) as numeric)>cast(substr(a.time_start_numeric3, 1, 2) as numeric)
then a.date_started+1 else a.date_started end as date_started2,
case when cast(substr(a.time_end, 1, 2) as numeric)<cast(substr(a.time_end_numeric3, 1, 2) as numeric)
then a.date_end-1 else a.date_end end as date_end2, door_avg, door_median, door_avg2, door_median2, median_chapter_time, median_chapter_time2,
/*avg_pace, median_pace, avg_pace2, median_pace2,*/ section_median, section_median2, section_avg2, avg_chapter_time2, 'runner' as runner_name, rank_chapter, chapter_rank_at_that_time, finished_chapters,
finished_chapters_at_that_time, rank_section, section_rank_at_that_time, finished_sections, finished_sections_at_that_time, rank_split, split_rank_at_that_time, finished_splits, finished_splits_at_that_time,
rank_pace, pace_rank_at_that_time, finished_paces, finished_paces_at_that_time,
row_number() over (partition by a.id, a.cle2 order by id2 desc) as rang
from splits_cleaned_runner a
left join best_paces_history_runner2 b on a.id=b.id and a.cle2=b.cle2
left join (select cle2, gold2, gold, door_avg, door_median, door_avg2, door_median2, min(cumulative_door_gold) as cumulative_door_gold, min(cumulative_door_gold_num) as cumulative_door_gold_num
		   from doorsplits_golds2_runner
		   group by cle2, gold2, gold, door_avg, door_median, door_avg2, door_median2) e on a.cle2=e.cle2
left join doorsplits_golds_history_runner2 ee on a.cle2=ee.cle2 and a.id=ee.id
left join chapter_history3_runner c on a.id=c.id and a.chapter=c.chapter
left join section_history3_runner d on a.id=d.id and a.section=d.section
left join chapter_golds3_runner f on a.chapter=f.chapter
left join section_golds3_runner g on a.section=g.section
left join (select a.id, b.split as split_of_reset, b.cle2 as cle2_reset
from (select id, max(cle2)+1 as max
from splits_cleaned_runner
group by id) a
left join (select distinct cle2, split from splits_cleaned_runner) b on a.max=b.cle2) resets on resets.id=a.id
left join (select *, cast (id as numeric) as id2 from pb_history_runner) h on a.id>h.id2) aa
where rang=1
order by id, cle2;

/* RNG splits (like Lago) to get the % of patterns (like % of early dives, etc.) */

drop table if exists rng_splits_runner;
create table rng_splits_runner as
select pattern, substr(pattern, 4, length(pattern)-3) as pattern2, runs, total, percentage
from(select pattern, runs, total, percentage
from (select a.*, total, round(runs)/round(total)*100 as percentage
from(
select lago_pattern as pattern, count(*) as runs
from splits_overview_runner a
left join splits_cleaned_runner b on a.id=b.id and a.cle2=b.cle2
where (a.cle2=14 and a.lrt_number<117) or (a.cle2=13 and cle2_reset=14 and
case when time_end_numeric2>time_end_numeric and b.time_end<>time_end_numeric3 then time_end_numeric-time_end_numeric2+86400 else time_end_numeric-time_end_numeric2 end>=case when runner_name like '%lu%'
and runner_name like '%is%' then 59 else 56 end)
group by 1) a
cross join (
select count(*) as total
from splits_overview_runner a
left join splits_cleaned_runner b on a.id=b.id and a.cle2=b.cle2
where (a.cle2=14 and a.lrt_number<117) or (a.cle2=13 and cle2_reset=14 and
case when time_end_numeric2>time_end_numeric and b.time_end<>time_end_numeric3 then time_end_numeric-time_end_numeric2+86400 else time_end_numeric-time_end_numeric2 end>=case when runner_name like '%lu%'
and runner_name like '%is%' then 59 else 56 end)) b)
union
(select a.*, total, round(runs)/round(total)*100 as percentage
from(
select mendez_pattern as pattern, count(*) as runs
from splits_overview_runner
where mendez_pattern<>'' and lrt_number<60
group by 1) a
cross join (
select count(*) as total
from splits_overview_runner
where cle2=30 and lrt_number<60) b)
union
(select a.*, total, round(runs)/round(total)*100 as percentage
from(
select catapult_pattern as pattern, count(*) as runs
from splits_overview_runner
where catapult_pattern<>'' and lrt_number<40
group by 1) a
cross join (
select count(*) as total
from splits_overview_runner
where cle2=65 and lrt_number<40) b)
union
(select a.*, total, round(runs)/round(total)*100 as percentage
from(
select cabin_pattern as pattern, count(*) as runs
from splits_overview_runner
where cabin_pattern<>''-- and lrt_number<40
group by 1) a
cross join (
select count(*) as total
from splits_overview_runner
where cle2=26-- and lrt_number<40
) b)
union
(select a.*, total, round(runs)/round(total)*100 as percentage
from(
select water_hall_pattern as pattern, count(*) as runs
from splits_overview_runner
where water_hall_pattern<>''-- and lrt_number<40
group by 1) a
cross join (
select count(*) as total
from splits_overview_runner
where cle2=38-- and lrt_number<40
) b)
union
(select a.*, total, round(runs)/round(total)*100 as percentage
from(
select novis1_pattern as pattern, count(*) as runs
from splits_overview_runner
where novis1_pattern<>''-- and lrt_number<40
group by 1) a
cross join (
select count(*) as total
from splits_overview_runner
where cle2=41-- and lrt_number<40
) b)
union
(select a.*, total, round(runs)/round(total)*100 as percentage
from(
select gallery_pattern as pattern, count(*) as runs
from splits_overview_runner
where gallery_pattern<>''-- and lrt_number<40
group by 1) a
cross join (
select count(*) as total
from splits_overview_runner
where cle2=43-- and lrt_number<40
) b)
union
(select a.*, total, round(runs)/round(total)*100 as percentage
from(
select novis2_pattern as pattern, count(*) as runs
from splits_overview_runner
where novis2_pattern<>''-- and lrt_number<40
group by 1) a
cross join (
select count(*) as total
from splits_overview_runner
where cle2=64-- and lrt_number<40
) b)
union
(select a.*, total, round(runs)/round(total)*100 as percentage
from(
select novis3_pattern as pattern, count(*) as runs
from splits_overview_runner
where novis3_pattern<>''-- and lrt_number<40
group by 1) a
cross join (
select count(*) as total
from splits_overview_runner
where cle2=74-- and lrt_number<40
) b)
union
(select a.*, total, round(runs)/round(total)*100 as percentage
from(
select u3_pattern as pattern, count(*) as runs
from splits_overview_runner
where u3_pattern<>''-- and lrt_number<40
group by 1) a
cross join (
select count(*) as total
from splits_overview_runner
where cle2=110-- and lrt_number<40
) b)
union
(select a.*, total, round(runs)/round(total)*100 as percentage
from(
select krauser_pattern as pattern, count(*) as runs
from splits_overview_runner
where krauser_pattern<>''-- and lrt_number<40
group by 1) a
cross join (
select count(*) as total
from splits_overview_runner
where cle2=112-- and lrt_number<40
) b)
union
(select a.*, total, round(runs)/round(total)*100 as percentage
from(
select war_room_pattern as pattern, count(*) as runs
from splits_overview_runner
where war_room_pattern<>''-- and lrt_number<40
group by 1) a
cross join (
select count(*) as total
from splits_overview_runner
where cle2=113-- and lrt_number<40
) b)
union
(select a.*, total, round(runs)/round(total)*100 as percentage
from(
select key_card_pattern as pattern, count(*) as runs
from splits_overview_runner
where key_card_pattern<>''-- and lrt_number<40
group by 1) a
cross join (
select count(*) as total
from splits_overview_runner
where cle2=117-- and lrt_number<40
) b)
order by pattern);

/* Same but to get the consecutive patterns (like how many early dives in a row */

drop table if exists consecutive_patterns_runner;
create table consecutive_patterns_runner as
select *
from (
select lago_pattern, max(rank) as maximum_consecutive_patterns
from(
select id, lago_pattern, row_number() over (partition by lago_pattern, row_number - row_number2 order by id) as rank
from(
select distinct a.id, lago_pattern,
row_number() over (order by a.id) as row_number,
row_number() over (partition by lago_pattern order by a.id) as row_number2
from splits_overview_runner a
left join splits_cleaned_runner b on a.id=b.id and a.cle2=b.cle2
where (a.cle2=14 and a.lrt_number<117) or (a.cle2=13 and cle2_reset=14 and
case when time_end_numeric2>time_end_numeric and b.time_end<>time_end_numeric3 then time_end_numeric-time_end_numeric2+86400 else time_end_numeric-time_end_numeric2 end>=case when runner_name like '%lu%'
and runner_name like '%is%' then 59 else 56 end))
order by id)
group by 1
union
select mendez_pattern, max(rank) as maximum_consecutive_patterns
from(
select id, mendez_pattern, row_number() over (partition by mendez_pattern, row_number - row_number2 order by id) as rank
from(
select distinct id, mendez_pattern,
row_number() over (order by id) as row_number,
row_number() over (partition by mendez_pattern order by id) as row_number2
from splits_overview_runner
where mendez_pattern<>'' and lrt_number<60)
order by id)
group by 1
union
select catapult_pattern, max(rank) as maximum_consecutive_patterns
from(
select id, catapult_pattern, row_number() over (partition by catapult_pattern, row_number - row_number2 order by id) as rank
from(
select distinct id, catapult_pattern,
row_number() over (order by id) as row_number,
row_number() over (partition by catapult_pattern order by id) as row_number2
from splits_overview_runner
where catapult_pattern<>'' and lrt_number<40)
order by id)
group by 1
union
select cabin_pattern, max(rank) as maximum_consecutive_patterns
from(
select id, cabin_pattern, row_number() over (partition by cabin_pattern, row_number - row_number2 order by id) as rank
from(
select distinct id, cabin_pattern,
row_number() over (order by id) as row_number,
row_number() over (partition by cabin_pattern order by id) as row_number2
from splits_overview_runner
where cabin_pattern<>''-- and lrt_number<40
)
order by id)
group by 1
union
select water_hall_pattern, max(rank) as maximum_consecutive_patterns
from(
select id, water_hall_pattern, row_number() over (partition by water_hall_pattern, row_number - row_number2 order by id) as rank
from(
select distinct id, water_hall_pattern,
row_number() over (order by id) as row_number,
row_number() over (partition by water_hall_pattern order by id) as row_number2
from splits_overview_runner
where water_hall_pattern<>''-- and lrt_number<40
)
order by id)
group by 1
union
select novis1_pattern, max(rank) as maximum_consecutive_patterns
from(
select id, novis1_pattern, row_number() over (partition by novis1_pattern, row_number - row_number2 order by id) as rank
from(
select distinct id, novis1_pattern,
row_number() over (order by id) as row_number,
row_number() over (partition by novis1_pattern order by id) as row_number2
from splits_overview_runner
where novis1_pattern<>''-- and lrt_number<40
)
order by id)
group by 1
union
select gallery_pattern, max(rank) as maximum_consecutive_patterns
from(
select id, gallery_pattern, row_number() over (partition by gallery_pattern, row_number - row_number2 order by id) as rank
from(
select distinct id, gallery_pattern,
row_number() over (order by id) as row_number,
row_number() over (partition by gallery_pattern order by id) as row_number2
from splits_overview_runner
where gallery_pattern<>''-- and lrt_number<40
)
order by id)
group by 1
union
select novis2_pattern, max(rank) as maximum_consecutive_patterns
from(
select id, novis2_pattern, row_number() over (partition by novis2_pattern, row_number - row_number2 order by id) as rank
from(
select distinct id, novis2_pattern,
row_number() over (order by id) as row_number,
row_number() over (partition by novis2_pattern order by id) as row_number2
from splits_overview_runner
where novis2_pattern<>''-- and lrt_number<40
)
order by id)
group by 1
union
select novis3_pattern, max(rank) as maximum_consecutive_patterns
from(
select id, novis3_pattern, row_number() over (partition by novis3_pattern, row_number - row_number2 order by id) as rank
from(
select distinct id, novis3_pattern,
row_number() over (order by id) as row_number,
row_number() over (partition by novis3_pattern order by id) as row_number2
from splits_overview_runner
where novis3_pattern<>''-- and lrt_number<40
)
order by id)
group by 1
union
select u3_pattern, max(rank) as maximum_consecutive_patterns
from(
select id, u3_pattern, row_number() over (partition by u3_pattern, row_number - row_number2 order by id) as rank
from(
select distinct id, u3_pattern,
row_number() over (order by id) as row_number,
row_number() over (partition by u3_pattern order by id) as row_number2
from splits_overview_runner
where u3_pattern<>''-- and lrt_number<40
)
order by id)
group by 1
union
select krauser_pattern, max(rank) as maximum_consecutive_patterns
from(
select id, krauser_pattern, row_number() over (partition by krauser_pattern, row_number - row_number2 order by id) as rank
from(
select distinct id, krauser_pattern,
row_number() over (order by id) as row_number,
row_number() over (partition by krauser_pattern order by id) as row_number2
from splits_overview_runner
where krauser_pattern<>''-- and lrt_number<40
)
order by id)
group by 1
union
select war_room_pattern, max(rank) as maximum_consecutive_patterns
from(
select id, war_room_pattern, row_number() over (partition by war_room_pattern, row_number - row_number2 order by id) as rank
from(
select distinct id, war_room_pattern,
row_number() over (order by id) as row_number,
row_number() over (partition by war_room_pattern order by id) as row_number2
from splits_overview_runner
where war_room_pattern<>''-- and lrt_number<40
)
order by id)
group by 1
union
select key_card_pattern, max(rank) as maximum_consecutive_patterns
from(
select id, key_card_pattern, row_number() over (partition by key_card_pattern, row_number - row_number2 order by id) as rank
from(
select distinct id, key_card_pattern,
row_number() over (order by id) as row_number,
row_number() over (partition by key_card_pattern order by id) as row_number2
from splits_overview_runner
where key_card_pattern<>''-- and lrt_number<40
)
order by id)
group by 1

)
order by lago_pattern;

/* Script is finished, here we have some useful queries */

/* All chapter golds with doorsplits golds combined per chapter */

drop table if exists chapter_golds_sheet_runner;
create table chapter_golds_sheet_runner as
select a.chapter, a.id, a.date_started, a.final_lrt, a.pb, a.chapter_gold2,
case when cumulative_chapter_gold2<60 then (case when trunc(cumulative_chapter_gold2-trunc(cumulative_chapter_gold2), 3) =0 then
to_char(trunc(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'000'
when trunc(cumulative_chapter_gold2-trunc(cumulative_chapter_gold2), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then to_char(trunc(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'00'
when trunc(cumulative_chapter_gold2-trunc(cumulative_chapter_gold2), 3) in (select numb from decimals_table_runner)
then to_char(trunc(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'0'
else
to_char(trunc(cumulative_chapter_gold2, 3) % 60, 'FM00.999') end)
else (case when trunc(cumulative_chapter_gold2-trunc(cumulative_chapter_gold2), 3) =0
then floor(cumulative_chapter_gold2 / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'000'
when trunc(cumulative_chapter_gold2-trunc(cumulative_chapter_gold2), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then floor(cumulative_chapter_gold2 / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'00'
when trunc(cumulative_chapter_gold2-trunc(cumulative_chapter_gold2), 3) in (select numb from decimals_table_runner)
then floor(cumulative_chapter_gold2 / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'0'
else
floor(cumulative_chapter_gold2 / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold2, 3) % 60, 'FM00.999') end) end as doorsplit_combined_gold, cumulative_chapter_gold2 as doorsplit_combined_gold2, a.cumulative_chapter_gold,
cumulative_door_gold, cumulative_door_gold_num, avg_chapter_time2, chapter_gold_at_that_time as previous_chapter_gold
from chapter_golds3_runner a
left join (select chapter, sum(gold) as cumulative_chapter_gold2
		   from(
select chapter, a.gold, a.gold2, a.cle2, min(cumulative_door_gold) as cumulative_door_gold
from doorsplits_golds2_runner a
left join (select distinct cle2, chapter from splits_overview_runner) b on a.cle2=b.cle2
			   group by chapter, a.gold, a.gold2, a.cle2 order by a.cle2) b
		  group by chapter) bb on a.chapter=bb.chapter
left join (select *
		   from (select cle2, chapter, cumulative_door_gold, cumulative_door_gold_num, row_number() over(partition by chapter
order by cle2 desc) as rang from splits_overview_runner) a where rang=1) c on a.chapter=c.chapter
left join (select distinct id, chapter, chapter_gold_at_that_time
		   from splits_overview_runner where chapter_time2=chapter_gold2) d on a.chapter=d.chapter and a.id=d.id;

/* All section golds with doorsplits golds combined per section + chapter golds combined per section */

drop table if exists section_golds_sheet_runner;
create table section_golds_sheet_runner as
select a.section, a.id, a.date_started, a.final_lrt, a.pb, a.section_gold2,
case when trunc(cumulative_chapter_gold3-trunc(cumulative_chapter_gold3), 3)=0 then (case when cumulative_chapter_gold3>=3600 then
floor(cumulative_chapter_gold3 / 3600) || ':' || case when floor(cumulative_chapter_gold3 / 60)-(floor(cumulative_chapter_gold3/3600)*60)<10 then '0' else '' end ||
	  floor(cumulative_chapter_gold3 / 60)-(floor(cumulative_chapter_gold3/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold3, 3) % 60, 'FM00.999')||'000'
else floor(cumulative_chapter_gold3 / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold3, 3) % 60, 'FM00.999')||'000' end)
when trunc(cumulative_chapter_gold3-trunc(cumulative_chapter_gold3), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then (case when cumulative_chapter_gold3>=3600 then
floor(cumulative_chapter_gold3 / 3600) || ':' || case when floor(cumulative_chapter_gold3 / 60)-(floor(cumulative_chapter_gold3/3600)*60)<10 then '0' else '' end ||
	  floor(cumulative_chapter_gold3 / 60)-(floor(cumulative_chapter_gold3/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold3, 3) % 60, 'FM00.999')||'00'
else floor(cumulative_chapter_gold3 / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold3, 3) % 60, 'FM00.999')||'00' end)
when trunc(cumulative_chapter_gold3-trunc(cumulative_chapter_gold3), 3) in (select numb from decimals_table_runner)
then (case when cumulative_chapter_gold3>=3600 then
floor(cumulative_chapter_gold3 / 3600) || ':' || case when floor(cumulative_chapter_gold3 / 60)-(floor(cumulative_chapter_gold3/3600)*60)<10 then '0' else '' end ||
          floor(cumulative_chapter_gold3 / 60)-(floor(cumulative_chapter_gold3/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold3, 3) % 60, 'FM00.999')||'0'
else floor(cumulative_chapter_gold3 / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold3, 3) % 60, 'FM00.999')||'0' end)
else (case when cumulative_chapter_gold3>=3600 then
floor(cumulative_chapter_gold3 / 3600) || ':' || case when floor(cumulative_chapter_gold3 / 60)-(floor(cumulative_chapter_gold3/3600)*60)<10 then '0' else '' end ||
	  floor(cumulative_chapter_gold3 / 60)-(floor(cumulative_chapter_gold3/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold3, 3) % 60, 'FM00.999')
else floor(cumulative_chapter_gold3 / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold3, 3) % 60, 'FM00.999') end) end as chapter_combined_gold, cumulative_chapter_gold3 as chapter_combined_gold2,

case when trunc(cumulative_chapter_gold2-trunc(cumulative_chapter_gold2), 3)=0 then (case when cumulative_chapter_gold2>=3600 then
floor(cumulative_chapter_gold2 / 3600) || ':' || case when floor(cumulative_chapter_gold2 / 60)-(floor(cumulative_chapter_gold2/3600)*60)<10 then '0' else '' end ||
	  floor(cumulative_chapter_gold2 / 60)-(floor(cumulative_chapter_gold2/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'000'
else floor(cumulative_chapter_gold2 / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'000' end)
when trunc(cumulative_chapter_gold2-trunc(cumulative_chapter_gold2), 3) in (0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
then (case when cumulative_chapter_gold2>=3600 then
floor(cumulative_chapter_gold2 / 3600) || ':' || case when floor(cumulative_chapter_gold2 / 60)-(floor(cumulative_chapter_gold2/3600)*60)<10 then '0' else '' end ||
	  floor(cumulative_chapter_gold2 / 60)-(floor(cumulative_chapter_gold2/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'00'
else floor(cumulative_chapter_gold2 / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'00' end)
when trunc(cumulative_chapter_gold2-trunc(cumulative_chapter_gold2), 3) in (select numb from decimals_table_runner)
then (case when cumulative_chapter_gold2>=3600 then
floor(cumulative_chapter_gold2 / 3600) || ':' || case when floor(cumulative_chapter_gold2 / 60)-(floor(cumulative_chapter_gold2/3600)*60)<10 then '0' else '' end ||
          floor(cumulative_chapter_gold2 / 60)-(floor(cumulative_chapter_gold2/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'0'
else floor(cumulative_chapter_gold2 / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold2, 3) % 60, 'FM00.999')||'0' end)
else (case when cumulative_chapter_gold2>=3600 then
floor(cumulative_chapter_gold2 / 3600) || ':' || case when floor(cumulative_chapter_gold2 / 60)-(floor(cumulative_chapter_gold2/3600)*60)<10 then '0' else '' end ||
	  floor(cumulative_chapter_gold2 / 60)-(floor(cumulative_chapter_gold2/3600)*60) || ':' ||
to_char(trunc(cumulative_chapter_gold2, 3) % 60, 'FM00.999')
else floor(cumulative_chapter_gold2 / 60) || ':' ||
to_char(trunc(cumulative_chapter_gold2, 3) % 60, 'FM00.999') end) end as doorsplit_combined_gold, cumulative_chapter_gold2 as doorsplit_combined_gold2, a.cumulative_section_gold,
cumulative_chapter_gold, cumulative_chapter_gold_num, cumulative_door_gold, cumulative_door_gold_num, a.section_avg2, section_gold_at_that_time as previous_section_gold
from section_golds3_runner a
left join (select section, sum(gold) as cumulative_chapter_gold2
		   from(
select distinct section, a.gold, a.gold2, a.cle2
from doorsplits_golds2_runner a
left join (select distinct cle2, section from splits_overview_runner) b on a.cle2=b.cle2) b
		  group by section) bb on a.section=bb.section
left join (select *
		   from (select cle2, section, cumulative_door_gold, cumulative_door_gold_num, row_number() over(partition by section
order by cle2 desc) as rang from splits_overview_runner) a where rang=1) c on a.section=c.section

left join (select section, sum(chapter_gold) as cumulative_chapter_gold3
		   from(
select section, a.chapter_gold, a.chapter_gold2, a.chapter, min(cumulative_chapter_gold) as cumulative_chapter_gold
from chapter_golds3_runner a
left join (select distinct chapter, section from splits_overview_runner) b on a.chapter=b.chapter
			   group by section, a.chapter_gold, a.chapter_gold2, a.chapter order by a.chapter) b
		  group by section) d on a.section=d.section
left join (select *
		   from (select chapter, section, cumulative_chapter_gold, cumulative_chapter_gold_num, row_number() over(partition by section
order by chapter desc) as rang from splits_overview_runner) a where rang=1) e on a.section=e.section
left join (select distinct id, section, section_gold_at_that_time
		   from splits_overview_runner where section_time2=section_gold2) f on a.section=f.section and a.id=f.id
order by case when a.section='Village' then 1 when a.section='Castle' then 2 else 3 end;

/* Getting the history of PBs by the day of the week */

drop table if exists weekday_data_runner;
create table weekday_data_runner as
select a.*, golds, chapter_golds, section_golds, best_paces,
attempts/case when number_of_pbs=0 then null else number_of_pbs end as attempts_to_get_a_pb,
round((round(golds, 4)/round(attempts, 4))*100, 2)||'%' as golds_ratio,
round((round(chapter_golds, 4)/round(attempts, 4))*100, 2)||'%' as chapter_golds_ratio,
round((round(section_golds, 4)/round(attempts, 4))*100, 2)||'%' as section_golds_ratio,
round((round(best_paces, 4)/round(attempts, 4))*100, 2)||'%' as best_paces_ratio,
round(round(attempts, 2)/case when golds=0 then null else golds end, 2) as attempts_to_get_a_gold,
round(round(attempts, 2)/case when chapter_golds=0 then null else chapter_golds end, 2) as attempts_to_get_a_chapter_gold,
round(round(attempts, 2)/case when section_golds=0 then null else section_golds end, 2) as attempts_to_get_a_section_gold,
round(round(attempts, 2)/case when best_paces=0 then null else best_paces end, 2) as attempts_to_get_a_best_pace,
playtime/case when golds=0 then null else golds end as playtime_to_get_a_gold,
playtime/case when chapter_golds=0 then null else chapter_golds end as playtime_to_get_a_chapter_gold,
playtime/case when section_golds=0 then null else section_golds end as playtime_to_get_a_section_gold,
playtime/case when best_paces=0 then null else best_paces end as playtime_to_get_a_best_pace
from (select case when extract(dow from date_started)=0 then 7 else extract(dow from date_started) end as weekday,
sum(playtime) as playtime, count(distinct id) as attempts, count(distinct case when pb=1 then id else null end) as number_of_pbs,
round(round(round(count(distinct case when pb=1 then id else null end), 4)/round(count(distinct id), 4), 4)*100, 2)||'%' as pb_ratio,
round(sum(playtime))/case when round(count(distinct case when pb=1 then id else null end))=0 then null else
round(count(distinct case when pb=1 then id else null end)) end playtime_to_get_a_pb
from attempts_treatment3_runner
group by 1) a
left join (
select case when extract(dow from date_started)=0 then 7 else extract(dow from date_started) end as weekday, sum(golded_split) as golds,
sum(golded_chapter) as chapter_golds, sum(golded_section) as section_golds, sum(was_best_pace) as best_paces
from splits_overview_runner
group by 1) b on a.weekday=b.weekday
order by a.weekday;
