struct Timeout(Copyable, Movable):
    """Granular timeout configuration for a request, expressed in seconds.

    Each field limits a different phase of the request lifecycle. A field set to
    `None` leaves that timeout unset, imposing no limit.

    A bare number can be passed wherever a `Timeout` is expected; it is treated
    as the total request timeout in seconds (e.g. `timeout=30`).
    """
    var connect: Optional[Float64]
    """Maximum time (seconds) allowed for the connection phase, or `None` for no limit."""
    var total: Optional[Float64]
    """Maximum time (seconds) allowed for the entire request, or `None` for no limit."""

    def __init__(out self, *, connect: Optional[Float64] = None, total: Optional[Float64] = None):
        """Constructs a `Timeout` from individual phase limits.

        Args:
            connect: Maximum time (seconds) for the connection phase, or `None`.
            total: Maximum time (seconds) for the entire request, or `None`.
        """
        self.connect = connect
        self.total = total

    @implicit
    def __init__(out self, total: Float64):
        """Constructs a `Timeout` limiting only the total request duration.

        Args:
            total: The maximum total request duration, in seconds.
        """
        self.connect = None
        self.total = total

    @implicit
    def __init__(out self, total: Int):
        """Constructs a `Timeout` limiting only the total request duration.

        Args:
            total: The maximum total request duration, in seconds.
        """
        self.connect = None
        self.total = Float64(total)
