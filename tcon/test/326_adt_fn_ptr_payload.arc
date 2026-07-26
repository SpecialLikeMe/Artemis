// Test: an ADT enum variant carrying a function pointer can be matched and called.
// Regression: the pattern binding recorded no callee signature, so in opaque-pointer
// mode the call site had no type for LLVMBuildCall2 and emitted a null operand
// ("module verification failed: Operand is null").
@unsafe extern fn printf(fmt: *i8, ...) i32;

enum Op {
    Apply(i32(i32)*),      // postfix function-pointer spelling
    Combine((i32)i32),     // prefix spelling — same type, different syntax
    Value(i32),
}

pub fn main() i32 {
    let mut inc: i32(i32)* = [](x: i32) i32 { return x + 1; };
    let mut dbl: (i32)i32  = [](x: i32) i32 { return x * 2; };

    let mut a: Op = Op.Apply(inc);
    let mut got_a: i32= 0;
    match (a) { Op::Apply(f) => { got_a = f(41); }, _ => {}, }
    if (got_a != 42) { return 1; }

    let mut b: Op = Op.Combine(dbl);
    let mut got_b: i32= 0;
    match (b) { Op::Combine(g) => { got_b = g(21); }, _ => {}, }
    if (got_b != 42) { return 2; }

    // A non-callable payload in the same enum must still bind as a plain value.
    let mut c: Op = Op.Value(7);
    let mut got_c: i32= 0;
    match (c) { Op::Value(v) => { got_c = v; }, _ => {}, }
    if (got_c != 7) { return 3; }

    return 0;
}
