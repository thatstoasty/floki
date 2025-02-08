from floki.uri import URI
from floki._logger import LOGGER
from floki.protocol import Protocol
from floki.body import Body
from floki.bytes import Bytes, CRLF, WHITESPACE, ByteReader, ByteWriter, OutOfBoundsError
from floki.header import Headers, HeaderKey, Header, write_header
from floki.cookie import RequestCookieJar


alias Duration = Int
alias SLASH = "/"


@fieldwise_init
struct RequestMethod(Copyable, ExplicitlyCopyable, Movable, Writable):
    var value: StaticString

    alias GET = Self("GET")
    alias POST = Self("POST")
    alias PUT = Self("PUT")
    alias DELETE = Self("DELETE")
    alias HEAD = Self("HEAD")
    alias PATCH = Self("PATCH")
    alias OPTIONS = Self("OPTIONS")

    fn write_to[T: Writer, //](self, mut writer: T):
        writer.write(self.value)

    @staticmethod
    fn from_string(s: StringSlice) raises -> RequestMethod:
        if s == "GET":
            return RequestMethod.GET
        elif s == "POST":
            return RequestMethod.POST
        elif s == "PUT":
            return RequestMethod.PUT
        elif s == "DELETE":
            return RequestMethod.DELETE
        elif s == "HEAD":
            return RequestMethod.HEAD
        elif s == "PATCH":
            return RequestMethod.PATCH
        elif s == "OPTIONS":
            return RequestMethod.OPTIONS
        else:
            raise Error("Invalid HTTP method: ", s)


@fieldwise_init
struct HTTPRequest(Movable, Stringable, Writable):
    var headers: Headers
    var cookies: RequestCookieJar
    var uri: URI
    var body: Body

    var method: RequestMethod
    var protocol: Protocol

    var timeout: Optional[Duration]

    fn __init__(
        out self,
        owned uri: URI,
        headers: Headers = Headers(),
        cookies: RequestCookieJar = RequestCookieJar(),
        method: RequestMethod = RequestMethod.GET,
        protocol: Protocol = Protocol.HTTP_11,
        owned body: Body = Body(),
        timeout: Optional[Duration] = None,
    ):
        self.headers = headers.copy()
        self.cookies = cookies.copy()
        self.method = method.copy()
        self.protocol = protocol.copy()
        self.uri = uri^
        self.body = body^
        self.timeout = timeout
        self.set_content_length(len(self.body))

        if HeaderKey.CONNECTION not in self.headers:
            self.headers[HeaderKey.CONNECTION] = "keep-alive"

        if HeaderKey.HOST not in self.headers:
            if self.uri.port:
                self.headers[HeaderKey.HOST] = String(self.uri.host, ":", String(self.uri.port.value()))
            else:
                self.headers[HeaderKey.HOST] = self.uri.host

    fn set_connection_close(mut self):
        self.headers[HeaderKey.CONNECTION] = "close"

    fn set_content_length(mut self, length: Int):
        self.headers[HeaderKey.CONTENT_LENGTH] = String(length)

    fn connection_close(self) -> Bool:
        var result = self.headers.get(HeaderKey.CONNECTION)
        if not result:
            return False
        return result.value() == "close"

    fn write_to[T: Writer, //](self, mut writer: T):
        var path = self.uri.path if len(self.uri.path) > 1 else SLASH
        if len(self.uri.query_string) > 0:
            path.write("?", self.uri.query_string)

        writer.write(
            self.method,
            WHITESPACE,
            path,
            WHITESPACE,
            self.protocol,
            CRLF,
            self.headers,
            self.cookies,
            CRLF,
            self.body.as_string_slice(),
        )

    fn encode(self) -> Bytes:
        """Encodes request as bytes."""
        var path = self.uri.path if len(self.uri.path) > 1 else SLASH
        if len(self.uri.query_string) > 0:
            path.write("?", self.uri.query_string)

        var writer = ByteWriter()
        writer.write(
            self.method,
            WHITESPACE,
            path,
            WHITESPACE,
            self.protocol,
            CRLF,
            self.headers,
            self.cookies,
            CRLF,
            self.body.as_string_slice(),
        )
        return writer.consume()

    fn __str__(self) -> String:
        return String(self)
