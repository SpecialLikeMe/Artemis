// FAIL: global function reads private field of an istruc instance
istruc Wallet {
    private i32 balance;
    public void __construct__(Wallet* self, i32 b) { self.balance = b; }
}
fn steal(w: *Wallet) i32 { return w->balance; }  // ERROR: balance is private
fn main() i32 {
    fn w(500) Wallet;
    return steal(&w);
}
