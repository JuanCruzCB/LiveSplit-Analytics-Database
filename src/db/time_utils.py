from decimal import Decimal


def format_duration(seconds: Decimal) -> str:
    """
    Convert a Decimal number to a string in H:MM:SS.mmm, M:SS.mmm
    or S.mmm format depending on the value of the number.

    - Example 1: format_time(Decimal("4625.333")) returns "1:17:05.333"
    - Example 2: format_time(Decimal("65.583")) returns "1:05.583"
    - Example 3: format_time(Decimal("5.567")) returns "5.567"
    """
    if seconds < 0:
        msg = "Duration cannot be negative. Received: {seconds}"
        raise ValueError(msg)

    hs = int(seconds // 3600)
    mins = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    ms = int((seconds - int(seconds)) * 1000)

    if hs:
        return f"{hs}:{mins:02}:{secs:02}.{ms:03}"
    if mins:
        return f"{mins:01}:{secs:02}.{ms:03}"

    return f"{secs}.{ms:03}"


def parse_duration(time: str) -> Decimal:
    """
    Parse a time in either MM:SS.mmm or HH:MM:SS.mmm format to
    a Decimal object representing the total duration in seconds.

    - Example 1: parse_duration("1:17:05.333") returns Decimal("4625.333")
    - Example 2: parse_duration("1:05.583") returns Decimal("65.583")
    - Example 3: parse_duration("5.567") returns Decimal("5.567")
    """
    if "-" in time:
        msg = f"Negative durations are not supported. Received: {time}"
        raise ValueError(msg)

    if time.count(":") == 2:  # noqa: PLR2004
        hours, minutes, seconds = time.split(sep=":")
        return (int(hours) * 60 * 60) + (int(minutes) * 60) + Decimal(value=seconds)

    if time.count(":") == 1:
        minutes, seconds = time.split(sep=":")
        return int(minutes) * 60 + Decimal(value=seconds)

    return Decimal(value=time)


def compute_lowest_time(times: list[str]) -> str:
    """
    Receives a list of times in [H]:MM:SS.mmm format and
    returns the lowest time among all of them.

    - Example: compute_lowest_time(["1:17:05.333", "1:05.583", "5.567"]) returns "5.567"
    """
    times_decimal = [
        parse_duration(time) for time in times if ":" in time or "." in time
    ]
    return format_duration(seconds=min(times_decimal))


def transform_days_hours_mins_secs(total_playtime: str) -> str:
    """
    Transform a total playtime string in 'X days HH:MM:SS'
    format into 'Y hours' format.

    - Example: transform_days_hours_mins_secs("1 days 02:30:45") returns "26.5 hours"
    """
    hours = 0
    if "days" in total_playtime:
        days_part, time_part = total_playtime.split(sep="days")
        hours += int(days_part.strip()) * 24
        total_playtime = time_part.strip()

    if ":" in total_playtime:
        hrs, mins, secs = map(int, total_playtime.split(sep=":"))
        hours += hrs + mins / 60 + secs / 3600

    return f"{round(number=hours, ndigits=1)} hours"


def transform_interval_to_hours_mins(interval: str | None) -> str:
    """
    Transform a time interval string in 'HH:MM:SS' format into
    'X hs and Y mins' format.

    The interval string can have an invalid format or be None.

    - Example 1: transform_interval_to_hours_mins("02:30:00") returns "2 hs and 30 mins"
    - Example 2: transform_interval_to_hours_mins("00:45:00") returns "45 mins"
    """
    if interval is None:
        return ""

    if ":" not in interval:
        if "." in interval:
            rounded = round(number=float(interval), ndigits=2)
            return str(rounded)
        return interval

    try:
        hours = int(interval.split(sep=":")[0])
        minutes = int(interval.split(sep=":")[1])
    except ValueError:
        return interval

    if hours == 0:
        return f"{minutes} mins"

    return f"{hours} hs and {minutes} mins"
