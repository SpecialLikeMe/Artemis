# 4. Variables and Constants

## Local Variables

```arc
i32 x = 10;
i32 y;        // uninitialized (undefined value — initialize before use)
```

## Global Variables

```arc
i32 global_counter = 0;

void increment() { global_counter = global_counter + 1; }
```

## `constexpr` — Compile-Time Constants

`constexpr` marks a variable as a compile-time constant. The value must be a constant expression (literals, `sizeof`, arithmetic on other constexprs):

```arc
constexpr i32 MAX_SIZE = 256;
constexpr f64 TAU      = 6.28318;
constexpr i32 BUF_WORDS = MAX_SIZE / sizeof(i32);
```

## `consteval` — Manual Construction

`consteval` declares a variable whose constructor you call explicitly, rather than having it invoked automatically at the declaration site:

```arc
istruc Buffer {
    i32* data;
    i32  len;
    void __construct__(&self, i32 n) {
        // allocate n i32s ...
    }
}

consteval Buffer buf;    // declared but NOT constructed yet
buf.__construct__(100);  // you call it yourself
```

This is useful for placement-new patterns, lazy initialization, or careful control of construction order.

## `sizeof`

```arc
u64 sz  = sizeof(i32);      // 4
u64 sz2 = sizeof(MyStruct);
```

---

[Prev: Types](03_types.md) | [Next: Functions](05_functions.md)
