// PASS: proc macro functions with all valid return-type annotations.
// Each macro injects a wrapper that CALLS the decorated function/uses the type,
// proving the annotation type (attr, attr verify, derive) actually integrates.

fn mark_attr(&memstr alloc, tokenstream* input) *tokenstream attr {
    return quote {
        fn call_fn_a(x: i32) i32 { return fn_a(x) + 1000; }
    };
}

fn mark_attr_verify(&memstr alloc, tokenstream* input) *tokenstream attr verify {
    return quote {
        fn call_fn_b(x: i32) i32 { return fn_b(x) + 1000; }
    };
}

fn mark_derive(&memstr alloc, tokenstream* input) *tokenstream derive {
    return quote {
        fn get_myval_doubled(m: *MyVal) i32 { return m.get() * 2; }
    };
}

#[mark_attr]
fn fn_a(x: i32) i32 { return x + 1; }

#[mark_attr_verify]
fn fn_b(x: i32) i32 { return x + 2; }

#derive[mark_derive]
istruc MyVal {
    let mut v: i32;
    fn __construct__(self: *MyVal, v: i32) void { self.v = v; }
    fn get(self: *MyVal) i32 { return self.v; }
}

pub fn main() i32 {
    if (fn_a(10) != 11) { return 1; }
    if (fn_b(10) != 12) { return 2; }
    let mut mv: MyVal(42);
    if (mv.get() != 42) { return 3; }
    // Verify each annotation type injected a wrapper that calls the decorated item
    if (call_fn_a(10) != 1011) { return 4; }         // fn_a(10)+1000 = 11+1000
    if (call_fn_b(10) != 1012) { return 5; }         // fn_b(10)+1000 = 12+1000
    if (get_myval_doubled(&mv) != 84) { return 6; }  // mv.get()*2 = 42*2
    return 0;
}
