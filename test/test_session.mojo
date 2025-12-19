from utils import Variant
from testing import TestSuite, assert_equal, assert_true
import emberjson
from floki.session import Session
from floki.http import Status
from floki.cookie.cookie_jar import CookieKey


fn assert_variant_equal(expected: Variant[Int, String, Bool], actual: emberjson.Value) raises -> None:
    if actual.is_int() and expected.isa[Int]():
        assert_equal(Int64(expected[Int]), actual.int())
    elif actual.is_string() and expected.isa[String]():
        assert_equal(expected[String], actual.string())
    elif actual.is_bool() and expected.isa[Bool]():
        assert_equal(expected[Bool], actual.bool())


fn assert_variant_equal2(expected: Variant[Int, String], actual: emberjson.Value) raises -> None:
    if actual.is_int() and expected.isa[Int]():
        assert_equal(Int64(expected[Int]), actual.int())
    elif actual.is_string() and expected.isa[String]():
        assert_equal(expected[String], actual.string())


fn test_get() raises -> None:
    var response = Session().get("https://jsonplaceholder.typicode.com/todos/1")
    assert_equal(response.status, Status.OK)
    var expected: Dict[String, Variant[Int, String, Bool]] = {
        "userId": 1, "id": 1, "title": "delectus aut autem", "completed": False
    }
    for node in response.body.as_json().object().items():
        assert_variant_equal(expected[node.key], node.data)


fn test_post() raises -> None:
    var response = Session().post(
        "https://httpbingo.org/post",
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "floki-test-client/0.1",
        },
        data={"title": "booggg", "body": "bar", "userId": 1, "active": True},
    )

    assert_equal(response.status, Status.OK) # Should be 201, but httpbingo returns 200?
    var expected: Dict[String, Variant[Int, String, Bool]] = {
        "title": "booggg", "body": "bar", "userId": 1, "active": True
    }
    for node in response.body.as_json()["json"].object().items():
        assert_variant_equal(expected[node.key], node.data)
    

fn test_post_file() raises -> None:
    var expected: Dict[String, Variant[String, Dict[String, List[String]]]] = {
        "name": "file.json",
    }
    var content = {
        "recently_edited": [
            "floki/session.mojo"
        ]
    }
    expected["content"] = content^
    with open("test/data/file.json", "r") as f:
        var response = Session().post(
            "https://jsonplaceholder.typicode.com/todos",
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            data=f,
        )
        assert_equal(response.status, Status.CREATED)
        for node in response.body.as_json().object().items():
            if node.data.is_string():
                assert_equal(expected[node.key][String], node.data.string())
            elif node.data.is_object():
                for subnode in node.data.object().items():
                    for item in subnode.data.array():
                        assert_equal(expected[node.key][Dict[String, List[String]]][subnode.key][0], item.string())
                

fn test_put() raises -> None:
    var response = Session().put(
        "https://jsonplaceholder.typicode.com/posts/1",
        {
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        data={"key1": "updated_value1", "key2": "updated_value2"},
    )
    assert_equal(response.status, Status.OK)
    for node in response.body.as_json().object().items():
        assert_true(node.key in ["key1", "key2", "id"])


fn test_put_file() raises -> None:
    var expected: Dict[String, Variant[Int, String]] = {
        "id": 1,
        "key1": "patched_value",
    }
    with open("test/data/update.json", "r") as f:
        var response = Session().put(
            "https://jsonplaceholder.typicode.com/posts/1",
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            data=f,
        )
        assert_equal(response.status, Status.OK)
        for node in response.body.as_json().object().items():
            assert_variant_equal2(expected[node.key], node.data)


fn test_patch() raises -> None:   
    var expected: Dict[String, Variant[Int, String]] = {
        "userId": 1,
        "id": 1,
        "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
        "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto",
        "key1": "patched_value",
    } 
    var response = Session().patch(
        "https://jsonplaceholder.typicode.com/posts/1",
        {
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        data={"key1": "patched_value"},
    )
    assert_equal(response.status, Status.OK)
    for node in response.body.as_json().object().items():
        assert_variant_equal2(expected[node.key], node.data)


fn test_patch_file() raises -> None:
    var expected: Dict[String, Variant[Int, String]] = {
        "userId": 1,
        "id": 1,
        "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
        "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto",
        "key1": "patched_value",
    } 
    with open("test/data/update.json", "r") as f:
        var response = Session().patch(
            "https://jsonplaceholder.typicode.com/posts/1",
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            data=f,
        )
        assert_equal(response.status, Status.OK)
        for node in response.body.as_json().object().items():
            assert_variant_equal2(expected[node.key], node.data)


fn test_delete() raises -> None:    
    var response = Session().delete("https://jsonplaceholder.typicode.com/posts/1")
    assert_equal(response.status, Status.OK)


fn test_head() raises -> None:
    var response = Session().head("https://httpbingo.org/head")
    assert_equal(response.status, Status.OK)


fn test_options() raises -> None:
    var response = Session().options("https://jsonplaceholder.typicode.com/posts")
    assert_equal(response.status, Status.NO_CONTENT)
    assert_equal(response.headers["access-control-allow-methods"], "GET,HEAD,PUT,PATCH,POST,DELETE")


fn test_cookie_parsing() raises -> None:    
    var response = Session().get(
        "https://httpbin.org/cookies/set",
        query_parameters={"freeform": "my_val"},
    )
    assert_equal(response.status, Status.OK)
    assert_equal(response.cookies[CookieKey("freeform", "httpbin.org", path="/")].value, "my_val")


fn main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
    # var suite = TestSuite()
    # suite.test[test_post_file]()
    # suite^.run()
