// FAIL: undeclared identifier used inside a class method body
istruc Processor {
    i32 run(const Processor* self) {
        return undefined_constant + 1;  // ERROR: undefined_constant undeclared
    }
}
i32 main() {
    Processor p;
    return p.run();
}
