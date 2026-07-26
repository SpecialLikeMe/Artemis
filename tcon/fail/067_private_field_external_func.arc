// FAIL: external function accessing private field via class pointer
istruc Hidden {
    private i32 key;
    public void __construct__(Hidden* self, i32 k) { self.key = k; }
}
fn extract(h: *Hidden) i32 { return h->key; }  // ERROR: key is private
fn main() i32 { return 0; }
