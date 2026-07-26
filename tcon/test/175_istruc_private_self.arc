// members are accessible from within class methods (self)
istruc BankAccount {
    let mut balance: i32;
    let mut pin: i32;

    fn __construct__(self: *BankAccount, initial: i32, p: i32) void {
        self.balance = initial;
        self.pin     = p;
    }

    fn verify(self: *const BankAccount, p: i32) bool {
        return self.pin == p;
    }

    fn get_balance(self: *const BankAccount) i32 {
        return self.balance;
    }

    fn deposit(self: *BankAccount, amount: i32) void {
        self.balance = self.balance + amount;
    }
}

pub fn main() i32 {
    let mut acct: BankAccount(100, 1234);

    if (!acct.verify(1234))   { return 1; }
    if (acct.verify(9999))    { return 2; }
    if (acct.get_balance() != 100) { return 3; }

    acct.deposit(50);
    if (acct.get_balance() != 150) { return 4; }
    return 0;
}
