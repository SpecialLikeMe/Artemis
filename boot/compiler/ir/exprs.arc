// Expression IR generation for the Artemis self-hosting compiler.

namespace ir {

// Forward declarations
i8* visit_expr(parser.expr_node* e, ir_context* ctx);
i8* visit_lvalue(parser.expr_node* e, ir_context* ctx);

// Resolve the LLVM struct type and base pointer for a member-access chain.
// Works with LLVM opaque pointers by using the ir_context type tables instead
// of LLVMGetElementType (which returns null in opaque-pointer mode).
// Returns the pointer to use as base for LLVMBuildStructGEP2, and writes the
// struct type to *out_struct_type.  Returns null if the chain cannot be resolved.
i8* resolve_struct_base(parser.expr_node* obj, ir_context* ctx, i8** out_struct_type) {
    *out_struct_type = (i8*)0;

    if (obj.kind == ek_identifier) {
        i8* local_t = ctx_lookup_local_type(ctx, obj.str_val);
        i8* alloca  = ctx_lookup_local(ctx, obj.str_val);
        if (alloca == (i8*)0 || local_t == (i8*)0) { return (i8*)0; }

        if (LLVMGetTypeKind(local_t) == LLVMStructTypeKind) {
            // Struct by value: alloca is the struct pointer
            *out_struct_type = local_t;
            return alloca;
        }
        // Pointer-to-struct: load to get the struct pointer
        i8* deref_t = ctx_lookup_deref_type(ctx, obj.str_val);
        if (deref_t != (i8*)0 && LLVMGetTypeKind(deref_t) == LLVMStructTypeKind) {
            *out_struct_type = deref_t;
            return LLVMBuildLoad2(ctx.llvm_builder, local_t, alloca, "ptr_deref");
        }
        return (i8*)0;
    }

    // (*ptr).field — explicit dereference of a pointer-to-struct
    if (obj.kind == ek_unary && obj.uop == uop_deref && obj.operand != (parser.expr_node*)0) {
        if (obj.operand.kind == ek_identifier) {
            i8* local_t = ctx_lookup_local_type(ctx, obj.operand.str_val);
            i8* alloca  = ctx_lookup_local(ctx, obj.operand.str_val);
            if (alloca == (i8*)0 || local_t == (i8*)0) { return (i8*)0; }
            i8* deref_t = ctx_lookup_deref_type(ctx, obj.operand.str_val);
            if (deref_t != (i8*)0 && LLVMGetTypeKind(deref_t) == LLVMStructTypeKind) {
                *out_struct_type = deref_t;
                return LLVMBuildLoad2(ctx.llvm_builder, local_t, alloca, "ptr_deref");
            }
        }
        return (i8*)0;
    }

    // arr[i].field — array-of-struct subscript
    if (obj.kind == ek_subscript && obj.object != (parser.expr_node*)0) {
        i8* elem_ptr = visit_lvalue(obj, ctx);
        if (elem_ptr == (i8*)0) { return (i8*)0; }
        if (obj.object.kind == ek_identifier) {
            i8* local_t = ctx_lookup_local_type(ctx, obj.object.str_val);
            if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMArrayTypeKind) {
                i8* elem_t = LLVMGetElementType(local_t);
                if (elem_t != (i8*)0 && LLVMGetTypeKind(elem_t) == LLVMStructTypeKind) {
                    *out_struct_type = elem_t;
                    return elem_ptr;
                }
            }
        }
        return (i8*)0;
    }

    if (obj.kind == ek_member) {
        i8* parent_st = (i8*)0;
        i8* parent_ptr = resolve_struct_base(obj.object, ctx, &parent_st);
        if (parent_ptr == (i8*)0 || parent_st == (i8*)0) { return (i8*)0; }

        i8* pname = LLVMGetStructName(parent_st);
        if (pname == (i8*)0) { return (i8*)0; }

        i32 fidx = ctx_field_index(ctx, pname, obj.member_name);
        if (fidx < 0) {
            if (ctx.current_namespace != (i8*)0) {
                i8 ns_pname[512];
                snprintf(ns_pname, (u64)512, "%s__NS_%s", ctx.current_namespace, pname);
                fidx = ctx_field_index(ctx, ns_pname, obj.member_name);
                if (fidx >= 0) { pname = lexer.str_dup(ns_pname); parent_st = st_map_get(&ctx.struct_types, pname); }
            }
        }
        if (fidx < 0) { return (i8*)0; }

        i8* ft = ctx_field_type(ctx, pname, fidx);
        if (ft == (i8*)0) { return (i8*)0; }

        i8* gep = LLVMBuildStructGEP2(ctx.llvm_builder, parent_st, parent_ptr, (i32)fidx, obj.member_name);

        if (LLVMGetTypeKind(ft) == LLVMStructTypeKind) {
            *out_struct_type = ft;
            return gep;
        }
        struct_meta* sm = struct_meta_find(&ctx.struct_meta_tbl, pname);
        if (sm != (struct_meta*)0 && fidx < sm.field_pointee.len) {
            i8* pt = sm.field_pointee.data[fidx];
            if (pt != (i8*)0 && LLVMGetTypeKind(pt) == LLVMStructTypeKind) {
                *out_struct_type = pt;
                return LLVMBuildLoad2(ctx.llvm_builder, ft, gep, "fld_deref");
            }
        }
        return (i8*)0;
    }

    return (i8*)0;
}

