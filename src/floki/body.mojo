import emberjson
from floki.bytes import Bytes


struct Body(Movable, Sized):
    """Represents the body of an HTTP request or response.

    At the moment, this only supports JSON serialization and deserialization.
    """

    var body: Bytes

    fn __init__(out self, body: Span[Byte]):
        self.body = Bytes(body)

    fn __init__(out self, owned body: Bytes):
        self.body = body^

    fn __init__(out self):
        self.body = Bytes()

    fn __init__(out self, data: Dict[String, String]):
        """Initializes the body from a dictionary, converting it to a form-encoded string."""
        var json = {x.key: emberjson.Value(x.value) for x in data.items()}
        self.body = Bytes(emberjson.to_string(emberjson.Object(json)).as_bytes())

    fn __len__(self) -> Int:
        return len(self.body)

    fn __iadd__(mut self, other: Body):
        self.body += other.body

    fn __iadd__(mut self, other: Span[Byte]):
        self.body.extend(other)

    fn as_bytes(self) -> Span[Byte, __origin_of(self.body)]:
        return Span(self.body)

    fn as_string_slice(self) -> StringSlice[__origin_of(self.body)]:
        return StringSlice(unsafe_from_utf8=Span(self.body))

    fn as_dict(self) raises -> Dict[String, String]:
        """Converts the response body to a JSON object."""
        var parser = emberjson.Parser(StringSlice(unsafe_from_utf8=self.body))
        var json = parser.parse().object()
        return {x.key: String(x.data) for x in json.items()}

    fn write_to[W: Writer, //](self, mut writer: W):
        """Writes the body to a writer.

        Parameters:
            W: The type of the writer.

        Args:
            writer: The writer to which the body will be written.
        """
        writer.write(StringSlice(unsafe_from_utf8=self.body))

    fn consume(mut self) -> Bytes:
        """Consumes the body and returns it as Bytes."""
        var consumed_body = self.body^
        self.body = Bytes()
        return consumed_body^
