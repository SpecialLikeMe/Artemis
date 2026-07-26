// PASS: auto var: type = expr syntax (trailing type annotation).

pub fn main() i32 {
    let mut base: i32= 10;
    let mut doubled: i32= base * 2;
    let mut result: i32= doubled + base;
    return result - 30;  // expect 0
}
