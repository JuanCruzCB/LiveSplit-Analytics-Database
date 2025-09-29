import logging
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml

YAML_CONFIG_FILE = Path(__file__).parent.parent / "config" / "config.yaml"
OUTPUT_DIR = Path(__file__).parent.parent / "output"
LAST_UPDATES_FILE = Path(__file__).parent.parent / "config" / "last_table_updates.json"

OUTPUT_DIR.mkdir(exist_ok=True)

logger = logging.getLogger(__name__)


def setup_logging() -> None:
    """
    Sets up logging configuration for the application.
    """
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%d/%m/%Y %I:%M:%S %p",
        handlers=[
            logging.FileHandler(OUTPUT_DIR / "history.log"),
            logging.StreamHandler(),
        ],
    )


@dataclass
class MainRunnerConfig:
    name: str
    splits_file: Path

    def __post_init__(self) -> None:
        """
        Validate that the main runner configuration was initialized correctly.
        """
        if "," in self.name or "-" in self.name or "_" in self.name or " " in self.name:
            msg = (
                "The main runner name cannot have commas, hyphens, "
                "underscores or spaces."
            )
            logger.exception(msg)
            raise ValueError(msg)

        if not self.splits_file.exists():
            msg = f"The file {self.splits_file} does not exist."
            logger.exception(msg)
            raise FileNotFoundError(msg)


@dataclass
class OtherRunnersConfig:
    names: list[str]
    splits_folder: Path

    def __post_init__(self) -> None:
        """
        Validate that the other runners configuration was initialized correctly.
        """
        for name in self.names:
            if "," in name or "-" in name or "_" in name or " " in name:
                msg = (
                    "The runner names cannot have commas, hyphens, "
                    "underscores or spaces."
                )
                logger.exception(msg)
                raise ValueError(msg)

        if not self.splits_folder.exists():
            msg = f"The folder {self.splits_folder} does not exist."
            logger.exception(msg)
            raise FileNotFoundError(msg)


@dataclass
class GoogleAPIConfig:
    service_account_secrets_file: Path | None
    google_sheet_id: str | None
    google_drive_folder_id: str | None

    def __init__(
        self,
        service_account_secrets_file: str | None,
        google_sheet_id: str | None,
        google_drive_folder_id: str | None,
    ) -> None:
        if service_account_secrets_file is None:
            self.service_account_secrets_file = service_account_secrets_file
        else:
            self.service_account_secrets_file = Path(service_account_secrets_file)
        self.google_sheet_id = google_sheet_id
        self.google_drive_folder_id = google_drive_folder_id

    def __post_init__(self) -> None:
        """
        Validate that the Google API configuration was initialized correctly.
        """
        if (
            self.service_account_secrets_file
            and not self.service_account_secrets_file.exists()
        ):
            msg = f"The file {self.service_account_secrets_file} does not exist."
            logger.exception(msg)
            raise FileNotFoundError(msg)


@dataclass
class LocalDatabaseConfig:
    dbname: str
    user: str
    host: str
    password: int | str
    port: int

    def to_dict(self) -> dict[str, Any]:
        """
        Returns the database configuration as a dictionary.
        """
        return {
            "dbname": self.dbname,
            "user": self.user,
            "host": self.host,
            "password": self.password,
            "port": self.port,
        }


@dataclass
class SQLScripts:
    main_sql_script: Path
    config_sql_script: Path

    def __post_init__(self) -> None:
        """
        Validate that the SQL scripts configuration was initialized correctly.
        """
        if not self.main_sql_script.exists():
            msg = f"The file {self.main_sql_script} does not exist."
            logger.exception(msg)
            raise FileNotFoundError(msg)
        if not self.config_sql_script.exists():
            msg = f"The file {self.config_sql_script} does not exist."
            logger.exception(msg)
            raise FileNotFoundError(msg)


@dataclass
class Config:
    main_runner: MainRunnerConfig
    other_runners: OtherRunnersConfig
    google_api: GoogleAPIConfig
    local_db: LocalDatabaseConfig
    sql_scripts: SQLScripts
    last_table_updates_file: Path
    output_dir: Path


def load_config() -> Config:
    """
    Loads configuration from the YAML file into a Config object and returns it.
    """
    with YAML_CONFIG_FILE.open("r") as f:
        config: dict[Any, Any] = yaml.safe_load(f)

    try:
        main_runner = MainRunnerConfig(
            name=config["main_runner"]["name"],
            splits_file=Path(config["main_runner"]["splits_file"]),
        )

        other_runners = OtherRunnersConfig(
            names=config["other_runners"]["names"],
            splits_folder=Path(config["other_runners"]["splits_folder"]),
        )

        google_api_dict = config["google_api"]
        google_api = GoogleAPIConfig(
            service_account_secrets_file=google_api_dict[
                "service_account_secrets_file"
            ],
            google_sheet_id=google_api_dict["google_sheet_id"],
            google_drive_folder_id=google_api_dict["google_drive_folder_id"],
        )

        local_db_dict = config["local_database_config"]
        local_db = LocalDatabaseConfig(
            dbname=local_db_dict["dbname"],
            user=local_db_dict["user"],
            host=local_db_dict["host"],
            password=local_db_dict["password"],
            port=local_db_dict["port"],
        )

        sql_scripts = SQLScripts(
            main_sql_script=Path(config["sql_scripts"]["main_sql_script"]).resolve(),
            config_sql_script=Path(
                config["sql_scripts"]["config_sql_script"],
            ).resolve(),
        )

    except KeyError as e:
        msg = "The structure of the config.yaml file is incorrect."
        logger.exception(msg)
        raise ValueError(msg) from e

    return Config(
        main_runner=main_runner,
        other_runners=other_runners,
        google_api=google_api,
        local_db=local_db,
        sql_scripts=sql_scripts,
        last_table_updates_file=LAST_UPDATES_FILE,
        output_dir=OUTPUT_DIR,
    )
