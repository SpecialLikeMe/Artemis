// FAIL: accessing a non-existent field in a union
union Num { let i: i32; let f: f32; }
fn main() i32 {
    let mut n: Num;
    return n.d;  // ERROR: no field 'd' in union Num
}
