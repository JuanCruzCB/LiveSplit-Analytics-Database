import logging
from dataclasses import dataclass
from pathlib import Path

logger = logging.getLogger(__name__)


@dataclass
class GoogleAPIConfig:
    service_account_secrets_file: Path | None
    google_sheet_id: str | None
    google_drive_folder_id: str | None

    def __init__(
        self,
        service_account_secrets_file: str | None,
        google_sheet_id: str | None,
        google_drive_folder_id: str | None,
    ) -> None:
        if service_account_secrets_file is None:
            self.service_account_secrets_file = service_account_secrets_file
        else:
            self.service_account_secrets_file = Path(service_account_secrets_file)
        self.google_sheet_id = google_sheet_id
        self.google_drive_folder_id = google_drive_folder_id

    def __post_init__(self) -> None:
        """
        Validate that the Google API configuration was initialized correctly.
        """
        if (
            self.service_account_secrets_file
            and not self.service_account_secrets_file.exists()
        ):
            msg = f"The file {self.service_account_secrets_file} does not exist."
            logger.error(msg)
            raise FileNotFoundError(msg)
