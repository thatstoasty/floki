@fieldwise_init
struct Protocol(Equatable, ImplicitlyCopyable, Writable):
    """Represents the protocol used in an HTTP request or response."""
    var value: UInt8
    """Internal enum value."""
    comptime HTTP = Self(0)
    """Represents the HTTP protocol. This is the default protocol used for web communication."""
    comptime HTTPS = Self(1)
    """Represents the HTTPS protocol, which is the secure version of HTTP. It uses encryption to protect data transmitted between the client and server."""

    fn __init__(out self, s: StringSlice) raises:
        """Constructs a Protocol from its string representation.

        Args:
            s: The string representation of the protocol ("http" or "https").

        Raises:
            Error: If the string does not match a known protocol.
        """
        if s == "http":
            return Self.HTTP
        elif s == "https":
            return Self.HTTPS
        else:
            raise Error("Invalid protocol: ", s)
    
    fn __eq__(self, other: Self) -> Bool:
        """Compares two Protocol instances for equality.

        Args:
            other: The Protocol instance to compare with.

        Returns:
            True if both instances represent the same protocol.
        """
        return self.value == other.value
    
    fn write_to(self, mut writer: Some[Writer]):
        """Writes the protocol name to a writer.

        Args:
            writer: The writer to which the protocol name will be written.
        """
        if self == Self.HTTP:
            writer.write("http")
        else:
            writer.write("https")   


