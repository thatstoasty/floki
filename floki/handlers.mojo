"""Helpers for configuring a libcurl easy handle to send request bodies."""
from floki.callbacks import fd_read_callback, read_callback
from mojo_curl.easy import Easy, Result


comptime SIZE_LIMIT = 2_147_483_648
"""Size limit (2GB) for using the standard post field size option in libcurl. Requests with body sizes above this threshold will use the large post field size option."""

comptime _EMPTY_BODY: StaticString = ""
"""Static storage for zero-length bodies: libcurl keeps the post fields pointer until the transfer ends, so it must outlive the request."""


def _set_post_fields[origin: ImmOrigin, //](easy: Easy, data: Span[Byte, origin], caller: StaticString) raises:
    """Sets `data` as the request body, with an explicit size.

    The size is always set, including for an empty body: without it libcurl
    falls back to `strlen` on the pointer, or to a chunked upload with
    `Expect: 100-continue` when no post fields are set at all.

    Parameters:
        origin: The origin of the data span.

    Args:
        easy: The libcurl easy handle to configure.
        data: The request body as a span of bytes.
        caller: The name of the calling handler, used in error messages.
    """
    var data_size = len(data)
    # libcurl dictates the usage of the large post field size option over 2GB.
    var result = easy.post_field_size_large(data_size) if data_size > SIZE_LIMIT else easy.post_field_size(data_size)
    if result != Result.OK:
        raise Error(caller, ": Failed to set post fields size: ", easy.describe_error(result))

    result = easy.post_fields(data) if data_size > 0 else easy.post_fields(_EMPTY_BODY.as_bytes())
    if result != Result.OK:
        raise Error(caller, ": Failed to set post fields: ", easy.describe_error(result))


def _handle_post[origin: ImmOrigin, //](easy: Easy, data: Span[Byte, origin]) raises:
    """Configures the libcurl easy handle for a POST request with byte data.

    Parameters:
        origin: The origin of the data span.

    Args:
        easy: The libcurl easy handle to configure.
        data: The request body as a span of bytes.
    """
    var result = easy.post()
    if result != Result.OK:
        raise Error("_handle_post: Failed to set POST method: ", easy.describe_error(result))
    _set_post_fields(easy, data, "_handle_post")


def _handle_post[origin: ImmOrigin, //](easy: Easy, data: Pointer[FileHandle, origin]) raises:
    """Configures the libcurl easy handle for a POST request with file data.

    Args:
        easy: The libcurl easy handle to configure.
        data: The file handle to read request body data from.
    """
    var result = easy.post()
    if result != Result.OK:
        raise Error("_handle_post: Failed to set POST method: ", easy.describe_error(result))

    result = easy.read_function(fd_read_callback)
    if result != Result.OK:
        raise Error("_handle_post: Failed to set read function: ", easy.describe_error(result))

    result = easy.read_data(Pointer(to=data[]).unsafe_bitcast[NoneType]())
    if result != Result.OK:
        raise Error("_handle_post: Failed to set read data: ", easy.describe_error(result))


def _handle_put[origin: ImmOrigin, //](easy: Easy, data: Span[Byte, origin]) raises:
    """Configures the libcurl easy handle for a PUT request with byte data.

    Parameters:
        origin: The origin of the data span.

    Args:
        easy: The libcurl easy handle to configure.
        data: The request body as a span of bytes.
    """
    comptime http_method = "PUT"
    var result = easy.custom_request(http_method)
    if result != Result.OK:
        raise Error("_handle_put: Failed to set PUT method: ", easy.describe_error(result))

    _set_post_fields(easy, data, "_handle_put")


def _handle_put[origin: ImmOrigin, //](easy: Easy, data: Pointer[FileHandle, origin]) raises:
    """Configures the libcurl easy handle for a PUT request with file data.

    Args:
        easy: The libcurl easy handle to configure.
        data: The file handle to read request body data from.
    """
    comptime http_method = "PUT"
    var result = easy.custom_request(http_method)
    if result != Result.OK:
        raise Error("_handle_put: Failed to set PUT method: ", easy.describe_error(result))

    result = easy.upload()
    if result != Result.OK:
        raise Error("_handle_put: Failed to set PUT method: ", easy.describe_error(result))

    result = easy.read_function(fd_read_callback)
    if result != Result.OK:
        raise Error("_handle_put: Failed to set read function: ", easy.describe_error(result))

    result = easy.read_data(Pointer(to=data[]).unsafe_bitcast[NoneType]())
    if result != Result.OK:
        raise Error("_handle_put: Failed to set read data: ", easy.describe_error(result))

    # TODO: Need a way to set the file read size.
    # result = easy.read_file_size(len(temp))
    # if result != Result.OK:
    #     raise Error("_handle_put: Failed to set read file size: ", easy.describe_error(result))


def _handle_delete(easy: Easy) raises:
    """Configures the libcurl easy handle for a DELETE request.

    Args:
        easy: The libcurl easy handle to configure.
    """
    comptime http_method = "DELETE"
    var result = easy.custom_request(http_method)
    if result != Result.OK:
        raise Error("_handle_delete: Failed to set DELETE method: ", easy.describe_error(result))


def _handle_patch[origin: ImmOrigin, //](easy: Easy, data: Span[Byte, origin]) raises:
    """Configures the libcurl easy handle for a PATCH request with byte data.

    Parameters:
        origin: The origin of the data span.

    Args:
        easy: The libcurl easy handle to configure.
        data: The request body as a span of bytes.
    """
    comptime http_method = "PATCH"
    var result = easy.custom_request(http_method)
    if result != Result.OK:
        raise Error("_handle_patch: Failed to set PATCH method: ", easy.describe_error(result))

    _set_post_fields(easy, data, "_handle_patch")


def _handle_patch[origin: ImmOrigin, //](easy: Easy, data: Pointer[FileHandle, origin]) raises:
    """Configures the libcurl easy handle for a PATCH request with file data.

    Args:
        easy: The libcurl easy handle to configure.
        data: The file handle to read request body data from.
    """
    comptime http_method = "PATCH"
    var result = easy.custom_request(http_method)
    if result != Result.OK:
        raise Error("_handle_patch: Failed to set PATCH method: ", easy.describe_error(result))

    result = easy.post()
    if result != Result.OK:
        raise Error("_handle_patch: Failed to set POST method: ", easy.describe_error(result))

    result = easy.read_function(fd_read_callback)
    if result != Result.OK:
        raise Error("_handle_patch: Failed to set read function: ", easy.describe_error(result))

    result = easy.read_data(Pointer(to=data[]).unsafe_bitcast[NoneType]())
    if result != Result.OK:
        raise Error("_handle_patch: Failed to set read data: ", easy.describe_error(result))


def _handle_head(easy: Easy) raises:
    """Configures the libcurl easy handle for a HEAD request.

    Args:
        easy: The libcurl easy handle to configure.
    """
    # Set NOBODY to true to avoid downloading the body, also tells libcurl to use HEAD.
    var result = easy.nobody()
    if result != Result.OK:
        raise Error("_handle_head: Failed to set NOBODY option: ", easy.describe_error(result))


def _handle_options(easy: Easy) raises:
    """Configures the libcurl easy handle for an OPTIONS request.

    Args:
        easy: The libcurl easy handle to configure.
    """
    comptime http_method = "OPTIONS"
    var result = easy.custom_request(http_method)
    if result != Result.OK:
        raise Error("_handle_options: Failed to set OPTIONS method: ", easy.describe_error(result))
