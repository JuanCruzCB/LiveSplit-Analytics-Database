/* Chapter golds */

drop table if exists global_chapter_golds;
create table global_chapter_golds as
select *
from (select *
from (
select a.chapter, a.chapter_gold2 as sawken, b.chapter_gold2 as luis, c.chapter_gold2 as joker, d.chapter_gold2 as mateo,
e.chapter_gold2 as arcadan, f.chapter_gold2 as richy, g.chapter_gold2 as derek, h.chapter_gold2 as nevs, i.chapter_gold2 as otaku, j.chapter_gold2 as pocho, k.chapter_gold2 as missing
from chapter_golds2_sawken a
left join chapter_golds2_luis b on a.chapter=b.chapter
left join chapter_golds2_joker c on a.chapter=c.chapter
left join chapter_golds2_mateo d on a.chapter=d.chapter
left join chapter_golds2_arcadan e on a.chapter=e.chapter
left join chapter_golds2_richy f on a.chapter=f.chapter
left join chapter_golds2_derek g on a.chapter=g.chapter
left join chapter_golds2_nevs h on a.chapter=h.chapter
left join chapter_golds2_otaku i on a.chapter=i.chapter
left join chapter_golds2_pocho j on a.chapter=j.chapter
left join chapter_golds2_missing k on a.chapter=k.chapter
union
select 'Total' as chapter, a.cumulative_chapter_gold as sawken, b.cumulative_chapter_gold as luis, c.cumulative_chapter_gold as joker,
d.cumulative_chapter_gold as mateo, e.cumulative_chapter_gold as arcadan, f.cumulative_chapter_gold as richy,
g.cumulative_chapter_gold as derek, h.cumulative_chapter_gold as nevs, i.cumulative_chapter_gold as otaku, j.cumulative_chapter_gold as pocho, k.cumulative_chapter_gold as missing
from chapter_golds3_sawken a
left join chapter_golds3_luis b on a.chapter=b.chapter
left join chapter_golds3_joker c on a.chapter=c.chapter
left join chapter_golds3_mateo d on a.chapter=d.chapter
left join chapter_golds3_arcadan e on a.chapter=e.chapter
left join chapter_golds3_richy f on a.chapter=f.chapter
left join chapter_golds3_derek g on a.chapter=g.chapter
left join chapter_golds3_nevs h on a.chapter=h.chapter
left join chapter_golds3_otaku i on a.chapter=i.chapter
left join chapter_golds3_pocho j on a.chapter=j.chapter
left join chapter_golds3_missing k on a.chapter=k.chapter
where a.chapter='6-1'
union
select 'Last update' as chapter, *
from (select cast(max(date_started) as varchar) as sawken from attempts_treatment3_sawken) a
cross join (select cast(max(date_started) as varchar) as luis from attempts_treatment3_luis) b
cross join (select cast(max(date_started) as varchar) as joker from attempts_treatment3_joker) c
cross join (select cast(max(date_started) as varchar) as mateo from attempts_treatment3_mateo) d
cross join (select cast(max(date_started) as varchar) as arcadan from attempts_treatment3_arcadan) e
cross join (select cast(max(date_started) as varchar) as richy from attempts_treatment3_richy) f
cross join (select cast(max(date_started) as varchar) as derek from attempts_treatment3_derek) g
cross join (select cast(max(date_started) as varchar) as nevs from attempts_treatment3_nevs) h
cross join (select cast(max(date_started) as varchar) as otaku from attempts_treatment3_otaku) i
cross join (select cast(max(date_started) as varchar) as pocho from attempts_treatment3_pocho) j
cross join (select cast(max(date_started) as varchar) as missing from attempts_treatment3_missing) k
union
select 'PB' as chapter, *
from (select lrt_pb as sawken
      from(select *, row_number() over (order by date_started desc, pb_lrt) as rang
           from pb_history_sawken) aa
           where rang=1) a
cross join (select lrt_pb as luis
      from(select *, row_number() over (order by date_started desc, pb_lrt) as rang
           from pb_history_luis) aa
           where rang=1) b
cross join (select lrt_pb as joker
      from(select *, row_number() over (order by date_started desc, pb_lrt) as rang
           from pb_history_joker) aa
           where rang=1) c
cross join (select lrt_pb as mateo
      from(select *, row_number() over (order by date_started desc, pb_lrt) as rang
           from pb_history_mateo) aa
           where rang=1) d
cross join (select lrt_pb as arcadan
      from(select *, row_number() over (order by date_started desc, pb_lrt) as rang
           from pb_history_arcadan) aa
           where rang=1) e
cross join (select lrt_pb as richy
      from(select *, row_number() over (order by date_started desc, pb_lrt) as rang
           from pb_history_richy) aa
           where rang=1) f
cross join (select lrt_pb as derek
      from(select *, row_number() over (order by date_started desc, pb_lrt) as rang
           from pb_history_derek) aa
           where rang=1) g
cross join (select lrt_pb as nevs
      from(select *, row_number() over (order by date_started desc, pb_lrt) as rang
           from pb_history_nevs) aa
           where rang=1) h
cross join (select lrt_pb as otaku
      from(select *, row_number() over (order by date_started desc, pb_lrt) as rang
           from pb_history_otaku) aa
           where rang=1) i
cross join (select lrt_pb as pocho
      from(select *, row_number() over (order by date_started desc, pb_lrt) as rang
           from pb_history_pocho) aa
           where rang=1) j
cross join (select lrt_pb as missing
      from(select *, row_number() over (order by date_started desc, pb_lrt) as rang
           from pb_history_missing) aa
           where rang=1) k) z
union (select 'Attempts' as chapter, *
from
(select cast(max(id)-84 as varchar) as sawken from attempts_treatment3_sawken)
cross join (select cast(max(id)as varchar) as luis from attempts_treatment3_luis)
cross join (select cast(max(id)as varchar) as joker from attempts_treatment3_joker)
cross join (select cast(max(id)as varchar) as mateo from attempts_treatment3_mateo)
cross join (select cast(max(id)as varchar) as arcadan from attempts_treatment3_arcadan)
cross join (select cast(max(id)-3912 as varchar) as richy from attempts_treatment3_richy)
cross join (select cast(max(id) as varchar) as derek from attempts_treatment3_derek)
cross join (select cast(max(id) as varchar) as nevs from attempts_treatment3_nevs)
cross join (select cast(max(id)-4779 as varchar) as otaku from attempts_treatment3_otaku)
cross join (select cast(max(id) as varchar) as pocho from attempts_treatment3_pocho)
cross join (select cast(max(id) as varchar) as missing from attempts_treatment3_missing))
union(
select 'Total playtime' as chapter, *
from
(select cast(sum(playtime) as varchar) as sawken from attempts_treatment3_sawken)
cross join (select cast(sum(playtime) as varchar) as luis from attempts_treatment3_luis)
cross join (select cast(sum(playtime) as varchar) as joker from attempts_treatment3_joker)
cross join (select cast(sum(playtime) as varchar) as mateo from attempts_treatment3_mateo)
cross join (select cast(sum(playtime) as varchar) as arcadan from attempts_treatment3_arcadan)
cross join (select cast(sum(playtime) as varchar) as richy from attempts_treatment3_richy)
cross join (select cast(sum(playtime) as varchar) as derek from attempts_treatment3_derek)
cross join (select cast(sum(playtime) as varchar) as nevs from attempts_treatment3_nevs)
cross join (select cast(sum(playtime) as varchar) as otaku from attempts_treatment3_otaku)
cross join (select cast(sum(playtime) as varchar) as pocho from attempts_treatment3_pocho)
cross join (select cast(sum(playtime) as varchar) as missing from attempts_treatment3_missing))) z
order by case when chapter not in ('Last update', 'Total', 'PB', 'Attempts', 'Total playtime') then 1 when chapter='Total' then 2 when chapter='Last update' then 3 when chapter='PB' then 4
when chapter='Attempts' then 5 else 6 end, chapter;

