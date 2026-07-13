import floki
from floki import (
    ConnectionError,
    RequestError,
    TimeoutError,
    TLSError,
    TooManyRedirectsError,
    TransportError,
)
from floki.session import Session
from floki.timeout import Timeout


def main() raises -> None:
    # `floki.get` (and every other request function) raises `RequestError` when the
    # transfer fails before a response is received. `RequestError` wraps one of
    # several concrete error types; use `isa[T]()` to test which one it holds and
    # `error[T]` to pull the concrete value out.

    # A 1ms total timeout guarantees the transfer fails, so we can see the handling.
    var session = Session(timeout=Timeout(total=0.001))

    try:
        var r = session.get("https://example.com")
        print("Got a response:", r.status.code)
    except e:
        # `e` is a `RequestError`. Branch on the underlying kind:
        if e.isa[TimeoutError]():
            print("Request timed out:", e[TimeoutError])
        elif e.isa[ConnectionError]():
            print("Could not reach the server:", e[ConnectionError])
        elif e.isa[TLSError]():
            print("TLS/SSL failure:", e[TLSError])
        elif e.isa[TooManyRedirectsError]():
            print("Too many redirects:", e[TooManyRedirectsError])
        elif e.isa[TransportError]():
            print("Transport-level failure:", e[TransportError])
        else:
            # Any other low-level error carried by the `RequestError`.
            print("Request failed:", e)

    # If you don't care about the category, the `RequestError` is `Writable`, so you
    # can print or format it directly for a human-readable message.
    try:
        _ = session.get("https://example.com")
    except e:
        print("Request failed:", e)
