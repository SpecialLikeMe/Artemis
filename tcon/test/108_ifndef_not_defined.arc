@ifndef MISSING_FLAG
fn value() i32 { return 9; }
@endif

pub fn main() i32 {
    if (value() != 9) { return 1; }
    return 0;
}
