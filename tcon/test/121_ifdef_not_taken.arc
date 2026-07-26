@ifdef UNDEFINED_FLAG
fn bad() i32 { return 1; }
@else
fn good() i32 { return 0; }
@endif

pub fn main() i32 {
    return good();
}
