from floki import Session


def main() raises:
    var session = Session()
    var response = session.get("localhost:8080/users/1")
    print(response.as_text())
