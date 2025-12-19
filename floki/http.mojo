@fieldwise_init
struct Protocol(Equatable, ImplicitlyCopyable, Writable):
    var value: UInt8
    comptime HTTP = Self(0)
    comptime HTTPS = Self(1)

    fn __init__(out self, s: StringSlice) raises:
        if s == "http":
            return Self.HTTP
        elif s == "https":
            return Self.HTTPS
        else:
            raise Error("Invalid protocol: ", s)
    
    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    
    fn write_to(self, mut writer: Some[Writer]):
        if self == Self.HTTP:
            writer.write("http")
        else:
            writer.write("https")   


@fieldwise_init
@register_passable("trivial")
struct Status(Copyable, Equatable, Stringable, Writable):
    var code: UInt16
    var message: StaticString

    comptime CONTINUE = Self(100, "Continue")
    comptime SWITCHING_PROTOCOLS = Self(101, "Switching Protocols")
    comptime PROCESSING = Self(102, "Processing")
    comptime EARLY_HINTS = Self(103, "Early Hints")

    comptime OK = Self(200, "OK")
    comptime CREATED = Self(201, "Created")
    comptime ACCEPTED = Self(202, "Accepted")
    comptime NON_AUTHORITATIVE_INFORMATION = Self(203, "Non-Authoritative Information")
    comptime NO_CONTENT = Self(204, "No Content")
    comptime RESET_CONTENT = Self(205, "Reset Content")
    comptime PARTIAL_CONTENT = Self(206, "Partial Content")
    comptime MULTI_STATUS = Self(207, "Multi-Status")
    comptime ALREADY_REPORTED = Self(208, "Already Reported")
    comptime IM_USED = Self(226, "IM Used")
    comptime MULTIPLE_CHOICES = Self(300, "Multiple Choices")
    comptime MOVED_PERMANENTLY = Self(301, "Moved Permanently")
    comptime FOUND = Self(302, "Found")
    comptime TEMPORARY_REDIRECT = Self(307, "Temporary Redirect")
    comptime PERMANENT_REDIRECT = Self(308, "Permanent Redirect")

    comptime BAD_REQUEST = Self(400, "Bad Request")
    comptime UNAUTHORIZED = Self(401, "Unauthorized")
    comptime PAYMENT_REQUIRED = Self(402, "Payment Required")
    comptime FORBIDDEN = Self(403, "Forbidden")
    comptime NOT_FOUND = Self(404, "Not Found")
    comptime METHOD_NOT_ALLOWED = Self(405, "Method Not Allowed")
    comptime NOT_ACCEPTABLE = Self(406, "Not Acceptable")
    comptime PROXY_AUTHENTICATION_REQUIRED = Self(407, "Proxy Authentication Required")
    comptime REQUEST_TIMEOUT = Self(408, "Request Timeout")
    comptime CONFLICT = Self(409, "Conflict")
    comptime GONE = Self(410, "Gone")
    comptime LENGTH_REQUIRED = Self(411, "Length Required")
    comptime PRECONDITION_FAILED = Self(412, "Precondition Failed")
    comptime PAYLOAD_TOO_LARGE = Self(413, "Payload Too Large")
    comptime URI_TOO_LONG = Self(414, "URI Too Long")
    comptime UNSUPPORTED_MEDIA_TYPE = Self(415, "Unsupported Media Type")
    comptime RANGE_NOT_SATISFIABLE = Self(416, "Range Not Satisfiable")
    comptime EXPECTATION_FAILED = Self(417, "Expectation Failed")
    comptime IM_A_TEAPOT = Self(418, "I'm a teapot")
    comptime MISDIRECTED_REQUEST = Self(421, "Misdirected Request")
    comptime UNPROCESSABLE_ENTITY = Self(422, "Unprocessable Entity")
    comptime LOCKED = Self(423, "Locked")
    comptime FAILED_DEPENDENCY = Self(424, "Failed Dependency")
    comptime TOO_EARLY = Self(425, "Too Early")
    comptime UPGRADE_REQUIRED = Self(426, "Upgrade Required")
    comptime PRECONDITION_REQUIRED = Self(428, "Precondition Required")
    comptime TOO_MANY_REQUESTS = Self(429, "Too Many Requests")
    comptime REQUEST_HEADER_FIELDS_TOO_LARGE = Self(431, "Request Header Fields Too Large")
    comptime UNAVAILABLE_FOR_LEGAL_REASONS = Self(451, "Unavailable For Legal Reasons")

    comptime INTERNAL_ERROR = Self(500, "Internal Server Error")
    comptime NOT_IMPLEMENTED = Self(501, "Not Implemented")
    comptime BAD_GATEWAY = Self(502, "Bad Gateway")
    comptime SERVICE_UNAVAILABLE = Self(503, "Service Unavailable")
    comptime GATEWAY_TIMEOUT = Self(504, "Gateway Timeout")
    comptime HTTP_VERSION_NOT_SUPPORTED = Self(505, "HTTP Version Not Supported")
    comptime VARIANT_ALSO_NEGOTIATES = Self(506, "Variant Also Negotiates")
    comptime INSUFFICIENT_STORAGE = Self(507, "Insufficient Storage")
    comptime LOOP_DETECTED = Self(508, "Loop Detected")
    comptime NOT_EXTENDED = Self(510, "Not Extended")
    comptime NETWORK_AUTHENTICATION_REQUIRED = Self(511, "Network Authentication Required")

    fn __init__(out self, code: Int) raises:
        """Creates a Status instance from an integer representation.

        Arguments:
            s: The integer representation of the status code.

        Returns:
            A Status instance corresponding to the provided integer.
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

    fn __eq__(self, other: Self) -> Bool:
        """Compares two Status instances for equality.

        Arguments:
            other: The Status instance to compare with.

        Returns:
            True if both instances have the same value, otherwise False.
        """
        return self.code == other.code and self.message == other.message

    fn __eq__(self, other: Int) -> Bool:
        """Compares a Status instance with an integer for equality.

        Arguments:
            other: The integer to compare with.

        Returns:
            True if the Status instance's value matches the integer, otherwise False.
        """
        return self.code == other

    fn write_to(self, mut writer: Some[Writer]) -> None:
        """Writes the Status instance to a writer.

        This method is used to write the status code in a human-readable format.

        Args:
            writer: The writer to which the status code will be written.
        """
        writer.write(self.code, " ", self.message)

    fn __str__(self) -> String:
        """Converts the Status instance to its string representation.

        Returns:
            A string representation of the status code.
        """
        return String.write(self)


@fieldwise_init
struct RequestMethod(Equatable, ImplicitlyCopyable, Writable):
    var value: UInt8

    comptime GET = Self(0)
    comptime POST = Self(1)
    comptime PUT = Self(2)
    comptime DELETE = Self(3)
    comptime HEAD = Self(4)
    comptime PATCH = Self(5)
    comptime OPTIONS = Self(6)

    fn __init__(out self, s: StringSlice) raises:
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

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    
    fn write_to(self, mut writer: Some[Writer]):
        writer.write(self.value)
