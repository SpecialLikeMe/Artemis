// FAIL: using an undeclared enum variant
enum Direction { North, South, East, West }
i32 main() {
    i32 d = Up;  // ERROR: Up is not declared
    return d;
}
