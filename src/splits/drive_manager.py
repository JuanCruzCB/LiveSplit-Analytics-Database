import logging
from datetime import UTC, datetime

from pydrive2.drive import GoogleDrive, GoogleDriveFile
from pydrive2.files import ApiRequestError

from splits.exceptions import GoogleDriveFolderNotFoundError
from splits.splits_manager import SplitsManager

logger = logging.getLogger(__name__)


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
        logger.info("Downloading any out-of-sync split files from the Drive...")
        for remote_file in self._list_remote_files():
            if "splits" in remote_file["title"]:
                self._process_remote_splits_file(remote_file)

    def _list_remote_files(self) -> list[GoogleDriveFile]:
        """
        List all non-trashed files in the Google Drive folder specified
        in the constructor.
        """
        query = {"q": f"'{self._google_drive_folder_id}' in parents and trashed=false"}
        try:
            return self._google_drive.ListFile(query).GetList()
        except ApiRequestError as e:
            logger.exception(
                "There's no Google Drive folder with id = %s",
                self._google_drive_folder_id,
            )
            raise GoogleDriveFolderNotFoundError from e

    def _process_remote_splits_file(
        self,
        remote_file: GoogleDriveFile,
    ) -> None:
        """
        Checks a remote splits file of the Google Drive folder.

        If the runner name contained within the splits file's name is not
        in the list of allowed runners → ignore the file.

        If it is in the list → check whether the file exists locally.

        If it doesn't → download the file for the first time.

        If it does AND is out of sync → download the file to sync it.
        """
        file = remote_file["title"]
        runner_name = file.replace(".lss", "").replace("splits ", "")

        if runner_name not in self._splits_manager.runner_names:
            logger.warning(
                "Ignoring unknown splits file: '%s'",
                file,
            )
            return None

        local_file = self._splits_manager.find_splits_file_by_runner_name(runner_name)

        if local_file is None:
            return self._download_file(remote_file, first_time=True)

        if local_file.is_outdated(
            datetime.strptime(
                remote_file["modifiedDate"],
                self.GOOGLE_DRIVE_DATE_TIME_FORMAT,
            ).replace(tzinfo=UTC),
        ):
            return self._download_file(remote_file)

        return logger.info(
            (
                "Splits file '%s' is already up to date locally, "
                "so there's no need to update it."
            ),
            local_file.file_path.stem,
        )

    def _download_file(
        self,
        file: GoogleDriveFile,
        *,
        first_time: bool = False,
    ) -> None:
        """
        Download the specified file from the Google Drive folder
        into the folder where all the splits files are stored locally.

        Log a different message depending on whether this file
        is being downloaded for the first time ever or not.
        """
        filename = file["title"]
        logger.info(
            "Downloading '%s'%s...",
            filename,
            " for the first time" if first_time else "",
        )
        file.GetContentFile(self._splits_manager.splits_folder / filename)
