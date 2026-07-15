#pragma once
// compiler/smt/smt.hxx — Domain-specific safety analyzer.
// Runs abstract interpretation on LIR (SSA form) to determine, for each
// safety-critical instruction (arr_ptr_, deref_, div_/rem_), whether:
//   GOOD    — the check provably passes (no UB possible)
//   BAD     — the check provably fails (UB certain, compile error)
//   UNKNOWN — cannot determine; a runtime check will be injected
//
// Abstract domain:
//   Integers: closed intervals [lo, hi]  with ±∞ sentinels
//   Pointers: tri-state { NON_NULL, NULL, MAYBE_NULL }

#include <string>
#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <algorithm>
#include <cstdint>
#include "../mir/mir.hxx"

// ============================================================ Abstract values

static constexpr int64_t INF  =  (int64_t)9000000000000000LL;
static constexpr int64_t NINF = -(int64_t)9000000000000000LL;

enum class anull : uint8_t { non_null, null, maybe };

struct abs_int {
    int64_t lo = NINF, hi = INF;
    bool    bot = false; // ⊥ = unreachable path

    static abs_int top()  { return {NINF, INF, false}; }
    static abs_int bot_() { return {0, 0, true}; }
    static abs_int exact(int64_t v) { return {v, v, false}; }
    static abs_int range(int64_t a, int64_t b) { return {a, b, false}; }

    bool is_top() const { return !bot && lo == NINF && hi == INF; }
    bool definitely_nonzero() const { return !bot && (lo > 0 || hi < 0); }
    bool definitely_zero()    const { return !bot && lo == 0 && hi == 0; }
    bool definitely_in(int64_t a, int64_t b) const {
        return !bot && lo >= a && hi <= b;
    }
    bool possibly_zero() const { return bot || (lo <= 0 && hi >= 0); }

    abs_int join(const abs_int& o) const {
        if (bot) return o;
        if (o.bot) return *this;
        return {std::min(lo, o.lo), std::max(hi, o.hi), false};
    }
    // Widening: after fixpoint iteration, widen to ±∞ to ensure termination
    abs_int widen(const abs_int& o) const {
        if (bot) return o;
        int64_t nlo = (o.lo < lo) ? NINF : lo;
        int64_t nhi = (o.hi > hi) ? INF  : hi;
        return {nlo, nhi, false};
    }
    bool operator==(const abs_int& o) const { return bot==o.bot && lo==o.lo && hi==o.hi; }
    bool operator!=(const abs_int& o) const { return !(*this == o); }
};

struct abs_ptr {
    anull null_st = anull::maybe;
    static abs_ptr non_null()  { return {anull::non_null}; }
    static abs_ptr null_()     { return {anull::null}; }
    static abs_ptr maybe()     { return {anull::maybe}; }
    bool definitely_nonnull() const { return null_st == anull::non_null; }
    bool definitely_null()    const { return null_st == anull::null; }
    abs_ptr join(const abs_ptr& o) const {
        if (null_st == o.null_st) return *this;
        return {anull::maybe};
    }
    bool operator==(const abs_ptr& o) const { return null_st == o.null_st; }
};

// ============================================================ Abstract state

// Records that a boolean SSA temp was produced by a null comparison (p == null / p != null).
// Used by narrow_for_branch to narrow pointer null state when branching on the result.
struct null_check_info {
    std::string ptr_tmp; // the pointer SSA name being compared
    bool        is_ne;   // true = "p != null" (ne), false = "p == null" (eq)
    bool operator==(const null_check_info& o) const {
        return ptr_tmp == o.ptr_tmp && is_ne == o.is_ne;
    }
};

struct abs_state {
    std::unordered_map<std::string, abs_int>        ints;        // SSA name → interval
    std::unordered_map<std::string, abs_ptr>        ptrs;        // SSA name → null status
    std::unordered_map<std::string, null_check_info> null_checks; // bool tmp → null cmp info
    bool reachable = true;

    abs_int get_int(const std::string& name) const {
        auto it = ints.find(name);
        return it == ints.end() ? abs_int::top() : it->second;
    }
    abs_ptr get_ptr(const std::string& name) const {
        auto it = ptrs.find(name);
        return it == ptrs.end() ? abs_ptr::maybe() : it->second;
    }
    void set_int(const std::string& name, abs_int v) { if (!name.empty()) ints[name] = v; }
    void set_ptr(const std::string& name, abs_ptr v) { if (!name.empty()) ptrs[name] = v; }

