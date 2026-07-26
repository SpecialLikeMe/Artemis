// PASS: interface with field stubs — istruc must provide the field.
interface HasId {
    let mut id: i32;
    let mut name: *i8= (i8*)0;  // field with default value (optional)
}

istruc User : HasId {
    let mut id: i32;         // required — no default in interface
    let mut name: *i8;       // optional — has interface default but we override anyway
    let mut age: i32;
}

pub fn main() i32 {
    let mut u: User;
    u.id   = 42;
    u.name = (i8*)0;
    u.age  = 30;
    if (u.id != 42) { return 1; }
    return 0;
}
