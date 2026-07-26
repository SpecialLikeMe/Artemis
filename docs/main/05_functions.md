# 5. Functions

---

## Basic Functions

Functions are declared with `fn`:

```arc
fn add(a: i32, b: i32) i32 { return a + b; }

fn greet(name: *i8) void {
    // ... use name ...
}
```

`pub fn main() i32` is the program entry point:

```arc
pub fn main() i32 { return 0; }
```

The `pub` keyword makes the function visible outside the current module.

---

## Fallible Functions — `!T` Return Type

A function that may fail appends `!` before the return type:

```arc
fn maybe_divide(a: i32, b: i32) !i32 {
    if (b == 0) {
        return error.DivByZero;
    }
    return a / b;
}
```

Return an error with `return error.Name;`. Return a value normally otherwise.
See [Chapter 24](24_error_handling.md) for full error-handling coverage.

---

## Variadic Functions

`...` at the end of the parameter list marks a variadic function:

```arc
@unsafe extern fn printf(fmt: *i8, ...) i32;

// calling a variadic function:
printf("Value: %d\n", 42);
```

---

## `inline` Hint

`inline` is a hint to inline the function at call sites:

```arc
inline fn fast_add(a: i32, b: i32) i32 { return a + b; }
```

This is an optimizer hint — the compiler may ignore it.

---

## Forward Declarations

Declare a function without a body to call it before its definition:

```arc
fn compute(x: i32) i32;   // forward declaration

pub fn main() i32 { return compute(5); }

fn compute(x: i32) i32 { return x * x; }
```

---

## Generics

Type parameters go in `<>` after the function name:

```arc
fn max<T>(a: T, b: T) T { return a > b ? a : b; }

let x: i32 = max<i32>(3, 7);    // explicit
let y: f64  = max(1.5, 2.5);    // inferred: T = f64
```

See [Chapter 11](11_generics.md) for details.

---

## Function Pointer Types

Function pointer types use `(ARGS)RETURN` notation:

```arc
let fn_ptr: (i32, i32)i32;     // pointer to fn(i32, i32) -> i32
let double: *(i32)i32;          // pointer-to-fn returning i32
```

Lambdas use `[]` notation:

```arc
let add = [](a: i32, b: i32) i32 { return a + b; };
```

---

## Allocator Parameter Convention

Functions that need heap memory should accept an allocator parameter rather than calling `malloc` directly. The `&memstr` type accepts any `memstr`-declared allocator:

```arc
fn make_buffer(n: u64, alloc: &memstr) *void {
    return alloc.mmap(n);
}
```

`istruc` methods may allocate internally since they implement the allocator themselves. See [Chapter 13](13_memory.md).
