import std.sys._libc as libc
from std.ffi import c_char, c_int, c_long, c_uchar, external_call, get_errno
from std.sys import CompilationTarget
from std import time

from mojo_datetime import DateTime, TimeZone, TZ_UTC, TimeDelta, SITimeUnit

comptime time_t = Int64
"""C `time_t` type, representing time in seconds since the Epoch (1970-01-01 00:00:00 UTC)."""
comptime suseconds_t = time_t
"""C `suseconds_t` type, representing microseconds. It is typically the same as `time_t`."""
comptime c_void = NoneType
"""C `void` type, used for generic pointers."""

comptime ImmutExternalUnsafePointer = UnsafePointer[origin=ImmutExternalOrigin, ...]
comptime MutExternalUnsafePointer = UnsafePointer[origin=MutExternalOrigin, ...]


@fieldwise_init
struct _CTime(ImplicitlyCopyable, Writable):
    """C `tm` struct."""

    var seconds: c_int
    """Seconds, valid range is 0-60 (60 is for leap seconds)."""
    var minutes: c_int
    """Minutes, valid range is 0-59."""
    var hours: c_int
    """Hour, valid range is 0-23."""
    var day_of_month: c_int
    """Day of the month, valid range is 1-31."""
    var month: c_int
    """Month, valid range is 0-11 (0 is January, 11 is December)."""
    var year: c_int
    """Year minus 1900."""
    var day_of_week: c_int
    """Day of the week, valid range is 0-6 (0 is Sunday)."""
    var day_of_year: c_int
    """Day of the year, valid range is 0-365 (Jan/01 = 0)."""
    var is_daylight_savings: c_int
    """Whether daylight saving time is in effect at the time described.
    The value is positive if daylight saving time is in effect,
    zero if it is not, and negative if the information is not available."""
    var time_zone_offset: c_long
    """The difference, in seconds, of the timezone represented by this broken-down time and UTC"""
    var time_zone: Optional[ImmutExternalUnsafePointer[c_char]]
    """Pointer to a string representing the timezone name, e.g. "UTC", "America/New_York"."""

    def __init__(out self):
        """Initializes a new time struct."""
        self.seconds = 0
        self.minutes = 0
        self.hours = 0
        self.day_of_month = 0
        self.month = 0
        self.year = 0
        self.day_of_week = 0
        self.day_of_year = 0
        self.is_daylight_savings = 0
        self.time_zone_offset = 0
        self.time_zone = None

    def write_to(self, mut writer: Some[Writer]):
        """Writes the time struct to a writer.

        Args:
            writer: The writer to write to.
        """
        writer.write(
            "tm(seconds=",
            self.seconds,
            ", minutes=",
            self.minutes,
            ", hours=",
            self.hours,
            ", day_of_month=",
            self.day_of_month,
            ", month=",
            self.month,
            ", year=",
            self.year,
            ", day_of_week=",
            self.day_of_week,
            ", day_of_year=",
            self.day_of_year,
            ", is_daylight_savings=",
            self.is_daylight_savings,
            ", time_zone_offset=",
            self.time_zone_offset,
        )
        if self.time_zone:
            writer.write(", time_zone=", StringSlice(unsafe_from_utf8_ptr=self.time_zone.value()))
        writer.write(")")


@fieldwise_init
struct _CTimeValue(ImplicitlyCopyable, Writable, TrivialRegisterPassable):
    """C `TimeValue` struct."""

    var seconds: time_t
    """Seconds to wait. Corresponds to `tv_sec` in C."""
    var microseconds: suseconds_t
    """Microseconds to wait. Corresponds to `tv_usec` in C."""


@fieldwise_init
struct _CTimeZone(ImplicitlyCopyable, Writable, TrivialRegisterPassable):
    """C `timezone` struct."""

    var minutes_west: c_int
    """Minutes west of Greenwich."""
    var dst_time_correction: c_int
    """Type of DST correction."""


# def now[utc: Bool = False]() raises -> DateTime[TZ_UTC]:
#     """Return the current time in UTC or local time.

#     Parameters:
#         utc: If True, return the current time in UTC. Otherwise, return the current time in local time.

#     Returns:
#         The current time.

#     Raises:
#         Error: If unable to get the current time via C.
#     """
#     return from_timestamp[utc=utc](get_time_of_day())


def now() raises -> DateTime[TZ_UTC]:
    """Construct a datetime from `time.now()`.

    Returns:
        A UTC DateTime.
    """
    return from_utc_timestamp(get_time_of_day())


