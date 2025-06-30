from enum import Enum, StrEnum
from pathlib import Path

PROJECT_FOLDER = Path(__file__).parent.parent


class Files(Enum):
    GOOGLE_SERVICE_ACCOUNT_SECRETS_FILE = (
        PROJECT_FOLDER / "credentials" / "service_account_secrets.json"
    )
    MAIN_SQL_FILE = PROJECT_FOLDER / "scripts" / "NG Pro Individual.sql"
    GLOBAL_SQL_FILE = PROJECT_FOLDER / "scripts" / "NG Pro Global.sql"
    LAST_UPDATES_FILE = PROJECT_FOLDER / "info" / "last_table_updates.json"


class Format(StrEnum):
    GOOD_DATE_FORMAT = "%d/%m/%Y"
    DATE_TIME_FORMAT = "%d/%m/%Y %H:%M:%S"
    GOOGLE_DRIVE_DATE_TIME_FORMAT = "%Y-%m-%dT%H:%M:%S.%fZ"
    BAD_DATE_FORMAT = "%Y-%m-%d"
