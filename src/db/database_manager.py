import logging
import time
from datetime import datetime
from pathlib import Path

import psycopg
from pandas import DataFrame

from db.database_error import DatabaseError
from db.last_updates_tracker import LastUpdatesTracker

logger = logging.getLogger(__name__)


class DatabaseManager:
    def __init__(
        self,
        sql_script: Path,
        utility_sql_script: Path,
        db_config: dict[str, str | int],
        main_runner_name: str,
        last_updates_tracker: LastUpdatesTracker,
    ) -> None:
        self._sql_script = sql_script
        self._utility_sql_script = utility_sql_script
        self._db_config = db_config
        self._main_runner_name = main_runner_name
        self._last_updates_tracker = last_updates_tracker

        self._connection = None

    def open_connection(self) -> None:
        """
        Connect to the local postgres db using the
        hardcoded credentials.
        """
        try:
            self._connection = psycopg.connect(**self._db_config)  # type: ignore  # noqa: PGH003
        except psycopg.Error as e:
            raise DatabaseError(
                message="Failed to connect to local Postgres database.",
                db_config=self._db_config,
                original_exception=e,
            ) from e

    def close_connection(self) -> None:
        """
        Close the connection to the local postgres db.
        """
        if self._connection:
            self._connection.close()
            self._connection = None

    def execute(
        self,
        query: str,
        message: str = "Unspecified query ran",
        params: dict[str, str | int] | None = None,
    ) -> DataFrame:
        """
        Return a DataFrame with the results of running the specified query
        on the db.
        """
        if not self._connection:
            raise DatabaseError

        try:
            result = DataFrame()
            start = time.time()
            with self._connection.cursor() as cur:
                cur.execute(query, params)  # type: ignore  # noqa: PGH003
                end = time.time()
                if cur.description:
                    data = cur.fetchall()
                    columns = [desc.name for desc in cur.description]
                    result = DataFrame(data=data, columns=columns)

            self._connection.commit()

        except psycopg.Error as e:
            raise DatabaseError(
                message=f"There was an SQL error while running the query {query}.",
                original_exception=e,
            ) from e
        else:
            logger.info("%s in %.3f seconds!", message, end - start)
            return result

    def create_utility_tables(self) -> None:
        if not self._connection:
            raise DatabaseError

        logger.info("Creating utility tables...")
        utility_sql_script = self._utility_sql_script.read_text()
        self.execute(
            query=utility_sql_script, message="Created utility tables succesfully"
        )

    def update_runners_tables(self, splits: dict[Path, datetime]) -> bool:
        """
        If there's currently a connection, run the main SQL script.
        """
        if not self._connection:
            raise DatabaseError

        logger.info("Updating the database tables...")
        sql_script = self._sql_script.read_text()
        new_updates = False

        for split, file_last_modified in splits.items():
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
            modified_script = sql_script.replace("runner", runner_name)
            modified_script = modified_script.replace("path", f"{split!s}")

            self.execute(
                query=modified_script,
                message=f"Updated the database tables for {runner_name} successfully",
            )

            self._last_updates_tracker.set_timestamp_now(file=split)
            new_updates = True

        if not new_updates:
            logger.info("The database is already up to date.")
        return new_updates

    def __del__(self) -> None:
        self.close_connection()
