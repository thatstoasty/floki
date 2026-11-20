# The Joy of Mojo: A Python Programmer’s Perspective

What makes code _feel_ satisfying to write?

Is it the ability to express exact control over data? Or perhaps writing or consuming an intuitively designed API?

In this post, I’ll be discussing my experience developing an HTTP client package as part of Modular’s Community Grant program!

## Where this project came from

I first started using Mojo 🔥 in 2024. I was looking to pick up another language; preferably a systems programming language to expand the toolbelt, as Python has its limitations. Around that time, I started hearing about Mojo; a systems programming language with Pythonic syntax and Python interoperability. Perfect.

So, what’s the first thing you do when you try out a new language? That’s right, spin up an HTTP server and send some requests. I’m already familiar with the `requests` Python library, so let's try it out using the Python interop. feature.

```mojo
from std.python import Python

def main() raises:
   var requests = Python.import_module("requests")
   var response = requests.get("https://catfact.ninja/fact")
   var body = response.json()
   if response.status_code != 200:
       print(body)
       raise Error("Request failed!")
  
   print(body["fact"])
```

Okay, not bad, but what about doing this in pure Mojo? Surely there must be a library for this already (he says about a brand new programming language). As you can already imagine, there was not. Not long after that, a fledgling HTTP framework named `lightbug_http` popped up in the ecosystem. I reached out to the developer that created it and offered to help out as a primary maintainer.

Eventually life happened, and lightbug was archived. It was an educational experience, but it also revealed the veritable depth of complexity when it comes to this domain of software. Instead of re-implementing everything, why not build on one of the most thoroughly tested pieces of software out there?

## Building Floki: A libcurl powered HTTP client

`Floki` is a Mojo package that provides an HTTP client powered by `libcurl`, with an API similar to Python’s `Requests` library. Libcurl is a free, open-source C library for transferring data over networks using URL syntax. It powers the `curl` command-line tool, and Floki too!

## How it works

### Establishing the foundation via C FFI

In order to make this work we make use of Mojo’s feature that enables you to dynamically load shared C libraries at runtime. Mojo provides a convenient wrapper struct named `OwnedDLHandle` that manages opening and closing the library handle. Knowing `libcurl` will be loaded, let’s create a more purpose-built user interface for calling the functions it provides.

```mojo
from std.ffi import OwnedDLHandle, RTLD, c_int, c_long

comptime CURLcode = c_int

@fieldwise_init
struct curl(Movable):
   var handle: OwnedDLHandle

   def __init__(out self) raises:
       self.handle = OwnedDLHandle("/path/to/libcurl.so", RTLD.LAZY)

   def curl_global_init(self, flags: c_long) raises -> CURLcode:
       return self.handle.get_function[CURLcode]("curl_global_init")(flags)
```

For the sake of brevity, I’ve pared down the actual implementation. The wrapper struct handles ownership of the handle, and provides methods for users to call `libcurl` functions through.

However, it’s not enough to just be able to call the functions. We need to ensure we’re passing the correct data. It can be confusing to remember what C types map to Mojo types, but thankfully the standard library’s FFI module comes with most of the type aliases you’ll need! The project makes heavy use of them, as well as our own type aliases for the various `libcurl` types.

```mojo
from std.ffi import OwnedDLHandle, RTLD, c_int, c_long

# Type aliases for curl
comptime CURL = MutExternalPointer[NoneType]
"""Opaque pointer type for CURL easy handles."""
comptime CURLcode = c_int
"""Type alias for CURL result codes."""
# ...more type aliases for other types
```

When a Mojo program using the package calls any functions that require `libcurl`, an instance of the FFI wrapper `curl` struct defined above is created and stored globally for reuse. Callers use the `curl_ffi` function to get a pointer to the FFI wrapper, and then call the functions they need. From here, more specialized structs are built on top of the FFI wrapper to provide a more user-friendly interface for making HTTP requests. For example, Floki exclusively uses `libcurl’s` `Easy` interface for synchronous internet transfers, so I included a Mojo interface to guarantee proper resource management using Linear Types. If an Easy handle is opened, it __must__ be explicitly closed to free the resources.

```mojo
from mojo_curl.c import curl_ffi, CURL

@explicit_destroy("The easy handle must be explicitly destroyed by calling `close()` to free resources.")
struct Easy(Deinitable where False, Movable):
   var easy: CURL

   def __init__(out self) raises:
       self.easy = curl_ffi()[].easy_init()

   def close(deinit self):
       curl_ffi()[].easy_cleanup(self.easy)
    
    # the rest of the methods for setting options, performing requests, etc.
```

With this, we have everything we need to link against `libcurl`, configure it, and start performing HTTP requests!