    // Get abstract integer of a mir_val
    abs_int eval_int(const mir_val& v) const {
        if (v.kind == mvk::i_const || v.kind == mvk::b_const)
            return abs_int::exact(v.ival);
        if (v.kind == mvk::null_val) return abs_int::exact(0);
        if (v.kind == mvk::tmp || v.kind == mvk::param) return get_int(v.name);
        return abs_int::top();
    }
    abs_ptr eval_ptr(const mir_val& v) const {
        if (v.kind == mvk::null_val) return abs_ptr::null_();
        if (v.kind == mvk::i_const && v.ival != 0) return abs_ptr::non_null();
        if (v.kind == mvk::tmp || v.kind == mvk::param || v.kind == mvk::local ||
            v.kind == mvk::global) return get_ptr(v.name);
        return abs_ptr::maybe();
    }

    // Join two states (meet at a control-flow join point)
    abs_state join(const abs_state& o) const {
        if (!reachable) return o;
        if (!o.reachable) return *this;
        abs_state res; res.reachable = true;
        for (auto& [k, v] : ints) {
            auto it = o.ints.find(k);
            res.ints[k] = (it == o.ints.end()) ? v : v.join(it->second);
        }
        for (auto& [k, v] : o.ints) {
            if (!res.ints.count(k)) res.ints[k] = v;
        }
        for (auto& [k, v] : ptrs) {
            auto it = o.ptrs.find(k);
            res.ptrs[k] = (it == o.ptrs.end()) ? v : v.join(it->second);
        }
        for (auto& [k, v] : o.ptrs) {
            if (!res.ptrs.count(k)) res.ptrs[k] = v;
        }
        // Merge null_checks (union: a check known on either path is kept)
        for (auto& [k, v] : null_checks) {
            if (!res.null_checks.count(k)) res.null_checks[k] = v;
        }
        for (auto& [k, v] : o.null_checks) {
            if (!res.null_checks.count(k)) res.null_checks[k] = v;
        }
        return res;
    }
    bool operator==(const abs_state& o) const {
        return reachable == o.reachable && ints == o.ints && ptrs == o.ptrs
            && null_checks == o.null_checks;
    }
};

// ============================================================ Safety verdict

enum class verdict : uint8_t { good, bad, unknown };

struct check_site {
    mik      kind;      // arr_ptr_, deref_, div_, rem_
    verdict  result;
    uint64_t line;
    expr_node* src;     // back-link to AST node (for injection)
};

// ============================================================ Abstract arithmetic

static abs_int eval_binop(binary_op bop, const abs_int& lhs, const abs_int& rhs) {
    if (lhs.bot || rhs.bot) return abs_int::bot_();
    switch (bop) {
    case binary_op::add:
        return abs_int::range(
            (lhs.lo == NINF || rhs.lo == NINF) ? NINF : lhs.lo + rhs.lo,
            (lhs.hi == INF  || rhs.hi == INF)  ? INF  : lhs.hi + rhs.hi);
    case binary_op::sub:
        return abs_int::range(
            (lhs.lo == NINF || rhs.hi == INF)  ? NINF : lhs.lo - rhs.hi,
            (lhs.hi == INF  || rhs.lo == NINF) ? INF  : lhs.hi - rhs.lo);
    case binary_op::mul: {
        // Conservatively compute all four corners
        auto safe_mul = [](int64_t a, int64_t b) -> int64_t {
            if (a == 0 || b == 0) return 0;
            if (a == NINF || b == NINF || a == INF || b == INF)
                return (a > 0) == (b > 0) ? INF : NINF;
            return a * b;
        };
        int64_t c1 = safe_mul(lhs.lo, rhs.lo), c2 = safe_mul(lhs.lo, rhs.hi);
        int64_t c3 = safe_mul(lhs.hi, rhs.lo), c4 = safe_mul(lhs.hi, rhs.hi);
        return abs_int::range(std::min({c1,c2,c3,c4}), std::max({c1,c2,c3,c4}));
    }
    case binary_op::eq:  case binary_op::ne:
    case binary_op::lt:  case binary_op::gt:
    case binary_op::lte: case binary_op::gte:
        return abs_int::range(0, 1); // boolean result
    default:
        return abs_int::top();
    }
}

