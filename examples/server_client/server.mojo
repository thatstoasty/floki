from flare.prelude import *  # Request, Response, Router, HttpServer, ok, ok_json, SocketAddr, ...


def home(req: Request) -> Response:  # no raises - body cannot fail
    return ok("flare is up")


def health(req: Request) -> Response:  # no raises - static JSON
    return ok_json('{"status":"ok"}')


def greet(req: Request) raises -> Response:  # raises - req.param("name")
    return ok("hello, " + req.param("name"))  #   raises if :name is missing


def main() raises:
    var r = Router()
    r.get("/", home)
    r.get("/hi/:name", greet)
    r.get("/health", health)

    var srv = HttpServer.bind(SocketAddr.localhost(8080))
    print("server listening on http://localhost:8080")
    srv.serve(r^)
