# 8. Arrays

## Stack Arrays

```arc
let mut nums: [8]i32;
nums[0] = 1;
nums[7] = 8;
```

The syntax is `[N]T` for a fixed-size array of `N` elements of type `T`.

## Initialization

```arc
let mut primes: [5]i32;
primes[0] = 2; primes[1] = 3; primes[2] = 5; primes[3] = 7; primes[4] = 11;
```

## Passing to Functions

Arrays decay to pointers when passed to functions:

```arc
fn fill(arr: *i32, n: i32, val: i32) void {
    let mut i: i32 = 0;
    while (i < n) { arr[i] = val; i = i + 1; }
}

pub fn main() i32 {
    let mut buf: [10]i32;
    fill(buf, 10, 0);
    return 0;
}
```

## Arrays as istruc Fields

```arc
istruc Grid {
    let mut cells: [64]i32;
    let mut width: i32;
    let mut height: i32;

    fn set(self: *Grid, x: i32, y: i32, v: i32) void {
        self.cells[y * self.width + x] = v;
    }
    fn get(self: *Grid, x: i32, y: i32) i32 {
        return self.cells[y * self.width + x];
    }
}
```

Pointer-typed array fields are also supported:

```arc
istruc Pool {
    let mut slots: [32]*void;
    let mut top: i32;
}
```

## Range-Based For Loop

Iterate over a slice (pointer + length) using `for .. in`:

```arc
let mut arr: [5]i32;
arr[0] = 1; arr[1] = 2; arr[2] = 3; arr[3] = 4; arr[4] = 5;

for (let v: i32 in arr[0..5]) {
    // v takes each element value
}
```

---

[Prev: Pointers](07_pointers.md) | [Next: Structs, Unions, and Enums](09_structs_unions_enums.md)
