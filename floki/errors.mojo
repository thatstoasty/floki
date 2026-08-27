"""Typed errors raised by floki when an HTTP request fails at the transport level."""
from std.utils import Variant
from mojo_curl.easy import Result


trait FlokiError(Movable, Writable):
    """A trait for errors raised by floki when an HTTP request fails before a usable response is received."""
    ...


@fieldwise_init
struct ConnectionError(FlokiError):
    """An error raised when an HTTP request fails due to a connection-level failure.

    This error is raised when the underlying transport fails to establish a connection
    to the server, such as when DNS resolution fails, the connection is refused, or
    the connection is dropped mid-transfer.
    """

    def write_to(self, mut writer: Some[Writer]):
        """Writes a human-readable representation of the error.

        Args:
            writer: The writer to which the error will be written.
        """
        writer.write("ConnectionError: A Connection error occurred.")


@fieldwise_init
struct TimeoutError(FlokiError):
    """An error raised when an HTTP request exceeds its configured timeout.

    This error is raised when the request takes longer than the timeout specified in
    the session configuration, indicating that the server did not respond in time.
    """

    def write_to(self, mut writer: Some[Writer]):
        """Writes a human-readable representation of the error.

        Args:
            writer: The writer to which the error will be written.
        """
        writer.write("TimeoutError: The request exceeded its configured timeout.")


@fieldwise_init
struct TLSError(FlokiError):
    """An error raised when an HTTP request fails due to a TLS/SSL failure.

    This error is raised when the underlying transport encounters a TLS/SSL error,
    such as a handshake failure or a certificate verification failure.
    """

    def write_to(self, mut writer: Some[Writer]):
        """Writes a human-readable representation of the error.

        Args:
            writer: The writer to which the error will be written.
        """
        writer.write("TLSError: A TLS/SSL error occurred.")


@fieldwise_init
struct TooManyRedirectsError(FlokiError):
    """An error raised when an HTTP request follows too many redirects.

    This error is raised when the request exceeds the maximum number of redirects
    allowed by libcurl, indicating a potential redirect loop or misconfiguration.
    """

    def write_to(self, mut writer: Some[Writer]):
        """Writes a human-readable representation of the error.

        Args:
            writer: The writer to which the error will be written.
        """
        writer.write("TooManyRedirectsError: The request followed too many redirects.")


@fieldwise_init
struct TransportError(FlokiError):
    """An error raised when an HTTP request fails due to a transport-level failure.

    This error is raised for transport-level failures that do not fall into more
    specific categories, such as connection errors, timeouts, TLS errors, or too many
    redirects.
    """

    def write_to(self, mut writer: Some[Writer]):
        """Writes a human-readable representation of the error.

        Args:
            writer: The writer to which the error will be written.
        """
        writer.write("TransportError: A transport-level failure occurred.")


@fieldwise_init
struct RequestError(FlokiError):
    """An error raised when an HTTP request fails before a usable response is received.

    Unlike `HTTPError` (which represents a response that *was* received but carried a
    non-2xx status), a `RequestError` represents a transport-level failure: the request
    never completed. Inspect `kind` to branch on the category of the failure.
    """

    comptime _TIMEOUT_CODES = [Result.OPERATION_TIMEDOUT]
    comptime _CONNECTION_CODES = [
        Result.COULDNT_CONNECT,
        Result.COULDNT_RESOLVE_HOST,
        Result.COULDNT_RESOLVE_PROXY,
        Result.GOT_NOTHING,
        Result.SEND_ERROR,
        Result.RECV_ERROR,
    ]
    comptime _TLS_CODES = [
        Result.SSL_CONNECT_ERROR,
        Result.PEER_FAILED_VERIFICATION,
        Result.SSL_CERT_PROBLEM,
        Result.SSL_CACERT_BAD_FILE,
    ]

    comptime _type = Variant[Error, ConnectionError, TimeoutError, TLSError, TooManyRedirectsError, TransportError]
    """The error type enum."""
    var value: Self._type
    """The underlying error value, which may be one of several specific error types."""

    def __init__(out self, code: Result):
        """Constructs a `RequestError` from a libcurl result code.

        Args:
            code: The libcurl result code from a failed transfer.

        Returns:
            A `RequestError` representing the failure, with the appropriate kind and details.
        """
        if code == Result.OPERATION_TIMEDOUT:
            self.value = TimeoutError()
        elif code in materialize[Self._CONNECTION_CODES]():
            self.value = ConnectionError()
        elif code in materialize[Self._TLS_CODES]():
            self.value = TLSError()
        elif code in materialize[Self._TIMEOUT_CODES]():
            self.value = TimeoutError()
        else:
            self.value = TransportError()

    @implicit
    def __init__(out self, var e: Error):
        """Constructs a `RequestError` from a low-level `Error`.

        Args:
            e: The underlying `Error` returned by the libcurl FFI.
        """
        self.value = e^

    @implicit
    def __init__(out self, var e: ConnectionError):
        """Constructs a `RequestError` from a low-level `ConnectionError`.

        Args:
            e: The underlying `ConnectionError`.
        """
        self.value = e^
    
    @implicit
    def __init__(out self, var e: TimeoutError):
        """Constructs a `RequestError` from a low-level `TimeoutError`.

        Args:
            e: The underlying `TimeoutError`.
        """
        self.value = e^
    
    @implicit
    def __init__(out self, var e: TLSError):
        """Constructs a `RequestError` from a low-level `TLSError`.

        Args:
            e: The underlying `TLSError`.
        """
        self.value = e^
    
    @implicit
    def __init__(out self, var e: TooManyRedirectsError):
        """Constructs a `RequestError` from a low-level `TooManyRedirectsError`.

        Args:
            e: The underlying `TooManyRedirectsError`.
        """
        self.value = e^

    @implicit
    def __init__(out self, var e: TransportError):
        """Constructs a `RequestError` from a low-level `TransportError`.

        Args:
            e: The underlying `TransportError`.
        """
        self.value = e^

    def __getitem_param__[T: FlokiError](ref self) -> ref[origin_of(self.value)._get_owned_interior["value"]] T:
        """Returns a reference to the underlying error value of the specified type.

        Parameters:
            T: The specific error type to retrieve.

        Returns:
            A reference to the underlying error value of type `T`.
        """
        return self.value[T]
    
    def isa[T: FlokiError](self) -> Bool:
        """Checks if the underlying error value is of the specified type.

        Parameters:
            T: The specific error type to check against.

        Returns:
            True if the underlying error value is of type `T`, False otherwise.
        """
        return self.value.isa[T]()

    def write_to(self, mut writer: Some[Writer]):
        """Writes a human-readable representation of the error.

        Args:
            writer: The writer to which the error will be written.
        """
        comptime for i in range(len(Self._type.Ts)):
            comptime t = Self._type.Ts[i]
            comptime if conforms_to(t, Writable):
                if self.value.isa[t]():
                    writer.write(self.value[t])
                    return

        writer.write("RequestError: An unknown error occurred.")
    
    def to_error(deinit self) -> Error:
        """Converts the `RequestError` into a low-level `Error`.

        If the underlying error value is already an `Error`, it is returned directly.
        Otherwise, a new `Error` is constructed with a message describing the failure.

        Returns:
            An `Error` representing the underlying failure.
        """
        if self.value.isa[Error]():
            return self.value^.unwrap[Error]()
        
        return Error(self.value)
