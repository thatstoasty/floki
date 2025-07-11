# floki

![Mojo 25.4](https://img.shields.io/badge/Mojo%F0%9F%94%A5-25.4-purple)

A barebones HTTP/1.1 client for Mojo using only Mojo and external C calls.

Please check out the `src/test.mojo` for an example of how to use the client for now. I will add documentation later.

```mojo
from floki.session import Session, TCPConnection

fn main() raises -> None:
    var client = Session()
    var response = client.post(
        "http://jsonplaceholder.typicode.com/todos",
        {"Content-Type": "application/json"},
        data={"key1": "value1", "key2": "value2"},
    )
    print("POST Response Status Code:", response.status_code)
    for pair in response.body.as_dict().items():
        print(pair.key, ":", pair.value)
```
