"""Authentication schemes that can be applied to outgoing HTTP requests."""
from floki.headers import Headers
from std import base64


trait Auth(Copyable, Movable):
    """A strategy for authenticating an HTTP request.

    Implement this trait to define a custom authentication scheme. The `apply`
    method receives the request's headers and may add whatever headers the scheme
    requires (an `Authorization` header, an `X-Api-Key` header, a signed request
    header, etc.).

    #### Examples:
    ```mojo
    from floki.auth import Auth
    from floki.headers import Headers

    @fieldwise_init
    struct ApiKeyAuth(Auth):
        var key: String

        def apply(self, mut headers: Headers):
            headers["X-Api-Key"] = self.key
    ```
    """

    def apply(self, mut headers: Headers):
        """Applies this authentication scheme to the request headers.

        Apply should not override any headers that are already present in `headers`.

        Args:
            headers: The request headers to mutate in place.
        """
        ...


@fieldwise_init
struct NoAuth(Auth):
    """An `Auth` scheme that applies no authentication.

    Used as the default when no `auth` argument is supplied to a request.
    """

    def apply(self, mut headers: Headers):
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
            The `Basic <base64>` credential string, per RFC 7617.
        """
        return String(t"Basic {base64.b64encode(String(t'{self.username}:{self.password}'))}")

    def apply(self, mut headers: Headers):
        """Adds a Basic `Authorization` header to the request.

        Args:
            headers: The request headers to mutate in place.
        """
        if "Authorization" not in headers:
            headers["Authorization"] = self.header_value()


@fieldwise_init
struct BearerAuth(Auth):
    """HTTP Bearer token authentication credentials (RFC 6750)."""

    var token: String
    """The bearer token to authenticate with."""

    def header_value(self) -> String:
        """Builds the `Authorization` header value for this token.

        Returns:
            The `Bearer <token>` credential string, per RFC 6750.
        """
        return String(t"Bearer {self.token}")

    def apply(self, mut headers: Headers):
        """Adds a Bearer `Authorization` header to the request.

        Args:
            headers: The request headers to mutate in place.
        """
        if "Authorization" not in headers:
            headers["Authorization"] = self.header_value()
