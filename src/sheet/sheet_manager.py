import logging
from datetime import UTC, datetime, timedelta, timezone
from decimal import Decimal

import numpy as np
from gspread import Client
from gspread.exceptions import APIError, WorksheetNotFound
from pandas import DataFrame

from sheet.utils import get_days_hours_str, get_hours_minutes_str

logger = logging.getLogger(__name__)


class SheetManager:
    DATE_TIME_FORMAT = "%d/%m/%Y %H:%M:%S"
    GOOD_DATE_FORMAT = "%d/%m/%Y"
    BAD_DATE_FORMAT = "%Y-%m-%d"

    def __init__(self, gspread_client: Client, google_sheet_id: str):
        self._spreadsheet = gspread_client.open_by_key(google_sheet_id)

    def _update_sheet_with_copy(
        self,
        sheet_tab_name: str,
        data: DataFrame,
        starting_cell: str,
    ) -> None:
        """
        Copies the current contents of the tab 'sheet_tab_name' and
        pastes them onto 'sheet_tab_name old'.
        Then updates the tab 'sheet_tab_name' starting from 'starting_cell'
        inside the Google Sheet with the 'data' that was sent.
        """
        data_list = data.replace({np.nan: ""}).to_numpy().tolist()
        old_sheet_tab_name = f"{sheet_tab_name} old"
        try:
            old_sheet = self._spreadsheet.worksheet(title=old_sheet_tab_name)
            original_sheet = self._spreadsheet.worksheet(title=sheet_tab_name)
            original_data = original_sheet.get_all_values()

            if original_data:
                old_sheet.update(values=original_data, range_name="A1")
                logger.info("Backup '%s' overwritten successfully!", old_sheet_tab_name)

            original_sheet.update(
                range_name=starting_cell,
                values=data_list,
            )
        except WorksheetNotFound as e:
            msg = f"Sheet tab '{sheet_tab_name}' not found in the Google Sheet."
            logger.exception(msg)
            raise ValueError(msg) from e
        except APIError as e:
            msg = f"Google Sheets API error while updating '{sheet_tab_name}': {e!s}"
            logger.exception(msg)
            raise RuntimeError(msg) from e
        except Exception as e:
            msg = f"Unexpected error while updating '{sheet_tab_name}': {e!s}"
            logger.exception(msg)
            raise RuntimeError(msg) from e
        else:
            logger.info("Sheet '%s' updated successfully!", sheet_tab_name)

    def _update_sheet_without_copy(
        self,
        sheet_tab_name: str,
        data: DataFrame,
        starting_cell: str,
    ) -> None:
        """
        Updates the tab 'sheet_tab_name' starting from 'starting_cell'
        inside the Google Sheet with the 'data' that was sent.
        """
        data_list = data.replace({np.nan: ""}).to_numpy().tolist()
        original_sheet = self._spreadsheet.worksheet(title=sheet_tab_name)
        try:
            original_sheet.update(
                range_name=starting_cell,
                values=data_list,
            )
        except WorksheetNotFound as e:
            msg = f"Sheet tab '{sheet_tab_name}' not found in the Google Sheet."
            logger.exception(msg)
            raise ValueError(msg) from e
        except APIError as e:
            msg = f"Google Sheets API error while updating '{sheet_tab_name}': {e!s}"
            logger.exception(msg)
            raise RuntimeError(msg) from e
        except Exception as e:
            msg = f"Unexpected error while updating '{sheet_tab_name}': {e!s}"
            logger.exception(msg)
            raise RuntimeError(msg) from e
        else:
            logger.info("Sheet '%s' updated successfully!", sheet_tab_name)

    def upload_runners_doorsplit_golds(self, doorsplit_golds: DataFrame) -> None:
        self._update_sheet_with_copy(
            sheet_tab_name="Doors",
            data=doorsplit_golds.drop(columns=["split"]),
            starting_cell="B3",
        )

    def upload_runners_chapter_golds(
        self, chapter_golds: DataFrame, chapter_golds_by_doors: DataFrame
    ) -> None:
        self._update_sheet_with_copy(
            sheet_tab_name="Chapters",
            data=chapter_golds.drop(columns=["chapter"]),
            starting_cell="B3",
        )
        self._update_sheet_without_copy(
            sheet_tab_name="Chapters",
            data=chapter_golds_by_doors.drop(columns=["chapter"]),
            starting_cell="B25",
        )

    def upload_runners_section_golds(
        self,
        section_golds: DataFrame,
        section_golds_by_chapters: DataFrame,
        section_golds_by_doors: DataFrame,
    ) -> None:
        self._update_sheet_with_copy(
            sheet_tab_name="Sections",
            data=section_golds.drop(columns=["section"]),
            starting_cell="B3",
        )
        self._update_sheet_without_copy(
            sheet_tab_name="Sections",
            data=section_golds_by_chapters.drop(columns=["section"]),
            starting_cell="B9",
        )
        self._update_sheet_without_copy(
            sheet_tab_name="Sections",
            data=section_golds_by_doors.drop(columns=["section"]),
            starting_cell="B15",
        )

    def upload_runners_best_paces(
        self,
        best_paces: DataFrame,
    ) -> None:
        self._update_sheet_with_copy(
            sheet_tab_name="Paces",
            data=best_paces.drop(columns=["chapter"]),
            starting_cell="B3",
        )

    def upload_runners_rng_patterns(
        self,
        rng_patterns: DataFrame,
    ) -> None:
        rng_patterns = rng_patterns.map(
            lambda x: float(x) if isinstance(x, Decimal) else x
        ).drop(columns=["rng pattern"])

        self._update_sheet_with_copy(
            sheet_tab_name="RNG Patterns",
            data=rng_patterns,
            starting_cell="B4",
        )

    def upload_runners_general_stats(
        self,
        general_stats: DataFrame,
    ) -> None:
        general_stats = general_stats.drop(columns=["Stat"])
        general_stats.iloc[0] = general_stats.iloc[0].apply(
            lambda date_str: datetime.strptime(date_str, self.BAD_DATE_FORMAT)
            .replace(tzinfo=UTC)
            .strftime(self.GOOD_DATE_FORMAT),
        )
        general_stats.iloc[3] = general_stats.iloc[3].apply(
            lambda playtime: get_days_hours_str(playtime)
        )
        self._update_sheet_without_copy(
            sheet_tab_name="General",
            data=general_stats,
            starting_cell="B3",
        )

    def upload_runners_resets(
        self,
        resets: DataFrame,
    ) -> None:
        resets = resets.map(lambda x: float(x) if isinstance(x, Decimal) else x).drop(
            columns=["split"]
        )
        self._update_sheet_without_copy(
            sheet_tab_name="Resets",
            data=resets.map(lambda x: float(x) if isinstance(x, Decimal) else x),
            starting_cell="A3",
        )

    def upload_runners_weekday_data(
        self,
        weekday_data: DataFrame,
    ) -> None:
        indexes_with_playtime = weekday_data.index[
            weekday_data["Stat type"].str.contains("Playtime", case=False, na=False)
        ].tolist()
        for i in indexes_with_playtime:
            weekday_data.iloc[i] = weekday_data.iloc[i].apply(get_hours_minutes_str)
        weekday_data = weekday_data.drop(columns=["Day", "Stat type"])
        self._update_sheet_without_copy(
            sheet_tab_name="Weekday",
            data=weekday_data,
            starting_cell="C2",
        )

    def upload_last_updated_on(self) -> None:
        try:
            sheet = self._spreadsheet.worksheet(title="Title")

            utc_minus_3 = timezone(timedelta(hours=-3))
            current_time = datetime.now(tz=utc_minus_3).strftime(self.DATE_TIME_FORMAT)
            sheet.update_acell(
                "A2",
                f"Last updated on: {current_time} (UTC-3)",
            )
        except WorksheetNotFound as e:
            msg = "The tab 'Title' does not exist in the Google Sheet."
            logger.exception(msg)
            raise ValueError(msg) from e
        except APIError as e:
            msg = "Google Sheets API error during post_last_update."
            logger.exception(msg)
            raise RuntimeError(msg) from e
        except Exception as e:
            msg = "Unexpected error during post_last_update."
            logger.exception(msg)
            raise RuntimeError(msg) from e
        else:
            logger.info("Sheet '%s' updated successfully!", sheet)
