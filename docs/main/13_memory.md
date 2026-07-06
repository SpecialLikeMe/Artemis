# 13. Memory Management and Allocators

Artemis has no garbage collector and no hidden allocation. All heap memory must go through an explicit allocator. The language provides the `memstr` keyword and `&memstr` parameter type to formalize allocator passing.

---

## The `memstr` Declaration

`memstr` declares an allocator class. It is syntactically like `istruc` but marks the type as an allocator that can be passed via `&memstr`. The required methods are `mmap` (allocate), `rmap` (release/free), and `deinit` (destroy the allocator itself):

```arc
extern void* malloc(u64 n);
extern void  free(void* p);

memstr BumpAlloc {
    void* base;
    u64   used;
    u64   cap;

    void __construct__(BumpAlloc* self, u64 capacity) {
        self.base = malloc(capacity);
        self.used = 0;
        self.cap  = capacity;
    }

    void* mmap(BumpAlloc* self, u64 n) {
        if (self.used + n > self.cap) { return (void*)0; }
        u8*   p   = (u8*)self.base;
        void* ptr = (void*)(p + self.used);
        self.used = self.used + n;
        return ptr;
    }

    void rmap(BumpAlloc* self, void* p) { }   // bump allocators ignore individual frees

    void deinit(BumpAlloc* self) { free(self.base); }
}
```

You can also write a regular `istruc` and use it as an allocator by passing it by pointer directly — `memstr` simply lets you pass it through the `&memstr` abstraction.

---

## Passing Allocators: `&memstr`

`&memstr` is the abstract allocator parameter type. Any `memstr` value is automatically accepted:

```arc
void* make_buffer(u64 n, &memstr alloc) {
    return alloc.mmap(n);
}

i32 main() {
    BumpAlloc bump(4096);
    void* buf = make_buffer(128, bump);
    bump.deinit();
    return 0;
}
```

`alloc.mmap(n)` dispatches through the allocator's vtable — it calls `BumpAlloc.mmap` transparently.

---

## Using `istruc` Allocators Directly

For cases where `&memstr` abstraction is not needed, pass the allocator as a plain pointer:

```arc
istruc HeapAlloc {
    i32 count;
    void __construct__(HeapAlloc* self) { self.count = 0; }

    void* alloc(HeapAlloc* self, u64 size) {
        self.count = self.count + 1;
        return malloc(size);
    }

    void dealloc(HeapAlloc* self, void* ptr) {
        self.count = self.count - 1;
        free(ptr);
    }
}

i32 main() {
    HeapAlloc a;

    i32* p = (i32*)a.alloc(sizeof(i32) * 3);
    p[0] = 10; p[1] = 20; p[2] = 30;

    a.dealloc(p);
    return 0;
}
```

---

## Arena Allocator Pattern

An arena (bump) allocator carves out slices from a single block. It cannot free individual allocations — reset the whole arena at once:

```arc
istruc Arena {
    void* base;
    u64   used;
    u64   cap;

    void __construct__(Arena* self, u64 capacity) {
        self.base = malloc(capacity);
        self.used = 0;
        self.cap  = capacity;
    }

    void* alloc(Arena* self, u64 size) {
        if (self.used + size > self.cap) { return (void*)0; }
        u8*   p      = (u8*)self.base;
        void* result = (void*)(p + self.used);
        self.used    = self.used + size;
        return result;
    }

    void reset(Arena* self) { self.used = 0; }

    void deinit(Arena* self) { free(self.base); }
}

i32 main() {
    Arena arena(1024);
    i32*  a = (i32*)arena.alloc(sizeof(i32));
    i32*  b = (i32*)arena.alloc(sizeof(i32));
    (*a) = 1; (*b) = 2;
    arena.reset();     // reclaim all at once
    arena.deinit();
    return 0;
}
```

---

## `defer` for Cleanup

`defer` guarantees teardown runs no matter which `return` is taken:

```arc
i32 process() {
    Arena arena(4096);
    defer { arena.deinit(); }

    void* buf = arena.alloc(100);
    if (buf == (void*)0) { return -1; }   // deinit still runs

    // ...
    return 0;   // deinit runs here too
}
```

See [Chapter 20](20_defer.md) for full `defer` semantics.

---

## Standard Library Allocators

The standard library provides vector (dynamic array) which works with any `&memstr`-compatible allocator:

```arc
extern std.vector;

// std.vector methods that need memory take &memstr:
// void push(vector* self, T val, &memstr a)
// void grow(vector* self, &memstr a)
// void deinit(vector* self, &memstr a)
```

---

## Raw `malloc` / `free`

Direct `malloc`/`free` calls are permitted but should be wrapped in allocator structs for any non-trivial use. Artemis does not enforce the use of `memstr` at the language level; the allocator discipline is a convention, not a hard rule.

```arc
extern void* malloc(u64 n);
extern void  free(void* p);

i32* p = (i32*)malloc(sizeof(i32) * 10);
if (p == (void*)0) { /* out of memory */ }
p[0] = 42;
free(p);
```

---

[Prev: Namespaces](12_namespaces.md) | [Next: Operator Overloading](14_operators.md)
