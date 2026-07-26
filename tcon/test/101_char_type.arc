pub fn main() i32 {
    let mut c: char= 'A';
    if (c != 65) { return 1; }
    let mut d: char= c;
    if (d != 'A') { return 2; }
    let mut lo: char= 'a';
    if (lo != 97) { return 3; }
    return 0;
}
