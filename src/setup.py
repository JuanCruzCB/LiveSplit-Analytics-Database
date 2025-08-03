from os import getenv
from pathlib import Path

from dotenv import load_dotenv

PROJECT_FOLDER = Path(__file__).parent.parent

GOOGLE_SERVICE_ACCOUNT_SECRETS_FILE = (
    PROJECT_FOLDER / "credentials" / "service_account_secrets.json"
)
MAIN_SQL_FILE = PROJECT_FOLDER / "scripts" / "NG Pro Individual.sql"
GLOBAL_SQL_FILE = PROJECT_FOLDER / "scripts" / "NG Pro Global (LIGHT).sql"
LAST_UPDATES_FILE = PROJECT_FOLDER / "info" / "last_table_updates.json"


def load_environment_variables() -> tuple[str, str, str, str]:
    """
    Loads the 4 environment variables from the .env file and
    returns them if all of them were set.
    """
    load_dotenv()
    my_splits_file_str = getenv("MY_SPLITS_FILE")
    other_runners_splits_folder_str = getenv("OTHER_RUNNERS_SPLITS_FOLDER")
    google_sheet_url = getenv("GOOGLE_SHEET_URL")
    google_drive_folder_id = getenv("GOOGLE_DRIVE_FOLDER_ID")

    if (
        my_splits_file_str is None
        or other_runners_splits_folder_str is None
        or google_sheet_url is None
        or google_drive_folder_id is None
    ):
        msg = "The 4 environment variables in the .env file must be set."
        raise ValueError(msg)

    return (
        my_splits_file_str,
        other_runners_splits_folder_str,
        google_sheet_url,
        google_drive_folder_id,
    )


def validate_paths(my_splits_file: str, other_runners_splits_folder: str) -> None:
    """
    Validates that all files the project needs actually exist.
    """
    for path in [
        GOOGLE_SERVICE_ACCOUNT_SECRETS_FILE,
        MAIN_SQL_FILE,
        GLOBAL_SQL_FILE,
        LAST_UPDATES_FILE,
        Path(my_splits_file),
        Path(other_runners_splits_folder),
    ]:
        if not path.exists():
            msg = f"The path {path} does not exist."
            raise FileNotFoundError(msg)