All of the FFI bindings are available separate from Floki as their own package named [mojo-curl](https://github.com/thatstoasty/mojo-curl).

### Floki: A human-friendly web request client

<Image showing it’s built on mojo-curl, mojo_datetime, emberjson>

Designed with a human friendly API in mind, taking inspiration from Python’s `requests` library.

- All standard HTTP methods: `get`, `post`, `put`, `patch`, `delete`, `head`, and `options`.
- One-shot free functions (`floki.get(...)`) or a reusable `Session` that persists configuration across requests.
- Request bodies from JSON, form-encoded data, raw bytes, files, or your own structs.
- Authentication helpers (Basic, Bearer) plus a pluggable `Auth` trait for custom schemes.
- Query parameters, custom headers, and automatic redirect handling.
- Cookie parsing and a cookie jar.
- Ergonomic responses: status-class checks, body as text/bytes/typed or dynamic JSON, and case-insensitive headers.
- Session-level timeout, retry-with-backoff, proxy, and TLS verification controls.

### Floki in action

#### HTTP Methods

Every HTTP method is available both as a free function and as a `Session` method:

TODO: Include terminal gifs for the examples?

```mojo
import floki
from floki.session import Session

def main() raises -> None:
    var r = floki.get("https://httpbin.org/get")

    var session = Session()
    var r2 = session.delete("https://httpbin.org/delete")
```

#### Request bodies: JSON, forms, and more

Pass a dictionary literal to send JSON, or wrap it in `FormData` for
`application/x-www-form-urlencoded`:

```mojo
import floki
from floki.forms import FormData

def main() raises -> None:
    # JSON body (Content-Type: application/json)
    var r = floki.post("https://httpbin.org/post", data={"key": "value"})

    # Form-encoded body (Content-Type: application/x-www-form-urlencoded)
    var r2 = floki.post("https://httpbin.org/post", data=FormData({"key": "value"}))
```

Raw bytes, file handles, and arbitrary `Writable` structs can also be sent as the body.

#### Working with responses

A `Response` exposes the status, headers, and body, with convenience accessors for
the common cases:

```mojo
import floki

def main() raises -> None:
    var r = floki.get("https://httpbin.org/get")

    # Status checks by class (1xx-5xx), plus the exact `is_ok` (200 only).
    if r.is_success():        # any 2xx
        print(r.status.code, r.reason())
    if r.is_client_error() or r.is_server_error():
        r.raise_for_status()  # raises HTTPError on a non-2xx response

    # Body as text, raw bytes, or JSON.
    print(r.as_text())                    # StringSpan over the body
    var data = r.as_json()                # dynamic JSON, e.g. data["url"]

    # Headers are looked up case-insensitively.
    print(r.content_type())            # value of the Content-Type header
    print(r.header("x-request-id", "<none>"))
```

For typed JSON, deserialize straight into a struct with `r.as[T]()`:

```mojo
import floki

@fieldwise_init
struct Todo(Defaultable, Deinitable, Movable):
    var id: Int
    var title: String

    def __init__(out self):
        self.id = 0
        self.title = ""

def main() raises -> None:
    var r = floki.get("https://jsonplaceholder.typicode.com/todos/1")
    var todo = r.as[Todo]()
    print(todo.id, todo.title)
```

Small code snippets are great for a quick overview, but what about some practical examples? Check out these demonstrations of Floki being used with other packages I’ve created!

#### Minimal curl dupe

- [Minimal curl dupe]()

TODO: Explanation of what it does, and a GIF of it in action. Also citation link to the link to the example.

#### HTTP server and client

- [HTTP Server and Client]()

TODO: Explanation of what it does, and a GIF of it in action. Also citation link to the link to the example.

#### HTTP server and SQLite TUI client

- [SQLite TUI]()

TODO: Explanation of what it does, and a GIF of it in action. Also citation link to the link to the example.

## What was hard

Along the way, I ran into my fair share of issues when it comes to missing features or bugs. The real gap is the inability to call C variadic functions through DLHandle. While it does work for statically linked libraries, it does not work for dynamically linked ones. The libcurl API makes heavy use of variadics unfortunately, which meant I needed to use a small shim C library to call the libcurl functions correctly. This makes Floki much less portable because it depends on linking two shared libraries instead of one now. Libcurl is generally available on most machines, but my shim library is not. It’s not an issue while running Mojo code in a Pixi managed environment where both libcurl and the shim are pulled into the Pixi environment, but for a compiled binary, it proves to be problematic.

The packaging story could also be better. I consider it part of the growing pains of a new ecosystem, but most Mojo projects won’t compile from across versions. And most projects depend on being built from source as a Git dependency, so this leads to fragmentation or an aversion to depending on someone else’s package being updated for the new Mojo version before working on mine. That being said, Modular does have improvements to the experience in mind, and I think we’ll be seeing improvements in the near future.

## My thoughts on Mojo

### Why Mojo feels good to write

Looping back around to the original question; what makes code feel satisfying to write?

I think it’s a combination of a few things. The language syntax, language design decisions, ability to express desired interfaces, and progressive disclosure of complexity all play a part in that.

#### The syntax

I find Pythonic syntax to look and feel cleaner than most languages. Every additional symbol or keyword adds cognitive load, and Mojo has done a good job of keeping that to a minimum. Mojo makes it possible to write code that is both concise, expressive, and performant.

Let's consider a hypothetical `HashMap` struct in Mojo and Rust. Is there really a big difference between `HashMap.new()` and `HashMap::new();`? In isolation, no. But when reading code in larger codebases, I do find that it makes it more challenging to reason about what I'm reading.

Now let's expand this to an arbitrary code example that generally expresses the same behavior in both languages. Both are quite readable, but Mojo has the slight edge when it comes to being able to discern the intent of the code at a glance in my opinion.

TODO: Side by side code example if possible?

```mojo
def main():
    var ages = {"alice": 30, "bob": 25, "carol": 35}

    for entry in ages.items():
        print(t"{entry.key}: {entry.value}")
```

```rust
use std::collections::HashMap;

fn main() {
    let ages = HashMap::from([("alice", 30), ("bob", 25), ("carol", 35)]);

    for (name, age) in &ages {
        println!("{name}: {age}");
    }
}
```

#### Language design decisions

One thing I'm always impressed by, is the how the language has evolved over time. The design decisions made by the team have been well thought out, and based on research, feedback, and experience. With each new release, it's clear that the foundational design philosophy enables intuitive composition of language features.

Compile-time programming is the the best example of this. It's a powerful feature that's _easy to reach for_, and _easy to use_ in Mojo. For example, what would it take to lift this code to run at compile time?

```mojo
def my_add(a: Int, b: Int) -> Int:
    return a + b + 1

def main():
    var result = my_add(1, 2)
    print(result)
```

Yes, we just slap a `comptime` keyword in front of the variable instead of `var`.

```mojo
def my_add(a: Int, b: Int) -> Int:
    return a + b + 1

def main():
    comptime result = my_add(1, 2)
    var runtime_result = my_add(1, 2)
    print(result, runtime_result)
```

And we can do the same with assertions, and loop unrolling as well! It's seamless switching between runtime and compile-time programming.

```mojo
comptime word = "Hello!"

def main():
    for char in word:
        print(char)
    
    comptime for char in word:
        comptime assert char != "!", "Excitement isn't allowed here." # code fails to compile due to failing the assertion
        print(char)
```

When all of the features of a language compose well, and are easy to reach for, it makes it easier to express the exact desired interfaces and contracts with users of your code. I often find myself wishing for certain aspects of Mojo when writing Python code, like Linear Type support and Origins. It frees up mental bandwidth for library authors like myself, and its consumers if the API contract can inform and enforce correct usage.

```mojo
@fieldwise_init
@explicit_destroy("The handle must be explicitly destroyed by calling `close()` to free resources.")
struct Handle(Deinitable where False, Movable):

   def close(deinit self):
        # Clean-up happens here
       ...
```

As the author, I know that if a `Handle` is opened, it __must__ be explicitly closed and don't need to worry about the fallout of a user not doing so. As a user, I don't have to worry about the lifecycle of the `Handle` once I've opened one because the compiler will enforce that it's closed correctly.

TODO: Origin example

#### Progressive disclosure of complexity

TODO: Content here

## What's next?

In the short term, I'd like to throw together a cookbook for common recipes and patterns for using Floki. Well written documentation is important, but  The project is open to contributions, and I'd love to hear ideas on how to improve it. Try it out, break it, stress test it, and let me know what gaps you find. It's challenging to account for all of the different use cases, so it helps in strengthening the soundness of Floki.

## Give it a try

Come join the party! I'm open to contributions on any of these Mojo projects.

- [Mojo-curl: Libcurl bindings](https://github.com/thatstoasty/mojo-curl)
- [Floki: HTTP Client](https://github.com/thatstoasty/floki)
- [Prism: CLI builder](https://github.com/thatstoasty/prism)
- [Mist: Terminal ANSI styling and color](https://github.com/thatstoasty/mist)
- [Mog: Terminal styling](https://github.com/thatstoasty/mog)
- [Stump: Structured logger](https://github.com/thatstoasty/stump)
- [Slight: SQLite bindings](https://github.com/thatstoasty/slight)

## About me

My name is Mikhail Tavarez, and I’ve been part of the Mojo community since 2024. I spend most of my days at work building internal data services and tooling for data engineers. I'm always down to chat about music, games, books, programming, and whatnot, so feel free to reach out! Thanks again to Modular for choosing my project for their grant program; it’s been an absolute pleasure to work alongside the team.