// Infer the struct LLVM type for an expression WITHOUT emitting any IR.
// Returns the struct type if the expression is a struct or pointer-to-struct,
// else returns null.
i8* infer_expr_struct_type(parser.expr_node* e, ir_context* ctx) {
    if (e == (parser.expr_node*)0) { return (i8*)0; }
    if (e.kind == ek_identifier) {
        i8* local_t = ctx_lookup_local_type(ctx, e.str_val);
        if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMStructTypeKind) {
            return local_t;
        }
        i8* deref_t = ctx_lookup_deref_type(ctx, e.str_val);
        if (deref_t != (i8*)0 && LLVMGetTypeKind(deref_t) == LLVMStructTypeKind) {
            return deref_t;
        }
        return (i8*)0;
    }
    if (e.kind == ek_unary && e.uop == uop_deref && e.operand != (parser.expr_node*)0) {
        if (e.operand.kind == ek_identifier) {
            i8* deref_t = ctx_lookup_deref_type(ctx, e.operand.str_val);
            if (deref_t != (i8*)0 && LLVMGetTypeKind(deref_t) == LLVMStructTypeKind) {
                return deref_t;
            }
        }
        return (i8*)0;
    }
    if (e.kind == ek_member && e.member_name != (i8*)0) {
        i8* parent_st = infer_expr_struct_type(e.object, ctx);
        if (parent_st == (i8*)0) { return (i8*)0; }
        i8* pname = LLVMGetStructName(parent_st);
        if (pname == (i8*)0) { return (i8*)0; }
        i32 fidx = ctx_field_index(ctx, pname, e.member_name);
        if (fidx < 0) { return (i8*)0; }
        i8* ft = ctx_field_type(ctx, pname, fidx);
        if (ft != (i8*)0 && LLVMGetTypeKind(ft) == LLVMStructTypeKind) { return ft; }
        struct_meta* sm = struct_meta_find(&ctx.struct_meta_tbl, pname);
        if (sm != (struct_meta*)0 && fidx < sm.field_pointee.len) {
            i8* pt = sm.field_pointee.data[fidx];
            if (pt != (i8*)0 && LLVMGetTypeKind(pt) == LLVMStructTypeKind) { return pt; }
        }
        return (i8*)0;
    }
    // arr[i] where arr is an array of structs
    if (e.kind == ek_subscript && e.object != (parser.expr_node*)0) {
        if (e.object.kind == ek_identifier) {
            i8* local_t = ctx_lookup_local_type(ctx, e.object.str_val);
            if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMArrayTypeKind) {
                i8* elem_t = LLVMGetElementType(local_t);
                if (elem_t != (i8*)0 && LLVMGetTypeKind(elem_t) == LLVMStructTypeKind) {
                    return elem_t;
                }
            }
        }
        return (i8*)0;
    }
    return (i8*)0;
}

// Get the declared element type for an lvalue expression (avoids LLVMGetElementType,
// which is broken in LLVM opaque-pointer mode).
i8* lvalue_elem_type(parser.expr_node* e, ir_context* ctx) {
    if (e == (parser.expr_node*)0) { return (i8*)0; }
    if (e.kind == ek_identifier) {
        i8* local_t = ctx_lookup_local_type(ctx, e.str_val);
        if (local_t != (i8*)0) { return local_t; }
        // Global variable
        i8* gv = sv_map_get(&ctx.global_vars, e.str_val);
        if (gv != (i8*)0) { return LLVMGlobalGetValueType(gv); }
        return (i8*)0;
    }
    if (e.kind == ek_unary && e.uop == uop_deref) {
        if (e.operand != (parser.expr_node*)0 && e.operand.kind == ek_identifier) {
            return ctx_lookup_deref_type(ctx, e.operand.str_val);
        }
        return (i8*)0;
    }
    if (e.kind == ek_member && e.member_name != (i8*)0) {
        i8* struct_type = infer_expr_struct_type(e.object, ctx);
        if (struct_type == (i8*)0) { return (i8*)0; }
        i8* sname = LLVMGetStructName(struct_type);
        if (sname == (i8*)0) { return (i8*)0; }
        i32 fidx = ctx_field_index(ctx, sname, e.member_name);
        if (fidx < 0) {
            if (ctx.current_namespace != (i8*)0) {
                i8 ns_sname[512];
                snprintf(ns_sname, (u64)512, "%s__NS_%s", ctx.current_namespace, sname);
                fidx = ctx_field_index(ctx, ns_sname, e.member_name);
                if (fidx >= 0) { sname = lexer.str_dup(ns_sname); }
            }
        }
        if (fidx < 0) { return (i8*)0; }
        return ctx_field_type(ctx, sname, fidx);
    }
    if (e.kind == ek_subscript && e.object != (parser.expr_node*)0) {
        if (e.object.kind == ek_identifier) {
            i8* local_t = ctx_lookup_local_type(ctx, e.object.str_val);
            if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMArrayTypeKind) {
                return LLVMGetElementType(local_t);
            }
            // Global array
            i8* gv = sv_map_get(&ctx.global_vars, e.object.str_val);
            if (gv != (i8*)0) {
                i8* gv_t = LLVMGlobalGetValueType(gv);
                if (gv_t != (i8*)0 && LLVMGetTypeKind(gv_t) == LLVMArrayTypeKind) {
                    return LLVMGetElementType(gv_t);
                }
            }
            i8* deref_t = ctx_lookup_deref_type(ctx, e.object.str_val);
            if (deref_t != (i8*)0) { return deref_t; }
        }
    }
    return (i8*)0;
}

// Coerce an integer value to a target type (truncate/extend as needed).
i8* coerce_int_val(i8* val, i8* target_type, i8* builder) {
    if (val == (i8*)0 || target_type == (i8*)0) { return val; }
    i8* val_type = LLVMTypeOf(val);
    if (val_type == target_type) { return val; }

    i32 val_kind    = LLVMGetTypeKind(val_type);
    i32 target_kind = LLVMGetTypeKind(target_type);

    if (val_kind == LLVMIntegerTypeKind && target_kind == LLVMIntegerTypeKind) {
        i32 vw = LLVMGetIntTypeWidth(val_type);
        i32 tw = LLVMGetIntTypeWidth(target_type);
        if (vw == tw) { return val; }
        if (vw < tw) {
            // i1 (bool) must be zero-extended; SExt would turn 'true' into -1.
            if (vw == 1) { return LLVMBuildZExt(builder, val, target_type, "zext"); }
            return LLVMBuildSExt(builder, val, target_type, "sext");
        }
        return LLVMBuildTrunc(builder, val, target_type, "trunc");
    }
    if (val_kind == LLVMIntegerTypeKind && target_kind == LLVMPointerTypeKind) {
        return LLVMBuildIntToPtr(builder, val, target_type, "i2p");
    }
    if (val_kind == LLVMPointerTypeKind && target_kind == LLVMIntegerTypeKind) {
        return LLVMBuildPtrToInt(builder, val, target_type, "p2i");
    }
    if (llvm_is_float(val_type) && llvm_is_float(target_type)) {
        return LLVMBuildFPCast(builder, val, target_type, "fpcast");
    }
    return val;
}

// Normalize a value to i1 for use as a branch condition.
i8* to_bool(i8* val, i8* builder, i8* llvm_ctx) {
    if (val == (i8*)0) { return LLVMConstInt(LLVMInt1TypeInContext(llvm_ctx), 0, 0); }
    i8* vt = LLVMTypeOf(val);
    i32 kind = LLVMGetTypeKind(vt);
    if (kind == LLVMIntegerTypeKind) {
        if (LLVMGetIntTypeWidth(vt) == 1) { return val; }
        return LLVMBuildICmp(builder, LLVMIntNE, val,
                                   LLVMConstNull(vt), "tobool");
    }
    if (kind == LLVMPointerTypeKind) {
        return LLVMBuildICmp(builder, LLVMIntNE, val,
                                   LLVMConstNull(vt), "ptobool");
    }
    if (llvm_is_float(vt)) {
        return LLVMBuildFCmp(builder, LLVMRealONE, val,
                                   LLVMConstNull(vt), "ftobool");
    }
    return val;
}

