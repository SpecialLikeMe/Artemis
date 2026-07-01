#pragma once
#include "types.hxx"
#include "../parser/main.hxx"

// Encode a single type_node into a short string for name mangling.
inline std::string mangle_type(const type_node* t) {
    if (!t) return "v";
    if (t->is_func_ptr) return "FP";
    std::string s;
    for (int i = 0; i < t->pointer_depth; i++) s += "P";
    if (t->is_primitive) {
        switch (t->prim.value_or(prim_type_t::void_t)) {
            case prim_type_t::void_t:  s += "v";    break;
            case prim_type_t::char_t:
            case prim_type_t::i8:      s += "i8";   break;
            case prim_type_t::i16:     s += "i16";  break;
            case prim_type_t::i32:     s += "i32";  break;
            case prim_type_t::i64:     s += "i64";  break;
            case prim_type_t::i128:    s += "i128"; break;
            case prim_type_t::u8:      s += "u8";   break;
            case prim_type_t::u16:     s += "u16";  break;
            case prim_type_t::u32:     s += "u32";  break;
            case prim_type_t::u64:     s += "u64";  break;
            case prim_type_t::u128:    s += "u128"; break;
            case prim_type_t::f32:     s += "f32";  break;
            case prim_type_t::f64:     s += "f64";  break;
            case prim_type_t::boolean: s += "b";    break;
            default:                   s += "?";    break;
        }
    } else {
        s += t->name.value_or("?");
    }
    return s;
}

// Build the mangled name for an overloaded function: funcname__type1_type2_...
inline std::string build_mangled_name(const std::string& base, const std::vector<param_decl>& params) {
    std::string m = base + "__";
    for (size_t i = 0; i < params.size(); i++) {
        if (i) m += "_";
        m += mangle_type(params[i].type);
    }
    return m;
}

// Get the IR name for a func_decl (handles mangling, extern "C", class methods).
inline std::string ir_func_name(const func_decl* fd) {
    if (fd->is_extern_c)         return fd->name;
    if (!fd->mangled_name.empty()) return fd->mangled_name;
    if (fd->is_overloaded)       return build_mangled_name(fd->name, fd->params);
    return fd->name;
}
