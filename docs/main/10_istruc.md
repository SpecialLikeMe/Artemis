# 10. Classes (istruc)

`istruc` (inline struct with methods) provides object-oriented features without vtable or garbage-collector overhead. It is like a C struct with attached methods. There is no inheritance — use [interfaces](26_interfaces.md) for shared behaviour contracts.

---

## Basic Declaration

```arc
istruc Vec3 {
    let mut x: f64;
    let mut y: f64;
    let mut z: f64;

    fn __construct__(self: *Vec3, a: f64, b: f64, c: f64) void {
        self.x = a; self.y = b; self.z = c;
    }

    fn dot(self: *Vec3, other: Vec3) f64 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    fn add(self: *Vec3, other: Vec3) Vec3 {
        let mut result: Vec3(self.x + other.x, self.y + other.y, self.z + other.z);
        return result;
    }
}

pub fn main() i32 {
    let mut a: Vec3(1.0, 0.0, 0.0);
    let mut b: Vec3(0.0, 1.0, 0.0);
    let d: f64 = a.dot(b);   // 0.0
    return 0;
}
```

---

## Explicit Self Parameter

Every method declares an explicit pointer to the owning type as its **first** parameter, conventionally named `self`. Dot-notation calls (`a.method()`) automatically pass the receiver.

```arc
istruc Counter {
    let mut count: i32;

    fn __construct__(self: *Counter) void {
        self.count = 0;
    }

    fn increment(self: *Counter) void {
        self.count = self.count + 1;
    }

    fn get(self: *Counter) i32 {
        return self.count;
    }
}

pub fn main() i32 {
    let mut c: Counter();
    c.increment();
    c.increment();
    return c.get();   // 2
}
```

---

## Field Default Values

Fields can have default values that are applied before `__construct__` runs:

```arc
istruc Config {
    let mut width: i32 = 640;
    let mut height: i32 = 480;
    let mut enabled: bool = true;

    fn __construct__(self: *Config) void { }
}

pub fn main() i32 {
    let mut cfg: Config();
    // cfg.width == 640, cfg.height == 480, cfg.enabled == true
    cfg.width = 800;
    return 0;
}
```

---

## Constructor Arguments

```arc
istruc Pair {
    let mut first: i32;
    let mut second: i32;

    fn __construct__(self: *Pair, a: i32, b: i32) void {
        self.first = a;
        self.second = b;
    }

    fn sum(self: *Pair) i32 {
        return self.first + self.second;
    }
}

pub fn main() i32 {
    let mut p: Pair(10, 20);
    return p.sum();   // 30
}
```

---

## Implementing Interfaces

An istruc can implement one or more interfaces. The interface's fields must appear in the istruc (they form a prefix):

```arc
interface Drawable {
    let mut color: i32;
}

istruc Circle : Drawable {
    let mut color: i32 = 0xFF0000;   // red
    let mut radius: f64;

    fn __construct__(self: *Circle, r: f64) void {
        self.radius = r;
    }

    fn area(self: *Circle) f64 {
        return 3.14159 * self.radius * self.radius;
    }
}

pub fn paint(d: interface Drawable) void {
    // d.color is accessible through the interface
}
```

---

## Operator Overloading

Define `operator+`, `operator==`, etc. as methods:

```arc
istruc Vec2 {
    let mut x: f64;
    let mut y: f64;

    fn __construct__(self: *Vec2, a: f64, b: f64) void {
        self.x = a; self.y = b;
    }

    fn operator+(self: *Vec2, other: Vec2) Vec2 {
        let mut r: Vec2(self.x + other.x, self.y + other.y);
        return r;
    }

    fn operator==(self: *Vec2, other: Vec2) bool {
        return self.x == other.x && self.y == other.y;
    }
}
```

---

## Notes

- There is no `this` keyword — the self pointer is always explicitly declared.
- istruc types cannot inherit from other istrucs (use interfaces for polymorphism).
- Fields are laid out in declaration order (same as C structs).
- `@typeinfo(MyIstruc)` returns `kind == 5`.

---

[Prev: Structs, Unions, Enums](09_structs_unions_enums.md) | [Next: Generics](11_generics.md)
