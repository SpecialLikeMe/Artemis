#pragma once
// compiler/lir/lir.hxx — Low-level IR (SSA form).
// MIR's alloca/load_local/store_local instructions are eliminated via mem2reg
// using Braun et al. online SSA construction.  Only phi_ instructions remain.
// This is the input to the domain-specific safety analyzer.

#include <string>
#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <optional>
#include <cassert>
#include "../mir/mir.hxx"

// LIR reuses mir_val / mir_instr / mir_block etc. by reference.
// "LIR" == a mir_func where:
//  - alloca_ / load_local / store_local instructions are gone
//  - every local variable use is a named SSA value
//  - phi_ instructions appear at join points

// ============================================================ Braun mem2reg =
//
// Algorithm: "Simple and Efficient Construction of Static Single Assignment Form"
// (Braun et al., 2013).  We implement the simplified version for non-loop-heavy
// code with fixup for back-edges (loop phis).
//
// Data structures per function:
//   current_def[slot][block_label] = mir_val  (the reaching definition)
//   incomplete_phis[block_label][slot] = phi_instr_idx (placeholder phis)

struct lir_lower_ctx {
    mir_func* func;
    // Sealed blocks: a block is sealed when all its predecessors are known.
    std::unordered_set<std::string> sealed;
    // current_def[slot][block] = current reaching SSA value
    std::unordered_map<std::string,
        std::unordered_map<std::string, mir_val>> current_def;
    // incomplete phis: for back-edges we insert a placeholder phi before the
    // predecessors of a loop header are known.
    // incomplete_phis[block][slot] = index into block's instrs for the phi_
    std::unordered_map<std::string,
        std::unordered_map<std::string, size_t>> incomplete_phis;

    void write_variable(const std::string& slot, const std::string& blk, mir_val v) {
        current_def[slot][blk] = std::move(v);
    }

    mir_val read_variable(const std::string& slot, const std::string& blk);
    mir_val read_variable_recursive(const std::string& slot, const std::string& blk);
    mir_val add_phi_operands(const std::string& slot, mir_block& blk, size_t phi_idx);
    mir_val try_remove_trivial_phi(mir_block& blk, size_t phi_idx);
    void    seal_block(const std::string& lbl);
};

mir_val lir_lower_ctx::read_variable(const std::string& slot, const std::string& blk) {
    auto it = current_def.find(slot);
    if (it != current_def.end()) {
        auto jt = it->second.find(blk);
        if (jt != it->second.end()) return jt->second;
    }
    return read_variable_recursive(slot, blk);
}

mir_val lir_lower_ctx::read_variable_recursive(const std::string& slot,
                                               const std::string& blk) {
    mir_block* bb = func->find_block(blk);
    if (!bb) return mir_val::i(0); // unreachable / unknown

    mir_val val;
    if (!sealed.count(blk)) {
        // Incomplete phi: insert placeholder
        std::string phi_name = slot + "_phi_" + blk;
        mir_instr phi; phi.kind = mik::phi_; phi.dest = phi_name;
        if (func->slot_types.count(slot)) phi.type = func->slot_types.at(slot);
        bb->instrs.insert(bb->instrs.begin(), std::move(phi)); // prepend
        size_t idx = 0;
        incomplete_phis[blk][slot] = idx;
        val = mir_val::tmp(phi_name, phi.type);
    } else if (bb->preds.size() == 1) {
        val = read_variable(slot, bb->preds[0]);
    } else if (bb->preds.empty()) {
        // No predecessors and not in current_def: undefined (treat as zero/opaque)
        val = mir_val::i(0);
    } else {
        // Insert real phi
        std::string phi_name = slot + "_phi_" + blk;
        mir_instr phi; phi.kind = mik::phi_; phi.dest = phi_name;
        if (func->slot_types.count(slot)) phi.type = func->slot_types.at(slot);
        bb->instrs.insert(bb->instrs.begin(), std::move(phi));
        val = mir_val::tmp(phi_name);
        write_variable(slot, blk, val);
        val = add_phi_operands(slot, *bb, 0);
    }

    write_variable(slot, blk, val);
    return val;
}

mir_val lir_lower_ctx::add_phi_operands(const std::string& slot, mir_block& blk,
                                        size_t phi_idx) {
    mir_instr& phi = blk.instrs[phi_idx];
    for (const auto& pred : blk.preds) {
        mir_val incoming = read_variable(slot, pred);
        phi.phi_args.push_back({incoming, pred});
    }
    return try_remove_trivial_phi(blk, phi_idx);
}

mir_val lir_lower_ctx::try_remove_trivial_phi(mir_block& blk, size_t phi_idx) {
    mir_instr& phi = blk.instrs[phi_idx];
    // A phi is trivial if all incoming values are the same (or is itself)
    mir_val* same = nullptr;
    std::string phi_tmp = phi.dest;
    for (auto& arg : phi.phi_args) {
        if (arg.val.kind == mvk::tmp && arg.val.name == phi_tmp) continue; // self-ref
        if (same && same->name == arg.val.name && same->kind == arg.val.kind) continue;
        if (same) return mir_val::tmp(phi_tmp, phi.type); // not trivial
        same = &arg.val;
    }
    mir_val replacement = same ? *same : mir_val::i(0);
    // Replace uses of phi_tmp with replacement throughout the function
    auto replace_in_val = [&](mir_val& v) {
        if (v.kind == mvk::tmp && v.name == phi_tmp) v = replacement;
    };
    auto replace_in_instr = [&](mir_instr& i) {
        for (auto& op : i.ops) replace_in_val(op);
        for (auto& pa : i.phi_args) replace_in_val(pa.val);
    };
    for (auto& b : func->blocks) {
        for (auto& i : b.instrs) replace_in_instr(i);
        replace_in_val(b.term.cond);
        replace_in_val(b.term.ret_val);
    }
    // Mark the phi as deleted (make it a no-op opaque)
    phi.kind = mik::opaque_; phi.dest = "";
    return replacement;
}

