// Test: `interface I` as a by-value parameter dispatches through the vtable.
// Regression: the parameter used to lower to a bare void*, so the call site handed
// over a pointer to the concrete struct while the callee read a fat pointer out of
// it — the vtable slot came from the object's own bytes and the call segfaulted.
@unsafe extern fn printf(fmt: *i8, ...) i32;

interface Shape {
    fn area(self: *Shape) i32;
}

istruc Sq : Shape {
    let mut s: i32;
    fn area(self: *Sq) i32 { return self.s * self.s; }
}

istruc Rect : Shape {
    let mut w: i32;
    let mut h: i32;
    fn area(self: *Rect) i32 { return self.w * self.h; }
}

fn total(x: interface Shape) i32 { return x.area(); }

pub fn main() i32 {
    let mut q: Sq;
    q.s = 4;
    let mut r: Rect;
    r.w = 3;
    r.h = 5;

    // Same call site, two different concrete types — each must select its own impl.
    if (total(q) != 16) { return 1; }
    if (total(r) != 15) { return 2; }
    return 0;
}
