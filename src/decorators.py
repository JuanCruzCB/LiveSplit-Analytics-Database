import time
from functools import wraps

from constants import TIME_FORMAT
from timing import execution_times


def measure_time(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        execution_time = time.time() - start_time
        seconds = int(execution_time)
        milliseconds = int((execution_time % 1) * 1000)
        execution_time_formatted = TIME_FORMAT.format(seconds, milliseconds)
        execution_times[func.__name__] = execution_time_formatted

        return result

    return wrapper