void lir_lower_ctx::seal_block(const std::string& lbl) {
    if (sealed.count(lbl)) return;
    sealed.insert(lbl);
    auto it = incomplete_phis.find(lbl);
    if (it == incomplete_phis.end()) return;
    mir_block* bb = func->find_block(lbl);
    if (!bb) return;
    for (auto& [slot, phi_idx] : it->second)
        add_phi_operands(slot, *bb, phi_idx);
}

// ============================================================ mem2reg pass ==

// Rewrites a single mir_func to SSA form in place.
// After this pass: alloca_/load_local/store_local instructions are removed,
// replaced by direct value references and phi_ nodes.
inline void mem2reg(mir_func& func) {
    lir_lower_ctx ctx;
    ctx.func = &func;

    // Collect all local slots promoted by this pass
    std::unordered_set<std::string> promotable;
    for (auto& blk : func.blocks)
        for (auto& i : blk.instrs)
            if (i.kind == mik::alloca_) promotable.insert(i.dest);

    // Seal all blocks that have no back-edge predecessors (all non-loop-header
    // blocks).  Loop headers are sealed after the pass handles back-edges.
    // Simple heuristic: seal every block immediately (works for non-loops;
    // for loops we rely on the incomplete_phis mechanism).
    // We do a two-pass approach:
    //  Pass A: compute a reaching-def per block for each slot
    //  Pass B: rewrite instructions using the reaching defs

    // Initialize parameter slots as defined in the entry block
    for (auto& [slot, _] : func.slot_types) {
        if (slot.rfind("sp_", 0) == 0) {
            // Parameter slot — look for the store_local in entry that defines it
            // Leave as-is for now; param value comes from the store at function entry
        }
    }

    // Process blocks in CFG order (depth-first pre-order)
    std::vector<std::string> order;
    std::unordered_set<std::string> visited;
    std::function<void(const std::string&)> dfs = [&](const std::string& lbl) {
        if (!visited.insert(lbl).second) return;
        order.push_back(lbl);
        mir_block* bb = func.find_block(lbl);
        if (!bb) return;
        if (bb->term.kind == mtk::br_) dfs(bb->term.true_lbl);
        if (bb->term.kind == mtk::condbr_) { dfs(bb->term.true_lbl); dfs(bb->term.false_lbl); }
    };
    if (!func.blocks.empty()) dfs(func.blocks[0].label);

    // Seal all blocks (simple: we just do it up front; incomplete phis handle the rest)
    for (auto& blk : func.blocks) ctx.sealed.insert(blk.label);

    // Scan each block; rewrite load_local → SSA value, store_local → write_variable
    for (auto& lbl : order) {
        mir_block* bb = func.find_block(lbl);
        if (!bb) continue;

        std::vector<mir_instr> new_instrs;
        for (auto& i : bb->instrs) {
            if (i.kind == mik::alloca_ && promotable.count(i.dest)) {
                // Drop the alloca_ instruction
                continue;
            }
            if (i.kind == mik::store_local && !i.ops.empty() &&
                i.ops.size() >= 2 && promotable.count(i.ops[1].name)) {
                // store_local slot val → write_variable(slot, blk, val)
                ctx.write_variable(i.ops[1].name, lbl, i.ops[0]);
                continue;
            }
            if (i.kind == mik::load_local && !i.ops.empty() &&
                promotable.count(i.ops[0].name)) {
                // load_local slot → read_variable(slot, blk)
                mir_val v = ctx.read_variable(i.ops[0].name, lbl);
                // Record that dest tmp now equals v
                ctx.write_variable(i.dest, lbl, v);
                // Rewrite downstream uses: rename i.dest → v throughout remaining instrs
                auto rename = [&](mir_val& mv) {
                    if (mv.kind == mvk::tmp && mv.name == i.dest) mv = v;
                };
                for (auto& ni : new_instrs) {
                    for (auto& op : ni.ops) rename(op);
                    for (auto& pa : ni.phi_args) rename(pa.val);
                }
                rename(bb->term.cond); rename(bb->term.ret_val);
                continue;
            }
            new_instrs.push_back(std::move(i));
        }
        bb->instrs = std::move(new_instrs);
    }

    // Remove no-op phi_ instructions (those with empty dest from trivial elimination)
    for (auto& blk : func.blocks) {
        blk.instrs.erase(std::remove_if(blk.instrs.begin(), blk.instrs.end(),
            [](const mir_instr& i) { return i.kind == mik::opaque_ && i.dest.empty(); }),
            blk.instrs.end());
    }
}

// ============================================================ Module entry ==

// Convert a mir_module into LIR in-place.
inline void lower_to_lir(mir_module& mod) {
    for (auto& f : mod.funcs) mem2reg(f);
}
