from dataclasses import dataclass
from pathlib import Path

import yaml

PROJECT_FOLDER = Path(__file__).parent.parent
YAML_CONFIG_FILE = PROJECT_FOLDER / "config" / "config.yaml"
INDIVIDUAL_SQL_FILE = PROJECT_FOLDER / "scripts" / "NG Pro Individual.sql"
GLOBAL_SQL_FILE = PROJECT_FOLDER / "scripts" / "NG Pro Global (LIGHT).sql"
LAST_UPDATES_FILE = PROJECT_FOLDER / "config" / "last_table_updates.json"


@dataclass
class Config:
    individual_sql_file: Path
    global_sql_file: Path
    last_updates_file: Path
    other_runners_splits_folder: Path
    main_runner_splits_file: Path
    service_account_secrets_file: Path
    google_sheet_url: str
    google_drive_folder_id: str
    db_config: dict[str, str]
    allowed_runners: list[str]

    def validate(self) -> None:
        """
        Validates that all files and folders the project needs exist.
        """
        paths = [
            self.individual_sql_file,
            self.global_sql_file,
            self.other_runners_splits_folder,
            self.main_runner_splits_file,
            self.service_account_secrets_file,
        ]
        for path in paths:
            if not path.exists():
                msg = f"The file or folder {path} does not exist."
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
        google_sheet_url = config["main"]["google_sheet_url"]
        google_drive_folder_id = config["main"]["google_drive_folder_id"]

        db_config = config["database"]

        runners = [runner.strip() for runner in config["runners"] if runner.strip()]

    except KeyError as err:
        msg = "The structure of the config.yaml file is incorrect."
        raise ValueError(msg) from err

    cfg = Config(
        individual_sql_file=INDIVIDUAL_SQL_FILE,
        global_sql_file=GLOBAL_SQL_FILE,
        last_updates_file=LAST_UPDATES_FILE,
        other_runners_splits_folder=other_runners_splits_folder,
        main_runner_splits_file=main_runner_splits_file,
        service_account_secrets_file=service_account_secrets_file,
        google_sheet_url=google_sheet_url,
        google_drive_folder_id=google_drive_folder_id,
        db_config=db_config,
        allowed_runners=runners,
    )
    cfg.validate()
    return cfg
