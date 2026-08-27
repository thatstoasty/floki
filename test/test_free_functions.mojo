from floki.http import Status
from std.testing import TestSuite, assert_equal, assert_true

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


@fieldwise_init
struct QueryParameters(Defaultable, Deinitable, Movable):
    var foo: String

    def __init__(out self):
        self.foo = ""


@fieldwise_init
struct ArgResponse(Defaultable, Deinitable, Movable):
    var args: QueryParameters
    var headers: Dict[String, String]
    var origin: String
    var url: String

    def __init__(out self):
        self.args = QueryParameters()
        self.headers = Dict[String, String]()
        self.origin = ""
        self.url = ""


def test_get_with_query_parameters() raises -> None:
    var response = floki.get(
        "https://httpbin.org/get",
        query_parameters={"foo": "bar"},
    )
    assert_equal(response.status, Status.OK)
    assert_equal(response.body.as[ArgResponse]().args.foo, "bar")


@fieldwise_init
struct CustomHeaderResponse(Defaultable, Deinitable, Movable):
    var args: Dict[String, String]
    var headers: Dict[String, String]
    var origin: String
    var url: String

    def __init__(out self):
        self.args = Dict[String, String]()
        self.headers = Dict[String, String]()
        self.origin = ""
        self.url = ""


def test_get_with_custom_headers() raises -> None:
    var response = floki.get(
        "https://httpbin.org/get",
        headers={"X-Custom-Header": "floki-test"},
    )
    assert_equal(response.status, Status.OK)
    assert_equal(
        response.body.as[CustomHeaderResponse]().headers["X-Custom-Header"],
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


@fieldwise_init
struct PostPayload(Defaultable, Deinitable, Equatable, Movable, Writable):
    var title: String
    var body: String
    var userId: Int

    def __init__(out self):
        self.title = ""
        self.body = ""
        self.userId = 0


def test_post_struct() raises -> None:
    var response = floki.post(
        "https://jsonplaceholder.typicode.com/todos",
        data=PostPayload(title="test title", body="test body", userId=1),
        headers={"Content-Type": "application/json"},
    )
    assert_equal(response.status, Status.CREATED)


@fieldwise_init
struct UpdatePayload(Defaultable, Deinitable, Equatable, Movable, Writable):
    var key1: String
    var key2: String

    def __init__(out self):
        self.key1 = ""
        self.key2 = ""


def test_put_struct() raises -> None:
    var response = floki.put(
        "https://jsonplaceholder.typicode.com/posts/1",
        data=UpdatePayload(key1="updated_value1", key2="updated_value2"),
        headers={"Content-Type": "application/json"},
    )
    assert_equal(response.status, Status.OK)


@fieldwise_init
struct PatchPayload(Defaultable, Deinitable, Equatable, Movable, Writable):
    var key1: String

    def __init__(out self):
        self.key1 = ""


def test_patch_struct() raises -> None:
    var response = floki.patch(
        "https://jsonplaceholder.typicode.com/todos/1",
        data=PatchPayload(key1="patched_value"),
        headers={"Content-Type": "application/json"},
    )
    assert_equal(response.status, Status.OK)


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
    # var suite = TestSuite()
    # suite.test[test_patch]()
    # suite^.run()
