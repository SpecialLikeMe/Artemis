# 20. `defer` and `errdefer`

`defer` runs a statement or block at the end of the enclosing scope, regardless of how the scope exits (normal fall-through, `return`, `break`, or `continue`).

---

## Basic Syntax

```arc
// Single statement form
defer free(buf);

// Block form
defer {
    close(fd);
    free(buf);
}
```

The deferred action is registered at the point the `defer` statement is encountered, but executes when the enclosing scope closes.

---

## Execution Ordering

Multiple `defer` statements in the same scope execute in **LIFO** (last-in, first-out) order — the last `defer` encountered runs first:

```arc
i32 main() {
    i32 g = 0;

    {
        defer g = 7;
        if (g != 0) { return 1; }
    }
    if (g != 7) { return 2; }

    return 0;
}
```

---

## Guaranteed Cleanup

`defer` is the primary tool for ensuring cleanup happens on all return paths:

```arc
i32 process_file(i8* path) {
    void* fp = fopen(path, "rb");
    if (fp == (void*)0) { return -1; }
    defer { fclose(fp); }    // runs when process_file returns, on any path

    // Read file...
    if (read_error) { return -2; }   // fclose still runs
    return 0;                         // fclose runs here too
}
```

---

## Scoped Deferral

`defer` is scoped to the nearest enclosing `{...}` block:

```arc
i32 main() {
    i32 g = 0;
    {
        defer g = 42;      // runs when this inner block exits, not at function end
    }
    // g is 42 here
    return g;
}
```

---

## Common Patterns

### Arena cleanup

```arc
i32 process() {
    Arena arena(65536);
    defer { arena.deinit(); }

    void* data = arena.alloc(1024);
    if (data == (void*)0) { return -1; }   // deinit still runs

    // ... use data ...
    return 0;
}
```

### Lock / unlock

```arc
void critical_section(SpinLock* lock, State* s) {
    lock.lock();
    defer { lock.unlock(); }

    // ... modify s safely ...
    if (error_case) { return; }   // unlock still runs
}
```

### File open / close

```arc
void write_log(i8* msg) {
    void* fp = fopen("log.txt", "a");
    if (fp == (void*)0) { return; }
    defer { fclose(fp); }

    fprintf(fp, "%s\n", msg);
}
```

---

## `errdefer`

`errdefer` is like `defer`, but fires **only when the enclosing scope exits via an error** — either a `return error.X;` or a `try` call that propagates an error upward. It does nothing on normal (success) returns.

### Syntax

```arc
// Single expression form
errdefer alloc.deinit(resource);

// Block form
errdefer {
    printf("cleanup after error\n");
    alloc.deinit(resource);
}
```

### Behaviour

| Exit path | `defer` fires? | `errdefer` fires? |
|-----------|---------------|-------------------|
| Normal return | Yes | **No** |
| `return error.X` | Yes | **Yes** |
| `try` propagation | Yes | **Yes** |

### Example — Error-Only Cleanup

```arc
auto open_and_process(i8* path) !i32 {
    void* fp = fopen(path, "rb");
    if (fp == null) { return error.NotFound; }

    defer   { fclose(fp); }         // always close the file
    errdefer { log_error(path); }   // log only when something goes wrong

    i32 result = process(fp);
    return result;
}
```

If `process(fp)` succeeds, only `fclose` runs. If an error is returned or propagated, both `log_error` and `fclose` run (in LIFO order, `errdefer` first since it was registered after `defer`).

### Combining `defer` and `errdefer`

Multiple `errdefer` statements execute in LIFO order, just like `defer`. They interleave with `defer` according to registration order:

```arc
auto allocate_two() !void {
    void* a = alloc(64);
    defer  { free(a); }
    errdefer { log("failed after a"); }

    void* b = alloc(64);
    defer  { free(b); }
    errdefer { log("failed after b"); }

    try do_work(a, b);
    // Success: both free() run, no log() calls
    // Error:   log("failed after b"), log("failed after a"), free(b), free(a)
}
```

---

[Prev: Function Pointers](19_function_pointers.md) | [Next: Error Handling](24_error_handling.md)
