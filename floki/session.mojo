"""HTTP Client."""
import emberjson
from floki.auth import Auth, NoAuth
from floki.body import Body
from floki.callbacks import read_callback, write_callback
from floki.cookie.cookie_jar import CookieJar
from floki.data import RequestData
from floki.forms import FormData
from floki.handlers import _handle_delete, _handle_head, _handle_options, _handle_patch, _handle_post, _handle_put
from floki.headers import Headers
from floki.http import RequestMethod
from floki.proxy import Proxy
from floki.response import Response
from floki.retry import Retry
from floki.timeout import Timeout
from floki.tls import TLS
from mojo_curl.easy import Easy, Result
from mojo_curl.list import CurlList
from std.pathlib import Path
from std.time import sleep
from std.utils import Variant


def _build_url_with_query(url: String, query_parameters: Dict[String, String], easy: Easy) raises -> String:
    """Builds a URL with query parameters appended.

    Args:
        url: The base URL to which query parameters will be appended.
        query_parameters: A dictionary of query parameters to append to the URL.
        easy: An instance of `Easy` used for URL encoding.

    Returns:
        The full URL with query parameters appended.

    Raises:
        Error: If there is a failure in URL encoding or setting the URL.
    """
    var full_url = String(t"{url}?")
    for i, pair in enumerate(query_parameters.items()):
        full_url.write(t"{easy.escape(pair.key)}={easy.escape(pair.value)}")
        if i != len(query_parameters) - 1:
            full_url.write("&")

    return full_url^


