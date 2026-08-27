from floki.errors import RequestError
from mojo_curl.easy import Result
from std.testing import TestSuite, assert_equal, assert_true


# def test_request_error_writes_message() raises -> None:
#     var e = RequestError(kind=ErrorKind.TIMEOUT, url="https://example.com", message="timed out", code=28)
#     assert_equal(String(e), "RequestError [Timeout] for https://example.com: timed out")


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
