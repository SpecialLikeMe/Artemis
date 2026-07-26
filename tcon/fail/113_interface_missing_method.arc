// FAIL: istruc that claims to implement an interface but is missing a required method
interface Drawable {
    fn draw(self: *Drawable) void;
}

istruc Circle : Drawable {
    let mut radius: i32;
    // Missing: draw() method — should fail
}

fn main() i32 { return 0; }
