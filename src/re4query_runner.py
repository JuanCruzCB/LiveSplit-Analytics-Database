from datetime import datetime
from decimal import Decimal
from enum import StrEnum
from pathlib import Path

import numpy as np
import pandas as pd
from pandas import DataFrame

from constants import Format
from re4database_manager import RE4DatabaseManager
from utils import get_days_hours_str, get_hours_minutes_str


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
    CURRENTLY_ALLOWED_RUNNERS = (
        "sawken",
        "luis",
        "joker",
        "mateo",
        "arcadan",
        "richy",
        "derek",
        "nevs",
        "otaku",
        "pocho",
        "missing",
    )

    def __init__(
        self,
        main_sql_script: Path,
        global_sql_script: Path,
        last_updates_file: Path,
        runner: str = "sawken",
    ):
        self._runner = runner
        self._db = RE4DatabaseManager(
            main_sql_script=main_sql_script,
            global_sql_script=global_sql_script,
            last_updates_file=last_updates_file,
        )
        self._excel_dir = Path(__file__).parent.parent / "excels"
        self._excel_dir.mkdir(exist_ok=True)

    """
    MAIN QUERIES
    """

    @property
    def db(self):
        return self._db

    def query_doorsplit_golds(self) -> DataFrame:
        doorsplit_golds = self._db.query_db(query=ConstantQuery.DOORSPLIT_GOLDS_QUERY)
        doorsplit_golds = doorsplit_golds.replace({np.nan: ""})
        return doorsplit_golds.drop(columns=["split"])

    def query_chapter_golds(self) -> DataFrame:
        columns = ", ".join(
            ("chapter", *self.CURRENTLY_ALLOWED_RUNNERS),
        )
        global_chapter_golds_query = f"""
        SELECT {columns}
        FROM global_chapter_golds
        WHERE chapter like '%-%' or chapter='Total';
        """  # noqa: S608
        chapter_golds = self._db.query_db(query=global_chapter_golds_query)
        chapter_golds = chapter_golds.replace({np.nan: ""})
        return chapter_golds.drop(columns=["chapter"])

    def query_chapter_golds_by_doors(self) -> DataFrame:
        columns = ", ".join(self.CURRENTLY_ALLOWED_RUNNERS)
        global_chapter_golds_by_doors_query = f"""
        SELECT {columns}
        FROM global_chapter_golds_doors;
        """  # noqa: S608
        chapter_golds_by_doors = self._db.query_db(
            query=global_chapter_golds_by_doors_query
        )
        return chapter_golds_by_doors.replace({np.nan: ""})

    def query_section_golds(self) -> DataFrame:
        columns = ", ".join(self.CURRENTLY_ALLOWED_RUNNERS)
        global_section_golds_query = f"""
        SELECT {columns}
        FROM global_section_golds;
        """  # noqa: S608
        section_golds = self._db.query_db(query=global_section_golds_query)
        return section_golds.replace({np.nan: ""})

    def query_section_golds_by_chapters(self) -> DataFrame:
        columns = ", ".join(self.CURRENTLY_ALLOWED_RUNNERS)
        global_section_golds_by_chapters_query = f"""
        SELECT {columns}
        FROM global_section_golds_chapters;
        """  # noqa: S608
        section_golds_by_chapters = self._db.query_db(
            query=global_section_golds_by_chapters_query
        )
        return section_golds_by_chapters.replace({np.nan: ""})

    def query_section_golds_by_doors(self) -> DataFrame:
        columns = ", ".join(self.CURRENTLY_ALLOWED_RUNNERS)
        global_section_golds_by_doors_query = f"""
        SELECT {columns}
        FROM global_section_golds_doors;
        """  # noqa: S608
        section_golds_by_doors = self._db.query_db(
            query=global_section_golds_by_doors_query
        )
        return section_golds_by_doors.replace({np.nan: ""})

    def query_best_paces(self) -> DataFrame:
        best_paces = self._db.query_db(query=ConstantQuery.BEST_PACES_QUERY)
        best_paces = best_paces.replace({np.nan: ""})
        return best_paces.drop(columns=["chapter"])

    def query_rng_patterns(self) -> DataFrame:
        rng_patterns = self._db.query_db(query=ConstantQuery.RNG_PATTERNS_QUERY)
        rng_patterns = rng_patterns.replace({np.nan: ""})
        rng_patterns = rng_patterns.map(
            lambda x: float(x) if isinstance(x, Decimal) else x
        )
        return rng_patterns.drop(columns=["pattern"])

    def query_general_stats(self) -> DataFrame:
        columns = ", ".join(self.CURRENTLY_ALLOWED_RUNNERS)
        general_stats_query = f"""
        SELECT chapter, {columns}
        FROM global_chapter_golds
        WHERE chapter NOT LIKE '%-%' AND chapter <> 'Total';
        """  # noqa: S608
        general_stats = self._db.query_db(query=general_stats_query)
        general_stats = general_stats.replace({np.nan: ""})
        general_stats = general_stats.drop(columns=["chapter"])
        general_stats.iloc[1] = general_stats.iloc[1].apply(
            lambda date_str: datetime.strptime(
                date_str, Format.BAD_DATE_FORMAT
            ).strftime(Format.GOOD_DATE_FORMAT),
        )
        general_stats.iloc[3] = general_stats.iloc[3].apply(
            lambda playtime: get_days_hours_str(playtime)
        )
        return general_stats

    def query_resets(self) -> DataFrame:
        columns = ",\n".join(
            f"case when percent_{name} < 0 then 0 else percent_{name} end as percent_{name}"
            for name in self.CURRENTLY_ALLOWED_RUNNERS
        )
        resets_query = f"""
        SELECT split,
        {columns}
        FROM global_resets;
        """  # noqa: S608
        resets = self._db.query_db(query=resets_query)
        resets = resets.map(lambda x: float(x) if isinstance(x, Decimal) else x)
        return resets.replace({np.nan: ""})

    def query_weekday_data(self) -> DataFrame:
        weekday = self._db.query_db(query=ConstantQuery.WEEKDAY_DATA_QUERY)
        weekday = weekday.replace({np.nan: ""})

        ranges_to_process = [
            range(7, 14),
            range(21, 28),
            range(35, 42),
            range(49, 56),
            range(63, 70),
        ]
        for r in ranges_to_process:
            for i in r:
                weekday.iloc[i] = weekday.iloc[i].apply(get_hours_minutes_str)
        return weekday.drop(columns=["day", "col"])

    """
    SECONDARY QUERIES
    """

    def run(self, query: str, excel_name: str = "") -> DataFrame:
        """
        Execute query and optionally save to Excel.
        """
        result = self._db.query_db(query)
        if "date_started" in result.columns:
            result["date_started"] = pd.to_datetime(
                result["date_started"],
                errors="coerce",
            ).dt.strftime(Format.GOOD_DATE_FORMAT.value)
        if excel_name:
            result.to_excel(self._excel_dir / f"{excel_name}.xlsx", index=False)
        return result

    def export_table_names(self):
        table_names = self._db.query_db(ConstantQuery.ALL_TABLE_NAMES.value)
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

    def doorsplit_golds(self, version: int = 2, ties: bool = False) -> DataFrame:
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
        desc: bool = True,
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
