# 2. Getting Started

## Hello, World

```arc
extern "C" { i32 puts(i8* s); }

i32 main() {
    puts("Hello, World!");
    return 0;
}
```

Save as `hello.arc`, then:
```
arc run hello.arc
```

## A More Complete Example

```arc
extern "C" { void* malloc(u64 n); void free(void* p); i32 printf(i8* fmt, ...); }

istruc Counter {
    i32 value;
    void __construct__(&self) { self.value = 0; }
    void inc(&self)           { self.value = self.value + 1; }
    i32  get(&self)           { return self.value; }
}

i32 main() {
    Counter c;
    c.inc(); c.inc(); c.inc();
    printf("Count: %d\n", c.get());   // Count: 3
    return 0;
}
```

> **Challenge:** Modify `Counter` to support a `dec()` method and a `reset()` method. Then modify `main` to count to 5, decrement twice, then reset.

---

[Prev: Introduction](01_introduction.md) | [Next: Types](03_types.md)
