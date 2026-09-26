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
    cfg = load_config()
    runner_names = [cfg.main_runner.name, *cfg.other_runners.names]

    splits_handler = SplitsHandler(
        splits_output_folder=cfg.other_runners.splits_folder,
        main_runner_splits_file=cfg.main_runner.splits_file,
        runner_names=runner_names,
    )
    last_updates = LastUpdatesTracker(
        storage_file=cfg.last_table_updates_file,
        default_files=splits_handler.get_splits_files_paths(),
    )
    db_handler = DatabaseHandler(
        sql_script=cfg.sql_scripts.builder,
        config_sql_script=cfg.sql_scripts.config,
        db_config=cfg.local_database,
        exclude_data_before=cfg.exclude_data_before_str,
        last_updates_tracker=last_updates,
    )
    qr = QueryRunner(
        db_handler=db_handler,
        query_builder=QueryBuilder(),
        runner_names=runner_names,
        main_runner_name=cfg.main_runner.name,
        output_dir=cfg.output_dir,
    )

    run_pipeline(cfg, splits_handler, qr)


if __name__ == "__main__":
    main()
