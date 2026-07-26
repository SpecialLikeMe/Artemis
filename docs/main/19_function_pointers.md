# 19. Function Pointers

## Declaring a Function Pointer Type

The function pointer type uses the form `*(ArgTypes)ReturnType`. Use `using` to give a function-pointer type a name:

```arc
using BinaryOp = *(i32, i32)i32;
```

This declares `BinaryOp` as a pointer to a function taking two `i32` arguments and returning `i32`.

## Basic Usage

```arc
fn add(a: i32, b: i32) i32 { return a + b; }
fn mul(a: i32, b: i32) i32 { return a * b; }

fn apply(op: BinaryOp, x: i32, y: i32) i32 { return op(x, y); }

pub fn main() i32 {
    let mut f: BinaryOp = add;
    let r: i32 = apply(f, 3, 4);   // 7
    f = mul;
    let r2: i32 = apply(f, 3, 4);  // 12
    return 0;
}
```

## Storing in istrucs

```arc
istruc Dispatcher {
    let mut handler: *(i32)i32;

    fn set(self: *Dispatcher, f: *(i32)i32) void { self.handler = f; }
    fn run(self: *Dispatcher, x: i32) i32        { return self.handler(x); }
}
```

## Inline Types

Function pointer types can appear inline without a `using`:

```arc
fn call_with_5(f: *(i32)i32) void { f(5); }
```

## Lambdas as Function Pointers

Lambda expressions produce function pointer values:

```arc
let double: *(i32)i32 = [](x: i32) i32 { return x * 2; };
let result: i32 = double(21);   // 42
```

## ADT Enum Variants Holding Function Pointers

```arc
enum action {
    compute(*(i32)i32),
}

pub fn main() i32 {
    let mut a: action = action.compute([](x: i32) i32 { return x * x; });
    return a[0](5);   // 25
}
```

> **Challenge:** Build an `EventSystem` istruc that holds up to 8 function pointers of type `*(i32)void`. Add `fn register(self: *EventSystem, cb: *(i32)void) void` and `fn emit(self: *EventSystem, event: i32) void` that calls all registered callbacks.

---

[Prev: Compile-Time Features](18_comptime.md) | [Next: The defer Statement](20_defer.md)
