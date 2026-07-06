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

    void __construct__(Stack* self) { self.top = 0; }

    void push(Stack* self, T val) {
        self.data[self.top] = val;
        self.top = self.top + 1;
    }

    T pop(Stack* self) {
        self.top = self.top - 1;
        return self.data[self.top];
    }

    bool empty(Stack* self) { return self.top == 0; }
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

> **Challenge:** Write a generic `Pair<A, B>` istruc with fields `first` and `second`. Add a method `void swap(Pair* self)` that exchanges the two values (same type only — use `Pair<T, T>`).

---

## Generics Guidance

Artemis generics use monomorphization — each distinct instantiation is compiled separately. Three conventions keep generic code manageable.

> These are documentation conventions, not enforced language rules. The compiler does not reject code that departs from them.

### Convention 1: Prefer a Single Type Parameter

Generic code works best with a single type parameter `T`. Multiple type parameters increase the instantiation surface and are harder to reason about:

```arc
// Preferred: single type param
istruc Option<T> {
    T   value;
    b8  has_value;
}

// More complex — consider whether composition is cleaner
istruc Pair<A, B> {
    A first;
    B second;
}
```

### Convention 2: Document Implicit Requirements

Artemis generics are unconstrained — any type can be substituted. Document assumptions explicitly:

```arc
// Requires: T is trivially copyable (no internal pointers).
void swap<T>(T* a, T* b) {
    T tmp = (*a);
    (*a) = (*b);
    (*b) = tmp;
}
```

This makes monomorphization failures easier to diagnose.

### Convention 3: Limit Nesting Depth

Deep generic instantiation can cause exponential compile-time growth. The informal limit is three levels:

```
vector<T>               // Level 1
map<K, vector<V>>       // Level 2
cache<Key, map<K, vector<V>>>  // Level 3 — maximum recommended
```

Beyond three levels, consider erasing the inner type to `void*` and casting at the boundary.

| Convention | Rule | Rationale |
|------------|------|-----------|
| 1 | Prefer single `<T>` | Keeps instantiation space small |
| 2 | Document implicit type requirements | Prevents confusing monomorphization errors |
| 3 | Max ~3 levels of generic nesting | Avoids exponential compile-time and binary bloat |

---

[Prev: Classes (istruc)](10_istruc.md) | [Next: Namespaces](12_namespaces.md)
