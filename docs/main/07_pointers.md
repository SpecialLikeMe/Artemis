# 7. Pointers

Pointers work like C. Dereferencing uses `(*ptr)` or `ptr->field`; the `->` form is supported but deprecated in style — prefer `(*ptr).field`.

---

## Basics

```arc
let mut x: i32 = 42;
let mut p: *i32 = &x;      // take address of x
let val: i32 = (*p);       // dereference: read through p
(*p) = 100;                // dereference: write through p
// x is now 100
```

---

## Null Pointer

The null pointer constant is `null`:

```arc
let mut p: *i32 = null;
if (p == null) { /* pointer is null */ }
```

`null` can be assigned to any pointer type or `?T` nullable. Casting `null` to a numeric type gives `0`.

---

## Pointer Arithmetic

Pointer arithmetic scales by the element size:

```arc
let mut arr: [4]i32;
arr[0] = 10; arr[1] = 20; arr[2] = 30; arr[3] = 40;
let mut p: *i32 = arr;

let v: i32 = p[2];    // 30 (subscript is pointer arithmetic)
p = p + 1;            // advance by sizeof(i32) = 4 bytes
let w: i32 = p[0];    // 20 (now pointing at arr[1])
```

---

## Multi-Level Pointers

```arc
let mut x: i32 = 5;
let mut p: *i32 = &x;
let mut pp: **i32 = &p;
let v: i32 = (**pp);   // 5
(**pp) = 99;            // writes through two levels of indirection
```

---

## `*void` — Generic Pointer

`*void` can hold any pointer. Cast to a typed pointer before dereferencing:

```arc
let generic: *void = (*void)(&x);
let back: *i32 = (*i32)generic;
let val: i32 = (*back);       // 99
```

---

## Member Access via Pointer

Use `(*ptr).field`:

```arc
struct Point {
    let x: i32;
    let y: i32;
}

let mut pt: Point;
pt.x = 3; pt.y = 4;
let mut p: *Point = &pt;

let x1: i32 = (*p).x;   // preferred
```

---

## Immutable Pointer Qualifiers

Artemis follows C const-pointer semantics. The placement of `const` controls which aspect of a pointer is immutable.

| Declaration         | Can reseat pointer? | Can modify data through pointer? |
|---------------------|---------------------|----------------------------------|
| `*T`                | Yes                 | Yes                              |
| `*const T`          | Yes                 | **No**                           |

### `*const T` — Pointer to Immutable Data

The pointer can be reseated, but the data it points to cannot be modified through it:

```arc
let mut x: i32 = 1;
let mut y: i32 = 2;
let p: *const i32 = &x;
(*p) = 5;   // COMPILE ERROR: data is read-only through *const T
p   = &y;   // OK: pointer itself can be reseated
```

This is the correct type for **read-only method receivers**:

```arc
fn get_balance(self: *const BankAccount) i32 {
    return self.balance;       // OK: reading
    // self.balance = 0;      // COMPILE ERROR
}
```

---

> **Challenge:** Write a function `fn swap(a: *i32, b: *i32) void` that swaps the values at two addresses.

---

[Prev: Control Flow](06_control_flow.md) | [Next: Arrays](08_arrays.md)
