union Bytes {
    let word: i32;
    let byte0: i8;
}

pub fn main() i32 {
    let mut u: Bytes;
    u.word = 0x41424344;
    let mut first: i8= u.byte0;
    if (first != 0x44 && first != 0x41) { return 1; }
    return 0;
}
