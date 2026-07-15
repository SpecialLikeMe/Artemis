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
// Status: scaffolding only — the lowering pass is a future work item.
// Gate behind --use-mir flag; current pipeline skips MIR/LIR entirely.

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
    i32  kind;
    i32  type_id;
    i8*  name;
    i64  iconst;
    f64  fconst;
}

struct lir_instr {
    i32      kind;
    lir_val* dst;
    lir_val* src1;
    lir_val* src2;
    i8*      label;
    i8*      fn_name;
    lir_val** args;
    i32      args_len;
    u64      line;
    i8*      check_msg;  // for LI_RTCHECK_*: message on failure
}

struct lir_block {
    i8*          name;
    lir_instr**  instrs;
    i32          instrs_len;
    i32          instrs_cap;
}

struct lir_func {
    i8*         name;
    lir_block** blocks;
    i32         blocks_len;
    i32         blocks_cap;
}

struct lir_module {
    lir_func** funcs;
    i32        funcs_len;
    i32        funcs_cap;
}

// ---- Lower MIR → LIR (stub) ----
// TODO: implement the actual lowering pass.
// Aggregate values in MIR are split into pointer + series of scalar loads/stores.
lir_module* lir_lower_mir(i8* mir_mod) {
    return (lir_module*)0;
}

} // namespace lir
