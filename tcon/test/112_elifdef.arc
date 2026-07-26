@define <B> <>

@ifdef A
fn which() i32 { return 1; }
@elifdef B
fn which() i32 { return 2; }
@else
fn which() i32 { return 3; }
@endif

pub fn main() i32 {
    if (which() != 2) { return 1; }
    return 0;
}
