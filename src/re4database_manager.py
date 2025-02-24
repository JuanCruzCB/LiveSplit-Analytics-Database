from datetime import datetime
import json
from pathlib import Path

import psycopg2
from pandas import DataFrame

from constants import DATE_TIME_FORMAT
from decorators import measure_time


GLOBAL_DOORSPLIT_GOLDS_QUERY = """
select *
from global_door_golds;
"""

GLOBAL_CHAPTER_GOLDS_QUERY = """
select chapter, sawken, luis, joker, mateo, arcadan, richy, derek, best, best_cumulative_chapters
from global_chapter_golds
where chapter like '%-%' or chapter='Total';
"""

GLOBAL_CHAPTER_GOLDS_BY_DOORS_QUERY = """
select chapter, sawken, luis, joker, mateo, arcadan, richy, derek, best, cumulative_best
from global_chapter_golds_doors;
"""

GLOBAL_SECTION_GOLDS_QUERY = """
select section, sawken, luis, joker, mateo, arcadan, richy, derek, best, best_cumulative_sections
from global_section_golds;
"""


GLOBAL_SECTION_GOLDS_BY_CHAPTERS_QUERY = """
select section, sawken, luis, joker, mateo, arcadan, richy, derek, best, cumulative_best
from global_section_golds_chapters;
"""

GLOBAL_SECTION_GOLDS_BY_DOORS_QUERY = """
select section, sawken, luis, joker, mateo, arcadan, richy, derek, best, cumulative_best
from global_section_golds_doors;
"""

GLOBAL_BEST_PACES_QUERY = """
select *
from global_best_paces_chapter;
"""

GLOBAL_RNG_PATTERNS_QUERY = """
select *
from global_rng_patterns;
"""

GENERAL_STATS_QUERY = """
select chapter, sawken, luis, joker, mateo, arcadan, richy, derek
from global_chapter_golds
where chapter not like '%-%' and chapter<>'Total';
"""

RESETS_QUERY = """
select split, case when percent_sawken<0 then 0 else percent_sawken end as percent_sawken,
case when percent_luis<0 then 0 else percent_luis end as percent_luis,
case when percent_joker<0 then 0 else percent_joker end as percent_joker,
case when percent_mateo<0 then 0 else percent_mateo end as percent_mateo,
case when percent_arcadan<0 then 0 else percent_arcadan end as percent_arcadan,
case when percent_richy<0 then 0 else percent_richy end as percent_richy,
case when percent_derek<0 then 0 else percent_derek end as percent_derek
from global_resets;
"""

WEEKDAY_DATA_QUERY = """select * from global_weekday_data"""


