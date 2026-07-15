#pragma once
#include "context.hxx"
#include "types.hxx"
#include <unordered_map>
#include <string>
#include <vector>

// ---- Template string substitution ----------------------------------------
// Replaces %varname with $N and *K (1-indexed input) with $N in the raw
// instruction text, where N is the operand's absolute index in the LLVM
// constraint ordering (outputs first, then inputs).

static std::string asm_substitute(
    const std::string& raw,
    const std::vector<asm_constraint_entry>& outputs,
    const std::vector<asm_constraint_entry>& inputs)
{
    std::unordered_map<std::string, size_t> name_idx;
    for (size_t i = 0; i < outputs.size(); i++) name_idx[outputs[i].varname] = i;
    for (size_t i = 0; i < inputs.size();  i++) name_idx[inputs[i].varname]  = outputs.size() + i;

    std::string result;
    result.reserve(raw.size() + 16);
    size_t pos = 0;
    size_t n   = raw.size();

    while (pos < n) {
        char c = raw[pos];
        if (c == '%') {
            // %varname → $idx
            pos++;
            std::string name;
            while (pos < n && (std::isalnum((unsigned char)raw[pos]) || raw[pos] == '_'))
                name += raw[pos++];
            auto it = name_idx.find(name);
            if (it != name_idx.end())
                result += "$" + std::to_string(it->second);
            else
                result += "%" + name; // passthrough if unknown (e.g. %rax in AT&T)
        } else if (c == '*') {
            // *K (1-indexed input) → $(outputs.size() + K - 1)
            pos++;
            std::string digits;
            while (pos < n && std::isdigit((unsigned char)raw[pos])) digits += raw[pos++];
            if (!digits.empty()) {
                size_t k   = static_cast<size_t>(std::stoul(digits));
                size_t idx = outputs.size() + (k > 0 ? k - 1 : 0);
                result += "$" + std::to_string(idx);
            } else {
                result += '*';
            }
        } else if (c == '$') {
            result += "$$"; // escape bare '$' in user asm text
            pos++;
        } else {
            result += c;
            pos++;
        }
    }
    return result;
}

// ---- Constraint string builder --------------------------------------------
// Format: "=mod,...,mod,...,~{reg},..."
// Outputs (with "=" prefix) come first, then inputs, then clobbers.

static std::string asm_constraints(
    const std::vector<asm_constraint_entry>& outputs,
    const std::vector<asm_constraint_entry>& inputs,
    const std::vector<std::string>&          clobbers)
{
    std::string s;
    for (auto& out : outputs) {
        if (!s.empty()) s += ",";
        s += "=" + out.modifier;
    }
    for (auto& in : inputs) {
        if (!s.empty()) s += ",";
        s += in.modifier;
    }
    for (auto& clob : clobbers) {
        if (clob == "cca") continue; // "cca" = automatic, emit no explicit clobber
        if (!s.empty()) s += ",";
        s += "~{" + clob + "}";
    }
    return s;
}

// ---- Variable helpers -----------------------------------------------------

static LLVMTypeRef asm_var_type(const std::string& name, ir_context* ctx) {
    LLVMTypeRef t = ctx->lookup_local_type(name);
    if (t) return t;
    auto git = ctx->global_vars.find(name);
    if (git != ctx->global_vars.end()) return LLVMGlobalGetValueType(git->second);
    return LLVMInt64TypeInContext(ctx->llvm_ctx); // fallback
}

static LLVMValueRef asm_load(const std::string& name, ir_context* ctx) {
    LLVMValueRef ptr  = ctx->lookup_local(name);
    LLVMTypeRef  type = ctx->lookup_local_type(name);
    if (ptr && type)
        return LLVMBuildLoad2(ctx->llvm_builder, type, ptr, name.c_str());
    auto git = ctx->global_vars.find(name);
    if (git != ctx->global_vars.end()) {
        LLVMTypeRef gt = LLVMGlobalGetValueType(git->second);
        return LLVMBuildLoad2(ctx->llvm_builder, gt, git->second, name.c_str());
    }
    throw std::runtime_error("IR: inline asm: cannot load input '" + name + "'");
}

