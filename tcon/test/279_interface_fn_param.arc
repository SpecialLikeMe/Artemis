// PASS: istruc implementing an interface can be passed where the interface type is expected.
interface Shape {
    let mut area: i32;
}
istruc Circle : Shape {
    let mut area: i32;
    fn __construct__(self: *Circle, a: i32) void { self.area = a; }
}
istruc Square : Shape {
    let mut area: i32;
    fn __construct__(self: *Square, a: i32) void { self.area = a; }
}
fn get_area(s: Shape) i32 {
    return s.area;
}
pub fn main() i32 {
    let mut c: Circle(314);
    let mut sq: Square(100);
    if (get_area(c) != 314)  { return 1; }
    if (get_area(sq) != 100) { return 2; }
    return 0;
}
