@define <X> <1>
@undef X
@define <X> <99>

pub fn main() i32 {
    let mut v: i32= X;
    if (v != 99) { return 1; }
    return 0;
}
