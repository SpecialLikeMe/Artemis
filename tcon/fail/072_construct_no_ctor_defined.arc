// FAIL: comptime on a type with no __construct__, then explicit call
istruc Plain { i32 v; }
i32 main() {
    comptime Plain p;
    p.__construct__();  // ERROR: Plain has no __construct__
    return p.v;
}