// Get the struct name for a value's type.
i8* get_struct_name_from_val(i8* val) {
    if (val == (i8*)0) { return (i8*)0; }
    i8* vt = LLVMTypeOf(val);
    i32 kind = LLVMGetTypeKind(vt);
    if (kind == LLVMPointerTypeKind) {
        i8* elem = LLVMGetElementType(vt);
        if (LLVMGetTypeKind(elem) == LLVMStructTypeKind) {
            return LLVMGetStructName(elem);
        }
        return (i8*)0;
    }
    if (kind == LLVMStructTypeKind) {
        return LLVMGetStructName(vt);
    }
    return (i8*)0;
}

// Emit a call to a function (handles arg coercion).
i8* emit_call(i8* fn, i8* fn_type, i8** args, i32 nargs, i8* builder) {
    return LLVMBuildCall2(builder, fn_type, fn, args, nargs, "");
}

// Look up a named function, trying namespace qualification.
i8* find_func(i8* name, ir_context* ctx) {
    // Try bare name
    i8* fn = sv_map_get(&ctx.global_funcs, name);
    if (fn != (i8*)0) { return fn; }

    // Try current namespace
    if (ctx.current_namespace != (i8*)0) {
        i8 ns_name[512];
        snprintf(ns_name, (u64)512, "%s__NS_%s", ctx.current_namespace, name);
        fn = sv_map_get(&ctx.global_funcs, ns_name);
        if (fn != (i8*)0) { return fn; }
    }
    return (i8*)0;
}

i8* find_func_type(i8* name, ir_context* ctx) {
    i8* ft = st_map_get(&ctx.global_func_types, name);
    if (ft != (i8*)0) { return ft; }

    if (ctx.current_namespace != (i8*)0) {
        i8 ns_name[512];
        snprintf(ns_name, (u64)512, "%s__NS_%s", ctx.current_namespace, name);
        ft = st_map_get(&ctx.global_func_types, ns_name);
        if (ft != (i8*)0) { return ft; }
    }
    return (i8*)0;
}

// Emit lvalue (pointer to location) for an assignable expression.
i8* visit_lvalue(parser.expr_node* e, ir_context* ctx) {
    if (e == (parser.expr_node*)0) { return (i8*)0; }

    if (e.kind == ek_identifier) {
        i8* alloca = ctx_lookup_local(ctx, e.str_val);
        if (alloca != (i8*)0) { return alloca; }
        // Global var
        i8* gv = sv_map_get(&ctx.global_vars, e.str_val);
        return gv;
    }

    if (e.kind == ek_unary && e.uop == uop_deref) {
        // *ptr -> the pointer value itself is the address
        return visit_expr(e.operand, ctx);
    }

    if (e.kind == ek_subscript) {
        i8* base = visit_lvalue(e.object, ctx);
        if (base == (i8*)0) { base = visit_expr(e.object, ctx); }
        i8* idx  = visit_expr(e.index, ctx);
        if (base == (i8*)0 || idx == (i8*)0) { return (i8*)0; }

        i8* base_type = LLVMTypeOf(base);
        i8* elem_type = (i8*)0;

        i32 bkind = LLVMGetTypeKind(base_type);
        if (bkind == LLVMPointerTypeKind) {
            // Use context lookup to avoid LLVMGetElementType on opaque ptr (broken in LLVM 22).
            i8* inner = (i8*)0;
            if (e.object.kind == ek_identifier) {
                i8* local_t = ctx_lookup_local_type(ctx, e.object.str_val);
                if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMArrayTypeKind) {
                    inner = local_t;
                }
                // Check global arrays too
                if (inner == (i8*)0) {
                    i8* gv = sv_map_get(&ctx.global_vars, e.object.str_val);
                    if (gv != (i8*)0) {
                        i8* gv_t = LLVMGlobalGetValueType(gv);
                        if (gv_t != (i8*)0 && LLVMGetTypeKind(gv_t) == LLVMArrayTypeKind) {
                            inner = gv_t;
                        }
                    }
                }
            }
            if (inner != (i8*)0) {
                // Array subscript: GEP [N x T]*, i64 0, idx
                i8* zero = LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), 0, 0);
                i8* idxs[2];
                idxs[0] = zero;
                idxs[1] = idx;
                return LLVMBuildGEP2(ctx.llvm_builder, inner, base, idxs, 2, "arr_gep");
            }
            // Pointer variable: load the pointer value, then GEP by index.
            i8* ptr_val = LLVMBuildLoad2(ctx.llvm_builder, base_type, base, "ptr_load");
            i8* deref_t = (i8*)0;
            if (e.object.kind == ek_identifier) {
                deref_t = ctx_lookup_deref_type(ctx, e.object.str_val);
            }
            if (deref_t == (i8*)0) { deref_t = LLVMInt8TypeInContext(ctx.llvm_ctx); }
            return LLVMBuildGEP2(ctx.llvm_builder, deref_t, ptr_val, &idx, 1, "ptr_gep");
        }
        return (i8*)0;
    }

    if (e.kind == ek_member) {
        if (e.member_name == (i8*)0) { return (i8*)0; }

        // Use context-aware struct resolution (avoids LLVMGetElementType, which
        // returns null in LLVM opaque-pointer mode).
        i8* struct_type = (i8*)0;
        i8* obj_ptr = resolve_struct_base(e.object, ctx, &struct_type);

        if (obj_ptr == (i8*)0 || struct_type == (i8*)0) { return (i8*)0; }

        i8* sname = LLVMGetStructName(struct_type);
        if (sname == (i8*)0) { return (i8*)0; }

        i32 field_idx = ctx_field_index(ctx, sname, e.member_name);
        if (field_idx < 0) {
            if (ctx.current_namespace != (i8*)0) {
                i8 ns_sname[512];
                snprintf(ns_sname, (u64)512, "%s__NS_%s", ctx.current_namespace, sname);
                field_idx = ctx_field_index(ctx, ns_sname, e.member_name);
                if (field_idx >= 0) {
                    sname = lexer.str_dup(ns_sname);
                    struct_type = st_map_get(&ctx.struct_types, sname);
                }
            }
        }
        if (field_idx < 0) { return (i8*)0; }

        return LLVMBuildStructGEP2(ctx.llvm_builder, struct_type, obj_ptr,
                                   (i32)field_idx, e.member_name);
    }

    return (i8*)0;
}