/* Chapter golds by door golds */

drop table if exists global_chapter_golds_doors;
create table global_chapter_golds_doors as
select distinct a.chapter, a.doorsplit_combined_gold as sawken, b.doorsplit_combined_gold as luis, c.doorsplit_combined_gold as joker, d.doorsplit_combined_gold as mateo, e.doorsplit_combined_gold as arcadan,
f.doorsplit_combined_gold as richy, g.doorsplit_combined_gold as derek, h.doorsplit_combined_gold as nevs, i.doorsplit_combined_gold as otaku, j.doorsplit_combined_gold as pocho,
k.doorsplit_combined_gold as missing
from chapter_golds_sheet_sawken a
left join chapter_golds_sheet_luis b on a.chapter=b.chapter
left join chapter_golds_sheet_joker c on a.chapter=c.chapter
left join chapter_golds_sheet_mateo d on a.chapter=d.chapter
left join chapter_golds_sheet_arcadan e on a.chapter=e.chapter
left join chapter_golds_sheet_richy f on a.chapter=f.chapter
left join chapter_golds_sheet_derek g on a.chapter=g.chapter
left join chapter_golds_sheet_nevs h on a.chapter=h.chapter
left join chapter_golds_sheet_otaku i on a.chapter=i.chapter
left join chapter_golds_sheet_pocho j on a.chapter=j.chapter
left join chapter_golds_sheet_missing k on a.chapter=k.chapter
union
select distinct 'Total' as chapter, a.cumulative_door_gold as sawken, b.cumulative_door_gold as luis, c.cumulative_door_gold as joker, d.cumulative_door_gold as mateo, e.cumulative_door_gold as arcadan,
f.cumulative_door_gold as richy, g.cumulative_door_gold as derek, h.cumulative_door_gold as nevs, i.cumulative_door_gold as otaku, j.cumulative_door_gold as pocho, k.cumulative_door_gold as missing
from chapter_golds_sheet_sawken a
left join chapter_golds_sheet_luis b on a.chapter=b.chapter
left join chapter_golds_sheet_joker c on a.chapter=c.chapter
left join chapter_golds_sheet_mateo d on a.chapter=d.chapter
left join chapter_golds_sheet_arcadan e on a.chapter=e.chapter
left join chapter_golds_sheet_richy f on a.chapter=f.chapter
left join chapter_golds_sheet_derek g on a.chapter=g.chapter
left join chapter_golds_sheet_nevs h on a.chapter=h.chapter
left join chapter_golds_sheet_otaku i on a.chapter=i.chapter
left join chapter_golds_sheet_pocho j on a.chapter=j.chapter
left join chapter_golds_sheet_missing k on a.chapter=k.chapter
where a.chapter='6-1'
order by 1;

/* Best paces (at the end of each chapter only) */

