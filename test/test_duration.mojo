from std.testing import TestSuite, assert_equal, assert_true
from floki.cookie.duration import Duration


def test_duration_default_is_zero() raises -> None:
    var d = Duration()
    assert_equal(d.total_seconds, 0)


def test_duration_from_seconds() raises -> None:
    var d = Duration(seconds=45)
    assert_equal(d.total_seconds, 45)


def test_duration_from_minutes() raises -> None:
    var d = Duration(minutes=5)
    assert_equal(d.total_seconds, 300)


def test_duration_from_hours() raises -> None:
    var d = Duration(hours=2)
    assert_equal(d.total_seconds, 7200)


def test_duration_from_days() raises -> None:
    var d = Duration(days=1)
    assert_equal(d.total_seconds, 86400)


def test_duration_combined_components() raises -> None:
    # 1 day + 2 hours + 3 minutes + 4 seconds = 86400 + 7200 + 180 + 4 = 93784
    var d = Duration(seconds=4, minutes=3, hours=2, days=1)
    assert_equal(d.total_seconds, 93784)


def test_duration_minutes_and_seconds() raises -> None:
    var d = Duration(seconds=30, minutes=2)
    assert_equal(d.total_seconds, 150)


def test_duration_from_string() raises -> None:
    var d = Duration("3600")
    assert_equal(d.total_seconds, 3600)


def test_duration_from_string_zero() raises -> None:
    var d = Duration("0")
    assert_equal(d.total_seconds, 0)


def test_duration_from_string_large_value() raises -> None:
    var d = Duration("86400")
    assert_equal(d.total_seconds, 86400)


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
