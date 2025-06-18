from datetime import timedelta
from enum import Enum, StrEnum
from pathlib import Path


class Files(Enum):
    MY_SPLITS_FILE = Path(
        r"H:\Juan\4. Speedrunning\LiveSplit\Splits\RE4 Steam\2024 LRT\1. NG Pro.lss"
    )
    GOOGLE_SERVICE_ACCOUNT_SECRETS_FILE = Path(
        r"H:\Juan\3. Projects\GH Sawken\Python\Automated LiveSplit Stats Sheet\credentials\service_account_secrets.json"
    )
    MAIN_SQL_FILE = Path(r"H:\Juan\4. Speedrunning\RE4 Steam\script ng pro steam.sql")
    GLOBAL_SQL_FILE = Path(r"H:\Juan\4. Speedrunning\RE4 Steam\global ng pro steam.sql")
    LAST_UPDATES_FILE = Path(
        r"H:\Juan\3. Projects\GH Sawken\Python\Automated LiveSplit Stats Sheet\info\last_table_updates.json"
    )
    SPLITS_OUTPUT_FOLDER = Path(
        r"H:\Juan\4. Speedrunning\LiveSplit\Splits\RE4 Steam\2024 LRT\Not mine"
    )


class ORDER_COLUMNS(StrEnum):
    LRT_NUMBER = "lrt_number"
    CLE2 = "cle2"
    DATE_STARTED = "date_started"


class Format(Enum):
    DATE_FORMAT = "%d/%m/%Y"
    DATE_TIME_FORMAT = "%d/%m/%Y %H:%M:%S"
    GOOGLE_DRIVE_DATE_TIME_FORMAT = "%Y-%m-%dT%H:%M:%S.%fZ"
    BAD_DATE_FORMAT = "%Y-%m-%d"
    TIME_FORMAT = "{:02}.{:03}"


class ConstantQuery(Enum):
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


GOOGLE_DRIVE_TIMEZONE_OFFSET = timedelta(hours=3)
GOOGLE_DRIVE_FOLDER_ID = "1-OvGMbjiemrxMaie166Cmwbu3k5WvXGh"
GOOGLE_SHEET_URL = "https://docs.google.com/spreadsheets/d/1q1e9GCgaUc-LbhQWHEVjKkl0275hkfDVq0rHgQLrF-E/edit?usp=sharing"
DB_CONFIG = {
    "dbname": "postgres",
    "user": "postgres",
    "host": "localhost",
    "password": 123,
    "port": 5432,
}
CURRENTLY_ALLOWED_RUNNERS = [
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
]
CURRENTLY_ALLOWED_SPLITS = [
    f"splits {runner}.lss" for runner in CURRENTLY_ALLOWED_RUNNERS
]
DEFAULT_UPDATES = {
    key: "1/1/2025 1:00:00"
    for key in [
        "1. NG Pro",
        "splits arcadan",
        "splits derek",
        "splits joker",
        "splits luis",
        "splits mateo",
        "splits richy",
        "splits nevs",
        "splits otaku",
        "splits pocho",
    ]
}
