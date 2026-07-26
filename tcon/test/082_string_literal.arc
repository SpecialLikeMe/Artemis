fn strlen_impl(s: *const i8) i32 {
    let mut n: i32= 0;
    while (s[n] != 0) { n = n + 1; }
    return n;
}

pub fn main() i32 {
    const hello: *i8 = "hello";
    if (strlen_impl(hello) != 5) { return 1; }
    const empty: *i8 = "";
    if (strlen_impl(empty) != 0) { return 2; }
    return 0;
}
