from testing import TestSuite, assert_equal
from floki.http import Status
import floki

fn test_get() raises -> None:
    var response = floki.get("https://httpbingo.org/get")
    assert_equal(response.status, Status.OK)


fn test_post() raises -> None:
    var response = floki.post(
        "https://jsonplaceholder.typicode.com/todos",
        {
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        data={"key1": "value1", "key2": {"subkey": "value"}},
    )
    assert_equal(response.status, Status.CREATED)


fn test_put() raises -> None:
    var response = floki.put(
        "https://jsonplaceholder.typicode.com/posts/1",
        {
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        data={"key1": "updated_value1", "key2": "updated_value2"},
    )
    assert_equal(response.status, Status.OK)


fn test_patch() raises -> None:
    var response = floki.patch(
        "https://jsonplaceholder.typicode.com/todos/1",
        {
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        data={"key1": "patched_value"},
    )
    assert_equal(response.status, Status.OK)


fn test_delete() raises -> None:
    var response = floki.delete("https://jsonplaceholder.typicode.com/posts/1")
    assert_equal(response.status, Status.OK)


fn test_head() raises -> None:
    var response = floki.head("https://httpbingo.org/head")
    assert_equal(response.status, Status.OK)


fn test_options() raises -> None:
    var response = floki.options("https://jsonplaceholder.typicode.com/posts")
    assert_equal(response.status, Status.NO_CONTENT)
    assert_equal(response.headers["access-control-allow-methods"], "GET,HEAD,PUT,PATCH,POST,DELETE")


fn main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
    # var suite = TestSuite()
    # suite.test[test_patch]()
    # suite^.run()
