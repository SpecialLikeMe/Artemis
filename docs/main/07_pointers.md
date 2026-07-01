# 7. Pointers

Pointers work like C, with one key syntax difference: `(*ptr).field` is preferred over `ptr->field` (which still works but emits a deprecation warning).

## Basics

```arc
i32  x   = 42;
i32* p   = &x;       // address of x
i32  val = (*p);     // dereference p
(*p) = 100;          // write through p
```

## Pointer Arithmetic

```arc
i32 arr[4];
arr[0] = 10; arr[1] = 20; arr[2] = 30; arr[3] = 40;
i32* p = arr;
i32  v = p[2];       // 30
p = p + 1;           // advance one element
```

## Multi-Level Pointers

```arc
i32   x  = 5;
i32*  p  = &x;
i32** pp = &p;
i32   v  = (**pp);   // 5
```

## `void*` — Generic Pointer

```arc
void* generic = (void*)(&x);
i32*  back    = (i32*)generic;
```

`0` is the null pointer constant:
```arc
i32* p = 0;
if (p == 0) { /* null check */ }
```

## Deprecated `->` Syntax

`p->field` desugars to `(*p).field` at parse time and emits a deprecation warning. Use `(*p).field` directly.

> **Challenge:** Write a function `void swap(i32* a, i32* b)` that swaps the values at two pointer addresses without using a temporary variable.

---

[Prev: Control Flow](06_control_flow.md) | [Next: Arrays](08_arrays.md)
