fn strlen_c(s: *char) i32 {
    let mut n: i32= 0;
    while (s[n] != 0) { n = n + 1; }
    return n;
}

pub fn main() i32 {
    let mut hello: *char= "hello";
    if (strlen_c(hello) != 5) { return 1; }
    if (hello[0] != 'h') { return 2; }
    if (hello[4] != 'o') { return 3; }
    let mut empty: *char= "";
    if (strlen_c(empty) != 0) { return 4; }
    return 0;
}
