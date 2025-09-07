from decimal import Decimal

from pandas import DataFrame


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
    times_decimal = [parse_time(cg) for cg in times]
    return format_time(min(times_decimal))


def add_best_and_cumulative_best_columns(
    golds: DataFrame, *, skip_first_col: bool
) -> DataFrame:
    """
    Receives a DataFrame with the runners golds and calculates the best gold
    and cumulative best gold of all the data, then adds these as new columns
    and returns the modified DataFrame.
    """
    if skip_first_col:
        golds["Best gold"] = golds.apply(
            lambda row: calculate_best_time(row[1:]),
            axis=1,
        )
    else:
        golds["Best gold"] = golds.apply(
            lambda row: calculate_best_time(row),
            axis=1,
        )

    golds["Best gold seconds"] = golds["Best gold"].map(parse_time)
    golds["Cumulative best seconds"] = golds["Best gold seconds"].cumsum()
    golds["Cumulative best"] = golds["Cumulative best seconds"].apply(format_time)
    golds = golds.drop(columns=["Best gold seconds", "Cumulative best seconds"])

    best_gold_idx = golds.columns.get_loc("Best gold")
    cumulative_best_idx = golds.columns.get_loc("Cumulative best")

    # The last row of the 'Best gold' and 'Cumulative best' columns
    # doesn't need to hold any data.
    golds.iloc[golds.index[-1], best_gold_idx] = ""  # type: ignore  # noqa: PGH003
    golds.iloc[golds.index[-1], cumulative_best_idx] = ""  # type: ignore  # noqa: PGH003

    return golds


def transform_days_hours_mins_secs(total_playtime: str) -> str:
    """
    Transform a total playtime string in 'X days HH:MM:SS' format into
    'X days and Y hours' format.
    """
    # TODO: Calculate total seconds from HH:MM:SS then convert to rounded hours, for more accuracy.
    days = total_playtime.split(" ")[0]
    hours = int(total_playtime.split(" ")[2].split(":")[0])

    return f"{days} days and {int(hours)} hours"


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
