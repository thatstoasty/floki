from std.testing import TestSuite, assert_equal, assert_true
from floki.http import Status, Protocol
from floki.body import Body
from floki.response import Response
from floki.cookie.cookie_jar import CookieJar


# === Status ===

def test_status_from_int_200() raises -> None:
    var s = Status(200)
    assert_true(s == Status.OK)


def test_status_from_int_201() raises -> None:
    var s = Status(201)
    assert_true(s == Status.CREATED)


def test_status_from_int_404() raises -> None:
    var s = Status(404)
    assert_true(s == Status.NOT_FOUND)


def test_status_from_int_500() raises -> None:
    var s = Status(500)
    assert_true(s == Status.INTERNAL_ERROR)


def test_status_from_int_invalid_raises() raises -> None:
    var raised = False
    try:
        var _ = Status(999)
    except:
        raised = True
    assert_true(raised)


def test_status_equality() raises -> None:
    assert_true(Status.OK == Status.OK)
    assert_true(not (Status.OK == Status.NOT_FOUND))


def test_status_eq_int() raises -> None:
    assert_true(Status.OK == 200)
    assert_true(not (Status.OK == 201))


def test_status_write_to_ok() raises -> None:
    assert_equal(String.write(Status.OK), "200 OK")


def test_status_write_to_not_found() raises -> None:
    assert_equal(String.write(Status.NOT_FOUND), "404 Not Found")


# === Protocol ===

def test_protocol_from_string_http() raises -> None:
    var p = Protocol("http")
    assert_true(p == Protocol.HTTP)


def test_protocol_from_string_https() raises -> None:
    var p = Protocol("https")
    assert_true(p == Protocol.HTTPS)


def test_protocol_invalid_raises() raises -> None:
    var raised = False
    try:
        var _ = Protocol("ftp")
    except:
        raised = True
    assert_true(raised)


def test_protocol_write_to_http() raises -> None:
    assert_equal(String.write(Protocol.HTTP), "http")


def test_protocol_write_to_https() raises -> None:
    assert_equal(String.write(Protocol.HTTPS), "https")


# === Body ===

def test_body_valid_utf8_from_span() raises -> None:
    var body = Body("hello".as_bytes())
    assert_equal(len(body), 5)


def test_body_empty() raises -> None:
    var body = Body(List[Byte]())
    assert_equal(len(body), 0)


def test_body_as_text() raises -> None:
    var body = Body("hello world".as_bytes())
    assert_equal(String(body.as_text()), "hello world")


def test_body_as_bytes_len() raises -> None:
    var body = Body("hello".as_bytes())
    assert_equal(len(body.as_bytes()), 5)


def test_body_len() raises -> None:
    var body = Body("hello".as_bytes())
    assert_equal(len(body), 5)


struct TestJSON(Movable, Defaultable, ImplicitlyDestructible):
    var name: String

    def __init__(out self):
        self.name = ""


def test_body_as_json_object() raises -> None:
    var body = Body('{"name": "floki"}'.as_bytes())
    assert_equal(body.as_json[TestJSON]().name, "floki")


def test_body_as_json_empty_raises() raises -> None:
    var raised = False
    var body = Body(List[Byte]())
    try:
        var _ = body.as_json[TestJSON]()
    except:
        raised = True
    assert_true(raised)


def test_body_consume() raises -> None:
    var body = Body("hello".as_bytes())
    var bytes = body^.take_bytes()
    assert_equal(len(bytes), 5)


# === Response ===

def test_http_response_is_ok_true() raises -> None:
    var response = Response(
        body=List[Byte](), cookies=CookieJar(),
        status=Status.OK, protocol=Protocol.HTTPS,
    )
    assert_true(response.is_ok())


def test_http_response_is_ok_false_for_201() raises -> None:
    # is_ok() only matches status 200 exactly — 201 Created also returns False
    var response = Response(
        body=List[Byte](), cookies=CookieJar(),
        status=Status.CREATED, protocol=Protocol.HTTPS,
    )
    assert_true(not response.is_ok())


def test_http_response_is_ok_false_for_404() raises -> None:
    var response = Response(
        body=List[Byte](), cookies=CookieJar(),
        status=Status.NOT_FOUND, protocol=Protocol.HTTPS,
    )
    assert_true(not response.is_ok())


def test_http_response_is_redirect_301() raises -> None:
    var response = Response(
        body=List[Byte](), cookies=CookieJar(),
        status=Status.MOVED_PERMANENTLY, protocol=Protocol.HTTP,
    )
    assert_true(response.is_redirect())


def test_http_response_is_redirect_302() raises -> None:
    var response = Response(
        body=List[Byte](), cookies=CookieJar(),
        status=Status.FOUND, protocol=Protocol.HTTP,
    )
    assert_true(response.is_redirect())


def test_http_response_is_redirect_307() raises -> None:
    var response = Response(
        body=List[Byte](), cookies=CookieJar(),
        status=Status.TEMPORARY_REDIRECT, protocol=Protocol.HTTP,
    )
    assert_true(response.is_redirect())


def test_http_response_is_redirect_308() raises -> None:
    var response = Response(
        body=List[Byte](), cookies=CookieJar(),
        status=Status.PERMANENT_REDIRECT, protocol=Protocol.HTTP,
    )
    assert_true(response.is_redirect())


def test_http_response_is_not_redirect_200() raises -> None:
    var response = Response(
        body=List[Byte](), cookies=CookieJar(),
        status=Status.OK, protocol=Protocol.HTTPS,
    )
    assert_true(not response.is_redirect())


def test_http_response_raise_for_status_passes_on_200() raises -> None:
    var response = Response(
        body=List[Byte](), cookies=CookieJar(),
        status=Status.OK, protocol=Protocol.HTTPS,
    )
    try:
        response.raise_for_status()  # must not raise
    except e:
        raise Error(t"raise_for_status raised unexpectedly on 200 OK: {e}")


def test_http_response_raise_for_status_raises_on_404() raises -> None:
    var response = Response(
        body=List[Byte](), cookies=CookieJar(),
        status=Status.NOT_FOUND, protocol=Protocol.HTTPS,
    )
    try:
        response.raise_for_status()
    except HTTPError:
        return
    
    raise Error("raise_for_status did not raise on 404")


def test_http_response_raise_for_status_raises_on_500() raises -> None:
    var response = Response(
        body=List[Byte](), cookies=CookieJar(),
        status=Status.INTERNAL_ERROR, protocol=Protocol.HTTP,
    )
    try:
        response.raise_for_status()
    except:
        return
    
    raise Error("raise_for_status did not raise on 500")


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
