from google.oauth2.service_account import Credentials
import gspread
import pandas as pd
from pathlib import Path
import numpy as np
from decorators import measure_time
from typing import Any
from datetime import datetime


class RE4SheetManager:
    def __init__(self):
        self.sheet_url = "https://docs.google.com/spreadsheets/d/1q1e9GCgaUc-LbhQWHEVjKkl0275hkfDVq0rHgQLrF-E/edit?usp=sharing"
        self.credentials = Credentials.from_service_account_file(
            filename=Path(__file__).parent.parent
            / "credentials"
            / "service_account_secrets.json",
            scopes=[
                "https://www.googleapis.com/auth/spreadsheets",
                "https://www.googleapis.com/auth/drive",
            ],
        )
        client = gspread.authorize(credentials=self.credentials)
        self.spreadsheet = client.open_by_url(url=self.sheet_url)

    def _get_hours_minutes_str(self, seconds: str) -> str:
        try:
            seconds = int(seconds)
            hours = seconds // 3600
            remaining_seconds = seconds % 3600
            minutes = remaining_seconds // 60
        except Exception:
            return ""

        # Format hours string
        if hours == 0:
            hours_str = ""
        elif hours == 1:
            hours_str = "1 hr"
        else:
            hours_str = f"{hours} hs"

        # Format minutes string
        if minutes == 0:
            minutes_str = ""
        elif minutes == 1:
            minutes_str = "1 min"
        else:
            minutes_str = f"{minutes} mins"

        # Combine hours and minutes
        if hours_str and minutes_str:
            return f"{hours_str} and {minutes_str}"
        elif hours_str:
            return hours_str
        elif minutes_str:
            return minutes_str
        else:
            return "0 mins"

    def _get_days_hours_str(self, seconds: str) -> str:
        try:
            seconds = int(seconds)
            days = seconds // 86400
            remaining_seconds = seconds % 86400
            hours = remaining_seconds // 3600
        except Exception:
            return ""

        if days == 0:
            days_str = ""
        elif days == 1:
            days_str = "1 day"
        else:
            days_str = f"{days} days"

        if hours == 0:
            hours_str = ""
        elif hours == 1:
            hours_str = "1 hour"
        else:
            hours_str = f"{hours} hours"

        if days_str and hours_str:
            return f"{days_str} and {hours_str}"
        elif days_str:
            return days_str
        elif hours_str:
            return hours_str
        else:
            return "0 hours"

    def copy_excel_to_sheet(
        self,
        sheet_tab_name: str,
        data: list[list[Any]],
        range_name: str,
        make_copy: bool,
    ) -> None:
        try:
            original_sheet = self.spreadsheet.worksheet(title=sheet_tab_name)

            if make_copy:
                old_sheet_tab_name = f"{sheet_tab_name} old"
                old_sheet = self.spreadsheet.worksheet(title=old_sheet_tab_name)
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
    def copy_doorsplits_to_sheet(self, doorsplits: Path) -> None:
        SHEET_TAB_NAME = "Doors"
        excel = pd.read_excel(
            doorsplits,
            usecols=range(1, 8),
        )
        excel = excel.replace({np.nan: ""})
        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            data=excel.values.tolist(),
            range_name="B3",
            make_copy=True,
        )

    @measure_time
    def copy_chapters_to_sheet(self, chapters: Path, chapters_by_doors: Path) -> None:
        SHEET_TAB_NAME = "Chapters"
        excel1 = pd.read_excel(
            chapters,
            usecols=range(1, 10),
        )
        excel1 = excel1.replace({np.nan: ""})
        excel2 = pd.read_excel(chapters_by_doors, usecols=range(1, 10))
        excel2 = excel2.replace({np.nan: ""})
        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            data=excel1.values.tolist(),
            range_name="B3",
            make_copy=True,
        )
        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            data=excel2.values.tolist(),
            range_name="B25",
            make_copy=True,
        )

    @measure_time
    def copy_sections_to_sheet(
        self,
        sections: Path,
        sections_by_chapters: Path,
        sections_by_doors: Path,
    ) -> None:
        SHEET_TAB_NAME = "Sections"
        excel1 = pd.read_excel(sections, usecols=range(1, 10))
        excel1 = excel1.replace({np.nan: ""})
        excel2 = pd.read_excel(sections_by_chapters, usecols=range(1, 10))
        excel2 = excel2.replace({np.nan: ""})
        excel3 = pd.read_excel(sections_by_doors, usecols=range(1, 10))
        excel3 = excel3.replace({np.nan: ""})
        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            data=excel1.values.tolist(),
            range_name="B3",
            make_copy=True,
        )
        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            data=excel2.values.tolist(),
            range_name="B9",
            make_copy=True,
        )
        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            data=excel3.values.tolist(),
            range_name="B15",
            make_copy=True,
        )

    @measure_time
    def copy_paces_to_sheet(
        self,
        paces: Path,
    ) -> None:
        SHEET_TAB_NAME = "Paces"
        excel = pd.read_excel(paces, usecols=range(1, 9))
        excel = excel.replace({np.nan: ""})
        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            data=excel.values.tolist(),
            range_name="B3",
            make_copy=True,
        )

    @measure_time
    def copy_rng_patterns_to_sheet(
        self,
        rng_patterns: Path,
    ) -> None:
        SHEET_TAB_NAME = "RNG Patterns"
        excel = pd.read_excel(rng_patterns, usecols=range(1, 15))
        excel = excel.replace({np.nan: ""})
        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            data=excel.values.tolist(),
            range_name="B4",
            make_copy=True,
        )

    @measure_time
    def copy_general_stats_to_sheet(
        self,
        general_stats: Path,
    ) -> None:
        SHEET_TAB_NAME = "General"
        excel = pd.read_excel(general_stats, usecols=range(1, 8))
        excel = excel.replace({np.nan: ""})
        data = excel.values.tolist()
        input_format = "%Y-%m-%d"
        output_format = "%d/%m/%Y"
        dates_formatted = list(
            map(
                lambda date_str: datetime.strptime(date_str, input_format).strftime(
                    output_format
                ),
                data[0],
            )
        )
        data[0] = dates_formatted

        playtime_formatted = list(
            map(lambda playtime: self._get_days_hours_str((playtime)), data[3]),
        )
        data[3] = playtime_formatted

        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME, data=data, range_name="B3", make_copy=False
        )

    @measure_time
    def copy_resets_to_sheet(
        self,
        resets: Path,
    ) -> None:
        SHEET_TAB_NAME = "Resets"
        excel = pd.read_excel(resets, usecols=range(1, 8))
        excel = excel.replace({np.nan: ""})

        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            data=excel.values.tolist(),
            range_name="B3",
            make_copy=False,
        )

    @measure_time
    def copy_weekday_data_to_sheet(
        self,
        weekday_data: Path,
    ) -> None:
        SHEET_TAB_NAME = "Weekday"
        excel = pd.read_excel(weekday_data, usecols=range(2, 9))
        excel = excel.replace({np.nan: ""})
        data = excel.values.tolist()

        ranges_to_process = [
            range(7, 14),
            range(21, 28),
            range(35, 42),
            range(49, 56),
            range(63, 70),
        ]

        for r in ranges_to_process:
            for i in r:
                data[i] = list(
                    map(lambda playtime: self._get_hours_minutes_str(playtime), data[i])
                )

        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            data=data,
            range_name="C2",
            make_copy=False,
        )

    @measure_time
    def copy_graphs_to_sheet(
        self,
        url_village_graph: str,
        url_castle_graph: str,
        url_island_graph: str,
    ) -> None:
        SHEET_TAB_NAME = "Resets graphs"
        try:
            sheet = self.spreadsheet.worksheet(title=SHEET_TAB_NAME)
            sheet.update_acell("A1", f'=IMAGE("{url_village_graph}")')
            sheet.update_acell("A2", f'=IMAGE("{url_castle_graph}")')
            sheet.update_acell("A3", f'=IMAGE("{url_island_graph}")')
        except gspread.exceptions.WorksheetNotFound:
            raise Exception(
                f"The tab {SHEET_TAB_NAME} does not exist in the google sheet."
            )
