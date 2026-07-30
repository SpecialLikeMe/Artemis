@include <afmt_inc.arc>
pub fn main() i32 {
    let mut errbuf: [512]i8;
    let mut line: u64= 12u;
    let mut err_msg: *i8= "bad";
    let mut tok_name: *i8= "ident";
    let mut val: *i8= "x";
    afmt(errbuf, (u64)512, "error at line %d: %s; got %s '%s'", .{ line, err_msg, tok_name, val });
    aprint("%s\n", .{ errbuf });
    afmt(errbuf, (u64)512, "error at line %d: %s; got %s", .{ line, err_msg, tok_name });
    aprint("%s\n", .{ errbuf });
    return 0;
}
