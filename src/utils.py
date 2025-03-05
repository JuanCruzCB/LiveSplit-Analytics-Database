def get_singular_plural_str(time: int, type: str) -> str:
    match time:
        case 0:
            return ""
        case 1:
            return f"1 {type}"
        case _:
            return f"{time} {type}s"


def get_hours_minutes_str(seconds: str) -> str:
    try:
        secs = int(seconds)
        hours = secs // 3600
        remaining_seconds = secs % 3600
        minutes = remaining_seconds // 60
    except Exception as e:
        raise e

    hours_str = get_singular_plural_str(time=hours, type="hour")
    minutes_str = get_singular_plural_str(time=minutes, type="min")

    if hours_str and minutes_str:
        return f"{hours_str} and {minutes_str}"
    elif hours_str:
        return hours_str
    elif minutes_str:
        return minutes_str
    else:
        return "0 mins"


def get_days_hours_str(seconds: str) -> str:
    try:
        secs = int(seconds)
        days = secs // 86400
        remaining_seconds = secs % 86400
        hours = remaining_seconds // 3600
    except Exception:
        return ""

    days_str = get_singular_plural_str(time=days, type="day")
    hours_str = get_singular_plural_str(time=hours, type="hour")

    if days_str and hours_str:
        return f"{days_str} and {hours_str}"
    elif days_str:
        return days_str
    elif hours_str:
        return hours_str
    else:
        return "0 hours"
