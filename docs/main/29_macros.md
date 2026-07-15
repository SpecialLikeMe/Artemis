# 29. Macros

Artemis provides two macro systems: **const-resolve macros** (token-rewriting, like Rust's `macro_rules!`) and **proc macros** (procedural, operating on tokenstreams).

---

## Const-Resolve Macros

Defined with `const_resolve`, these macros match token patterns and expand them at parse time.

```arc
const_resolve double_it {
    ($x:expr) => { (($x) + ($x)) }
}

i32 main() {
    i32 result = double_it(21);  // expands to ((21) + (21)) = 42
    return result - 42;
}
```

---

### Pattern Fragments

| Fragment       | Matches                                         |
|----------------|-------------------------------------------------|
| `$name:expr`   | Any expression                                  |
| `$name:ident`  | An identifier                                   |
| `$name:literal`| An integer, float, string, or character literal |
| `$name:ty`     | A type expression (including pointer stars)     |
| `$name:tt`     | Any single token or balanced `()`/`[]`/`{}`    |
| `$name:stmt`   | A statement (including its `;`)                 |
| `$name:block`  | A `{ ... }` block                               |
| `$name:path`   | A `.`-separated identifier path               |

---

### Multiple Rules

A macro can have multiple rules; the first matching rule wins:

```arc
const_resolve make_min {
    ($a:expr, $b:expr) => { (($a) < ($b) ? ($a) : ($b)) }
    ($a:expr)           => { $a }
}
```

---

### Statement-Expanding Macros (the `()` form)

Macros that expand into statements omit the trailing `;` from the expansion — the call-site semicolon terminates the expanded statement:

```arc
const_resolve let_i32 {
    ($name:ident = $val:expr) => { i32 $name = $val }
}

i32 main() {
    let_i32(x = 10);   // expands to: i32 x = 10;
    return x - 10;
}
```

---

### Variadic Patterns

Use `$group($cap:kind)*` / `+` / `?` for repetition. The modifier follows the closing `)` directly — there is no comma between the `$()` group and the modifier:

| Modifier | Meaning            |
|----------|--------------------|
| `*`      | Zero or more times |
| `+`      | One or more times  |
| `?`      | Zero or one time   |

The group must be named: `$lit($val:expr)*` — the name (`lit`) is used to expand the repetition in the body.

```arc
const_resolve sum_all {
    ($first:expr, $rest($v:expr)*) => { ($first + (0 $rest(+ $v)*)) }
}

i32 main() {
    i32 s = sum_all(1, 2, 3, 4);   // 10
    return s - 10;
}
```

#### Multiple Variadic Groups

When a pattern has two or more variadic groups that could be ambiguous, separate them with `;`:

```arc
const_resolve zip_add {
    ($a($x:expr)* ; $b($y:expr)*) => { ... }
}
```

When the boundary is unambiguous (e.g., different token types separate the groups), the `;` can be omitted.

---

### Syntax-Definition Macros (the `[]` form)

`[]` rules define **new statement-level syntax** — they trigger on a keyword rather than on the macro name itself. This lets you write language constructs that look like built-in statements.

#### Definition

```arc
const_resolve create {
    () => {},

    ($val:expr) => {
        auto x = $val;
    },

    ["let", $name:ident, $eq("=", $val:expr)?] => {
        auto $name = $eq?;
    }
}
```

#### Pattern Syntax in `[]` Rules

- **Comma-separated elements** — commas in a `[]` pattern are separators, not tokens to match
- **`"word"`** — matches a literal identifier or token with that exact text in the source
- **`$name:fragment`** — captures a fragment (same types as `()` form)
- **`$group(sub_pattern)?`** — optional group; `$group?` in the body emits the group's captures when present and nothing when absent

#### Invocation

`[]` rules fire when the **first literal word** of the pattern appears in source code. No `!` suffix is needed. The macro name is not used in the invocation:

```arc
int main() {
    create(4 + 1);      // matches () and ($val:expr) rules — invoked by name
    let y = 4 - 4;      // matches ["let",...] rule — triggered by literal "let"
    return y;
}
```

#### Optional Groups in the Body

Use `$name?` to emit the content of an optional variadic group, or nothing when the group was absent:

```arc
// Pattern:   ["let", $name:ident, $eq("=", $val:expr)?]
// Body:      auto $name = $eq?;
//
// let x = 5;  →  auto x = 5;
// let x;      →  auto x = ;       (caller must ensure the pattern always has '=')
```

#### Expansion Timing

`[]` macro rules are registered during parsing, before any code is emitted. The expansion is spliced directly into the token stream where the trigger word appears, so the resulting tokens are parsed as normal Artemis statements. Name resolution and namespace/dot-path disambiguation happen after expansion.

#### Complete Example

```arc
const_resolve create {
    () => {},
    ($val:expr) => {
        auto x = $val;
    },
    ["let", $name:ident, $eq("=", $val:expr)?] => {
        auto $name = $eq?;
    }
}

int main() {
    create(4+1);    // expands to: auto x = 4+1;
    let y = 4-4;    // expands to: auto y = 4-4;
    return y;       // y == 0
}
```

---

### Invocation Delimiters

A `()` or `[]` or `{}` macro can be invoked with any of the three bracket forms — the choice does not affect matching:

```arc
double_it(x)    // parenthesis form
double_it[x]    // bracket form (identical semantics)
double_it{x}    // brace form (identical semantics)
```

---

## Proc Macros

Proc macros operate on **tokenstreams** — sequences of tokens that can be inspected and rewritten. They are regular functions annotated with an `attr` or `derive` marker placed after `)` and before `{`.

A proc macro function takes an allocator and a tokenstream input, and returns a tokenstream:

```arc
tokenstream* add_debug(&memstr alloc, tokenstream* input) attr {
    // inspect `input` tokenstream, return modified tokenstream
    return quote{ /* synthetic output */ };
}
```

The `attr` marker declares this function as an attribute proc macro. Use `derive` for derive macros.

### `verify` Modifier

Adding `verify` after the macro marker tells the compiler to validate that the returned tokenstream is syntactically well-formed:

```arc
tokenstream* safe_macro(&memstr alloc, tokenstream* input) attr verify {
    return quote{ i32 x = 0; };
}
```

### `quote{}`

`quote{}` creates a tokenstream literal from inline code syntax:

```arc
tokenstream* wrap_log(&memstr alloc, tokenstream* input) attr {
    tokenstream* out = quote{ printf("calling\n"); };
    return out;
}
```

### `ast()` and `tks()`

- `ast(expr)` — returns the AST representation of `expr` as a tokenstream handle
- `tks(expr)` — converts `expr` to a raw tokenstream

These are used inside proc macro bodies to reflect on and transform code.

### Custom Token Types

Use `__token` to define custom token patterns inside proc macro bodies:

```arc
tokenstream* my_macro(&memstr alloc, tokenstream* input) attr {
    __token kw_space = "<=>";
    // use kw_space to match custom syntax in input
    return input;
}
```

### Applying Proc Macros

#### `#[name]` — Attribute Proc Macro

Apply an attribute proc macro to the next declaration:

```arc
#[add_debug]
istruc Foo { i32 x; }

#[wrap_log(verbose)]
i32 compute(i32 x) { return x * x; }
```

#### `#derive[Name]` — Derive Proc Macro

Apply a derive proc macro to generate code for a struct:

```arc
#derive[Debug]
#derive[Clone]
istruc Bar { i32 y; }
```

#### `#![name]` — Whole-File Attribute

Apply a proc macro to the entire file's tokenstream. Must appear at the top of the file:

```arc
#![my_module_macro]

i32 main() { return 0; }
```

### Built-in Derive Macros

Artemis provides three built-in derive macros:

| Derive    | Synthesised function                      | Behaviour                       |
|-----------|-------------------------------------------|---------------------------------|
| `Debug`   | `void __derive_Debug_T(T* self)`          | Inspect/print struct (stub)     |
| `Clone`   | `T __derive_Clone_T(T* self)`             | Memberwise copy                 |
| `Default` | `T __derive_Default_T()`                  | Zero-initialise all fields      |

```arc
#derive[Debug]
#derive[Clone]
#derive[Default]
istruc Vec2 {
    i32 x;
    i32 y;
}

i32 main() {
    Vec2 v  = __derive_Default_Vec2();   // {0, 0}
    Vec2 v2 = __derive_Clone_Vec2(&v);   // copy
    __derive_Debug_Vec2(&v2);            // debug print
    return v.x + v.y;                    // 0
}
```

---

[Prev: Type Aliases and Auto](28_typedef_auto.md) | [Next: Generics Guidance](11_generics.md)
