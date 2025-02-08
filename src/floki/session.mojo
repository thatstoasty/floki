from sys.intrinsics import _type_is_eq
from floki.body import Body
from floki.connection import create_connection, TCPConnection, Connection
from floki.bytes import Bytes, DEFAULT_BUFFER_SIZE
from floki._logger import LOGGER
from floki.pool_manager import PoolManager, PoolKey
from floki.uri import URI, Scheme
from floki.tls import establish_tls_context, TLSConnection
from floki.response import HTTPResponse
from floki.request import HTTPRequest, RequestMethod
from floki.header import Headers, HeaderKey
from floki.address import AddressFamily, NetworkType


struct Session[ConnectionType: Connection = TLSConnection]:
    var _connections: PoolManager[ConnectionType]
    var allow_redirects: Bool

    fn __init__(
        out self,
        cached_connections: Int = 10,
        allow_redirects: Bool = False,
    ):
        self.allow_redirects = allow_redirects
        self._connections = PoolManager[ConnectionType](capacity=cached_connections)

    fn send(mut self, owned request: HTTPRequest) raises -> HTTPResponse:
        """Responsible for sending an HTTP request to a server and receiving the corresponding response.

        It performs the following steps:
        1. Creates a connection to the server specified in the request.
        2. Sends the request body using the connection.
        3. Receives the response from the server.
        4. Closes the connection.
        5. Returns the received response as an `HTTPResponse` object.

        Note: The code assumes that the `HTTPRequest` object passed as an argument has a valid URI with a host and port specified.

        Args:
            request: An `HTTPRequest` object representing the request to be sent.

        Returns:
            The received response.

        Raises:
            Error: If there is a failure in sending or receiving the message.
        """
        if len(request.uri.host) == 0:
            raise Error("Session.send: Host must not be empty.")

        if not request.uri.is_https() and _type_is_eq[ConnectionType, TLSConnection]():
            raise Error("Session.send: Only HTTPS requests are supported for secure sessions.")
        elif not request.uri.is_http() and _type_is_eq[ConnectionType, TCPConnection]():
            raise Error("Session.send: Only HTTP requests are supported for insecure sessions.")

        var port: UInt16
        var scheme = Scheme.HTTPS  # Just assume HTTPS for now.
        if request.uri.port:
            port = request.uri.port.value()
        else:
            if request.uri.scheme == Scheme.HTTPS.value:
                port = 443
            elif request.uri.scheme == Scheme.HTTP.value:
                port = 80
                scheme = Scheme.HTTP
            else:
                raise Error("Session.send: Invalid scheme received in the URI.")

        var pool_key = PoolKey(request.uri.host, port, scheme)
        var cached_connection = False
        var connection: ConnectionType
        try:
            connection = self._connections.take(pool_key)
            cached_connection = True
        except e:
            if e.as_string_slice() == "PoolManager.take: Key not found.":
                connection = ConnectionType(request.uri.host, port)
            else:
                LOGGER.error(e)
                raise Error("Session.send: Failed to create a connection to host.")

        try:
            # Encode no longer consumes the request, so we can use it again in case of a connection reset.
            _ = connection.write(request.encode())
        except e:
            # Maybe peer reset ungracefully, so try a fresh connection
            if e.as_string_slice() == "SendError: Connection reset by peer.":
                LOGGER.debug("Session.send: Connection reset by peer. Trying a fresh connection.")
                connection.teardown()
                if cached_connection:
                    return self.send(request^)
            LOGGER.error("Session.send: Failed to send message.")
            raise e

        var response_buffer = Bytes(capacity=DEFAULT_BUFFER_SIZE)
        try:
            _ = connection.read(response_buffer)
        except e:
            if e.as_string_slice() == "EOF":
                connection.teardown()
                if cached_connection:
                    return self.send(request^)
                raise Error("Session.send: No response received from the server.")
            else:
                LOGGER.error(e)
                raise Error("Session.send: Failed to read response from peer.")

        var response: HTTPResponse
        try:
            response = HTTPResponse.from_bytes(response_buffer, connection)
        except e:
            LOGGER.error("Failed to parse a response...")
            try:
                connection.teardown()
            except:
                LOGGER.error("Failed to teardown connection...")
            raise e

        # Redirects should not keep the connection alive, as redirects can send the client to a different server.
        if self.allow_redirects and response.is_redirect():
            connection.teardown()
            return self._handle_redirect(request^, response^)
        # Server told the client to close the connection, we can assume the server closed their side after sending the response.
        elif response.connection_close():
            connection.teardown()
        # Otherwise, persist the connection by giving it back to the pool manager.
        else:
            self._connections.give(pool_key, connection^)
        return response^

    fn _handle_redirect(
        mut self, owned original_request: HTTPRequest, owned original_response: HTTPResponse
    ) raises -> HTTPResponse:
        var new_uri: URI
        var new_location: String
        try:
            new_location = original_response.headers[HeaderKey.LOCATION]
        except e:
            raise Error("Session._handle_redirect: `Location` header was not received in the response.")

        if new_location.startswith("http"):
            try:
                new_uri = URI.parse(new_location)
            except e:
                raise Error("Session._handle_redirect: Failed to parse the new URI: ", e)
            original_request.headers[HeaderKey.HOST] = new_uri.host
        else:
            new_uri = original_request.uri
            new_uri.path = new_location
        original_request.uri = new_uri
        return self.send(original_request^)

    fn get(
        mut self,
        url: String,
        headers: Headers = {},
        query_parameters: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> HTTPResponse:
        return self.send(
            HTTPRequest(
                uri=URI.parse(url),
                headers=headers,
                method=RequestMethod.GET,
                body=Body(),
                timeout=timeout,
            )
        )

    fn post(
        mut self,
        url: String,
        headers: Headers = {},
        data: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> HTTPResponse:
        return self.send(
            HTTPRequest(
                uri=URI.parse(url),
                headers=headers,
                method=RequestMethod.POST,
                body=Body(data),
                timeout=timeout,
            )
        )

    fn put(
        mut self,
        url: String,
        headers: Headers = {},
        data: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> HTTPResponse:
        return self.send(
            HTTPRequest(
                uri=URI.parse(url),
                headers=headers,
                method=RequestMethod.PUT,
                body=Body(data),
                timeout=timeout,
            )
        )

    fn delete(
        mut self,
        url: String,
        headers: Headers = {},
        timeout: Optional[Int] = None,
    ) raises -> HTTPResponse:
        return self.send(
            HTTPRequest(
                uri=URI.parse(url),
                headers=headers,
                method=RequestMethod.DELETE,
                body=Body(),
                timeout=timeout,
            )
        )

    fn patch(
        mut self,
        url: String,
        headers: Headers = {},
        data: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> HTTPResponse:
        return self.send(
            HTTPRequest(
                uri=URI.parse(url),
                headers=headers,
                method=RequestMethod.PATCH,
                body=Body(data),
                timeout=timeout,
            )
        )

    fn head(
        mut self,
        url: String,
        headers: Headers = {},
        timeout: Optional[Int] = None,
    ) raises -> HTTPResponse:
        return self.send(
            HTTPRequest(
                uri=URI.parse(url),
                headers=headers,
                method=RequestMethod.HEAD,
                body=Body(),
                timeout=timeout,
            )
        )

    fn options(
        mut self,
        url: String,
        headers: Headers = {},
        data: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> HTTPResponse:
        return self.send(
            HTTPRequest(
                uri=URI.parse(url),
                headers=headers,
                method=RequestMethod.OPTIONS,
                body=Body(data),
                timeout=timeout,
            )
        )


# struct InsecureSession:
#     var _connections: PoolManager[TCPConnection[AddressFamily.AF_INET, NetworkType.tcp4]]
#     var allow_redirects: Bool

#     fn __init__(
#         out self,
#         cached_connections: Int = 10,
#         allow_redirects: Bool = False,
#     ):
#         self.allow_redirects = allow_redirects
#         self._connections = PoolManager[TCPConnection[AddressFamily.AF_INET, NetworkType.tcp4]](
#             capacity=cached_connections
#         )

#     fn send(mut self, owned request: HTTPRequest) raises -> HTTPResponse:
#         """Responsible for sending an HTTP request to a server and receiving the corresponding response.

#         It performs the following steps:
#         1. Creates a connection to the server specified in the request.
#         2. Sends the request body using the connection.
#         3. Receives the response from the server.
#         4. Closes the connection.
#         5. Returns the received response as an `HTTPResponse` object.

#         Note: The code assumes that the `HTTPRequest` object passed as an argument has a valid URI with a host and port specified.

#         Args:
#             request: An `HTTPRequest` object representing the request to be sent.

#         Returns:
#             The received response.

#         Raises:
#             Error: If there is a failure in sending or receiving the message.
#         """
#         if len(request.uri.host) == 0:
#             raise Error("Session.send: Host must not be empty.")

#         if not request.uri.is_http():
#             raise Error("Session.send: Only HTTP requests are supported.")

#         var port: UInt16
#         if request.uri.port:
#             port = request.uri.port.value()
#         else:
#             if request.uri.scheme == Scheme.HTTP.value:
#                 port = 80
#             else:
#                 raise Error("Session.send: Invalid scheme received in the URI.")

#         var pool_key = PoolKey(request.uri.host, port, Scheme.HTTP)
#         var cached_connection = False
#         var connection: TCPConnection
#         try:
#             connection = self._connections.take(pool_key)
#             cached_connection = True
#         except e:
#             if e.as_string_slice() == "PoolManager.take: Key not found.":
#                 connection = create_connection(request.uri.host, port)
#             else:
#                 LOGGER.error(e)
#                 raise Error("Session.send: Failed to create a connection to host.")

#         try:
#             # Encode no longer consumes the request, so we can use it again in case of a connection reset.
#             _ = connection.write(request.encode())
#         except e:
#             # Maybe peer reset ungracefully, so try a fresh connection
#             if e.as_string_slice() == "SendError: Connection reset by peer.":
#                 LOGGER.debug("Session.send: Connection reset by peer. Trying a fresh connection.")
#                 connection.teardown()
#                 if cached_connection:
#                     return self.send(request^)
#             LOGGER.error("Session.send: Failed to send message.")
#             raise e

#         var new_buf = Bytes(capacity=DEFAULT_BUFFER_SIZE)
#         try:
#             _ = connection.read(new_buf)
#         except e:
#             if e.as_string_slice() == "EOF":
#                 connection.teardown()
#                 if cached_connection:
#                     return self.send(request^)
#                 raise Error("Session.send: No response received from the server.")
#             else:
#                 LOGGER.error(e)
#                 raise Error("Session.send: Failed to read response from peer.")

#         var response: HTTPResponse
#         try:
#             response = HTTPResponse.from_bytes(new_buf, connection)
#         except e:
#             LOGGER.error("Failed to parse a response...")
#             try:
#                 connection.teardown()
#             except:
#                 LOGGER.error("Failed to teardown connection...")
#             raise e

#         # Redirects should not keep the connection alive, as redirects can send the client to a different server.
#         if self.allow_redirects and response.is_redirect():
#             connection.teardown()
#             return self._handle_redirect(request^, response^)
#         # Server told the client to close the connection, we can assume the server closed their side after sending the response.
#         elif response.connection_close():
#             connection.teardown()
#         # Otherwise, persist the connection by giving it back to the pool manager.
#         else:
#             self._connections.give(pool_key, connection^)
#         return response^

#     fn _handle_redirect(
#         mut self, owned original_request: HTTPRequest, owned original_response: HTTPResponse
#     ) raises -> HTTPResponse:
#         var new_uri: URI
#         var new_location: String
#         try:
#             new_location = original_response.headers[HeaderKey.LOCATION]
#         except e:
#             raise Error("Session._handle_redirect: `Location` header was not received in the response.")

#         if new_location.startswith("http"):
#             try:
#                 new_uri = URI.parse(new_location)
#             except e:
#                 raise Error("Session._handle_redirect: Failed to parse the new URI: ", e)
#             original_request.headers[HeaderKey.HOST] = new_uri.host
#         else:
#             new_uri = original_request.uri
#             new_uri.path = new_location
#         original_request.uri = new_uri
#         return self.send(original_request^)

#     fn get(
#         mut self,
#         url: String,
#         headers: Headers = {},
#         query_parameters: Dict[String, String] = {},
#         timeout: Optional[Int] = None,
#     ) raises -> HTTPResponse:
#         return self.send(
#             HTTPRequest(
#                 uri=URI.parse(url),
#                 headers=headers,
#                 method=RequestMethod.GET,
#                 body=Body(),
#                 timeout=timeout,
#             )
#         )

#     fn post(
#         mut self,
#         url: String,
#         headers: Headers = {},
#         data: Dict[String, String] = {},
#         timeout: Optional[Int] = None,
#     ) raises -> HTTPResponse:
#         return self.send(
#             HTTPRequest(
#                 uri=URI.parse(url),
#                 headers=headers,
#                 method=RequestMethod.POST,
#                 body=Body(data),
#                 timeout=timeout,
#             )
#         )

#     fn put(
#         mut self,
#         url: String,
#         headers: Headers = {},
#         data: Dict[String, String] = {},
#         timeout: Optional[Int] = None,
#     ) raises -> HTTPResponse:
#         return self.send(
#             HTTPRequest(
#                 uri=URI.parse(url),
#                 headers=headers,
#                 method=RequestMethod.PUT,
#                 body=Body(data),
#                 timeout=timeout,
#             )
#         )

#     fn delete(
#         mut self,
#         url: String,
#         headers: Headers = {},
#         timeout: Optional[Int] = None,
#     ) raises -> HTTPResponse:
#         return self.send(
#             HTTPRequest(
#                 uri=URI.parse(url),
#                 headers=headers,
#                 method=RequestMethod.DELETE,
#                 body=Body(),
#                 timeout=timeout,
#             )
#         )

#     fn patch(
#         mut self,
#         url: String,
#         headers: Headers = {},
#         data: Dict[String, String] = {},
#         timeout: Optional[Int] = None,
#     ) raises -> HTTPResponse:
#         return self.send(
#             HTTPRequest(
#                 uri=URI.parse(url),
#                 headers=headers,
#                 method=RequestMethod.PATCH,
#                 body=Body(data),
#                 timeout=timeout,
#             )
#         )

#     fn head(
#         mut self,
#         url: String,
#         headers: Headers = {},
#         timeout: Optional[Int] = None,
#     ) raises -> HTTPResponse:
#         return self.send(
#             HTTPRequest(
#                 uri=URI.parse(url),
#                 headers=headers,
#                 method=RequestMethod.HEAD,
#                 body=Body(),
#                 timeout=timeout,
#             )
#         )

#     fn options(
#         mut self,
#         url: String,
#         headers: Headers = {},
#         data: Dict[String, String] = {},
#         timeout: Optional[Int] = None,
#     ) raises -> HTTPResponse:
#         return self.send(
#             HTTPRequest(
#                 uri=URI.parse(url),
#                 headers=headers,
#                 method=RequestMethod.OPTIONS,
#                 body=Body(data),
#                 timeout=timeout,
#             )
#         )
