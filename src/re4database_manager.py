import json
from datetime import datetime
from decimal import Decimal
from pathlib import Path

import numpy as np
import psycopg2
from pandas import DataFrame

from constants import CURRENTLY_ALLOWED_RUNNERS, DEFAULT_UPDATES, ConstantQuery, Format
from decorators import measure_time
from utils import get_days_hours_str, get_hours_minutes_str


class RE4DatabaseManager:
    def __init__(self) -> None:
        self._config = {
            "dbname": "postgres",
            "user": "postgres",
            "host": "localhost",
            "password": 123,
            "port": 5432,
        }
        self._main_sql_script = Path(
            r"H:\Juan\4. Speedrunning\RE4 Steam\script ng pro steam.sql"
        )
        self._global_sql_script = Path(
            r"H:\Juan\4. Speedrunning\RE4 Steam\global ng pro steam.sql"
        )
        self._last_updates_file = Path(
            r"H:\Juan\3. Projects\GH Sawken\Python\UpdateGoldsGlobal\info\last_table_updates.json"
        )
        self._connection = None
        self._cursor = None

        self._open_connection()

    def _open_connection(self) -> None:
        try:
            self._connection = psycopg2.connect(**self._config)
            self._cursor = self._connection.cursor()
        except psycopg2.Error as e:
            raise e

    def close_connection(self) -> None:
        if self._cursor:
            self._cursor.close()
        if self._connection:
            self._connection.close()

    def _read_sql_script(self, script_path: Path) -> str:
        with open(script_path, "r") as file:
            return file.read()

    def _load_last_updates(self) -> dict[str, str]:
        if not self._last_updates_file.exists():
            with open(file=self._last_updates_file, mode="w") as json_file:
                json.dump(obj=DEFAULT_UPDATES, fp=json_file, indent=4)
            return DEFAULT_UPDATES
        else:
            with open(file=self._last_updates_file, mode="r") as json_file:
                return json.load(fp=json_file)

    def _save_last_updates(self, updates: dict[str, str]) -> None:
        with open(file=self._last_updates_file, mode="w") as json_file:
            json.dump(obj=updates, fp=json_file, indent=4)

    @measure_time
    def update_runners_tables(self, splits: dict[str, str]) -> bool:
        """
        If there's currently a connection, run the main SQL script.
        """
        if not self._connection or not self._cursor:
            raise Exception("No database connection available.")

        last_table_updates = self._load_last_updates()
        sql_script = self._read_sql_script(self._main_sql_script)
        new_updates = False

        try:
            for split, last_modified in splits.items():
                runner_name = "sawken" if "1. " in split else split[7:]
                if datetime.strptime(
                    last_table_updates[split], Format.DATE_TIME_FORMAT.value
                ) < datetime.strptime(last_modified, Format.DATE_TIME_FORMAT.value):
                    modified_script = sql_script

                    if "splits" in split:
                        modified_script = modified_script.replace(
                            "sawken", split[7:]
                        ).replace(r"2024 LRT\1. NG Pro", rf"2024 LRT\Not mine\{split}")

                    self._cursor.execute(modified_script)
                    self._connection.commit()

                    last_table_updates[split] = datetime.now().strftime(
                        Format.DATE_TIME_FORMAT.value
                    )
                    print(
                        f"Updated the database tables for {runner_name} successfully!"
                    )
                    new_updates = True
                else:
                    print(
                        f"Not updating the tables for {runner_name} since they are already up to date."
                    )

            self._save_last_updates(updates=last_table_updates)

        except psycopg2.Error as e:
            raise e

        return new_updates

    @measure_time
    def update_global_tables(self) -> None:
        if not self._connection or not self._cursor:
            raise Exception("No database connection available.")

        try:
            sql_script = self._read_sql_script(script_path=self._global_sql_script)
            self._cursor.execute(sql_script)
            self._connection.commit()
            print("Updated the database global tables succesfully!")

        except psycopg2.Error as e:
            raise e

    @measure_time
    def query_db(self, query: str) -> DataFrame:
        if not self._connection or not self._cursor:
            raise Exception("No database connection available.")

        try:
            self._cursor.execute(query)
            df = DataFrame(
                data=self._cursor.fetchall(),
                columns=[desc[0] for desc in self._cursor.description],
            )
            return df
        except psycopg2.Error as e:
            raise e

    @measure_time
    def query_doorsplit_golds(self) -> DataFrame:
        df = self.query_db(query=ConstantQuery.DOORSPLIT_GOLDS_QUERY.value)
        df = df.replace({np.nan: ""})
        return df.drop(columns=["split"])

    @measure_time
    def query_chapter_golds(self) -> DataFrame:
        extra_columns = ["best", "best_cumulative_chapters"]
        columns = ", ".join(["chapter"] + CURRENTLY_ALLOWED_RUNNERS + extra_columns)
        GLOBAL_CHAPTER_GOLDS_QUERY = f"""
        SELECT {columns}
        FROM global_chapter_golds
        WHERE chapter like '%-%' or chapter='Total';
        """
        df = self.query_db(query=GLOBAL_CHAPTER_GOLDS_QUERY)
        df = df.replace({np.nan: ""})
        return df.drop(columns=["chapter"])

    @measure_time
    def query_chapter_golds_by_doors(self) -> DataFrame:
        extra_columns = ["best", "cumulative_best"]
        columns = ", ".join(CURRENTLY_ALLOWED_RUNNERS + extra_columns)
        GLOBAL_CHAPTER_GOLDS_BY_DOORS_QUERY = f"""
        SELECT {columns}
        FROM global_chapter_golds_doors;
        """
        df = self.query_db(query=GLOBAL_CHAPTER_GOLDS_BY_DOORS_QUERY)
        return df.replace({np.nan: ""})

    @measure_time
    def query_section_golds(self) -> DataFrame:
        extra_columns = ["best", "best_cumulative_sections"]
        columns = ", ".join(CURRENTLY_ALLOWED_RUNNERS + extra_columns)
        GLOBAL_SECTION_GOLDS_QUERY = f"""
        SELECT {columns}
        FROM global_section_golds;
        """
        df = self.query_db(query=GLOBAL_SECTION_GOLDS_QUERY)
        return df.replace({np.nan: ""})

    @measure_time
    def query_section_golds_by_chapters(self) -> DataFrame:
        extra_columns = ["best", "cumulative_best"]
        columns = ", ".join(CURRENTLY_ALLOWED_RUNNERS + extra_columns)
        GLOBAL_SECTION_GOLDS_BY_CHAPTERS_QUERY = f"""
        SELECT {columns}
        FROM global_section_golds_chapters;
        """
        df = self.query_db(query=GLOBAL_SECTION_GOLDS_BY_CHAPTERS_QUERY)
        return df.replace({np.nan: ""})

    @measure_time
    def query_section_golds_by_doors(self) -> DataFrame:
        extra_columns = ["best", "cumulative_best"]
        columns = ", ".join(CURRENTLY_ALLOWED_RUNNERS + extra_columns)
        GLOBAL_SECTION_GOLDS_BY_DOORS_QUERY = f"""
        SELECT {columns}
        FROM global_section_golds_doors;
        """
        df = self.query_db(query=GLOBAL_SECTION_GOLDS_BY_DOORS_QUERY)
        return df.replace({np.nan: ""})

    @measure_time
    def query_best_paces(self) -> DataFrame:
        df = self.query_db(query=ConstantQuery.BEST_PACES_QUERY.value)
        df = df.replace({np.nan: ""})
        return df.drop(columns=["chapter"])

    @measure_time
    def query_rng_patterns(self) -> DataFrame:
        df = self.query_db(query=ConstantQuery.RNG_PATTERNS_QUERY.value)
        df = df.replace({np.nan: ""})
        df = df.map(lambda x: float(x) if isinstance(x, Decimal) else x)
        return df.drop(columns=["pattern"])

    @measure_time
    def query_general_stats(self) -> DataFrame:
        columns = ", ".join(CURRENTLY_ALLOWED_RUNNERS)
        GENERAL_STATS_QUERY = f"""
        SELECT chapter, {columns}
        FROM global_chapter_golds
        WHERE chapter NOT LIKE '%-%' AND chapter <> 'Total';
        """
        df = self.query_db(query=GENERAL_STATS_QUERY)
        df = df.replace({np.nan: ""})
        df = df.drop(columns=["chapter"])
        df.iloc[0] = df.iloc[0].apply(
            lambda date_str: datetime.strptime(
                date_str, Format.BAD_DATE_FORMAT.value
            ).strftime(Format.DATE_FORMAT.value)
        )
        df.iloc[3] = df.iloc[3].apply(lambda playtime: get_days_hours_str(playtime))
        return df

    @measure_time
    def query_resets(self) -> DataFrame:
        columns = ",\n".join(
            f"case when percent_{name} < 0 then 0 else percent_{name} end as percent_{name}"
            for name in CURRENTLY_ALLOWED_RUNNERS
        )
        RESETS_QUERY = f"""
        SELECT split,
        {columns}
        FROM global_resets;
        """
        df = self.query_db(query=RESETS_QUERY)
        df = df.map(lambda x: float(x) if isinstance(x, Decimal) else x)
        return df.replace({np.nan: ""})

    @measure_time
    def query_weekday_data(self) -> DataFrame:
        df = self.query_db(query=ConstantQuery.WEEKDAY_DATA_QUERY.value)
        df = df.replace({np.nan: ""})

        ranges_to_process = [
            range(7, 14),
            range(21, 28),
            range(35, 42),
            range(49, 56),
            range(63, 70),
        ]
        for r in ranges_to_process:
            for i in r:
                df.iloc[i] = df.iloc[i].apply(get_hours_minutes_str)
        return df.drop(columns=["day", "col"])

    def __del__(self) -> None:
        self.close_connection()
