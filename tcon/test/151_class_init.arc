istruc Token {
    let mut id: i32;
    let mut kind: i32;
    fn total(self: *const Token) i32 { return self.id + self.kind; }
}
pub fn main() i32 {
    let mut t: Token= Token { .id = 5, .kind = 6 };
    if (t.total() != 11) { return 1; }
    return 0;
}
