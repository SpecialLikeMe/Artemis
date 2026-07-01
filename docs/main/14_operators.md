# 14. Operator Overloading

Define custom behaviour for arithmetic and comparison operators on `istruc` types.

## Arithmetic Operators

```arc
istruc Vec2 {
    f64 x; f64 y;

    Vec2 operator+(Vec2 other) {
        Vec2 r;
        r.x = self.x + other.x;
        r.y = self.y + other.y;
        return r;
    }

    Vec2 operator-(Vec2 other) {
        Vec2 r;
        r.x = self.x - other.x;
        r.y = self.y - other.y;
        return r;
    }

    Vec2 operator*(f64 s) {
        Vec2 r;
        r.x = self.x * s;
        r.y = self.y * s;
        return r;
    }
}

i32 main() {
    Vec2 a; a.x = 1.0; a.y = 2.0;
    Vec2 b; b.x = 3.0; b.y = 4.0;
    Vec2 c = a + b;    // (4.0, 6.0)
    Vec2 d = c * 2.0;  // (8.0, 12.0)
    return 0;
}
```

## Comparison Operators

```arc
istruc Complex {
    f64 re; f64 im;

    bool operator==(Complex other) {
        return self.re == other.re && self.im == other.im;
    }

    bool operator!=(Complex other) {
        return !(self == other);
    }
}
```

## Subscript Operator

```arc
istruc IntBuf {
    i32 data[64];

    i32 operator[](i32 idx) {
        return self.data[idx];
    }
}
```

## Conversion Operators

Use `explicit operator T()` to define a cast to type `T`:
```arc
istruc Celsius {
    f64 value;
    explicit operator f64() { return self.value; }
}

Celsius temp;
temp.value = 100.0;
f64 raw = (f64)temp;
```

## Supported Operators

`+`, `-`, `*`, `/`, `%`, `==`, `!=`, `<`, `>`, `<=`, `>=`, `[]`, `&` (bit-and), `|`, `^`, `<<`, `>>`

---

[Prev: Memory Management](13_memory.md) | [Next: Inline Assembly](15_asm.md)
