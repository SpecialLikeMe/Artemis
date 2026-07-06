# 9. Structs, Unions, and Enums

---

## Structs

A `struct` is a plain C-style aggregate. It has fields but no methods.

```arc
struct Point {
    f64 x;
    f64 y;
}

struct Rect {
    Point origin;
    f64   width;
    f64   height;
}
```

### Creating and Using Structs

```arc
Point p;
p.x = 1.0;
p.y = 2.0;

// Named-field aggregate initializer
Point q = Point { .x = 3.0, .y = 4.0 };

// Inferred-type initializer (type comes from context)
Point r = .{ .x = 5.0, .y = 6.0 };
```

### Passing Structs

Structs are passed by value or by pointer:

```arc
void translate(Point* pt, f64 dx, f64 dy) {
    (*pt).x = (*pt).x + dx;
    (*pt).y = (*pt).y + dy;
}

Point p = .{ .x = 1.0, .y = 2.0 };
translate(&p, 0.5, 0.5);
```

---

## Unions

All fields of a union share the same memory region. Reading a field that was not the last written is undefined behaviour, but unions are useful for type-punning:

```arc
union IntOrFloat {
    i32 i;
    f32 f;
}

IntOrFloat u;
u.i = 0x3f800000;    // write as integer
// u.f is now 1.0    // read as float (IEEE 754 bit pattern)
```

Unions may contain any type, including structs.

---

## Typedefs

`typedef` creates a transparent alias for a type:

```arc
typedef i32   ErrorCode;
typedef Point Vec2;

ErrorCode err = 0;
Vec2      pos = .{ .x = 0.0, .y = 0.0 };
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
i32 c = color.green;    // 1

if (c == color.green) { /* ... */ }
if (c != color.red)   { /* ... */ }
```

Plain enum variables can be assigned integer values directly:

```arc
color c = color.blue;   // 2
i32   n = c;             // n == 2
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

status s = status.ok;
```

Plain tag variants are accessed like plain enum values (`status.ok`, etc.).

### Variant Form 2 — Tuple Variant

Tuple variants carry an ordered list of typed values:

```arc
enum result {
    ok,
    err(const i8*, i32),    // message, code
}

result x = result.err("bad input", 42);

// Payload access: dereference the enum variable, then index
const i8* msg  = (*x)[0];
i32       code = (*x)[1];
```

The enum variable `x` holds the tagged union. `(*x)` dereferences to the payload; `[N]` indexes the N-th tuple element.

### Variant Form 3 — Named Struct Variant

Named struct variants carry fields addressed by name:

```arc
enum event {
    none,
    key_press { i32 key; i32 modifiers; },
    mouse_move { f32 x; f32 y; },
}

event e = event.key_press { .key = 65, .modifiers = 0 };

// Payload access: dereference, then field name
i32 k = (*e).key;

e = event.mouse_move { .x = 1.5, .y = 2.5 };
f32 xv = (*e).x;
```

### Variant Form 4 — istruc Body Variant

`istruc` body variants embed a full class body with fields **and** methods. The body is delimited by `.{ ... }`. A user-defined `__construct__` is optional.

```arc
enum msg {
    empty,
    text .{
        char* rc;
        void __construct__(msg.text* self, char* a) {
            self.rc = a;
        }
    },
}
```

**The self-parameter type inside the body uses the qualified name `EnumName.VariantName`** (not just the variant name alone). This is required because the variant is internally named `msg__NS_text`.

Construction calls the constructor with `EnumName.VariantName(args...)`:

```arc
msg bar = msg.text("Hello world");
```

Methods on the variant work like ordinary istruc methods:

```arc
enum io_error {
    success,
    fatal .{
        const i8* msg;
        i32 code;
        i32 get_code(const io_error.fatal* self) { return self.code; }
    },
}

io_error e = io_error.fatal .{ .msg = "disk full", .code = 28 };
i32 c = e.get_code();    // resolves to the fatal variant's method
```

### Accessing Payload — the Deref Rule

The enum variable holds the **tagged union** (tag + raw payload bytes):

```arc
msg bar = msg.text("Hello world");
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
    nothing,                     // plain tag
    number(i32),                 // tuple (1 element)
    pair { i32 a; i32 b; },      // named struct
    text .{                      // istruc body
        char* s;
        void __construct__(value.text* self, char* str) {
            self.s = str;
        }
        i32 len(const value.text* self) {
            i32 n = 0;
            while (self.s[n] != 0) { n = n + 1; }
            return n;
        }
    },
}
```

---

[Prev: Arrays](08_arrays.md) | [Next: Classes (istruc)](10_istruc.md)
