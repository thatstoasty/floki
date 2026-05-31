from std.collections.string._utf8 import _is_valid_utf8

import emberjson


struct Body(Copyable, Sized, Writable, Equatable):
    """Represents the body of an HTTP request or response.

    At the moment, this only supports JSON serialization and deserialization.
    """

    var body: List[Byte]
    """The raw body content as a list of bytes."""

    def __init__(out self, var body: List[Byte]):
        """Constructs a Body instance from a list of bytes.

        Args:
            body: The body content as a list of bytes.
        """
        self.body = body^

    def __init__[origin: ImmutOrigin, //](out self, body: Span[Byte, origin]):
        """Alternate constructor that accepts a Span[Byte] for the body content.

        Parameters:
            origin: The origin of the data span.

        Args:
            body: The body content as a span of bytes.
        """
        self.body = List[Byte](body)

    def __len__(self) -> Int:
        """Returns the length of the body in bytes.

        Returns:
            The number of bytes in the body.
        """
        return len(self.body)

    def as_bytes(self) -> Span[Byte, origin_of(self.body)]:
        """Returns a view of the body content as a span of bytes.

        Returns:
            A `Span[Byte]` referencing the body's underlying data.
        """
        return Span(self.body)

    def as_text(self) raises -> StringSlice[origin_of(self.body)]:
        """Creates and returns a `StringSlice` view of the body content.

        Returns:
            The body content as a string slice.
        """
        return StringSlice(from_utf8=Span(self.body))
    
    def as_json[T: Movable & ImplicitlyDestructible & Defaultable](mut self, out result: T) raises:
        """Converts the response body to a JSON object.
        
        Returns:
            The body content parsed as a JSON value.
        
        Raises:
            Error: if the body is empty or cannot be parsed as JSON.
        """
        return emberjson.deserialize[T](emberjson.Parser(self.as_text()))

    def write_to(self, mut writer: Some[Writer]) raises:
        """Writes the body to a writer.

        Args:
            writer: The writer to which the body will be written.
        """
        writer.write(self.as_text())

    def take_bytes(deinit self) -> List[Byte]:
        """Consumes the body and returns it as List[Byte].
        
        Returns:
            The body content as a list of bytes.
        """
        return self.body^
