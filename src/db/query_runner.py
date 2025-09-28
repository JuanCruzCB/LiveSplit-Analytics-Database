from enum import StrEnum
from pathlib import Path

import numpy as np
import pandas as pd
from pandas import DataFrame

from db.database_manager import DatabaseManager
from db.query_builder import QueryBuilder
from db.utils import (
    add_best_and_cumulative_best_cols,
    transform_days_hours_mins_secs,
    transform_interval_to_hours_mins,
)
from splits.splits_file import SplitsFile

type OptionalParams = dict[str, str | int] | None


class OrderColumns(StrEnum):
    RUN_ID = "run_id"
    SPLIT_INDEX = "split_index"
    LRT_TIME = "lrt_time"
    RUN_STARTED_AT = "run_started_at"


class OrderType(StrEnum):
    ASCENDING = ""
    DESCENDING = "DESC"


class QueryRunner:
    GOOD_DATE_FORMAT = "%d/%m/%Y"
    GOOD_DATETIME_FORMAT = "%d/%m/%Y %H:%M:%S UTC"

    def __init__(
        self,
        db_manager: DatabaseManager,
        query_builder: QueryBuilder,
        allowed_runners: list[str],
        main_runner_name: str,
    ) -> None:
        self._db = db_manager
        self._query_builder = query_builder
        self._allowed_runners = allowed_runners
        self._main_runner = main_runner_name
        self._output_dir = Path(__file__).parent.parent.parent / "output"
        self._output_dir.mkdir(exist_ok=True)

    """
    MAIN QUERIES
    """

    def open_db_connection(self) -> None:
        """
        Open the connection to the local postgres db.
        """
        self._db.open_connection()

    def close_db_connection(self) -> None:
        """
        Close the connection to the local postgres db.
        """
        self._db.close_connection()

    def create_config_tables(self) -> None:
        """
        Create the configuration tables in the DB.

        - Default split names.
        - Delimiting where each chapter and area starts and ends.
        - Defining how many splits each area has.
        - Defining the RNG pattern categorization.
        - Creating all the dates from 2000-01-01 to 2030-12-31.
        """
        self._db.create_config_tables()

    def update_runners_tables(self, splits_files: list[SplitsFile]) -> bool:
        """
        Update the runner/s tables in the DB by running the splits database
        builder SQL script once for each splits file in the dict.
        """
        return self._db.update_runners_tables(splits_files=splits_files)

    def _build_combined_data(
        self,
        column_header_queries: list[str],
        data_queries: list[str],
        *,
        best_col: bool,
        sum_of_best_col: bool,
    ) -> DataFrame:
        """
        Returns a DataFrame that combines all the resulting DataFrames obtained
        by running all the specified queries, left to right.

        Optionally, it can add a "Best" column and a
        "Cumulative best" column at the end.
        """
        dfs = []
        for header_query in column_header_queries:
            if header_query != "":
                header_column = self.execute(query=header_query)
                header_column.columns = header_column.columns.str.replace("_", " ")
                header_column.columns = header_column.columns.str.title()
                dfs.append(header_column)

        for data_query in data_queries:
            for runner in self._allowed_runners:
                runner_data = self.execute(query=data_query.format(runner=runner))
                dfs.append(runner_data)

        combined_df = pd.concat(dfs, axis=1)

        if not best_col and sum_of_best_col:
            msg = (
                "Cannot add a cumulative best column "
                "without adding a best column first."
            )
            raise ValueError(msg)

        if best_col and not sum_of_best_col:
            combined_df = add_best_and_cumulative_best_cols(combined_df)
            combined_df = combined_df.drop(columns=["Cumulative best"])
        elif best_col and sum_of_best_col:
            combined_df = add_best_and_cumulative_best_cols(combined_df)

        combined_df.columns = combined_df.columns.str.replace("_", " ")
        combined_df.columns = combined_df.columns.str.title()
        return combined_df

    def get_runners_doorsplit_golds(
        self,
        *,
        split_names_col: bool,
        best_col: bool,
        sum_of_best_col: bool,
    ) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the doorsplit golds of that runner.
        The last row contains the doorsplits sum of best of that runner.
        """
        return self._build_combined_data(
            column_header_queries=[
                self._query_builder.DOORSPLIT_NAMES_QUERY_WITH_TOTAL
                if split_names_col
                else "",
            ],
            data_queries=[self._query_builder.doorsplit_golds_minimal()],
            best_col=best_col,
            sum_of_best_col=sum_of_best_col,
        )

    def get_runners_chapter_golds(
        self,
        *,
        chapter_names_col: bool,
        best_col: bool,
        sum_of_best_col: bool,
    ) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the chapter golds of that runner.
        The last row contains the chapter sum of best of that runner.

        The very first column that shows the chapter names, is optional.

        In addition, there's a column with the best chapter gold for each
        chapter, and a column with the cumulative best chapters.
        """
        return self._build_combined_data(
            column_header_queries=[
                self._query_builder.CHAPTER_NAMES_QUERY_WITH_TOTAL
                if chapter_names_col
                else "",
            ],
            data_queries=[self._query_builder.chapter_golds_minimal()],
            best_col=best_col,
            sum_of_best_col=sum_of_best_col,
        )

    def get_runners_chapter_golds_by_doors(
        self,
        *,
        chapter_names_col: bool,
        best_col: bool,
        sum_of_best_col: bool,
    ) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the chapter golds by adding up all
        the doorsplit golds of that chapter of that runner.
        The last row contains the doorsplits sum of best of that runner.

        In addition, there's a column with the best chapter gold for each
        chapter, and a column with the cumulative best chapters.
        """
        return self._build_combined_data(
            column_header_queries=[
                self._query_builder.CHAPTER_NAMES_QUERY_WITH_TOTAL
                if chapter_names_col
                else "",
            ],
            data_queries=[self._query_builder.chapter_golds_by_doors_minimal()],
            best_col=best_col,
            sum_of_best_col=sum_of_best_col,
        )

    def get_runners_area_golds(
        self,
        *,
        area_names_col: bool,
        best_col: bool,
        sum_of_best_col: bool,
    ) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the area golds of that runner.
        The last row contains the area sum of best of that runner.

        In addition, there's a column with the best area gold for each
        area, and a column with the cumulative best areas.
        """
        return self._build_combined_data(
            column_header_queries=[
                self._query_builder.AREA_NAMES_QUERY if area_names_col else "",
            ],
            data_queries=[self._query_builder.area_golds_minimal()],
            best_col=best_col,
            sum_of_best_col=sum_of_best_col,
        )

    def get_runners_area_golds_by_chapters(
        self,
        *,
        area_names_col: bool,
        best_col: bool,
        sum_of_best_col: bool,
    ) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the area golds by adding up all
        the chapter golds of that area of that runner.
        The last row contains the chapter sum of best of that runner.

        In addition, there's a column with the best area gold for each
        area, and a column with the cumulative best areas.
        """
        return self._build_combined_data(
            column_header_queries=[
                self._query_builder.AREA_NAMES_QUERY if area_names_col else "",
            ],
            data_queries=[self._query_builder.area_golds_by_chapters_minimal()],
            best_col=best_col,
            sum_of_best_col=sum_of_best_col,
        )

    def get_runners_area_golds_by_doors(
        self,
        *,
        area_names_col: bool,
        best_col: bool,
        sum_of_best_col: bool,
    ) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the area golds by adding up all
        the doorsplit golds of that area of that runner.
        The last row contains the doorsplits sum of best of that runner.

        In addition, there's a column with the best area gold for each
        area, and a column with the cumulative best areas.
        """
        return self._build_combined_data(
            column_header_queries=[
                self._query_builder.AREA_NAMES_QUERY if area_names_col else "",
            ],
            data_queries=[self._query_builder.area_golds_by_doors_minimal()],
            best_col=best_col,
            sum_of_best_col=sum_of_best_col,
        )

    def get_runners_best_paces(
        self,
        *,
        chapter_names_col: bool,
        best_col: bool,
    ) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the best paces of that runner per chapter.

        In addition, there's a column with the overall best pace for each
        chapter.
        """
        return self._build_combined_data(
            column_header_queries=[
                self._query_builder.CHAPTER_NAMES_QUERY if chapter_names_col else "",
            ],
            data_queries=[self._query_builder.best_paces_minimal()],
            best_col=best_col,
            sum_of_best_col=False,
        )

    def get_runners_rng_patterns(self, *, pattern_names_col: bool) -> DataFrame:
        """
        Returns a DataFrame that contains, for each runner, the
        percentage of different RNG patterns that runner has gotten overall
        and also the maximum amount of times in a row they've gotten each pattern
        subtype within each pattern.
        """
        data = self._build_combined_data(
            column_header_queries=[
                self._query_builder.PATTERN_NAMES_QUERY if pattern_names_col else "",
            ],
            data_queries=[
                self._query_builder.rng_patterns_percentages_minimal(),
                self._query_builder.rng_patterns_max_in_a_row_minimal(),
            ],
            best_col=False,
            sum_of_best_col=False,
        )
        numeric_cols = data.select_dtypes(include=np.number).columns
        data[numeric_cols] = (
            data[numeric_cols]
            .astype(float)
            .round(2)
            .clip(lower=0)  # More efficient way to set minimum value to 0
        )
        return data

    def get_runners_general_stats(self, *, stat_names_col: bool) -> DataFrame:
        """
        Returns a DataFrame with simple stats for each runner:
        1) The last time they've updated their splits (as in, ran the game).
        2) Their PB.
        3) Their total number of attempts.
        4) Their total playtime, in days and hours.
        """
        dfs = []

        if stat_names_col:
            dfs.append(
                pd.DataFrame(
                    {"Stat": ["Last update", "PB", "Attempts", "Total playtime"]},
                ),
            )

        for runner in self._allowed_runners:
            runner_stats = self.execute(
                query=self._query_builder.general_stats(runner=runner),
            )
            runner_stats["last_update"] = pd.to_datetime(
                runner_stats["last_update"],
            ).dt.strftime(self.GOOD_DATE_FORMAT)
            runner_stats["total_playtime"] = runner_stats["total_playtime"].apply(
                lambda x: transform_days_hours_mins_secs(x),
            )

            runner_stats_transposed = runner_stats.transpose()
            runner_stats = pd.DataFrame({runner: runner_stats_transposed[0].to_list()})
            dfs.append(runner_stats)

        overall_df = pd.concat(dfs, axis=1)
        overall_df.columns = overall_df.columns.str.capitalize()
        return overall_df

    def get_runners_resets(self, *, split_names_col: bool) -> DataFrame:
        """
        Returns a DataFrame with the percentage of resets for each runner, for
        all doorsplits. As in, what percentage of the runs that get to that split
        end up with the runner resetting on that split.
        """
        data = self._build_combined_data(
            column_header_queries=[
                self._query_builder.DOORSPLIT_NAMES_QUERY if split_names_col else "",
            ],
            data_queries=[self._query_builder.resets_minimal()],
            best_col=False,
            sum_of_best_col=False,
        )
        skip_cols = 1 if split_names_col else 0
        numeric_cols = data.columns[skip_cols:]
        data[numeric_cols] = data[numeric_cols].astype(float).round(2).clip(lower=0)
        return data

    def get_runners_weekday_data(self, *, weekday_stat_cols: bool) -> DataFrame:
        """
        Returns a DataFrame with many different stats related to how
        each runner performs on the seven days of the week.
        """
        dfs = []

        if weekday_stat_cols:
            weekdays = [
                "Monday",
                "Tuesday",
                "Wednesday",
                "Thursday",
                "Friday",
                "Saturday",
                "Sunday",
            ]
            stat_types = [
                "Attempts to get a PB",
                "Playtime to get a PB",
                "Attempts to get a gold",
                "Playtime to get a gold",
                "Attempts to get a chapter gold",
                "Playtime to get a chapter gold",
                "Attempts to get an area gold",
                "Playtime to get an area gold",
                "Attempts to get a best pace",
                "Playtime to get a best pace",
            ]
            repeated_stats = []
            for stat in stat_types:
                repeated_stats.extend([stat] * 7)

            dfs.append(
                DataFrame(
                    {
                        "Day": weekdays * len(stat_types),
                        "Stat type": repeated_stats,
                    },
                ),
            )

        for runner in self._allowed_runners:
            runner_weekday = self.execute(
                query=self._query_builder.weekday_data(runner=runner),
            )
            runner_weekday[runner] = runner_weekday[runner].apply(
                lambda x: transform_interval_to_hours_mins(x),
            )
            dfs.append(runner_weekday)

        overall_df = pd.concat(dfs, axis=1)
        overall_df.columns = overall_df.columns.str.capitalize()
        return overall_df

    """
    SECONDARY QUERIES
    """

    def execute(
        self,
        query: str,
        params: OptionalParams = None,
        excel_name: str = "",
    ) -> DataFrame:
        """
        Returns a DataFrame with the result data of executing the specified query on the
        DB.

        The query can include params, optionally.

        The result data can be exported to an excel file, optionally.
        """
        data = self._db.execute(query=query, params=params)
        datetime_cols = data.select_dtypes(
            include=["datetime64", "datetimetz"],
        ).columns.tolist()
        for col in datetime_cols:
            data[col] = data[col].apply(
                lambda x: pd.to_datetime(x, errors="coerce").strftime(
                    self.GOOD_DATETIME_FORMAT,
                )
                if pd.notna(x)
                else None,
            )

        if excel_name:
            data.to_excel(self._output_dir / f"{excel_name}.xlsx", index=False)
        return data

    def drop_staging_tables(self) -> None:
        """
        Drops all tables from the DB that are staging tables, meaning they start
        with 'stg'.
        """
        for table in self.export_table_names():
            if "stg" in table:
                self.execute(query=f"DROP TABLE {table};")

    def export_table_names(self) -> list[str]:
        """
        Exports the names of all tables in the DB to a .txt file, one table
        per line.

        Also returns this list of tables.
        """
        tables_df = self.execute(query=self._query_builder.TABLE_NAMES_QUERY)
        tables = tables_df["table_name"].to_list()
        with Path(self._output_dir / "tables.txt").open("w") as f:
            f.write("\n".join(tables))

        return tables

    def doorsplit_golds(self, *, ties: bool = False) -> DataFrame:
        """
        Returns a DataFrame with all the doorsplit golds of the runner.

        Can include tied doorsplit golds or not.
        """
        if ties:
            extra_condition = ""
            excel_name = f"{self._main_runner}_doorsplit_golds_with_ties"
        else:
            extra_condition = "WHERE lrt_time_instance = 1"
            excel_name = f"{self._main_runner}_doorsplit_golds_without_ties"
        return self.execute(
            query=self._query_builder.doorsplit_golds(
                runner=self._main_runner,
                extra_condition=extra_condition,
            ),
            excel_name=excel_name,
        )

    def chapter_golds(self, *, ties: bool = False) -> DataFrame:
        """
        Returns a DataFrame with all the chapter golds of the runner.

        Can include tied chapter golds or not.
        """
        if ties:
            extra_condition = ""
            excel_name = f"{self._main_runner}_chapter_golds_with_ties"
        else:
            extra_condition = "WHERE chapter_time_instance = 1"
            excel_name = f"{self._main_runner}_chapter_golds_without_ties"

        return self.execute(
            query=self._query_builder.chapter_golds(
                runner=self._main_runner,
                extra_condition=extra_condition,
            ),
            excel_name=excel_name,
        )

    def area_golds(self, *, ties: bool = False) -> DataFrame:
        """
        Returns a DataFrame with all the area golds of the runner.

        Can include tied area golds or not.
        """
        if ties:
            extra_condition = ""
            excel_name = f"{self._main_runner}_area_golds_with_ties"
        else:
            extra_condition = "WHERE area_time_instance = 1"
            excel_name = f"{self._main_runner}_area_golds_without_ties"

        return self.execute(
            query=self._query_builder.area_golds(
                runner=self._main_runner,
                extra_condition=extra_condition,
            ),
            excel_name=excel_name,
        )

    def pb_summary(self) -> DataFrame:
        """
        Returns a DataFrame with summary data of the runner's PB (personal best),
        doorsplit by doorsplit, useful to provide a sense of where the run went
        well and where it didn't.
        """
        # TODO: There's a mistake on the splits_overview table, doorsplit 77
        # is duplicated for whatever reason.
        return self.execute(
            query=self._query_builder.pb_summary(runner=self._main_runner),
            excel_name=f"{self._main_runner}_pb_summary",
        )

    def doorsplits_of_chapter_golds(self, chapter: str = "") -> DataFrame:
        """
        Get all doorsplits that make up each chapter gold of the runner.

        Optionally, provide a specific chapter to only check that one.
        """
        if chapter:
            extra_condition = f"AND CHAPTER = '{chapter}'"
            chapter = chapter.replace("-", "_")
            excel_name = f"{self._main_runner}_chapter_gold_{chapter}_components"
        else:
            extra_condition = ""
            excel_name = f"{self._main_runner}_chapter_golds_components"

        return self.execute(
            query=self._query_builder.doorsplits_of_chapter_golds(
                runner=self._main_runner,
                extra_condition=extra_condition,
            ),
            excel_name=excel_name,
        )

    def doorsplit_history(
        self,
        split_name: str,
        order_by: OrderColumns = OrderColumns.LRT_TIME,
        order_type: OrderType = OrderType.DESCENDING,
    ) -> DataFrame:
        """
        Returns a DataFrame with the entire history of a specific doorsplit, which
        are all the times ever obtained on that split.

        These times are ordered by their time value descending by default, but
        can be ordered by a different attribute, optionally.
        """
        if "{" not in split_name:
            split_name = f"-{split_name}"
        split_name_formatted = (
            split_name.replace("{", "").replace("}", "").replace("-", "")
        )
        excel_name = f"{self._main_runner}_{split_name_formatted}_history"
        return self.execute(
            query=self._query_builder.doorsplit_history(
                runner=self._main_runner,
                order_by=order_by,
                order_type=order_type,
            ),
            params={"split_name": split_name},
            excel_name=excel_name,
        )

    def compare_runners_doorsplit_golds(self, other_runner: str) -> DataFrame:
        """
        Returns a DataFrame with all doorsplit golds of the main runner and another
        runner, as well as the difference between these golds, for each split.
        """
        return self.execute(
            query=self._query_builder.compare_runners_doorsplit_golds(
                runner1=self._main_runner,
                runner2=other_runner,
            ),
            excel_name=f"ds_golds_{self._main_runner}_vs_{other_runner}",
        )

    def compare_runners_doorsplit_medians(self, other_runner: str) -> DataFrame:
        """
        Returns a DataFrame with all doorsplit medians of the main runner and another
        runner, as well as the difference between these medians, for each split.
        """
        return self.execute(
            query=self._query_builder.compare_runners_doorsplit_medians(
                runner1=self._main_runner,
                runner2=other_runner,
            ),
            excel_name=f"ds_medians_{self._main_runner}_vs_{other_runner}",
        )

    def attempts_per_day(self) -> DataFrame:
        """
        Returns a DataFrame with the number of attempts the runner has
        ever done for each unique day that they've done attempts for
        in their history.
        """
        return self.execute(
            query=self._query_builder.attempts_per_day(runner=self._main_runner),
            excel_name=f"attempts_per_day_{self._main_runner}",
        )

    def attempts_per_day_of_the_week(self) -> DataFrame:
        """
        Returns a DataFrame with the number of attempts the runner has
        ever done for each unique day of the week.
        """
        return self.execute(
            query=self._query_builder.attempts_per_day_of_the_week(
                runner=self._main_runner,
            ),
            excel_name=f"attempts_per_day_of_the_week_{self._main_runner}",
        )

    def attempts_per_week(self) -> DataFrame:
        """
        Returns a DataFrame with the number of attempts the runner has
        done for each week of the year.
        """
        return self.execute(
            query=self._query_builder.attempts_per_week(runner=self._main_runner),
            excel_name=f"attempts_per_week_{self._main_runner}",
        )
