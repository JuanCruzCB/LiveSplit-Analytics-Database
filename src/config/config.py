import logging
from dataclasses import dataclass
from pathlib import Path

import yaml

from config.exclude_data_before_config import ExcludeDataBeforeConfig
from config.google_api_config import GoogleAPIConfig
from config.local_database_config import LocalDatabaseConfig
from config.main_runner_config import MainRunnerConfig
from config.other_runners_config import OtherRunnersConfig
from config.sql_scripts_config import SQLScriptsConfig

PROJECT_DIR = Path(__file__).parent.parent.parent
YAML_CONFIG_FILE = PROJECT_DIR / "config" / "config.yaml"
LAST_UPDATES_FILE = PROJECT_DIR / "config" / "last_table_updates.json"
OUTPUT_DIR = PROJECT_DIR / "output"


logger = logging.getLogger(__name__)


@dataclass
class Config:
    main_runner: MainRunnerConfig
    other_runners: OtherRunnersConfig
    google_api: GoogleAPIConfig
    local_db: LocalDatabaseConfig
    sql_scripts: SQLScriptsConfig
    exclude_data_before: ExcludeDataBeforeConfig
    last_table_updates_file: Path
    output_dir: Path


def load_config() -> Config:
    """
    Loads configuration from the YAML file into a Config object and returns it.
    """
    OUTPUT_DIR.mkdir(exist_ok=True)

    if not YAML_CONFIG_FILE.exists():
        msg = f"The configuration file '{YAML_CONFIG_FILE}' does not exist."
        logger.exception(msg)
        raise FileNotFoundError(msg)

    with YAML_CONFIG_FILE.open("r") as f:
        config = yaml.safe_load(f)

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

        local_db_dict = config["local_database"]
        local_db = LocalDatabaseConfig(
            dbname=local_db_dict["dbname"],
            user=local_db_dict["user"],
            host=local_db_dict["host"],
            password=local_db_dict["password"],
            port=local_db_dict["port"],
        )

        sql_scripts = SQLScriptsConfig(
            builder=Path(config["sql_scripts"]["builder"]).resolve(),
            config=Path(config["sql_scripts"]["config"]).resolve(),
        )

        exclude_data_before = ExcludeDataBeforeConfig(
            date=config.get("exclude_data_before", None),
        )

    except KeyError as e:
        msg = f"The structure of the '{YAML_CONFIG_FILE}' file is invalid."
        logger.exception(msg)
        raise ValueError(msg) from e

    return Config(
        main_runner=main_runner,
        other_runners=other_runners,
        google_api=google_api,
        local_db=local_db,
        sql_scripts=sql_scripts,
        exclude_data_before=exclude_data_before,
        last_table_updates_file=LAST_UPDATES_FILE,
        output_dir=OUTPUT_DIR,
    )
