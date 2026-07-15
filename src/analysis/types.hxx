#pragma once
#include <string>
#include "../parser/expr.hxx"

// ------------------------------------------------------------------ stringify

inline std::string prim_to_str(prim_type_t p, uint32_t bw = 0) {
    switch (p) {
        case prim_type_t::char_t:    return "char";
        case prim_type_t::arb_int:   return "i" + std::to_string(bw);
        case prim_type_t::arb_uint:  return "u" + std::to_string(bw);
        case prim_type_t::arb_float: return "f" + std::to_string(bw);
        case prim_type_t::arb_bool:  return "b" + std::to_string(bw);
        case prim_type_t::void_t:    return "void";
        default:                     return "?";
    }
}

inline std::string type_to_str(const type_node* t) {
    if (!t) return "<null-type>";
    std::string s;
    if (t->is_nullable) s += "?";
    if (t->is_extern)   s += "extern ";
    if (t->is_inline)   s += "inline ";
    if (t->is_register) s += "register ";
    if (t->is_const)    s += "const ";
    s += t->is_primitive ? prim_to_str(t->prim.value(), t->bit_width)
                         : t->name.value_or("<unnamed>");
    for (int i = 0; i < t->pointer_depth; i++) s += '*';
    if (t->array_size.has_value()) s += "[]";
    return s;
}

// ------------------------------------------------------------------ category checks

inline bool is_int_prim(prim_type_t p) {
    return p == prim_type_t::char_t || p == prim_type_t::arb_int || p == prim_type_t::arb_uint;
}
inline bool is_float_prim(prim_type_t p) { return p == prim_type_t::arb_float; }
inline bool is_bool_prim(prim_type_t p)  { return p == prim_type_t::arb_bool; }
inline bool is_numeric_prim(prim_type_t p) { return is_int_prim(p) || is_float_prim(p); }
inline bool is_unsigned_int(prim_type_t p) { return p == prim_type_t::arb_uint; }

// ------------------------------------------------------------------ ranks / promotion

// Returns the bit-width of a type for promotion purposes.
// char is treated as 8-bit signed int.
inline uint32_t effective_width(prim_type_t p, uint32_t bw) {
    return (p == prim_type_t::char_t) ? 8 : bw;
}

inline prim_type_t wider_int(prim_type_t a, uint32_t bwa, prim_type_t b, uint32_t bwb) {
    uint32_t wa = effective_width(a, bwa), wb = effective_width(b, bwb);
    if (wa != wb) return (wa > wb) ? a : b;
    return is_unsigned_int(a) ? a : b;
}

inline prim_type_t wider_float(prim_type_t /*a*/, uint32_t bwa,
                               prim_type_t b, uint32_t bwb) {
    return (bwa >= bwb) ? prim_type_t::arb_float : b;
}

// ------------------------------------------------------------------ compatibility

inline bool types_equal(const type_node* a, const type_node* b) {
    if (!a || !b) return false;
    if (a->pointer_depth != b->pointer_depth) return false;
    if (a->is_primitive != b->is_primitive)   return false;
    if (a->is_primitive) {
        if (a->prim.value() != b->prim.value()) return false;
        return a->bit_width == b->bit_width;
    }
    return a->name.value_or("") == b->name.value_or("");
}

