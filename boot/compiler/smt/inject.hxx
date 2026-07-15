#pragma once
// compiler/smt/inject.hxx — Populate ir_context::unsafe_ops from SMT results.
// UNKNOWN sites produce runtime checks; BAD sites are compile errors.
// This header is included from src/main.cpp AFTER the SMT runs and BEFORE IR
// emission, so it bridges the MIR/SMT layer to the LLVM IR emitter.

#include <string>
#include <vector>
#include "smt.hxx"
#include "../ir/context.hxx"

struct inject_error {
    uint64_t    line;
    std::string message;
    expr_node*  src;
};

// Translate a check_site kind (mik) to ir_context's check_kind enum.
static check_kind mik_to_check_kind(mik k) {
    switch (k) {
    case mik::arr_ptr_: return check_kind::bounds;
    case mik::div_:
    case mik::rem_:     return check_kind::div_zero;
    case mik::deref_:   return check_kind::null_deref;
    default:            return check_kind::bounds; // fallback
    }
}

static const char* mik_ub_name(mik k) {
    switch (k) {
    case mik::arr_ptr_: return "out_of_bounds";
    case mik::div_:
    case mik::rem_:     return "div_zero";
    case mik::deref_:   return "null_deref";
    default:            return "undefined";
    }
}

struct inject_result {
    std::vector<inject_error> errors;  // BAD sites: compile-time errors
    bool                      ok;      // false if any BAD sites found
};

// Call this after analyze_module() and before IR emission.
// On success, ctx->unsafe_ops is populated with UNKNOWN check sites.
// Returns errors for BAD sites; caller should abort compilation if !result.ok.
inline inject_result inject_checks(const smt_result& smt, ir_context* ctx) {
    inject_result res; res.ok = true;

    // Compile errors for BAD sites
    for (const auto& site : smt.errors) {
        res.errors.push_back({
            site.line,
            std::string("Safety error: provably unsafe ") + mik_ub_name(site.kind) +
            " at line " + std::to_string(site.line),
            site.src
        });
        res.ok = false;
    }

    // Runtime check injection for UNKNOWN sites
    for (const auto& site : smt.unknowns) {
        if (site.src) {
            ctx->unsafe_ops[site.src] = mik_to_check_kind(site.kind);
        } else {
            // Safety site with no AST anchor — we cannot inject a runtime check.
            // Emit a compile-time warning so the developer knows.
            fprintf(stderr, "warning: safety: untracked potential null/bounds violation at line %u "
                            "(opaque MIR instruction — no runtime check injected)\n",
                            static_cast<unsigned>(site.line));
        }
    }

    return res;
}
