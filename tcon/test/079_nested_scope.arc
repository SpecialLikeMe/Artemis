pub fn main() i32 {
    let mut a: i32= 1;
    {
        let mut b: i32= 2;
        {
            let mut c: i32= 3;
            a = a + b + c;
        }
        a = a + b;
    }
    if (a != 8) { return 1; }
    return 0;
}
