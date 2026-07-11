"""Module-level convenience functions for sending requests without a `Session`."""
import emberjson
from floki.auth import Auth, NoAuth
from floki.body import Body
from floki.forms import FormData
from floki.headers import Headers
from floki.http import RequestMethod
from floki.proxy import Proxy
from floki.response import Response
from floki.retry import Retry
from floki.session import RequestData, Session
from floki.timeout import Timeout
from floki.tls import TLS


def get[
    A: Auth = NoAuth, //
](
    var url: String,
    var headers: Headers = Headers(),
    query_parameters: Dict[String, String] = {},
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    auth: Optional[A] = None,
) raises -> Response:
    """Sends a GET request to the specified URL.

    Parameters:
        A: The concrete `Auth` scheme type, inferred from `auth`.

    Args:
        url: The URL to which the request is sent.
        headers: HTTP headers to include in the request.
        query_parameters: Query parameters to include in the request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        auth: An optional authentication scheme to apply to the request.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the request fails.

    #### Examples:
    ```mojo
    import floki
    from floki.auth import BasicAuth

    def main() raises:
        var r = floki.get("https://httpbin.org/get", auth=BasicAuth("user", "pass"))
    ```
    """
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.GET](
        url=url,
        headers=headers,
        query_parameters=query_parameters,
        data=RequestData(List[Byte]()),
        auth=auth,
    )


def post[
    A: Auth = NoAuth, //
](
    var url: String,
    var headers: Headers = Headers(),
    var data: emberjson.Object = {},
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    query_parameters: Dict[String, String] = {},
    auth: Optional[A] = None,
) raises -> Response:
    """Sends a POST request to the specified URL.

    Parameters:
        A: The concrete `Auth` scheme type, inferred from `auth`.

    Args:
        url: The URL to which the request is sent.
        headers: HTTP headers to include in the request.
        data: The data to include in the body of the POST request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        query_parameters: Query parameters to include in the request URL.
        auth: An optional authentication scheme to apply to the request.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the data cannot be serialized to JSON or if the request fails.

    #### Examples:
    ```mojo
    import floki

    def main() raises:
        var r = floki.post("https://httpbin.org/post", data={"key": "value"})
    ```
    """
    var json_data = emberjson.to_string(data^).as_bytes()
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.POST](
        url=url,
        headers=headers,
        query_parameters=query_parameters,
        data=json_data,
        auth=auth,
    )


def post[
    A: Auth = NoAuth, //
](
    var url: String,
    data: FormData,
    var headers: Headers = Headers(),
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    query_parameters: Dict[String, String] = {},
    auth: Optional[A] = None,
) raises -> Response:
    """Sends a POST request with `application/x-www-form-urlencoded` data to the specified URL.

    Parameters:
        A: The concrete `Auth` scheme type, inferred from `auth`.

    Args:
        url: The URL to which the request is sent.
        data: The form fields to include in the body of the POST request.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        query_parameters: Query parameters to include in the request URL.
        auth: An optional authentication scheme to apply to the request.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the request fails.

    #### Examples:
    ```mojo
    import floki
    from floki.forms import FormData

    def main() raises:
        var r = floki.post("https://httpbin.org/post", data=FormData({"key": "value"}))
    ```
    """
    if "Content-Type" not in headers:
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    var encoded = data.encode()
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.POST](
        url=url,
        headers=headers,
        query_parameters=query_parameters,
        data=RequestData(encoded.as_bytes()),
        auth=auth,
    )


def post[
    T: AnyType & ImplicitlyDestructible & Defaultable, //
](
    var url: String,
    data: T,
    var headers: Headers = Headers(),
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    query_parameters: Dict[String, String] = {},
) raises -> Response:
    """Sends a POST request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        data: The data to include in the body of the POST request.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        query_parameters: Query parameters to include in the request URL.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the data cannot be serialized to JSON or if the request fails.

    #### Examples:
    ```mojo
    from floki.session import Session

    @fieldwise_init
    struct Point(ImplicitlyDestructible):
        var x: Int
        var y: Int

    def main() raises:
        var session = Session()
        var r = session.post("https://httpbin.org/post", data=Point(0, 1))
    ```
    """
    var json_data = emberjson.serialize(data)
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.POST](
        url=url,
        headers=headers,
        query_parameters=query_parameters,
        data=json_data.as_bytes(),
    )


def post[
    origin: ImmutOrigin, //
](
    var url: String,
    data: Span[Byte, origin],
    var headers: Headers = Headers(),
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    query_parameters: Dict[String, String] = {},
) raises -> Response:
    """Sends a POST request to the specified URL.

    Parameters:
        origin: The origin of the data span.

    Args:
        url: The URL to which the request is sent.
        data: The data to include in the body of the POST request.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        query_parameters: Query parameters to include in the request URL.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the data cannot be sent as bytes.

    #### Examples:
    ```mojo
    import floki

    def main() raises:
        var r = floki.post("https://httpbin.org/post", data="hello".as_bytes())
    ```
    """
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.POST](
        url=url,
        headers=headers,
        query_parameters=query_parameters,
        data=data,
    )


