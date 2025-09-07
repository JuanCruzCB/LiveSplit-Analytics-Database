from datetime import datetime
from decimal import Decimal
from enum import StrEnum
from pathlib import Path

import pandas as pd
from pandas import DataFrame

from db.database_manager import DatabaseManager
from db.utils import (
    add_best_and_cumulative_best_columns,
    calculate_best_time,
    transform_days_hours_mins_secs,
    transform_interval_to_hours_mins,
)

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
    DOORSPLIT_NAMES_QUERY = """
    SELECT split_name
    FROM cfg_default_split_names;
    """
    CHAPTER_NAMES_QUERY = """
    SELECT chapter
    FROM cfg_chapter_area_splits_from_to
    ORDER BY chapter;
    """
    AREA_NAMES_QUERY = """
    SELECT area
    FROM cfg_splits_per_area;
    """
    TABLE_NAMES_QUERY = """
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
    ORDER BY table_name;
    """
    PATTERN_NAMES_QUERY = """
    SELECT SUBSTRING(pattern_name, 3) AS pattern
    FROM cfg_rng_pattern_rules;
    """

    def __init__(
        self,
        db_manager: DatabaseManager,
        allowed_runners: list[str],
        main_runner_name: str,
    ):
        self._db = db_manager
        self._allowed_runners = allowed_runners
        self._main_runner = main_runner_name
        self._output_dir = Path(__file__).parent.parent.parent / "output"
        self._output_dir.mkdir(exist_ok=True)

    """
    MAIN QUERIES
    """

    def open_db_connection(self) -> None:
        self._db.open_connection()

    def close_db_connection(self) -> None:
        self._db.close_connection()

    def create_config_tables(self) -> None:
        self._db.create_config_tables()

    def update_runners_tables(self, splits: dict[Path, datetime]) -> bool:
        return self._db.update_runners_tables(splits=splits)

    def _get_golds(
        self,
        division_type_query: str,
        golds_query: str,
        *,
        add_best_and_cumulative: bool = True,
    ) -> DataFrame:
        dfs = []

        if division_type_query:
            division_names = self.execute(division_type_query)
            division_names.loc[len(division_names)] = "Total"
            dfs.append(division_names)

        for runner in self._allowed_runners:
            runner_golds = self.execute(golds_query.format(runner=runner))
            dfs.append(runner_golds)

        overall_df = pd.concat(dfs, axis=1)
        overall_df.columns = overall_df.columns.str.capitalize()
        if add_best_and_cumulative:
            overall_df = add_best_and_cumulative_best_columns(
                overall_df, skip_first_col=bool(division_type_query)
            )

        return overall_df

    def get_runners_doorsplit_golds(self, *, add_first_col: bool) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the doorsplit golds of that runner.
        The last row contains the doorsplits sum of best of that runner.
        """
        return self._get_golds(
            division_type_query=self.DOORSPLIT_NAMES_QUERY if add_first_col else "",
            golds_query="""
            SELECT
                lrt_time_fmt AS {runner}
            FROM
            (
                SELECT DISTINCT
                    split_index,
                    lrt_time_fmt
                FROM doorsplit_golds2_{runner}

                UNION

                SELECT
                    NULL,
                    LTRIM(TO_CHAR(MAX(sum_of_best), 'HH24:MI:SS.FF3'), '0:') AS lrt_time_fmt
                FROM doorsplit_golds2_{runner}
                ORDER BY split_index
            );
            """,
            add_best_and_cumulative=False,
        )

    def get_runners_chapter_golds(self, *, add_first_col: bool) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the chapter golds of that runner.
        The last row contains the chapter sum of best of that runner.

        The very first column that shows the chapter names, is optional.

        In addition, there's a column with the best chapter gold for each
        chapter, and a column with the cumulative best chapters.
        """
        return self._get_golds(
            division_type_query=self.CHAPTER_NAMES_QUERY if add_first_col else "",
            golds_query="""
            SELECT
                chapter_time_fmt AS {runner}
            FROM
            (
                SELECT DISTINCT
                    chapter,
                    chapter_time_fmt
                FROM chapter_golds2_{runner}

                UNION

                SELECT
                    NULL,
                    LTRIM(TO_CHAR(MAX(sum_of_best), 'HH24:MI:SS.FF3'), '0:') AS chapter_time_fmt
                FROM chapter_golds2_{runner}

                ORDER BY chapter
            );
            """,
        )

    def get_runners_chapter_golds_by_doors(self, *, add_first_col: bool) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the chapter golds by adding up all
        the doorsplit golds of that chapter of that runner.
        The last row contains the doorsplits sum of best of that runner.

        In addition, there's a column with the best chapter gold for each
        chapter, and a column with the cumulative best chapters.
        """
        return self._get_golds(
            division_type_query=self.CHAPTER_NAMES_QUERY if add_first_col else "",
            golds_query="""
            SELECT
                chapter_gold_by_doors_fmt AS {runner}
            FROM
            (
                SELECT DISTINCT
                    chapter,
                    chapter_gold_by_doors_fmt
                FROM chapter_golds_by_doors_{runner}

                UNION

                SELECT
                    NULL,
                    LTRIM(TO_CHAR(MAX(sum_of_best), 'HH24:MI:SS.FF3'), '0:') AS chapter_gold_by_doors_fmt
                FROM chapter_golds_by_doors_{runner}

                ORDER BY chapter
            );
            """,
        )

    def get_runners_area_golds(self, *, add_first_col: bool) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the area golds of that runner.
        The last row contains the area sum of best of that runner.

        In addition, there's a column with the best area gold for each
        area, and a column with the cumulative best areas.
        """
        return self._get_golds(
            division_type_query=self.AREA_NAMES_QUERY if add_first_col else "",
            golds_query="""
            SELECT
                area_time_fmt AS {runner}
            FROM
            (
                SELECT
                    area,
                    area_time_fmt,
                    sort
                FROM
                (
                    SELECT DISTINCT
                        ag.area,
                        area_time_fmt,
                        cfg.sort
                    FROM area_golds2_{runner} ag

                    LEFT JOIN cfg_splits_per_area cfg
                    ON ag.area = cfg.area
                ) a

                UNION

                SELECT
                    NULL,
                    LTRIM(TO_CHAR(MAX(sum_of_best), 'HH24:MI:SS.FF3'), '0:') AS area_time_fmt,
                    NULL
                FROM area_golds2_{runner}

                ORDER BY sort
            );
            """,
        )

    def get_runners_area_golds_by_chapters(self, *, add_first_col: bool) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the area golds by adding up all
        the chapter golds of that area of that runner.
        The last row contains the chapter sum of best of that runner.

        In addition, there's a column with the best area gold for each
        area, and a column with the cumulative best areas.
        """
        return self._get_golds(
            division_type_query=self.AREA_NAMES_QUERY if add_first_col else "",
            golds_query="""
            SELECT
                area_gold_by_chapters_fmt AS {runner}
            FROM
            (
                SELECT
                    area,
                    area_gold_by_chapters_fmt,
                    sort
                FROM
                (
                    SELECT DISTINCT
                        ag.area,
                        area_gold_by_chapters_fmt,
                        cfg.sort
                    FROM area_golds_by_chapters_{runner} ag

                    LEFT JOIN cfg_splits_per_area cfg
                    ON ag.area = cfg.area
                ) a

                UNION

                SELECT
                    NULL,
                    LTRIM(TO_CHAR(MAX(sum_of_best), 'HH24:MI:SS.FF3'), '0:') AS area_gold_by_chapters_fmt,
                    NULL
                FROM area_golds_by_chapters_{runner}

                ORDER BY sort
            );
            """,
        )

    def get_runners_area_golds_by_doors(self, *, add_first_col: bool) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the area golds by adding up all
        the doorsplit golds of that area of that runner.
        The last row contains the doorsplits sum of best of that runner.

        In addition, there's a column with the best area gold for each
        area, and a column with the cumulative best areas.
        """
        return self._get_golds(
            division_type_query=self.AREA_NAMES_QUERY if add_first_col else "",
            golds_query="""
            SELECT
                area_gold_by_doors_fmt AS {runner}
            FROM
            (
                SELECT
                    area,
                    area_gold_by_doors_fmt,
                    sort
                FROM
                (
                    SELECT DISTINCT
                        ag.area,
                        area_gold_by_doors_fmt,
                        cfg.sort
                    FROM area_golds_by_doors_{runner} ag

                    LEFT JOIN cfg_splits_per_area cfg
                    ON ag.area = cfg.area
                ) a

                UNION

                SELECT
                    NULL,
                    LTRIM(TO_CHAR(MAX(sum_of_best), 'HH24:MI:SS.FF3'), '0:') AS area_gold_by_doors_fmt,
                    NULL
                FROM area_golds_by_doors_{runner}

                ORDER BY sort
            );
            """,
        )

    def get_runners_best_paces(self, *, add_first_col: bool) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the best paces of that runner per chapter.

        In addition, there's a column with the overall best pace for each
        chapter.
        """
        dfs = []

        if add_first_col:
            chapter_names = self.execute(query=self.CHAPTER_NAMES_QUERY)
            dfs.append(chapter_names)

        for runner in self._allowed_runners:
            runners_best_paces = self.execute(
                query=f"""
                SELECT
                    lrt_pace_fmt AS {runner}
                FROM (
                    SELECT DISTINCT
                        split_index,
                        split_name,
                        lrt_pace_fmt
                    FROM paces_best_{runner}
                    WHERE split_name LIKE '%{{%'
                    ORDER BY split_index
                );
                """  # noqa: S608
            )
            dfs.append(runners_best_paces)

        overall_df = pd.concat(dfs, axis=1)
        if add_first_col:
            overall_df["Best"] = overall_df.apply(
                lambda row: calculate_best_time(row[1:]),
                axis=1,
            )
        else:
            overall_df["Best"] = overall_df.apply(
                lambda row: calculate_best_time(row),
                axis=1,
            )
        overall_df.columns = overall_df.columns.str.capitalize()
        return overall_df

    def get_runners_rng_patterns(self, *, add_first_col: bool) -> DataFrame:
        """
        Returns a DataFrame that contains, for each runner, the
        percentage of different RNG patterns that runner has gotten overall
        and also the maximum amount of times in a row they've gotten each pattern
        subtype within each pattern.
        """
        dfs = []

        if add_first_col:
            pattern_names = self.execute(query=self.PATTERN_NAMES_QUERY)
            dfs.append(pattern_names)

        for runner in self._allowed_runners:
            runners_percentages = self.execute(
                query=f"""
                SELECT pattern_percentage AS {runner}
                FROM rng_patterns_stats_{runner};
                """  # noqa: S608
            )
            dfs.append(runners_percentages)

        for runner in self._allowed_runners:
            runners_max_in_a_row = self.execute(
                query=f"""
                SELECT max_patterns_in_a_row AS {runner}
                FROM rng_patterns_stats_{runner};
                """  # noqa: S608
            )
            dfs.append(runners_max_in_a_row)

        overall_df = pd.concat(dfs, axis=1)
        overall_df = overall_df.map(lambda x: float(x) if isinstance(x, Decimal) else x)
        overall_df.columns = overall_df.columns.str.capitalize()
        return overall_df

    def get_runners_general_stats(self, *, add_first_col: bool) -> DataFrame:
        """
        Returns a DataFrame with simple stats for each runner:
        1) The last time they've updated their splits (as in, ran the game).
        2) Their PB.
        3) Their total number of attempts.
        4) Their total playtime, in days and hours.
        """
        dfs = []

        if add_first_col:
            dfs.append(
                pd.DataFrame(
                    {"Stat": ["Last update", "PB", "Attempts", "Total playtime"]}
                )
            )

        for runner in self._allowed_runners:
            runner_stats = self.execute(
                query=f"SELECT * FROM general_stats_{runner};"  # noqa: S608
            )
            runner_stats["last_update"] = pd.to_datetime(
                runner_stats["last_update"]
            ).dt.strftime(self.GOOD_DATE_FORMAT)
            runner_stats["total_playtime"] = runner_stats["total_playtime"].apply(
                lambda x: transform_days_hours_mins_secs(x)
            )

            runner_stats_transposed = runner_stats.transpose()
            runner_stats = pd.DataFrame({runner: runner_stats_transposed[0].to_list()})
            dfs.append(runner_stats)

        overall_df = pd.concat(dfs, axis=1)
        overall_df.columns = overall_df.columns.str.capitalize()
        return overall_df

    def get_runners_resets(self, *, add_first_col: bool) -> DataFrame:
        """
        Returns a DataFrame with the percentage of resets for each runner, for
        all doorsplits. As in, what percentage of the runs that get to that split
        end up with the runner resetting on that split.
        """
        dfs = []

        if add_first_col:
            split_names = self.execute(query=self.DOORSPLIT_NAMES_QUERY)
            dfs.append(split_names)

        for runner in self._allowed_runners:
            runner_resets = self.execute(
                query=f"""
                SELECT percentage_reset AS {runner}
                FROM resets2_{runner}
                """  # noqa: S608
            )
            runner_resets = runner_resets.map(lambda percent: max(percent, 0))
            dfs.append(runner_resets)

        overall_df = pd.concat(dfs, axis=1)
        overall_df.columns = overall_df.columns.str.capitalize()
        overall_df = overall_df.map(lambda x: float(x) if isinstance(x, Decimal) else x)
        return overall_df

    def get_runners_weekday_data(self, *, add_first_two_cols: bool) -> DataFrame:
        """
        Returns a DataFrame with many different stats related to how
        each runner performs on the seven days of the week.
        """
        dfs = []

        if add_first_two_cols:
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
                    }
                )
            )

        for runner in self._allowed_runners:
            runner_weekday = self.execute(
                query=f"""
                SELECT attempts_to_get_a_pb AS {runner}
                FROM (
                    SELECT iso_weekday, attempts_to_get_a_pb::TEXT, 1 AS sort_key
                    FROM weekday_stats_{runner}

                    UNION

                    SELECT iso_weekday, playtime_to_get_a_pb::TEXT, 2 AS sort_key
                    FROM weekday_stats_{runner}

                    UNION

                    SELECT iso_weekday, attempts_to_get_a_doorsplit_gold::TEXT, 3 AS sort_key
                    FROM weekday_stats_{runner}

                    UNION

                    SELECT iso_weekday, playtime_to_get_a_doorsplit_gold::TEXT, 4 AS sort_key
                    FROM weekday_stats_{runner}

                    UNION

                    SELECT iso_weekday, attempts_to_get_a_chapter_gold::TEXT, 5 AS sort_key
                    FROM weekday_stats_{runner}

                    UNION

                    SELECT iso_weekday, playtime_to_get_a_chapter_gold::TEXT, 6 AS sort_key
                    FROM weekday_stats_{runner}

                    UNION

                    SELECT iso_weekday, attempts_to_get_a_area_gold::TEXT, 7 AS sort_key
                    FROM weekday_stats_{runner}

                    UNION

                    SELECT iso_weekday, playtime_to_get_a_area_gold::TEXT, 8 AS sort_key
                    FROM weekday_stats_{runner}

                    UNION

                    SELECT iso_weekday, attempts_to_get_a_best_pace::TEXT, 9 AS sort_key
                    FROM weekday_stats_{runner}

                    UNION

                    SELECT iso_weekday, playtime_to_get_a_best_pace::TEXT, 10 AS sort_key
                    FROM weekday_stats_{runner}

                    ORDER BY sort_key, iso_weekday
                );
                """  # noqa: S608
            )
            runner_weekday[runner] = runner_weekday[runner].apply(
                lambda x: transform_interval_to_hours_mins(x)
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
        Returns a DataFrame with the result data of executing the specified query on the DB.

        The query can include params, optionally.

        The result data can be exported to an excel file, optionally.
        """
        data = self._db.execute(query=query, params=params)
        datetime_cols = data.select_dtypes(
            include=["datetime64", "datetimetz"]
        ).columns.tolist()
        for col in datetime_cols:
            data[col] = data[col].apply(
                lambda x: pd.to_datetime(x, errors="coerce").strftime(
                    self.GOOD_DATETIME_FORMAT
                )
                if pd.notna(x)
                else None
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
        tables_df = self.execute(query=self.TABLE_NAMES_QUERY)
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
            query=f"""
            SELECT
                run_id,
                split_index,
                split_name,
                lrt_time_fmt AS gold,
                split_started_at,
                split_ended_at,
                run_started_at,
                run_ended_at
            FROM doorsplit_golds2_{self._main_runner}
            {extra_condition};
            """,  # noqa: S608
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
            query=f"""
            SELECT
                run_id,
                chapter,
                chapter_time_fmt AS gold,
                chapter_started_at,
                chapter_ended_at,
                run_started_at,
                run_ended_at
            FROM chapter_golds2_{self._main_runner}
            {extra_condition};
            """,  # noqa: S608
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
            query=f"""
            SELECT
                run_id,
                area,
                area_time_fmt AS gold,
                area_started_at,
                area_ended_at,
                run_started_at,
                run_ended_at
            FROM area_golds2_{self._main_runner}
            {extra_condition};
            """,  # noqa: S608
            excel_name=excel_name,
        )

    def pb_summary(self) -> DataFrame:
        """
        Returns a DataFrame with summary data of the runner's PB (personal best), doorsplit
        by doorsplit, useful to provide a sense of where the run went well and where it didn't.

        TODO: There's a mistake on the splits_overview table, doorsplit 77 is duplicated for
        whatever reason.
        """
        return self.execute(
            query=f"""
            SELECT
                run_id,
                split_index AS index,
                split_name AS split,
                lrt_time_fmt AS ds_time,
                ds_gold_fmt AS ds_gold,
                chapter_time_fmt AS ch_time,
                chapter_gold_fmt AS ch_gold,
                area_time_fmt AS area_time,
                area_gold_fmt AS area_gold,
                lrt_pace_fmt AS pace,
                best_pace_fmt AS best_pace,
                doorsplit_rank AS ds_rank,
                doorsplit_rank_at_that_time AS ds_rank_at_that_time,
                chapter_rank AS ch_rank,
                chapter_rank_at_that_time AS ch_rank_at_that_time,
                area_rank,
                area_rank_at_that_time,
                pace_rank,
                pace_rank_at_that_time AS pace_rank_at_that_time,
                run_started_at,
                run_ended_at,
                LTRIM(TO_CHAR(final_lrt_time::INTERVAL, 'HH24:MI:SS.FF3'), '0:') AS pb
            FROM splits_overview_{self._main_runner}
            WHERE run_id = (SELECT MAX(run_id) FROM pb_history_{self._main_runner})
            ORDER BY split_index;
            """,  # noqa: S608
            excel_name=f"{self._main_runner}_pb_summary",
        )

    def doorsplits_of_chapter_golds(self, chapter: str = "") -> DataFrame:
        """
        Get all doorsplits that make up each chapter gold of the runner.

        Optionally, provide a specific chapter to only check that one.
        """
        if chapter:
            extra_condition = f"AND CHAPTER = '{chapter}'"
            excel_name = f"{self._main_runner}_chapter_gold_{chapter.replace('-', '_')}_components"
        else:
            extra_condition = ""
            excel_name = f"{self._main_runner}_chapter_golds_components"

        return self.execute(
            query=f"""
            SELECT
                run_id,
                split_index AS index,
                split_name AS split,
                chapter,
                lrt_time_fmt AS ds_time,
                ds_gold_fmt AS ds_gold,
                chapter_gold_fmt AS ch_gold,
                split_started_at,
                split_ended_at
            FROM splits_overview_{self._main_runner}
            WHERE chapter_time = chapter_gold {extra_condition}
            ORDER BY split_index;
            """,  # noqa: S608
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
            query=f"""
            SELECT
                run_id,
                split_index,
                split_name,
                chapter,
                lrt_time_fmt AS ds_time,
                ds_gold_fmt AS ds_gold,
                split_started_at,
                split_ended_at,
                run_started_at,
                run_ended_at
            FROM splits_overview_{self._main_runner}
            WHERE split_name = %(split_name)s
            ORDER BY {order_by.value} {order_type.value};
            """,  # noqa: S608
            params={"split_name": split_name},
            excel_name=excel_name,
        )

    def compare_runners_doorsplit_golds(self, other_runner: str) -> DataFrame:
        """
        Returns a DataFrame with all doorsplit golds of the main runner and another
        runner, as well as the difference between these golds, for each split.
        """
        return self.execute(
            query=f"""
            SELECT
                runner1.split_index AS split_number,
                runner1.split_name,
                runner1.lrt_time_fmt AS {self._main_runner}_ds_gold,
                runner2.lrt_time_fmt AS {other_runner}_ds_gold,
                (runner1.lrt_time - runner2.lrt_time)::TEXT AS difference
            FROM
            (
                SELECT DISTINCT
                    split_index,
                    split_name,
                    lrt_time,
                    lrt_time_fmt
                FROM doorsplit_golds2_{self._main_runner}
            ) runner1

            FULL JOIN
            (
                SELECT DISTINCT
                    split_index,
                    split_name,
                    lrt_time,
                    lrt_time_fmt
                FROM doorsplit_golds2_{other_runner}
            ) runner2
            ON runner1.split_index = runner2.split_index
            ORDER BY runner1.split_index;
            """,  # noqa: S608
            excel_name=f"ds_golds_{self._main_runner}_vs_{other_runner}",
        )

    def compare_runners_doorsplit_medians(self, other_runner: str) -> DataFrame:
        """
        Returns a DataFrame with all doorsplit medians of the main runner and another
        runner, as well as the difference between these medians, for each split.
        """
        return self.execute(
            query=f"""
            SELECT
                runner1.split_index AS split_number,
                runner1.split_name,
                runner1.lrt_time_med_fmt AS {self._main_runner}_ds_med,
                runner2.lrt_time_med_fmt AS {other_runner}_ds_med,
                (runner1.lrt_time_med - runner2.lrt_time_med)::TEXT AS difference
            FROM
            (
                SELECT
                    split_index,
                    split_name,
                    lrt_time_med,
                    lrt_time_med_fmt
                FROM doorsplits_avg_med_{self._main_runner}
            ) runner1

            FULL JOIN
            (
                SELECT
                    split_index,
                    split_name,
                    lrt_time_med,
                    lrt_time_med_fmt
                FROM doorsplits_avg_med_{other_runner}
            ) runner2
            ON runner1.split_index = runner2.split_index
            ORDER BY runner1.split_index;
            """,  # noqa: S608
            excel_name=f"ds_medians_{self._main_runner}_vs_{other_runner}",
        )

    def attempts_per_day(self) -> DataFrame:
        """
        Returns a DataFrame with the number of attempts the runner has
        ever done for each unique day that they've done attempts for
        in their history.
        """
        return self.execute(
            query=f"""
            SELECT
                TO_CHAR(date_started_at, 'DD/MM/YYYY'),
                EXTRACT(ISODOW FROM date_started_at) AS iso_weekday,
                attempts_on_date
            FROM
            (
                SELECT
                    DATE(run_started_at) AS date_started_at,
                    COUNT(*) AS attempts_on_date
                FROM attempts_data5_{self._main_runner}
                GROUP BY DATE(run_started_at)
            )
            ORDER BY date_started_at;
            """,  # noqa: S608
            excel_name=f"attempts_per_day_{self._main_runner}",
        )

    def attempts_per_day_of_the_week(self) -> DataFrame:
        """
        Returns a DataFrame with the number of attempts the runner has
        ever done for each unique day of the week.
        """
        return self.execute(
            query=f"""
            SELECT
                TO_CHAR(DATE '2000-01-03' + (iso_weekday - 1) * INTERVAL '1 day', 'Day') AS weekday,
                SUM(attempts_on_date) AS total_attempts
            FROM
            (
                SELECT
                    date_started_at,
                    EXTRACT(ISODOW FROM date_started_at) AS iso_weekday,
                    attempts_on_date
                FROM
                (
                    SELECT
                        DATE(run_started_at) AS date_started_at,
                        COUNT(*) AS attempts_on_date
                    FROM attempts_data5_{self._main_runner}
                    GROUP BY DATE(run_started_at)
                )
                ORDER BY date_started_at
            )
            GROUP BY iso_weekday
            ORDER BY iso_weekday;
            """,  # noqa: S608
            excel_name=f"attempts_per_day_of_the_week_{self._main_runner}",
        )

    def attempts_per_week(self) -> DataFrame:
        """
        Returns a DataFrame with the number of attempts the runner has
        done for each week of the year.
        """
        return self.execute(
            query=f"""
            SELECT
                EXTRACT(ISOYEAR FROM dt) AS year_num,
                EXTRACT(WEEK FROM dt) AS week_num,
                TO_CHAR(DATE_TRUNC('WEEK', dt)::DATE, 'DD/MM/YYYY') AS week_start,
                TO_CHAR((DATE_TRUNC('WEEK', dt) + INTERVAL '6 days')::DATE, 'DD/MM/YYYY') AS week_end,
                COUNT(DISTINCT run_id) AS total_attempts
            FROM cfg_dates cfg

            LEFT JOIN attempts_data5_{self._main_runner} att
            ON cfg.dt = DATE(att.run_started_at)
            WHERE EXTRACT(ISOYEAR FROM dt) = EXTRACT(ISOYEAR FROM CURRENT_DATE) AND dt <= CURRENT_DATE
            GROUP BY
                year_num,
                week_num,
                week_start,
                week_end
            ORDER BY week_num;
            """,  # noqa: S608
            excel_name=f"attempts_per_week_{self._main_runner}",
        )
