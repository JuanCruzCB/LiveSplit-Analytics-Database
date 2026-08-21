import logging
from dataclasses import dataclass
from pathlib import Path

from pydrive2.auth import GoogleAuth  # pyright: ignore[reportMissingTypeStubs]
from pydrive2.drive import GoogleDrive  # pyright: ignore[reportMissingTypeStubs]

logger = logging.getLogger(__name__)


@dataclass
class GoogleDriveAuth:
    """
    Manage authentication with Google Drive API.
    """

    service_account_secrets_file: Path | None

    def auth(self) -> GoogleDrive:
        """
        Authenticate with Google Drive using PyDrive2 based
        on the auth data inside a service_account_secrets.json file
        which contains the credentials.
        """
        try:
            logger.info("Authenticating on Google Drive...")
            gauth = GoogleAuth(
                settings={
                    "client_config_backend": "service",
                    "service_config": {
                        "client_json_file_path": str(self.service_account_secrets_file),
                        "client_user_email": "",
                    },
                    "oauth_scope": [
                        "https://www.googleapis.com/auth/drive",
                    ],
                },
            )
            gauth.ServiceAuth()
        except (OSError, ValueError) as e:
            msg = f"Failed to authenticate with Google Drive: {e}"
            logger.exception(msg)
            raise RuntimeError(msg) from e
        else:
            logger.info("Authentication for Google Drive was succesful!")
            return GoogleDrive(gauth)