drop table if exists global_best_paces_chapter;
create table global_best_paces_chapter as
select case when substr(b.split, 2, 3)='End' then '6-1' else substr(b.split, 2, 3) end as chapter, a.best_pace2 as sawken, b.best_pace2 as luis, c.best_pace2 as joker, d.best_pace2 as mateo,
e.best_pace2 as arcadan, f.best_pace2 as richy, g.best_pace2 as derek, h.best_pace2 as nevs, i.best_pace2 as otaku, j.best_pace2 as pocho, k.best_pace2 as missing
from (select distinct cle2, split, best_pace2, best_pace from best_paces_sawken) a
left join (select distinct cle2, split, best_pace2, best_pace from best_paces_luis) b on a.cle2=b.cle2
left join (select distinct cle2, split, best_pace2, best_pace from best_paces_joker) c on a.cle2=c.cle2
left join (select distinct cle2, split, best_pace2, best_pace from best_paces_mateo) d on a.cle2=d.cle2
left join (select distinct cle2, split, best_pace2, best_pace from best_paces_arcadan) e on a.cle2=e.cle2
left join (select distinct cle2, split, best_pace2, best_pace from best_paces_richy) f on a.cle2=f.cle2
left join (select distinct cle2, split, best_pace2, best_pace from best_paces_derek) g on a.cle2=g.cle2
left join (select distinct cle2, split, best_pace2, best_pace from best_paces_nevs) h on a.cle2=h.cle2
left join (select distinct cle2, split, best_pace2, best_pace from best_paces_otaku) i on a.cle2=i.cle2
left join (select distinct cle2, split, best_pace2, best_pace from best_paces_pocho) j on a.cle2=j.cle2
left join (select distinct cle2, split, best_pace2, best_pace from best_paces_missing) k on a.cle2=k.cle2
where a.split like '%{%'
order by a.cle2;

/* Door golds */

drop table if exists global_door_golds;
create table global_door_golds as
select split, sawken, luis, joker, mateo, arcadan, richy, derek, nevs, otaku, pocho, missing
from
(select *
from
(select b.split, a.gold2 as sawken, b.gold2 as luis, c.gold2 as joker, d.gold2 as mateo, e.gold2 as arcadan,
f.gold2 as richy, g.gold2 as derek, h.gold2 as nevs, i.gold2 as otaku, j.gold2 as pocho, k.gold2 as missing, row_number() over (order by a.cle2) as rang
from (select distinct cle2, split, gold2, gold from doorsplits_golds_sawken) a
left join (select distinct cle2, split, gold2, gold from doorsplits_golds_luis) b on a.cle2=b.cle2
left join (select distinct cle2, split, gold2, gold from doorsplits_golds_joker) c on a.cle2=c.cle2
left join (select distinct cle2, split, gold2, gold from doorsplits_golds_mateo) d on a.cle2=d.cle2
left join (select distinct cle2, split, gold2, gold from doorsplits_golds_arcadan) e on a.cle2=e.cle2
left join (select distinct cle2, split, gold2, gold from doorsplits_golds_richy) f on a.cle2=f.cle2
left join (select distinct cle2, split, gold2, gold from doorsplits_golds_derek) g on a.cle2=g.cle2
left join (select distinct cle2, split, gold2, gold from doorsplits_golds_nevs) h on a.cle2=h.cle2
left join (select distinct cle2, split, gold2, gold from doorsplits_golds_otaku) i on a.cle2=i.cle2
left join (select distinct cle2, split, gold2, gold from doorsplits_golds_pocho) j on a.cle2=j.cle2
left join (select distinct cle2, split, gold2, gold from doorsplits_golds_missing) k on a.cle2=k.cle2)
union
(select 'Total' as split, a.cumulative_door_gold as sawken, b.cumulative_door_gold as luis, c.cumulative_door_gold as joker,
d.cumulative_door_gold as mateo, e.cumulative_door_gold as arcadan, f.cumulative_door_gold as richy,
g.cumulative_door_gold as derek, h.cumulative_door_gold as nevs, i.cumulative_door_gold as otaku, j.cumulative_door_gold as pocho, k.cumulative_door_gold as missing, 124 as rang
from doorsplits_golds2_sawken a
left join doorsplits_golds2_luis b on a.cle2=b.cle2
left join doorsplits_golds2_joker c on a.cle2=c.cle2
left join doorsplits_golds2_mateo d on a.cle2=d.cle2
left join doorsplits_golds2_arcadan e on a.cle2=e.cle2
left join doorsplits_golds2_richy f on a.cle2=f.cle2
left join doorsplits_golds2_derek g on a.cle2=g.cle2
left join doorsplits_golds2_nevs h on a.cle2=h.cle2
left join doorsplits_golds2_otaku i on a.cle2=i.cle2
left join doorsplits_golds2_pocho j on a.cle2=j.cle2
left join doorsplits_golds2_missing k on a.cle2=k.cle2
where a.cle2=123))
order by rang;

/* Section golds */

