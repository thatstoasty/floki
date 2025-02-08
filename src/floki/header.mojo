from floki.request import RequestMethod
from floki.bytes import Bytes, ByteReader, is_newline, is_space, BytesConstant, CRLF


@fieldwise_init
struct HeaderKey(Movable):
    # TODO: Fill in more of these
    alias CONNECTION = "connection"
    alias CONTENT_TYPE = "content-type"
    alias CONTENT_LENGTH = "content-length"
    alias CONTENT_ENCODING = "content-encoding"
    alias TRANSFER_ENCODING = "transfer-encoding"
    alias DATE = "date"
    alias LOCATION = "location"
    alias HOST = "host"
    alias SERVER = "server"
    alias SET_COOKIE = "set-cookie"
    alias COOKIE = "cookie"


@fieldwise_init
struct Header(Copyable, ExplicitlyCopyable, Movable, Stringable, Writable):
    var key: String
    var value: String

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[T: Writer, //](self, mut writer: T):
        writer.write(self.key, ": ", self.value, CRLF)


@always_inline
fn write_header[T: Writer, //](mut writer: T, key: String, value: String):
    writer.write(key, ": ", value, CRLF)


struct Headers(Copyable, ExplicitlyCopyable, Movable, Stringable, Writable):
    """Represents the header key/values in an http request/response.

    Header keys are normalized to lowercase.
    """

    var _inner: Dict[String, String]

    fn __init__(out self):
        self._inner = Dict[String, String]()

    @implicit
    fn __init__(out self, headers: Dict[String, String]):
        self._inner = headers

    fn __init__(out self, owned *headers: Header):
        self._inner = Dict[String, String]()
        for header in headers:
            self[header.key.lower()] = header.value

    @always_inline
    fn __init__(
        out self,
        owned keys: List[String],
        owned values: List[String],
        __dict_literal__: (),
    ):
        """Constructs a dictionary from the given keys and values.

        Args:
            keys: The list of keys to build the dictionary with.
            values: The corresponding values to pair with the keys.
            __dict_literal__: Tell Mojo to use this method for dict literals.
        """
        # TODO: Use power_of_two_initial_capacity to reserve space.
        self = Self()
        debug_assert(
            len(keys) == len(values),
            "keys and values must have the same length",
        )

        # TODO: Should transfer the key/value's from the list to avoid copying
        # the values.
        self._inner = Dict[String, String]()
        for i in range(len(keys)):
            self[keys[i].lower()] = values[i]

    @always_inline
    fn empty(self) -> Bool:
        return len(self._inner) == 0

    @always_inline
    fn __contains__(self, key: String) -> Bool:
        return key.lower() in self._inner

    @always_inline
    fn __getitem__(self, key: String) raises -> ref [self._inner._entries[0].value().value] String:
        try:
            return self._inner[key.lower()]
        except:
            raise Error("KeyError: Key not found in headers: ", key)

    @always_inline
    fn get(self, key: String) -> Optional[String]:
        return self._inner.get(key.lower())

    @always_inline
    fn __setitem__(mut self, key: String, value: String):
        self._inner[key.lower()] = value

    fn content_length(self) -> Int:
        try:
            return Int(self[HeaderKey.CONTENT_LENGTH])
        except:
            return 0

    fn _parse_raw(mut self, mut r: ByteReader) raises -> (RequestMethod, String, String, List[String]):
        var first_byte = r.peek()
        if not first_byte:
            raise Error("Headers._parse_raw: Failed to read first byte from response header")

        var first = r.read_word()
        r.increment()
        var second = r.read_word()
        r.increment()
        var third = r.read_line()
        var cookies = List[String]()

        while not is_newline(r.peek()):
            var key = r.read_until(BytesConstant.COLON)
            r.increment()
            if is_space(r.peek()):
                r.increment()

            # TODO (bgreni): Handle possible trailing whitespace
            var value = r.read_line()
            var k = StringSlice(unsafe_from_utf8=key).lower()
            if k == HeaderKey.SET_COOKIE:
                cookies.append(String(bytes=value))
                continue

            self._inner[k] = String(bytes=value)
        return (
            RequestMethod.from_string(StringSlice(unsafe_from_utf8=first)),
            String(bytes=second),
            String(bytes=third),
            cookies^,
        )

    fn write_to[T: Writer, //](self, mut writer: T):
        for header in self._inner.items():
            write_header(writer, header.key, header.value)

    fn __str__(self) -> String:
        return String(self)
