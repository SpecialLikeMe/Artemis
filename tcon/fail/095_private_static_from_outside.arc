// FAIL: calling a private static method from outside the class
istruc MathHelper {
    private static i32 secret_formula(i32 x) { return x * x + 1; }
    public static i32 public_api(i32 x) { return MathHelper.secret_formula(x); }
}
i32 main() {
    return MathHelper.secret_formula(5);  // ERROR: secret_formula is private
}
