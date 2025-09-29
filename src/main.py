from config import load_config, setup_logging
from db.database_manager import DatabaseManager
from db.last_updates_tracker import LastUpdatesTracker
from db.query_builder import QueryBuilder
from db.query_runner import QueryRunner
from execution_modes import (
    run_with_google_drive_and_google_sheets,
    run_with_google_drive_only,
    run_with_google_sheets_only,
    run_without_google_api,
)
from splits.splits_manager import SplitsManager


def main() -> None:
    """
    Entry point of the application.

    Sets up logging, loads configuration, initializes authentication and managers,
    synchronizes splits, updates the database, and updates the Google Sheet.
    """
    setup_logging()
    config = load_config()
    runner_names = [config.main_runner.name, *config.other_runners.names]

    splits = SplitsManager(
        splits_output_folder=config.other_runners.splits_folder,
        main_runner_splits_file=config.main_runner.splits_file,
        runner_names=runner_names,
    )
    last_updates = LastUpdatesTracker(
        storage_file=config.last_table_updates_file,
        default_files=splits.splits_files_paths,
    )
    db_manager = DatabaseManager(
        sql_script=config.sql_scripts.main_sql_script,
        config_sql_script=config.sql_scripts.config_sql_script,
        db_config=config.local_db,
        last_updates_tracker=last_updates,
    )
    query_runner = QueryRunner(
        db_manager=db_manager,
        query_builder=QueryBuilder(),
        runner_names=runner_names,
        main_runner_name=config.main_runner.name,
    )

    if not config.google_api.service_account_secrets_file:
        run_without_google_api(splits, query_runner)
    elif config.google_api.google_drive_folder_id and config.google_api.google_sheet_id:
        run_with_google_drive_and_google_sheets(
            config,
            splits,
            query_runner,
        )
    elif (
        config.google_api.google_drive_folder_id
        and not config.google_api.google_sheet_id
    ):
        run_with_google_drive_only(config, splits, query_runner)
    elif (
        not config.google_api.google_drive_folder_id
        and config.google_api.google_sheet_id
    ):
        run_with_google_sheets_only(config, splits, query_runner)


if __name__ == "__main__":
    main()
