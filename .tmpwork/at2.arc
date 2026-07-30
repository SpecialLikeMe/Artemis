@unsafe extern fn printf(f: *i8, ...) i32;
fn probe(args: anytype) i32 {
    let mut ti: *type_info= @typeinfo(@typeof(args));
    match (*ti) {
        type_info::Struct(nm, flds, nf, sz, al, tup, pk) => {
            @unsafe { printf("nfields=%d size=%d\n", (i32)nf, (i32)sz); }
            let mut i: i32= 0;
            while (i < (i32)nf) {
                @unsafe { printf("  [%d] off=%d size=%d\n", i, flds[i].offset, flds[i].size); }
                i = i + 1;
            }
            return (i32)nf;
        },
        _ => { @unsafe { printf("not a struct\n"); } return -1; }
    }
}
pub fn main() i32 {
    let mut n: i32= 42;
    return probe(.{ "hello", n, (i64)7 }) == 3 ? 0 : 1;
}
