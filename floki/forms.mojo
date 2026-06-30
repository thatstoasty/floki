from floki.encoding import urlencode


@fieldwise_init
struct FormData(Movable):
    """Represents `application/x-www-form-urlencoded` form data for a request body.

    Wrapping a `Dict[String, String]` in `FormData` (rather than accepting a bare
    dictionary) keeps it unambiguous from the JSON `data={...}` overloads, which take
    an `emberjson.Object`.
    """

    var fields: Dict[String, String]
    """The form fields to encode into the request body."""

    def encode(self) -> String:
        """Encodes the form fields as `application/x-www-form-urlencoded` data.

        Returns:
            The encoded form body, e.g. `key1=value1&key2=value2`.
        """
        return urlencode(self.fields)