def post(
    var url: String,
    data: FileHandle,
    var headers: Headers = Headers(),
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    query_parameters: Dict[String, String] = {},
) raises -> Response:
    """Sends a POST request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        data: The data to include in the body of the POST request.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        query_parameters: Query parameters to include in the request URL.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the data cannot be sent from the file handle.

    #### Examples:
    ```mojo
    import floki

    def main() raises:
        with open("data.json", "r") as file:
            var r = floki.post("https://httpbin.org/post", data=file)
    ```
    """
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.POST](
        url=url,
        headers=headers,
        query_parameters=query_parameters,
        data=Pointer(to=data),
    )


def put[
    A: Auth = NoAuth, //
](
    var url: String,
    var headers: Headers = Headers(),
    var data: emberjson.Object = {},
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    query_parameters: Dict[String, String] = {},
    auth: Optional[A] = None,
) raises -> Response:
    """Sends a PUT request to the specified URL.

    Parameters:
        A: The concrete `Auth` scheme type, inferred from `auth`.

    Args:
        url: The URL to which the request is sent.
        headers: HTTP headers to include in the request.
        data: The data to include in the body of the PUT request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        query_parameters: Query parameters to include in the request URL.
        auth: An optional authentication scheme to apply to the request.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the data cannot be serialized to JSON or if the request fails.

    #### Examples:
    ```mojo
    import floki

    def main() raises:
        var r = floki.put("https://httpbin.org/put", data={"key": "value"})
    ```
    """
    var json_data = emberjson.to_string(data^).as_bytes()
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.PUT](
        url=url,
        headers=headers,
        query_parameters=query_parameters,
        data=json_data,
        auth=auth,
    )


def put[
    T: AnyType & ImplicitlyDestructible, //
](
    var url: String,
    data: T,
    var headers: Headers = Headers(),
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    query_parameters: Dict[String, String] = {},
) raises -> Response:
    """Sends a PUT request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        data: The data to include in the body of the PUT request.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        query_parameters: Query parameters to include in the request URL.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the data cannot be serialized to JSON or if the request fails.

    #### Examples:
    ```mojo
    from floki.session import Session

    @fieldwise_init
    struct Point:
        var x: Int
        var y: Int

    def main() raises:
        var session = Session()
        var r = session.put("https://httpbin.org/put", data=Point(0, 1))
    ```
    """
    var json_data = emberjson.serialize(data)
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.PUT](
        url=url,
        headers=headers,
        query_parameters=query_parameters,
        data=json_data.as_bytes(),
    )


def put[
    origin: ImmutOrigin, //
](
    var url: String,
    data: Span[Byte, origin],
    var headers: Headers = Headers(),
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    query_parameters: Dict[String, String] = {},
) raises -> Response:
    """Sends a PUT request to the specified URL.

    Parameters:
        origin: The origin of the data span.

    Args:
        url: The URL to which the request is sent.
        data: The data to include in the body of the PUT request.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        query_parameters: Query parameters to include in the request URL.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the data cannot be sent as bytes.

    #### Examples:
    ```mojo
    import floki

    def main() raises:
        var r = floki.put("https://httpbin.org/put", data="hello".as_bytes())
    ```
    """
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.PUT](
        url=url,
        headers=headers,
        query_parameters=query_parameters,
        data=data,
    )


def put(
    var url: String,
    data: FileHandle,
    var headers: Headers = Headers(),
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    query_parameters: Dict[String, String] = {},
) raises -> Response:
    """Sends a PUT request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        data: The data to include in the body of the PUT request.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        query_parameters: Query parameters to include in the request URL.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the data cannot be sent from the file handle.

    #### Examples:
    ```mojo
    import floki

    def main() raises:
        with open("data.json", "r") as file:
            var r = floki.put("https://httpbin.org/put", data=file)
    ```
    """
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.PUT](
        url=url,
        headers=headers,
        query_parameters=query_parameters,
        data=Pointer(to=data),
    )


def delete[
    A: Auth = NoAuth, //
](
    var url: String,
    var headers: Headers = Headers(),
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    query_parameters: Dict[String, String] = {},
    auth: Optional[A] = None,
) raises -> Response:
    """Sends a DELETE request to the specified URL.

    Parameters:
        A: The concrete `Auth` scheme type, inferred from `auth`.

    Args:
        url: The URL to which the request is sent.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        query_parameters: Query parameters to include in the request URL.
        auth: An optional authentication scheme to apply to the request.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the request fails.

    #### Examples:
    ```mojo
    import floki

    def main() raises:
        var r = floki.delete("https://httpbin.org/delete")
    ```
    """
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.DELETE](
        url=url,
        headers=headers,
        query_parameters=query_parameters,
        data=RequestData(List[Byte]()),
        auth=auth,
    )


