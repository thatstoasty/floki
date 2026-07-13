from floki.http import Status
from floki.proxy import Proxy
from floki.session import Session
from floki.tls import TLS
from std.pathlib import Path
from std.testing import TestSuite, assert_equal, assert_false, assert_raises, assert_true

import floki


# --- Proxy unit tests (no network) ---


def test_proxy_implicit_from_string() raises -> None:
    var p: Proxy = "http://proxy.example:8080"
    assert_true(Bool(p))
    assert_equal(p.url, "http://proxy.example:8080")
    assert_false(Bool(p.username))


def test_proxy_with_credentials_and_bypass() raises -> None:
    var p = Proxy(
        "http://proxy.example:8080",
        username="user",
        password="secret",
        no_proxy=["localhost", "127.0.0.1"],
    )
    assert_equal(p.username.value(), "user")
    assert_equal(p.password.value(), "secret")
    assert_equal(p.no_proxy, ["localhost", "127.0.0.1"])


# --- TLS unit tests (no network) ---


def test_tls_defaults_to_verify() raises -> None:
    var t = TLS()
    assert_true(t.verify)
    assert_false(Bool(t.ca_bundle))
    assert_false(Bool(t.ca_path))


def test_tls_can_disable_verification() raises -> None:
    var t = TLS(verify=False)
    assert_false(t.verify)


def test_tls_custom_ca_bundle() raises -> None:
    var t = TLS(ca_bundle=Path("/etc/ssl/cert.pem"))
    assert_true(t.verify)
    assert_equal(t.ca_bundle.value(), Path("/etc/ssl/cert.pem"))


# --- Integration tests (network) ---


def test_tls_verification_enabled_succeeds() raises -> None:
    var session = Session()
    var response = session.get("https://httpbingo.org/get")
    assert_equal(response.status, Status.OK)


def test_tls_verification_disabled_succeeds() raises -> None:
    var session = Session(tls=TLS(verify=False))
    var response = session.get("https://httpbingo.org/get")
    assert_equal(response.status, Status.OK)


def test_proxy_is_bypassed_for_no_proxy_host() raises -> None:
    # The bogus proxy is never contacted because the target host is in no_proxy.
    var session = Session(proxy=Proxy("http://127.0.0.1:9", no_proxy=["httpbingo.org"]))
    var response = session.get("https://httpbingo.org/get")
    assert_equal(response.status, Status.OK)


def test_proxy_is_applied() raises -> None:
    # A bogus, non-bypassed proxy must cause the request to fail, proving the
    # proxy is actually routed through rather than ignored.
    with assert_raises():
        var session = Session(proxy=Proxy("http://127.0.0.1:9"))
        _ = session.get("https://httpbingo.org/get")


def test_free_function_forwards_tls() raises -> None:
    var response = floki.get("https://httpbingo.org/get", tls=TLS(verify=False))
    assert_equal(response.status, Status.OK)


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
