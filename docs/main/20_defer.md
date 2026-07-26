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
pub fn main() i32 {
    let mut g: i32 = 0;

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
fn process_file(path: *i8) i32 {
    let fp: *void = fopen(path, "rb");
    if (fp == (*void)0) { return -1; }
    defer { fclose(fp); }    // runs when process_file returns, on any path

    // Read file...
    return 0;   // fclose runs here
}
```

---

## Scoped Deferral

`defer` is scoped to the nearest enclosing `{...}` block:

```arc
pub fn main() i32 {
    let mut g: i32 = 0;
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
fn process() i32 {
    let mut arena: Arena(65536);
    defer { arena.deinit(); }

    let data: *void = arena.alloc(1024);
    if (data == (*void)0) { return -1; }   // deinit still runs

    // ... use data ...
    return 0;
}
```

### Lock / unlock

```arc
fn critical_section(lock: *SpinLock, s: *State) void {
    lock.acquire();
    defer { lock.release(); }

    // ... modify s safely ...
    if (error_case) { return; }   // release still runs
}
```

---

## `errdefer`

`errdefer` is like `defer`, but fires **only when the enclosing scope exits via an error** — either a `return error.X;` or a `try` call that propagates an error upward. It does nothing on normal (success) returns.

### Syntax

```arc
// Single expression form
errdefer resource.deinit();

// Block form
errdefer {
    log_error();
    resource.deinit();
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
fn open_and_process(path: *i8) !i32 {
    let fp: *void = fopen(path, "rb");
    if (fp == null) { return error.NotFound; }

    defer   { fclose(fp); }         // always close the file
    errdefer { log_error(path); }   // log only when something goes wrong

    let result: i32 = try process(fp);
    return result;
}
```

If `process(fp)` succeeds, only `fclose` runs. If an error is returned or propagated, both `log_error` and `fclose` run (in LIFO order).

---

[Prev: Function Pointers](19_function_pointers.md) | [Next: Error Handling](24_error_handling.md)
