from typing import TYPE_CHECKING, Final, Literal, LiteralString

if TYPE_CHECKING:
    from db.order_by import OrderColumns, OrderType


TABLE_NAMES_QUERY: Final[LiteralString] = """
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
"""
PATTERN_NAMES_QUERY: Final[LiteralString] = """
SELECT SUBSTRING(pattern_name, 3) AS pattern
FROM cfg_rng_pattern_rules;
"""


def doorsplit_names(footer: Literal["Total", "PB"] | None = None) -> str:
    """
    Returns an SQL query that selects all the doorsplit names of the game
    and optionally adds a footer at the end of the list called either "Total" or "PB".
    """
    if not footer:
        return """
        SELECT split_name
        FROM cfg_default_split_names
        ORDER BY split_index;
        """

    return f"""
        SELECT split_name
        FROM
        (
            SELECT
                cfg.split_index,
                cfg.split_name
            FROM cfg_default_split_names cfg

            UNION

            SELECT 999, '{footer}'
        ) split_names
        ORDER BY split_names.split_index;
        """  # noqa: S608


def chapter_names(footer: Literal["Total", "PB"] | None = None) -> str:
    """
    Returns an SQL query that selects all the chapter names of the game
    and optionally adds a footer at the end of the list called either "Total" or "PB".
    """
    if not footer:
        return """
        SELECT chapter
        FROM cfg_chapter_area_splits_from_to
        ORDER BY chapter;
        """

    return f"""
        SELECT chapter
        FROM cfg_chapter_area_splits_from_to

        UNION

        SELECT '{footer}'
        ORDER BY chapter;
        """  # noqa: S608


def area_names(footer: Literal["Total", "PB"] | None = None) -> str:
    """
    Returns an SQL query that selects all the area names of the game
    and optionally adds a footer at the end of the list called either "Total" or "PB".
    """
    if not footer:
        return """
        SELECT area
        FROM cfg_splits_per_area
        ORDER BY sort;
        """

    return f"""
        SELECT area
        FROM
        (
            SELECT
                cfg.sort,
                cfg.area
            FROM cfg_splits_per_area cfg

            UNION

            SELECT 999, '{footer}'
        ) area_names
        ORDER BY area_names.sort;
        """  # noqa: S608


def doorsplit_golds_minimal() -> str:
    """
    Returns an SQL query that selects all the doorsplit golds of the
    runner.

    Tied golds are skipped.
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
            """  # noqa: E501


def chapter_golds_minimal() -> str:
    """
    Returns an SQL query that selects all the chapter golds of the
    runner.

    Tied golds are skipped.
    """
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
            """  # noqa: E501


def chapter_golds_by_doors_minimal() -> str:
    """
    Returns an SQL query that selects all the chapter golds of the
    runner but calculated adding the doorsplit golds of the chapter.

    Tied golds are skipped.
    """
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
            """  # noqa: E501


def area_golds_minimal() -> str:
    """
    Returns an SQL query that selects all the area golds of the
    runner.

    Tied golds are skipped.
    """
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
            """  # noqa: E501


def area_golds_by_chapters_minimal() -> str:
    """
    Returns an SQL query that selects all the area golds of the
    runner but calculated adding the chapter golds of the section.

    Tied golds are skipped.
    """
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
        """  # noqa: E501


def area_golds_by_doors_minimal() -> str:
    """
    Returns an SQL query that selects all the area golds of the
    runner but calculated adding the doorsplit golds of the section.

    Tied golds are skipped.
    """
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
            """  # noqa: E501


def best_paces_minimal() -> str:
    """
    Returns an SQL query that selects all the best paces of the
    runner.

    Only the pace at the end of each chapter is included.
    """
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


def pb_by_doors_minimal() -> str:
    """
    Returns an SQL query that selects all the doorsplit times obtained
    in the runner's PB.
    """
    return """
            SELECT
                {runner}
            FROM
            (
                SELECT
                    split_index,
                    lrt_time_fmt AS {runner}
                FROM
                (
                    SELECT DISTINCT
                        run_id,
                        split_index,
                        lrt_time_fmt
                    FROM splits_overview_{runner}
                    WHERE run_id = (SELECT MAX(run_id) FROM pb_history_{runner})
                    ORDER BY split_index
                ) a

                UNION

                SELECT
                    NULL,
                    LTRIM(TO_CHAR(lrt_pb::INTERVAL, 'HH24:MI:SS.FF3'), '0:') AS {runner}
                FROM pb_history_{runner}
                WHERE run_id = (SELECT MAX(run_id) FROM pb_history_{runner})
            )
            """


def pb_by_chapters_minimal() -> str:
    """
    Returns an SQL query that selects all the chapter times obtained
    in the runner's PB.
    """
    return """
            SELECT
                {runner}
            FROM
            (
                SELECT
                    chapter,
                    chapter_time_fmt AS {runner}
                FROM
                (
                    SELECT DISTINCT
                        run_id,
                        chapter,
                        chapter_time_fmt
                    FROM splits_overview_{runner}
                    WHERE run_id = (SELECT MAX(run_id) FROM pb_history_{runner})
                    ORDER BY chapter
                ) a

                UNION

                SELECT
                    NULL,
                    LTRIM(TO_CHAR(lrt_pb::INTERVAL, 'HH24:MI:SS.FF3'), '0:') AS {runner}
                FROM pb_history_{runner}
                WHERE run_id = (SELECT MAX(run_id) FROM pb_history_{runner})
            )
            """


def pb_by_areas_minimal() -> str:
    """
    Returns an SQL query that selects all the area times obtained
    in the runner's PB.
    """
    return """
            SELECT
                {runner}
            FROM
            (
                SELECT
                    area,
                    sort,
                    area_time_fmt AS {runner}
                FROM
                (
                    SELECT DISTINCT
                        so.run_id,
                        so.area,
                        so.area_time_fmt,
                        cfg.sort
                    FROM splits_overview_{runner} so

                    LEFT JOIN cfg_splits_per_area cfg
                    ON so.area = cfg.area

                    WHERE so.run_id = (SELECT MAX(run_id) from pb_history_{runner})
                ) a

                UNION

                SELECT
                    NULL,
                    NULL,
                    LTRIM(TO_CHAR(lrt_pb::INTERVAL, 'HH24:MI:SS.FF3'), '0:') AS {runner}
                FROM pb_history_{runner}
                WHERE run_id = (SELECT MAX(run_id) FROM pb_history_{runner})
                ORDER BY sort
            )
            """


def rng_patterns_percentages_minimal() -> str:
    """
    Returns an SQL query that selects all the RNG pattern percentages
    of the runner.
    """
    return """
            SELECT pattern_percentage AS {runner}
            FROM rng_patterns_stats_{runner};
            """


def rng_patterns_max_in_a_row_minimal() -> str:
    """
    Returns an SQL query that selects all the maximum instances in a row
    of each RNG pattern of the runner.
    """
    return """
            SELECT max_patterns_in_a_row AS {runner}
            FROM rng_patterns_stats_{runner};
            """


def resets_minimal() -> str:
    """
    Returns an SQL query that selects all the reset percentages for each
    split of the runner.
    """
    return """
            SELECT percentage_reset AS {runner}
            FROM resets2_{runner};
            """


def attempts_per_week(runner: str) -> str:
    """
    Returns an SQL query that selects the total number of attempts done
    for each week of the current year of the runner.
    """
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
        """  # noqa: E501, S608


