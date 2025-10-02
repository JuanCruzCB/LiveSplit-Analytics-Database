import logging
from dataclasses import dataclass
from pathlib import Path

logger = logging.getLogger(__name__)


@dataclass
class SQLScriptsConfig:
    builder: Path
    config: Path

    def __post_init__(self) -> None:
        """
        Validate that the SQL scripts configuration was initialized correctly.
        """
        if not self.builder.exists():
            msg = f"The file {self.builder} does not exist."
            logger.exception(msg)
            raise FileNotFoundError(msg)
        if not self.config.exists():
            msg = f"The file {self.config} does not exist."
            logger.exception(msg)
            raise FileNotFoundError(msg)
