from std.testing import TestSuite, assert_equal, assert_true
from mojo_datetime import DateTime
from floki._time import now
from floki.cookie.expiration import Expiration
from floki.cookie.cookie import Cookie


def test_libcurl_session_expiration() raises -> None:
    var expires = Expiration.from_libcurl_expires("0")
    assert_true(expires.is_session())


def test_libcurl_timestamp_expiration() raises -> None:
    var expires = Expiration.from_libcurl_expires("1893456000")
    assert_true(expires.is_datetime())
    var expires_datetime = expires.datetime.value()
    assert_equal(expires_datetime.year, 2030)
    assert_equal(expires_datetime.month, 1)
    assert_equal(expires_datetime.day, 1)
    assert_equal(expires_datetime.hour, 0)
    assert_equal(expires_datetime.minute, 0)
    assert_equal(expires_datetime.second, 0)


def test_cookie_parsing_with_expiration() raises -> None:
    var cookie = Cookie("httpbin.org\tFALSE\t/\tFALSE\t1893456000\tfreeform\tmy_val")
    assert_equal(cookie.name, "freeform")
    assert_equal(cookie.value, "my_val")
    assert_true(cookie.expires.is_datetime())
    var expires = cookie.expires.datetime.value()
    assert_equal(expires.year, 2030)
    assert_equal(expires.month, 1)
    assert_equal(expires.day, 1)
    assert_equal(expires.hour, 0)
    assert_equal(expires.minute, 0)
    assert_equal(expires.second, 0)


# === Additional Expiration Tests ===

def test_expiration_default_is_session() raises -> None:
    var exp = Expiration()
    assert_true(exp.is_session())
    assert_true(not exp.is_datetime())


def test_expiration_from_datetime() raises -> None:
    var exp = Expiration(DateTime(2040, 6, 15, 12, 0, 0, 0))
    assert_true(exp.is_datetime())
    assert_true(not exp.is_session())
    var dt = exp.datetime.value()
    assert_equal(dt.year, 2040)
    assert_equal(dt.month, 6)
    assert_equal(dt.day, 15)


def test_expiration_invalidate() raises -> None:
    var exp = Expiration.invalidate()
    assert_true(exp.is_datetime())
    var dt = exp.datetime.value()
    assert_equal(dt.year, 1970)
    assert_equal(dt.month, 1)
    assert_equal(dt.day, 1)


def test_expiration_equality_session() raises -> None:
    var exp1 = Expiration()
    var exp2 = Expiration()
    assert_true(exp1 == exp2)


def test_expiration_equality_datetime() raises -> None:
    var exp1 = Expiration(DateTime(2030, 1, 1, 0, 0, 0, 0))
    var exp2 = Expiration(DateTime(2030, 1, 1, 0, 0, 0, 0))
    assert_true(exp1 == exp2)


def test_expiration_inequality_different_dates() raises -> None:
    var exp1 = Expiration(DateTime(2030, 1, 1, 0, 0, 0, 0))
    var exp2 = Expiration(DateTime(2031, 6, 15, 0, 0, 0, 0))
    assert_true(not (exp1 == exp2))


def test_expiration_inequality_session_vs_datetime() raises -> None:
    var session = Expiration()
    var datetime_exp = Expiration(DateTime(2030, 1, 1, 0, 0, 0, 0))
    assert_true(not (session == datetime_exp))


def test_expiration_http_date_timestamp_none_for_session() raises -> None:
    var exp = Expiration()
    var result = exp.http_date_timestamp()
    assert_true(not Bool(result))


# === Additional Cookie Tests ===

def test_cookie_basic_construction() raises -> None:
    var cookie = Cookie("session_id", "abc123")
    assert_equal(cookie.name, "session_id")
    assert_equal(cookie.value, "abc123")
    assert_true(cookie.expires.is_session())
    assert_equal(cookie.secure, False)
    assert_equal(cookie.partitioned, False)
    assert_true(not cookie.domain)
    assert_true(not cookie.path)


def test_cookie_construction_with_domain_and_path() raises -> None:
    var cookie = Cookie("token", "xyz", domain="example.com", path="/api")
    assert_equal(cookie.domain.value(), "example.com")
    assert_equal(cookie.path.value(), "/api")


