@fieldwise_init
@register_passable("trivial")
struct Duration(Copyable, ImplicitlyCopyable, Movable):
    var total_seconds: Int

    fn __init__(out self, seconds: Int = 0, minutes: Int = 0, hours: Int = 0, days: Int = 0):
        self.total_seconds = seconds
        self.total_seconds += minutes * 60
        self.total_seconds += hours * 60 * 60
        self.total_seconds += days * 24 * 60 * 60

    fn __init__(out self, text: StringSlice) raises:
        return Self(seconds=Int(text))
