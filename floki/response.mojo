from floki.http import Protocol, Status
from floki.body import Body
from floki.cookie.cookie_jar import CookieJar

comptime WHITESPACE = " "
comptime CRLF = "\r\n"


@fieldwise_init
struct HTTPError(Movable):
    var status: Status


@fieldwise_init
struct HTTPResponse(Movable, Writable):
    var headers: Dict[String, String]
    var cookies: CookieJar
    var body: Body
    var status: Status
    var protocol: Protocol

    fn __init__(
        out self,
        var body: List[Byte],
        var cookies: CookieJar,
        status: Status,
        protocol: Protocol,
        var headers: Dict[String, String] = {},
    ) raises:
        self.headers = headers^
        self.cookies = cookies^
        self.status = status
        self.protocol = protocol
        self.body = Body(body^)

    fn write_to(self, mut writer: Some[Writer]):
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

    fn __str__(self) -> String:
        return String.write(self)

    @always_inline
    fn is_redirect(self) -> Bool:
        return self.status in [
            Status.MOVED_PERMANENTLY,
            Status.FOUND,
            Status.TEMPORARY_REDIRECT,
            Status.PERMANENT_REDIRECT,
        ]
    
    @always_inline
    fn is_ok(self) -> Bool:
        return self.status == Status.OK
    
    fn raise_for_status(self) raises HTTPError:
        if not self.is_ok():
            raise HTTPError(self.status)
