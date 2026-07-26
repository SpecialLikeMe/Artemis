fn get_bits(val: i32, lo: i32, hi: i32) i32 {
    let mut mask: i32= ((1 << (hi - lo + 1)) - 1) << lo;
    return (val & mask) >> lo;
}

pub fn main() i32 {
    let mut v: i32= 0xAB;
    if (get_bits(v, 0, 3) != 0xB) { return 1; }
    if (get_bits(v, 4, 7) != 0xA) { return 2; }
    let mut w: i32= 0xFF00;
    if (get_bits(w, 8, 15) != 0xFF) { return 3; }
    return 0;
}
