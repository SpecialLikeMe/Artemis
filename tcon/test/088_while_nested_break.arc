pub fn main() i32 {
    let mut outer: i32= 0;
    let mut inner_total: i32= 0;
    while (outer < 3) {
        let mut inner: i32= 0;
        while (1) {
            if (inner >= 3) { break; }
            inner_total = inner_total + 1;
            inner = inner + 1;
        }
        outer = outer + 1;
    }
    if (outer != 3)       { return 1; }
    if (inner_total != 9) { return 2; }
    return 0;
}
