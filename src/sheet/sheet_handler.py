from datetime import datetime, timedelta, timezone
from typing import Final

from gspread import Client, Spreadsheet, Worksheet
from gspread.exceptions import APIError, SpreadsheetNotFound, WorksheetNotFound
from gspread.utils import a1_to_rowcol, rowcol_to_a1
from loguru import logger
from polars import DataFrame

from sheet.exceptions import SheetNotFoundError, UnauthorizedError


class SheetHandler:
    GOOD_DATETIME_FORMAT: Final[str] = "%d/%m/%Y %H:%M:%S"
    _spreadsheet: Spreadsheet

    def __init__(self, gspread_client: Client, google_sheet_id: str) -> None:
        try:
            self._spreadsheet = gspread_client.open_by_key(
                key=google_sheet_id,
            )
        except SpreadsheetNotFound as e:
            msg = f"The spreadsheet with id = {google_sheet_id} was not found."
            logger.exception(msg)
            raise SheetNotFoundError from e
        except PermissionError as e:
            err_msg = (
                "The service account that is being used does not have authorization "
                f"on the spreadsheet with id = {google_sheet_id}"
            )
            logger.exception(err_msg)
            raise UnauthorizedError from e

    def _find_worksheet_by_title(self, title: str) -> Worksheet:
        """
        Finds a worksheet inside the spreadsheet by its title.
        """
        try:
            return self._spreadsheet.worksheet(title=title)
        except WorksheetNotFound as e:
            msg = f"The tab '{title}' does not exist in the Google Sheet."
            logger.exception(msg)
            raise ValueError(msg) from e

    def upload_dataframe(
        self,
        data: DataFrame,
        tab_name: str,
        starting_cell: str,
    ) -> None:
        sheet = self._find_worksheet_by_title(title=tab_name)
        try:
            _ = sheet.update(
                range_name=starting_cell,
                values=data.fill_nan(value=None).to_numpy().tolist(),
            )
        except APIError as e:
            msg = f"Google Sheets API error while updating '{tab_name}': {e!s}"
            logger.exception(msg)
            raise RuntimeError(msg) from e
        except Exception as e:
            msg = f"Unexpected error while updating '{tab_name}': {e!s}"
            logger.exception(msg)
            raise RuntimeError(msg) from e
        else:
            logger.info("Sheet '{}' updated successfully!", tab_name)

    def upload_changelog(
        self,
        before_after_data: DataFrame,
        tab_name: str,
        starting_cell: str,
    ) -> None:
        sheet = self._find_worksheet_by_title(title=tab_name)
        try:
            utc_minus_3 = timezone(offset=timedelta(hours=-3))
            current_time = datetime.now(tz=utc_minus_3).strftime(
                format=self.GOOD_DATETIME_FORMAT,
            )
            _ = sheet.update_acell(
                label="A2",
                value=f"Last updated on: {current_time} (UTC-3)",
            )

            # Clear all the values in the range starting from 'starting_cell' to
            # the last row of the sheet and 2 columns to the right of 'starting_cell'.
            _, start_col = a1_to_rowcol(label=starting_cell)
            end_col = start_col + 2
            end_row = sheet.row_count
            clear_range = f"{starting_cell}:{rowcol_to_a1(row=end_row, col=end_col)}"
            _ = sheet.batch_clear(ranges=[clear_range])

            _ = sheet.update(
                range_name=starting_cell,
                values=before_after_data.fill_nan(value=None).to_numpy().tolist(),
            )
        except APIError as e:
            msg = "Google Sheets API error during 'upload_changelog'."
            logger.exception(msg)
            raise RuntimeError(msg) from e
        except Exception as e:
            msg = "Unexpected error during 'upload_changelog'."
            logger.exception(msg)
            raise RuntimeError(msg) from e
        else:
            logger.info("Sheet '{}' updated successfully!", sheet.title)
