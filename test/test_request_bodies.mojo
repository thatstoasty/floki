from floki.data import RequestData
from floki.http import RequestMethod, Status
from floki.session import Session
from std.testing import TestSuite, assert_equal, assert_false

import floki


# httpbingo echoes the body as a base64url `data:` URL, and header values as lists.
comptime ECHO = "https://httpbingo.org/anything"
comptime BINARY_DATA_URL = "data:application/octet-stream;base64,AAH_"
"""The echo of the bytes 0x00 0x01 0xFF."""


def _binary_payload() -> List[Byte]:
    return [0x00, 0x01, 0xFF]


def _echoed_data(response: floki.Response) raises -> String:
    return String(response.as_json()["data"].string())


def _echoed_header(response: floki.Response, name: String) raises -> String:
    return String(response.as_json()["headers"][name][0].string())


def test_put_mutable_span_sends_raw_bytes() raises -> None:
    # A mutable span used to resolve to the generic JSON overload and arrive as `[0,1,255]`.
    var payload = _binary_payload()
    var session = Session()
    var response = session.put(ECHO, data=Span(payload), headers={"Content-Type": "application/octet-stream"})
    assert_equal(response.status, Status.OK)
    assert_equal(_echoed_data(response), BINARY_DATA_URL)
    assert_equal(_echoed_header(response, "Content-Type"), "application/octet-stream")


def test_post_string_bytes_sends_raw_bytes() raises -> None:
    var body = String("<Delete><Object><Key>a</Key></Object></Delete>")
    var session = Session()
    var response = session.post(ECHO, data=body.as_bytes(), headers={"Content-Type": "application/xml"})
    assert_equal(response.status, Status.OK)
    assert_equal(_echoed_header(response, "Content-Type"), "application/xml")
    assert_equal(_echoed_header(response, "Content-Length"), String(body.byte_length()))


def test_patch_mutable_span_sends_raw_bytes() raises -> None:
    var payload = _binary_payload()
    var session = Session()
    var response = session.patch(ECHO, data=Span(payload), headers={"Content-Type": "application/octet-stream"})
    assert_equal(response.status, Status.OK)
    assert_equal(_echoed_data(response), BINARY_DATA_URL)


def test_free_function_put_mutable_span_sends_raw_bytes() raises -> None:
    var payload = _binary_payload()
    var response = floki.put(ECHO, data=Span(payload), headers={"Content-Type": "application/octet-stream"})
    assert_equal(response.status, Status.OK)
    assert_equal(_echoed_data(response), BINARY_DATA_URL)


def test_put_empty_body() raises -> None:
    # Used to crash inside libcurl: the post fields pointed at a destroyed temporary.
    var empty = List[Byte]()
    var session = Session()
    var response = session.put(ECHO, data=Span(empty))
    assert_equal(response.status, Status.OK)
    assert_equal(_echoed_data(response), "")
    assert_equal(_echoed_header(response, "Content-Length"), "0")


def test_post_empty_body_is_not_chunked() raises -> None:
    # Used to fall back to `Transfer-Encoding: chunked` with `Expect: 100-continue`.
    var empty = List[Byte]()
    var session = Session()
    var response = session.send[RequestMethod.POST](ECHO, {}, RequestData[ImmOrigin(origin_of(empty))](Span(empty)))
    assert_equal(response.status, Status.OK)
    assert_equal(_echoed_header(response, "Content-Length"), "0")
    assert_false("Transfer-Encoding" in response.as_json()["headers"].object())


def test_patch_empty_body() raises -> None:
    var empty = List[Byte]()
    var session = Session()
    var response = session.patch(ECHO, data=Span(empty))
    assert_equal(response.status, Status.OK)
    assert_equal(_echoed_header(response, "Content-Length"), "0")


def test_dot_segments_are_collapsed_by_default() raises -> None:
    # httpbingo redirects a path with dot segments to its cleaned form, so a 200 means
    # libcurl already collapsed `/a/../b` before sending.
    var session = Session(allow_redirects=False)
    assert_equal(session.get(ECHO + "/a/../b").status, Status.OK)


def test_path_as_is_sends_dot_segments() raises -> None:
    var session = Session(allow_redirects=False, path_as_is=True)
    assert_equal(session.get(ECHO + "/a/../b").status, Status.TEMPORARY_REDIRECT)
    # The option is reapplied after the handle is reset between requests.
    assert_equal(session.get(ECHO + "/c/./d").status, Status.TEMPORARY_REDIRECT)


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
