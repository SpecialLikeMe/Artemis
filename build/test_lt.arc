struct S { u64 len; u64 cap; }
void foo(S* b, u64 extra) { if (b.len + extra < b.cap) { return; } }
struct done { i32 x; }
