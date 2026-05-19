from std.testing import TestSuite, assert_equal, assert_true
from floki.http import Status
import floki

def test_get() raises -> None:
    var response = floki.get("https://httpbingo.org/get")
    assert_equal(response.status, Status.OK)


def test_post() raises -> None:
    var response = floki.post(
        "https://jsonplaceholder.typicode.com/todos",
        {
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        data={"key1": "value1", "key2": {"subkey": "value"}},
    )
    assert_equal(response.status, Status.CREATED)


def test_put() raises -> None:
    var response = floki.put(
        "https://jsonplaceholder.typicode.com/posts/1",
        {
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        data={"key1": "updated_value1", "key2": "updated_value2"},
    )
    assert_equal(response.status, Status.OK)


def test_patch() raises -> None:
    var response = floki.patch(
        "https://jsonplaceholder.typicode.com/todos/1",
        {
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        data={"key1": "patched_value"},
    )
    assert_equal(response.status, Status.OK)


def test_delete() raises -> None:
    var response = floki.delete("https://jsonplaceholder.typicode.com/posts/1")
    assert_equal(response.status, Status.OK)


def test_head() raises -> None:
    var response = floki.head("https://httpbingo.org/head")
    assert_equal(response.status, Status.OK)


def test_options() raises -> None:
    var response = floki.options("https://jsonplaceholder.typicode.com/posts")
    assert_equal(response.status, Status.NO_CONTENT)
    assert_equal(response.headers["access-control-allow-methods"], "GET,HEAD,PUT,PATCH,POST,DELETE")


def test_get_with_query_parameters() raises -> None:
    var response = floki.get(
        "https://httpbin.org/get",
        query_parameters={"foo": "bar"},
    )
    assert_equal(response.status, Status.OK)
    assert_equal(response.body.as_json()["args"]["foo"].string(), "bar")


def test_get_with_custom_headers() raises -> None:
    var response = floki.get(
        "https://httpbin.org/get",
        headers={"X-Custom-Header": "floki-test"},
    )
    assert_equal(response.status, Status.OK)
    assert_equal(
        response.body.as_json()["headers"]["X-Custom-Header"].string(),
        "floki-test",
    )


def test_post_raw_bytes() raises -> None:
    var payload = '{"raw": true}'.as_bytes()
    var response = floki.post(
        "https://httpbingo.org/post",
        payload,
        headers={"Content-Type": "application/json"},
    )
    assert_equal(response.status, Status.OK)


def test_put_raw_bytes() raises -> None:
    var payload = '{"updated": true}'.as_bytes()
    var response = floki.put(
        "https://httpbingo.org/put",
        payload,
        headers={"Content-Type": "application/json"},
    )
    assert_equal(response.status, Status.OK)


def test_patch_raw_bytes() raises -> None:
    var payload = '{"patched": true}'.as_bytes()
    var response = floki.patch(
        "https://httpbingo.org/patch",
        payload,
        headers={"Content-Type": "application/json"},
    )
    assert_equal(response.status, Status.OK)


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
    # var suite = TestSuite()
    # suite.test[test_patch]()
    # suite^.run()
