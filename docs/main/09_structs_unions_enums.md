# 9. Structs, Unions, and Enums

## Structs

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

Access fields via dot notation. Pass by value or pointer:
```arc
Point p;
p.x = 1.0;
p.y = 2.0;

void translate(Point* pt, f64 dx, f64 dy) {
    (*pt).x = (*pt).x + dx;
    (*pt).y = (*pt).y + dy;
}
```

## Unions

All fields share the same memory:
```arc
union IntOrFloat {
    i32 i;
    f32 f;
}

IntOrFloat u;
u.i = 0x3f800000;
// u.f is now 1.0 (IEEE 754)
```

## Typedefs

```arc
typedef i32   ErrorCode;
typedef Point Vec2;

ErrorCode err = 0;
Vec2      pos;
```

## Enums

```arc
enum Color {
    Red,
    Green,
    Blue,
    Custom = 100
}

Color c = Color.Green;
if (c == Color.Green) { /* ... */ }
```

Enum variants are `i32` integers. `Color.Red` is `0`, `Color.Green` is `1`, `Color.Custom` is `100`.

> **Challenge:** Define a struct `Matrix2x2` with fields `a`, `b`, `c`, `d` (all `f64`). Write a function `f64 det(Matrix2x2* m)` that returns `a*d - b*c`.

---

[Prev: Arrays](08_arrays.md) | [Next: Classes (istruc)](10_istruc.md)
