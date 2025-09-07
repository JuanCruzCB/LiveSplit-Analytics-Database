import logging
from datetime import datetime, timedelta, timezone

import numpy as np
from gspread import Client
from gspread.exceptions import APIError, SpreadsheetNotFound, WorksheetNotFound
from pandas import DataFrame

logger = logging.getLogger(__name__)


class SheetNotFoundError(Exception):
    pass


class UnauthorizedError(Exception):
    pass


class SheetManager:
    GOOD_DATETIME_FORMAT = "%d/%m/%Y %H:%M:%S"
    GOOD_DATE_FORMAT = "%d/%m/%Y"
    BAD_DATE_FORMAT = "%Y-%m-%d"

    def __init__(self, gspread_client: Client, google_sheet_id: str):
        try:
            self._spreadsheet = gspread_client.open_by_key(google_sheet_id)
        except SpreadsheetNotFound as e:
            msg = f"The spreadsheet with id = {google_sheet_id} was not found."
            logger.exception(msg)
            raise SheetNotFoundError from e
        except PermissionError as e:
            msg = f"The service account that is being used does not have authorization on the spreadsheet with id = {google_sheet_id}"
            logger.exception(msg)
            raise UnauthorizedError from e

    def _update_sheet_with_copy(
        self,
        tab_name: str,
        starting_cell: str,
        data: DataFrame,
    ) -> None:
        """
        Copies the current contents of the tab 'sheet_tab_name' and
        pastes them onto 'sheet_tab_name old'.
        Then updates the tab 'sheet_tab_name' starting from 'starting_cell'
        inside the Google Sheet with the 'data' that was sent.
        """
        data_list = data.replace({np.nan: ""}).to_numpy().tolist()
        old_sheet_tab_name = f"{tab_name} old"
        try:
            old_sheet = self._spreadsheet.worksheet(title=old_sheet_tab_name)
            original_sheet = self._spreadsheet.worksheet(title=tab_name)
            original_data = original_sheet.get_all_values()

            if original_data:
                old_sheet.update(values=original_data, range_name="A1")
                logger.info("Backup '%s' overwritten successfully!", old_sheet_tab_name)

            original_sheet.update(
                range_name=starting_cell,
                values=data_list,
            )
        except WorksheetNotFound as e:
            msg = f"Sheet tab '{tab_name}' not found in the Google Sheet."
            logger.exception(msg)
            raise ValueError(msg) from e
        except APIError as e:
            msg = f"Google Sheets API error while updating '{tab_name}': {e!s}"
            logger.exception(msg)
            raise RuntimeError(msg) from e
        except Exception as e:
            msg = f"Unexpected error while updating '{tab_name}': {e!s}"
            logger.exception(msg)
            raise RuntimeError(msg) from e
        else:
            logger.info("Sheet '%s' updated successfully!", tab_name)

    def _update_sheet_without_copy(
        self,
        tab_name: str,
        starting_cell: str,
        data: DataFrame,
    ) -> None:
        """
        Updates the tab 'sheet_tab_name' starting from 'starting_cell'
        inside the Google Sheet with the 'data' that was sent.
        """
        data_list = data.replace({np.nan: ""}).to_numpy().tolist()
        original_sheet = self._spreadsheet.worksheet(title=tab_name)
        try:
            original_sheet.update(
                range_name=starting_cell,
                values=data_list,
            )
        except WorksheetNotFound as e:
            msg = f"Sheet tab '{tab_name}' not found in the Google Sheet."
            logger.exception(msg)
            raise ValueError(msg) from e
        except APIError as e:
            msg = f"Google Sheets API error while updating '{tab_name}': {e!s}"
            logger.exception(msg)
            raise RuntimeError(msg) from e
        except Exception as e:
            msg = f"Unexpected error while updating '{tab_name}': {e!s}"
            logger.exception(msg)
            raise RuntimeError(msg) from e
        else:
            logger.info("Sheet '%s' updated successfully!", tab_name)

    def upload_runners_doorsplit_golds(self, doorsplit_golds: DataFrame) -> None:
        self._update_sheet_with_copy(
            tab_name="Doors",
            starting_cell="B3",
            data=doorsplit_golds,
        )

    def upload_runners_chapter_golds(
        self, chapter_golds: DataFrame, chapter_golds_by_doors: DataFrame
    ) -> None:
        self._update_sheet_with_copy(
            tab_name="Chapters",
            starting_cell="B3",
            data=chapter_golds,
        )
        self._update_sheet_without_copy(
            tab_name="Chapters",
            starting_cell="B25",
            data=chapter_golds_by_doors,
        )

    def upload_runners_area_golds(
        self,
        area_golds: DataFrame,
        area_golds_by_chapters: DataFrame,
        area_golds_by_doors: DataFrame,
    ) -> None:
        self._update_sheet_with_copy(
            tab_name="Sections",
            starting_cell="B3",
            data=area_golds,
        )
        self._update_sheet_without_copy(
            tab_name="Sections", starting_cell="B9", data=area_golds_by_chapters
        )

        self._update_sheet_without_copy(
            tab_name="Sections", starting_cell="B15", data=area_golds_by_doors
        )

    def upload_runners_best_paces(
        self,
        best_paces: DataFrame,
    ) -> None:
        self._update_sheet_with_copy(
            tab_name="Paces",
            starting_cell="B3",
            data=best_paces,
        )

    def upload_runners_rng_patterns(
        self,
        rng_patterns: DataFrame,
    ) -> None:
        self._update_sheet_with_copy(
            tab_name="RNG Patterns",
            starting_cell="B4",
            data=rng_patterns,
        )

    def upload_runners_general_stats(
        self,
        general_stats: DataFrame,
    ) -> None:
        self._update_sheet_without_copy(
            tab_name="General",
            starting_cell="B3",
            data=general_stats,
        )

    def upload_runners_resets(
        self,
        resets: DataFrame,
    ) -> None:
        self._update_sheet_without_copy(
            tab_name="Resets",
            starting_cell="B3",
            data=resets,
        )

    def upload_runners_weekday_data(
        self,
        weekday_data: DataFrame,
    ) -> None:
        self._update_sheet_without_copy(
            tab_name="Weekday",
            starting_cell="C2",
            data=weekday_data,
        )

    def upload_last_updated_on(self) -> None:
        try:
            sheet = self._spreadsheet.worksheet(title="Title")

            utc_minus_3 = timezone(timedelta(hours=-3))
            current_time = datetime.now(tz=utc_minus_3).strftime(
                self.GOOD_DATETIME_FORMAT
            )
            sheet.update_acell(
                label="A2",
                value=f"Last updated on: {current_time} (UTC-3)",
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
            logger.info("Sheet '%s' updated successfully!", sheet.title)
