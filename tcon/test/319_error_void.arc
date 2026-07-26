// PASS: !void error propagation and catch
fn may_err(x: i32) !void {
    if (x == 0) { return error.zero; }
}
pub fn main() i32 {
    may_err(1) catch |e| { return 10; };   // no error
    may_err(0) catch |e| { return 0; };    // caught, return 0
    return 1;
}
