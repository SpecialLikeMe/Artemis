#pragma once
#include <unordered_map>
#include <vector>
#include <string>
#include <stdexcept>
#include "../parser/main.hxx"

class scope_manager {
    struct frame_t { std::unordered_map<std::string, var_decl*> vars; };
    std::vector<frame_t> frames;

public:
    std::unordered_map<std::string, func_decl*>    global_funcs;
    std::unordered_map<std::string, struct_decl*>  structs;
    std::unordered_map<std::string, enum_decl*>    enums;
    std::unordered_map<std::string, union_decl*>   unions;
    std::unordered_map<std::string, typedef_decl*> typedefs;

    void push() { frames.emplace_back(); }
    void pop()  { if (!frames.empty()) frames.pop_back(); }

    void declare_var(const std::string& name, var_decl* d) {
        if (frames.empty()) push();
        if (frames.back().vars.count(name))
            throw std::runtime_error(
                "Semantic Error at line " + std::to_string(d->line) +
                ": Redeclaration of '" + name + "' in the same scope");
        frames.back().vars[name] = d;
    }

    var_decl* lookup_var(const std::string& name) const {
        for (auto it = frames.rbegin(); it != frames.rend(); ++it) {
            auto f = it->vars.find(name);
            if (f != it->vars.end()) return f->second;
        }
        return nullptr;
    }

    // Forward declarations allowed; redefinition (two bodies) is an error.
    void declare_func(func_decl* d) {
        auto it = global_funcs.find(d->name);
        if (it != global_funcs.end() && it->second->body && d->body)
            throw std::runtime_error(
                "Semantic Error at line " + std::to_string(d->line) +
                ": Redefinition of function '" + d->name + "'");
        if (d->body || it == global_funcs.end())
            global_funcs[d->name] = d;
    }

    func_decl* lookup_func(const std::string& name) const {
        auto it = global_funcs.find(name);
        return it != global_funcs.end() ? it->second : nullptr;
    }

    void declare_struct(struct_decl* d) {
        if (structs.count(d->name))
            throw std::runtime_error(
                "Semantic Error at line " + std::to_string(d->line) +
                ": Redeclaration of struct '" + d->name + "'");
        structs[d->name] = d;
    }

    void declare_enum(enum_decl* d) {
        if (enums.count(d->name))
            throw std::runtime_error(
                "Semantic Error at line " + std::to_string(d->line) +
                ": Redeclaration of enum '" + d->name + "'");
        enums[d->name] = d;
    }

    void declare_union(union_decl* d) {
        if (unions.count(d->name))
            throw std::runtime_error(
                "Semantic Error at line " + std::to_string(d->line) +
                ": Redeclaration of union '" + d->name + "'");
        unions[d->name] = d;
    }

    void declare_typedef(typedef_decl* d) {
        if (typedefs.count(d->alias))
            throw std::runtime_error(
                "Semantic Error at line " + std::to_string(d->line) +
                ": Redeclaration of typedef '" + d->alias + "'");
        typedefs[d->alias] = d;
    }

    bool is_known_type(const std::string& name) const {
        return structs.count(name) || enums.count(name) ||
               unions.count(name) || typedefs.count(name);
    }
};
