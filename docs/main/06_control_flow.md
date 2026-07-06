# 6. Control Flow

---

## `if` / `else`

```arc
if (x > 0) {
    // positive
} else if (x < 0) {
    // negative
} else {
    // zero
}
```

Parentheses around the condition are **optional**:

```arc
if x > 0 { /* positive */ }
```

Braces are required for multi-statement bodies.

---

### If/Else Captures

Bind the condition value to a name inside the branch with `|name|`:

```arc
i32* maybe_ptr = get_ptr();    // may be null

if (maybe_ptr) |p| {
    // p is bound to maybe_ptr, guaranteed non-null here
    use(*p);
}

if (maybe_ptr) |p| {
    use(*p);
} else |q| {
    // q is the (null) condition value; usually used with error unions
}
```

Captures work like Zig's if-let / Rust's if-let. The captured variable is only visible inside the corresponding branch body.

---

## `while`

```arc
i32 i = 0;
while (i < 10) {
    i = i + 1;
}

// Parentheses are optional:
while i < 10 { i = i + 1; }
```

There is no `do … while`. Use a `while (true) { … if (cond) break; }` pattern instead.

---

## `for`

```arc
for (i32 i = 0; i < 10; i = i + 1) {
    // body
}

// Parentheses are optional:
for i32 i = 0; i < 10; i = i + 1 { }
```

All three sections (init, condition, step) are optional:

```arc
for (;;) { break; }    // infinite loop
for (; x > 0; x = x - 1) { /* no init */ }
```

The init section may be a variable declaration or an expression statement.

---

## Range-Based `for`

Iterate directly over a container or array without managing indices:

```arc
// for (Type varname : collection) { body }
i32 arr[5] = {1, 2, 3, 4, 5};
i32 sum = 0;
for (i32 v : arr) {
    sum = sum + v;   // sum = 15
}
```

The element type must match the container's element type. This form works with any type that provides a `begin`/`end` iterator interface (including standard library containers such as `vector`).

```arc
// vector example
vector<i32> nums = ...;
for (i32 x : nums) {
    // x is each element in turn
}
```

---

## `break` and `continue`

```arc
for (i32 i = 0; i < 100; i = i + 1) {
    if (i == 5)  continue;   // skip iteration 5
    if (i == 10) break;      // stop at 10
}
```

`break` exits the innermost enclosing `for`, `while`, or `switch`.  
`continue` skips the remainder of the current iteration.

---

## `switch`

```arc
switch (x) {
    case 1: { /* ... */ break; }
    case 2: { /* ... */ break; }
    default: { /* ... */ }
}

// Parentheses are optional:
switch x {
    case 1: { /* ... */ break; }
    default: { /* ... */ }
}
```

Cases do not fall through automatically. Always end a case with `break` (or `return`/`continue`) unless you explicitly want shared code paths without execution reaching the next case.

---

## `constexpr if`

The condition is evaluated at compile time; the dead branch is not compiled at all:

```arc
constexpr i32 MODE = 1;

if constexpr (MODE == 1) {
    // compiled in
} else {
    // completely eliminated — not type-checked or emitted
}
```

Both `constexpr if` (prefix) and `if constexpr` (infix) forms are accepted. This is the primary tool for zero-cost platform or configuration branches. Any `constexpr` variable, `sizeof` expression, or literal arithmetic is valid in the condition.

---

## `defer`

`defer` runs a statement or block when the enclosing scope exits (covered in detail in [Chapter 20](20_defer.md)):

```arc
void process() {
    void* buf = malloc(256);
    defer free(buf);     // runs when process() returns, on any path

    if (something_failed()) return;   // free(buf) still runs here
    // ...
}
```

---

[Prev: Functions](05_functions.md) | [Next: Pointers](07_pointers.md)
