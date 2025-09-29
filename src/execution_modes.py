from pathlib import Path

from pandas import DataFrame

from auth.google_drive_auth import GoogleDriveAuth
from auth.google_sheets_auth import GoogleSheetsAuth
from config import Config
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
            split_names_col=False,
            best_col=False,
            sum_of_best_col=False,
        ),
        "chapter_golds": query_runner.get_runners_chapter_golds(
            chapter_names_col=False,
            best_col=True,
            sum_of_best_col=True,
        ),
        "chapter_golds_by_doors": query_runner.get_runners_chapter_golds_by_doors(
            chapter_names_col=False,
            best_col=True,
            sum_of_best_col=True,
        ),
        "area_golds": query_runner.get_runners_area_golds(
            area_names_col=False,
            best_col=True,
            sum_of_best_col=True,
        ),
        "area_golds_by_chapters": query_runner.get_runners_area_golds_by_chapters(
            area_names_col=False,
            best_col=True,
            sum_of_best_col=True,
        ),
        "area_golds_by_doors": query_runner.get_runners_area_golds_by_doors(
            area_names_col=False,
            best_col=True,
            sum_of_best_col=True,
        ),
        "best_paces": query_runner.get_runners_best_paces(
            chapter_names_col=False,
            best_col=True,
        ),
        "rng_patterns": query_runner.get_runners_rng_patterns(pattern_names_col=False),
        "general_stats": query_runner.get_runners_general_stats(stat_names_col=False),
        "resets": query_runner.get_runners_resets(split_names_col=False),
        "weekday_data": query_runner.get_runners_weekday_data(weekday_stat_cols=False),
    }


def export_to_google_sheet(
    sheet_manager: SheetManager,
    data: dict[str, DataFrame],
) -> None:
    """
    Update all relevant data to the Google Sheet in specified tabs and starting cells.
    """
    sheet_manager.upload_dataframe_without_copy(
        tab_name="General",
        starting_cell="B3",
        data=data["general_stats"],
    )
    sheet_manager.upload_dataframe_with_copy(
        tab_name="Doors",
        starting_cell="B3",
        data=data["doorsplit_golds"],
    )
    sheet_manager.upload_dataframe_with_copy(
        tab_name="Chapters",
        starting_cell="B3",
        data=data["chapter_golds"],
    )
    sheet_manager.upload_dataframe_without_copy(
        tab_name="Chapters",
        starting_cell="B25",
        data=data["chapter_golds_by_doors"],
    )
    sheet_manager.upload_dataframe_with_copy(
        tab_name="Sections",
        starting_cell="B3",
        data=data["area_golds"],
    )
    sheet_manager.upload_dataframe_without_copy(
        tab_name="Sections",
        starting_cell="B9",
        data=data["area_golds_by_chapters"],
    )
    sheet_manager.upload_dataframe_without_copy(
        tab_name="Sections",
        starting_cell="B15",
        data=data["area_golds_by_doors"],
    )
    sheet_manager.upload_dataframe_with_copy(
        tab_name="Paces",
        starting_cell="B3",
        data=data["best_paces"],
    )
    sheet_manager.upload_dataframe_without_copy(
        tab_name="Resets",
        starting_cell="B3",
        data=data["resets"],
    )
    sheet_manager.upload_dataframe_with_copy(
        tab_name="RNG Patterns",
        starting_cell="C4",
        data=data["rng_patterns"],
    )
    sheet_manager.upload_dataframe_without_copy(
        tab_name="Weekday",
        starting_cell="C2",
        data=data["weekday_data"],
    )
    sheet_manager.upload_last_updated_on(tab_name="Title", cell="A2")


def export_to_excel(data: dict[str, DataFrame], output_dir: Path) -> None:
    """
    Export all relevant data to excel files.
    """
    for name, df in data.items():
        df.to_excel(output_dir / f"{name}.xlsx", index=False)


