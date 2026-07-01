// FAIL: subclass directly reads private field of base (not via an accessor)
istruc Account {
    private i32 balance;
    public void __construct__(Account* self, i32 b) { self.balance = b; }
}
istruc SavingsAccount : Account {
    i32 total(const SavingsAccount* self) { return self.balance; }  // ERROR: balance is private
}
i32 main() { return 0; }
