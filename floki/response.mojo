from mojo_curl.easy import Easy
from mojo_curl.c.header import curl_header
from mojo_curl.c.types import ExternalMutPointer
from floki.http import Protocol, StatusCode
from floki.reader import BytesConstant, ByteReader, is_newline, is_space
from floki._logger import LOGGER
from floki.body import Body


@fieldwise_init
struct HTTPResponse(Movable):
    var headers: Dict[String, String]
    # var cookies: ResponseCookieJar
    var body: Body

    var status_code: StatusCode
    var reason: String
    var protocol: Protocol

    @staticmethod
    fn from_bytes(easy: Easy, b: Span[Byte]) raises -> HTTPResponse:
        var reader = ByteReader(b)
        var headers = easy.headers()
        # var cookies = ResponseCookieJar()

        # TODO: Use easy to get protocol, status, code and reason.
        var protocol: Protocol = Protocol.from_string(easy.get_scheme())
        var status_code = easy.response_code()
        var reason: String = "OK"

        # try:
        #     var properties = parse_response_headers(reader)
        #     protocol, status_code, reason = properties[0], properties[1], properties[2]
        #     # cookies.from_headers(properties[3])
        #     reader.skip_carriage_return()
        # except e:
        #     raise Error("Failed to parse response headers: ", e)

        try:
            return HTTPResponse(
                reader=reader,
                headers=headers^,
                # cookies=cookies,
                protocol=protocol,
                status_code=StatusCode.from_int(Int(status_code)),
                reason=reason,
            )
        except e:
            LOGGER.error(e)
            raise Error("Failed to read request body")

    #     @staticmethod
    #     fn from_bytes[ConnectionType: Connection](b: Span[Byte], connection: ConnectionType) raises -> HTTPResponse:
    #         var reader = ByteReader(b)
    #         var headers = Headers()
    #         var cookies = ResponseCookieJar()

    #         var properties = parse_response_headers(headers, reader)
    #         protocol, status_code, reason = properties[0], properties[1], properties[2]
    #         try:
    #             cookies.from_headers(properties[3])
    #             reader.skip_carriage_return()
    #         except e:
    #             raise Error("Failed to parse response headers: ", e)

    #         var response = HTTPResponse(
    #             Bytes(),
    #             headers=headers,
    #             cookies=cookies,
    #             protocol=protocol,
    #             status_code=StatusCode.from_int(Int(status_code)),
    #             reason=reason,
    #         )

    #         var transfer_encoding = response.headers.get(HeaderKey.TRANSFER_ENCODING)
    #         if transfer_encoding and transfer_encoding.value() == "chunked":
    #             var b = Bytes(reader.read_bytes())
    #             var buff = Bytes(capacity=DEFAULT_BUFFER_SIZE)
    #             try:
    #                 while connection.read(buff) > 0:
    #                     b += buff

    #                     if (
    #                         buff[-5] == ord("0")
    #                         and buff[-4] == BytesConstant.CR
    #                         and buff[-3] == BytesConstant.LF
    #                         and buff[-2] == BytesConstant.CR
    #                         and buff[-1] == BytesConstant.LF
    #                     ):
    #                         break

    #                     buff.clear()
    #                 response.read_chunks(b)
    #                 return response^
    #             except e:
    #                 LOGGER.error(e)
    #                 raise Error("Failed to read chunked response.")

    #         try:
    #             response.read_body(reader)
    #             return response^
    #         except e:
    #             LOGGER.error(e)
    #             raise Error("Failed to read request body: ")

    #     fn __init__(
    #         out self,
    #         body_bytes: Span[Byte],
    #         headers: Headers = Headers(),
    #         cookies: ResponseCookieJar = ResponseCookieJar(),
    #         status_code: StatusCode = StatusCode.OK,
    #         reason: String = "OK",
    #         protocol: Protocol = Protocol.HTTP_11,
    #     ):
    #         self.headers = headers
    #         self.cookies = cookies
    #         if HeaderKey.CONTENT_TYPE not in self.headers:
    #             self.headers[HeaderKey.CONTENT_TYPE] = "application/octet-stream"
    #         self.status_code = status_code
    #         self.reason = reason
    #         self.protocol = protocol
    #         self.body = Body(Span(body_bytes))
    #         if HeaderKey.CONNECTION not in self.headers:
    #             self.set_connection_keep_alive()
    #         if HeaderKey.CONTENT_LENGTH not in self.headers:
    #             self.set_content_length(len(body_bytes))
    #         if HeaderKey.DATE not in self.headers:
    #             try:
    #                 var current_time = String(now(utc=True))
    #                 self.headers[HeaderKey.DATE] = current_time
    #             except:
    #                 LOGGER.debug("DATE header not set, unable to get current time and it was instead omitted.")

    fn __init__(
        out self,
        mut reader: ByteReader,
        var headers: Dict[String, String] = {},
        # cookies: ResponseCookieJar = ResponseCookieJar(),
        status_code: StatusCode = StatusCode.OK,
        reason: String = "OK",
        protocol: Protocol = Protocol.HTTP,
    ) raises:
        self.headers = headers^
        # self.cookies = cookies
        if "content-type" not in self.headers:
            self.headers["content-type"] = "application/octet-stream"
        self.status_code = status_code
        self.reason = reason
        self.protocol = protocol
        self.body = Body(reader.read_bytes())
        # self.set_content_length(len(self.body))
        # if HeaderKey.CONNECTION not in self.headers:
        #     self.set_connection_keep_alive()
        # if HeaderKey.CONTENT_LENGTH not in self.headers:
        #     self.set_content_length(len(self.body))
        # if HeaderKey.DATE not in self.headers:
        #     try:
        #         var current_time = String(now(utc=True))
        #         self.headers[HeaderKey.DATE] = current_time
        #     except:
        #         pass


