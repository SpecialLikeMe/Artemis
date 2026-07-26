// FAIL: subclass directly reads private field of base (not via an accessor)
istruc Account {
    private i32 balance;
    public void __construct__(Account* self, i32 b) { self.balance = b; }
}
istruc SavingsAccount : Account {
    fn total(self: *const SavingsAccount) i32 { return self.balance; }  // ERROR: balance is private
}
fn main() i32 { return 0; }
