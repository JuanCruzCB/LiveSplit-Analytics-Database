from enum import StrEnum


class OrderColumns(StrEnum):
    RUN_ID = "run_id"
    SPLIT_INDEX = "split_index"
    LRT_TIME = "lrt_time"
    RUN_STARTED_AT = "run_started_at"


class OrderType(StrEnum):
    ASCENDING = ""
    DESCENDING = "DESC"
