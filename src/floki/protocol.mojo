@fieldwise_init
struct Protocol(Copyable, ExplicitlyCopyable, Movable, Writable):
    var value: String
    alias HTTP_11 = Self("HTTP/1.1")
    alias HTTP_10 = Self("HTTP/1.0")

    fn write_to[T: Writer, //](self, mut writer: T):
        writer.write(self.value)

    @staticmethod
    fn from_string(s: StringSlice) raises -> Self:
        if s == "HTTP/1.1":
            return Self.HTTP_11
        elif s == "HTTP/1.0":
            return Self.HTTP_10
        else:
            raise Error("Invalid protocol: ", s)
