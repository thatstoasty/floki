from std import base64


trait Auth(Copyable, Movable):
    """A strategy for authenticating an HTTP request.

    Implement this trait to define a custom authentication scheme. The `apply`
    method receives the request's header dictionary and may add whatever headers
    the scheme requires (an `Authorization` header, an `X-Api-Key` header, a
    signed request header, etc.).

    #### Examples:
    ```mojo
    from floki.auth import Auth

    @fieldwise_init
    struct ApiKeyAuth(Auth):
        var key: String

        def apply(self, mut headers: Dict[String, String]):
            headers["X-Api-Key"] = self.key
    ```
    """

    def apply(self, mut headers: Dict[String, String]):
        """Applies this authentication scheme to the request headers.

        Args:
            headers: The request headers to mutate in place.
        """
        ...


@fieldwise_init
struct NoAuth(Auth):
    """An `Auth` scheme that applies no authentication.

    Used as the default when no `auth` argument is supplied to a request.
    """

    def apply(self, mut headers: Dict[String, String]):
        """Applies no authentication, leaving the headers unchanged.

        Args:
            headers: The request headers (left unchanged).
        """
        pass


@fieldwise_init
struct BasicAuth(Auth):
    """HTTP Basic authentication credentials (RFC 7617)."""

    var username: String
    """The username to authenticate with."""
    var password: String
    """The password to authenticate with."""

    def header_value(self) -> String:
        """Builds the `Authorization` header value for these credentials.

        Returns:
            The `Basic <base64>` header value.
        """
        return String(t"Basic {base64.b64encode(String(t'{self.username}:{self.password}'))}")

    def apply(self, mut headers: Dict[String, String]):
        """Adds a Basic `Authorization` header to the request.

        Args:
            headers: The request headers to mutate in place.
        """
        headers["Authorization"] = self.header_value()


@fieldwise_init
struct BearerAuth(Auth):
    """HTTP Bearer token authentication credentials (RFC 6750)."""

    var token: String
    """The bearer token to authenticate with."""

    def header_value(self) -> String:
        """Builds the `Authorization` header value for this token.

        Returns:
            The `Bearer <token>` header value.
        """
        return String(t"Bearer {self.token}")

    def apply(self, mut headers: Dict[String, String]):
        """Adds a Bearer `Authorization` header to the request.

        Args:
            headers: The request headers to mutate in place.
        """
        headers["Authorization"] = self.header_value()


def apply_auth[A: Auth, //](auth: A, mut headers: Dict[String, String]):
    """Applies an authentication scheme to request headers without overriding existing entries.

    Headers already present in `headers` (e.g. an explicit `Authorization` header
    set on the request) take precedence over those supplied by `auth`.

    Parameters:
        A: The concrete `Auth` scheme type.

    Args:
        auth: The authentication scheme to apply.
        headers: The request headers to mutate in place.
    """
    var auth_headers = Dict[String, String]()
    auth.apply(auth_headers)
    for entry in auth_headers.items():
        if entry.key not in headers:
            headers[entry.key] = entry.value
