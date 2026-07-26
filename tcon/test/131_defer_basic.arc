let mut g: i32= 0;

fn set(v: i32) void { g = v; }

pub fn main() i32 {
    g = 0;
    {
        defer set(42);
        if (g != 0) { return 1; }
    }
    if (g != 42) { return 2; }

    g = 0;
    {
        defer { set(7); }
        if (g != 0) { return 3; }
    }
    if (g != 7) { return 4; }

    return 0;
}
