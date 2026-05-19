from mojo_datetime import DateTime, TimeZone, TimeDelta, SITimeUnit, TZ_UTC
from floki._time import from_utc_timestamp


comptime HTTP_DATE_FORMAT = "ddd, DD MMM YYYY HH:mm:ss ZZZ"
"""The date format used for the `Expires` attribute of cookies, following the HTTP-date format specified in RFC 7231."""


@fieldwise_init
struct Expiration(Copyable, Defaultable, Equatable):
    """Represents the expiration setting for a cookie, which can be either session-scoped (no explicit expiry) or a specific datetime. Provides methods for constructing, comparing, and formatting expiration values.
    """

    var variant: UInt8
    """An internal variant discriminator to determine if this is a session expiration (variant 0) or a datetime expiration (variant 1)."""
    var datetime: Optional[DateTime[TZ_UTC]]
    """The specific expiration datetime if variant is 1, or None if this is a session expiration (variant 0)."""

    def __init__(out self):
        """Constructs a session-scoped Expiration (no explicit expiry)."""
        self.variant = 0
        self.datetime = None

    def __init__(out self, time: DateTime[TZ_UTC]):
        """Constructs an Expiration with a specific datetime.

        Args:
            time: The expiration datetime.
        """
        self.variant = 1
        self.datetime = time

    def __init__(out self, text: StringSlice) raises:
        """Constructs an Expiration by parsing an HTTP date string.

        Args:
            text: The string representation of the expiration date, or "0" for session-scoped.

        Raises:
            Error: If the string cannot be parsed as a valid date.
        """
        if text == "0":
            self.variant = 0
            self.datetime = None
        else:
            self = Self(time=DateTime.parse[fmt_str=HTTP_DATE_FORMAT](text))

    @staticmethod
    def from_libcurl_expires(text: StringSlice) raises -> Self:
        """Constructs an Expiration from libcurl's cookie-list expires field.

        Args:
            text: The libcurl cookie-list expiration value, either "0" for a session cookie or a Unix
                timestamp in seconds.

        Returns:
            An Expiration parsed from the libcurl expires value.

        Raises:
            Error: If the timestamp cannot be parsed into a valid date.
        """
        var expires_timestamp = atol(text)
        if expires_timestamp == 0:
            return Self()
        return Self(from_utc_timestamp(expires_timestamp))
        # return Self(DateTime.from_unix_epoch(TimeDelta(expires_timestamp)))

    @staticmethod
    def invalidate() -> Self:
        """Creates an Expiration set to the Unix epoch, effectively invalidating the cookie.

        Returns:
            An Expiration representing January 1, 1970.
        """
        return Self(variant=1, datetime=DateTime(1970, 1, 1, 0, 0, 0, 0))

    def is_session(self) -> Bool:
        """Checks if this is a session-scoped expiration (no explicit expiry).

        Returns:
            True if the expiration is session-scoped.
        """
        return self.variant == 0

    def is_datetime(self) -> Bool:
        """Checks if this expiration has an explicit datetime.

        Returns:
            True if the expiration is set to a specific datetime.
        """
        return self.variant == 1

    def http_date_timestamp(self) raises -> Optional[String]:
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
        var result = String()
        return dt.write_to[HTTP_DATE_FORMAT](result)

    def __eq__(self, other: Self) -> Bool:
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
            return self.datetime.value() == other.datetime.value()

        return True
