from std.collections.string._utf8 import _is_valid_utf8

import emberjson


struct Body(Copyable, Sized):
    """Represents the body of an HTTP request or response.

    At the moment, this only supports JSON serialization and deserialization.
    """

    var body: List[Byte]
    """The raw body content as a list of bytes."""
    var _json_cache: Optional[emberjson.Value]
    """An optional cache for the parsed JSON value, to avoid redundant parsing on multiple accesses."""

    fn __init__(out self, var body: List[Byte]) raises:
        """Constructs a Body instance from a list of bytes.

        Args:
            body: The body content as a list of bytes.
        
        Raises:
            * Error: if the body is not valid UTF-8.
        """
        if not _is_valid_utf8(body):
            raise Error("Body must be valid UTF-8")

        self.body = body^
        self._json_cache = None

    fn __init__[origin: ImmutOrigin, //](out self, body: Span[Byte, origin]) raises:
        """Alternate constructor that accepts a Span[Byte] for the body content.

        Parameters:
            origin: The origin of the data span.

        Args:
            body: The body content as a span of bytes.
        
        Raises:
            * Error: if the body is not valid UTF-8.
        """
        if not _is_valid_utf8(body):
            raise Error("Body must be valid UTF-8")
        self.body = List[Byte](body)
        self._json_cache = None

    fn __len__(self) -> Int:
        """Returns the length of the body in bytes.

        Returns:
            The number of bytes in the body.
        """
        return len(self.body)

    fn as_bytes(self) -> Span[Byte, origin_of(self.body)]:
        """Returns a view of the body content as a span of bytes.

        Returns:
            A `Span[Byte]` referencing the body's underlying data.
        """
        return Span(self.body)

    fn as_string_slice(self) -> StringSlice[origin_of(self.body)]:
        """Creates and returns a `StringSlice` view of the body content.

        Returns:
            The body content as a string slice.
        """
        return StringSlice(unsafe_from_utf8=Span(self.body))

    fn as_json(mut self) raises -> ref [origin_of(self._json_cache._value)] emberjson.Value:
        """Converts the response body to a JSON object.
        
        Returns:
            The body content parsed as a JSON value.
        
        Raises:
            Error: if the body is empty or cannot be parsed as JSON.
        """
        if not self.body:
            raise Error("Body is empty; cannot parse as JSON.")

        if self._json_cache:
            return self._json_cache.value()

        self._json_cache = emberjson.parse(StringSlice(from_utf8=self.body))
        return self._json_cache.value()

    fn write_to(self, mut writer: Some[Writer]):
        """Writes the body to a writer.

        Args:
            writer: The writer to which the body will be written.
        """
        writer.write(StringSlice(unsafe_from_utf8=self.body))

    fn consume(deinit self) -> List[Byte]:
        """Consumes the body and returns it as List[Byte].
        
        Returns:
            The body content as a list of bytes.
        """
        return self.body^
