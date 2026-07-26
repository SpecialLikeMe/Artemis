# 9. Structs, Unions, and Enums

---

## Structs

A `struct` is a plain C-style aggregate. It has fields but no methods.

```arc
struct Point {
    let x: f64;
    let y: f64;
}

struct Rect {
    let origin: Point;
    let width: f64;
    let height: f64;
}
```

### Creating and Using Structs

```arc
let mut p: Point;
p.x = 1.0;
p.y = 2.0;

// Named-field aggregate initializer
let mut q: Point = Point { .x = 3.0, .y = 4.0 };

// Inferred-type initializer (type comes from context)
let mut r: Point = .{ .x = 5.0, .y = 6.0 };
```

### Passing Structs

Structs are passed by value or by pointer:

```arc
fn translate(pt: *Point, dx: f64, dy: f64) void {
    (*pt).x = (*pt).x + dx;
    (*pt).y = (*pt).y + dy;
}

let mut p: Point = .{ .x = 1.0, .y = 2.0 };
translate(&p, 0.5, 0.5);
```

### Anonymous Structs

An initializer written without a leading type name produces an **anonymous struct**. Two anonymous structs with the same field names and types share the same type.

```arc
let x = .{
    .port = 8080,
    .host = "localhost",
};
// x.port == 8080, x.host == "localhost"
```

Fields without names are positional and accessed with the subscript operator:

```arc
let mut foo = .{ 12, "hello", 99 };
// foo[0] == 12
// foo[1] == "hello"
// foo[2] == 99
foo[0] = 10;   // reassign positional field (foo is mut)
```

---

## Unions

All fields of a union share the same memory region. Reading a field that was not the last written is undefined behaviour, but unions are useful for type-punning:

```arc
union IntOrFloat {
    let i: i32;
    let f: f32;
}

let mut u: IntOrFloat;
u.i = 0x3f800000;    // write as integer
// u.f is now 1.0    // read as float (IEEE 754 bit pattern)
```

Unions may contain any type, including structs.

---

## Typedefs

`using` creates a transparent alias for a type:

```arc
using ErrorCode = i32;
using Vec2 = Point;

let err: ErrorCode = 0;
let pos: Vec2 = .{ .x = 0.0, .y = 0.0 };
```

---

## Plain Enums

Plain enums declare a set of named integer constants:

```arc
enum color {
    red,
    green,
    blue,
}
```

Variants are `i32` values starting at 0 and incrementing. Access them with `.`:

```arc
let c: i32 = color.green;    // 1

if (c == color.green) { /* ... */ }
if (c != color.red)   { /* ... */ }
```

Plain enum variables can be assigned integer values directly:

```arc
let c: color = color.blue;   // 2
let n: i32 = c;              // n == 2
```

---

## ADT Enums (Algebraic Data Types)

ADT enums are tagged unions: each variant can carry different payload data. There are four variant forms that can be freely mixed within one `enum` declaration.

### Variant Form 1 — Plain Tag (No Payload)

```arc
enum status {
    ok,
    fail,
    timeout,
}

let mut s: status = status.ok;
```

Plain tag variants are accessed like plain enum values (`status.ok`, etc.).

### Variant Form 2 — Tuple Variant

Tuple variants carry an ordered list of typed values:

```arc
enum result {
    ok,
    err(*i8, i32),    // message, code
}

let x: result = result.err("bad input", 42);

// Payload access: dereference the enum variable, then index
let msg: *i8 = (*x)[0];
let code: i32 = (*x)[1];
```

The enum variable `x` holds the tagged union. `(*x)` dereferences to the payload; `[N]` indexes the N-th tuple element.

### Variant Form 3 — Named Struct Variant

Named struct variants carry fields addressed by name:

```arc
enum event {
    none,
    key_press { let key: i32; let modifiers: i32; },
    mouse_move { let x: f32; let y: f32; },
}

let mut e: event = event.key_press { .key = 65, .modifiers = 0 };

// Payload access: dereference, then field name
let k: i32 = (*e).key;

e = event.mouse_move { .x = 1.5, .y = 2.5 };
let xv: f32 = (*e).x;
```

### Variant Form 4 — istruc Body Variant

`istruc` body variants embed a full class body with fields **and** methods. The body is delimited by `.{ ... }`. A user-defined `__construct__` is optional.

```arc
enum msg {
    empty,
    text .{
        let mut rc: *i8;
        fn __construct__(self: *msg.text, a: *i8) void {
            self.rc = a;
        }
    },
}
```

**The self-parameter type inside the body uses the qualified name `EnumName.VariantName`** (not just the variant name alone). This is required because the variant is internally named `msg__NS_text`.

Construction calls the constructor with `EnumName.VariantName(args...)`:

```arc
let mut bar: msg = msg.text("Hello world");
```

Methods on the variant work like ordinary istruc methods:

```arc
enum io_error {
    success,
    fatal .{
        let mut msg: *i8;
        let mut code: i32;
        fn get_code(self: *io_error.fatal) i32 { return self.code; }
    },
}

let mut e: io_error = io_error.fatal .{ .msg = "disk full", .code = 28 };
let c: i32 = e.get_code();    // resolves to the fatal variant's method
```

### Accessing Payload — the Deref Rule

The enum variable holds the **tagged union** (tag + raw payload bytes):

```arc
let mut bar: msg = msg.text("Hello world");
// bar  → the tagged union (has tag + payload bytes)
// *bar → the payload (the msg.text struct)
```

To get the payload:
- **Named struct / istruc variants**: `(*var).field`
- **Tuple variants**: `(*var)[N]`
- **Plain tags**: no payload; just use the value as an integer

### Mixing Variant Forms

A single enum can mix all four forms:

```arc
enum value {
    nothing,                          // plain tag
    number(i32),                      // tuple (1 element)
    pair { let a: i32; let b: i32; }, // named struct
    text .{                           // istruc body
        let mut s: *i8;
        fn __construct__(self: *value.text, str: *i8) void {
            self.s = str;
        }
        fn len(self: *value.text) i32 {
            let mut n: i32 = 0;
            while (self.s[n] != 0) { n = n + 1; }
            return n;
        }
    },
}
```

---

[Prev: Arrays](08_arrays.md) | [Next: Classes (istruc)](10_istruc.md)
