from std.testing import TestSuite, assert_equal, assert_true
from floki.cookie.same_site import SameSite


def test_same_site_none_has_value_zero() raises -> None:
    assert_equal(SameSite.NONE.value, UInt8(0))


def test_same_site_lax_has_value_one() raises -> None:
    assert_equal(SameSite.LAX.value, UInt8(1))


def test_same_site_strict_has_value_two() raises -> None:
    assert_equal(SameSite.STRICT.value, UInt8(2))


def test_same_site_from_string_none() raises -> None:
    var ss = SameSite("none")
    assert_true(ss == SameSite.NONE)


def test_same_site_from_string_lax() raises -> None:
    var ss = SameSite("lax")
    assert_true(ss == SameSite.LAX)


def test_same_site_from_string_strict() raises -> None:
    var ss = SameSite("strict")
    assert_true(ss == SameSite.STRICT)


def test_same_site_invalid_string_raises() raises -> None:
    var raised = False
    try:
        var _ = SameSite("invalid")
    except:
        raised = True
    assert_true(raised)


def test_same_site_equality() raises -> None:
    assert_true(SameSite.NONE == SameSite.NONE)
    assert_true(SameSite.LAX == SameSite.LAX)
    assert_true(SameSite.STRICT == SameSite.STRICT)


def test_same_site_inequality() raises -> None:
    assert_true(not (SameSite.NONE == SameSite.LAX))
    assert_true(not (SameSite.LAX == SameSite.STRICT))
    assert_true(not (SameSite.NONE == SameSite.STRICT))


def test_same_site_write_to_none() raises -> None:
    assert_equal(String.write(SameSite.NONE), "none")


def test_same_site_write_to_lax() raises -> None:
    assert_equal(String.write(SameSite.LAX), "lax")


def test_same_site_write_to_strict() raises -> None:
    assert_equal(String.write(SameSite.STRICT), "strict")


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
