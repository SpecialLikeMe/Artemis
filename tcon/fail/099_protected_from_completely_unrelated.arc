// FAIL: completely unrelated class accesses protected member of another class
istruc Animal { protected i32 heartrate; }
istruc Machine {
    fn read_bio(a: *Animal) i32 { return a->heartrate; }  // ERROR: heartrate is protected
}
fn main() i32 { return 0; }
