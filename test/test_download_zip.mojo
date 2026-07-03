from floki.auth import BasicAuth
from floki.http import Status
from std.testing import TestSuite, assert_equal, assert_true

import floki


def test_download_zip() raises -> None:
    var response = floki.get("https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-zip-file.zip")
    assert_equal(response.status, Status.OK)

    var content_type = response.headers["content-type"]
    assert_true(
        content_type.startswith("application/zip") or content_type.startswith("application/octet-stream"),
        String(t"expected zip content-type, got: {content_type}"),
    )

    var body = response.body.as_bytes()
    assert_true(len(body) > 0, "zip body should not be empty")

    # ZIP magic bytes: PK\x03\x04
    assert_equal(Int(body[0]), 0x50)  # 'P'
    assert_equal(Int(body[1]), 0x4B)  # 'K'
    assert_equal(Int(body[2]), 0x03)
    assert_equal(Int(body[3]), 0x04)


def test_authorization_header() raises -> None:
    var response = floki.get(
        "https://httpbingo.org/basic-auth/user/password",
        auth=BasicAuth("user", "password"),
    )
    assert_equal(response.status, Status.OK)

    var response_unauth = floki.get("https://httpbingo.org/basic-auth/user/password")
    assert_equal(response_unauth.status, Status.UNAUTHORIZED)


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
