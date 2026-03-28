from std.memory import memcpy
from std.ffi import c_char, c_size_t, get_errno
from std.sys import stderr
from mojo_curl.c.types import ImmutExternalPointer, MutExternalPointer, MutExternalOpaquePointer


# To read HTTP response data into a list of bytes.
fn write_callback(
    ptr: MutExternalPointer[c_char], size: c_size_t, nmemb: c_size_t, userdata: MutExternalOpaquePointer
) -> c_size_t:
    """Callback for libcurl to write received HTTP response data into a byte buffer.

    Args:
        ptr: Pointer to the received data.
        size: Size of each data element (always 1).
        nmemb: Number of data elements received.
        userdata: Pointer to the `List[UInt8]` buffer to append data to.

    Returns:
        The number of bytes handled, which must equal `size * nmemb` to indicate success.
    """
    var body = userdata.bitcast[List[UInt8]]()
    var s = Span(ptr=ptr.bitcast[UInt8](), length=Int(size * nmemb))
    body[].extend(s)
    return size * nmemb


@fieldwise_init
struct DataToRead:
    """Struct to hold data that will be read by the `read_callback` function for libcurl."""
    var data: ImmutExternalPointer[Byte]
    """The total number of bytes remaining to be read from the data pointer."""
    var bytes_remaining: UInt
    """The pointer to the data that will be read by the `read_callback` function for libcurl."""


fn read_callback(
    ptr: MutExternalPointer[c_char], size: c_size_t, nmemb: c_size_t, userdata: MutExternalOpaquePointer
) -> c_size_t:
    """Callback for libcurl to read request body data from a byte buffer.

    Args:
        ptr: Pointer to the buffer where data should be written.
        size: Size of each data element (always 1).
        nmemb: Number of data elements the buffer can hold.
        userdata: Pointer to a `DataToRead` struct containing the source data.

    Returns:
        The number of bytes copied into the buffer, or 0 when no data remains.
    """
    var data = userdata.bitcast[DataToRead]()
    var buffer_size = size * nmemb  # Max bytes we can write to ptr

    # Nothing to write
    if buffer_size < 1:
        return 0

    # We will copy as much data as possible into the 'ptr' buffer, but no more than 'size' * 'nmemb' bytes
    # Determine how much data to copy: either remaining data or buffer capacity
    var bytes_to_read = min(data[].bytes_remaining, buffer_size)
    if bytes_to_read > 0:
        # Copy the data into the buffer
        memcpy(
            dest=ptr,
            src=data[].data.bitcast[Int8](),
            count=Int(bytes_to_read),
        )

        # Update the userdata to reflect the consumed data
        data[].data += bytes_to_read
        data[].bytes_remaining -= UInt(bytes_to_read)

        return bytes_to_read

    return 0


fn fd_read_callback(
    ptr: MutExternalPointer[c_char], size: c_size_t, nmemb: c_size_t, userdata: MutExternalOpaquePointer
) -> c_size_t:
    """Callback for libcurl to read request body data from a file descriptor.

    Args:
        ptr: Pointer to the buffer where data should be written.
        size: Size of each data element (always 1).
        nmemb: Number of data elements the buffer can hold.
        userdata: Pointer to a `FileHandle` to read from.

    Returns:
        The number of bytes read into the buffer, or an abort code on error.
    """
    var file = userdata.bitcast[FileHandle]()
    var buffer_size = size * nmemb  # Max bytes we can write to ptr

    # Nothing to write
    if buffer_size < 1:
        return 0

    # Copy the data into the buffer
    try:
        var fd = FileDescriptor(file[]._get_raw_fd())
        return fd.read_bytes(Span(ptr=ptr.bitcast[UInt8](), length=Int(buffer_size)))
    except e:
        print("fd_read_callback: Error reading from file descriptor: ", e, " errno: ", get_errno(), file=stderr)
        # TODO: Add READ_FUNC_ABORT constant to mojo-curl and return it here to signal an error.
        return 0x10000000
