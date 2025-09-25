from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from db.query_runner import OrderColumns, OrderType


class QueryBuilder:
    DOORSPLIT_NAMES_QUERY_WITH_TOTAL = """
    SELECT split_name
    FROM
    (
        SELECT
            cfg.split_index,
            cfg.split_name
        FROM cfg_default_split_names cfg

        UNION

        SELECT 999, 'Total'
    ) split_names
    ORDER BY split_names.split_index;
    """
    DOORSPLIT_NAMES_QUERY = """
    SELECT split_name
    FROM cfg_default_split_names
    ORDER BY split_index;
    """
    CHAPTER_NAMES_QUERY_WITH_TOTAL = """
    SELECT chapter
    FROM cfg_chapter_area_splits_from_to

    UNION

    SELECT 'Total'
    ORDER BY chapter;
    """
    CHAPTER_NAMES_QUERY = """
    SELECT chapter
    FROM cfg_chapter_area_splits_from_to;
    """
    AREA_NAMES_QUERY = """
    SELECT area
    FROM
    (
        SELECT
            cfg.sort,
            cfg.area
        FROM cfg_splits_per_area cfg

        UNION

        SELECT 999, 'Total'
    ) area_names
    ORDER BY area_names.sort;
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

    def __init__(self) -> None:
        pass

    def doorsplit_golds_minimal(self) -> str:
        """
        Returns an SQL query that fetches all the doorsplit golds of the
        runner without ties.
        """
        return """
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
                """

    def chapter_golds_minimal(self) -> str:
        return """
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
                """

    def chapter_golds_by_doors_minimal(self) -> str:
        return """
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
                """

    def area_golds_minimal(self) -> str:
        return """
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
                """

    def area_golds_by_chapters_minimal(self) -> str:
        return """
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
            """

    def area_golds_by_doors_minimal(self) -> str:
        return """
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
                """

    def best_paces_minimal(self) -> str:
        return """
                SELECT
                    lrt_pace_fmt AS {runner}
                FROM
                (
                    SELECT DISTINCT
                        split_index,
                        split_name,
                        lrt_pace_fmt
                    FROM paces_best_{runner}
                    WHERE split_name LIKE '%{{%'
                    ORDER BY split_index
                );
                """

    def rng_patterns_percentages_minimal(self) -> str:
        return """
                SELECT pattern_percentage AS {runner}
                FROM rng_patterns_stats_{runner};
                """

    def rng_patterns_max_in_a_row_minimal(self) -> str:
        return """
                SELECT max_patterns_in_a_row AS {runner}
                FROM rng_patterns_stats_{runner};
                """

    def resets_minimal(self) -> str:
        return """
                SELECT percentage_reset AS {runner}
                FROM resets2_{runner};
                """

    def attempts_per_week(self, runner: str) -> str:
        return f"""
            SELECT
                EXTRACT(ISOYEAR FROM dt) AS year_num,
                EXTRACT(WEEK FROM dt) AS week_num,
                TO_CHAR(DATE_TRUNC('WEEK', dt)::DATE, 'DD/MM/YYYY') AS week_start,
                TO_CHAR((DATE_TRUNC('WEEK', dt) + INTERVAL '6 days')::DATE, 'DD/MM/YYYY') AS week_end,
                COUNT(DISTINCT run_id) AS total_attempts
            FROM cfg_dates cfg

            LEFT JOIN attempts_data5_{runner} att
            ON cfg.dt = DATE(att.run_started_at)
            WHERE EXTRACT(ISOYEAR FROM dt) = EXTRACT(ISOYEAR FROM CURRENT_DATE) AND dt <= CURRENT_DATE
            GROUP BY
                year_num,
                week_num,
                week_start,
                week_end
            ORDER BY week_num;
            """  # noqa: S608

    def attempts_per_day_of_the_week(self, runner: str) -> str:
        return f"""
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
                    FROM attempts_data5_{runner}
                    GROUP BY DATE(run_started_at)
                )
                ORDER BY date_started_at
            )
            GROUP BY iso_weekday
            ORDER BY iso_weekday;
            """  # noqa: S608

    def attempts_per_day(self, runner: str) -> str:
        return f"""
            SELECT
                TO_CHAR(date_started_at, 'DD/MM/YYYY'),
                EXTRACT(ISODOW FROM date_started_at) AS iso_weekday,
                attempts_on_date
            FROM
            (
                SELECT
                    DATE(run_started_at) AS date_started_at,
                    COUNT(*) AS attempts_on_date
                FROM attempts_data5_{runner}
                GROUP BY DATE(run_started_at)
            )
            ORDER BY date_started_at;"""  # noqa: S608

    def compare_runners_doorsplit_medians(self, runner1: str, runner2: str) -> str:
        return f"""
            SELECT
                runner1.split_index AS split_number,
                runner1.split_name,
                runner1.lrt_time_med_fmt AS {runner1}_ds_med,
                runner2.lrt_time_med_fmt AS {runner2}_ds_med,
                (runner1.lrt_time_med - runner2.lrt_time_med)::TEXT AS difference
            FROM
            (
                SELECT
                    split_index,
                    split_name,
                    lrt_time_med,
                    lrt_time_med_fmt
                FROM doorsplits_avg_med_{runner1}
            ) runner1

            FULL JOIN
            (
                SELECT
                    split_index,
                    split_name,
                    lrt_time_med,
                    lrt_time_med_fmt
                FROM doorsplits_avg_med_{runner2}
            ) runner2
            ON runner1.split_index = runner2.split_index
            ORDER BY runner1.split_index;
            """  # noqa: S608

    def compare_runners_doorsplit_golds(self, runner1: str, runner2: str) -> str:
        return f"""
            SELECT
                runner1.split_index AS split_number,
                runner1.split_name,
                runner1.lrt_time_fmt AS {runner1}_ds_gold,
                runner2.lrt_time_fmt AS {runner2}_ds_gold,
                (runner1.lrt_time - runner2.lrt_time)::TEXT AS difference
            FROM
            (
                SELECT DISTINCT
                    split_index,
                    split_name,
                    lrt_time,
                    lrt_time_fmt
                FROM doorsplit_golds2_{runner1}
            ) runner1

            FULL JOIN
            (
                SELECT DISTINCT
                    split_index,
                    split_name,
                    lrt_time,
                    lrt_time_fmt
                FROM doorsplit_golds2_{runner2}
            ) runner2
            ON runner1.split_index = runner2.split_index
            ORDER BY runner1.split_index;
            """  # noqa: S608

    def doorsplit_history(
        self,
        runner: str,
        order_by: "OrderColumns",
        order_type: "OrderType",
    ) -> str:
        return f"""
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
            FROM splits_overview_{runner}
            WHERE split_name = %(split_name)s
            ORDER BY {order_by.value} {order_type.value};
            """  # noqa: S608

    def doorsplits_of_chapter_golds(self, runner: str, extra_condition: str) -> str:
        return f"""
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
            FROM splits_overview_{runner}
            WHERE chapter_time = chapter_gold {extra_condition}
            ORDER BY split_index;
            """  # noqa: S608

    def pb_summary(self, runner: str) -> str:
        return f"""
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
            FROM splits_overview_{runner}
            WHERE run_id = (SELECT MAX(run_id) FROM pb_history_{runner})
            ORDER BY split_index;
            """  # noqa: S608

    def doorsplit_golds(self, runner: str, extra_condition: str) -> str:
        return f"""
            SELECT
                run_id,
                split_index,
                split_name,
                lrt_time_fmt AS gold,
                split_started_at,
                split_ended_at,
                run_started_at,
                run_ended_at
            FROM doorsplit_golds2_{runner}
            {extra_condition};
            """  # noqa: S608

    def chapter_golds(self, runner: str, extra_condition: str) -> str:
        return f"""
            SELECT
                run_id,
                chapter,
                chapter_time_fmt AS gold,
                chapter_started_at,
                chapter_ended_at,
                run_started_at,
                run_ended_at
            FROM chapter_golds2_{runner}
            {extra_condition};
            """  # noqa: S608

    def area_golds(self, runner: str, extra_condition: str) -> str:
        return f"""
            SELECT
                run_id,
                area,
                area_time_fmt AS gold,
                area_started_at,
                area_ended_at,
                run_started_at,
                run_ended_at
            FROM area_golds2_{runner}
            {extra_condition};
            """  # noqa: S608

    def general_stats(self, runner: str) -> str:
        return f"""
            SELECT
                last_update,
                pb,
                attempts,
                total_playtime
            FROM general_stats_{runner};
            """  # noqa: S608

    def weekday_data(self, runner: str) -> str:
        return f"""
            SELECT attempts_to_get_a_pb AS {runner}
            FROM
            (
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
