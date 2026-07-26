// EXPECT_FAIL
// Non-void function missing return → compiler must emit error
fn bad_func() i32 {
    let mut x: i32= 5;
}

pub fn main() i32 {
    return bad_func();
}
