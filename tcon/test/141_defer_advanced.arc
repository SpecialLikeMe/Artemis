let mut log: [8]i32;
let mut log_idx: i32= 0;

fn push(v: i32) void {
    log[log_idx] = v;
    log_idx = log_idx + 1;
}

fn inner() void {
    defer push(10);
    defer push(11);
    push(1);
    push(2);
}

fn with_return(x: i32) i32 {
    defer push(99);
    if (x > 0) {
        defer push(88);
        push(50);
        return x;
    }
    push(60);
    return 0;
}

pub fn main() i32 {
    inner();
    if (log[0] != 1)  { return 1; }
    if (log[1] != 2)  { return 2; }
    if (log[2] != 11) { return 3; }
    if (log[3] != 10) { return 4; }

    log_idx = 0;
    with_return(5);
    if (log[0] != 50) { return 5; }
    if (log[1] != 88) { return 6; }
    if (log[2] != 99) { return 7; }

    return 0;
}
