from datetime import datetime, timedelta
from pathlib import Path

from pydrive.auth import GoogleAuth
from pydrive.drive import GoogleDrive

from constants import DATE_TIME_FORMAT, GOOGLE_DRIVE_DATE_TIME_FORMAT
from decorators import measure_time


class RE4DriveManager:
    def __init__(self) -> None:
        self.splits_folder_id = "1-OvGMbjiemrxMaie166Cmwbu3k5WvXGh"
        self.currently_allowed_runners = [
            "arcadan",
            "derek",
            "joker",
            "luis",
            "mateo",
            "richy",
            "nevs",
        ]
        self.output_folder = Path(
            r"H:\Juan\4. Speedrunning\LiveSplit\Splits\RE4 Steam\2024 LRT\Not mine"
        )
        self.credentials_file = Path(
            r"H:\Juan\3. Projects\GH Sawken\Python\UpdateGoldsGlobal\credentials\my_credentials.txt"
        )
        self.client_secrets_file = Path(
            r"H:\Juan\3. Projects\GH Sawken\Python\UpdateGoldsGlobal\credentials\client_secrets.json"
        )
        self.google_drive = None
        self.login_google()

    @measure_time
    def login_google(self) -> None:
        gauth = GoogleAuth()

        gauth.LoadClientConfigFile(client_config_file=str(self.client_secrets_file))

        gauth.client_config_file = str(self.client_secrets_file)

        try:
            gauth.LoadCredentialsFile(credentials_file=self.credentials_file)
        except FileNotFoundError:
            print("Credentials file not found. Starting authentication...")
            gauth.LocalWebserverAuth()
            gauth.SaveCredentialsFile(credentials_file=self.credentials_file)

        if gauth.credentials is None:
            gauth.LocalWebserverAuth()
            gauth.SaveCredentialsFile(credentials_file=self.credentials_file)
        elif gauth.access_token_expired:
            try:
                gauth.Refresh()
            except Exception:
                print("Token refresh failed. Re-authenticating...")
                gauth.LocalWebserverAuth()
                gauth.SaveCredentialsFile(credentials_file=self.credentials_file)

        self.google_drive = GoogleDrive(auth=gauth)

    @measure_time
    def splits_last_modified(self) -> dict[str, str]:
        if not self.output_folder.exists():
            raise Exception(
                "The output folder for the splits of other runners does not exist."
            )
        local_splits = {}
        for splits in self.output_folder.glob(pattern="*.lss"):
            path_obj = Path(splits)
            split_name = path_obj.stem
            mtime = path_obj.stat().st_mtime
            mtime_date = datetime.fromtimestamp(mtime).strftime(DATE_TIME_FORMAT)
            local_splits[split_name] = mtime_date

        my_splits = Path(
            r"H:\Juan\4. Speedrunning\LiveSplit\Splits\RE4 Steam\2024 LRT\1. NG Pro.lss"
        )
        my_splits_name = my_splits.stem
        my_splits_mtime = my_splits.stat().st_mtime
        my_splits_mtime_date = datetime.fromtimestamp(my_splits_mtime).strftime(
            DATE_TIME_FORMAT
        )

        local_splits[my_splits_name] = my_splits_mtime_date

        return local_splits

    @measure_time
    def download_splits(self) -> dict[str, str]:
        print("Getting splits")
        print("=" * 100)
        if self.google_drive is None:
            raise Exception("We are not connected to Google Drive.")

        files_in_drive = self.google_drive.ListFile(
            {"q": f"'{self.splits_folder_id}' in parents and trashed=false"}
        ).GetList()

        local_splits = self.splits_last_modified()
        allowed_splits = [
            f"splits {runner}.lss" for runner in self.currently_allowed_runners
        ]

        for file in files_in_drive:
            title = file["title"]
            if title not in allowed_splits:
                continue

            modified_date = (
                datetime.strptime(file["modifiedDate"], GOOGLE_DRIVE_DATE_TIME_FORMAT)
                - timedelta(hours=3)
            ).strftime(DATE_TIME_FORMAT)

            file_name = title.replace(".lss", "")
            if datetime.strptime(
                local_splits[file_name], DATE_TIME_FORMAT
            ) < datetime.strptime(modified_date, DATE_TIME_FORMAT):
                print(f"Downloading {title}...")

                file.GetContentFile(self.output_folder / title)
            else:
                print(
                    f"{title} is already up to date locally, so there's no need to download it."
                )

        print("=" * 50 + "\n")
        return self.splits_last_modified()
