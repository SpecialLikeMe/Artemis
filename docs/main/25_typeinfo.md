# 25. Type Reflection (`@typeinfo`)

`@typeinfo(Type)` is a compiler builtin that returns a pointer to a compile-time constant `type_info` struct describing the given type. It requires no import or `extern` declaration — `type_info`, `type_info_field`, and `type_info_method` are built into the compiler.

---

## Basic Usage

```arc
type_info* ti = @typeinfo(i32);
printf("name=%s  size=%d  bits=%d\n", ti.name, ti.size, ti.bits);
// name=i32  size=4  bits=32

type_info* ts = @typeinfo(MyStruct);
printf("kind=%d  fields=%d\n", ts.kind, ts.field_count);
```

---

## `type_info` Layout

| Field | Type | Description |
|-------|------|-------------|
| `name` | `i8*` | Type name string (e.g. `"i32"`, `"Point"`) |
| `size` | `i32` | Byte size of the type |
| `align` | `i32` | Byte alignment |
| `kind` | `i32` | Kind constant (see table below) |
| `bits` | `i32` | Bit width for primitives; 0 for struct types |
| `is_signed` | `i32` | 1 if signed integer, 0 otherwise |
| `field_count` | `i32` | Number of fields (struct/istruc) |
| `fields` | `type_info_field*` | Array of field descriptors (or null) |
| `elem_type` | `type_info*` | Pointee's `type_info` for pointer kinds |
| `method_count` | `i32` | Number of methods (istruc only) |
| `methods` | `type_info_method*` | Array of method descriptors (or null) |

---

## Kind Constants

| Value | Meaning |
|-------|---------|
| `0` | Primitive (`i32`, `f64`, `bool`, etc.) |
| `1` | Pointer (`T*`) |
| `2` | Struct (plain `struct`) |
| `3` | Union (`union`) |
| `4` | Enum |
| `5` | Istruc (`istruc` — struct with methods) |
| `6` | Fixed array |
| `7` | Function pointer |
| `8` | Unknown / unresolved |

---

## `type_info_field` Layout

Each element of the `fields` array is a `type_info_field`:

| Field | Type | Description |
|-------|------|-------------|
| `name` | `i8*` | Field name string |
| `offset` | `i32` | Byte offset within the struct |
| `size` | `i32` | Field byte size |
| `align` | `i32` | Field alignment |

---

## Examples

### Primitive type

```arc
type_info* ti = @typeinfo(f64);
// ti.kind == 0  (primitive)
// ti.bits == 64
// ti.size == 8
// ti.is_signed == 0   (floats are not "signed" in the integer sense)
```

### Struct type

```arc
struct Point { i32 x; i32 y; }

type_info* tp = @typeinfo(Point);
// tp.kind        == 2    (struct)
// tp.size        == 8    (two i32s)
// tp.field_count == 2
// tp.fields[0].name   == "x"
// tp.fields[0].offset == 0
// tp.fields[1].name   == "y"
// tp.fields[1].offset == 4
```

### Istruc type

```arc
istruc Counter {
    i32 n;
    void __construct__(Counter* self) { self.n = 0; }
    void inc(Counter* self)           { self.n = self.n + 1; }
}

type_info* tc = @typeinfo(Counter);
// tc.kind == 5   (istruc)
// tc.field_count == 1   (field n)
// tc.method_count >= 1  (at least inc is visible)
```

### Pointer type

```arc
type_info* tp = @typeinfo(i32*);
// tp.kind == 1           (pointer)
// tp.size == 8           (64-bit pointer)
// tp.elem_type != null   (points to type_info for i32)
// tp.elem_type.kind == 0 (primitive)
```

---

## Notes

- `@typeinfo` operand must be a **type name**, not a variable or expression.
- The returned pointer points to a **compiler-generated constant** in the program's data segment — it is always valid and never null.
- No runtime overhead: the struct is emitted once per unique type and shared.
- Generic instantiations (`Box<i32>`, `Box<f64>`) each get their own `type_info`.

---

[Prev: Macros](29_macros.md) | [Next: Build System](build_system.md)
