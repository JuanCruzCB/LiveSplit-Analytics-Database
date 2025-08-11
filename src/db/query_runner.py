from datetime import datetime
from enum import StrEnum
from pathlib import Path

import pandas as pd
from pandas import DataFrame

from db.database_manager import DatabaseManager
from db.utils import calculate_best_time, format_time, parse_time


class ConstantQuery(StrEnum):
    DOORSPLIT_GOLDS_QUERY = "SELECT * FROM global_door_golds;"
    BEST_PACES_QUERY = "SELECT * FROM global_best_paces_chapter;"
    RNG_PATTERNS_QUERY = "SELECT * FROM global_rng_patterns;"
    WEEKDAY_DATA_QUERY = "SELECT * FROM global_weekday_data;"
    RELEVANT_TABLE_NAMES = """
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
        AND table_name NOT LIKE '%treatment%'
        AND table_name NOT LIKE '%cleaned%'
        AND table_name NOT LIKE '%info%'
        AND table_name NOT LIKE '%notepad%'
    ORDER BY table_name;
    """


class OrderColumns(StrEnum):
    LRT_RAW_TIME = "lrt_number"
    SPLIT_NUMBER = "cle2"
    DATE_STARTED = "date_started"


class QueryRunner:
    GOOD_DATE_FORMAT = "%d/%m/%Y"

    def __init__(
        self,
        db_manager: DatabaseManager,
        allowed_runners: list[str],
        main_runner_name: str,
    ):
        self._db = db_manager
        self._allowed_runners = allowed_runners
        self._runner = main_runner_name
        self._output_dir = Path(__file__).parent.parent.parent / "output"
        self._output_dir.mkdir(exist_ok=True)

    """
    MAIN QUERIES
    """

    def open_db_connection(self) -> None:
        self._db.open_connection()

    def close_db_connection(self) -> None:
        self._db.close_connection()

    def update_runners_tables(self, splits: dict[Path, datetime]) -> bool:
        return self._db.update_runners_tables(splits=splits)

    def update_global_tables(self) -> None:
        self._db.update_global_tables()

    @staticmethod
    def _add_best_and_cumulative_best_columns(golds: DataFrame) -> DataFrame:
        golds["Best gold"] = golds.apply(
            calculate_best_time,
            axis=1,
        )
        golds["Best gold seconds"] = golds["Best gold"].map(parse_time)
        golds["Cumulative best seconds"] = golds["Best gold seconds"].cumsum()
        golds["Cumulative best"] = golds["Cumulative best seconds"].apply(format_time)
        golds = golds.drop(columns=["Best gold seconds", "Cumulative best seconds"])

        best_gold_idx = golds.columns.get_loc("Best gold")
        cumulative_best_idx = golds.columns.get_loc("Cumulative best")

        golds.iloc[golds.index[-1], best_gold_idx] = ""  # type: ignore  # noqa: PGH003
        golds.iloc[golds.index[-1], cumulative_best_idx] = ""  # type: ignore  # noqa: PGH003

        return golds

    @staticmethod
    def _add_best_column(
        df: DataFrame,
        *,
        remove_last_cell: bool = True,
    ) -> DataFrame:
        df["Best"] = df.apply(
            calculate_best_time,
            axis=1,
        )
        if remove_last_cell:
            df.iloc[df.index[-1], 11] = ""

        return df

    def get_doorsplit_golds(self) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the doorsplit golds of that runner.
        The last row contains the doorsplits sum of best of that runner.
        """
        return self._db.execute(query=ConstantQuery.DOORSPLIT_GOLDS_QUERY)

    def get_chapter_golds(self) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the chapter golds of that runner.
        The last row contains the chapter sum of best of that runner.

        In addition, there's a column with the best chapter gold for each
        chapter, and a column with the cumulative best chapters.
        """
        runners = ", ".join(self._allowed_runners)
        global_chapter_golds_query = f"""
        SELECT chapter, {runners}
        FROM global_chapter_golds
        WHERE chapter LIKE '%-%' OR chapter = 'Total';
        """  # noqa: S608
        chapter_golds = self._db.execute(query=global_chapter_golds_query)
        chapter_golds = chapter_golds.drop(columns=["chapter"])
        chapter_golds = QueryRunner._add_best_and_cumulative_best_columns(chapter_golds)
        return chapter_golds

    def get_chapter_golds_by_doors(self) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the chapter golds by adding up all
        the doorsplit golds of that chapter of that runner.
        The last row contains the doorsplits sum of best of that runner.

        In addition, there's a column with the best chapter gold for each
        chapter, and a column with the cumulative best chapters.
        """
        runners = ", ".join(self._allowed_runners)
        global_chapter_golds_by_doors_query = f"""
        SELECT {runners}
        FROM global_chapter_golds_doors;
        """  # noqa: S608
        chapter_golds_by_doors = self._db.execute(
            query=global_chapter_golds_by_doors_query
        )
        chapter_golds_by_doors = QueryRunner._add_best_and_cumulative_best_columns(
            chapter_golds_by_doors
        )
        return chapter_golds_by_doors

    def get_section_golds(self) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the section golds of that runner.
        The last row contains the section sum of best of that runner.

        In addition, there's a column with the best section gold for each
        section, and a column with the cumulative best sections.
        """
        runners = ", ".join(self._allowed_runners)
        global_section_golds_query = f"""
        SELECT {runners}
        FROM global_section_golds;
        """  # noqa: S608
        section_golds = self._db.execute(query=global_section_golds_query)
        section_golds = QueryRunner._add_best_and_cumulative_best_columns(section_golds)
        return section_golds

    def get_section_golds_by_chapters(self) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the section golds by adding up all
        the chapter golds of that section of that runner.
        The last row contains the chapter sum of best of that runner.

        In addition, there's a column with the best section gold for each
        section, and a column with the cumulative best sections.
        """
        runners = ", ".join(self._allowed_runners)
        global_section_golds_by_chapters_query = f"""
        SELECT {runners}
        FROM global_section_golds_chapters;
        """  # noqa: S608
        section_golds_by_chapters = self._db.execute(
            query=global_section_golds_by_chapters_query
        )
        section_golds_by_chapters = QueryRunner._add_best_and_cumulative_best_columns(
            section_golds_by_chapters
        )
        return section_golds_by_chapters

    def get_section_golds_by_doors(self) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the section golds by adding up all
        the doorsplit golds of that section of that runner.
        The last row contains the doorsplits sum of best of that runner.

        In addition, there's a column with the best section gold for each
        section, and a column with the cumulative best sections.
        """
        runners = ", ".join(self._allowed_runners)
        global_section_golds_by_doors_query = f"""
        SELECT {runners}
        FROM global_section_golds_doors;
        """  # noqa: S608
        section_golds_by_doors = self._db.execute(
            query=global_section_golds_by_doors_query
        )
        section_golds_by_doors = QueryRunner._add_best_and_cumulative_best_columns(
            section_golds_by_doors
        )
        return section_golds_by_doors

    def get_best_paces(self) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the best paces of that runner per chapter.

        In addition, there's a column with the overall best pace for each
        chapter.
        """
        best_paces = self._db.execute(query=ConstantQuery.BEST_PACES_QUERY)
        best_paces = best_paces.drop(columns=["chapter"])
        best_paces = QueryRunner._add_best_column(best_paces, remove_last_cell=False)
        return best_paces

    def get_rng_patterns(self) -> DataFrame:
        """
        Returns a DataFrame where, for each runner, contains the
        percentage of different RNG patterns that runner has gotten overall
        and also the maximum amount of times in a row they've gotten each pattern.
        """
        return self._db.execute(query=ConstantQuery.RNG_PATTERNS_QUERY)

    def get_general_stats(self) -> DataFrame:
        """
        Returns a DataFrame with simple stats for each runner:
        1) The last time they've updated their splits (as in, ran the game).
        2) Their PB.
        3) Their total number of attempts or resets.
        4) Their total playtime, in days and hours.
        """
        runners = ", ".join(self._allowed_runners)
        general_stats_query = f"""
        SELECT chapter, {runners}
        FROM global_chapter_golds
        WHERE chapter NOT LIKE '%-%' AND chapter <> 'Total';
        """  # noqa: S608
        return self._db.execute(query=general_stats_query)

    def get_resets(self) -> DataFrame:
        """
        Returns a DataFrame with the percentage of resets for each runner, for
        all doorsplits. As in, what percentage of the runs that get to that split
        end up with the runner resetting on that split.
        """
        columns = ",\n".join(
            f"CASE WHEN percent_{name} < 0 THEN 0 ELSE percent_{name} END AS percent_{name}"
            for name in self._allowed_runners
        )
        resets_query = f"""
        SELECT split,
        {columns}
        FROM global_resets;
        """  # noqa: S608
        return self._db.execute(query=resets_query)

    def get_weekday_data(self) -> DataFrame:
        """
        Returns a DataFrame with many different stats related to how
        the runner performs on different days of the week.
        """
        return self._db.execute(query=ConstantQuery.WEEKDAY_DATA_QUERY)

    """
    SECONDARY QUERIES
    """

    def execute(
        self, query: str, params: dict | None = None, excel_name: str = ""
    ) -> DataFrame:
        """
        Execute the query on the db and optionally save the data to an excel file.
        """
        data = self._db.execute(query=query, params=params)
        if "date_started" in data.columns:
            data["date_started"] = data["date_started"].apply(
                lambda x: pd.to_datetime(x, errors="coerce").strftime(
                    self.GOOD_DATE_FORMAT
                )
                if pd.notna(x)
                else None
            )
        if excel_name:
            data.to_excel(self._output_dir / f"{excel_name}.xlsx", index=False)
        return data

    def export_relevant_table_names(self) -> None:
        relevant_tables = self._db.execute(ConstantQuery.RELEVANT_TABLE_NAMES.value)
        with Path(self._output_dir / "relevant_tables.txt").open("w") as f:
            f.write("\n".join(relevant_tables["table_name"].to_list()))

    def doorsplit_golds(self, version: int = 2, *, ties: bool = False) -> DataFrame:
        """
        Get all doorsplit golds (version 1 or 2).
        """
        if version == 1:
            return self.execute(
                query=f"""
                SELECT ds_golds.cle2, ds_golds.split, ds_golds.gold2, ds_golds.date_started
                FROM doorsplits_golds2_{self._runner} AS ds_golds
                INNER JOIN default_split_names_{self._runner} AS split_names on ds_golds.cle2 = split_names.cle2
                ORDER BY cle2
                """,  # noqa: S608
                excel_name=f"{self._runner}_doorsplit_golds_v1",
            )

        return self.execute(
            query=f"""
            WITH tied_golds2 (tied) AS (values (%(ties)s))
            SELECT *
            FROM (
                SELECT
                    id,
                    cle2,
                    split,
                    lrt_split,
                    date_started,
                    time_start,
                    CASE
                        WHEN row_number() OVER (partition by cle2 order by id) = 1 THEN 0
                        ELSE 1
                    END AS tied_gold
                FROM (
                    SELECT
                        id,
                        cle2,
                        split,
                        lrt_split,
                        date_started,
                        time_start,
                        rank() over (partition by cle2 order by lrt_number) AS rang
                    FROM (
                        SELECT *
                        FROM splits_overview_{self._runner}) aa) a
                        WHERE rang = 1
                    )
                    WHERE tied_gold <= (SELECT tied FROM tied_golds2)
            ORDER BY cle2, id;
            """,  # noqa: S608
            params={"ties": int(ties)},
            excel_name=f"{self._runner}_doorsplits_golds_v2_with_ties"
            if ties
            else f"{self._runner}_doorsplits_golds_v2_without_ties",
        )

    def chapter_golds(self, version: int = 2) -> DataFrame:
        """
        Get chapter golds (version 1 or 2).
        """
        if version == 1:
            return self.execute(
                query=f"""
                SELECT chapter, chapter_gold2, date_started
                FROM chapter_golds2_{self._runner}
                """,  # noqa: S608
                excel_name=f"{self._runner}_chapter_golds_v1",
            )
        return self.execute(
            query=f"""
            SELECT
                id,
                chapter,
                chapter_time2,
                date_started,
                time_start
            FROM (
                SELECT
                    id,
                    chapter,
                    chapter_time,
                    chapter_time2,
                    chapter_gold,
                    chapter_gold2,
                    chapter_gold_at_that_time,
                    date_started,
                    date_started2,
                    time_start,
                    row_number() over (partition by id, chapter order by cle2) AS rang
                FROM splits_overview_{self._runner}
                WHERE chapter_time2=chapter_gold2
                ORDER BY chapter, id
            ) a
            WHERE rang = 1
            ORDER BY chapter, id;
            """,  # noqa: S608
            excel_name=f"{self._runner}_chapter_golds_v2",
        )

    def section_golds(self, version: int = 2) -> DataFrame:
        """
        Get section golds (version 1 or 2).
        """
        if version == 1:
            return self.execute(
                query=f"""
                SELECT section, section_gold2, date_started
                FROM section_golds3_{self._runner}
                """,  # noqa: S608
                excel_name=f"{self._runner}_section_golds_v1",
            )
        return self.execute(
            query=f"""
            SELECT
                id,
                section,
                section_time2,
                date_started,
                time_start
            FROM (
                SELECT
                    id,
                    section,
                    section_time,
                    section_time2,
                    section_gold,
                    section_gold2,
                    section_gold_at_that_time,
                    date_started,
                    date_started2,
                    time_start,
                    row_number() over (partition by id, section order by cle2) AS rang
                FROM splits_overview_{self._runner}
                WHERE section_time2 = section_gold2
                ORDER BY section, id
            ) a
            WHERE rang = 1
            ORDER BY
                CASE
                    WHEN section='Village' THEN 1
                    WHEN section='Castle' THEN 2
                    ELSE 3
                END,
                id;
            """,  # noqa: S608
            excel_name=f"{self._runner}_section_golds_v2",
        )

    def doorsplits_pb_analysis(self) -> DataFrame:
        return self.execute(
            query=f"""
            SELECT
                id,
                date_started,
                cle2,
                split,
                lrt_split,
                gold2,
                rank_split,
                split_rank_at_that_time,
                finished_splits,
                finished_splits_at_that_time
            FROM splits_overview_{self._runner}
            WHERE id IN (SELECT max(id) FROM pb_history_{self._runner})
            ORDER BY cle2;
            """,  # noqa: S608
            excel_name=f"{self._runner}_doorsplits_pb_analysis",
        )

    def chapter_pb_analysis(self) -> DataFrame:
        return self.execute(
            query=f"""
            SELECT
                id,
                date_started,
                chapter,
                chapter_time2,
                chapter_gold2,
                rank_chapter,
                chapter_rank_at_that_time,
                finished_chapters,
                finished_chapters_at_that_time
            FROM splits_overview_{self._runner}
            WHERE id IN (SELECT max(id) FROM pb_history_{self._runner})
            ORDER BY chapter;
            """,  # noqa: S608
            excel_name=f"{self._runner}_chapter_pb_analysis",
        )

    def section_pb_analysis(self) -> DataFrame:
        return self.execute(
            query=f"""
            SELECT
                id,
                date_started,
                section,
                section_time2,
                section_gold2,
                rank_section,
                section_rank_at_that_time,
                finished_sections,
                finished_sections_at_that_time
            FROM splits_overview_{self._runner}
            WHERE id IN (SELECT max(id) FROM pb_history_{self._runner})
            ORDER BY
                CASE
                    WHEN section = 'Village' THEN 1
                    WHEN section = 'Castle' THEN 2
                    ELSE 3
                END;
            """,  # noqa: S608
            excel_name=f"{self._runner}_section_pb_analysis",
        )

    def best_paces_pb_analysis(self) -> DataFrame:
        return self.execute(
            query=f"""
            SELECT
                id,
                date_started,
                cle2,
                split,
                pace2,
                best_pace2,
                rank_pace,
                pace_rank_at_that_time,
                finished_paces,
                finished_paces_at_that_time
            FROM splits_overview_{self._runner}
            WHERE id IN (SELECT max(id) FROM pb_history_{self._runner})
            ORDER BY cle2;
            """,  # noqa: S608
            excel_name=f"{self._runner}_best_paces_pb_analysis",
        )

    def best_paces_eoc_pb_analysis(self) -> DataFrame:
        return self.execute(
            query=f"""
            SELECT
                id,
                date_started,
                cle2,
                split,
                pace2,
                best_pace2,
                rank_pace,
                pace_rank_at_that_time,
                finished_paces,
                finished_paces_at_that_time
            FROM splits_overview_{self._runner}
            WHERE id IN (SELECT max(id) FROM pb_history_{self._runner})
            AND split LIKE '%{{%'
            ORDER BY cle2;
            """,  # noqa: S608
            excel_name=f"{self._runner}_best_paces_eoc_pb_analysis",
        )

    def doorsplits_of_chapter_gold(self, chapter: str) -> DataFrame:
        """
        Get all doorsplits that make up a chapter gold.
        """
        return self.execute(
            query=f"""
            SELECT cle2, split, chapter, lrt_split, gold2, chapter_gold2, date_started
            FROM splits_overview_{self._runner}
            WHERE chapter = %(chapter)s AND chapter_time = chapter_gold
            ORDER BY cle2;
            """,  # noqa: S608
            params={"chapter": chapter},
            excel_name=f"{self._runner}_chapter_{chapter.replace('-', '_')}_components",
        )

    def split_history(
        self,
        split_name: str,
        order_by: OrderColumns = OrderColumns.LRT_RAW_TIME,
        *,
        desc: bool = True,
    ) -> DataFrame:
        """
        Get history of a specific split.
        """
        if "{" not in split_name:
            split_name = f"-{split_name}"
        split_name_formatted = (
            split_name.replace("{", "").replace("}", "").replace("-", "")
        )
        return self.execute(
            query=f"""
            SELECT split, lrt_split, date_started
            FROM splits_overview_{self._runner}
            WHERE split = %(split_name)s
            ORDER BY {order_by.value}
            {"DESC" if desc else ""};
            """,  # noqa: S608
            params={"split_name": split_name},
            excel_name=f"{self._runner}_{split_name_formatted}_history",
        )

    def compare_runners_doorsplit_golds(self, other_runner: str) -> DataFrame:
        return self.execute(
            query=f"""
            SELECT
            runner1.cle2 AS split_number,
            runner1.gold AS {self._runner}_door_gold,
            runner2.gold AS {other_runner}_door_gold,
            runner1.gold2 AS {self._runner}_door_gold2,
            runner2.gold2 AS {other_runner}_door_gold2,
            runner1.gold - runner2.gold AS difference
            FROM
                (SELECT DISTINCT cle2, gold, gold2 FROM doorsplits_golds2_{self._runner}) runner1
            FULL JOIN
                (SELECT DISTINCT cle2, gold, gold2 FROM doorsplits_golds2_{other_runner}) runner2
            ON runner1.cle2 = runner2.cle2
            ORDER BY runner1.cle2;
            """,  # noqa: S608
            excel_name=f"doorsplit_golds_comparison_{self._runner}_vs_{other_runner}",
        )

    def compare_runners_doorsplit_medians(self, other_runner: str) -> DataFrame:
        return self.execute(
            query=f"""
            SELECT
            runner1.cle2 AS split_number,
            runner1.door_median AS {self._runner}_door_median,
            runner2.door_median AS {other_runner}_door_median,
            runner1.door_median2 AS {self._runner}_door_median2,
            runner2.door_median2 AS {other_runner}_door_median2,
            runner1.door_median - runner2.door_median AS difference
            FROM
            (SELECT DISTINCT cle2, door_median, door_median2 FROM doorsplits_golds2_{self._runner}) runner1
            FULL JOIN
            (SELECT DISTINCT cle2, door_median, door_median2 FROM doorsplits_golds2_{other_runner}) runner2
            ON runner1.cle2 = runner2.cle2
            ORDER BY runner1.cle2;
            """,  # noqa: S608
            excel_name=f"doorsplit_medians_comparison_{self._runner}_vs_{other_runner}",
        )

    def attempts_per_week(self) -> DataFrame:
        return self.execute(
            query=f"""
            SELECT
            CASE
                WHEN EXTRACT(week from date) = 1 AND EXTRACT(month from date) = 12 THEN EXTRACT(year from date) + 1
                WHEN EXTRACT(week from date) > 50 AND EXTRACT(month from date) = 1 THEN EXTRACT(year from date) - 1
                ELSE EXTRACT(year from date) end * 100 + EXTRACT(week from date) AS week, count(distinct id) AS runs
            FROM dates a
            LEFT JOIN attempts_treatment3_{self._runner} b on a.date = b.date_started
            WHERE EXTRACT(year from date) = EXTRACT(year from current_date) AND date <= current_date
            GROUP BY 1
            ORDER BY 1;
            """,  # noqa: S608
            excel_name=f"attempts_per_week_{self._runner}",
        )