drop table if exists global_section_golds;
create table global_section_golds as
select section, sawken, luis, joker, mateo, arcadan, richy, derek, nevs, otaku, pocho, missing
from(
select *
from
(select a.section, a.section_gold2 as sawken, b.section_gold2 as luis, c.section_gold2 as joker, d.section_gold2 as mateo,
e.section_gold2 as arcadan, f.section_gold2 as richy, g.section_gold2 as derek, h.section_gold2 as nevs, i.section_gold2 as otaku, j.section_gold2 as pocho, k.section_gold2 as missing,
case when a.section='Village' then 1 when a.section='Castle' then 2 else 3 end as rang
from section_golds2_sawken a
left join section_golds2_luis b on a.section=b.section
left join section_golds2_joker c on a.section=c.section
left join section_golds2_mateo d on a.section=d.section
left join section_golds2_arcadan e on a.section=e.section
left join section_golds2_richy f on a.section=f.section
left join section_golds2_derek g on a.section=g.section
left join section_golds2_nevs h on a.section=h.section
left join section_golds2_otaku i on a.section=i.section
left join section_golds2_pocho j on a.section=j.section
left join section_golds2_missing k on a.section=k.section)
union
(select 'Total' as section, a.cumulative_section_gold as sawken, b.cumulative_section_gold as luis, c.cumulative_section_gold as joker,
d.cumulative_section_gold as mateo, e.cumulative_section_gold as arcadan, f.cumulative_section_gold as richy,
g.cumulative_section_gold as derek, h.cumulative_section_gold as nevs, i.cumulative_section_gold as otaku, j.cumulative_section_gold as pocho, k.cumulative_section_gold as missing, 4 as rang
from section_golds3_sawken a
left join section_golds3_luis b on a.section=b.section
left join section_golds3_joker c on a.section=c.section
left join section_golds3_mateo d on a.section=d.section
left join section_golds3_arcadan e on a.section=e.section
left join section_golds3_richy f on a.section=f.section
left join section_golds3_derek g on a.section=g.section
left join section_golds3_nevs h on a.section=h.section
left join section_golds3_otaku i on a.section=i.section
left join section_golds3_pocho j on a.section=j.section
left join section_golds3_missing k on a.section=k.section
where a.section='Island'))
order by rang;

/* Section golds by door golds */

drop table if exists global_section_golds_doors;
create table global_section_golds_doors as
select *
from(select distinct a.section, a.doorsplit_combined_gold as sawken, b.doorsplit_combined_gold as luis, c.doorsplit_combined_gold as joker, d.doorsplit_combined_gold as mateo, e.doorsplit_combined_gold as arcadan,
f.doorsplit_combined_gold as richy, g.doorsplit_combined_gold as derek, h.doorsplit_combined_gold as nevs, i.doorsplit_combined_gold as otaku, j.doorsplit_combined_gold as pocho,
k.doorsplit_combined_gold as missing
from section_golds_sheet_sawken a
left join section_golds_sheet_luis b on a.section=b.section
left join section_golds_sheet_joker c on a.section=c.section
left join section_golds_sheet_mateo d on a.section=d.section
left join section_golds_sheet_arcadan e on a.section=e.section
left join section_golds_sheet_richy f on a.section=f.section
left join section_golds_sheet_derek g on a.section=g.section
left join section_golds_sheet_nevs h on a.section=h.section
left join section_golds_sheet_otaku i on a.section=i.section
left join section_golds_sheet_pocho j on a.section=j.section
left join section_golds_sheet_missing k on a.section=k.section
union
select distinct 'Total' as section, a.cumulative_door_gold as sawken, b.cumulative_door_gold as luis, c.cumulative_door_gold as joker, d.cumulative_door_gold as mateo, e.cumulative_door_gold as arcadan,
f.cumulative_door_gold as richy, g.cumulative_door_gold as derek, h.cumulative_door_gold as nevs, i.cumulative_door_gold as otaku, j.cumulative_door_gold as pocho, k.cumulative_door_gold as missing
from section_golds_sheet_sawken a
left join section_golds_sheet_luis b on a.section=b.section
left join section_golds_sheet_joker c on a.section=c.section
left join section_golds_sheet_mateo d on a.section=d.section
left join section_golds_sheet_arcadan e on a.section=e.section
left join section_golds_sheet_richy f on a.section=f.section
left join section_golds_sheet_derek g on a.section=g.section
left join section_golds_sheet_nevs h on a.section=h.section
left join section_golds_sheet_otaku i on a.section=i.section
left join section_golds_sheet_pocho j on a.section=j.section
left join section_golds_sheet_missing k on a.section=k.section
where a.section='Island') a
order by case when a.section='Village' then 1 when a.section='Castle' then 2 when a.section='Island' then 3 else 4 end;

/* Section golds by chapter golds */

drop table if exists global_section_golds_chapters;
create table global_section_golds_chapters as
select *
from (
select distinct a.section, a.chapter_combined_gold as sawken, b.chapter_combined_gold as luis, c.chapter_combined_gold as joker, d.chapter_combined_gold as mateo, e.chapter_combined_gold as arcadan,
f.chapter_combined_gold as richy, g.chapter_combined_gold as derek, h.chapter_combined_gold as nevs, i.chapter_combined_gold as otaku, j.chapter_combined_gold as pocho, k.chapter_combined_gold as missing
from section_golds_sheet_sawken a
left join section_golds_sheet_luis b on a.section=b.section
left join section_golds_sheet_joker c on a.section=c.section
left join section_golds_sheet_mateo d on a.section=d.section
left join section_golds_sheet_arcadan e on a.section=e.section
left join section_golds_sheet_richy f on a.section=f.section
left join section_golds_sheet_derek g on a.section=g.section
left join section_golds_sheet_nevs h on a.section=h.section
left join section_golds_sheet_otaku i on a.section=i.section
left join section_golds_sheet_pocho j on a.section=j.section
left join section_golds_sheet_missing k on a.section=k.section
union
select distinct 'Total' as section, a.cumulative_chapter_gold as sawken, b.cumulative_chapter_gold as luis, c.cumulative_chapter_gold as joker, d.cumulative_chapter_gold as mateo, e.cumulative_chapter_gold as arcadan,
f.cumulative_chapter_gold as richy, g.cumulative_chapter_gold as derek, h.cumulative_chapter_gold as nevs, i.cumulative_chapter_gold as otaku, j.cumulative_chapter_gold as pocho, k.cumulative_chapter_gold as missing
from section_golds_sheet_sawken a
left join section_golds_sheet_luis b on a.section=b.section
left join section_golds_sheet_joker c on a.section=c.section
left join section_golds_sheet_mateo d on a.section=d.section
left join section_golds_sheet_arcadan e on a.section=e.section
left join section_golds_sheet_richy f on a.section=f.section
left join section_golds_sheet_derek g on a.section=g.section
left join section_golds_sheet_nevs h on a.section=h.section
left join section_golds_sheet_otaku i on a.section=i.section
left join section_golds_sheet_pocho j on a.section=j.section
left join section_golds_sheet_missing k on a.section=k.section
where a.section='Island') a
order by case when a.section='Village' then 1 when a.section='Castle' then 2 when a.section='Island' then 3 else 4 end;

