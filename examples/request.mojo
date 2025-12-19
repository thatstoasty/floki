import floki
from floki import Status


fn main() raises -> None:
    # Make a Request
    var r = floki.get("https://api.github.com/events")
    r = floki.post("https://httpbin.org/post", data={"key": "value"})
    r = floki.put("https://httpbin.org/put", data={"key": "value"})
    r = floki.delete("https://httpbin.org/delete")
    r = floki.head("https://httpbin.org/get")
    r = floki.options("https://httpbin.org/get")

    # Passing Parameters In URLs
    var payload = {"key1": "value1", "key2": "value2"}
    r = floki.get("https://httpbin.org/get", query_parameters=payload)
    # print(r.url()) # TODO: Implement URL method to get the final URL with query parameters
    for header in r.headers.items():
        print(String(header.key, ": ", header.value))
    
    # Response Content
    r = floki.get("https://api.github.com/events")
    # print(r.body.as_string_slice())

    ## Get the raw bytes of the response body
    var bytes = r.body.as_bytes()
    # print(bytes.__str__())

    # JSON Response Content
    r = floki.get("https://api.github.com/events")
    print(r.body.as_json())

    # Custom Headers
    var url = "https://api.github.com/some/endpoint"
    r = floki.get(url, headers={"user-agent": "my-app/0.0.1"})

    # More complicated POST requests

    ## Form encoded data by default
    # TODO: Floki does not currently support converting dicts to form-encoded data
    # so you have to do it manually for now. This should be added as a feature in the future.
    # r = floki.post("https://httpbin.org/post", data={"key1": "value1", "key2": "value2"})
    r = floki.post("https://httpbin.org/post", data="key1=value1&key2=value2".as_bytes())
    print(r.body.as_string_slice())

    ## Send json data
    r = floki.post(
        "https://api.github.com/some/endpoint",
        headers={"Content-Type": "application/json"},
        data={"some": "data"}
    )

    # Response Status Codes
    r = floki.get('https://httpbin.org/get')
    print(r.status.code)
    print(Status.OK == r.status)
    # r.raise_for_status() # To raise if the response was an HTTP error

    