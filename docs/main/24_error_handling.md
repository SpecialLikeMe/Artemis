# 24. Error Handling

Artemis uses **error unions** instead of exceptions. Functions that may fail declare a `!T` return type. The caller either propagates the error with `try` or catches it with `catch`. There is no `throw` keyword and no stack unwinding.

---

## Declaring a Fallible Function

```arc
fn maybe_divide(a: i32, b: i32) !i32 {
    if (b == 0) {
        return error.DivByZero;
    }
    return a / b;
}
```

Inside a `!T` function:
- `return expr;` returns a successful value.
- `return error.Name;` returns an error.

---

## Error Literals: `error.Name`

Error tags are named values using the `error.` prefix:

```arc
error.NotFound
error.Overflow
error.InvalidInput
error.DivByZero
```

Any identifier after `error.` is valid — there is no enum declaration needed. Tags are i32 values hashed from the name at compile time. Error names are available as strings at runtime through the `error_t.name` field.

---

## `catch` — Catching Errors

`expr catch |varname| { handler }` catches an error from the preceding `!T` call. The handler block runs **only if** the call returned an error; if the call succeeded, the block is skipped:

```arc
maybe_divide(10, 0) catch |e| {
    // e is error_t: { i32 code; i8* name; i8* payload; }
    // e.name == "DivByZero"
}

// No error: handler does not run
maybe_divide(10, 2) catch |e| {
    // not reached
}
```

### The `error_t` Struct

The `e` variable in `catch |e|` is of type `error_t`:

```arc
struct error_t {
    let code: i32;     // FNV-1a hash of the error name
    let name: *i8;     // human-readable string, e.g. "DivByZero"
    let payload: *i8;  // reserved; currently null
}
```

---

## `try` — Propagating Errors

`try expr` unwraps the value on success, or immediately propagates the error out of the enclosing `!T` function:

```arc
fn outer(x: i32) !i32 {
    let v: i32 = try inner(x);   // if inner fails, outer returns that error
    return v * 2;
}
```

`try` can only appear inside a function with a `!T` return type.

### Chaining `try`

```arc
fn read_config(path: *i8) !i32 {
    let fd: i32 = try open_file(path);
    let n: i32  = try read_bytes(fd);
    return n;
}
```

---

## Full Example

```arc
fn inner_fn(x: i32) !i32 {
    if (x < 0) {
        return error.Negative;
    }
    return x + 1;
}

fn outer_fn(x: i32) !i32 {
    let v: i32 = try inner_fn(x);
    return v * 2;
}

pub fn main() i32 {
    let mut outer_err: i32 = 0;

    outer_fn(-1) catch |e| {
        // e.name == "Negative"
        outer_err = 1;
    }

    outer_fn(3) catch |e| {
        outer_err = 99;   // not reached
    }

    return outer_err;   // 1
}
```

---

## `!void` — Fallible Void Functions

Functions that may fail but return nothing on success use `!void`:

```arc
fn write_file(path: *i8, data: *i8) !void {
    let fp: *void = fopen(path, "w");
    if (fp == null) { return error.OpenFailed; }
    defer { fclose(fp); }
    // write data...
}

pub fn main() i32 {
    write_file("out.txt", "hello") catch |e| {
        return 1;
    }
    return 0;
}
```

---

[Prev: Compile-Time Features](18_comptime.md) | [Next: Interfaces](26_interfaces.md)
