- [ ] **SQL scripts**:
  - Improve the performance of the main SQL script.
  - Shorten the main SQL script.
  - Improve the comments on both SQL scripts.
  - Make the config SQL customizable.
- [ ] **Make the project work for any game, any category, either one runner or multiple runners.**:
- [ ] **Have one DB with multiple schemas, one schema per game + category or one DB per game + runner, with just the public schema?**
- [ ] **Make a CLI, especially to query the DB**.
- [ ] **Fix and finish all docstrings**.
- [ ] **Write a proper and thorough README.md**.
- [ ] **Possibly remove outliers from the RNG pattern categorization calculation**.
- [ ] **Add pytest as a dependency and add tests along with test data (.lss files mostly)**.
- [ ] **Add automated formatting on the Google Sheet via the dependency gspread-formatting**:
- [ ] **SplitsFile class**:

  - Need to refactor it to make it cleaner and more understandable.
  - Add more methods to it to cover more functionality.
  - Can verify that all split files have the same split name structure as the main runners splits.
  - We can automatically generate the default split names based off of the main runner, checking what split names start with "-.." and which "{..."
  - We can obtain the chapter ranges automatically from the splits file itself (currently being calculated on SQL).

  - Example:

  ```py
  # Example code for gspread-formatting lib (uv add gspread-formatting)
  from pathlib import Path  # noqa: I001

  from gspread_formatting import (
      Color,
      ConditionalFormatRule,
      GridRange,
      GradientRule,
      get_conditional_format_rules,
      InterpolationPoint,
  )

  from auth.google_sheets_auth import GoogleSheetsAuth
  from sheet.sheet_manager import SheetManager

  service_account_secrets = Path(
      r"H:\Juan\3. Projects\Python\LiveSplit Analytics Database\config\service_account_secrets.json"
  )
  google_sheets_auth = GoogleSheetsAuth(service_account_secrets)
  sheet_manager = SheetManager(
      google_sheets_auth.auth(),
      google_sheet_id="1q1e9GCgaUc-LbhQWHEVjKkl0275hkfDVq0rHgQLrF-E",
  )

  test_tab = sheet_manager._spreadsheet.worksheet(title="test")
  # rules = get_conditional_format_rules(test_tab).rules


  BEST_VALUE_COLOR = Color(red=0.34117648, green=0.73333335, blue=0.5411765)
  MID_VALUE_COLOR = Color(red=1, green=0.8392157, blue=0.4)
  WORST_VALUE_COLOR = Color(red=0.9019608, green=0.4862745, blue=0.4509804)


  rules = get_conditional_format_rules(test_tab)
  rules.clear()

  rule = ConditionalFormatRule(
      ranges=[GridRange.from_a1_range("A10:K10", test_tab)],
      gradientRule=GradientRule(
          minpoint=InterpolationPoint(
              color=BEST_VALUE_COLOR,
              type="MIN",
          ),
          midpoint=InterpolationPoint(
              color=MID_VALUE_COLOR,
              type="PERCENTILE",
              value="50",
          ),
          maxpoint=InterpolationPoint(
              color=WORST_VALUE_COLOR,
              type="MAX",
          ),
      ),
  )

  rules.append(rule)
  rules.save()
  ```

- [ ] **Description for the repo**: Data Analysis / Data Engineering project related to speedrunning and more specifically to LiveSplit files (.lss).