// ============================================================ Per-block analysis

// Returns the outgoing abstract state after executing a block, given the
// incoming state.  Also populates check_sites for safety-critical instructions.
static abs_state analyze_block(const mir_block& blk, abs_state state,
                               std::vector<check_site>& sites) {
    if (!state.reachable) return state;

    for (const auto& i : blk.instrs) {
        if (i.kind == mik::opaque_ || i.kind == mik::alloca_) {
            // Opaque: result is unknown
            if (!i.dest.empty()) {
                state.set_int(i.dest, abs_int::top());
                state.set_ptr(i.dest, abs_ptr::maybe());
            }
            continue;
        }
        if (i.kind == mik::phi_) {
            // Join all incoming values
            abs_int joined_i; joined_i.bot = true;
            abs_ptr joined_p; bool first = true;
            for (auto& arg : i.phi_args) {
                abs_int ai = state.eval_int(arg.val);
                abs_ptr ap = state.eval_ptr(arg.val);
                if (first) { joined_i = ai; joined_p = ap; first = false; }
                else { joined_i = joined_i.join(ai); joined_p = joined_p.join(ap); }
            }
            if (i.phi_args.empty()) { joined_i = abs_int::top(); }
            state.set_int(i.dest, joined_i);
            state.set_ptr(i.dest, joined_p);
            continue;
        }
        if (i.kind == mik::binop_ || i.kind == mik::div_ || i.kind == mik::rem_) {
            if (i.ops.size() < 2) continue;
            abs_int lhs = state.eval_int(i.ops[0]);
            abs_int rhs = state.eval_int(i.ops[1]);

            // Safety check for division/remainder
            if (i.kind == mik::div_ || i.kind == mik::rem_) {
                verdict v;
                if (rhs.definitely_nonzero()) v = verdict::good;
                else if (rhs.definitely_zero()) v = verdict::bad;
                else v = verdict::unknown;
                sites.push_back({i.kind, v, i.line, i.src});
                if (v == verdict::bad) { state.reachable = false; return state; }
            }

            abs_int res = eval_binop(i.bop, lhs, rhs);
            state.set_int(i.dest, res);
            // Booleans (eq/ne/lt/gt/lte/gte) — result is a pointer to nothing,
            // not a pointer itself, so don't set ptr state.
            // Track null comparisons for pointer narrowing in branch successors
            if ((i.bop == binary_op::eq || i.bop == binary_op::ne) && i.ops.size() == 2) {
                bool lhs_null = (i.ops[0].kind == mvk::null_val);
                bool rhs_null = (i.ops[1].kind == mvk::null_val);
                if (lhs_null || rhs_null) {
                    const std::string& ptr_name = lhs_null ? i.ops[1].name : i.ops[0].name;
                    if (!ptr_name.empty())
                        state.null_checks[i.dest] = {ptr_name, i.bop == binary_op::ne};
                }
            }
            continue;
        }
        if (i.kind == mik::unop_) {
            if (i.ops.empty()) continue;
            abs_int src = state.eval_int(i.ops[0]);
            abs_int res = src; // conservative default
            if (i.uop == unary_op::neg) {
                res = abs_int::range(
                    (src.hi == INF)  ? NINF : -src.hi,
                    (src.lo == NINF) ? INF  : -src.lo);
            } else if (i.uop == unary_op::log_not) {
                res = abs_int::range(0, 1);
            }
            state.set_int(i.dest, res);
            continue;
        }
        if (i.kind == mik::cast_) {
            if (i.ops.empty()) continue;
            // Preserve integer value through cast (may lose range info for narrowing)
            state.set_int(i.dest, state.eval_int(i.ops[0]));
            state.set_ptr(i.dest, state.eval_ptr(i.ops[0]));
            continue;
        }
        if (i.kind == mik::deref_) {
            if (i.ops.empty()) continue;
            abs_ptr ap = state.eval_ptr(i.ops[0]);
            verdict v;
            if (ap.definitely_nonnull()) v = verdict::good;
            else if (ap.definitely_null()) v = verdict::bad;
            else v = verdict::unknown;
            sites.push_back({i.kind, v, i.line, i.src});
            if (v == verdict::bad) { state.reachable = false; return state; }
            // After a successful deref, the result is a non-null pointer-sized value
            state.set_ptr(i.dest, abs_ptr::non_null());
            state.set_int(i.dest, abs_int::top());
            continue;
        }
        if (i.kind == mik::arr_ptr_) {
            if (i.ops.size() < 2) continue;
            abs_int idx = state.eval_int(i.ops[1]);
            verdict v;
            if (i.arr_size > 0) {
                // Static array: check idx in [0, arr_size-1]
                if (idx.definitely_in(0, i.arr_size - 1)) v = verdict::good;
                else if (idx.lo >= i.arr_size || idx.hi < 0) v = verdict::bad;
                else v = verdict::unknown;
            } else {
                // Dynamic array: size unknown at compile time.
                // Provably negative index is always bad; otherwise unknown (runtime check needed).
                if (idx.hi < 0)  v = verdict::bad;
                else             v = verdict::unknown;
            }
            sites.push_back({i.kind, v, i.line, i.src});
            if (v == verdict::bad) { state.reachable = false; return state; }
            // Result is a valid pointer (if check passes)
            state.set_ptr(i.dest, abs_ptr::non_null());
            continue;
        }
        if (i.kind == mik::field_) {
            if (i.ops.empty()) continue;
            // If base is a pointer, null check may be needed
            abs_ptr ap = state.eval_ptr(i.ops[0]);
            if (ap.definitely_null()) {
                sites.push_back({mik::deref_, verdict::bad, i.line, i.src});
                state.reachable = false; return state;
            }
            if (!ap.definitely_nonnull()) {
                // maybe-null base: inject a runtime check site
                sites.push_back({mik::field_, verdict::unknown, i.line, i.src});
            }
            state.set_ptr(i.dest, ap.definitely_nonnull() ? abs_ptr::non_null() : abs_ptr::maybe());
            continue;
        }
        if (i.kind == mik::load_ptr_ || i.kind == mik::store_ptr_) {
            // The pointer was already checked by deref_/arr_ptr_/field_
            // Result of load is unknown
            if (!i.dest.empty()) {
                state.set_int(i.dest, abs_int::top());
                state.set_ptr(i.dest, abs_ptr::maybe());
            }
            continue;
        }
        if (i.kind == mik::call_) {
            // Function call: conservatively mark result as unknown
            if (!i.dest.empty()) {
                state.set_int(i.dest, abs_int::top());
                state.set_ptr(i.dest, abs_ptr::maybe());
            }
            continue;
        }
        if (i.kind == mik::store_local || i.kind == mik::load_local) {
            // Should have been removed by mem2reg; treat as opaque
            if (!i.dest.empty()) {
                state.set_int(i.dest, abs_int::top());
                state.set_ptr(i.dest, abs_ptr::maybe());
            }
        }
    }
    return state;
}