def _validate_timestamp[timezone: TimeZone = TZ_UTC](
    tm: _CTime, time_val: Optional[_CTimeValue] = None
) raises -> DateTime[timezone]:
    """Validate the timestamp.

    Args:
        tm: The time struct.
        time_val: The time value.

    Returns:
        The validated timestamp.

    Raises:
        Error: If the timestamp is invalid.
    """
    var year = Int(tm.year) + 1900
    if not -1 < year < 10000:
        raise Error("The year parsed out from the timestamp is too large or negative. Received: ", year)

    var month = Int(tm.month) + 1
    if not -1 < month < 13:
        raise Error("The month parsed out from the timestamp is too large or negative. Received: ", month)

    var day = Int(tm.day_of_month)
    if not -1 < day < 32:
        raise Error("The day of the month parsed out from the timestamp is too large or negative. Received: ", day)

    var hours = Int(tm.hours)
    if not -1 < hours < 25:
        raise Error("The hour parsed out from the timestamp is too large or negative. Received: ", hours)

    var minutes = Int(tm.minutes)
    if not -1 < minutes < 61:
        raise Error("The minutes parsed out from the timestamp is too large or negative. Received: ", minutes)

    var seconds = Int(tm.seconds)
    if not -1 < seconds < 61:
        raise Error("The day of the month parsed out from the timestamp is too large or negative. Received: ", seconds)

    var microseconds = Int(time_val.value().microseconds) if time_val else 0
    if microseconds < 0:
        raise Error("Received negative microseconds. Received: ", microseconds)

    return DateTime[timezone](
        year,
        month,
        day,
        hours,
        minutes,
        seconds,
        microseconds,
    )


def _gettimeofday(tv: MutUnsafePointer[_CTimeValue, ...], tz: MutUnsafePointer[_CTimeZone, ...]) -> c_int:
    """Gets the current time. It's a wrapper around libc `gettimeofday`.
    The `tv` parameter is a pointer to a `struct timeval` that will be filled.

    Args:
        tv: UnsafePointer to a `struct timeval` that will be filled with the current time.
        tz: UnsafePointer to a `struct timezone` that will be filled with the timezone information.

    Returns:
        The return value is 0 on success, or -1 on error. If an error occurs,
        the global variable `errno` is set to indicate the error.

    #### C Function:
    ```c
    int gettimeofday(struct timeval *restrict tv, struct timezone *_Nullable restrict tz);
    ```
    """
    return external_call["gettimeofday", c_int, type_of(tv), type_of(tz)](tv, tz)


def get_time_of_day() raises -> _CTimeValue:
    """Gets the current time. Wrapper around libc `gettimeofday`.

    Returns:
        The current time.

    #### C Function:
    ```c
    int gettimeofday(struct timeval *restrict tv, struct timezone *restrict tz);
    ```
    """
    var tv = InlineArray[_CTimeValue, 1](uninitialized=True)
    var tz = InlineArray[_CTimeZone, 1](uninitialized=True)
    var result = _gettimeofday(tv.unsafe_ptr(), tz.unsafe_ptr())
    if result != 0:
        var errno = get_errno()
        if errno == errno.EFAULT:
            raise Error(
                "[EFAULT] gettimeofday failed: One of `tv` or `tz` pointed outside the accessible address space."
            )
        else:
            raise Error("[UNKNOWN] gettimeofday failed with unknown errno code: ", errno)
    return tv[0].copy()


def _localtime_r(timep: ImmutUnsafePointer[time_t, ...], result: MutUnsafePointer[_CTime, ...]) -> None:
    """Converts a time value to a broken-down local time.

    Args:
        timep: UnsafePointer to a time value in seconds since the Epoch.
        result: UnsafePointer to a `_CTime` struct where the broken-down local time will be stored.

    #### C Function:
    ```c
    struct tm *localtime_r(const time_t *timep, struct tm *result);
    ```
    """
    _ = external_call["localtime_r", ImmutExternalUnsafePointer[_CTime], type_of(timep), type_of(result)](timep, result)


def get_local_time(seconds_since_epoch: time_t) raises -> _CTime:
    """Converts a time value to a broken-down local time.

    Args:
        seconds_since_epoch: Time value in seconds since the Epoch.

    #### C Function:
    ```c
    struct tm *localtime_r(const time_t *timep, struct tm *result);
    ```
    """
    var result = InlineArray[_CTime, 1](uninitialized=True)
    _localtime_r(UnsafePointer(to=seconds_since_epoch), result.unsafe_ptr())
    return result[0].copy()


