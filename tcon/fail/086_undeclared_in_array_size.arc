// FAIL: undeclared identifier used inside a class method body
istruc Processor {
    fn run(self: *const Processor) i32 {
        return undefined_constant + 1;  // ERROR: undefined_constant undeclared
    }
}
fn main() i32 {
    let mut p: Processor;
    return p.run();
}
