from pathlib import Path

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

    for file in file_list:
        if ".lss" in file["title"]:
            print(f"Downloading {file['title']}...")
            files.append(
                {
                    "name": file["title"].replace(".lss", ""),
                    "runner": file["title"][7:].replace(".lss", ""),
                }
            )
            file.GetContentFile(OUTPUT_FOLDER / file["title"])

    print("Finished downloading all the .lss files!\n")

    return [
        {
            "name": "1. NG Pro",
            "runner": "sawken",
        }
    ] + files