@fieldwise_init
struct Status(Copyable, Equatable, Writable, TrivialRegisterPassable):
    """Represents the status of an HTTP response, including the status code and a corresponding message."""
    var code: UInt16
    """Represents the status code of an HTTP response. The status code indicates the result of the HTTP request and provides information about the success or failure of the request."""
    var message: StaticString
    """A human-readable message corresponding to the status code. This message provides additional information about the status of the HTTP response."""

    comptime CONTINUE = Self(100, "Continue")
    """HTTP 100: The server has received the request headers and the client should proceed to send the request body."""
    comptime SWITCHING_PROTOCOLS = Self(101, "Switching Protocols")
    """HTTP 101: The server is switching protocols as requested by the client."""
    comptime PROCESSING = Self(102, "Processing")
    """HTTP 102: The server has received and is processing the request, but no response is available yet."""
    comptime EARLY_HINTS = Self(103, "Early Hints")
    """HTTP 103: The server is sending some response headers before the final HTTP message."""

    comptime OK = Self(200, "OK")
    """HTTP 200: The request has succeeded."""
    comptime CREATED = Self(201, "Created")
    """HTTP 201: The request has been fulfilled and a new resource has been created."""
    comptime ACCEPTED = Self(202, "Accepted")
    """HTTP 202: The request has been accepted for processing, but processing has not been completed."""
    comptime NON_AUTHORITATIVE_INFORMATION = Self(203, "Non-Authoritative Information")
    """HTTP 203: The returned metadata is not exactly the same as available from the origin server."""
    comptime NO_CONTENT = Self(204, "No Content")
    """HTTP 204: The server successfully processed the request but is not returning any content."""
    comptime RESET_CONTENT = Self(205, "Reset Content")
    """HTTP 205: The server successfully processed the request and is asking the client to reset the document view."""
    comptime PARTIAL_CONTENT = Self(206, "Partial Content")
    """HTTP 206: The server is delivering only part of the resource due to a range header sent by the client."""
    comptime MULTI_STATUS = Self(207, "Multi-Status")
    """HTTP 207: The message body contains multiple status codes for multiple independent operations."""
    comptime ALREADY_REPORTED = Self(208, "Already Reported")
    """HTTP 208: The members of a DAV binding have already been enumerated in a previous reply."""
    comptime IM_USED = Self(226, "IM Used")
    """HTTP 226: The server has fulfilled a request for the resource with instance-manipulations applied."""
    comptime MULTIPLE_CHOICES = Self(300, "Multiple Choices")
    """HTTP 300: The request has more than one possible response."""
    comptime MOVED_PERMANENTLY = Self(301, "Moved Permanently")
    """HTTP 301: The resource has been permanently moved to a new URL."""
    comptime FOUND = Self(302, "Found")
    """HTTP 302: The resource resides temporarily under a different URL."""
    comptime TEMPORARY_REDIRECT = Self(307, "Temporary Redirect")
    """HTTP 307: The request should be repeated with another URL, but future requests should still use the original URL."""
    comptime PERMANENT_REDIRECT = Self(308, "Permanent Redirect")
    """HTTP 308: The resource has been permanently moved to a new URL and all future requests should use the new URL."""

    comptime BAD_REQUEST = Self(400, "Bad Request")
    """HTTP 400: The server cannot process the request due to a client error."""
    comptime UNAUTHORIZED = Self(401, "Unauthorized")
    """HTTP 401: Authentication is required and has failed or has not been provided."""
    comptime PAYMENT_REQUIRED = Self(402, "Payment Required")
    """HTTP 402: Reserved for future use; generally indicates payment is required."""
    comptime FORBIDDEN = Self(403, "Forbidden")
    """HTTP 403: The server understood the request but refuses to authorize it."""
    comptime NOT_FOUND = Self(404, "Not Found")
    """HTTP 404: The requested resource could not be found on the server."""
    comptime METHOD_NOT_ALLOWED = Self(405, "Method Not Allowed")
    """HTTP 405: The HTTP method is not allowed for the requested resource."""
    comptime NOT_ACCEPTABLE = Self(406, "Not Acceptable")
    """HTTP 406: The server cannot produce a response matching the acceptable values defined in the request headers."""
    comptime PROXY_AUTHENTICATION_REQUIRED = Self(407, "Proxy Authentication Required")
    """HTTP 407: The client must first authenticate itself with the proxy."""
    comptime REQUEST_TIMEOUT = Self(408, "Request Timeout")
    """HTTP 408: The server timed out waiting for the request."""
    comptime CONFLICT = Self(409, "Conflict")
    """HTTP 409: The request conflicts with the current state of the server."""
    comptime GONE = Self(410, "Gone")
    """HTTP 410: The requested resource is no longer available and will not be available again."""
    comptime LENGTH_REQUIRED = Self(411, "Length Required")
    """HTTP 411: The request did not specify the length of its content, which is required by the resource."""
    comptime PRECONDITION_FAILED = Self(412, "Precondition Failed")
    """HTTP 412: A precondition given in the request headers was not met by the server."""
    comptime PAYLOAD_TOO_LARGE = Self(413, "Payload Too Large")
    """HTTP 413: The request entity is larger than the server is willing or able to process."""
    comptime URI_TOO_LONG = Self(414, "URI Too Long")
    """HTTP 414: The URI provided was too long for the server to process."""
    comptime UNSUPPORTED_MEDIA_TYPE = Self(415, "Unsupported Media Type")
    """HTTP 415: The media type of the request data is not supported by the server."""
    comptime RANGE_NOT_SATISFIABLE = Self(416, "Range Not Satisfiable")
    """HTTP 416: The range specified in the Range header cannot be fulfilled."""
    comptime EXPECTATION_FAILED = Self(417, "Expectation Failed")
    """HTTP 417: The expectation given in the Expect header could not be met by the server."""
    comptime IM_A_TEAPOT = Self(418, "I'm a teapot")
    """HTTP 418: The server refuses to brew coffee because it is, permanently, a teapot."""
    comptime MISDIRECTED_REQUEST = Self(421, "Misdirected Request")
    """HTTP 421: The request was directed at a server that is not able to produce a response."""
    comptime UNPROCESSABLE_ENTITY = Self(422, "Unprocessable Entity")
    """HTTP 422: The request was well-formed but could not be followed due to semantic errors."""
    comptime LOCKED = Self(423, "Locked")
    """HTTP 423: The resource that is being accessed is locked."""
    comptime FAILED_DEPENDENCY = Self(424, "Failed Dependency")
    """HTTP 424: The request failed because it depended on another request that failed."""
    comptime TOO_EARLY = Self(425, "Too Early")
    """HTTP 425: The server is unwilling to process a request that might be replayed."""
    comptime UPGRADE_REQUIRED = Self(426, "Upgrade Required")
    """HTTP 426: The client should switch to a different protocol as indicated in the Upgrade header."""
    comptime PRECONDITION_REQUIRED = Self(428, "Precondition Required")
    """HTTP 428: The origin server requires the request to be conditional."""
    comptime TOO_MANY_REQUESTS = Self(429, "Too Many Requests")
    """HTTP 429: The user has sent too many requests in a given amount of time."""
    comptime REQUEST_HEADER_FIELDS_TOO_LARGE = Self(431, "Request Header Fields Too Large")
    """HTTP 431: The server is unwilling to process the request because its header fields are too large."""
    comptime UNAVAILABLE_FOR_LEGAL_REASONS = Self(451, "Unavailable For Legal Reasons")
    """HTTP 451: The resource is unavailable due to legal reasons."""

    comptime INTERNAL_ERROR = Self(500, "Internal Server Error")
    """HTTP 500: The server encountered an unexpected condition that prevented it from fulfilling the request."""
    comptime NOT_IMPLEMENTED = Self(501, "Not Implemented")
    """HTTP 501: The server does not support the functionality required to fulfill the request."""
    comptime BAD_GATEWAY = Self(502, "Bad Gateway")
    """HTTP 502: The server received an invalid response from an upstream server."""
    comptime SERVICE_UNAVAILABLE = Self(503, "Service Unavailable")
    """HTTP 503: The server is currently unable to handle the request due to temporary overloading or maintenance."""
    comptime GATEWAY_TIMEOUT = Self(504, "Gateway Timeout")
    """HTTP 504: The server did not receive a timely response from an upstream server."""
    comptime HTTP_VERSION_NOT_SUPPORTED = Self(505, "HTTP Version Not Supported")
    """HTTP 505: The server does not support the HTTP protocol version used in the request."""
    comptime VARIANT_ALSO_NEGOTIATES = Self(506, "Variant Also Negotiates")
    """HTTP 506: Transparent content negotiation for the request results in a circular reference."""
    comptime INSUFFICIENT_STORAGE = Self(507, "Insufficient Storage")
    """HTTP 507: The server is unable to store the representation needed to complete the request."""
    comptime LOOP_DETECTED = Self(508, "Loop Detected")
    """HTTP 508: The server detected an infinite loop while processing the request."""
    comptime NOT_EXTENDED = Self(510, "Not Extended")
    """HTTP 510: Further extensions to the request are required for the server to fulfill it."""
    comptime NETWORK_AUTHENTICATION_REQUIRED = Self(511, "Network Authentication Required")
    """HTTP 511: The client needs to authenticate to gain network access."""

    fn __init__(out self, code: Int) raises:
        """Creates a Status instance from an integer representation.

        Args:
            code: The integer representation of the status code.

        Returns:
            A Status instance corresponding to the provided integer.
        
        Raises:
            Error: If the integer does not correspond to a known status code.
        """
        # For every comptime defined in Status, check if the integer matches
        # the value of the alias.
        if Self.OK == code:
            self = Self.OK
        elif Self.CREATED == code:
            self = Self.CREATED
        elif Self.ACCEPTED == code:
            self = Self.ACCEPTED
        elif Self.NON_AUTHORITATIVE_INFORMATION == code:
            self = Self.NON_AUTHORITATIVE_INFORMATION
        elif Self.NO_CONTENT == code:
            self = Self.NO_CONTENT
        elif Self.RESET_CONTENT == code:
            self = Self.RESET_CONTENT
        elif Self.PARTIAL_CONTENT == code:
            self = Self.PARTIAL_CONTENT
        elif Self.MULTI_STATUS == code:
            self = Self.MULTI_STATUS
        elif Self.ALREADY_REPORTED == code:
            self = Self.ALREADY_REPORTED
        elif Self.IM_USED == code:
            self = Self.IM_USED
        elif Self.MULTIPLE_CHOICES == code:
            self = Self.MULTIPLE_CHOICES
        elif Self.MOVED_PERMANENTLY == code:
            self = Self.MOVED_PERMANENTLY
        elif Self.FOUND == code:
            self = Self.FOUND
        elif Self.TEMPORARY_REDIRECT == code:
            self = Self.TEMPORARY_REDIRECT
        elif Self.PERMANENT_REDIRECT == code:
            self = Self.PERMANENT_REDIRECT
        elif Self.BAD_REQUEST == code:
            self = Self.BAD_REQUEST
        elif Self.UNAUTHORIZED == code:
            self = Self.UNAUTHORIZED
        elif Self.PAYMENT_REQUIRED == code:
            self = Self.PAYMENT_REQUIRED
        elif Self.FORBIDDEN == code:
            self = Self.FORBIDDEN
        elif Self.NOT_FOUND == code:
            self = Self.NOT_FOUND
        elif Self.METHOD_NOT_ALLOWED == code:
            self = Self.METHOD_NOT_ALLOWED
        elif Self.NOT_ACCEPTABLE == code:
            self = Self.NOT_ACCEPTABLE
        elif Self.PROXY_AUTHENTICATION_REQUIRED == code:
            self = Self.PROXY_AUTHENTICATION_REQUIRED
        elif Self.REQUEST_TIMEOUT == code:
            self = Self.REQUEST_TIMEOUT
        elif Self.CONFLICT == code:
            self = Self.CONFLICT
        elif Self.GONE == code:
            self = Self.GONE
        elif Self.LENGTH_REQUIRED == code:
            self = Self.LENGTH_REQUIRED
        elif Self.PRECONDITION_FAILED == code:
            self = Self.PRECONDITION_FAILED
        elif Self.PAYLOAD_TOO_LARGE == code:
            self = Self.PAYLOAD_TOO_LARGE
        elif Self.URI_TOO_LONG == code:
            self = Self.URI_TOO_LONG
        elif Self.UNSUPPORTED_MEDIA_TYPE == code:
            self = Self.UNSUPPORTED_MEDIA_TYPE
        elif Self.RANGE_NOT_SATISFIABLE == code:
            self = Self.RANGE_NOT_SATISFIABLE
        elif Self.EXPECTATION_FAILED == code:
            self = Self.EXPECTATION_FAILED
        elif Self.IM_A_TEAPOT == code:
            self = Self.IM_A_TEAPOT
        elif Self.MISDIRECTED_REQUEST == code:
            self = Self.MISDIRECTED_REQUEST
        elif Self.UNPROCESSABLE_ENTITY == code:
            self = Self.UNPROCESSABLE_ENTITY
        elif Self.LOCKED == code:
            self = Self.LOCKED
        elif Self.FAILED_DEPENDENCY == code:
            self = Self.FAILED_DEPENDENCY
        elif Self.TOO_EARLY == code:
            self = Self.TOO_EARLY
        elif Self.UPGRADE_REQUIRED == code:
            self = Self.UPGRADE_REQUIRED
        elif Self.PRECONDITION_REQUIRED == code:
            self = Self.PRECONDITION_REQUIRED
        elif Self.TOO_MANY_REQUESTS == code:
            self = Self.TOO_MANY_REQUESTS
        elif Self.REQUEST_HEADER_FIELDS_TOO_LARGE == code:
            self = Self.REQUEST_HEADER_FIELDS_TOO_LARGE
        elif Self.UNAVAILABLE_FOR_LEGAL_REASONS == code:
            self = Self.UNAVAILABLE_FOR_LEGAL_REASONS
        elif Self.INTERNAL_ERROR == code:
            self = Self.INTERNAL_ERROR
        elif Self.NOT_IMPLEMENTED == code:
            self = Self.NOT_IMPLEMENTED
        elif Self.BAD_GATEWAY == code:
            self = Self.BAD_GATEWAY
        elif Self.SERVICE_UNAVAILABLE == code:
            self = Self.SERVICE_UNAVAILABLE
        elif Self.GATEWAY_TIMEOUT == code:
            self = Self.GATEWAY_TIMEOUT
        elif Self.HTTP_VERSION_NOT_SUPPORTED == code:
            self = Self.HTTP_VERSION_NOT_SUPPORTED
        elif Self.VARIANT_ALSO_NEGOTIATES == code:
            self = Self.VARIANT_ALSO_NEGOTIATES
        elif Self.INSUFFICIENT_STORAGE == code:
            self = Self.INSUFFICIENT_STORAGE
        elif Self.LOOP_DETECTED == code:
            self = Self.LOOP_DETECTED
        elif Self.NOT_EXTENDED == code:
            self = Self.NOT_EXTENDED
        elif Self.NETWORK_AUTHENTICATION_REQUIRED == code:
            self = Self.NETWORK_AUTHENTICATION_REQUIRED
        elif Self.CONTINUE == code:
            self = Self.CONTINUE
        elif Self.SWITCHING_PROTOCOLS == code:
            self = Self.SWITCHING_PROTOCOLS
        elif Self.PROCESSING == code:
            self = Self.PROCESSING
        elif Self.EARLY_HINTS == code:
            self = Self.EARLY_HINTS
        else:
            raise Error("Unknown status code: ", code)

    fn __eq__(self, other: Int) -> Bool:
        """Compares a Status instance with an integer for equality.

        Args:
            other: The integer to compare with.

        Returns:
            True if the Status instance's value matches the integer, otherwise False.
        """
        return self.code == UInt16(other)

    fn write_to(self, mut writer: Some[Writer]) -> None:
        """Writes the Status instance to a writer.

        This method is used to write the status code in a human-readable format.

        Args:
            writer: The writer to which the status code will be written.
        """
        writer.write(self.code, " ", self.message)


