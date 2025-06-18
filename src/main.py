from constants import (
    Files,
    GOOGLE_DRIVE_FOLDER_ID,
    GOOGLE_SHEET_URL,
    DB_CONFIG,
    CURRENTLY_ALLOWED_RUNNERS,
    DEFAULT_UPDATES,
)
from google_auth_manager import GoogleAuthManager
from re4database_manager import RE4DatabaseManager
from re4drive_manager import RE4DriveManager
from re4sheet_manager import RE4SheetManager


def update_db_and_sheet(
    db_manager: RE4DatabaseManager, sheet_manager: RE4SheetManager
) -> None:
    print("Querying the database")
    print("=" * 100)
    df_doorsplit_golds = db_manager.query_doorsplit_golds()
    df_chapter_golds = db_manager.query_chapter_golds()
    df_chapter_golds_by_doors = db_manager.query_chapter_golds_by_doors()
    df_section_golds = db_manager.query_section_golds()
    df_section_golds_by_chapters = db_manager.query_section_golds_by_chapters()
    df_section_golds_by_doors = db_manager.query_section_golds_by_doors()
    df_best_paces = db_manager.query_best_paces()
    df_rng_patterns = db_manager.query_rng_patterns()
    df_general_stats = db_manager.query_general_stats()
    df_resets = db_manager.query_resets()
    df_weekday_data = db_manager.query_weekday_data()
    print("=" * 100 + "\n")

    print("Updating the Google Sheet")
    print("=" * 100)
    sheet_manager.copy_doorsplits_to_sheet(doorsplits=df_doorsplit_golds)
    sheet_manager.copy_chapters_to_sheet(
        chapters=df_chapter_golds,
        chapters_by_doors=df_chapter_golds_by_doors,
    )
    sheet_manager.copy_sections_to_sheet(
        sections=df_section_golds,
        sections_by_chapters=df_section_golds_by_chapters,
        sections_by_doors=df_section_golds_by_doors,
    )
    sheet_manager.copy_paces_to_sheet(paces=df_best_paces)
    sheet_manager.copy_rng_patterns_to_sheet(rng_patterns=df_rng_patterns)
    sheet_manager.copy_general_stats_to_sheet(general_stats=df_general_stats)
    sheet_manager.copy_resets_to_sheet(resets=df_resets)
    sheet_manager.copy_weekday_data_to_sheet(weekday_data=df_weekday_data)
    sheet_manager.post_last_update()
    print("=" * 100 + "\n")


def main() -> None:
    auth_manager = GoogleAuthManager(
        service_account_file=Files.GOOGLE_SERVICE_ACCOUNT_SECRETS_FILE.value
    )
    drive_manager = RE4DriveManager(
        google_drive=auth_manager.google_drive,
        google_drive_folder_id=GOOGLE_DRIVE_FOLDER_ID,
        splits_output_folder=Files.SPLITS_OUTPUT_FOLDER.value,
        my_splits_file=Files.MY_SPLITS_FILE.value,
    )
    sheet_manager = RE4SheetManager(
        gspread_client=auth_manager.gspread_client,
        google_sheet_url=GOOGLE_SHEET_URL,
    )
    db_manager = RE4DatabaseManager(
        db_config=DB_CONFIG,
        main_sql_script=Files.MAIN_SQL_FILE.value,
        global_sql_script=Files.GLOBAL_SQL_FILE.value,
        last_updates_file=Files.LAST_UPDATES_FILE.value,
        currently_allowed_runners=CURRENTLY_ALLOWED_RUNNERS,
        default_updates=DEFAULT_UPDATES,
    )

    print("Getting splits")
    print("=" * 100)
    drive_manager.update_local_splits()
    splits = drive_manager.get_local_splits()
    print("=" * 50 + "\n")

    print("Updating the database")
    print("=" * 100)
    db_manager.open_connection()
    new_updates = db_manager.update_runners_tables(splits=splits)
    db_manager.update_global_tables()
    print("=" * 100 + "\n")

    if new_updates:
        update_db_and_sheet(db_manager=db_manager, sheet_manager=sheet_manager)
    else:
        print(
            "Not querying the database nor updating the sheet since there's no new data."
        )

    db_manager.close_connection()


if __name__ == "__main__":
    main()
