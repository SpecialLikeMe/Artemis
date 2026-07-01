// 138: ADT enum — tuple variant
enum result {
    ok,
    err(const i8*, i32),
}

i32 main() {
    result x;
    x = result::ok;
    x = result::err("bad input", 42);
    const i8* msg = (*x)[0];
    i32 code = (*x)[1];
    if (code != 42) { return 1; }
    return 0;
}
