@fieldwise_init
struct Protocol(ImplicitlyCopyable, Copyable, Movable, Writable):
    var value: UInt8
    comptime HTTP = Self(0)
    comptime HTTPS = Self(1)

    fn write_to[T: Writer, //](self, mut writer: T):
        writer.write(self.value)

    @staticmethod
    fn from_string(s: StringSlice) raises -> Self:
        if s == "http":
            return Self.HTTP
        elif s == "https":
            return Self.HTTPS
        else:
            raise Error("Invalid protocol: ", s)


@fieldwise_init
@register_passable("trivial")
struct StatusCode(Copyable, EqualityComparable, Movable, Writable, Stringable):
    var value: UInt16

    comptime CONTINUE = Self(100)
    comptime SWITCHING_PROTOCOLS = Self(101)
    comptime PROCESSING = Self(102)
    comptime EARLY_HINTS = Self(103)

    comptime OK = Self(200)
    comptime CREATED = Self(201)
    comptime ACCEPTED = Self(202)
    comptime NON_AUTHORITATIVE_INFORMATION = Self(203)
    comptime NO_CONTENT = Self(204)
    comptime RESET_CONTENT = Self(205)
    comptime PARTIAL_CONTENT = Self(206)
    comptime MULTI_STATUS = Self(207)
    comptime ALREADY_REPORTED = Self(208)
    comptime IM_USED = Self(226)

    comptime MULTIPLE_CHOICES = Self(300)
    comptime MOVED_PERMANENTLY = Self(301)
    comptime FOUND = Self(302)
    comptime TEMPORARY_REDIRECT = Self(307)
    comptime PERMANENT_REDIRECT = Self(308)

    comptime BAD_REQUEST = Self(400)
    comptime UNAUTHORIZED = Self(401)
    comptime PAYMENT_REQUIRED = Self(402)
    comptime FORBIDDEN = Self(403)
    comptime NOT_FOUND = Self(404)
    comptime METHOD_NOT_ALLOWED = Self(405)
    comptime NOT_ACCEPTABLE = Self(406)
    comptime PROXY_AUTHENTICATION_REQUIRED = Self(407)
    comptime REQUEST_TIMEOUT = Self(408)
    comptime CONFLICT = Self(409)
    comptime GONE = Self(410)
    comptime LENGTH_REQUIRED = Self(411)
    comptime PRECONDITION_FAILED = Self(412)
    comptime PAYLOAD_TOO_LARGE = Self(413)
    comptime URI_TOO_LONG = Self(414)
    comptime UNSUPPORTED_MEDIA_TYPE = Self(415)
    comptime RANGE_NOT_SATISFIABLE = Self(416)
    comptime EXPECTATION_FAILED = Self(417)
    comptime IM_A_TEAPOT = Self(418)
    comptime MISDIRECTED_REQUEST = Self(421)
    comptime UNPROCESSABLE_ENTITY = Self(422)
    comptime LOCKED = Self(423)
    comptime FAILED_DEPENDENCY = Self(424)
    comptime TOO_EARLY = Self(425)
    comptime UPGRADE_REQUIRED = Self(426)
    comptime PRECONDITION_REQUIRED = Self(428)
    comptime TOO_MANY_REQUESTS = Self(429)
    comptime REQUEST_HEADER_FIELDS_TOO_LARGE = Self(431)
    comptime UNAVAILABLE_FOR_LEGAL_REASONS = Self(451)

    comptime INTERNAL_ERROR = Self(500)
    comptime NOT_IMPLEMENTED = Self(501)
    comptime BAD_GATEWAY = Self(502)
    comptime SERVICE_UNAVAILABLE = Self(503)
    comptime GATEWAY_TIMEOUT = Self(504)
    comptime HTTP_VERSION_NOT_SUPPORTED = Self(505)
    comptime VARIANT_ALSO_NEGOTIATES = Self(506)
    comptime INSUFFICIENT_STORAGE = Self(507)
    comptime LOOP_DETECTED = Self(508)
    comptime NOT_EXTENDED = Self(510)
    comptime NETWORK_AUTHENTICATION_REQUIRED = Self(511)

    @staticmethod
    fn from_int(code: Int) raises -> StatusCode:
        """Creates a StatusCode instance from an integer representation.

        Arguments:
            s: The integer representation of the status code.

        Returns:
            A StatusCode instance corresponding to the provided integer.
        """
        # For every comptime defined in StatusCode, check if the integer matches
        # the value of the alias.
        if Self.OK == code:
            return Self.OK
        elif Self.CREATED == code:
            return Self.CREATED
        elif Self.ACCEPTED == code:
            return Self.ACCEPTED
        elif Self.NON_AUTHORITATIVE_INFORMATION == code:
            return Self.NON_AUTHORITATIVE_INFORMATION
        elif Self.NO_CONTENT == code:
            return Self.NO_CONTENT
        elif Self.RESET_CONTENT == code:
            return Self.RESET_CONTENT
        elif Self.PARTIAL_CONTENT == code:
            return Self.PARTIAL_CONTENT
        elif Self.MULTI_STATUS == code:
            return Self.MULTI_STATUS
        elif Self.ALREADY_REPORTED == code:
            return Self.ALREADY_REPORTED
        elif Self.IM_USED == code:
            return Self.IM_USED
        elif Self.MULTIPLE_CHOICES == code:
            return Self.MULTIPLE_CHOICES
        elif Self.MOVED_PERMANENTLY == code:
            return Self.MOVED_PERMANENTLY
        elif Self.FOUND == code:
            return Self.FOUND
        elif Self.TEMPORARY_REDIRECT == code:
            return Self.TEMPORARY_REDIRECT
        elif Self.PERMANENT_REDIRECT == code:
            return Self.PERMANENT_REDIRECT
        elif Self.BAD_REQUEST == code:
            return Self.BAD_REQUEST
        elif Self.UNAUTHORIZED == code:
            return Self.UNAUTHORIZED
        elif Self.PAYMENT_REQUIRED == code:
            return Self.PAYMENT_REQUIRED
        elif Self.FORBIDDEN == code:
            return Self.FORBIDDEN
        elif Self.NOT_FOUND == code:
            return Self.NOT_FOUND
        elif Self.METHOD_NOT_ALLOWED == code:
            return Self.METHOD_NOT_ALLOWED
        elif Self.NOT_ACCEPTABLE == code:
            return Self.NOT_ACCEPTABLE
        elif Self.PROXY_AUTHENTICATION_REQUIRED == code:
            return Self.PROXY_AUTHENTICATION_REQUIRED
        elif Self.REQUEST_TIMEOUT == code:
            return Self.REQUEST_TIMEOUT
        elif Self.CONFLICT == code:
            return Self.CONFLICT
        elif Self.GONE == code:
            return Self.GONE
        elif Self.LENGTH_REQUIRED == code:
            return Self.LENGTH_REQUIRED
        elif Self.PRECONDITION_FAILED == code:
            return Self.PRECONDITION_FAILED
        elif Self.PAYLOAD_TOO_LARGE == code:
            return Self.PAYLOAD_TOO_LARGE
        elif Self.URI_TOO_LONG == code:
            return Self.URI_TOO_LONG
        elif Self.UNSUPPORTED_MEDIA_TYPE == code:
            return Self.UNSUPPORTED_MEDIA_TYPE
        elif Self.RANGE_NOT_SATISFIABLE == code:
            return Self.RANGE_NOT_SATISFIABLE
        elif Self.EXPECTATION_FAILED == code:
            return Self.EXPECTATION_FAILED
        elif Self.IM_A_TEAPOT == code:
            return Self.IM_A_TEAPOT
        elif Self.MISDIRECTED_REQUEST == code:
            return Self.MISDIRECTED_REQUEST
        elif Self.UNPROCESSABLE_ENTITY == code:
            return Self.UNPROCESSABLE_ENTITY
        elif Self.LOCKED == code:
            return Self.LOCKED
        elif Self.FAILED_DEPENDENCY == code:
            return Self.FAILED_DEPENDENCY
        elif Self.TOO_EARLY == code:
            return Self.TOO_EARLY
        elif Self.UPGRADE_REQUIRED == code:
            return Self.UPGRADE_REQUIRED
        elif Self.PRECONDITION_REQUIRED == code:
            return Self.PRECONDITION_REQUIRED
        elif Self.TOO_MANY_REQUESTS == code:
            return Self.TOO_MANY_REQUESTS
        elif Self.REQUEST_HEADER_FIELDS_TOO_LARGE == code:
            return Self.REQUEST_HEADER_FIELDS_TOO_LARGE
        elif Self.UNAVAILABLE_FOR_LEGAL_REASONS == code:
            return Self.UNAVAILABLE_FOR_LEGAL_REASONS
        elif Self.INTERNAL_ERROR == code:
            return Self.INTERNAL_ERROR
        elif Self.NOT_IMPLEMENTED == code:
            return Self.NOT_IMPLEMENTED
        elif Self.BAD_GATEWAY == code:
            return Self.BAD_GATEWAY
        elif Self.SERVICE_UNAVAILABLE == code:
            return Self.SERVICE_UNAVAILABLE
        elif Self.GATEWAY_TIMEOUT == code:
            return Self.GATEWAY_TIMEOUT
        elif Self.HTTP_VERSION_NOT_SUPPORTED == code:
            return Self.HTTP_VERSION_NOT_SUPPORTED
        elif Self.VARIANT_ALSO_NEGOTIATES == code:
            return Self.VARIANT_ALSO_NEGOTIATES
        elif Self.INSUFFICIENT_STORAGE == code:
            return Self.INSUFFICIENT_STORAGE
        elif Self.LOOP_DETECTED == code:
            return Self.LOOP_DETECTED
        elif Self.NOT_EXTENDED == code:
            return Self.NOT_EXTENDED
        elif Self.NETWORK_AUTHENTICATION_REQUIRED == code:
            return Self.NETWORK_AUTHENTICATION_REQUIRED
        elif Self.CONTINUE == code:
            return Self.CONTINUE
        elif Self.SWITCHING_PROTOCOLS == code:
            return Self.SWITCHING_PROTOCOLS
        elif Self.PROCESSING == code:
            return Self.PROCESSING
        elif Self.EARLY_HINTS == code:
            return Self.EARLY_HINTS
        else:
            raise Error("Unknown status code: ", code)

    fn __eq__(self, other: Self) -> Bool:
        """Compares two StatusCode instances for equality.

        Arguments:
            other: The StatusCode instance to compare with.

        Returns:
            True if both instances have the same value, otherwise False.
        """
        return self.value == other.value

    fn __eq__(self, other: Int) -> Bool:
        """Compares a StatusCode instance with an integer for equality.

        Arguments:
            other: The integer to compare with.

        Returns:
            True if the StatusCode instance's value matches the integer, otherwise False.
        """
        return self.value == other

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        """Writes the StatusCode instance to a writer.

        This method is used to write the status code in a human-readable format.

        Args:
            writer: The writer to which the status code will be written.
        """
        writer.write(self.value)
    
    fn __str__(self) -> String:
        """Converts the StatusCode instance to its string representation.

        Returns:
            A string representation of the status code.
        """
        return String(self.value)


@fieldwise_init
struct RequestMethod(ImplicitlyCopyable, Copyable, Movable, Writable, EqualityComparable):
    var value: UInt8

    comptime GET = Self(0)
    comptime POST = Self(1)
    comptime PUT = Self(2)
    comptime DELETE = Self(3)
    comptime HEAD = Self(4)
    comptime PATCH = Self(5)
    comptime OPTIONS = Self(6)

    fn write_to[T: Writer, //](self, mut writer: T):
        writer.write(self.value)

    @staticmethod
    fn from_string(s: StringSlice) raises -> Self:
        if s == "GET":
            return RequestMethod.GET
        elif s == "POST":
            return RequestMethod.POST
        elif s == "PUT":
            return RequestMethod.PUT
        elif s == "DELETE":
            return RequestMethod.DELETE
        elif s == "HEAD":
            return RequestMethod.HEAD
        elif s == "PATCH":
            return RequestMethod.PATCH
        elif s == "OPTIONS":
            return RequestMethod.OPTIONS
        else:
            raise Error("Invalid HTTP method: ", s)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value