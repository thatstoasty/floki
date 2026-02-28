# floki

A `requests` like HTTP client for Mojo, leveraging `libcurl` under the hood.

![Mojo Version](https://img.shields.io/badge/Mojo%F0%9F%94%A5-26.1-orange)
![Build Status](https://github.com/thatstoasty/floki/actions/workflows/build.yml/badge.svg)
![Test Status](https://github.com/thatstoasty/floki/actions/workflows/test.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Adding the `floki` package to your project

First, you'll need to configure your `pixi.toml` file to include my Mojo community Conda channel. Add `"https://repo.prefix.dev/mojo-community"` to the list of channels.

### Installing it from the `mojo-community` Conda channel

First, you'll need to install the `curl_wrapper` library, which provides a thin wrapper around libcurl to avoid issues with variadic arguments. You can add it by running:

```bash
pixi add curl_wrapper -g "https://github.com/thatstoasty/mojo-curl.git" --subdir shim --branch main
```

> Note: Mojo cannot currently support calling C functions with variadic arguments, and the libcurl client interface makes heavy use of them. The `curl_wrapper` library provides a thin wrapper around libcurl to avoid this issue. Remember to always validate the code you're pulling from third-party sources!

Next, run the following commands in your terminal:

```bash
pixi add floki && pixi install
```

This will add `floki` to your project's dependencies and install it along with its dependencies.

### Building it from source

There's two ways to build `floki` from source: directly from the Git repository or by cloning the repository locally.

#### Building from source: Git

Run the following commands in your terminal:

```bash
pixi add -g "https://github.com/thatstoasty/floki.git" && pixi install
```

#### Building from source: Local

```bash
# Clone the repository to your local machine
git clone https://github.com/thatstoasty/floki.git

# Add the package to your project from the local path
pixi add -s ./path/to/floki && pixi install
```

```mojo
import floki

fn main() raises -> None:
    var response = floki.get("https://example.com")
    for pair in response.headers.items():
        print(pair.key, ": ", pair.value)
    print(response.body.as_string_slice())
```

## TODO

- Add an option for streaming responses instead of loading it all into memory.
- Cookie support.
- Cleanup cookie parsing code, it seems pretty slow.
- Sus out the myriad of bugs and edge cases that may arise as libcurl and requests can do A LOT of things, that I've never used before. Please open issues and open PRs to help address these gaps where possible.
- Add methods to free Session explicitly, same with Easy handles.
- Add support for passing Dict data to session methods. Just passing a dict literal is a little limiting. I've tried, but it gets very hairy trying to convert it to an emberjson JSON object.
- Add support for converting dictionaries to form-encoded data for POST requests.

Reminder, this is a hobby project! You're free to fork it and make changes as you see fit.
