// FAIL: accessing a private field from outside the class must be rejected
istruc Wallet {
    private i32 balance;
    public void __construct__(Wallet* self, i32 v) { self.balance = v; }
}

i32 main() {
    Wallet w(100);
    i32 stolen = w.balance;  // ERROR: 'balance' is private
    return stolen;
}