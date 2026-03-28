from floki.http import Protocol, Status
from floki.body import Body
from floki.cookie.cookie_jar import CookieJar

comptime WHITESPACE = " "
"""Whitespace character used in HTTP formatting."""
comptime CRLF = "\r\n"
"""Carriage return and line feed characters used in HTTP formatting."""

@fieldwise_init
struct HTTPError(Movable):
    """An error that is raised when an HTTP response indicates a failure (i.e., a non-2xx status code)."""
    var status: Status
    """The HTTP status code that caused the error."""


@fieldwise_init
struct HTTPResponse(Movable, Writable):
    """Represents an HTTP response received from the server."""
    var headers: Dict[String, String]
    """The HTTP headers included in the response."""
    var cookies: CookieJar
    """The cookies included in the response."""
    var body: Body
    """The body of the response."""
    var status: Status
    """The HTTP status code of the response."""
    var protocol: Protocol
    """The HTTP protocol used in the response."""

    fn __init__(
        out self,
        var body: List[Byte],
        var cookies: CookieJar,
        status: Status,
        protocol: Protocol,
        var headers: Dict[String, String] = {},
    ) raises:
        """Constructs an HTTPResponse from its component parts.

        Args:
            body: The raw response body as a list of bytes.
            cookies: The cookies received in the response.
            status: The HTTP status code of the response.
            protocol: The HTTP protocol used in the response.
            headers: The HTTP headers included in the response.
        
        Raises:
            Error: If there is a failure in constructing the Body from the provided bytes.
        """
        self.headers = headers^
        self.cookies = cookies^
        self.status = status
        self.protocol = protocol
        self.body = Body(body^)

    fn write_to(self, mut writer: Some[Writer]):
        """Writes the HTTP response to a writer in a standard HTTP format.

        Args:
            writer: The writer to which the HTTP response will be written.
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
            self.body.as_string_slice()
        )

    @always_inline
    fn is_redirect(self) -> Bool:
        """Checks if the response status code indicates a redirect (i.e., 3xx status codes).
        
        Returns:
            True if the status code is a redirect, False otherwise.
        """
        return self.status in [
            Status.MOVED_PERMANENTLY,
            Status.FOUND,
            Status.TEMPORARY_REDIRECT,
            Status.PERMANENT_REDIRECT,
        ]
    
    @always_inline
    fn is_ok(self) -> Bool:
        """Checks if the response status code indicates success (i.e., a 2xx status code).

        Returns:
            True if the status code indicates success, False otherwise.
        """
        return self.status == Status.OK
    
    fn raise_for_status(self) raises HTTPError:
        """Raises an HTTPError if the response status code indicates a failure (i.e., a non-2xx status code).

        Raises:
            HTTPError: If the response status code indicates a failure.
        """
        if not self.is_ok():
            raise HTTPError(self.status)
