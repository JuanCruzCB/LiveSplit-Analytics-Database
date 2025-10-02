import logging

from config.config import OUTPUT_DIR


def setup_logging() -> None:
    """
    Sets up logging configuration for the application.
    """
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%d/%m/%Y %I:%M:%S %p",
        handlers=[
            logging.FileHandler(OUTPUT_DIR / "history.log"),
            logging.StreamHandler(),
        ],
    )
