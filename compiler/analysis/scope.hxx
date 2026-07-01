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
    // Functions: keyed by name, each entry is a list of overloads
    std::unordered_map<std::string, std::vector<func_decl*>> global_funcs;
    std::unordered_map<std::string, struct_decl*>  structs;
    std::unordered_map<std::string, enum_decl*>    enums;
    std::unordered_map<std::string, enum_decl*>    enum_variants; // variant name → owning enum
    std::unordered_map<std::string, union_decl*>   unions;
    std::unordered_map<std::string, typedef_decl*> typedefs;
    std::unordered_map<std::string, class_decl*>   classes;

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
    // Same name + same params = same overload; different params = new overload.
    void declare_func(func_decl* d) {
        auto& vec = global_funcs[d->name];
        for (auto* existing : vec) {
            if (params_match(existing, d)) {
                // Same overload
                if (existing->body && d->body)
                    throw std::runtime_error(
                        "Semantic Error at line " + std::to_string(d->line) +
                        ": Redefinition of function '" + d->name + "'");
                if (d->body) *existing = *d; // update with body
                return;
            }
        }
        // New overload
        vec.push_back(d);
        if (vec.size() > 1) {
            // Mark all as overloaded
            for (auto* f : vec) f->is_overloaded = true;
        }
    }

    // Look up first (or only) overload - for backward compat; prefer lookup_overloads.
    func_decl* lookup_func(const std::string& name) const {
        auto it = global_funcs.find(name);
        if (it == global_funcs.end() || it->second.empty()) return nullptr;
        return it->second.front();
    }

    // All overloads for a name
    const std::vector<func_decl*>* lookup_overloads(const std::string& name) const {
        auto it = global_funcs.find(name);
        if (it == global_funcs.end()) return nullptr;
        return &it->second;
    }

    void declare_class(class_decl* d) {
        if (classes.count(d->name))
            throw std::runtime_error(
                "Semantic Error at line " + std::to_string(d->line) +
                ": Redeclaration of class '" + d->name + "'");
        if (structs.count(d->name))
            throw std::runtime_error(
                "Semantic Error at line " + std::to_string(d->line) +
                ": '" + d->name + "' already declared as a struct");
        classes[d->name] = d;
    }

    class_decl* lookup_class(const std::string& name) const {
        auto it = classes.find(name);
        return it != classes.end() ? it->second : nullptr;
    }

private:
    static bool params_match(const func_decl* a, const func_decl* b) {
        if (a->params.size() != b->params.size()) return false;
        for (size_t i = 0; i < a->params.size(); i++) {
            const type_node* ta = a->params[i].type;
            const type_node* tb = b->params[i].type;
            if (!ta || !tb) return false;
            if (ta->pointer_depth != tb->pointer_depth) return false;
            if (ta->is_primitive != tb->is_primitive)   return false;
            if (ta->is_primitive && ta->prim != tb->prim) return false;
            if (!ta->is_primitive && ta->name != tb->name) return false;
        }
        return true;
    }
public:

    void declare_struct(struct_decl* d) {
        if (structs.count(d->name))
            throw std::runtime_error(
                "Semantic Error at line " + std::to_string(d->line) +
                ": Redeclaration of struct '" + d->name + "'");
        if (classes.count(d->name))
            throw std::runtime_error(
                "Semantic Error at line " + std::to_string(d->line) +
                ": '" + d->name + "' already declared as a class");
        structs[d->name] = d;
    }

    void declare_enum(enum_decl* d) {
        if (enums.count(d->name))
            throw std::runtime_error(
                "Semantic Error at line " + std::to_string(d->line) +
                ": Redeclaration of enum '" + d->name + "'");
        enums[d->name] = d;
        for (auto& [vname, vval] : d->variants)
            enum_variants[vname] = d;
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
               unions.count(name) || typedefs.count(name) ||
               classes.count(name);
    }
};
