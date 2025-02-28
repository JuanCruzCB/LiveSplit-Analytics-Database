from enum import Enum


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


CURRENTLY_ALLOWED_RUNNERS = [
    "arcadan",
    "derek",
    "joker",
    "luis",
    "mateo",
    "richy",
    "nevs",
]
