# 11. Generics

Functions and istrucs can be parameterised over types using `<T>` syntax.

## Generic Functions

```arc
T max<T>(T a, T b) { return a > b ? a : b; }

i32 main() {
    i32 x = max<i32>(3, 7);     // 7
    f64 y = max<f64>(1.5, 2.5); // 2.5
    return 0;
}
```

## Generic istrucs

```arc
istruc Stack<T> {
    T   data[64];
    i32 top;

    void __construct__(&self) { self.top = 0; }

    void push(&self, T val) {
        self.data[self.top] = val;
        self.top = self.top + 1;
    }

    T pop(&self) {
        self.top = self.top - 1;
        return self.data[self.top];
    }

    bool empty(&self) { return self.top == 0; }
}

i32 main() {
    Stack<i32> s;
    s.push(1); s.push(2); s.push(3);
    i32 x = s.pop();   // 3
    return 0;
}
```

## Monomorphisation

Type parameters are resolved at compile time. Each distinct instantiation (`Stack<i32>`, `Stack<f64>`, etc.) produces a separate set of compiled functions. There is no runtime type erasure.

> **Challenge:** Write a generic `Pair<A, B>` istruc with fields `first` and `second`. Add a method `void swap(&self)` that exchanges the two values (same type only — use `Pair<T, T>`).

---

[Prev: Classes (istruc)](10_istruc.md) | [Next: Namespaces](12_namespaces.md)
