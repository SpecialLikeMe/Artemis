// Test new syntax features: typedef auto, trailing types, using aliases
typedef auto MyInt = i32;
typedef auto PtrInt = i32*;

// Trailing-type global variable declarations
auto x: i32 = 10;
auto y: i32 = 20;

// using alias: var = auto (type inference placeholder)
using var = auto;

i32 add(i32 a, i32 b) { return a + b; }

// Function with trailing return type (no colon — space separated)
auto compute() i32 {
    auto result: i32 = add(x, y);
    return result;
}

i32 main() {
    // typedef auto
    MyInt a = 42;
    if (a != 42) { return 1; }

    // Trailing type local vars
    auto b: i32 = 7;
    auto c: i32 = b * 6;
    if (c != 42) { return 2; }

    // Function with trailing return type
    auto v: i32 = compute();
    if (v != 30) { return 3; }

    // using alias: var (= auto) with type inferred from initializer
    var d = 99;
    if (d != 99) { return 4; }

    return 0;
}
