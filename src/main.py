from config.config import load_config
from config.logger import setup_logging
from db.database_handler import DatabaseHandler
from db.last_updates_tracker import LastUpdatesTracker
from db.query_builder import QueryBuilder
from db.query_runner import QueryRunner
from pipeline import run_pipeline
from splits.splits_handler import SplitsHandler


def main() -> None:
    """
    Entry point of the application.

    1. Sets up logging.
    2. Loads configuration from config.yaml.
    3. Initializes SplitsHandler, LastUpdatesTracker, DatabaseHandler, and QueryRunner.
    4. Runs the data processing pipeline.
    """
    setup_logging()
    config = load_config()
    runner_names = [config.main_runner.name, *config.other_runners.names]

    splits_handler = SplitsHandler(
        splits_output_folder=config.other_runners.splits_folder,
        main_runner_splits_file=config.main_runner.splits_file,
        runner_names=runner_names,
    )
    last_updates = LastUpdatesTracker(
        storage_file=config.last_table_updates_file,
        default_files=splits_handler.get_splits_files_paths(),
    )
    db_handler = DatabaseHandler(
        sql_script=config.sql_scripts.builder,
        config_sql_script=config.sql_scripts.config,
        db_config=config.local_db,
        exclude_data_before_config=config.exclude_data_before,
        last_updates_tracker=last_updates,
    )
    qr = QueryRunner(
        db_handler=db_handler,
        query_builder=QueryBuilder(),
        runner_names=runner_names,
        main_runner_name=config.main_runner.name,
        output_dir=config.output_dir,
    )

    run_pipeline(config, splits_handler, qr)


if __name__ == "__main__":
    main()
