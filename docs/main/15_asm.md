# 15. Inline Assembly

`__asm__` provides direct access to hardware instructions when no Artemis construct reaches the required level.

---

## Syntax

```
__asm__ {
    instructions
    : output_name "=constraint" (var)
    : input_name  "constraint"  (var)
    : "clobber", ...
}
```

The three `:` sections are all **optional**. Omit trailing sections you don't need:

```arc
__asm__ { nop }                    // no inputs, outputs, or clobbers
__asm__ { rdtsc : result : : eax, edx }  // output + clobbers, no inputs
```

---

## Constraint Modifiers

| Modifier | Meaning |
|----------|---------|
| `r`  | Any general-purpose register |
| `m`  | Memory operand |
| `i`  | Immediate integer constant |
| `=`  | Write-only output (prefix: `"=r"`) |
| `+`  | Read-write operand (prefix: `"+r"`) |

---

## Variable References in Instructions

Reference operands by name with `%name`:

```arc
i32 a = 3; i32 b = 4; i32 result;
__asm__ {
    add %a, %b
    : result "=r" (result)
    : a "r" (a), b "r" (b)
}
```

---

## No-Op

```arc
i32 main() {
    i32 x = 5;
    __asm__ { nop }
    // x is still 5
    return 0;
}
```

---

## Copy via Register

```arc
i32 src = 42; i32 dst = 0;
__asm__ {
    mov %src, %dst
    : dst "=r" (dst)
    : src "r"  (src)
}
// dst is now 42
```

---

## Clobber Lists

List registers or memory that the instruction may modify:

```arc
__asm__ {
    rdtsc
    : result "=r" (result)
    :
    : eax, edx
}
```

Use `"memory"` to act as a full memory barrier (prevents reordering around the asm block):

```arc
__asm__ {
    mfence
    :
    :
    : memory
}
```

---

## Notes

- Inline asm bodies are not validated by the Artemis compiler — invalid instructions produce LLVM errors.
- The asm body is passed verbatim to LLVM inline asm; it follows AT&T/Intel syntax depending on the LLVM target.
- For portability, keep asm blocks small and document the register contract.

---

[Prev: Operator Overloading](14_operators.md) | [Next: C Interoperability](16_c_interop.md)
