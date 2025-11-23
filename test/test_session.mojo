from testing import TestSuite, assert_equal
from floki.session import Session
from floki.http import StatusCode


fn test_get() raises -> None:
    print("Running test_get\n")
    var client = Session()
    var response = client.get("https://example.com")

    assert_equal(response.status_code, StatusCode.OK)
    print("Headers:")
    for pair in response.headers.items():
        print(String(pair.key, ": ", pair.value))

    # print("Is connection set to connection-close? ", response.connection_close())

    print(response.body.as_string_slice())


fn test_get_query_parameters() raises -> None:
    print("Running test_get_query_parameters\n")
    var client = Session()
    var response = client.get(
        "https://jsonplaceholder.typicode.com/comments",
        query_parameters={
            "postId": "1",
        }
    )

    assert_equal(response.status_code, StatusCode.OK)
    print("Headers:")
    for pair in response.headers.items():
        print(String(pair.key, ": ", pair.value))

    # print("Is connection set to connection-close? ", response.connection_close())

    print(response.body.as_string_slice())


fn test_post() raises -> None:
    print("Running test_post\n")
    var client = Session()
    var response = client.post(
        "https://jsonplaceholder.typicode.com/todos",
        {
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        data={"key1": "value1", "key2": {"subkey": "value"}},
    )
    print("Headers:")
    for node in response.headers.items():
        print(String(node.key, ": ", node.value))
    
    # print("Body:")
    # print(response.body.as_string_slice())
    assert_equal(response.status_code, StatusCode.CREATED)
    print("Body:")
    for node in response.body.as_json().items():
        print(String(node.key, ": ", node.data))
    
    print(response.body.as_json()["key2"]["subkey"])


fn test_post_file() raises -> None:
    print("Running test_post_file\n")
    var client = Session()

    with open("test/data/file.json", "r") as f:
        var response = client.post(
            "https://jsonplaceholder.typicode.com/todos",
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            data=f,
        )
        assert_equal(response.status_code, StatusCode.CREATED)
        print("Body:")
        for node in response.body.as_json().items():
            print(String(node.key, ": ", node.data))
        
        print(response.body.as_json()["content"]["recently_edited"])


fn test_put() raises -> None:
    print("Running test_put\n")
    var client = Session()
    var response = client.put(
        "https://jsonplaceholder.typicode.com/posts/1",
        {
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        data={"key1": "updated_value1", "key2": "updated_value2"},
    )
    print("PUT Response Body:")
    print(response.body.as_string_slice())
    assert_equal(response.status_code, StatusCode.OK)


fn test_put_file() raises -> None:
    print("Running test_put_file\n")
    var client = Session()

    with open("test/data/update.json", "r") as f:
        var response = client.put(
            "https://jsonplaceholder.typicode.com/posts/1",
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            data=f,
        )
        assert_equal(response.status_code, StatusCode.OK)
        print("Body:")
        for node in response.body.as_json().items():
            print(String(node.key, ": ", node.data))


fn test_patch() raises -> None:
    print("Running test_patch\n")
    var client = Session()
    var response = client.patch(
        "https://jsonplaceholder.typicode.com/posts/1",
        {
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        data={"key1": "patched_value"},
    )
    assert_equal(response.status_code, StatusCode.OK)
    print("PATCH Response Body:")
    print(response.body.as_string_slice())


fn test_patch_file() raises -> None:
    print("Running test_patch_file\n")
    var client = Session()

    with open("test/data/update.json", "r") as f:
        var response = client.patch(
            "https://jsonplaceholder.typicode.com/posts/1",
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            data=f,
        )
        assert_equal(response.status_code, StatusCode.OK)
        print("Body:")
        for node in response.body.as_json().items():
            print(String(node.key, ": ", node.data))


fn test_delete() raises -> None:
    print("Running test_delete\n")
    var client = Session()
    var response = client.delete("https://jsonplaceholder.typicode.com/posts/1")
    assert_equal(response.status_code, StatusCode.OK)
    print("DELETE Response Body:")
    print(response.body.as_string_slice())


fn test_head() raises -> None:
    var client = Session()
    var response = client.head("https://example.com")
    print("HEAD Response Status Code:", response.status_code)
    print("HEAD Response Headers:")
    for pair in response.headers.items():
        print(String(pair.key, ": ", pair.value))


fn test_options() raises -> None:
    var client = Session()
    var response = client.options("https://jsonplaceholder.typicode.com/posts")
    print("OPTIONS Response Status Code:", response.status_code)
    print("OPTIONS Response Headers:")
    for pair in response.headers.items():
        print(String(pair.key, ": ", pair.value))
    print("Methods available:", response.headers["access-control-allow-methods"])


fn main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
    # var suite = TestSuite()
    # suite.test[test_put_file]()
    # suite^.run()
