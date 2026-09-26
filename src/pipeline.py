from collections.abc import Generator
from contextlib import contextmanager
from pathlib import Path
from typing import Any

import polars as pl
from polars import DataFrame

from config.config import Config
from db.query_runner import QueryRunner
from db.utils import diff_before_after
from drive.drive_handler import DriveHandler
from google_auth import authenticate_google_drive, authenticate_google_sheets
from sheet.sheet_handler import SheetHandler
from splits.splits_handler import SplitsHandler

SHEET_UPLOADS = [
    ("general_stats", "General", "B3"),
    ("doorsplit_golds", "Doors", "A3"),
    ("chapter_golds", "Chapters", "A3"),
    ("chapter_golds_by_doors", "Chapters", "B25"),
    ("area_golds", "Sections", "A3"),
    ("area_golds_by_chapters", "Sections", "B9"),
    ("area_golds_by_doors", "Sections", "B15"),
    ("best_paces", "Paces", "B3"),
    ("resets", "Resets", "B3"),
    ("rng_patterns", "RNG Patterns", "C4"),
    ("weekday_data", "Weekday", "C2"),
]


def build_drive_handler(
    config: Config,
    splits_handler: SplitsHandler,
) -> DriveHandler | None:
    """
    Build a DriveHandler instance if the configuration has the necessary
    information for Google Drive authentication and folder ID. Returns None if
    the configuration is missing any of the required information.
    """
    if not (
        config.google_api.service_account_secrets_file
        and config.google_api.google_drive_folder_id
    ):
        return None

    google_drive = authenticate_google_drive(
        secrets_file=config.google_api.service_account_secrets_file,
    )
    return DriveHandler(
        google_drive_folder_id=config.google_api.google_drive_folder_id,
        google_drive=google_drive,
        splits_handler=splits_handler,
    )


def build_sheet_handler(config: Config) -> SheetHandler | None:
    """
    Build a SheetHandler instance if the configuration has the necessary
    information for Google Sheets authentication and sheet ID. Returns None if
    the configuration is missing any of the required information.
    """
    if not (
        config.google_api.service_account_secrets_file
        and config.google_api.google_sheet_id
    ):
        return None

    gspread_client = authenticate_google_sheets(
        secrets_file=config.google_api.service_account_secrets_file,
    )
    return SheetHandler(
        gspread_client=gspread_client,
        google_sheet_id=config.google_api.google_sheet_id,
    )


@contextmanager
def db_session(qr: QueryRunner) -> Generator[QueryRunner, Any]:  # pyright: ignore[reportExplicitAny]
    """
    Context manager for database session. Opens a connection to the database,
    creates the config tables and closes the connection when done. Yields the
    QueryRunner instance for use within the context.
    """
    qr.open_db_connection()
    try:
        qr.create_config_tables()
        yield qr
    finally:
        qr.close_db_connection()


def get_main_golds(qr: QueryRunner) -> tuple[DataFrame, DataFrame, DataFrame]:
    """
    Get the main golds from the database and return them as a tuple of DataFrames.
    """
    doorsplit_golds = qr.get_runners_doorsplit_golds(
        split_names_col=True,
        best_col=False,
        sum_of_best_col=False,
    )
    chapter_golds = qr.get_runners_chapter_golds(
        chapter_names_col=True,
        best_col=True,
        sum_of_best_col=True,
    )
    area_golds = qr.get_runners_area_golds(
        area_names_col=True,
        best_col=True,
        sum_of_best_col=True,
    )
    return doorsplit_golds, chapter_golds, area_golds


def get_diffs(
    doorsplit_golds: DataFrame,
    chapter_golds: DataFrame,
    area_golds: DataFrame,
    all_data: dict[str, DataFrame],
) -> DataFrame:
    """
    Get the differences between the old and new golds.
    """
    diff_ds_golds = diff_before_after(
        df1=doorsplit_golds,
        df2=all_data["doorsplit_golds"],
    )
    diff_ch_golds = diff_before_after(
        df1=chapter_golds,
        df2=all_data["chapter_golds"],
    )
    diff_area_golds = diff_before_after(
        df1=area_golds,
        df2=all_data["area_golds"],
    )
    return pl.concat(
        items=[diff_ds_golds, diff_ch_golds, diff_area_golds],
        how="vertical",
    )