def _gmtime(timep: ImmutUnsafePointer[time_t, ...]) -> Optional[MutExternalUnsafePointer[_CTime]]:
    """Converts a time value to a broken-down UTC time.

    Args:
        timep: UnsafePointer to a time value in seconds since the Epoch.

    Returns:
        Broken down UTC time.

    #### C Function:
    ```c
    struct tm *gmtime(const time_t *timep);
    ```
    """
    return external_call["gmtime", Optional[MutExternalUnsafePointer[_CTime]], type_of(timep)](timep)


def get_gm_time(time: time_t) raises -> _CTime:
    """Converts a time value to a broken-down UTC time.

    Args:
        time: Time value in seconds since the Epoch.

    Returns:
        Broken down UTC time.

    #### C Function:
    ```c
    struct tm *gmtime(const time_t *timep);
    ```
    """
    var result = _gmtime(UnsafePointer[mut=False](to=time))
    if not result:
        raise Error(
            "get_gm_time failed: The pointer to the result is still null, which indicates the conversion failed."
        )

    # TODO (Mikhail): Maybe copy the result, not sure if take_pointee is safe here.
    return result.value().take_pointee()


comptime MAX_TIMESTAMP: Float64 = 32503737600
"""Maximum timestamp."""
comptime MAX_TIMESTAMP_MS = MAX_TIMESTAMP * 1000
"""Maximum timestamp in milliseconds."""
comptime MAX_TIMESTAMP_US = MAX_TIMESTAMP * 1_000_000
"""Maximum timestamp in microseconds."""


def normalize_timestamp(var timestamp: Float64) raises -> Float64:
    """Normalize millisecond and microsecond timestamps into normal timestamps.

    Args:
        timestamp: The timestamp to normalize.

    Returns:
        The normalized timestamp.

    Raises:
        Error: If the timestamp is too large.
    """
    if timestamp > MAX_TIMESTAMP:
        if timestamp < MAX_TIMESTAMP_MS:
            timestamp /= 1000
        elif timestamp < MAX_TIMESTAMP_US:
            timestamp /= 1_000_000
        else:
            raise Error("The specified timestamp ", timestamp, " is too large.")
    return timestamp


def from_utc_timestamp(time: _CTimeValue) raises -> DateTime[TZ_UTC]:
    """Create a DateTime instance from a timestamp.

    Args:
        time: The timestamp as a C TimeValue.

    Returns:
        The DateTime instance.

    Raises:
        Error: If the timestamp is invalid.
    """
    return _validate_timestamp[timezone=TZ_UTC](get_gm_time(time.seconds), time)


def from_utc_timestamp(timestamp: Int) raises -> DateTime[TZ_UTC]:
    """Create a DateTime instance from a timestamp.

    Args:
        timestamp: The timestamp in seconds.

    Returns:
        The DateTime instance.

    Raises:
        Error: If the timestamp is invalid.
    """
    var t = _CTimeValue(seconds=Int64(timestamp), microseconds=0)
    return _validate_timestamp[timezone=TZ_UTC](get_gm_time(t.seconds), t)


def _strptime(
    buf: ImmutUnsafePointer[c_char, ...], format: ImmutUnsafePointer[c_char, ...], tm: MutUnsafePointer[_CTime, ...]
) -> MutExternalUnsafePointer[c_char]:
    """Parses a time string according to a format string.

    Args:
        buf: Time string to parse.
        format: Time format string.
        tm: UnsafePointer to a `_CTime` struct where the broken-down time will be stored.

    Returns:
        Broken down time.

    #### C Function:
    ```c
    char *strptime(
        const char *restrict buf, const char *restrict format, struct tm *restrict tm
    );
    ```
    """
    return external_call[
        "strptime",
        MutExternalUnsafePointer[c_char],
        type_of(buf),
        type_of(format),
        type_of(tm),
    ](buf, format, tm)


def parse_time_with_format(mut time: String, mut format: String) raises -> _CTime:
    """Parses a time string according to a format string.

    Args:
        time: Time string to parse. This must be mutable so it can be null terminated for C interop.
        format: Time format string. This must be mutable so it can be null terminated for C interop.

    Returns:
        Broken down time.

    #### C Function:
    ```c
    char *strptime(
        const char *restrict buf, const char *restrict format, struct tm *restrict tm
    );
    ```
    """
    var tm = InlineArray[_CTime, 1](uninitialized=True)
    _ = _strptime(
        time.as_c_string_slice().unsafe_ptr(),
        format.as_c_string_slice().unsafe_ptr(),
        tm.unsafe_ptr(),
    )
    return tm[0].copy()
