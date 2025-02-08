from memory import UnsafePointer
from memory.span import _SpanIter


alias Bytes = List[Byte, True]
alias DEFAULT_BUFFER_SIZE = 4096

alias CRLF = "\r\n"
alias WHITESPACE = " "


struct BytesConstant:
    alias WHITESPACE = Byte(ord(WHITESPACE))
    alias COLON = Byte(ord(":"))
    alias CR = Byte(ord("\r"))
    alias LF = Byte(ord("\n"))
    alias CRLF = CRLF.as_bytes()
    alias DOUBLE_CRLF = "\r\n\r\n".as_bytes()


fn bytes_equal(lhs: Span[Byte], rhs: Span[Byte]) -> Bool:
    """Checks if two byte spans are equal.

    Args:
        lhs: The first byte span to compare.
        rhs: The second byte span to compare.

    Returns:
        True if the byte spans are equal, False otherwise.
    """
    if len(lhs) != len(rhs):
        return False
    for i in range(len(lhs)):
        if lhs[i] != rhs[i]:
            return False
    return True


@always_inline
fn is_newline(b: Byte) -> Bool:
    return b == BytesConstant.LF or b == BytesConstant.CR


@always_inline
fn is_space(b: Byte) -> Bool:
    return b == BytesConstant.WHITESPACE


struct ByteWriter(Writer):
    var _inner: Bytes

    fn __init__(out self, capacity: UInt = DEFAULT_BUFFER_SIZE):
        self._inner = Bytes(capacity=capacity)

    @always_inline
    fn write_bytes(mut self, bytes: Span[Byte]) -> None:
        """Writes the contents of `bytes` into the internal buffer.

        Args:
            bytes: The bytes to write.
        """
        self._inner.extend(bytes)

    fn write[*Ts: Writable](mut self, *args: *Ts) -> None:
        """Write data to the `Writer`.

        Parameters:
            Ts: The types of data to write.

        Args:
            args: The data to write.
        """

        @parameter
        for i in range(args.__len__()):
            args[i].write_to(self)

    @always_inline
    fn consuming_write(mut self, owned b: Bytes):
        self._inner.extend(b^)

    @always_inline
    fn write_byte(mut self, b: Byte):
        self._inner.append(b)

    fn consume(mut self) -> Bytes:
        var ret = self._inner^
        self._inner = Bytes()
        return ret^


alias EndOfReaderError = "No more bytes to read."
alias OutOfBoundsError = "Tried to read past the end of the ByteReader."


struct ByteReader[origin: Origin](Sized):
    var _inner: Span[Byte, origin]
    var read_pos: Int

    fn __init__(out self, b: Span[Byte, origin]):
        self._inner = b
        self.read_pos = 0

    fn copy(self) -> Self:
        return ByteReader(self._inner[self.read_pos :])

    fn __contains__(self, b: Byte) -> Bool:
        for i in range(self.read_pos, len(self._inner)):
            if self._inner[i] == b:
                return True
        return False

    @always_inline
    fn available(self) -> Bool:
        return self.read_pos < len(self._inner)

    fn __len__(self) -> Int:
        return len(self._inner) - self.read_pos

    fn peek(self) raises -> ref [origin] Byte:
        if not self.available():
            raise EndOfReaderError
        return self._inner[self.read_pos]

    fn read_bytes(mut self, n: Int = -1) raises -> Span[Byte, origin]:
        var count = n
        var start = self.read_pos
        if n == -1:
            count = len(self)

        if start + count > len(self._inner):
            raise OutOfBoundsError

        self.read_pos += count
        return self._inner[start : start + count]

    fn read_until(mut self, char: Byte) -> Span[Byte, origin]:
        var start = self.read_pos
        for i in range(start, len(self._inner)):
            if self._inner[i] == char:
                break
            self.increment()

        return self._inner[start : self.read_pos]

    @always_inline
    fn read_word(mut self) -> Span[Byte, origin]:
        return self.read_until(BytesConstant.WHITESPACE)

    fn read_line(mut self) -> Span[Byte, origin]:
        var start = self.read_pos
        for i in range(start, len(self._inner)):
            if is_newline(self._inner[i]):
                break
            self.increment()

        # If we are at the end of the buffer, there is no newline to check for.
        var ret = self._inner[start : self.read_pos]
        if not self.available():
            return ret

        if self._inner[self.read_pos] == BytesConstant.CR:
            self.increment(2)
        else:
            self.increment()
        return ret

    fn skip_whitespace(mut self):
        for i in range(self.read_pos, len(self._inner)):
            if is_space(self._inner[i]):
                self.increment()
            else:
                break

    fn skip_carriage_return(mut self):
        for i in range(self.read_pos, len(self._inner)):
            if self._inner[i] == BytesConstant.CR:
                self.increment(2)
            else:
                break

    @always_inline
    fn increment(mut self, v: Int = 1):
        self.read_pos += v
