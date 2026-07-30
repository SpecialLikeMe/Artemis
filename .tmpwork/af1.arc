@unsafe extern fn printf(f: *i8, ...) i32;
fn probe(args: anytype) i32 {
    let mut ti: *type_info= @typeinfo(@typeof(args));
    match (*ti) {
        type_info::Struct(nm, flds, nf, sz, al, tup, pk) => {
            let mut base: *u8= (u8*)&args;
            @unsafe { printf("nf=%d base=%p\n", (i32)nf, (void*)base); }
            let mut i: i32= 0;
            while (i < (i32)nf) {
                let mut off: i32= flds[i].offset;
                let mut fsz: i32= flds[i].size;
                @unsafe { printf("  [%d] off=%d size=%d\n", i, off, fsz); }
                i = i + 1;
            }
            return (i32)nf;
        },
        _ => { return -1; }
    }
}
pub fn main() i32 { let mut n: i32= 42; return probe(.{ "hi", n, (i64)7 }); }
