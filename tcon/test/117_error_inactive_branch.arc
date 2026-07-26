@define <SAFE> <>

@ifdef SAFE
fn ok() i32 { return 0; }
@else
@error <This branch must never be reached>
@endif

pub fn main() i32 {
    return ok();
}
