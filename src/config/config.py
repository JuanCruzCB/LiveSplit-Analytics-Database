from datetime import UTC, date, datetime
from pathlib import Path

import yaml
from loguru import logger
from pydantic import BaseModel, ConfigDict, ValidationError, field_validator

from config.google_api_config import GoogleAPIConfig
from config.local_database_config import LocalDatabaseConfig
from config.main_runner_config import MainRunnerConfig
from config.other_runners_config import OtherRunnersConfig
from config.paths import LAST_UPDATES_FILE, OUTPUT_DIR, YAML_CONFIG_FILE
from config.sql_scripts_config import SQLScriptsConfig


class Config(BaseModel):
    model_config = ConfigDict(frozen=True)  # pyright: ignore[reportUnannotatedClassAttribute]

    main_runner: MainRunnerConfig
    other_runners: OtherRunnersConfig
    google_api: GoogleAPIConfig
    local_database: LocalDatabaseConfig
    sql_scripts: SQLScriptsConfig
    exclude_data_before: date | None = None
    last_table_updates_file: Path = LAST_UPDATES_FILE
    output_dir: Path = OUTPUT_DIR

    @field_validator("exclude_data_before")
    @classmethod
    def _must_be_in_the_past(cls, v: date | None) -> date | None:
        """
        Validate that the date is in the correct format YYYY-MM-DD and that it is before
        the current date.
        """
        if v is not None and v >= datetime.now(tz=UTC).date():
            msg = f"The date {v} must be before the current date."
            raise ValueError(msg)
        return v

    @property
    def exclude_data_before_str(self) -> str:
        """
        Return the exclude_data_before date as a string in the format YYYY-MM-DD.

        If the date is None, return a default date string "2000-01-01".
        """
        return (
            self.exclude_data_before.strftime(format="%Y-%m-%d")
            if self.exclude_data_before
            else "2000-01-01"
        )


def load_config() -> Config:
    """
    Loads configuration from the YAML file into a Config object and returns it.
    """
    OUTPUT_DIR.mkdir(exist_ok=True)

    if not YAML_CONFIG_FILE.exists():
        msg = f"The configuration file '{YAML_CONFIG_FILE}' does not exist."
        logger.error(msg)
        raise FileNotFoundError(msg)

    with YAML_CONFIG_FILE.open("r") as f:
        raw = yaml.safe_load(stream=f)  # pyright: ignore[reportAny]

    if not isinstance(raw, dict):
        msg = f"'{YAML_CONFIG_FILE}' must contain a mapping at the top level."
        logger.error(msg)
        raise TypeError(msg)

    try:
        return Config.model_validate(obj=raw)
    except ValidationError as e:
        logger.error(f"Invalid configuration in {YAML_CONFIG_FILE}:\n{e}")
        raise
