import emberjson
from emberjson import Object, Value
from flare.http import Extracted, Handler, HttpServer, PathInt, Request, Response, Router, ok
from flare.prelude import *  # Request, Response, Router, HttpServer, ok, ok_json, SocketAddr, ...
from slight import Connection
from std.pathlib import Path


@fieldwise_init
struct User(Defaultable, Movable, Writable, Deinitable):
    var id: Int
    var name: String
    var email: String

    def __init__(out self):
        self.id = 0
        self.name = ""
        self.email = ""


# There's issues with threading and use of sqlite, passing a pointer to the connection
# Leads to a sqlite misuse error. So we just open a new connection for each request. This is not ideal, but it works for this example.
@fieldwise_init
struct GetUserHandler(Copyable, Handler, Movable):
    var db_path: Path

    def serve(self, req: Request) raises -> Response:
        var db = Connection.open(self.db_path)
        var id = Int(req.param("id"))
        print(t"GET /users/{id}")
        var stmt = db.prepare("SELECT id, name, email FROM users WHERE id = ? LIMIT 1;")
        var rows = stmt.query[User]((id,))
        var row = rows.next()
        # Checked before `.value()`, which aborts the whole process on an empty
        # `Optional` rather than raising -- no `except` can catch it.
        if not row:
            return Response(status=404, body=List("User not found".as_bytes()))

        var value: String
        try:
            value = emberjson.to_json(row.value())
        except:
            return Response(status=500, body=List("Could not serialize user.".as_bytes()))

        return ok(value)


def main() raises:
    var path = Path("todo.db")
    var db = Connection.open(path)
    db.execute_batch(
        """
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE
    );
    INSERT OR IGNORE INTO users (name, email) VALUES ('Alice', 'alice@example.com');
    INSERT OR IGNORE INTO users (name, email) VALUES ('Bob', 'bob@example.com');
    """
    )

    var r = Router()
    r.get("/users/:id", GetUserHandler(path))

    var srv = HttpServer.bind(SocketAddr.localhost(8080))
    print("server listening on http://localhost:8080")
    srv.serve(r^)
