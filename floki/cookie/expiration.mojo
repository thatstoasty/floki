from small_time import SmallTime, TimeZone
from small_time.small_time import parse_time_with_format


comptime HTTP_DATE_FORMAT = "ddd, DD MMM YYYY HH:mm:ss ZZZ"
"""The date format used for the `Expires` attribute of cookies, following the HTTP-date format specified in RFC 7231."""


@fieldwise_init
struct Expiration(Copyable, Equatable, Defaultable):
    """Represents the expiration setting for a cookie, which can be either session-scoped (no explicit expiry) or a specific datetime. Provides methods for constructing, comparing, and formatting expiration values."""
    var variant: UInt8
    """An internal variant discriminator to determine if this is a session expiration (variant 0) or a datetime expiration (variant 1)."""
    var datetime: Optional[SmallTime]
    """The specific expiration datetime if variant is 1, or None if this is a session expiration (variant 0)."""

    fn __init__(out self):
        """Constructs a session-scoped Expiration (no explicit expiry)."""
        self.variant = 0
        self.datetime = None

    fn __init__(out self, time: SmallTime):
        """Constructs an Expiration with a specific datetime.

        Args:
            time: The expiration datetime.
        """
        self.variant = 1
        self.datetime = time

    fn __init__(out self, text: StringSlice) raises:
        """Constructs an Expiration by parsing a date string.

        Args:
            text: The string representation of the expiration date, or "0" for session-scoped.

        Raises:
            Error: If the string cannot be parsed as a valid date.
        """
        if text == "0":
            self.variant = 0
            self.datetime = None
        else:
            self = Self(time=parse_time_with_format(text, HTTP_DATE_FORMAT, TimeZone.UTC))

    @staticmethod
    fn invalidate() -> Self:
        """Creates an Expiration set to the Unix epoch, effectively invalidating the cookie.

        Returns:
            An Expiration representing January 1, 1970.
        """
        return Self(variant=1, datetime=SmallTime(1970, 1, 1, 0, 0, 0, 0))

    fn is_session(self) -> Bool:
        """Checks if this is a session-scoped expiration (no explicit expiry).

        Returns:
            True if the expiration is session-scoped.
        """
        return self.variant == 0

    fn is_datetime(self) -> Bool:
        """Checks if this expiration has an explicit datetime.

        Returns:
            True if the expiration is set to a specific datetime.
        """
        return self.variant == 1

    fn http_date_timestamp(self) raises -> Optional[String]:
        """Formats the expiration datetime as an HTTP date string.

        Returns:
            The formatted date string, or None if no datetime is set.
        
        Raises:
            Error: If the datetime is not valid.
        """
        if not self.datetime:
            return None

        # TODO fix this it breaks time and space (replacing timezone might add or remove something sometimes)
        var dt = self.datetime.value()
        # dt.time_zone = TimeZone.UTC
        return dt.format[HTTP_DATE_FORMAT]()

    fn __eq__(self, other: Self) -> Bool:
        """Compares two Expiration instances for equality.

        Args:
            other: The Expiration to compare with.

        Returns:
            True if both instances represent the same expiration.
        """
        if self.variant != other.variant:
            return False
        if self.variant == 1:
            if Bool(self.datetime) != Bool(other.datetime):
                return False
            elif not Bool(self.datetime) and not Bool(other.datetime):
                return True
            return self.datetime.value().isoformat() == other.datetime.value().isoformat()

        return True