def attempts_per_day_of_the_week(runner: str) -> str:
    """
    Returns an SQL query that selects the total number of attempts ever done
    for each day of the week.
    """
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
        """  # noqa: E501, S608


def attempts_per_day(runner: str) -> str:
    """
    Returns an SQL query that selects the total number of attempts ever done
    for each individual day that the runner did attempts.
    """
    return f"""
        SELECT
            TO_CHAR(date_started_at, 'DD/MM/YYYY') AS date_fmt,
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


def compare_runners_doorsplit_medians(runner1: str, runner2: str) -> str:
    """
    Returns an SQL query that selects the difference between the median time for
    each doorsplit of two runners.
    """
    return f"""
        SELECT
            runner1.split_index AS split_number,
            runner1.split_name,
            runner1.lrt_time_med_fmt AS {runner1}_ds_med,
            runner2.lrt_time_med_fmt AS {runner2}_ds_med,
            ROUND(EXTRACT(EPOCH FROM (runner1.lrt_time_med - runner2.lrt_time_med))::NUMERIC, 3) AS difference
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
        """  # noqa: E501, S608


def compare_runners_doorsplit_golds(runner1: str, runner2: str) -> str:
    """
    Returns an SQL query that selects the difference between the gold time for
    each doorsplit of two runners.
    """
    return f"""
        SELECT
            runner1.split_index AS split_number,
            runner1.split_name,
            runner1.lrt_time_fmt AS {runner1}_ds_gold,
            runner2.lrt_time_fmt AS {runner2}_ds_gold,
            ROUND(EXTRACT(EPOCH FROM (runner1.lrt_time - runner2.lrt_time))::NUMERIC, 3) AS difference
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
        """  # noqa: E501, S608


def doorsplit_history(
    runner: str,
    order_by: "OrderColumns",
    order_type: "OrderType",
) -> str:
    """
    Returns an SQL query that selects the entire doorsplit history of a specific
    split of the runner.
    """
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


def doorsplits_of_chapter_golds(runner: str, extra_condition: str) -> str:
    """
    Returns an SQL query that selects the doorsplit times that make up one
    or all chapter golds of the runner.

    The extra condition can be used to filter by a specific chapter or
    to show all chapters if it's empty.
    """
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


def pb_summary(runner: str) -> str:
    """
    Returns an SQL query that selects the main relevant stats of the runner's PB
    to get a sense of how the run went.
    """
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


def doorsplit_golds(runner: str, extra_condition: str) -> str:
    """
    Returns an SQL query that selects all the doorsplit golds of the runner
    with relevant data of each one.

    Tied golds can be skipped or included.
    """
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


def chapter_golds(runner: str, extra_condition: str) -> str:
    """
    Returns an SQL query that selects all the chapter golds of the runner
    with relevant data of each one.

    Tied golds can be skipped or included.
    """
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


def area_golds(runner: str, extra_condition: str) -> str:
    """
    Returns an SQL query that selects all the area golds of the runner
    with relevant data of each one.

    Tied golds can be skipped or included.
    """
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


def general_stats(runner: str) -> str:
    """
    Returns an SQL query that selects all the basic stats of the runner
    which includes the last time they updated their splits, their PB,
    their total attempts and their total playtime.
    """
    return f"""
        SELECT
            last_update,
            pb,
            attempts,
            total_playtime
        FROM general_stats_{runner};
        """  # noqa: S608


def weekday_data(runner: str) -> str:
    """
    Returns an SQL query that selects all the stats related to how
    the runner performs on each of the seven days of the week.
    """
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