// Can a value of type `rhs` be assigned to a location of type `lhs`?
inline bool assignable(const type_node* lhs, const type_node* rhs) {
    if (!lhs || !rhs) return false;

    // null literal: assignable to any pointer type or any ?T type;
    // rejected by non-nullable, non-pointer types.
    if (rhs->is_null_literal) {
        if (lhs->pointer_depth > 0) return true;
        if (lhs->is_nullable)       return true;
        return false;
    }

    // Nullable mismatch: ?T cannot be implicitly coerced to T.
    // The programmer must explicitly unwrap (e.g. via if/conditional).
    // Note: non-nullable → nullable is always fine (handled by normal type matching below).
    if (rhs->is_nullable && !lhs->is_nullable && lhs->pointer_depth == 0) {
        return false;
    }

    // array-to-pointer decay: T[] decays to T*
    if (rhs->array_size.has_value() && lhs->pointer_depth == rhs->pointer_depth + 1) {
        if (lhs->is_primitive && rhs->is_primitive) {
            if (lhs->prim == rhs->prim && lhs->bit_width == rhs->bit_width) return true;
            if (lhs->prim == prim_type_t::void_t) return true;
        } else if (!lhs->is_primitive && !rhs->is_primitive) {
            if (lhs->name.value_or("") == rhs->name.value_or("")) return true;
        }
    }

    // null pointer constant: any integer can be assigned to a pointer
    if (lhs->pointer_depth > 0 && rhs->pointer_depth == 0 &&
        rhs->is_primitive && is_int_prim(rhs->prim.value())) return true;

    // pointer assignment
    if (lhs->pointer_depth > 0 || rhs->pointer_depth > 0) {
        if (lhs->pointer_depth != rhs->pointer_depth) return false;
        bool lv = lhs->is_primitive && lhs->prim == prim_type_t::void_t;
        bool rv = rhs->is_primitive && rhs->prim == prim_type_t::void_t;
        if (lv || rv || types_equal(lhs, rhs)) return true;
        // Same-width integer pointer coercion: i8* ↔ u8* ↔ char* etc.
        if (lhs->is_primitive && rhs->is_primitive &&
            is_int_prim(lhs->prim.value()) && is_int_prim(rhs->prim.value()) &&
            effective_width(lhs->prim.value(), lhs->bit_width) ==
            effective_width(rhs->prim.value(), rhs->bit_width)) return true;
        return false;
    }

    if (lhs->is_primitive != rhs->is_primitive) return false;
    if (!lhs->is_primitive)
        return lhs->name.value_or("") == rhs->name.value_or("");

    prim_type_t lp = lhs->prim.value(), rp = rhs->prim.value();
    if (lp == rp && lhs->bit_width == rhs->bit_width) return true;

    if (is_int_prim(lp)   && is_int_prim(rp))   return true; // implicit integer conversion
    if (is_float_prim(lp) && is_float_prim(rp)) return true; // implicit float narrowing/widening
    if (is_float_prim(lp) && is_int_prim(rp))   return true; // int -> float
    if (is_int_prim(lp)   && is_bool_prim(rp))  return true; // bool -> int
    if (is_bool_prim(lp)  && is_int_prim(rp))   return true; // int -> bool
    if (is_bool_prim(lp)  && is_bool_prim(rp))  return true;

    return false;
}

// Is the type usable as a condition (if/while/for)?
inline bool is_truthy(const type_node* t) {
    if (!t) return false;
    if (t->pointer_depth > 0) return true;
    if (!t->is_primitive) return false;
    prim_type_t p = t->prim.value();
    return is_numeric_prim(p) || is_bool_prim(p);
}

// Equality/inequality comparable (==, !=)
inline bool eq_comparable(const type_node* a, const type_node* b) {
    if (types_equal(a, b)) return true;
    if (a->pointer_depth > 0 && b->pointer_depth > 0) return true;
    if (a->pointer_depth > 0 && b->is_null_literal) return true;
    if (b->pointer_depth > 0 && a->is_null_literal) return true;
    if (a->pointer_depth > 0 && b->is_primitive && is_int_prim(b->prim.value())) return true;
    if (b->pointer_depth > 0 && a->is_primitive && is_int_prim(a->prim.value())) return true;
    if (!a->is_primitive || !b->is_primitive) return false;
    prim_type_t ap = a->prim.value(), bp = b->prim.value();
    return (is_numeric_prim(ap) || is_bool_prim(ap)) &&
           (is_numeric_prim(bp) || is_bool_prim(bp));
}

// Compute the promoted type of two primitive operands.
// Returns {prim_type_t, bit_width} for the result of a binary operation.
#include <utility>
inline std::pair<prim_type_t, uint32_t> promote_pair(
    prim_type_t ap, uint32_t abw, prim_type_t bp, uint32_t bbw)
{
    bool af = is_float_prim(ap), bf = is_float_prim(bp);
    if (af && bf) return {prim_type_t::arb_float, std::max(abw, bbw)};
    if (af)       return {ap, abw};
    if (bf)       return {bp, bbw};
    // Both integer-category (int/uint/char/bool)
    uint32_t wa = effective_width(ap, abw), wb = effective_width(bp, bbw);
    uint32_t maxw = std::max(wa, wb);
    if (ap == prim_type_t::arb_uint || bp == prim_type_t::arb_uint)
        return {prim_type_t::arb_uint, maxw};
    if (ap == prim_type_t::arb_bool && bp == prim_type_t::arb_bool)
        return {prim_type_t::arb_bool, maxw};
    return {prim_type_t::arb_int, maxw};
}

// Ordered comparison (<, >, <=, >=)
inline bool ord_comparable(const type_node* a, const type_node* b) {
    if (a->pointer_depth > 0 && b->pointer_depth > 0 && types_equal(a, b)) return true;
    if (!a->is_primitive || !b->is_primitive) return false;
    return is_numeric_prim(a->prim.value()) && is_numeric_prim(b->prim.value());
}
