from small_time import SmallTime, TimeZone
from small_time.small_time import parse_time_with_format


comptime HTTP_DATE_FORMAT = "ddd, DD MMM YYYY HH:mm:ss ZZZ"


@fieldwise_init
struct Expiration(Copyable, Equatable, Defaultable):
    var variant: UInt8
    var datetime: Optional[SmallTime]

    fn __init__(out self):
        self.variant = 0
        self.datetime = None

    fn __init__(out self, time: SmallTime):
        self.variant = 1
        self.datetime = time

    fn __init__(out self, text: StringSlice) raises:
        if text == "0":
            self.variant = 0
            self.datetime = None
        else:
            self = Self(time=parse_time_with_format(text, HTTP_DATE_FORMAT, TimeZone.UTC))

    @staticmethod
    fn invalidate() -> Self:
        return Self(variant=1, datetime=SmallTime(1970, 1, 1, 0, 0, 0, 0))

    fn is_session(self) -> Bool:
        return self.variant == 0

    fn is_datetime(self) -> Bool:
        return self.variant == 1

    fn http_date_timestamp(self) raises -> Optional[String]:
        if not self.datetime:
            return None

        # TODO fix this it breaks time and space (replacing timezone might add or remove something sometimes)
        var dt = self.datetime.value()
        # dt.time_zone = TimeZone.UTC
        return dt.format[HTTP_DATE_FORMAT]()

    fn __eq__(self, other: Self) -> Bool:
        if self.variant != other.variant:
            return False
        if self.variant == 1:
            if Bool(self.datetime) != Bool(other.datetime):
                return False
            elif not Bool(self.datetime) and not Bool(other.datetime):
                return True
            return self.datetime.value().isoformat() == other.datetime.value().isoformat()

        return True
