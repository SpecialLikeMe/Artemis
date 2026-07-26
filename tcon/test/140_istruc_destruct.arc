let mut g_count: i32= 0;

istruc Tracker {
    let mut id: i32;

    fn __construct__(self: *Tracker, n: i32) void {
        self.id = n;
        g_count = g_count + 1;
    }

    fn __destruct__(self: *Tracker) void {
        g_count = g_count - 1;
    }

    fn get(self: *const Tracker) i32 {
        return self.id;
    }
}

pub fn main() i32 {
    if (g_count != 0) { return 1; }

    let mut t: Tracker(42);
    if (g_count != 1)  { return 2; }
    if (t.get() != 42) { return 3; }

    t.__destruct__();
    if (g_count != 0)  { return 4; }

    return 0;
}
