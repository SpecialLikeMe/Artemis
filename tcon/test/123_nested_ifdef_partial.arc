@define <OUTER> <>

@ifdef OUTER
@ifdef INNER_MISSING
fn val() i32 { return 1; }
@else
fn val() i32 { return 2; }
@endif
@endif

pub fn main() i32 {
    if (val() != 2) { return 1; }
    return 0;
}
