# 24. Error Handling

Artemis uses **error unions** instead of exceptions. Functions that may fail declare a `!T` return type. The caller either propagates the error with `try` or catches it with `except`. There is no `throw` keyword and no stack unwinding.

---

## Declaring a Fallible Function

The trailing `!T` return type is written with `auto` as the declared return type:

```arc
auto maybe_divide(i32 a, i32 b) !i32 {
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

## `except` — Catching Errors

`expr except |varname| { handler }` catches an error from the preceding `!T` call. The handler block runs **only if** the call returned an error; if the call succeeded, the block is skipped:

```arc
maybe_divide(10, 0) except |e| {
    // e is error_t: { i32 code; i8* name; i8* payload; }
    printf("Error: %s (code %d)\n", e.name, e.code);
}

// No error: handler does not run
maybe_divide(10, 2) except |e| {
    printf("This will not print\n");
}
```

### The `error_t` Struct

The `e` variable in `except |e|` is of type `error_t`, which has these fields:

```arc
struct error_t {
    i32  code;     // FNV-1a hash of the error name
    i8*  name;     // human-readable string, e.g. "DivByZero"
    i8*  payload;  // reserved; currently null
}
```

---

## `try` — Propagating Errors

`try expr` unwraps the value on success, or immediately propagates the error out of the enclosing `!T` function:

```arc
auto outer(i32 x) !i32 {
    i32 v = try inner(x);   // if inner fails, outer returns that error immediately
    return v * 2;
}
```

`try` can only appear inside a function with a `!T` return type. Using `try` in a non-error-union function is a compile error.

### Chaining `try`

```arc
auto read_config(i8* path) !i32 {
    i32 fd = try open_file(path);
    i32 n  = try read_bytes(fd);
    return n;
}
```

---

## `res` Block

A `res` block scopes error propagation as an inline unit. `try` inside a `res` block propagates the error out of the block, not the enclosing function:

```arc
i32 safe_value = 0;
res {
    safe_value = try maybe_divide(10, 2);
}
```

`res` is useful when you want to use `try` without making the surrounding function a `!T` function.

---

## `noexcept` Functions

A function marked `noexcept` signals it will never return an error. The compiler enforces this:

```arc
i32 safe_add(i32 a, i32 b) noexcept {
    return a + b;
}
```

A `noexcept` function body must not contain `try`, `except`, or `return error.X`. Using these inside a `noexcept` function is a compile error.

You can test at compile time whether an expression is `noexcept`:

```arc
bool b = noexcept(safe_add(1, 2));   // true
```

---

## Full Example

```arc
auto inner_fn(i32 x) !i32 {
    if (x < 0) {
        return error.Negative;
    }
    return x + 1;
}

auto outer_fn(i32 x) !i32 {
    i32 v = try inner_fn(x);
    return v * 2;
}

i32 main() {
    i32 outer_err = 0;

    outer_fn(-1) except |e| {
        // e.name == "Negative"
        outer_err = 1;
    }

    outer_fn(3) except |e| {
        outer_err = 99;   // not reached
    }

    return outer_err;   // 1
}
```

---

[Prev: Language Reference](23_reference.md) | [Next: Nullable Types](25_nullable.md)
