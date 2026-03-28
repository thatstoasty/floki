@fieldwise_init
struct Duration(ImplicitlyCopyable, TrivialRegisterPassable):
    """Represents a duration of time, stored internally as total seconds."""
    var total_seconds: Int
    """The total duration in seconds."""

    fn __init__(out self, seconds: Int = 0, minutes: Int = 0, hours: Int = 0, days: Int = 0):
        """Constructs a Duration from time components.

        Args:
            seconds: Number of seconds.
            minutes: Number of minutes.
            hours: Number of hours.
            days: Number of days.
        """
        self.total_seconds = seconds
        self.total_seconds += minutes * 60
        self.total_seconds += hours * 60 * 60
        self.total_seconds += days * 24 * 60 * 60

    fn __init__(out self, text: StringSlice) raises:
        """Constructs a Duration by parsing a string as a number of seconds.

        Args:
            text: The string representation of the duration in seconds.

        Raises:
            Error: If the string cannot be parsed as an integer.
        """
        return Self(seconds=Int(text))
