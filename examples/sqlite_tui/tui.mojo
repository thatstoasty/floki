"""Looks up a user by id, through the todo server.

Type an id and press enter: the floki session asks the server for
`/users/{id}` and the result is shown below the input. Only digits can be
typed, since the server parses the id as an integer.

Run the server first (`mojo server.mojo`), then this.

The request runs inside `update`, so the interface waits on it. Against a
server on this machine that is a few milliseconds; the session's timeout bounds
it when the server is down. Moving it off the loop would mean running it as a
background task, and the runtime's mailbox carries a single `Int`, once -- not
a user record, and not a request per keypress.
"""

import mog
from banjo.app import Program, Runtime
from banjo.components.help import HelpView
from banjo.components.key import Binding, Help
from banjo.components.text_input import TextInput
from emberjson import Value, from_json
from floki.timeout import Timeout
from mog import Profile
from std.utils.variant import Variant
from termctl.event.event import Char, Enter, Esc, Event, KeyEvent, KeyModifiers
from termctl.multiplex import DefaultSelector

from floki import Session


comptime RENDER_HZ = 60.0
"""The ceiling on repaints."""
comptime SERVER = "localhost:8080"
"""Where `server.mojo` listens."""

comptime TITLE = mog.Style(Profile.ANSI).bold().foreground(mog.Color(5))
"""The heading."""
comptime LABEL = mog.Style(Profile.ANSI).foreground(mog.Color(8))
"""Field names in the result."""
comptime CARD = mog.Style(Profile.ANSI, border=mog.ROUNDED_BORDER, padding=mog.Padding(1, 0)).border_foreground(
    mog.Color(8)
)
"""The box a found user is drawn in."""
comptime PROBLEM = mog.Style(Profile.ANSI, width=74, padding=mog.Padding(2, 0)).foreground(mog.Color(1))
"""Anything that went wrong. Wrapped, since a transport error can be long."""
comptime HINT = mog.Style(Profile.ANSI).foreground(mog.Color(8))
"""Guidance before the first lookup."""
comptime APP = mog.Style(Profile.ANSI, border=mog.ROUNDED_BORDER, padding=mog.Padding(1))


@fieldwise_init
struct Msg(ImplicitlyCopyable):
    """Everything this app can be told."""

    var value: Variant[KeyEvent]

    def isa[T: Copyable](self) -> Bool:
        return self.value.isa[T]()

    def __getitem_param__[T: Copyable](ref self) -> ref[origin_of(self.value)._get_owned_interior["value"]] T:
        return self.value[T]


@fieldwise_init
struct User(Copyable):
    """A user, as the server describes one."""

    var id: Int
    var name: String
    var email: String


def _is_digit(key: KeyEvent) -> Bool:
    """Whether a key types a decimal digit.

    Args:
        key: The key that was pressed.

    Returns:
        True for `0` through `9` with no modifier held.
    """
    if not key.code.isa[Char]() or key.modifiers != KeyModifiers.NONE:
        return False
    var codepoint = key.code[Char].char.to_u32()
    return codepoint >= UInt32(ord("0")) and codepoint <= UInt32(ord("9"))


struct Model(Program):
    comptime Msg = Msg

    var session: Session
    """Makes the requests. Kept for the app's lifetime, so connections are reused."""
    var input: TextInput
    """Where the id is typed."""
    var user: Optional[User]
    """The last user found, if the last lookup found one."""
    var problem: String
    """Why the last lookup found nobody, if it did not."""
    var help: HelpView
    """Renders the key bindings."""
    var bindings: List[Binding]
    """What the help view describes."""
    var done: Bool

    def __init__(out self) raises:
        # Bounded, because the request blocks the interface until it returns.
        self.session = Session(timeout=Timeout(connect=2.0, total=5.0))

        self.input = TextInput()
        self.input.prompt = "  user id > "
        self.input.placeholder = "a number, e.g. 1"
        self.input.styles_prompt = mog.Style(Profile.ANSI).foreground(mog.Color(5))
        self.input.styles_placeholder = HINT.copy()

        self.user = None
        self.problem = String()
        self.help = HelpView(width=76)
        self.bindings = [
            Binding(keys=[Enter()], help=Help("enter", "look up")),
            self.input.keymap.backspace.copy(),
            Binding(keys=[Esc()], help=Help("esc", "quit")),
        ]
        self.done = False

    @staticmethod
    def on_event(event: Event) raises -> Optional[Msg]:
        if not event.isa[KeyEvent]():
            return None
        return Msg(event[KeyEvent])

    def on_tick(mut self, tag: Int) raises -> Optional[Msg]:
        return None

    def on_result(mut self, value: Int) raises -> Optional[Msg]:
        return None

    def update(mut self, msg: Msg) raises -> Optional[Msg]:
        if not msg.isa[KeyEvent]():
            return None

        var key = msg[KeyEvent]
        if key.code.isa[Esc]():
            self.done = True
            return None

        if key.code.isa[Enter]():
            self._look_up()
            return None

        # Only digits are typed. Anything else would reach the server as an id
        # it cannot parse, so it is refused here. Editing keys still reach the
        # input, since they are not characters.
        if key.code.isa[Char]() and not _is_digit(key) and key.modifiers == KeyModifiers.NONE:
            return None

        _ = self.input.update(key)
        return None

    def _look_up(mut self):
        """Fetches the user whose id is typed, and records what came back."""
        self.user = None
        if self.input.value.byte_length() == 0:
            self.problem = "Type a user id first."
            return

        var id = self.input.value.copy()
        try:
            var response = self.session.get(String(SERVER, "/users/", id))
            if not response:
                self.problem = String("No user with id ", id, ". The server answered ", response.status.code, ".")
                return

            try:
                var json = from_json[Value](response.as_text())
                self.user = User(
                    Int(json["id"].int()),
                    json["name"].string().copy(),
                    json["email"].string().copy(),
                )
                self.problem = String()
            except:
                self.problem = String("The server's reply for id ", id, " was not a user.")
        except e:
            self.problem = String("Could not reach the server at ", SERVER, ". Is it running? (", e, ")")

    def view(self) raises -> String:
        var out = String(TITLE.render("User lookup"), "\n\n", self.input.view(), "\n\n")

        if self.user:
            ref user = self.user.value()
            out.write(
                CARD.render(
                    String(
                        LABEL.render("id   "),
                        "  ",
                        user.id,
                        "\n",
                        LABEL.render("name "),
                        "  ",
                        user.name,
                        "\n",
                        LABEL.render("email"),
                        "  ",
                        user.email,
                    )
                )
            )
        elif self.problem.byte_length() > 0:
            out.write(PROBLEM.render(self.problem))

        out.write("\n\n", HINT.render(self.help.short_view(self.bindings)))
        return APP.render(out)

    def is_done(self) -> Bool:
        return self.done


def main() raises:
    var model = Model()
    var rt = Runtime[Model](DefaultSelector(), RENDER_HZ)
    rt.run(model)
