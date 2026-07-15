# 7. Pointers

Pointers work like C. Dereferencing uses `(*ptr)` or `ptr->field`; the `->` form is supported but deprecated in style — prefer `(*ptr).field`.

---

## Basics

```arc
i32  x   = 42;
i32* p   = &x;      // take address of x
i32  val = (*p);    // dereference: read through p
(*p) = 100;         // dereference: write through p
// x is now 100
```

---

## Null Pointer

The null pointer constant is `null`:

```arc
i32* p = null;
if (p == null) { /* pointer is null */ }
```

`null` can be assigned to any pointer type or `?T` nullable. Casting `null` to a numeric type gives `0`.

---

## Pointer Arithmetic

Pointer arithmetic scales by the element size:

```arc
i32 arr[4];
arr[0] = 10; arr[1] = 20; arr[2] = 30; arr[3] = 40;
i32* p = arr;

i32 v = p[2];    // 30 (subscript is pointer arithmetic)
p = p + 1;       // advance by sizeof(i32) = 4 bytes
i32 w = p[0];    // 20 (now pointing at arr[1])
```

---

## Multi-Level Pointers

```arc
i32   x  = 5;
i32*  p  = &x;
i32** pp = &p;
i32   v  = (**pp);   // 5
(**pp) = 99;          // writes through two levels of indirection
```

---

## `void*` — Generic Pointer

`void*` can hold any pointer. Cast to a typed pointer before dereferencing:

```arc
void* generic = (void*)(&x);
i32*  back    = (i32*)generic;
i32   val     = (*back);       // 99
```

---

## Member Access via Pointer

Use `(*ptr).field` or the deprecated `ptr->field`:

```arc
struct Point { i32 x; i32 y; }

Point  pt;    pt.x = 3; pt.y = 4;
Point* p = &pt;

i32 x1 = (*p).x;   // preferred
i32 x2 = p->x;     // works, but deprecated style
```

---

## `const` Pointer Qualifiers

Artemis follows standard C const-pointer semantics. The placement of `const` controls which aspect of a pointer is immutable.

| Declaration        | Can reseat pointer? | Can modify data through pointer? |
|--------------------|---------------------|----------------------------------|
| `T*`               | Yes                 | Yes                              |
| `const T*`         | Yes                 | **No**                           |
| `T* const`         | **No**              | Yes                              |
| `const T* const`   | **No**              | **No**                           |

### `const T*` — Pointer to Const Data

The pointer can be reseated (pointed elsewhere), but the data it points to cannot be modified through it:

```arc
i32 x = 1; i32 y = 2;
const i32* p = &x;
(*p) = 5;   // COMPILE ERROR: data is read-only through const T*
p   = &y;   // OK: pointer itself can be reseated
```

This is the correct type for **read-only method receivers**:

```arc
i32 get_balance(const BankAccount* self) {
    return self.balance;       // OK: reading
    // self.balance = 0;      // COMPILE ERROR: mutating through const pointer
}
```

### `T* const` — Const Pointer (Mutable Data)

The pointer cannot be reseated, but the data is mutable:

```arc
i32 value = 0;
i32* const cp = &value;
(*cp) = 42;   // OK: data is mutable
cp   = &y;    // COMPILE ERROR: cannot reseat a const pointer
```

### `const T* const` — Both Immutable

```arc
const i32* const ccp = &value;
(*ccp) = 1;   // COMPILE ERROR: data is read-only
ccp   = &y;   // COMPILE ERROR: pointer is fixed
```

### `const T` — Immutable Variable

A `const` variable cannot be reassigned after initialization:

```arc
const i32 MAX = 100;
MAX = 200;   // COMPILE ERROR: assignment to const
```

`const` variables are not compile-time constants — for that, use `comptime`. `const` only prevents reassignment at runtime.

---

> **Challenge:** Write a function `void swap(i32* a, i32* b)` that swaps the values at two addresses.

---

[Prev: Control Flow](06_control_flow.md) | [Next: Arrays](08_arrays.md)
