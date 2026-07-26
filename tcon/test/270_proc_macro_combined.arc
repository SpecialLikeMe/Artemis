// PASS: attr and derive proc macros coexist in the same file.
// Injected code calls and uses the decorated items.

fn logged(&memstr alloc, tokenstream* input) *tokenstream attr {
    return quote {
        fn logged_add_pair(p: *Pair) i32 {
            return add_pair(p) * 2;
        }
    };
}

fn add_display(&memstr alloc, tokenstream* input) *tokenstream derive {
    return quote {
        fn display_pair(p: *Pair) i32 {
            return p.a * 100 + p.b;
        }
    };
}

#derive[add_display]
istruc Pair {
    let mut a: i32;
    let mut b: i32;
    fn __construct__(self: *Pair, a: i32, b: i32) void {
        self.a = a;
        self.b = b;
    }
    fn swap(self: *Pair) void {
        let mut tmp: i32= self.a;
        self.a = self.b;
        self.b = tmp;
    }
}

#[logged]
fn add_pair(p: *Pair) i32 {
    return p.a + p.b;
}

pub fn main() i32 {
    let mut p: Pair(3, 7);
    if (add_pair(&p) != 10) { return 1; }
    // Verify attr macro injected wrapper that calls add_pair
    if (logged_add_pair(&p) != 20) { return 2; }  // (3+7)*2
    // Verify derive macro injected function that uses Pair fields
    if (display_pair(&p) != 307) { return 3; }  // 3*100+7
    p.swap();
    if (p.a != 7 || p.b != 3) { return 4; }
    if (logged_add_pair(&p) != 20) { return 5; }  // still (7+3)*2
    if (display_pair(&p) != 703) { return 6; }  // 7*100+3
    return 0;
}
