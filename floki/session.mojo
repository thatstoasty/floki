from std.reflection import get_base_type_name
from std.utils import Variant
from mojo_curl.easy import Easy, Result
from mojo_curl.list import CurlList
from floki.callbacks import read_callback, write_callback
from floki.response import Response
from floki.http import RequestMethod
from floki.body import Body
from floki.cookie.cookie_jar import CookieJar
from floki.data import RequestData
from floki.handlers import _handle_post, _handle_put, _handle_delete, _handle_patch, _handle_head, _handle_options
import emberjson


struct Session(Movable):
    """A Session object to manage and persist settings across multiple HTTP requests."""
    var easy: Easy
    """Wraps a libcurl easy handle, which is used to configure and perform HTTP requests."""
    var allow_redirects: Bool
    """Indicates whether the session should automatically follow HTTP redirects."""
    var headers: Dict[String, String]
    """Default headers to include in every request made with this session."""
    var verbose: Bool
    """Indicates whether libcurl's verbose logging mode is enabled for this session."""

    comptime DEFAULT_HEADERS = {
        "User-Agent": "floki/0.3.2",
    }
    """Default headers that are included in every request made with this session, unless overridden by request-specific headers."""

    def __init__(
        out self,
        allow_redirects: Bool = True,
        var headers: Dict[String, String] = {},
        verbose: Bool = False,
    ) raises:
        """Initialize a new Session.
        
        Args:
            allow_redirects: Whether to follow HTTP redirects automatically.
            headers: Default headers to include in requests.
            verbose: If True, enables libcurl's verbose logging mode for debugging.
        
        Raises:
            Error: If there is a failure in initializing the libcurl easy handle or setting options.
        """
        self.easy = Easy()
        self.allow_redirects = allow_redirects
        self.headers = materialize[Self.DEFAULT_HEADERS]()
        self.headers.update(headers)
        self.verbose = verbose
        if self.allow_redirects:
            self.raise_if_error(self.easy.follow_location(), "Failed to set follow location to enable redirects: ")
        if self.verbose:
            self.raise_if_error(self.easy.verbose(), "Failed to set libcurl verbose mode: ")

    def raise_if_error(self, code: Result, message: StringSlice) raises:
        """Raises an error if the libcurl result code indicates failure.

        Args:
            code: The libcurl result code to check.
            message: The error message prefix to use if the code indicates failure.
        
        Raises:
            Error: If the code does not indicate success, with a message describing the error.
        """
        if code != Result.OK:
            raise Error(message, self.easy.describe_error(code))

    def send[origin: ImmutOrigin, //, method: RequestMethod](
        self,
        mut url: String,
        headers: Dict[String, String],
        data: RequestData[origin],
        timeout: Optional[Int] = None,
        query_parameters: Dict[String, String] = {},
    ) raises -> Response:
        """Sends an HTTP request and returns the corresponding response.

        Parameters:
            origin: The origin of the request data.
            method: The HTTP method to use for the request.

        Args:
            url: The URL to which the request is sent.
            headers: A dictionary of HTTP headers to include in the request.
            data: An optional `RequestData` variant representing the request body.
            timeout: An optional timeout in seconds for the request.
            query_parameters: An optional dictionary of query parameters to include in the URL. GET requests only.

        Returns:
            The received response as an `Response` object.

        Raises:
            Error: If there is a failure in sending or receiving the message.
        """
        try:
            # Set the url
            if query_parameters:
                # URL-encode the parameter values
                # TODO: This is inefficient w/ string copies, but it's ok for now. I'm not sure if we can get mutable
                # references to the values in the dictionary as we iterate rn.
                var params: List[String] = [
                    String(t"{self.easy.escape(pair.key)}={self.easy.escape(pair.value)}")
                    for pair in query_parameters.items()
                ]
   
                # Append the query parameters to the URL.
                var full_url = String(t"{url}?{'&'.join(params)}")
                self.raise_if_error(self.easy.url(full_url), "Failed to set URL with query parameters: ")
            else:
                self.raise_if_error(self.easy.url(url), "Failed to set URL: ")

            # Set the buffer to load the response into
            var response_body = List[Byte](capacity=8192)
            self.raise_if_error(
                self.easy.write_data(UnsafePointer(to=response_body).bitcast[NoneType]()),
                "Failed to set write data: ",
            )

            # Set the write callback to load the response data into the above buffer.
            self.raise_if_error(self.easy.write_function(write_callback), "Failed to set write function: ")

            # Set method specific curl options
            comptime if method == RequestMethod.POST:
                if data.isa[Span[Byte, origin]]():
                    _handle_post(self.easy, data[Span[Byte, origin]])
                else:
                    _handle_post(self.easy, data[Pointer[FileHandle, origin]])
            elif method == RequestMethod.PUT:
                if data.isa[Span[Byte, origin]]():
                    _handle_put(self.easy, data[Span[Byte, origin]])
                else:
                    _handle_put(self.easy, data[Pointer[FileHandle, origin]])
            elif method == RequestMethod.DELETE:
                _handle_delete(self.easy)
            elif method == RequestMethod.PATCH:
                if data.isa[Span[Byte, origin]]():
                    _handle_patch(self.easy, data[Span[Byte, origin]])
                else:
                    _handle_patch(self.easy, data[Pointer[FileHandle, origin]])
            elif method == RequestMethod.HEAD:
                _handle_head(self.easy)
            elif method == RequestMethod.OPTIONS:
                _handle_options(self.easy)

            if timeout:
                self.raise_if_error(self.easy.timeout(timeout.value()), "Failed to set timeout: ")

            var header_list = CurlList(headers)
            try:
                # If there's any headers set on the session, add them too.
                # but only if they aren't already set in the request-specific headers, since those should take precedence.
                for header in self.headers.items():
                    if header.key not in headers:
                        header_list.append(String(t"{header.key}: {header.value}"))
        
                # Set headers
                self.raise_if_error(self.easy.http_headers(header_list), "Failed to set HTTP headers: ")

                # Enable the cookie engine
                self.raise_if_error(self.easy.cookie_file(), "Failed to enable cookie engine: ")

                # Perform the transfer
                self.raise_if_error(self.easy.perform(), "Failed to perform the request: ")
            finally:
                header_list^.free() # Free headers after performing the request.
            
            return Response(
                body=response_body^,
                headers=self.easy.headers(),
                protocol=Protocol(self.easy.get_scheme()),
                status=Status(Int(self.easy.response_code())),
                cookies=CookieJar(self.easy.cookies()),
            )
        finally:
            self.easy.reset() # Reset the easy handle to clear any state for the next request.
            if self.allow_redirects:
                _ = self.easy.follow_location()
            if self.verbose:
                _ = self.easy.verbose()

    def get(
        self,
        var url: String,
        var headers: Dict[String, String] = {},
        query_parameters: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> Response:
        """Sends a GET request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            headers: HTTP headers to include in the request.
            query_parameters: Query parameters to include in the request.
            timeout: An optional timeout in seconds for the request.

        Returns:
            The received response as an `Response` object.
        
        Raises:
            Error: If there is a failure in sending or receiving the message.
        
        #### Examples:
        ```mojo
        from floki.session import Session

        def main() raises:
            var session = Session()
            var r = session.get("https://httpbin.org/get")
        ```
        """
        return self.send[RequestMethod.GET](
            url=url,
            headers=headers^,
            timeout=timeout,
            data=RequestData(List[Byte]()),
            query_parameters=query_parameters,
        )

    def post(
        self,
        var url: String,
        var headers: Dict[String, String] = {},
        var data: emberjson.Object = {},
        timeout: Optional[Int] = None,
    ) raises -> Response:
        """Sends a POST request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            headers: HTTP headers to include in the request.
            data: The data to include in the body of the POST request.
            timeout: An optional timeout in seconds for the request.

        Returns:
            The received response as an `Response` object.
        
        Raises:
            Error: If there is a failure in sending or receiving the message.
        
        #### Examples:
        ```mojo
        from floki.session import Session

        def main() raises:
            var session = Session()
            var r = session.post("https://httpbin.org/post", data={"key": "value"})
        ```
        """
        var json_data = emberjson.to_string(data^).as_bytes()
        return self.send[RequestMethod.POST](
            url=url,
            headers=headers^,
            data=RequestData(json_data),
            timeout=timeout,
        )
    
    def post[T: AnyType & ImplicitlyDestructible, //](
        self,
        var url: String,
        data: T,
        var headers: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> Response:
        """Sends a POST request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the POST request.
            headers: HTTP headers to include in the request.
            timeout: An optional timeout in seconds for the request.

        Returns:
            The received response as an `Response` object.
        
        Raises:
            Error: If there is a failure in sending or receiving the message.
        
        #### Examples:
        ```mojo
        from floki.session import Session

        @fieldwise_init
        struct Point:
            var x: Int
            var y: Int

        def main() raises:
            var session = Session()
            var r = session.post("https://httpbin.org/post", data=Point(0, 1))
        ```
        """
        var json_data = emberjson.serialize(data)
        return self.send[RequestMethod.POST](
            url=url,
            headers=headers^,
            data=json_data.as_bytes(),
            timeout=timeout,
        )

    def post[origin: ImmutOrigin, //](
        self,
        var url: String,
        data: Span[Byte, origin],
        var headers: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> Response:
        """Sends a POST request to the specified URL.

        Parameters:
            origin: The origin of the data span.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the POST request.
            headers: HTTP headers to include in the request.
            timeout: An optional timeout in seconds for the request.

        Returns:
            The received response as an `Response` object.
        
        Raises:
            Error: If there is a failure in sending or receiving the message.
        
        #### Examples:
        ```mojo
        from floki.session import Session

        def main() raises:
            var session = Session()
            var r = session.post("https://httpbin.org/post", data="hello".as_bytes())
        ```
        """
        return self.send[RequestMethod.POST](
            url=url,
            headers=headers^,
            data=RequestData(data),
            timeout=timeout,
        )

    def post(
        self,
        var url: String,
        data: FileHandle,
        var headers: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> Response:
        """Sends a POST request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the POST request.
            headers: HTTP headers to include in the request.
            timeout: An optional timeout in seconds for the request.

        Returns:
            The received response as an `Response` object.
        
        Raises:
            Error: If there is a failure in sending or receiving the message.
        
        #### Examples:
        ```mojo
        from floki.session import Session

        def main() raises:
            var session = Session()
            with open("data.json", "r") as file:
                var r = session.post("https://httpbin.org/post", data=file)
        ```
        """
        return self.send[RequestMethod.POST](
            url=url,
            headers=headers^,
            data=RequestData(Pointer(to=data)),
            timeout=timeout,
        )

    def put(
        self,
        var url: String,
        var headers: Dict[String, String] = {},
        var data: emberjson.Object = {},
        timeout: Optional[Int] = None,
    ) raises -> Response:
        """Sends a PUT request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            headers: HTTP headers to include in the request.
            data: The data to include in the body of the PUT request.
            timeout: An optional timeout in seconds for the request.

        Returns:
            The received response as an `Response` object.
        
        Raises:
            Error: If there is a failure in sending or receiving the message.
        
        #### Examples:
        ```mojo
        from floki.session import Session

        def main() raises:
            var session = Session()
            var r = session.put("https://httpbin.org/put", data={"key": "value"})
        ```
        """
        var json_data = emberjson.to_string(data^).as_bytes()
        return self.send[RequestMethod.PUT](
            url=url,
            headers=headers^,
            data=json_data,
            timeout=timeout,
        )

    def put[T: AnyType & ImplicitlyDestructible, //](
        self,
        var url: String,
        data: T,
        var headers: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> Response:
        """Sends a PUT request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the PUT request.
            headers: HTTP headers to include in the request.
            timeout: An optional timeout in seconds for the request.

        Returns:
            The received response as an `Response` object.
        
        Raises:
            Error: If there is a failure in sending or receiving the message.
        
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
        return self.send[RequestMethod.PUT](
            url=url,
            headers=headers^,
            data=json_data.as_bytes(),
            timeout=timeout,
        )

    def put[origin: ImmutOrigin, //](
        self,
        var url: String,
        data: Span[Byte, origin],
        var headers: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> Response:
        """Sends a PUT request to the specified URL.

        Parameters:
            origin: The origin of the data span.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the PUT request.
            headers: HTTP headers to include in the request.
            timeout: An optional timeout in seconds for the request.

        Returns:
            The received response as an `Response` object.
        
        Raises:
            Error: If there is a failure in sending or receiving the message.
        
        #### Examples:
        ```mojo
        from floki.session import Session

        def main() raises:
            var session = Session()
            var r = session.put("https://httpbin.org/put", data="hello".as_bytes())
        ```
        """
        return self.send[RequestMethod.PUT](
            url=url,
            headers=headers^,
            data=data,
            timeout=timeout,
        )

    def put(
        self,
        var url: String,
        data: FileHandle,
        var headers: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> Response:
        """Sends a PUT request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the PUT request.
            headers: HTTP headers to include in the request.
            timeout: An optional timeout in seconds for the request.

        Returns:
            The received response as an `Response` object.
        
        Raises:
            Error: If there is a failure in sending or receiving the message.
        
        #### Examples:
        ```mojo
        from floki.session import Session

        def main() raises:
            var session = Session()
            with open("data.json", "r") as file:
                var r = session.put("https://httpbin.org/put", data=file)
        ```
        """
        return self.send[RequestMethod.PUT](
            url=url,
            headers=headers^,
            data=Pointer(to=data),
            timeout=timeout,
        )

    def delete(
        self,
        var url: String,
        var headers: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> Response:
        """Sends a DELETE request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            headers: HTTP headers to include in the request.
            timeout: An optional timeout in seconds for the request.

        Returns:
            The received response as an `Response` object.
        
        Raises:
            Error: If there is a failure in sending or receiving the message.
        
        #### Examples:
        ```mojo
        from floki.session import Session

        def main() raises:
            var session = Session()
            var r = session.delete("https://httpbin.org/delete")
        ```
        """
        return self.send[RequestMethod.DELETE](
            url=url,
            headers=headers^,
            data=RequestData(List[Byte]()),
            timeout=timeout,
        )

    def patch(
        self,
        var url: String,
        var headers: Dict[String, String] = {},
        var data: emberjson.Object = {},
        timeout: Optional[Int] = None,
    ) raises -> Response:
        """Sends a PATCH request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            headers: HTTP headers to include in the request.
            data: The data to include in the body of the PATCH request.
            timeout: An optional timeout in seconds for the request.

        Returns:
            The received response as an `Response` object.
        
        Raises:
            Error: If there is a failure in sending or receiving the message.
        
        #### Examples:
        ```mojo
        from floki.session import Session

        def main() raises:
            var session = Session()
            var r = session.patch("https://httpbin.org/patch", data={"key": "value"})
        ```
        """
        var json_data = emberjson.to_string(data^).as_bytes()
        return self.send[RequestMethod.PATCH](
            url=url,
            headers=headers^,
            data=json_data,
            timeout=timeout,
        )
    
    def patch[T: AnyType & ImplicitlyDestructible, //](
        self,
        var url: String,
        data: T,
        var headers: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> Response:
        """Sends a PATCH request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the PATCH request.
            headers: HTTP headers to include in the request.
            timeout: An optional timeout in seconds for the request.

        Returns:
            The received response as an `Response` object.
        
        Raises:
            Error: If there is a failure in sending or receiving the message.
        
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
        return self.send[RequestMethod.PATCH](
            url=url,
            headers=headers^,
            data=json_data.as_bytes(),
            timeout=timeout,
        )

    def patch[origin: ImmutOrigin, //](
        self,
        var url: String,
        data: Span[Byte, origin],
        var headers: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> Response:
        """Sends a PATCH request to the specified URL.

        Parameters:
            origin: The origin of the data span.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the PATCH request.
            headers: HTTP headers to include in the request.
            timeout: An optional timeout in seconds for the request.

        Returns:
            The received response as an `Response` object.
        
        Raises:
            Error: If there is a failure in sending or receiving the message.
        
        #### Examples:
        ```mojo
        from floki.session import Session

        def main() raises:
            var session = Session()
            var r = session.patch("https://httpbin.org/patch", data="hello".as_bytes())
        ```
        """
        return self.send[RequestMethod.PATCH](
            url=url,
            headers=headers^,
            data=data,
            timeout=timeout,
        )

    def patch(
        self,
        var url: String,
        data: FileHandle,
        var headers: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> Response:
        """Sends a PATCH request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the PATCH request.
            headers: HTTP headers to include in the request.
            timeout: An optional timeout in seconds for the request.

        Returns:
            The received response as an `Response` object.
        
        Raises:
            Error: If there is a failure in sending or receiving the message.
        
        #### Examples:
        ```mojo
        from floki.session import Session

        def main() raises:
            var session = Session()
            with open("data.json", "r") as file:
                var r = session.patch("https://httpbin.org/patch", data=file)
        ```
        """
        return self.send[RequestMethod.PATCH](
            url=url,
            headers=headers^,
            data=Pointer(to=data),
            timeout=timeout,
        )

    def head(
        self,
        var url: String,
        var headers: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> Response:
        """Sends a HEAD request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            headers: HTTP headers to include in the request.
            timeout: An optional timeout in seconds for the request.

        Returns:
            The received response as an `Response` object.
        
        Raises:
            Error: If there is a failure in sending or receiving the message.
        
        #### Examples:
        ```mojo
        from floki.session import Session

        def main() raises:
            var session = Session()
            var r = session.head("https://httpbin.org/get")
        ```
        """
        return self.send[RequestMethod.HEAD](
            url=url,
            headers=headers^,
            data=RequestData(List[Byte]()),
            timeout=timeout,
        )

    def options(
        self,
        var url: String,
        var headers: Dict[String, String] = {},
        timeout: Optional[Int] = None,
    ) raises -> Response:
        """Sends an OPTIONS request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            headers: HTTP headers to include in the request.
            timeout: An optional timeout in seconds for the request.

        Returns:
            The received response as an `Response` object.
        
        Raises:
            Error: If there is a failure in sending or receiving the message.
        
        #### Examples:
        ```mojo
        from floki.session import Session

        def main() raises:
            var session = Session()
            var r = session.options("https://httpbin.org/get")
        ```
        """
        return self.send[RequestMethod.OPTIONS](
            url=url,
            headers=headers^,
            data=RequestData(List[Byte]()),
            timeout=timeout,
        )
