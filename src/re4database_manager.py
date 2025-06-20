import json
from datetime import datetime
import time
from decimal import Decimal
from pathlib import Path

import numpy as np
import psycopg2
from pandas import DataFrame

from constants import ConstantQuery, Format
from utils import get_days_hours_str, get_hours_minutes_str


class RE4DatabaseManager:
    DB_CONFIG = {
        "dbname": "postgres",
        "user": "postgres",
        "host": "localhost",
        "password": 123,
        "port": 5432,
    }
    DEFAULT_UPDATES = {
        key: "1/1/2025 1:00:00"
        for key in [
            "1. NG Pro",
            "splits arcadan",
            "splits derek",
            "splits joker",
            "splits luis",
            "splits mateo",
            "splits richy",
            "splits nevs",
            "splits otaku",
            "splits pocho",
        ]
    }
    CURRENTLY_ALLOWED_RUNNERS = [
        "sawken",
        "luis",
        "joker",
        "mateo",
        "arcadan",
        "richy",
        "derek",
        "nevs",
        "otaku",
        "pocho",
    ]

    def __init__(
        self,
        main_sql_script: Path,
        global_sql_script: Path,
        last_updates_file: Path,
    ) -> None:
        self._main_sql_script = main_sql_script
        self._global_sql_script = global_sql_script
        self._last_updates_file = last_updates_file

        self._connection = None
        self._cursor = None

    def open_connection(self) -> None:
        """
        Connect to the local postgres db using the hardcoded credentials and create a cursor object.
        """
        try:
            self._connection = psycopg2.connect(**self.DB_CONFIG)
            self._cursor = self._connection.cursor()
        except psycopg2.Error as e:
            raise e

    def close_connection(self) -> None:
        """
        Close the cursor object and close the connection to the local postgres db.
        """
        if self._cursor:
            self._cursor.close()
        if self._connection:
            self._connection.close()

    def _read_main_sql_script(self) -> str:
        """
        Return the content of the main SQL script.
        """
        with open(self._main_sql_script, "r") as file:
            return file.read()

    def _read_global_sql_script(self) -> str:
        """
        Return the content of the global SQL script.
        """
        with open(self._global_sql_script, "r") as file:
            return file.read()

    def _load_last_updates(self) -> dict[str, str]:
        """
        Create the last updates json file if it doesn't exist. Return its contents if it exists.
        """
        if not self._last_updates_file.exists():
            with open(file=self._last_updates_file, mode="w") as json_file:
                json.dump(obj=self.DEFAULT_UPDATES, fp=json_file, indent=4)
            return self.DEFAULT_UPDATES
        else:
            with open(file=self._last_updates_file, mode="r") as json_file:
                return json.load(fp=json_file)

    def _save_last_updates(self, updates: dict[str, str]) -> None:
        """
        Update the last updates json file with new data.
        """
        with open(file=self._last_updates_file, mode="w") as json_file:
            json.dump(obj=updates, fp=json_file, indent=4)

    def update_runners_tables(self, splits: dict[str, datetime]) -> bool:
        """
        If there's currently a connection, run the main SQL script.
        """
        if not self._connection or not self._cursor:
            raise Exception("No database connection available.")

        last_table_updates = self._load_last_updates()
        sql_script = self._read_main_sql_script()
        new_updates = False

        for split, file_last_modified in splits.items():
            modified_script = sql_script
            db_last_modified = datetime.strptime(
                last_table_updates[split], Format.DATE_TIME_FORMAT
            )

            if db_last_modified > file_last_modified:
                print(
                    f"Not updating the tables for file {split} since they are already up to date."
                )
                continue

            if "splits" in split:
                modified_script = modified_script.replace("sawken", split[7:]).replace(
                    r"2024 LRT\1. NG Pro", rf"2024 LRT\Not mine\{split}"
                )
                runner_name = split[7:]
            else:
                runner_name = "sawken"

            try:
                start = time.time()
                self._cursor.execute(modified_script)
                self._connection.commit()
                end = time.time()
            except psycopg2.Error as e:
                raise e

            last_table_updates[split] = datetime.now().strftime(Format.DATE_TIME_FORMAT)
            print(
                f"Updated the database tables for {runner_name} successfully in {end - start:.3f} seconds!"
            )
            new_updates = True

        self._save_last_updates(updates=last_table_updates)

        return new_updates

    def update_global_tables(self) -> None:
        """
        Run the global SQL script that updates the global tables.
        """
        if not self._connection or not self._cursor:
            raise Exception("No database connection available.")

        try:
            sql_script = self._read_global_sql_script()
            start = time.time()
            self._cursor.execute(sql_script)
            self._connection.commit()
            end = time.time()
            print(
                f"Updated the database global tables successfully in {end - start:.3f} seconds!"
            )

        except psycopg2.Error as e:
            raise e

    def query_db(self, query: str) -> DataFrame:
        """
        Return a DataFrame with the results of running the specified query
        on the db.
        """
        if not self._connection or not self._cursor:
            raise Exception("No database connection available.")

        try:
            self._cursor.execute(query)
            return DataFrame(
                data=self._cursor.fetchall(),
                columns=[desc[0] for desc in self._cursor.description],
            )
        except psycopg2.Error as e:
            raise e

    def query_doorsplit_golds(self) -> DataFrame:
        df = self.query_db(query=ConstantQuery.DOORSPLIT_GOLDS_QUERY)
        df = df.replace({np.nan: ""})
        return df.drop(columns=["split"])

    def query_chapter_golds(self) -> DataFrame:
        extra_columns = ["best", "best_cumulative_chapters"]
        columns = ", ".join(
            ["chapter"] + self.CURRENTLY_ALLOWED_RUNNERS + extra_columns
        )
        GLOBAL_CHAPTER_GOLDS_QUERY = f"""
        SELECT {columns}
        FROM global_chapter_golds
        WHERE chapter like '%-%' or chapter='Total';
        """
        df = self.query_db(query=GLOBAL_CHAPTER_GOLDS_QUERY)
        df = df.replace({np.nan: ""})
        return df.drop(columns=["chapter"])

    def query_chapter_golds_by_doors(self) -> DataFrame:
        extra_columns = ["best", "cumulative_best"]
        columns = ", ".join(self.CURRENTLY_ALLOWED_RUNNERS + extra_columns)
        GLOBAL_CHAPTER_GOLDS_BY_DOORS_QUERY = f"""
        SELECT {columns}
        FROM global_chapter_golds_doors;
        """
        df = self.query_db(query=GLOBAL_CHAPTER_GOLDS_BY_DOORS_QUERY)
        return df.replace({np.nan: ""})

    def query_section_golds(self) -> DataFrame:
        extra_columns = ["best", "best_cumulative_sections"]
        columns = ", ".join(self.CURRENTLY_ALLOWED_RUNNERS + extra_columns)
        GLOBAL_SECTION_GOLDS_QUERY = f"""
        SELECT {columns}
        FROM global_section_golds;
        """
        df = self.query_db(query=GLOBAL_SECTION_GOLDS_QUERY)
        return df.replace({np.nan: ""})

    def query_section_golds_by_chapters(self) -> DataFrame:
        extra_columns = ["best", "cumulative_best"]
        columns = ", ".join(self.CURRENTLY_ALLOWED_RUNNERS + extra_columns)
        GLOBAL_SECTION_GOLDS_BY_CHAPTERS_QUERY = f"""
        SELECT {columns}
        FROM global_section_golds_chapters;
        """
        df = self.query_db(query=GLOBAL_SECTION_GOLDS_BY_CHAPTERS_QUERY)
        return df.replace({np.nan: ""})

    def query_section_golds_by_doors(self) -> DataFrame:
        extra_columns = ["best", "cumulative_best"]
        columns = ", ".join(self.CURRENTLY_ALLOWED_RUNNERS + extra_columns)
        GLOBAL_SECTION_GOLDS_BY_DOORS_QUERY = f"""
        SELECT {columns}
        FROM global_section_golds_doors;
        """
        df = self.query_db(query=GLOBAL_SECTION_GOLDS_BY_DOORS_QUERY)
        return df.replace({np.nan: ""})

    def query_best_paces(self) -> DataFrame:
        df = self.query_db(query=ConstantQuery.BEST_PACES_QUERY)
        df = df.replace({np.nan: ""})
        return df.drop(columns=["chapter"])

    def query_rng_patterns(self) -> DataFrame:
        df = self.query_db(query=ConstantQuery.RNG_PATTERNS_QUERY)
        df = df.replace({np.nan: ""})
        df = df.map(lambda x: float(x) if isinstance(x, Decimal) else x)
        return df.drop(columns=["pattern"])

    def query_general_stats(self) -> DataFrame:
        columns = ", ".join(self.CURRENTLY_ALLOWED_RUNNERS)
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
                date_str, Format.BAD_DATE_FORMAT
            ).strftime(Format.DATE_FORMAT)
        )
        df.iloc[3] = df.iloc[3].apply(lambda playtime: get_days_hours_str(playtime))
        return df

    def query_resets(self) -> DataFrame:
        columns = ",\n".join(
            f"case when percent_{name} < 0 then 0 else percent_{name} end as percent_{name}"
            for name in self.CURRENTLY_ALLOWED_RUNNERS
        )
        RESETS_QUERY = f"""
        SELECT split,
        {columns}
        FROM global_resets;
        """
        df = self.query_db(query=RESETS_QUERY)
        df = df.map(lambda x: float(x) if isinstance(x, Decimal) else x)
        return df.replace({np.nan: ""})

    def query_weekday_data(self) -> DataFrame:
        df = self.query_db(query=ConstantQuery.WEEKDAY_DATA_QUERY)
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
