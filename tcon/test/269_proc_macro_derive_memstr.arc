// PASS: derive proc macro applied to a memstr type.
// Macros inject functions that use the memstr type's methods,
// proving injected code can work with the decorated type.

fn add_writer(&memstr alloc, tokenstream* input) *tokenstream derive {
    return quote {
        fn write_str(buf: *Buffer, s: *i8) void {
            let mut i: i32 = 0;
            while (s[i] != 0) { buf.push(s[i]); i = i + 1; }
        }
    };
}

fn add_clear(&memstr alloc, tokenstream* input) *tokenstream derive {
    return quote {
        fn clear_buffer(buf: *Buffer) void {
            buf.len = 0;
        }
    };
}

@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

#derive[add_writer]
#derive[add_clear]
memstr Buffer {
    let mut data: *i8;
    let mut len: i32;
    let mut cap: i32;
    fn __construct__(self: *Buffer, cap: i32) void {
        self.data = (i8*)malloc((u64)cap);
        self.len = 0;
        self.cap = cap;
    }
    fn push(self: *Buffer, c: i8) void {
        if (self.len < self.cap) {
            self.data[self.len] = c;
            self.len = self.len + 1;
        }
    }
    fn get(self: *Buffer, i: i32) i8 { return self.data[i]; }
    fn deinit(self: *Buffer) void { free((void*)self.data); }
}

pub fn main() i32 {
    let mut b: Buffer(64);
    write_str(&b, "Hello");
    if (b.len != 5) { return 1; }
    if (b.get(0) != 'H') { return 2; }
    if (b.get(4) != 'o') { return 3; }
    clear_buffer(&b);
    if (b.len != 0) { return 4; }
    write_str(&b, "AB");
    if (b.len != 2) { return 5; }
    if (b.get(0) != 'A') { return 6; }
    b.deinit();
    return 0;
}
