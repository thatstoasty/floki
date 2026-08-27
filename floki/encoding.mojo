"""URL percent-encoding and decoding helpers for `application/x-www-form-urlencoded` data."""

comptime _HEX: StaticString = "0123456789ABCDEF"

comptime _PERCENT = Byte(37)
"""The `%` byte, introducing a percent-escape."""
comptime _PLUS = Byte(43)
"""The `+` byte, used to encode a space."""
comptime _EQUALS = Byte(61)
"""The `=` byte, separating a form field's name from its value."""
comptime _AMPERSAND = Byte(38)
"""The `&` byte, separating one form field from the next."""
comptime _SPACE = Byte(32)
"""The space byte, which encodes as `+` rather than `%20`."""


@always_inline
def _is_unreserved(b: Byte) -> Bool:
    """Reports whether a byte may appear literally in encoded form data.

    Args:
        b: The byte to test.

    Returns:
        True if `b` is unreserved (letters, digits, `-`, `_`, `.`, `~`), False otherwise.
    """
    return (
        (b >= 65 and b <= 90)  # A-Z
        or (b >= 97 and b <= 122)  # a-z
        or (b >= 48 and b <= 57)  # 0-9
        or b == 45  # -
        or b == 95  # _
        or b == 46  # .
        or b == 126  # ~
    )


@always_inline
def _encoded_length(s: StringSpan) -> Int:
    """Computes the number of bytes `s` occupies once percent-encoded.

    Args:
        s: The string to measure.

    Returns:
        The encoded byte length.
    """
    var length = 0
    for b in s.as_bytes():
        length += 1 if (_is_unreserved(b) or b == _SPACE) else 3
    return length


@always_inline
def _percent_encode_into(s: StringSpan, mut out: List[Byte]):
    """Percent-encodes `s`, appending the encoded bytes to `out`.

    Unreserved characters (letters, digits, `-`, `_`, `.`, `~`) are left as-is, spaces
    are encoded as `+`, and everything else is escaped as `%XX`.

    Args:
        s: The string to encode.
        out: The buffer to append the encoded bytes to.
    """
    var hex = _HEX.as_bytes()
    for b in s.as_bytes():
        if _is_unreserved(b):
            out.append(b)
        elif b == _SPACE:
            out.append(_PLUS)
        else:
            out.append(_PERCENT)
            out.append(hex[Int(b) >> 4])
            out.append(hex[Int(b) & 0xF])


def _percent_encode(s: StringSpan) -> String:
    """Percent-encodes a string for use in `application/x-www-form-urlencoded` data.

    Unreserved characters (letters, digits, `-`, `_`, `.`, `~`) are left as-is, spaces
    are encoded as `+`, and everything else is escaped as `%XX`.

    Args:
        s: The string to encode.

    Returns:
        The percent-encoded string.
    """
    var buffer = List[Byte](capacity=_encoded_length(s))
    _percent_encode_into(s, buffer)
    # Percent-encoding only ever emits ASCII, so the buffer is valid UTF-8 by construction.
    return String(unsafe_from_utf8=Span(buffer))


def urlencode(data: Dict[String, String]) -> String:
    """Encodes a dictionary as `application/x-www-form-urlencoded` data.

    Args:
        data: The form fields to encode.

    Returns:
        The encoded form body, e.g. `key1=value1&key2=value2`.
    """
    var field_count = len(data)
    if field_count == 0:
        return String()

    # Size the buffer exactly so the encode pass below never reallocates: one `=`
    # per field, one `&` between fields, plus each encoded key and value.
    var capacity = 2 * field_count - 1
    for entry in data.items():
        capacity += _encoded_length(entry.key) + _encoded_length(entry.value)

    var buffer = List[Byte](capacity=capacity)
    for i, entry in enumerate(data.items()):
        if i != 0:
            buffer.append(_AMPERSAND)
        _percent_encode_into(entry.key, buffer)
        buffer.append(_EQUALS)
        _percent_encode_into(entry.value, buffer)

    # Percent-encoding only ever emits ASCII, so the buffer is valid UTF-8 by construction.
    return String(unsafe_from_utf8=Span(buffer))