/* Percentage by pattern (for example % of early dives, late dives, etc.) and number of consecutive patterns in a row (for example
number of early dives in a row) */

drop table if exists global_rng_patterns;
create table global_rng_patterns as
select z.pattern, coalesce(round(cast(a.percentage as numeric), 2), 0) as percent_sawken,
coalesce(round(cast(b.percentage as numeric), 2), 0) as percent_luis, coalesce(round(cast(c.percentage as numeric), 2), 0) as percent_joker,
coalesce(round(cast(d.percentage as numeric), 2), 0) as percent_mateo, coalesce(round(cast(e.percentage as numeric), 2), 0) as percent_arcadan,
coalesce(round(cast(f.percentage as numeric), 2), 0) as percent_richy, coalesce(round(cast(g.percentage as numeric), 2), 0) as percent_derek,
coalesce(round(cast(h.percentage as numeric), 2), 0) as percent_nevs, coalesce(round(cast(i.percentage as numeric), 2), 0) as percent_otaku,
coalesce(round(cast(j.percentage as numeric), 2), 0) as percent_pocho, coalesce(round(cast(k.percentage as numeric), 2), 0) as percent_missing,
coalesce(a1.maximum_consecutive_patterns, 0) as max_in_a_row_sawken, coalesce(b1.maximum_consecutive_patterns, 0) as max_in_a_row_luis,
coalesce(c1.maximum_consecutive_patterns, 0) as max_in_a_row_joker, coalesce(d1.maximum_consecutive_patterns, 0) as max_in_a_row_mateo,
coalesce(e1.maximum_consecutive_patterns, 0) as max_in_a_row_arcadan, coalesce(f1.maximum_consecutive_patterns, 0) as max_in_a_row_richy,
coalesce(g1.maximum_consecutive_patterns, 0) as max_in_a_row_derek, coalesce(h1.maximum_consecutive_patterns, 0) as max_in_a_row_nevs,
coalesce(i1.maximum_consecutive_patterns, 0) as max_in_a_row_otaku, coalesce(j1.maximum_consecutive_patterns, 0) as max_in_a_row_pocho,
coalesce(k1.maximum_consecutive_patterns, 0) as max_in_a_row_missing
from rng z
left join rng_splits_sawken a on z.pattern=a.pattern
left join rng_splits_luis b on z.pattern=b.pattern
left join rng_splits_joker c on z.pattern=c.pattern
left join rng_splits_mateo d on z.pattern=d.pattern
left join rng_splits_arcadan e on z.pattern=e.pattern
left join rng_splits_richy f on z.pattern=f.pattern
left join rng_splits_derek g on z.pattern=g.pattern
left join rng_splits_nevs h on z.pattern=h.pattern
left join rng_splits_otaku i on z.pattern=i.pattern
left join rng_splits_pocho j on z.pattern=j.pattern
left join rng_splits_missing k on z.pattern=k.pattern
left join consecutive_patterns_sawken a1 on z.pattern=a1.lago_pattern
left join consecutive_patterns_luis b1 on z.pattern=b1.lago_pattern
left join consecutive_patterns_joker c1 on z.pattern=c1.lago_pattern
left join consecutive_patterns_mateo d1 on z.pattern=d1.lago_pattern
left join consecutive_patterns_arcadan e1 on z.pattern=e1.lago_pattern
left join consecutive_patterns_richy f1 on z.pattern=f1.lago_pattern
left join consecutive_patterns_derek g1 on z.pattern=g1.lago_pattern
left join consecutive_patterns_nevs h1 on z.pattern=h1.lago_pattern
left join consecutive_patterns_otaku i1 on z.pattern=i1.lago_pattern
left join consecutive_patterns_pocho j1 on z.pattern=j1.lago_pattern
left join consecutive_patterns_missing k1 on z.pattern=k1.lago_pattern
order by z.pattern;

/* Percentage of resets after each split */

drop table if exists global_resets;
create table global_resets as
select b.split, round(cast(a.percentage_resets as numeric), 2) as percent_sawken,
round(cast(b.percentage_resets as numeric), 2) as percent_luis, round(cast(c.percentage_resets as numeric), 2) as percent_joker,
round(cast(d.percentage_resets as numeric), 2) as percent_mateo, round(cast(e.percentage_resets as numeric), 2) as percent_arcadan,
round(cast(f.percentage_resets as numeric), 2) as percent_richy, round(cast(g.percentage_resets as numeric), 2) as percent_derek,
round(cast(h.percentage_resets as numeric), 2) as percent_nevs, round(cast(i.percentage_resets as numeric), 2) as percent_otaku,
round(cast(j.percentage_resets as numeric), 2) as percent_pocho, round(cast(k.percentage_resets as numeric), 2) as percent_missing
from resets_history2_sawken a
left join resets_history2_luis b on a.cle2=b.cle2
left join resets_history2_joker c on a.cle2=c.cle2
left join resets_history2_mateo d on a.cle2=d.cle2
left join resets_history2_arcadan e on a.cle2=e.cle2
left join resets_history2_richy f on a.cle2=f.cle2
left join resets_history2_derek g on a.cle2=g.cle2
left join resets_history2_nevs h on a.cle2=h.cle2
left join resets_history2_otaku i on a.cle2=i.cle2
left join resets_history2_pocho j on a.cle2=j.cle2
left join resets_history2_missing k on a.cle2=k.cle2
where a.percentage_resets<>0 or b.percentage_resets<>0 or c.percentage_resets<>0 or d.percentage_resets<>0 or e.percentage_resets<>0 or
f.percentage_resets<>0 or g.percentage_resets<>0 or h.percentage_resets<>0 or i.percentage_resets<>0 or j.percentage_resets<>0 or k.percentage_resets<>0;

