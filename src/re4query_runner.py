from enum import StrEnum
from pathlib import Path

import pandas as pd
from pandas import DataFrame

from re4database_manager import RE4DatabaseManager
from utils import format_time, parse_time


class ConstantQuery(StrEnum):
    DOORSPLIT_GOLDS_QUERY = "SELECT * FROM global_door_golds;"
    BEST_PACES_QUERY = "SELECT * FROM global_best_paces_chapter;"
    RNG_PATTERNS_QUERY = "SELECT * FROM global_rng_patterns;"
    WEEKDAY_DATA_QUERY = "SELECT * FROM global_weekday_data;"
    ALL_TABLE_NAMES = """
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        ORDER BY table_name;
    """
    SAWKEN_VS_JOKER_MEDIAN_DOORSPLITS = """
    SELECT
    s.cle2,
    s.door_median AS sawken_door_median,
    j.door_median AS joker_door_median,
    s.door_median2 AS sawken_door_median2,
    j.door_median2 AS joker_door_median2,
    s.door_median - j.door_median AS difference
    FROM
    (SELECT DISTINCT cle2, door_median, door_median2 FROM doorsplits_golds2_sawken) s
    FULL JOIN
    (SELECT DISTINCT cle2, door_median, door_median2 FROM doorsplits_golds2_joker) j
    ON s.cle2 = j.cle2
    ORDER BY s.cle2;
    """
    SAWKEN_VS_JOKER_GOLD_DOORSPLITS = """SELECT
        s.cle2,
        s.gold AS sawken_door_gold,
        j.gold AS joker_door_gold,
        s.gold2 AS sawken_door_gold2,
        j.gold2 AS joker_door_gold2,
        s.gold - j.gold AS difference
    FROM
        (SELECT DISTINCT cle2, gold, gold2 FROM doorsplits_golds2_sawken) s
    FULL JOIN
        (SELECT DISTINCT cle2, gold, gold2 FROM doorsplits_golds2_joker) j
    ON s.cle2 = j.cle2
    ORDER BY s.cle2;
    """


class OrderColumns(StrEnum):
    LRT_NUMBER = "lrt_number"
    CLE2 = "cle2"
    DATE_STARTED = "date_started"


