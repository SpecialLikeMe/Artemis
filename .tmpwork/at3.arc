@unsafe extern fn printf(f: *i8, ...) i32;
fn probe(args: anytype) i32 {
    let mut ti: *type_info= @typeinfo(@typeof(args));
    match (*ti) {
        type_info::Struct(nm, flds, nf, sz, al, tup, pk) => {
            @unsafe { printf("nf=%d flds=%p\n", (i32)nf, (void*)flds); }
            let mut base: *type_info_field= flds;
            @unsafe { printf("base=%p\n", (void*)base); }
            let mut o0: i32= base[0].offset;
            @unsafe { printf("o0=%d\n", o0); }
            return (i32)nf;
        },
        _ => { return -1; }
    }
}
pub fn main() i32 { let mut n: i32= 42; return probe(.{ "hi", n }) == 2 ? 0 : 1; }
