import logging
from dataclasses import dataclass
from datetime import date

logger = logging.getLogger(__name__)


@dataclass
class ExcludeDataBeforeConfig:
    date: date | None

    def __post_init__(self) -> None:
        """
        Validate that the date is in the correct format YYYY-MM-DD and that it is before
        the current date.
        """
        if not self.date:
            return

        if self.date >= date.today():  # noqa: DTZ011
            msg = f"The date {self.date} must be before the current date."
            logger.error(msg)
            raise ValueError(msg)

    def get_date_str(self) -> str:
        """
        Return the date as a string in the format YYYY-MM-DD.

        If the date is None, return a default date string "2000-01-01".
        """
        return self.date.strftime("%Y-%m-%d") if self.date else "2000-01-01"
