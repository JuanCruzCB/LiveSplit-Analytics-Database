import logging
from dataclasses import dataclass
from pathlib import Path

logger = logging.getLogger(__name__)


@dataclass
class OtherRunnersConfig:
    names: list[str]
    splits_folder: Path

    def __post_init__(self) -> None:
        """
        Validate that the other runners configuration was initialized correctly.
        """
        for name in self.names:
            if "," in name or "-" in name or "_" in name or " " in name:
                msg = (
                    "The runner names cannot have commas, hyphens, "
                    "underscores or spaces."
                )
                logger.exception(msg)
                raise ValueError(msg)

        if not self.splits_folder.exists():
            msg = f"The folder {self.splits_folder} does not exist."
            logger.exception(msg)
            raise FileNotFoundError(msg)
