from memory import UnsafePointer
from sys.ffi import external_call, OpaquePointer
from floki._logger import LOGGER
from floki.socket import Socket
from floki._libc import (
    c_int,
    c_char,
    c_uchar,
    in_addr,
    sockaddr,
    sockaddr_in,
    socklen_t,
    AddressFamily,
    AddressLength,
    ntohs,
    inet_ntop,
    socket,
    gai_strerror,
    SocketType,
)

alias DEFAULT_IP_PORT: UInt16 = 0


struct AddressConstants:
    """Constants used in address parsing."""

    alias LOCALHOST = "localhost"
    alias IPV4_LOCALHOST = "127.0.0.1"
    alias IPV6_LOCALHOST = "::1"
    alias EMPTY = ""


trait Addr(Copyable, EqualityComparable, ExplicitlyCopyable, Movable, Representable, Stringable, Writable):
    alias _type: StaticString

    fn __init__(out self, ip: String, port: UInt16):
        ...

    @always_inline
    fn address_family(self) -> Int:
        ...

    @always_inline
    fn is_v4(self) -> Bool:
        ...

    @always_inline
    fn is_v6(self) -> Bool:
        ...

    @always_inline
    fn is_unix(self) -> Bool:
        ...


trait AnAddrInfo:
    fn get_ip_address(self, host: String) raises -> in_addr:
        """TODO: Once default functions can be implemented in traits, this should use the functions currently
        implemented in the `addrinfo_macos` and `addrinfo_unix` structs.
        """
        ...


@fieldwise_init
struct NetworkType(Copyable, EqualityComparable, Movable):
    var value: StaticString

    alias empty = NetworkType("")
    alias tcp = NetworkType("tcp")
    alias tcp4 = NetworkType("tcp4")
    alias tcp6 = NetworkType("tcp6")
    alias udp = NetworkType("udp")
    alias udp4 = NetworkType("udp4")
    alias udp6 = NetworkType("udp6")
    alias ip = NetworkType("ip")
    alias ip4 = NetworkType("ip4")
    alias ip6 = NetworkType("ip6")
    alias unix = NetworkType("unix")

    alias SUPPORTED_TYPES = [
        Self.tcp,
        Self.tcp4,
        Self.tcp6,
        Self.udp,
        Self.udp4,
        Self.udp6,
        Self.ip,
        Self.ip4,
        Self.ip6,
    ]
    alias TCP_TYPES = [
        Self.tcp,
        Self.tcp4,
        Self.tcp6,
    ]
    alias UDP_TYPES = [
        Self.udp,
        Self.udp4,
        Self.udp6,
    ]
    alias IP_TYPES = [
        Self.ip,
        Self.ip4,
        Self.ip6,
    ]

    fn __eq__(self, other: NetworkType) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: NetworkType) -> Bool:
        return self.value != other.value

    fn is_ip_protocol(self) -> Bool:
        """Check if the network type is an IP protocol."""
        return self in (NetworkType.ip, NetworkType.ip4, NetworkType.ip6)

    fn is_ipv4(self) -> Bool:
        """Check if the network type is IPv4."""
        return self in (NetworkType.tcp4, NetworkType.udp4, NetworkType.ip4)

    fn is_ipv6(self) -> Bool:
        """Check if the network type is IPv6."""
        return self in (NetworkType.tcp6, NetworkType.udp6, NetworkType.ip6)


struct TCPAddr[network: NetworkType = NetworkType.tcp4](Addr):
    alias _type = "TCPAddr"
    var ip: String
    var port: UInt16
    var zone: String  # IPv6 addressing zone

    fn __init__(out self, ip: String = "127.0.0.1", port: UInt16 = 8000):
        self.ip = ip
        self.port = port
        self.zone = ""

    fn __init__(out self, network: NetworkType, ip: String, port: UInt16, zone: String = ""):
        self.ip = ip
        self.port = port
        self.zone = zone

    @always_inline
    fn address_family(self) -> Int:
        @parameter
        if network == NetworkType.tcp4:
            return Int(AddressFamily.AF_INET.value)
        elif network == NetworkType.tcp6:
            return Int(AddressFamily.AF_INET6.value)
        else:
            return Int(AddressFamily.AF_UNSPEC.value)

    @always_inline
    fn is_v4(self) -> Bool:
        return network == NetworkType.tcp4

    @always_inline
    fn is_v6(self) -> Bool:
        return network == NetworkType.tcp6

    @always_inline
    fn is_unix(self) -> Bool:
        return False

    fn __eq__(self, other: Self) -> Bool:
        return self.ip == other.ip and self.port == other.port and self.zone == other.zone

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    fn __str__(self) -> String:
        if self.zone != "":
            return join_host_port(self.ip + "%" + self.zone, String(self.port))
        return join_host_port(self.ip, String(self.port))

    fn __repr__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer, //](self, mut writer: W):
        writer.write("TCPAddr(", "ip=", repr(self.ip), ", port=", String(self.port), ", zone=", repr(self.zone), ")")


