@define <LEVEL> <>

@ifdef LEVEL_1
fn which() i32 { return 1; }
@elifdef LEVEL
fn which() i32 { return 2; }
@elifdef LEVEL_3
fn which() i32 { return 3; }
@else
fn which() i32 { return 4; }
@endif

pub fn main() i32 {
    if (which() != 2) { return 1; }
    return 0;
}
