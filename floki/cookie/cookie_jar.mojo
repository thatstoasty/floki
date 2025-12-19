from collections.dict import Hasher
from small_time import now
from mojo_curl.list import CurlList
from floki.cookie.cookie import Cookie


@fieldwise_init
struct CookieKey(KeyElement):
    var name: String
    var domain: String
    var path: String

    @implicit
    fn __init__(
        out self,
        name: String,
        domain: Optional[String] = None,
        path: Optional[String] = None,
    ):
        self.name = name
        self.domain = domain.or_else("")
        self.path = path.or_else("/")

    fn __eq__(self: Self, other: Self) -> Bool:
        return self.name == other.name and self.domain == other.domain and self.path == other.path

    fn __hash__[H: Hasher](self, mut hasher: H):
        """Updates hasher with the underlying bytes.

        Parameters:
            H: The hasher type.

        Args:
            hasher: The hasher instance.
        """
        hasher.update(String(self.name, "~", self.domain, "~", self.path))


@fieldwise_init
struct CookieJar(Copyable, Sized, Stringable, Writable, Defaultable):
    var _inner: Dict[CookieKey, Cookie]

    fn __init__(out self):
        self._inner = Dict[CookieKey, Cookie]()

    fn __init__(out self, *cookies: Cookie):
        self._inner = Dict[CookieKey, Cookie]()
        for cookie in cookies:
            self.set_cookie(cookie.copy())

    fn __init__(out self, var raw_cookies: CurlList) raises:
        self._inner = Dict[CookieKey, Cookie]()
        try:
            for cookie in raw_cookies:
                self.set_cookie(Cookie(cookie))
        finally:
            raw_cookies^.free()

    @always_inline
    fn __setitem__(mut self, var key: CookieKey, var value: Cookie):
        self._inner[key^] = value^

    fn __getitem__(ref self, var key: CookieKey) raises -> ref [self._inner._entries[0].value().value] Cookie:
        return self._inner[key^]

    fn get(self, key: CookieKey) -> Optional[Cookie]:
        return self._inner.get(key)

    @always_inline
    fn __contains__(self, key: CookieKey) -> Bool:
        return key in self._inner

    @always_inline
    fn __contains__(self, key: Cookie) -> Bool:
        return CookieKey(key.name, key.domain, key.path) in self

    fn __str__(self) -> String:
        return String.write(self)

    @always_inline
    fn __len__(self) -> Int:
        return len(self._inner)

    @always_inline
    fn __bool__(self) -> Bool:
        return len(self) == 0

    @always_inline
    fn set_cookie(mut self, var cookie: Cookie):
        self[CookieKey(cookie.name, cookie.domain, cookie.path)] = cookie^

    fn add_headers_to_jar(mut self, headers: List[String]) raises:
        for header in headers:
            var cookie: Cookie
            try:
                cookie = Cookie(header)
            except:
                raise Error("Failed to parse cookie header string: ", header)
            
            self.set_cookie(cookie^)

    fn write_to[T: Writer](self, mut writer: T):
        for cookie in self._inner.values():
            writer.write("set-cookie", ": ", cookie.build_header_value())

    # fn clear_expired_cookies(mut self) raises:
    #     var now = now()
    #     var keys_to_remove = List[CookieKey]()
    #     for kv in self._inner.items():
    #         if kv.value.is_expired(now):
    #             keys_to_remove.append(kv.key)

    #     for key in keys_to_remove:
    #         self._inner.remove(key)