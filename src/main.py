from pandas import DataFrame

from auth.google_drive_auth import GoogleDriveAuth
from auth.google_sheets_auth import GoogleSheetsAuth
from config import load_config, setup_logging
from db.database_manager import DatabaseManager, LastUpdatesTracker
from db.query_builder import QueryBuilder
from db.query_runner import QueryRunner
from sheet.sheet_manager import SheetManager
from splits.drive_manager import DriveManager
from splits.splits_manager import SplitsManager


def get_all_database_data(query_runner: QueryRunner) -> dict[str, DataFrame]:
    """
    Get all relevant data from the database and return it as a dictionary of DataFrames.
    """
    return {
        "doorsplit_golds": query_runner.get_runners_doorsplit_golds(
            split_names_col=False, best_col=False, sum_of_best_col=False
        ),
        "chapter_golds": query_runner.get_runners_chapter_golds(
            chapter_names_col=False, best_col=True, sum_of_best_col=True
        ),
        "chapter_golds_by_doors": query_runner.get_runners_chapter_golds_by_doors(
            chapter_names_col=False, best_col=True, sum_of_best_col=True
        ),
        "area_golds": query_runner.get_runners_area_golds(
            area_names_col=False, best_col=True, sum_of_best_col=True
        ),
        "area_golds_by_chapters": query_runner.get_runners_area_golds_by_chapters(
            area_names_col=False, best_col=True, sum_of_best_col=True
        ),
        "area_golds_by_doors": query_runner.get_runners_area_golds_by_doors(
            area_names_col=False, best_col=True, sum_of_best_col=True
        ),
        "best_paces": query_runner.get_runners_best_paces(
            chapter_names_col=False, best_col=True
        ),
        "rng_patterns": query_runner.get_runners_rng_patterns(pattern_names_col=False),
        "general_stats": query_runner.get_runners_general_stats(stat_names_col=False),
        "resets": query_runner.get_runners_resets(split_names_col=False),
        "weekday_data": query_runner.get_runners_weekday_data(weekday_stat_cols=False),
    }


def update_google_sheet(
    sheet_manager: SheetManager, data: dict[str, DataFrame]
) -> None:
    """
    Update all relevant data to the Google Sheet in specified tabs and starting cells.
    """
    sheet_manager.upload_dataframe_without_copy(
        tab_name="General", starting_cell="B3", data=data["general_stats"]
    )
    sheet_manager.upload_dataframe_with_copy(
        tab_name="Doors", starting_cell="B3", data=data["doorsplit_golds"]
    )
    sheet_manager.upload_dataframe_with_copy(
        tab_name="Chapters", starting_cell="B3", data=data["chapter_golds"]
    )
    sheet_manager.upload_dataframe_without_copy(
        tab_name="Chapters", starting_cell="B25", data=data["chapter_golds_by_doors"]
    )
    sheet_manager.upload_dataframe_with_copy(
        tab_name="Sections", starting_cell="B3", data=data["area_golds"]
    )
    sheet_manager.upload_dataframe_without_copy(
        tab_name="Sections", starting_cell="B9", data=data["area_golds_by_chapters"]
    )
    sheet_manager.upload_dataframe_without_copy(
        tab_name="Sections", starting_cell="B15", data=data["area_golds_by_doors"]
    )
    sheet_manager.upload_dataframe_with_copy(
        tab_name="Paces", starting_cell="B3", data=data["best_paces"]
    )
    sheet_manager.upload_dataframe_without_copy(
        tab_name="Resets", starting_cell="B3", data=data["resets"]
    )
    sheet_manager.upload_dataframe_with_copy(
        tab_name="RNG Patterns", starting_cell="C4", data=data["rng_patterns"]
    )
    sheet_manager.upload_dataframe_without_copy(
        tab_name="Weekday", starting_cell="C2", data=data["weekday_data"]
    )
    sheet_manager.upload_last_updated_on(tab_name="Title", cell="A2")


def main() -> None:
    """
    Entry point of the application.

    Sets up logging, loads configuration, initializes authentication and managers,
    synchronizes splits, updates the database, and updates the Google Sheet.
    """
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
        sql_script=config.sql_script,
        config_sql_script=config.config_sql_script,
        db_config=config.db_config,
        main_runner_name=config.allowed_runners[0],
        last_updates_tracker=last_updates,
    )
    qr = QueryRunner(
        db_manager=db,
        query_builder=QueryBuilder(),
        allowed_runners=config.allowed_runners,
        main_runner_name=config.allowed_runners[0],
    )

    try:
        qr.open_db_connection()
        qr.create_config_tables()
        if qr.update_runners_tables(splits=splits.get_splits_last_modtime()):
            all_data = get_all_database_data(qr)
            update_google_sheet(sheet, all_data)
    finally:
        # qr.drop_staging_tables()
        qr.close_db_connection()


if __name__ == "__main__":
    main()
