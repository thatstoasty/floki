from small_time.small_time import now
import emberjson
from floki.uri import URI
from floki._logger import LOGGER
from floki.body import Body
from floki.bytes import (
    Bytes,
    ByteReader,
    ByteWriter,
    is_newline,
    is_space,
    DEFAULT_BUFFER_SIZE,
    BytesConstant,
    CRLF,
    WHITESPACE,
)
from floki.connection import Connection
from floki.tls import TLSConnection, TLSContext
from floki.cookie import ResponseCookieJar
from floki.header import Headers, HeaderKey, write_header
from floki.protocol import Protocol


@fieldwise_init
@register_passable("trivial")
struct StatusCode(Copyable, EqualityComparable, ExplicitlyCopyable, Movable, Writable):
    var value: UInt16

    alias CONTINUE = Self(100)
    alias SWITCHING_PROTOCOLS = Self(101)
    alias PROCESSING = Self(102)
    alias EARLY_HINTS = Self(103)

    alias OK = Self(200)
    alias CREATED = Self(201)
    alias ACCEPTED = Self(202)
    alias NON_AUTHORITATIVE_INFORMATION = Self(203)
    alias NO_CONTENT = Self(204)
    alias RESET_CONTENT = Self(205)
    alias PARTIAL_CONTENT = Self(206)
    alias MULTI_STATUS = Self(207)
    alias ALREADY_REPORTED = Self(208)
    alias IM_USED = Self(226)

    alias MULTIPLE_CHOICES = Self(300)
    alias MOVED_PERMANENTLY = Self(301)
    alias FOUND = Self(302)
    alias TEMPORARY_REDIRECT = Self(307)
    alias PERMANENT_REDIRECT = Self(308)

    alias BAD_REQUEST = Self(400)
    alias UNAUTHORIZED = Self(401)
    alias PAYMENT_REQUIRED = Self(402)
    alias FORBIDDEN = Self(403)
    alias NOT_FOUND = Self(404)
    alias METHOD_NOT_ALLOWED = Self(405)
    alias NOT_ACCEPTABLE = Self(406)
    alias PROXY_AUTHENTICATION_REQUIRED = Self(407)
    alias REQUEST_TIMEOUT = Self(408)
    alias CONFLICT = Self(409)
    alias GONE = Self(410)
    alias LENGTH_REQUIRED = Self(411)
    alias PRECONDITION_FAILED = Self(412)
    alias PAYLOAD_TOO_LARGE = Self(413)
    alias URI_TOO_LONG = Self(414)
    alias UNSUPPORTED_MEDIA_TYPE = Self(415)
    alias RANGE_NOT_SATISFIABLE = Self(416)
    alias EXPECTATION_FAILED = Self(417)
    alias IM_A_TEAPOT = Self(418)
    alias MISDIRECTED_REQUEST = Self(421)
    alias UNPROCESSABLE_ENTITY = Self(422)
    alias LOCKED = Self(423)
    alias FAILED_DEPENDENCY = Self(424)
    alias TOO_EARLY = Self(425)
    alias UPGRADE_REQUIRED = Self(426)
    alias PRECONDITION_REQUIRED = Self(428)
    alias TOO_MANY_REQUESTS = Self(429)
    alias REQUEST_HEADER_FIELDS_TOO_LARGE = Self(431)
    alias UNAVAILABLE_FOR_LEGAL_REASONS = Self(451)

    alias INTERNAL_ERROR = Self(500)
    alias NOT_IMPLEMENTED = Self(501)
    alias BAD_GATEWAY = Self(502)
    alias SERVICE_UNAVAILABLE = Self(503)
    alias GATEWAY_TIMEOUT = Self(504)
    alias HTTP_VERSION_NOT_SUPPORTED = Self(505)
    alias VARIANT_ALSO_NEGOTIATES = Self(506)
    alias INSUFFICIENT_STORAGE = Self(507)
    alias LOOP_DETECTED = Self(508)
    alias NOT_EXTENDED = Self(510)
    alias NETWORK_AUTHENTICATION_REQUIRED = Self(511)

    @staticmethod
    fn from_int(code: Int) raises -> StatusCode:
        """Creates a StatusCode instance from an integer representation.

        Arguments:
            s: The integer representation of the status code.

        Returns:
            A StatusCode instance corresponding to the provided integer.
        """
        # For every alias defined in StatusCode, check if the integer matches
        # the value of the alias.
        if Self.OK == code:
            return Self.OK
        elif Self.CREATED == code:
            return Self.CREATED
        elif Self.ACCEPTED == code:
            return Self.ACCEPTED
        elif Self.NON_AUTHORITATIVE_INFORMATION == code:
            return Self.NON_AUTHORITATIVE_INFORMATION
        elif Self.NO_CONTENT == code:
            return Self.NO_CONTENT
        elif Self.RESET_CONTENT == code:
            return Self.RESET_CONTENT
        elif Self.PARTIAL_CONTENT == code:
            return Self.PARTIAL_CONTENT
        elif Self.MULTI_STATUS == code:
            return Self.MULTI_STATUS
        elif Self.ALREADY_REPORTED == code:
            return Self.ALREADY_REPORTED
        elif Self.IM_USED == code:
            return Self.IM_USED
        elif Self.MULTIPLE_CHOICES == code:
            return Self.MULTIPLE_CHOICES
        elif Self.MOVED_PERMANENTLY == code:
            return Self.MOVED_PERMANENTLY
        elif Self.FOUND == code:
            return Self.FOUND
        elif Self.TEMPORARY_REDIRECT == code:
            return Self.TEMPORARY_REDIRECT
        elif Self.PERMANENT_REDIRECT == code:
            return Self.PERMANENT_REDIRECT
        elif Self.BAD_REQUEST == code:
            return Self.BAD_REQUEST
        elif Self.UNAUTHORIZED == code:
            return Self.UNAUTHORIZED
        elif Self.PAYMENT_REQUIRED == code:
            return Self.PAYMENT_REQUIRED
        elif Self.FORBIDDEN == code:
            return Self.FORBIDDEN
        elif Self.NOT_FOUND == code:
            return Self.NOT_FOUND
        elif Self.METHOD_NOT_ALLOWED == code:
            return Self.METHOD_NOT_ALLOWED
        elif Self.NOT_ACCEPTABLE == code:
            return Self.NOT_ACCEPTABLE
        elif Self.PROXY_AUTHENTICATION_REQUIRED == code:
            return Self.PROXY_AUTHENTICATION_REQUIRED
        elif Self.REQUEST_TIMEOUT == code:
            return Self.REQUEST_TIMEOUT
        elif Self.CONFLICT == code:
            return Self.CONFLICT
        elif Self.GONE == code:
            return Self.GONE
        elif Self.LENGTH_REQUIRED == code:
            return Self.LENGTH_REQUIRED
        elif Self.PRECONDITION_FAILED == code:
            return Self.PRECONDITION_FAILED
        elif Self.PAYLOAD_TOO_LARGE == code:
            return Self.PAYLOAD_TOO_LARGE
        elif Self.URI_TOO_LONG == code:
            return Self.URI_TOO_LONG
        elif Self.UNSUPPORTED_MEDIA_TYPE == code:
            return Self.UNSUPPORTED_MEDIA_TYPE
        elif Self.RANGE_NOT_SATISFIABLE == code:
            return Self.RANGE_NOT_SATISFIABLE
        elif Self.EXPECTATION_FAILED == code:
            return Self.EXPECTATION_FAILED
        elif Self.IM_A_TEAPOT == code:
            return Self.IM_A_TEAPOT
        elif Self.MISDIRECTED_REQUEST == code:
            return Self.MISDIRECTED_REQUEST
        elif Self.UNPROCESSABLE_ENTITY == code:
            return Self.UNPROCESSABLE_ENTITY
        elif Self.LOCKED == code:
            return Self.LOCKED
        elif Self.FAILED_DEPENDENCY == code:
            return Self.FAILED_DEPENDENCY
        elif Self.TOO_EARLY == code:
            return Self.TOO_EARLY
        elif Self.UPGRADE_REQUIRED == code:
            return Self.UPGRADE_REQUIRED
        elif Self.PRECONDITION_REQUIRED == code:
            return Self.PRECONDITION_REQUIRED
        elif Self.TOO_MANY_REQUESTS == code:
            return Self.TOO_MANY_REQUESTS
        elif Self.REQUEST_HEADER_FIELDS_TOO_LARGE == code:
            return Self.REQUEST_HEADER_FIELDS_TOO_LARGE
        elif Self.UNAVAILABLE_FOR_LEGAL_REASONS == code:
            return Self.UNAVAILABLE_FOR_LEGAL_REASONS
        elif Self.INTERNAL_ERROR == code:
            return Self.INTERNAL_ERROR
        elif Self.NOT_IMPLEMENTED == code:
            return Self.NOT_IMPLEMENTED
        elif Self.BAD_GATEWAY == code:
            return Self.BAD_GATEWAY
        elif Self.SERVICE_UNAVAILABLE == code:
            return Self.SERVICE_UNAVAILABLE
        elif Self.GATEWAY_TIMEOUT == code:
            return Self.GATEWAY_TIMEOUT
        elif Self.HTTP_VERSION_NOT_SUPPORTED == code:
            return Self.HTTP_VERSION_NOT_SUPPORTED
        elif Self.VARIANT_ALSO_NEGOTIATES == code:
            return Self.VARIANT_ALSO_NEGOTIATES
        elif Self.INSUFFICIENT_STORAGE == code:
            return Self.INSUFFICIENT_STORAGE
        elif Self.LOOP_DETECTED == code:
            return Self.LOOP_DETECTED
        elif Self.NOT_EXTENDED == code:
            return Self.NOT_EXTENDED
        elif Self.NETWORK_AUTHENTICATION_REQUIRED == code:
            return Self.NETWORK_AUTHENTICATION_REQUIRED
        elif Self.CONTINUE == code:
            return Self.CONTINUE
        elif Self.SWITCHING_PROTOCOLS == code:
            return Self.SWITCHING_PROTOCOLS
        elif Self.PROCESSING == code:
            return Self.PROCESSING
        elif Self.EARLY_HINTS == code:
            return Self.EARLY_HINTS
        else:
            raise Error("Unknown status code: ", code)

    fn __eq__(self, other: Self) -> Bool:
        """Compares two StatusCode instances for equality.

        Arguments:
            other: The StatusCode instance to compare with.

        Returns:
            True if both instances have the same value, otherwise False.
        """
        return self.value == other.value

    fn __eq__(self, other: Int) -> Bool:
        """Compares a StatusCode instance with an integer for equality.

        Arguments:
            other: The integer to compare with.

        Returns:
            True if the StatusCode instance's value matches the integer, otherwise False.
        """
        return self.value == other

    fn __ne__(self, other: Self) -> Bool:
        """Compares two StatusCode instances for inequality.

        Arguments:
            other: The StatusCode instance to compare with.

        Returns:
            True if both instances have different values, otherwise False.
        """
        return self.value != other.value

    fn __ne__(self, other: Int) -> Bool:
        """Compares a StatusCode instance with an integer for inequality.

        Arguments:
            other: The integer to compare with.

        Returns:
            True if the StatusCode instance's value does not match the integer, otherwise False.
        """
        return self.value != other

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        """Writes the StatusCode instance to a writer.

        This method is used to write the status code in a human-readable format.

        Args:
            writer: The writer to which the status code will be written.
        """
        writer.write(self.value)


