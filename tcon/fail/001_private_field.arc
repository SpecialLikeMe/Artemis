// FAIL: accessing a private field from outside the class must be rejected
istruc Wallet {
    private i32 balance;
    public void __construct__(Wallet* self, i32 v) { self.balance = v; }
}

fn main() i32 {
    fn w(100) Wallet;
    let mut stolen: i32= w.balance;  // ERROR: 'balance' is private
    return stolen;
}