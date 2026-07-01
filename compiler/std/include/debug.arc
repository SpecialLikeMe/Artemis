// std.debug — Panic handler, assertions, memory poison helpers.
// All functions at global scope after extern std.debug;

extern i32   printf(i8* fmt, ...);
extern void  abort();
extern void* malloc(u64 n);

namespace debug {
void panic(i8* msg) {
    printf("\nPANIC: %s\n", msg);
    abort();
}

void panic_fmt(i8* fmt_str, i32 val) {
    printf("\nPANIC: ");
    printf(fmt_str, val);
    printf("\n");
    abort();
}

void bounds_check(i32 idx, i32 len, i8* context) {
    if (idx < 0 || idx >= len) {
        printf("\nPANIC: bounds check failed in %s: index %d out of bounds [0,%d)\n",
               context, idx, len);
        abort();
    }
}

void null_check(void* p, i8* context) {
    if (p == (void*)0) {
        printf("\nPANIC: null pointer dereference in %s\n", context);
        abort();
    }
}

void assert(bool cond, i8* msg) {
@ifdef DEBUG
    if (!cond) { panic(msg); }
@endif
}

void poison(void* p, u64 n) {
    u8* b = (u8*)p;
    for (u64 i = 0; i < n; i = i + 1) b[i] = (u8)(0xDEu ^ (u8)(i & 0xFFu));
}

bool is_poisoned(void* p, u64 n) {
    u8* b = (u8*)p;
    i32 hits = 0;
    for (u64 i = 0; i < n; i = i + 1) {
        if (b[i] == (u8)(0xDEu ^ (u8)(i & 0xFFu))) { hits = hits + 1; }
    }
    return hits > (i32)(n / 2);
}

void breakpoint() { }

} // namespace debug