from typing import cast

from loguru import logger
from pydrive2.drive import GoogleDrive  # pyright: ignore[reportMissingTypeStubs]
from pydrive2.files import ApiRequestError  # pyright: ignore[reportMissingTypeStubs]

from drive.exceptions import GoogleDriveFolderNotFoundError
from drive.remote_splits_file import RemoteSplitsFile
from splits.splits_handler import SplitsHandler


class DriveHandler:
    _google_drive_folder_id: str
    _google_drive: GoogleDrive
    _splits_handler: SplitsHandler

    def __init__(
        self,
        google_drive_folder_id: str,
        google_drive: GoogleDrive,
        splits_handler: SplitsHandler,
    ) -> None:
        self._google_drive_folder_id = google_drive_folder_id
        self._google_drive = google_drive
        self._splits_handler = splits_handler

    def sync_local_splits(self) -> None:
        """
        Update the local splits with their remote versions if the versions
        on the Google Drive folder are newer than the local ones.

        Additionally, also download splits files that are allowed but don't
        exist locally because they haven't been downloaded yet.
        """
        logger.info("Downloading any out-of-sync split files from the Drive...")
        for remote_file in self._list_remote_splits_files():
            self._process_remote_splits_file(remote_file)

    def _list_remote_splits_files(self) -> list[RemoteSplitsFile]:
        """
        List all non-trashed splits files in the configured Google Drive folder.
        """
        query = {"q": f"'{self._google_drive_folder_id}' in parents and trashed=false"}
        try:
            raw_files = self._google_drive.ListFile(param=query).GetList()  # pyright: ignore[reportUnknownMemberType, reportUnknownVariableType]
        except ApiRequestError as e:
            logger.exception(
                "Failed to list files in Google Drive folder '{}'",
                self._google_drive_folder_id,
            )
            raise GoogleDriveFolderNotFoundError from e

        return [
            RemoteSplitsFile.from_drive_file(raw)  # pyright: ignore[reportUnknownArgumentType]
            for raw in raw_files  # pyright: ignore[reportUnknownVariableType]
            if cast("str", raw["title"]).startswith("splits ")
        ]

    def _process_remote_splits_file(self, remote_file: RemoteSplitsFile) -> None:
        """
        Decide whether a remote splits file needs to be downloaded.

        - Unknown runners are ignored.
        - Files that don't exist locally are downloaded for the first time.
        - Files that exist locally but are older than their remote version
          are re-downloaded.
        - Otherwise, nothing happens.
        """
        runner_name = remote_file.runner_name

        if runner_name not in self._splits_handler.runner_names:
            logger.warning("Ignoring unknown splits file: '{}'", remote_file.title)
            return

        local_file = self._splits_handler.find_splits_file_by_runner_name(runner_name)

        if local_file is None:
            self._download_file(remote_file, first_time=True)
            return

        if local_file.is_older_than(dt=remote_file.modified_at):
            self._download_file(remote_file)
            return

        logger.info(
            "Splits file '{}' is already up to date locally, so there's no need to update it.",  # noqa: E501
            local_file.file_path.stem,
        )

    def _download_file(
        self,
        remote_file: RemoteSplitsFile,
        *,
        first_time: bool = False,
    ) -> None:
        """
        Download a remote splits file into the local splits folder.
        """
        logger.info(
            "Downloading '{}'{}...",
            remote_file.title,
            " for the first time" if first_time else "",
        )
        remote_file.download_to(
            path=self._splits_handler.splits_folder / remote_file.title,
        )
