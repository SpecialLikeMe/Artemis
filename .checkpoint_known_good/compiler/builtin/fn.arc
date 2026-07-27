// builtin/fn.arc — Canonical list of all @ compiler builtins.
//
// All builtins are recognised by the parser when preceded by '@' and followed
// by '('.  IR codegen for each lives in ir/exprs.arc (dispatched via ek_*
// expression kinds).  This file documents the interface and houses helpers
// that are common to multiple builtins.
//
// Current builtins:
//
//   @typeinfo(T)         — returns type_info* for type T at compile time
//                          expr kind: ek_typeinfo_e  (ir/exprs.arc:emit_typeinfo_global)
//
//   @shcopy(expr)        — explicit shallow copy (value semantics; default for =)
//                          expr kind: ek_shcopy      (ir/exprs.arc)
//
//   @decopy(expr)        — deep copy; calls __deep_copy__ if defined, else memcpy
//                          expr kind: ek_decopy      (ir/exprs.arc)
//
//   @move(expr)          — move: copy value then zero source allocation
//                          expr kind: ek_move_expr   (ir/exprs.arc)
//
//   @cstype(expr)        — first-class type value.
//                          In type position it synthesises a real type, so
//                          @cstype(@typeinfo(T)) resolves back to T (see test 314).
//                          In expression position it evaluates to the i64 type
//                          encoding (kind | bit width), usable for comparisons.
//                          expr kind: ek_cstype      (ir/exprs.arc)
//
// The `ref` operator (not @-prefixed, just the keyword `ref`) produces a
// pointer whose depth is inferred from context:
//   int *p = ref x;     → p = &x   (depth 1)
//   expr kind: ek_ref_expr (parser/main.arc, ir/exprs.arc)
//
// Builtins that are preprocessor-level (not expr-level):
//   @include <path>      — handled by preproc.arc
//   @define name value   — handled by preproc.arc

namespace builtin {

// ---- Builtin name table ----
// Used to validate that @name is a known builtin when the parser encounters @name(

struct builtin_entry {
    let name: *i8;
    let kind: i32;    // ek_* expression kind
}

// All currently implemented expression-level builtins.
// The list is checked in order; first match wins.
let mut g_builtins: [5]builtin_entry;
let mut g_builtins_len: i32= 0;

fn builtin_init() void {
    if (g_builtins_len > 0) { return; }
    g_builtins[0].name = "typeinfo"; g_builtins[0].kind = 13; // ek_typeinfo_e
    g_builtins[1].name = "shcopy";   g_builtins[1].kind = 26; // ek_shcopy
    g_builtins[2].name = "decopy";   g_builtins[2].kind = 27; // ek_decopy
    g_builtins[3].name = "move";     g_builtins[3].kind = 28; // ek_move_expr
    g_builtins[4].name = "cstype";   g_builtins[4].kind = 34; // ek_cstype
    g_builtins_len = 5;
}

fn is_builtin(name: *i8) bool {
    if (name == (i8*)0) { return false; }
    builtin_init();
    let mut i: i32= 0;
    while (i < g_builtins_len) {
        if (strcmp(g_builtins[i].name, name) == 0) { return true; }
        i = i + 1;
    }
    return false;
}

} // namespace builtin
