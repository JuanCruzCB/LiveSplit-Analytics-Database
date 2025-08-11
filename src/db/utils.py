from decimal import Decimal


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
