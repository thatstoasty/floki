import emberjson
from floki.cookie.cookie_jar import CookieKey
from floki.http import Protocol, Status
from floki.session import Session
from std.pathlib import Path
from std.testing import TestSuite, assert_equal, assert_false, assert_true
from std.utils import Variant

from floki.cookie.cookie import Cookie


def assert_variant_equal(expected: Variant[Int, String, Bool], actual: emberjson.Value) raises -> None:
    if actual.is_int() and expected.isa[Int]():
        assert_equal(Int64(expected[Int]), actual.int())
    elif actual.is_string() and expected.isa[String]():
        assert_equal(expected[String], actual.string())
    elif actual.is_bool() and expected.isa[Bool]():
        assert_equal(expected[Bool], actual.bool())


def assert_variant_equal2(expected: Variant[Int, String], actual: emberjson.Value) raises -> None:
    if actual.is_int() and expected.isa[Int]():
        assert_equal(Int64(expected[Int]), actual.int())
    elif actual.is_string() and expected.isa[String]():
        assert_equal(expected[String], actual.string())


@fieldwise_init
struct Todo(Defaultable, Equatable, ImplicitlyDestructible, Movable, Writable):
    var userId: Int
    var id: Int
    var title: String
    var completed: Bool

    def __init__(out self):
        self.userId = 0
        self.id = 0
        self.title = ""
        self.completed = False


def test_get() raises -> None:
    var session = Session()
    var response = session.get("https://jsonplaceholder.typicode.com/todos/1")
    assert_equal(response.status, Status.OK)

    var todo = response.body.as[Todo]()
    assert_equal(todo.userId, 1)
    assert_equal(todo.id, 1)
    assert_equal(todo.title, "delectus aut autem")
    assert_equal(todo.completed, False)


@fieldwise_init
struct Record(Defaultable, Equatable, ImplicitlyDestructible, Movable, Writable):
    var userId: Int
    var body: String
    var title: String
    var active: Bool

    def __init__(out self):
        self.userId = 0
        self.body = ""
        self.title = ""
        self.active = False


@fieldwise_init
struct ServerPostResponse(Defaultable, Equatable, ImplicitlyDestructible, Movable, Writable):
    var args: Dict[String, String]
    var headers: Dict[String, emberjson.Value]
    var method: String
    var origin: String
    var url: String
    var data: String
    var files: Dict[String, String]
    var form: Dict[String, String]
    var json: Record

    def __init__(out self):
        self.args = Dict[String, String]()
        self.headers = Dict[String, emberjson.Value]()
        self.method = ""
        self.origin = ""
        self.url = ""
        self.data = ""
        self.files = Dict[String, String]()
        self.form = Dict[String, String]()
        self.json = Record()


def test_post() raises -> None:
    var session = Session()
    var response = session.post(
        "https://httpbingo.org/post",
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "floki-test-client/0.1",
        },
        data={"title": "booggg", "body": "bar", "userId": 1, "active": True},
    )

    assert_equal(response.status, Status.OK)  # Should be 201, but httpbingo returns 200?

    var post_response = response.body.as[ServerPostResponse]()
    assert_equal(post_response.json.userId, 1)
    assert_equal(post_response.json.body, "bar")
    assert_equal(post_response.json.title, "booggg")
    assert_equal(post_response.json.active, True)


struct Content(Defaultable, Equatable, ImplicitlyDestructible, Movable, Writable):
    var recently_edited: List[String]

    def __init__(out self):
        self.recently_edited = List[String]()


struct FileContent(Defaultable, Equatable, ImplicitlyDestructible, Movable, Writable):
    var id: Int
    var name: String
    var content: Content

    def __init__(out self):
        self.id = 0
        self.name = ""
        self.content = Content()


def test_post_file() raises -> None:
    with open("test/data/file.json", "r") as f:
        var session = Session()
        var response = session.post(
            "https://jsonplaceholder.typicode.com/todos",
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            data=f,
        )
        assert_equal(response.status, Status.CREATED)

        file_content = response.body.as[FileContent]()
        assert_equal(file_content.name, "file.json")
        assert_equal(file_content.content.recently_edited, ["floki/session.mojo"])


