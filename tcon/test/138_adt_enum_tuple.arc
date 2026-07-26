// 138: ADT enum — tuple variant
enum result {
    ok,
    err(const i8*, i32),
}

pub fn main() i32 {
    let mut x: result;
    x = result.ok;
    x = result.err("bad input", 42);
    const msg: *i8 = (*x)[0];
    let mut code: i32= (*x)[1];
    if (code != 42) { return 1; }
    return 0;
}
