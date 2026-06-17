from std import base64


def _encode_basic_credentials(username: StringSlice, password: StringSlice) -> String:
    """Generates a Basic Authorization header value for HTTP requests.

    Args:
        username: The username for authentication.
        password: The password for authentication.

    Returns:
        A string representing the Basic Authorization header value.
    """
    return base64.b64encode(String(t"{username}:{password}"))
    # # Combine username and password with a colon
    # var credentials = String(t"{username}:{password}")
    
    # # Return the formatted Authorization header
    # return String(t"Basic {base64.b64encode(credentials)}")

def authorization_header(username: StringSlice, password: StringSlice) -> Dict[String, String]:
    """Generates a Basic Authorization header value for HTTP requests.

    Args:
        username: The username for authentication.
        password: The password for authentication.

    Returns:
        A dictionary entry representing the Basic Authorization header.
    """
    return {"Authorization": String(t"Basic {_encode_basic_credentials(username, password)}")}
