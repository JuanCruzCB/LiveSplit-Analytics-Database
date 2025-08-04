from pathlib import Path

import yaml

PROJECT_FOLDER = Path(__file__).parent.parent

MAIN_SQL_FILE = PROJECT_FOLDER / "scripts" / "NG Pro Individual.sql"
GLOBAL_SQL_FILE = PROJECT_FOLDER / "scripts" / "NG Pro Global (LIGHT).sql"
LAST_UPDATES_FILE = PROJECT_FOLDER / "config" / "last_table_updates.json"


def load_config() -> tuple[str, str, str, str, str, dict[str, str], list[str]]:
    with (PROJECT_FOLDER / "config" / "config.yaml").open("r") as f:
        config = yaml.safe_load(f)

    try:
        other_runners_splits_folder = config["main"]["other_runners_splits_folder"]
        my_splits_file = config["main"]["my_splits_file"]
        service_account_secrets_file = config["main"]["service_account_secrets_file"]
        google_sheet_url = config["main"]["google_sheet_url"]
        google_drive_folder_id = config["main"]["google_drive_folder_id"]

        db_config = config["database"]

        runners = config["runners"]

    except KeyError as err:
        msg = "The structure of the config.yaml file is incorrect."
        raise ValueError(msg) from err

    return (
        other_runners_splits_folder,
        my_splits_file,
        service_account_secrets_file,
        google_sheet_url,
        google_drive_folder_id,
        db_config,
        runners,
    )


def validate_paths(
    other_runners_splits_folder: str,
    my_splits_file: str,
    service_account_secrets_file: str,
) -> None:
    """
    Validates that all files the project needs actually exist.
    """
    for path in [
        MAIN_SQL_FILE,
        GLOBAL_SQL_FILE,
        LAST_UPDATES_FILE,
        Path(my_splits_file),
        Path(other_runners_splits_folder),
        Path(service_account_secrets_file),
    ]:
        if not path.exists():
            if path.is_file():
                msg = f"The file {path} does not exist."
            elif path.is_dir():
                msg = f"The folder {path} does not exist."
            raise FileNotFoundError(msg)
