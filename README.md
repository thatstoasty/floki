# floki

A `requests` like HTTP client for Mojo, leveraging `libcurl` under the hood.


![Mojo Version](https://img.shields.io/badge/Mojo%F0%9F%94%A5-25.7-orange)
![Build Status](https://github.com/thatstoasty/floki/actions/workflows/build.yml/badge.svg)
![Test Status](https://github.com/thatstoasty/floki/actions/workflows/test.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Installation

1. First, you'll need to configure your `pixi.toml` file to include my Conda channel. Add `"https://repo.prefix.dev/mojo-community"` to the list of channels.
2. Next, add `floki` to your project's dependencies by running `pixi add floki`.
3. Add the helper library for libcurl bindings by running `pixi add curl_wrapper -g "https://github.com/thatstoasty/mojo-curl.git" --subdirectory shim --branch main`.
    - Mojo cannot currently support calling C functions with variadic arguments, and libcurl makes heavy use of them. The `curl_wrapper` library provides a thin wrapper around libcurl to avoid this issue. Remember to always validate the code you're pulling from third-party sources!
4. Finally, run `pixi install` to install in `floki` and its dependencies. You should see the `.mojopkg` files in `$CONDA_PREFIX/lib/mojo/`.

Please check out the `test/test_session.mojo` for an example of how to use the client for now. I will add documentation later.

```mojo
from floki import Session

fn main() raises -> None:
    var client = Session()
    var response = client.get("https://example.com")

    for pair in response.headers.items():
        print(String(pair.key, ": ", pair.value))
    print("Response body: ", response.body.as_string_slice())
```

## TODO

- Add an option for streaming responses instead of loading it all into memory.
- Cookie support.
- Sus out the myriad of bugs and edge cases that may arise as libcurl and requests can do A LOT of things, that I've never used before. Please open issues and open PRs to help address these gaps where possible.
- Add methods to free Session explicitly, same with Easy handles.

Reminder, this is a hobby project! You're free to fork it and make changes as you see fit.
