from pathlib import Path

from gspread import authorize
from google.oauth2.service_account import Credentials
from pydrive2.auth import GoogleAuth
from pydrive2.drive import GoogleDrive


class GoogleAuthManager:
    def __init__(self, service_account_path: Path):
        self._service_account_path = service_account_path
        try:
            self._google_drive = self._auth_google_drive()
            self._gspread_client = self._auth_google_sheets()
        except Exception as e:
            raise Exception(
                f"Failed to authenticate with Google Drive or Google Sheets: {e}"
            )
        print("Logged in to Google Drive and Google Sheets succesfully.")

    @property
    def google_drive(self):
        return self._google_drive

    @property
    def gspread_client(self):
        return self._gspread_client

    def _auth_google_drive(self):
        gauth = GoogleAuth(
            settings={
                "client_config_backend": "service",
                "service_config": {
                    "client_json_file_path": str(self._service_account_path),
                    "client_user_email": "",
                },
                "oauth_scope": [
                    "https://www.googleapis.com/auth/drive",
                ],
            }
        )
        gauth.ServiceAuth()
        return GoogleDrive(gauth)

    def _auth_google_sheets(self):
        return authorize(
            credentials=Credentials.from_service_account_file(
                filename=self._service_account_path,
                scopes=[
                    "https://www.googleapis.com/auth/spreadsheets",
                    "https://www.googleapis.com/auth/drive",
                ],
            )
        )
