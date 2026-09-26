from pathlib import Path

from pydantic import BaseModel, field_validator


class GoogleAPIConfig(BaseModel):
    service_account_secrets_file: Path | None = None
    google_sheet_id: str | None = None
    google_drive_folder_id: str | None = None

    @field_validator("service_account_secrets_file")
    @classmethod
    def _file_must_exist(cls, v: Path | None) -> Path | None:
        if v is not None and not v.exists():
            msg = f"The file {v} does not exist."
            raise ValueError(msg)
        return v
