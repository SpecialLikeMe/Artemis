# 26. Interfaces

Interfaces define a **contract** — a set of fields and/or methods that implementing `istruc` types must provide.

## Declaring an Interface

```arc
interface Drawable {
    fn draw(self: *Drawable) void;
    fn resize(self: *Drawable, w: i32, h: i32) void;
}
```

Methods declared without a body are **required** — any implementing `istruc` must provide them.

## Default Implementations

A method with a body in an interface is **optional** (a default). Implementing types may override it or inherit the default:

```arc
interface Printable {
    fn to_str(self: *Printable) *i8;  // required

    fn print(self: *Printable) void { // default: optional to override
        let s: *i8 = self.to_str();
        // ... print s ...
    }
}
```

## Implementing an Interface

Use `: InterfaceName` after the `istruc` name:

```arc
istruc Circle : Drawable {
    let mut x: i32;
    let mut y: i32;
    let mut radius: i32;

    fn draw(self: *Circle) void {
        // ... draw logic ...
    }

    fn resize(self: *Circle, w: i32, h: i32) void {
        self.radius = w / 2;
    }
}
```

The compiler verifies that all required methods are implemented. A compile error is raised for any missing method.

## Multiple Interfaces

An `istruc` can implement multiple interfaces by listing them comma-separated:

```arc
istruc Button : Drawable, Printable {
    let mut x: i32;
    let mut y: i32;
    let mut w: i32;
    let mut h: i32;
    let mut label: *i8;

    fn draw(self: *Button) void              { /* ... */ }
    fn resize(self: *Button, w: i32, h: i32) void { self.w = w; self.h = h; }
    fn to_str(self: *Button) *i8             { return self.label; }
}
```

## Interface Fields

Interfaces can declare **required fields** (no initializer) or **default fields** (with initializer):

```arc
interface Named {
    let mut name: *i8;   // required: implementing istruc must provide this field
    let mut id: i32 = 0; // optional default: inherited if not overridden
}
```

## Generic Interfaces

Interfaces may carry type parameters:

```arc
interface Mapper<T, U> {
    fn map(self: *Mapper<T, U>, input: T) U;
}

istruc DoubleInt : Mapper<i32, i32> {
    fn map(self: *DoubleInt, input: i32) i32 { return input * 2; }
}
```

---

## Interfaces as Parameter Types

An `interface` type can be used directly as a parameter type, enabling polymorphism without generics:

```arc
fn render(d: interface Drawable) void {
    d.draw();
}
```

At the call site the compiler coerces the concrete `istruc` value to the interface's pointer representation and passes it to `render`. This is the primary form of runtime polymorphism in Artemis — and it is opt-in.

```arc
istruc Circle : Drawable {
    let mut r: i32;
    fn draw(self: *Circle) void { /* ... */ }
    fn resize(self: *Circle, w: i32, h: i32) void { self.r = w / 2; }
}

let mut c: Circle();
c.r = 5;
render(c);   // c passed as Drawable interface pointer
```

---

## Inheritance vs Interfaces

Artemis does not support class inheritance. Use interfaces to share behaviour across unrelated types.

---

[Prev: Error Handling](24_error_handling.md) | [Next: Type Aliases and auto](28_typedef_auto.md)
