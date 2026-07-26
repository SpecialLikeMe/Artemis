fn first_char(s: *char) i32 {
    return s[0];
}

pub fn main() i32 {
    let mut word: *char= "hi";
    let mut c: i32= first_char(word);
    if (c != 'h') { return 1; }
    return 0;
}