@fieldwise_init
@register_passable("trivial")
struct addrinfo_macos(AnAddrInfo):
    """
    For MacOS, I had to swap the order of ai_canonname and ai_addr.
    https://stackoverflow.com/questions/53575101/calling-getaddrinfo-directly-from-python-ai-addr-is-null-pointer.
    """

    var ai_flags: c_int
    var ai_family: c_int
    var ai_socktype: c_int
    var ai_protocol: c_int
    var ai_addrlen: socklen_t
    var ai_canonname: UnsafePointer[c_char]
    var ai_addr: UnsafePointer[sockaddr]
    var ai_next: OpaquePointer

    fn __init__(
        out self,
        ai_flags: c_int = 0,
        ai_family: c_int = 0,
        ai_socktype: c_int = 0,
        ai_protocol: c_int = 0,
        ai_addrlen: socklen_t = 0,
    ):
        self.ai_flags = ai_flags
        self.ai_family = ai_family
        self.ai_socktype = ai_socktype
        self.ai_protocol = ai_protocol
        self.ai_addrlen = ai_addrlen
        self.ai_canonname = UnsafePointer[c_char]()
        self.ai_addr = UnsafePointer[sockaddr]()
        self.ai_next = OpaquePointer()

    fn get_ip_address(self, host: String) raises -> in_addr:
        """Returns an IP address based on the host.
        This is a MacOS-specific implementation.

        Args:
            host: String - The host to get the IP from.

        Returns:
            The IP address.
        """
        var result = UnsafePointer[Self]()
        var hints = Self(
            ai_flags=0, ai_family=AddressFamily.AF_INET.value, ai_socktype=SocketType.SOCK_STREAM.value, ai_protocol=0
        )
        try:
            getaddrinfo(host, String(), hints, result)
        except e:
            LOGGER.error("Failed to get IP address.")
            raise e

        if not result[].ai_addr:
            freeaddrinfo(result)
            raise Error("Failed to get IP address because the response's `ai_addr` was null.")

        var ip = result[].ai_addr.bitcast[sockaddr_in]()[].sin_addr
        freeaddrinfo(result)
        return ip


@fieldwise_init
@register_passable("trivial")
struct addrinfo_unix(AnAddrInfo):
    """Standard addrinfo struct for Unix systems.
    Overwrites the existing libc `getaddrinfo` function to adhere to the AnAddrInfo trait.
    """

    var ai_flags: c_int
    var ai_family: c_int
    var ai_socktype: c_int
    var ai_protocol: c_int
    var ai_addrlen: socklen_t
    var ai_addr: UnsafePointer[sockaddr]
    var ai_canonname: UnsafePointer[c_char]
    var ai_next: OpaquePointer

    fn __init__(
        out self,
        ai_flags: c_int = 0,
        ai_family: c_int = 0,
        ai_socktype: c_int = 0,
        ai_protocol: c_int = 0,
        ai_addrlen: socklen_t = 0,
    ):
        self.ai_flags = ai_flags
        self.ai_family = ai_family
        self.ai_socktype = ai_socktype
        self.ai_protocol = ai_protocol
        self.ai_addrlen = ai_addrlen
        self.ai_addr = UnsafePointer[sockaddr]()
        self.ai_canonname = UnsafePointer[c_char]()
        self.ai_next = OpaquePointer()

    fn get_ip_address(self, host: String) raises -> in_addr:
        """Returns an IP address based on the host.
        This is a Unix-specific implementation.

        Args:
            host: String - The host to get IP from.

        Returns:
            The IP address.
        """
        var result = UnsafePointer[Self]()
        var hints = Self(
            ai_flags=0, ai_family=AddressFamily.AF_INET.value, ai_socktype=SocketType.SOCK_STREAM.value, ai_protocol=0
        )
        try:
            getaddrinfo(host, String(), hints, result)
        except e:
            LOGGER.error("Failed to get IP address.")
            raise e

        if not result[].ai_addr:
            freeaddrinfo(result)
            raise Error("Failed to get IP address because the response's `ai_addr` was null.")

        var ip = result[].ai_addr.bitcast[sockaddr_in]()[].sin_addr
        freeaddrinfo(result)
        return ip


