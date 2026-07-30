@include <afmt_inc.arc>
pub fn main() i32 {
    let mut n: i32= 5;
    let mut b: [64]i8;
    aprint("a %d\n", .{ n });
    afmt(b, (u64)64, "b %d", .{ n });
    aprint("c %s\n", .{ "x" });
    return 0;
}
