# 8. Arrays

## Stack Arrays

```arc
i32 nums[8];
nums[0] = 1;
nums[7] = 8;
```

## Initialization

```arc
i32 primes[5];
primes[0] = 2; primes[1] = 3; primes[2] = 5; primes[3] = 7; primes[4] = 11;
```

## Passing to Functions

Arrays decay to pointers when passed to functions:
```arc
void fill(i32* arr, i32 n, i32 val) {
    for (i32 i = 0; i < n; i = i + 1) arr[i] = val;
}

i32 main() {
    i32 buf[10];
    fill(buf, 10, 0);
    return 0;
}
```

## Arrays as istruc Fields

```arc
istruc Grid {
    i32 cells[64];
    i32 width;
    i32 height;

    void set(&self, i32 x, i32 y, i32 v) {
        self.cells[y * self.width + x] = v;
    }
    i32 get(&self, i32 x, i32 y) {
        return self.cells[y * self.width + x];
    }
}
```

Pointer-typed array fields are also supported:
```arc
istruc Pool {
    void* slots[32];   // array of 32 void* pointers
    i32   top;
}
```

---

[Prev: Pointers](07_pointers.md) | [Next: Structs, Unions, and Enums](09_structs_unions_enums.md)
