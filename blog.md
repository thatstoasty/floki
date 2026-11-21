# The Joy of Mojo: Building an HTTP Client

What makes code _feel_ satisfying to write?

Is it the ability to express exact control over data? Or perhaps writing or consuming an intuitively designed API?

In this post, I'll walk through building an HTTP client for Mojo, made possible by Modular's Community Grant program!

## Where this project came from

Back in 2024, I was looking to pick up another language; preferably a systems programming language to expand my toolbelt, as Python has its limitations. After a few months dabbling with Rust, Go, and Gleam, I started hearing of Mojo 🔥. It claimed to provide exactly what I was looking for: systems-level control with Pythonic syntax, _and_ Python interoperability. Perfect!

So, what's the first thing you do when you try out a new language? That's right, send some web requests and play around with the responses. I'm already familiar with the `requests` Python library, so let's try it out using the Python interoperability feature.

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

Okay, not bad, but what about doing this in pure Mojo? Surely there must be a library for this already (he says about a brand new programming language). As you can probably guess, there wasn't. Not long after that, a fledgling HTTP framework named `lightbug_http` popped up in the ecosystem. I reached out to the developer who created it and offered to help, and eventually became one of its primary maintainers.

Eventually life happened, and lightbug was archived. It was an educational experience, but it also showed me just how deep the rabbit hole goes when it comes to sending and serving HTTP requests. I took a break for a few months to work on some other projects for awhile, with the plan to come back around once Mojo had matured some more. When I came back around to the idea, I really didn't want to re-implement everything from first principles. So, I thought why not build on one of the most thoroughly tested pieces of software out there instead?

## Floki: A human-friendly web request client

Floki is a Mojo package that provides an HTTP client with an API that takes its cues from Python's `requests` library. If you've ever used the `curl` command-line tool, you've already used `libcurl`, a free, open-source C library for transferring data over networks using URL syntax. Now it powers Floki too!

Here's a few examples of Floki in action!

### HTTP Methods

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

### Request bodies: JSON, forms, and more

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

### Working with responses

A `Response` exposes familiar convenience accessors for commonly accessed data like status, headers, and body.

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

For typed JSON, you can deserialize straight into a struct with `r.as[T]()`:

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

Small code snippets are great for a quick overview, but what about some practical examples? Check out these demonstrations of Floki being used with other packages from the ecosystem, some of which I've created!

#### Minimal curl dupe

![Flurl GIF]()

