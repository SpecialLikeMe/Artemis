let mut table: [5]i32;

fn init_table() void {
    for (let mut i: i32 = 0; i < 5; i++) {
        table[i] = i * 10;
    }
}

pub fn main() i32 {
    init_table();
    if (table[0] != 0)  { return 1; }
    if (table[1] != 10) { return 2; }
    if (table[4] != 40) { return 3; }
    return 0;
}
