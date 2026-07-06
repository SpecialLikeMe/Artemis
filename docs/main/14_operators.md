# 14. Operator Overloading

Custom operator behaviour is defined as methods on `istruc` types. Every overloaded operator must declare an explicit `self` pointer as its first parameter, exactly like any other method.

---

## Arithmetic Operators

```arc
istruc Vec2 {
    f64 x; f64 y;

    void __construct__(Vec2* self, f64 a, f64 b) { self.x = a; self.y = b; }

    Vec2 operator+(const Vec2* self, Vec2 other) {
        Vec2 r;
        r.x = self.x + other.x;
        r.y = self.y + other.y;
        return r;
    }

    Vec2 operator-(const Vec2* self, Vec2 other) {
        Vec2 r;
        r.x = self.x - other.x;
        r.y = self.y - other.y;
        return r;
    }

    Vec2 operator*(const Vec2* self, f64 s) {
        Vec2 r;
        r.x = self.x * s;
        r.y = self.y * s;
        return r;
    }
}

i32 main() {
    Vec2 a(1.0, 2.0);
    Vec2 b(3.0, 4.0);
    Vec2 c = a + b;     // (4.0, 6.0)
    Vec2 d = c * 2.0;   // (8.0, 12.0)
    return 0;
}
```

---

## Comparison Operators

```arc
istruc Complex {
    f64 re; f64 im;

    bool operator==(const Complex* self, Complex other) {
        return self.re == other.re && self.im == other.im;
    }

    bool operator!=(const Complex* self, Complex other) {
        return !((*self) == other);
    }

    bool operator<(const Complex* self, Complex other) {
        // e.g., compare by magnitude squared
        f64 lm = self.re * self.re + self.im * self.im;
        f64 rm = other.re * other.re + other.im * other.im;
        return lm < rm;
    }
}
```

---

## Subscript Operator

```arc
istruc IntBuf {
    i32 data[64];

    i32 operator[](const IntBuf* self, i32 idx) {
        return self.data[idx];
    }
}

IntBuf buf;
buf.data[0] = 99;
i32 v = buf[0];   // calls operator[], result is 99
```

---

## Assignment Operator (`operator=`)

When a class defines `operator=`, every assignment to a variable of that class type calls it — including `= expr` initialization:

```arc
istruc String {
    char* data;
    i32   len;

    void operator=(String* self, String other) {
        self.data = other.data;   // shallow reference copy
        self.len  = other.len;
    }
}

String s1; s1.data = "hello"; s1.len = 5;
String s2 = s1;    // calls String.operator=
s2 = s1;           // also calls operator=
```

**Note:** `= expr` in a declaration calls `operator=`, not `__construct__`. If you need constructor semantics from a value, use `()` or `{}` instead.

---

## Conversion Operators

A conversion operator lets you cast the type to another type using `(T)expr`:

```arc
istruc Ratio {
    i32 num; i32 den;

    void __construct__(Ratio* self, i32 n, i32 d) { self.num = n; self.den = d; }

    operator i32(const Ratio* self) {
        return self.num / self.den;
    }

    operator f64(const Ratio* self) {
        return (f64)self.num / (f64)self.den;
    }
}

Ratio r(10, 3);
i32 iv = (i32)r;    // 3   — integer division
f64 fv = (f64)r;    // 3.333...
```

---

## Supported Operators

| Operator | Example definition |
|----------|--------------------|
| `+`  | `T operator+(const T* self, T other)` |
| `-`  | `T operator-(const T* self, T other)` |
| `*`  | `T operator*(const T* self, T other)` |
| `/`  | `T operator/(const T* self, T other)` |
| `%`  | `T operator%(const T* self, T other)` |
| `==` | `bool operator==(const T* self, T other)` |
| `!=` | `bool operator!=(const T* self, T other)` |
| `<`  | `bool operator<(const T* self, T other)` |
| `>`  | `bool operator>(const T* self, T other)` |
| `<=` | `bool operator<=(const T* self, T other)` |
| `>=` | `bool operator>=(const T* self, T other)` |
| `[]` | `T operator[](const T* self, i32 idx)` |
| `=`  | `void operator=(T* self, T other)` |
| `&`  | `T operator&(const T* self, T other)` |
| `\|`  | `T operator\|(const T* self, T other)` |
| `^`  | `T operator^(const T* self, T other)` |
| `<<` | `T operator<<(const T* self, i32 n)` |
| `>>` | `T operator>>(const T* self, i32 n)` |
| `TypeName` | `operator TypeName(const T* self)` — conversion |

The self pointer may be `const T*` (read-only) for operators that do not modify the receiver, or `T*` for `operator=` and compound assignment operators.

---

[Prev: Memory Management](13_memory.md) | [Next: Inline Assembly](15_asm.md)
