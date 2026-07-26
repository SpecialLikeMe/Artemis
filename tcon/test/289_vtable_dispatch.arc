// PASS: vtable dispatch through struct function pointer fields
struct ops_t {
    let add: *(i32, i32)i32;
    let mul: *(i32, i32)i32;
}

fn do_add(a: i32, b: i32) i32 { return a + b; }
fn do_mul(a: i32, b: i32) i32 { return a * b; }

istruc Calc {
    let mut ops: *ops_t;

    fn __construct__(self: *Calc, o: *ops_t) void {
        self.ops = o;
    }

    fn compute_add(self: *Calc, a: i32, b: i32) i32 {
        return (*self.ops).add(a, b);
    }

    fn compute_mul(self: *Calc, a: i32, b: i32) i32 {
        return (*self.ops).mul(a, b);
    }
}

pub fn main() i32 {
    let mut o: ops_t;
    o.add = do_add;
    o.mul = do_mul;

    let mut c: Calc(&o);

    if (c.compute_add(3, 4) != 7)  { return 1; }
    if (c.compute_mul(3, 4) != 12) { return 2; }
    if (c.compute_add(10, 5) != 15) { return 3; }
    if (c.compute_mul(6, 7) != 42)  { return 4; }

    return 0;
}
