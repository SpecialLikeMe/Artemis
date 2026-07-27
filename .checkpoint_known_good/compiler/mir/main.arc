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
// Gated behind the --use-mir flag; the default pipeline lowers the AST straight to
// LLVM IR and does not build MIR/LIR.

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
    let kind: i32;       // mir_val_kind
    let type_id: i32;    // index into type table
    let name: *i8;       // for MV_LOCAL/MV_GLOBAL/MV_PARAM
    let iconst: i64;     // for MV_CONST integer
    let fconst: f64;     // for MV_CONST float
}

struct mir_instr {
    let kind: i32;       // mir_instr_kind
    let dst: *mir_val;        // null if no result
    let src1: *mir_val;
    let src2: *mir_val;
    let label: *i8;      // for MI_BRANCH, MI_CBRANCH, MI_LABEL
    let fn_name: *i8;    // for MI_CALL
    let args: **mir_val;      // for MI_CALL
    let args_len: i32;
    let line: u64;
}

struct mir_block {
    let name: *i8;
    let instrs: **mir_instr;
    let instrs_len: i32;
    let instrs_cap: i32;
}

struct mir_func {
    let name: *i8;
    let blocks: **mir_block;
    let blocks_len: i32;
    let blocks_cap: i32;
}

struct mir_module {
    let funcs: **mir_func;
    let funcs_len: i32;
    let funcs_cap: i32;
}

// The AST → MIR lowering pass lives in mir/lower.arc as `lower_program`, which is
// what the driver calls under --use-mir.

} // namespace mir
