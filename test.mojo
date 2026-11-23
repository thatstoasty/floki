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

def main() raises:
    ...