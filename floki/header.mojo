"""Helpers for constructing HTTP header values."""
from floki.auth import BasicAuth


def authorization_header(username: StringSlice, password: StringSlice) -> Dict[String, String]:
    """Generates a Basic Authorization header value for HTTP requests.

    Args:
        username: The username for authentication.
        password: The password for authentication.

    Returns:
        A dictionary entry representing the Basic Authorization header.
    """
    return {"Authorization": BasicAuth(String(username), String(password)).header_value()}
