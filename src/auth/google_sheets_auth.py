import logging
from dataclasses import dataclass
from pathlib import Path

from google.oauth2.service_account import Credentials
from gspread import Client, authorize

logger = logging.getLogger(__name__)


@dataclass
class GoogleSheetsAuth:
    """
    Manage authentication with Google Sheets API.
    """

    service_account_secrets_file: Path

    def auth(self) -> Client:
        """
        Authenticate with Google Sheets using gspread, based
        on the auth data inside a service_account_secrets.json file
        which contains the credentials.
        """
        try:
            logger.info("Authenticating on Google Sheets...")
            client = authorize(
                credentials=Credentials.from_service_account_file(
                    filename=str(self.service_account_secrets_file),
                    scopes=[
                        "https://www.googleapis.com/auth/spreadsheets",
                        "https://www.googleapis.com/auth/drive",
                    ],
                ),
            )
        except (OSError, ValueError) as e:
            msg = f"Failed to authenticate with Google Sheets: {e}"
            logger.exception(msg)
            raise RuntimeError(msg) from e
        else:
            logger.info("Authentication for Google Sheets was succesful!")
            return client
