# 11. Generics

Functions and istrucs can be parameterised over types using `<T>` syntax.

## Generic Functions

```arc
fn max<T>(a: T, b: T) T { return a > b ? a : b; }

pub fn main() i32 {
    let x: i32 = max<i32>(3, 7);      // 7
    let y: f64 = max<f64>(1.5, 2.5);  // 2.5
    return 0;
}
```

## Generic istrucs

```arc
istruc Stack<T> {
    let mut data: [64]T;
    let mut top: i32;

    fn __construct__(self: *Stack) void { self.top = 0; }

    fn push(self: *Stack, val: T) void {
        self.data[self.top] = val;
        self.top = self.top + 1;
    }

    fn pop(self: *Stack) T {
        self.top = self.top - 1;
        return self.data[self.top];
    }

    fn empty(self: *Stack) bool { return self.top == 0; }
}

pub fn main() i32 {
    let mut s: Stack<i32>();
    s.push(1); s.push(2); s.push(3);
    let x: i32 = s.pop();   // 3
    return 0;
}
```

## Monomorphisation

Type parameters are resolved at compile time. Each distinct instantiation (`Stack<i32>`, `Stack<f64>`, etc.) produces a separate set of compiled functions. There is no runtime type erasure.

> **Challenge:** Write a generic `Pair<A, B>` istruc with fields `first` and `second`. Add a method `fn swap(self: *Pair) void` that exchanges the two values (same type only — use `Pair<T, T>`).

---

## Generics Guidance

Artemis generics use monomorphization — each distinct instantiation is compiled separately. Three conventions keep generic code manageable.

> These are documentation conventions, not enforced language rules. The compiler does not reject code that departs from them.

### Convention 1: Prefer a Single Type Parameter

Generic code works best with a single type parameter `T`. Multiple type parameters increase the instantiation surface and are harder to reason about:

```arc
// Preferred: single type param
istruc Option<T> {
    let mut value: T;
    let mut has_value: b8;
}

// More complex — consider whether composition is cleaner
istruc Pair<A, B> {
    let mut first: A;
    let mut second: B;
}
```

### Convention 2: Document Implicit Requirements

Artemis generics are unconstrained — any type can be substituted. Document assumptions explicitly:

```arc
// Requires: T is trivially copyable (no internal pointers).
fn swap<T>(a: *T, b: *T) void {
    let tmp: T = (*a);
    (*a) = (*b);
    (*b) = tmp;
}
```

This makes monomorphization failures easier to diagnose.

### Convention 3: Limit Nesting Depth

Deep generic instantiation can cause exponential compile-time growth. The informal limit is three levels:

```
vector<T>                      // Level 1
map<K, vector<V>>              // Level 2
cache<Key, map<K, vector<V>>>  // Level 3 — maximum recommended
```

Beyond three levels, consider erasing the inner type to `*void` and casting at the boundary.

| Convention | Rule | Rationale |
|------------|------|-----------|
| 1 | Prefer single `<T>` | Keeps instantiation space small |
| 2 | Document implicit type requirements | Prevents confusing monomorphization errors |
| 3 | Max ~3 levels of generic nesting | Avoids exponential compile-time and binary bloat |

---

[Prev: Classes (istruc)](10_istruc.md) | [Next: Namespaces](12_namespaces.md)