#     @always_inline
#     fn set_connection_close(mut self):
#         self.headers[HeaderKey.CONNECTION] = "close"

#     fn connection_close(self) -> Bool:
#         var result = self.headers.get(HeaderKey.CONNECTION)
#         if not result:
#             return False
#         return result.value() == "close"

#     @always_inline
#     fn set_connection_keep_alive(mut self):
#         self.headers[HeaderKey.CONNECTION] = "keep-alive"

#     @always_inline
#     fn set_content_length(mut self, l: Int):
#         self.headers[HeaderKey.CONTENT_LENGTH] = String(l)

#     @always_inline
#     fn content_length(self) -> Int:
#         try:
#             return Int(self.headers[HeaderKey.CONTENT_LENGTH])
#         except:
#             return 0

#     @always_inline
#     fn is_redirect(self) -> Bool:
#         return self.status_code in [
#             StatusCode.MOVED_PERMANENTLY,
#             StatusCode.FOUND,
#             StatusCode.TEMPORARY_REDIRECT,
#             StatusCode.PERMANENT_REDIRECT,
#         ]

#     @always_inline
#     fn read_body(mut self, mut r: ByteReader) raises -> None:
#         self.body = Body(r.read_bytes(self.content_length()))
#         self.set_content_length(len(self.body))

#     fn read_chunks(mut self, chunks: Span[Byte]) raises:
#         var reader = ByteReader(chunks)
#         while True:
#             var size = atol(String(bytes=reader.read_line()), 16)
#             if size == 0:
#                 break
#             var data = reader.read_bytes(size)
#             reader.skip_carriage_return()
#             self.set_content_length(self.content_length() + len(data))
#             self.body += Bytes(data)

#     fn write_to[T: Writer](self, mut writer: T):
#         writer.write(self.protocol, WHITESPACE, self.status_code.value, WHITESPACE, self.reason, CRLF)

#         if HeaderKey.SERVER not in self.headers:
#             writer.write("server: lightbug_http", CRLF)

#         writer.write(self.headers, self.cookies, CRLF, self.body.as_string_slice())

#     fn encode(owned self) -> Bytes:
#         """Encodes response as bytes.

#         This method consumes the data in this request and it should
#         no longer be considered valid.
#         """
#         var writer = ByteWriter()
#         writer.write(
#             self.protocol,
#             WHITESPACE,
#             String(self.status_code.value),
#             WHITESPACE,
#             self.reason,
#             CRLF,
#             "server: lightbug_http",
#             CRLF,
#         )
#         if HeaderKey.DATE not in self.headers:
#             try:
#                 write_header(writer, HeaderKey.DATE, String(now(utc=True)))
#             except:
#                 pass
#         writer.write(self.headers, self.cookies, CRLF)
#         writer.consuming_write(self.body.consume())
#         return writer.consume()

#     fn __str__(self) -> String:
#         return String(self)


# fn parse_response_headers(mut headers: Headers, mut r: ByteReader) raises -> (Protocol, String, String, List[String]):
#     if not r.peek():
#         raise Error("parse_response_headers: Failed to read first byte from response header")

#     var first = r.read_word()
#     r.increment()
#     var second = r.read_word()
#     r.increment()
#     var third = r.read_line()
#     var cookies = List[String]()

#     while not is_newline(r.peek()):
#         var key = r.read_until(BytesConstant.COLON)
#         r.increment()
#         if is_space(r.peek()):
#             r.increment()

#         # TODO (bgreni): Handle possible trailing whitespace
#         var value = r.read_line()
#         var k = StringSlice(unsafe_from_utf8=key).lower()
#         if k == HeaderKey.SET_COOKIE:
#             cookies.append(String(bytes=value))
#             continue

#         headers._inner[k] = String(bytes=value)
#     return (
#         Protocol.from_string(StringSlice(unsafe_from_utf8=first)),
#         String(bytes=second),
#         String(bytes=third),
#         cookies^,
#     )
