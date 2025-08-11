from datetime import UTC, datetime, timedelta, timezone
from decimal import Decimal

import numpy as np
from gspread import Client
from gspread.exceptions import APIError, WorksheetNotFound
from pandas import DataFrame

from utils import get_days_hours_str, get_hours_minutes_str


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
    ):
        """
        Copies the current contents of the tab 'sheet_tab_name' and
        pastes them onto 'sheet_tab_name old'.
        Then updates the tab 'sheet_tab_name' starting from 'starting_cell'
        inside the Google Sheet with the 'data' that was sent.
        """
        data_list = data.replace({np.nan: ""}).to_numpy().tolist()
        try:
            old_sheet_tab_name = f"{sheet_tab_name} old"
            old_sheet = self._spreadsheet.worksheet(title=old_sheet_tab_name)

            original_sheet = self._spreadsheet.worksheet(title=sheet_tab_name)
            original_data = original_sheet.get_all_values()

            if original_data:
                old_sheet.update(values=original_data, range_name="A1")
                print(f"Backup '{old_sheet_tab_name}' overwritten successfully!")

            original_sheet.update(
                range_name=starting_cell,
                values=data_list,
            )
            print(f"Sheet '{sheet_tab_name}' updated successfully!")

        except WorksheetNotFound as e:
            msg = f"Sheet tab '{sheet_tab_name}' not found in the Google Sheet."
            raise ValueError(msg) from e
        except APIError as e:
            msg = f"Google Sheets API error while updating '{sheet_tab_name}': {e!s}"
            raise RuntimeError(msg) from e
        except Exception as e:
            msg = f"Unexpected error while updating '{sheet_tab_name}': {e!s}"
            raise RuntimeError(msg) from e

    def _update_sheet_without_copy(
        self,
        sheet_tab_name: str,
        data: DataFrame,
        starting_cell: str,
    ):
        """
        Updates the tab 'sheet_tab_name' starting from 'starting_cell'
        inside the Google Sheet with the 'data' that was sent.
        """
        data_list = data.replace({np.nan: ""}).to_numpy().tolist()
        try:
            original_sheet = self._spreadsheet.worksheet(title=sheet_tab_name)
            original_sheet.update(
                range_name=starting_cell,
                values=data_list,
            )
            print(f"Sheet '{sheet_tab_name}' updated successfully!")

        except WorksheetNotFound as e:
            msg = f"Sheet tab '{sheet_tab_name}' not found in the Google Sheet."
            raise ValueError(msg) from e
        except APIError as e:
            msg = f"Google Sheets API error while updating '{sheet_tab_name}': {e!s}"
            raise RuntimeError(msg) from e
        except Exception as e:
            msg = f"Unexpected error while updating '{sheet_tab_name}': {e!s}"
            raise RuntimeError(msg) from e

    def copy_doorsplits_to_sheet(self, doorsplit_golds: DataFrame) -> None:
        self._update_sheet_with_copy(
            sheet_tab_name="Doors",
            data=doorsplit_golds.drop(columns=["split"]),
            starting_cell="B3",
        )

    def copy_chapters_to_sheet(
        self, chapter_golds: DataFrame, chapter_golds_by_doors: DataFrame
    ) -> None:
        self._update_sheet_with_copy(
            sheet_tab_name="Chapters",
            data=chapter_golds,
            starting_cell="B3",
        )
        self._update_sheet_without_copy(
            sheet_tab_name="Chapters",
            data=chapter_golds_by_doors,
            starting_cell="B25",
        )

    def copy_sections_to_sheet(
        self,
        section_golds: DataFrame,
        section_golds_by_chapters: DataFrame,
        section_golds_by_doors: DataFrame,
    ) -> None:
        self._update_sheet_with_copy(
            sheet_tab_name="Sections",
            data=section_golds,
            starting_cell="B3",
        )
        self._update_sheet_without_copy(
            sheet_tab_name="Sections",
            data=section_golds_by_chapters,
            starting_cell="B9",
        )
        self._update_sheet_without_copy(
            sheet_tab_name="Sections",
            data=section_golds_by_doors,
            starting_cell="B15",
        )

    def copy_best_paces_to_sheet(
        self,
        best_paces: DataFrame,
    ) -> None:
        self._update_sheet_with_copy(
            sheet_tab_name="Paces",
            data=best_paces,
            starting_cell="B3",
        )

    def copy_rng_patterns_to_sheet(
        self,
        rng_patterns: DataFrame,
    ) -> None:
        rng_patterns = rng_patterns.map(
            lambda x: float(x) if isinstance(x, Decimal) else x
        ).drop(columns=["pattern"])

        self._update_sheet_with_copy(
            sheet_tab_name="RNG Patterns",
            data=rng_patterns,
            starting_cell="B4",
        )

    def copy_general_stats_to_sheet(
        self,
        general_stats: DataFrame,
    ) -> None:
        general_stats = general_stats.drop(columns=["chapter"])
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

    def copy_resets_to_sheet(
        self,
        resets: DataFrame,
    ) -> None:
        self._update_sheet_without_copy(
            sheet_tab_name="Resets",
            data=resets.map(lambda x: float(x) if isinstance(x, Decimal) else x),
            starting_cell="A3",
        )

    def copy_weekday_data_to_sheet(
        self,
        weekday_data: DataFrame,
    ) -> None:
        ranges_to_process = [
            range(7, 14),
            range(21, 28),
            range(35, 42),
            range(49, 56),
            range(63, 70),
        ]
        for r in ranges_to_process:
            for i in r:
                weekday_data.iloc[i] = weekday_data.iloc[i].apply(get_hours_minutes_str)
        self._update_sheet_without_copy(
            sheet_tab_name="Weekday",
            data=weekday_data.drop(columns=["day", "col"]),
            starting_cell="C2",
        )

    def post_last_update(self) -> None:
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
            raise ValueError(msg) from e
        except APIError as e:
            msg = "Google Sheets API error during post_last_update."
            raise RuntimeError(msg) from e
        except Exception as e:
            msg = "Unexpected error during post_last_update."
            raise RuntimeError(msg) from e
