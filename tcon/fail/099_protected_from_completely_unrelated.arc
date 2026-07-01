// FAIL: completely unrelated class accesses protected member of another class
istruc Animal { protected i32 heartrate; }
istruc Machine {
    i32 read_bio(Animal* a) { return a->heartrate; }  // ERROR: heartrate is protected
}
i32 main() { return 0; }