def test_cookie_construction_secure_and_partitioned() raises -> None:
    var cookie = Cookie("secure_cookie", "val", secure=True, partitioned=True)
    assert_true(cookie.secure)
    assert_true(cookie.partitioned)


def test_cookie_parsing_session_expiration() raises -> None:
    var cookie = Cookie("httpbin.org\tFALSE\t/\tFALSE\t0\tsession_token\tabc")
    assert_equal(cookie.name, "session_token")
    assert_equal(cookie.value, "abc")
    assert_true(cookie.expires.is_session())


def test_cookie_parsing_secure_flag() raises -> None:
    var cookie = Cookie("httpbin.org\tFALSE\t/\tTRUE\t0\tsecure_tok\tval")
    assert_true(cookie.secure)
    assert_true(not cookie.partitioned)


def test_cookie_parsing_partitioned_flag() raises -> None:
    var cookie = Cookie("httpbin.org\tTRUE\t/\tFALSE\t0\tpart_tok\tval")
    assert_true(cookie.partitioned)
    assert_true(not cookie.secure)


def test_cookie_parsing_domain_and_path() raises -> None:
    var cookie = Cookie("example.com\tFALSE\t/api/v1\tFALSE\t0\tmy_cookie\tmy_value")
    assert_equal(cookie.domain.value(), "example.com")
    assert_equal(cookie.path.value(), "/api/v1")


def test_cookie_str_method() raises -> None:
    var cookie = Cookie("session_id", "abc123")
    assert_equal(cookie.__str__(), "Name: session_id Value: abc123")


def test_cookie_write_to_method() raises -> None:
    var cookie = Cookie("session_id", "abc123")
    assert_equal(String.write(cookie), "Cookie(name=session_id, value=abc123)")


def test_cookie_build_header_value_basic() raises -> None:
    var cookie = Cookie("session_id", "abc123")
    assert_equal(cookie.build_header_value(), "session_id=abc123")


def test_cookie_build_header_value_with_domain() raises -> None:
    var cookie = Cookie("session_id", "abc123", domain="example.com")
    assert_equal(cookie.build_header_value(), "session_id=abc123; Domain=example.com")


def test_cookie_build_header_value_with_path() raises -> None:
    var cookie = Cookie("session_id", "abc123", path="/api")
    assert_equal(cookie.build_header_value(), "session_id=abc123; Path=/api")


def test_cookie_build_header_value_secure() raises -> None:
    var cookie = Cookie("session_id", "abc123", secure=True)
    assert_equal(cookie.build_header_value(), "session_id=abc123; Secure")


def test_cookie_build_header_value_partitioned() raises -> None:
    var cookie = Cookie("session_id", "abc123", partitioned=True)
    assert_equal(cookie.build_header_value(), "session_id=abc123; Partitioned")


def test_cookie_build_header_value_all_attrs() raises -> None:
    var cookie = Cookie(
        "session_id",
        "abc123",
        domain="example.com",
        path="/api",
        secure=True,
        partitioned=True,
    )
    assert_equal(
        cookie.build_header_value(),
        "session_id=abc123; Domain=example.com; Path=/api; Secure; Partitioned",
    )


def test_cookie_is_expired_epoch() raises -> None:
    var cookie = Cookie("old", "value")
    cookie.clear_cookie()  # Sets expiration to epoch (1970)
    var current_time = now()
    assert_true(cookie.is_expired(current_time))


def test_cookie_is_not_expired_future_date() raises -> None:
    var future_expiry = Expiration(DateTime(2099, 12, 31, 0, 0, 0, 0))
    var cookie = Cookie("valid", "value", expires=future_expiry^)
    var current_time = now()
    assert_true(not cookie.is_expired(current_time))


def test_cookie_session_never_expired() raises -> None:
    var cookie = Cookie("session", "value")
    var current_time = now()
    assert_true(not cookie.is_expired(current_time))


def test_cookie_clear_cookie() raises -> None:
    var cookie = Cookie("token", "value", expires=Expiration(DateTime(2030, 1, 1, 0, 0, 0, 0)))
    assert_true(cookie.expires.is_datetime())
    cookie.clear_cookie()
    assert_true(cookie.expires.is_datetime())
    var dt = cookie.expires.datetime.value()
    assert_equal(dt.year, 1970)


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
