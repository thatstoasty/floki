import floki
from floki.forms import FormData

def main() raises -> None:
    # # JSON body (Content-Type: application/json)
    # var r = floki.post("https://httpbin.org/post", data={"key": "value"})

    # # Form-encoded body (Content-Type: application/x-www-form-urlencoded)
    # var r2 = floki.post("https://httpbin.org/post", data=FormData({"key": "value"}))

    # Bytes body (Content-Type: application/octet-stream)
    var r3 = floki.post("https://httpbin.org/post", data="raw bytes".as_bytes())
    print(r3.as_text())
