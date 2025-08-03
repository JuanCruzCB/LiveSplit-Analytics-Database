from pathlib import Path

from google_auth_manager import GoogleAuthManager
from re4drive_manager import RE4DriveManager
from re4query_runner import RE4QueryRunner
from re4sheet_manager import RE4SheetManager
from setup import (
    GLOBAL_SQL_FILE,
    GOOGLE_SERVICE_ACCOUNT_SECRETS_FILE,
    LAST_UPDATES_FILE,
    MAIN_SQL_FILE,
    load_environment_variables,
    validate_paths,
)


def update_db_and_sheet(
    query_runner: RE4QueryRunner, sheet_manager: RE4SheetManager
) -> None:
    """
    Obtain all the dataframes with the required data by querying the database
    and export their data onto the Google Sheet.
    """
    print("Querying the database")
    print("=" * 100)
    doorsplit_golds = query_runner.get_doorsplit_golds()
    chapter_golds = query_runner.get_chapter_golds()
    chapter_golds_by_doors = query_runner.get_chapter_golds_by_doors()
    section_golds = query_runner.get_section_golds()
    section_golds_by_chapters = query_runner.get_section_golds_by_chapters()
    section_golds_by_doors = query_runner.get_section_golds_by_doors()
    best_paces = query_runner.get_best_paces()
    rng_patterns = query_runner.get_rng_patterns()
    general_stats = query_runner.get_general_stats()
    resets = query_runner.get_resets()
    weekday_data = query_runner.get_weekday_data()
    print("=" * 100 + "\n")

    print("Updating the Google Sheet")
    print("=" * 100)
    sheet_manager.copy_general_stats_to_sheet(general_stats)
    sheet_manager.copy_doorsplits_to_sheet(doorsplit_golds)
    sheet_manager.copy_chapters_to_sheet(
        chapter_golds,
        chapter_golds_by_doors,
    )
    sheet_manager.copy_sections_to_sheet(
        section_golds,
        section_golds_by_chapters,
        section_golds_by_doors,
    )
    sheet_manager.copy_best_paces_to_sheet(best_paces)
    sheet_manager.copy_resets_to_sheet(resets)
    sheet_manager.copy_rng_patterns_to_sheet(rng_patterns)
    sheet_manager.copy_weekday_data_to_sheet(weekday_data)
    sheet_manager.post_last_update()
    print("=" * 100 + "\n")


def main() -> None:
    (
        my_splits_file_str,
        other_runners_splits_folder_str,
        google_sheet_url,
        google_drive_folder_id,
    ) = load_environment_variables()

    validate_paths(my_splits_file_str, other_runners_splits_folder_str)

    auth_manager = GoogleAuthManager(
        service_account_file=GOOGLE_SERVICE_ACCOUNT_SECRETS_FILE
    )
    drive_manager = RE4DriveManager(
        google_drive_folder_id=google_drive_folder_id,
        google_drive=auth_manager.google_drive,
        splits_output_folder=Path(other_runners_splits_folder_str),
        my_splits_file=Path(my_splits_file_str),
    )
    sheet_manager = RE4SheetManager(
        gspread_client=auth_manager.gspread_client, google_sheet_url=google_sheet_url
    )
    query_runner = RE4QueryRunner(
        main_sql_script=MAIN_SQL_FILE,
        global_sql_script=GLOBAL_SQL_FILE,
        last_updates_file=LAST_UPDATES_FILE,
    )

    print("Getting splits")
    print("=" * 100)
    drive_manager.update_local_splits()
    splits = drive_manager.get_local_splits()
    print("=" * 100 + "\n")

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
