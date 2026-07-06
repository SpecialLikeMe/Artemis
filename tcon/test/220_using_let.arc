// PASS: `using let = const auto;` and `using var = auto;` contextual aliases work.
using let = const auto;
using var = auto;

i32 main() {
    let x = 42;
    var y = x + 8;
    if (y != 50) { return 1; }
    return 0;
}
