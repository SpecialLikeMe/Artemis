// FAIL: accessing a member that exists in neither the class nor any base class
istruc A { let mut x: i32; }
istruc B : A { let mut y: i32; }
fn main() i32 {
    let mut b: B;
    b.x = 1;
    b.y = 2;
    let mut z: i32= b.zzz;  // ERROR: zzz not in B or A
    return z;
}
