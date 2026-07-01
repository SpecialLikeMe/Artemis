# 20. The `defer` Statement

`defer` schedules a statement or block to execute when the enclosing scope exits, regardless of which `return` path is taken. Multiple defers in the same scope run in reverse declaration order (LIFO).

## Single-Statement Defer

```arc
void example() {
    void* buf = malloc(1024);
    defer free(buf);

    // ... use buf ...
}   // free(buf) runs here
```

## Block Defer

```arc
void example() {
    defer {
        close_file(f);
        unlock(mutex);
    }
    // ... body ...
}   // block runs here
```

## LIFO Order

```arc
void ordered() {
    defer printf("third\n");
    defer printf("second\n");
    defer printf("first\n");
    // prints: first, second, third
}
```

## Early Return

Deferred code runs even when returning early:
```arc
i32 process(BumpAlloc* a) {
    void* buf = (*a).alloc(256);
    defer (*a).reset();

    if (buf == 0) { return -1; }   // reset() still runs
    // ... use buf ...
    return 0;
}
```

## Typical Pattern — Paired Acquire/Release

```arc
i32 run() {
    BumpAlloc a(4096);
    defer { a.deinit(); }

    i32* arr = (i32*)a.alloc(sizeof(i32) * 64);
    if (arr == 0) { return 1; }
    // ... work ...
    return 0;
}
```

---

[Prev: Function Pointers](19_function_pointers.md) | [Next: Build System](21_build_system.md)