def run_without_google_api(
    splits: SplitsManager,
    qr: QueryRunner,
    output_dir: Path,
) -> None:
    """
    Run the application without using Google API services, which means the splits
    are purely local (they don't get updated with their corresponding remote versions)
    and the resulting data is outputted to excel files instead of to a Google Sheet.
    """
    splits.validate_all_splits()
    splits.clean_all_splits()

    try:
        qr.open_db_connection()
        qr.create_config_tables()
        if qr.update_runners_tables(splits_files=splits.splits_files):
            all_data = get_all_database_data(qr)
            export_to_excel(all_data, output_dir)
    finally:
        # qr.drop_staging_tables()
        qr.close_db_connection()


def run_with_google_drive_and_google_sheets(
    config: Config,
    splits: SplitsManager,
    qr: QueryRunner,
) -> None:
    """
    Run the application using both Google Drive and Google Sheets services, which means
    the splits are updated with their corresponding remote versions and the resulting
    data is uploaded to the Google Sheet.
    """
    google_drive = GoogleDriveAuth(
        service_account_secrets_file=config.google_api.service_account_secrets_file,  # type: ignore
    )
    google_sheets = GoogleSheetsAuth(
        service_account_secrets_file=config.google_api.service_account_secrets_file,  # type: ignore
    )
    drive_manager = DriveManager(
        google_drive_folder_id=config.google_api.google_drive_folder_id,  # type: ignore
        google_drive=google_drive.auth(),
        splits_manager=splits,
    )
    sheet_manager = SheetManager(
        gspread_client=google_sheets.auth(),
        google_sheet_id=config.google_api.google_sheet_id,  # type: ignore
    )

    drive_manager.sync_local_splits()
    splits.validate_all_splits()
    splits.clean_all_splits()
    try:
        qr.open_db_connection()
        qr.create_config_tables()
        if qr.update_runners_tables(splits_files=splits.splits_files):
            all_data = get_all_database_data(qr)
            export_to_google_sheet(sheet_manager, all_data)
    finally:
        # qr.drop_staging_tables()
        qr.close_db_connection()


def run_with_google_drive_only(
    config: Config,
    splits: SplitsManager,
    qr: QueryRunner,
    output_dir: Path,
) -> None:
    """
    Run the application using Google Drive but not Google Sheets, which means
    the splits are updated with their corresponding remote versions and the resulting
    data is exported to excel files.
    """
    google_drive = GoogleDriveAuth(
        service_account_secrets_file=config.google_api.service_account_secrets_file,  # type: ignore
    )
    drive_manager = DriveManager(
        google_drive_folder_id=config.google_api.google_drive_folder_id,  # type: ignore
        google_drive=google_drive.auth(),
        splits_manager=splits,
    )

    drive_manager.sync_local_splits()
    splits.validate_all_splits()
    splits.clean_all_splits()
    try:
        qr.open_db_connection()
        qr.create_config_tables()
        if qr.update_runners_tables(splits_files=splits.splits_files):
            all_data = get_all_database_data(qr)
            export_to_excel(all_data, output_dir)
    finally:
        # qr.drop_staging_tables()
        qr.close_db_connection()


def run_with_google_sheets_only(
    config: Config,
    splits: SplitsManager,
    qr: QueryRunner,
) -> None:
    """
    Run the application using the Google Sheets services but not the Google Drive ones,
    which means the splits are purely local and the resulting data is uploaded to the
    Google Sheet.
    """
    google_sheets = GoogleSheetsAuth(
        service_account_secrets_file=config.google_api.service_account_secrets_file,  # type: ignore
    )
    sheet_manager = SheetManager(
        gspread_client=google_sheets.auth(),
        google_sheet_id=config.google_api.google_sheet_id,  # type: ignore
    )

    splits.validate_all_splits()
    splits.clean_all_splits()
    try:
        qr.open_db_connection()
        qr.create_config_tables()
        if qr.update_runners_tables(splits_files=splits.splits_files):
            all_data = get_all_database_data(qr)
            export_to_google_sheet(sheet_manager, all_data)
    finally:
        # qr.drop_staging_tables()
        qr.close_db_connection()
