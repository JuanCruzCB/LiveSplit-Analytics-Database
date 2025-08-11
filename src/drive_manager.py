from datetime import UTC, datetime
from typing import Any

from pydrive2.drive import GoogleDrive

from splits_manager import SplitsManager


class DriveManager:
    GOOGLE_DRIVE_DATE_TIME_FORMAT = "%Y-%m-%dT%H:%M:%S.%fZ"

    def __init__(
        self,
        google_drive_folder_id: str,
        google_drive: GoogleDrive,
        splits_manager: SplitsManager,
    ) -> None:
        self._google_drive_folder_id = google_drive_folder_id
        self._google_drive = google_drive
        self._splits_manager = splits_manager

    def sync_local_splits(self) -> None:
        """
        Update the local splits with their remote versions if the versions
        on the Google Drive folder are newer than the local ones.

        Additionally, also download splits files that are allowed but don't
        yet exist locally because they haven't been downloaded yet.
        """
        local_splits = self._splits_manager.get_splits_stem_last_modtime()
        query = {"q": f"'{self._google_drive_folder_id}' in parents and trashed=false"}
        all_remote_files = self._google_drive.ListFile(query).GetList()

        for remote_file in all_remote_files:
            self._process_remote_file(remote_file, local_splits)

    def _process_remote_file(
        self, remote_file: Any, local_splits: dict[str, datetime]
    ) -> None:
        """
        Checks a remote file of the Google Drive folder.

        If it contains 'splits' and that filename is currently allowed,
        check whether that file already exists locally.

        If it doesn't → download it.

        If it does → check whether the local version is outdated and if so,
        download the remote version to sync it locally.
        """
        filename = remote_file["title"]

        if "splits" not in filename:
            return None

        if (
            "splits" in filename
            and filename not in self._splits_manager.currently_allowed_splits
        ):
            return print(f"Ignoring unknown splits file: '{filename}'")

        base_name = filename.replace(".lss", "")

        if base_name not in local_splits:
            return self._download_drive_splits(filename, remote_file)

        last_modified_datetime_local = local_splits[base_name]
        last_modified_datetime_remote = datetime.strptime(
            remote_file["modifiedDate"],
            self.GOOGLE_DRIVE_DATE_TIME_FORMAT,
        ).replace(tzinfo=UTC)
        if last_modified_datetime_remote > last_modified_datetime_local:
            return self._download_drive_splits(filename, remote_file, first_time="")

        return print(
            f"File '{filename}' is already up to date locally, so there's no need to update it."
        )

    def _download_drive_splits(
        self, filename: str, splits_file: Any, first_time: str = " for the first time"
    ) -> None:
        """
        Download the specified splits_file from the Google Drive folder
        into the output folder assigned on the constructor.

        Print a different message depending on whether this file
        is being downloaded for the first time ever or not.
        """
        print(f"Downloading '{filename}'{first_time}...")
        splits_file.GetContentFile(self._splits_manager.splits_output_folder / filename)