// Branch-condition narrowing: given that a conditional branch was taken (or not),
// narrow the abstract state for the successor block.
static abs_state narrow_for_branch(abs_state state, const mir_val& cond, bool taken) {
    // Pattern: cond is the result of a comparison instruction.
    // We look for the most recent binop that produced cond.name and narrow accordingly.
    // For the purposes of this analyzer, we encode narrowing directly: when we see
    // that a condbr was taken in the true/false direction, we check the cond value.
    if (cond.kind == mvk::b_const) {
        if ((cond.ival != 0) != taken) state.reachable = false;
        return state;
    }
    if (cond.kind == mvk::tmp) {
        // Try to narrow based on the condition being non-zero / zero
        abs_int cv = state.eval_int(cond);
        if (taken && cv.definitely_zero())    state.reachable = false;
        if (!taken && cv.definitely_nonzero()) state.reachable = false;
        // Narrow pointer null state from null-comparison branches:
        //   if (p != null) → taken branch: p is non-null
        //   if (p == null) → taken branch: p is null
        auto it = state.null_checks.find(cond.name);
        if (it != state.null_checks.end()) {
            const std::string& ptr_name = it->second.ptr_tmp;
            bool ne_null = it->second.is_ne; // true = "p != null"
            if ((taken && ne_null) || (!taken && !ne_null)) {
                state.set_ptr(ptr_name, abs_ptr::non_null());
            } else {
                state.set_ptr(ptr_name, abs_ptr::null_());
            }
        }
    }
    return state;
}

// ============================================================ Fixed-point

