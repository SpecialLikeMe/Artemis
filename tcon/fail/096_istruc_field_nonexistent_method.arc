// FAIL: calling a non-existent method on an istruc instance
istruc Logger {
    let mut level: i32;
    fn __construct__(self: *Logger, l: i32) void { self.level = l; }
}
fn main() i32 {
    fn log(1) Logger;
    log.flush();  // ERROR: Logger has no method 'flush'
    return 0;
}
