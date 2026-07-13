from floki.errors import ErrorKind, RequestError
from mojo_curl.easy import Result
from std.testing import TestSuite, assert_equal, assert_true


def test_classify_timeout() raises -> None:
    assert_true(ErrorKind.from_result(Result.OPERATION_TIMEDOUT) == ErrorKind.TIMEOUT)


def test_classify_connection() raises -> None:
    assert_true(ErrorKind.from_result(Result.COULDNT_CONNECT) == ErrorKind.CONNECTION)
    assert_true(ErrorKind.from_result(Result.COULDNT_RESOLVE_HOST) == ErrorKind.CONNECTION)
    assert_true(ErrorKind.from_result(Result.COULDNT_RESOLVE_PROXY) == ErrorKind.CONNECTION)
    assert_true(ErrorKind.from_result(Result.GOT_NOTHING) == ErrorKind.CONNECTION)
    assert_true(ErrorKind.from_result(Result.SEND_ERROR) == ErrorKind.CONNECTION)
    assert_true(ErrorKind.from_result(Result.RECV_ERROR) == ErrorKind.CONNECTION)


def test_classify_tls() raises -> None:
    assert_true(ErrorKind.from_result(Result.SSL_CONNECT_ERROR) == ErrorKind.TLS)
    assert_true(ErrorKind.from_result(Result.PEER_FAILED_VERIFICATION) == ErrorKind.TLS)


def test_classify_too_many_redirects() raises -> None:
    assert_true(ErrorKind.from_result(Result.TOO_MANY_REDIRECTS) == ErrorKind.TOO_MANY_REDIRECTS)


def test_classify_unknown_falls_back_to_transport() raises -> None:
    # A code with no specific classification (OK) falls through to TRANSPORT.
    assert_true(ErrorKind.from_result(Result.OK) == ErrorKind.TRANSPORT)


def test_error_kind_writes_name() raises -> None:
    assert_equal(String.write(ErrorKind.TIMEOUT), "Timeout")
    assert_equal(String.write(ErrorKind.CONNECTION), "Connection")
    assert_equal(String.write(ErrorKind.TLS), "TLS")
    assert_equal(String.write(ErrorKind.TOO_MANY_REDIRECTS), "TooManyRedirects")
    assert_equal(String.write(ErrorKind.TRANSPORT), "Transport")


# def test_request_error_writes_message() raises -> None:
#     var e = RequestError(kind=ErrorKind.TIMEOUT, url="https://example.com", message="timed out", code=28)
#     assert_equal(String.write(e), "RequestError [Timeout] for https://example.com: timed out")


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
