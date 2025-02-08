from floki.header import HeaderKey, Header


@fieldwise_init
struct Cookie(Copyable, ExplicitlyCopyable, Movable):
    alias EXPIRES = "Expires"
    alias MAX_AGE = "Max-Age"
    alias DOMAIN = "Domain"
    alias PATH = "Path"
    alias SECURE = "Secure"
    alias HTTP_ONLY = "HttpOnly"
    alias SAME_SITE = "SameSite"
    alias PARTITIONED = "Partitioned"

    alias SEPERATOR = "; "
    alias EQUAL = "="

    var name: String
    var value: String
    var expires: Expiration
    var secure: Bool
    var http_only: Bool
    var partitioned: Bool
    var same_site: Optional[SameSite]
    var domain: Optional[String]
    var path: Optional[String]
    var max_age: Optional[Duration]

    @staticmethod
    fn from_set_header(header_str: StringSlice) raises -> Self:
        var parts = header_str.split(Cookie.SEPERATOR)
        if len(parts) < 1:
            raise Error("invalid Cookie")

        var cookie = Cookie("", String(parts[0]), path=String("/"))
        if Cookie.EQUAL in parts[0]:
            var name_value = parts[0].split(Cookie.EQUAL)
            cookie.name = String(name_value[0])
            cookie.value = String(name_value[1])

        for i in range(1, len(parts)):
            var part = parts[i]
            if part == Cookie.PARTITIONED:
                cookie.partitioned = True
            elif part == Cookie.SECURE:
                cookie.secure = True
            elif part == Cookie.HTTP_ONLY:
                cookie.http_only = True
            elif part.startswith(Cookie.SAME_SITE):
                cookie.same_site = SameSite.from_string(part.removeprefix(Cookie.SAME_SITE + Cookie.EQUAL))
            elif part.startswith(Cookie.DOMAIN):
                cookie.domain = String(part.removeprefix(Cookie.DOMAIN + Cookie.EQUAL))
            elif part.startswith(Cookie.PATH):
                cookie.path = String(part.removeprefix(Cookie.PATH + Cookie.EQUAL))
            elif part.startswith(Cookie.MAX_AGE):
                cookie.max_age = Duration.from_string(part.removeprefix(Cookie.MAX_AGE + Cookie.EQUAL))
            elif part.startswith(Cookie.EXPIRES):
                if expires := Expiration.from_string(part.removeprefix(Cookie.EXPIRES + Cookie.EQUAL)):
                    cookie.expires = expires.value()

        return cookie^

    fn __init__(
        out self,
        name: String,
        value: String,
        expires: Expiration = Expiration.session(),
        max_age: Optional[Duration] = Optional[Duration](None),
        domain: Optional[String] = Optional[String](None),
        path: Optional[String] = Optional[String](None),
        same_site: Optional[SameSite] = Optional[SameSite](None),
        secure: Bool = False,
        http_only: Bool = False,
        partitioned: Bool = False,
    ):
        self.name = name
        self.value = value
        self.expires = expires
        self.max_age = max_age
        self.domain = domain
        self.path = path
        self.secure = secure
        self.http_only = http_only
        self.same_site = same_site
        self.partitioned = partitioned

    fn __str__(self) -> String:
        return String.write("Name: ", self.name, " Value: ", self.value)

    fn clear_cookie(mut self):
        self.max_age = Optional[Duration](None)
        self.expires = Expiration.invalidate()

    fn to_header(self) raises -> Header:
        return Header(HeaderKey.SET_COOKIE, self.build_header_value())

    fn build_header_value(self) -> String:
        var header_value = String.write(self.name, Cookie.EQUAL, self.value)
        if self.expires.is_datetime():
            try:
                if v := self.expires.http_date_timestamp():
                    header_value.write(Cookie.SEPERATOR, Cookie.EXPIRES, Cookie.EQUAL, v.value())
            except:
                # TODO: This should be a hardfail however Writeable trait write_to method does not raise
                # the call flow needs to be refactored
                pass

        if self.max_age:
            header_value.write(
                Cookie.SEPERATOR, Cookie.MAX_AGE, Cookie.EQUAL, String(self.max_age.value().total_seconds)
            )
        if self.domain:
            header_value.write(Cookie.SEPERATOR, Cookie.DOMAIN, Cookie.EQUAL, self.domain.value())
        if self.path:
            header_value.write(Cookie.SEPERATOR, Cookie.PATH, Cookie.EQUAL, self.path.value())
        if self.secure:
            header_value.write(Cookie.SEPERATOR, Cookie.SECURE)
        if self.http_only:
            header_value.write(Cookie.SEPERATOR, Cookie.HTTP_ONLY)
        if self.same_site:
            header_value.write(Cookie.SEPERATOR, Cookie.SAME_SITE, Cookie.EQUAL, String(self.same_site.value()))
        if self.partitioned:
            header_value.write(Cookie.SEPERATOR, Cookie.PARTITIONED)
        return header_value
