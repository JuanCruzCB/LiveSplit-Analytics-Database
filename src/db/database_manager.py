import json
import time
from datetime import UTC, datetime
from pathlib import Path

import psycopg2
from pandas import DataFrame


class LastUpdatesTracker:
    """
    Tracks the last time each file has been updated from a predefined set of files.
    The tracking is loaded to and from a JSON file.
    """

    DATE_TIME_FORMAT = "%d/%m/%Y %H:%M:%S"
    DEFAULT_TIMESTAMP = "1/1/2025 00:00:00"

    def __init__(self, storage_file: Path, default_files: list[Path]) -> None:
        self._storage_file = storage_file
        self._default_data = dict.fromkeys(
            default_files,
            datetime.strptime(self.DEFAULT_TIMESTAMP, self.DATE_TIME_FORMAT).astimezone(
                UTC
            ),
        )

    def is_first_file_equal_to(self, file: Path) -> bool:
        """
        Checks whether the given file is the same as the first
        file on the JSON file.
        """
        last_updates = self.load_last_updates()
        first_file = next(iter(last_updates))
        return first_file == file

    def set_timestamp_now(self, file: Path) -> None:
        """
        Set the current UTC timestamp for a given file
        and save the update to the JSON file.
        """
        last_updates = self.load_last_updates()
        last_updates[file] = datetime.now().astimezone(UTC)
        self.save_last_updates(last_updates)

    def get_timestamp(self, file: Path) -> datetime:
        """
        Get the last update timestamp for a given file.
        """
        return self.load_last_updates()[file]

    def load_last_updates(self) -> dict[Path, datetime]:
        """
        Load the last update timestamps from the storage file.

        - If the storage file does not exist, it will be created with default timestamps.
        - If the storage file exists, it will be read and parsed.
        - In either case, a dictionary with the data is returned.
        """
        if not self._storage_file.exists():
            self.save_last_updates(self._default_data)
            return self._default_data

        with self._storage_file.open(mode="r") as json_file:
            raw_data = json.load(fp=json_file)
            return {
                Path(file): datetime.strptime(modtime, self.DATE_TIME_FORMAT).replace(
                    tzinfo=UTC
                )
                for file, modtime in raw_data.items()
            }

    def save_last_updates(self, updates: dict[Path, datetime]) -> None:
        """
        Save the given update timestamps to the JSON file.
        """
        serializable_dict = {
            str(file): modtime.strftime(self.DATE_TIME_FORMAT)
            for file, modtime in updates.items()
        }
        with self._storage_file.open(mode="w") as json_file:
            json.dump(obj=serializable_dict, fp=json_file, indent=4)


class DatabaseError(Exception):
    """
    Custom exception for database connection failures.
    """

    def __init__(
        self,
        message: str = "There's no current connection to the local Postgres Database.",
        db_config: dict | None = None,
        original_exception: Exception | None = None,
    ) -> None:
        self.message = message
        self.db_config = db_config
        self.original_exception = original_exception
        super().__init__(message)

    def __str__(self) -> str:
        config_info = f" (Config: {self.db_config})" if self.db_config else ""
        return f"{self.message}{config_info}"


class DatabaseManager:
    def __init__(
        self,
        individual_sql_script: Path,
        global_sql_script: Path,
        db_config: dict,
        main_runner_name: str,
        last_updates_tracker: LastUpdatesTracker,
    ) -> None:
        self._individual_sql_script = individual_sql_script
        self._global_sql_script = global_sql_script
        self._db_config = db_config
        self._main_runner_name = main_runner_name
        self._last_updates_tracker = last_updates_tracker

        self._connection = None
        self._cursor = None

    def open_connection(self) -> None:
        """
        Connect to the local postgres db using the
        hardcoded credentials and create a cursor object.
        """
        try:
            self._connection = psycopg2.connect(**self._db_config)
            self._cursor = self._connection.cursor()
        except psycopg2.Error as e:
            raise DatabaseError(
                message="Failed to connect to local Postgres Database.",
                db_config=self._db_config,
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

    def update_runners_tables(self, splits: dict[Path, datetime]) -> bool:
        """
        If there's currently a connection, run the main SQL script.
        """
        if not self._connection or not self._cursor:
            raise DatabaseError

        sql_script = self._individual_sql_script.read_text()
        new_updates = False

        for split, file_last_modified in splits.items():
            modified_script = sql_script
            db_last_modified = self._last_updates_tracker.get_timestamp(file=split)

            if db_last_modified > file_last_modified:
                print(
                    f"Not updating the tables for file '{split}' since they are already up to date.",
                )
                continue

            runner_name = (
                self._main_runner_name
                if self._last_updates_tracker.is_first_file_equal_to(file=split)
                else split.stem[7:]
            )
            modified_script = modified_script.replace("runner", runner_name)
            modified_script = modified_script.replace("path", f"{split!s}")

            try:
                self._execute_sql_script(
                    modified_script,
                    message=f"Updated the database tables for {runner_name} successfully",
                )
            except psycopg2.Error as e:
                raise DatabaseError(
                    message=f"There was an SQL error while updating the individual tables for {runner_name}",
                    original_exception=e,
                ) from e

            self._last_updates_tracker.set_timestamp_now(file=split)
            new_updates = True

        return new_updates

    def update_global_tables(self) -> None:
        """
        Run the global SQL script that updates the global tables.
        """
        if not self._connection or not self._cursor:
            raise DatabaseError

        try:
            self._execute_sql_script(
                sql_script=self._global_sql_script.read_text(),
                message="Updated the database global tables successfully",
            )

        except psycopg2.Error as e:
            raise DatabaseError(
                message="There was an SQL error while updating the global tables.",
                original_exception=e,
            ) from e

    def query(self, query: str, params: tuple | None = None) -> DataFrame:
        """
        Return a DataFrame with the results of running the specified query
        on the db.
        """
        if not self._connection or not self._cursor:
            raise DatabaseError

        try:
            self._cursor.execute(query, params)
            return DataFrame(
                data=self._cursor.fetchall(),
                columns=[desc[0] for desc in self._cursor.description],
            )
        except psycopg2.Error as e:
            raise DatabaseError(
                message=f"There was an SQL error while running the query {query}.",
                original_exception=e,
            ) from e

    def _execute_sql_script(self, sql_script: str, message: str):
        start = time.time()
        self._cursor.execute(sql_script)
        self._connection.commit()
        end = time.time()
        print(f"{message} in {end - start:.3f} seconds!")

    def __del__(self) -> None:
        self.close_connection()
