from datetime import datetime
from pathlib import Path

from pydrive2.drive import GoogleDrive

from constants import Format, GOOGLE_DRIVE_TIMEZONE_OFFSET


class RE4DriveManager:
    def __init__(
        self,
        google_drive: GoogleDrive,
        google_drive_folder_id: str,
        currently_allowed_runners: list[str],
        splits_output_folder: Path,
        my_splits_file: Path,
    ) -> None:
        self._google_drive = google_drive
        self._google_drive_folder_id = google_drive_folder_id
        self._allowed_splits = [
            f"splits {runner}.lss" for runner in currently_allowed_runners
        ]
        self._splits_output_folder = splits_output_folder
        self._my_splits_file = my_splits_file

    def _convert_time_str(self, timestamp: float) -> str:
        """
        Converts a float timestamp to a string in the format specified by DATE_TIME_FORMAT.
        """
        return datetime.fromtimestamp(timestamp).strftime(Format.DATE_TIME_FORMAT.value)

    def _convert_time_obj(self, date: str) -> datetime:
        """
        Converts a string of a date to a datetime object in the format specified by GOOGLE_DRIVE_DATE_TIME_FORMAT.
        """
        return datetime.strptime(date, Format.DATE_TIME_FORMAT.value)

    def _get_drive_files(self) -> list:
        """
        Returns a list with data about all the files currently on the Google Drive folder.
        """
        return self._google_drive.ListFile(
            {"q": f"'{self._google_drive_folder_id}' in parents and trashed=false"}
        ).GetList()

    def _get_local_splits_mtime(self) -> dict[str, str]:
        """
        Checks the local folder containing the splits of the runners and
        returns a dict where each key is the splits file name and the value is
        that splits last modification time.
        """
        if not self._splits_output_folder.exists():
            raise Exception(
                "The output folder for the splits of other runners does not exist."
            )

        local_splits = {
            splits_file.stem: self._convert_time_str(
                timestamp=splits_file.stat().st_mtime
            )
            for splits_file in self._splits_output_folder.glob(pattern="*.lss")
        }

        local_splits[self._my_splits_file.stem] = self._convert_time_str(
            timestamp=self._my_splits_file.stat().st_mtime
        )

        return local_splits

    def download_splits(self) -> dict[str, str]:
        if self._google_drive is None:
            raise Exception("We are not connected to Google Drive.")

        local_splits = self._get_local_splits_mtime()

        drive_splits = [
            file
            for file in self._get_drive_files()
            if file["title"] in self._allowed_splits
        ]

        for file in drive_splits:
            title = file["title"]

            modified_date = (
                datetime.strptime(
                    file["modifiedDate"], Format.GOOGLE_DRIVE_DATE_TIME_FORMAT.value
                )
                - GOOGLE_DRIVE_TIMEZONE_OFFSET
            ).strftime(Format.DATE_TIME_FORMAT.value)

            file_name = title.replace(".lss", "")
            if self._convert_time_obj(
                date=local_splits[file_name]
            ) < self._convert_time_obj(date=modified_date):
                print(f"Downloading {title}...")
                file.GetContentFile(self._splits_output_folder / title)
            else:
                print(
                    f"{title} is already up to date locally, so there's no need to download it."
                )

        return self._get_local_splits_mtime()
