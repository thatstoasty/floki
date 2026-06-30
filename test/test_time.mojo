from floki._time import _CTime, _validate_timestamp, from_utc_timestamp, get_gm_time, now, parse_time_with_format
from mojo_datetime import TZ_UTC, DateTime
from std.python import Python, PythonObject
from std.testing import TestSuite, assert_equal, assert_true


def py_dt_datetime() raises -> PythonObject:
    var _datetime = Python.import_module("datetime")
    return _datetime.datetime


# TODO: Need a better way to test this, since it's not deterministic.
def assert_datetime_equal(dt: DateTime, py_dt: PythonObject) raises:
    assert_true(
        dt.year == UInt16(Int(String(py_dt.year)))
        and dt.month == UInt8(Int(String(py_dt.month)))
        and dt.hour == UInt8(Int(String(py_dt.hour)))
        and dt.minute == UInt8(Int(String(py_dt.minute)))
        and dt.second == UInt8(Int(String(py_dt.second))),
        String(t"dt: {dt} is not equal to py_dt: {py_dt}"),
    )


def test_utc_now() raises:
    assert_datetime_equal(py_dt=py_dt_datetime().utcnow(), dt=now())


# === _CTime tests ===


def test_ctime_default_init() raises -> None:
    var tm = _CTime()
    assert_equal(Int(tm.seconds), 0)
    assert_equal(Int(tm.minutes), 0)
    assert_equal(Int(tm.hours), 0)
    assert_equal(Int(tm.day_of_month), 0)
    assert_equal(Int(tm.month), 0)
    assert_equal(Int(tm.year), 0)
    assert_equal(Int(tm.day_of_week), 0)
    assert_equal(Int(tm.day_of_year), 0)
    assert_equal(Int(tm.is_daylight_savings), 0)


# === _validate_timestamp tests ===


def test_validate_timestamp_epoch() raises -> None:
    # Unix epoch in C tm struct: year=70 (1970-1900), month=0 (January), day=1
    var tm = _CTime(
        seconds=0,
        minutes=0,
        hours=0,
        day_of_month=1,
        month=0,
        year=70,
        day_of_week=4,
        day_of_year=0,
        is_daylight_savings=0,
        time_zone_offset=0,
        time_zone=None,
    )
    var dt = _validate_timestamp[TZ_UTC](tm)
    assert_equal(dt.year, 1970)
    assert_equal(dt.month, 1)
    assert_equal(dt.day, 1)
    assert_equal(dt.hour, 0)
    assert_equal(dt.minute, 0)
    assert_equal(dt.second, 0)


def test_validate_timestamp_known_date() raises -> None:
    # 2030-06-15 14:30:45
    var tm = _CTime(
        seconds=45,
        minutes=30,
        hours=14,
        day_of_month=15,
        month=5,
        year=130,
        day_of_week=6,
        day_of_year=165,
        is_daylight_savings=0,
        time_zone_offset=0,
        time_zone=None,
    )
    var dt = _validate_timestamp[TZ_UTC](tm)
    assert_equal(dt.year, 2030)
    assert_equal(dt.month, 6)
    assert_equal(dt.day, 15)
    assert_equal(dt.hour, 14)
    assert_equal(dt.minute, 30)
    assert_equal(dt.second, 45)


# === get_gm_time tests ===


def test_get_gm_time_epoch() raises -> None:
    var tm = get_gm_time(0)
    assert_equal(Int(tm.year), 70)  # 1970 - 1900
    assert_equal(Int(tm.month), 0)  # January (0-indexed)
    assert_equal(Int(tm.day_of_month), 1)
    assert_equal(Int(tm.hours), 0)
    assert_equal(Int(tm.minutes), 0)
    assert_equal(Int(tm.seconds), 0)


def test_get_gm_time_known_timestamp() raises -> None:
    # 1893456000 = 2030-01-01 00:00:00 UTC
    var tm = get_gm_time(1893456000)
    assert_equal(Int(tm.year), 130)  # 2030 - 1900
    assert_equal(Int(tm.month), 0)  # January (0-indexed)
    assert_equal(Int(tm.day_of_month), 1)
    assert_equal(Int(tm.hours), 0)
    assert_equal(Int(tm.minutes), 0)
    assert_equal(Int(tm.seconds), 0)


# === from_utc_timestamp tests ===


def test_from_utc_timestamp_epoch() raises -> None:
    var dt = from_utc_timestamp(0)
    assert_equal(dt.year, 1970)
    assert_equal(dt.month, 1)
    assert_equal(dt.day, 1)
    assert_equal(dt.hour, 0)
    assert_equal(dt.minute, 0)
    assert_equal(dt.second, 0)


def test_from_utc_timestamp_known() raises -> None:
    # 1893456000 = 2030-01-01 00:00:00 UTC
    var dt = from_utc_timestamp(1893456000)
    assert_equal(dt.year, 2030)
    assert_equal(dt.month, 1)
    assert_equal(dt.day, 1)
    assert_equal(dt.hour, 0)
    assert_equal(dt.minute, 0)
    assert_equal(dt.second, 0)


def test_from_utc_timestamp_mid_day() raises -> None:
    # 1893499200 = 2030-01-01 12:00:00 UTC (1893456000 + 43200)
    var dt = from_utc_timestamp(1893499200)
    assert_equal(dt.year, 2030)
    assert_equal(dt.month, 1)
    assert_equal(dt.day, 1)
    assert_equal(dt.hour, 12)
    assert_equal(dt.minute, 0)
    assert_equal(dt.second, 0)


# === now tests ===


def test_now_does_not_raise() raises -> None:
    var dt = now()
    assert_true(dt.year >= 2020)
    assert_true(dt.year <= 2100)


# === parse_time_with_format tests ===


def test_parse_time_with_format_date() raises -> None:
    var time_str = String("2030-01-01")
    var fmt = String("%Y-%m-%d")
    var tm = parse_time_with_format(time_str, fmt)
    assert_equal(Int(tm.year), 130)  # 2030 - 1900
    assert_equal(Int(tm.month), 0)  # January (0-indexed)
    assert_equal(Int(tm.day_of_month), 1)


def test_parse_time_with_format_time() raises -> None:
    var time_str = String("12:30:45")
    var fmt = String("%H:%M:%S")
    var tm = parse_time_with_format(time_str, fmt)
    assert_equal(Int(tm.hours), 12)
    assert_equal(Int(tm.minutes), 30)
    assert_equal(Int(tm.seconds), 45)


def test_parse_time_with_format_datetime() raises -> None:
    var time_str = String("2025-07-04 08:15:00")
    var fmt = String("%Y-%m-%d %H:%M:%S")
    var tm = parse_time_with_format(time_str, fmt)
    assert_equal(Int(tm.year), 125)  # 2025 - 1900
    assert_equal(Int(tm.month), 6)  # July (0-indexed)
    assert_equal(Int(tm.day_of_month), 4)
    assert_equal(Int(tm.hours), 8)
    assert_equal(Int(tm.minutes), 15)
    assert_equal(Int(tm.seconds), 0)


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
