# 10. Classes (istruc)

`istruc` (inline struct with methods) provides object-oriented features without vtable or garbage-collector overhead. It is like a C struct with methods attached. There is no inheritance — use [interfaces](26_interfaces.md) for shared behaviour contracts.

---

## Basic Declaration

```arc
istruc Vec3 {
    f64 x; f64 y; f64 z;

    void __construct__(Vec3* self, f64 a, f64 b, f64 c) {
        self.x = a; self.y = b; self.z = c;
    }

    f64 dot(const Vec3* self, Vec3 other) {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    Vec3 add(const Vec3* self, Vec3 other) {
        Vec3 result(self.x + other.x, self.y + other.y, self.z + other.z);
        return result;
    }
}

i32 main() {
    Vec3 a(1.0, 0.0, 0.0);
    Vec3 b(0.0, 1.0, 0.0);
    f64  d = a.dot(b);   // 0.0
    return 0;
}
```

---

## Explicit Self Parameter

Every method declares an explicit pointer to the owning type as its **first** parameter. The convention is to name it `self`. Dot-notation calls (`a.method()`) automatically pass the receiver as that first argument.

```arc
istruc Counter {
    i32 count;

    void increment(Counter* self) {
        self.count = self.count + 1;
    }

    i32 get(const Counter* self) {
        return self.count;
    }
}

Counter c;
c.increment();     // equivalent to Counter.increment(&c)
i32 v = c.get();   // equivalent to Counter.get(&c)
```

`const T* self` means the method does not write through the receiver — it is a read-only method. See [Pointer Const Semantics](27_pointer_const.md).

---

## Constructors (`__construct__`)

A method named `__construct__` is called automatically when a variable is declared with `()`:

```arc
Vec3 v(1.0, 2.0, 3.0);   // calls __construct__(1.0, 2.0, 3.0)
```

A zero-argument constructor is invoked when you declare with no arguments and the istruc defines one:

```arc
istruc Empty {
    i32 x;
    void __construct__(Empty* self) { self.x = 0; }
}
Empty e;    // calls e.__construct__()
```

### Brace Syntax — Struct Literal (Not Constructor)

`{ }` after a type name is a **struct literal initializer**, not a constructor call:

```arc
Vec3 v = Vec3 { .x = 1.0, .y = 0.0, .z = 0.0 };  // struct literal, not constructor
```

This initializes fields by name and does not call `__construct__`. If you want the constructor, always use `()`.

### Assignment (`=`) vs Construction

**Construction** happens only via `()`:
```arc
Vec3 v(1.0, 2.0, 3.0);    // constructor called
```

**Assignment** (`= expr`) calls `operator=` if the class defines one, otherwise performs a raw memory copy:
```arc
Vec3 v = some_other_vec3;  // calls Vec3.operator= if defined, else raw store
```

`= expr` does **not** invoke `__construct__`. If you need initialization from an expression, define `operator=`.

---

## Read-Only Methods

Declare `self` as `const T*` to mark a method as non-mutating:

```arc
istruc BankAccount {
    i32 balance;
    i32 pin;

    bool verify(const BankAccount* self, i32 p) {
        return self.pin == p;          // reads only; cannot assign self.pin = ...
    }

    i32 get_balance(const BankAccount* self) {
        return self.balance;
    }

    void deposit(BankAccount* self, i32 amount) {
        self.balance = self.balance + amount;   // mutating: non-const self
    }
}
```

---

## Static Methods

Static methods belong to the class, not any instance. Call them via `ClassName.method()` or `ClassName.method()`:

```arc
istruc Factory {
    i32 value;

    static Factory make(i32 val) {
        Factory f;
        f.value = val;
        return f;
    }
}

Factory f = Factory.make(42);
```

Static methods do not receive an implicit `self` parameter.

---

## Aggregate Initializer

If an `istruc` has no `__construct__`, use the named-field form to initialize it:

```arc
istruc Token {
    i32 id;
    i32 kind;
    i32 total(const Token* self) { return self.id + self.kind; }
}

Token t = Token { .id = 5, .kind = 6 };
i32 v = t.total();   // 11
```

---

## Operator Overloading

See [Chapter 14](14_operators.md) for the full operator list. Each overloaded operator is a method with an explicit `self` pointer:

```arc
istruc Vec2 {
    i32 x; i32 y;

    Vec2 operator+(const Vec2* self, Vec2 other) {
        Vec2 r;
        r.x = self.x + other.x;
        r.y = self.y + other.y;
        return r;
    }

    bool operator==(const Vec2* self, Vec2 other) {
        return self.x == other.x && self.y == other.y;
    }
}

Vec2 a(1, 2);
Vec2 b(3, 4);
Vec2 c = a + b;      // calls operator+
bool eq = (a == a);  // calls operator==
```

### `operator=`

Define `operator=` to control what happens on assignment:

```arc
istruc String {
    char* data;

    void operator=(String* self, String* other) {
        self.data = (*other).data;   // shallow copy
    }
}

String s1; s1.data = "hello";
String s2 = s1;    // calls operator=
```

### Conversion Operators

Define a cast target to enable explicit `(T)` casts:

```arc
istruc Ratio {
    i32 num; i32 den;
    void __construct__(Ratio* self, i32 n, i32 d) { self.num = n; self.den = d; }
    operator i32(const Ratio* self) { return self.num / self.den; }
}

Ratio r(10, 3);
i32 v = (i32)r;    // calls operator i32, result is 3
```

---

## Interfaces

An `istruc` can implement one or more interfaces by listing them after `:`:

```arc
interface Drawable {
    void draw(Drawable* self);
}

istruc Circle : Drawable {
    i32 radius;
    void draw(Circle* self) { /* render */ }
}
```

The compiler verifies at compile time that every required interface method and field is present. See [Chapter 26](26_interfaces.md).

---

## Generic `istruc`

Type parameters go in `<>` after the class name:

```arc
istruc Box<T> {
    T value;
}

Box<i32> b;
b.value = 77;
```

Each distinct instantiation (`Box<i32>`, `Box<f64>`) is compiled to a separate concrete type. See [Chapter 11](11_generics.md).

---

## `comptime` — Deferred Construction

Declare a variable without invoking any constructor, then call it yourself:

```arc
comptime Timer u;
u.__construct__(20);   // called manually, e.g. inside a conditional
```

Useful for placement-new patterns or when construction order must be exact. See [Chapter 18](18_comptime.md).

---

## Name Mangling

Methods are internally named `ClassName__MT_methodname`. `operator=` becomes `ClassName__MT_operator=`. This mangling is an implementation detail; user code always uses dot-notation.

---

[Prev: Structs, Unions, and Enums](09_structs_unions_enums.md) | [Next: Generics](11_generics.md)
