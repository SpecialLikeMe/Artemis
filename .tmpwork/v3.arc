istruc Shape {
    let mut id: i32;
    virtual i32 area(const Shape* self) { return 0; }
    fn get_id(self: *const Shape) i32 { return self.id; }
}
istruc Circle : Shape {
    let mut r: i32;
    fn area(self: *const Circle) i32 override { return self.r * self.r; }
}
pub fn main() i32 { return 0; }