- [Link to the project](https://github.com/thatstoasty/floki/tree/blog-examples/examples/flurl).

I used `Prism` to build a CLI interface to mirror a small slice of `curl`'s behavior using Floki to perform the web requests.

#### HTTP server and client

![Server Client GIF]()

- [Link to the project](https://github.com/thatstoasty/floki/tree/blog-examples/examples/server_client).

I used `flare` to create a small single web server serving hard-coded user data. Floki sends requests to the server and prints the response bodies.

#### HTTP server and SQLite TUI client

![SQLite TUI GIF]()

- [Link to the project](https://github.com/thatstoasty/floki/tree/blog-examples/examples/sqlite_tui).

I used `flare` to create a small single web server serving user data, along with `slight` to create and query a sqlite database. Floki sends requests to the server and prints the response bodies. The web client is presented via an interactive TUI built using `banjo`.

## How it works

### Establishing the foundation via C FFI

To make this work, Floki uses Mojo’s ability to dynamically load C shared libraries at runtime.. Mojo provides a convenient wrapper struct named `OwnedDLHandle` that manages opening and closing the library handle. Knowing `libcurl` will be loaded, let's create a more purpose-built interface for calling the functions it provides.

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

For the sake of brevity, I've pared down the actual implementation. The wrapper struct handles ownership of the handle, and exposes methods to call `libcurl` functions through.

However, it's not enough to just be able to call the functions. It's important to ensure that the the correct data is passed through. It can be confusing to remember which C types map to which Mojo types, but thankfully the standard library's FFI module comes with most of the type aliases you'll need! The project makes heavy use of them, as well as our own type aliases for the various `libcurl` types.

```mojo
from std.ffi import OwnedDLHandle, RTLD, c_int, c_long

# Type aliases for curl
comptime CURL = MutPointer[NoneType, origin=MutUntrackedOrigin]
"""Opaque pointer type for CURL easy handles."""
comptime CURLcode = c_int
"""Type alias for CURL result codes."""
# ...more type aliases for other types
```

When a Mojo program using the package calls any functions that require `libcurl`, an instance of the FFI wrapper `curl` struct defined above is created and stored globally for reuse. Callers use the `curl_ffi` function to get a pointer to the FFI wrapper, and then call the functions they need.

From here, more specialized structs are built on top of the FFI wrapper to provide a more user-friendly interface for making HTTP requests.

For example, Floki exclusively uses `libcurl`'s `Easy` interface for synchronous transfers, so I included a Mojo interface to guarantee proper resource management using Linear Types. If an `Easy` handle is opened, it __must__ be explicitly closed to free the resources.

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

With this, everything is in place to load `libcurl`, configure it, and start performing HTTP requests!

All of the FFI bindings are available separately as their own package: [mojo-curl](https://github.com/thatstoasty/mojo-curl).

### The final steps

The last piece was to tie all together in a convenient `Session` struct that'll carry useful persistent configurations to apply to via `Easy` handle. A few configurations include: default headers, retry policy, controlling redirects, and timeout settings.

```mojo
struct Session(Movable):
    """A Session object to manage and persist settings across multiple HTTP requests."""

    var easy: Easy
    """Wraps a libcurl easy handle, which is used to configure and perform HTTP requests."""
    var allow_redirects: Bool
    """Whether the session should automatically follow HTTP redirects or not."""
    var headers: Headers
    """Default headers to include in every request."""
    var verbose: Bool
    """ Whether libcurl's verbose logging mode is enabled or not."""
    var timeout: Timeout
    """Timeout configuration applied to every request."""
    var retry: Optional[Retry]
    """Retry policy applied to every request made."""
    var proxy: Optional[Proxy]
    """Proxy configuration applied to every request made."""
    var tls: Optional[TLS]
    """TLS/SSL verification settings applied to every request made."""
    var path_as_is: Bool
    """Indicates whether URL paths are sent exactly as given, without collapsing `.` and `..` segments."""

    ...

    # get, put, post, patch, etc. methods
```

## What was hard

### Calling C variadic functions

Along the way, I ran into my fair share of missing features and bugs. The biggest gap is the inability to call C variadic functions through `DLHandle`. Let's use the following `libcurl` function which is our primary configuration interface as an example.

```c
CURLcode curl_easy_setopt(CURL *curl, CURLoption option, ...);
```

Looks simple enough, but how do I pass variadic arguments from Mojo to C?

If I statically link `libcurl` to my Mojo program, I can use `external_call` against those linked symbols.

```mojo
from std.ffi import external_call, c_int

comptime CURL = MutPointer[NoneType, origin=MutUntrackedOrigin]
comptime CURLcode = c_int
comptime CURLoption = c_int

def curl_easy_setopt[T: AnyType, //](curl: CURL, option: CURLoption, parameter: T) -> CURLcode:
    # CURLcode curl_easy_setopt(CURL *curl, CURLoption option, ...);
    return external_call["curl_easy_setopt", CURLoption, num_fixed_args=1](
        curl,
        option,
        parameter,
    )
```

Unfortunately, this approach __does not__ work for C variadic functions called through dynamically loaded libraries. I had to create a small shim C library to correctly pass the data for `parameter`.

```c
CURLcode curl_easy_setopt_long(CURL *curl, CURLoption option, long param) {
    return curl_easy_setopt(curl, option, param);
}
```

And here's what it looks like in Mojo, along with the failed attempts to call `curl_easy_setopt` directly.

```mojo
from std.ffi import OwnedDLHandle, c_int, c_long

comptime CURL = MutPointer[NoneType, origin=MutUntrackedOrigin]
comptime CURLcode = c_int
comptime CURLoption = c_int

@fieldwise_init
struct curl(Movable):
    var handle: OwnedDLHandle
    var shim_handle: OwnedDLHandle

    # Doesn't work! Fails within libcurl after being called.
    def curl_easy_setopt[T: AnyType](self, easy: CURL, option: CURLoption, parameter: T) raises -> CURLcode:
        return self.handle.get_function[CURLcode]("curl_easy_setopt")(easy, option, parameter)

    # Also doesn't work! Same error as above.
    def curl_easy_setopt_long(self, easy: CURL, option: CURLoption, parameter: c_long) raises -> CURLcode:
        return self.handle.get_function[CURLcode]("curl_easy_setopt")(easy, option, parameter)

    # This works!
    def curl_shim_easy_setopt_long(self, easy: CURL, option: CURLoption, parameter: c_long) raises -> CURLcode:
        return self.shim_handle.get_function[CURLcode]("curl_easy_setopt_long")(easy, option, parameter)
```

This makes Floki much less portable because it now depends on two shared libraries instead of one. Most computers will have a version of `libcurl` already available, but I can't say the same for my shim library. It's not an issue while running Mojo code in a Pixi managed environment where both `libcurl` and the shim are pulled into the Pixi environment. However, for a compiled binary, you need to ship the shim alongside your binary which introduces additional maintenance.

### Mojo project management and packaging

Mojo is new. Many of the popular languages of today took years before their project management and packaging stories felt solid.
That being said, there is room for improvement for Mojo project tooling. I consider it part of the growing pains of a nascent ecosystem. But the challenges with creating a new project and adding dependencies creates tangible friction, which makes the barrier for entry higher than it needs to be.

Let's start with Mojo installation. Users can install it using `uv` or `pixi`; always great to have options. The `uv` path feels like a trap though. First, it reads more like Mojo is being added to a Python project, and not that I'm creating a Mojo project. Not only that, but as far as I know __you cannot add Mojo dependencies using uv__. If you want to use Floki and you set up your project using `uv`, you need to go back to step 1 and set up a new project using `pixi`.

The packaging story could also be better. Building and distributing packages is currently somewhat fractured. Modular maintains the `modular-community` Conda channel for community packages, which has been nice to have. But to publish to that channel, I need to maintain a build recipe in their Github repository that's separate from my project's `pixi.toml` file (which is akin to Rust's `Cargo.toml` or Python's `pyproject.toml`). Many projects in the ecosystem opt to be built from source instead of publishing to a Conda channel to minimize overhead of release management.

I know Modular is already working on a package manager, and I think the experience will be greatly improved in the near future! There's been plenty of [fruitful discusson in the Modular forum about the topic](https://forum.modular.com/t/open-question-what-would-you-like-to-see-from-a-mojo-package-manager/2799).

## My thoughts on Mojo

### Why Mojo feels good to write

Looping back around to the original question: what makes code feel satisfying to write?

I think it's a combination of a few things. The language syntax, language design decisions, ability to express desired interfaces, and progressive disclosure of complexity all play a part in that.

#### The syntax

I find Pythonic syntax to look and feel cleaner than most languages. Every additional symbol or keyword adds cognitive load, and Mojo has done a good job of keeping that to a minimum. Mojo makes it possible to write code that is concise, expressive, and performant.

Let's consider a hypothetical `HashMap` struct in Mojo and Rust. Is there really a big difference between `HashMap.new()` and `HashMap::new();`? In isolation, no. But when reading code in larger codebases, the additional symbols _do_ add mental noise and I find that it's more challenging to reason about what I'm reading.

With Python being my most used language, Mojo feels slick and familiar, but with the option to dip into more complex features if I need them. Take a look at the minimal code snippet below.

```mojo
def main():
    var ages = {"alice": 30, "bob": 25, "carol": 35}

    for entry in ages.items():
        print(t"{entry.key}: {entry.value}")
```

To me it might as well be Python, much of the knowledge and muscle memory carries over easily. I can speak Spanish, and I don't speak Portugese or Italian, but the common roots enable me to understand a fair bit of what I hear. That's how I view the relationship between Mojo and Python.

#### Language design decisions

One thing that always impresses me is how the language has evolved over time. With each new release, it's clear that the foundational design philosophy enables intuitive composition of language features.

Compile-time programming is the best example of this. It's a powerful feature that's _easy to reach for_, and _easy to use_ in Mojo. For example, what would it take to lift this code to run at compile time?

```mojo
def my_add(a: Int, b: Int) -> Int:
    return a + b + 1

def main():
    var result = my_add(1, 2)
    print(result)
```

We just slap a `comptime` keyword in front of the variable instead of `var`.

```mojo
def my_add(a: Int, b: Int) -> Int:
    return a + b + 1

def main():
    comptime result = my_add(1, 2)
    var runtime_result = my_add(1, 2)
    print(result, runtime_result)
```

The same goes for assertions and loop unrolling. Moving between runtime and compile time feels seamless.

```mojo
comptime word = "Hello!"

def main():
    for char in word:
        print(char)
    
    comptime for char in word:
        comptime assert char != "!", "Excitement isn't allowed here." # code fails to compile due to failing the assertion
        print(char)
```

When all of the features of a language compose well, and are easy to reach for, it's easier to express the exact desired interfaces and contracts with users. I often find myself wishing for certain aspects of Mojo when writing Python code, like linear type support. When the API itself can enforce correct usage, both the library author and its users have less to keep in their heads.

We touched upon on linear types earlier, remember the `Easy` struct?

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

At a high level, linear types are a type system feature that requires every value to be used exact once. Practically speaking, it means no duplication and no silent deinitialization of the object. For the `Easy` struct, that means you can't accidentally copy the internal handle, and a user can't compile their code until they make sure that the handle is closed via the `close` method on every code path.

As the author, I know that if an `Easy` handle is opened, it __must__ be explicitly closed and I don't need to worry about the fallout of a user not doing so. As a user, I don't have to worry about the lifecycle of the `Easy` handle once I've opened one, because the compiler will enforce that it's closed correctly. When I'm writing Python code that needs the same behavior, __must__ is usually downgraded to __should__, and I have to design defensively around states that I can't assert are invalid. I know we've all added something along the lines of "You __must__ call X method after performing Y! ...please?" to documentation before.

## What's next?

In the short term, I'd like to put together a cookbook for common recipes and patterns for using Floki. Well written documentation is important, but practical examples provide a better sense of what using the package looks like and provide starting points for code that can be copied.

I'd love to hear ideas on how to improve Floki. Try it out, break it, stress test it, and let me know what gaps you find. Real-world use cases are the best way to harden the project!

## Give it a try

You can find the installation instructions in `Adding the floki package to your project` section of the README.

- [Floki: HTTP Client](https://github.com/thatstoasty/floki)

Come join the party! I'm open to contributions on any of these Mojo projects.

- [Mojo-curl: Libcurl bindings](https://github.com/thatstoasty/mojo-curl)
- [Prism: CLI builder](https://github.com/thatstoasty/prism)
- [Mist: Terminal ANSI styling and color](https://github.com/thatstoasty/mist)
- [Mog: Terminal styling](https://github.com/thatstoasty/mog)
- [Stump: Structured logger](https://github.com/thatstoasty/stump)
- [Slight: SQLite bindings](https://github.com/thatstoasty/slight)

## About me

My name is Mikhail Tavarez, and I've been part of the Mojo community since 2024. I spend most of my days at work building internal data services and tooling for data engineers. I'm always available to chat about music, games, books, programming, and whatnot, so feel free to reach out! Thank you to Modular for choosing my project for their grant program; it's been an absolute pleasure to work alongside the team.

My Socials:

- [Github](https://github.com/thatstoasty)
- [LinkedIn](https://www.linkedin.com/in/mikhail-tavarez-a94750b6/)
