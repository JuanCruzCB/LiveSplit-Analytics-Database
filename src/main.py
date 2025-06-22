from constants import Files
from google_auth_manager import GoogleAuthManager
from re4drive_manager import RE4DriveManager
from re4query_runner import RE4QueryRunner
from re4sheet_manager import RE4SheetManager


def update_db_and_sheet(
    query_runner: RE4QueryRunner, sheet_manager: RE4SheetManager
) -> None:
    print("Querying the database")
    print("=" * 100)
    df_doorsplit_golds = query_runner.query_doorsplit_golds()
    df_chapter_golds = query_runner.query_chapter_golds()
    df_chapter_golds_by_doors = query_runner.query_chapter_golds_by_doors()
    df_section_golds = query_runner.query_section_golds()
    df_section_golds_by_chapters = query_runner.query_section_golds_by_chapters()
    df_section_golds_by_doors = query_runner.query_section_golds_by_doors()
    df_best_paces = query_runner.query_best_paces()
    df_rng_patterns = query_runner.query_rng_patterns()
    df_general_stats = query_runner.query_general_stats()
    df_resets = query_runner.query_resets()
    df_weekday_data = query_runner.query_weekday_data()
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
        splits_output_folder=Files.SPLITS_OUTPUT_FOLDER.value,
        my_splits_file=Files.MY_SPLITS_FILE.value,
    )
    sheet_manager = RE4SheetManager(
        gspread_client=auth_manager.gspread_client,
    )
    query_runner = RE4QueryRunner(
        main_sql_script=Files.MAIN_SQL_FILE.value,
        global_sql_script=Files.GLOBAL_SQL_FILE.value,
        last_updates_file=Files.LAST_UPDATES_FILE.value,
    )

    print("Getting splits")
    print("=" * 100)
    drive_manager.update_local_splits()
    splits = drive_manager.get_local_splits()
    print("=" * 50 + "\n")

    print("Updating the database")
    print("=" * 100)
    query_runner.db.open_connection()
    new_updates = query_runner.db.update_runners_tables(splits=splits)
    query_runner.db.update_global_tables()
    print("=" * 100 + "\n")

    if new_updates:
        update_db_and_sheet(query_runner=query_runner, sheet_manager=sheet_manager)
    else:
        print(
            "Not querying the database nor updating the sheet since there's no new data."
        )

    query_runner.db.close_connection()


if __name__ == "__main__":
    main()
