from decimal import Decimal

import polars as pl
from polars import DataFrame


def format_time(seconds: Decimal) -> str:
    """
    Convert a Decimal number to a string in [H:]MM:SS.mmm format.
    """
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    milliseconds = int((seconds - int(seconds)) * 1000)

    if hours > 0:
        return f"{hours}:{minutes:02}:{secs:02}.{milliseconds:03}"
    if minutes == 0:
        return f"{secs:02}.{milliseconds:03}"
    return f"{minutes:01}:{secs:02}.{milliseconds:03}"


def parse_time(time: str) -> Decimal:
    """
    Parse a time in minutes:seconds.milliseconds (3 decimals)
    or hours:minutes:seconds.milliseconds (also 3 decimals)
    format to seconds.milliseconds.
    """
    time = str(time)

    if time.count(":") == 2:  # noqa: PLR2004
        hours, minutes, seconds = time.split(":")
        return (int(hours) * 60 * 60) + (int(minutes) * 60) + Decimal(seconds)

    if time.count(":") == 1:
        minutes, seconds = time.split(":")
        return int(minutes) * 60 + Decimal(seconds)

    return Decimal(time)


def calculate_best_time(times: list[str]) -> str:
    """
    Receives a list of times in [H]:MM:SS.mmm format and
    returns the minimum time among all of them.
    """
    times_decimal = [parse_time(time) for time in times if ":" in time or "." in time]
    return format_time(min(times_decimal))


def add_best_and_cumulative_best_cols(times: DataFrame) -> DataFrame:
    """
    Receives a DataFrame with the runners times and calculates the best time
    and cumulative best time of all the data, then adds these as new columns
    and returns the modified DataFrame.
    """
    times = times.with_columns(
        pl.struct(times.columns)
        .map_elements(
            function=lambda row: calculate_best_time(times=list(row.values())),
            return_dtype=pl.String,
        )
        .alias(name="Best"),
    )

    times = times.with_columns(
        pl.col(name="Best")
        .map_elements(
            function=parse_time,
            return_dtype=pl.Decimal(precision=None, scale=3),
        )
        .alias(name="Best (seconds)"),
    )

    times = times.with_columns(
        pl.col(name="Best (seconds)").cum_sum().alias(name="Cumulative best (seconds)"),
    )

    times = times.with_columns(
        pl.col(name="Cumulative best (seconds)")
        .map_elements(function=format_time, return_dtype=pl.String)
        .alias(name="Cumulative best"),
    )

    times = times.drop(["Best (seconds)", "Cumulative best (seconds)"])

    # Remove the last row of the Best and Cumulative best columns.
    return times.with_columns(
        pl.when(pl.int_range(0, pl.len()) == pl.len() - 1)
        .then(statement=pl.lit(value=""))
        .otherwise(statement=pl.col(name="Best"))
        .alias(name="Best"),
        pl.when(pl.int_range(0, pl.len()) == pl.len() - 1)
        .then(statement=pl.lit(value=""))
        .otherwise(statement=pl.col(name="Cumulative best"))
        .alias(name="Cumulative best"),
    )


def transform_days_hours_mins_secs(total_playtime: str) -> str:
    """
    Transform a total playtime string in 'X days HH:MM:SS'
    format into 'X hours' format.
    """
    hours = 0
    if "days" in total_playtime:
        days_part, time_part = total_playtime.split("days")
        hours += int(days_part.strip()) * 24
        total_playtime = time_part.strip()

    if ":" in total_playtime:
        hrs, mins, secs = map(int, total_playtime.split(":"))
        hours += hrs + mins / 60 + secs / 3600

    return f"{round(hours, 1)} hours"


def transform_interval_to_hours_mins(interval: str | None) -> str:
    """
    Transform a time interval string in 'HH:MM:SS' format into
    'X hrs and Y mins' format.

    The interval string can have an invalid format or be None.
    """
    if interval is None:
        return ""

    if ":" not in interval:
        if "." in interval:
            rounded = round(float(interval), 2)
            return str(rounded)
        return interval

    try:
        hours = int(interval.split(":")[0])
        minutes = int(interval.split(":")[1])
    except ValueError:
        return interval

    if hours == 0:
        return f"{minutes} mins"

    return f"{hours} hrs and {minutes} mins"
