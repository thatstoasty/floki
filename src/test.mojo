from floki.session import Session, TCPConnection

fn test_http_request(mut client: Session[TCPConnection]) raises -> None:
    # var response = client.get(
    #     "https://jsonplaceholder.typicode.com/todos/1",
    #     {"Content-Type": "application/json"}
    # )

    # # print status code
    # print("Status Code:", response.status_code)
    # print("Headers:")
    # print(response.headers)
    # print("Is connection set to connection-close? ", response.connection_close())

    # # print body
    # for pair in response.body.as_dict().items():
    #     print(pair.key, ":", pair.value)

    response = client.post(
        "http://jsonplaceholder.typicode.com/todos",
        {"Content-Type": "application/json"},
        data={"key1": "value1", "key2": "value2"},
    )
    print("POST Response Status Code:", response.status_code)
    for pair in response.body.as_dict().items():
        print(pair.key, ":", pair.value)


fn test_https_request(mut client: Session) raises -> None:
    # var response = client.get(
    #     "https://jsonplaceholder.typicode.com/todos/1",
    #     {"Content-Type": "application/json"}
    # )

    # # print status code
    # print("Status Code:", response.status_code)
    # print("Headers:")
    # print(response.headers)
    # print("Is connection set to connection-close? ", response.connection_close())

    # # print body
    # for pair in response.body.as_dict().items():
    #     print(pair.key, ":", pair.value)

    response = client.post(
        "https://jsonplaceholder.typicode.com/todos",
        {"Content-Type": "application/json"},
        data={"key1": "value1", "key2": "value2"},
    )
    print("POST Response Status Code:", response.status_code)
    for pair in response.body.as_dict().items():
        print(pair.key, ":", pair.value)


fn main() -> None:
    try:
        var client = Session()
        test_https_request(client)
        var insecure_client = Session[TCPConnection]()
        test_http_request(insecure_client)
    except e:
        print(e)
