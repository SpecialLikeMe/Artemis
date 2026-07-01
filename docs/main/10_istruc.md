# 10. Classes (istruc)

`istruc` (inline struct with methods) provides object-oriented features with zero overhead unless you use virtual dispatch.

## Basic istruc

```arc
istruc Vec3 {
    f64 x; f64 y; f64 z;

    void __construct__(&self, f64 x, f64 y, f64 z) {
        self.x = x; self.y = y; self.z = z;
    }

    f64 dot(&self, Vec3* other) {
        return self.x * (*other).x + self.y * (*other).y + self.z * (*other).z;
    }

    Vec3 add(&self, Vec3 other) {
        Vec3 result(self.x + other.x, self.y + other.y, self.z + other.z);
        return result;
    }
}

i32 main() {
    Vec3 a(1.0, 0.0, 0.0);
    Vec3 b(0.0, 1.0, 0.0);
    f64  d = a.dot(&b);   // 0.0
    return 0;
}
```

## Constructors (`__construct__`)

The method named `__construct__` is called automatically at the declaration site:

```arc
Vec3 v(1.0, 2.0, 3.0);   // calls v.__construct__(1.0, 2.0, 3.0)
```

A zero-argument `__construct__` is called when you declare with no args:
```arc
istruc Empty {
    i32 x;
    void __construct__(&self) { self.x = 0; }
}
Empty e;   // calls e.__construct__()
```

## Access Modifiers

```arc
istruc BankAccount {
    public    i32 id;
    private   f64 balance;
    protected f64 interest_rate;

    public void deposit(&self, f64 amount) {
        self.balance = self.balance + amount;
    }
    public f64 get_balance(&self) { return self.balance; }
    private void recalculate(&self) { /* ... */ }
}
```

- `public` (default): accessible everywhere
- `private`: only within the class's own methods
- `protected`: within the class and its subclasses

## Static Methods

Static methods belong to the class, not instances. Call via `ClassName.method()`:

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

## Inheritance

```arc
istruc Animal {
    i32 legs;
    void __construct__(&self, i32 l) { self.legs = l; }
    void speak(&self) { /* base */ }
}

istruc Dog : Animal {
    void __construct__(&self) { self.legs = 4; }
    void fetch(&self) { /* ... */ }
}
```

## Virtual Dispatch

Prefix methods with `virtual` to enable polymorphism. Use `override` in subclasses:

```arc
istruc Shape {
    virtual f64 area(&self) { return 0.0; }
}

istruc Circle : Shape {
    f64 radius;
    void __construct__(&self, f64 r) { self.radius = r; }
    override f64 area(&self) { return 3.14159 * self.radius * self.radius; }
}

istruc Square : Shape {
    f64 side;
    void __construct__(&self, f64 s) { self.side = s; }
    override f64 area(&self) { return self.side * self.side; }
}
```

## `mandatory virtual`

Forces all subclasses to provide an override:
```arc
istruc Base {
    mandatory virtual void do_work(&self);
}
```

## `local` (Friend-Like Declarations)

Functions declared with `local` inside an istruc can access its private members:
```arc
istruc Node {
    private i32 data;
    local i32 get_node_data(Node* n) { return (*n).data; }
}
```

## Operator Overloading

Covered in detail in [Chapter 14](14_operators.md). Brief example:
```arc
istruc Complex {
    f64 re; f64 im;
    Complex operator+(Complex other) {
        Complex r;
        r.re = self.re + other.re;
        r.im = self.im + other.im;
        return r;
    }
}
```

## Conversion Operators

```arc
istruc Celsius {
    f64 value;
    explicit operator f64() { return self.value; }
}

Celsius temp;
temp.value = 100.0;
f64 raw = (f64)temp;   // calls conversion operator
```

> **Challenge:** Implement a singly-linked list node as an `istruc` with an `i32 value` and an `i32* next` pointer. Add a static `make(i32 v)` constructor and a method `i32 sum()` that walks the chain and returns the total.

---

[Prev: Structs, Unions, and Enums](09_structs_unions_enums.md) | [Next: Generics](11_generics.md)
