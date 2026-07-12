# floki

A `requests` like HTTP client for Mojo, leveraging `libcurl` under the hood.

![Mojo Version](https://img.shields.io/badge/Mojo%F0%9F%94%A5-1.0.0b2-orange)
![Build Status](https://github.com/thatstoasty/floki/actions/workflows/build.yml/badge.svg)
![Test Status](https://github.com/thatstoasty/floki/actions/workflows/test.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

```mojo
import floki

def main() raises -> None:
    var response = floki.get("https://example.com")
    for pair in response.headers.items():
        print(pair.key, ": ", pair.value)
    print(response.as_text())
```

## Adding the `floki` package to your project

### Pre-requisites

You'll need to enable the `pixi-build` preview by adding this to the workspace section of your `pixi.toml` file.

```bash
preview = ["pixi-build"]
```

### Building it from source

There's two ways to build `floki` from source: directly from the Git repository or by cloning the repository locally.

#### Building from source: Git

Run the following commands in your terminal:

```bash
pixi add floki --git "https://github.com/thatstoasty/floki.git" --tag v0.3.4 && pixi install
```

#### Building from source: Local

```bash
# Clone the repository to your local machine
git clone https://github.com/thatstoasty/floki.git

# Add the package to your project from the local path
pixi add -s ./path/to/floki && pixi install
```

## Configuring library paths

> Note: Mojo cannot currently support calling C functions with variadic arguments, and the libcurl client interface makes heavy use of them. Floki uses my small shim C library `curl_wrapper`, which provides a thin wrapper around libcurl to avoid this issue.

Floki leverages `mojo-curl` as an FFI interface to `libcurl`, and it needs to locate two dynamic libraries at runtime: `libcurl` and `libcurl_wrapper` (the thin C shim that wraps libcurl's variadic functions).

### Default behavior

By default, the library looks for both in your project's Pixi environment:

| Library | macOS | Linux |
| --- | --- | --- |
| libcurl | `.pixi/envs/default/lib/libcurl.dylib` | `.pixi/envs/default/lib/libcurl.so` |
| curl_wrapper | `.pixi/envs/default/lib/libcurl_wrapper.dylib` | `.pixi/envs/default/lib/libcurl_wrapper.so` |

If you're working in a Pixi environment, the libraries will already be in the expected location and no additional configuration is needed.

### Custom library paths

If your libraries are in a different location, you can override the paths using either **environment variables** or **compile-time defines**.

#### Environment variables

Set `LIBCURL_LIB_PATH` and `CURL_WRAPPER_LIB_PATH` before running your program:

```bash
export LIBCURL_LIB_PATH="/usr/lib/libcurl.so"
export CURL_WRAPPER_LIB_PATH="/opt/mylibs/libcurl_wrapper.so"
mojo run my_program.mojo
```

#### Compile-time defines

Pass the paths as `-D` flags when compiling or running:

```bash
mojo run -D LIBCURL_LIB_PATH="/usr/lib/libcurl.so" -D CURL_WRAPPER_LIB_PATH="/opt/mylibs/libcurl_wrapper.so" my_program.mojo
```

Compile-time defines take priority over environment variables. If neither is set, the default Pixi environment paths are used.

## Features

Floki aims to provide a `requests`-like experience on top of `libcurl`.

- All standard HTTP methods: `get`, `post`, `put`, `patch`, `delete`, `head`, and `options`.
- One-shot free functions (`floki.get(...)`) or a reusable `Session` that persists configuration across requests.
- Request bodies from JSON, form-encoded data, raw bytes, files, or your own structs.
- Authentication helpers (Basic, Bearer) plus a pluggable `Auth` trait for custom schemes.
- Query parameters, custom headers, and automatic redirect handling.
- Cookie parsing and a cookie jar.
- Ergonomic responses: status-class checks, body as text/bytes/typed or dynamic JSON, and case-insensitive headers.
- Session-level timeout, retry-with-backoff, proxy, and TLS verification controls.

### Methods

Every method is available both as a free function and as a `Session` method:

```mojo
import floki
from floki.session import Session

def main() raises -> None:
    var r = floki.get("https://httpbin.org/get")

    var session = Session()
    var r2 = session.delete("https://httpbin.org/delete")
```

### Request bodies: JSON, forms, and more

Pass a dictionary literal to send JSON, or wrap it in `FormData` for
`application/x-www-form-urlencoded`:

```mojo
import floki
from floki.forms import FormData

def main() raises -> None:
    # JSON body (Content-Type: application/json)
    var r = floki.post("https://httpbin.org/post", data={"key": "value"})

    # Form-encoded body (Content-Type: application/x-www-form-urlencoded)
    var r2 = floki.post("https://httpbin.org/post", data=FormData({"key": "value"}))
```

Raw bytes, file handles, and arbitrary `Writable` structs can also be sent as the body.

### Working with responses

A `Response` exposes the status, headers, and body, with convenience accessors for
the common cases:

```mojo
import floki

def main() raises -> None:
    var r = floki.get("https://httpbin.org/get")

    # Status checks by class (1xx-5xx), plus the exact `is_ok` (200 only).
    if r.is_success():        # any 2xx
        print(r.status.code, r.reason())
    if r.is_client_error() or r.is_server_error():
        r.raise_for_status()  # raises HTTPError on a non-2xx response

    # Body as text, raw bytes, or JSON.
    print(r.as_text())                    # StringSlice over the body
    var data = r.as_json()                # dynamic JSON, e.g. data["url"]

    # Headers are looked up case-insensitively.
    print(r.content_type())            # value of the Content-Type header
    print(r.header("x-request-id", "<none>"))
```

For typed JSON, deserialize straight into a struct with `r.as[T]()`:

```mojo
import floki

@fieldwise_init
struct Todo(Defaultable, ImplicitlyDestructible, Movable):
    var id: Int
    var title: String

    def __init__(out self):
        self.id = 0
        self.title = ""

def main() raises -> None:
    var r = floki.get("https://jsonplaceholder.typicode.com/todos/1")
    var todo = r.as[Todo]()
    print(todo.id, todo.title)
```

`raise_for_status()` treats any 2xx as success, so `201 Created` and `204 No Content`
do not raise.

### Handling request errors

When a request fails *before* a usable response comes back — a DNS failure, a refused
connection, a timeout, a TLS problem — floki raises a `RequestError`. (This is distinct
from `HTTPError`, which `raise_for_status()` raises when a response *was* received but
carried a non-2xx status.)

A `RequestError` wraps one of several concrete error types:

| Concrete type | Raised when |
| --- | --- |
| `TimeoutError` | The request exceeded its configured timeout. |
| `ConnectionError` | The server couldn't be reached (DNS failure, refused/dropped connection). |
| `TLSError` | A TLS/SSL handshake or certificate-verification failure. |
| `TooManyRedirectsError` | The request followed more redirects than allowed. |
| `TransportError` | Any other transport-level failure. |

Use `error.isa[T]()` to test which type it holds and `error[T]` to pull the concrete
value out:

```mojo
import floki
from floki import ConnectionError, TimeoutError, TLSError

def main() raises -> None:
    try:
        var r = floki.get("https://example.com")
        print(r.status.code)
    except e:  # `e` is a `RequestError`
        if e.isa[TimeoutError]():
            print("Timed out:", e[TimeoutError])
        elif e.isa[ConnectionError]():
            print("Could not connect:", e[ConnectionError])
        elif e.isa[TLSError]():
            print("TLS failure:", e[TLSError])
        else:
            print("Request failed:", e)
```

- `error.isa[T]()` returns `True` when the `RequestError` currently holds a value of
  type `T`.
- `error[T]` (the `__getitem_param__` subscript) returns the underlying value of type
  `T`. Only call it after `isa[T]()` has confirmed the type.

If you don't need to branch on the category, a `RequestError` is `Writable`, so you can
print or format it directly for a human-readable message.

### Authentication

Basic and Bearer helpers are built in, and any type implementing the `Auth` trait
can supply its own headers. Authentication is provided per request:

```mojo
import floki
from floki import Headers
from floki.auth import Auth, BasicAuth, BearerAuth

def main() raises -> None:
    var r = floki.get("https://httpbin.org/basic-auth/user/pass", auth=BasicAuth("user", "pass"))
    var r2 = floki.get("https://api.example.com/me", auth=BearerAuth("my-token"))

# Custom scheme: implement `apply` to set whatever headers you need.
@fieldwise_init
struct ApiKeyAuth(Auth):
    var key: String

    def apply(self, mut headers: Headers):
        headers["X-Api-Key"] = self.key
```

A header you set explicitly on the request always takes precedence over the `auth` argument.

### Query parameters

```mojo
import floki

def main() raises -> None:
    var r = floki.get("https://httpbin.org/get", query_parameters={"q": "mojo", "page": "1"})
```

### Timeouts

Configure granular connect/total timeouts (in seconds) on a `Session`. A bare number
is treated as the total timeout:

```mojo
from floki.session import Session
from floki.timeout import Timeout

def main() raises -> None:
    var session = Session(timeout=Timeout(connect=5.0, total=30.0))
    var quick = Session(timeout=10)  # 10 second total timeout
    var r = session.get("https://example.com")
```

### Retries with backoff

Retry failed transfers and retryable status codes with exponential backoff:

```mojo
from floki.session import Session
from floki.retry import Retry

def main() raises -> None:
    var session = Session(
        retry=Retry(max_retries=3, backoff_factor=0.5, status_forcelist=[500, 502, 503, 504])
    )
    var r = session.get("https://example.com")
```

The delay before retry _n_ is `backoff_factor * 2 ** (n - 1)` seconds.

### Proxies

```mojo
from floki.session import Session
from floki.proxy import Proxy

def main() raises -> None:
    var session = Session(proxy=Proxy("http://proxy.example:8080"))

    # With credentials and a bypass list:
    var authed = Session(
        proxy=Proxy(
            "http://proxy.example:8080",
            username="user",
            password="secret",
            no_proxy=["localhost", "127.0.0.1"],
        )
    )
    var r = session.get("https://example.com")
```

### TLS verification

TLS certificate and hostname verification is enabled by default. It can be disabled
(use with great caution) or pointed at a custom certificate authority bundle:

```mojo
from std.pathlib import Path
from floki.session import Session
from floki.tls import TLS

def main() raises -> None:
    # Disable verification — only for testing or trusted networks.
    var insecure = Session(tls=TLS(verify=False))

    # Use a custom CA bundle (e.g. a private PKI or self-signed cert).
    var custom = Session(tls=TLS(ca_bundle=Path("/path/to/ca-bundle.pem")))
    var r = custom.get("https://internal.example.com")
```

> `timeout`, `retry`, `proxy`, and `tls` are also accepted directly by the free
> functions (e.g. `floki.get(url, timeout=10)`), which forward them to the one-shot
> `Session` they create internally.

## TODO

### TODO: Features

- Streaming responses — the whole body is buffered into a List[Byte]; large downloads and SSE need incremental access.
- `multipart/form-data` file uploads (files=): today only `x-www-form-urlencoded` is supported, so real file uploads aren't possible.
- Response encoding awareness: `as_text()` assumes UTF-8 and raises otherwise; it ignores the charset in `Content-Type`. At minimum, expose a lossy decode fallback.
- `Accept-Encoding` / transparent decompression: ability to set it so gzip/deflate responses come back decoded (libcurl does this if you enable it).
- Multi-value response headers: Headers wraps `Dict[String, String]`, so repeated headers collapse (`Set-Cookie` is handled separately by the jar, but others are lost).
- Add support for passing Dict data to session methods. Just passing a dict literal is a little limiting. I've tried, but it gets very hairy trying to convert it to an emberjson Value object.

### TODO: Optimizations

- Cleanup cookie parsing code, it seems pretty slow.
- I should update `mojo-curl` bindings to indicate which Easy handle methods mutate the handle. It's deceptive that they're all marked as borrowing self immutably, because it can update the Easy handle's internal state via FFI.

### TODO: Bugs

- Sus out the myriad of bugs and edge cases that may arise as libcurl and requests can do A LOT of things, that I've never used before. Please open issues and open PRs to help address these gaps where possible.

Reminder, this is a hobby project! You're free to fork it and make changes as you see fit.
