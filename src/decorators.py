from functools import wraps
import time

from constants import TIME_FORMAT
from timing import execution_times


def measure_time(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        execution_time = time.time() - start_time
        execution_time_formatted = time.strftime(
            TIME_FORMAT, time.gmtime(execution_time)
        )
        execution_times[func.__name__] = execution_time_formatted
        return result

    return wrapper
