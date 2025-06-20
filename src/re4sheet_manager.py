from datetime import datetime
from typing import Any

import gspread
from gspread.exceptions import APIError, WorksheetNotFound
from pandas import DataFrame

from constants import Format


class RE4SheetManager:
    GOOGLE_SHEET_URL = "https://docs.google.com/spreadsheets/d/1q1e9GCgaUc-LbhQWHEVjKkl0275hkfDVq0rHgQLrF-E/edit?usp=sharing"

    def __init__(self, gspread_client: gspread.Client):
        self._spreadsheet = gspread_client.open_by_url(url=self.GOOGLE_SHEET_URL)

    def _update_sheet(
        self,
        sheet_tab_name: str,
        data: list[list[Any]],
        range_name: str,
        make_copy: bool = False,
    ) -> None:
        try:
            original_sheet = self._spreadsheet.worksheet(title=sheet_tab_name)

            if make_copy:
                old_sheet_tab_name = f"{sheet_tab_name} old"
                old_sheet = self._spreadsheet.worksheet(title=old_sheet_tab_name)
                original_data = original_sheet.get_all_values()
                if original_data:
                    old_sheet.update(values=original_data, range_name="A1")
                    print(f"Backup '{old_sheet_tab_name}' overwritten successfully!")

            original_sheet.update(
                range_name=range_name,
                values=data,
            )
            print(f"Sheet '{sheet_tab_name}' updated successfully!")

        except WorksheetNotFound as e:
            raise ValueError(
                f"Sheet tab '{sheet_tab_name}' not found in the Google Sheet."
            ) from e
        except APIError as e:
            raise RuntimeError(
                f"Google Sheets API error while updating '{sheet_tab_name}': {str(e)}"
            ) from e
        except Exception as e:
            raise RuntimeError(
                f"Unexpected error while updating '{sheet_tab_name}': {str(e)}"
            ) from e

    def copy_doorsplits_to_sheet(self, doorsplits: DataFrame) -> None:
        self._update_sheet(
            sheet_tab_name="Doors",
            data=doorsplits.values.tolist(),
            range_name="B3",
            make_copy=True,
        )

    def copy_chapters_to_sheet(
        self, chapters: DataFrame, chapters_by_doors: DataFrame
    ) -> None:
        self._update_sheet(
            sheet_tab_name="Chapters",
            data=chapters.values.tolist(),
            range_name="B3",
            make_copy=True,
        )
        self._update_sheet(
            sheet_tab_name="Chapters",
            data=chapters_by_doors.values.tolist(),
            range_name="B25",
        )

    def copy_sections_to_sheet(
        self,
        sections: DataFrame,
        sections_by_chapters: DataFrame,
        sections_by_doors: DataFrame,
    ) -> None:
        self._update_sheet(
            sheet_tab_name="Sections",
            data=sections.values.tolist(),
            range_name="B3",
            make_copy=True,
        )
        self._update_sheet(
            sheet_tab_name="Sections",
            data=sections_by_chapters.values.tolist(),
            range_name="B9",
        )
        self._update_sheet(
            sheet_tab_name="Sections",
            data=sections_by_doors.values.tolist(),
            range_name="B15",
        )

    def copy_paces_to_sheet(
        self,
        paces: DataFrame,
    ) -> None:
        self._update_sheet(
            sheet_tab_name="Paces",
            data=paces.values.tolist(),
            range_name="B3",
            make_copy=True,
        )

    def copy_rng_patterns_to_sheet(
        self,
        rng_patterns: DataFrame,
    ) -> None:
        self._update_sheet(
            sheet_tab_name="RNG Patterns",
            data=rng_patterns.values.tolist(),
            range_name="B4",
            make_copy=True,
        )

    def copy_general_stats_to_sheet(
        self,
        general_stats: DataFrame,
    ) -> None:
        self._update_sheet(
            sheet_tab_name="General",
            data=general_stats.values.tolist(),
            range_name="B3",
        )

    def copy_resets_to_sheet(
        self,
        resets: DataFrame,
    ) -> None:
        self._update_sheet(
            sheet_tab_name="Resets",
            data=resets.values.tolist(),
            range_name="A3",
        )

    def copy_weekday_data_to_sheet(
        self,
        weekday_data: DataFrame,
    ) -> None:
        self._update_sheet(
            sheet_tab_name="Weekday",
            data=weekday_data.values.tolist(),
            range_name="C2",
        )

    def post_last_update(self) -> None:
        try:
            sheet = self._spreadsheet.worksheet(title="Title")
            current_time = datetime.now().strftime(Format.DATE_TIME_FORMAT)
            sheet.update_acell(
                "A2",
                f"Last updated on: {current_time} (UTC-3)",
            )
        except WorksheetNotFound as e:
            raise ValueError(
                "The tab 'Title' does not exist in the Google Sheet."
            ) from e
        except APIError as e:
            raise RuntimeError(
                "Google Sheets API error during post_last_update."
            ) from e
        except Exception as e:
            raise RuntimeError("Unexpected error during post_last_update.") from e
