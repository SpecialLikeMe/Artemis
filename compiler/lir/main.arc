// compiler/lir/main.arc — Low-level Intermediate Representation (LIR)
//
// LIR is a further lowering of MIR:
//   - Everything scalar (no struct values — only pointers to structs)
//   - All memory operations explicit (every load and store visible as instructions)
//   - Designed as direct input to the SMT analysis and bounds-check injector
//   - All aggregate operations are split into element-wise scalar ops
//
// Pipeline: MIR → LIR (this file) → SMT → LLVM IR emit
//
// Gated behind the --use-mir flag; the default pipeline lowers the AST straight to
// LLVM IR and does not build MIR/LIR.

namespace lir {

// ---- LIR value kinds (narrower than MIR: only scalar types) ----
enum lir_val_kind {
    LV_ICONST  = 0,  // integer constant
    LV_FCONST  = 1,  // float constant
    LV_LOCAL   = 2,  // scalar local (SSA)
    LV_GLOBAL  = 3,  // global (ptr to storage)
    LV_PARAM   = 4,
}

// ---- LIR instruction kinds ----
enum lir_instr_kind {
    LI_NOP     = 0,
    LI_ASSIGN  = 1,  // dst = src  (scalar only)
    LI_LOAD    = 2,  // dst = *ptr
    LI_STORE   = 3,  // *ptr = src
    LI_GEP     = 4,  // dst = ptr + byte_offset
    LI_BINOP   = 5,
    LI_UNOP    = 6,
    LI_CALL    = 7,
    LI_BR      = 8,  // unconditional branch
    LI_CBR     = 9,  // conditional branch
    LI_RET     = 10,
    LI_LABEL   = 11,
    LI_ALLOCA  = 12,
    LI_CAST    = 13,
    // SMT-specific pseudo-instructions injected by the bounds-check pass:
    LI_RTCHECK_NULL   = 20, // abort if ptr == null
    LI_RTCHECK_BOUNDS = 21, // abort if idx < 0 || idx >= len
}

struct lir_val {
    let kind: i32;
    let type_id: i32;
    let name: *i8;
    let iconst: i64;
    let fconst: f64;
}

struct lir_instr {
    let kind: i32;
    let dst: *lir_val;
    let src1: *lir_val;
    let src2: *lir_val;
    let label: *i8;
    let fn_name: *i8;
    let args: **lir_val;
    let args_len: i32;
    let line: u64;
    let check_msg: *i8;  // for LI_RTCHECK_*: message on failure
}

struct lir_block {
    let name: *i8;
    let instrs: **lir_instr;
    let instrs_len: i32;
    let instrs_cap: i32;
}

struct lir_func {
    let name: *i8;
    let blocks: **lir_block;
    let blocks_len: i32;
    let blocks_cap: i32;
}

struct lir_module {
    let funcs: **lir_func;
    let funcs_len: i32;
    let funcs_cap: i32;
}

// The MIR → LIR lowering pass lives in lir/lower.arc as `lower_mir`, which is what
// the driver calls under --use-mir.

} // namespace lir
