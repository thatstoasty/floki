from sys.param_env import env_get_string
from sys import stdout, stderr
from logger import Logger, Level


fn get_log_level() -> Level:
    """Returns the log level based on the parameter environment variable `LOG_LEVEL`.

    Returns:
        The log level.
    """
    comptime level = env_get_string["FLOKI_LOG_LEVEL", "INFO"]()

    @parameter
    if level == "NOTSET":
        return Level.NOTSET
    elif level == "TRACE":
        return Level.TRACE
    elif level == "DEBUG":
        return Level.DEBUG
    elif level == "INFO":
        return Level.INFO
    elif level == "WARNING":
        return Level.WARNING
    elif level == "ERROR":
        return Level.ERROR
    elif level == "CRITICAL":
        return Level.CRITICAL
    else:
        return Level.INFO


comptime LOG_LEVEL = get_log_level()
"""Logger level determined by the `FLOKI_LOG_LEVEL` param environment variable.

When building or running the application, you can set `FLOKI_LOG_LEVEL` by providing the the following option:

```bash
mojo build ... -D FLOKI_LOG_LEVEL=DEBUG
# or
mojo ... -D FLOKI_LOG_LEVEL=DEBUG
```
"""


comptime LOGGER = Logger[LOG_LEVEL]()
