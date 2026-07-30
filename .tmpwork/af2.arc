@unsafe extern fn printf(f: *i8, ...) i32;
struct Mixed { let a: *i8; let b: i32; let c: i64; }
fn dump(ti: *type_info) void {
    match (*ti) {
        type_info::Struct(nm, flds, nf, sz, al, tup, pk) => {
            let mut szv: i32= (i32)sz;
            let mut alv: i32= (i32)al;
            let mut fp: *void= (void*)flds;
            @unsafe { printf("  struct sz=%d align=%d nf=%d flds=%p\n", szv, alv, (i32)nf, fp); }
            let mut i: i32= 0;
            while (i < (i32)nf) {
                let mut o: i32= flds[i].offset;
                let mut z: i32= flds[i].size;
                let mut a2: i32= flds[i].align;
                @unsafe { printf("  [%d] off=%d size=%d align=%d\n", i, o, z, a2); }
                i = i + 1;
            }
        },
        _ => { @unsafe { printf("  not struct (tag=%d)\n", ti.__tag); } }
    }
}
fn probe(args: anytype) void { @unsafe { printf("anon:\n"); } dump(@typeinfo(@typeof(args))); }
pub fn main() i32 {
    @unsafe { printf("named:\n"); }
    dump(@typeinfo(Mixed));
    let mut n: i32= 42;
    probe(.{ "hi", n, (i64)7 });
    return 0;
}
