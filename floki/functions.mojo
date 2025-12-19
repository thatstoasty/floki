from floki.session import Session
from floki.response import HTTPResponse
from floki.http import RequestMethod
from floki.body import Body
import emberjson


fn get(
    var url: String,
    var headers: Dict[String, String] = {},
    query_parameters: Dict[String, String] = {},
    timeout: Optional[Int] = None,
) raises -> HTTPResponse:
    """Sends a GET request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        headers: HTTP headers to include in the request.
        query_parameters: Query parameters to include in the request.
        timeout: An optional timeout in seconds for the request.

    Returns:
        The received response as an `HTTPResponse` object.
    """
    return Session().send[RequestMethod.GET](
        url=url,
        headers=headers^,
        timeout=timeout,
        query_parameters=query_parameters,
        data=List[Byte](),
    )


fn post(
    var url: String,
    var headers: Dict[String, String] = {},
    var data: emberjson.Object = {},
    timeout: Optional[Int] = None,
) raises -> HTTPResponse:
    """Sends a POST request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        headers: HTTP headers to include in the request.
        data: The data to include in the body of the POST request.
        timeout: An optional timeout in seconds for the request.

    Returns:
        The received response as an `HTTPResponse` object.
    """
    var json_data = emberjson.to_string(data^).as_bytes()
    return Session().send[RequestMethod.POST](
        url=url,
        headers=headers^,
        data=json_data,
        timeout=timeout,
    )


fn post(
    var url: String,
    data: Span[mut=False, Byte],
    var headers: Dict[String, String] = {},
    timeout: Optional[Int] = None,
) raises -> HTTPResponse:
    """Sends a POST request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        data: The data to include in the body of the POST request.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.

    Returns:
        The received response as an `HTTPResponse` object.
    """
    return Session().send[RequestMethod.POST](
        url=url,
        headers=headers^,
        data=data,
        timeout=timeout,
    )


fn post(
    var url: String,
    mut data: FileHandle,
    var headers: Dict[String, String] = {},
    timeout: Optional[Int] = None,
) raises -> HTTPResponse:
    """Sends a POST request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        data: The data to include in the body of the POST request.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.

    Returns:
        The received response as an `HTTPResponse` object.
    """
    return Session().send[RequestMethod.POST](
        url=url,
        headers=headers^,
        file=data,
        timeout=timeout,
    )


fn put(
    var url: String,
    var headers: Dict[String, String] = {},
    var data: emberjson.Object = {},
    timeout: Optional[Int] = None,
) raises -> HTTPResponse:
    """Sends a PUT request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        headers: HTTP headers to include in the request.
        data: The data to include in the body of the PUT request.
        timeout: An optional timeout in seconds for the request.

    Returns:
        The received response as an `HTTPResponse` object.
    """
    var json_data = emberjson.to_string(data^).as_bytes()
    return Session().send[RequestMethod.PUT](
        url=url,
        headers=headers^,
        data=json_data,
        timeout=timeout,
    )


fn put(
    var url: String,
    data: Span[mut=False, Byte],
    var headers: Dict[String, String] = {},
    timeout: Optional[Int] = None,
) raises -> HTTPResponse:
    """Sends a PUT request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        data: The data to include in the body of the PUT request.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.

    Returns:
        The received response as an `HTTPResponse` object.
    """
    return Session().send[RequestMethod.PUT](
        url=url,
        headers=headers^,
        data=data,
        timeout=timeout,
    )


fn put(
    var url: String,
    mut data: FileHandle,
    var headers: Dict[String, String] = {},
    timeout: Optional[Int] = None,
) raises -> HTTPResponse:
    """Sends a PUT request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        data: The data to include in the body of the PUT request.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.

    Returns:
        The received response as an `HTTPResponse` object.
    """
    return Session().send[RequestMethod.PUT](
        url=url,
        headers=headers^,
        file=data,
        timeout=timeout,
    )


fn delete(
    var url: String,
    var headers: Dict[String, String] = {},
    timeout: Optional[Int] = None,
) raises -> HTTPResponse:
    """Sends a DELETE request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.

    Returns:
        The received response as an `HTTPResponse` object.
    """
    return Session().send[RequestMethod.DELETE](
        url=url,
        headers=headers^,
        timeout=timeout,
        data=List[Byte](),
    )


fn patch(
    var url: String,
    var headers: Dict[String, String] = {},
    var data: emberjson.Object = {},
    timeout: Optional[Int] = None,
) raises -> HTTPResponse:
    """Sends a GET request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        headers: HTTP headers to include in the request.
        data: The data to include in the body of the PATCH request.
        timeout: An optional timeout in seconds for the request.

    Returns:
        The received response as an `HTTPResponse` object.
    """
    var json_data = emberjson.to_string(data^).as_bytes()
    return Session().send[RequestMethod.PATCH](
        url=url,
        headers=headers^,
        data=json_data,
        timeout=timeout,
    )

fn patch(
    var url: String,
    data: Span[mut=False, Byte],
    var headers: Dict[String, String] = {},
    timeout: Optional[Int] = None,
) raises -> HTTPResponse:
    """Sends a GET request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        data: The data to include in the body of the PATCH request.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.

    Returns:
        The received response as an `HTTPResponse` object.
    """
    return Session().send[RequestMethod.PATCH](
        url=url,
        headers=headers^,
        data=data,
        timeout=timeout,
    )

fn patch(
    var url: String,
    mut data: FileHandle,
    var headers: Dict[String, String] = {},
    timeout: Optional[Int] = None,
) raises -> HTTPResponse:
    """Sends a GET request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        data: The data to include in the body of the PATCH request.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.

    Returns:
        The received response as an `HTTPResponse` object.
    """
    return Session().send[RequestMethod.PATCH](
        url=url,
        headers=headers^,
        file=data,
        timeout=timeout,
    )


fn head(
    var url: String,
    var headers: Dict[String, String] = {},
    timeout: Optional[Int] = None,
) raises -> HTTPResponse:
    """Sends a HEAD request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.

    Returns:
        The received response as an `HTTPResponse` object.
    """
    return Session().send[RequestMethod.HEAD](
        url=url,
        headers=headers^,
        timeout=timeout,
        data=List[Byte](),
    )


fn options(
    var url: String,
    var headers: Dict[String, String] = {},
    timeout: Optional[Int] = None,
) raises -> HTTPResponse:
    """Sends an OPTIONS request to the specified URL.

    Args:
        url: The URL to which the request is sent.
        headers: HTTP headers to include in the request.
        timeout: An optional timeout in seconds for the request.

    Returns:
        The received response as an `HTTPResponse` object.
    """
    return Session().send[RequestMethod.OPTIONS](
        url=url,
        headers=headers^,
        timeout=timeout,
        data=List[Byte](),
    )