fn parse_ipv6_bracketed_address[
    origin: ImmutableOrigin
](address: StringSlice[origin]) raises -> (StringSlice[origin], UInt16):
    """Parse an IPv6 address enclosed in brackets.

    Returns:
        Tuple of (host, colon_index_offset).
    """
    if address[0] != "[":
        return address, UInt16(0)

    var end_bracket_index = address.find("]")
    if end_bracket_index == -1:
        raise Error("missing ']' in address")

    if end_bracket_index + 1 == len(address):
        raise MissingPortError

    var colon_index = end_bracket_index + 1
    if address[colon_index] != ":":
        raise MissingPortError

    return (address[1:end_bracket_index], UInt16(end_bracket_index + 1))


fn validate_no_brackets[
    origin: ImmutableOrigin
](address: StringSlice[origin], start_idx: UInt16, end_idx: Optional[UInt16] = None) raises:
    """Validate that the address segment contains no brackets."""
    var segment: StringSlice[origin]

    if end_idx is None:
        segment = address[Int(start_idx) :]
    else:
        segment = address[Int(start_idx) : Int(end_idx.value())]

    if segment.find("[") != -1:
        raise Error("unexpected '[' in address")
    if segment.find("]") != -1:
        raise Error("unexpected ']' in address")


fn _parse_port[origin: ImmutableOrigin](port_str: StringSlice[origin]) raises -> UInt16:
    """Parse and validate port number."""
    if port_str == AddressConstants.EMPTY:
        raise MissingPortError

    alias MIN_PORT = 0
    alias MAX_PORT = 65535
    var port = Int(port_str)
    if port < MIN_PORT or port > MAX_PORT:
        raise Error("The provided port number is out of range (0-65535).")

    return UInt16(port)


fn parse_address[
    origin: ImmutableOrigin
](network: NetworkType, address: StringSlice[origin]) raises -> (String, UInt16):
    """Parse an address string into a host and port.

    Args:
        network: The network type (tcp, tcp4, tcp6, udp, udp4, udp6, ip, ip4, ip6, unix).
        address: The address string.

    Returns:
        Tuple containing the host and port.
    """
    if address == AddressConstants.EMPTY:
        raise Error("missing host")

    if address == AddressConstants.LOCALHOST:
        if network.is_ipv4():
            return String(AddressConstants.IPV4_LOCALHOST), DEFAULT_IP_PORT
        elif network.is_ipv6():
            return String(AddressConstants.IPV6_LOCALHOST), DEFAULT_IP_PORT

    if network.is_ip_protocol():
        if network == NetworkType.ip6 and address.find(":") != -1:
            return String(address), DEFAULT_IP_PORT

        if address.find(":") != -1:
            raise Error("IP protocol addresses should not include ports")

        return String(address), DEFAULT_IP_PORT

    var colon_index = address.rfind(":")
    if colon_index == -1:
        raise MissingPortError

    var host: StringSlice[origin]
    var port: UInt16

    if address[0] == "[":
        try:
            var bracket_offset: UInt16
            (host, bracket_offset) = parse_ipv6_bracketed_address(address)
            validate_no_brackets(address, bracket_offset)
        except e:
            raise e
    else:
        host = address[:colon_index]
        if host.find(":") != -1:
            raise TooManyColonsError

    port = _parse_port(address[colon_index + 1 :])
    if host == AddressConstants.LOCALHOST:
        if network.is_ipv4():
            return String(AddressConstants.IPV4_LOCALHOST), port
        elif network.is_ipv6():
            return String(AddressConstants.IPV6_LOCALHOST), port

    return String(host), port


# TODO: Support IPv6 long form.
fn join_host_port(host: StringSlice, port: StringSlice) -> String:
    if host.find(":") != -1:  # must be IPv6 literal
        return "[" + host + "]:" + port
    return host + ":" + port


alias MissingPortError = Error("missing port in address")
alias TooManyColonsError = Error("too many colons in address")


