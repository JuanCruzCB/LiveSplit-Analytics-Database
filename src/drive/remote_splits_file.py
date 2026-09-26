from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import cast

from pydrive2.files import GoogleDriveFile  # pyright: ignore[reportMissingTypeStubs]

_GOOGLE_DRIVE_DATE_TIME_FORMAT = "%Y-%m-%dT%H:%M:%S.%fZ"


@dataclass(frozen=True)
class RemoteSplitsFile:
    """
    A splits file living in the Google Drive folder.

    Wraps the raw pydrive2 object for type safety.
    """

    title: str
    modified_at: datetime
    _raw: GoogleDriveFile

    @classmethod
    def from_drive_file(cls, raw: GoogleDriveFile) -> "RemoteSplitsFile":
        """
        Create a RemoteSplitsFile instance from a raw pydrive2 GoogleDriveFile
        object.
        """
        return cls(
            title=cast("str", raw["title"]),
            modified_at=datetime.strptime(
                cast("str", raw["modifiedDate"]),
                _GOOGLE_DRIVE_DATE_TIME_FORMAT,
            ).replace(tzinfo=UTC),
            _raw=raw,
        )

    @property
    def runner_name(self) -> str:
        """
        Returns the runner name that this splits file belongs to,
        assuming that the splits file is named in the proper format:
        "splits <runner_name>.lss"
        """
        return Path(self.title).stem.removeprefix("splits ")

    def download_to(self, path: Path) -> None:
        """
        Download the remote splits file to the given local path.
        """
        self._raw.GetContentFile(filename=path)  # pyright: ignore[reportUnknownMemberType]
