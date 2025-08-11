import logging
import time
from datetime import datetime
from pathlib import Path

import psycopg2
from pandas import DataFrame

from db.last_updates_tracker import LastUpdatesTracker

logger = logging.getLogger(__name__)


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

        logger.info("Updating the individual database tables...")
        sql_script = self._individual_sql_script.read_text()
        new_updates = False

        for split, file_last_modified in splits.items():
            modified_script = sql_script
            db_last_modified = self._last_updates_tracker.get_timestamp(file=split)

            if db_last_modified > file_last_modified:
                logger.info(
                    "Not updating the tables for splits file '%s' since they are already up to date.",
                    split.name,
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

        if not new_updates:
            logger.info("The database is already up to date.")
        return new_updates

    def update_global_tables(self) -> None:
        """
        Run the global SQL script that updates the global tables.
        """
        if not self._connection or not self._cursor:
            raise DatabaseError

        logger.info("Updating the global database tables...")
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
        logger.info("%s in %.3f seconds!", message, end - start)

    def __del__(self) -> None:
        self.close_connection()
