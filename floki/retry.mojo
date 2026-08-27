"""The `Retry` type used to configure retry behavior for requests made by a `Session`."""


struct Retry(Copyable, Equatable, Writable):
    """A retry policy with exponential backoff for failed requests.

    A request is retried when the underlying transfer fails (e.g. a connection
    error or timeout) or when the response status code appears in
    `status_forcelist`. Between attempts, floki sleeps for an exponentially
    increasing delay derived from `backoff_factor`.

    A default-constructed `Retry()` performs no retries.
    """

    var max_retries: Int
    """Maximum number of retries to attempt after the initial request. `0` disables retries."""
    var backoff_factor: Float64
    """Base delay (seconds) used to compute the exponential backoff between retries."""
    var status_forcelist: List[Int]
    """Response status codes that should trigger a retry."""

    def __init__(
        out self,
        max_retries: Int = 0,
        backoff_factor: Float64 = 0.0,
        status_forcelist: List[Int] = [408, 429, 500, 502, 503, 504],
    ):
        """Constructs a `Retry` policy.

        A default-constructed `Retry()` performs no retries, since `max_retries`
        defaults to `0`. The `status_forcelist` is inert until `max_retries > 0`.

        Args:
            max_retries: Maximum number of retries after the initial request. `0` disables retries.
            backoff_factor: Base delay (seconds) used to compute the exponential backoff between retries.
            status_forcelist: Response status codes that should trigger a retry.
        """
        self.max_retries = max_retries
        self.backoff_factor = backoff_factor
        self.status_forcelist = status_forcelist.copy()

    def backoff_time(self, attempt: Int) -> Float64:
        """Computes the backoff delay before a given retry attempt.

        Uses exponential backoff: `backoff_factor * 2 ** (attempt - 1)`.

        Args:
            attempt: The 1-based retry attempt number.

        Returns:
            The number of seconds to wait before performing the attempt.
        """
        return self.backoff_factor * (2.0 ** Float64(attempt - 1))

    def should_retry(self, status_code: Int) -> Bool:
        """Reports whether a response with the given status code should be retried.

        Args:
            status_code: The HTTP status code returned by the server.

        Returns:
            True if `status_code` is in `status_forcelist`, False otherwise.
        """
        return status_code in self.status_forcelist
