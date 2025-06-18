from re4drive_manager import RE4DriveManager
from constants import GOOGLE_DRIVE_FOLDER_ID, Files
from google_auth_manager import GoogleAuthManager


auth_manager = GoogleAuthManager(
    service_account_file=Files.GOOGLE_SERVICE_ACCOUNT_SECRETS_FILE.value
)

drive_manager = RE4DriveManager(
    google_drive=auth_manager.google_drive,
    google_drive_folder_id=GOOGLE_DRIVE_FOLDER_ID,
    splits_output_folder=Files.SPLITS_OUTPUT_FOLDER.value,
    my_splits_file=Files.MY_SPLITS_FILE.value,
)

drive_manager.update_local_splits()
