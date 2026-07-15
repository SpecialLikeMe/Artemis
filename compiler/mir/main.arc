// compiler/mir/main.arc — Mid-level Intermediate Representation (MIR)
//
// MIR is a lowering of the AST to a three-address, single-assignment form:
//   - All loops are flattened to goto/label form
//   - All compound conditions are split into basic boolean ops
//   - Struct field accesses are normalized to byte-offset form
//   - No nested expressions — everything is a three-address assignment
//
// Pipeline: AST → MIR (this file) → LIR → SMT → LLVM IR emit
//
// Status: scaffolding only — the lowering pass is a future work item.
// Gate behind --use-mir flag; current pipeline skips MIR/LIR entirely.

namespace mir {

// ---- Value kinds ----
enum mir_val_kind {
    MV_CONST   = 0,  // immediate constant
    MV_LOCAL   = 1,  // local variable (named SSA slot)
    MV_GLOBAL  = 2,  // global variable reference
    MV_PARAM   = 3,  // function parameter
}

// ---- Instruction kinds ----
enum mir_instr_kind {
    MI_NOP      = 0,
    MI_COPY     = 1,   // dst = src
    MI_LOAD     = 2,   // dst = *ptr
    MI_STORE    = 3,   // *ptr = src
    MI_GEP      = 4,   // dst = &base.field (byte offset)
    MI_BINOP    = 5,   // dst = lhs op rhs
    MI_UNOP     = 6,   // dst = op src
    MI_CALL     = 7,   // dst = fn(args...)
    MI_BRANCH   = 8,   // goto label
    MI_CBRANCH  = 9,   // if cond goto lbl_t else lbl_f
    MI_RETURN   = 10,  // return val?
    MI_LABEL    = 11,  // label target
    MI_ALLOCA   = 12,  // dst = alloca T
    MI_CAST     = 13,  // dst = (T)src
}

struct mir_val {
    i32  kind;       // mir_val_kind
    i32  type_id;    // index into type table
    i8*  name;       // for MV_LOCAL/MV_GLOBAL/MV_PARAM
    i64  iconst;     // for MV_CONST integer
    f64  fconst;     // for MV_CONST float
}

struct mir_instr {
    i32      kind;       // mir_instr_kind
    mir_val* dst;        // null if no result
    mir_val* src1;
    mir_val* src2;
    i8*      label;      // for MI_BRANCH, MI_CBRANCH, MI_LABEL
    i8*      fn_name;    // for MI_CALL
    mir_val** args;      // for MI_CALL
    i32      args_len;
    u64      line;
}

struct mir_block {
    i8*         name;
    mir_instr** instrs;
    i32         instrs_len;
    i32         instrs_cap;
}

struct mir_func {
    i8*         name;
    mir_block** blocks;
    i32         blocks_len;
    i32         blocks_cap;
}

struct mir_module {
    mir_func** funcs;
    i32        funcs_len;
    i32        funcs_cap;
}

// ---- Lower AST → MIR (stub) ----
// TODO: implement the actual lowering pass
// Currently returns a null/empty module; the main pipeline skips this when
// --use-mir is not passed.
mir_module* mir_lower_program(i8* prog) {
    return (mir_module*)0;
}

} // namespace mir
