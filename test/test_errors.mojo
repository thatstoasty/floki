from floki.errors import ConnectionError, RequestError, TimeoutError, TLSError, TransportError
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


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
