import emberjson


struct Body(Copyable, Movable, Sized):
    """Represents the body of an HTTP request or response.

    At the moment, this only supports JSON serialization and deserialization.
    """

    var body: List[Byte]
    var _json_cache: Optional[emberjson.JSON]

    fn __init__(out self, body: Span[Byte]):
        self.body = List[Byte](body)
        self._json_cache = None

    fn __len__(self) -> Int:
        return len(self.body)

    fn as_bytes(self) -> Span[Byte, origin_of(self.body)]:
        return Span(self.body)

    fn as_string_slice(self) -> StringSlice[origin_of(self.body)]:
        return StringSlice(unsafe_from_utf8=Span(self.body))

    fn as_json(mut self) raises -> ref [origin_of(self._json_cache._value)] emberjson.JSON:
        """Converts the response body to a JSON object."""
        if not self.body:
            raise Error("Body is empty; cannot parse as JSON.")

        if self._json_cache:
            return self._json_cache.value()

        self._json_cache = emberjson.parse(StringSlice(unsafe_from_utf8=self.body))
        return self._json_cache.value()

    fn write_to[W: Writer, //](self, mut writer: W):
        """Writes the body to a writer.

        Parameters:
            W: The type of the writer.

        Args:
            writer: The writer to which the body will be written.
        """
        writer.write(StringSlice(unsafe_from_utf8=self.body))

    fn consume(mut self) -> List[Byte]:
        """Consumes the body and returns it as List[Byte]."""
        var consumed_body = self.body^
        self.body = List[Byte]()
        return consumed_body^
