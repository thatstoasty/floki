comptime _HEX: StaticString = "0123456789ABCDEF"


def _percent_encode(s: StringSlice) -> String:
    """Percent-encodes a string for use in `application/x-www-form-urlencoded` data.

    Unreserved characters (letters, digits, `-`, `_`, `.`, `~`) are left as-is, spaces
    are encoded as `+`, and everything else is escaped as `%XX`.

    Args:
        s: The string to encode.

    Returns:
        The percent-encoded string.
    """
    var result = String()
    for b in s.as_bytes():
        if (
            (b >= 65 and b <= 90)  # A-Z
            or (b >= 97 and b <= 122)  # a-z
            or (b >= 48 and b <= 57)  # 0-9
            or b == 45  # -
            or b == 95  # _
            or b == 46  # .
            or b == 126  # ~
        ):
            result += chr(Int(b))
        elif b == 32:  # space
            result += "+"
        else:
            result += "%"
            result += String(_HEX[byte=Int(b) >> 4])
            result += String(_HEX[byte=Int(b) & 0xF])
    return result


def urlencode(data: Dict[String, String]) -> String:
    """Encodes a dictionary as `application/x-www-form-urlencoded` data.

    Args:
        data: The form fields to encode.

    Returns:
        The encoded form body, e.g. `key1=value1&key2=value2`.
    """
    var result = String()
    var data_length = len(data)
    for i, pair in enumerate(data.items()):
        result.write(t"{_percent_encode(pair.key)}={_percent_encode(pair.value)}")
        if i != data_length:
            result.write("&")
    return result^