static void asm_store(const std::string& name, LLVMValueRef val, ir_context* ctx) {
    LLVMValueRef ptr = ctx->lookup_local(name);
    if (ptr) { LLVMBuildStore(ctx->llvm_builder, val, ptr); return; }
    auto git = ctx->global_vars.find(name);
    if (git != ctx->global_vars.end()) { LLVMBuildStore(ctx->llvm_builder, val, git->second); return; }
    throw std::runtime_error("IR: inline asm: cannot store output '" + name + "'");
}

// ---- Main visitor ---------------------------------------------------------

inline void visit_asm_stmt(asm_stmt* s, ir_context* ctx) {
    auto& outs  = s->outputs;
    auto& ins   = s->inputs;
    auto& clobs = s->clobbers;

    // Build the substituted asm template.
    std::string tmpl = asm_substitute(s->raw_instructions, outs, ins);
    // Trim leading/trailing blank lines so LLVM doesn't see an empty first line.
    {
        size_t b = tmpl.find_first_not_of("\r\n \t");
        size_t e = tmpl.find_last_not_of("\r\n \t");
        tmpl = (b == std::string::npos) ? "" : tmpl.substr(b, e - b + 1);
    }

    // Build LLVM constraint string.
    std::string constraint_str = asm_constraints(outs, ins, clobs);

    // Collect input values and their LLVM types.
    std::vector<LLVMValueRef> args;
    std::vector<LLVMTypeRef>  param_types;
    args.reserve(ins.size());
    param_types.reserve(ins.size());
    for (auto& in : ins) {
        LLVMValueRef v = asm_load(in.varname, ctx);
        args.push_back(v);
        param_types.push_back(LLVMTypeOf(v));
    }

    // Determine the return type (void / single / struct of outputs).
    LLVMTypeRef ret_type;
    if (outs.empty()) {
        ret_type = LLVMVoidTypeInContext(ctx->llvm_ctx);
    } else if (outs.size() == 1) {
        ret_type = asm_var_type(outs[0].varname, ctx);
    } else {
        std::vector<LLVMTypeRef> out_types;
        out_types.reserve(outs.size());
        for (auto& out : outs) out_types.push_back(asm_var_type(out.varname, ctx));
        ret_type = LLVMStructTypeInContext(
            ctx->llvm_ctx, out_types.data(), (unsigned)out_types.size(), /*packed=*/0);
    }

    LLVMTypeRef fn_type = LLVMFunctionType(
        ret_type, param_types.data(), (unsigned)param_types.size(), /*vararg=*/0);

    LLVMValueRef asm_val = LLVMGetInlineAsm(
        fn_type,
        tmpl.c_str(),            tmpl.size(),
        constraint_str.c_str(),  constraint_str.size(),
        /*HasSideEffects=*/1,
        /*IsAlignStack=*/0,
        LLVMInlineAsmDialectIntel,
        /*CanThrow=*/0);

    LLVMValueRef call_result = LLVMBuildCall2(
        ctx->llvm_builder, fn_type, asm_val,
        args.empty() ? nullptr : args.data(),
        (unsigned)args.size(),
        outs.empty() ? "" : "asm_out");

    // Write outputs back to their variables.
    if (outs.size() == 1) {
        asm_store(outs[0].varname, call_result, ctx);
    } else {
        for (unsigned i = 0; i < (unsigned)outs.size(); i++) {
            LLVMValueRef v = LLVMBuildExtractValue(
                ctx->llvm_builder, call_result, i,
                ("out_" + outs[i].varname).c_str());
            asm_store(outs[i].varname, v, ctx);
        }
    }
}
