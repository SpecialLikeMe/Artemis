// private members are accessible from within class methods (self)
istruc BankAccount {
    private i32 balance;
    private i32 pin;

    public void __construct__(BankAccount* self, i32 initial, i32 p) {
        self.balance = initial;
        self.pin     = p;
    }

    public bool verify(const BankAccount* self, i32 p) {
        return self.pin == p;
    }

    public i32 get_balance(const BankAccount* self) {
        return self.balance;
    }

    public void deposit(BankAccount* self, i32 amount) {
        self.balance = self.balance + amount;
    }
}

i32 main() {
    BankAccount acct(100, 1234);

    if (!acct.verify(1234))   { return 1; }
    if (acct.verify(9999))    { return 2; }
    if (acct.get_balance() != 100) { return 3; }

    acct.deposit(50);
    if (acct.get_balance() != 150) { return 4; }
    return 0;
}
