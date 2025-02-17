from google.oauth2.service_account import Credentials
import gspread
import pandas as pd
from pathlib import Path
import numpy as np
from pandas import DataFrame
from decorators import measure_time


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

    def _get_days_hours_str(self, seconds: int) -> str:
        days = seconds // 86400
        remaining_seconds = seconds % 86400
        hours = remaining_seconds // 3600

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
        self, sheet_tab_name: str, excel: DataFrame, range_name: str
    ) -> None:
        old_sheet_tab_name = f"{sheet_tab_name} old"
        excel = excel.replace({np.nan: ""})
        excel.columns = excel.columns.str.capitalize()
        excel.columns = excel.columns.str.replace("_", " ")

        try:
            original_sheet = self.spreadsheet.worksheet(title=sheet_tab_name)
            if sheet_tab_name != "General" and sheet_tab_name != "Resets":
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
            values=[excel.columns.values.tolist()] + excel.values.tolist(),
        )

        print(f"Sheet '{sheet_tab_name}' updated successfully!")

    @measure_time
    def copy_doorsplits_to_sheet(self, doorsplits: Path) -> None:
        SHEET_TAB_NAME = "Doors"
        excel = pd.read_excel(doorsplits, sheet_name="Sheet1")
        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            excel=excel,
            range_name="A2",
        )

    @measure_time
    def copy_chapters_to_sheet(self, chapters: Path, chapters_by_doors: Path) -> None:
        SHEET_TAB_NAME = "Chapters"
        excel1 = pd.read_excel(chapters, sheet_name="Sheet1")
        excel2 = pd.read_excel(chapters_by_doors, sheet_name="Sheet1")
        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            excel=excel1,
            range_name="A2",
        )
        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            excel=excel2,
            range_name="A24",
        )

    @measure_time
    def copy_sections_to_sheet(
        self,
        sections: Path,
        sections_by_chapters: Path,
        sections_by_doors: Path,
    ) -> None:
        SHEET_TAB_NAME = "Sections"
        excel1 = pd.read_excel(sections, sheet_name="Sheet1")
        excel2 = pd.read_excel(sections_by_chapters, sheet_name="Sheet1")
        excel3 = pd.read_excel(sections_by_doors, sheet_name="Sheet1")
        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            excel=excel1,
            range_name="A2",
        )
        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            excel=excel2,
            range_name="A8",
        )
        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            excel=excel3,
            range_name="A14",
        )

    @measure_time
    def copy_paces_to_sheet(
        self,
        paces: Path,
    ) -> None:
        SHEET_TAB_NAME = "Paces"
        excel = pd.read_excel(paces, sheet_name="Sheet1")
        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            excel=excel,
            range_name="A2",
        )

    @measure_time
    def copy_rng_patterns_to_sheet(
        self,
        rng_patterns: Path,
    ) -> None:
        SHEET_TAB_NAME = "RNG Patterns"
        excel = pd.read_excel(rng_patterns, sheet_name="Sheet1")
        excel.columns = excel.columns.str.replace("max_in_a_row", "")
        excel.columns = excel.columns.str.replace("percent", "")

        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            excel=excel,
            range_name="A3",
        )

    @measure_time
    def copy_general_stats_to_sheet(
        self,
        general_stats: Path,
    ) -> None:
        SHEET_TAB_NAME = "General"
        excel = pd.read_excel(general_stats, sheet_name="Sheet1")
        dates_row = excel.iloc[0]

        for i, date_str in enumerate(dates_row[1:], start=1):
            try:
                date_obj = pd.to_datetime(date_str, errors="coerce", format="%Y-%m-%d")
                if pd.isna(date_obj):  # Check if the conversion failed
                    raise ValueError(f"Invalid date format: {date_str}")
                excel.iloc[0, i] = date_obj.strftime("%d/%m/%Y")
            except ValueError:
                print(f"Invalid date format: {date_str}")

        total_playtime_row = excel.iloc[3]

        for i, seconds in enumerate(total_playtime_row[1:]):
            try:
                days_hours_str = self._get_days_hours_str(int(seconds))
                excel.iloc[3, i + 1] = days_hours_str
            except ValueError:
                print(f"Invalid total playtime format: {seconds}")

        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            excel=excel,
            range_name="A2",
        )

    @measure_time
    def copy_resets_to_sheet(
        self,
        resets: Path,
    ) -> None:
        SHEET_TAB_NAME = "Resets"
        excel = pd.read_excel(resets, sheet_name="Sheet1")
        excel.columns = excel.columns.str.replace("percent", "")

        self.copy_excel_to_sheet(
            sheet_tab_name=SHEET_TAB_NAME,
            excel=excel,
            range_name="A2",
        )

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
