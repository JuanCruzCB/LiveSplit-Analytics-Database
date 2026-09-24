import sys

from loguru import logger

from config.config import OUTPUT_DIR


def setup_logging() -> None:
    """
    Sets up logging configuration for the application.
    """
    log_format = "{time:DD/MM/YYYY hh:mm:ss A} - {name} - {level} - {message}"

    logger.remove()

    _ = logger.add(
        OUTPUT_DIR / "history.log",
        level="INFO",
        format=log_format,
        encoding="UTF-8",
    )

    _ = logger.add(
        sys.stdout,
        level="INFO",
        format=log_format,
    )
