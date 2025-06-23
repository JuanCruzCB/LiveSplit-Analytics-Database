import json
import time
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, ClassVar

import psycopg2
from pandas import DataFrame

from constants import Format


class DatabaseError(Exception):
    """
    Custom exception for database connection failures.
    """

    def __init__(
        self,
        message: str,
        db_config: dict | None = None,
        original_exception: Exception | None = None,
    ):
        self.message = message
        self.db_config = db_config
        self.original_exception = original_exception
        super().__init__(message)

    def __str__(self) -> str:
        config_info = f" (Config: {self.db_config})" if self.db_config else ""
        return f"{self.message}{config_info}"


class RE4DatabaseManager:
    DB_CONFIG: ClassVar[dict[str, Any]] = {
        "dbname": "postgres",
        "user": "postgres",
        "host": "localhost",
        "password": 123,
        "port": 5432,
    }
    DEFAULT_UPDATES: ClassVar[dict[str, str]] = dict.fromkeys(
        [
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
        ],
        "1/1/2025 1:00:00",
    )

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
        Connect to the local postgres db using the
        hardcoded credentials and create a cursor object.
        """
        try:
            self._connection = psycopg2.connect(**self.DB_CONFIG)
            self._cursor = self._connection.cursor()
        except psycopg2.Error as e:
            raise DatabaseError(
                message="Failed to connect to local Postgres Database.",
                db_config=self.DB_CONFIG,
                original_exception=e,
            ) from e

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
        with Path(self._main_sql_script).open("r") as file:
            return file.read()

    def _read_global_sql_script(self) -> str:
        """
        Return the content of the global SQL script.
        """
        with Path(self._global_sql_script).open("r") as file:
            return file.read()

    def _load_last_updates(self) -> dict[str, str]:
        """
        Create the last updates json file if it doesn't exist.
        Return its contents if it exists.
        """
        if not self._last_updates_file.exists():
            with Path(self._last_updates_file).open(mode="w") as json_file:
                json.dump(obj=self.DEFAULT_UPDATES, fp=json_file, indent=4)
            return self.DEFAULT_UPDATES

        with Path(self._last_updates_file).open(mode="r") as json_file:
            return json.load(fp=json_file)

    def _save_last_updates(self, updates: dict[str, str]) -> None:
        """
        Update the last updates json file with new data.
        """
        with Path(self._last_updates_file).open(mode="w") as json_file:
            json.dump(obj=updates, fp=json_file, indent=4)

    def update_runners_tables(self, splits: dict[str, datetime]) -> bool:
        """
        If there's currently a connection, run the main SQL script.
        """
        if not self._connection or not self._cursor:
            raise DatabaseError(
                message="There's no current connection to the local Postgres Database."
            )

        last_table_updates = self._load_last_updates()
        sql_script = self._read_main_sql_script()
        new_updates = False

        for split, file_last_modified in splits.items():
            modified_script = sql_script
            db_last_modified = datetime.strptime(
                last_table_updates[split],
                Format.DATE_TIME_FORMAT,
            ).astimezone(UTC)

            if db_last_modified > file_last_modified:
                print(
                    f"Not updating the tables for file {split} since they are already up to date.",
                )
                continue

            if "splits" in split:
                modified_script = modified_script.replace("sawken", split[7:]).replace(
                    r"2024 LRT\1. NG Pro",
                    rf"2024 LRT\Not mine\{split}",
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
                raise DatabaseError(
                    message=f"There was an SQL error while updating the individual tables for {runner_name}",
                    original_exception=e,
                ) from e

            last_table_updates[split] = datetime.now().strftime(Format.DATE_TIME_FORMAT)  # noqa: DTZ005
            print(
                f"Updated the database tables for {runner_name} successfully in {end - start:.3f} seconds!",
            )
            new_updates = True

        self._save_last_updates(updates=last_table_updates)

        return new_updates

    def update_global_tables(self) -> None:
        """
        Run the global SQL script that updates the global tables.
        """
        if not self._connection or not self._cursor:
            raise DatabaseError(
                message="There's no current connection to the local Postgres Database."
            )

        try:
            sql_script = self._read_global_sql_script()
            start = time.time()
            self._cursor.execute(sql_script)
            self._connection.commit()
            end = time.time()
            print(
                f"Updated the database global tables successfully in {end - start:.3f} seconds!",
            )

        except psycopg2.Error as e:
            raise DatabaseError(
                message="There was an SQL error while updating the global tables.",
                original_exception=e,
            ) from e

    def query_db(self, query: str) -> DataFrame:
        """
        Return a DataFrame with the results of running the specified query
        on the db.
        """
        if not self._connection or not self._cursor:
            raise DatabaseError(
                message="There's no current connection to the local Postgres Database."
            )

        try:
            self._cursor.execute(query)
            return DataFrame(
                data=self._cursor.fetchall(),
                columns=[desc[0] for desc in self._cursor.description],
            )
        except psycopg2.Error as e:
            raise DatabaseError(
                message=f"There was an SQL error while running the query {query}.",
                original_exception=e,
            ) from e

    def __del__(self) -> None:
        self.close_connection()
