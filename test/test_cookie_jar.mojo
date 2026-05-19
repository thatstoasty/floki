from std.testing import TestSuite, assert_equal, assert_true
from mojo_datetime import DateTime
from floki._time import now
from floki.cookie.expiration import Expiration
from floki.cookie.cookie import Cookie
from floki.cookie.cookie_jar import CookieJar, CookieKey


# === CookieKey Tests ===

def test_cookie_key_default_domain_and_path() raises -> None:
    var key = CookieKey("session_id")
    assert_equal(key.name, "session_id")
    assert_equal(key.domain, "")
    assert_equal(key.path, "/")


def test_cookie_key_with_explicit_domain_and_path() raises -> None:
    var key = CookieKey("token", "example.com", "/api")
    assert_equal(key.name, "token")
    assert_equal(key.domain, "example.com")
    assert_equal(key.path, "/api")


def test_cookie_key_equality() raises -> None:
    var key1 = CookieKey("session_id")
    var key2 = CookieKey("session_id")
    assert_true(key1 == key2)


def test_cookie_key_full_equality() raises -> None:
    var key1 = CookieKey("token", "example.com", "/api")
    var key2 = CookieKey("token", "example.com", "/api")
    assert_true(key1 == key2)


def test_cookie_key_inequality_by_name() raises -> None:
    var key1 = CookieKey("session_id")
    var key2 = CookieKey("token")
    assert_true(not (key1 == key2))


def test_cookie_key_inequality_by_domain() raises -> None:
    var key1 = CookieKey("token", "example.com", "/")
    var key2 = CookieKey("token", "other.com", "/")
    assert_true(not (key1 == key2))


def test_cookie_key_inequality_by_path() raises -> None:
    var key1 = CookieKey("token", "example.com", "/api")
    var key2 = CookieKey("token", "example.com", "/admin")
    assert_true(not (key1 == key2))


# === CookieJar Tests ===

def test_cookie_jar_empty_construction() raises -> None:
    var jar = CookieJar()
    assert_equal(len(jar), 0)


def test_cookie_jar_bool_true_when_empty() raises -> None:
    var jar = CookieJar()
    assert_true(jar.__bool__())


def test_cookie_jar_from_cookies() raises -> None:
    var jar = CookieJar(Cookie("session_id", "abc123"), Cookie("token", "xyz"))
    assert_equal(len(jar), 2)
    assert_true(CookieKey("session_id") in jar)
    assert_true(CookieKey("token") in jar)


def test_cookie_jar_set_and_get_cookie() raises -> None:
    var jar = CookieJar()
    jar.set_cookie(Cookie("session_id", "abc123"))
    assert_equal(jar[CookieKey("session_id")].name, "session_id")
    assert_equal(jar[CookieKey("session_id")].value, "abc123")


def test_cookie_jar_get_returns_none_for_missing() raises -> None:
    var jar = CookieJar()
    var result = jar.get(CookieKey("missing"))
    assert_true(not Bool(result))


def test_cookie_jar_get_returns_cookie_when_present() raises -> None:
    var jar = CookieJar()
    jar.set_cookie(Cookie("session_id", "abc123"))
    var result = jar.get(CookieKey("session_id"))
    assert_true(Bool(result))
    assert_equal(result.value().name, "session_id")
    assert_equal(result.value().value, "abc123")


def test_cookie_jar_contains_by_key_present() raises -> None:
    var jar = CookieJar()
    jar.set_cookie(Cookie("session_id", "abc123"))
    assert_true(CookieKey("session_id") in jar)


def test_cookie_jar_contains_by_key_absent() raises -> None:
    var jar = CookieJar()
    jar.set_cookie(Cookie("session_id", "abc123"))
    assert_true(not (CookieKey("other") in jar))


def test_cookie_jar_contains_by_cookie() raises -> None:
    var jar = CookieJar()
    jar.set_cookie(Cookie("session_id", "abc123"))
    assert_true(Cookie("session_id", "abc123") in jar)


def test_cookie_jar_len_after_adding() raises -> None:
    var jar = CookieJar()
    jar.set_cookie(Cookie("cookie1", "val1"))
    jar.set_cookie(Cookie("cookie2", "val2"))
    jar.set_cookie(Cookie("cookie3", "val3"))
    assert_equal(len(jar), 3)


def test_cookie_jar_bool_false_when_nonempty() raises -> None:
    var jar = CookieJar()
    jar.set_cookie(Cookie("session_id", "abc123"))
    assert_true(not jar.__bool__())


def test_cookie_jar_replace_existing_cookie() raises -> None:
    var jar = CookieJar()
    jar.set_cookie(Cookie("session_id", "old_value"))
    jar.set_cookie(Cookie("session_id", "new_value"))
    assert_equal(len(jar), 1)
    assert_equal(jar[CookieKey("session_id")].value, "new_value")


def test_cookie_jar_write_to_contains_header() raises -> None:
    var jar = CookieJar()
    jar.set_cookie(Cookie("session_id", "abc123"))
    var output = String.write(jar)
    assert_true("set-cookie" in output)
    assert_true("session_id=abc123" in output)


def test_cookie_jar_clear_expired_cookies() raises -> None:
    var jar = CookieJar()
    # Add a cookie whose expiry is set to epoch (1970 — always expired)
    var expired_cookie = Cookie("old_token", "expired_value")
    expired_cookie.clear_cookie()
    jar.set_cookie(expired_cookie^)
    # Add a session cookie (no expiry, never expires)
    jar.set_cookie(Cookie("active_session", "active_value"))
    assert_equal(len(jar), 2)
    jar.clear_expired_cookies()
    assert_equal(len(jar), 1)
    assert_true(CookieKey("active_session") in jar)
    assert_true(not (CookieKey("old_token") in jar))


def test_cookie_jar_add_headers_to_jar() raises -> None:
    var jar = CookieJar()
    jar.add_headers_to_jar(["httpbin.org\tFALSE\t/\tFALSE\t0\tsession_id\tabc123"])
    assert_equal(len(jar), 1)
    # Domain is set from parsed string, so key includes "httpbin.org"
    assert_true(CookieKey("session_id", "httpbin.org", "/") in jar)


def test_cookie_jar_add_headers_to_jar_multiple() raises -> None:
    var jar = CookieJar()
    jar.add_headers_to_jar([
        "httpbin.org\tFALSE\t/\tFALSE\t0\tcookie1\tval1",
        "httpbin.org\tFALSE\t/\tFALSE\t0\tcookie2\tval2",
    ])
    assert_equal(len(jar), 2)


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
