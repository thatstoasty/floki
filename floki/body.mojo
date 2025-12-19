from collections.string._utf8 import _is_valid_utf8

import emberjson


struct Body(Copyable, Sized):
    """Represents the body of an HTTP request or response.

    At the moment, this only supports JSON serialization and deserialization.
    """

    var body: List[Byte]
    var _json_cache: Optional[emberjson.JSON]

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

    fn __init__(out self, body: Span[Byte]) raises:
        """Alternate constructor that accepts a Span[Byte] for the body content.

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
        return len(self.body)

    fn as_bytes(self) -> Span[Byte, origin_of(self.body)]:
        return Span(self.body)

    fn as_string_slice(self) -> StringSlice[origin_of(self.body)]:
        """Creates and returns a `StringSlice` view of the body content.

        Returns:
            The body content as a string slice.
        """
        return StringSlice(unsafe_from_utf8=Span(self.body))

    fn as_json(mut self) raises -> ref [origin_of(self._json_cache._value)] emberjson.JSON:
        """Converts the response body to a JSON object."""
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
        """Consumes the body and returns it as List[Byte]."""
        return self.body^
