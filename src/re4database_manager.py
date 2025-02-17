from pathlib import Path
import psycopg2
import time


class RE4DatabaseManager:
    def __init__(self) -> None:
        self.config = {
            "dbname": "postgres",
            "user": "postgres",
            "host": "localhost",
            "password": 123,
            "port": 5432,
        }
        self.main_sql_script_path = Path(
            r"H:\Juan\4. Speedrunning\RE4 Steam\script ng pro steam.sql"
        )
        self.connection = None
        self.cursor = None

        self.connect_to_database()

    def connect_to_database(self) -> None:
        try:
            self.connection = psycopg2.connect(**self.config)
            self.cursor = self.connection.cursor()
        except psycopg2.Error as e:
            print(f"Database connection error: {e}")
            self.connection = None
            self.cursor = None

    def close_connection(self) -> None:
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()

    def get_main_sql_script_content(self) -> str:
        with open(file=self.main_sql_script_path, mode="r") as file:
            return file.read()

    def update_database(self) -> None:
        """
        If there's currently a connection, run the main SQL script.
        """
        if not self.connection or not self.cursor:
            print("No database connection available.")

        try:
            start_time = time.time()
            self.cursor.execute(self.get_main_sql_script_content())
            execution_time = time.time() - start_time
            print(f"RE4 Database updated successfully in {execution_time:.3f} seconds!")
        except psycopg2.Error as e:
            raise e

    def get_golds_on_date(self, date: str) -> tuple[list[tuple], list[str]]:
        """
        If there's currently a connection, get the table of golds on a certain date
        and return the data + the column names.
        """
        if not self.connection or not self.cursor:
            return "No database connection available."

        try:
            self.cursor.execute(self.golds_on_date_query(date=date))
            data = self.cursor.fetchall()
            columns = [desc[0] for desc in self.cursor.description]
            return data, columns
        except psycopg2.Error as e:
            raise e

    def get_golds_on_dates(
        self, dates: set[str], videos: list[RE4Video]
    ) -> dict[str, list[Gold]]:
        """
        For each date in the dates passed as argument, get the data and columns for it, and parse
        it using pandas.
        """
        for date in sorted(dates):
            data, columns = self.get_golds_on_date(date=date)
            self.gold_data_extractor.extract_golds(
                data=data, columns=columns, videos=videos
            )

        return self.gold_data_extractor.get_golds()

    def golds_on_date_query(self, date: str) -> str:
        return f"""with select_date (date) as (values (cast('{date}' as date)))
select aa.*, case when aa.chapter_time is null then null else bb.time_start end as chapter_time_start,
case when aa.section_time is null then null else cc.time_start end as section_time_start
from (select id, cle2, split, chapter, section, date_started, date_started2, time_start, time_end, final_lrt, pb,
case when golded_split=1 and lrt_number=gold then lrt_split else null end as door_time,
case when golded_chapter=1 and chapter_time=chapter_gold and (rang_chapter=1 or rang_chapter2=1) then chapter_time2 else null end as chapter_time,
case when golded_section=1 and section_time=section_gold and (rang_section=1 or rang_section2=1) then section_time2 else null end as section_time,
case when was_best_pace=1 and pace=best_pace then pace2 else null end as pace,
case when golded_split=1 and lrt_number=gold  then gold_at_that_time else null end as previous_gold,
case when golded_chapter=1 and chapter_time=chapter_gold and (rang_chapter=1 or rang_chapter2=1) then chapter_gold_at_that_time else null end as previous_chapter_gold,
case when golded_section=1 and section_time=section_gold and (rang_section=1 or rang_section2=1) then section_gold_at_that_time else null end as previous_section_gold,
case when was_best_pace=1 and pace=best_pace  then best_pace_at_that_time else null end as previous_best_pace
from (
select *, row_number() over (partition by id, section order by cle2 desc) as rang_section,
row_number() over (partition by id, chapter order by cle2 desc) as rang_chapter,
row_number() over (partition by id, section order by cle2) as rang_section2,
row_number() over (partition by id, chapter order by cle2) as rang_chapter2
from splits_overview_sawken
where date_started=(select date from select_date)) a
where (golded_chapter=1 and (rang_chapter=1 or rang_chapter2=1) and chapter_time=chapter_gold) or
(golded_split=1 and lrt_number=gold) or (golded_section=1 and (rang_section=1 or rang_section2=1) and section_time=section_gold)
or (was_best_pace=1 and pace=best_pace)
order by id, cle2) aa
left join (select id, cle2, split, chapter, section, date_started, date_started2, time_start, time_end, final_lrt, pb,
case when golded_split=1 and lrt_number=gold then lrt_split else null end as door_time,
case when golded_chapter=1 and chapter_time=chapter_gold and rang_chapter=1 then chapter_time2 else null end as chapter_time,
case when golded_section=1 and section_time=section_gold and rang_section=1 then section_time2 else null end as section_time,
case when was_best_pace=1 and pace=best_pace then pace2 else null end as pace,
case when golded_split=1 and lrt_number=gold  then gold_at_that_time else null end as previous_gold,
case when golded_chapter=1 and chapter_time=chapter_gold and rang_chapter=1 then chapter_gold_at_that_time else null end as previous_chapter_gold,
case when golded_section=1 and section_time=section_gold and rang_section=1 then section_gold_at_that_time else null end as previous_section_gold,
case when was_best_pace=1 and pace=best_pace  then best_pace_at_that_time else null end as previous_best_pace
from (
select *, row_number() over (partition by id, section order by cle2) as rang_section,
row_number() over (partition by id, chapter order by cle2) as rang_chapter
from splits_overview_sawken
where date_started=(select date from select_date)) a
where golded_chapter=1 and rang_chapter=1 and chapter_time=chapter_gold
order by id, cle2) bb on aa.id=bb.id and aa.chapter=bb.chapter
left join (select id, cle2, split, chapter, section, date_started, date_started2, time_start, time_end, final_lrt, pb,
case when golded_split=1 and lrt_number=gold then lrt_split else null end as door_time,
case when golded_chapter=1 and chapter_time=chapter_gold and rang_chapter=1 then chapter_time2 else null end as chapter_time,
case when golded_section=1 and section_time=section_gold and rang_section=1 then section_time2 else null end as section_time,
case when was_best_pace=1 and pace=best_pace then pace2 else null end as pace,
case when golded_split=1 and lrt_number=gold  then gold_at_that_time else null end as previous_gold,
case when golded_chapter=1 and chapter_time=chapter_gold and rang_chapter=1 then chapter_gold_at_that_time else null end as previous_chapter_gold,
case when golded_section=1 and section_time=section_gold and rang_section=1 then section_gold_at_that_time else null end as previous_section_gold,
case when was_best_pace=1 and pace=best_pace  then best_pace_at_that_time else null end as previous_best_pace
from (
select *, row_number() over (partition by id, section order by cle2) as rang_section,
row_number() over (partition by id, chapter order by cle2) as rang_chapter
from splits_overview_sawken
where date_started=(select date from select_date)) a
where golded_section=1 and rang_section=1 and section_time=section_gold
order by id, cle2) cc on aa.id=cc.id and aa.section=cc.section;"""

    def __del__(self) -> None:
        self.close_connection()
