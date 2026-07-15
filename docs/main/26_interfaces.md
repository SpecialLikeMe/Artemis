# 26. Interfaces

Interfaces define a **contract** — a set of methods and/or fields that a type must provide. Interfaces have no fields of their own and no vtable; they are a compile-time check only.

## Declaring an Interface

```arc
interface Drawable {
    void draw(Drawable* self);
    void resize(Drawable* self, i32 w, i32 h);
}
```

Methods declared without a body are **required** — any implementing `istruc` must provide them.

## Default Implementations

A method with a body in an interface is **optional** (a default). Implementing types may override it or inherit the default:

```arc
interface Printable {
    i8* to_str(Printable* self);  // required

    void print(Printable* self) { // default: optional to override
        i8* s = self.to_str();
        // ... print s ...
    }
}
```

## Implementing an Interface

Use `: InterfaceName` after the `istruc` name:

```arc
istruc Circle : Drawable {
    i32 x;
    i32 y;
    i32 radius;

    void draw(Circle* self) {
        // ... draw logic ...
    }

    void resize(Circle* self, i32 w, i32 h) {
        self.radius = w / 2;
    }
}
```

The compiler verifies that all required methods are implemented. A compile error is raised for any missing method.

## Multiple Interfaces

An `istruc` can implement multiple interfaces by listing them comma-separated:

```arc
istruc Button : Drawable, Printable {
    i32 x; i32 y; i32 w; i32 h;
    i8* label;

    void draw(Button* self)       { /* ... */ }
    void resize(Button* self, i32 w, i32 h) { self.w = w; self.h = h; }
    i8*  to_str(Button* self)     { return self.label; }
}
```

## Interface Fields

Interfaces can declare **required fields** (no initializer) or **default fields** (with initializer):

```arc
interface Named {
    i8* name;        // required: implementing istruc must provide this field
    i32 id = 0;      // optional default: inherited if not overridden
}
```

## Generic Interfaces

Interfaces may carry type parameters, making them usable with any concrete type:

```arc
interface Mapper<T, U> {
    U map(Mapper<T, U>* self, T input);
}

istruc DoubleInt : Mapper<i32, i32> {
    i32 map(DoubleInt* self, i32 input) { return input * 2; }
}
```

Implementing an interface with concrete type arguments verifies that all required methods have the correct signatures.

---

## Interfaces as Parameter Types

An `interface` type can be used directly as a parameter type, enabling polymorphism without generics:

```arc
interface Drawable {
    void draw(Drawable* self);
}

void render(interface Drawable d) {
    d.draw();
}
```

At the call site the compiler builds a fat pointer (concrete pointer + vtable pointer) from the concrete `istruc` value and passes it to `render`. This is the only form of runtime polymorphism in Artemis — and it is opt-in.

```arc
istruc Circle : Drawable {
    i32 r;
    void draw(Circle* self) { /* ... */ }
}

Circle c;
c.r = 5;
render(c);   // c passed as Drawable fat pointer
```

---

## Inheritance vs Interfaces

Artemis does not support class inheritance. Use interfaces to share behaviour across unrelated types.

---

[Prev: Error Handling](24_error_handling.md) | [Next: Type Aliases and auto](28_typedef_auto.md)
