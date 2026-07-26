// PASS: ADT enum with function pointer field accessed via subscript and called
@unsafe extern fn printf(fmt: *i8, ...) i32;

enum foo {
    bar((i32)i32),
    baz(i32, i32),
}
pub fn main() i32 {
    let v: foo = foo.bar([](i32 x) i32 { return x * 2; });
    let r: i32 = v[0](5);
    if (r != 10) { return 1; }
    return 0;
}