def get_all_database_data(qr: QueryRunner) -> dict[str, DataFrame]:
    """
    Get the main relevant data from the database and return it as a
    dictionary of DataFrames.
    """
    return {
        "doorsplit_golds": qr.get_runners_doorsplit_golds(
            split_names_col=True,
            best_col=False,
            sum_of_best_col=False,
        ),
        "chapter_golds": qr.get_runners_chapter_golds(
            chapter_names_col=True,
            best_col=True,
            sum_of_best_col=True,
        ),
        "chapter_golds_by_doors": qr.get_runners_chapter_golds_by_doors(
            chapter_names_col=False,
            best_col=True,
            sum_of_best_col=True,
        ),
        "area_golds": qr.get_runners_area_golds(
            area_names_col=True,
            best_col=True,
            sum_of_best_col=True,
        ),
        "area_golds_by_chapters": qr.get_runners_area_golds_by_chapters(
            area_names_col=False,
            best_col=True,
            sum_of_best_col=True,
        ),
        "area_golds_by_doors": qr.get_runners_area_golds_by_doors(
            area_names_col=False,
            best_col=True,
            sum_of_best_col=True,
        ),
        "best_paces": qr.get_runners_best_paces(
            chapter_names_col=False,
            best_col=True,
        ),
        "rng_patterns": qr.get_runners_rng_patterns(pattern_names_col=False),
        "general_stats": qr.get_runners_general_stats(stat_names_col=False),
        "resets": qr.get_runners_resets(split_names_col=False),
        "weekday_data": qr.get_runners_weekday_data(weekday_stat_cols=False),
    }


def export_to_google_sheet(
    sheet_handler: SheetHandler,
    data: dict[str, DataFrame],
    diffs: DataFrame,
) -> None:
    """
    Exports the given data to a Google Sheet using the provided SheetHandler.
    """
    for data_key, tab_name, starting_cell in SHEET_UPLOADS:
        sheet_handler.upload_dataframe(
            data=data[data_key],
            tab_name=tab_name,
            starting_cell=starting_cell,
        )

    sheet_handler.upload_changelog(
        before_after_data=diffs,
        tab_name="Changelog",
        starting_cell="A4",
    )


def export_to_excel_files(
    output_dir: Path,
    data: dict[str, DataFrame],
    diffs: DataFrame,
) -> None:
    """
    Exports the given data to Excel files in the specified output directory.
    """
    for name, df in data.items():
        _ = df.write_excel(workbook=output_dir / f"{name}.xlsx")

    _ = diffs.write_excel(workbook=output_dir / "changelog.xlsx")


def run_pipeline(
    config: Config,
    splits_handler: SplitsHandler,
    qr: QueryRunner,
) -> None:
    """
    Runs the data processing pipeline:

    1. Synchronizes local splits with Google Drive (if configured).
    2. Validates and cleans all splits.
    3. Gets the current data from the database if any.
    4. Updates the database with new splits data.
    5. Exports the updated data to Google Sheets (if configured) or saves it
    as Excel files in the output directory.
    """
    drive_handler = build_drive_handler(config, splits_handler)
    sheet_handler = build_sheet_handler(config)

    if drive_handler is not None:
        drive_handler.sync_local_splits()

    splits_handler.validate_all_splits()
    splits_handler.clean_all_splits()

    with db_session(qr):
        old_golds = get_main_golds(qr)

        if not qr.update_runners_tables(splits_files=splits_handler.get_splits_files()):
            return

        all_data = get_all_database_data(qr)

        if sheet_handler is None:
            export_to_excel_files(
                output_dir=config.output_dir,
                data=all_data,
                diffs=get_diffs(*old_golds, all_data=all_data),
            )
        else:
            export_to_google_sheet(
                sheet_handler=sheet_handler,
                data=all_data,
                diffs=get_diffs(*old_golds, all_data=all_data),
            )