fn binary_port_to_int(port: UInt16) -> Int:
    """Convert a binary port to an integer.

    Args:
        port: The binary port.

    Returns:
        The port as an integer.
    """
    return Int(ntohs(port))


fn binary_ip_to_string[address_family: AddressFamily](owned ip_address: UInt32) raises -> String:
    """Convert a binary IP address to a string by calling `inet_ntop`.

    Parameters:
        address_family: The address family of the IP address.

    Args:
        ip_address: The binary IP address.

    Returns:
        The IP address as a string.
    """

    @parameter
    if address_family == AddressFamily.AF_INET:
        return inet_ntop[address_family, AddressLength.INET_ADDRSTRLEN](ip_address)
    else:
        return inet_ntop[address_family, AddressLength.INET6_ADDRSTRLEN](ip_address)


fn _getaddrinfo[
    T: AnAddrInfo, hints_origin: ImmutableOrigin, result_origin: MutableOrigin, //
](
    nodename: UnsafePointer[c_char, mut=False],
    servname: UnsafePointer[c_char, mut=False],
    hints: Pointer[T, hints_origin],
    res: Pointer[UnsafePointer[T], result_origin],
) -> c_int:
    """Libc POSIX `getaddrinfo` function.

    Args:
        nodename: The node name.
        servname: The service name.
        hints: A Pointer to the hints.
        res: A UnsafePointer to the result.

    Returns:
        0 on success, an error code on failure.

    #### C Function
    ```c
    int getaddrinfo(const char *restrict nodename, const char *restrict servname, const struct addrinfo *restrict hints, struct addrinfo **restrict res)
    ```

    #### Notes:
    * Reference: https://man7.org/linux/man-pages/man3/getaddrinfo.3p.html
    """
    return external_call[
        "getaddrinfo",
        c_int,  # FnName, RetType
        UnsafePointer[c_char, mut=False],
        UnsafePointer[c_char, mut=False],
        Pointer[T, hints_origin],  # Args
        Pointer[UnsafePointer[T], result_origin],  # Args
    ](nodename, servname, hints, res)


fn getaddrinfo[
    T: AnAddrInfo, //
](owned node: String, owned service: String, hints: T, mut res: UnsafePointer[T]) raises:
    """Libc POSIX `getaddrinfo` function.

    Args:
        node: The node name.
        service: The service name.
        hints: A Pointer to the hints.
        res: A UnsafePointer to the result.

    Raises:
        Error: If an error occurs while attempting to receive data from the socket.
        EAI_AGAIN: The name could not be resolved at this time. Future attempts may succeed.
        EAI_BADFLAGS: The `ai_flags` value was invalid.
        EAI_FAIL: A non-recoverable error occurred when attempting to resolve the name.
        EAI_FAMILY: The `ai_family` member of the `hints` argument is not supported.
        EAI_MEMORY: Out of memory.
        EAI_NONAME: The name does not resolve for the supplied parameters.
        EAI_SERVICE: The `servname` is not supported for `ai_socktype`.
        EAI_SOCKTYPE: The `ai_socktype` is not supported.
        EAI_SYSTEM: A system error occurred. `errno` is set in this case.

    #### C Function
    ```c
    int getaddrinfo(const char *restrict nodename, const char *restrict servname, const struct addrinfo *restrict hints, struct addrinfo **restrict res)
    ```

    #### Notes:
    * Reference: https://man7.org/linux/man-pages/man3/getaddrinfo.3p.html.
    """
    var result = _getaddrinfo(
        node.unsafe_cstr_ptr().origin_cast[mut=False](),
        service.unsafe_cstr_ptr().origin_cast[mut=False](),
        Pointer(to=hints),
        Pointer(to=res),
    )
    if result != 0:
        # gai_strerror returns a char buffer that we don't know the length of.
        var err = gai_strerror(result)
        var msg = String()
        var i = 0
        while err[i] != 0:
            i += 1

        msg.write_bytes(Span[Byte, __origin_of(err)](ptr=err.bitcast[c_uchar](), length=i))
        raise Error("getaddrinfo: ", msg)


fn freeaddrinfo[T: AnAddrInfo, //](ptr: UnsafePointer[T]):
    """Free the memory allocated by `getaddrinfo`."""
    external_call["freeaddrinfo", NoneType, UnsafePointer[T]](ptr)
