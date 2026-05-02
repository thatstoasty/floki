from std.testing import TestSuite, assert_equal, assert_true
from floki.cookie.expiration import Expiration


fn test_libcurl_session_expiration() raises -> None:
    var expires = Expiration.from_libcurl_expires("0")
    assert_true(expires.is_session())


fn test_libcurl_timestamp_expiration() raises -> None:
    var expires = Expiration.from_libcurl_expires("1893456000")
    assert_true(expires.is_datetime())
    var expires_datetime = expires.datetime.value()
    assert_equal(expires_datetime.year, 2030)
    assert_equal(expires_datetime.month, 1)
    assert_equal(expires_datetime.day, 1)
    assert_equal(expires_datetime.hour, 0)
    assert_equal(expires_datetime.minute, 0)
    assert_equal(expires_datetime.second, 0)


fn main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
