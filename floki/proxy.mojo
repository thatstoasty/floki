"""The `Proxy` type used to configure proxying for requests made by a `Session`."""


struct Proxy(Boolable, Movable):
    """Proxy configuration for requests made by a `Session`.

    The proxy `url` may include a scheme and port, e.g. `http://proxy.example:8080`
    or `socks5://127.0.0.1:1080`. Optional credentials and a `no_proxy` bypass list
    can be supplied as well.

    A bare URL string can be passed wherever a `Proxy` is expected
    (e.g. `proxy="http://proxy.example:8080"`). A default-constructed `Proxy()`
    means "no proxy".
    """

    var url: String
    """The proxy URL, including optional scheme and port. Empty means no proxy."""
    var username: Optional[String]
    """The username to authenticate with the proxy, or `None`."""
    var password: Optional[String]
    """The password to authenticate with the proxy, or `None`."""
    var no_proxy: List[String]
    """A list of hosts that should bypass the proxy, or `None`."""

    @implicit
    def __init__(
        out self,
        var url: String,
        *,
        username: Optional[String] = None,
        password: Optional[String] = None,
        var no_proxy: List[String] = [],
    ) raises:
        """Constructs a `Proxy` from a URL and optional settings.

        Args:
            url: The proxy URL, including optional scheme and port.
            username: The username to authenticate with the proxy, or `None`.
            password: The password to authenticate with the proxy, or `None`.
            no_proxy: A list of hosts that should bypass the proxy.
        """
        if url.byte_length() <= 0:
            raise Error("Proxy URL cannot be empty")

        self.url = url^
        self.username = username
        self.password = password
        self.no_proxy = no_proxy^

    def __bool__(self) -> Bool:
        """Reports whether a proxy is configured.

        Returns:
            True if a non-empty proxy URL is set, False otherwise.
        """
        return self.url.byte_length() > 0