class RE4DatabaseManager:
    def __init__(self) -> None:
        self.config = {
            "dbname": "postgres",
            "user": "postgres",
            "host": "localhost",
            "password": 123,
            "port": 5432,
        }
        self.main_sql_script = Path(
            r"H:\Juan\4. Speedrunning\RE4 Steam\script ng pro steam.sql"
        )
        self.global_sql_script = Path(
            r"H:\Juan\4. Speedrunning\RE4 Steam\global ng pro steam.sql"
        )
        self.last_updates_file = (
            Path(__file__).parent.parent / "info" / "last_table_updates.json"
        )
        self.connection = None
        self.cursor = None

        self._open_connection()

    def _open_connection(self) -> None:
        try:
            self.connection = psycopg2.connect(**self.config)
            self.cursor = self.connection.cursor()
        except psycopg2.Error as e:
            raise e

    def close_connection(self) -> None:
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()

    def _read_sql_script(self, script_path: Path) -> str:
        with open(script_path, "r") as file:
            return file.read()

    def _load_last_updates(self) -> dict[str, str]:
        if not self.last_updates_file.exists():
            default_updates = {
                "1. NG Pro": "2025-01-01 1:00:00",
                "splits arcadan": "2025-01-01 1:00:00",
                "splits derek": "2025-01-01 1:00:00",
                "splits joker": "2025-01-01 1:00:00",
                "splits luis": "2025-01-01 1:00:00",
                "splits mateo": "2025-01-01 1:00:00",
                "splits richy": "2025-01-01 1:00:00",
            }
            with open(file=self.last_updates_file, mode="w") as json_file:
                json.dump(obj=default_updates, fp=json_file, indent=4)
            return default_updates
        else:
            with open(file=self.last_updates_file, mode="r") as json_file:
                return json.load(fp=json_file)

    def _save_last_updates(self, updates: dict[str, str]) -> None:
        with open(file=self.last_updates_file, mode="w") as json_file:
            json.dump(obj=updates, fp=json_file, indent=4)

    @measure_time
    def update_runners_tables(self, splits: dict[str, str]) -> None:
        """
        If there's currently a connection, run the main SQL script.
        """
        if not self.connection or not self.cursor:
            print("No database connection available.")
            return

        last_table_updates = self._load_last_updates()
        sql_script = self._read_sql_script(self.main_sql_script)

        try:
            for split, last_modified in splits.items():
                runner_name = "sawken" if "1. " in split else split[7:]
                if last_table_updates[split] < last_modified:
                    modified_script = sql_script

                    if "splits" in split:
                        modified_script = modified_script.replace(
                            "sawken", split[7:]
                        ).replace(r"2024 LRT\1. NG Pro", rf"2024 LRT\Not mine\{split}")

                    self.cursor.execute(sql_script)
                    self.connection.commit()

                    last_table_updates[split] = datetime.now().strftime(
                        DATE_TIME_FORMAT
                    )
                    print(
                        f"Updated the database tables for {runner_name} successfully!"
                    )
                else:
                    print(
                        f"Not updating the tables for {runner_name} since they are already up to date."
                    )

            self._save_last_updates(updates=last_table_updates)

        except psycopg2.Error as e:
            raise e

    @measure_time
    def update_global_tables(self) -> None:
        try:
            sql_script = self._read_sql_script(script_path=self.global_sql_script)
            self.cursor.execute(sql_script)
            self.connection.commit()
            print("Updated the database global tables succesfully!")

        except psycopg2.Error as e:
            raise e

    @measure_time
    def query_db(self, query: str) -> DataFrame:
        try:
            self.cursor.execute(query)
            df = DataFrame(
                data=self.cursor.fetchall(),
                columns=[desc[0] for desc in self.cursor.description],
            )
            return df
        except psycopg2.Error as e:
            raise e

    @measure_time
    def query_doorsplit_golds(self) -> DataFrame:
        return self.query_db(query=GLOBAL_DOORSPLIT_GOLDS_QUERY)

    @measure_time
    def query_chapter_golds(self) -> DataFrame:
        return self.query_db(query=GLOBAL_CHAPTER_GOLDS_QUERY)

    @measure_time
    def query_chapter_golds_by_doors(self) -> DataFrame:
        return self.query_db(query=GLOBAL_CHAPTER_GOLDS_BY_DOORS_QUERY)

    @measure_time
    def query_section_golds(self) -> DataFrame:
        return self.query_db(query=GLOBAL_SECTION_GOLDS_QUERY)

    @measure_time
    def query_section_golds_by_chapters(self) -> DataFrame:
        return self.query_db(query=GLOBAL_SECTION_GOLDS_BY_CHAPTERS_QUERY)

    @measure_time
    def query_section_golds_by_doors(self) -> DataFrame:
        return self.query_db(query=GLOBAL_SECTION_GOLDS_BY_DOORS_QUERY)

    @measure_time
    def query_best_paces(self) -> DataFrame:
        return self.query_db(query=GLOBAL_BEST_PACES_QUERY)

    @measure_time
    def query_rng_patterns(self) -> DataFrame:
        return self.query_db(query=GLOBAL_RNG_PATTERNS_QUERY)

    @measure_time
    def query_general_stats(self) -> DataFrame:
        return self.query_db(query=GENERAL_STATS_QUERY)

    @measure_time
    def query_resets(self) -> DataFrame:
        return self.query_db(query=RESETS_QUERY)

    @measure_time
    def query_weekday_data(self) -> DataFrame:
        return self.query_db(query=WEEKDAY_DATA_QUERY)

    def __del__(self) -> None:
        self.close_connection()
