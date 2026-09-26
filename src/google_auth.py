from pathlib import Path

from gspread import Client, service_account
from loguru import logger
from pydrive2.auth import GoogleAuth  # pyright: ignore[reportMissingTypeStubs]
from pydrive2.drive import GoogleDrive  # pyright: ignore[reportMissingTypeStubs]

_DRIVE_AUTH_SCOPE = "https://www.googleapis.com/auth/drive"
_SHEETS_AUTH_SCOPE = "https://www.googleapis.com/auth/spreadsheets"


def authenticate_google_drive(secrets_file: Path) -> GoogleDrive:
    """
    Authenticate with Google Drive using a service account secrets file.
    """
    logger.info("Authenticating on Google Drive...")
    gauth = GoogleAuth(
        settings={
            "client_config_backend": "service",
            "service_config": {
                "client_json_file_path": str(secrets_file),
                "client_user_email": "",
            },
            "oauth_scope": [_DRIVE_AUTH_SCOPE],
        },
    )
    gauth.ServiceAuth()
    logger.info("Authentication for Google Drive was successful!")
    return GoogleDrive(auth=gauth)


def authenticate_google_sheets(secrets_file: Path) -> Client:
    """
    Authenticate with Google Sheets using a service account secrets file.
    """
    logger.info("Authenticating on Google Sheets...")
    client = service_account(
        filename=secrets_file,
        scopes=[_SHEETS_AUTH_SCOPE, _DRIVE_AUTH_SCOPE],
    )
    logger.info("Authentication for Google Sheets was successful!")
    return client
