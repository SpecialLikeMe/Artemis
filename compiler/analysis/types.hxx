#pragma once
#include <string>
#include "../parser/expr.hxx"

// ------------------------------------------------------------------ stringify

inline std::string prim_to_str(prim_type_t p) {
    switch (p) {
        case prim_type_t::char_t:  return "char";
        case prim_type_t::i8:      return "i8";
        case prim_type_t::i16:     return "i16";
        case prim_type_t::i32:     return "i32";
        case prim_type_t::i64:     return "i64";
        case prim_type_t::i128:    return "i128";
        case prim_type_t::i256:    return "i256";
        case prim_type_t::i512:    return "i512";
        case prim_type_t::u8:      return "u8";
        case prim_type_t::u16:     return "u16";
        case prim_type_t::u32:     return "u32";
        case prim_type_t::u64:     return "u64";
        case prim_type_t::u128:    return "u128";
        case prim_type_t::u256:    return "u256";
        case prim_type_t::u512:    return "u512";
        case prim_type_t::f8:      return "f8";
        case prim_type_t::f16:     return "f16";
        case prim_type_t::f32:     return "f32";
        case prim_type_t::f64:     return "f64";
        case prim_type_t::f128:    return "f128";
        case prim_type_t::f256:    return "f256";
        case prim_type_t::f512:    return "f512";
        case prim_type_t::boolean: return "bool";
        case prim_type_t::b1:      return "b1";
        case prim_type_t::b8:      return "b8";
        case prim_type_t::b16:     return "b16";
        case prim_type_t::b32:     return "b32";
        case prim_type_t::b64:     return "b64";
        case prim_type_t::b128:    return "b128";
        case prim_type_t::b256:    return "b256";
        case prim_type_t::b512:    return "b512";
        case prim_type_t::void_t:  return "void";
        default:                   return "?";
    }
}

inline std::string type_to_str(const type_node* t) {
    if (!t) return "<null-type>";
    std::string s;
    if (t->is_extern)   s += "extern ";
    if (t->is_inline)   s += "inline ";
    if (t->is_register) s += "register ";
    if (t->is_const)    s += "const ";
    s += t->is_primitive ? prim_to_str(t->prim.value())
                         : t->name.value_or("<unnamed>");
    for (int i = 0; i < t->pointer_depth; i++) s += '*';
    if (t->array_size.has_value()) s += "[]";
    return s;
}

// ------------------------------------------------------------------ category checks

inline bool is_int_prim(prim_type_t p) {
    switch (p) {
        case prim_type_t::char_t:
        case prim_type_t::i8:   case prim_type_t::i16:  case prim_type_t::i32:
        case prim_type_t::i64:  case prim_type_t::i128: case prim_type_t::i256:
        case prim_type_t::i512:
        case prim_type_t::u8:   case prim_type_t::u16:  case prim_type_t::u32:
        case prim_type_t::u64:  case prim_type_t::u128: case prim_type_t::u256:
        case prim_type_t::u512: return true;
        default:                return false;
    }
}

inline bool is_float_prim(prim_type_t p) {
    switch (p) {
        case prim_type_t::f8:   case prim_type_t::f16:  case prim_type_t::f32:
        case prim_type_t::f64:  case prim_type_t::f128: case prim_type_t::f256:
        case prim_type_t::f512: return true;
        default:                return false;
    }
}

inline bool is_bool_prim(prim_type_t p) {
    switch (p) {
        case prim_type_t::boolean:
        case prim_type_t::b1:   case prim_type_t::b8:   case prim_type_t::b16:
        case prim_type_t::b32:  case prim_type_t::b64:  case prim_type_t::b128:
        case prim_type_t::b256: case prim_type_t::b512: return true;
        default:                return false;
    }
}

inline bool is_numeric_prim(prim_type_t p) { return is_int_prim(p) || is_float_prim(p); }

inline bool is_unsigned_int(prim_type_t p) {
    switch (p) {
        case prim_type_t::u8:   case prim_type_t::u16:  case prim_type_t::u32:
        case prim_type_t::u64:  case prim_type_t::u128: case prim_type_t::u256:
        case prim_type_t::u512: return true;
        default:                return false;
    }
}

// ------------------------------------------------------------------ ranks / promotion

inline int int_rank(prim_type_t p) {
    switch (p) {
        case prim_type_t::char_t:
        case prim_type_t::i8:   case prim_type_t::u8:   return 1;
        case prim_type_t::i16:  case prim_type_t::u16:  return 2;
        case prim_type_t::i32:  case prim_type_t::u32:  return 3;
        case prim_type_t::i64:  case prim_type_t::u64:  return 4;
        case prim_type_t::i128: case prim_type_t::u128: return 5;
        case prim_type_t::i256: case prim_type_t::u256: return 6;
        case prim_type_t::i512: case prim_type_t::u512: return 7;
        default:                return 0;
    }
}