// Helper to build args array for a call.
i8** build_args(parser.expr_node** arg_nodes, i32 nargs, ir_context* ctx) {
    if (nargs == 0) { return (i8**)0; }
    i8** args = (i8**)malloc(sizeof(i8*) * (u64)nargs);
    i32 i = 0;
    while (i < nargs) {
        i8* av = visit_expr(arg_nodes[i], ctx);
        args[i] = av;
        i = i + 1;
    }
    return args;
}

// Coerce call arguments to match declared parameter types (int width narrowing/widening).
// Skips variadic args beyond the fixed parameter count.
void coerce_args_to_fn(i8* fn_ty, i8** args, i32 nargs, i8* builder) {
    if (fn_ty == (i8*)0) { return; }
    if (LLVMGetTypeKind(fn_ty) != LLVMFunctionTypeKind) { return; }
    i32 np = (i32)LLVMCountParamTypes(fn_ty);
    if (np == 0) { return; }
    i8** param_types = (i8**)malloc(sizeof(i8*) * (u64)np);
    LLVMGetParamTypes(fn_ty, param_types);
    i32 i = 0;
    while (i < nargs && i < np) {
        if (args[i] != (i8*)0 && param_types[i] != (i8*)0) {
            args[i] = coerce_int_val(args[i], param_types[i], builder);
        }
        i = i + 1;
    }
    free((i8*)param_types);
}

i8* visit_binary(parser.expr_node* e, ir_context* ctx) {
    i8* lhs = visit_expr(e.lhs, ctx);
    i8* rhs = visit_expr(e.rhs, ctx);
    if (lhs == (i8*)0 || rhs == (i8*)0) { return (i8*)0; }

    i8* lt = LLVMTypeOf(lhs);
    i8* rt = LLVMTypeOf(rhs);
    bool is_float_op = llvm_is_float(lt);
    bool is_ptr_op   = LLVMGetTypeKind(lt) == LLVMPointerTypeKind;

    // Coerce rhs to lhs type for arithmetic
    if (!is_float_op && !is_ptr_op) {
        rhs = coerce_int_val(rhs, lt, ctx.llvm_builder);
    }
    if (is_float_op) {
        rhs = coerce_int_val(rhs, lt, ctx.llvm_builder);
    }

    // Helper to get pointee type for pointer arithmetic (LLVMGetElementType is broken for opaque ptrs).
    i8* ptr_elem_t = (i8*)0;
    if (is_ptr_op && e.lhs != (parser.expr_node*)0) {
        if (e.lhs.kind == ek_identifier) {
            ptr_elem_t = ctx_lookup_deref_type(ctx, e.lhs.str_val);
        }
        if (ptr_elem_t == (i8*)0) { ptr_elem_t = LLVMInt8TypeInContext(ctx.llvm_ctx); }
    }

    i32 op = e.bop;
    if (op == bop_add) {
        if (is_float_op) { return LLVMBuildFAdd(ctx.llvm_builder, lhs, rhs, "fadd"); }
        if (is_ptr_op)   {
            return LLVMBuildGEP2(ctx.llvm_builder, ptr_elem_t, lhs, &rhs, 1, "ptr_add");
        }
        return LLVMBuildAdd(ctx.llvm_builder, lhs, rhs, "add");
    }
    if (op == bop_sub) {
        if (is_float_op) { return LLVMBuildFSub(ctx.llvm_builder, lhs, rhs, "fsub"); }
        if (is_ptr_op) {
            i8* neg_rhs = LLVMBuildNeg(ctx.llvm_builder, rhs, "neg");
            return LLVMBuildGEP2(ctx.llvm_builder, ptr_elem_t, lhs, &neg_rhs, 1, "ptr_sub");
        }
        return LLVMBuildSub(ctx.llvm_builder, lhs, rhs, "sub");
    }
    if (op == bop_mul) {
        if (is_float_op) { return LLVMBuildFMul(ctx.llvm_builder, lhs, rhs, "fmul"); }
        return LLVMBuildMul(ctx.llvm_builder, lhs, rhs, "mul");
    }
    if (op == bop_div) {
        if (is_float_op) { return LLVMBuildFDiv(ctx.llvm_builder, lhs, rhs, "fdiv"); }
        bool uns = is_unsigned_type_node(e.lhs.cast_type);
        if (uns) { return LLVMBuildUDiv(ctx.llvm_builder, lhs, rhs, "udiv"); }
        return LLVMBuildSDiv(ctx.llvm_builder, lhs, rhs, "sdiv");
    }
    if (op == bop_mod) {
        if (is_float_op) { return LLVMBuildFRem(ctx.llvm_builder, lhs, rhs, "frem"); }
        return LLVMBuildSRem(ctx.llvm_builder, lhs, rhs, "srem");
    }
    if (op == bop_bit_and) { return LLVMBuildAnd(ctx.llvm_builder, lhs, rhs, "and"); }
    if (op == bop_bit_or)  { return LLVMBuildOr(ctx.llvm_builder, lhs, rhs, "or"); }
    if (op == bop_bit_xor) { return LLVMBuildXor(ctx.llvm_builder, lhs, rhs, "xor"); }
    if (op == bop_shl)     { return LLVMBuildShl(ctx.llvm_builder, lhs, rhs, "shl"); }
    if (op == bop_shr)     { return LLVMBuildLShr(ctx.llvm_builder, lhs, rhs, "shr"); }

    // Logical
    if (op == bop_log_and) {
        i8* l1 = to_bool(lhs, ctx.llvm_builder, ctx.llvm_ctx);
        i8* r1 = to_bool(rhs, ctx.llvm_builder, ctx.llvm_ctx);
        return LLVMBuildAnd(ctx.llvm_builder, l1, r1, "land");
    }
    if (op == bop_log_or) {
        i8* l1 = to_bool(lhs, ctx.llvm_builder, ctx.llvm_ctx);
        i8* r1 = to_bool(rhs, ctx.llvm_builder, ctx.llvm_ctx);
        return LLVMBuildOr(ctx.llvm_builder, l1, r1, "lor");
    }

    // Comparison
    i32 pred = -1;
    if (op == bop_eq)  { pred = is_float_op ? LLVMRealOEQ : LLVMIntEQ; }
    if (op == bop_ne)  { pred = is_float_op ? LLVMRealONE : LLVMIntNE; }
    if (op == bop_lt)  { pred = is_float_op ? LLVMRealOLT : LLVMIntSLT; }
    if (op == bop_gt)  { pred = is_float_op ? LLVMRealOGT : LLVMIntSGT; }
    if (op == bop_lte) { pred = is_float_op ? LLVMRealOLE : LLVMIntSLE; }
    if (op == bop_gte) { pred = is_float_op ? LLVMRealOGE : LLVMIntSGE; }

    if (pred >= 0) {
        if (is_float_op) {
            return LLVMBuildFCmp(ctx.llvm_builder, pred, lhs, rhs, "fcmp");
        }
        // For pointer comparisons with integer rhs (e.g. ptr == 0), coerce to ptr null.
        if (is_ptr_op && LLVMGetTypeKind(rt) == LLVMIntegerTypeKind) {
            rhs = coerce_int_val(rhs, lt, ctx.llvm_builder);
        }
        return LLVMBuildICmp(ctx.llvm_builder, pred, lhs, rhs, "icmp");
    }

    return lhs;
}

