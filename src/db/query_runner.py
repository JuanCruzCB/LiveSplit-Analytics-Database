from datetime import datetime
from enum import StrEnum
from pathlib import Path

import pandas as pd
from pandas import DataFrame

from db.database_manager import DatabaseManager
from db.utils import (
    add_best_and_cumulative_best_columns,
    calculate_best_time,
    format_time,
    parse_time,
)


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

    def update_runners_tables(self, splits: dict[Path, datetime]) -> bool:
        return self._db.update_runners_tables(splits=splits)

    def _get_golds(
        self,
        division_type_query: str,
        golds_query: str,
        *,
        add_best_and_cumulative: bool = True,
    ) -> DataFrame:
        division_names = self._db.execute(division_type_query)
        division_names.loc[len(division_names)] = "Total"

        dfs = []
        dfs.append(division_names)
        for runner in self._allowed_runners:
            runner_golds = self._db.execute(golds_query.format(runner=runner))

            runner_golds["Times in seconds"] = runner_golds[runner].map(parse_time)
            sum_of_best = format_time(runner_golds["Times in seconds"].sum())
            runner_golds.loc[len(runner_golds)] = sum_of_best
            runner_golds = runner_golds.drop(columns=["Times in seconds"])

            dfs.append(runner_golds)

        overall_df = pd.concat(dfs, axis=1)
        overall_df.columns = overall_df.columns.str.capitalize()
        if add_best_and_cumulative:
            overall_df = add_best_and_cumulative_best_columns(overall_df)

        return overall_df

    def get_runners_doorsplit_golds(self) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the doorsplit golds of that runner.
        The last row contains the doorsplits sum of best of that runner.
        """
        return self._get_golds(
            division_type_query=f"""
            SELECT split
            FROM default_split_names_{self._main_runner};
            """,  # noqa: S608
            golds_query="""
            SELECT gold2 AS {runner}
            FROM (
                SELECT DISTINCT cle2, gold2
                FROM doorsplits_golds_{runner}
                ORDER BY cle2
            );
            """,
            add_best_and_cumulative=False,
        )

    def get_runners_chapter_golds(self) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the chapter golds of that runner.
        The last row contains the chapter sum of best of that runner.

        In addition, there's a column with the best chapter gold for each
        chapter, and a column with the cumulative best chapters.
        """
        return self._get_golds(
            division_type_query=f"""
            SELECT DISTINCT chapter
            FROM split_name_info3_{self._main_runner}
            ORDER BY chapter
            """,  # noqa: S608
            golds_query="""
            SELECT chapter_gold2 AS {runner}
            FROM (
                SELECT DISTINCT chapter, chapter_gold2
                FROM chapter_golds2_{runner}
                ORDER BY chapter
            );
            """,
        )

    def get_runners_chapter_golds_by_doors(self) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the chapter golds by adding up all
        the doorsplit golds of that chapter of that runner.
        The last row contains the doorsplits sum of best of that runner.

        In addition, there's a column with the best chapter gold for each
        chapter, and a column with the cumulative best chapters.
        """
        return self._get_golds(
            division_type_query=f"""
            SELECT DISTINCT chapter
            FROM split_name_info3_{self._main_runner}
            ORDER BY chapter
            """,  # noqa: S608
            golds_query="""
            SELECT doorsplit_combined_gold AS {runner}
            FROM (
                SELECT DISTINCT chapter, doorsplit_combined_gold
                FROM chapter_golds_sheet_{runner}
                ORDER BY chapter
            );
            """,
        )

    def get_runners_section_golds(self) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the section golds of that runner.
        The last row contains the section sum of best of that runner.

        In addition, there's a column with the best section gold for each
        section, and a column with the cumulative best sections.
        """
        return self._get_golds(
            division_type_query=f"""
            SELECT section
            FROM section_splits_{self._main_runner};
            """,  # noqa: S608
            golds_query="""
            SELECT section_gold2 AS {runner}
            FROM (
                SELECT DISTINCT
                    section,
                    section_gold2,
                    CASE
                        WHEN section = 'Village' THEN 1
                        WHEN section = 'Castle' THEN 2
                        ELSE 3 END AS index
                FROM section_golds3_{runner}
            )
            ORDER BY index;
            """,
        )

    def get_runners_section_golds_by_chapters(self) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the section golds by adding up all
        the chapter golds of that section of that runner.
        The last row contains the chapter sum of best of that runner.

        In addition, there's a column with the best section gold for each
        section, and a column with the cumulative best sections.
        """
        return self._get_golds(
            division_type_query=f"""
            SELECT section
            FROM section_splits_{self._main_runner};
            """,  # noqa: S608
            golds_query="""
            SELECT chapter_combined_gold AS {runner}
            FROM (
                SELECT DISTINCT
                    section,
                    chapter_combined_gold,
                    CASE
                        WHEN section = 'Village' THEN 1
                        WHEN section = 'Castle' THEN 2
                        ELSE 3 END AS index
                FROM section_golds_sheet_{runner}
            )
            ORDER BY index;
            """,
        )

    def get_runners_section_golds_by_doors(self) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the section golds by adding up all
        the doorsplit golds of that section of that runner.
        The last row contains the doorsplits sum of best of that runner.

        In addition, there's a column with the best section gold for each
        section, and a column with the cumulative best sections.
        """
        return self._get_golds(
            division_type_query=f"""
            SELECT section
            FROM section_splits_{self._main_runner};
            """,  # noqa: S608
            golds_query="""
            SELECT doorsplit_combined_gold AS {runner}
            FROM (
                SELECT DISTINCT
                    section,
                    doorsplit_combined_gold,
                    CASE
                        WHEN section = 'Village' THEN 1
                        WHEN section = 'Castle' THEN 2
                        ELSE 3 END AS index
                FROM section_golds_sheet_{runner}
            )
            ORDER BY index;
            """,
        )

    def get_runners_best_paces(self) -> DataFrame:
        """
        Returns a DataFrame where the first row is the name of all runners
        and each column contains all the best paces of that runner per chapter.

        In addition, there's a column with the overall best pace for each
        chapter.
        """
        chapter_names = self._db.execute(
            query=f"""
            SELECT DISTINCT chapter
            FROM split_name_info3_{self._main_runner}
            ORDER BY chapter
            """  # noqa: S608
        )

        dfs = []
        dfs.append(chapter_names)
        for runner in self._allowed_runners:
            runners_best_paces = self._db.execute(
                query=f"""
                SELECT best_pace2 AS {runner}
                FROM (
                    SELECT DISTINCT cle2, split, best_pace2
                    FROM best_paces_{runner}
                    WHERE split LIKE '%{{%'
                    ORDER BY cle2
                );
                """  # noqa: S608
            )
            dfs.append(runners_best_paces)

        overall_df = pd.concat(dfs, axis=1)
        overall_df["Best"] = overall_df.apply(
            lambda row: calculate_best_time(row[1:]),
            axis=1,
        )
        overall_df.columns = overall_df.columns.str.capitalize()
        return overall_df

    def get_runners_rng_patterns(self) -> DataFrame:
        """
        Returns a DataFrame where, for each runner, contains the
        percentage of different RNG patterns that runner has gotten overall
        and also the maximum amount of times in a row they've gotten each pattern.
        """
        pattern_names = self._db.execute(
            query=f"""
            SELECT pattern2 as pattern
            FROM rng_splits_{self._main_runner}
            """  # noqa: S608
        )

        dfs = []
        dfs.append(pattern_names)
        for runner in self._allowed_runners:
            runners_percentages = self._db.execute(
                query=f"""
                SELECT percentage AS {runner}
                FROM (
                    SELECT
                        t1.pattern,
                        COALESCE(t2.percentage, 0) AS percentage
                    FROM rng t1
                    LEFT JOIN rng_splits_{runner} t2
                        ON t1.pattern = t2.pattern
                    ORDER BY pattern
                );
                """  # noqa: S608
            )
            dfs.append(runners_percentages)

        for runner in self._allowed_runners:
            runners_max_in_a_row = self._db.execute(
                query=f"""
                SELECT max AS {runner}
                FROM (
                    SELECT
                        t1.pattern,
                        COALESCE(t2.maximum_consecutive_patterns, 0) AS max
                    FROM rng t1
                    LEFT JOIN consecutive_patterns_{runner} t2
                        ON t1.pattern = t2.lago_pattern
                    ORDER BY pattern
                );
                """  # noqa: S608
            )
            dfs.append(runners_max_in_a_row)

        overall_df = pd.concat(dfs, axis=1)
        overall_df.columns = overall_df.columns.str.capitalize()
        return overall_df

    def get_runners_general_stats(self) -> DataFrame:
        """
        Returns a DataFrame with simple stats for each runner:
        1) The last time they've updated their splits (as in, ran the game).
        2) Their PB.
        3) Their total number of attempts or resets.
        4) Their total playtime, in days and hours.
        """
        dfs = []
        dfs.append(
            DataFrame({"Stat": ["Last update", "PB", "Attempts", "Total playtime"]})
        )
        wrong_attempt_counts = {"sawken": 84, "richy": 3912, "otaku": 4779}
        for runner in self._allowed_runners:
            runner_stats = self._db.execute(
                query=f"""
                SELECT stats AS {runner}
                FROM (
                    SELECT CAST(MAX(date_started) AS VARCHAR) AS stats, 1 AS sort_key
                    FROM attempts_treatment3_{runner}

                    UNION

                    (SELECT final_lrt, 2 AS sort_key
                    FROM pb_history_{runner}
                    ORDER BY id DESC
                    LIMIT 1)

                    UNION

                    SELECT CAST((MAX(id) - {wrong_attempt_counts.get(runner, 0)})AS VARCHAR) AS {runner}, 3 AS sort_key
                    FROM attempts_treatment3_{runner}

                    UNION

                    SELECT CAST(SUM(playtime) AS VARCHAR) AS playtime, 4 AS sort_key
                    FROM attempts_treatment3_{runner}

                    ORDER BY sort_key
                );
                """  # noqa: S608
            )
            dfs.append(runner_stats)

        overall_df = pd.concat(dfs, axis=1)
        overall_df.columns = overall_df.columns.str.capitalize()
        return overall_df

    def get_runners_resets(self) -> DataFrame:
        """
        Returns a DataFrame with the percentage of resets for each runner, for
        all doorsplits. As in, what percentage of the runs that get to that split
        end up with the runner resetting on that split.
        """
        split_names = self._db.execute(
            query=f"""
            SELECT split
            FROM default_split_names_{self._main_runner};
            """  # noqa: S608
        )

        dfs = []
        dfs.append(split_names)
        for runner in self._allowed_runners:
            runner_resets = self._db.execute(
                query=f"""
                SELECT percentage_resets AS {runner}
                FROM resets_history2_{runner}
                """  # noqa: S608
            )
            runner_resets = runner_resets.map(lambda percent: max(percent, 0))
            dfs.append(runner_resets)

        overall_df = pd.concat(dfs, axis=1)
        overall_df.columns = overall_df.columns.str.capitalize()
        return overall_df

    def get_runners_weekday_data(self) -> DataFrame:
        """
        Returns a DataFrame with many different stats related to how
        the runner performs on different days of the week.
        """
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
            "Attempts to get a section gold",
            "Playtime to get a section gold",
            "Attempts to get a best pace",
            "Playtime to get a best pace",
        ]
        repeated_stats = []
        for stat in stat_types:
            repeated_stats.extend([stat] * 7)

        dfs = []
        dfs.append(
            DataFrame(
                {
                    "Day": weekdays * len(stat_types),
                    "Stat type": repeated_stats,
                }
            )
        )
        for runner in self._allowed_runners:
            runner_weekday = self._db.execute(
                query=f"""
                SELECT attempts_to_get_a_pb AS {runner}
                FROM (
                    SELECT weekday, attempts_to_get_a_pb, 1 AS sort_key
                    FROM weekday_data_{runner}

                    UNION

                    SELECT weekday, playtime_to_get_a_pb, 2 AS sort_key
                    FROM weekday_data_{runner}

                    UNION

                    SELECT weekday, attempts_to_get_a_gold, 3 AS sort_key
                    FROM weekday_data_{runner}

                    UNION

                    SELECT weekday, playtime_to_get_a_gold, 4 AS sort_key
                    FROM weekday_data_{runner}

                    UNION

                    SELECT weekday, attempts_to_get_a_chapter_gold, 5 AS sort_key
                    FROM weekday_data_{runner}

                    UNION

                    SELECT weekday, playtime_to_get_a_chapter_gold, 6 AS sort_key
                    FROM weekday_data_{runner}

                    UNION

                    SELECT weekday, attempts_to_get_a_section_gold, 7 AS sort_key
                    FROM weekday_data_{runner}

                    UNION

                    SELECT weekday, playtime_to_get_a_section_gold, 8 AS sort_key
                    FROM weekday_data_{runner}

                    UNION

                    SELECT weekday, attempts_to_get_a_best_pace, 9 AS sort_key
                    FROM weekday_data_{runner}

                    UNION

                    SELECT weekday, playtime_to_get_a_best_pace, 10 AS sort_key
                    FROM weekday_data_{runner}

                    ORDER BY sort_key, weekday
                );
                """  # noqa: S608
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
        params: dict[str, str | int] | None = None,
        excel_name: str = "",
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
        relevant_tables = self._db.execute("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
                AND table_name NOT LIKE '%treatment%'
                AND table_name NOT LIKE '%cleaned%'
                AND table_name NOT LIKE '%info%'
                AND table_name NOT LIKE '%notepad%'
            ORDER BY table_name;
        """)
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
                FROM doorsplits_golds2_{self._main_runner} AS ds_golds
                INNER JOIN default_split_names_{self._main_runner} AS split_names on ds_golds.cle2 = split_names.cle2
                ORDER BY cle2
                """,  # noqa: S608
                excel_name=f"{self._main_runner}_doorsplit_golds_v1",
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
                        FROM splits_overview_{self._main_runner}) aa) a
                        WHERE rang = 1
                    )
                    WHERE tied_gold <= (SELECT tied FROM tied_golds2)
            ORDER BY cle2, id;
            """,  # noqa: S608
            params={"ties": int(ties)},
            excel_name=f"{self._main_runner}_doorsplits_golds_v2_with_ties"
            if ties
            else f"{self._main_runner}_doorsplits_golds_v2_without_ties",
        )

    def chapter_golds(self, version: int = 2) -> DataFrame:
        """
        Get chapter golds (version 1 or 2).
        """
        if version == 1:
            return self.execute(
                query=f"""
                SELECT chapter, chapter_gold2, date_started
                FROM chapter_golds2_{self._main_runner}
                """,  # noqa: S608
                excel_name=f"{self._main_runner}_chapter_golds_v1",
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
                FROM splits_overview_{self._main_runner}
                WHERE chapter_time2=chapter_gold2
                ORDER BY chapter, id
            ) a
            WHERE rang = 1
            ORDER BY chapter, id;
            """,  # noqa: S608
            excel_name=f"{self._main_runner}_chapter_golds_v2",
        )

    def section_golds(self, version: int = 2) -> DataFrame:
        """
        Get section golds (version 1 or 2).
        """
        if version == 1:
            return self.execute(
                query=f"""
                SELECT section, section_gold2, date_started
                FROM section_golds3_{self._main_runner}
                """,  # noqa: S608
                excel_name=f"{self._main_runner}_section_golds_v1",
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
                FROM splits_overview_{self._main_runner}
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
            excel_name=f"{self._main_runner}_section_golds_v2",
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
            FROM splits_overview_{self._main_runner}
            WHERE id IN (SELECT max(id) FROM pb_history_{self._main_runner})
            ORDER BY cle2;
            """,  # noqa: S608
            excel_name=f"{self._main_runner}_doorsplits_pb_analysis",
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
            FROM splits_overview_{self._main_runner}
            WHERE id IN (SELECT max(id) FROM pb_history_{self._main_runner})
            ORDER BY chapter;
            """,  # noqa: S608
            excel_name=f"{self._main_runner}_chapter_pb_analysis",
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
            FROM splits_overview_{self._main_runner}
            WHERE id IN (SELECT max(id) FROM pb_history_{self._main_runner})
            ORDER BY
                CASE
                    WHEN section = 'Village' THEN 1
                    WHEN section = 'Castle' THEN 2
                    ELSE 3
                END;
            """,  # noqa: S608
            excel_name=f"{self._main_runner}_section_pb_analysis",
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
            FROM splits_overview_{self._main_runner}
            WHERE id IN (SELECT max(id) FROM pb_history_{self._main_runner})
            ORDER BY cle2;
            """,  # noqa: S608
            excel_name=f"{self._main_runner}_best_paces_pb_analysis",
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
            FROM splits_overview_{self._main_runner}
            WHERE id IN (SELECT max(id) FROM pb_history_{self._main_runner})
            AND split LIKE '%{{%'
            ORDER BY cle2;
            """,  # noqa: S608
            excel_name=f"{self._main_runner}_best_paces_eoc_pb_analysis",
        )

    def doorsplits_of_chapter_gold(self, chapter: str) -> DataFrame:
        """
        Get all doorsplits that make up a chapter gold.
        """
        return self.execute(
            query=f"""
            SELECT cle2, split, chapter, lrt_split, gold2, chapter_gold2, date_started
            FROM splits_overview_{self._main_runner}
            WHERE chapter = %(chapter)s AND chapter_time = chapter_gold
            ORDER BY cle2;
            """,  # noqa: S608
            params={"chapter": chapter},
            excel_name=f"{self._main_runner}_chapter_{chapter.replace('-', '_')}_components",
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
            FROM splits_overview_{self._main_runner}
            WHERE split = %(split_name)s
            ORDER BY {order_by.value}
            {"DESC" if desc else ""};
            """,  # noqa: S608
            params={"split_name": split_name},
            excel_name=f"{self._main_runner}_{split_name_formatted}_history",
        )

    def compare_runners_doorsplit_golds(self, other_runner: str) -> DataFrame:
        return self.execute(
            query=f"""
            SELECT
            runner1.cle2 AS split_number,
            runner1.gold AS {self._main_runner}_door_gold,
            runner2.gold AS {other_runner}_door_gold,
            runner1.gold2 AS {self._main_runner}_door_gold2,
            runner2.gold2 AS {other_runner}_door_gold2,
            runner1.gold - runner2.gold AS difference
            FROM
                (SELECT DISTINCT cle2, gold, gold2 FROM doorsplits_golds2_{self._main_runner}) runner1
            FULL JOIN
                (SELECT DISTINCT cle2, gold, gold2 FROM doorsplits_golds2_{other_runner}) runner2
            ON runner1.cle2 = runner2.cle2
            ORDER BY runner1.cle2;
            """,  # noqa: S608
            excel_name=f"doorsplit_golds_comparison_{self._main_runner}_vs_{other_runner}",
        )

    def compare_runners_doorsplit_medians(self, other_runner: str) -> DataFrame:
        return self.execute(
            query=f"""
            SELECT
            runner1.cle2 AS split_number,
            runner1.door_median AS {self._main_runner}_door_median,
            runner2.door_median AS {other_runner}_door_median,
            runner1.door_median2 AS {self._main_runner}_door_median2,
            runner2.door_median2 AS {other_runner}_door_median2,
            runner1.door_median - runner2.door_median AS difference
            FROM
            (SELECT DISTINCT cle2, door_median, door_median2 FROM doorsplits_golds2_{self._main_runner}) runner1
            FULL JOIN
            (SELECT DISTINCT cle2, door_median, door_median2 FROM doorsplits_golds2_{other_runner}) runner2
            ON runner1.cle2 = runner2.cle2
            ORDER BY runner1.cle2;
            """,  # noqa: S608
            excel_name=f"doorsplit_medians_comparison_{self._main_runner}_vs_{other_runner}",
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
            LEFT JOIN attempts_treatment3_{self._main_runner} b on a.date = b.date_started
            WHERE EXTRACT(year from date) = EXTRACT(year from current_date) AND date <= current_date
            GROUP BY 1
            ORDER BY 1;
            """,  # noqa: S608
            excel_name=f"attempts_per_week_{self._main_runner}",
        )
