from std.collections.dict import Hasher
from small_time import now
from mojo_curl.list import CurlList
from floki.cookie.cookie import Cookie


@fieldwise_init
struct CookieKey(KeyElement):
    """A key for identifying cookies in the CookieJar, based on name, domain, and path."""
    var name: String
    """The cookie name."""
    var domain: String
    """The cookie domain."""
    var path: String
    """The cookie path."""

    @implicit
    fn __init__(
        out self,
        name: String,
        domain: Optional[String] = None,
        path: Optional[String] = None,
    ):
        """Constructs a CookieKey from name, domain, and path.

        Args:
            name: The cookie name.
            domain: The cookie domain. Defaults to empty string if None.
            path: The cookie path. Defaults to "/" if None.
        """
        self.name = name
        self.domain = domain.or_else("")
        self.path = path.or_else("/")

    fn __eq__(self: Self, other: Self) -> Bool:
        """Compares two CookieKey instances for equality.

        Args:
            other: The CookieKey to compare with.

        Returns:
            True if name, domain, and path all match.
        """
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
struct CookieJar(Copyable, Sized, Writable, Defaultable):
    """A collection of cookies, indexed by CookieKey (name, domain, path)."""
    var _inner: Dict[CookieKey, Cookie]
    """Internal dictionary storing cookies by their keys."""

    fn __init__(out self):
        """Constructs an empty CookieJar."""
        self._inner = Dict[CookieKey, Cookie]()

    fn __init__(out self, *cookies: Cookie) raises:
        """Constructs a CookieJar pre-populated with the given cookies.
        
        Args:
            cookies: A variable number of Cookie instances to add to the jar.
        
        Raises:
            Error: If any of the provided cookies are invalid.
        """
        self._inner = Dict[CookieKey, Cookie]()
        for cookie in cookies:
            self.set_cookie(cookie.copy())

    fn __init__(out self, var raw_cookies: CurlList) raises:
        """Constructs a CookieJar by parsing cookies from a libcurl cookie list.

        Args:
            raw_cookies: A CurlList of raw cookie strings to parse.

        Raises:
            Error: If a cookie string cannot be parsed.
        """
        self._inner = Dict[CookieKey, Cookie]()
        try:
            for cookie in raw_cookies:
                self.set_cookie(Cookie(cookie))
        finally:
            raw_cookies^.free()

    @always_inline
    fn __setitem__(mut self, var key: CookieKey, var value: Cookie):
        """Sets a cookie in the jar by key.

        Args:
            key: The CookieKey identifying the cookie.
            value: The Cookie to store.
        """
        self._inner[key^] = value^

    fn __getitem__(ref self, var key: CookieKey) raises -> ref [self._inner] Cookie:
        """Retrieves a cookie from the jar by key.

        Args:
            key: The CookieKey identifying the cookie.

        Returns:
            A reference to the Cookie.

        Raises:
            KeyError: If the key is not found.
        """
        return self._inner[key^]

    fn get(self, key: CookieKey) -> Optional[Cookie]:
        """Retrieves a cookie from the jar by key, returning None if not found.

        Args:
            key: The CookieKey identifying the cookie.

        Returns:
            The Cookie if found, or None.
        """
        return self._inner.get(key)

    @always_inline
    fn __contains__(self, key: CookieKey) -> Bool:
        """Checks if a cookie with the given key exists in the jar.

        Args:
            key: The CookieKey to look up.

        Returns:
            True if the cookie is present.
        """
        return key in self._inner

    @always_inline
    fn __contains__(self, key: Cookie) -> Bool:
        """Checks if the given cookie exists in the jar.

        Args:
            key: The Cookie to look up (matched by name, domain, and path).

        Returns:
            True if the cookie is present.
        """
        return CookieKey(key.name, key.domain, key.path) in self

    @always_inline
    fn __len__(self) -> Int:
        """Returns the number of cookies in the jar.

        Returns:
            The cookie count.
        """
        return len(self._inner)

    @always_inline
    fn __bool__(self) -> Bool:
        """Returns True if the cookie jar is empty.

        Returns:
            True if the jar contains no cookies.
        """
        return len(self) == 0

    @always_inline
    fn set_cookie(mut self, var cookie: Cookie):
        """Adds or replaces a cookie in the jar.

        Args:
            cookie: The Cookie to store.
        """
        self[CookieKey(cookie.name, cookie.domain, cookie.path)] = cookie^

    fn add_headers_to_jar(mut self, headers: List[String]) raises:
        """Parses cookie header strings and adds them to the jar.

        Args:
            headers: A list of raw cookie header strings to parse.

        Raises:
            Error: If a header string cannot be parsed as a cookie.
        """
        for header in headers:
            var cookie: Cookie
            try:
                cookie = Cookie(header)
            except:
                raise Error("Failed to parse cookie header string: ", header)
            
            self.set_cookie(cookie^)

    fn write_to(self, mut writer: Some[Writer]):
        """Writes all cookies as `Set-Cookie` headers to a writer.

        Args:
            writer: The writer to which the cookie headers will be written.
        """
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