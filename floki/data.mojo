from std.utils import Variant


@fieldwise_init
struct RequestData[origin: ImmutOrigin]:
    """Data variant to represent either a FileHandle or a Span of bytes for request bodies.

    Parameters:
        origin: The origin of the data span.
    """

    var data: Variant[Pointer[FileHandle, Self.origin], Span[Byte, Self.origin]]
    """The `data` field can hold either a pointer to a `FileHandle` or a span of bytes, allowing for flexible handling of request bodies in different formats."""

    @implicit
    def __init__(
        out self,
        data: Pointer[FileHandle, Self.origin],
    ):
        """Initializes a `RequestData` instance with the provided data.

        Args:
            data: A pointer to a `FileHandle`, representing the request body.
        """
        self.data = data

    @implicit
    def __init__(
        out self,
        data: Span[Byte, Self.origin],
    ):
        """Initializes a `RequestData` instance with the provided data.

        Args:
            data: A span of bytes, representing the request body.
        """
        self.data = data

    def isa[T: AnyType](self) -> Bool:
        """Checks if the contained data is of the specified type.

        Parameters:
            T: The type to check against.

        Returns:
            True if the contained data is of type T, False otherwise.
        """
        return self.data.isa[T]()

    def __getitem_param__[T: AnyType](ref self) -> ref[self.data] T:
        """Retrieves the contained data as the specified type.

        Parameters:
            T: The type to retrieve.

        Returns:
            The contained data cast to type T.
        """
        return self.data[T]
