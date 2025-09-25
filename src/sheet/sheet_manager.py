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

    def __init__(self, gspread_client: Client, google_sheet_id: str) -> None:
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

    def upload_dataframe_with_copy(
        self,
        tab_name: str,
        starting_cell: str,
        data: DataFrame,
    ) -> None:
        """
        Copies the current contents of the tab 'tab_name' and
        pastes them onto 'tab_name old'.

        Then updates the tab of the Google Sheet named 'tab_name' starting from the
        cell 'starting_cell', with the 'data' that was sent.
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

    def upload_dataframe_without_copy(
        self,
        tab_name: str,
        starting_cell: str,
        data: DataFrame,
    ) -> None:
        """
        Updates the tab of the Google Sheet named 'tab_name' starting from the
        cell 'starting_cell', with the 'data' that was sent.
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

    def upload_last_updated_on(self, tab_name: str, cell: str) -> None:
        """
        Posts, on the given 'tab_name' and 'cell' of the Google Sheet,
        the current date and time (in UTC-3 timezone), to show when
        the Google Sheet was last updated.
        """
        try:
            sheet = self._spreadsheet.worksheet(title=tab_name)

            utc_minus_3 = timezone(timedelta(hours=-3))
            current_time = datetime.now(tz=utc_minus_3).strftime(
                self.GOOD_DATETIME_FORMAT
            )
            sheet.update_acell(
                label=cell,
                value=f"Last updated on: {current_time} (UTC-3)",
            )
        except WorksheetNotFound as e:
            msg = f"The tab '{tab_name}' does not exist in the Google Sheet."
            logger.exception(msg)
            raise ValueError(msg) from e
        except APIError as e:
            msg = "Google Sheets API error during 'upload_last_updated_on'."
            logger.exception(msg)
            raise RuntimeError(msg) from e
        except Exception as e:
            msg = "Unexpected error during 'upload_last_updated_on'."
            logger.exception(msg)
            raise RuntimeError(msg) from e
        else:
            logger.info("Sheet '%s' updated successfully!", sheet.title)
