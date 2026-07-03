from floki.http import Status
from floki.retry import Retry
from floki.session import Session
from floki.timeout import Timeout
from std.testing import TestSuite, assert_equal, assert_false, assert_true

import floki


# --- Timeout unit tests (no network) ---


def test_timeout_defaults_to_no_limits() raises -> None:
    var t = Timeout()
    assert_false(Bool(t.connect))
    assert_false(Bool(t.total))


def test_timeout_implicit_from_int() raises -> None:
    var t: Timeout = 30
    assert_false(Bool(t.connect))
    assert_true(Bool(t.total))
    assert_equal(t.total.value(), 30.0)


def test_timeout_connect_and_total() raises -> None:
    var t = Timeout(connect=5.0, total=30.0)
    assert_equal(t.connect.value(), 5.0)
    assert_equal(t.total.value(), 30.0)


# --- Retry unit tests (no network) ---


def test_retry_default_is_disabled() raises -> None:
    var r = Retry()
    assert_equal(r.max_retries, 0)


def test_retry_backoff_is_exponential() raises -> None:
    var r = Retry(max_retries=5, backoff_factor=0.5, status_forcelist=[500])
    assert_equal(r.backoff_time(1), 0.5)
    assert_equal(r.backoff_time(2), 1.0)
    assert_equal(r.backoff_time(3), 2.0)
    assert_equal(r.backoff_time(4), 4.0)


def test_retry_should_retry_matches_forcelist() raises -> None:
    var r = Retry(max_retries=1, backoff_factor=0.1, status_forcelist=[500, 503])
    assert_true(r.should_retry(500))
    assert_true(r.should_retry(503))
    assert_false(r.should_retry(200))
    assert_false(r.should_retry(404))


# --- Integration tests (network) ---


def test_session_timeout_request_succeeds() raises -> None:
    var s = Session(timeout=Timeout(connect=5.0, total=30.0))
    var response = s.get("https://httpbingo.org/get")
    assert_equal(response.status, Status.OK)


def test_retry_exhausts_on_persistent_5xx() raises -> None:
    # httpbingo always returns 503 here; with retries exhausted the final response is returned.
    var s = Session(retry=Retry(max_retries=2, backoff_factor=0.05, status_forcelist=[503]))
    var response = s.get("https://httpbingo.org/status/503")
    assert_equal(response.status.code, 503)


def test_free_function_forwards_timeout_and_retry() raises -> None:
    var response = floki.get(
        "https://httpbingo.org/get",
        timeout=10,
        retry=Retry(max_retries=1, backoff_factor=0.05, status_forcelist=[500]),
    )
    assert_equal(response.status, Status.OK)


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
