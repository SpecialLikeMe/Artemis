@define <DEBUG> <>

@ifdef DEBUG
fn mode() i32 { return 1; }
@else
fn mode() i32 { return 0; }
@endif

pub fn main() i32 {
    if (mode() != 1) { return 1; }
    return 0;
}
