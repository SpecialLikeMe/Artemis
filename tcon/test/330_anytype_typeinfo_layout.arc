// Test: @typeinfo reports the real ABI layout, and an anytype argument struct can be
// walked through it. This is what lets the compiler format without C varargs.
//
// Regressions covered:
//  - the module's data layout was attached *after* codegen, so layout queries answered
//    for LLVM's default ABI (i64 aligned to 4) and { ptr, i32, i64 } reported size 20
//    with field offsets 0/8/12 instead of 24 and 0/8/16.
//  - an ADT payload pointer binding lost its pointee type, so `flds[i].offset` compiled
//    to a byte GEP and a constant 0 rather than a field read.
//  - anytype instantiations were keyed on the type *kind*, so two calls passing
//    different anonymous structs shared one specialization.
//  - a specialization created from inside an istruc method inherited an implicit self.
struct Mixed { let a: *i8; let b: i32; let c: i64; }

fn field_off(ti: *type_info, idx: i32) i32 {
    match (*ti) {
        type_info::Struct(nm, flds, nf, sz, al, tup, pk) => {
            if (idx >= (i32)nf) { return -1; }
            let mut off: i32= flds[idx].offset;
            return off;
        },
        _ => { return -2; }
    }
}

fn struct_size(ti: *type_info) i32 {
    match (*ti) {
        type_info::Struct(nm, flds, nf, sz, al, tup, pk) => { return (i32)sz; },
        _ => { return -1; }
    }
}

fn nfields(args: anytype) i32 {
    let mut ti: *type_info= @typeinfo(@typeof(args));
    match (*ti) {
        type_info::Struct(nm, flds, nf, sz, al, tup, pk) => { return (i32)nf; },
        _ => { return -1; }
    }
}

// Read the i32 sitting in slot `idx` of an anytype argument struct, using the offset
// @typeinfo reports. If the offsets were wrong this would read padding.
fn slot_i32(args: anytype, idx: i32) i32 {
    let mut ti: *type_info= @typeinfo(@typeof(args));
    match (*ti) {
        type_info::Struct(nm, flds, nf, sz, al, tup, pk) => {
            if (idx >= (i32)nf) { return -1; }
            let mut base: *u8= (u8*)&args;
            let mut p: *i32= (i32*)(base + flds[idx].offset);
            return *p;
        },
        _ => { return -1; }
    }
}

istruc Holder {
    let mut v: i32;
    // Same call from inside an istruc method: the specialization must not pick up self.
    fn count(self: *Holder) i32 { return nfields(.{ self.v, "x" }); }
}

pub fn main() i32 {
    let mut ti: *type_info= @typeinfo(Mixed);
    if (struct_size(ti) != 24)  { return 1; }   // not the naive 8+4+8 = 20
    if (field_off(ti, 0) != 0)  { return 2; }
    if (field_off(ti, 1) != 8)  { return 3; }
    if (field_off(ti, 2) != 16) { return 4; }   // not the naive 12

    // Distinct anonymous shapes must get distinct specializations.
    let mut n: i32= 7;
    if (nfields(.{ n })       != 1) { return 5; }
    if (nfields(.{ n, "a" })  != 2) { return 6; }
    if (nfields(.{ n, "a", n }) != 3) { return 7; }

    // Values read back at their reported offsets.
    let mut a: i32= 11;
    let mut b: i32= 22;
    if (slot_i32(.{ a, "pad", b }, 0) != 11) { return 8; }
    if (slot_i32(.{ a, "pad", b }, 2) != 22) { return 9; }

    let mut h: Holder;
    h.v = 3;
    if (h.count() != 2) { return 10; }

    return 0;
}
