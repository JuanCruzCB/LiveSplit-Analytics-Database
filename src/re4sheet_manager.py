from datetime import datetime
from pathlib import Path
from typing import Any

import gspread
from google.oauth2.service_account import Credentials
from pandas import DataFrame

from constants import Format
from decorators import measure_time


class RE4SheetManager:
    def __init__(self):
        client = gspread.authorize(
            credentials=Credentials.from_service_account_file(
                filename=Path(
                    r"H:\Juan\3. Projects\GH Sawken\Python\UpdateGoldsGlobal\credentials\service_account_secrets.json"
                ),
                scopes=[
                    "https://www.googleapis.com/auth/spreadsheets",
                    "https://www.googleapis.com/auth/drive",
                ],
            )
        )
        self._spreadsheet = client.open_by_url(
            url="https://docs.google.com/spreadsheets/d/1q1e9GCgaUc-LbhQWHEVjKkl0275hkfDVq0rHgQLrF-E/edit?usp=sharing"
        )
        print("Logged in to Google Sheets successfully.")

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

        except gspread.exceptions.WorksheetNotFound:
            raise Exception(
                f"The tab {sheet_tab_name} does not exist in the google sheet."
            )

        original_sheet.update(
            range_name=range_name,
            values=data,
        )

        print(f"Sheet '{sheet_tab_name}' updated successfully!")

    @measure_time
    def copy_doorsplits_to_sheet(self, doorsplits: DataFrame) -> None:
        self._update_sheet(
            sheet_tab_name="Doors",
            data=doorsplits.values.tolist(),
            range_name="B3",
            make_copy=True,
        )

    @measure_time
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

    @measure_time
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

    @measure_time
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

    @measure_time
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

    @measure_time
    def copy_general_stats_to_sheet(
        self,
        general_stats: DataFrame,
    ) -> None:
        self._update_sheet(
            sheet_tab_name="General",
            data=general_stats.values.tolist(),
            range_name="B3",
        )

    @measure_time
    def copy_resets_to_sheet(
        self,
        resets: DataFrame,
    ) -> None:
        self._update_sheet(
            sheet_tab_name="Resets",
            data=resets.values.tolist(),
            range_name="A3",
        )

    @measure_time
    def copy_weekday_data_to_sheet(
        self,
        weekday_data: DataFrame,
    ) -> None:
        self._update_sheet(
            sheet_tab_name="Weekday",
            data=weekday_data.values.tolist(),
            range_name="C2",
        )

    @measure_time
    def copy_graphs_to_sheet(
        self,
        url_village_graph: str,
        url_castle_graph: str,
        url_island_graph: str,
    ) -> None:
        try:
            sheet = self._spreadsheet.worksheet(title="Resets graphs")
            sheet.update_acell("A1", f'=IMAGE("{url_village_graph}")')
            sheet.update_acell("A2", f'=IMAGE("{url_castle_graph}")')
            sheet.update_acell("A3", f'=IMAGE("{url_island_graph}")')
        except gspread.exceptions.WorksheetNotFound:
            raise Exception(
                'The tab "Resets graphs" does not exist in the google sheet.'
            )

    @measure_time
    def post_last_update(self) -> None:
        try:
            sheet = self._spreadsheet.worksheet(title="Title")
            sheet.update_acell(
                "A2",
                f"Last updated on: {datetime.now().strftime(Format.DATE_TIME_FORMAT.value)} (UTC-3)",
            )
        except gspread.exceptions.WorksheetNotFound:
            raise Exception("The tab 'Title' does not exist in the google sheet.")
