// FAIL: accessing private field from a completely external context
istruc Token {
    private i32 id;
    public void __construct__(Token* self, i32 v) { self.id = v; }
}
fn main() i32 {
    fn t(42) Token;
    let mut x: i32= t.id;  // ERROR: id is private
    return x;
}
