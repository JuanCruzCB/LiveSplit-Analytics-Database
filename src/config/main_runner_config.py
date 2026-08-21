import logging
from dataclasses import dataclass
from pathlib import Path

logger = logging.getLogger(__name__)


@dataclass
class MainRunnerConfig:
    name: str
    splits_file: Path

    def __post_init__(self) -> None:
        """
        Validate that the main runner configuration was initialized correctly.
        """
        if "," in self.name or "-" in self.name or "_" in self.name or " " in self.name:
            msg = (
                "The main runner name cannot have commas, hyphens, "
                "underscores or spaces."
            )
            logger.error(msg)
            raise ValueError(msg)

        if not self.splits_file.exists():
            msg = f"The file {self.splits_file} does not exist."
            logger.error(msg)
            raise FileNotFoundError(msg)