@fieldwise_init
struct RequestMethod(Equatable, ImplicitlyCopyable, Writable):
    """Represents the HTTP method used in an HTTP request, such as GET, POST, PUT, DELETE, etc."""
    var value: UInt8
    """Internal enum value."""

    comptime GET = Self(0)
    """The GET method is used to retrieve data from a server. It is a read-only operation and should not have any side effects on the server's state."""
    comptime POST = Self(1)
    """The POST method is used to submit data to a server, often resulting in a change in the server's state or side effects. It is commonly used for creating new resources or submitting form data."""
    comptime PUT = Self(2)
    """The PUT method is used to update an existing resource on the server or create a new resource if it does not exist. It is idempotent, meaning that multiple identical requests should have the same effect as a single request."""
    comptime DELETE = Self(3)
    """The DELETE method is used to delete a resource on the server. It is also idempotent, meaning that multiple identical requests should have the same effect as a single request."""
    comptime HEAD = Self(4)
    """The HEAD method is similar to GET, but it only retrieves the headers of a resource without the body. It is often used to check if a resource exists or to retrieve metadata about a resource without downloading the entire content."""
    comptime PATCH = Self(5)
    """The PATCH method is used to apply partial modifications to a resource on the server. It is not idempotent, meaning that multiple identical requests may have different effects."""
    comptime OPTIONS = Self(6)
    """The OPTIONS method is used to describe the communication options for the target resource. It allows clients to discover which HTTP methods are supported by the server for a specific resource."""

    fn __init__(out self, s: StringSlice) raises:
        """Constructs a RequestMethod from its string representation.

        Args:
            s: The string representation of the HTTP method (e.g. "GET", "POST").

        Raises:
            Error: If the string does not match a known HTTP method.
        """
        if s == "GET":
            self = RequestMethod.GET
        elif s == "POST":
            self = RequestMethod.POST
        elif s == "PUT":
            self = RequestMethod.PUT
        elif s == "DELETE":
            self = RequestMethod.DELETE
        elif s == "HEAD":
            self = RequestMethod.HEAD
        elif s == "PATCH":
            self = RequestMethod.PATCH
        elif s == "OPTIONS":
            self = RequestMethod.OPTIONS
        else:
            raise Error("Invalid HTTP method: ", s)
