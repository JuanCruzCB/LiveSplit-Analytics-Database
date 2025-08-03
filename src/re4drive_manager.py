from datetime import UTC, datetime

from pydrive2.drive import GoogleDrive

from re4splits_manager import RE4SplitsManager


class RE4DriveManager:
    GOOGLE_DRIVE_DATE_TIME_FORMAT = "%Y-%m-%dT%H:%M:%S.%fZ"

    def __init__(
        self,
        google_drive_folder_id: str,
        google_drive: GoogleDrive,
        splits_manager: RE4SplitsManager,
    ) -> None:
        self._google_drive_folder_id = google_drive_folder_id
        self._google_drive = google_drive
        self._splits_manager = splits_manager

    def _get_drive_files(self) -> list:
        """
        Returns a list with data about all the files that are currently on
        the Google Drive folder.
        """
        return self._google_drive.ListFile(
            {"q": f"'{self._google_drive_folder_id}' in parents and trashed=false"}
        ).GetList()

    def _get_allowed_splits_drive(self) -> list:
        """
        Filter the list of splits files from the Google Drive folder
        to only include the ones that are currently allowed.

        Print a message for each unknown split file found,
        indicating that it was not downloaded.
        """
        allowed_splits = []
        for file in self._get_drive_files():
            title = file["title"]
            if "splits" not in title:
                continue

            if title in self._splits_manager.CURRENTLY_ALLOWED_SPLITS:
                allowed_splits.append(file)
            else:
                print(
                    f"Unknown splits file found: {title}. This file was not downloaded."
                )

        return allowed_splits

    def update_local_splits(self) -> None:
        """
        Update the local splits with their remote versions if the versions
        on the Google Drive folder are newer than the local ones.

        Additionally, also download splits file that are allowed but don't
        yet exist locally because they haven't been downloaded yet.
        """
        if self._google_drive is None:
            msg = "We are not connected to Google Drive."
            raise ValueError(msg)

        local_splits = self._splits_manager.get_splits_names()
        allowed_splits_drive = self._get_allowed_splits_drive()

        for splits_file in allowed_splits_drive:
            splits_filename = splits_file["title"]

            if (splits_filename.replace(".lss", "")) not in local_splits:
                print(f"Downloading {splits_filename} for the first time...")
                splits_file.GetContentFile(
                    self._splits_manager.splits_output_folder / splits_filename
                )
                continue

            last_modified_datetime_local = local_splits[
                splits_filename.replace(".lss", "")
            ]
            last_modified_datetime_remote = datetime.strptime(
                splits_file["modifiedDate"],
                self.GOOGLE_DRIVE_DATE_TIME_FORMAT,
            ).replace(tzinfo=UTC)

            if last_modified_datetime_remote > last_modified_datetime_local:
                print(f"Downloading {splits_filename}...")
                splits_file.GetContentFile(
                    self._splits_manager.splits_output_folder / splits_filename
                )
            else:
                print(
                    f"{splits_filename} is already up to date locally, so there's no need to download it."
                )
