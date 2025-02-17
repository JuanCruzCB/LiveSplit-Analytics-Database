import psycopg2
from pandas import DataFrame

from decorators import measure_time

GLOBAL_DOORSPLIT_GOLDS_QUERY = """
select *
from global_door_golds;
"""

GLOBAL_CHAPTER_GOLDS_QUERY = """
select chapter, sawken, luis, joker, mateo, arcadan, richy, derek, best, best_cumulative_chapters
from global_chapter_golds
where chapter like '%-%' or chapter='Total';
"""

GLOBAL_CHAPTER_GOLDS_BY_DOORS_QUERY = """
select chapter, sawken, luis, joker, mateo, arcadan, richy, derek, best, cumulative_best
from global_chapter_golds_doors;
"""

GLOBAL_SECTION_GOLDS_QUERY = """
select section, sawken, luis, joker, mateo, arcadan, richy, derek, best, best_cumulative_sections
from global_section_golds;
"""


GLOBAL_SECTION_GOLDS_BY_CHAPTERS_QUERY = """
select section, sawken, luis, joker, mateo, arcadan, richy, derek, best, cumulative_best
from global_section_golds_chapters;
"""

GLOBAL_SECTION_GOLDS_BY_DOORS_QUERY = """
select section, sawken, luis, joker, mateo, arcadan, richy, derek, best, cumulative_best
from global_section_golds_doors;
"""

GLOBAL_BEST_PACES_QUERY = """
select *
from global_best_paces_chapter;
"""

GLOBAL_RNG_PATTERNS_QUERY = """
select *
from global_rng_patterns;
"""

GENERAL_STATS_QUERY = """
select chapter, sawken, luis, joker, mateo, arcadan, richy, derek
from global_chapter_golds
where chapter not like '%-%' and chapter<>'Total';
"""

RESETS_QUERY = """
select split, case when percent_sawken<0 then 0 else percent_sawken end as percent_sawken,
case when percent_luis<0 then 0 else percent_luis end as percent_luis,
case when percent_joker<0 then 0 else percent_joker end as percent_joker,
case when percent_mateo<0 then 0 else percent_mateo end as percent_mateo,
case when percent_arcadan<0 then 0 else percent_arcadan end as percent_arcadan,
case when percent_richy<0 then 0 else percent_richy end as percent_richy,
case when percent_derek<0 then 0 else percent_derek end as percent_derek
from global_resets;
"""


DB_CONFIG = {
    "dbname": "postgres",
    "user": "postgres",
    "host": "localhost",
    "password": 123,
    "port": 5432,
}

RUNNERS_SQL_SCRIPT_PATH = r"H:\Juan\4. Speedrunning\RE4 Steam\script ng pro steam.sql"
GLOBAL_SQL_SCRIPT_PATH = r"H:\Juan\4. Speedrunning\RE4 Steam\global ng pro steam.sql"


@measure_time
def update_runners_tables(files: list[dict[str, str]]) -> None:
    try:
        with psycopg2.connect(**DB_CONFIG) as connection:
            with connection.cursor() as cursor:
                for file in files:
                    # TODO: remove this later

                    # Load the contents of the original .sql script into a variable (the original one
                    # always has the formatting for sawken splits specifically)
                    with open(file=RUNNERS_SQL_SCRIPT_PATH, mode="r") as f:
                        sql_script = f.read()

                    if "splits" in file["name"]:
                        sql_script = sql_script.replace(
                            "sawken", file["runner"]
                        ).replace(
                            r"2024 LRT\1. NG Pro", rf"2024 LRT\Not mine\{file['name']}"
                        )

                    cursor.execute(sql_script)
                    print(
                        f"Updated the database tables for {file['runner']} succesfully!"
                    )

    except psycopg2.Error as e:
        print(f"Database error: {e}")
        raise e

    print()


@measure_time
def update_global_tables() -> None:
    try:
        with psycopg2.connect(**DB_CONFIG) as connection:
            with connection.cursor() as cursor:
                with open(file=GLOBAL_SQL_SCRIPT_PATH, mode="r") as f:
                    sql_script = f.read()
                cursor.execute(sql_script)
                print("Updated the database global tables succesfully!")

    except psycopg2.Error as e:
        print(f"Database error: {e}")
        raise e


def query_db(query: str) -> DataFrame:
    try:
        with psycopg2.connect(**DB_CONFIG) as connection:
            with connection.cursor() as cursor:
                cursor.execute(query)
                df = DataFrame(
                    data=cursor.fetchall(),
                    columns=[desc[0] for desc in cursor.description],
                )
                return df
    except psycopg2.Error as e:
        print(f"Database error: {e}")
        raise e


@measure_time
def query_doorsplit_golds() -> DataFrame:
    return query_db(query=GLOBAL_DOORSPLIT_GOLDS_QUERY)


@measure_time
def query_chapter_golds() -> DataFrame:
    return query_db(query=GLOBAL_CHAPTER_GOLDS_QUERY)


@measure_time
def query_chapter_golds_by_doors() -> DataFrame:
    return query_db(query=GLOBAL_CHAPTER_GOLDS_BY_DOORS_QUERY)


@measure_time
def query_section_golds() -> DataFrame:
    return query_db(query=GLOBAL_SECTION_GOLDS_QUERY)


@measure_time
def query_section_golds_by_chapters() -> DataFrame:
    return query_db(query=GLOBAL_SECTION_GOLDS_BY_CHAPTERS_QUERY)


@measure_time
def query_section_golds_by_doors() -> DataFrame:
    return query_db(query=GLOBAL_SECTION_GOLDS_BY_DOORS_QUERY)


@measure_time
def query_best_paces() -> DataFrame:
    return query_db(query=GLOBAL_BEST_PACES_QUERY)


@measure_time
def query_rng_patterns() -> DataFrame:
    return query_db(query=GLOBAL_RNG_PATTERNS_QUERY)


@measure_time
def query_general_stats() -> DataFrame:
    return query_db(query=GENERAL_STATS_QUERY)


@measure_time
def query_resets() -> DataFrame:
    return query_db(query=RESETS_QUERY)
