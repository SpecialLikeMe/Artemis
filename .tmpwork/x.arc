enum D { A, B }
fn f(d: i32) i32 { switch (d) { case A: break; default: break; } return 0; }
pub fn main() i32 { return f(0); }
