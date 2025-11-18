from floki.session import Session, TCPConnection
from floki.header import Headers, Header
import emberjson


@fieldwise_init
struct Todo(Writable):
    var done: Bool
    var due: String
    var task: String

    fn write_to[W: Writer, //](self, mut writer: W):
        """Writes the Todo to a writer."""
        writer.write("Task: " + self.task + "\n")
        writer.write("Done: " + String(self.done) + "\n")
        writer.write("Due: " + self.due + "\n")


fn main() raises -> None:
    var client = Session[TCPConnection]()
    var response = client.get("http://localhost:3000/todos")
    print("GET Response Status Code:", response.status_code)

    var parser = emberjson.Parser(StringSlice(unsafe_from_utf8=response.body.body))
    var body = parser.parse()

    if body.is_array():
        for value in body.array():
            if value.is_object():
                # Assuming the object has the fields 'done', 'due', and 'task'
                var item = value.object()
                print(Todo(done=Bool(item["done"]), due=String(item["due"]), task=String(item["task"])))

    # print(String(response.body.as_string_slice()))
    # for pair in response.body.as_dict().items():
    #     print(pair.key, ":", pair.value)
