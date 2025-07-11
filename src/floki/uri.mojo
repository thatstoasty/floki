from floki.bytes import Bytes, ByteReader, bytes_equal


fn find_all(s: StringSlice, sub_str: StringSlice) -> List[Int]:
    match_idxs = List[Int]()
    var current_idx: Int = s.find(sub_str)
    while current_idx > -1:
        match_idxs.append(current_idx)
        current_idx = s.find(sub_str, start=current_idx + 1)
    return match_idxs^


fn _process_substrings[
    origin: ImmutableOrigin
](encoded_slice: StringSlice[origin], percent_idxs: List[Int], disallowed_escapes: List[StaticString]) -> List[String]:
    var current_idx = 0
    var slice_start = 0
    var sub_strings = List[String]()
    var str_bytes = List[Byte]()
    while current_idx < len(percent_idxs):
        var slice_end = percent_idxs[current_idx]
        sub_strings.append(String(encoded_slice[slice_start:slice_end]))

        var current_offset = slice_end
        while current_idx < len(percent_idxs):
            if (current_offset + 3) > len(encoded_slice):
                # If the percent escape is not followed by two hex digits, we stop processing.
                break

            try:
                char_byte = atol(
                    encoded_slice[current_offset + 1 : current_offset + 3],
                    base=16,
                )
                str_bytes.append(char_byte)
            except:
                break

            if percent_idxs[current_idx + 1] != (current_offset + 3):
                current_offset += 3
                break

            current_idx += 1
            current_offset = percent_idxs[current_idx]

        if len(str_bytes) > 0:
            var sub_str_from_bytes = String()
            sub_str_from_bytes.write_bytes(str_bytes)
            for disallowed in disallowed_escapes:
                sub_str_from_bytes = sub_str_from_bytes.replace(disallowed, "")
            sub_strings.append(sub_str_from_bytes)
            str_bytes.clear()

        slice_start = current_offset
        current_idx += 1

    return sub_strings


fn unquote[
    expand_plus: Bool = False
](text: StringSlice, disallowed_escapes: List[StaticString] = List[StaticString]()) -> String:
    var encoded_str: String

    @parameter
    if expand_plus:
        encoded_str = text.replace(QueryDelimiters.PLUS_ESCAPED_SPACE, " ")
    else:
        encoded_str = String(text)

    var percent_idxs: List[Int] = find_all(encoded_str, URIDelimiters.CHAR_ESCAPE)
    if len(percent_idxs) < 1:
        return encoded_str^

    var slice_start = 0

    var encoded_slice = encoded_str.as_string_slice()
    var sub_strings = _process_substrings(encoded_slice, percent_idxs, disallowed_escapes)
    sub_strings.append(String(encoded_slice[slice_start:]))

    return StaticString("").join(sub_strings)


alias QueryMap = Dict[String, String]


struct QueryDelimiters:
    alias STRING_START = "?"
    alias ITEM = "&"
    alias ITEM_ASSIGN = "="
    alias PLUS_ESCAPED_SPACE = "+"


struct URIDelimiters:
    alias SCHEMA = "://"
    alias PATH = "/"
    alias ROOT_PATH = "/"
    alias CHAR_ESCAPE = "%"
    alias AUTHORITY = "@"
    alias QUERY = "?"
    alias SCHEME = ":"


struct PortBounds:
    # For port parsing
    alias NINE: UInt8 = ord("9")
    alias ZERO: UInt8 = ord("0")


@fieldwise_init
struct Scheme(Copyable, EqualityComparable, ExplicitlyCopyable, Hashable, Movable, Representable, Stringable, Writable):
    var value: String
    alias HTTP = Self("http")
    alias HTTPS = Self("https")

    fn __hash__(self) -> UInt:
        return hash(self.value)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        return self.value != other.value

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        writer.write("Scheme(value=", repr(self.value), ")")

    fn __repr__(self) -> String:
        return String.write(self)

    fn __str__(self) -> String:
        return self.value.upper()


