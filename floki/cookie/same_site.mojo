@fieldwise_init
struct SameSite(Copyable, Writable, Equatable, TrivialRegisterPassable):
    """Represents the SameSite attribute of an HTTP cookie, which controls when cookies are sent with cross-site requests."""
    var value: UInt8
    """Internal enum value."""

    comptime NONE = Self(0)
    """The cookie will be sent in all contexts, i.e. in responses to both first-party and cross-origin requests. If SameSite=None is used, the cookie Secure attribute must also be set (i.e. the cookie is only sent over secure connections)."""
    comptime LAX = Self(1)
    """The cookie is not sent on normal cross-site subrequests (for example to load images or frames into a third party site), but is sent when a user is navigating to the origin site (i.e. when following a link). This is the default value when SameSite isn't specified."""
    comptime STRICT = Self(2)
    """The cookie is only sent in a first-party context and not with requests initiated by third party websites."""

    fn __init__(out self, text: StringSlice) raises:
        """Constructs a SameSite from its string representation.

        Args:
            text: The string value ("none", "lax", or "strict").

        Raises:
            Error: If the string does not match a known SameSite value.
        """
        if text == "none":
            return SameSite.NONE
        elif text == "lax":
            return SameSite.LAX
        elif text == "strict":
            return SameSite.STRICT
        raise Error("Invalid SameSite value: ", text)

    fn __eq__(self, other: Self) -> Bool:
        """Compares two SameSite instances for equality.

        Args:
            other: The SameSite instance to compare with.

        Returns:
            True if both instances represent the same SameSite policy.
        """
        return self.value == other.value
    
    fn write_to(self, mut writer: Some[Writer]):
        """Writes the SameSite policy name to a writer.

        Args:
            writer: The writer to which the policy name will be written.
        """
        if self == Self.NONE:
            writer.write("none")
        elif self == Self.LAX:
            writer.write("lax")
        else:
            writer.write("strict")