i8* visit_assign(parser.expr_node* e, ir_context* ctx) {
    i8* lhs_ptr = visit_lvalue(e.lhs, ctx);
    i8* rhs_val = visit_expr(e.rhs, ctx);

    if (lhs_ptr == (i8*)0 || rhs_val == (i8*)0) { return rhs_val; }

    // Compound assignments: load lhs, apply op, store
    i32 op = e.bop;
    if (op != bop_assign) {
        i8* elem_type = lvalue_elem_type(e.lhs, ctx);
        if (elem_type == (i8*)0) {
            i8* lhs_type = LLVMTypeOf(lhs_ptr);
            if (LLVMGetTypeKind(lhs_type) == LLVMPointerTypeKind) {
                elem_type = LLVMGetElementType(lhs_type);
            }
            if (elem_type == (i8*)0) { elem_type = lhs_type; }
        }

        i8* cur = LLVMBuildLoad2(ctx.llvm_builder, elem_type, lhs_ptr, "load_for_op");
        rhs_val = coerce_int_val(rhs_val, elem_type, ctx.llvm_builder);

        i8* result = (i8*)0;
        bool is_f  = llvm_is_float(elem_type);
        if (op == bop_add_assign) {
            result = is_f ? LLVMBuildFAdd(ctx.llvm_builder, cur, rhs_val, "fadd_a")
                          : LLVMBuildAdd(ctx.llvm_builder, cur, rhs_val, "add_a");
        } else if (op == bop_sub_assign) {
            result = is_f ? LLVMBuildFSub(ctx.llvm_builder, cur, rhs_val, "fsub_a")
                          : LLVMBuildSub(ctx.llvm_builder, cur, rhs_val, "sub_a");
        } else if (op == bop_mul_assign) {
            result = is_f ? LLVMBuildFMul(ctx.llvm_builder, cur, rhs_val, "fmul_a")
                          : LLVMBuildMul(ctx.llvm_builder, cur, rhs_val, "mul_a");
        } else if (op == bop_div_assign) {
            result = is_f ? LLVMBuildFDiv(ctx.llvm_builder, cur, rhs_val, "fdiv_a")
                          : LLVMBuildSDiv(ctx.llvm_builder, cur, rhs_val, "sdiv_a");
        } else if (op == bop_mod_assign) {
            result = LLVMBuildSRem(ctx.llvm_builder, cur, rhs_val, "srem_a");
        } else if (op == bop_and_assign) {
            result = LLVMBuildAnd(ctx.llvm_builder, cur, rhs_val, "and_a");
        } else if (op == bop_or_assign) {
            result = LLVMBuildOr(ctx.llvm_builder, cur, rhs_val, "or_a");
        } else if (op == bop_xor_assign) {
            result = LLVMBuildXor(ctx.llvm_builder, cur, rhs_val, "xor_a");
        } else if (op == bop_shl_assign) {
            result = LLVMBuildShl(ctx.llvm_builder, cur, rhs_val, "shl_a");
        } else if (op == bop_shr_assign) {
            result = LLVMBuildLShr(ctx.llvm_builder, cur, rhs_val, "shr_a");
        } else {
            result = rhs_val;
        }
        if (result != (i8*)0) {
            LLVMBuildStore(ctx.llvm_builder, result, lhs_ptr);
            return result;
        }
    }

    // Simple store — use declared type from context, not LLVMGetElementType,
    // which is unreliable for opaque pointers in LLVM 15+.
    i8* elem_t = lvalue_elem_type(e.lhs, ctx);
    if (elem_t != (i8*)0) {
        rhs_val = coerce_int_val(rhs_val, elem_t, ctx.llvm_builder);
    }
    LLVMBuildStore(ctx.llvm_builder, rhs_val, lhs_ptr);
    return rhs_val;
}

