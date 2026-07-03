from floki import Session
from prism import Command

def main() raises:
    var session = Session()
    var response = session.get("http://localhost:8080/")
    print(response.as_text())

