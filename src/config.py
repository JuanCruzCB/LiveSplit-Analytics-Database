import logging
from dataclasses import dataclass
from pathlib import Path

import yaml

PROJECT_FOLDER = Path(__file__).parent.parent
YAML_CONFIG_FILE = PROJECT_FOLDER / "config" / "config.yaml"
LAST_UPDATES_FILE = PROJECT_FOLDER / "config" / "last_table_updates.json"
SQL_SCRIPT = PROJECT_FOLDER / "sql scripts" / "splits_database_builder.sql"
CONFIG_SQL_SCRIPT = PROJECT_FOLDER / "sql scripts" / "config.sql"

logger = logging.getLogger(__name__)


@dataclass
class Config:
    sql_script: Path
    config_sql_script: Path
    last_updates_file: Path
    other_runners_splits_folder: Path
    main_runner_splits_file: Path
    service_account_secrets_file: Path
    google_sheet_id: str
    google_drive_folder_id: str
    db_config: dict[str, str | int]
    allowed_runners: list[str]

    def validate(self) -> None:
        """
        Validates that all files and folders the project needs exist.
        """
        paths = [
            self.sql_script,
            self.config_sql_script,
            self.other_runners_splits_folder,
            self.main_runner_splits_file,
            self.service_account_secrets_file,
        ]
        for path in paths:
            if not path.exists():
                msg = f"The file or folder {path} does not exist."
                logger.exception(msg)
                raise FileNotFoundError(msg)


def load_config() -> Config:
    with YAML_CONFIG_FILE.open("r") as f:
        config = yaml.safe_load(f)

    try:
        other_runners_splits_folder = Path(
            config["main"]["other_runners_splits_folder"]
        )
        main_runner_splits_file = Path(config["main"]["main_runner_splits_file"])
        service_account_secrets_file = Path(
            config["main"]["service_account_secrets_file"]
        )
        google_sheet_id = config["main"]["google_sheet_id"]
        google_drive_folder_id = config["main"]["google_drive_folder_id"]

        db_config = config["database"]

        runners = [runner.strip() for runner in config["runners"] if runner.strip()]

        for runner in runners:
            if "," in runner or "-" in runner or " " in runner or "_" in runner:
                msg = "The runner names cannot have commas, hyphens, underscores or spaces."
                logger.exception(msg)
                raise ValueError(msg)

    except KeyError as e:
        msg = "The structure of the config.yaml file is incorrect."
        logger.exception(msg)
        raise ValueError(msg) from e

    cfg = Config(
        sql_script=SQL_SCRIPT,
        config_sql_script=CONFIG_SQL_SCRIPT,
        last_updates_file=LAST_UPDATES_FILE,
        other_runners_splits_folder=other_runners_splits_folder,
        main_runner_splits_file=main_runner_splits_file,
        service_account_secrets_file=service_account_secrets_file,
        google_sheet_id=google_sheet_id,
        google_drive_folder_id=google_drive_folder_id,
        db_config=db_config,
        allowed_runners=runners,
    )
    cfg.validate()
    return cfg


def setup_logging():
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%d/%m/%Y %I:%M:%S %p",
        handlers=[
            logging.FileHandler(PROJECT_FOLDER / "output" / "history.log"),
            logging.StreamHandler(),
        ],
    )
