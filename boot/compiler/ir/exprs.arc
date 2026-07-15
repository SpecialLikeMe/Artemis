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

    // arr[i].field — array-of-struct subscript (local array or pointer-to-struct)
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
            // Pointer-to-struct parameter: deref_t holds the element struct type.
            i8* deref_t = ctx_lookup_deref_type(ctx, obj.object.str_val);
            if (deref_t != (i8*)0 && LLVMGetTypeKind(deref_t) == LLVMStructTypeKind) {
                *out_struct_type = deref_t;
                return elem_ptr;
            }
            // Global pointer-to-struct
            i8* gv = sv_map_get(&ctx.global_vars, obj.object.str_val);
            if (gv != (i8*)0) {
                i8* gv_t = LLVMGlobalGetValueType(gv);
                if (gv_t != (i8*)0 && LLVMGetTypeKind(gv_t) == LLVMArrayTypeKind) {
                    i8* elem_t = LLVMGetElementType(gv_t);
                    if (elem_t != (i8*)0 && LLVMGetTypeKind(elem_t) == LLVMStructTypeKind) {
                        *out_struct_type = elem_t;
                        return elem_ptr;
                    }
                }
            }
        }
        // Member access subscript: self.field[i] where field is T* pointer to struct
        if (obj.object.kind == ek_member && obj.object.member_name != (i8*)0) {
            i8* parent_st2 = infer_expr_struct_type(obj.object.object, ctx);
            if (parent_st2 != (i8*)0) {
                i8* pname2 = LLVMGetStructName(parent_st2);
                if (pname2 != (i8*)0) {
                    i32 fidx3 = ctx_field_index(ctx, pname2, obj.object.member_name);
                    if (fidx3 >= 0) {
                        struct_meta* sm3 = struct_meta_find(&ctx.struct_meta_tbl, pname2);
                        if (sm3 != (struct_meta*)0 && fidx3 < sm3.field_pointee.len) {
                            i8* pt3 = sm3.field_pointee.data[fidx3];
                            if (pt3 != (i8*)0 && LLVMGetTypeKind(pt3) == LLVMStructTypeKind) {
                                *out_struct_type = pt3;
                                return elem_ptr;
                            }
                        }
                    }
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
        // Member access subscript: self.field[i] where field is T* pointing to struct
        if (e.object.kind == ek_member && e.object.member_name != (i8*)0) {
            i8* parent_st = infer_expr_struct_type(e.object.object, ctx);
            if (parent_st != (i8*)0) {
                i8* pname = LLVMGetStructName(parent_st);
                if (pname != (i8*)0) {
                    i32 fidx2 = ctx_field_index(ctx, pname, e.object.member_name);
                    if (fidx2 >= 0) {
                        struct_meta* sm2 = struct_meta_find(&ctx.struct_meta_tbl, pname);
                        if (sm2 != (struct_meta*)0 && fidx2 < sm2.field_pointee.len) {
                            i8* pt2 = sm2.field_pointee.data[fidx2];
                            if (pt2 != (i8*)0 && LLVMGetTypeKind(pt2) == LLVMStructTypeKind) { return pt2; }
                        }
                    }
                }
            }
        }
        return (i8*)0;
    }
    return (i8*)0;
}

// Helper: get the field type at index fidx from an ADT tuple variant
i8* adt_tuple_field_type(parser.enum_decl* adt_ed, i32 fidx, ir_context* ctx) {
    if (adt_ed == (parser.enum_decl*)0) { return (i8*)0; }
    i32 tvi = 0;
    while (tvi < adt_ed.variants_len) {
        if (adt_ed.variant_kinds != (i32*)0 && adt_ed.variant_kinds[tvi] == 1) {
            i32 fc = (adt_ed.variant_field_counts != (i32*)0) ? adt_ed.variant_field_counts[tvi] : 0;
            if (fidx >= 0 && fidx < fc && adt_ed.variant_field_type_flat != (i8**)0) {
                parser.type_node* ft = (parser.type_node*)adt_ed.variant_field_type_flat[tvi * 8 + fidx];
                if (ft != (parser.type_node*)0) { return llvm_type_of(ft, ctx); }
            }
            return LLVMInt32TypeInContext(ctx.llvm_ctx);
        }
        tvi = tvi + 1;
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
        // ADT tuple payload subscript: (*x)[i]
        if (e.object.kind == ek_unary && e.object.uop == uop_deref &&
                e.object.operand != (parser.expr_node*)0 &&
                e.object.operand.kind == ek_identifier && e.index != (parser.expr_node*)0 &&
                e.index.kind == ek_int_lit) {
            i8* local_t = ctx_lookup_local_type(ctx, e.object.operand.str_val);
            if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMStructTypeKind) {
                i8* sname = LLVMGetStructName(local_t);
                if (sname != (i8*)0) {
                    i8* adt_ed_ptr = sv_map_get(&ctx.adt_enum_decls, sname);
                    if (adt_ed_ptr != (i8*)0) {
                        i32 fidx = (i32)e.index.int_val;
                        i8* ft = adt_tuple_field_type((parser.enum_decl*)adt_ed_ptr, fidx, ctx);
                        if (ft != (i8*)0) { return ft; }
                    }
                }
            }
        }
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
        } else {
            // For non-identifier objects (e.g., struct member arrays or pointer subscripts),
            // use the field/deref type of the object expression.
            i8* field_t = lvalue_elem_type(e.object, ctx);
            if (field_t != (i8*)0 && LLVMGetTypeKind(field_t) == LLVMArrayTypeKind) {
                return LLVMGetElementType(field_t);
            }
            // field_t is a pointer (opaque ptr): resolve the pointee element type
            if (field_t != (i8*)0 && LLVMGetTypeKind(field_t) == LLVMPointerTypeKind) {
                if (e.object.kind == ek_member && e.object.member_name != (i8*)0) {
                    i8* parent_st = infer_expr_struct_type(e.object.object, ctx);
                    if (parent_st != (i8*)0) {
                        i8* pname = LLVMGetStructName(parent_st);
                        if (pname != (i8*)0) {
                            i32 fidx = ctx_field_index(ctx, pname, e.object.member_name);
                            if (fidx >= 0) {
                                struct_meta* sm = struct_meta_find(&ctx.struct_meta_tbl, pname);
                                if (sm != (struct_meta*)0 && fidx < sm.field_pointee.len) {
                                    i8* pt = sm.field_pointee.data[fidx];
                                    if (pt != (i8*)0) { return pt; }
                                }
                            }
                        }
                    }
                }
                return LLVMInt8TypeInContext(ctx.llvm_ctx);
            }
            if (field_t != (i8*)0) {
                return field_t;
            }
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

// Look up a named function, trying namespace qualification and parent namespaces.
i8* find_func(i8* name, ir_context* ctx) {
    i8* fn = sv_map_get(&ctx.global_funcs, name);
    if (fn != (i8*)0) { return fn; }

    if (ctx.current_namespace != (i8*)0) {
        i8 ns_work[512];
        snprintf(ns_work, (u64)512, "%s", ctx.current_namespace);
        i32 ns_len = (i32)strlen(ns_work);
        while (ns_len > 0) {
            i8 ns_name[512];
            snprintf(ns_name, (u64)512, "%s__NS_%s", ns_work, name);
            fn = sv_map_get(&ctx.global_funcs, ns_name);
            if (fn != (i8*)0) { return fn; }
            // Strip last __NS_ component to walk up to parent namespace
            i32 split = -1;
            i32 ki = ns_len - 1;
            while (ki >= 4) {
                if (ns_work[ki-4]=='_' && ns_work[ki-3]=='_' && ns_work[ki-2]=='N' && ns_work[ki-1]=='S' && ns_work[ki]=='_') {
                    split = ki - 4;
                    break;
                }
                ki = ki - 1;
            }
            if (split < 0) { break; }
            ns_work[split] = 0;
            ns_len = split;
        }
    }
    return (i8*)0;
}

i8* find_func_type(i8* name, ir_context* ctx) {
    i8* ft = st_map_get(&ctx.global_func_types, name);
    if (ft != (i8*)0) { return ft; }

    if (ctx.current_namespace != (i8*)0) {
        i8 ns_work2[512];
        snprintf(ns_work2, (u64)512, "%s", ctx.current_namespace);
        i32 ns_len2 = (i32)strlen(ns_work2);
        while (ns_len2 > 0) {
            i8 ns_name2[512];
            snprintf(ns_name2, (u64)512, "%s__NS_%s", ns_work2, name);
            ft = st_map_get(&ctx.global_func_types, ns_name2);
            if (ft != (i8*)0) { return ft; }
            i32 split2 = -1;
            i32 ki2 = ns_len2 - 1;
            while (ki2 >= 4) {
                if (ns_work2[ki2-4]=='_' && ns_work2[ki2-3]=='_' && ns_work2[ki2-2]=='N' && ns_work2[ki2-1]=='S' && ns_work2[ki2]=='_') {
                    split2 = ki2 - 4;
                    break;
                }
                ki2 = ki2 - 1;
            }
            if (split2 < 0) { break; }
            ns_work2[split2] = 0;
            ns_len2 = split2;
        }
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
        if (gv != (i8*)0) { return gv; }
        // Global function (e.g. &funcname used as a function pointer)
        i8* gfn = sv_map_get(&ctx.global_funcs, e.str_val);
        return gfn;
    }

    if (e.kind == ek_unary && e.uop == uop_deref) {
        // *ptr -> the pointer value itself is the address
        return visit_expr(e.operand, ctx);
    }

    if (e.kind == ek_subscript) {
        // ADT tuple payload access: (*x)[i] where x is an ADT enum local
        if (e.object != (parser.expr_node*)0 && e.object.kind == ek_unary && e.object.uop == uop_deref) {
            parser.expr_node* inner = e.object.operand;
            if (inner != (parser.expr_node*)0 && inner.kind == ek_identifier && inner.str_val != (i8*)0) {
                i8* local_t = ctx_lookup_local_type(ctx, inner.str_val);
                if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMStructTypeKind) {
                    i8* sname = LLVMGetStructName(local_t);
                    if (sname != (i8*)0) {
                        i8* adt_ed_ptr = sv_map_get(&ctx.adt_enum_decls, sname);
                        if (adt_ed_ptr != (i8*)0) {
                            parser.enum_decl* adt_ed = (parser.enum_decl*)adt_ed_ptr;
                            // Find first tuple variant (vkind == 1) to get field types
                            i32 tvi = 0; i32 found_vi = -1;
                            while (tvi < adt_ed.variants_len && found_vi < 0) {
                                if (adt_ed.variant_kinds != (i32*)0 && adt_ed.variant_kinds[tvi] == 1) { found_vi = tvi; }
                                tvi = tvi + 1;
                            }
                            if (found_vi >= 0 && adt_ed.variant_field_type_flat != (i8**)0) {
                                i32 fc = (adt_ed.variant_field_counts != (i32*)0) ? adt_ed.variant_field_counts[found_vi] : 0;
                                i8* alloca = ctx_lookup_local(ctx, inner.str_val);
                                if (alloca != (i8*)0 && e.index != (parser.expr_node*)0 && e.index.kind == ek_int_lit) {
                                    i32 fidx = (i32)e.index.int_val;
                                    // Compute byte offset for field fidx
                                    u64 byte_off = 0;
                                    i32 fi = 0;
                                    i8* i32t = LLVMInt32TypeInContext(ctx.llvm_ctx);
                                    while (fi < fidx && fi < fc) {
                                        parser.type_node* ft = (parser.type_node*)adt_ed.variant_field_type_flat[found_vi * 8 + fi];
                                        i8* flt = (ft != (parser.type_node*)0) ? llvm_type_of(ft, ctx) : i32t;
                                        u64 fsz = llvm_type_byte_size(flt);
                                        byte_off = byte_off + ((fsz + 7) & ~(u64)7);
                                        fi = fi + 1;
                                    }
                                    // GEP into payload (field 1 of ADT struct)
                                    i8* pay_gep = LLVMBuildStructGEP2(ctx.llvm_builder, local_t, alloca, 1, "adt_pay");
                                    i8* i8t = LLVMInt8TypeInContext(ctx.llvm_ctx);
                                    i8* off_v = LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), byte_off, 0);
                                    return LLVMBuildGEP2(ctx.llvm_builder, i8t, pay_gep, &off_v, 1, "adt_fld");
                                }
                            }
                        }
                    }
                }
            }
        }

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
            // For non-identifier objects (e.g., struct member arrays), use lvalue_elem_type.
            if (inner == (i8*)0 && e.object.kind != ek_identifier) {
                i8* field_t = lvalue_elem_type(e.object, ctx);
                if (field_t != (i8*)0 && LLVMGetTypeKind(field_t) == LLVMArrayTypeKind) {
                    inner = field_t;
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
            if (deref_t == (i8*)0 && e.object.kind == ek_member && e.object.member_name != (i8*)0) {
                i8* parent_st_c = infer_expr_struct_type(e.object.object, ctx);
                if (parent_st_c != (i8*)0) {
                    i8* pname_c = LLVMGetStructName(parent_st_c);
                    if (pname_c != (i8*)0) {
                        i32 fidx_c = ctx_field_index(ctx, pname_c, e.object.member_name);
                        if (fidx_c >= 0) {
                            struct_meta* sm_c = struct_meta_find(&ctx.struct_meta_tbl, pname_c);
                            if (sm_c != (struct_meta*)0 && fidx_c < sm_c.field_pointee.len) {
                                deref_t = sm_c.field_pointee.data[fidx_c];
                            }
                        }
                    }
                }
            }
            if (deref_t == (i8*)0) { deref_t = LLVMInt8TypeInContext(ctx.llvm_ctx); }
            return LLVMBuildGEP2(ctx.llvm_builder, deref_t, ptr_val, &idx, 1, "ptr_gep");
        }
        return (i8*)0;
    }

    if (e.kind == ek_member) {
        if (e.member_name == (i8*)0) { return (i8*)0; }

        // ADT named field access: (*x).field where x is an ADT enum local
        if (e.object != (parser.expr_node*)0 && e.object.kind == ek_unary && e.object.uop == uop_deref &&
                e.object.operand != (parser.expr_node*)0 && e.object.operand.kind == ek_identifier) {
            i8* local_t = ctx_lookup_local_type(ctx, e.object.operand.str_val);
            if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMStructTypeKind) {
                i8* sname_adt = LLVMGetStructName(local_t);
                if (sname_adt != (i8*)0) {
                    i8* adt_ed_ptr = sv_map_get(&ctx.adt_enum_decls, sname_adt);
                    if (adt_ed_ptr != (i8*)0) {
                        parser.enum_decl* adt_ed = (parser.enum_decl*)adt_ed_ptr;
                        i8* alloca = ctx_lookup_local(ctx, e.object.operand.str_val);
                        if (alloca != (i8*)0) {
                            // Search all named/istruc variants for this field
                            i32 vi = 0;
                            while (vi < adt_ed.variants_len) {
                                i32 vkind = (adt_ed.variant_kinds != (i32*)0) ? adt_ed.variant_kinds[vi] : 0;
                                i32 fc = (adt_ed.variant_field_counts != (i32*)0) ? adt_ed.variant_field_counts[vi] : 0;
                                if ((vkind == 2 || vkind == 3) && fc > 0 &&
                                        adt_ed.variant_field_names_flat != (i8**)0) {
                                    u64 byte_off = 0;
                                    i32 fi = 0;
                                    i8* i32t = LLVMInt32TypeInContext(ctx.llvm_ctx);
                                    while (fi < fc) {
                                        i8* vfname = adt_ed.variant_field_names_flat[vi * 8 + fi];
                                        if (vfname != (i8*)0 && strcmp(vfname, e.member_name) == 0) {
                                            // Found field — GEP into payload
                                            i8* pay_gep = LLVMBuildStructGEP2(ctx.llvm_builder, local_t, alloca, 1, "adt_pay");
                                            i8* i8t = LLVMInt8TypeInContext(ctx.llvm_ctx);
                                            i8* off_v = LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), byte_off, 0);
                                            return LLVMBuildGEP2(ctx.llvm_builder, i8t, pay_gep, &off_v, 1, "adt_fld");
                                        }
                                        parser.type_node* ft = (adt_ed.variant_field_type_flat != (i8**)0)
                                            ? (parser.type_node*)adt_ed.variant_field_type_flat[vi * 8 + fi] : (parser.type_node*)0;
                                        i8* flt = (ft != (parser.type_node*)0) ? llvm_type_of(ft, ctx) : i32t;
                                        u64 fsz = llvm_type_byte_size(flt);
                                        byte_off = byte_off + ((fsz + 7) & ~(u64)7);
                                        fi = fi + 1;
                                    }
                                }
                                vi = vi + 1;
                            }
                        }
                    }
                }
            }
        }

        // ADT named field: x.field where x is a pointer-to-ADT-enum local (auto-deref)
        if (e.object != (parser.expr_node*)0 && e.object.kind == ek_identifier) {
            i8* deref_t2 = ctx_lookup_deref_type(ctx, e.object.str_val);
            if (deref_t2 != (i8*)0 && LLVMGetTypeKind(deref_t2) == LLVMStructTypeKind) {
                i8* sname_adt2 = LLVMGetStructName(deref_t2);
                if (sname_adt2 != (i8*)0) {
                    i8* adt_ed_ptr2 = sv_map_get(&ctx.adt_enum_decls, sname_adt2);
                    if (adt_ed_ptr2 != (i8*)0) {
                        parser.enum_decl* adt_ed2 = (parser.enum_decl*)adt_ed_ptr2;
                        i8* self_alloca = ctx_lookup_local(ctx, e.object.str_val);
                        i8* ptr_t = ctx_lookup_local_type(ctx, e.object.str_val);
                        if (self_alloca != (i8*)0 && ptr_t != (i8*)0) {
                            i8* self_ptr = LLVMBuildLoad2(ctx.llvm_builder, ptr_t, self_alloca, "self_ptr");
                            i32 vi2 = 0;
                            while (vi2 < adt_ed2.variants_len) {
                                i32 vkind2 = (adt_ed2.variant_kinds != (i32*)0) ? adt_ed2.variant_kinds[vi2] : 0;
                                i32 fc2 = (adt_ed2.variant_field_counts != (i32*)0) ? adt_ed2.variant_field_counts[vi2] : 0;
                                if ((vkind2 == 2 || vkind2 == 3) && fc2 > 0 && adt_ed2.variant_field_names_flat != (i8**)0) {
                                    u64 byte_off2 = 0;
                                    i32 fi2 = 0;
                                    i8* i32t2 = LLVMInt32TypeInContext(ctx.llvm_ctx);
                                    while (fi2 < fc2) {
                                        i8* vfname2 = adt_ed2.variant_field_names_flat[vi2 * 8 + fi2];
                                        if (vfname2 != (i8*)0 && strcmp(vfname2, e.member_name) == 0) {
                                            i8* pay_gep2 = LLVMBuildStructGEP2(ctx.llvm_builder, deref_t2, self_ptr, 1, "adt_pay");
                                            i8* i8t2 = LLVMInt8TypeInContext(ctx.llvm_ctx);
                                            i8* off_v2 = LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), byte_off2, 0);
                                            return LLVMBuildGEP2(ctx.llvm_builder, i8t2, pay_gep2, &off_v2, 1, "adt_fld");
                                        }
                                        parser.type_node* ft2 = (adt_ed2.variant_field_type_flat != (i8**)0)
                                            ? (parser.type_node*)adt_ed2.variant_field_type_flat[vi2 * 8 + fi2] : (parser.type_node*)0;
                                        i8* flt2 = (ft2 != (parser.type_node*)0) ? llvm_type_of(ft2, ctx) : i32t2;
                                        u64 fsz2 = llvm_type_byte_size(flt2);
                                        byte_off2 = byte_off2 + ((fsz2 + 7) & ~(u64)7);
                                        fi2 = fi2 + 1;
                                    }
                                }
                                vi2 = vi2 + 1;
                            }
                        }
                    }
                }
            }
        }

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

        // Union fields: cast base pointer to field type pointer instead of struct GEP.
        if (ctx_is_union(ctx, sname)) {
            i8* ft = ctx_field_type(ctx, sname, field_idx);
            if (ft == (i8*)0) { return (i8*)0; }
            // obj_ptr already points to the union's storage; just return it reinterpreted.
            return obj_ptr;
        }

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
    // Operator overload dispatch for struct types
    if (e.lhs != (parser.expr_node*)0) {
        i8* st = infer_expr_struct_type(e.lhs, ctx);
        if (st != (i8*)0) {
            i8* sname = LLVMGetStructName(st);
            if (sname != (i8*)0) {
                i8* op_str = (i8*)0;
                i32 bop = e.bop;
                if (bop == bop_add) { op_str = "operator+"; }
                else if (bop == bop_sub)  { op_str = "operator-"; }
                else if (bop == bop_mul)  { op_str = "operator*"; }
                else if (bop == bop_div)  { op_str = "operator/"; }
                else if (bop == bop_mod)  { op_str = "operator%"; }
                else if (bop == bop_eq)   { op_str = "operator=="; }
                else if (bop == bop_ne)   { op_str = "operator!="; }
                else if (bop == bop_lt)   { op_str = "operator<"; }
                else if (bop == bop_gt)   { op_str = "operator>"; }
                else if (bop == bop_lte)  { op_str = "operator<="; }
                else if (bop == bop_gte)  { op_str = "operator>="; }
                if (op_str != (i8*)0) {
                    i8 op_fn_name[512];
                    snprintf(op_fn_name, (u64)512, "%s__NS_%s", sname, op_str);
                    i8* fn    = sv_map_get(&ctx.global_funcs,      op_fn_name);
                    i8* fn_ty = st_map_get(&ctx.global_func_types, op_fn_name);
                    if (fn != (i8*)0 && fn_ty != (i8*)0) {
                        i8* lhs_ptr = visit_lvalue(e.lhs, ctx);
                        i8* rhs_val = visit_expr(e.rhs, ctx);
                        if (lhs_ptr == (i8*)0) { lhs_ptr = visit_expr(e.lhs, ctx); }
                        if (lhs_ptr != (i8*)0 && rhs_val != (i8*)0) {
                            u32 nparams = LLVMCountParamTypes(fn_ty);
                            i8* cargs[2];
                            cargs[0] = lhs_ptr;
                            i8** param_ts = (i8**)malloc(sizeof(i8*) * (u64)(nparams + 1));
                            if (nparams > 0) { LLVMGetParamTypes(fn_ty, param_ts); }
                            if (nparams >= 2) {
                                rhs_val = coerce_int_val(rhs_val, param_ts[1], ctx.llvm_builder);
                            }
                            free((i8*)param_ts);
                            cargs[1] = rhs_val;
                            i32 nargs = (nparams >= 2) ? 2 : 1;
                            return LLVMBuildCall2(ctx.llvm_builder, fn_ty, fn, cargs, nargs, "op_result");
                        }
                    }
                }
            }
        }
    }

    // Short-circuit logical AND/OR: evaluate RHS only if needed
    if (e.bop == bop_log_and) {
        i8* lhs_val = visit_expr(e.lhs, ctx);
        if (lhs_val == (i8*)0) { return (i8*)0; }
        i8* lhs_bool = to_bool(lhs_val, ctx.llvm_builder, ctx.llvm_ctx);
        i8* cur_fn   = ctx.current_func;
        i8* then_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, cur_fn, "land_rhs");
        i8* merge_bb = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, cur_fn, "land_merge");
        i8* lhs_bb   = LLVMGetInsertBlock(ctx.llvm_builder);
        LLVMBuildCondBr(ctx.llvm_builder, lhs_bool, then_bb, merge_bb);
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, then_bb);
        i8* rhs_val = visit_expr(e.rhs, ctx);
        i8* rhs_bool = (rhs_val != (i8*)0) ? to_bool(rhs_val, ctx.llvm_builder, ctx.llvm_ctx) : LLVMConstInt(LLVMInt1TypeInContext(ctx.llvm_ctx), 0, 0);
        i8* rhs_bb   = LLVMGetInsertBlock(ctx.llvm_builder);
        LLVMBuildBr(ctx.llvm_builder, merge_bb);
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb);
        i8* i1t = LLVMInt1TypeInContext(ctx.llvm_ctx);
        i8* phi = LLVMBuildPhi(ctx.llvm_builder, i1t, "land");
        i8* false_val = LLVMConstInt(i1t, 0, 0);
        LLVMAddIncoming(phi, &false_val, &lhs_bb, 1);
        LLVMAddIncoming(phi, &rhs_bool, &rhs_bb, 1);
        return phi;
    }
    if (e.bop == bop_log_or) {
        i8* lhs_val2 = visit_expr(e.lhs, ctx);
        if (lhs_val2 == (i8*)0) { return (i8*)0; }
        i8* lhs_bool2 = to_bool(lhs_val2, ctx.llvm_builder, ctx.llvm_ctx);
        i8* cur_fn2   = ctx.current_func;
        i8* else_bb   = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, cur_fn2, "lor_rhs");
        i8* merge_bb2 = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, cur_fn2, "lor_merge");
        i8* lhs_bb2   = LLVMGetInsertBlock(ctx.llvm_builder);
        LLVMBuildCondBr(ctx.llvm_builder, lhs_bool2, merge_bb2, else_bb);
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, else_bb);
        i8* rhs_val2 = visit_expr(e.rhs, ctx);
        i8* rhs_bool2 = (rhs_val2 != (i8*)0) ? to_bool(rhs_val2, ctx.llvm_builder, ctx.llvm_ctx) : LLVMConstInt(LLVMInt1TypeInContext(ctx.llvm_ctx), 0, 0);
        i8* rhs_bb2   = LLVMGetInsertBlock(ctx.llvm_builder);
        LLVMBuildBr(ctx.llvm_builder, merge_bb2);
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb2);
        i8* i1t2 = LLVMInt1TypeInContext(ctx.llvm_ctx);
        i8* phi2 = LLVMBuildPhi(ctx.llvm_builder, i1t2, "lor");
        i8* true_val = LLVMConstInt(i1t2, 1, 0);
        LLVMAddIncoming(phi2, &true_val, &lhs_bb2, 1);
        LLVMAddIncoming(phi2, &rhs_bool2, &rhs_bb2, 1);
        return phi2;
    }

    i8* lhs = visit_expr(e.lhs, ctx);
    i8* rhs = visit_expr(e.rhs, ctx);
    if (lhs == (i8*)0 || rhs == (i8*)0) { return (i8*)0; }

    i8* lt = LLVMTypeOf(lhs);
    i8* rt = LLVMTypeOf(rhs);
    bool is_float_op = llvm_is_float(lt);
    bool is_ptr_op   = LLVMGetTypeKind(lt) == LLVMPointerTypeKind;

    // Determine if the operands are unsigned integers (for div/mod/comparisons).
    bool uns = false;
    if (e.lhs != (parser.expr_node*)0) {
        if (e.lhs.kind == ek_identifier && e.lhs.str_val != (i8*)0) {
            uns = ctx_lookup_local_unsigned(ctx, e.lhs.str_val);
            if (!uns) { uns = sb_map_get(&ctx.global_var_unsigned, e.lhs.str_val); }
        }
        if (!uns) { uns = is_unsigned_type_node(e.lhs.cast_type); }
    }

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
        if (uns) { return LLVMBuildUDiv(ctx.llvm_builder, lhs, rhs, "udiv"); }
        return LLVMBuildSDiv(ctx.llvm_builder, lhs, rhs, "sdiv");
    }
    if (op == bop_mod) {
        if (is_float_op) { return LLVMBuildFRem(ctx.llvm_builder, lhs, rhs, "frem"); }
        if (uns) { return LLVMBuildURem(ctx.llvm_builder, lhs, rhs, "urem"); }
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
    if (op == bop_lt)  { pred = is_float_op ? LLVMRealOLT : (uns ? LLVMIntULT : LLVMIntSLT); }
    if (op == bop_gt)  { pred = is_float_op ? LLVMRealOGT : (uns ? LLVMIntUGT : LLVMIntSGT); }
    if (op == bop_lte) { pred = is_float_op ? LLVMRealOLE : (uns ? LLVMIntULE : LLVMIntSLE); }
    if (op == bop_gte) { pred = is_float_op ? LLVMRealOGE : (uns ? LLVMIntUGE : LLVMIntSGE); }

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
        bool uns_a = false;
        if (e.lhs != (parser.expr_node*)0 && e.lhs.kind == ek_identifier) {
            uns_a = ctx_lookup_local_unsigned(ctx, e.lhs.str_val);
        }
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
                          : (uns_a ? LLVMBuildUDiv(ctx.llvm_builder, cur, rhs_val, "udiv_a")
                                   : LLVMBuildSDiv(ctx.llvm_builder, cur, rhs_val, "sdiv_a"));
        } else if (op == bop_mod_assign) {
            result = uns_a ? LLVMBuildURem(ctx.llvm_builder, cur, rhs_val, "urem_a")
                           : LLVMBuildSRem(ctx.llvm_builder, cur, rhs_val, "srem_a");
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
        // For pointer-to-struct locals (e.g., self: T* stored as alloca ptr),
        // obj_ptr is the alloca holding the struct pointer — load to get actual T*.
        if (obj_ptr != (i8*)0 && obj_expr != (parser.expr_node*)0 && obj_expr.kind == ek_identifier) {
            i8* local_t = ctx_lookup_local_type(ctx, obj_expr.str_val);
            if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMPointerTypeKind) {
                obj_ptr = LLVMBuildLoad2(ctx.llvm_builder, local_t, obj_ptr, "self_load");
            }
        }

        i8* struct_name = (i8*)0;
        if (obj_ptr != (i8*)0) {
            i8* pt = LLVMTypeOf(obj_ptr);
            i32 pk = LLVMGetTypeKind(pt);
            if (pk == LLVMPointerTypeKind) {
                i8* inner = LLVMGetElementType(pt);
                if (inner != (i8*)0 && LLVMGetTypeKind(inner) == LLVMStructTypeKind) {
                    struct_name = LLVMGetStructName(inner);
                }
            }
        }
        // Fallback: derive struct name from local type via infer_expr_struct_type
        // (needed for LLVM opaque-pointer mode where LLVMGetElementType returns null)
        if (struct_name == (i8*)0 && obj_expr != (parser.expr_node*)0) {
            i8* st = infer_expr_struct_type(obj_expr, ctx);
            if (st != (i8*)0) {
                struct_name = LLVMGetStructName(st);
            }
        }

        if (struct_name != (i8*)0 && method_name != (i8*)0) {
            i8 mt_name[512];
            snprintf(mt_name, (u64)512, "%s__MT_%s", struct_name, method_name);
            i8* fn    = sv_map_get(&ctx.global_funcs,      mt_name);
            i8* fn_ty = st_map_get(&ctx.global_func_types, mt_name);

            // Fallback: try __NS_ prefix (istruc/namespace methods)
            if (fn == (i8*)0 || fn_ty == (i8*)0) {
                snprintf(mt_name, (u64)512, "%s__NS_%s", struct_name, method_name);
                fn    = sv_map_get(&ctx.global_funcs,      mt_name);
                fn_ty = st_map_get(&ctx.global_func_types, mt_name);
            }

            if (fn != (i8*)0 && fn_ty != (i8*)0) {
                i32 nargs = e.args_len + 1;
                i8** args = (i8**)malloc(sizeof(i8*) * (u64)nargs);
                args[0]   = obj_ptr;
                i32 i = 0;
                u32 nparams = LLVMCountParamTypes(fn_ty);
                i8** param_ts = (i8**)malloc(sizeof(i8*) * (u64)(nparams + 1));
                if (nparams > 0) { LLVMGetParamTypes(fn_ty, param_ts); }
                while (i < e.args_len) {
                    i8* av = visit_expr(e.args[i], ctx);
                    i32 pi = i + 1;
                    if (av != (i8*)0 && (u32)pi < nparams) {
                        av = coerce_int_val(av, param_ts[pi], ctx.llvm_builder);
                    }
                    args[i + 1] = av;
                    i = i + 1;
                }
                free((i8*)param_ts);
                i8* result = LLVMBuildCall2(ctx.llvm_builder, fn_ty, fn, args, nargs, "");
                free((i8*)args);
                return result;
            }
        }

        // ADT variant method: e.method() where e is an ADT enum value
        if (struct_name != (i8*)0 && method_name != (i8*)0) {
            i8* adt_ed_ptr_vm = sv_map_get(&ctx.adt_enum_decls, struct_name);
            if (adt_ed_ptr_vm != (i8*)0) {
                parser.enum_decl* adt_ed_vm = (parser.enum_decl*)adt_ed_ptr_vm;
                i32 vi_vm = 0;
                while (vi_vm < adt_ed_vm.variants_len) {
                    i32 vkind_vm = (adt_ed_vm.variant_kinds != (i32*)0) ? adt_ed_vm.variant_kinds[vi_vm] : 0;
                    if (vkind_vm == 2 || vkind_vm == 3) {
                        i8 adtmt_name[512];
                        snprintf(adtmt_name, (u64)512, "%s__NS_%s__MT_%s", struct_name, adt_ed_vm.variant_names[vi_vm], method_name);
                        i8* fn_vm    = sv_map_get(&ctx.global_funcs,      adtmt_name);
                        i8* fn_ty_vm = st_map_get(&ctx.global_func_types, adtmt_name);
                        if (fn_vm != (i8*)0 && fn_ty_vm != (i8*)0) {
                            i32 nargs_vm = e.args_len + 1;
                            i8** args_vm = (i8**)malloc(sizeof(i8*) * (u64)nargs_vm);
                            args_vm[0] = obj_ptr;
                            i32 i_vm = 0;
                            while (i_vm < e.args_len) {
                                args_vm[i_vm + 1] = visit_expr(e.args[i_vm], ctx);
                                i_vm = i_vm + 1;
                            }
                            i8* result_vm = LLVMBuildCall2(ctx.llvm_builder, fn_ty_vm, fn_vm, args_vm, nargs_vm, "");
                            free((i8*)args_vm);
                            return result_vm;
                        }
                    }
                    vi_vm = vi_vm + 1;
                }
            }
        }

        // ADT enum constructor: EnumName.VariantName(args...) or EnumName.VariantName()
        if (obj_expr != (parser.expr_node*)0 && obj_expr.kind == ek_identifier &&
                obj_expr.str_val != (i8*)0 && method_name != (i8*)0) {
            i8* adt_ed_ptr = sv_map_get(&ctx.adt_enum_decls, obj_expr.str_val);
            if (adt_ed_ptr != (i8*)0) {
                parser.enum_decl* adt_ed = (parser.enum_decl*)adt_ed_ptr;
                // Find the variant index
                i32 var_idx = -1;
                i32 vi = 0;
                while (vi < adt_ed.variants_len) {
                    if (strcmp(adt_ed.variant_names[vi], method_name) == 0) { var_idx = vi; }
                    vi = vi + 1;
                }
                if (var_idx >= 0) {
                    i8* enum_st = st_map_get(&ctx.struct_types, obj_expr.str_val);
                    if (enum_st != (i8*)0) {
                        i8* alloca = LLVMBuildAlloca(ctx.llvm_builder, enum_st, "adt_ctor");
                        LLVMBuildStore(ctx.llvm_builder, LLVMConstNull(enum_st), alloca);
                        // Store tag at field 0
                        i8* tag_ptr = LLVMBuildStructGEP2(ctx.llvm_builder, enum_st, alloca, 0, "adt_tag");
                        i8* i32t = LLVMInt32TypeInContext(ctx.llvm_ctx);
                        LLVMBuildStore(ctx.llvm_builder, LLVMConstInt(i32t, (u64)var_idx, 0), tag_ptr);
                        // Store args into payload at byte offsets (field 1 = [N x i8])
                        i8* pay_ptr = LLVMBuildStructGEP2(ctx.llvm_builder, enum_st, alloca, 1, "adt_pay");
                        u64 byte_off = 0;
                        i32 ai = 0;
                        while (ai < e.args_len) {
                            i8* av = visit_expr(e.args[ai], ctx);
                            if (av != (i8*)0) {
                                i8* av_t = LLVMTypeOf(av);
                                u64 av_sz = llvm_type_byte_size(av_t);
                                // GEP into payload bytes
                                i8* i8t = LLVMInt8TypeInContext(ctx.llvm_ctx);
                                i8* arr_t = LLVMArrayType(i8t, 1);
                                i8* fptr = LLVMBuildGEP2(ctx.llvm_builder, i8t, pay_ptr, (i8**)0, 0, "pay_elem");
                                // Build GEP with explicit byte offset
                                i8* idx_v = LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), byte_off, 0);
                                i8* elem = LLVMBuildGEP2(ctx.llvm_builder, i8t, pay_ptr, &idx_v, 1, "pay_elem");
                                LLVMBuildStore(ctx.llvm_builder, av, elem);
                                byte_off = byte_off + ((av_sz + 7) & ~(u64)7);
                            }
                            ai = ai + 1;
                        }
                        return LLVMBuildLoad2(ctx.llvm_builder, enum_st, alloca, "adt_val");
                    }
                }
            }
        }

        // Try namespace call: obj must be an identifier naming a namespace.
        if (obj_expr != (parser.expr_node*)0 && obj_expr.kind == ek_identifier &&
                obj_expr.str_val != (i8*)0 && method_name != (i8*)0) {
            i8 ns_fn_name[512];
            snprintf(ns_fn_name, (u64)512, "%s__NS_%s", obj_expr.str_val, method_name);
            i8* ns_fn    = sv_map_get(&ctx.global_funcs,      ns_fn_name);
            i8* ns_fn_ty = st_map_get(&ctx.global_func_types, ns_fn_name);
            if (ns_fn != (i8*)0 && ns_fn_ty != (i8*)0) {
                i32 nargs = e.args_len;
                i8** args = (i8**)0;
                if (nargs > 0) {
                    args = (i8**)malloc(sizeof(i8*) * (u64)nargs);
                    i32 i = 0;
                    while (i < nargs) { args[i] = visit_expr(e.args[i], ctx); i = i + 1; }
                    coerce_args_to_fn(ns_fn_ty, args, nargs, ctx.llvm_builder);
                }
                i8* result = LLVMBuildCall2(ctx.llvm_builder, ns_fn_ty, ns_fn, args, nargs, "");
                if (args != (i8**)0) { free((i8*)args); }
                return result;
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

        if (fn == (i8*)0) {
            // Try as local function-pointer variable (indirect call).
            // In LLVM opaque-pointer mode LLVMGetElementType returns null, so we use
            // the function type stored at declaration time in local_func_types.
            i8* lfn_ty = ctx_lookup_local_func_type(ctx, callee_name);
            if (lfn_ty != (i8*)0) {
                i8* local_alloca = ctx_lookup_local(ctx, callee_name);
                if (local_alloca != (i8*)0) {
                    i8* ptr_t = LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                    i8* fp = LLVMBuildLoad2(ctx.llvm_builder, ptr_t, local_alloca, "fp");
                    i32 nargs2 = e.args_len;
                    i8** args2 = (i8**)0;
                    if (nargs2 > 0) {
                        args2 = (i8**)malloc(sizeof(i8*) * (u64)nargs2);
                        i32 i = 0;
                        while (i < nargs2) {
                            args2[i] = visit_expr(e.args[i], ctx);
                            i = i + 1;
                        }
                    }
                    if (args2 != (i8**)0) {
                        coerce_args_to_fn(lfn_ty, args2, nargs2, ctx.llvm_builder);
                    }
                    i8* result2 = LLVMBuildCall2(ctx.llvm_builder, lfn_ty, fp, args2, nargs2, "");
                    if (args2 != (i8**)0) { free((i8*)args2); }
                    return result2;
                }
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

    // Generic monomorphization: if call has type_args and callee is a generic function
    if (fn == (i8*)0 && callee_name != (i8*)0 && e.type_args_len > 0) {
        i8* gfd_ptr = sv_map_get(&ctx.generic_funcs, callee_name);
        if (gfd_ptr != (i8*)0) {
            parser.func_decl* gfd = (parser.func_decl*)gfd_ptr;
            // Build specialized name: callee__mono_T1_T2
            i8 mono_name[512];
            i32 mn_off = snprintf(mono_name, (u64)512, "%s__mono", callee_name);
            i32 tai = 0;
            while (tai < e.type_args_len) {
                parser.type_node* ta = e.type_args[tai];
                i8 ta_str[64];
                if (ta != (parser.type_node*)0 && ta.is_primitive) {
                    if (ta.prim == (i32)arb_int) {
                        snprintf(ta_str, (u64)64, "_i%d", (i32)ta.bit_width);
                    } else if (ta.prim == (i32)arb_uint) {
                        snprintf(ta_str, (u64)64, "_u%d", (i32)ta.bit_width);
                    } else if (ta.prim == (i32)arb_float) {
                        snprintf(ta_str, (u64)64, "_f%d", (i32)ta.bit_width);
                    } else if (ta.prim == (i32)arb_bool) {
                        snprintf(ta_str, (u64)64, "_b%d", (i32)ta.bit_width);
                    } else {
                        snprintf(ta_str, (u64)64, "_p%d", (i32)ta.prim);
                    }
                } else if (ta != (parser.type_node*)0 && ta.name != (i8*)0) {
                    snprintf(ta_str, (u64)64, "_%s", ta.name);
                } else {
                    snprintf(ta_str, (u64)64, "_T");
                }
                i32 tl = (i32)strlen(ta_str);
                if (mn_off + tl < 510) {
                    i32 ci = 0;
                    while (ci < tl) { mono_name[mn_off + ci] = ta_str[ci]; ci = ci + 1; }
                    mn_off = mn_off + tl;
                    mono_name[mn_off] = 0;
                }
                tai = tai + 1;
            }
            i8* mono_name_dup = lexer.str_dup(mono_name);

            // Check if already instantiated
            fn    = sv_map_get(&ctx.global_funcs,      mono_name_dup);
            fn_ty = st_map_get(&ctx.global_func_types, mono_name_dup);

            if (fn == (i8*)0 || fn_ty == (i8*)0) {
                // Bind type parameters
                i32 tp_i = 0;
                while (tp_i < gfd.type_params_len && tp_i < e.type_args_len) {
                    i8* param_name = gfd.type_params[tp_i];
                    parser.type_node* ta = e.type_args[tp_i];
                    i8* ta_llvm = llvm_type_of(ta, ctx);
                    st_map_set(&ctx.type_param_bindings, param_name, ta_llvm);
                    tp_i = tp_i + 1;
                }

                // Temporarily rename and hide type params for prototype/body generation
                i8* saved_name      = gfd.name;
                i8* saved_mangle    = gfd.mangled_name;
                i32 saved_tp_len    = gfd.type_params_len;
                gfd.name            = mono_name_dup;
                gfd.mangled_name    = (i8*)0;
                gfd.type_params_len = 0; // suppress generic guard in visit_func_decl_*

                // Save builder/context state
                i8* saved_bb        = LLVMGetInsertBlock(ctx.llvm_builder);
                i8* saved_func      = ctx.current_func;
                i8* saved_func_ty   = ctx.current_func_type;
                i8* saved_ret_ty    = ctx.current_ret_type;
                bool saved_is_eu    = ctx.current_func_is_error_union;
                i8* saved_eu_ty     = ctx.current_error_union_type;
                i8* saved_cls       = ctx.current_class_name;

                visit_func_decl_prototype(gfd, ctx);
                visit_func_decl(gfd, ctx);

                // Restore
                gfd.name            = saved_name;
                gfd.mangled_name    = saved_mangle;
                gfd.type_params_len = saved_tp_len;
                ctx.current_func              = saved_func;
                ctx.current_func_type         = saved_func_ty;
                ctx.current_ret_type          = saved_ret_ty;
                ctx.current_func_is_error_union = saved_is_eu;
                ctx.current_error_union_type  = saved_eu_ty;
                ctx.current_class_name        = saved_cls;
                LLVMPositionBuilderAtEnd(ctx.llvm_builder, saved_bb);

                // Clear type param bindings
                tp_i = 0;
                while (tp_i < gfd.type_params_len) {
                    st_map_set(&ctx.type_param_bindings, gfd.type_params[tp_i], (i8*)0);
                    tp_i = tp_i + 1;
                }

                fn    = sv_map_get(&ctx.global_funcs,      mono_name_dup);
                fn_ty = st_map_get(&ctx.global_func_types, mono_name_dup);
            }
        }
    }

    // Generic type inference: call has no type_args but callee is generic — infer from args
    if (fn == (i8*)0 && callee_name != (i8*)0 && e.type_args_len == 0) {
        i8* gfd_ptr = sv_map_get(&ctx.generic_funcs, callee_name);
        if (gfd_ptr != (i8*)0) {
            parser.func_decl* gfd = (parser.func_decl*)gfd_ptr;
            // Evaluate args to infer types
            i32 nai = e.args_len;
            i8** infer_vals = (i8**)0;
            if (nai > 0) {
                infer_vals = (i8**)malloc(sizeof(i8*) * (u64)nai);
                i32 ii = 0;
                while (ii < nai) {
                    infer_vals[ii] = visit_expr(e.args[ii], ctx);
                    ii = ii + 1;
                }
            }
            // Build mono_name by matching type params to arg types
            i8 mono_name_inf[512];
            i32 mn_off_inf = snprintf(mono_name_inf, (u64)512, "%s__mono", callee_name);
            i32 tp_i = 0;
            bool infer_ok = gfd.type_params_len > 0;
            while (tp_i < gfd.type_params_len) {
                i8* tpname = gfd.type_params[tp_i];
                // Find first param whose type node name matches this type param
                i8* inferred_ty = (i8*)0;
                i32 pi = 0;
                while (pi < gfd.params_len && inferred_ty == (i8*)0) {
                    parser.param_decl pd = gfd.params[pi];
                    if (pd.type != (parser.type_node*)0) {
                        if (pd.type.name != (i8*)0 && strcmp(pd.type.name, tpname) == 0) {
                            if (pi < nai && infer_vals != (i8**)0 && infer_vals[pi] != (i8*)0) {
                                inferred_ty = LLVMTypeOf(infer_vals[pi]);
                            }
                        }
                    }
                    pi = pi + 1;
                }
                if (inferred_ty == (i8*)0) { infer_ok = false; }
                else {
                    st_map_set(&ctx.type_param_bindings, tpname, inferred_ty);
                    // Append type suffix to mono_name
                    i32 tk = LLVMGetTypeKind(inferred_ty);
                    i8 ta_s[64];
                    if (tk == LLVMIntegerTypeKind) {
                        u32 bw = LLVMGetIntTypeWidth(inferred_ty);
                        snprintf(ta_s, (u64)64, "_i%d", (i32)bw);
                    } else if (tk == LLVMFloatTypeKind) {
                        snprintf(ta_s, (u64)64, "_f32");
                    } else if (tk == LLVMDoubleTypeKind) {
                        snprintf(ta_s, (u64)64, "_f64");
                    } else if (tk == LLVMPointerTypeKind) {
                        snprintf(ta_s, (u64)64, "_ptr");
                    } else {
                        snprintf(ta_s, (u64)64, "_T");
                    }
                    i32 tl = (i32)strlen(ta_s);
                    if (mn_off_inf + tl < 510) {
                        i32 ci = 0;
                        while (ci < tl) { mono_name_inf[mn_off_inf + ci] = ta_s[ci]; ci = ci + 1; }
                        mn_off_inf = mn_off_inf + tl;
                        mono_name_inf[mn_off_inf] = 0;
                    }
                }
                tp_i = tp_i + 1;
            }
            if (infer_ok) {
                i8* mni_dup = lexer.str_dup(mono_name_inf);
                fn    = sv_map_get(&ctx.global_funcs,      mni_dup);
                fn_ty = st_map_get(&ctx.global_func_types, mni_dup);
                if (fn == (i8*)0 || fn_ty == (i8*)0) {
                    i8* saved_name2   = gfd.name;
                    i8* saved_mangle2 = gfd.mangled_name;
                    i32 saved_tp_len2 = gfd.type_params_len;
                    gfd.name            = mni_dup;
                    gfd.mangled_name    = (i8*)0;
                    gfd.type_params_len = 0;
                    i8* saved_bb2       = LLVMGetInsertBlock(ctx.llvm_builder);
                    i8* saved_func2     = ctx.current_func;
                    i8* saved_fty2      = ctx.current_func_type;
                    i8* saved_rty2      = ctx.current_ret_type;
                    bool saved_eu2      = ctx.current_func_is_error_union;
                    i8* saved_euty2     = ctx.current_error_union_type;
                    i8* saved_cls2      = ctx.current_class_name;
                    visit_func_decl_prototype(gfd, ctx);
                    visit_func_decl(gfd, ctx);
                    gfd.name            = saved_name2;
                    gfd.mangled_name    = saved_mangle2;
                    gfd.type_params_len = saved_tp_len2;
                    ctx.current_func              = saved_func2;
                    ctx.current_func_type         = saved_fty2;
                    ctx.current_ret_type          = saved_rty2;
                    ctx.current_func_is_error_union = saved_eu2;
                    ctx.current_error_union_type  = saved_euty2;
                    ctx.current_class_name        = saved_cls2;
                    LLVMPositionBuilderAtEnd(ctx.llvm_builder, saved_bb2);
                    // Clear type param bindings
                    tp_i = 0;
                    while (tp_i < gfd.type_params_len) {
                        st_map_set(&ctx.type_param_bindings, gfd.type_params[tp_i], (i8*)0);
                        tp_i = tp_i + 1;
                    }
                    fn    = sv_map_get(&ctx.global_funcs,      mni_dup);
                    fn_ty = st_map_get(&ctx.global_func_types, mni_dup);
                }
                // If monomorphization succeeded, use inferred_vals as pre-evaluated args
                if (fn != (i8*)0 && fn_ty != (i8*)0) {
                    i32 ni2 = e.args_len;
                    if (infer_vals != (i8**)0) {
                        coerce_args_to_fn(fn_ty, infer_vals, ni2, ctx.llvm_builder);
                    }
                    i8* result = LLVMBuildCall2(ctx.llvm_builder, fn_ty, fn, infer_vals, ni2, "");
                    if (infer_vals != (i8**)0) { free((i8*)infer_vals); }
                    return result;
                }
            }
            if (infer_vals != (i8**)0) { free((i8*)infer_vals); }
            // Clear any partial bindings
            tp_i = 0;
            while (tp_i < gfd.type_params_len) {
                st_map_set(&ctx.type_param_bindings, gfd.type_params[tp_i], (i8*)0);
                tp_i = tp_i + 1;
            }
        }
    }

    if (fn == (i8*)0 && callee_name != (i8*)0) {
        // Lazily synthesise __derive_Clone_StructName(StructType* self) -> StructType
        i8* clone_prefix = "__derive_Clone_";
        u64 clone_prefix_len = (u64)strlen(clone_prefix);
        if (strncmp(callee_name, clone_prefix, clone_prefix_len) == 0) {
            i8* sname = callee_name + (i64)clone_prefix_len;
            i8* st = st_map_get(&ctx.struct_types, sname);
            if (st != (i8*)0) {
                i8* ptr_t = LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                i8* param_types[1];
                param_types[0] = ptr_t;
                fn_ty = LLVMFunctionType(st, param_types, 1, 0);
                fn = LLVMAddFunction(ctx.llvm_mod, callee_name, fn_ty);
                i8* entry_bb = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "entry");
                i8* saved_bb = LLVMGetInsertBlock(ctx.llvm_builder);
                LLVMPositionBuilderAtEnd(ctx.llvm_builder, entry_bb);
                i8* self_param = LLVMGetParam(fn, 0);
                i8* loaded = LLVMBuildLoad2(ctx.llvm_builder, st, self_param, "clone");
                LLVMBuildRet(ctx.llvm_builder, loaded);
                LLVMPositionBuilderAtEnd(ctx.llvm_builder, saved_bb);
                sv_map_set(&ctx.global_funcs,      lexer.str_dup(callee_name), fn);
                st_map_set(&ctx.global_func_types, lexer.str_dup(callee_name), fn_ty);
            }
        }
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

// Gets or creates the __artemis_error_t LLVM struct type in the IR context.
i8* get_error_struct_type(ir_context* ctx, i8* i32_t) {
    i8* err_struct_t = st_map_get(&ctx.struct_types, "__artemis_error_t");
    if (err_struct_t == (i8*)0) {
        err_struct_t = LLVMStructCreateNamed(ctx.llvm_ctx, "__artemis_error_t");
        i8* ptrt = LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
        i8* flds[2];
        flds[0] = i32_t;
        flds[1] = ptrt;
        LLVMStructSetBody(err_struct_t, flds, 2, 0);
        st_map_set(&ctx.struct_types, "__artemis_error_t", err_struct_t);
        struct_meta esm;
        esm.name = "__artemis_error_t";
        esm.is_union = false;
        name_list_init(&esm.field_names);
        type_list_init(&esm.field_types);
        bool_list_init(&esm.field_unsigned);
        type_list_init(&esm.field_pointee);
        name_list_push(&esm.field_names, "code");
        type_list_push(&esm.field_types, i32_t);
        bool_list_push(&esm.field_unsigned, false);
        type_list_push(&esm.field_pointee, (i8*)0);
        name_list_push(&esm.field_names, "payload");
        type_list_push(&esm.field_types, ptrt);
        bool_list_push(&esm.field_unsigned, false);
        type_list_push(&esm.field_pointee, (i8*)0);
        struct_meta_vec_push(&ctx.struct_meta_tbl, esm);
    }
    return err_struct_t;
}

// Gets or creates the __artemis_error_payload global variable in the IR module.
i8* get_error_payload_global(ir_context* ctx) {
    i8* payload_gv = sv_map_get(&ctx.global_vars, "__artemis_error_payload");
    if (payload_gv == (i8*)0) {
        i8* ptrt = LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
        payload_gv = LLVMAddGlobal(ctx.llvm_mod, ptrt, "__artemis_error_payload");
        LLVMSetInitializer(payload_gv, LLVMConstNull(ptrt));
        sv_map_set(&ctx.global_vars, "__artemis_error_payload", payload_gv);
    }
    return payload_gv;
}

// Emit error-variable binding (if any) and then visit the handler block.
// Split out from ek_except_expr to avoid a codegen bug where code following an
// if-block whose body contains nested ifs gets silently dropped.
void visit_except_handler(parser.expr_node* e, ir_context* ctx, i8* neg1, i8* i32_t) {
    if (e.member_name != (i8*)0) {
        // Outer-if body uses only helper calls — no nested ifs here.
        i8* err_struct_t = get_error_struct_type(ctx, i32_t);
        i8* err_alloca   = LLVMBuildAlloca(ctx.llvm_builder, err_struct_t, e.member_name);
        i8* code_gep     = LLVMBuildStructGEP2(ctx.llvm_builder, err_struct_t, err_alloca, 0, "err_code_ptr");
        LLVMBuildStore(ctx.llvm_builder, neg1, code_gep);
        i8* ptrt2        = LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
        i8* payload_gv   = get_error_payload_global(ctx);
        i8* payload_val  = LLVMBuildLoad2(ctx.llvm_builder, ptrt2, payload_gv, "err_payload");
        i8* payload_gep  = LLVMBuildStructGEP2(ctx.llvm_builder, err_struct_t, err_alloca, 1, "err_payload_ptr");
        LLVMBuildStore(ctx.llvm_builder, payload_val, payload_gep);
        ctx_declare_local(ctx, e.member_name, err_alloca, err_struct_t, (i8*)0, false);
    }
    visit_block_stmt((parser.block_stmt*)e.handler_block, ctx);
}

// Main expression visitor.
i8* visit_expr(parser.expr_node* e, ir_context* ctx) {
    if (e == (parser.expr_node*)0) { return (i8*)0; }

    i32 kind = e.kind;

    if (kind == ek_int_lit) {
        i64 iv = e.int_val;
        if (iv < (i64)-2147483648 || iv > (i64)2147483647) {
            return LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), (u64)iv, 1);
        }
        return LLVMConstInt(LLVMInt32TypeInContext(ctx.llvm_ctx), (u64)iv, 1);
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

    if (kind == ek_error_lit) {
        // error.Variant(payload) — store payload in global, return -1
        if (e.operand != (parser.expr_node*)0) {
            i8* payload_gv = sv_map_get(&ctx.global_vars, "__artemis_error_payload");
            if (payload_gv == (i8*)0) {
                i8* ptrt = LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                payload_gv = LLVMAddGlobal(ctx.llvm_mod, ptrt, "__artemis_error_payload");
                LLVMSetInitializer(payload_gv, LLVMConstNull(ptrt));
                sv_map_set(&ctx.global_vars, "__artemis_error_payload", payload_gv);
            }
            i8* payload_val = visit_expr(e.operand, ctx);
            if (payload_val != (i8*)0) {
                LLVMBuildStore(ctx.llvm_builder, payload_val, payload_gv);
            }
        }
        i8* i32_t = LLVMInt32TypeInContext(ctx.llvm_ctx);
        i64 minus1_e = (i64)-1;
        return LLVMConstInt(i32_t, (u64)minus1_e, 1);
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

        // ADT named field access: (*x).field — look up field type from variant metadata
        if (e.object != (parser.expr_node*)0 && e.object.kind == ek_unary && e.object.uop == uop_deref &&
                e.object.operand != (parser.expr_node*)0 && e.object.operand.kind == ek_identifier) {
            i8* local_t = ctx_lookup_local_type(ctx, e.object.operand.str_val);
            if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMStructTypeKind) {
                i8* sname_adt = LLVMGetStructName(local_t);
                if (sname_adt != (i8*)0 && sv_map_get(&ctx.adt_enum_decls, sname_adt) != (i8*)0) {
                    parser.enum_decl* adt_ed = (parser.enum_decl*)sv_map_get(&ctx.adt_enum_decls, sname_adt);
                    // Find the field type in any named/istruc variant
                    i32 vi = 0;
                    while (vi < adt_ed.variants_len) {
                        i32 vkind = (adt_ed.variant_kinds != (i32*)0) ? adt_ed.variant_kinds[vi] : 0;
                        i32 fc = (adt_ed.variant_field_counts != (i32*)0) ? adt_ed.variant_field_counts[vi] : 0;
                        if ((vkind == 2 || vkind == 3) && fc > 0 && adt_ed.variant_field_names_flat != (i8**)0) {
                            i32 fi = 0;
                            while (fi < fc) {
                                i8* vfn2 = adt_ed.variant_field_names_flat[vi * 8 + fi];
                                if (vfn2 != (i8*)0 && strcmp(vfn2, e.member_name) == 0) {
                                    parser.type_node* ft = (adt_ed.variant_field_type_flat != (i8**)0)
                                        ? (parser.type_node*)adt_ed.variant_field_type_flat[vi * 8 + fi] : (parser.type_node*)0;
                                    i8* flt = (ft != (parser.type_node*)0) ? llvm_type_of(ft, ctx) : LLVMInt32TypeInContext(ctx.llvm_ctx);
                                    return LLVMBuildLoad2(ctx.llvm_builder, flt, ptr, "adt_fld_load");
                                }
                                fi = fi + 1;
                            }
                        }
                        vi = vi + 1;
                    }
                }
            }
        }

        // ADT named field load: x.field where x is a pointer-to-ADT-enum local (auto-deref)
        if (e.object != (parser.expr_node*)0 && e.object.kind == ek_identifier) {
            i8* deref_t3 = ctx_lookup_deref_type(ctx, e.object.str_val);
            if (deref_t3 != (i8*)0 && LLVMGetTypeKind(deref_t3) == LLVMStructTypeKind) {
                i8* sname_adt3 = LLVMGetStructName(deref_t3);
                if (sname_adt3 != (i8*)0) {
                    i8* adt_ed_ptr3 = sv_map_get(&ctx.adt_enum_decls, sname_adt3);
                    if (adt_ed_ptr3 != (i8*)0) {
                        parser.enum_decl* adt_ed3 = (parser.enum_decl*)adt_ed_ptr3;
                        i32 vi3 = 0;
                        while (vi3 < adt_ed3.variants_len) {
                            i32 vkind3 = (adt_ed3.variant_kinds != (i32*)0) ? adt_ed3.variant_kinds[vi3] : 0;
                            i32 fc3 = (adt_ed3.variant_field_counts != (i32*)0) ? adt_ed3.variant_field_counts[vi3] : 0;
                            if ((vkind3 == 2 || vkind3 == 3) && fc3 > 0 && adt_ed3.variant_field_names_flat != (i8**)0) {
                                i32 fi3 = 0;
                                while (fi3 < fc3) {
                                    i8* vfn3 = adt_ed3.variant_field_names_flat[vi3 * 8 + fi3];
                                    if (vfn3 != (i8*)0 && strcmp(vfn3, e.member_name) == 0) {
                                        parser.type_node* ft3 = (adt_ed3.variant_field_type_flat != (i8**)0)
                                            ? (parser.type_node*)adt_ed3.variant_field_type_flat[vi3 * 8 + fi3] : (parser.type_node*)0;
                                        i8* flt3 = (ft3 != (parser.type_node*)0) ? llvm_type_of(ft3, ctx) : LLVMInt32TypeInContext(ctx.llvm_ctx);
                                        return LLVMBuildLoad2(ctx.llvm_builder, flt3, ptr, "adt_fld_load2");
                                    }
                                    fi3 = fi3 + 1;
                                }
                            }
                            vi3 = vi3 + 1;
                        }
                    }
                }
            }
        }

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
        // Struct → primitive: look for a conversion operator (e.g. operator_i32)
        if (vkind == LLVMStructTypeKind) {
            i8* sn = LLVMGetStructName(val_t);
            if (sn != (i8*)0) {
                i8 cop_name[512];
                i8* cop_fn    = (i8*)0;
                i8* cop_fn_ty = (i8*)0;
                if (tkind == LLVMIntegerTypeKind) {
                    u32 cop_bw = LLVMGetIntTypeWidth(target_t);
                    snprintf(cop_name, (u64)512, "%s__NS_operator_i%d", sn, (i32)cop_bw);
                    cop_fn    = sv_map_get(&ctx.global_funcs,      cop_name);
                    cop_fn_ty = st_map_get(&ctx.global_func_types, cop_name);
                    if (cop_fn == (i8*)0 || cop_fn_ty == (i8*)0) {
                        snprintf(cop_name, (u64)512, "%s__NS_operator_u%d", sn, (i32)cop_bw);
                        cop_fn    = sv_map_get(&ctx.global_funcs,      cop_name);
                        cop_fn_ty = st_map_get(&ctx.global_func_types, cop_name);
                    }
                }
                if (llvm_is_float(target_t)) {
                    snprintf(cop_name, (u64)512, "%s__NS_operator_f64", sn);
                    cop_fn    = sv_map_get(&ctx.global_funcs,      cop_name);
                    cop_fn_ty = st_map_get(&ctx.global_func_types, cop_name);
                    if (cop_fn == (i8*)0 || cop_fn_ty == (i8*)0) {
                        snprintf(cop_name, (u64)512, "%s__NS_operator_f32", sn);
                        cop_fn    = sv_map_get(&ctx.global_funcs,      cop_name);
                        cop_fn_ty = st_map_get(&ctx.global_func_types, cop_name);
                    }
                }
                if (cop_fn != (i8*)0 && cop_fn_ty != (i8*)0) {
                    i8* self_ptr = visit_lvalue(e.operand, ctx);
                    if (self_ptr == (i8*)0) {
                        self_ptr = LLVMBuildAlloca(ctx.llvm_builder, val_t, "conv_tmp");
                        LLVMBuildStore(ctx.llvm_builder, val, self_ptr);
                    }
                    i8* cop_args[1];
                    cop_args[0] = self_ptr;
                    return LLVMBuildCall2(ctx.llvm_builder, cop_fn_ty, cop_fn, cop_args, 1, "conv_op");
                }
            }
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
        i8* else_t = LLVMTypeOf(else_val);
        // Coerce types for PHI: both branches must have the same type
        if (phi_t != else_t) {
            i32 then_k = LLVMGetTypeKind(phi_t);
            i32 else_k = LLVMGetTypeKind(else_t);
            if (then_k == LLVMIntegerTypeKind && else_k == LLVMIntegerTypeKind) {
                // Widen the narrower branch
                i32 tw = LLVMGetIntTypeWidth(phi_t);
                i32 ew = LLVMGetIntTypeWidth(else_t);
                if (tw > ew) {
                    // position at else_end block to insert extension
                    LLVMPositionBuilderAtEnd(ctx.llvm_builder, else_end);
                    else_val = LLVMBuildSExt(ctx.llvm_builder, else_val, phi_t, "ext");
                    else_end = LLVMGetInsertBlock(ctx.llvm_builder);
                    LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb);
                } else if (ew > tw) {
                    phi_t = else_t;
                    LLVMPositionBuilderAtEnd(ctx.llvm_builder, then_end);
                    then_val = LLVMBuildSExt(ctx.llvm_builder, then_val, phi_t, "ext");
                    then_end = LLVMGetInsertBlock(ctx.llvm_builder);
                    LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb);
                }
            } else if (then_k == LLVMPointerTypeKind && else_k == LLVMIntegerTypeKind) {
                // Convert integer to pointer (null pointer case)
                LLVMPositionBuilderAtEnd(ctx.llvm_builder, else_end);
                else_val = LLVMBuildIntToPtr(ctx.llvm_builder, else_val, phi_t, "i2p_tern");
                else_end = LLVMGetInsertBlock(ctx.llvm_builder);
                LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb);
            } else if (then_k == LLVMIntegerTypeKind && else_k == LLVMPointerTypeKind) {
                phi_t = else_t;
                LLVMPositionBuilderAtEnd(ctx.llvm_builder, then_end);
                then_val = LLVMBuildIntToPtr(ctx.llvm_builder, then_val, phi_t, "i2p_tern");
                then_end = LLVMGetInsertBlock(ctx.llvm_builder);
                LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb);
            }
        }
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

    if (kind == ek_null_coal) {
        // a ?? b: if a is non-null use a, else use b
        if (e.lhs == (parser.expr_node*)0 || e.rhs == (parser.expr_node*)0) { return (i8*)0; }
        i8* lhs_val = visit_expr(e.lhs, ctx);
        if (lhs_val == (i8*)0) { return (i8*)0; }

        i8* null_val = LLVMConstNull(LLVMTypeOf(lhs_val));
        i8* is_null  = LLVMBuildICmp(ctx.llvm_builder, LLVMIntEQ, lhs_val, null_val, "is_null");

        i8* fn        = ctx.current_func;
        i8* null_bb   = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "coal_null");
        i8* nonnull_bb = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "coal_nonnull");
        i8* merge_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "coal_merge");

        LLVMBuildCondBr(ctx.llvm_builder, is_null, null_bb, nonnull_bb);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, null_bb);
        i8* rhs_val = visit_expr(e.rhs, ctx);
        i8* null_end = LLVMGetInsertBlock(ctx.llvm_builder);
        LLVMBuildBr(ctx.llvm_builder, merge_bb);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, nonnull_bb);
        i8* nonnull_end = LLVMGetInsertBlock(ctx.llvm_builder);
        LLVMBuildBr(ctx.llvm_builder, merge_bb);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb);
        if (rhs_val == (i8*)0) { return lhs_val; }
        i8* phi_t = LLVMTypeOf(lhs_val);
        i8* phi = LLVMBuildPhi(ctx.llvm_builder, phi_t, "coal");
        i8* incoming_vals[2];
        i8* incoming_blocks[2];
        incoming_vals[0]   = rhs_val;
        incoming_vals[1]   = lhs_val;
        incoming_blocks[0] = null_end;
        incoming_blocks[1] = nonnull_end;
        LLVMAddIncoming(phi, incoming_vals, incoming_blocks, 2);
        return phi;
    }

    if (kind == ek_class_init) {
        // ADT named-struct constructor: member_expr { .field = val, ... }
        // e.object is set (ek_member pointing to EnumName.VariantName) and e.init_type is null
        if (e.init_type == (parser.type_node*)0 && e.object != (parser.expr_node*)0) {
            // Derive enum name and variant name from e.object
            i8* enum_name    = (i8*)0;
            i8* variant_name = (i8*)0;
            parser.expr_node* obj_e = e.object;
            if (obj_e.kind == ek_member && obj_e.object != (parser.expr_node*)0 && obj_e.object.kind == ek_identifier) {
                enum_name    = obj_e.object.str_val;
                variant_name = obj_e.member_name;
            } else if (obj_e.kind == ek_identifier) {
                enum_name    = obj_e.str_val;
                variant_name = (i8*)0; // plain variant
            }
            if (enum_name != (i8*)0 && variant_name != (i8*)0) {
                i8* adt_ed_ptr = sv_map_get(&ctx.adt_enum_decls, enum_name);
                i8* enum_st    = st_map_get(&ctx.struct_types, enum_name);
                if (adt_ed_ptr != (i8*)0 && enum_st != (i8*)0) {
                    parser.enum_decl* adt_ed = (parser.enum_decl*)adt_ed_ptr;
                    // Find variant index
                    i32 var_idx = -1;
                    i32 vi = 0;
                    while (vi < adt_ed.variants_len) {
                        if (strcmp(adt_ed.variant_names[vi], variant_name) == 0) { var_idx = vi; }
                        vi = vi + 1;
                    }
                    if (var_idx >= 0) {
                        i8* alloca = LLVMBuildAlloca(ctx.llvm_builder, enum_st, "adt_finit");
                        LLVMBuildStore(ctx.llvm_builder, LLVMConstNull(enum_st), alloca);
                        // Store tag
                        i8* i32t    = LLVMInt32TypeInContext(ctx.llvm_ctx);
                        i8* tag_ptr = LLVMBuildStructGEP2(ctx.llvm_builder, enum_st, alloca, 0, "adt_tag");
                        LLVMBuildStore(ctx.llvm_builder, LLVMConstInt(i32t, (u64)var_idx, 0), tag_ptr);
                        // Store named fields into payload by looking up field order in variant metadata
                        i8 vqname[512];
                        snprintf(vqname, (u64)512, "%s__%s", enum_name, variant_name);
                        i8* pay_ptr = LLVMBuildStructGEP2(ctx.llvm_builder, enum_st, alloca, 1, "adt_pay");
                        i8* i8t = LLVMInt8TypeInContext(ctx.llvm_ctx);
                        // Compute per-field byte offsets from variant field type metadata
                        struct_meta* vsm = struct_meta_find(&ctx.struct_meta_tbl, vqname);
                        i32 fi = 0;
                        while (fi < e.field_count) {
                            i8* fname = e.field_names[fi];
                            i8* fval  = visit_expr(e.field_vals[fi], ctx);
                            if (fval != (i8*)0 && vsm != (struct_meta*)0) {
                                // Find field index in variant metadata
                                i32 field_idx = -1;
                                u64 byte_off  = 0;
                                i32 si = 0;
                                while (si < vsm.field_names.len) {
                                    if (fname != (i8*)0 && strcmp(vsm.field_names.data[si], fname) == 0) { field_idx = si; }
                                    if (field_idx < 0) {
                                        u64 fsz = llvm_type_byte_size(vsm.field_types.data[si]);
                                        byte_off = byte_off + ((fsz + 7) & ~(u64)7);
                                    }
                                    si = si + 1;
                                }
                                if (field_idx >= 0) {
                                    i8* flt   = vsm.field_types.data[field_idx];
                                    fval = coerce_int_val(fval, flt, ctx.llvm_builder);
                                    i8* idx_v = LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), byte_off, 0);
                                    i8* elem  = LLVMBuildGEP2(ctx.llvm_builder, i8t, pay_ptr, &idx_v, 1, "pay_elem");
                                    LLVMBuildStore(ctx.llvm_builder, fval, elem);
                                }
                            }
                            fi = fi + 1;
                        }
                        return LLVMBuildLoad2(ctx.llvm_builder, enum_st, alloca, "adt_val");
                    }
                }
            }
            return (i8*)0;
        }
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
                    i8* fptr   = LLVMBuildStructGEP2(ctx.llvm_builder, struct_t, alloca, fidx, fname);
                    i8* elem_t = ctx_field_type(ctx, sname, fidx);
                    if (elem_t == (i8*)0) {
                        i8* ftype = LLVMTypeOf(fptr);
                        elem_t = LLVMGetElementType(ftype);
                    }
                    if (elem_t != (i8*)0) {
                        fval = coerce_int_val(fval, elem_t, ctx.llvm_builder);
                    }
                    LLVMBuildStore(ctx.llvm_builder, fval, fptr);
                }
            }
            i = i + 1;
        }
        return LLVMBuildLoad2(ctx.llvm_builder, struct_t, alloca, "struct_val");
    }

    // Annotations: compile-time only, emit nothing
    if (kind == ek_annotation) { return (i8*)0; }

    // try expr: evaluate inner; if == -1 (error), propagate by returning -1
    if (kind == ek_try_expr) {
        if (e.operand == (parser.expr_node*)0) { return (i8*)0; }
        i8* inner = visit_expr(e.operand, ctx);
        if (inner == (i8*)0) { return (i8*)0; }
        i8* i32_t = LLVMInt32TypeInContext(ctx.llvm_ctx);
        i8* coerced = coerce_int_val(inner, i32_t, ctx.llvm_builder);
        i64 minus1 = (i64)-1;
        i8* neg1 = LLVMConstInt(i32_t, (u64)minus1, 1);
        i8* is_err = LLVMBuildICmp(ctx.llvm_builder, LLVMIntEQ, coerced, neg1, "try_is_err");
        i8* fn     = ctx.current_func;
        i8* err_bb = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "try_err");
        i8* ok_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "try_ok");
        LLVMBuildCondBr(ctx.llvm_builder, is_err, err_bb, ok_bb);
        // Error path: fire defers + errdefers, then return -1
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, err_bb);
        i32 try_di = ctx.defers.len - 1;
        while (try_di >= 0) {
            emit_deferred(&ctx.defers.data[try_di], ctx);
            try_di = try_di - 1;
        }
        i32 try_ei = ctx.errdefers.len - 1;
        while (try_ei >= 0) {
            emit_deferred(&ctx.errdefers.data[try_ei], ctx);
            try_ei = try_ei - 1;
        }
        i8* ret_t = ctx.current_ret_type != (i8*)0 ? ctx.current_ret_type : i32_t;
        LLVMBuildRet(ctx.llvm_builder, coerce_int_val(neg1, ret_t, ctx.llvm_builder));
        // OK path: yield the value
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, ok_bb);
        return coerced;
    }

    // expr except |e| { handler }: evaluate expr; if == -1, run handler; else yield value
    if (kind == ek_except_expr) {
        if (e.object == (parser.expr_node*)0) { return (i8*)0; }
        i8* inner = visit_expr(e.object, ctx);
        if (inner == (i8*)0) { return (i8*)0; }
        i8* i32_t = LLVMInt32TypeInContext(ctx.llvm_ctx);
        i8* coerced = coerce_int_val(inner, i32_t, ctx.llvm_builder);
        i64 minus1_exc = (i64)-1;
        i8* neg1 = LLVMConstInt(i32_t, (u64)minus1_exc, 1);
        i8* is_err = LLVMBuildICmp(ctx.llvm_builder, LLVMIntEQ, coerced, neg1, "exc_is_err");
        i8* fn      = ctx.current_func;
        i8* err_bb  = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "exc_err");
        i8* ok_bb   = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn, "exc_ok");
        LLVMBuildCondBr(ctx.llvm_builder, is_err, err_bb, ok_bb);
        // Error path: execute handler block
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, err_bb);
        if (e.handler_block != (i8*)0) {
            visit_except_handler(e, ctx, neg1, i32_t);
        }
        // Only branch to ok_bb if block didn't already terminate
        i8* cur_bb = LLVMGetInsertBlock(ctx.llvm_builder);
        i8* term   = LLVMGetBasicBlockTerminator(cur_bb);
        if (term == (i8*)0) { LLVMBuildBr(ctx.llvm_builder, ok_bb); }
        // OK path: yield value
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, ok_bb);
        return coerced;
    }

    return (i8*)0;
}

} // namespace ir
