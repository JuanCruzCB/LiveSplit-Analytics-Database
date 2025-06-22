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
    elif days_str:
        return days_str
    elif hours_str:
        return hours_str
    else:
        return "0 hours"
