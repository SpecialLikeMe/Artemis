// PASS: anonymous struct literal .{.f=v} with field access
pub fn main() i32 {
    let x = .{ .port = 8080, .code = 42 };
    if (x.port != 8080) { return 1; }
    if (x.code != 42)   { return 2; }
    return 0;
}
