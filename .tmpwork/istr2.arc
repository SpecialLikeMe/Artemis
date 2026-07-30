@include <afmt_inc.arc>
namespace lx {
istruc box_t {
    let mut line: i32;
    fn boom(self: *box_t) void {
        let mut start_line: i32= self.line;
        aprint("error at line %d\n", .{ start_line });
    }
}
}
pub fn main() i32 { let mut warm: i32= 1; aprint("warm %d
", .{ warm }); let mut b: lx.box_t; b.line = 3; b.boom(); return 0; }
