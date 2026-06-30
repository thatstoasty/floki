struct TLS(Copyable, Movable):
    """TLS/SSL verification settings for requests made by a `Session`.

    By default, floki verifies the server's certificate chain and that the
    certificate matches the requested host. Verification can be disabled (use
    with great caution — this defeats the security guarantees of TLS), and a
    custom certificate authority bundle or directory can be supplied for cases
    such as self-signed certificates or private PKIs.
    """
    var verify: Bool
    """Whether to verify the server's TLS certificate and hostname. Defaults to True."""
    var ca_bundle: Optional[String]
    """Path to a custom CA certificate bundle file (PEM), or `None` to use the default."""
    var ca_path: Optional[String]
    """Path to a directory of CA certificates, or `None` to use the default."""

    def __init__(
        out self,
        verify: Bool = True,
        *,
        ca_bundle: Optional[String] = None,
        ca_path: Optional[String] = None,
    ):
        """Constructs a `TLS` configuration.

        Args:
            verify: Whether to verify the server's TLS certificate and hostname.
            ca_bundle: Path to a custom CA certificate bundle file (PEM), or `None`.
            ca_path: Path to a directory of CA certificates, or `None`.
        """
        self.verify = verify
        self.ca_bundle = ca_bundle
        self.ca_path = ca_path
