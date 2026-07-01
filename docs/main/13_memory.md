# 13. Memory Management and Allocators

Artemis enforces **allocator-explicit** heap usage. Application code that needs heap memory must receive an allocator as a parameter rather than calling `malloc` directly.

## The `memstr` Allocator Interface

`memstr` declares an allocator interface with three function-pointer slots:

```arc
memstr MyAlloc {
    .ptr = 0;
    .vtable = {
        .mmap   = malloc;    // allocation
        .rmap   = realloc;   // reallocation
        .deinit = free;      // deallocation
    };
}
```

Pass allocators by `&memstr` reference:
```arc
void* make_buffer(u64 n, &memstr alloc) {
    return alloc.mmap(n);
}
```

## Custom Allocator via istruc

Another way to do so is wrapping allocation logic in an istruc and passing it by pointer, but it is not recommended due to the explicit memstr:

```arc
extern void* malloc(u64 n);
extern void  free(void* p);

istruc BumpAlloc {
    void* base;
    u64   used;
    u64   cap;

    void __construct__(&self, u64 capacity) {
        self.base = malloc(capacity);
        self.used = 0;
        self.cap  = capacity;
    }

    void* alloc(&self, u64 n) {
        if (self.used + n > self.cap) { return (void*)0; }
        void* ptr = (void*)((u8*)self.base + self.used);
        self.used = self.used + n;
        return ptr;
    }

    void reset(&self)  { self.used = 0; }
    void deinit(&self) { free(self.base); }
}
```

## Passing Allocators Through Call Stacks

```arc
i32 sum_array(BumpAlloc* alloc, i32 n) {
    i32* arr = (i32*)(*alloc).alloc((u64)(sizeof(i32) * n));
    if (arr == 0) { return -1; }
    i32 s = 0;
    for (i32 i = 0; i < n; i = i + 1) { arr[i] = i + 1; s = s + arr[i]; }
    return s;
}
```

## Heap Alloc Rule (Compiler-Enforced)

Any top-level non-`main` function that directly calls `malloc`, `calloc`, or `realloc` must declare a `&memstr` parameter. istruc methods are exempt:

```arc
// COMPILE ERROR
void* bad(u64 n) { return malloc(n); }

// CORRECT
void* good(u64 n, &memstr alloc) { return alloc.mmap(n); }
```

## `defer` for Cleanup

Use `defer` to guarantee cleanup at scope exit regardless of which `return` is taken:

```arc
i32 process() {
    BumpAlloc a(4096);
    defer { a.deinit(); }

    void* buf = a.alloc(100);
    if (buf == 0) { return -1; }   // deinit still runs
    // ... use buf ...
    return 0;
}
```

See [Chapter 20](20_defer.md) for more on `defer`.

> **Challenge:** Implement a `FreeListAlloc` istruc that manages a fixed pool of 16 `void*` slots. Add `alloc()` that returns the next free slot and `free_slot(void* p)` that returns a slot to the pool.

---

[Prev: Namespaces](12_namespaces.md) | [Next: Operator Overloading](14_operators.md)
