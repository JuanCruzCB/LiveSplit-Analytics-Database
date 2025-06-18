from datetime import datetime
from pathlib import Path

from pydrive2.drive import GoogleDrive

from constants import Format, GOOGLE_DRIVE_TIMEZONE_OFFSET, CURRENTLY_ALLOWED_SPLITS


class RE4DriveManager:
    def __init__(
        self,
        google_drive: GoogleDrive,
        google_drive_folder_id: str,
        splits_output_folder: Path,
        my_splits_file: Path,
    ) -> None:
        self._google_drive = google_drive
        self._google_drive_folder_id = google_drive_folder_id
        self._splits_output_folder = splits_output_folder
        self._my_splits_file = my_splits_file

    def _timestamp_to_str(self, timestamp: float) -> str:
        """
        Converts a float timestamp to a string in the format specified by DATE_TIME_FORMAT.
        """
        return datetime.fromtimestamp(timestamp).strftime(Format.DATE_TIME_FORMAT.value)

    def _str_to_datetime(self, date: str) -> datetime:
        """
        Converts a string of a date to a datetime object in the format specified by GOOGLE_DRIVE_DATE_TIME_FORMAT.
        """
        return datetime.strptime(date, Format.DATE_TIME_FORMAT.value)

    def _get_drive_splits(self) -> list:
        """
        Returns a list with data about all the splits files that are currently on
        the Google Drive folder and that are allowed.
        """
        files = self._google_drive.ListFile(
            {"q": f"'{self._google_drive_folder_id}' in parents and trashed=false"}
        ).GetList()

        return [file for file in files if file["title"] in CURRENTLY_ALLOWED_SPLITS]

    def get_local_splits(self) -> dict[str, str]:
        """
        Checks the local folder containing the splits of the runners and
        returns a dict where each key is the splits file name and the value is
        that splits last modification time.
        """
        if not self._splits_output_folder.exists():
            raise FileNotFoundError(
                "The output folder for the splits of other runners does not exist."
            )

        local_splits = {
            splits_file.stem: self._timestamp_to_str(
                timestamp=splits_file.stat().st_mtime
            )
            for splits_file in self._splits_output_folder.glob(pattern="*.lss")
        }

        local_splits[self._my_splits_file.stem] = self._timestamp_to_str(
            timestamp=self._my_splits_file.stat().st_mtime
        )

        return local_splits

    def update_local_splits(self) -> None:
        """
        Update the local splits with their remote versions if the versions on the Google Drive folder
        are newer than the local ones.
        """
        if self._google_drive is None:
            raise ValueError("We are not connected to Google Drive.")

        local_splits = self.get_local_splits()

        for splits_file in self._get_drive_splits():
            title = splits_file["title"]
            splits_file_name = title.replace(".lss", "")

            modified_date = (
                datetime.strptime(
                    splits_file["modifiedDate"],
                    Format.GOOGLE_DRIVE_DATE_TIME_FORMAT.value,
                )
                - GOOGLE_DRIVE_TIMEZONE_OFFSET
            ).strftime(Format.DATE_TIME_FORMAT.value)

            if self._str_to_datetime(
                date=local_splits[splits_file_name]
            ) < self._str_to_datetime(date=modified_date):
                print(f"Downloading {title}...")
                splits_file.GetContentFile(self._splits_output_folder / title)
            else:
                print(
                    f"{title} is already up to date locally, so there's no need to download it."
                )
