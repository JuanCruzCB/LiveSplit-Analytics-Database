import logging
import time
from pathlib import Path

import psycopg
from pandas import DataFrame

from config import LocalDatabaseConfig
from db.exceptions import (
    ConnectionError,  # noqa: A004
    NoActiveConnectionError,
    QueryExecutionError,
)
from db.last_updates_tracker import LastUpdatesTracker
from splits.splits_file import SplitsFile

logger = logging.getLogger(__name__)

type OptionalParams = dict[str, str | int] | None


class DatabaseManager:
    def __init__(
        self,
        sql_script: Path,
        config_sql_script: Path,
        db_config: LocalDatabaseConfig,
        last_updates_tracker: LastUpdatesTracker,
    ) -> None:
        self._sql_script = sql_script
        self._config_sql_script = config_sql_script
        self._db_config = db_config
        self._last_updates_tracker = last_updates_tracker

        self._connection = None

    def open_connection(self) -> None:
        """
        Connect to the local postgres db using the
        hardcoded credentials.
        """
        try:
            self._connection = psycopg.connect(**self._db_config.to_dict())  # type: ignore  # noqa: PGH003
        except psycopg.Error as e:
            raise ConnectionError(
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
        params: OptionalParams = None,
    ) -> DataFrame:
        """
        Return a DataFrame with the results of running the specified query
        on the db.
        """
        if not self._connection:
            raise NoActiveConnectionError(db_config=self._db_config)

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
            raise QueryExecutionError(
                db_config=self._db_config,
                original_exception=e,
                message=f"There was an SQL error while running the query:\n {query}",
            ) from e
        else:
            logger.info("%s in %.3f seconds!", message, end - start)
            return result

    def create_config_tables(self) -> None:
        """
        Creates the necessary configuration tables in the db.
        """
        if not self._connection:
            raise NoActiveConnectionError(db_config=self._db_config)

        logger.info("Creating config tables...")
        config_sql_script = self._config_sql_script.read_text()
        self.execute(
            query=config_sql_script,
            message="Created config tables succesfully",
        )

    def _update_runner_table(self, sql_script: str, splits_file: SplitsFile) -> bool:
        """
        Attempt to update the tables for a specific runner, which only happens
        if the splits last modification time is newer than the last time
        that runner's tables tables were updated.
        """
        db_last_modified = self._last_updates_tracker.get_timestamp(
            file=splits_file.file_path,
        )
        if splits_file.is_older_than(dt=db_last_modified):
            logger.info(
                (
                    "Not updating the tables for splits file '%s' since they are "
                    "already up to date."
                ),
                splits_file.file_path.stem,
            )
            return False

        modified_script = sql_script.replace("runner", splits_file.runner_name)
        modified_script = modified_script.replace(
            "path",
            f"{splits_file.file_path_str}",
        )
        self.execute(
            query=modified_script,
            message=(
                "Updated the database tables for "
                f"{splits_file.runner_name} successfully!"
            ),
        )

        self._last_updates_tracker.set_timestamp_now(file=splits_file.file_path)
        return True

    def update_runners_tables(self, splits_files: list[SplitsFile]) -> bool:
        """
        If there's currently a connection, attempt to update the tables
        of all runners.

        Returns true if at least one of the runners' tables were updated,
        false otherwise.
        """
        if not self._connection:
            raise NoActiveConnectionError(db_config=self._db_config)

        logger.info("Updating the database tables...")
        sql_script = self._sql_script.read_text()

        new_updates = any(
            self._update_runner_table(sql_script=sql_script, splits_file=splits_file)
            for splits_file in splits_files
        )

        if not new_updates:
            logger.info("The database is already up to date.")
        return new_updates

    def __del__(self) -> None:
        """
        Closes the connection to the local Postgres database when
        the object is destroyed.
        """
        self.close_connection()
