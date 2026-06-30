from floki.auth import Auth, BasicAuth, BearerAuth
from floki.forms import FormData
from floki.http import Status
from floki.session import Session
from std.testing import TestSuite, assert_equal, assert_true

import floki


@fieldwise_init
struct ApiKeyAuth(Auth):
    """A custom `Auth` scheme that sends an API key in the `X-Api-Key` header."""

    var key: String

    def apply(self, mut headers: Dict[String, String]):
        headers["X-Api-Key"] = self.key


def test_basic_auth_succeeds() raises -> None:
    var response = floki.get(
        "https://httpbingo.org/basic-auth/user/password",
        auth=BasicAuth("user", "password"),
    )
    assert_equal(response.status, Status.OK)


def test_basic_auth_missing_fails() raises -> None:
    var response = floki.get("https://httpbingo.org/basic-auth/user/password")
    assert_equal(response.status, Status.UNAUTHORIZED)


def test_bearer_auth_succeeds() raises -> None:
    var response = floki.get(
        "https://httpbingo.org/bearer",
        auth=BearerAuth("some-token"),
    )
    assert_equal(response.status, Status.OK)


def test_session_get_with_auth() raises -> None:
    var session = Session()
    var response = session.get(
        "https://httpbingo.org/basic-auth/user/password",
        auth=BasicAuth("user", "password"),
    )
    assert_equal(response.status, Status.OK)


def test_request_headers_override_auth() raises -> None:
    # A request-specific Authorization header should win over the auth argument.
    var response = floki.get(
        "https://httpbingo.org/basic-auth/user/password",
        headers={"Authorization": BasicAuth("user", "password").header_value()},
        auth=BasicAuth("wrong", "wrong"),
    )
    assert_equal(response.status, Status.OK)


def test_custom_auth_scheme() raises -> None:
    # A user-defined Auth scheme can set arbitrary headers via apply().
    var response = floki.get("https://httpbingo.org/headers", auth=ApiKeyAuth("secret123"))
    assert_equal(response.status, Status.OK)
    var body = response.body.as_text()
    assert_true("secret123" in body, "expected custom X-Api-Key header to be echoed back")


def test_form_data_post() raises -> None:
    var response = floki.post(
        "https://httpbingo.org/post",
        data=FormData({"key1": "value1", "key2": "value 2"}),
    )
    assert_equal(response.status, Status.OK)
    var body = response.body.as_text()
    assert_true("key1=value1" in body, "expected form field key1 to be echoed back")
    assert_true("key2=value+2" in body, "expected form field key2 to be echoed back")


def test_form_data_content_type() raises -> None:
    var response = floki.post(
        "https://httpbingo.org/post",
        data=FormData({"key": "value"}),
    )
    assert_equal(response.status, Status.OK)
    var body = response.body.as_text()
    assert_true("application/x-www-form-urlencoded" in body, "expected Content-Type to be form-urlencoded")


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
