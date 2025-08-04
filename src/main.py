from config import load_config
from google_auth_manager import GoogleAuthManager
from re4database_manager import LastUpdatesTracker, RE4DatabaseManager
from re4drive_manager import RE4DriveManager
from re4query_runner import RE4QueryRunner
from re4sheet_manager import RE4SheetManager
from re4splits_manager import RE4SplitsManager


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
    cfg = load_config()

    auth_manager = GoogleAuthManager(
        service_account_secrets_file=cfg.service_account_secrets_file
    )
    splits_manager = RE4SplitsManager(
        splits_output_folder=cfg.other_runners_splits_folder,
        main_runner_splits_file=cfg.main_runner_splits_file,
        allowed_runners=cfg.allowed_runners,
    )
    drive_manager = RE4DriveManager(
        google_drive_folder_id=cfg.google_drive_folder_id,
        google_drive=auth_manager.google_drive,
        splits_manager=splits_manager,
    )
    sheet_manager = RE4SheetManager(
        gspread_client=auth_manager.gspread_client,
        google_sheet_url=cfg.google_sheet_url,
    )
    last_updates_tracker = LastUpdatesTracker(
        storage_file=cfg.last_updates_file,
        default_files=[
            cfg.main_runner_splits_file,
            *list(cfg.other_runners_splits_folder.glob("*.lss")),
        ],
    )
    db_manager = RE4DatabaseManager(
        individual_sql_script=cfg.individual_sql_file,
        global_sql_script=cfg.global_sql_file,
        db_config=cfg.db_config,
        main_runner_name=cfg.allowed_runners[0],
        last_updates_tracker=last_updates_tracker,
    )
    query_runner = RE4QueryRunner(
        db_manager=db_manager, allowed_runners=cfg.allowed_runners
    )

    print("Getting splits")
    print("=" * 100)
    drive_manager.sync_local_splits()
    print("=" * 100 + "\n")

    print("Checking splits")
    print("=" * 100)
    splits_manager.clean_splits()
    splits = splits_manager.get_splits_last_modtime()
    print("=" * 100 + "\n")

    print("Updating the database")
    print("=" * 100)
    query_runner.open_db_connection()
    new_updates = query_runner.update_runners_tables(splits=splits)
    query_runner.update_global_tables()
    print("=" * 100 + "\n")

    if new_updates:
        update_db_and_sheet(query_runner=query_runner, sheet_manager=sheet_manager)
    else:
        print(
            "Not querying the database nor updating the sheet since there's no new data."
        )

    query_runner.close_db_connection()


if __name__ == "__main__":
    main()
