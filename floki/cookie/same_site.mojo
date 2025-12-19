@fieldwise_init
@register_passable("trivial")
struct SameSite(Copyable, Stringable, Writable, Equatable):
    var value: UInt8

    comptime NONE = Self(0)
    comptime LAX = Self(1)
    comptime STRICT = Self(2)

    fn __init__(out self, text: StringSlice) raises:
        if text == "none":
            return SameSite.NONE
        elif text == "lax":
            return SameSite.LAX
        elif text == "strict":
            return SameSite.STRICT
        raise Error("Invalid SameSite value: ", text)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    
    fn write_to[W: Writer](self, mut writer: W):
        if self == Self.NONE:
            writer.write("none")
        elif self == Self.LAX:
            writer.write("lax")
        else:
            writer.write("strict")

    fn __str__(self) -> String:
        return String.write(self)
