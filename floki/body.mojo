import emberjson


struct Body(Copyable, Movable, Sized):
    """Represents the body of an HTTP request or response.

    At the moment, this only supports JSON serialization and deserialization.
    """

    var body: List[Byte]

    fn __init__(out self, body: Span[Byte]):
        self.body = List[Byte](body)

    fn __init__(out self, var body: List[Byte]):
        self.body = body^

    fn __init__(out self):
        self.body = List[Byte]()

    fn __init__(out self, data: Dict[String, String]):
        """Initializes the body from a dictionary, converting it to a form-encoded string."""
        var json = {x.key: emberjson.Value(x.value) for x in data.items()}
        self.body = List[Byte](emberjson.to_string(emberjson.Object(json^)).as_bytes())

    fn __len__(self) -> Int:
        return len(self.body)

    fn __iadd__(mut self, var other: Body):
        self.body += other.body^
        other.body = List[Byte]()

    fn __iadd__(mut self, other: Span[Byte]):
        self.body.extend(other)

    fn as_bytes(self) -> Span[Byte, origin_of(self.body)]:
        return Span(self.body)

    fn as_string_slice(self) -> StringSlice[origin_of(self.body)]:
        return StringSlice(unsafe_from_utf8=Span(self.body))

    fn as_dict(self) raises -> Dict[String, String]:
        """Converts the response body to a JSON object."""
        var parser = emberjson.Parser(StringSlice(unsafe_from_utf8=self.body))
        ref json = parser.parse().object()
        return {x.key: String(x.data) for x in json.items()}

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
