from enum import StrEnum


class OrderColumns(StrEnum):
    RUN_ID = "run_id"
    SPLIT_INDEX = "split_index"
    SPLIT_GT = "split_gt"
    RUN_STARTED_AT = "run_started_at"


class OrderType(StrEnum):
    ASCENDING = ""
    DESCENDING = "DESC"