@fieldwise_init
struct URI(Copyable, ExplicitlyCopyable, Movable, Representable, Stringable, Writable):
    var _original_path: String
    var scheme: String
    var path: String
    var query_string: String
    var queries: QueryMap
    var _hash: String
    var host: String
    var port: Optional[UInt16]

    var full_uri: String
    var request_uri: String

    var username: String
    var password: String

    @staticmethod
    fn parse(owned uri: String) raises -> URI:
        """Parses a URI which is defined using the following format.

        `[scheme:][//[user_info@]host][/]path[?query][#fragment]`
        """
        var reader = ByteReader(uri.as_bytes())

        # TODO (@thatstoasty): We're scanning twice, looking for the protocol delimiter, then again.
        # Parse the scheme, if exists.
        # Assume http if no scheme is provided, fairly safe given the context of lightbug.
        var scheme: String = "http"
        if "://" in uri:
            var scheme_bytes = reader.read_until(ord(URIDelimiters.SCHEME))
            if not bytes_equal(reader.read_bytes(3), "://".as_bytes()):
                raise Error("URI.parse: Invalid URI format, scheme should be followed by `://`. Received: ", uri)
            scheme = String(bytes=scheme_bytes)

        # Parse the user info, if exists.
        # TODO (@thatstoasty): Store the user information (username and password) if it exists.
        if ord(URIDelimiters.AUTHORITY) in reader:
            _ = reader.read_until(ord(URIDelimiters.AUTHORITY))
            reader.increment(1)

        # TODOs (@thatstoasty)
        # Handle ipv4 and ipv6 literal
        # Handle string host
        # A query right after the domain is a valid uri, but it's equivalent to example.com/?query
        # so we should add the normalization of paths
        var host_and_port = StringSlice(unsafe_from_utf8=reader.read_until(ord(URIDelimiters.PATH)))
        colon = host_and_port.find(URIDelimiters.SCHEME)
        var host: String
        var port: Optional[UInt16] = None
        if colon != -1:
            host = String(host_and_port[:colon])
            var port_end = colon + 1
            # loop through the post colon chunk until we find a non-digit character
            for b in host_and_port[colon + 1 :].codepoints():
                if UInt8(b.to_u32()) < PortBounds.ZERO or UInt8(b.to_u32()) > PortBounds.NINE:
                    break
                port_end += 1
            port = UInt16(atol(String(host_and_port[colon + 1 : port_end])))
        else:
            host = String(host_and_port)

        # Reads until either the start of the query string, or the end of the uri.
        var unquote_reader = reader.copy()
        var original_path_bytes = unquote_reader.read_until(ord(URIDelimiters.QUERY))
        var original_path: String
        if not original_path_bytes:
            original_path = "/"
        else:
            original_path = unquote(String(bytes=original_path_bytes), disallowed_escapes=List(StaticString("/")))

        # Parse the path
        var path: String = "/"
        var request_uri: String = "/"
        if reader.available() and reader.peek() == ord(URIDelimiters.PATH):
            # Copy the remaining bytes to read the request uri.
            var request_uri_reader = reader.copy()
            request_uri = String(bytes=request_uri_reader.read_bytes())
            # Read until the query string, or the end if there is none.
            path = unquote(
                String(bytes=reader.read_until(ord(URIDelimiters.QUERY))), disallowed_escapes=List(StaticString("/"))
            )

        # Parse query
        var query: String = ""
        if reader.available() and reader.peek() == ord(URIDelimiters.QUERY):
            # TODO: Handle fragments for anchors
            query = String(bytes=reader.read_bytes()[1:])

        var queries = QueryMap()
        if query:
            var query_items = query.split(QueryDelimiters.ITEM)

            for item in query_items:
                var key_val = item.split(QueryDelimiters.ITEM_ASSIGN, 1)
                var key = unquote[expand_plus=True](key_val[0])

                if key:
                    queries[key] = ""
                    if len(key_val) == 2:
                        queries[key] = unquote[expand_plus=True](key_val[1])

        return URI(
            _original_path=original_path,
            scheme=scheme,
            path=path,
            query_string=query,
            queries=queries,
            _hash="",
            host=host,
            port=port,
            full_uri=uri,
            request_uri=request_uri,
            username="",
            password="",
        )

    fn __str__(self) -> String:
        var result = String(self.scheme, URIDelimiters.SCHEMA, self.host, self.path)
        if len(self.query_string) > 0:
            result.write(QueryDelimiters.STRING_START, self.query_string)
        return result^

    fn __repr__(self) -> String:
        return String(self)

    fn write_to[T: Writer](self, mut writer: T):
        writer.write(
            "URI(",
            "scheme=",
            repr(self.scheme),
            ", host=",
            repr(self.host),
            ", path=",
            repr(self.path),
            ", _original_path=",
            repr(self._original_path),
            ", query_string=",
            repr(self.query_string),
            ", full_uri=",
            repr(self.full_uri),
            ", request_uri=",
            repr(self.request_uri),
            ")",
        )

    fn is_https(self) -> Bool:
        return self.scheme == "https"

    fn is_http(self) -> Bool:
        return self.scheme == "http" or len(self.scheme) == 0
