from pathlib import Path
from datetime import datetime

from pydrive.auth import GoogleAuth
from pydrive.drive import GoogleDrive

from decorators import measure_time

SPLITS_FOLDER_ID = "1-OvGMbjiemrxMaie166Cmwbu3k5WvXGh"
OUTPUT_FOLDER = Path(
    r"H:\Juan\4. Speedrunning\LiveSplit\Splits\RE4 Steam\2024 LRT\Not mine"
)
CREDENTIALS_FILE = Path(
    r"H:\Juan\3. Projects\GH Sawken\Python\UpdateGoldsGlobal\credentials\my_credentials.txt"
)
CLIENT_SECRETS_FILE = Path(
    r"H:\Juan\3. Projects\GH Sawken\Python\UpdateGoldsGlobal\credentials\client_secrets.json"
)


@measure_time
def splits_last_modified() -> dict[str, datetime]:
    local_splits = {}
    for splits in OUTPUT_FOLDER.glob(pattern="*.lss"):
        path_obj = Path(splits)
        split_name = path_obj.stem
        mtime = path_obj.stat().st_mtime
        mtime_date = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M:%S")
        local_splits[split_name] = mtime_date

    return local_splits


@measure_time
def download_splits() -> list[dict[str, str]]:
    """
    Returns a list of splits with their name and last modified date.
    """

    gauth = GoogleAuth()

    gauth.LoadClientConfigFile(client_config_file=str(CLIENT_SECRETS_FILE))

    gauth.client_config_file = str(CLIENT_SECRETS_FILE)

    try:
        gauth.LoadCredentialsFile(credentials_file=CREDENTIALS_FILE)
    except FileNotFoundError:
        print("Credentials file not found. Starting authentication...")
        gauth.LocalWebserverAuth()
        gauth.SaveCredentialsFile(credentials_file=CREDENTIALS_FILE)

    if gauth.credentials is None:
        gauth.LocalWebserverAuth()
        gauth.SaveCredentialsFile(credentials_file=CREDENTIALS_FILE)
    elif gauth.access_token_expired:
        try:
            gauth.Refresh()
        except RefreshError:
            print("Token refresh failed. Re-authenticating...")
            gauth.LocalWebserverAuth()
            gauth.SaveCredentialsFile(credentials_file=CREDENTIALS_FILE)

    drive = GoogleDrive(auth=gauth)

    if not OUTPUT_FOLDER.exists():
        raise Exception(
            "The output folder for the splits of other runners does not exist."
        )

    file_list = drive.ListFile(
        {"q": f"'{SPLITS_FOLDER_ID}' in parents and trashed=false"}
    ).GetList()

    files = []

    local_splits = splits_last_modified()

    for file in file_list:
        title = file["title"]
        modified_date = file["modifiedDate"]
        if ".lss" in title:
            modified_date_formatted = datetime.strptime(
                modified_date, "%Y-%m-%dT%H:%M:%S.%fZ"
            ).strftime("%Y-%m-%d %H:%M:%S")
            name = title.replace(".lss", "")
            if local_splits[name] < modified_date_formatted:
                print(f"Downloading {title}...")
                files.append(
                    {
                        "name": name,
                        "runner": title[7:].replace(".lss", ""),
                    }
                )
                file.GetContentFile(OUTPUT_FOLDER / title)
            else:
                print(
                    f"{title} is already up to date locally, so there's no need to download it."
                )

    print("Finished downloading the .lss files!\n")
    return [
        {
            "name": "1. NG Pro",
            "runner": "sawken",
        }
    ] + files
