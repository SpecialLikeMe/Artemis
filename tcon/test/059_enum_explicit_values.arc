enum Status { Ok = 0, Warn = 1, Err = 2, Fatal = 99 }

pub fn main() i32 {
    if (Ok    != 0)  { return 1; }
    if (Warn  != 1)  { return 2; }
    if (Err   != 2)  { return 3; }
    if (Fatal != 99) { return 4; }
    return 0;
}
