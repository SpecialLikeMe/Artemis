pub fn main() i32 {
    let mut big: i32= 0x141;
    let mut small: i8= (i8)big;
    if (small != 0x41) { return 1; }
    return 0;
}