/* Weekday data */

drop table if exists global_weekday_data;
create table global_weekday_data as
select case when weekday=1 then 'Monday' when weekday=2 then 'Tuesday' when weekday=3 then 'Wednesday' when weekday=4 then 'Thursday' when weekday=5 then 'Friday' when weekday=6 then 'Saturday' when weekday=7 then 'Sunday' else '' end as
day, col, sawken, luis, joker, mateo, arcadan, richy, derek, nevs, otaku, pocho, missing
from (select a.weekday, 'a' as col2, 'Attempts to get a PB' as col, sawken, luis, joker, mateo, arcadan, richy, derek, nevs, otaku, pocho, missing
from (select weekday, attempts_to_get_a_pb as sawken
from weekday_data_sawken) a
left join (select weekday, attempts_to_get_a_pb as luis
from weekday_data_luis) b on a.weekday=b.weekday
left join (select weekday, attempts_to_get_a_pb as joker
from weekday_data_joker) c on a.weekday=c.weekday
left join (select weekday, attempts_to_get_a_pb as mateo
from weekday_data_mateo) d on a.weekday=d.weekday
left join (select weekday, attempts_to_get_a_pb as arcadan
from weekday_data_arcadan) e on a.weekday=e.weekday
left join (select weekday, attempts_to_get_a_pb as richy
from weekday_data_richy) f on a.weekday=f.weekday
left join (select weekday, attempts_to_get_a_pb as derek
from weekday_data_derek) g on a.weekday=g.weekday
left join (select weekday, attempts_to_get_a_pb as nevs
from weekday_data_nevs) h on a.weekday=h.weekday
left join (select weekday, attempts_to_get_a_pb as otaku
from weekday_data_otaku) i on a.weekday=i.weekday
left join (select weekday, attempts_to_get_a_pb as pocho
from weekday_data_pocho) j on a.weekday=j.weekday
left join (select weekday, attempts_to_get_a_pb as missing
from weekday_data_missing) k on a.weekday=k.weekday

union

select a.weekday, 'b' as col2, 'Playtime to get a PB' as col, sawken, luis, joker, mateo, arcadan, richy, derek, nevs, otaku, pocho, missing
from (select weekday, playtime_to_get_a_pb as sawken
from weekday_data_sawken) a
left join (select weekday, playtime_to_get_a_pb as luis
from weekday_data_luis) b on a.weekday=b.weekday
left join (select weekday, playtime_to_get_a_pb as joker
from weekday_data_joker) c on a.weekday=c.weekday
left join (select weekday, playtime_to_get_a_pb as mateo
from weekday_data_mateo) d on a.weekday=d.weekday
left join (select weekday, playtime_to_get_a_pb as arcadan
from weekday_data_arcadan) e on a.weekday=e.weekday
left join (select weekday, playtime_to_get_a_pb as richy
from weekday_data_richy) f on a.weekday=f.weekday
left join (select weekday, playtime_to_get_a_pb as derek
from weekday_data_derek) g on a.weekday=g.weekday
left join (select weekday, playtime_to_get_a_pb as nevs
from weekday_data_nevs) h on a.weekday=h.weekday
left join (select weekday, playtime_to_get_a_pb as otaku
from weekday_data_otaku) i on a.weekday=i.weekday
left join (select weekday, playtime_to_get_a_pb as pocho
from weekday_data_pocho) j on a.weekday=j.weekday
left join (select weekday, playtime_to_get_a_pb as missing
from weekday_data_missing) k on a.weekday=k.weekday

union

select a.weekday, 'c' as col2, 'Attempts to get a gold' as col, sawken, luis, joker, mateo, arcadan, richy, derek, nevs, otaku, pocho, missing
from (select weekday, attempts_to_get_a_gold as sawken
from weekday_data_sawken) a
left join (select weekday, attempts_to_get_a_gold as luis
from weekday_data_luis) b on a.weekday=b.weekday
left join (select weekday, attempts_to_get_a_gold as joker
from weekday_data_joker) c on a.weekday=c.weekday
left join (select weekday, attempts_to_get_a_gold as mateo
from weekday_data_mateo) d on a.weekday=d.weekday
left join (select weekday, attempts_to_get_a_gold as arcadan
from weekday_data_arcadan) e on a.weekday=e.weekday
left join (select weekday, attempts_to_get_a_gold as richy
from weekday_data_richy) f on a.weekday=f.weekday
left join (select weekday, attempts_to_get_a_gold as derek
from weekday_data_derek) g on a.weekday=g.weekday
left join (select weekday, attempts_to_get_a_gold as nevs
from weekday_data_nevs) h on a.weekday=h.weekday
left join (select weekday, attempts_to_get_a_gold as otaku
from weekday_data_otaku) i on a.weekday=i.weekday
left join (select weekday, attempts_to_get_a_gold as pocho
from weekday_data_pocho) j on a.weekday=j.weekday
left join (select weekday, attempts_to_get_a_gold as missing
from weekday_data_missing) k on a.weekday=k.weekday

union

select a.weekday, 'd' as col2, 'Playtime to get a gold' as col, sawken, luis, joker, mateo, arcadan, richy, derek, nevs, otaku, pocho, missing
from (select weekday, playtime_to_get_a_gold as sawken
from weekday_data_sawken) a
left join (select weekday, playtime_to_get_a_gold as luis
from weekday_data_luis) b on a.weekday=b.weekday
left join (select weekday, playtime_to_get_a_gold as joker
from weekday_data_joker) c on a.weekday=c.weekday
left join (select weekday, playtime_to_get_a_gold as mateo
from weekday_data_mateo) d on a.weekday=d.weekday
left join (select weekday, playtime_to_get_a_gold as arcadan
from weekday_data_arcadan) e on a.weekday=e.weekday
left join (select weekday, playtime_to_get_a_gold as richy
from weekday_data_richy) f on a.weekday=f.weekday
left join (select weekday, playtime_to_get_a_gold as derek
from weekday_data_derek) g on a.weekday=g.weekday
left join (select weekday, playtime_to_get_a_gold as nevs
from weekday_data_nevs) h on a.weekday=h.weekday
left join (select weekday, playtime_to_get_a_gold as otaku
from weekday_data_otaku) i on a.weekday=i.weekday
left join (select weekday, playtime_to_get_a_gold as pocho
from weekday_data_pocho) j on a.weekday=j.weekday
left join (select weekday, playtime_to_get_a_gold as missing
from weekday_data_missing) k on a.weekday=k.weekday

union

select a.weekday, 'e' as col2, 'Attempts to get a chapter gold' as col, sawken, luis, joker, mateo, arcadan, richy, derek, nevs, otaku, pocho, missing
from (select weekday, attempts_to_get_a_chapter_gold as sawken
from weekday_data_sawken) a
left join (select weekday, attempts_to_get_a_chapter_gold as luis
from weekday_data_luis) b on a.weekday=b.weekday
left join (select weekday, attempts_to_get_a_chapter_gold as joker
from weekday_data_joker) c on a.weekday=c.weekday
left join (select weekday, attempts_to_get_a_chapter_gold as mateo
from weekday_data_mateo) d on a.weekday=d.weekday
left join (select weekday, attempts_to_get_a_chapter_gold as arcadan
from weekday_data_arcadan) e on a.weekday=e.weekday
left join (select weekday, attempts_to_get_a_chapter_gold as richy
from weekday_data_richy) f on a.weekday=f.weekday
left join (select weekday, attempts_to_get_a_chapter_gold as derek
from weekday_data_derek) g on a.weekday=g.weekday
left join (select weekday, attempts_to_get_a_chapter_gold as nevs
from weekday_data_nevs) h on a.weekday=h.weekday
left join (select weekday, attempts_to_get_a_chapter_gold as otaku
from weekday_data_otaku) i on a.weekday=i.weekday
left join (select weekday, attempts_to_get_a_chapter_gold as pocho
from weekday_data_pocho) j on a.weekday=j.weekday
left join (select weekday, attempts_to_get_a_chapter_gold as missing
from weekday_data_missing) k on a.weekday=k.weekday

union

select a.weekday, 'f' as col2, 'Playtime to get a chapter gold' as col, sawken, luis, joker, mateo, arcadan, richy, derek, nevs, otaku, pocho, missing
from (select weekday, playtime_to_get_a_chapter_gold as sawken
from weekday_data_sawken) a
left join (select weekday, playtime_to_get_a_chapter_gold as luis
from weekday_data_luis) b on a.weekday=b.weekday
left join (select weekday, playtime_to_get_a_chapter_gold as joker
from weekday_data_joker) c on a.weekday=c.weekday
left join (select weekday, playtime_to_get_a_chapter_gold as mateo
from weekday_data_mateo) d on a.weekday=d.weekday
left join (select weekday, playtime_to_get_a_chapter_gold as arcadan
from weekday_data_arcadan) e on a.weekday=e.weekday
left join (select weekday, playtime_to_get_a_chapter_gold as richy
from weekday_data_richy) f on a.weekday=f.weekday
left join (select weekday, playtime_to_get_a_chapter_gold as derek
from weekday_data_derek) g on a.weekday=g.weekday
left join (select weekday, playtime_to_get_a_chapter_gold as nevs
from weekday_data_nevs) h on a.weekday=h.weekday
left join (select weekday, playtime_to_get_a_chapter_gold as otaku
from weekday_data_otaku) i on a.weekday=i.weekday
left join (select weekday, playtime_to_get_a_chapter_gold as pocho
from weekday_data_pocho) j on a.weekday=j.weekday
left join (select weekday, playtime_to_get_a_chapter_gold as missing
from weekday_data_missing) k on a.weekday=k.weekday

union

select a.weekday, 'g' as col2, 'Attempts to get a section gold' as col, sawken, luis, joker, mateo, arcadan, richy, derek, nevs, otaku, pocho, missing
from (select weekday, attempts_to_get_a_section_gold as sawken
from weekday_data_sawken) a
left join (select weekday, attempts_to_get_a_section_gold as luis
from weekday_data_luis) b on a.weekday=b.weekday
left join (select weekday, attempts_to_get_a_section_gold as joker
from weekday_data_joker) c on a.weekday=c.weekday
left join (select weekday, attempts_to_get_a_section_gold as mateo
from weekday_data_mateo) d on a.weekday=d.weekday
left join (select weekday, attempts_to_get_a_section_gold as arcadan
from weekday_data_arcadan) e on a.weekday=e.weekday
left join (select weekday, attempts_to_get_a_section_gold as richy
from weekday_data_richy) f on a.weekday=f.weekday
left join (select weekday, attempts_to_get_a_section_gold as derek
from weekday_data_derek) g on a.weekday=g.weekday
left join (select weekday, attempts_to_get_a_section_gold as nevs
from weekday_data_nevs) h on a.weekday=h.weekday
left join (select weekday, attempts_to_get_a_section_gold as otaku
from weekday_data_otaku) i on a.weekday=i.weekday
left join (select weekday, attempts_to_get_a_section_gold as pocho
from weekday_data_pocho) j on a.weekday=j.weekday
left join (select weekday, attempts_to_get_a_section_gold as missing
from weekday_data_missing) k on a.weekday=k.weekday

union

select a.weekday, 'h' as col2, 'Playtime to get a section gold' as col, sawken, luis, joker, mateo, arcadan, richy, derek, nevs, otaku, pocho, missing
from (select weekday, playtime_to_get_a_section_gold as sawken
from weekday_data_sawken) a
left join (select weekday, playtime_to_get_a_section_gold as luis
from weekday_data_luis) b on a.weekday=b.weekday
left join (select weekday, playtime_to_get_a_section_gold as joker
from weekday_data_joker) c on a.weekday=c.weekday
left join (select weekday, playtime_to_get_a_section_gold as mateo
from weekday_data_mateo) d on a.weekday=d.weekday
left join (select weekday, playtime_to_get_a_section_gold as arcadan
from weekday_data_arcadan) e on a.weekday=e.weekday
left join (select weekday, playtime_to_get_a_section_gold as richy
from weekday_data_richy) f on a.weekday=f.weekday
left join (select weekday, playtime_to_get_a_section_gold as derek
from weekday_data_derek) g on a.weekday=g.weekday
left join (select weekday, playtime_to_get_a_section_gold as nevs
from weekday_data_nevs) h on a.weekday=h.weekday
left join (select weekday, playtime_to_get_a_section_gold as otaku
from weekday_data_otaku) i on a.weekday=i.weekday
left join (select weekday, playtime_to_get_a_section_gold as pocho
from weekday_data_pocho) j on a.weekday=j.weekday
left join (select weekday, playtime_to_get_a_section_gold as missing
from weekday_data_missing) k on a.weekday=k.weekday

union

select a.weekday, 'i' as col2, 'Attempts to get a best pace' as col, sawken, luis, joker, mateo, arcadan, richy, derek, nevs, otaku, pocho, missing
from (select weekday, attempts_to_get_a_best_pace as sawken
from weekday_data_sawken) a
left join (select weekday, attempts_to_get_a_best_pace as luis
from weekday_data_luis) b on a.weekday=b.weekday
left join (select weekday, attempts_to_get_a_best_pace as joker
from weekday_data_joker) c on a.weekday=c.weekday
left join (select weekday, attempts_to_get_a_best_pace as mateo
from weekday_data_mateo) d on a.weekday=d.weekday
left join (select weekday, attempts_to_get_a_best_pace as arcadan
from weekday_data_arcadan) e on a.weekday=e.weekday
left join (select weekday, attempts_to_get_a_best_pace as richy
from weekday_data_richy) f on a.weekday=f.weekday
left join (select weekday, attempts_to_get_a_best_pace as derek
from weekday_data_derek) g on a.weekday=g.weekday
left join (select weekday, attempts_to_get_a_best_pace as nevs
from weekday_data_nevs) h on a.weekday=h.weekday
left join (select weekday, attempts_to_get_a_best_pace as otaku
from weekday_data_otaku) i on a.weekday=i.weekday
left join (select weekday, attempts_to_get_a_best_pace as pocho
from weekday_data_pocho) j on a.weekday=j.weekday
left join (select weekday, attempts_to_get_a_best_pace as missing
from weekday_data_missing) k on a.weekday=k.weekday

union

select a.weekday, 'j' as col2, 'Playtime to get a best pace' as col, sawken, luis, joker, mateo, arcadan, richy, derek, nevs, otaku, pocho, missing
from (select weekday, playtime_to_get_a_best_pace as sawken
from weekday_data_sawken) a
left join (select weekday, playtime_to_get_a_best_pace as luis
from weekday_data_luis) b on a.weekday=b.weekday
left join (select weekday, playtime_to_get_a_best_pace as joker
from weekday_data_joker) c on a.weekday=c.weekday
left join (select weekday, playtime_to_get_a_best_pace as mateo
from weekday_data_mateo) d on a.weekday=d.weekday
left join (select weekday, playtime_to_get_a_best_pace as arcadan
from weekday_data_arcadan) e on a.weekday=e.weekday
left join (select weekday, playtime_to_get_a_best_pace as richy
from weekday_data_richy) f on a.weekday=f.weekday
left join (select weekday, playtime_to_get_a_best_pace as derek
from weekday_data_derek) g on a.weekday=g.weekday
left join (select weekday, playtime_to_get_a_best_pace as nevs
from weekday_data_nevs) h on a.weekday=h.weekday
left join (select weekday, playtime_to_get_a_best_pace as otaku
from weekday_data_otaku) i on a.weekday=i.weekday
left join (select weekday, playtime_to_get_a_best_pace as pocho
from weekday_data_pocho) j on a.weekday=j.weekday
left join (select weekday, playtime_to_get_a_best_pace as missing
from weekday_data_missing) k on a.weekday=k.weekday) a

order by col2, weekday;