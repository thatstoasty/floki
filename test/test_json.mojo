import emberjson
from floki.session import Session
from std.testing import TestSuite, assert_equal, assert_true
from std.utils import Variant


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


def test_todo_deserialization() raises -> None:
    var response = Session().get("https://jsonplaceholder.typicode.com/todos/1")
    var expected = Todo(userId=1, id=1, title="delectus aut autem", completed=False)
    assert_equal(response.body.as[Todo](), expected)


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
    # var suite = TestSuite()
    # suite.test[test_options]()
    # suite^.run()