@fieldwise_init
struct HTTPResponse(Movable, Stringable, Writable):
    var headers: Headers
    var cookies: ResponseCookieJar
    var body: Body

    var status_code: StatusCode
    var reason: String
    var protocol: Protocol

    @staticmethod
    fn from_bytes(b: Span[Byte]) raises -> HTTPResponse:
        var reader = ByteReader(b)
        var headers = Headers()
        var cookies = ResponseCookieJar()
        var protocol: Protocol
        var status_code: String
        var reason: String

        try:
            var properties = parse_response_headers(headers, reader)
            protocol, status_code, reason = properties[0], properties[1], properties[2]
            cookies.from_headers(properties[3])
            reader.skip_carriage_return()
        except e:
            raise Error("Failed to parse response headers: ", e)

        try:
            return HTTPResponse(
                reader=reader,
                headers=headers,
                cookies=cookies,
                protocol=protocol,
                status_code=StatusCode.from_int(Int(status_code)),
                reason=reason,
            )
        except e:
            LOGGER.error(e)
            raise Error("Failed to read request body")

    @staticmethod
    fn from_bytes[ConnectionType: Connection](b: Span[Byte], connection: ConnectionType) raises -> HTTPResponse:
        var reader = ByteReader(b)
        var headers = Headers()
        var cookies = ResponseCookieJar()

        var properties = parse_response_headers(headers, reader)
        protocol, status_code, reason = properties[0], properties[1], properties[2]
        try:
            cookies.from_headers(properties[3])
            reader.skip_carriage_return()
        except e:
            raise Error("Failed to parse response headers: ", e)

        var response = HTTPResponse(
            Bytes(),
            headers=headers,
            cookies=cookies,
            protocol=protocol,
            status_code=StatusCode.from_int(Int(status_code)),
            reason=reason,
        )

        var transfer_encoding = response.headers.get(HeaderKey.TRANSFER_ENCODING)
        if transfer_encoding and transfer_encoding.value() == "chunked":
            var b = Bytes(reader.read_bytes())
            var buff = Bytes(capacity=DEFAULT_BUFFER_SIZE)
            try:
                while connection.read(buff) > 0:
                    b += buff

                    if (
                        buff[-5] == ord("0")
                        and buff[-4] == BytesConstant.CR
                        and buff[-3] == BytesConstant.LF
                        and buff[-2] == BytesConstant.CR
                        and buff[-1] == BytesConstant.LF
                    ):
                        break

                    buff.clear()
                response.read_chunks(b)
                return response^
            except e:
                LOGGER.error(e)
                raise Error("Failed to read chunked response.")

        try:
            response.read_body(reader)
            return response^
        except e:
            LOGGER.error(e)
            raise Error("Failed to read request body: ")

    fn __init__(
        out self,
        body_bytes: Span[Byte],
        headers: Headers = Headers(),
        cookies: ResponseCookieJar = ResponseCookieJar(),
        status_code: StatusCode = StatusCode.OK,
        reason: String = "OK",
        protocol: Protocol = Protocol.HTTP_11,
    ):
        self.headers = headers
        self.cookies = cookies
        if HeaderKey.CONTENT_TYPE not in self.headers:
            self.headers[HeaderKey.CONTENT_TYPE] = "application/octet-stream"
        self.status_code = status_code
        self.reason = reason
        self.protocol = protocol
        self.body = Body(Span(body_bytes))
        if HeaderKey.CONNECTION not in self.headers:
            self.set_connection_keep_alive()
        if HeaderKey.CONTENT_LENGTH not in self.headers:
            self.set_content_length(len(body_bytes))
        if HeaderKey.DATE not in self.headers:
            try:
                var current_time = String(now(utc=True))
                self.headers[HeaderKey.DATE] = current_time
            except:
                LOGGER.debug("DATE header not set, unable to get current time and it was instead omitted.")

    fn __init__(
        out self,
        mut reader: ByteReader,
        headers: Headers = Headers(),
        cookies: ResponseCookieJar = ResponseCookieJar(),
        status_code: StatusCode = StatusCode.OK,
        reason: String = "OK",
        protocol: Protocol = Protocol.HTTP_11,
    ) raises:
        self.headers = headers
        self.cookies = cookies
        if HeaderKey.CONTENT_TYPE not in self.headers:
            self.headers[HeaderKey.CONTENT_TYPE] = "application/octet-stream"
        self.status_code = status_code
        self.reason = reason
        self.protocol = protocol
        self.body = Body(Span(Bytes(reader.read_bytes())))
        self.set_content_length(len(self.body))
        if HeaderKey.CONNECTION not in self.headers:
            self.set_connection_keep_alive()
        if HeaderKey.CONTENT_LENGTH not in self.headers:
            self.set_content_length(len(self.body))
        if HeaderKey.DATE not in self.headers:
            try:
                var current_time = String(now(utc=True))
                self.headers[HeaderKey.DATE] = current_time
            except:
                pass

    @always_inline
    fn set_connection_close(mut self):
        self.headers[HeaderKey.CONNECTION] = "close"

    fn connection_close(self) -> Bool:
        var result = self.headers.get(HeaderKey.CONNECTION)
        if not result:
            return False
        return result.value() == "close"

    @always_inline
    fn set_connection_keep_alive(mut self):
        self.headers[HeaderKey.CONNECTION] = "keep-alive"

    @always_inline
    fn set_content_length(mut self, l: Int):
        self.headers[HeaderKey.CONTENT_LENGTH] = String(l)

    @always_inline
    fn content_length(self) -> Int:
        try:
            return Int(self.headers[HeaderKey.CONTENT_LENGTH])
        except:
            return 0

    @always_inline
    fn is_redirect(self) -> Bool:
        return self.status_code in [
            StatusCode.MOVED_PERMANENTLY,
            StatusCode.FOUND,
            StatusCode.TEMPORARY_REDIRECT,
            StatusCode.PERMANENT_REDIRECT,
        ]

    @always_inline
    fn read_body(mut self, mut r: ByteReader) raises -> None:
        self.body = Body(r.read_bytes(self.content_length()))
        self.set_content_length(len(self.body))

    fn read_chunks(mut self, chunks: Span[Byte]) raises:
        var reader = ByteReader(chunks)
        while True:
            var size = atol(String(bytes=reader.read_line()), 16)
            if size == 0:
                break
            var data = reader.read_bytes(size)
            reader.skip_carriage_return()
            self.set_content_length(self.content_length() + len(data))
            self.body += Bytes(data)

    fn write_to[T: Writer](self, mut writer: T):
        writer.write(self.protocol, WHITESPACE, self.status_code.value, WHITESPACE, self.reason, CRLF)

        if HeaderKey.SERVER not in self.headers:
            writer.write("server: lightbug_http", CRLF)

        writer.write(self.headers, self.cookies, CRLF, self.body.as_string_slice())

    fn encode(owned self) -> Bytes:
        """Encodes response as bytes.

        This method consumes the data in this request and it should
        no longer be considered valid.
        """
        var writer = ByteWriter()
        writer.write(
            self.protocol,
            WHITESPACE,
            String(self.status_code.value),
            WHITESPACE,
            self.reason,
            CRLF,
            "server: lightbug_http",
            CRLF,
        )
        if HeaderKey.DATE not in self.headers:
            try:
                write_header(writer, HeaderKey.DATE, String(now(utc=True)))
            except:
                pass
        writer.write(self.headers, self.cookies, CRLF)
        writer.consuming_write(self.body.consume())
        return writer.consume()

    fn __str__(self) -> String:
        return String(self)


fn parse_response_headers(mut headers: Headers, mut r: ByteReader) raises -> (Protocol, String, String, List[String]):
    if not r.peek():
        raise Error("parse_response_headers: Failed to read first byte from response header")

    var first = r.read_word()
    r.increment()
    var second = r.read_word()
    r.increment()
    var third = r.read_line()
    var cookies = List[String]()

    while not is_newline(r.peek()):
        var key = r.read_until(BytesConstant.COLON)
        r.increment()
        if is_space(r.peek()):
            r.increment()

        # TODO (bgreni): Handle possible trailing whitespace
        var value = r.read_line()
        var k = StringSlice(unsafe_from_utf8=key).lower()
        if k == HeaderKey.SET_COOKIE:
            cookies.append(String(bytes=value))
            continue

        headers._inner[k] = String(bytes=value)
    return (
        Protocol.from_string(StringSlice(unsafe_from_utf8=first)),
        String(bytes=second),
        String(bytes=third),
        cookies^,
    )