class RE4QueryRunner:
    GOOD_DATE_FORMAT = "%d/%m/%Y"

    def __init__(
        self,
        db_manager: RE4DatabaseManager,
        allowed_runners: list[str],
        runner: str = "sawken",
    ):
        self._db = db_manager
        self._allowed_runners = allowed_runners
        self._runner = runner
        self._excel_dir = Path(__file__).parent.parent / "excels"
        self._excel_dir.mkdir(exist_ok=True)

    """
    MAIN QUERIES
    """

    @property
    def db(self):
        return self._db

    @staticmethod
    def _calculate_best_time(times: list[str]) -> str:
        """
        Receives a list of times in [H]:MM:SS.mmm format and
        returns the minimum time among all of them.
        """
        times_decimal = [parse_time(cg) for cg in times]
        return format_time(min(times_decimal))

    @staticmethod
    def _add_best_and_cumulative_best_columns(golds: DataFrame) -> DataFrame:
        golds["Best gold"] = golds.apply(
            RE4QueryRunner._calculate_best_time,
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
        remove_last_cell: bool = True,  # noqa: FBT001, FBT002
    ) -> DataFrame:
        df["Best"] = df.apply(
            RE4QueryRunner._calculate_best_time,
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
        return self._db.query(query=ConstantQuery.DOORSPLIT_GOLDS_QUERY)

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
        WHERE chapter like '%-%' or chapter='Total';
        """  # noqa: S608
        chapter_golds = self._db.query(query=global_chapter_golds_query)
        chapter_golds = chapter_golds.drop(columns=["chapter"])
        chapter_golds = RE4QueryRunner._add_best_and_cumulative_best_columns(
            chapter_golds
        )
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
        chapter_golds_by_doors = self._db.query(
            query=global_chapter_golds_by_doors_query
        )
        chapter_golds_by_doors = RE4QueryRunner._add_best_and_cumulative_best_columns(
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
        section_golds = self._db.query(query=global_section_golds_query)
        section_golds = RE4QueryRunner._add_best_and_cumulative_best_columns(
            section_golds
        )
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
        section_golds_by_chapters = self._db.query(
            query=global_section_golds_by_chapters_query
        )
        section_golds_by_chapters = (
            RE4QueryRunner._add_best_and_cumulative_best_columns(
                section_golds_by_chapters
            )
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
        section_golds_by_doors = self._db.query(
            query=global_section_golds_by_doors_query
        )
        section_golds_by_doors = RE4QueryRunner._add_best_and_cumulative_best_columns(
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
        best_paces = self._db.query(query=ConstantQuery.BEST_PACES_QUERY)
        best_paces = best_paces.drop(columns=["chapter"])
        best_paces = RE4QueryRunner._add_best_column(best_paces, remove_last_cell=False)
        return best_paces

    def get_rng_patterns(self) -> DataFrame:
        """
        Returns a DataFrame where, for each runner, contains the
        percentage of different RNG patterns that runner has gotten overall
        and also the maximum amount of times in a row they've gotten each pattern.
        """
        return self._db.query(query=ConstantQuery.RNG_PATTERNS_QUERY)

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
        return self._db.query(query=general_stats_query)

    def get_resets(self) -> DataFrame:
        """
        Returns a DataFrame with the percentage of resets for each runner, for
        all doorsplits. As in, what percentage of the runs that get to that split
        end up with the runner resetting on that split.
        """
        columns = ",\n".join(
            f"case when percent_{name} < 0 then 0 else percent_{name} end as percent_{name}"
            for name in self._allowed_runners
        )
        resets_query = f"""
        SELECT split,
        {columns}
        FROM global_resets;
        """  # noqa: S608
        return self._db.query(query=resets_query)

    def get_weekday_data(self) -> DataFrame:
        """
        Returns a DataFrame with many different stats related to how
        the runner performs on different days of the week.
        """
        return self._db.query(query=ConstantQuery.WEEKDAY_DATA_QUERY)

    """
    SECONDARY QUERIES
    """

    def run(self, query: str, excel_name: str = "") -> DataFrame:
        """
        Execute query and optionally save to Excel.
        """
        result = self._db.query(query)
        if "date_started" in result.columns:
            result["date_started"] = pd.to_datetime(
                result["date_started"],
                errors="coerce",
            ).dt.strftime(self.GOOD_DATE_FORMAT)
        if excel_name:
            result.to_excel(self._excel_dir / f"{excel_name}.xlsx", index=False)
        return result

    def export_table_names(self):
        table_names = self._db.query(ConstantQuery.ALL_TABLE_NAMES.value)
        relevant_table_names = [
            t
            for t in table_names["table_name"]
            if not any(x in t for x in ["treatment", "cleaned", "info", "notepad"])
        ]

        relevant_tables_path = (
            Path(__file__).parent.parent / "info" / "relevant_tables.txt"
        )
        with Path(relevant_tables_path).open("w") as f:
            f.write("\n".join(relevant_table_names))

    def doorsplit_golds(self, version: int = 2, ties: bool = False) -> DataFrame:  # noqa: FBT001, FBT002
        """
        Get all doorsplit golds (version 1 or 2).
        """
        if version == 1:
            return self.run(
                f"""SELECT ds.cle2, sn.split, ds.gold2, ds.date_started
                FROM doorsplits_golds2_{self._runner} as ds
                INNER JOIN default_split_names_sawken as sn on ds.cle2 = sn.cle2
                ORDER BY cle2""",
                f"{self._runner}_doorsplit_golds_v1",
            )
        if ties:
            excel_name = f"{self._runner}_doorsplits_golds_v2_with_ties"
        else:
            excel_name = f"{self._runner}_doorsplits_golds_v2_without_ties"

        return self.run(
            query=f"""
            with tied_golds2 (tied) as (values ({int(ties)}))
            select *
            from(
            select id, cle2, split, lrt_split, date_started, time_start, case when row_number() over (partition by cle2 order by id)=1 then 0 else 1 end as tied_gold
            from (
            select id, cle2, split, lrt_split, date_started, time_start, rank() over (partition by cle2 order by lrt_number) as rang
            from (
            select *
            from splits_overview_{self._runner}) aa) a
            where rang=1)
            where tied_gold<=(select tied from tied_golds2)
            order by cle2, id;
            """,
            excel_name=excel_name,
        )

    def chapter_golds(self, version: int = 2) -> DataFrame:
        """
        Get chapter golds (version 1 or 2).
        """
        if version == 1:
            return self.run(
                f"SELECT chapter, chapter_gold2, date_started FROM chapter_golds2_{self._runner}",
                f"{self._runner}_chapter_golds_v1",
            )
        return self.run(
            f"""
            select id, chapter, chapter_time2,
            date_started, time_start
            from (
            select id, chapter, chapter_time, chapter_time2, chapter_gold, chapter_gold2, chapter_gold_at_that_time,
            date_started, date_started2, time_start, row_number() over (partition by id, chapter order by cle2) as rang
            from splits_overview_{self._runner}
            where chapter_time2=chapter_gold2
            order by chapter, id) a
            where rang=1
            order by chapter, id;
            """,
            f"{self._runner}_chapter_golds_v2",
        )

    def section_golds(self, version: int = 2) -> DataFrame:
        """
        Get section golds (version 1 or 2).
        """
        if version == 1:
            return self.run(
                f"SELECT section, section_gold2, date_started FROM section_golds3_{self._runner}",
                f"{self._runner}_section_golds_v1",
            )
        return self.run(
            f"""
            select id, section, section_time2,
            date_started, time_start
            from (
            select id, section, section_time, section_time2, section_gold, section_gold2, section_gold_at_that_time,
            date_started, date_started2, time_start, row_number() over (partition by id, section order by cle2) as rang
            from splits_overview_{self._runner}
            where section_time2=section_gold2
            order by section, id) a
            where rang=1
            order by case when section='Village' then 1 when section='Castle' then 2 else 3 end, id;
            """,
            f"{self._runner}_section_golds_v2",
        )

    def doorsplits_pb_analysis(self) -> DataFrame:
        return self.run(
            f"""
                SELECT id, date_started, cle2, split, lrt_split, gold2,
                       rank_split, split_rank_at_that_time,
                       finished_splits, finished_splits_at_that_time
                FROM splits_overview_{self._runner}
                WHERE id IN (SELECT max(id) FROM pb_history_{self._runner})
                ORDER BY cle2
            """,
            f"{self._runner}_doorsplits_pb_analysis",
        )

    def chapter_pb_analysis(self) -> DataFrame:
        return self.run(
            f"""
                SELECT id, date_started, chapter, chapter_time2, chapter_gold2,
                       rank_chapter, chapter_rank_at_that_time,
                       finished_chapters, finished_chapters_at_that_time
                FROM splits_overview_{self._runner}
                WHERE id IN (SELECT max(id) FROM pb_history_{self._runner})
                ORDER BY chapter
            """,
            f"{self._runner}_chapter_pb_analysis",
        )

    def section_pb_analysis(self) -> DataFrame:
        return self.run(
            f"""
                SELECT id, date_started, section, section_time2, section_gold2,
                       rank_section, section_rank_at_that_time,
                       finished_sections, finished_sections_at_that_time
                FROM splits_overview_{self._runner}
                WHERE id IN (SELECT max(id) FROM pb_history_{self._runner})
                ORDER BY CASE WHEN section='Village' THEN 1
                             WHEN section='Castle' THEN 2 ELSE 3 END
            """,
            f"{self._runner}_section_pb_analysis",
        )

    def best_paces_pb_analysis(self) -> DataFrame:
        return self.run(
            f"""
                SELECT id, date_started, cle2, split, pace2, best_pace2,
                       rank_pace, pace_rank_at_that_time,
                       finished_paces, finished_paces_at_that_time
                FROM splits_overview_{self._runner}
                WHERE id IN (SELECT max(id) FROM pb_history_{self._runner})
                ORDER BY cle2
            """,
            f"{self._runner}_section_pb_analysis",
        )

    def best_paces_eoc_pb_analysis(self) -> DataFrame:
        return self.run(
            f"""
                SELECT id, date_started, cle2, split, pace2, best_pace2,
                       rank_pace, pace_rank_at_that_time,
                       finished_paces, finished_paces_at_that_time
                FROM splits_overview_{self._runner}
                WHERE id IN (SELECT max(id) FROM pb_history_{self._runner})
                AND split LIKE '%{{%'
                ORDER BY cle2
            """,
            f"{self._runner}_section_pb_analysis",
        )

    def doorsplits_of_chapter_gold(self, chapter: str) -> DataFrame:
        """
        Get all doorsplits that make up a chapter gold.
        """
        return self.run(
            f"""SELECT cle2, split, chapter, lrt_split, gold2, chapter_gold2, date_started
            FROM splits_overview_{self._runner}
            WHERE chapter='{chapter}' AND chapter_time = chapter_gold
            ORDER BY cle2""",
            f"{self._runner}_chapter_{chapter.replace('-', '_')}_components",
        )

    def split_history(
        self,
        split_name: str,
        order_by: StrEnum = OrderColumns.LRT_NUMBER,
        desc: bool = True,  # noqa: FBT001, FBT002
    ) -> DataFrame:
        """
        Get history of a specific split.
        """
        if "{" not in split_name:
            split_name = f"-{split_name}"
        return self.run(
            f"""SELECT split, lrt_split, date_started
            FROM splits_overview_{self._runner}
            WHERE split='{split_name}'
            ORDER BY {order_by.value} {"DESC" if desc else ""}""",
            f"{self._runner}_split_history_{split_name.replace('{', '').replace('}', '').replace('-', '')}",
        )

    def compare_runners(
        self,
        other_runner: str,
        compare_type: str = "golds",
    ) -> DataFrame:
        """
        Compare two runners (golds or medians).
        """
        queries = {
            "golds": ConstantQuery.SAWKEN_VS_JOKER_GOLD_DOORSPLITS,
            "medians": ConstantQuery.SAWKEN_VS_JOKER_MEDIAN_DOORSPLITS,
        }
        return self.run(
            queries[compare_type].value,
            f"comparison_{self._runner}_vs_{other_runner}_{compare_type}",
        )

    def attempts_per_week(self) -> DataFrame:
        return self.run(
            query=f"""select case when extract(week from date)=1 and extract(month from date)=12 then extract(year from date)+1
            when extract(week from date)>50 and extract(month from date)=1 then extract(year from date)-1 else extract(year from date) end*100+extract(week from date) as week, count(distinct id) as runs
            from dates a
            left join attempts_treatment3_{self._runner} b on a.date=b.date_started
            where extract(year from date)=extract(year from current_date)
            and date<=current_date
            group by 1
            order by 1""",  # noqa: S608
            excel_name=f"attempts_per_week_{self._runner}",
        )
