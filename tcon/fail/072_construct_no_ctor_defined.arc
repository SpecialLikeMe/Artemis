// FAIL: comptime on a type with no __construct__, then explicit call
istruc Plain { let mut v: i32; }
fn main() i32 {
    comptime Plain p;
    p.__construct__();  // ERROR: Plain has no __construct__
    return p.v;
}
