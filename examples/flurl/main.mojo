"""Flurl: a minimal curl-like HTTP client built with prism and floki."""
from prism import ArgSet, Command, Flag, FlagSet, exact_args, read_args
from std.sys import exit, stderr

from floki import ConnectionError, Headers, RequestError, Response, Session, Timeout, TimeoutError


def parse_headers(raw: List[String]) raises -> Headers:
    """Parses `Key: Value` entries into `Headers`."""
    var headers = Headers()
    for entry in raw:
        var idx = entry.find(":")
        if idx <= 0:
            raise Error("Invalid header, expected 'Key: Value': ", entry)
        headers[String(entry[byte=0:idx].strip())] = String(entry[byte = idx + 1 :].strip())
    return headers^


def resolve_method(flags: FlagSet, has_body: Bool) raises -> String:
    """Chooses the request method: `-I` wins, then `-X`, then POST if a body is given, else GET."""
    if flags.get[Bool]("head").or_else(False):
        return "HEAD"
    var method = flags.get[String]("request")
    if method:
        return method.value().upper()
    return "POST" if has_body else "GET"


def send(
    mut session: Session, method: String, url: String, var headers: Headers, body: String
) raises RequestError -> Response:
    """Dispatches to the floki `Session` method matching `method`."""
    if method == "GET":
        return session.get(url, headers=headers^)
    elif method == "POST":
        return session.post(url, headers=headers^, data=body.as_bytes())
    elif method == "PUT":
        return session.put(url, headers=headers^, data=body.as_bytes())
    elif method == "PATCH":
        return session.patch(url, headers=headers^, data=body.as_bytes())
    elif method == "DELETE":
        return session.delete(url, headers=headers^)
    elif method == "HEAD":
        return session.head(url, headers=headers^)
    elif method == "OPTIONS":
        return session.options(url, headers=headers^)
    raise RequestError(String("Unsupported method: ", method))


def print_head(response: Response):
    """Prints the status line and response headers, followed by a blank line."""
    print("HTTP ", response.status, sep="")
    for entry in response.headers.items():
        print(entry.key, ": ", entry.value, sep="")
    print()


def run(args: ArgSet, flags: FlagSet) raises -> None:
    var url = String(args[0])
    var headers = parse_headers(flags.get[List[String]]("header").or_else([]))

    # `--json` is `-d` plus JSON content headers, without overriding user-supplied ones.
    var body = flags.get[String]("data")
    var json = flags.get[String]("json")
    if json:
        body = json.value()
        if "Content-Type" not in headers:
            headers["Content-Type"] = "application/json"
        if "Accept" not in headers:
            headers["Accept"] = "application/json"

    var method = resolve_method(flags, Bool(body))
    var timeout = Timeout()
    var max_time = flags.get[Float64]("max-time")
    if max_time:
        timeout = Timeout(total=max_time.value())

    var session = Session(
        allow_redirects=flags.get[Bool]("location").or_else(False),
        verbose=flags.get[Bool]("verbose").or_else(False),
        timeout=timeout^,
    )

    # Like curl, `-s` hides error messages but keeps the exit codes.
    var silent = flags.get[Bool]("silent").or_else(False)
    var response: Response
    try:
        response = send(session, method, url, headers^, body.or_else(""))
    except e:
        if not silent:
            print("flurl:", e, file=stderr)
        # Mirror curl's exit codes for the common failure cases.
        if e.isa[ConnectionError]():
            exit(7)
        elif e.isa[TimeoutError]():
            exit(28)
        exit(1)
        return

    if flags.get[Bool]("fail").or_else(False) and response.status.code >= 400:
        if not silent:
            print("flurl: The requested URL returned error:", response.status, file=stderr)
        exit(22)

    if method == "HEAD" or flags.get[Bool]("include").or_else(False):
        print_head(response)
    if method != "HEAD":
        print(response.as_text(), end="")


def main() -> None:
    var cli = Command(
        name="flurl",
        usage="A minimal curl-like HTTP client.",
        run=run,
        arg_validator=exact_args[1](),
        reject_unknown_subcommands=False,
        flags=[
            Flag.new[String](name="request", shorthand="X", usage="HTTP method to use (default: GET, or POST with data)."),
            Flag.new[List[String]](name="header", shorthand="H", usage="Header to send, as 'Key: Value'. Repeatable."),
            Flag.new[String](name="data", shorthand="d", usage="Raw request body."),
            Flag.new[String](name="json", usage="JSON request body; sets Content-Type and Accept to application/json."),
            Flag.new[Bool](name="include", shorthand="i", usage="Print the status line and response headers."),
            Flag.new[Bool](name="head", shorthand="I", usage="Send a HEAD request and print only the headers."),
            Flag.new[Bool](name="location", shorthand="L", usage="Follow redirects."),
            Flag.new[Float64](name="max-time", shorthand="m", usage="Maximum time in seconds for the whole request."),
            Flag.new[Bool](name="verbose", shorthand="v", usage="Print libcurl's verbose transfer output."),
            Flag.new[Bool](name="fail", shorthand="f", usage="Exit with code 22 on HTTP 4xx/5xx responses."),
            Flag.new[Bool](name="silent", shorthand="s", usage="Silent mode. Don't print error messages."),
        ],
        mutually_exclusive_flags=["data", "json"],
    )
    cli.execute(read_args())
