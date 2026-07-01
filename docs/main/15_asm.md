# 15. Inline Assembly

Use `__asm__` for direct hardware access when no Artemis construct reaches the required level.

## Syntax

```
__asm__ {
    <instructions>
: <output constraints>
: <input constraints>
: <clobbers>
}
```

## Example — Read Timestamp Counter

```arc
i32 rdtsc_low() {
    i32 result;
    __asm__ {
        rdtsc
    : result
    :
    : eax, edx
    }
    return result;
}
```

## Example — Atomic Increment

```arc
void atomic_inc(i32* ptr) {
    __asm__ {
        lock xaddl $1, (ptr)
    :
    : ptr
    : memory
    }
}
```

## Constraint Modifiers

| Modifier | Meaning                  |
|----------|--------------------------|
| `r`      | Any general register     |
| `m`      | Memory operand           |
| `i`      | Immediate integer        |
| `=`      | Write-only output        |
| `+`      | Read-write output        |
| `memory` | Memory clobber (barrier) |

---

[Prev: Operator Overloading](14_operators.md) | [Next: C Interoperability](16_c_interop.md)
