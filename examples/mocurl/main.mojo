from prism import Command

from floki import Session


def main() raises:
    var session = Session()
    var response = session.get("http://localhost:8080/")
    print(response.as_text())
