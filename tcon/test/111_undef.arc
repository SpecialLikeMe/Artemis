@define <FLAG> <>
@undef FLAG

@ifndef FLAG
fn val() i32 { return 5; }
@else
fn val() i32 { return 0; }
@endif

pub fn main() i32 {
    if (val() != 5) { return 1; }
    return 0;
}
