from datetime import datetime, timedelta
from pathlib import Path

from pydrive2.drive import GoogleDrive

from constants import Format


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
        self._currently_allowed_runners = currently_allowed_runners
        self._splits_output_folder = splits_output_folder
        self._my_splits_file = my_splits_file

    def _splits_last_modified(self) -> dict[str, str]:
        if not self._splits_output_folder.exists():
            raise Exception(
                "The output folder for the splits of other runners does not exist."
            )

        local_splits = {}
        for splits in self._splits_output_folder.glob(pattern="*.lss"):
            path_obj = Path(splits)
            split_name = path_obj.stem
            mtime = path_obj.stat().st_mtime
            mtime_date = datetime.fromtimestamp(mtime).strftime(
                Format.DATE_TIME_FORMAT.value
            )
            local_splits[split_name] = mtime_date

        my_splits_name = self._my_splits_file.stem
        my_splits_mtime = self._my_splits_file.stat().st_mtime
        my_splits_mtime_date = datetime.fromtimestamp(my_splits_mtime).strftime(
            Format.DATE_TIME_FORMAT.value
        )

        local_splits[my_splits_name] = my_splits_mtime_date

        return local_splits

    def download_splits(self) -> dict[str, str]:
        if self._google_drive is None:
            raise Exception("We are not connected to Google Drive.")

        files_in_drive = self._google_drive.ListFile(
            {"q": f"'{self._google_drive_folder_id}' in parents and trashed=false"}
        ).GetList()

        local_splits = self._splits_last_modified()
        allowed_splits = [
            f"splits {runner}.lss" for runner in self._currently_allowed_runners
        ]

        for file in files_in_drive:
            title = file["title"]
            if title not in allowed_splits:
                continue

            modified_date = (
                datetime.strptime(
                    file["modifiedDate"], Format.GOOGLE_DRIVE_DATE_TIME_FORMAT.value
                )
                - timedelta(hours=3)
            ).strftime(Format.DATE_TIME_FORMAT.value)

            file_name = title.replace(".lss", "")
            if datetime.strptime(
                local_splits[file_name], Format.DATE_TIME_FORMAT.value
            ) < datetime.strptime(modified_date, Format.DATE_TIME_FORMAT.value):
                print(f"Downloading {title}...")

                file.GetContentFile(self._splits_output_folder / title)
            else:
                print(
                    f"{title} is already up to date locally, so there's no need to download it."
                )

        return self._splits_last_modified()