struct PutResponse(Defaultable, Equatable, ImplicitlyDestructible, Movable, Writable):
    var id: Int
    var key1: String
    var key2: String

    def __init__(out self):
        self.id = 0
        self.key1 = ""
        self.key2 = ""


def test_put() raises -> None:
    var session = Session()
    var response = session.put(
        "https://jsonplaceholder.typicode.com/posts/1",
        {
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        data={"key1": "updated_value1", "key2": "updated_value2"},
    )
    assert_equal(response.status, Status.OK)

    var put_response = response.body.as[PutResponse]()
    assert_equal(put_response.id, 1)
    assert_equal(put_response.key1, "updated_value1")
    assert_equal(put_response.key2, "updated_value2")


struct PutFileResponse(Defaultable, Equatable, ImplicitlyDestructible, Movable, Writable):
    var id: Int
    var key1: String

    def __init__(out self):
        self.id = 0
        self.key1 = ""


def test_put_file() raises -> None:
    with open("test/data/update.json", "r") as f:
        var session = Session()
        var response = session.put(
            "https://jsonplaceholder.typicode.com/posts/1",
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            data=f,
        )
        assert_equal(response.status, Status.OK)

        var put_file_response = response.body.as[PutFileResponse]()
        assert_equal(put_file_response.id, 1)
        assert_equal(put_file_response.key1, "patched_value")


@fieldwise_init
struct PatchedTodo(Defaultable, Equatable, ImplicitlyDestructible, Movable, Writable):
    var userId: Int
    var id: Int
    var title: String
    var body: String
    var key1: String

    def __init__(out self):
        self.userId = 0
        self.id = 0
        self.title = ""
        self.body = ""
        self.key1 = ""


def test_patch() raises -> None:
    var session = Session()
    var response = session.patch(
        "https://jsonplaceholder.typicode.com/posts/1",
        {
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        data={"key1": "patched_value"},
    )
    assert_equal(response.status, Status.OK)

    var patched_todo = response.body.as[PatchedTodo]()
    assert_equal(patched_todo.userId, 1)
    assert_equal(patched_todo.id, 1)
    assert_equal(patched_todo.title, "sunt aut facere repellat provident occaecati excepturi optio reprehenderit")
    assert_equal(
        patched_todo.body,
        (
            "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas"
            " totam\nnostrum rerum est autem sunt rem eveniet architecto"
        ),
    )
    assert_equal(patched_todo.key1, "patched_value")


def test_patch_file() raises -> None:
    with open("test/data/update.json", "r") as f:
        var session = Session()
        var response = session.patch(
            "https://jsonplaceholder.typicode.com/posts/1",
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            data=f,
        )
        assert_equal(response.status, Status.OK)

        var patched_todo = response.body.as[PatchedTodo]()
        assert_equal(patched_todo.userId, 1)
        assert_equal(patched_todo.id, 1)
        assert_equal(patched_todo.title, "sunt aut facere repellat provident occaecati excepturi optio reprehenderit")
        assert_equal(
            patched_todo.body,
            (
                "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas"
                " totam\nnostrum rerum est autem sunt rem eveniet architecto"
            ),
        )
        assert_equal(patched_todo.key1, "patched_value")


def test_delete() raises -> None:
    var session = Session()
    var response = session.delete("https://jsonplaceholder.typicode.com/posts/1")
    assert_equal(response.status, Status.OK)


def test_head() raises -> None:
    var session = Session()
    var response = session.head("https://httpbingo.org/head")
    assert_equal(response.status, Status.OK)


def test_options() raises -> None:
    var session = Session()
    var response = session.options("https://jsonplaceholder.typicode.com/posts")
    assert_equal(response.status, Status.NO_CONTENT)
    assert_equal(response.headers["access-control-allow-methods"], "GET,HEAD,PUT,PATCH,POST,DELETE")


def test_cookie_parsing() raises -> None:
    var session = Session()
    var response = session.get(
        "https://httpbin.org/cookies/set",
        query_parameters={"freeform": "my_val"},
    )
    assert_equal(response.status, Status.OK)
    assert_equal(response.cookies[CookieKey("freeform", "httpbin.org", path="/")].value, "my_val")


def test_session_reuse() raises -> None:
    var session = Session()
    var r1 = session.get("https://jsonplaceholder.typicode.com/todos/1")
    assert_equal(r1.status, Status.OK)
    var r2 = session.get("https://jsonplaceholder.typicode.com/todos/2")
    assert_equal(r2.status, Status.OK)


@fieldwise_init
struct ServerGetResponse(Defaultable, ImplicitlyDestructible, Movable):
    var args: Dict[String, String]
    var headers: Dict[String, String]
    var origin: String
    var url: String

    def __init__(out self):
        self.args = Dict[String, String]()
        self.headers = Dict[String, String]()
        self.origin = ""
        self.url = ""


def test_session_level_headers() raises -> None:
    var session = Session(headers={"X-Floki-Test": "session-headers"})
    var response = session.get(
        "https://httpbin.org/get",
    )
    assert_equal(response.status, Status.OK)
    assert_equal(
        response.body.as[ServerGetResponse]().headers["X-Floki-Test"],
        "session-headers",
    )


def test_session_no_redirects() raises -> None:
    var session = Session(allow_redirects=False)
    var response = session.get("https://httpbin.org/redirect/1")
    assert_true(response.is_redirect())


def test_response_is_ok() raises -> None:
    var session = Session()
    var response = session.get("https://jsonplaceholder.typicode.com/todos/1")
    assert_true(response.is_ok())


def test_response_body_as_bytes() raises -> None:
    var session = Session()
    var response = session.get("https://jsonplaceholder.typicode.com/todos/1")
    assert_true(len(response.body.as_bytes()) > 0)


def test_response_protocol_is_https() raises -> None:
    var session = Session()
    var response = session.get("https://jsonplaceholder.typicode.com/todos/1")
    assert_true(response.protocol == Protocol.HTTPS)


def test_response_raise_for_status_passes_on_200() raises -> None:
    var session = Session()
    var response = session.get("https://jsonplaceholder.typicode.com/todos/1")
    try:
        response.raise_for_status()  # must not raise
    except e:
        raise Error(t"raise_for_status raised unexpectedly on 200 OK: {e}")


def test_response_raise_for_status_raises_on_4xx() raises -> None:
    var raised = False
    var session = Session()
    var response = session.get("https://httpbingo.org/status/404")
    try:
        response.raise_for_status()
    except:
        raised = True
    assert_true(raised)


def test_post_struct() raises -> None:
    var session = Session()
    var response = session.post(
        "https://httpbingo.org/post",
        data=Record(userId=1, body="bar", title="booggg", active=True),
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    assert_equal(response.status, Status.OK)
    var post_response = response.body.as[ServerPostResponse]()
    assert_equal(post_response.json.userId, 1)
    assert_equal(post_response.json.body, "bar")
    assert_equal(post_response.json.title, "booggg")
    assert_equal(post_response.json.active, True)


@fieldwise_init
struct PutStructData(Defaultable, Equatable, ImplicitlyDestructible, Movable, Writable):
    var key1: String
    var key2: String

    def __init__(out self):
        self.key1 = ""
        self.key2 = ""


def test_put_struct() raises -> None:
    var session = Session()
    var response = session.put(
        "https://jsonplaceholder.typicode.com/posts/1",
        data=PutStructData(key1="updated_value1", key2="updated_value2"),
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    assert_equal(response.status, Status.OK)
    var put_response = response.body.as[PutResponse]()
    assert_equal(put_response.id, 1)
    assert_equal(put_response.key1, "updated_value1")
    assert_equal(put_response.key2, "updated_value2")


@fieldwise_init
struct PatchStructData(Defaultable, Equatable, ImplicitlyDestructible, Movable, Writable):
    var key1: String

    def __init__(out self):
        self.key1 = ""


def test_patch_struct() raises -> None:
    var session = Session()
    var response = session.patch(
        "https://jsonplaceholder.typicode.com/posts/1",
        data=PatchStructData(key1="patched_value"),
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    assert_equal(response.status, Status.OK)
    var patched_todo = response.body.as[PatchedTodo]()
    assert_equal(patched_todo.userId, 1)
    assert_equal(patched_todo.id, 1)
    assert_equal(patched_todo.key1, "patched_value")


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
    # var suite = TestSuite()
    # suite.test[test_tls_settings]()
    # suite^.run()
