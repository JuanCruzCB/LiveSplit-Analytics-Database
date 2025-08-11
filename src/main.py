from pandas import DataFrame

from auth.google_auth_manager import GoogleAuthManager
from config import load_config
from db.database_manager import DatabaseManager, LastUpdatesTracker
from db.query_runner import QueryRunner
from sheet.sheet_manager import SheetManager
from splits.drive_manager import DriveManager
from splits.splits_manager import SplitsManager


def get_all_database_data(query_runner: QueryRunner) -> dict[str, DataFrame]:
    print("Querying database for all required data...")
    print("=" * 100)
    data = {
        "doorsplit_golds": query_runner.get_doorsplit_golds(),
        "chapter_golds": query_runner.get_chapter_golds(),
        "chapter_golds_by_doors": query_runner.get_chapter_golds_by_doors(),
        "section_golds": query_runner.get_section_golds(),
        "section_golds_by_chapters": query_runner.get_section_golds_by_chapters(),
        "section_golds_by_doors": query_runner.get_section_golds_by_doors(),
        "best_paces": query_runner.get_best_paces(),
        "rng_patterns": query_runner.get_rng_patterns(),
        "general_stats": query_runner.get_general_stats(),
        "resets": query_runner.get_resets(),
        "weekday_data": query_runner.get_weekday_data(),
    }
    print("=" * 100 + "\n")
    return data


def update_google_sheet(
    sheet_manager: SheetManager, data: dict[str, DataFrame]
) -> None:
    print("Updating Google Sheet with latest data...")
    print("=" * 100)

    sheet_manager.copy_general_stats_to_sheet(data["general_stats"])
    sheet_manager.copy_doorsplits_to_sheet(data["doorsplit_golds"])
    sheet_manager.copy_chapters_to_sheet(
        data["chapter_golds"],
        data["chapter_golds_by_doors"],
    )
    sheet_manager.copy_sections_to_sheet(
        data["section_golds"],
        data["section_golds_by_chapters"],
        data["section_golds_by_doors"],
    )
    sheet_manager.copy_best_paces_to_sheet(data["best_paces"])
    sheet_manager.copy_resets_to_sheet(data["resets"])
    sheet_manager.copy_rng_patterns_to_sheet(data["rng_patterns"])
    sheet_manager.copy_weekday_data_to_sheet(data["weekday_data"])
    sheet_manager.post_last_update()
    print("=" * 100 + "\n")


def main() -> None:
    config = load_config()
    print("Logging in to Google Drive and Google Sheets...")
    print("=" * 100)
    auth_manager = GoogleAuthManager(
        service_account_secrets_file=config.service_account_secrets_file
    )
    print("Logged in succesfully!")
    print("=" * 100 + "\n")

    splits_manager = SplitsManager(
        splits_output_folder=config.other_runners_splits_folder,
        main_runner_splits_file=config.main_runner_splits_file,
        allowed_runners=config.allowed_runners,
    )

    drive_manager = DriveManager(
        google_drive_folder_id=config.google_drive_folder_id,
        google_drive=auth_manager.google_drive,
        splits_manager=splits_manager,
    )

    print("Downloading any out-of-sync split files from the Drive...")
    print("=" * 100)
    drive_manager.sync_local_splits()
    print("=" * 100 + "\n")
    print("Cleaning any dirty split files...")
    print("=" * 100)
    splits_manager.clean_splits()
    print("=" * 100 + "\n")

    sheet_manager = SheetManager(
        gspread_client=auth_manager.gspread_client,
        google_sheet_id=config.google_sheet_id,
    )

    last_updates_tracker = LastUpdatesTracker(
        storage_file=config.last_updates_file, default_files=splits_manager.get_splits()
    )

    db_manager = DatabaseManager(
        individual_sql_script=config.individual_sql_file,
        global_sql_script=config.global_sql_file,
        db_config=config.db_config,
        main_runner_name=config.allowed_runners[0],
        last_updates_tracker=last_updates_tracker,
    )

    query_runner = QueryRunner(
        db_manager=db_manager,
        allowed_runners=config.allowed_runners,
        main_runner_name=config.allowed_runners[0],
    )

    try:
        print("Updating database tables...")
        print("=" * 100)
        query_runner.open_db_connection()
        if query_runner.update_runners_tables(
            splits=splits_manager.get_splits_last_modtime()
        ):
            query_runner.update_global_tables()
            print("=" * 100 + "\n")
            all_data = get_all_database_data(query_runner)
            update_google_sheet(sheet_manager, all_data)
        else:
            print("=" * 100 + "\n")
            print("No new data - not updating the sheet.")
    finally:
        query_runner.close_db_connection()


if __name__ == "__main__":
    main()
