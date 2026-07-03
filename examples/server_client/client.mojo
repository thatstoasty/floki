from floki import Session


def main() raises:
    var session = Session()
    var response = session.get("localhost:8080/")
    print(response.as_text())

    response = session.get("localhost:8080/hi/Floki")
    print(response.as_text())

    response = session.get("localhost:8080/health")
    print(response.as_text())