i8* visit_call(parser.expr_node* e, ir_context* ctx) {
    if (e.callee == (parser.expr_node*)0) { return (i8*)0; }

    // Method call: obj.method(args)
    if (e.callee.kind == ek_member) {
        parser.expr_node* obj_expr = e.callee.object;
        i8* method_name = e.callee.member_name;

        // Build fully-qualified method name
        // First visit obj to determine its type
        i8* obj_ptr = visit_lvalue(obj_expr, ctx);
        if (obj_ptr == (i8*)0) {
            obj_ptr = visit_expr(obj_expr, ctx);
        }

        i8* struct_name = (i8*)0;
        if (obj_ptr != (i8*)0) {
            i8* pt = LLVMTypeOf(obj_ptr);
            i32 pk = LLVMGetTypeKind(pt);
            if (pk == LLVMPointerTypeKind) {
                i8* inner = LLVMGetElementType(pt);
                if (LLVMGetTypeKind(inner) == LLVMStructTypeKind) {
                    struct_name = LLVMGetStructName(inner);
                }
            }
        }

        if (struct_name != (i8*)0 && method_name != (i8*)0) {
            i8 mt_name[512];
            snprintf(mt_name, (u64)512, "%s__MT_%s", struct_name, method_name);
            i8* fn    = sv_map_get(&ctx.global_funcs,      mt_name);
            i8* fn_ty = st_map_get(&ctx.global_func_types, mt_name);

            if (fn != (i8*)0 && fn_ty != (i8*)0) {
                i32 nargs = e.args_len + 1;
                i8** args = (i8**)malloc(sizeof(i8*) * (u64)nargs);
                args[0]   = obj_ptr;
                i32 i = 0;
                while (i < e.args_len) {
                    args[i + 1] = visit_expr(e.args[i], ctx);
                    i = i + 1;
                }
                i8* result = LLVMBuildCall2(ctx.llvm_builder, fn_ty, fn, args, nargs, "");
                free((i8*)args);
                return result;
            }
        }

        // Fallback: just emit as regular expression
        if (obj_ptr != (i8*)0 && method_name != (i8*)0) {
            i8* loaded = (i8*)0;
            i8* pt = LLVMTypeOf(obj_ptr);
            i8* inner = (i8*)0;
            if (LLVMGetTypeKind(pt) == LLVMPointerTypeKind) {
                inner = LLVMGetElementType(pt);
                if (LLVMGetTypeKind(inner) == LLVMPointerTypeKind) {
                    loaded = LLVMBuildLoad2(ctx.llvm_builder, inner, obj_ptr, "fn_load");
                }
            }
        }
        return (i8*)0;
    }

    // Regular function call
    i8* fn = (i8*)0;
    i8* fn_ty = (i8*)0;
    i8* callee_name = (i8*)0;

    if (e.callee.kind == ek_identifier) {
        callee_name = e.callee.str_val;
        // Try overloaded variants (append __OL1, __OL2 etc.)
        fn    = find_func(callee_name, ctx);
        fn_ty = find_func_type(callee_name, ctx);

        if (fn == (i8*)0) {
            // Try as method in current class
            if (ctx.current_class_name != (i8*)0) {
                i8 mt_name[512];
                snprintf(mt_name, (u64)512, "%s__MT_%s", ctx.current_class_name, callee_name);
                fn    = sv_map_get(&ctx.global_funcs,      mt_name);
                fn_ty = st_map_get(&ctx.global_func_types, mt_name);
            }
        }
    } else {
        // Computed callee (function pointer)
        i8* fp = visit_expr(e.callee, ctx);
        if (fp == (i8*)0) { return (i8*)0; }
        i8* fp_type = LLVMTypeOf(fp);
        i32 fk = LLVMGetTypeKind(fp_type);
        if (fk != LLVMPointerTypeKind) { return (i8*)0; }
        fn_ty = LLVMGetElementType(fp_type);
        i32 nargs = e.args_len;
        i8** args = (i8**)0;
        if (nargs > 0) {
            args = (i8**)malloc(sizeof(i8*) * (u64)nargs);
            i32 i = 0;
            while (i < nargs) {
                args[i] = visit_expr(e.args[i], ctx);
                i = i + 1;
            }
        }
        i8* result = LLVMBuildCall2(ctx.llvm_builder, fn_ty, fp, args, nargs, "");
        if (args != (i8**)0) { free((i8*)args); }
        return result;
    }

    if (fn == (i8*)0 || fn_ty == (i8*)0) {
        // Unknown function — emit nothing (or emit an intrinsic call)
        return (i8*)0;
    }

    i32 nargs = e.args_len;
    i8** args = (i8**)0;
    if (nargs > 0) {
        args = (i8**)malloc(sizeof(i8*) * (u64)nargs);
        i32 i = 0;
        while (i < nargs) {
            args[i] = visit_expr(e.args[i], ctx);
            i = i + 1;
        }
        coerce_args_to_fn(fn_ty, args, nargs, ctx.llvm_builder);
    }
    i8* result = LLVMBuildCall2(ctx.llvm_builder, fn_ty, fn, args, nargs, "");
    if (args != (i8**)0) { free((i8*)args); }
    return result;
}

