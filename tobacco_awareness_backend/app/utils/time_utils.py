from datetime import datetime, timezone, timedelta

# Bangladesh Standard Time is UTC+6 (Asia/Dhaka)
BST_TIMEZONE = timezone(timedelta(hours=6))


def get_bst_now() -> datetime:
    """Returns the current datetime in Bangladesh Standard Time (UTC+6)."""
    return datetime.now(timezone.utc).astimezone(BST_TIMEZONE)


def get_bst_today_str() -> str:
    """Returns today's date string in 'YYYY-MM-DD' format based on BST (UTC+6)."""
    return get_bst_now().strftime("%Y-%m-%d")
