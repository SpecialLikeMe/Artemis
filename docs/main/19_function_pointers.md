# 19. Function Pointers

## Declaring a Function Pointer Type

Use `typedef` to give a function-pointer type a name:

```arc
typedef i32(i32, i32)* BinaryOp;
```

This declares `BinaryOp` as a pointer to a function taking two `i32` arguments and returning `i32`.

## Basic Usage

```arc
i32 add(i32 a, i32 b) { return a + b; }
i32 mul(i32 a, i32 b) { return a * b; }

i32 apply(BinaryOp op, i32 x, i32 y) { return op(x, y); }

i32 main() {
    BinaryOp f = add;
    i32 r = apply(f, 3, 4);   // 7
    f = mul;
    r = apply(f, 3, 4);       // 12
    return 0;
}
```

## Storing in istrucs

```arc
istruc Dispatcher {
    i32(i32)* handler;

    void set(&self, i32(i32)* fn) { self.handler = fn; }
    i32 run(&self, i32 x)         { return self.handler(x); }
}
```

## Inline Types

Function pointer types can appear inline without a typedef:
```arc
void call_with_5(i32(i32)* fn) { fn(5); }
```

> **Challenge:** Build an `EventSystem` istruc that holds up to 8 function pointers of type `void(i32)*`. Add `register(void(i32)* cb)` and `emit(i32 event)` that calls all registered callbacks.

---

[Prev: Compile-Time Features](18_comptime.md) | [Next: The defer Statement](20_defer.md)
