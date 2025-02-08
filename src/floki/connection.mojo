from sys.info import os_is_macos
from floki.bytes import Bytes
from floki.address import NetworkType, TCPAddr
from floki._libc import (
    socket,
    connect,
    send,
    shutdown,
    close,
)
from floki._logger import LOGGER
from floki.socket import Socket

alias Duration = Int
"""Alias for Duration, which is represented as an Int in nanoseconds."""
alias default_tcp_keep_alive = Duration(15 * 1000 * 1000 * 1000)  # 15 seconds
"""The default TCP keep-alive duration."""


trait Connection(Movable):
    fn __init__(out self, owned host: String, port: UInt16) raises:
        ...

    fn read(self, mut buf: Bytes) raises -> Int:
        ...

    fn write(self, buf: Span[Byte]) raises -> Int:
        ...

    fn close(mut self) raises:
        ...

    fn shutdown(mut self) raises -> None:
        ...

    fn teardown(mut self) raises:
        ...

    # fn local_addr(self) -> TCPAddr:
    #     ...

    # fn remote_addr(self) -> TCPAddr:
    #     ...


struct TCPConnection(Connection, Movable):
    var socket: Socket

    fn __init__(out self, owned host: String, port: UInt16) raises:
        self = create_connection(host^, port)

    fn __init__(out self, owned socket: Socket):
        self.socket = socket^

    fn __moveinit__(out self, owned existing: Self):
        self.socket = existing.socket^

    fn read(self, mut buf: Bytes) raises -> Int:
        try:
            return self.socket.receive(buf)
        except e:
            if e.as_string_slice() == "EOF":
                raise e
            else:
                LOGGER.error(e)
                raise Error("TCPConnection.read: Failed to read data from connection.")

    fn write(self, buf: Span[Byte]) raises -> Int:
        if buf[-1] == 0:
            raise Error("TCPConnection.write: Buffer must not be null-terminated.")

        try:
            return self.socket.send(buf)
        except e:
            LOGGER.error("TCPConnection.write: Failed to write data to connection.")
            raise e

    fn close(mut self) raises:
        self.socket.close()

    fn shutdown(mut self) raises:
        self.socket.shutdown()

    fn teardown(mut self) raises:
        self.socket.teardown()

    fn is_closed(self) -> Bool:
        return self.socket._closed

    # TODO: Switch to property or return ref when trait supports attributes.
    fn local_address(self) -> ref [self.socket._local_address] TCPAddr[NetworkType.tcp4]:
        return self.socket.local_address()

    fn remote_address(self) -> ref [self.socket._remote_address] TCPAddr[NetworkType.tcp4]:
        return self.socket.remote_address()


fn create_connection(host: String, port: UInt16) raises -> TCPConnection:
    """Connect to a server using a socket.

    Args:
        host: The host to connect to.
        port: The port to connect on.

    Returns:
        The socket file descriptor.
    """
    var socket = Socket()
    try:
        socket.connect(host, port)
    except e:
        LOGGER.error(e)
        try:
            socket.shutdown()
        except e:
            LOGGER.error("Failed to shutdown socket: ", e)
        raise Error("Failed to establish a connection to the server.")

    return TCPConnection(socket^)
