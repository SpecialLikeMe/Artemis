# 6. Control Flow

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

Single-statement bodies don't need braces, but using them is recommended.

## `while`

```arc
i32 i = 0;
while (i < 10) {
    i = i + 1;
}
```

## `for`

```arc
for (i32 i = 0; i < 10; i = i + 1) {
    // ...
}
```

The init, condition, and step are all optional:
```arc
for (;;) { break; }   // infinite loop
```

## `break` and `continue`

```arc
for (i32 i = 0; i < 100; i = i + 1) {
    if (i == 5)  continue;   // skip 5
    if (i == 10) break;      // stop at 10
}
```

## `switch`

```arc
switch (x) {
    case 1: { /* ... */ break; }
    case 2: { /* ... */ break; }
    default: { /* ... */ }
}
```

## `constexpr if`

The condition is evaluated at compile time; the dead branch is not emitted into the binary:
```arc
constexpr i32 MODE = 1;

if constexpr (MODE == 1) {
    // this branch is compiled in
} else {
    // this branch is eliminated
}
```

---

[Prev: Functions](05_functions.md) | [Next: Pointers](07_pointers.md)
