"""The `Headers` type: a case-insensitive collection of HTTP headers."""


struct Headers(Boolable, Copyable, Defaultable, Movable, Sized, Writable):
    """A case-insensitive collection of HTTP headers.

    HTTP header names are case-insensitive, so `Headers` normalizes every key to
    lowercase whenever a value is inserted, looked up, or tested for membership.
    As a result `headers["Content-Type"]`, `headers["content-type"]`, and
    `headers["CONTENT-TYPE"]` all refer to the same entry.

    A `Dict[String, String]` converts implicitly to `Headers`, so request helpers
    that accept `Headers` can still be called with a dictionary literal, e.g.
    `floki.get(url, headers={"Accept": "application/json"})`.
    """

    var _inner: Dict[String, String]
    """The underlying storage, mapping normalized (lowercased) names to values."""

    def __init__(out self):
        """Constructs an empty `Headers` collection."""
        self._inner = Dict[String, String]()

    @implicit
    def __init__(out self, var headers: Dict[String, String]):
        """Constructs a `Headers` collection from a dictionary, normalizing its keys.

        Args:
            headers: Header names and values. Keys are normalized to lowercase.
        """
        self._inner = Dict[String, String]()
        for entry in headers.items():
            self._inner[Self._normalize(entry.key)] = entry.value

    def __init__(out self, var keys: List[String], var values: List[String], __dict_literal__: NoneType):
        """Constructs a `Headers` collection from a dictionary literal, normalizing its keys.

        This enables dictionary-literal syntax wherever a `Headers` is expected,
        e.g. `floki.get(url, headers={"Accept": "application/json"})`.

        Args:
            keys: The header names from the literal.
            values: The header values from the literal, paired with `keys`.
            __dict_literal__: Internal marker enabling dictionary-literal syntax.
        """
        self._inner = Dict[String, String]()
        for pair in zip(keys, values):
            self._inner[Self._normalize(pair[0])] = pair[1]

    @staticmethod
    def _normalize(key: StringSlice) -> String:
        """Normalizes a header name to its canonical (lowercased) form.

        Args:
            key: The header name to normalize.

        Returns:
            The lowercased header name.
        """
        return key.lower()

    def __getitem__(ref self, key: StringSlice) raises -> ref[self._inner] String:
        """Looks up a header value by name, case-insensitively.

        Args:
            key: The header name to look up.

        Returns:
            A reference to the stored header value.

        Raises:
            KeyError: If no header with the given name is present.
        """
        return self._inner[Self._normalize(key)]

    def __setitem__(mut self, key: StringSlice, var value: String):
        """Sets a header value by name, normalizing the name first.

        Args:
            key: The header name to set.
            value: The header value to store.
        """
        self._inner[Self._normalize(key)] = value^

    def __contains__(self, key: StringSlice) -> Bool:
        """Reports whether a header with the given name is present, case-insensitively.

        Args:
            key: The header name to look for.

        Returns:
            True if a header with the normalized name exists, False otherwise.
        """
        return Self._normalize(key) in self._inner

    def get(self, key: StringSlice, var default: String = "") -> String:
        """Looks up a header value by name, returning `default` if it is absent.

        Args:
            key: The header name to look up.
            default: The value to return when the header is not present.

        Returns:
            The header value, or `default` if the header is not present.
        """
        return self._inner.get(Self._normalize(key), default)

    def update(mut self, var other: Self):
        """Merges another `Headers` collection into this one, overwriting on conflicts.

        Args:
            other: The headers to merge in. Its keys are already normalized.
        """
        self._inner.update(other._inner^)

    def __len__(self) -> Int:
        """Returns the number of headers in the collection.

        Returns:
            The header count.
        """
        return len(self._inner)

    def __bool__(self) -> Bool:
        """Reports whether the collection contains any headers.

        Returns:
            True if at least one header is present, False otherwise.
        """
        return Bool(self._inner)

    def write_to(self, mut writer: Some[Writer]):
        """Writes the headers in `name: value` form, one per line separated by CRLF.

        Args:
            writer: The writer to which the headers will be written.
        """
        for entry in self._inner.items():
            writer.write(entry.key, ": ", entry.value, "\r\n")
