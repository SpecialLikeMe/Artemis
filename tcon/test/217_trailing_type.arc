// PASS: auto var: type = expr syntax (trailing type annotation).

i32 main() {
    auto base: i32 = 10;
    auto doubled: i32 = base * 2;
    auto result: i32 = doubled + base;
    return result - 30;  // expect 0
}