inline int float_rank(prim_type_t p) {
    switch (p) {
        case prim_type_t::f8:   return 1;
        case prim_type_t::f16:  return 2;
        case prim_type_t::f32:  return 3;
        case prim_type_t::f64:  return 4;
        case prim_type_t::f128: return 5;
        case prim_type_t::f256: return 6;
        case prim_type_t::f512: return 7;
        default:                return 0;
    }
}

inline prim_type_t wider_int(prim_type_t a, prim_type_t b) {
    int ra = int_rank(a), rb = int_rank(b);
    if (ra != rb) return ra > rb ? a : b;
    return is_unsigned_int(a) ? a : b; // same rank: prefer unsigned
}

inline prim_type_t wider_float(prim_type_t a, prim_type_t b) {
    return float_rank(a) >= float_rank(b) ? a : b;
}

inline prim_type_t promote_prim(prim_type_t a, prim_type_t b) {
    bool af = is_float_prim(a), bf = is_float_prim(b);
    if (af && bf) return wider_float(a, b);
    if (af)       return a;
    if (bf)       return b;
    return wider_int(a, b);
}

// ------------------------------------------------------------------ compatibility

inline bool types_equal(const type_node* a, const type_node* b) {
    if (!a || !b) return false;
    if (a->pointer_depth != b->pointer_depth) return false;
    if (a->is_primitive != b->is_primitive)   return false;
    if (a->is_primitive) return a->prim.value() == b->prim.value();
    return a->name.value_or("") == b->name.value_or("");
}

// Can a value of type `rhs` be assigned to a location of type `lhs`?
inline bool assignable(const type_node* lhs, const type_node* rhs) {
    if (!lhs || !rhs) return false;

    // array-to-pointer decay: T[] decays to T* (and T[]* etc.)
    if (rhs->array_size.has_value() && lhs->pointer_depth == rhs->pointer_depth + 1) {
        if (lhs->is_primitive && rhs->is_primitive) {
            if (lhs->prim == rhs->prim) return true;
            if (lhs->prim == prim_type_t::void_t) return true; // void* <- T[]
        } else if (!lhs->is_primitive && !rhs->is_primitive) {
            if (lhs->name.value_or("") == rhs->name.value_or("")) return true;
        }
    }

    // null pointer constant: any integer can be assigned to a pointer (e.g. return 0 from void*)
    if (lhs->pointer_depth > 0 && rhs->pointer_depth == 0 &&
        rhs->is_primitive && is_int_prim(rhs->prim.value())) return true;

    // pointer assignment
    if (lhs->pointer_depth > 0 || rhs->pointer_depth > 0) {
        if (lhs->pointer_depth != rhs->pointer_depth) return false;
        bool lv = lhs->is_primitive && lhs->prim == prim_type_t::void_t;
        bool rv = rhs->is_primitive && rhs->prim == prim_type_t::void_t;
        if (lv || rv || types_equal(lhs, rhs)) return true;
        // Same-rank integer pointer coercion: i8* ↔ u8* (char* interop), etc.
        if (lhs->is_primitive && rhs->is_primitive &&
            is_int_prim(lhs->prim.value()) && is_int_prim(rhs->prim.value()) &&
            int_rank(lhs->prim.value()) == int_rank(rhs->prim.value())) return true;
        return false;
    }

    if (lhs->is_primitive != rhs->is_primitive) return false;
    if (!lhs->is_primitive)
        return lhs->name.value_or("") == rhs->name.value_or("");

    prim_type_t lp = lhs->prim.value(), rp = rhs->prim.value();
    if (lp == rp) return true;

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
    if (a->pointer_depth > 0 && b->pointer_depth > 0) return true; // ptr == ptr
    // null literal (int 0) against pointer
    if (a->pointer_depth > 0 && b->is_primitive && is_int_prim(b->prim.value())) return true;
    if (b->pointer_depth > 0 && a->is_primitive && is_int_prim(a->prim.value())) return true;
    if (!a->is_primitive || !b->is_primitive) return false;
    prim_type_t ap = a->prim.value(), bp = b->prim.value();
    return (is_numeric_prim(ap) || is_bool_prim(ap)) &&
           (is_numeric_prim(bp) || is_bool_prim(bp));
}

// Ordered comparison (<, >, <=, >=)
inline bool ord_comparable(const type_node* a, const type_node* b) {
    if (a->pointer_depth > 0 && b->pointer_depth > 0 && types_equal(a, b)) return true;
    if (!a->is_primitive || !b->is_primitive) return false;
    return is_numeric_prim(a->prim.value()) && is_numeric_prim(b->prim.value());
}
