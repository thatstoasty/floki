from memory import memcpy
from sys.ffi import c_char, c_size_t, get_errno
from sys import stderr
from mojo_curl.c.types import ImmutExternalPointer, MutExternalPointer, MutExternalOpaquePointer


# To read HTTP response data into a list of bytes.
fn write_callback(
    ptr: MutExternalPointer[c_char], size: c_size_t, nmemb: c_size_t, userdata: MutExternalOpaquePointer
) -> c_size_t:
    var body = userdata.bitcast[List[UInt8]]()
    var s = Span(ptr=ptr.bitcast[UInt8](), length=Int(size * nmemb))
    body[].extend(s)
    return size * nmemb


@fieldwise_init
struct DataToRead:
    var data: ImmutExternalPointer[Byte]
    var bytes_remaining: UInt


fn read_callback(
    ptr: MutExternalPointer[c_char], size: c_size_t, nmemb: c_size_t, userdata: MutExternalOpaquePointer
) -> c_size_t:
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