struct func_analysis {
    std::vector<check_site> sites;
    bool has_bad = false;
};

static func_analysis analyze_func(const mir_func& func) {
    func_analysis result;
    if (func.blocks.empty()) return result;

    // Build block index map for back-edge detection (a back-edge goes to a block with a
    // smaller or equal index in the block list — i.e., a loop header).
    std::unordered_map<std::string, size_t> block_index;
    for (size_t bi = 0; bi < func.blocks.size(); ++bi)
        block_index[func.blocks[bi].label] = bi;

    // Map block label → incoming abstract state
    std::unordered_map<std::string, abs_state> in_states;
    // Entry block starts with reachable, all values unknown
    abs_state entry_state; entry_state.reachable = true;
    // Params are assumed unknown (could be any value)
    for (auto& [pname, _] : func.params) {
        entry_state.set_int(pname, abs_int::top());
        entry_state.set_ptr(pname, abs_ptr::maybe());
    }
    in_states[func.blocks[0].label] = entry_state;

    // Worklist algorithm: process blocks until fixpoint
    std::vector<std::string> worklist;
    std::unordered_set<std::string> in_wl;
    for (auto& b : func.blocks) { worklist.push_back(b.label); in_wl.insert(b.label); }

    const int MAX_ITERS = 20;
    for (int iter = 0; iter < MAX_ITERS && !worklist.empty(); ++iter) {
        std::string lbl = worklist.front(); worklist.erase(worklist.begin());
        in_wl.erase(lbl);

        const mir_block* bb = func.find_block(lbl);
        if (!bb) continue;

        auto sit = in_states.find(lbl);
        if (sit == in_states.end()) continue; // block not yet reachable

        std::vector<check_site> block_sites;
        abs_state out = analyze_block(*bb, sit->second, block_sites);

        // Propagate to successors
        auto propagate = [&](const std::string& succ_lbl, abs_state succ_state) {
            auto& succ_in = in_states[succ_lbl];
            abs_state joined = succ_in.reachable ? succ_in.join(succ_state) : succ_state;
            // Widening after a few iterations, but only on back-edges (loop headers).
            // Widening forward edges prematurely kills precision for straight-line code.
            bool is_back_edge = false;
            {
                auto cur_it = block_index.find(lbl);
                auto suc_it = block_index.find(succ_lbl);
                if (cur_it != block_index.end() && suc_it != block_index.end())
                    is_back_edge = (suc_it->second <= cur_it->second);
            }
            if (iter >= 5 && is_back_edge) {
                for (auto& [k, v] : joined.ints) {
                    auto old_it = succ_in.ints.find(k);
                    if (old_it != succ_in.ints.end())
                        joined.ints[k] = old_it->second.widen(v);
                }
            }
            if (!(joined == succ_in)) {
                succ_in = joined;
                if (!in_wl.count(succ_lbl)) {
                    worklist.push_back(succ_lbl);
                    in_wl.insert(succ_lbl);
                }
            }
        };

        if (bb->term.kind == mtk::br_) {
            propagate(bb->term.true_lbl, out);
        } else if (bb->term.kind == mtk::condbr_) {
            propagate(bb->term.true_lbl,  narrow_for_branch(out, bb->term.cond, true));
            propagate(bb->term.false_lbl, narrow_for_branch(out, bb->term.cond, false));
        }

        // Accumulate check sites from this block
        for (auto& s : block_sites) {
            result.sites.push_back(s);
            if (s.result == verdict::bad) result.has_bad = true;
        }
    }
    return result;
}

// ============================================================ Module analysis

struct smt_result {
    // Per-expression verdict: src expr_node* → verdict
    std::unordered_map<expr_node*, verdict> verdicts;
    // Compile errors: BAD sites (UB is certain)
    std::vector<check_site> errors;
    // Runtime check sites: UNKNOWN sites needing injection
    std::vector<check_site> unknowns;
};

inline smt_result analyze_module(const mir_module& mod) {
    smt_result res;
    for (const auto& func : mod.funcs) {
        auto fa = analyze_func(func);
        for (auto& site : fa.sites) {
            if (site.src) res.verdicts[site.src] = site.result;
            if (site.result == verdict::bad)     res.errors.push_back(site);
            if (site.result == verdict::unknown) res.unknowns.push_back(site);
        }
    }
    return res;
}
