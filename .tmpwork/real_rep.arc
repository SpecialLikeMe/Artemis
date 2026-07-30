@include <bind/llvm.arc>
@include <alloc.arc>
@include <fmt.arc>
namespace demo {
fn go(name: *i8, line: i32) void {
    let mut b: [512]i8;
    afmt(b, (u64)512, "%s at %d", .{ name, line });
    aprint("%s\n", .{ b });
    aprint("plain\n", .{});
}
}
pub fn main() i32 { demo.go("x", 1); return 0; }