struct Session(Movable):
    """A Session object to manage and persist settings across multiple HTTP requests."""

    var easy: Easy
    """Wraps a libcurl easy handle, which is used to configure and perform HTTP requests."""
    var allow_redirects: Bool
    """Indicates whether the session should automatically follow HTTP redirects."""
    var headers: Headers
    """Default headers to include in every request made with this session."""
    var verbose: Bool
    """Indicates whether libcurl's verbose logging mode is enabled for this session."""
    var timeout: Timeout
    """Timeout configuration applied to every request made with this session."""
    var retry: Retry
    """Retry policy applied to every request made with this session."""
    var proxy: Proxy
    """Proxy configuration applied to every request made with this session."""
    var tls: TLS
    """TLS/SSL verification settings applied to every request made with this session."""

    comptime DEFAULT_HEADERS = {
        "User-Agent": "floki/0.3.3",
    }
    """Default headers that are included in every request made with this session, unless overridden by request-specific headers."""

    def __init__(
        out self,
        allow_redirects: Bool = True,
        var headers: Headers = Headers(),
        verbose: Bool = False,
        var timeout: Timeout = Timeout(),
        var retry: Retry = Retry(),
        var proxy: Proxy = Proxy(),
        var tls: TLS = TLS(),
    ) raises:
        """Initialize a new Session.

        Args:
            allow_redirects: Whether to follow HTTP redirects automatically.
            headers: Default headers to include in requests.
            verbose: If True, enables libcurl's verbose logging mode for debugging.
            timeout: Timeout configuration applied to every request made with this session.
            retry: Retry policy applied to every request made with this session.
            proxy: Proxy configuration applied to every request made with this session.
            tls: TLS/SSL verification settings applied to every request made with this session.

        Raises:
            Error: If there is a failure in initializing the libcurl easy handle or setting options.
        """
        self.easy = Easy()
        self.allow_redirects = allow_redirects
        self.headers = Headers(materialize[Self.DEFAULT_HEADERS]())
        self.headers.update(headers^)
        self.verbose = verbose
        self.timeout = timeout^
        self.retry = retry^
        self.proxy = proxy^
        self.tls = tls^
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

    def send[
        origin: ImmutOrigin, //, method: RequestMethod, A: Auth = NoAuth
    ](
        self,
        mut url: String,
        mut headers: Headers,
        data: RequestData[origin],
        query_parameters: Dict[String, String] = {},
        auth: Optional[A] = None,
    ) raises -> Response:
        """Sends an HTTP request and returns the corresponding response.

        The session's `timeout` and `retry` configuration is applied to the request.

        Parameters:
            origin: The origin of the request data.
            method: The HTTP method to use for the request.
            A: The concrete `Auth` scheme type, inferred from `auth`.

        Args:
            url: The URL to which the request is sent.
            headers: A dictionary of HTTP headers to include in the request.
            data: An optional `RequestData` variant representing the request body.
            query_parameters: An optional dictionary of query parameters to include in the URL. GET requests only.
            auth: An optional authentication scheme to apply to the request.

        Returns:
            The received response as a `Response` object.

        Raises:
            Error: If there is a failure in sending or receiving the message.
        """
        try:
            # Set the url
            if query_parameters:
                # Append the query parameters to the URL.
                var full_url = _build_url_with_query(url, query_parameters, self.easy)
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

            # Apply the session's timeout configuration. libcurl expects milliseconds.
            if self.timeout.connect:
                self.raise_if_error(
                    self.easy.connect_timeout(Int(self.timeout.connect.value() * 1000)),
                    "Failed to set connect timeout: ",
                )
            if self.timeout.total:
                self.raise_if_error(
                    self.easy.timeout(Int(self.timeout.total.value() * 1000)),
                    "Failed to set timeout: ",
                )

            # Apply the session's proxy configuration.
            if self.proxy:
                self.raise_if_error(self.easy.proxy(self.proxy.url.copy()), "Failed to set proxy: ")
                if self.proxy.username:
                    self.raise_if_error(
                        self.easy.proxy_username(self.proxy.username.value().copy()),
                        "Failed to set proxy username: ",
                    )
                if self.proxy.password:
                    self.raise_if_error(
                        self.easy.proxy_password(self.proxy.password.value().copy()),
                        "Failed to set proxy password: ",
                    )
                if self.proxy.no_proxy:
                    self.raise_if_error(
                        self.easy.no_proxy(self.proxy.no_proxy.value().copy()),
                        "Failed to set no_proxy: ",
                    )

            # Apply the session's TLS verification settings. Disabling verification
            # is dangerous and should only be used for testing or trusted networks.
            if not self.tls.verify:
                self.raise_if_error(
                    self.easy.ssl_verify_peer(verify=False), "Failed to disable TLS peer verification: "
                )
                self.raise_if_error(
                    self.easy.ssl_verify_host(verify=False), "Failed to disable TLS host verification: "
                )
            if self.tls.ca_bundle:
                self.raise_if_error(self.easy.cainfo(self.tls.ca_bundle.value()), "Failed to set TLS CA bundle: ")
            if self.tls.ca_path:
                self.raise_if_error(self.easy.capath(self.tls.ca_path.value()), "Failed to set TLS CA path: ")

            # Apply the authentication scheme, if one was provided. Headers already
            # present on the request take precedence over auth-supplied headers.
            if auth:
                auth.value().apply(headers)

            var header_list = CurlList(headers._inner)
            try:
                # If there's any headers set on the session, add them too.
                # but only if they aren't already set in the request-specific headers, since those should take precedence.
                for header in self.headers._inner.items():
                    if header.key not in headers:
                        header_list.append(String(t"{header.key}: {header.value}"))

                # Set headers
                self.raise_if_error(self.easy.http_headers(header_list), "Failed to set HTTP headers: ")

                # Enable the cookie engine
                self.raise_if_error(self.easy.cookie_file(), "Failed to enable cookie engine: ")

                # Perform the transfer, retrying per the session's retry policy on
                # transfer errors or retryable status codes.
                var attempt = 0
                while True:
                    response_body.clear()  # Discard any partial body from a previous attempt.
                    var perform_result = self.easy.perform()
                    var status_code = Int(self.easy.response_code()) if perform_result == Result.OK else 0
                    var should_retry = perform_result != Result.OK or self.retry.should_retry(status_code)
                    if should_retry and attempt < self.retry.max_retries:
                        attempt += 1
                        sleep(self.retry.backoff_time(attempt))
                        continue
                    self.raise_if_error(perform_result, "Failed to perform the request: ")
                    break
            finally:
                header_list^.free()  # Free headers after performing the request.

            return Response(
                body=response_body^,
                headers=self.easy.headers(),
                protocol=Protocol(self.easy.get_scheme()),
                status=Status(Int(self.easy.response_code())),
                cookies=CookieJar(self.easy.cookies()),
            )
        finally:
            self.easy.reset()  # Reset the easy handle to clear any state for the next request.
            if self.allow_redirects:
                _ = self.easy.follow_location()
            if self.verbose:
                _ = self.easy.verbose()

    def get[
        A: Auth = NoAuth, //
    ](
        self,
        var url: String,
        var headers: Headers = Headers(),
        query_parameters: Dict[String, String] = {},
        auth: Optional[A] = None,
    ) raises -> Response:
        """Sends a GET request to the specified URL.

        Parameters:
            A: The concrete `Auth` scheme type, inferred from `auth`.

        Args:
            url: The URL to which the request is sent.
            headers: HTTP headers to include in the request.
            query_parameters: Query parameters to include in the request.
            auth: An optional authentication scheme to apply to the request.

        Returns:
            The received response as a `Response` object.

        Raises:
            Error: If there is a failure in sending or receiving the message.

        #### Examples:
        ```mojo
        from floki.session import Session
        from floki.auth import BasicAuth

        def main() raises:
            var session = Session()
            var r = session.get("https://httpbin.org/get", auth=BasicAuth("user", "pass"))
        ```
        """
        return self.send[RequestMethod.GET](
            url=url,
            headers=headers,
            data=RequestData(List[Byte]()),
            query_parameters=query_parameters,
            auth=auth,
        )

    def post[
        A: Auth = NoAuth, //
    ](
        self,
        var url: String,
        var headers: Headers = Headers(),
        var data: emberjson.Object = {},
        auth: Optional[A] = None,
    ) raises -> Response:
        """Sends a POST request to the specified URL.

        Parameters:
            A: The concrete `Auth` scheme type, inferred from `auth`.

        Args:
            url: The URL to which the request is sent.
            headers: HTTP headers to include in the request.
            data: The data to include in the body of the POST request.
            auth: An optional authentication scheme to apply to the request.

        Returns:
            The received response as a `Response` object.

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
            headers=headers,
            data=RequestData(json_data),
            auth=auth,
        )

    def post[
        A: Auth = NoAuth, //
    ](
        self,
        var url: String,
        data: FormData,
        var headers: Headers = Headers(),
        auth: Optional[A] = None,
    ) raises -> Response:
        """Sends a POST request with `application/x-www-form-urlencoded` data to the specified URL.

        Parameters:
            A: The concrete `Auth` scheme type, inferred from `auth`.

        Args:
            url: The URL to which the request is sent.
            data: The form fields to include in the body of the POST request.
            headers: HTTP headers to include in the request.
            auth: An optional authentication scheme to apply to the request.

        Returns:
            The received response as a `Response` object.

        Raises:
            Error: If there is a failure in sending or receiving the message.

        #### Examples:
        ```mojo
        from floki.session import Session
        from floki.forms import FormData

        def main() raises:
            var session = Session()
            var r = session.post("https://httpbin.org/post", data=FormData({"key": "value"}))
        ```
        """
        if "Content-Type" not in headers:
            headers["Content-Type"] = "application/x-www-form-urlencoded"
        var encoded = data.encode()
        return self.send[RequestMethod.POST](
            url=url,
            headers=headers,
            data=RequestData(encoded.as_bytes()),
            auth=auth,
        )

    def post[
        T: AnyType & ImplicitlyDestructible, //
    ](self, var url: String, data: T, var headers: Headers = Headers(),) raises -> Response:
        """Sends a POST request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the POST request.
            headers: HTTP headers to include in the request.

        Returns:
            The received response as a `Response` object.

        Raises:
            Error: If there is a failure in sending or receiving the message.

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
        return self.send[RequestMethod.POST](
            url=url,
            headers=headers,
            data=json_data.as_bytes(),
        )

    def post[
        origin: ImmutOrigin, //
    ](self, var url: String, data: Span[Byte, origin], var headers: Headers = Headers(),) raises -> Response:
        """Sends a POST request to the specified URL.

        Parameters:
            origin: The origin of the data span.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the POST request.
            headers: HTTP headers to include in the request.

        Returns:
            The received response as a `Response` object.

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
            headers=headers,
            data=RequestData(data),
        )

    def post(
        self,
        var url: String,
        data: FileHandle,
        var headers: Headers = Headers(),
    ) raises -> Response:
        """Sends a POST request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the POST request.
            headers: HTTP headers to include in the request.

        Returns:
            The received response as a `Response` object.

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
            headers=headers,
            data=RequestData(Pointer(to=data)),
        )

    def put[
        A: Auth = NoAuth, //
    ](
        self,
        var url: String,
        var headers: Headers = Headers(),
        var data: emberjson.Object = {},
        auth: Optional[A] = None,
    ) raises -> Response:
        """Sends a PUT request to the specified URL.

        Parameters:
            A: The concrete `Auth` scheme type, inferred from `auth`.

        Args:
            url: The URL to which the request is sent.
            headers: HTTP headers to include in the request.
            data: The data to include in the body of the PUT request.
            auth: An optional authentication scheme to apply to the request.

        Returns:
            The received response as a `Response` object.

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
            headers=headers,
            data=json_data,
            auth=auth,
        )

    def put[
        T: AnyType & ImplicitlyDestructible, //
    ](self, var url: String, data: T, var headers: Headers = Headers(),) raises -> Response:
        """Sends a PUT request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the PUT request.
            headers: HTTP headers to include in the request.

        Returns:
            The received response as a `Response` object.

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
            headers=headers,
            data=json_data.as_bytes(),
        )

    def put[
        origin: ImmutOrigin, //
    ](self, var url: String, data: Span[Byte, origin], var headers: Headers = Headers(),) raises -> Response:
        """Sends a PUT request to the specified URL.

        Parameters:
            origin: The origin of the data span.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the PUT request.
            headers: HTTP headers to include in the request.

        Returns:
            The received response as a `Response` object.

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
            headers=headers,
            data=data,
        )

    def put(
        self,
        var url: String,
        data: FileHandle,
        var headers: Headers = Headers(),
    ) raises -> Response:
        """Sends a PUT request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the PUT request.
            headers: HTTP headers to include in the request.

        Returns:
            The received response as a `Response` object.

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
            headers=headers,
            data=Pointer(to=data),
        )

    def delete[
        A: Auth = NoAuth, //
    ](self, var url: String, var headers: Headers = Headers(), auth: Optional[A] = None,) raises -> Response:
        """Sends a DELETE request to the specified URL.

        Parameters:
            A: The concrete `Auth` scheme type, inferred from `auth`.

        Args:
            url: The URL to which the request is sent.
            headers: HTTP headers to include in the request.
            auth: An optional authentication scheme to apply to the request.

        Returns:
            The received response as a `Response` object.

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
            headers=headers,
            data=RequestData(List[Byte]()),
            auth=auth,
        )

    def patch[
        A: Auth = NoAuth, //
    ](
        self,
        var url: String,
        var headers: Headers = Headers(),
        var data: emberjson.Object = {},
        auth: Optional[A] = None,
    ) raises -> Response:
        """Sends a PATCH request to the specified URL.

        Parameters:
            A: The concrete `Auth` scheme type, inferred from `auth`.

        Args:
            url: The URL to which the request is sent.
            headers: HTTP headers to include in the request.
            data: The data to include in the body of the PATCH request.
            auth: An optional authentication scheme to apply to the request.

        Returns:
            The received response as a `Response` object.

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
            headers=headers,
            data=json_data,
            auth=auth,
        )

    def patch[
        T: AnyType & ImplicitlyDestructible, //
    ](self, var url: String, data: T, var headers: Headers = Headers(),) raises -> Response:
        """Sends a PATCH request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the PATCH request.
            headers: HTTP headers to include in the request.

        Returns:
            The received response as a `Response` object.

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
            headers=headers,
            data=json_data.as_bytes(),
        )

    def patch[
        origin: ImmutOrigin, //
    ](self, var url: String, data: Span[Byte, origin], var headers: Headers = Headers(),) raises -> Response:
        """Sends a PATCH request to the specified URL.

        Parameters:
            origin: The origin of the data span.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the PATCH request.
            headers: HTTP headers to include in the request.

        Returns:
            The received response as a `Response` object.

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
            headers=headers,
            data=data,
        )

    def patch(
        self,
        var url: String,
        data: FileHandle,
        var headers: Headers = Headers(),
    ) raises -> Response:
        """Sends a PATCH request to the specified URL.

        Args:
            url: The URL to which the request is sent.
            data: The data to include in the body of the PATCH request.
            headers: HTTP headers to include in the request.

        Returns:
            The received response as a `Response` object.

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
            headers=headers,
            data=Pointer(to=data),
        )

    def head[
        A: Auth = NoAuth, //
    ](self, var url: String, var headers: Headers = Headers(), auth: Optional[A] = None,) raises -> Response:
        """Sends a HEAD request to the specified URL.

        Parameters:
            A: The concrete `Auth` scheme type, inferred from `auth`.

        Args:
            url: The URL to which the request is sent.
            headers: HTTP headers to include in the request.
            auth: An optional authentication scheme to apply to the request.

        Returns:
            The received response as a `Response` object.

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
            headers=headers,
            data=RequestData(List[Byte]()),
            auth=auth,
        )

    def options[
        A: Auth = NoAuth, //
    ](self, var url: String, var headers: Headers = Headers(), auth: Optional[A] = None,) raises -> Response:
        """Sends an OPTIONS request to the specified URL.

        Parameters:
            A: The concrete `Auth` scheme type, inferred from `auth`.

        Args:
            url: The URL to which the request is sent.
            headers: HTTP headers to include in the request.
            auth: An optional authentication scheme to apply to the request.

        Returns:
            The received response as a `Response` object.

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
            headers=headers,
            data=RequestData(List[Byte]()),
            auth=auth,
        )
