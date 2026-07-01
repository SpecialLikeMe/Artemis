// FAIL: external function accessing private field via class pointer
istruc Hidden {
    private i32 key;
    public void __construct__(Hidden* self, i32 k) { self.key = k; }
}
i32 extract(Hidden* h) { return h->key; }  // ERROR: key is private
i32 main() { return 0; }
