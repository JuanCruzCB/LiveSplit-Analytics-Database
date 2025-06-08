from contextlib import contextmanager
from time import sleep, time

from pandas import DataFrame

from constants import (
    Format,
    Files,
    GOOGLE_DRIVE_FOLDER_ID,
    SPLITS_OUTPUT_FOLDER,
    GOOGLE_SHEET_URL,
    DB_CONFIG,
    CURRENTLY_ALLOWED_RUNNERS,
    DEFAULT_UPDATES,
)
from google_auth_manager import GoogleAuthManager
from re4database_manager import RE4DatabaseManager
from re4drive_manager import RE4DriveManager
from re4sheet_manager import RE4SheetManager
from timing import execution_times


@contextmanager
def measure_total_time():
    start_time = time()
    yield
    execution_time = time() - start_time
    seconds = int(execution_time)
    milliseconds = int((execution_time % 1) * 1000)
    execution_time_formatted = Format.TIME_FORMAT.value.format(seconds, milliseconds)
    execution_times["The whole script"] = execution_time_formatted


def update_database(db_manager: RE4DatabaseManager, splits: dict[str, str]) -> bool:
    print("Updating the database")
    print("=" * 100)
    new_updates = db_manager.update_runners_tables(splits=splits)
    db_manager.update_global_tables()
    print("=" * 100 + "\n")
    return new_updates


def query_database(
    db_manager: RE4DatabaseManager,
) -> tuple[
    DataFrame,
    DataFrame,
    DataFrame,
    DataFrame,
    DataFrame,
    DataFrame,
    DataFrame,
    DataFrame,
    DataFrame,
    DataFrame,
    DataFrame,
]:
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

    db_manager.close_connection()
    print("=" * 100 + "\n")
    return (
        df_doorsplit_golds,
        df_chapter_golds,
        df_chapter_golds_by_doors,
        df_section_golds,
        df_section_golds_by_chapters,
        df_section_golds_by_doors,
        df_best_paces,
        df_rng_patterns,
        df_general_stats,
        df_resets,
        df_weekday_data,
    )


def update_sheet(
    sheet_manager: RE4SheetManager,
    dataframes: tuple[
        DataFrame,
        DataFrame,
        DataFrame,
        DataFrame,
        DataFrame,
        DataFrame,
        DataFrame,
        DataFrame,
        DataFrame,
        DataFrame,
        DataFrame,
    ],
) -> None:
    print("Updating the Google Sheet")
    print("=" * 100)
    sheet_manager.copy_doorsplits_to_sheet(doorsplits=dataframes[0])
    sheet_manager.copy_chapters_to_sheet(
        chapters=dataframes[1],
        chapters_by_doors=dataframes[2],
    )
    sheet_manager.copy_sections_to_sheet(
        sections=dataframes[3],
        sections_by_chapters=dataframes[4],
        sections_by_doors=dataframes[5],
    )
    sheet_manager.copy_paces_to_sheet(paces=dataframes[6])
    sheet_manager.copy_rng_patterns_to_sheet(rng_patterns=dataframes[7])
    sheet_manager.copy_general_stats_to_sheet(general_stats=dataframes[8])
    sheet_manager.copy_resets_to_sheet(resets=dataframes[9])
    sheet_manager.copy_weekday_data_to_sheet(weekday_data=dataframes[10])
    sheet_manager.post_last_update()
    print("=" * 100 + "\n")

    """
    url_village_graph = graph_village(excel=excel_files[9])
    url_castle_graph = graph_castle(excel=excel_files[9])
    url_island_graph = graph_island(excel=excel_files[9])

    sheet_manager.copy_graphs_to_sheet(
        url_village_graph=url_village_graph,
        url_castle_graph=url_castle_graph,
        url_island_graph=url_island_graph,
    )
    """


def main() -> None:
    with measure_total_time():
        auth_manager = GoogleAuthManager(
            service_account_path=Files.GOOGLE_SERVICE_ACCOUNT_SECRETS.value
        )
        drive_manager = RE4DriveManager(
            google_drive=auth_manager.google_drive,
            google_drive_folder_id=GOOGLE_DRIVE_FOLDER_ID,
            currently_allowed_runners=CURRENTLY_ALLOWED_RUNNERS,
            splits_output_folder=SPLITS_OUTPUT_FOLDER,
            my_splits_file=Files.MY_SPLITS_FILE.value,
        )
        sheet_manager = RE4SheetManager(
            gspread_client=auth_manager.gspread_client,
            google_sheet_url=GOOGLE_SHEET_URL,
        )
        db_manager = RE4DatabaseManager(
            db_config=DB_CONFIG,
            main_sql_script=Files.MAIN_SQL_SCRIPT.value,
            global_sql_script=Files.GLOBAL_SQL_SCRIPT.value,
            last_updates_file=Files.LAST_UPDATES_FILE.value,
            currently_allowed_runners=CURRENTLY_ALLOWED_RUNNERS,
            default_updates=DEFAULT_UPDATES,
        )

        while True:
            splits = drive_manager.download_splits()
            new_updates = update_database(db_manager=db_manager, splits=splits)
            if new_updates:
                dataframes = query_database(db_manager=db_manager)
                update_sheet(sheet_manager=sheet_manager, dataframes=dataframes)
            else:
                print(
                    "Not querying the database nor updating the sheet since there's no new data."
                )
                sleep(5)

    for func_name, exec_time in execution_times.items():
        print(f"{func_name} took {exec_time}")


if __name__ == "__main__":
    main()
