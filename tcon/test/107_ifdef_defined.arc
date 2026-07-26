@define <HAS_FEATURE> <>

@ifdef HAS_FEATURE
fn value() i32 { return 7; }
@endif

pub fn main() i32 {
    if (value() != 7) { return 1; }
    return 0;
}
