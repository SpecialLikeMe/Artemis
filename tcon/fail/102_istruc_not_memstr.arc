// Passing an istruc as &memstr must be rejected by the compiler.
extern void* malloc(u64 n);
extern void  free(void* p);

istruc BadAlloc {
    void* ptr;
    void __construct__(&self) { self.ptr = (void*)0; }
}

// This function requires a memstr allocator
void needs_memstr(&memstr a) {
    // body intentionally empty (just testing type checking)
}

i32 main() {
    BadAlloc b;
    needs_memstr(b);  // ERROR: istruc is not a valid &memstr
    return 0;
}
