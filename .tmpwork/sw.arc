enum Dir { North, South }
fn f(d: i32) i32 {
    switch (d) {
        case North: return 1;
        default: return 0;
    }
}
pub fn main() i32 { return f(North); }
