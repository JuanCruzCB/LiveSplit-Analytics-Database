import logging
from pathlib import Path

from google.oauth2.service_account import Credentials
from gspread import authorize
from pydrive2.auth import GoogleAuth
from pydrive2.drive import GoogleDrive

logger = logging.getLogger(__name__)


class GoogleAuthManager:
    """
    Authenticate with Google Drive and Google Sheets using a service account, by
    using the credentials inside a service_account_secrets.json file.
    """

    def __init__(self, service_account_secrets_file: Path):
        logger.info("Logging in to Google Drive and Google Sheets...")
        self._service_account_secrets_file = service_account_secrets_file
        try:
            self._google_drive = self._auth_google_drive()
            self._gspread_client = self._auth_google_sheets()
            logger.info("Logged in succesfully!")
        except (OSError, ValueError) as e:
            msg = f"Failed to authenticate with Google Drive or Google Sheets: {e}"
            logger.exception(msg)
            raise RuntimeError(msg) from e

    @property
    def google_drive(self):
        return self._google_drive

    @property
    def gspread_client(self):
        return self._gspread_client

    def _auth_google_drive(self):
        """
        Authenticate with Google Drive using PyDrive2 based
        on the auth data inside a service account file.
        """
        gauth = GoogleAuth(
            settings={
                "client_config_backend": "service",
                "service_config": {
                    "client_json_file_path": str(self._service_account_secrets_file),
                    "client_user_email": "",
                },
                "oauth_scope": [
                    "https://www.googleapis.com/auth/drive",
                ],
            },
        )
        gauth.ServiceAuth()
        return GoogleDrive(gauth)

    def _auth_google_sheets(self):
        """
        Authenticate with Google Sheets using gspread based
        on the auth data inside a service account file.
        """
        return authorize(
            credentials=Credentials.from_service_account_file(
                filename=str(self._service_account_secrets_file),
                scopes=[
                    "https://www.googleapis.com/auth/spreadsheets",
                    "https://www.googleapis.com/auth/drive",
                ],
            ),
        )
