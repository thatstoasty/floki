# from floki.header import HeaderKey, Header
from small_time import SmallTime
from floki.cookie.same_site import SameSite
from floki.cookie.expiration import Expiration
from floki.cookie.duration import Duration


@fieldwise_init
struct Cookie(Copyable, Writable):
    comptime EXPIRES = "Expires"
    comptime MAX_AGE = "Max-Age"
    comptime DOMAIN = "Domain"
    comptime PATH = "Path"
    comptime SECURE = "Secure"
    comptime HTTP_ONLY = "HttpOnly"
    comptime SAME_SITE = "SameSite"
    comptime PARTITIONED = "Partitioned"

    comptime SEPERATOR = "; "
    comptime EQUAL = "="

    var name: String
    var value: String
    var expires: Expiration
    var secure: Bool
    # var http_only: Bool
    var partitioned: Bool
    # var same_site: Optional[SameSite]
    var domain: Optional[String]
    var path: Optional[String]
    # var max_age: Optional[Duration]

    fn __init__(
        out self,
        var name: String,
        var value: String,
        var expires: Expiration = Expiration(),
        # max_age: Optional[Duration] = Optional[Duration](None),
        domain: Optional[String] = Optional[String](None),
        path: Optional[String] = Optional[String](None),
        # same_site: Optional[SameSite] = Optional[SameSite](None),
        *,
        secure: Bool = False,
        # http_only: Bool = False,
        partitioned: Bool = False,
    ):
        self.name = name
        self.value = value
        self.expires = expires^
        # self.max_age = max_age
        self.domain = domain
        self.path = path
        self.secure = secure
        # self.http_only = http_only
        # self.same_site = same_site
        self.partitioned = partitioned

    fn __init__[origin: Origin](out self, header: StringSlice[origin]) raises:
        var raw_parts = header.split("\t")
        var parts: List[StringSlice[origin].Immutable] = [part for part in raw_parts]
        self.domain = String(parts[0])
        self.partitioned = parts[1] == "TRUE"
        self.path = String(parts[2])
        self.secure = parts[3] == "TRUE"
        self.expires = Expiration(parts[4])
        self.name = String(parts[5])
        self.value = String(parts[6])
    
    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Cookie(", "name=", self.name, ", value=", self.value, ")")

    fn __str__(self) -> String:
        return String.write("Name: ", self.name, " Value: ", self.value)

    fn clear_cookie(mut self):
        # self.max_age = None
        self.expires = Expiration.invalidate()

    # fn to_header(self) raises -> Header:
    #     return Header(HeaderKey.SET_COOKIE, self.build_header_value())

    fn build_header_value(self) -> String:
        var header_value = String.write(self.name, Self.EQUAL, self.value)
        if self.expires.is_datetime():
            try:
                if v := self.expires.http_date_timestamp():
                    header_value.write(Self.SEPERATOR, Self.EXPIRES, Self.EQUAL, v.value())
            except:
                # TODO: This should be a hardfail however Writeable trait write_to method does not raise
                # the call flow needs to be refactored
                pass

        # if self.max_age:
        #     header_value.write(
        #         Self.SEPERATOR, Self.MAX_AGE, Self.EQUAL, String(self.max_age.value().total_seconds)
        #     )
        if self.domain:
            header_value.write(Self.SEPERATOR, Self.DOMAIN, Self.EQUAL, self.domain.value())
        if self.path:
            header_value.write(Self.SEPERATOR, Self.PATH, Self.EQUAL, self.path.value())
        if self.secure:
            header_value.write(Self.SEPERATOR, Self.SECURE)
        # if self.http_only:
        #     header_value.write(Self.SEPERATOR, Self.HTTP_ONLY)
        # if self.same_site:
        #     header_value.write(Self.SEPERATOR, Self.SAME_SITE, Self.EQUAL, String(self.same_site.value()))
        if self.partitioned:
            header_value.write(Self.SEPERATOR, Self.PARTITIONED)
        return header_value^

    # fn is_expired(self, now: SmallTime) -> Bool:
    #     if self.expires.is_datetime():
    #         return self.expires.datetime.value() <= now
    