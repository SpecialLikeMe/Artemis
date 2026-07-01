// FAIL: calling a non-existent method on an istruc instance
istruc Logger {
    i32 level;
    void __construct__(Logger* self, i32 l) { self.level = l; }
}
i32 main() {
    Logger log(1);
    log.flush();  // ERROR: Logger has no method 'flush'
    return 0;
}
