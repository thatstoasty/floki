from floki.errors import ConnectionError, RequestError, TimeoutError, TLSError, TransportError
from floki.session import Session
from floki.timeout import Timeout
from mojo_curl.easy import Result
from std.testing import TestSuite, assert_equal, assert_false, assert_true


# def test_request_error_writes_message() raises -> None:
#     var e = RequestError(kind=ErrorKind.TIMEOUT, url="https://example.com", message="timed out", code=28)
#     assert_equal(String(e), "RequestError [Timeout] for https://example.com: timed out")


def test_request_error_classifies_result_codes() raises -> None:
    assert_true(RequestError(Result.OPERATION_TIMEDOUT).isa[TimeoutError]())
    assert_true(RequestError(Result.COULDNT_CONNECT).isa[ConnectionError]())
    assert_true(RequestError(Result.SSL_CONNECT_ERROR).isa[TLSError]())
    assert_true(RequestError(Result.WRITE_ERROR).isa[TransportError]())


def test_request_error_from_string_wraps_error() raises -> None:
    var e = RequestError(String("Failed to serialize data to JSON"))
    assert_false(e.isa[ConnectionError]())
    assert_equal(String(e), "Failed to serialize data to JSON")


def test_refused_connection_raises_connection_error() raises -> None:
    var session = Session()
    try:
        _ = session.get("http://localhost:1")
    except e:
        assert_true(e.isa[ConnectionError]())
        return
    raise Error("Expected the request to fail.")


def test_timeout_raises_timeout_error() raises -> None:
    var session = Session(timeout=Timeout(total=1))
    try:
        _ = session.get("https://httpbin.org/delay/3")
    except e:
        assert_true(e.isa[TimeoutError]())
        return
    raise Error("Expected the request to time out.")


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
