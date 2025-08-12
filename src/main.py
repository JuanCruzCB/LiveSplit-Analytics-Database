from pandas import DataFrame

from auth.google_drive_auth import GoogleDriveAuth
from auth.google_sheets_auth import GoogleSheetsAuth
from config import load_config, setup_logging
from db.database_manager import DatabaseManager, LastUpdatesTracker
from db.query_runner import QueryRunner
from sheet.sheet_manager import SheetManager
from splits.drive_manager import DriveManager
from splits.splits_manager import SplitsManager


def get_all_database_data(query_runner: QueryRunner) -> dict[str, DataFrame]:
    return {
        "doorsplit_golds": query_runner.get_runners_doorsplit_golds(),
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


def update_google_sheet(
    sheet_manager: SheetManager, data: dict[str, DataFrame]
) -> None:
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


def main() -> None:
    setup_logging()
    config = load_config()

    google_drive_auth = GoogleDriveAuth(
        service_account_secrets_file=config.service_account_secrets_file
    )
    google_sheets_auth = GoogleSheetsAuth(
        service_account_secrets_file=config.service_account_secrets_file
    )
    splits = SplitsManager(
        splits_output_folder=config.other_runners_splits_folder,
        main_runner_splits_file=config.main_runner_splits_file,
        allowed_runners=config.allowed_runners,
    )
    drive = DriveManager(
        google_drive_folder_id=config.google_drive_folder_id,
        google_drive=google_drive_auth.auth(),
        splits_manager=splits,
    )

    drive.sync_local_splits()
    splits.clean_splits()

    sheet = SheetManager(
        gspread_client=google_sheets_auth.auth(),
        google_sheet_id=config.google_sheet_id,
    )
    last_updates = LastUpdatesTracker(
        storage_file=config.last_updates_file, default_files=splits.get_splits()
    )
    db = DatabaseManager(
        individual_sql_script=config.individual_sql_file,
        global_sql_script=config.global_sql_file,
        db_config=config.db_config,
        main_runner_name=config.allowed_runners[0],
        last_updates_tracker=last_updates,
    )
    qr = QueryRunner(
        db_manager=db,
        allowed_runners=config.allowed_runners,
        main_runner_name=config.allowed_runners[0],
    )

    try:
        qr.open_db_connection()
        if qr.update_runners_tables(splits=splits.get_splits_last_modtime()):
            qr.update_global_tables()
            all_data = get_all_database_data(qr)
            update_google_sheet(sheet, all_data)
    finally:
        qr.close_db_connection()


if __name__ == "__main__":
    main()
