@define <OUTER> <>
@define <INNER> <>

@ifdef OUTER
@ifdef INNER
fn val() i32 { return 3; }
@endif
@endif

pub fn main() i32 {
    if (val() != 3) { return 1; }
    return 0;
}
