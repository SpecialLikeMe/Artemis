let mut g_val: i32= 0;

fn set_val(v: i32) void {
    g_val = v;
}

fn add_to_val(v: i32) void {
    g_val = g_val + v;
}

pub fn main() i32 {
    set_val(10);
    if (g_val != 10) { return 1; }
    add_to_val(5);
    if (g_val != 15) { return 2; }
    return 0;
}
