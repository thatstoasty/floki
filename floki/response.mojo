"""The `Response` type used to represent HTTP responses received from a server."""
import emberjson
from floki.body import Body
from floki.cookie.cookie_jar import CookieJar
from floki.headers import Headers
from floki.http import Protocol, Status


comptime WHITESPACE = " "
"""Whitespace character used in HTTP formatting."""
comptime CRLF = "\r\n"
"""Carriage return and line feed characters used in HTTP formatting."""


@fieldwise_init
struct HTTPError(Movable, Writable):
    """An error that is raised when an HTTP response indicates a failure (i.e., a non-2xx status code)."""

    var status: Status
    """The HTTP status code that caused the error."""
    var url: String
    """The URL of the request that produced the error."""
    var body: String
    """A snippet of the response body, for debugging."""

    def write_to(self, mut writer: Some[Writer]) raises:
        """Writes a human-readable description of the error to a writer.

        Args:
            writer: The writer to which the error description will be written.

        Raises:
            Error: If writing to the writer fails.
        """
        writer.write(
            "HTTPError: ",
            self.status.code,
            WHITESPACE,
            self.status.message,
            " for ",
            self.url,
            CRLF,
            self.body,
        )


@fieldwise_init
struct Response(Boolable, Movable, Writable):
    """Represents an HTTP response received from the server."""

    var headers: Headers
    """The HTTP headers included in the response."""
    var cookies: CookieJar
    """The cookies included in the response."""
    var body: Body
    """The body of the response."""
    var status: Status
    """The HTTP status code of the response."""
    var protocol: Protocol
    """The HTTP protocol used in the response."""
    var url: String
    """The final URL of the request, after any redirects."""

    def __init__(
        out self,
        var body: List[Byte],
        var cookies: CookieJar,
        status: Status,
        protocol: Protocol,
        var headers: Headers = Headers(),
        var url: String = String(""),
    ) raises:
        """Constructs an Response from its component parts.

        Args:
            body: The raw response body as a list of bytes.
            cookies: The cookies received in the response.
            status: The HTTP status code of the response.
            protocol: The HTTP protocol used in the response.
            headers: The HTTP headers included in the response.
            url: The final URL of the request, after any redirects.

        Raises:
            Error: If there is a failure in constructing the Body from the provided bytes.
        """
        self.headers = headers^
        self.cookies = cookies^
        self.status = status
        self.protocol = protocol
        self.body = Body(body^)
        self.url = url^

    def write_to(self, mut writer: Some[Writer]) raises:
        """Writes the HTTP response to a writer in a standard HTTP format.

        Args:
            writer: The writer to which the HTTP response will be written.

        Raises:
            Error: If the response body is not valid UTF-8.
        """
        writer.write(
            self.protocol,
            WHITESPACE,
            self.status.code,
            WHITESPACE,
            self.status.message,
            CRLF,
            self.headers,
            CRLF,
            self.body.as_text(),
        )

    @always_inline
    def is_informational(self) -> Bool:
        """Checks if the response status code is informational (1xx).

        Returns:
            True if the status code is in the range 100-199, False otherwise.
        """
        return self.status.code >= 100 and self.status.code < 200

    @always_inline
    def is_success(self) -> Bool:
        """Checks if the response status code indicates success (2xx).

        Unlike `is_ok`, this is True for any 2xx status, including 201 Created
        and 204 No Content.

        Returns:
            True if the status code is in the range 200-299, False otherwise.
        """
        return self.status.code >= 200 and self.status.code < 300

    @always_inline
    def is_redirect(self) -> Bool:
        """Checks if the response status code indicates a redirect (3xx).

        Returns:
            True if the status code is in the range 300-399, False otherwise.
        """
        return self.status.code >= 300 and self.status.code < 400

    @always_inline
    def is_client_error(self) -> Bool:
        """Checks if the response status code indicates a client error (4xx).

        Returns:
            True if the status code is in the range 400-499, False otherwise.
        """
        return self.status.code >= 400 and self.status.code < 500

    @always_inline
    def is_server_error(self) -> Bool:
        """Checks if the response status code indicates a server error (5xx).

        Returns:
            True if the status code is in the range 500-599, False otherwise.
        """
        return self.status.code >= 500 and self.status.code < 600

    @always_inline
    def is_ok(self) -> Bool:
        """Checks if the response status code is exactly 200 OK.

        For a broader "was this successful" check that accepts any 2xx status,
        prefer `is_success`.

        Returns:
            True if the status code is 200, False otherwise.
        """
        return self.status == Status.OK

    def raise_for_status(self) raises HTTPError:
        """Raises an `HTTPError` if the response was not successful (i.e., not a 2xx status).

        2xx codes other than 200 (e.g., 201 Created, 204 No Content) are treated
        as successful and do not raise.

        Raises:
            HTTPError: If the response status code is not in the 2xx range.
        """
        if not self.is_success():
            var snippet: String
            try:
                snippet = String(self.body.as_text())
            except:
                snippet = ""  # body not valid UTF-8; leave empty
            # cap the snippet length to keep errors readable
            if snippet.byte_length() > 512:
                var new_snippet = String(snippet[byte=0:512])
                snippet = new_snippet^
            raise HTTPError(status=self.status, url=self.url, body=snippet^)

    def content_length(self) -> Int:
        """Returns the length of the response body in bytes.

        This does not necessarily correspond to the Content-Length header,
        but rather the actual length of the body content.

        Returns:
            The number of bytes in the response body.
        """
        return len(self.body)

    def __bool__(self) -> Bool:
        """Reports whether the response was successful (a 2xx status code).

        Returns:
            True if the status code is in the 2xx range, False otherwise.
        """
        return self.is_success()

    def reason(self) -> StaticString:
        """Returns the reason phrase associated with the status code.

        Returns:
            The status message, e.g. "OK" or "Not Found".
        """
        return self.status.message

    def as_text(self) raises -> StringSpan[origin_of(self.body.body)]:
        """Returns the response body decoded as text.

        Convenience for `response.body.as_text()`.

        Returns:
            The body content as a string slice.

        Raises:
            Error: If the response body is not valid UTF-8.
        """
        return self.body.as_text()

    def as_bytes(self) -> Span[Byte, origin_of(self.body.body)]:
        """Returns a view of the raw response body bytes.

        Convenience for `response.body.as_bytes()`.

        Returns:
            A `Span[Byte]` referencing the body's underlying data.
        """
        return self.body.as_bytes()

    def as_json(self) raises -> emberjson.Value:
        """Parses the response body as a dynamic JSON document for ad-hoc access.

        Convenience for `response.body.as_json()`, e.g. `response.as_json()["data"]`.
        To deserialize into a struct, use `as[T]()`.

        Returns:
            The body content parsed as an `emberjson.JSON` value.

        Raises:
            Error: if the body is empty or cannot be parsed as JSON.
        """
        return self.body.as_json()

    def as[T: Movable & Deinitable & Defaultable](self, out result: T) raises:
        """Deserializes the response body into a value of the given type.

        Convenience for `response.body.as[T]()`.

        Parameters:
            T: The type to deserialize the body into.

        Returns:
            The body content deserialized into a value of type `T`.

        Raises:
            Error: if the body is empty or cannot be parsed as JSON.
        """
        return self.body.as[T]()

    def header(self, name: StringSpan, default: String = "") -> String:
        """Looks up a response header by name, case-insensitively.

        HTTP header names are case-insensitive, so this matches regardless of the
        casing the server used.

        Args:
            name: The header name to look up.
            default: The value to return if the header is not present.

        Returns:
            The header value, or `default` if the header is not present.
        """
        return self.headers.get(name, default)

    def content_type(self) -> String:
        """Returns the value of the `Content-Type` header, or an empty string if absent.

        Returns:
            The `Content-Type` header value, e.g. "application/json".
        """
        return self.header("Content-Type")
