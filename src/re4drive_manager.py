from datetime import UTC, datetime
from pathlib import Path

from pydrive2.drive import GoogleDrive

from constants import Format


class RE4DriveManager:
    CURRENTLY_ALLOWED_SPLITS = (
        "splits luis.lss",
        "splits joker.lss",
        "splits mateo.lss",
        "splits arcadan.lss",
        "splits richy.lss",
        "splits derek.lss",
        "splits nevs.lss",
        "splits otaku.lss",
        "splits pocho.lss",
        "splits missing.lss",
    )

    def __init__(
        self,
        google_drive_folder_id: str,
        google_drive: GoogleDrive,
        splits_output_folder: Path,
        my_splits_file: Path,
    ) -> None:
        self._google_drive_folder_id = google_drive_folder_id
        self._google_drive = google_drive
        self._splits_output_folder = splits_output_folder
        self._my_splits_file = my_splits_file

    def _get_drive_files(self) -> list:
        """
        Returns a list with data about all the files that are currently on
        the Google Drive folder.
        """
        return self._google_drive.ListFile(
            {"q": f"'{self._google_drive_folder_id}' in parents and trashed=false"}
        ).GetList()

    def get_local_splits(self) -> dict[str, datetime]:
        """
        Checks the local folder containing the splits of the runners and
        returns a dict where each key is the splits file name and the value is
        that splits last modification time.
        """
        if not self._splits_output_folder.exists():
            msg = "The output folder for the splits of other runners does not exist."
            raise FileNotFoundError(msg)

        local_splits = {
            splits_file.stem: datetime.fromtimestamp(
                splits_file.stat().st_mtime, tz=UTC
            )
            for splits_file in self._splits_output_folder.glob(pattern="*.lss")
        }

        local_splits[self._my_splits_file.stem] = datetime.fromtimestamp(
            self._my_splits_file.stat().st_mtime, tz=UTC
        )

        return local_splits

    def _get_known_splits(self, drive_files: list) -> list:
        """
        Filter the list of splits files from the Google Drive folder
        to only include the ones that are currently allowed.

        Print a message for each unknown split file found,
        indicating that it was not downloaded.
        """
        allowed_splits = []
        for file in drive_files:
            title = file["title"]
            if "splits" not in title:
                continue

            if title in self.CURRENTLY_ALLOWED_SPLITS:
                allowed_splits.append(file)
            else:
                print(
                    f"Unknown splits file found: {title}. This file was not downloaded."
                )

        return allowed_splits

    def update_local_splits(self) -> None:
        """
        Update the local splits with their remote versions if the versions on the Google Drive folder
        are newer than the local ones.
        """
        if self._google_drive is None:
            msg = "We are not connected to Google Drive."
            raise ValueError(msg)

        local_splits = self.get_local_splits()
        drive_files = self._get_drive_files()
        known_splits = self._get_known_splits(drive_files)

        for splits_file in known_splits:
            splits_filename = splits_file["title"]

            last_modified_datetime_local = local_splits[
                splits_filename.replace(".lss", "")
            ]
            last_modified_datetime_remote = datetime.strptime(
                splits_file["modifiedDate"],
                Format.GOOGLE_DRIVE_DATE_TIME_FORMAT,
            ).replace(tzinfo=UTC)

            if last_modified_datetime_remote > last_modified_datetime_local:
                print(f"Downloading {splits_filename}...")
                splits_file.GetContentFile(self._splits_output_folder / splits_filename)
            else:
                print(
                    f"{splits_filename} is already up to date locally, so there's no need to download it."
                )
