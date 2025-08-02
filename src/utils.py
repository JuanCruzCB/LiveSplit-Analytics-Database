from decimal import Decimal


def get_hours_minutes_str(seconds: str) -> str:
    try:
        secs = int(seconds)
        hours = secs // 3600
        remaining_seconds = secs % 3600
        minutes = remaining_seconds // 60
    except ValueError:
        return ""

    # Format hours string
    if hours == 0:
        hours_str = ""
    elif hours == 1:
        hours_str = "1 hr"
    else:
        hours_str = f"{hours} hs"

    # Format minutes string
    if minutes == 0:
        minutes_str = ""
    elif minutes == 1:
        minutes_str = "1 min"
    else:
        minutes_str = f"{minutes} mins"

    # Combine hours and minutes
    if hours_str and minutes_str:
        return f"{hours_str} and {minutes_str}"
    if hours_str:
        return hours_str
    if minutes_str:
        return minutes_str
    return "0 mins"


def get_days_hours_str(seconds: str) -> str:
    try:
        secs = int(seconds)
        days = secs // 86400
        remaining_seconds = secs % 86400
        hours = remaining_seconds // 3600
    except Exception:
        return ""

    if days == 0:
        days_str = ""
    elif days == 1:
        days_str = "1 day"
    else:
        days_str = f"{days} days"

    if hours == 0:
        hours_str = ""
    elif hours == 1:
        hours_str = "1 hour"
    else:
        hours_str = f"{hours} hours"

    if days_str and hours_str:
        return f"{days_str} and {hours_str}"
    if days_str:
        return days_str
    if hours_str:
        return hours_str
    return "0 hours"


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

    if time.count(":") == 2:
        hours, minutes, seconds = time.split(":")
        return (int(hours) * 60 * 60) + (int(minutes) * 60) + Decimal(seconds)

    if time.count(":") == 1:
        minutes, seconds = time.split(":")
        return int(minutes) * 60 + Decimal(seconds)

    return Decimal(time)
