from datetime import datetime, timedelta
from pathlib import Path

from pydrive2.drive import GoogleDrive

from constants import Format


class RE4DriveManager:
    GOOGLE_DRIVE_TIMEZONE_OFFSET = timedelta(hours=3)
    GOOGLE_DRIVE_FOLDER_ID = "1-OvGMbjiemrxMaie166Cmwbu3k5WvXGh"
    CURRENTLY_ALLOWED_SPLITS = [
        "splits luis.lss",
        "splits joker.lss",
        "splits mateo.lss",
        "splits arcadan.lss",
        "splits richy.lss",
        "splits derek.lss",
        "splits nevs.lss",
        "splits otaku.lss",
        "splits pocho.lss",
    ]

    def __init__(
        self,
        google_drive: GoogleDrive,
        splits_output_folder: Path,
        my_splits_file: Path,
    ) -> None:
        self._google_drive = google_drive
        self._splits_output_folder = splits_output_folder
        self._my_splits_file = my_splits_file

    def _get_drive_splits(self) -> list:
        """
        Returns a list with data about all the splits files that are currently on
        the Google Drive folder and that are allowed.
        """
        files = self._google_drive.ListFile(
            {"q": f"'{self.GOOGLE_DRIVE_FOLDER_ID}' in parents and trashed=false"}
        ).GetList()

        return [
            file for file in files if file["title"] in self.CURRENTLY_ALLOWED_SPLITS
        ]

    def get_local_splits(self) -> dict[str, datetime]:
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
            splits_file.stem: datetime.fromtimestamp(splits_file.stat().st_mtime)
            for splits_file in self._splits_output_folder.glob(pattern="*.lss")
        }

        local_splits[self._my_splits_file.stem] = datetime.fromtimestamp(
            self._my_splits_file.stat().st_mtime
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
            splits_name = splits_file["title"]
            splits_file_name = splits_name.replace(".lss", "")

            last_modified_date_time_local = local_splits[splits_file_name]
            last_modified_date_time_remote = (
                datetime.strptime(
                    splits_file["modifiedDate"],
                    Format.GOOGLE_DRIVE_DATE_TIME_FORMAT.value,
                )
                - self.GOOGLE_DRIVE_TIMEZONE_OFFSET
            )

            if last_modified_date_time_remote > last_modified_date_time_local:
                print(f"Downloading {splits_name}...")
                splits_file.GetContentFile(self._splits_output_folder / splits_name)
            else:
                print(
                    f"{splits_name} is already up to date locally, so there's no need to download it."
                )