// Main expression visitor.
i8* visit_expr(parser.expr_node* e, ir_context* ctx) {
    if (e == (parser.expr_node*)0) { return (i8*)0; }

    i32 kind = e.kind;

    if (kind == ek_int_lit) {
        i8* i32t = LLVMInt64TypeInContext(ctx.llvm_ctx);
        return LLVMConstInt(i32t, (u64)e.int_val, 1);
    }

    if (kind == ek_float_lit) {
        i8* f64t = LLVMDoubleTypeInContext(ctx.llvm_ctx);
        return LLVMConstReal(f64t, e.flt_val);
    }

    if (kind == ek_string_lit) {
        if (e.str_val == (i8*)0) {
            return LLVMConstNull(LLVMPointerType(LLVMInt8TypeInContext(ctx.llvm_ctx), 0));
        }
        return LLVMBuildGlobalStringPtr(ctx.llvm_builder, e.str_val, "str");
    }

    if (kind == ek_char_lit) {
        i8* i8t = LLVMInt8TypeInContext(ctx.llvm_ctx);
        return LLVMConstInt(i8t, (u64)e.int_val, 0);
    }

    if (kind == ek_bool_lit) {
        i8* i1t = LLVMInt1TypeInContext(ctx.llvm_ctx);
        return LLVMConstInt(i1t, e.bool_val ? (u64)1 : (u64)0, 0);
    }

    if (kind == ek_null_lit) {
        i8* i8pt = LLVMPointerType(LLVMInt8TypeInContext(ctx.llvm_ctx), 0);
        return LLVMConstNull(i8pt);
    }

    if (kind == ek_identifier) {
        i8* alloca = ctx_lookup_local(ctx, e.str_val);
        if (alloca != (i8*)0) {
            i8* elem_t = ctx_lookup_local_type(ctx, e.str_val);
            if (elem_t == (i8*)0) {
                i8* at = LLVMTypeOf(alloca);
                if (LLVMGetTypeKind(at) == LLVMPointerTypeKind) {
                    elem_t = LLVMGetElementType(at);
                }
            }
            if (elem_t != (i8*)0) {
                // Array decay: return ptr to first element rather than loading the whole array.
                if (LLVMGetTypeKind(elem_t) == LLVMArrayTypeKind) {
                    i8* zero = LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), 0, 0);
                    i8* idxs[2];
                    idxs[0] = zero;
                    idxs[1] = zero;
                    return LLVMBuildGEP2(ctx.llvm_builder, elem_t, alloca, idxs, 2, "arr_decay");
                }
                return LLVMBuildLoad2(ctx.llvm_builder, elem_t, alloca, e.str_val);
            }
            return alloca;
        }
        // Global variable
        i8* gv = sv_map_get(&ctx.global_vars, e.str_val);
        if (gv != (i8*)0) {
            i8* elem_t = LLVMGlobalGetValueType(gv);
            if (elem_t != (i8*)0) {
                if (LLVMGetTypeKind(elem_t) == LLVMFunctionTypeKind) { return gv; }
                return LLVMBuildLoad2(ctx.llvm_builder, elem_t, gv, e.str_val);
            }
            return gv;
        }
        // Global function reference
        i8* fn = sv_map_get(&ctx.global_funcs, e.str_val);
        if (fn != (i8*)0) { return fn; }
        // Could be an enum constant
        i8* ec = sv_map_get(&ctx.global_vars, e.str_val);
        if (ec != (i8*)0) { return ec; }
        return (i8*)0;
    }

    if (kind == ek_unary) {
        if (e.uop == uop_addr_of) {
            return visit_lvalue(e.operand, ctx);
        }
        i8* val = visit_expr(e.operand, ctx);
        if (val == (i8*)0) { return (i8*)0; }
        i8* vt = LLVMTypeOf(val);

        if (e.uop == uop_neg) {
            if (llvm_is_float(vt)) { return LLVMBuildFNeg(ctx.llvm_builder, val, "fneg"); }
            return LLVMBuildNeg(ctx.llvm_builder, val, "neg");
        }
        if (e.uop == uop_log_not) {
            i8* b = to_bool(val, ctx.llvm_builder, ctx.llvm_ctx);
            i8* i1t = LLVMInt1TypeInContext(ctx.llvm_ctx);
            i8* one = LLVMConstInt(i1t, 1, 0);
            return LLVMBuildXor(ctx.llvm_builder, b, one, "not");
        }
        if (e.uop == uop_bit_not) {
            return LLVMBuildNot(ctx.llvm_builder, val, "bitnot");
        }
        if (e.uop == uop_deref) {
            i32 vkind = LLVMGetTypeKind(vt);
            if (vkind == LLVMPointerTypeKind) {
                // Use context lookup to find pointee type; LLVMGetElementType is broken for opaque ptrs.
                i8* elem = (i8*)0;
                if (e.operand != (parser.expr_node*)0) {
                    if (e.operand.kind == ek_identifier) {
                        elem = ctx_lookup_deref_type(ctx, e.operand.str_val);
                    } else if (e.operand.kind == ek_member && e.operand.member_name != (i8*)0) {
                        i8* parent_st = infer_expr_struct_type(e.operand.object, ctx);
                        if (parent_st != (i8*)0) {
                            i8* pname = LLVMGetStructName(parent_st);
                            if (pname != (i8*)0) {
                                i32 fidx = ctx_field_index(ctx, pname, e.operand.member_name);
                                if (fidx >= 0) {
                                    struct_meta* sm = struct_meta_find(&ctx.struct_meta_tbl, pname);
                                    if (sm != (struct_meta*)0 && fidx < sm.field_pointee.len) {
                                        elem = sm.field_pointee.data[fidx];
                                    }
                                }
                            }
                        }
                    }
                }
                if (elem == (i8*)0) { elem = LLVMInt8TypeInContext(ctx.llvm_ctx); }
                return LLVMBuildLoad2(ctx.llvm_builder, elem, val, "deref");
            }
            return val;
        }
        if (e.uop == uop_pre_inc || e.uop == uop_pre_dec) {
            i8* ptr = visit_lvalue(e.operand, ctx);
            if (ptr == (i8*)0) { return val; }
            i8* et = val != (i8*)0 ? LLVMTypeOf(val) : lvalue_elem_type(e.operand, ctx);
            if (et == (i8*)0) { return val; }
            i8* cur = LLVMBuildLoad2(ctx.llvm_builder, et, ptr, "inc_load");
            i8* one = LLVMConstInt(et, 1, 0);
            i8* new_val = (i8*)0;
            if (e.uop == uop_pre_inc) {
                new_val = LLVMBuildAdd(ctx.llvm_builder, cur, one, "inc");
            } else {
                new_val = LLVMBuildSub(ctx.llvm_builder, cur, one, "dec");
            }
            LLVMBuildStore(ctx.llvm_builder, new_val, ptr);
            return new_val;
        }
        if (e.uop == uop_post_inc || e.uop == uop_post_dec) {
            i8* ptr = visit_lvalue(e.operand, ctx);
            if (ptr == (i8*)0) { return val; }
            i8* et = val != (i8*)0 ? LLVMTypeOf(val) : lvalue_elem_type(e.operand, ctx);
            if (et == (i8*)0) { return val; }
            i8* cur = LLVMBuildLoad2(ctx.llvm_builder, et, ptr, "post_load");
            i8* one = LLVMConstInt(et, 1, 0);
            i8* new_val = (i8*)0;
            if (e.uop == uop_post_inc) {
                new_val = LLVMBuildAdd(ctx.llvm_builder, cur, one, "post_inc");
            } else {
                new_val = LLVMBuildSub(ctx.llvm_builder, cur, one, "post_dec");
            }
            LLVMBuildStore(ctx.llvm_builder, new_val, ptr);
            return cur;
        }
        return val;
    }

    if (kind == ek_binary) { return visit_binary(e, ctx); }
    if (kind == ek_assign) { return visit_assign(e, ctx); }
    if (kind == ek_call)   { return visit_call(e, ctx); }

    if (kind == ek_subscript) {
        i8* ptr = visit_lvalue(e, ctx);
        if (ptr != (i8*)0) {
            // Use context-derived element type; LLVMGetElementType(ptr) is broken in opaque mode.
            i8* et = lvalue_elem_type(e, ctx);
            if (et != (i8*)0) {
                return LLVMBuildLoad2(ctx.llvm_builder, et, ptr, "idx_load");
            }
        }
        return (i8*)0;
    }

    if (kind == ek_member) {
        i8* ptr = visit_lvalue(e, ctx);
        if (ptr == (i8*)0 || e.member_name == (i8*)0) { return (i8*)0; }
        // Resolve struct type and field type via context (opaque-pointer safe).
        i8* struct_type = (i8*)0;
        resolve_struct_base(e.object, ctx, &struct_type);
        if (struct_type == (i8*)0) { return (i8*)0; }
        i8* sname = LLVMGetStructName(struct_type);
        if (sname == (i8*)0) { return (i8*)0; }
        i32 fidx = ctx_field_index(ctx, sname, e.member_name);
        if (fidx < 0 && ctx.current_namespace != (i8*)0) {
            i8 ns_sname[512];
            snprintf(ns_sname, (u64)512, "%s__NS_%s", ctx.current_namespace, sname);
            fidx = ctx_field_index(ctx, ns_sname, e.member_name);
            if (fidx >= 0) { sname = lexer.str_dup(ns_sname); }
        }
        if (fidx < 0) { return (i8*)0; }
        i8* ft = ctx_field_type(ctx, sname, fidx);
        if (ft == (i8*)0) { return (i8*)0; }
        return LLVMBuildLoad2(ctx.llvm_builder, ft, ptr, "mem_load");
    }

    if (kind == ek_cast) {
        i8* val = visit_expr(e.operand, ctx);
        if (val == (i8*)0 || e.cast_type == (parser.type_node*)0) { return val; }
        i8* target_t = llvm_type_of(e.cast_type, ctx);
        if (target_t == (i8*)0) { return val; }
        i8* val_t = LLVMTypeOf(val);
        i32 vkind = LLVMGetTypeKind(val_t);
        i32 tkind = LLVMGetTypeKind(target_t);

        if (vkind == LLVMIntegerTypeKind && tkind == LLVMIntegerTypeKind) {
            i32 vw = LLVMGetIntTypeWidth(val_t);
            i32 tw = LLVMGetIntTypeWidth(target_t);
            if (vw == tw) { return val; }
            if (vw < tw) {
                bool uns = is_unsigned_type_node(e.cast_type);
                if (uns) { return LLVMBuildZExt(ctx.llvm_builder, val, target_t, "zext"); }
                return LLVMBuildSExt(ctx.llvm_builder, val, target_t, "sext");
            }
            return LLVMBuildTrunc(ctx.llvm_builder, val, target_t, "trunc");
        }
        if (vkind == LLVMIntegerTypeKind && tkind == LLVMPointerTypeKind) {
            return LLVMBuildIntToPtr(ctx.llvm_builder, val, target_t, "i2p");
        }
        if (vkind == LLVMPointerTypeKind && tkind == LLVMIntegerTypeKind) {
            return LLVMBuildPtrToInt(ctx.llvm_builder, val, target_t, "p2i");
        }
        if (vkind == LLVMPointerTypeKind && tkind == LLVMPointerTypeKind) {
            return LLVMBuildPointerCast(ctx.llvm_builder, val, target_t, "pcast");
        }
        if (vkind == LLVMIntegerTypeKind && llvm_is_float(target_t)) {
            bool uns = is_unsigned_type_node(e.cast_type);
            if (uns) { return LLVMBuildUIToFP(ctx.llvm_builder, val, target_t, "uitofp"); }
            return LLVMBuildSIToFP(ctx.llvm_builder, val, target_t, "sitofp");
        }
        if (llvm_is_float(val_t) && tkind == LLVMIntegerTypeKind) {
            bool uns = is_unsigned_type_node(e.cast_type);
            if (uns) { return LLVMBuildFPToUI(ctx.llvm_builder, val, target_t, "fptou"); }
            return LLVMBuildFPToSI(ctx.llvm_builder, val, target_t, "fptosi");
        }
        if (llvm_is_float(val_t) && llvm_is_float(target_t)) {
            return LLVMBuildFPCast(ctx.llvm_builder, val, target_t, "fpcast");
        }
        return val;
    }

    if (kind == ek_sizeof_e) {
        i8* sz_t = (i8*)0;
        if (e.cast_type != (parser.type_node*)0) {
            sz_t = llvm_type_of(e.cast_type, ctx);
        } else if (e.operand != (parser.expr_node*)0) {
            // sizeof(TypeName) is parsed as identifier operand when the parser can't
            // distinguish it from an expression (no variable declaration follows).
            // The C++ analysis pass rewrites this; we handle it here instead.
            if (e.operand.kind == ek_identifier && e.operand.str_val != (i8*)0) {
                // Check struct types first
                i8* struct_t = st_map_get(&ctx.struct_types, e.operand.str_val);
                if (struct_t != (i8*)0) { sz_t = struct_t; }
                // Check typedef aliases
                if (sz_t == (i8*)0) {
                    i8* alias_tn = typedef_map_get(&ctx.typedef_aliases, e.operand.str_val);
                    if (alias_tn != (i8*)0) {
                        sz_t = llvm_type_of((parser.type_node*)alias_tn, ctx);
                    }
                }
            }
            if (sz_t == (i8*)0) {
                i8* v = visit_expr(e.operand, ctx);
                if (v != (i8*)0) { sz_t = LLVMTypeOf(v); }
            }
        }
        if (sz_t == (i8*)0) {
            i8* i64t = LLVMInt64TypeInContext(ctx.llvm_ctx);
            return LLVMConstInt(i64t, 1, 0);
        }
        return LLVMSizeOf(sz_t);
    }

    if (kind == ek_ternary) {
        i8* cond_val = visit_expr(e.cond, ctx);
        if (cond_val == (i8*)0) { return (i8*)0; }
        i8* cond_b = to_bool(cond_val, ctx.llvm_builder, ctx.llvm_ctx);

        i8* fn       = ctx.current_func;
        i8* then_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "tern_then");
        i8* else_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "tern_else");
        i8* merge_bb = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "tern_merge");

        LLVMBuildCondBr(ctx.llvm_builder, cond_b, then_bb, else_bb);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, then_bb);
        i8* then_val = visit_expr(e.then_e, ctx);
        i8* then_end = LLVMGetInsertBlock(ctx.llvm_builder);
        LLVMBuildBr(ctx.llvm_builder, merge_bb);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, else_bb);
        i8* else_val = visit_expr(e.else_e, ctx);
        i8* else_end = LLVMGetInsertBlock(ctx.llvm_builder);
        LLVMBuildBr(ctx.llvm_builder, merge_bb);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb);
        if (then_val == (i8*)0 || else_val == (i8*)0) { return then_val; }

        i8* phi_t = LLVMTypeOf(then_val);
        i8* phi   = LLVMBuildPhi(ctx.llvm_builder, phi_t, "tern");
        i8* incoming_vals[2];
        i8* incoming_blocks[2];
        incoming_vals[0]   = then_val;
        incoming_vals[1]   = else_val;
        incoming_blocks[0] = then_end;
        incoming_blocks[1] = else_end;
        LLVMAddIncoming(phi, incoming_vals, incoming_blocks, 2);
        return phi;
    }

    if (kind == ek_class_init) {
        // Struct literal: allocate on stack, set fields, return ptr
        if (e.init_type == (parser.type_node*)0) { return (i8*)0; }
        i8* struct_t = llvm_type_of(e.init_type, ctx);
        if (struct_t == (i8*)0) { return (i8*)0; }

        i8* alloca = LLVMBuildAlloca(ctx.llvm_builder, struct_t, "struct_init");
        LLVMBuildStore(ctx.llvm_builder, LLVMConstNull(struct_t), alloca);

        i8* sname = LLVMGetStructName(struct_t);
        i32 i = 0;
        while (i < e.field_count) {
            i8* fname = e.field_names[i];
            i8* fval  = visit_expr(e.field_vals[i], ctx);
            if (sname != (i8*)0 && fname != (i8*)0 && fval != (i8*)0) {
                i32 fidx = ctx_field_index(ctx, sname, fname);
                if (fidx >= 0) {
                    i8* fptr = LLVMBuildStructGEP2(ctx.llvm_builder, struct_t, alloca, fidx, fname);
                    i8* ftype = LLVMTypeOf(fptr);
                    i8* elem_t = LLVMGetElementType(ftype);
                    fval = coerce_int_val(fval, elem_t, ctx.llvm_builder);
                    LLVMBuildStore(ctx.llvm_builder, fval, fptr);
                }
            }
            i = i + 1;
        }
        return LLVMBuildLoad2(ctx.llvm_builder, struct_t, alloca, "struct_val");
    }

    // Annotations: compile-time only, emit nothing
    if (kind == ek_annotation) { return (i8*)0; }

    return (i8*)0;
}

} // namespace ir