def patch[
    A: Auth = NoAuth, //
](
    var url: String,
    var headers: Headers = Headers(),
    var data: emberjson.Object = {},
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    query_parameters: Dict[String, String] = {},
    auth: Optional[A] = None,
) raises -> Response:
    """Sends a PATCH request to the specified URL.

    Parameters:
        A: The concrete `Auth` scheme type, inferred from `auth`.

    Args:
        url: The URL to which the request is sent.
        headers: HTTP headers to include in the request.
        data: The data to include in the body of the PATCH request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        query_parameters: Query parameters to include in the request URL.
        auth: An optional authentication scheme to apply to the request.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the data cannot be serialized to JSON or if the request fails.

    #### Examples:
    ```mojo
    import floki

    def main() raises:
        var r = floki.patch("https://httpbin.org/patch", data={"key": "value"})
    ```
    """
    var json_data = emberjson.to_string(data^).as_bytes()
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.PATCH](
        url=url,
        headers=headers,
        query_parameters=query_parameters,
        data=json_data,
        auth=auth,
    )


def patch[
    T: AnyType & ImplicitlyDestructible, //
](
    var url: String,
    data: T,
    var headers: Headers = Headers(),
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    query_parameters: Dict[String, String] = {},
) raises -> Response:
    """Sends a GET request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        data: The data to include in the body of the PATCH request.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        query_parameters: Query parameters to include in the request URL.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the data cannot be serialized to JSON or if the request fails.

    #### Examples:
    ```mojo
    from floki.session import Session

    @fieldwise_init
    struct Point:
        var x: Int
        var y: Int

    def main() raises:
        var session = Session()
        var r = session.patch("https://httpbin.org/patch", data=Point(0, 1))
    ```
    """
    var json_data = emberjson.serialize(data)
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.PATCH](
        url=url,
        headers=headers,
        query_parameters=query_parameters,
        data=json_data.as_bytes(),
    )


def patch[
    origin: ImmutOrigin, //
](
    var url: String,
    data: Span[Byte, origin],
    var headers: Headers = Headers(),
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    query_parameters: Dict[String, String] = {},
) raises -> Response:
    """Sends a GET request to the specified URL.

    Parameters:
        origin: The origin of the data span.

    Args:
        url: The URL to which the request is sent.
        data: The data to include in the body of the PATCH request.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        query_parameters: Query parameters to include in the request URL.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the data cannot be sent as bytes.

    #### Examples:
    ```mojo
    import floki

    def main() raises:
        var r = floki.patch("https://httpbin.org/patch", data="hello".as_bytes())
    ```
    """
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.PATCH](
        url=url,
        headers=headers,
        query_parameters=query_parameters,
        data=data,
    )


def patch(
    var url: String,
    data: FileHandle,
    var headers: Headers = Headers(),
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    query_parameters: Dict[String, String] = {},
) raises -> Response:
    """Sends a GET request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        data: The data to include in the body of the PATCH request.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        query_parameters: Query parameters to include in the request URL.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the data cannot be sent from the file handle.

    #### Examples:
    ```mojo
    import floki

    def main() raises:
        with open("data.json", "r") as file:
            var r = floki.patch("https://httpbin.org/patch", data=file)
    ```
    """
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.PATCH](
        url=url,
        headers=headers,
        query_parameters=query_parameters,
        data=Pointer(to=data),
    )


def head[
    A: Auth = NoAuth, //
](
    var url: String,
    var headers: Headers = Headers(),
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    auth: Optional[A] = None,
) raises -> Response:
    """Sends a HEAD request to the specified URL.

    Parameters:
        A: The concrete `Auth` scheme type, inferred from `auth`.

    Args:
        url: The URL to which the request is sent.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        auth: An optional authentication scheme to apply to the request.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the request fails.

    #### Examples:
    ```mojo
    import floki

    def main() raises:
        var r = floki.head("https://httpbin.org/get")
    ```
    """
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.HEAD](
        url=url,
        headers=headers,
        data=RequestData(List[Byte]()),
        auth=auth,
    )


def options[
    A: Auth = NoAuth, //
](
    var url: String,
    var headers: Headers = Headers(),
    var timeout: Timeout = Timeout(),
    var retry: Retry = Retry(),
    var proxy: Proxy = Proxy(),
    var tls: TLS = TLS(),
    auth: Optional[A] = None,
) raises -> Response:
    """Sends an OPTIONS request to the specified URL.

    Parameters:
        A: The concrete `Auth` scheme type, inferred from `auth`.

    Args:
        url: The URL to which the request is sent.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.
        retry: An optional retry policy for the request.
        proxy: An optional proxy configuration for the request.
        tls: An optional TLS configuration for the request.
        auth: An optional authentication scheme to apply to the request.

    Returns:
        The received response as an `Response` object.

    Raises:
        Error: If the request fails.

    #### Examples:
    ```mojo
    import floki

    def main() raises:
        var r = floki.options("https://httpbin.org/get")
    ```
    """
    var session = Session(timeout=timeout^, retry=retry^, proxy=proxy^, tls=tls^)
    return session.send[RequestMethod.OPTIONS](
        url=url,
        headers=headers,
        data=RequestData(List[Byte]()),
        auth=auth,
    )
