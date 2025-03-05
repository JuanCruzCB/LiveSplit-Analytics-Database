from datetime import datetime, timedelta
from pathlib import Path

from pydrive.auth import GoogleAuth
from pydrive.drive import GoogleDrive

from constants import CURRENTLY_ALLOWED_RUNNERS, Format
from decorators import measure_time


class RE4DriveManager:
    def __init__(self) -> None:
        self._splits_folder_id = "1-OvGMbjiemrxMaie166Cmwbu3k5WvXGh"
        self._output_folder = Path(
            r"H:\Juan\4. Speedrunning\LiveSplit\Splits\RE4 Steam\2024 LRT\Not mine"
        )
        self._credentials_file = Path(
            r"H:\Juan\3. Projects\GH Sawken\Python\UpdateGoldsGlobal\credentials\my_credentials.txt"
        )
        self._client_secrets_file = Path(
            r"H:\Juan\3. Projects\GH Sawken\Python\UpdateGoldsGlobal\credentials\client_secrets.json"
        )
        self._google_drive = None
        self._login_google()

    @measure_time
    def _login_google(self) -> None:
        gauth = GoogleAuth()

        gauth.LoadClientConfigFile(client_config_file=str(self._client_secrets_file))

        gauth.client_config_file = str(self._client_secrets_file)

        try:
            gauth.LoadCredentialsFile(credentials_file=self._credentials_file)
        except FileNotFoundError:
            print("Credentials file not found. Starting authentication...")
            gauth.LocalWebserverAuth()
            gauth.SaveCredentialsFile(credentials_file=self._credentials_file)

        if gauth.credentials is None:
            gauth.LocalWebserverAuth()
            gauth.SaveCredentialsFile(credentials_file=self._credentials_file)
        elif gauth.access_token_expired:
            try:
                gauth.Refresh()
            except Exception:
                print("Token refresh failed. Re-authenticating...")
                gauth.LocalWebserverAuth()
                gauth.SaveCredentialsFile(credentials_file=self._credentials_file)

        self._google_drive = GoogleDrive(auth=gauth)

    @measure_time
    def _splits_last_modified(self) -> dict[str, str]:
        if not self._output_folder.exists():
            raise Exception(
                "The output folder for the splits of other runners does not exist."
            )
        local_splits = {}
        for splits in self._output_folder.glob(pattern="*.lss"):
            path_obj = Path(splits)
            split_name = path_obj.stem
            mtime = path_obj.stat().st_mtime
            mtime_date = datetime.fromtimestamp(mtime).strftime(
                Format.DATE_TIME_FORMAT.value
            )
            local_splits[split_name] = mtime_date

        my_splits = Path(
            r"H:\Juan\4. Speedrunning\LiveSplit\Splits\RE4 Steam\2024 LRT\1. NG Pro.lss"
        )
        my_splits_name = my_splits.stem
        my_splits_mtime = my_splits.stat().st_mtime
        my_splits_mtime_date = datetime.fromtimestamp(my_splits_mtime).strftime(
            Format.DATE_TIME_FORMAT.value
        )

        local_splits[my_splits_name] = my_splits_mtime_date

        return local_splits

    @measure_time
    def download_splits(self) -> dict[str, str]:
        print("Getting splits")
        print("=" * 100)
        if self._google_drive is None:
            raise Exception("We are not connected to Google Drive.")

        files_in_drive = self._google_drive.ListFile(
            {"q": f"'{self._splits_folder_id}' in parents and trashed=false"}
        ).GetList()

        local_splits = self._splits_last_modified()
        allowed_splits = [
            f"splits {runner}.lss" for runner in CURRENTLY_ALLOWED_RUNNERS
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

                file.GetContentFile(self._output_folder / title)
            else:
                print(
                    f"{title} is already up to date locally, so there's no need to download it."
                )

        print("=" * 50 + "\n")
        return self._splits_last_modified()
