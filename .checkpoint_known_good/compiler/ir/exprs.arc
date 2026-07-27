// Expression IR generation for the Artemis self-hosting compiler.

namespace ir {

// Forward declarations
fn visit_expr(e: *parser.expr_node, ctx: *ir_context) *i8;
fn visit_lvalue(e: *parser.expr_node, ctx: *ir_context) *i8;
fn visit_block_stmt(blk: *parser.block_stmt, ctx: *ir_context) void;
fn visit_match_stmt(ms: *parser.match_stmt, ctx: *ir_context) void;
fn ctx_field_pointee_struct(sm: *struct_meta, fidx: i32, ctx: *ir_context) *i8;
// Forward declarations for decls.arc functions (included after exprs.arc)
fn visit_func_decl_prototype(fd: *parser.func_decl, ctx: *ir_context) void;
fn visit_func_decl(fd: *parser.func_decl, ctx: *ir_context) void;

// Resolve the LLVM struct type and base pointer for a member-access chain.
// Works with LLVM opaque pointers by using the ir_context type tables instead
// of LLVMGetElementType (which returns null in opaque-pointer mode).
// Returns the pointer to use as base for LLVMBuildStructGEP2, and writes the
// struct type to *out_struct_type.  Returns null if the chain cannot be resolved.
fn resolve_struct_base(obj: *parser.expr_node, ctx: *ir_context, out_struct_type: **i8) *i8 {
    *out_struct_type = (i8*)0;

    if (obj.kind == ek_identifier) {
        let mut local_t: *i8= ctx_lookup_local_type(ctx, obj.str_val);
        let mut alloca: *i8= ctx_lookup_local(ctx, obj.str_val);
        if (alloca == (i8*)0 || local_t == (i8*)0) { return (i8*)0; }

        if (LLVMGetTypeKind(local_t) == LLVMStructTypeKind) {
            // Struct by value: alloca is the struct pointer
            *out_struct_type = local_t;
            return alloca;
        }
        // Pointer-to-struct: load to get the struct pointer
        let mut deref_t: *i8= ctx_lookup_deref_type(ctx, obj.str_val);
        if (deref_t != (i8*)0 && LLVMGetTypeKind(deref_t) == LLVMStructTypeKind) {
            *out_struct_type = deref_t;
            return LLVMBuildLoad2(ctx.llvm_builder, local_t, alloca, "ptr_deref");
        }
        return (i8*)0;
    }

    // (*ptr).field — explicit dereference of a pointer-to-struct
    if (obj.kind == ek_unary && obj.uop == uop_deref && obj.operand != (parser.expr_node*)0) {
        if (obj.operand.kind == ek_identifier) {
            let mut local_t: *i8= ctx_lookup_local_type(ctx, obj.operand.str_val);
            let mut alloca: *i8= ctx_lookup_local(ctx, obj.operand.str_val);
            if (alloca == (i8*)0 || local_t == (i8*)0) { return (i8*)0; }
            let mut deref_t: *i8= ctx_lookup_deref_type(ctx, obj.operand.str_val);
            if (deref_t != (i8*)0 && LLVMGetTypeKind(deref_t) == LLVMStructTypeKind) {
                *out_struct_type = deref_t;
                return LLVMBuildLoad2(ctx.llvm_builder, local_t, alloca, "ptr_deref");
            }
        }
        // (*complex_expr) — e.g. (*self.tail). Use infer_expr_struct_type to get pointee struct.
        let mut inner_st: *i8= infer_expr_struct_type(obj.operand, ctx);
        if (inner_st != (i8*)0 && LLVMGetTypeKind(inner_st) == LLVMStructTypeKind) {
            let mut inner_ptr: *i8= visit_expr(obj.operand, ctx);
            if (inner_ptr != (i8*)0) {
                *out_struct_type = inner_st;
                return inner_ptr;
            }
        }
        return (i8*)0;
    }

    // arr[i].field — array-of-struct subscript (local array or pointer-to-struct)
    if (obj.kind == ek_subscript && obj.object != (parser.expr_node*)0) {
        let mut elem_ptr: *i8= visit_lvalue(obj, ctx);
        if (elem_ptr == (i8*)0) { return (i8*)0; }
        if (obj.object.kind == ek_identifier) {
            let mut local_t: *i8= ctx_lookup_local_type(ctx, obj.object.str_val);
            if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMArrayTypeKind) {
                let mut elem_t: *i8= LLVMGetElementType(local_t);
                if (elem_t != (i8*)0 && LLVMGetTypeKind(elem_t) == LLVMStructTypeKind) {
                    *out_struct_type = elem_t;
                    return elem_ptr;
                }
            }
            // Pointer-to-struct parameter: deref_t holds the element struct type.
            let mut deref_t: *i8= ctx_lookup_deref_type(ctx, obj.object.str_val);
            if (deref_t != (i8*)0 && LLVMGetTypeKind(deref_t) == LLVMStructTypeKind) {
                *out_struct_type = deref_t;
                return elem_ptr;
            }
            // Global pointer-to-struct
            let mut gv: *i8= sv_map_get(&ctx.global_vars, obj.object.str_val);
            if (gv != (i8*)0) {
                let mut gv_t: *i8= LLVMGlobalGetValueType(gv);
                if (gv_t != (i8*)0 && LLVMGetTypeKind(gv_t) == LLVMArrayTypeKind) {
                    let mut elem_t: *i8= LLVMGetElementType(gv_t);
                    if (elem_t != (i8*)0 && LLVMGetTypeKind(elem_t) == LLVMStructTypeKind) {
                        *out_struct_type = elem_t;
                        return elem_ptr;
                    }
                }
            }
        }
        // Member access subscript: self.field[i] where field is T arr[N] or T* pointer-to-struct
        if (obj.object.kind == ek_member && obj.object.member_name != (i8*)0) {
            let mut parent_st2: *i8= infer_expr_struct_type(obj.object.object, ctx);
            if (parent_st2 != (i8*)0) {
                let mut pname2: *i8= LLVMGetStructName(parent_st2);
                if (pname2 != (i8*)0) {
                    let mut fidx3: i32= ctx_field_index(ctx, pname2, obj.object.member_name);
                    if (fidx3 >= 0) {
                        // Fixed array-of-struct field: field type is [N x T] where T is a struct
                        let mut ftype3: *i8= ctx_field_type(ctx, pname2, fidx3);
                        if (ftype3 != (i8*)0 && LLVMGetTypeKind(ftype3) == LLVMArrayTypeKind) {
                            let mut elem_t3: *i8= LLVMGetElementType(ftype3);
                            if (elem_t3 != (i8*)0 && LLVMGetTypeKind(elem_t3) == LLVMStructTypeKind) {
                                *out_struct_type = elem_t3;
                                return elem_ptr;
                            }
                        }
                        // Pointer-to-struct field (or forward-reference / double-pointer element)
                        let mut sm3: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, pname2);
                        if (sm3 != (struct_meta*)0) {
                            // Case 1: element is a struct (*json_pair → json_pair element)
                            let mut pt3: *i8= ctx_field_pointee_struct(sm3, fidx3, ctx);
                            if (pt3 != (i8*)0) {
                                *out_struct_type = pt3;
                                return elem_ptr;
                            }
                            // Case 2: element is a pointer-to-struct (**json_val → *json_val element)
                            // Load the pointer from elem_ptr to get the struct pointer.
                            if (fidx3 < sm3.field_pointee.len) {
                                let mut raw_pt3: *i8= sm3.field_pointee.data[fidx3];
                                if (raw_pt3 != (i8*)0 && LLVMGetTypeKind(raw_pt3) == LLVMPointerTypeKind) {
                                    if (fidx3 < sm3.field_pointee_names.len && sm3.field_pointee_names.data[fidx3] != (i8*)0) {
                                        let mut qname3: *i8= sm3.field_pointee_names.data[fidx3];
                                        let mut struct_t3: *i8= st_map_get(&ctx.struct_types, qname3);
                                        if (struct_t3 != (i8*)0 && LLVMGetTypeKind(struct_t3) == LLVMStructTypeKind) {
                                            let mut ptrt: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                                            let mut loaded3: *i8= LLVMBuildLoad2(ctx.llvm_builder, ptrt, elem_ptr, "arr_ptr_deref");
                                            *out_struct_type = struct_t3;
                                            return loaded3;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return (i8*)0;
    }

    if (obj.kind == ek_member) {
        let mut parent_st: *i8= (i8*)0;
        let mut parent_ptr: *i8= resolve_struct_base(obj.object, ctx, &parent_st);
        if (parent_ptr == (i8*)0 || parent_st == (i8*)0) { return (i8*)0; }

        let mut pname: *i8= LLVMGetStructName(parent_st);
        if (pname == (i8*)0) { return (i8*)0; }

        let mut fidx: i32= ctx_field_index(ctx, pname, obj.member_name);
        if (fidx < 0) {
            if (ctx.current_namespace != (i8*)0) {
                let mut ns_pname: [512]i8;
                snprintf(ns_pname, (u64)512, "%s__NS_%s", ctx.current_namespace, pname);
                fidx = ctx_field_index(ctx, ns_pname, obj.member_name);
                if (fidx >= 0) { pname = lexer.str_dup(ns_pname); parent_st = st_map_get(&ctx.struct_types, pname); }
            }
        }
        if (fidx < 0) { return (i8*)0; }

        let mut ft: *i8= ctx_field_type(ctx, pname, fidx);
        if (ft == (i8*)0) { return (i8*)0; }

        let mut gep: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, parent_st, parent_ptr, (i32)fidx, obj.member_name);

        if (LLVMGetTypeKind(ft) == LLVMStructTypeKind) {
            *out_struct_type = ft;
            return gep;
        }
        let mut sm: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, pname);
        if (sm != (struct_meta*)0 && fidx < sm.field_pointee.len) {
            let mut pt: *i8= ctx_field_pointee_struct(sm, fidx, ctx);
            if (pt != (i8*)0) {
                *out_struct_type = pt;
                return LLVMBuildLoad2(ctx.llvm_builder, ft, gep, "fld_deref");
            }
        }
        return (i8*)0;
    }

    // Note: f(...).field is not handled here. A call result has no address, and
    // visit_expr resolves the base twice for a member chain, so emitting the call
    // from this path would evaluate it twice. visit_expr handles the single-level
    // f(...).field case directly with extractvalue instead.
    return (i8*)0;
}

// Infer the struct LLVM type for an expression WITHOUT emitting any IR.
// Returns the struct type if the expression is a struct or pointer-to-struct,
// else returns null.
fn infer_expr_struct_type(e: *parser.expr_node, ctx: *ir_context) *i8 {
    if (e == (parser.expr_node*)0) { return (i8*)0; }
    if (e.kind == ek_identifier) {
        let mut local_t: *i8= ctx_lookup_local_type(ctx, e.str_val);
        if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMStructTypeKind) {
            return local_t;
        }
        let mut deref_t: *i8= ctx_lookup_deref_type(ctx, e.str_val);
        if (deref_t != (i8*)0 && LLVMGetTypeKind(deref_t) == LLVMStructTypeKind) {
            return deref_t;
        }
        return (i8*)0;
    }
    if (e.kind == ek_unary && e.uop == uop_deref && e.operand != (parser.expr_node*)0) {
        if (e.operand.kind == ek_identifier) {
            let mut deref_t: *i8= ctx_lookup_deref_type(ctx, e.operand.str_val);
            if (deref_t != (i8*)0 && LLVMGetTypeKind(deref_t) == LLVMStructTypeKind) {
                return deref_t;
            }
        }
        // For (*expr) where expr is a member/deref that yields a pointer-to-struct,
        // infer_expr_struct_type of the operand gives the pointee struct type.
        let mut inner_st: *i8= infer_expr_struct_type(e.operand, ctx);
        if (inner_st != (i8*)0 && LLVMGetTypeKind(inner_st) == LLVMStructTypeKind) {
            return inner_st;
        }
        return (i8*)0;
    }
    if (e.kind == ek_member && e.member_name != (i8*)0) {
        let mut parent_st: *i8= infer_expr_struct_type(e.object, ctx);
        if (parent_st == (i8*)0) { return (i8*)0; }
        let mut pname: *i8= LLVMGetStructName(parent_st);
        if (pname == (i8*)0) { return (i8*)0; }
        let mut fidx: i32= ctx_field_index(ctx, pname, e.member_name);
        if (fidx < 0) { return (i8*)0; }
        let mut ft: *i8= ctx_field_type(ctx, pname, fidx);
        if (ft != (i8*)0 && LLVMGetTypeKind(ft) == LLVMStructTypeKind) { return ft; }
        let mut sm: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, pname);
        if (sm != (struct_meta*)0) {
            let mut pt: *i8= ctx_field_pointee_struct(sm, fidx, ctx);
            if (pt != (i8*)0) { return pt; }
        }
        return (i8*)0;
    }
    // arr[i] where arr is an array of structs or pointer-to-struct
    if (e.kind == ek_subscript && e.object != (parser.expr_node*)0) {
        if (e.object.kind == ek_identifier) {
            let mut local_t: *i8= ctx_lookup_local_type(ctx, e.object.str_val);
            if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMArrayTypeKind) {
                let mut elem_t: *i8= LLVMGetElementType(local_t);
                if (elem_t != (i8*)0 && LLVMGetTypeKind(elem_t) == LLVMStructTypeKind) {
                    return elem_t;
                }
            }
            // ptr[i] where ptr is T* (pointer-to-struct)
            let mut deref_t_s: *i8= ctx_lookup_deref_type(ctx, e.object.str_val);
            if (deref_t_s != (i8*)0 && LLVMGetTypeKind(deref_t_s) == LLVMStructTypeKind) {
                return deref_t_s;
            }
        }
        // Member access subscript: self.field[i] where field is [N x T] array or T* pointer-to-struct
        if (e.object.kind == ek_member && e.object.member_name != (i8*)0) {
            let mut parent_st: *i8= infer_expr_struct_type(e.object.object, ctx);
            if (parent_st != (i8*)0) {
                let mut pname: *i8= LLVMGetStructName(parent_st);
                if (pname != (i8*)0) {
                    let mut fidx2: i32= ctx_field_index(ctx, pname, e.object.member_name);
                    if (fidx2 >= 0) {
                        // Fixed array-of-struct field: [N x T]
                        let mut ftype2: *i8= ctx_field_type(ctx, pname, fidx2);
                        if (ftype2 != (i8*)0 && LLVMGetTypeKind(ftype2) == LLVMArrayTypeKind) {
                            let mut elem_t2: *i8= LLVMGetElementType(ftype2);
                            if (elem_t2 != (i8*)0 && LLVMGetTypeKind(elem_t2) == LLVMStructTypeKind) { return elem_t2; }
                        }
                        // Pointer-to-struct field (with forward-reference support)
                        let mut sm2: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, pname);
                        if (sm2 != (struct_meta*)0) {
                            let mut pt2: *i8= ctx_field_pointee_struct(sm2, fidx2, ctx);
                            if (pt2 != (i8*)0) { return pt2; }
                        }
                    }
                }
            }
        }
        return (i8*)0;
    }
    // @typeinfo(T) returns *type_info — infer struct type as type_info
    if (e.kind == ek_typeinfo_e) {
        ensure_typeinfo_types(ctx);
        return st_map_get(&ctx.struct_types, "type_info");
    }
    return (i8*)0;
}

// Resolve field_pointee struct type with forward-reference support.
// For *T fields (pointer_depth=1): if field_pointee[fidx] is a struct, return it.
// If it's i8/null (forward reference), look up via field_pointee_names.
// If it's already a pointer type (pointer_depth>=2), return null — handled by caller as Case 2.
fn ctx_field_pointee_struct(sm: *struct_meta, fidx: i32, ctx: *ir_context) *i8 {
    if (sm == (struct_meta*)0 || fidx < 0 || fidx >= sm.field_pointee.len) { return (i8*)0; }
    let mut pt: *i8= sm.field_pointee.data[fidx];
    if (pt != (i8*)0 && LLVMGetTypeKind(pt) == LLVMStructTypeKind) { return pt; }
    // If field_pointee is already a pointer type (e.g. **T → *T element), skip —
    // caller should handle this as a pointer-element case (load needed).
    if (pt != (i8*)0 && LLVMGetTypeKind(pt) == LLVMPointerTypeKind) { return (i8*)0; }
    // i8 or null: forward reference to a struct (pointer_depth=1) — resolve via stored name
    if (fidx < sm.field_pointee_names.len && sm.field_pointee_names.data[fidx] != (i8*)0) {
        let mut qname: *i8= sm.field_pointee_names.data[fidx];
        let mut found: *i8= st_map_get(&ctx.struct_types, qname);
        if (found != (i8*)0 && LLVMGetTypeKind(found) == LLVMStructTypeKind) { return found; }
    }
    return (i8*)0;
}

// Helper: get the field type at index fidx from an ADT tuple variant.
// For multi-variant enums where different variants have different payload types,
// this uses the FIRST tuple variant's layout — which may be wrong at runtime if
// the enum currently holds a different variant. This is a known limitation.
fn adt_tuple_field_type(adt_ed: *parser.enum_decl, fidx: i32, ctx: *ir_context) *i8 {
    if (adt_ed == (parser.enum_decl*)0) { return (i8*)0; }
    // Count tuple variants to warn about ambiguity
    let mut tuple_variant_count: i32= 0;
    let mut first_tvi: i32= -1;
    let mut tvi: i32= 0;
    while (tvi < adt_ed.variants_len) {
        if (adt_ed.variant_kinds != (i32*)0 && adt_ed.variant_kinds[tvi] == 1) {
            if (first_tvi < 0) { first_tvi = tvi; }
            tuple_variant_count = tuple_variant_count + 1;
        }
        tvi = tvi + 1;
    }
    if (first_tvi < 0) { return (i8*)0; }
    if (tuple_variant_count > 1) {
        printf("warning: ADT subscript on multi-variant enum uses first variant layout — may be wrong for other variants\n");
    }
    let mut fc: i32= (adt_ed.variant_field_counts != (i32*)0) ? adt_ed.variant_field_counts[first_tvi] : 0;
    if (fidx >= 0 && fidx < fc && adt_ed.variant_field_type_flat != (i8**)0) {
        let mut ft: *parser.type_node= (parser.type_node*)adt_ed.variant_field_type_flat[first_tvi * 8 + fidx];
        if (ft != (parser.type_node*)0) { return llvm_type_of(ft, ctx); }
    }
    return LLVMInt32TypeInContext(ctx.llvm_ctx);
}

// Like adt_tuple_field_type but returns the raw LLVM function type (no ptr wrapper) for
// function-pointer fields — needed for LLVMBuildCall2 in opaque-pointer mode.
fn adt_tuple_field_fn_type(adt_ed: *parser.enum_decl, fidx: i32, ctx: *ir_context) *i8 {
    if (adt_ed == (parser.enum_decl*)0) { return (i8*)0; }
    let mut tvi: i32= 0;
    while (tvi < adt_ed.variants_len) {
        if (adt_ed.variant_kinds != (i32*)0 && adt_ed.variant_kinds[tvi] == 1) {
            let mut fc: i32= (adt_ed.variant_field_counts != (i32*)0) ? adt_ed.variant_field_counts[tvi] : 0;
            if (fidx >= 0 && fidx < fc && adt_ed.variant_field_type_flat != (i8**)0) {
                let mut ft2: *parser.type_node= (parser.type_node*)adt_ed.variant_field_type_flat[tvi * 8 + fidx];
                if (ft2 != (parser.type_node*)0 && ft2.is_func_ptr) {
                    return llvm_func_type_of(ft2, ctx);
                }
                if (ft2 != (parser.type_node*)0) { return llvm_type_of(ft2, ctx); }
            }
            return (i8*)0;
        }
        tvi = tvi + 1;
    }
    return (i8*)0;
}

// Get the declared element type for an lvalue expression (avoids LLVMGetElementType,
// which is broken in LLVM opaque-pointer mode).
fn lvalue_elem_type(e: *parser.expr_node, ctx: *ir_context) *i8 {
    if (e == (parser.expr_node*)0) { return (i8*)0; }
    if (e.kind == ek_identifier) {
        let mut local_t: *i8= ctx_lookup_local_type(ctx, e.str_val);
        if (local_t != (i8*)0) { return local_t; }
        // Global variable (namespace-qualified lookup)
        let mut gv: *i8= find_global_var(e.str_val, ctx);
        if (gv != (i8*)0) { return LLVMGlobalGetValueType(gv); }
        return (i8*)0;
    }
    if (e.kind == ek_unary && e.uop == uop_deref) {
        if (e.operand != (parser.expr_node*)0 && e.operand.kind == ek_identifier) {
            return ctx_lookup_deref_type(ctx, e.operand.str_val);
        }
        return (i8*)0;
    }
    if (e.kind == ek_cast && e.cast_type != (parser.type_node*)0) {
        // For (T*)expr, return the pointee type T (strips one pointer level).
        let mut ct: *parser.type_node= e.cast_type;
        if (ct.pointer_depth > 0) {
            let mut stripped: parser.type_node;
            stripped = *ct;
            stripped.pointer_depth = stripped.pointer_depth - 1;
            return llvm_type_of(&stripped, ctx);
        }
        return llvm_type_of(ct, ctx);
    }
    if (e.kind == ek_typeinfo_e) {
        ensure_typeinfo_types(ctx);
        return st_map_get(&ctx.struct_types, "type_info");
    }
    if (e.kind == ek_member && e.member_name != (i8*)0) {
        let mut struct_type: *i8= infer_expr_struct_type(e.object, ctx);
        if (struct_type == (i8*)0) { return (i8*)0; }
        let mut sname: *i8= LLVMGetStructName(struct_type);
        if (sname == (i8*)0) { return (i8*)0; }
        let mut fidx: i32= ctx_field_index(ctx, sname, e.member_name);
        if (fidx < 0) {
            if (ctx.current_namespace != (i8*)0) {
                let mut ns_sname: [512]i8;
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
            let mut local_t: *i8= ctx_lookup_local_type(ctx, e.object.operand.str_val);
            if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMStructTypeKind) {
                let mut sname: *i8= LLVMGetStructName(local_t);
                if (sname != (i8*)0) {
                    let mut adt_ed_ptr: *i8= sv_map_get(&ctx.adt_enum_decls, sname);
                    if (adt_ed_ptr != (i8*)0) {
                        let mut fidx: i32= (i32)e.index.int_val;
                        let mut ft: *i8= adt_tuple_field_type((parser.enum_decl*)adt_ed_ptr, fidx, ctx);
                        if (ft != (i8*)0) { return ft; }
                    }
                }
            }
        }
        if (e.object.kind == ek_identifier) {
            let mut local_t: *i8= ctx_lookup_local_type(ctx, e.object.str_val);
            if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMArrayTypeKind) {
                return LLVMGetElementType(local_t);
            }
            // Direct ADT enum tuple subscript or anon struct subscript: x[i]
            if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMStructTypeKind) {
                let mut sname_adt_sub: *i8= LLVMGetStructName(local_t);
                if (sname_adt_sub != (i8*)0) {
                    let mut adt_ed_sub_ptr: *i8= sv_map_get(&ctx.adt_enum_decls, sname_adt_sub);
                    if (adt_ed_sub_ptr != (i8*)0 && e.index != (parser.expr_node*)0 && e.index.kind == ek_int_lit) {
                        let mut fidx_sub: i32= (i32)e.index.int_val;
                        let mut ft_sub: *i8= adt_tuple_field_type((parser.enum_decl*)adt_ed_sub_ptr, fidx_sub, ctx);
                        if (ft_sub != (i8*)0) {
                            // Function pointer fields are stored as opaque ptr — load as ptr
                            if (LLVMGetTypeKind(ft_sub) == LLVMPointerTypeKind) { return ft_sub; }
                            return ft_sub;
                        }
                    }
                }
                // Anonymous/regular struct positional subscript: get Nth field type
                if (e.index != (parser.expr_node*)0 && e.index.kind == ek_int_lit) {
                    let mut fidx_anon: u32= (u32)e.index.int_val;
                    let mut nc_anon: u32= LLVMCountStructElementTypes(local_t);
                    if (fidx_anon < nc_anon) { return LLVMStructGetTypeAtIndex(local_t, fidx_anon); }
                }
            }
            // Global array
            let mut gv: *i8= sv_map_get(&ctx.global_vars, e.object.str_val);
            if (gv != (i8*)0) {
                let mut gv_t: *i8= LLVMGlobalGetValueType(gv);
                if (gv_t != (i8*)0 && LLVMGetTypeKind(gv_t) == LLVMArrayTypeKind) {
                    return LLVMGetElementType(gv_t);
                }
            }
            let mut deref_t: *i8= ctx_lookup_deref_type(ctx, e.object.str_val);
            if (deref_t != (i8*)0) { return deref_t; }
        } else {
            // For non-identifier objects (e.g., struct member arrays or pointer subscripts),
            // use the field/deref type of the object expression.
            let mut field_t: *i8= lvalue_elem_type(e.object, ctx);
            if (field_t != (i8*)0 && LLVMGetTypeKind(field_t) == LLVMArrayTypeKind) {
                return LLVMGetElementType(field_t);
            }
            // field_t is a pointer (opaque ptr): resolve the pointee element type
            if (field_t != (i8*)0 && LLVMGetTypeKind(field_t) == LLVMPointerTypeKind) {
                if (e.object.kind == ek_member && e.object.member_name != (i8*)0) {
                    let mut parent_st: *i8= infer_expr_struct_type(e.object.object, ctx);
                    if (parent_st != (i8*)0) {
                        let mut pname: *i8= LLVMGetStructName(parent_st);
                        if (pname != (i8*)0) {
                            let mut fidx: i32= ctx_field_index(ctx, pname, e.object.member_name);
                            if (fidx >= 0) {
                                let mut sm: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, pname);
                                if (sm != (struct_meta*)0 && fidx < sm.field_pointee.len) {
                                    let mut pt: *i8= sm.field_pointee.data[fidx];
                                    if (pt != (i8*)0) {
                                        // Pointer element (e.g. **json_val → *json_val element): keep as ptr
                                        if (LLVMGetTypeKind(pt) == LLVMPointerTypeKind) { return pt; }
                                        // Struct element or forward-ref: try struct resolution
                                        let mut fpt: *i8= ctx_field_pointee_struct(sm, fidx, ctx);
                                        if (fpt != (i8*)0) { return fpt; }
                                        return pt;
                                    }
                                    // Forward-reference: pt is null but name may resolve
                                    let mut fpt2: *i8= ctx_field_pointee_struct(sm, fidx, ctx);
                                    if (fpt2 != (i8*)0) { return fpt2; }
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
fn coerce_int_val(val: *i8, target_type: *i8, builder: *i8) *i8 {
    if (val == (i8*)0 || target_type == (i8*)0) { return val; }
    let mut val_type: *i8= LLVMTypeOf(val);
    if (val_type == target_type) { return val; }

    let mut val_kind: i32= LLVMGetTypeKind(val_type);
    let mut target_kind: i32= LLVMGetTypeKind(target_type);

    if (val_kind == LLVMIntegerTypeKind && target_kind == LLVMIntegerTypeKind) {
        let mut vw: i32= LLVMGetIntTypeWidth(val_type);
        let mut tw: i32= LLVMGetIntTypeWidth(target_type);
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
    // Function reference stored/passed as a pointer (function pointer in opaque-ptr mode).
    // In LLVM 15+ all functions are global pointers; bitcast to ptr so the verifier
    // accepts the store instruction.
    if (val_kind == LLVMFunctionTypeKind && target_kind == LLVMPointerTypeKind) {
        return LLVMBuildBitCast(builder, val, target_type, "fn2ptr");
    }
    if (llvm_is_float(val_type) && llvm_is_float(target_type)) {
        return LLVMBuildFPCast(builder, val, target_type, "fpcast");
    }
    return val;
}

// Normalize a value to i1 for use as a branch condition.
fn to_bool(val: *i8, builder: *i8, llvm_ctx: *i8) *i8 {
    if (val == (i8*)0) { return LLVMConstInt(LLVMInt1TypeInContext(llvm_ctx), 0, 0); }
    let mut vt: *i8= LLVMTypeOf(val);
    let mut kind: i32= LLVMGetTypeKind(vt);
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
// NOTE: In LLVM 15+ opaque pointer mode, pointer types are untyped — callers
// that need the struct type behind a pointer must use ctx_lookup_deref_type or
// infer_expr_struct_type instead of relying on this function.
fn get_struct_name_from_val(val: *i8) *i8 {
    if (val == (i8*)0) { return (i8*)0; }
    let mut vt: *i8= LLVMTypeOf(val);
    let mut kind: i32= LLVMGetTypeKind(vt);
    if (kind == LLVMPointerTypeKind) {
        // Opaque pointer mode: element type is not queryable from the pointer type.
        return (i8*)0;
    }
    if (kind == LLVMStructTypeKind) {
        return LLVMGetStructName(vt);
    }
    return (i8*)0;
}

// Emit a call to a function (handles arg coercion).
fn emit_call(fn_ref: *i8, fn_type: *i8, args: **i8, nargs: i32, builder: *i8) *i8 {
    return LLVMBuildCall2(builder, fn_type, fn_ref, args, nargs, "");
}

// Look up a named function, trying namespace qualification and parent namespaces.
fn find_func(name: *i8, ctx: *ir_context) *i8 {
    let mut fn_ref: *i8= sv_map_get(&ctx.global_funcs, name);
    if (fn_ref != (i8*)0) { return fn_ref; }

    if (ctx.current_namespace != (i8*)0) {
        let mut ns_work: [512]i8;
        snprintf(ns_work, (u64)512, "%s", ctx.current_namespace);
        let mut ns_len: i32= (i32)strlen(ns_work);
        while (ns_len > 0) {
            let mut ns_name: [512]i8;
            snprintf(ns_name, (u64)512, "%s__NS_%s", ns_work, name);
            fn_ref = sv_map_get(&ctx.global_funcs, ns_name);
            if (fn_ref != (i8*)0) { return fn_ref; }
            // Strip last __NS_ component to walk up to parent namespace
            let mut split: i32= -1;
            let mut ki: i32= ns_len - 1;
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
    // `using Ns;` brings Ns's functions into scope under their bare names.
    return ctx_resolve_func(ctx, name);
}

fn find_func_type(name: *i8, ctx: *ir_context) *i8 {
    let mut ft: *i8= st_map_get(&ctx.global_func_types, name);
    if (ft != (i8*)0) { return ft; }

    if (ctx.current_namespace != (i8*)0) {
        let mut ns_work2: [512]i8;
        snprintf(ns_work2, (u64)512, "%s", ctx.current_namespace);
        let mut ns_len2: i32= (i32)strlen(ns_work2);
        while (ns_len2 > 0) {
            let mut ns_name2: [512]i8;
            snprintf(ns_name2, (u64)512, "%s__NS_%s", ns_work2, name);
            ft = st_map_get(&ctx.global_func_types, ns_name2);
            if (ft != (i8*)0) { return ft; }
            let mut split2: i32= -1;
            let mut ki2: i32= ns_len2 - 1;
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
    // `using Ns;` — same prefixes as find_func, so the type matches the resolved fn.
    if (ctx.using_ns_len > 0) {
        let mut ubuf2: [512]i8;
        let mut ui2: i32= 0;
        while (ui2 < ctx.using_ns_map.len) {
            snprintf(ubuf2, (u64)512, "%s%s", ctx.using_ns_map.data[ui2].key, name);
            ft = st_map_get(&ctx.global_func_types, ubuf2);
            if (ft != (i8*)0) { return ft; }
            ui2 = ui2 + 1;
        }
    }
    return (i8*)0;
}

// Build a flattened __NS_ qualified name from a member-access chain of identifiers.
// Returns true and fills buf if every node in the chain is an ek_identifier or ek_member.
fn build_ns_name_from_chain(e: *parser.expr_node, buf: *i8, buf_size: i32) bool {
    if (e == (parser.expr_node*)0) { return false; }
    if (e.kind == ek_identifier) {
        if (e.str_val == (i8*)0) { return false; }
        snprintf(buf, (u64)buf_size, "%s", e.str_val);
        return true;
    }
    if (e.kind == ek_member && e.member_name != (i8*)0) {
        let mut prefix: [512]i8;
        if (!build_ns_name_from_chain(e.object, prefix, 512)) { return false; }
        snprintf(buf, (u64)buf_size, "%s__NS_%s", prefix, e.member_name);
        return true;
    }
    return false;
}

// ---- @typeinfo(T) support ----

// Ensure the compiler-built type_info / type_info_field / type_info_method struct types
// are registered in struct_types. Called lazily from emit_typeinfo_global so @typeinfo(T)
// works without any extern std.typeinfo; include.
fn ensure_typeinfo_types(ctx: *ir_context) void {
    let mut ptrt: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
    let mut i32t: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
    let mut i8t: *i8= LLVMInt8TypeInContext(ctx.llvm_ctx);

    if (st_map_get(&ctx.struct_types, "type_info_field") == (i8*)0) {
        let mut tif: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info_field");
        let mut tif_flds: [4]*i8; tif_flds[0]=ptrt; tif_flds[1]=i32t; tif_flds[2]=i32t; tif_flds[3]=i32t;
        LLVMStructSetBody(tif, tif_flds, 4, 0);
        st_map_set(&ctx.struct_types, "type_info_field", tif);
        st_map_set(&ctx.struct_types, "std__NS_typeinfo__NS_type_info_field", tif);
        let mut smf: struct_meta;
        smf.name = "type_info_field"; smf.is_union = false; smf.is_istruc = false;
        name_list_init(&smf.field_names); type_list_init(&smf.field_types);
        bool_list_init(&smf.field_unsigned); type_list_init(&smf.field_pointee);
        name_list_push(&smf.field_names, "name");   type_list_push(&smf.field_types, ptrt); bool_list_push(&smf.field_unsigned, false); type_list_push(&smf.field_pointee, i8t);
        name_list_push(&smf.field_names, "offset"); type_list_push(&smf.field_types, i32t); bool_list_push(&smf.field_unsigned, false); type_list_push(&smf.field_pointee, (i8*)0);
        name_list_push(&smf.field_names, "size");   type_list_push(&smf.field_types, i32t); bool_list_push(&smf.field_unsigned, false); type_list_push(&smf.field_pointee, (i8*)0);
        name_list_push(&smf.field_names, "align");  type_list_push(&smf.field_types, i32t); bool_list_push(&smf.field_unsigned, false); type_list_push(&smf.field_pointee, (i8*)0);
        struct_meta_vec_push(&ctx.struct_meta_tbl, smf);
        let mut smf2: struct_meta;
        smf2.name = "std__NS_typeinfo__NS_type_info_field"; smf2.is_union = false; smf2.is_istruc = false;
        name_list_init(&smf2.field_names); type_list_init(&smf2.field_types);
        bool_list_init(&smf2.field_unsigned); type_list_init(&smf2.field_pointee);
        name_list_push(&smf2.field_names, "name");   type_list_push(&smf2.field_types, ptrt); bool_list_push(&smf2.field_unsigned, false); type_list_push(&smf2.field_pointee, i8t);
        name_list_push(&smf2.field_names, "offset"); type_list_push(&smf2.field_types, i32t); bool_list_push(&smf2.field_unsigned, false); type_list_push(&smf2.field_pointee, (i8*)0);
        name_list_push(&smf2.field_names, "size");   type_list_push(&smf2.field_types, i32t); bool_list_push(&smf2.field_unsigned, false); type_list_push(&smf2.field_pointee, (i8*)0);
        name_list_push(&smf2.field_names, "align");  type_list_push(&smf2.field_types, i32t); bool_list_push(&smf2.field_unsigned, false); type_list_push(&smf2.field_pointee, (i8*)0);
        struct_meta_vec_push(&ctx.struct_meta_tbl, smf2);
    }
    if (st_map_get(&ctx.struct_types, "type_info_method") == (i8*)0) {
        let mut tim: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info_method");
        let mut tim_flds: [3]*i8; tim_flds[0]=ptrt; tim_flds[1]=i32t; tim_flds[2]=i32t;
        LLVMStructSetBody(tim, tim_flds, 3, 0);
        st_map_set(&ctx.struct_types, "type_info_method", tim);
        st_map_set(&ctx.struct_types, "std__NS_typeinfo__NS_type_info_method", tim);
        let mut smm: struct_meta;
        smm.name = "type_info_method"; smm.is_union = false; smm.is_istruc = false;
        name_list_init(&smm.field_names); type_list_init(&smm.field_types);
        bool_list_init(&smm.field_unsigned); type_list_init(&smm.field_pointee);
        name_list_push(&smm.field_names, "name");        type_list_push(&smm.field_types, ptrt); bool_list_push(&smm.field_unsigned, false); type_list_push(&smm.field_pointee, i8t);
        name_list_push(&smm.field_names, "param_count"); type_list_push(&smm.field_types, i32t); bool_list_push(&smm.field_unsigned, false); type_list_push(&smm.field_pointee, (i8*)0);
        name_list_push(&smm.field_names, "ret_kind");    type_list_push(&smm.field_types, i32t); bool_list_push(&smm.field_unsigned, false); type_list_push(&smm.field_pointee, (i8*)0);
        struct_meta_vec_push(&ctx.struct_meta_tbl, smm);
    }
    if (st_map_get(&ctx.struct_types, "type_info") == (i8*)0) {
        // ---- Register payload struct LLVM types for type_info ADT enum ----
        // All fields use ptr (for pointer-typed) or i64 (for integer-typed).
        let mut i64t: *i8= LLVMInt64TypeInContext(ctx.llvm_ctx);

        // Helper macro-style: register a named payload struct + struct_meta
        // type_info_int { bits: i64, is_signed: i64 }
        if (st_map_get(&ctx.struct_types, "type_info_int") == (i8*)0) {
            let mut ti_int: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info_int");
            let mut tii_flds: [2]*i8; tii_flds[0]=i64t; tii_flds[1]=i64t;
            LLVMStructSetBody(ti_int, tii_flds, 2, 0);
            st_map_set(&ctx.struct_types, "type_info_int", ti_int);
            let mut sm_tii: struct_meta;
            sm_tii.name = "type_info_int"; sm_tii.is_union = false; sm_tii.is_istruc = false;
            name_list_init(&sm_tii.field_names); type_list_init(&sm_tii.field_types);
            bool_list_init(&sm_tii.field_unsigned); type_list_init(&sm_tii.field_pointee);
            name_list_init(&sm_tii.field_pointee_names);
            name_list_push(&sm_tii.field_names, "bits");      type_list_push(&sm_tii.field_types, i64t); bool_list_push(&sm_tii.field_unsigned, false); type_list_push(&sm_tii.field_pointee, (i8*)0); name_list_push(&sm_tii.field_pointee_names, (i8*)0);
            name_list_push(&sm_tii.field_names, "is_signed"); type_list_push(&sm_tii.field_types, i64t); bool_list_push(&sm_tii.field_unsigned, false); type_list_push(&sm_tii.field_pointee, (i8*)0); name_list_push(&sm_tii.field_pointee_names, (i8*)0);
            struct_meta_vec_push(&ctx.struct_meta_tbl, sm_tii);
        }
        // type_info_float { bits: i64 }
        if (st_map_get(&ctx.struct_types, "type_info_float") == (i8*)0) {
            let mut ti_flt: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info_float");
            let mut tif2_flds: [1]*i8; tif2_flds[0]=i64t;
            LLVMStructSetBody(ti_flt, tif2_flds, 1, 0);
            st_map_set(&ctx.struct_types, "type_info_float", ti_flt);
            let mut sm_tiflt: struct_meta;
            sm_tiflt.name = "type_info_float"; sm_tiflt.is_union = false; sm_tiflt.is_istruc = false;
            name_list_init(&sm_tiflt.field_names); type_list_init(&sm_tiflt.field_types);
            bool_list_init(&sm_tiflt.field_unsigned); type_list_init(&sm_tiflt.field_pointee);
            name_list_init(&sm_tiflt.field_pointee_names);
            name_list_push(&sm_tiflt.field_names, "bits"); type_list_push(&sm_tiflt.field_types, i64t); bool_list_push(&sm_tiflt.field_unsigned, false); type_list_push(&sm_tiflt.field_pointee, (i8*)0); name_list_push(&sm_tiflt.field_pointee_names, (i8*)0);
            struct_meta_vec_push(&ctx.struct_meta_tbl, sm_tiflt);
        }
        // type_info_pointer { depth: i64, is_const: i64, child: *type_info }
        if (st_map_get(&ctx.struct_types, "type_info_pointer") == (i8*)0) {
            let mut ti_ptr2: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info_pointer");
            let mut tip_flds: [3]*i8; tip_flds[0]=i64t; tip_flds[1]=i64t; tip_flds[2]=ptrt;
            LLVMStructSetBody(ti_ptr2, tip_flds, 3, 0);
            st_map_set(&ctx.struct_types, "type_info_pointer", ti_ptr2);
            let mut sm_tip: struct_meta;
            sm_tip.name = "type_info_pointer"; sm_tip.is_union = false; sm_tip.is_istruc = false;
            name_list_init(&sm_tip.field_names); type_list_init(&sm_tip.field_types);
            bool_list_init(&sm_tip.field_unsigned); type_list_init(&sm_tip.field_pointee);
            name_list_init(&sm_tip.field_pointee_names);
            name_list_push(&sm_tip.field_names, "depth");    type_list_push(&sm_tip.field_types, i64t); bool_list_push(&sm_tip.field_unsigned, false); type_list_push(&sm_tip.field_pointee, (i8*)0); name_list_push(&sm_tip.field_pointee_names, (i8*)0);
            name_list_push(&sm_tip.field_names, "is_const"); type_list_push(&sm_tip.field_types, i64t); bool_list_push(&sm_tip.field_unsigned, false); type_list_push(&sm_tip.field_pointee, (i8*)0); name_list_push(&sm_tip.field_pointee_names, (i8*)0);
            name_list_push(&sm_tip.field_names, "child");    type_list_push(&sm_tip.field_types, ptrt); bool_list_push(&sm_tip.field_unsigned, false); type_list_push(&sm_tip.field_pointee, (i8*)0); name_list_push(&sm_tip.field_pointee_names, (i8*)0);
            struct_meta_vec_push(&ctx.struct_meta_tbl, sm_tip);
        }
        // type_info_array { len: i64, child: *type_info }
        if (st_map_get(&ctx.struct_types, "type_info_array") == (i8*)0) {
            let mut ti_arr2: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info_array");
            let mut tia_flds: [2]*i8; tia_flds[0]=i64t; tia_flds[1]=ptrt;
            LLVMStructSetBody(ti_arr2, tia_flds, 2, 0);
            st_map_set(&ctx.struct_types, "type_info_array", ti_arr2);
            let mut sm_tia: struct_meta;
            sm_tia.name = "type_info_array"; sm_tia.is_union = false; sm_tia.is_istruc = false;
            name_list_init(&sm_tia.field_names); type_list_init(&sm_tia.field_types);
            bool_list_init(&sm_tia.field_unsigned); type_list_init(&sm_tia.field_pointee);
            name_list_init(&sm_tia.field_pointee_names);
            name_list_push(&sm_tia.field_names, "len");   type_list_push(&sm_tia.field_types, i64t); bool_list_push(&sm_tia.field_unsigned, false); type_list_push(&sm_tia.field_pointee, (i8*)0); name_list_push(&sm_tia.field_pointee_names, (i8*)0);
            name_list_push(&sm_tia.field_names, "child"); type_list_push(&sm_tia.field_types, ptrt); bool_list_push(&sm_tia.field_unsigned, false); type_list_push(&sm_tia.field_pointee, (i8*)0); name_list_push(&sm_tia.field_pointee_names, (i8*)0);
            struct_meta_vec_push(&ctx.struct_meta_tbl, sm_tia);
        }
        // type_info_slice { child: *type_info, is_const: i64 }
        if (st_map_get(&ctx.struct_types, "type_info_slice") == (i8*)0) {
            let mut ti_slc: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info_slice");
            let mut tis_flds: [2]*i8; tis_flds[0]=ptrt; tis_flds[1]=i64t;
            LLVMStructSetBody(ti_slc, tis_flds, 2, 0);
            st_map_set(&ctx.struct_types, "type_info_slice", ti_slc);
            let mut sm_tis: struct_meta;
            sm_tis.name = "type_info_slice"; sm_tis.is_union = false; sm_tis.is_istruc = false;
            name_list_init(&sm_tis.field_names); type_list_init(&sm_tis.field_types);
            bool_list_init(&sm_tis.field_unsigned); type_list_init(&sm_tis.field_pointee);
            name_list_init(&sm_tis.field_pointee_names);
            name_list_push(&sm_tis.field_names, "child");    type_list_push(&sm_tis.field_types, ptrt); bool_list_push(&sm_tis.field_unsigned, false); type_list_push(&sm_tis.field_pointee, (i8*)0); name_list_push(&sm_tis.field_pointee_names, (i8*)0);
            name_list_push(&sm_tis.field_names, "is_const"); type_list_push(&sm_tis.field_types, i64t); bool_list_push(&sm_tis.field_unsigned, false); type_list_push(&sm_tis.field_pointee, (i8*)0); name_list_push(&sm_tis.field_pointee_names, (i8*)0);
            struct_meta_vec_push(&ctx.struct_meta_tbl, sm_tis);
        }
        // type_info_struct { name: ptr, fields: ptr, field_count: i64, size_bytes: i64, align_bytes: i64, is_tuple: i64, is_packed: i64 }
        if (st_map_get(&ctx.struct_types, "type_info_struct") == (i8*)0) {
            let mut ti_str: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info_struct");
            let mut tistr_flds: [7]*i8; tistr_flds[0]=ptrt; tistr_flds[1]=ptrt; tistr_flds[2]=i64t; tistr_flds[3]=i64t; tistr_flds[4]=i64t; tistr_flds[5]=i64t; tistr_flds[6]=i64t;
            LLVMStructSetBody(ti_str, tistr_flds, 7, 0);
            st_map_set(&ctx.struct_types, "type_info_struct", ti_str);
            let mut sm_tistr: struct_meta;
            sm_tistr.name = "type_info_struct"; sm_tistr.is_union = false; sm_tistr.is_istruc = false;
            name_list_init(&sm_tistr.field_names); type_list_init(&sm_tistr.field_types);
            bool_list_init(&sm_tistr.field_unsigned); type_list_init(&sm_tistr.field_pointee);
            name_list_init(&sm_tistr.field_pointee_names);
            name_list_push(&sm_tistr.field_names, "name");        type_list_push(&sm_tistr.field_types, ptrt); bool_list_push(&sm_tistr.field_unsigned, false); type_list_push(&sm_tistr.field_pointee, (i8*)0); name_list_push(&sm_tistr.field_pointee_names, (i8*)0);
            name_list_push(&sm_tistr.field_names, "fields");      type_list_push(&sm_tistr.field_types, ptrt); bool_list_push(&sm_tistr.field_unsigned, false); type_list_push(&sm_tistr.field_pointee, (i8*)0); name_list_push(&sm_tistr.field_pointee_names, (i8*)0);
            name_list_push(&sm_tistr.field_names, "field_count"); type_list_push(&sm_tistr.field_types, i64t); bool_list_push(&sm_tistr.field_unsigned, false); type_list_push(&sm_tistr.field_pointee, (i8*)0); name_list_push(&sm_tistr.field_pointee_names, (i8*)0);
            name_list_push(&sm_tistr.field_names, "size_bytes");  type_list_push(&sm_tistr.field_types, i64t); bool_list_push(&sm_tistr.field_unsigned, false); type_list_push(&sm_tistr.field_pointee, (i8*)0); name_list_push(&sm_tistr.field_pointee_names, (i8*)0);
            name_list_push(&sm_tistr.field_names, "align_bytes"); type_list_push(&sm_tistr.field_types, i64t); bool_list_push(&sm_tistr.field_unsigned, false); type_list_push(&sm_tistr.field_pointee, (i8*)0); name_list_push(&sm_tistr.field_pointee_names, (i8*)0);
            name_list_push(&sm_tistr.field_names, "is_tuple");    type_list_push(&sm_tistr.field_types, i64t); bool_list_push(&sm_tistr.field_unsigned, false); type_list_push(&sm_tistr.field_pointee, (i8*)0); name_list_push(&sm_tistr.field_pointee_names, (i8*)0);
            name_list_push(&sm_tistr.field_names, "is_packed");   type_list_push(&sm_tistr.field_types, i64t); bool_list_push(&sm_tistr.field_unsigned, false); type_list_push(&sm_tistr.field_pointee, (i8*)0); name_list_push(&sm_tistr.field_pointee_names, (i8*)0);
            struct_meta_vec_push(&ctx.struct_meta_tbl, sm_tistr);
        }
        // type_info_istruc { name: ptr, fields: ptr, field_count: i64, methods: ptr, method_count: i64, interfaces: ptr, interface_count: i64, size_bytes: i64, align_bytes: i64 }
        if (st_map_get(&ctx.struct_types, "type_info_istruc") == (i8*)0) {
            let mut ti_istr: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info_istruc");
            let mut tiis_flds: [9]*i8; tiis_flds[0]=ptrt; tiis_flds[1]=ptrt; tiis_flds[2]=i64t; tiis_flds[3]=ptrt; tiis_flds[4]=i64t; tiis_flds[5]=ptrt; tiis_flds[6]=i64t; tiis_flds[7]=i64t; tiis_flds[8]=i64t;
            LLVMStructSetBody(ti_istr, tiis_flds, 9, 0);
            st_map_set(&ctx.struct_types, "type_info_istruc", ti_istr);
            let mut sm_tiis: struct_meta;
            sm_tiis.name = "type_info_istruc"; sm_tiis.is_union = false; sm_tiis.is_istruc = false;
            name_list_init(&sm_tiis.field_names); type_list_init(&sm_tiis.field_types);
            bool_list_init(&sm_tiis.field_unsigned); type_list_init(&sm_tiis.field_pointee);
            name_list_init(&sm_tiis.field_pointee_names);
            name_list_push(&sm_tiis.field_names, "name");            type_list_push(&sm_tiis.field_types, ptrt); bool_list_push(&sm_tiis.field_unsigned, false); type_list_push(&sm_tiis.field_pointee, (i8*)0); name_list_push(&sm_tiis.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiis.field_names, "fields");          type_list_push(&sm_tiis.field_types, ptrt); bool_list_push(&sm_tiis.field_unsigned, false); type_list_push(&sm_tiis.field_pointee, (i8*)0); name_list_push(&sm_tiis.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiis.field_names, "field_count");     type_list_push(&sm_tiis.field_types, i64t); bool_list_push(&sm_tiis.field_unsigned, false); type_list_push(&sm_tiis.field_pointee, (i8*)0); name_list_push(&sm_tiis.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiis.field_names, "methods");         type_list_push(&sm_tiis.field_types, ptrt); bool_list_push(&sm_tiis.field_unsigned, false); type_list_push(&sm_tiis.field_pointee, (i8*)0); name_list_push(&sm_tiis.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiis.field_names, "method_count");    type_list_push(&sm_tiis.field_types, i64t); bool_list_push(&sm_tiis.field_unsigned, false); type_list_push(&sm_tiis.field_pointee, (i8*)0); name_list_push(&sm_tiis.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiis.field_names, "interfaces");      type_list_push(&sm_tiis.field_types, ptrt); bool_list_push(&sm_tiis.field_unsigned, false); type_list_push(&sm_tiis.field_pointee, (i8*)0); name_list_push(&sm_tiis.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiis.field_names, "interface_count"); type_list_push(&sm_tiis.field_types, i64t); bool_list_push(&sm_tiis.field_unsigned, false); type_list_push(&sm_tiis.field_pointee, (i8*)0); name_list_push(&sm_tiis.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiis.field_names, "size_bytes");      type_list_push(&sm_tiis.field_types, i64t); bool_list_push(&sm_tiis.field_unsigned, false); type_list_push(&sm_tiis.field_pointee, (i8*)0); name_list_push(&sm_tiis.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiis.field_names, "align_bytes");     type_list_push(&sm_tiis.field_types, i64t); bool_list_push(&sm_tiis.field_unsigned, false); type_list_push(&sm_tiis.field_pointee, (i8*)0); name_list_push(&sm_tiis.field_pointee_names, (i8*)0);
            struct_meta_vec_push(&ctx.struct_meta_tbl, sm_tiis);
        }
        // type_info_union { name: ptr, fields: ptr, field_count: i64, size_bytes: i64, align_bytes: i64 }
        if (st_map_get(&ctx.struct_types, "type_info_union") == (i8*)0) {
            let mut ti_uni: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info_union");
            let mut tiu_flds: [5]*i8; tiu_flds[0]=ptrt; tiu_flds[1]=ptrt; tiu_flds[2]=i64t; tiu_flds[3]=i64t; tiu_flds[4]=i64t;
            LLVMStructSetBody(ti_uni, tiu_flds, 5, 0);
            st_map_set(&ctx.struct_types, "type_info_union", ti_uni);
            let mut sm_tiu: struct_meta;
            sm_tiu.name = "type_info_union"; sm_tiu.is_union = false; sm_tiu.is_istruc = false;
            name_list_init(&sm_tiu.field_names); type_list_init(&sm_tiu.field_types);
            bool_list_init(&sm_tiu.field_unsigned); type_list_init(&sm_tiu.field_pointee);
            name_list_init(&sm_tiu.field_pointee_names);
            name_list_push(&sm_tiu.field_names, "name");        type_list_push(&sm_tiu.field_types, ptrt); bool_list_push(&sm_tiu.field_unsigned, false); type_list_push(&sm_tiu.field_pointee, (i8*)0); name_list_push(&sm_tiu.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiu.field_names, "fields");      type_list_push(&sm_tiu.field_types, ptrt); bool_list_push(&sm_tiu.field_unsigned, false); type_list_push(&sm_tiu.field_pointee, (i8*)0); name_list_push(&sm_tiu.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiu.field_names, "field_count"); type_list_push(&sm_tiu.field_types, i64t); bool_list_push(&sm_tiu.field_unsigned, false); type_list_push(&sm_tiu.field_pointee, (i8*)0); name_list_push(&sm_tiu.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiu.field_names, "size_bytes");  type_list_push(&sm_tiu.field_types, i64t); bool_list_push(&sm_tiu.field_unsigned, false); type_list_push(&sm_tiu.field_pointee, (i8*)0); name_list_push(&sm_tiu.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiu.field_names, "align_bytes"); type_list_push(&sm_tiu.field_types, i64t); bool_list_push(&sm_tiu.field_unsigned, false); type_list_push(&sm_tiu.field_pointee, (i8*)0); name_list_push(&sm_tiu.field_pointee_names, (i8*)0);
            struct_meta_vec_push(&ctx.struct_meta_tbl, sm_tiu);
        }
        // type_info_enum { name: ptr, fields: ptr, field_count: i64, is_exhaustive: i64 }
        if (st_map_get(&ctx.struct_types, "type_info_enum") == (i8*)0) {
            let mut ti_enu: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info_enum");
            let mut tie_flds: [4]*i8; tie_flds[0]=ptrt; tie_flds[1]=ptrt; tie_flds[2]=i64t; tie_flds[3]=i64t;
            LLVMStructSetBody(ti_enu, tie_flds, 4, 0);
            st_map_set(&ctx.struct_types, "type_info_enum", ti_enu);
            let mut sm_tie: struct_meta;
            sm_tie.name = "type_info_enum"; sm_tie.is_union = false; sm_tie.is_istruc = false;
            name_list_init(&sm_tie.field_names); type_list_init(&sm_tie.field_types);
            bool_list_init(&sm_tie.field_unsigned); type_list_init(&sm_tie.field_pointee);
            name_list_init(&sm_tie.field_pointee_names);
            name_list_push(&sm_tie.field_names, "name");          type_list_push(&sm_tie.field_types, ptrt); bool_list_push(&sm_tie.field_unsigned, false); type_list_push(&sm_tie.field_pointee, (i8*)0); name_list_push(&sm_tie.field_pointee_names, (i8*)0);
            name_list_push(&sm_tie.field_names, "fields");        type_list_push(&sm_tie.field_types, ptrt); bool_list_push(&sm_tie.field_unsigned, false); type_list_push(&sm_tie.field_pointee, (i8*)0); name_list_push(&sm_tie.field_pointee_names, (i8*)0);
            name_list_push(&sm_tie.field_names, "field_count");   type_list_push(&sm_tie.field_types, i64t); bool_list_push(&sm_tie.field_unsigned, false); type_list_push(&sm_tie.field_pointee, (i8*)0); name_list_push(&sm_tie.field_pointee_names, (i8*)0);
            name_list_push(&sm_tie.field_names, "is_exhaustive"); type_list_push(&sm_tie.field_types, i64t); bool_list_push(&sm_tie.field_unsigned, false); type_list_push(&sm_tie.field_pointee, (i8*)0); name_list_push(&sm_tie.field_pointee_names, (i8*)0);
            struct_meta_vec_push(&ctx.struct_meta_tbl, sm_tie);
        }
        // type_info_adt_enum { name: ptr, variants: ptr, variant_count: i64, is_exhaustive: i64 }
        if (st_map_get(&ctx.struct_types, "type_info_adt_enum") == (i8*)0) {
            let mut ti_ade: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info_adt_enum");
            let mut tiade_flds: [4]*i8; tiade_flds[0]=ptrt; tiade_flds[1]=ptrt; tiade_flds[2]=i64t; tiade_flds[3]=i64t;
            LLVMStructSetBody(ti_ade, tiade_flds, 4, 0);
            st_map_set(&ctx.struct_types, "type_info_adt_enum", ti_ade);
            let mut sm_tiade: struct_meta;
            sm_tiade.name = "type_info_adt_enum"; sm_tiade.is_union = false; sm_tiade.is_istruc = false;
            name_list_init(&sm_tiade.field_names); type_list_init(&sm_tiade.field_types);
            bool_list_init(&sm_tiade.field_unsigned); type_list_init(&sm_tiade.field_pointee);
            name_list_init(&sm_tiade.field_pointee_names);
            name_list_push(&sm_tiade.field_names, "name");          type_list_push(&sm_tiade.field_types, ptrt); bool_list_push(&sm_tiade.field_unsigned, false); type_list_push(&sm_tiade.field_pointee, (i8*)0); name_list_push(&sm_tiade.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiade.field_names, "variants");      type_list_push(&sm_tiade.field_types, ptrt); bool_list_push(&sm_tiade.field_unsigned, false); type_list_push(&sm_tiade.field_pointee, (i8*)0); name_list_push(&sm_tiade.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiade.field_names, "variant_count"); type_list_push(&sm_tiade.field_types, i64t); bool_list_push(&sm_tiade.field_unsigned, false); type_list_push(&sm_tiade.field_pointee, (i8*)0); name_list_push(&sm_tiade.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiade.field_names, "is_exhaustive"); type_list_push(&sm_tiade.field_types, i64t); bool_list_push(&sm_tiade.field_unsigned, false); type_list_push(&sm_tiade.field_pointee, (i8*)0); name_list_push(&sm_tiade.field_pointee_names, (i8*)0);
            struct_meta_vec_push(&ctx.struct_meta_tbl, sm_tiade);
        }
        // type_info_interface { name: ptr, methods: ptr, method_count: i64 }
        if (st_map_get(&ctx.struct_types, "type_info_interface") == (i8*)0) {
            let mut ti_iface: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info_interface");
            let mut tiiface_flds: [3]*i8; tiiface_flds[0]=ptrt; tiiface_flds[1]=ptrt; tiiface_flds[2]=i64t;
            LLVMStructSetBody(ti_iface, tiiface_flds, 3, 0);
            st_map_set(&ctx.struct_types, "type_info_interface", ti_iface);
            let mut sm_tiiface: struct_meta;
            sm_tiiface.name = "type_info_interface"; sm_tiiface.is_union = false; sm_tiiface.is_istruc = false;
            name_list_init(&sm_tiiface.field_names); type_list_init(&sm_tiiface.field_types);
            bool_list_init(&sm_tiiface.field_unsigned); type_list_init(&sm_tiiface.field_pointee);
            name_list_init(&sm_tiiface.field_pointee_names);
            name_list_push(&sm_tiiface.field_names, "name");         type_list_push(&sm_tiiface.field_types, ptrt); bool_list_push(&sm_tiiface.field_unsigned, false); type_list_push(&sm_tiiface.field_pointee, (i8*)0); name_list_push(&sm_tiiface.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiiface.field_names, "methods");      type_list_push(&sm_tiiface.field_types, ptrt); bool_list_push(&sm_tiiface.field_unsigned, false); type_list_push(&sm_tiiface.field_pointee, (i8*)0); name_list_push(&sm_tiiface.field_pointee_names, (i8*)0);
            name_list_push(&sm_tiiface.field_names, "method_count"); type_list_push(&sm_tiiface.field_types, i64t); bool_list_push(&sm_tiiface.field_unsigned, false); type_list_push(&sm_tiiface.field_pointee, (i8*)0); name_list_push(&sm_tiiface.field_pointee_names, (i8*)0);
            struct_meta_vec_push(&ctx.struct_meta_tbl, sm_tiiface);
        }
        // type_info_fn { params: ptr, param_count: i64, return_type: ptr, is_var_args: i64, is_pub: i64, is_generic: i64, calling_conv: i64 }
        if (st_map_get(&ctx.struct_types, "type_info_fn") == (i8*)0) {
            let mut ti_fn2: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info_fn");
            let mut tifn_flds: [7]*i8; tifn_flds[0]=ptrt; tifn_flds[1]=i64t; tifn_flds[2]=ptrt; tifn_flds[3]=i64t; tifn_flds[4]=i64t; tifn_flds[5]=i64t; tifn_flds[6]=i64t;
            LLVMStructSetBody(ti_fn2, tifn_flds, 7, 0);
            st_map_set(&ctx.struct_types, "type_info_fn", ti_fn2);
            let mut sm_tifn: struct_meta;
            sm_tifn.name = "type_info_fn"; sm_tifn.is_union = false; sm_tifn.is_istruc = false;
            name_list_init(&sm_tifn.field_names); type_list_init(&sm_tifn.field_types);
            bool_list_init(&sm_tifn.field_unsigned); type_list_init(&sm_tifn.field_pointee);
            name_list_init(&sm_tifn.field_pointee_names);
            name_list_push(&sm_tifn.field_names, "params");       type_list_push(&sm_tifn.field_types, ptrt); bool_list_push(&sm_tifn.field_unsigned, false); type_list_push(&sm_tifn.field_pointee, (i8*)0); name_list_push(&sm_tifn.field_pointee_names, (i8*)0);
            name_list_push(&sm_tifn.field_names, "param_count");  type_list_push(&sm_tifn.field_types, i64t); bool_list_push(&sm_tifn.field_unsigned, false); type_list_push(&sm_tifn.field_pointee, (i8*)0); name_list_push(&sm_tifn.field_pointee_names, (i8*)0);
            name_list_push(&sm_tifn.field_names, "return_type");  type_list_push(&sm_tifn.field_types, ptrt); bool_list_push(&sm_tifn.field_unsigned, false); type_list_push(&sm_tifn.field_pointee, (i8*)0); name_list_push(&sm_tifn.field_pointee_names, (i8*)0);
            name_list_push(&sm_tifn.field_names, "is_var_args");  type_list_push(&sm_tifn.field_types, i64t); bool_list_push(&sm_tifn.field_unsigned, false); type_list_push(&sm_tifn.field_pointee, (i8*)0); name_list_push(&sm_tifn.field_pointee_names, (i8*)0);
            name_list_push(&sm_tifn.field_names, "is_pub");       type_list_push(&sm_tifn.field_types, i64t); bool_list_push(&sm_tifn.field_unsigned, false); type_list_push(&sm_tifn.field_pointee, (i8*)0); name_list_push(&sm_tifn.field_pointee_names, (i8*)0);
            name_list_push(&sm_tifn.field_names, "is_generic");   type_list_push(&sm_tifn.field_types, i64t); bool_list_push(&sm_tifn.field_unsigned, false); type_list_push(&sm_tifn.field_pointee, (i8*)0); name_list_push(&sm_tifn.field_pointee_names, (i8*)0);
            name_list_push(&sm_tifn.field_names, "calling_conv"); type_list_push(&sm_tifn.field_types, i64t); bool_list_push(&sm_tifn.field_unsigned, false); type_list_push(&sm_tifn.field_pointee, (i8*)0); name_list_push(&sm_tifn.field_pointee_names, (i8*)0);
            struct_meta_vec_push(&ctx.struct_meta_tbl, sm_tifn);
        }
        // type_info_error_union { payload: *type_info }
        if (st_map_get(&ctx.struct_types, "type_info_error_union") == (i8*)0) {
            let mut ti_eu: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info_error_union");
            let mut tieu_flds: [1]*i8; tieu_flds[0]=ptrt;
            LLVMStructSetBody(ti_eu, tieu_flds, 1, 0);
            st_map_set(&ctx.struct_types, "type_info_error_union", ti_eu);
            let mut sm_tieu: struct_meta;
            sm_tieu.name = "type_info_error_union"; sm_tieu.is_union = false; sm_tieu.is_istruc = false;
            name_list_init(&sm_tieu.field_names); type_list_init(&sm_tieu.field_types);
            bool_list_init(&sm_tieu.field_unsigned); type_list_init(&sm_tieu.field_pointee);
            name_list_init(&sm_tieu.field_pointee_names);
            name_list_push(&sm_tieu.field_names, "payload"); type_list_push(&sm_tieu.field_types, ptrt); bool_list_push(&sm_tieu.field_unsigned, false); type_list_push(&sm_tieu.field_pointee, (i8*)0); name_list_push(&sm_tieu.field_pointee_names, (i8*)0);
            struct_meta_vec_push(&ctx.struct_meta_tbl, sm_tieu);
        }
        // type_info_optional { child: *type_info }
        if (st_map_get(&ctx.struct_types, "type_info_optional") == (i8*)0) {
            let mut ti_opt: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info_optional");
            let mut tiopt_flds: [1]*i8; tiopt_flds[0]=ptrt;
            LLVMStructSetBody(ti_opt, tiopt_flds, 1, 0);
            st_map_set(&ctx.struct_types, "type_info_optional", ti_opt);
            let mut sm_tiopt: struct_meta;
            sm_tiopt.name = "type_info_optional"; sm_tiopt.is_union = false; sm_tiopt.is_istruc = false;
            name_list_init(&sm_tiopt.field_names); type_list_init(&sm_tiopt.field_types);
            bool_list_init(&sm_tiopt.field_unsigned); type_list_init(&sm_tiopt.field_pointee);
            name_list_init(&sm_tiopt.field_pointee_names);
            name_list_push(&sm_tiopt.field_names, "child"); type_list_push(&sm_tiopt.field_types, ptrt); bool_list_push(&sm_tiopt.field_unsigned, false); type_list_push(&sm_tiopt.field_pointee, (i8*)0); name_list_push(&sm_tiopt.field_pointee_names, (i8*)0);
            struct_meta_vec_push(&ctx.struct_meta_tbl, sm_tiopt);
        }

        // ---- Register type_info as ADT enum: { i32 tag, [72 x i8] payload } ----
        let mut i8arr72_t: *i8= LLVMArrayType2(i8t, 72);
        let mut ti_adt: *i8= LLVMStructCreateNamed(ctx.llvm_ctx, "type_info");
        let mut ti_adt_flds: [2]*i8; ti_adt_flds[0]=i32t; ti_adt_flds[1]=i8arr72_t;
        LLVMStructSetBody(ti_adt, ti_adt_flds, 2, 0);
        st_map_set(&ctx.struct_types, "type_info", ti_adt);
        st_map_set(&ctx.struct_types, "std__NS_typeinfo__NS_type_info", ti_adt);
        // struct_meta for type_info: __tag (i32) + __payload ([72 x i8])
        let mut smti_names: [2]*i8;
        smti_names[0] = "type_info";
        smti_names[1] = "std__NS_typeinfo__NS_type_info";
        let mut sni: i32= 0;
        while (sni < 2) {
            let mut smti: struct_meta;
            smti.name = smti_names[sni]; smti.is_union = false; smti.is_istruc = false;
            name_list_init(&smti.field_names); type_list_init(&smti.field_types);
            bool_list_init(&smti.field_unsigned); type_list_init(&smti.field_pointee);
            name_list_init(&smti.field_pointee_names);
            name_list_push(&smti.field_names, "__tag");     type_list_push(&smti.field_types, i32t);      bool_list_push(&smti.field_unsigned, false); type_list_push(&smti.field_pointee, (i8*)0); name_list_push(&smti.field_pointee_names, (i8*)0);
            name_list_push(&smti.field_names, "__payload"); type_list_push(&smti.field_types, i8arr72_t); bool_list_push(&smti.field_unsigned, false); type_list_push(&smti.field_pointee, (i8*)0); name_list_push(&smti.field_pointee_names, (i8*)0);
            struct_meta_vec_push(&ctx.struct_meta_tbl, smti);
            sni = sni + 1;
        }

        // ---- Register variant tag constants and alias struct types ----
        // Variant tag constants: type_info__Void=0, type_info__Bool=1, ...
        // Variant struct aliases: type_info__Int → type_info_int LLVM type + struct_meta
        //
        // Variant list: name, tag_value, payload_struct_name (null = unit variant)
        // 23 variants total.
        let mut var_names: [23]*i8;
        var_names[0]  = "Void";       var_names[1]  = "Bool";
        var_names[2]  = "Int";        var_names[3]  = "Uint";
        var_names[4]  = "Float";      var_names[5]  = "Char";
        var_names[6]  = "Usize";      var_names[7]  = "Isize";
        var_names[8]  = "Iofs";       var_names[9]  = "Pointer";
        var_names[10] = "Array";      var_names[11] = "Slice";
        var_names[12] = "Struct";     var_names[13] = "Istruc";
        var_names[14] = "Union";      var_names[15] = "Enum";
        var_names[16] = "AdtEnum";    var_names[17] = "Interface";
        var_names[18] = "Fn";         var_names[19] = "Lambda";
        var_names[20] = "ErrorUnion"; var_names[21] = "Optional";
        var_names[22] = "AnyType";
        // Payload struct names (null = unit/no payload)
        let mut pay_names: [23]*i8;
        pay_names[0]  = (i8*)0;               // Void
        pay_names[1]  = (i8*)0;               // Bool
        pay_names[2]  = "type_info_int";      // Int
        pay_names[3]  = "type_info_int";      // Uint (same payload as Int)
        pay_names[4]  = "type_info_float";    // Float
        pay_names[5]  = (i8*)0;               // Char
        pay_names[6]  = (i8*)0;               // Usize
        pay_names[7]  = (i8*)0;               // Isize
        pay_names[8]  = (i8*)0;               // Iofs
        pay_names[9]  = "type_info_pointer";  // Pointer
        pay_names[10] = "type_info_array";    // Array
        pay_names[11] = "type_info_slice";    // Slice
        pay_names[12] = "type_info_struct";   // Struct
        pay_names[13] = "type_info_istruc";   // Istruc
        pay_names[14] = "type_info_union";    // Union
        pay_names[15] = "type_info_enum";     // Enum
        pay_names[16] = "type_info_adt_enum"; // AdtEnum
        pay_names[17] = "type_info_interface";// Interface
        pay_names[18] = "type_info_fn";       // Fn
        pay_names[19] = "type_info_fn";       // Lambda (same as Fn)
        pay_names[20] = "type_info_error_union"; // ErrorUnion
        pay_names[21] = "type_info_optional"; // Optional
        pay_names[22] = (i8*)0;               // AnyType
        let mut vi2: i32= 0;
        while (vi2 < 23) {
            // Register tag constant: type_info__VarName and type_info__NS_VarName
            let mut tag_qname: [512]i8;
            snprintf(tag_qname, (u64)512, "type_info__%s", var_names[vi2]);
            let mut tag_gv: *i8= LLVMAddGlobal(ctx.llvm_mod, i32t, tag_qname);
            LLVMSetInitializer(tag_gv, LLVMConstInt(i32t, (u64)vi2, 0));
            LLVMSetGlobalConstant(tag_gv, 1);
            LLVMSetLinkage(tag_gv, LLVMInternalLinkage);
            sv_map_set(&ctx.global_vars, lexer.str_dup(tag_qname), tag_gv);
            sv_map_set(&ctx.global_vars, var_names[vi2], tag_gv);
            let mut tag_ns_qname: [512]i8;
            snprintf(tag_ns_qname, (u64)512, "type_info__NS_%s", var_names[vi2]);
            sv_map_set(&ctx.global_vars, lexer.str_dup(tag_ns_qname), tag_gv);
            // Register variant alias struct type in ctx.struct_types
            if (pay_names[vi2] != (i8*)0) {
                let mut pay_ty: *i8= st_map_get(&ctx.struct_types, pay_names[vi2]);
                if (pay_ty != (i8*)0) {
                    st_map_set(&ctx.struct_types, lexer.str_dup(tag_qname), pay_ty);
                    // Register struct_meta alias for variant (e.g. "type_info__Int")
                    let mut base_sm: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, pay_names[vi2]);
                    if (base_sm != (struct_meta*)0) {
                        let mut alias_sm: struct_meta;
                        alias_sm.name = lexer.str_dup(tag_qname);
                        alias_sm.is_union = base_sm.is_union;
                        alias_sm.is_istruc = base_sm.is_istruc;
                        alias_sm.field_names = base_sm.field_names;
                        alias_sm.field_types = base_sm.field_types;
                        alias_sm.field_unsigned = base_sm.field_unsigned;
                        alias_sm.field_pointee = base_sm.field_pointee;
                        alias_sm.field_pointee_names = base_sm.field_pointee_names;
                        struct_meta_vec_push(&ctx.struct_meta_tbl, alias_sm);
                    }
                }
            }
            vi2 = vi2 + 1;
        }

        // ---- Register fake parser.enum_decl for ctx.adt_enum_decls ----
        // This allows @typeinfo lookups on type_info itself to find it as an enum,
        // and enables any code that checks sv_map_get(&ctx.adt_enum_decls, "type_info").
        if (!sv_map_has(&ctx.adt_enum_decls, "type_info")) {
            let mut fake_ed: *parser.enum_decl= (parser.enum_decl*)arc_malloc(sizeof(parser__NS_enum_decl));
            memset((i8*)fake_ed, 0, sizeof(parser__NS_enum_decl));
            fake_ed.name = "type_info";
            fake_ed.is_adt = true;
            fake_ed.variants_len = 23;
            fake_ed.variants_cap = 23;
            fake_ed.variant_names = (i8**)arc_malloc(sizeof(i8*) * (u64)23);
            fake_ed.variant_vals  = (i64*)arc_malloc(sizeof(i64) * (u64)23);
            fake_ed.variant_has_val = (bool*)arc_malloc(sizeof(bool) * (u64)23);
            let mut vni: i32= 0;
            while (vni < 23) {
                fake_ed.variant_names[vni] = var_names[vni];
                fake_ed.variant_vals[vni]  = (i64)vni;
                fake_ed.variant_has_val[vni] = false;
                vni = vni + 1;
            }
            sv_map_set(&ctx.adt_enum_decls, "type_info", (i8*)fake_ed);
        }
    }
}

fn typeinfo_type_name(t: *parser.type_node, buf: *i8, buf_size: i32) void {
    if (t == (parser.type_node*)0) { snprintf(buf, (u64)buf_size, "void"); return; }
    // Array type: generates name like "i32_5arr"
    if (t.array_size_ptr != (i8*)0) {
        let mut sz_expr: *parser.expr_node= (parser.expr_node*)t.array_size_ptr;
        let mut n: i32= (sz_expr.kind == ek_int_lit) ? (i32)sz_expr.int_val : 0;
        let mut base_tn: parser.type_node;
        base_tn = *t;
        base_tn.array_size_ptr = (i8*)0;
        let mut base_buf: [128]i8;
        typeinfo_type_name(&base_tn, base_buf, 128);
        snprintf(buf, (u64)buf_size, "%s_%darr", base_buf, n);
        return;
    }
    // Function pointer type
    if (t.is_func_ptr) {
        snprintf(buf, (u64)buf_size, "fnptr");
        return;
    }
    if (t.is_primitive && t.has_prim) {
        let mut p: i32= t.prim;
        let mut bw: u32= t.bit_width;
        let mut bits: i32= (i32)(bw == 0 ? (u32)32 : bw);
        if (p == (i32)void_t)    { snprintf(buf, (u64)buf_size, "void"); }
        else if (p == (i32)char_t)    { snprintf(buf, (u64)buf_size, "i8"); }
        else if (p == (i32)arb_int)   { snprintf(buf, (u64)buf_size, "i%d", bits); }
        else if (p == (i32)arb_uint)  { snprintf(buf, (u64)buf_size, "u%d", bits); }
        else if (p == (i32)arb_bool)  { snprintf(buf, (u64)buf_size, "b%d", bits); }
        else if (p == (i32)arb_float) { snprintf(buf, (u64)buf_size, "f%d", bits); }
        else { snprintf(buf, (u64)buf_size, "prim"); }
    } else if (t.name != (i8*)0) {
        snprintf(buf, (u64)buf_size, "%s", t.name);
    } else {
        snprintf(buf, (u64)buf_size, "unknown");
    }
    let mut pd: i32= t.pointer_depth;
    while (pd > 0) {
        let mut curlen: i32= (i32)strlen(buf);
        if (curlen + 1 < buf_size) { buf[curlen] = 'p'; buf[curlen + 1] = 0; }
        pd = pd - 1;
    }
}

fn make_typeinfo_str_global(str_val: *i8, gname: *i8, ctx: *ir_context) *i8 {
    let mut existing_sg: *i8= LLVMGetNamedGlobal(ctx.llvm_mod, gname);
    if (existing_sg != (i8*)0) { return existing_sg; }
    let mut slen: u32= (u32)strlen(str_val);
    let mut sc: *i8= LLVMConstStringInContext(ctx.llvm_ctx, str_val, slen, 0);
    let mut sty: *i8= LLVMTypeOf(sc);
    let mut sgv: *i8= LLVMAddGlobal(ctx.llvm_mod, sty, gname);
    LLVMSetInitializer(sgv, sc);
    LLVMSetGlobalConstant(sgv, 1);
    return sgv;
}

// Get or create the __artemis_init_typeinfo function.
// If newly created, its entry block has NO terminator yet (caller adds ret void via ir_main).
fn get_or_create_typeinfo_init_fn(ctx: *ir_context) *i8 {
    let mut fn_v: *i8= LLVMGetNamedFunction(ctx.llvm_mod, "__artemis_init_typeinfo");
    if (fn_v != (i8*)0) { return fn_v; }
    let mut void_t: *i8= LLVMVoidTypeInContext(ctx.llvm_ctx);
    let mut fn_ty: *i8= LLVMFunctionType(void_t, (i8**)0, 0, 0);
    fn_v = LLVMAddFunction(ctx.llvm_mod, "__artemis_init_typeinfo", fn_ty);
    LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_v, "entry");
    return fn_v;
}

// Append stores to __artemis_init_typeinfo to fill a type_info global.
// tag: variant tag (0-22)
// For each i64 payload field: byte_offset (from start of payload) and value.
// For each pointer payload field: byte_offset and LLVM value pointer.
// Call this once per type_info global during emit_typeinfo_global.
fn typeinfo_init_store_i64(ctx: *ir_context, gv: *i8, tag: i32, byte_off: i32, val: i64) void {
    let mut fn_v: *i8= get_or_create_typeinfo_init_fn(ctx);
    let mut entry_bb: *i8= LLVMGetFirstBasicBlock(fn_v);
    if (entry_bb == (i8*)0) { return; }
    let mut b: *i8= LLVMCreateBuilderInContext(ctx.llvm_ctx);
    let mut term: *i8= LLVMGetBasicBlockTerminator(entry_bb);
    if (term != (i8*)0) {
        LLVMPositionBuilderBefore(b, term);
    } else {
        LLVMPositionBuilderAtEnd(b, entry_bb);
    }
    let mut ti_ty: *i8= st_map_get(&ctx.struct_types, "type_info");
    let mut i32t: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
    let mut i64t: *i8= LLVMInt64TypeInContext(ctx.llvm_ctx);
    let mut i8t2: *i8= LLVMInt8TypeInContext(ctx.llvm_ctx);
    // Store tag
    let mut tag_ptr: *i8= LLVMBuildStructGEP2(b, ti_ty, gv, 0, "tag_ptr");
    LLVMBuildStore(b, LLVMConstInt(i32t, (u64)tag, 0), tag_ptr);
    // Store i64 value at byte_off in payload
    let mut pay_ptr: *i8= LLVMBuildStructGEP2(b, ti_ty, gv, 1, "pay_ptr");
    let mut idx64: *i8= LLVMConstInt(i64t, (u64)byte_off, 0);
    let mut fptr: *i8= LLVMBuildGEP2(b, i8t2, pay_ptr, &idx64, 1, "fp");
    let mut store_v: *i8= LLVMBuildStore(b, LLVMConstInt(i64t, (u64)val, 0), fptr);
    LLVMSetAlignment(store_v, 8);
    LLVMDisposeBuilder(b);
}

fn typeinfo_init_store_ptr(ctx: *ir_context, gv: *i8, tag: i32, byte_off: i32, ptr_val: *i8) void {
    if (ptr_val == (i8*)0) { return; }
    let mut fn_v: *i8= get_or_create_typeinfo_init_fn(ctx);
    let mut entry_bb: *i8= LLVMGetFirstBasicBlock(fn_v);
    if (entry_bb == (i8*)0) { return; }
    let mut b: *i8= LLVMCreateBuilderInContext(ctx.llvm_ctx);
    let mut term: *i8= LLVMGetBasicBlockTerminator(entry_bb);
    if (term != (i8*)0) {
        LLVMPositionBuilderBefore(b, term);
    } else {
        LLVMPositionBuilderAtEnd(b, entry_bb);
    }
    let mut ti_ty: *i8= st_map_get(&ctx.struct_types, "type_info");
    let mut i32t: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
    let mut i64t: *i8= LLVMInt64TypeInContext(ctx.llvm_ctx);
    let mut i8t2: *i8= LLVMInt8TypeInContext(ctx.llvm_ctx);
    // Store tag
    let mut tag_ptr: *i8= LLVMBuildStructGEP2(b, ti_ty, gv, 0, "tag_ptr");
    LLVMBuildStore(b, LLVMConstInt(i32t, (u64)tag, 0), tag_ptr);
    // Store pointer at byte_off in payload
    let mut pay_ptr: *i8= LLVMBuildStructGEP2(b, ti_ty, gv, 1, "pay_ptr");
    let mut idx64: *i8= LLVMConstInt(i64t, (u64)byte_off, 0);
    let mut fptr: *i8= LLVMBuildGEP2(b, i8t2, pay_ptr, &idx64, 1, "fp");
    let mut store_v: *i8= LLVMBuildStore(b, ptr_val, fptr);
    LLVMSetAlignment(store_v, 8);
    LLVMDisposeBuilder(b);
}

// Emit or create just the tag-only store (no payload).
fn typeinfo_init_tag_only(ctx: *ir_context, gv: *i8, tag: i32) void {
    let mut fn_v: *i8= get_or_create_typeinfo_init_fn(ctx);
    let mut entry_bb: *i8= LLVMGetFirstBasicBlock(fn_v);
    if (entry_bb == (i8*)0) { return; }
    let mut b: *i8= LLVMCreateBuilderInContext(ctx.llvm_ctx);
    let mut term: *i8= LLVMGetBasicBlockTerminator(entry_bb);
    if (term != (i8*)0) {
        LLVMPositionBuilderBefore(b, term);
    } else {
        LLVMPositionBuilderAtEnd(b, entry_bb);
    }
    let mut ti_ty: *i8= st_map_get(&ctx.struct_types, "type_info");
    let mut i32t: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
    let mut tag_ptr: *i8= LLVMBuildStructGEP2(b, ti_ty, gv, 0, "tag_ptr");
    LLVMBuildStore(b, LLVMConstInt(i32t, (u64)tag, 0), tag_ptr);
    LLVMDisposeBuilder(b);
}

fn emit_typeinfo_global(t: *parser.type_node, ctx: *ir_context) *i8 {
    if (t == (parser.type_node*)0) { return (i8*)0; }

    let mut tname: [256]i8;
    typeinfo_type_name(t, tname, 256);
    let mut gname: [512]i8;
    snprintf(gname, (u64)512, "__typeinfo_%s", tname);

    let mut existing_ti: *i8= LLVMGetNamedGlobal(ctx.llvm_mod, gname);
    if (existing_ti != (i8*)0) { return existing_ti; }

    ensure_typeinfo_types(ctx);
    let mut ti_ty: *i8= st_map_get(&ctx.struct_types, "type_info");
    let mut tif_ty: *i8= st_map_get(&ctx.struct_types, "type_info_field");

    let mut i32ty: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
    let mut i8pty: *i8= LLVMPointerType(LLVMInt8TypeInContext(ctx.llvm_ctx), 0);
    let mut null_ptr: *i8= LLVMConstNull(i8pty);

    // Create the global with zeroinitializer; init function fills in the fields.
    let mut gname_dup: *i8= lexer.str_dup(gname);
    let mut gv: *i8= LLVMAddGlobal(ctx.llvm_mod, ti_ty, gname_dup);
    LLVMSetInitializer(gv, LLVMConstNull(ti_ty));
    // NOT global constant — init function writes to it
    LLVMSetGlobalConstant(gv, 0);

    // Determine variant tag and payload contents based on the type.
    // Tags: Void=0, Bool=1, Int=2, Uint=3, Float=4, Char=5, Usize=6, Isize=7, Iofs=8,
    //       Pointer=9, Array=10, Slice=11, Struct=12, Istruc=13, Union=14,
    //       Enum=15, AdtEnum=16, Interface=17, Fn=18, Lambda=19,
    //       ErrorUnion=20, Optional=21, AnyType=22

    if (t.pointer_depth > 0) {
        // Pointer variant (tag=9): type_info_pointer { depth: i64, is_const: i64, child: *type_info }
        let mut depth_val: i64= (i64)t.pointer_depth;
        let mut is_const_v: i64= t.ptr_data_const ? 1 : 0;
        let mut elem_tn: parser.type_node;
        elem_tn = *t;
        elem_tn.pointer_depth = t.pointer_depth - 1;
        let mut elem_gv: *i8= emit_typeinfo_global(&elem_tn, ctx);
        typeinfo_init_store_i64(ctx, gv, 9, 0,  depth_val);
        typeinfo_init_store_i64(ctx, gv, 9, 8,  is_const_v);
        if (elem_gv != (i8*)0) { typeinfo_init_store_ptr(ctx, gv, 9, 16, elem_gv); }
    } else if (t.array_size_ptr != (i8*)0) {
        // Array variant (tag=10): type_info_array { len: i64, child: *type_info }
        let mut sz_expr: *parser.expr_node= (parser.expr_node*)t.array_size_ptr;
        let mut n: i64= 0;
        if (sz_expr.kind == ek_int_lit) { n = (i64)sz_expr.int_val; }
        let mut base_tn: parser.type_node;
        base_tn = *t;
        base_tn.array_size_ptr = (i8*)0;
        let mut elem_gv2: *i8= emit_typeinfo_global(&base_tn, ctx);
        typeinfo_init_store_i64(ctx, gv, 10, 0, n);
        if (elem_gv2 != (i8*)0) { typeinfo_init_store_ptr(ctx, gv, 10, 8, elem_gv2); }
    } else if (t.is_func_ptr) {
        // Fn variant (tag=18): type_info_fn
        // payload field byte offsets: params=0, param_count=8, return_type=16, is_var_args=24, ...
        let mut pc: i64= (i64)t.fp_params_len;
        let mut is_va: i64= t.fp_variadic ? 1 : 0;
        typeinfo_init_store_i64(ctx, gv, 18, 8, pc);
        typeinfo_init_store_i64(ctx, gv, 18, 24, is_va);
    } else if (t.is_primitive && t.has_prim) {
        let mut p: i32= t.prim;
        let mut bw: u32= t.bit_width;
        if (p == (i32)void_t) {
            // Void variant (tag=0): no payload
            typeinfo_init_tag_only(ctx, gv, 0);
        } else if (p == (i32)char_t) {
            // Char variant (tag=5): no payload (char is Char, not Int)
            typeinfo_init_tag_only(ctx, gv, 5);
        } else if (p == (i32)arb_bool) {
            // Bool variant (tag=1): no payload
            typeinfo_init_tag_only(ctx, gv, 1);
        } else if (p == (i32)arb_int) {
            // Int variant (tag=2): type_info_int { bits: i64, is_signed: i64 }
            let mut bits_v: i64= (i64)(bw == 0 ? (u32)32 : bw);
            typeinfo_init_store_i64(ctx, gv, 2, 0, bits_v);
            typeinfo_init_store_i64(ctx, gv, 2, 8, 1);  // is_signed=1
        } else if (p == (i32)arb_uint) {
            // Uint variant (tag=3): type_info_int { bits: i64, is_signed: i64 }
            let mut bits_v2: i64= (i64)(bw == 0 ? (u32)32 : bw);
            typeinfo_init_store_i64(ctx, gv, 3, 0, bits_v2);
            typeinfo_init_store_i64(ctx, gv, 3, 8, 0);  // is_signed=0
        } else if (p == (i32)arb_float) {
            // Float variant (tag=4): type_info_float { bits: i64 }
            let mut bits_v3: i64= (i64)(bw == 0 ? (u32)64 : bw);
            typeinfo_init_store_i64(ctx, gv, 4, 0, bits_v3);
        } else if (p == (i32)arb_usize) {
            // Usize variant (tag=6): no payload
            typeinfo_init_tag_only(ctx, gv, 6);
        } else if (p == (i32)arb_isize) {
            // Isize variant (tag=7): no payload
            typeinfo_init_tag_only(ctx, gv, 7);
        } else if (p == (i32)arb_iofs) {
            // Iofs variant (tag=8): no payload
            typeinfo_init_tag_only(ctx, gv, 8);
        } else {
            // Unknown primitive: use Void
            typeinfo_init_tag_only(ctx, gv, 0);
        }
    } else if (t.name != (i8*)0) {
        // Named type: struct, istruc, union, enum, ADT enum
        // Check if usize/isize/iofs by name
        if (strcmp(t.name, "usize") == 0) {
            typeinfo_init_tag_only(ctx, gv, 6);
        } else if (strcmp(t.name, "isize") == 0) {
            typeinfo_init_tag_only(ctx, gv, 7);
        } else if (strcmp(t.name, "iofs") == 0) {
            typeinfo_init_tag_only(ctx, gv, 8);
        } else {
            // Check for ADT enum first
            let mut adt_ed_ti: *i8= sv_map_get(&ctx.adt_enum_decls, t.name);
            if (adt_ed_ti != (i8*)0) {
                let mut enum_d: *parser.enum_decl= (parser.enum_decl*)adt_ed_ti;
                if (enum_d.is_adt) {
                    // AdtEnum variant (tag=16): type_info_adt_enum { name, variants, variant_count, is_exhaustive }
                    let mut name_gname2: [512]i8;
                    snprintf(name_gname2, (u64)512, "__typeinfo_nm_%s", tname);
                    let mut name_gv2: *i8= make_typeinfo_str_global(t.name, name_gname2, ctx);
                    typeinfo_init_store_ptr(ctx, gv, 16, 0, name_gv2);
                    typeinfo_init_store_i64(ctx, gv, 16, 16, (i64)enum_d.variants_len);
                    typeinfo_init_store_i64(ctx, gv, 16, 24, 1);  // is_exhaustive=1
                } else {
                    // Simple Enum variant (tag=15): type_info_enum { name, fields, field_count, is_exhaustive }
                    let mut name_gname3: [512]i8;
                    snprintf(name_gname3, (u64)512, "__typeinfo_nm_%s", tname);
                    let mut name_gv3: *i8= make_typeinfo_str_global(t.name, name_gname3, ctx);
                    typeinfo_init_store_ptr(ctx, gv, 15, 0, name_gv3);
                    typeinfo_init_store_i64(ctx, gv, 15, 16, (i64)enum_d.variants_len);
                    typeinfo_init_store_i64(ctx, gv, 15, 24, 1);  // is_exhaustive=1
                }
            } else {
                // Check struct/istruc/union meta
                let mut sm_ti: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, t.name);
                if (sm_ti != (struct_meta*)0) {
                    let mut tag_v: i32= sm_ti.is_istruc ? 13 : 12;  // Istruc=13, Struct=12
                    let mut field_count_v: i64= (i64)sm_ti.field_names.len;
                    // Compute size by summing field sizes
                    let mut size_v: i64= 0;
                    let mut sfi2: i32= 0;
                    while (sfi2 < sm_ti.field_types.len) {
                        let mut fty2: *i8= sm_ti.field_types.data[sfi2];
                        if (fty2 != (i8*)0) { size_v = size_v + (i64)llvm_type_byte_size(fty2); }
                        sfi2 = sfi2 + 1;
                    }
                    // Name global
                    let mut name_gname4: [512]i8;
                    snprintf(name_gname4, (u64)512, "__typeinfo_nm_%s", tname);
                    let mut name_gv4: *i8= make_typeinfo_str_global(t.name, name_gname4, ctx);
                    // Build type_info_field array for fields
                    let mut fields_gv: *i8= (i8*)0;
                    if (tif_ty != (i8*)0 && field_count_v > 0) {
                        let mut fld_consts2: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)field_count_v);
                        let mut byte_off2: i32= 0;
                        let mut fci2: i32= 0;
                        while (fci2 < (i32)field_count_v) {
                            let mut fn_gname2: [512]i8;
                            snprintf(fn_gname2, (u64)512, "__typeinfo_fn_%s_%d", tname, fci2);
                            let mut fn_gv2: *i8= make_typeinfo_str_global(sm_ti.field_names.data[fci2], fn_gname2, ctx);
                            let mut fty3: *i8= (fci2 < sm_ti.field_types.len) ? sm_ti.field_types.data[fci2] : (i8*)0;
                            let mut fsize2: i32= (fty3 != (i8*)0) ? (i32)llvm_type_byte_size(fty3) : 0;
                            let mut falign2: i32= (fsize2 > 0) ? fsize2 : 1;
                            let mut tif_flds2: [4]*i8;
                            tif_flds2[0] = fn_gv2;
                            tif_flds2[1] = LLVMConstInt(i32ty, (u64)byte_off2, 1);
                            tif_flds2[2] = LLVMConstInt(i32ty, (u64)fsize2, 1);
                            tif_flds2[3] = LLVMConstInt(i32ty, (u64)falign2, 1);
                            fld_consts2[fci2] = LLVMConstNamedStruct(tif_ty, tif_flds2, 4);
                            byte_off2 = byte_off2 + fsize2;
                            fci2 = fci2 + 1;
                        }
                        let mut arr_const2: *i8= LLVMConstArray(tif_ty, fld_consts2, (u32)field_count_v);
                        arc_free((i8*)fld_consts2);
                        let mut flds_gname2: [512]i8;
                        snprintf(flds_gname2, (u64)512, "__typeinfo_flds_%s", tname);
                        let mut arr_ty2: *i8= LLVMTypeOf(arr_const2);
                        let mut arr_gv2: *i8= LLVMAddGlobal(ctx.llvm_mod, arr_ty2, flds_gname2);
                        LLVMSetInitializer(arr_gv2, arr_const2);
                        LLVMSetGlobalConstant(arr_gv2, 1);
                        fields_gv = arr_gv2;
                    }
                    // Build method array
                    let mut methods_gv: *i8= (i8*)0;
                    let mut method_count_v: i64= 0;
                    let mut tim_ty2: *i8= st_map_get(&ctx.struct_types, "type_info_method");
                    if (tim_ty2 != (i8*)0 && t.name != (i8*)0) {
                        let mut prefix2: [256]i8;
                        snprintf(prefix2, (u64)256, "%s__NS_", t.name);
                        let mut prefix_len2: i32= (i32)strlen(prefix2);
                        let mut meth_cap2: i32= 32;
                        let mut meth_consts2: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)meth_cap2);
                        let mut mi2: i32= 0;
                        let mut gi2: i32= 0;
                        while (gi2 < ctx.global_funcs.len) {
                            let mut key2: *i8= ctx.global_funcs.data[gi2].key;
                            if (key2 != (i8*)0 && strncmp(key2, prefix2, (u64)prefix_len2) == 0) {
                                let mut method_base2: *i8= key2 + prefix_len2;
                                if (strcmp(method_base2, "__construct__") != 0 &&
                                    strcmp(method_base2, "__destruct__") != 0 &&
                                    strncmp(method_base2, "operator", (u64)8) != 0) {
                                    let mut fn_ty_mi2: *i8= st_map_get(&ctx.global_func_types, key2);
                                    let mut param_cnt2: i32= (fn_ty_mi2 != (i8*)0) ? (i32)LLVMCountParamTypes(fn_ty_mi2) : 0;
                                    let mut ret_ty_mi2: *i8= (fn_ty_mi2 != (i8*)0) ? LLVMGetReturnType(fn_ty_mi2) : (i8*)0;
                                    let mut ret_kind_mi2: i32= (ret_ty_mi2 != (i8*)0) ? (i32)LLVMGetTypeKind(ret_ty_mi2) : 0;
                                    let mut mn_gname2: [512]i8;
                                    snprintf(mn_gname2, (u64)512, "__typeinfo_mn_%s_%d", tname, mi2);
                                    let mut mn_gv2: *i8= make_typeinfo_str_global(method_base2, mn_gname2, ctx);
                                    let mut tim_flds2: [3]*i8;
                                    tim_flds2[0] = mn_gv2;
                                    tim_flds2[1] = LLVMConstInt(i32ty, (u64)param_cnt2, 0);
                                    tim_flds2[2] = LLVMConstInt(i32ty, (u64)ret_kind_mi2, 0);
                                    if (mi2 >= meth_cap2) {
                                        meth_cap2 = meth_cap2 * 2;
                                        meth_consts2 = (i8**)arc_realloc((i8*)meth_consts2, sizeof(i8*) * (u64)meth_cap2);
                                    }
                                    meth_consts2[mi2] = LLVMConstNamedStruct(tim_ty2, tim_flds2, 3);
                                    mi2 = mi2 + 1;
                                }
                            }
                            gi2 = gi2 + 1;
                        }
                        method_count_v = (i64)mi2;
                        if (mi2 > 0) {
                            let mut marr_const2: *i8= LLVMConstArray(tim_ty2, meth_consts2, (u32)mi2);
                            let mut meth_gname2: [512]i8;
                            snprintf(meth_gname2, (u64)512, "__typeinfo_meths_%s", tname);
                            let mut marr_ty2: *i8= LLVMTypeOf(marr_const2);
                            let mut marr_gv2: *i8= LLVMAddGlobal(ctx.llvm_mod, marr_ty2, meth_gname2);
                            LLVMSetInitializer(marr_gv2, marr_const2);
                            LLVMSetGlobalConstant(marr_gv2, 1);
                            methods_gv = marr_gv2;
                        }
                        arc_free((i8*)meth_consts2);
                    }
                    // For Istruc (tag=13): type_info_istruc layout:
                    // [0]=name(ptr), [8]=fields(ptr), [16]=field_count(i64), [24]=methods(ptr),
                    // [32]=method_count(i64), [40]=interfaces(ptr), [48]=interface_count(i64),
                    // [56]=size_bytes(i64), [64]=align_bytes(i64)
                    // For Struct (tag=12): type_info_struct layout:
                    // [0]=name(ptr), [8]=fields(ptr), [16]=field_count(i64), [24]=size_bytes(i64),
                    // [32]=align_bytes(i64), [40]=is_tuple(i64), [48]=is_packed(i64)
                    if (tag_v == 13) {
                        typeinfo_init_store_ptr(ctx, gv, 13, 0,  name_gv4);
                        if (fields_gv != (i8*)0) { typeinfo_init_store_ptr(ctx, gv, 13, 8, fields_gv); }
                        typeinfo_init_store_i64(ctx, gv, 13, 16, field_count_v);
                        if (methods_gv != (i8*)0) { typeinfo_init_store_ptr(ctx, gv, 13, 24, methods_gv); }
                        typeinfo_init_store_i64(ctx, gv, 13, 32, method_count_v);
                        typeinfo_init_store_i64(ctx, gv, 13, 56, size_v);
                    } else {
                        typeinfo_init_store_ptr(ctx, gv, 12, 0,  name_gv4);
                        if (fields_gv != (i8*)0) { typeinfo_init_store_ptr(ctx, gv, 12, 8, fields_gv); }
                        typeinfo_init_store_i64(ctx, gv, 12, 16, field_count_v);
                        typeinfo_init_store_i64(ctx, gv, 12, 24, size_v);
                    }
                } else {
                    // Unknown named type: use Void
                    typeinfo_init_tag_only(ctx, gv, 0);
                }
            }
        }
    } else {
        // Unknown: use Void
        typeinfo_init_tag_only(ctx, gv, 0);
    }

    return gv;
}

// Look up a global variable, trying namespace qualification and parent namespaces.
fn find_global_var(name: *i8, ctx: *ir_context) *i8 {
    let mut gv: *i8= sv_map_get(&ctx.global_vars, name);
    if (gv != (i8*)0) { return gv; }

    if (ctx.current_namespace != (i8*)0) {
        let mut ns_work: [512]i8;
        snprintf(ns_work, (u64)512, "%s", ctx.current_namespace);
        let mut ns_len: i32= (i32)strlen(ns_work);
        while (ns_len > 0) {
            let mut ns_name: [512]i8;
            snprintf(ns_name, (u64)512, "%s__NS_%s", ns_work, name);
            gv = sv_map_get(&ctx.global_vars, ns_name);
            if (gv != (i8*)0) { return gv; }
            let mut split: i32= -1;
            let mut ki: i32= ns_len - 1;
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

// Emit lvalue (pointer to location) for an assignable expression.
fn visit_lvalue(e: *parser.expr_node, ctx: *ir_context) *i8 {
    if (e == (parser.expr_node*)0) { return (i8*)0; }

    if (e.kind == ek_identifier) {
        let mut alloca: *i8= ctx_lookup_local(ctx, e.str_val);
        if (alloca != (i8*)0) { return alloca; }
        // Global var (namespace-qualified lookup)
        let mut gv: *i8= find_global_var(e.str_val, ctx);
        if (gv != (i8*)0) { return gv; }
        // Global function (e.g. &funcname used as a function pointer)
        let mut gfn: *i8= find_func(e.str_val, ctx);
        return gfn;
    }

    if (e.kind == ek_unary && e.uop == uop_deref) {
        // *ptr -> the pointer value itself is the address
        return visit_expr(e.operand, ctx);
    }

    if (e.kind == ek_subscript) {
        // ADT tuple payload access: (*x)[i] where x is an ADT enum local
        if (e.object != (parser.expr_node*)0 && e.object.kind == ek_unary && e.object.uop == uop_deref) {
            let mut inner: *parser.expr_node= e.object.operand;
            if (inner != (parser.expr_node*)0 && inner.kind == ek_identifier && inner.str_val != (i8*)0) {
                let mut local_t: *i8= ctx_lookup_local_type(ctx, inner.str_val);
                if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMStructTypeKind) {
                    let mut sname: *i8= LLVMGetStructName(local_t);
                    if (sname != (i8*)0) {
                        let mut adt_ed_ptr: *i8= sv_map_get(&ctx.adt_enum_decls, sname);
                        if (adt_ed_ptr != (i8*)0) {
                            let mut adt_ed: *parser.enum_decl= (parser.enum_decl*)adt_ed_ptr;
                            // Find first tuple variant (vkind == 1) to get field types
                            let mut tvi: i32= 0; let mut found_vi: i32= -1;
                            while (tvi < adt_ed.variants_len && found_vi < 0) {
                                if (adt_ed.variant_kinds != (i32*)0 && adt_ed.variant_kinds[tvi] == 1) { found_vi = tvi; }
                                tvi = tvi + 1;
                            }
                            if (found_vi >= 0 && adt_ed.variant_field_type_flat != (i8**)0) {
                                let mut fc: i32= (adt_ed.variant_field_counts != (i32*)0) ? adt_ed.variant_field_counts[found_vi] : 0;
                                let mut alloca: *i8= ctx_lookup_local(ctx, inner.str_val);
                                if (alloca != (i8*)0 && e.index != (parser.expr_node*)0 && e.index.kind == ek_int_lit) {
                                    let mut fidx: i32= (i32)e.index.int_val;
                                    // Compute byte offset for field fidx
                                    let mut byte_off: u64= 0;
                                    let mut fi: i32= 0;
                                    let mut i32t: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
                                    while (fi < fidx && fi < fc) {
                                        let mut ft: *parser.type_node= (parser.type_node*)adt_ed.variant_field_type_flat[found_vi * 8 + fi];
                                        let mut flt: *i8= (ft != (parser.type_node*)0) ? llvm_type_of(ft, ctx) : i32t;
                                        let mut fsz: u64= llvm_type_byte_size(flt);
                                        byte_off = byte_off + ((fsz + 7) & ~(u64)7);
                                        fi = fi + 1;
                                    }
                                    // GEP into payload (field 1 of ADT struct)
                                    let mut pay_gep: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, local_t, alloca, 1, "adt_pay");
                                    let mut i8t: *i8= LLVMInt8TypeInContext(ctx.llvm_ctx);
                                    let mut off_v: *i8= LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), byte_off, 0);
                                    return LLVMBuildGEP2(ctx.llvm_builder, i8t, pay_gep, &off_v, 1, "adt_fld");
                                }
                            }
                        }
                    }
                }
            }
        }

        // Direct ADT subscript: x[i] where x is an ADT enum local (not via deref)
        if (e.object != (parser.expr_node*)0 && e.object.kind == ek_identifier && e.object.str_val != (i8*)0 &&
                e.index != (parser.expr_node*)0 && e.index.kind == ek_int_lit) {
            let mut dadt_local_t: *i8= ctx_lookup_local_type(ctx, e.object.str_val);
            if (dadt_local_t != (i8*)0 && LLVMGetTypeKind(dadt_local_t) == LLVMStructTypeKind) {
                let mut dadt_sname: *i8= LLVMGetStructName(dadt_local_t);
                if (dadt_sname != (i8*)0) {
                    let mut dadt_ed_ptr: *i8= sv_map_get(&ctx.adt_enum_decls, dadt_sname);
                    if (dadt_ed_ptr != (i8*)0) {
                        let mut dadt_ed: *parser.enum_decl= (parser.enum_decl*)dadt_ed_ptr;
                        let mut dadt_tvi: i32= 0; let mut dadt_fvi: i32= -1;
                        while (dadt_tvi < dadt_ed.variants_len && dadt_fvi < 0) {
                            if (dadt_ed.variant_kinds != (i32*)0 && dadt_ed.variant_kinds[dadt_tvi] == 1) { dadt_fvi = dadt_tvi; }
                            dadt_tvi = dadt_tvi + 1;
                        }
                        if (dadt_fvi >= 0 && dadt_ed.variant_field_type_flat != (i8**)0) {
                            let mut dadt_fc: i32= (dadt_ed.variant_field_counts != (i32*)0) ? dadt_ed.variant_field_counts[dadt_fvi] : 0;
                            let mut dadt_alloca: *i8= ctx_lookup_local(ctx, e.object.str_val);
                            if (dadt_alloca != (i8*)0) {
                                let mut dadt_fidx: i32= (i32)e.index.int_val;
                                let mut dadt_off: u64= 0;
                                let mut dadt_fi: i32= 0;
                                let mut dadt_i32t: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
                                while (dadt_fi < dadt_fidx && dadt_fi < dadt_fc) {
                                    let mut dadt_ft: *parser.type_node= (parser.type_node*)dadt_ed.variant_field_type_flat[dadt_fvi * 8 + dadt_fi];
                                    let mut dadt_flt: *i8= (dadt_ft != (parser.type_node*)0) ? llvm_type_of(dadt_ft, ctx) : dadt_i32t;
                                    let mut dadt_fsz: u64= llvm_type_byte_size(dadt_flt);
                                    dadt_off = dadt_off + ((dadt_fsz + 7) & ~(u64)7);
                                    dadt_fi = dadt_fi + 1;
                                }
                                let mut dadt_pay: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, dadt_local_t, dadt_alloca, 1, "dadt_pay");
                                let mut dadt_i8t: *i8= LLVMInt8TypeInContext(ctx.llvm_ctx);
                                let mut dadt_offv: *i8= LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), dadt_off, 0);
                                return LLVMBuildGEP2(ctx.llvm_builder, dadt_i8t, dadt_pay, &dadt_offv, 1, "dadt_fld");
                            }
                        }
                    }
                }
            }
        }

        let mut base: *i8= visit_lvalue(e.object, ctx);
        if (base == (i8*)0) { base = visit_expr(e.object, ctx); }
        let mut idx: *i8= visit_expr(e.index, ctx);
        if (base == (i8*)0 || idx == (i8*)0) { return (i8*)0; }

        let mut base_type: *i8= LLVMTypeOf(base);
        let mut elem_type: *i8= (i8*)0;

        let mut bkind: i32= LLVMGetTypeKind(base_type);
        if (bkind == LLVMPointerTypeKind) {
            // Use context lookup to avoid LLVMGetElementType on opaque ptr (broken in LLVM 22).
            let mut inner: *i8= (i8*)0;
            if (e.object.kind == ek_identifier) {
                let mut local_t: *i8= ctx_lookup_local_type(ctx, e.object.str_val);
                // Struct subscript (anonymous struct positional fields): foo[0] → struct GEP
                if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMStructTypeKind &&
                        e.index != (parser.expr_node*)0 && e.index.kind == ek_int_lit) {
                    let mut fidx_sub: i32= (i32)e.index.int_val;
                    return LLVMBuildStructGEP2(ctx.llvm_builder, local_t, base, (u32)fidx_sub, "anon_field");
                }
                if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMArrayTypeKind) {
                    inner = local_t;
                }
                // Check global arrays too
                if (inner == (i8*)0) {
                    let mut gv: *i8= sv_map_get(&ctx.global_vars, e.object.str_val);
                    if (gv != (i8*)0) {
                        let mut gv_t: *i8= LLVMGlobalGetValueType(gv);
                        if (gv_t != (i8*)0 && LLVMGetTypeKind(gv_t) == LLVMArrayTypeKind) {
                            inner = gv_t;
                        }
                    }
                }
            }
            // For non-identifier objects (e.g., struct member arrays), use lvalue_elem_type.
            if (inner == (i8*)0 && e.object.kind != ek_identifier) {
                let mut field_t: *i8= lvalue_elem_type(e.object, ctx);
                if (field_t != (i8*)0 && LLVMGetTypeKind(field_t) == LLVMArrayTypeKind) {
                    inner = field_t;
                }
            }
            // Cast subscript: ((T*)expr)[idx] — base is already the pointer value (no load needed).
            if (inner == (i8*)0 && e.object.kind == ek_cast) {
                let mut deref_t: *i8= lvalue_elem_type(e.object, ctx);
                if (deref_t == (i8*)0) { deref_t = LLVMInt8TypeInContext(ctx.llvm_ctx); }
                return LLVMBuildGEP2(ctx.llvm_builder, deref_t, base, &idx, 1, "cast_gep");
            }
            if (inner != (i8*)0) {
                // Emit runtime bounds guard if SMT marked this subscript as UNKNOWN.
                // e.int_val carries the array size; e.needs_rtcheck flags the check.
                if (e.needs_rtcheck && e.int_val > 0) {
                    emit_bounds_guard(idx, e.int_val, ctx);
                }
                // Array subscript: GEP [N x T]*, i64 0, idx
                let mut zero: *i8= LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), 0, 0);
                let mut idxs: [2]*i8;
                idxs[0] = zero;
                idxs[1] = idx;
                return LLVMBuildGEP2(ctx.llvm_builder, inner, base, idxs, 2, "arr_gep");
            }
            // Pointer variable: load the pointer value, then GEP by index.
            let mut ptr_val: *i8= LLVMBuildLoad2(ctx.llvm_builder, base_type, base, "ptr_load");
            let mut deref_t: *i8= (i8*)0;
            if (e.object.kind == ek_identifier) {
                deref_t = ctx_lookup_deref_type(ctx, e.object.str_val);
            }
            if (deref_t == (i8*)0 && e.object.kind == ek_member && e.object.member_name != (i8*)0) {
                let mut parent_st_c: *i8= infer_expr_struct_type(e.object.object, ctx);
                if (parent_st_c != (i8*)0) {
                    let mut pname_c: *i8= LLVMGetStructName(parent_st_c);
                    if (pname_c != (i8*)0) {
                        let mut fidx_c: i32= ctx_field_index(ctx, pname_c, e.object.member_name);
                        if (fidx_c >= 0) {
                            let mut sm_c: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, pname_c);
                            if (sm_c != (struct_meta*)0 && fidx_c < sm_c.field_pointee.len) {
                                deref_t = sm_c.field_pointee.data[fidx_c];
                                // Forward-reference (i8/null pointee, not ptr): try struct name lookup
                                if (deref_t == (i8*)0 || LLVMGetTypeKind(deref_t) == LLVMIntegerTypeKind) {
                                    let mut fpt_c: *i8= ctx_field_pointee_struct(sm_c, fidx_c, ctx);
                                    if (fpt_c != (i8*)0) { deref_t = fpt_c; }
                                }
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

        // Namespace-qualified global variable lvalue: e.g. &std.hash.FNV_OFFSET
        let mut lv_ns_chain: [512]i8;
        if (build_ns_name_from_chain(e, lv_ns_chain, 512)) {
            let mut lv_chain_gv: *i8= sv_map_get(&ctx.global_vars, lv_ns_chain);
            if (lv_chain_gv != (i8*)0) { return lv_chain_gv; }
        }

        // ADT named field access: (*x).field where x is an ADT enum local
        if (e.object != (parser.expr_node*)0 && e.object.kind == ek_unary && e.object.uop == uop_deref &&
                e.object.operand != (parser.expr_node*)0 && e.object.operand.kind == ek_identifier) {
            let mut local_t: *i8= ctx_lookup_local_type(ctx, e.object.operand.str_val);
            if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMStructTypeKind) {
                let mut sname_adt: *i8= LLVMGetStructName(local_t);
                if (sname_adt != (i8*)0) {
                    let mut adt_ed_ptr: *i8= sv_map_get(&ctx.adt_enum_decls, sname_adt);
                    if (adt_ed_ptr != (i8*)0) {
                        let mut adt_ed: *parser.enum_decl= (parser.enum_decl*)adt_ed_ptr;
                        let mut alloca: *i8= ctx_lookup_local(ctx, e.object.operand.str_val);
                        if (alloca != (i8*)0) {
                            // Search all named/istruc variants for this field
                            let mut vi: i32= 0;
                            while (vi < adt_ed.variants_len) {
                                let mut vkind: i32= (adt_ed.variant_kinds != (i32*)0) ? adt_ed.variant_kinds[vi] : 0;
                                let mut fc: i32= (adt_ed.variant_field_counts != (i32*)0) ? adt_ed.variant_field_counts[vi] : 0;
                                if ((vkind == 2 || vkind == 3) && fc > 0 &&
                                        adt_ed.variant_field_names_flat != (i8**)0) {
                                    let mut byte_off: u64= 0;
                                    let mut fi: i32= 0;
                                    let mut i32t: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
                                    while (fi < fc) {
                                        let mut vfname: *i8= adt_ed.variant_field_names_flat[vi * 8 + fi];
                                        if (vfname != (i8*)0 && strcmp(vfname, e.member_name) == 0) {
                                            // Found field — GEP into payload
                                            let mut pay_gep: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, local_t, alloca, 1, "adt_pay");
                                            let mut i8t: *i8= LLVMInt8TypeInContext(ctx.llvm_ctx);
                                            let mut off_v: *i8= LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), byte_off, 0);
                                            return LLVMBuildGEP2(ctx.llvm_builder, i8t, pay_gep, &off_v, 1, "adt_fld");
                                        }
                                        let mut ft: *parser.type_node= (adt_ed.variant_field_type_flat != (i8**)0)
                                            ? (parser.type_node*)adt_ed.variant_field_type_flat[vi * 8 + fi] : (parser.type_node*)0;
                                        let mut flt: *i8= (ft != (parser.type_node*)0) ? llvm_type_of(ft, ctx) : i32t;
                                        let mut fsz: u64= llvm_type_byte_size(flt);
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
            let mut deref_t2: *i8= ctx_lookup_deref_type(ctx, e.object.str_val);
            if (deref_t2 != (i8*)0 && LLVMGetTypeKind(deref_t2) == LLVMStructTypeKind) {
                let mut sname_adt2: *i8= LLVMGetStructName(deref_t2);
                if (sname_adt2 != (i8*)0) {
                    let mut adt_ed_ptr2: *i8= sv_map_get(&ctx.adt_enum_decls, sname_adt2);
                    if (adt_ed_ptr2 != (i8*)0) {
                        let mut adt_ed2: *parser.enum_decl= (parser.enum_decl*)adt_ed_ptr2;
                        let mut self_alloca: *i8= ctx_lookup_local(ctx, e.object.str_val);
                        let mut ptr_t: *i8= ctx_lookup_local_type(ctx, e.object.str_val);
                        if (self_alloca != (i8*)0 && ptr_t != (i8*)0) {
                            let mut self_ptr: *i8= LLVMBuildLoad2(ctx.llvm_builder, ptr_t, self_alloca, "self_ptr");
                            let mut vi2: i32= 0;
                            while (vi2 < adt_ed2.variants_len) {
                                let mut vkind2: i32= (adt_ed2.variant_kinds != (i32*)0) ? adt_ed2.variant_kinds[vi2] : 0;
                                let mut fc2: i32= (adt_ed2.variant_field_counts != (i32*)0) ? adt_ed2.variant_field_counts[vi2] : 0;
                                if ((vkind2 == 2 || vkind2 == 3) && fc2 > 0 && adt_ed2.variant_field_names_flat != (i8**)0) {
                                    let mut byte_off2: u64= 0;
                                    let mut fi2: i32= 0;
                                    let mut i32t2: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
                                    while (fi2 < fc2) {
                                        let mut vfname2: *i8= adt_ed2.variant_field_names_flat[vi2 * 8 + fi2];
                                        if (vfname2 != (i8*)0 && strcmp(vfname2, e.member_name) == 0) {
                                            let mut pay_gep2: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, deref_t2, self_ptr, 1, "adt_pay");
                                            let mut i8t2: *i8= LLVMInt8TypeInContext(ctx.llvm_ctx);
                                            let mut off_v2: *i8= LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), byte_off2, 0);
                                            return LLVMBuildGEP2(ctx.llvm_builder, i8t2, pay_gep2, &off_v2, 1, "adt_fld");
                                        }
                                        let mut ft2: *parser.type_node= (adt_ed2.variant_field_type_flat != (i8**)0)
                                            ? (parser.type_node*)adt_ed2.variant_field_type_flat[vi2 * 8 + fi2] : (parser.type_node*)0;
                                        let mut flt2: *i8= (ft2 != (parser.type_node*)0) ? llvm_type_of(ft2, ctx) : i32t2;
                                        let mut fsz2: u64= llvm_type_byte_size(flt2);
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
        let mut struct_type: *i8= (i8*)0;
        let mut obj_ptr: *i8= resolve_struct_base(e.object, ctx, &struct_type);

        if (obj_ptr == (i8*)0 || struct_type == (i8*)0) { return (i8*)0; }

        let mut sname: *i8= LLVMGetStructName(struct_type);
        if (sname == (i8*)0) { return (i8*)0; }

        let mut field_idx: i32= ctx_field_index(ctx, sname, e.member_name);
        if (field_idx < 0) {
            if (ctx.current_namespace != (i8*)0) {
                let mut ns_sname: [512]i8;
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
            let mut ft: *i8= ctx_field_type(ctx, sname, field_idx);
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
fn build_args(arg_nodes: **parser.expr_node, nargs: i32, ctx: *ir_context) **i8 {
    if (nargs == 0) { return (i8**)0; }
    let mut args: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)nargs);
    let mut i: i32= 0;
    while (i < nargs) {
        let mut av: *i8= visit_expr(arg_nodes[i], ctx);
        args[i] = av;
        i = i + 1;
    }
    return args;
}

// Coerce call arguments to match declared parameter types (int width narrowing/widening).
// Skips variadic args beyond the fixed parameter count.
fn coerce_args_to_fn(fn_ty: *i8, args: **i8, nargs: i32, builder: *i8) void {
    if (fn_ty == (i8*)0) { return; }
    if (LLVMGetTypeKind(fn_ty) != LLVMFunctionTypeKind) { return; }
    let mut np: i32= (i32)LLVMCountParamTypes(fn_ty);
    if (np == 0) { return; }
    let mut param_types: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)np);
    LLVMGetParamTypes(fn_ty, param_types);
    let mut i: i32= 0;
    while (i < nargs && i < np) {
        if (args[i] != (i8*)0 && param_types[i] != (i8*)0) {
            args[i] = coerce_int_val(args[i], param_types[i], builder);
        }
        i = i + 1;
    }
    arc_free((i8*)param_types);
}

// Like coerce_args_to_fn but also converts concrete memstr structs to &memstr fat pointers.
fn coerce_args_full(fn_ty: *i8, args: **i8, nargs: i32, ctx: *ir_context) void {
    if (fn_ty == (i8*)0) { return; }
    if (LLVMGetTypeKind(fn_ty) != LLVMFunctionTypeKind) { return; }
    let mut np: i32= (i32)LLVMCountParamTypes(fn_ty);
    if (np == 0) { return; }
    let mut param_types: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)np);
    LLVMGetParamTypes(fn_ty, param_types);
    let mut i: i32= 0;
    while (i < nargs && i < np) {
        if (args[i] != (i8*)0 && param_types[i] != (i8*)0) {
            let mut pk: i32= LLVMGetTypeKind(param_types[i]);
            let mut ak: i32= LLVMGetTypeKind(LLVMTypeOf(args[i]));
            if (pk == LLVMStructTypeKind && ctx.memstr_fat_type != (i8*)0 &&
                    param_types[i] == ctx.memstr_fat_type && ak == LLVMStructTypeKind &&
                    LLVMTypeOf(args[i]) != ctx.memstr_fat_type) {
                // Passing a concrete memstr struct as &memstr: build fat pointer.
                let mut sn: *i8= LLVMGetStructName(LLVMTypeOf(args[i]));
                let mut vtbl: *i8= (sn != (i8*)0) ? sv_map_get(&ctx.memstr_vtables, sn) : (i8*)0;
                // If args[i] was a load (opcode 27), reuse its source pointer to avoid copying.
                // Copying would break mutable allocators: each fat-ptr call would start with the
                // original used=0, making all allocations overlap.
                let mut data_ptr: *i8= (i8*)0;
                if (LLVMGetInstructionOpcode(args[i]) == 27) {
                    data_ptr = LLVMGetOperand(args[i], (u32)0);
                }
                if (data_ptr == (i8*)0) {
                    let mut tmp: *i8= LLVMBuildAlloca(ctx.llvm_builder, LLVMTypeOf(args[i]), "ms_tmp");
                    LLVMBuildStore(ctx.llvm_builder, args[i], tmp);
                    data_ptr = tmp;
                }
                let mut fat: *i8= LLVMGetUndef(ctx.memstr_fat_type);
                fat = LLVMBuildInsertValue(ctx.llvm_builder, fat, data_ptr, 0, "fat_d");
                let mut ptr_t: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                let mut vp: *i8= (vtbl != (i8*)0) ? vtbl : LLVMConstPointerNull(ptr_t);
                fat = LLVMBuildInsertValue(ctx.llvm_builder, fat, vp, 1, "fat_v");
                args[i] = fat;
            } else if (pk == LLVMPointerTypeKind && ak == LLVMStructTypeKind) {
                // Passing a concrete struct where a pointer (interface fat-ptr) is expected.
                // Alloca the struct and pass the pointer.
                let mut iface_ptr_tmp: *i8= LLVMBuildAlloca(ctx.llvm_builder, LLVMTypeOf(args[i]), "iface_ptr");
                LLVMBuildStore(ctx.llvm_builder, args[i], iface_ptr_tmp);
                args[i] = iface_ptr_tmp;
            } else if (pk == LLVMStructTypeKind && ak == LLVMStructTypeKind &&
                       param_types[i] != LLVMTypeOf(args[i])) {
                // Check if the target is an interface fat pointer
                let mut pt_sname: *i8= LLVMGetStructName(param_types[i]);
                let mut iface_vtbl_ty_ca: *i8= (pt_sname != (i8*)0) ?
                    st_map_get(&ctx.iface_vtable_types, pt_sname) : (i8*)0;
                if (iface_vtbl_ty_ca != (i8*)0) {
                    // Build fat pointer: { data_ptr, vtable_ptr }
                    let mut src_ty_ca: *i8= LLVMTypeOf(args[i]);
                    let mut sname_ca: *i8= LLVMGetStructName(src_ty_ca);
                    let mut iface_key_ca: [512]i8;
                    if (sname_ca != (i8*)0) {
                        snprintf(iface_key_ca, (u64)512, "%s__IFACE__%s", sname_ca, pt_sname);
                    } else {
                        iface_key_ca[0] = 0;
                    }
                    let mut vtbl_gv_ca: *i8= sv_map_get(&ctx.iface_concrete_vtables, iface_key_ca);
                    let mut data_ptr_ca: *i8= (i8*)0;
                    if (LLVMGetInstructionOpcode(args[i]) == 27) {
                        data_ptr_ca = LLVMGetOperand(args[i], (u32)0);
                    }
                    if (data_ptr_ca == (i8*)0) {
                        let mut tmp_ca: *i8= LLVMBuildAlloca(ctx.llvm_builder, src_ty_ca, "iface_tmp");
                        LLVMBuildStore(ctx.llvm_builder, args[i], tmp_ca);
                        data_ptr_ca = tmp_ca;
                    }
                    let mut ptr_t_ca: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                    let mut fat_ca: *i8= LLVMGetUndef(param_types[i]);
                    fat_ca = LLVMBuildInsertValue(ctx.llvm_builder, fat_ca, data_ptr_ca, 0, "iface_d");
                    let mut vp_ca: *i8= (vtbl_gv_ca != (i8*)0) ? vtbl_gv_ca : LLVMConstPointerNull(ptr_t_ca);
                    fat_ca = LLVMBuildInsertValue(ctx.llvm_builder, fat_ca, vp_ca, 1, "iface_v");
                    args[i] = fat_ca;
                } else {
                    // Passing a concrete struct (istruc impl) as a field-only interface struct.
                    // Reinterpret via alloca-store-load: interface fields are a prefix of the
                    // implementing struct, so loading just the interface portion is valid.
                    let mut iface_tmp: *i8= LLVMBuildAlloca(ctx.llvm_builder, LLVMTypeOf(args[i]), "iface_tmp");
                    LLVMBuildStore(ctx.llvm_builder, args[i], iface_tmp);
                    args[i] = LLVMBuildLoad2(ctx.llvm_builder, param_types[i], iface_tmp, "iface_cast");
                }
            } else {
                args[i] = coerce_int_val(args[i], param_types[i], ctx.llvm_builder);
            }
        }
        i = i + 1;
    }
    arc_free((i8*)param_types);
}

fn visit_binary(e: *parser.expr_node, ctx: *ir_context) *i8 {
    // Operator overload dispatch for struct types
    if (e.lhs != (parser.expr_node*)0) {
        let mut st: *i8= infer_expr_struct_type(e.lhs, ctx);
        if (st != (i8*)0) {
            let mut sname: *i8= LLVMGetStructName(st);
            if (sname != (i8*)0) {
                let mut op_str: *i8= (i8*)0;
                let mut bop: i32= e.bop;
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
                    let mut op_fn_name: [512]i8;
                    snprintf(op_fn_name, (u64)512, "%s__NS_%s", sname, op_str);
                    let mut fn_ref: *i8= sv_map_get(&ctx.global_funcs,      op_fn_name);
                    let mut fn_ty: *i8= st_map_get(&ctx.global_func_types, op_fn_name);
                    if (fn_ref != (i8*)0 && fn_ty != (i8*)0) {
                        let mut lhs_ptr: *i8= visit_lvalue(e.lhs, ctx);
                        let mut rhs_val: *i8= visit_expr(e.rhs, ctx);
                        if (lhs_ptr == (i8*)0) { lhs_ptr = visit_expr(e.lhs, ctx); }
                        if (lhs_ptr != (i8*)0 && rhs_val != (i8*)0) {
                            let mut nparams: u32= LLVMCountParamTypes(fn_ty);
                            let mut cargs: [2]*i8;
                            cargs[0] = lhs_ptr;
                            let mut param_ts: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)(nparams + 1));
                            if (nparams > 0) { LLVMGetParamTypes(fn_ty, param_ts); }
                            if (nparams >= 2) {
                                rhs_val = coerce_int_val(rhs_val, param_ts[1], ctx.llvm_builder);
                            }
                            arc_free((i8*)param_ts);
                            cargs[1] = rhs_val;
                            let mut nargs: i32= (nparams >= 2) ? 2 : 1;
                            return LLVMBuildCall2(ctx.llvm_builder, fn_ty, fn_ref, cargs, nargs, "op_result");
                        }
                    }
                }
            }
        }
    }

    // Short-circuit logical AND/OR: evaluate RHS only if needed
    if (e.bop == bop_log_and) {
        let mut lhs_val: *i8= visit_expr(e.lhs, ctx);
        if (lhs_val == (i8*)0) { return (i8*)0; }
        let mut lhs_bool: *i8= to_bool(lhs_val, ctx.llvm_builder, ctx.llvm_ctx);
        let mut cur_fn: *i8= ctx.current_func;
        let mut then_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, cur_fn, "land_rhs");
        let mut merge_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, cur_fn, "land_merge");
        let mut lhs_bb: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
        LLVMBuildCondBr(ctx.llvm_builder, lhs_bool, then_bb, merge_bb);
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, then_bb);
        let mut rhs_val: *i8= visit_expr(e.rhs, ctx);
        let mut rhs_bool: *i8= (rhs_val != (i8*)0) ? to_bool(rhs_val, ctx.llvm_builder, ctx.llvm_ctx) : LLVMConstInt(LLVMInt1TypeInContext(ctx.llvm_ctx), 0, 0);
        let mut rhs_bb: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
        LLVMBuildBr(ctx.llvm_builder, merge_bb);
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb);
        let mut i1t: *i8= LLVMInt1TypeInContext(ctx.llvm_ctx);
        let mut phi: *i8= LLVMBuildPhi(ctx.llvm_builder, i1t, "land");
        let mut false_val: *i8= LLVMConstInt(i1t, 0, 0);
        LLVMAddIncoming(phi, &false_val, &lhs_bb, 1);
        LLVMAddIncoming(phi, &rhs_bool, &rhs_bb, 1);
        return phi;
    }
    if (e.bop == bop_log_or) {
        let mut lhs_val2: *i8= visit_expr(e.lhs, ctx);
        if (lhs_val2 == (i8*)0) { return (i8*)0; }
        let mut lhs_bool2: *i8= to_bool(lhs_val2, ctx.llvm_builder, ctx.llvm_ctx);
        let mut cur_fn2: *i8= ctx.current_func;
        let mut else_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, cur_fn2, "lor_rhs");
        let mut merge_bb2: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, cur_fn2, "lor_merge");
        let mut lhs_bb2: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
        LLVMBuildCondBr(ctx.llvm_builder, lhs_bool2, merge_bb2, else_bb);
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, else_bb);
        let mut rhs_val2: *i8= visit_expr(e.rhs, ctx);
        let mut rhs_bool2: *i8= (rhs_val2 != (i8*)0) ? to_bool(rhs_val2, ctx.llvm_builder, ctx.llvm_ctx) : LLVMConstInt(LLVMInt1TypeInContext(ctx.llvm_ctx), 0, 0);
        let mut rhs_bb2: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
        LLVMBuildBr(ctx.llvm_builder, merge_bb2);
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb2);
        let mut i1t2: *i8= LLVMInt1TypeInContext(ctx.llvm_ctx);
        let mut phi2: *i8= LLVMBuildPhi(ctx.llvm_builder, i1t2, "lor");
        let mut true_val: *i8= LLVMConstInt(i1t2, 1, 0);
        LLVMAddIncoming(phi2, &true_val, &lhs_bb2, 1);
        LLVMAddIncoming(phi2, &rhs_bool2, &rhs_bb2, 1);
        return phi2;
    }

    let mut lhs: *i8= visit_expr(e.lhs, ctx);
    let mut rhs: *i8= visit_expr(e.rhs, ctx);
    if (lhs == (i8*)0 || rhs == (i8*)0) { return (i8*)0; }

    let mut lt: *i8= LLVMTypeOf(lhs);
    let mut rt: *i8= LLVMTypeOf(rhs);
    let mut is_float_op: bool= llvm_is_float(lt);
    let mut is_ptr_op: bool= LLVMGetTypeKind(lt) == LLVMPointerTypeKind;

    // Implicit-cast check (Zig philosophy): arithmetic on two differently-typed
    // non-constant integers is an error. Literals are compile-time constants and
    // may be coerced implicitly; only typed runtime values must match.
    if (!is_float_op && !is_ptr_op &&
            LLVMGetTypeKind(lt) == LLVMIntegerTypeKind &&
            LLVMGetTypeKind(rt) == LLVMIntegerTypeKind) {
        let mut lw: i32= LLVMGetIntTypeWidth(lt);
        let mut rw: i32= LLVMGetIntTypeWidth(rt);
        if (lw != rw) {
            // Allow if one side is a compile-time constant (integer literal)
            let mut lhs_const: bool= LLVMIsAConstantInt(lhs) != (i8*)0;
            let mut rhs_const: bool= LLVMIsAConstantInt(rhs) != (i8*)0;
            if (!lhs_const && !rhs_const) {
                let mut op_ic: i32= e.bop;
                if (op_ic == bop_add || op_ic == bop_sub || op_ic == bop_mul ||
                        op_ic == bop_div || op_ic == bop_mod) {
                    printf("error at line %llu: implicit integer cast: cannot mix %d-bit and %d-bit integers in arithmetic without explicit cast (use 'as')\n",
                           e.line, lw, rw);
                    ctx.had_error = true;
                }
            }
        }
    }

    // Rational and complex struct arithmetic: 2-field structs get special treatment.
    let mut lt_kind2: i32= LLVMGetTypeKind(lt);
    let mut lt_nfields: i32= (i32)LLVMCountStructElementTypes(lt);
    if (lt_kind2 == LLVMStructTypeKind && lt_nfields == 2) {
        let mut fld0: *i8= LLVMStructGetTypeAtIndex(lt, (u32)0);
        let mut fld0_kind: i32= LLVMGetTypeKind(fld0);
        let mut is_rat: bool= (fld0_kind == LLVMIntegerTypeKind);
        let mut is_cmp: bool= llvm_is_float(fld0);
        if (is_rat || is_cmp) {
            let mut op2: i32= e.bop;
            // Extract fields from lhs and rhs
            let mut la: *i8= LLVMBuildExtractValue(ctx.llvm_builder, lhs, (u32)0, "la");
            let mut lb: *i8= LLVMBuildExtractValue(ctx.llvm_builder, lhs, (u32)1, "lb");
            let mut ra: *i8= LLVMBuildExtractValue(ctx.llvm_builder, rhs, (u32)0, "ra");
            let mut rb: *i8= LLVMBuildExtractValue(ctx.llvm_builder, rhs, (u32)1, "rb");
            let mut r0: *i8= (i8*)0;
            let mut r1: *i8= (i8*)0;
            if (is_rat) {
                // Rational: {num, den}
                // +: {a.num*b.den + b.num*a.den, a.den*b.den}
                // -: {a.num*b.den - b.num*a.den, a.den*b.den}
                // *: {a.num*b.num, a.den*b.den}
                // /: {a.num*b.den, a.den*b.num}
                if (op2 == bop_add) {
                    let mut t0: *i8= LLVMBuildMul(ctx.llvm_builder, la, rb, "rn0");
                    let mut t1: *i8= LLVMBuildMul(ctx.llvm_builder, ra, lb, "rn1");
                    r0 = LLVMBuildAdd(ctx.llvm_builder, t0, t1, "rnum");
                    r1 = LLVMBuildMul(ctx.llvm_builder, lb, rb, "rden");
                } else if (op2 == bop_sub) {
                    let mut t0: *i8= LLVMBuildMul(ctx.llvm_builder, la, rb, "rn0");
                    let mut t1: *i8= LLVMBuildMul(ctx.llvm_builder, ra, lb, "rn1");
                    r0 = LLVMBuildSub(ctx.llvm_builder, t0, t1, "rnum");
                    r1 = LLVMBuildMul(ctx.llvm_builder, lb, rb, "rden");
                } else if (op2 == bop_mul) {
                    r0 = LLVMBuildMul(ctx.llvm_builder, la, ra, "rnum");
                    r1 = LLVMBuildMul(ctx.llvm_builder, lb, rb, "rden");
                } else if (op2 == bop_div) {
                    r0 = LLVMBuildMul(ctx.llvm_builder, la, rb, "rnum");
                    r1 = LLVMBuildMul(ctx.llvm_builder, lb, ra, "rden");
                }
                if (r0 != (i8*)0 && r1 != (i8*)0) {
                    let mut res2: *i8= LLVMGetUndef(lt);
                    res2 = LLVMBuildInsertValue(ctx.llvm_builder, res2, r0, 0, "q0");
                    res2 = LLVMBuildInsertValue(ctx.llvm_builder, res2, r1, 1, "q1");
                    return res2;
                }
                // Equality/comparison: compare as fractions (cross-multiply)
                if (op2 == bop_eq || op2 == bop_ne || op2 == bop_lt || op2 == bop_gt ||
                    op2 == bop_lte || op2 == bop_gte) {
                    let mut cross_l: *i8= LLVMBuildMul(ctx.llvm_builder, la, rb, "cl");
                    let mut cross_r: *i8= LLVMBuildMul(ctx.llvm_builder, ra, lb, "cr");
                    let mut pred2: i32= LLVMIntEQ;
                    if (op2 == bop_eq)  { pred2 = LLVMIntEQ; }
                    if (op2 == bop_ne)  { pred2 = LLVMIntNE; }
                    if (op2 == bop_lt)  { pred2 = LLVMIntSLT; }
                    if (op2 == bop_gt)  { pred2 = LLVMIntSGT; }
                    if (op2 == bop_lte) { pred2 = LLVMIntSLE; }
                    if (op2 == bop_gte) { pred2 = LLVMIntSGE; }
                    return LLVMBuildICmp(ctx.llvm_builder, pred2, cross_l, cross_r, "qcmp");
                }
            } else {
                // Complex: {re, im}
                // +: {a.re+b.re, a.im+b.im}
                // -: {a.re-b.re, a.im-b.im}
                // *: {a.re*b.re - a.im*b.im, a.re*b.im + a.im*b.re}
                // /: {(a.re*b.re + a.im*b.im)/denom, (a.im*b.re - a.re*b.im)/denom}
                if (op2 == bop_add) {
                    r0 = LLVMBuildFAdd(ctx.llvm_builder, la, ra, "cre");
                    r1 = LLVMBuildFAdd(ctx.llvm_builder, lb, rb, "cim");
                } else if (op2 == bop_sub) {
                    r0 = LLVMBuildFSub(ctx.llvm_builder, la, ra, "cre");
                    r1 = LLVMBuildFSub(ctx.llvm_builder, lb, rb, "cim");
                } else if (op2 == bop_mul) {
                    let mut t0: *i8= LLVMBuildFMul(ctx.llvm_builder, la, ra, "t0");
                    let mut t1: *i8= LLVMBuildFMul(ctx.llvm_builder, lb, rb, "t1");
                    let mut t2: *i8= LLVMBuildFMul(ctx.llvm_builder, la, rb, "t2");
                    let mut t3: *i8= LLVMBuildFMul(ctx.llvm_builder, lb, ra, "t3");
                    r0 = LLVMBuildFSub(ctx.llvm_builder, t0, t1, "cre");
                    r1 = LLVMBuildFAdd(ctx.llvm_builder, t2, t3, "cim");
                } else if (op2 == bop_div) {
                    let mut t0: *i8= LLVMBuildFMul(ctx.llvm_builder, la, ra, "t0");
                    let mut t1: *i8= LLVMBuildFMul(ctx.llvm_builder, lb, rb, "t1");
                    let mut t2: *i8= LLVMBuildFMul(ctx.llvm_builder, lb, ra, "t2");
                    let mut t3: *i8= LLVMBuildFMul(ctx.llvm_builder, la, rb, "t3");
                    let mut dnm_re: *i8= LLVMBuildFMul(ctx.llvm_builder, ra, ra, "dr");
                    let mut dnm_im: *i8= LLVMBuildFMul(ctx.llvm_builder, rb, rb, "di");
                    let mut denom: *i8= LLVMBuildFAdd(ctx.llvm_builder, dnm_re, dnm_im, "denom");
                    r0 = LLVMBuildFDiv(ctx.llvm_builder, LLVMBuildFAdd(ctx.llvm_builder, t0, t1, "nre"), denom, "cre");
                    r1 = LLVMBuildFDiv(ctx.llvm_builder, LLVMBuildFSub(ctx.llvm_builder, t2, t3, "nim"), denom, "cim");
                }
                if (r0 != (i8*)0 && r1 != (i8*)0) {
                    let mut res2: *i8= LLVMGetUndef(lt);
                    res2 = LLVMBuildInsertValue(ctx.llvm_builder, res2, r0, 0, "c0");
                    res2 = LLVMBuildInsertValue(ctx.llvm_builder, res2, r1, 1, "c1");
                    return res2;
                }
                // ==, !=: component-wise
                if (op2 == bop_eq || op2 == bop_ne) {
                    let mut eq_re: *i8= LLVMBuildFCmp(ctx.llvm_builder, LLVMRealOEQ, la, ra, "eq_re");
                    let mut eq_im: *i8= LLVMBuildFCmp(ctx.llvm_builder, LLVMRealOEQ, lb, rb, "eq_im");
                    let mut both: *i8= LLVMBuildAnd(ctx.llvm_builder, eq_re, eq_im, "ceq");
                    if (op2 == bop_ne) { return LLVMBuildNot(ctx.llvm_builder, both, "cne"); }
                    return both;
                }
            }
        }
    }
    // ---- End rational / complex ----

    // Determine if the operands are unsigned integers (for div/mod/comparisons).
    let mut uns: bool= false;
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
    let mut ptr_elem_t: *i8= (i8*)0;
    if (is_ptr_op && e.lhs != (parser.expr_node*)0) {
        if (e.lhs.kind == ek_identifier) {
            ptr_elem_t = ctx_lookup_deref_type(ctx, e.lhs.str_val);
        }
        if (ptr_elem_t == (i8*)0) { ptr_elem_t = LLVMInt8TypeInContext(ctx.llvm_ctx); }
    }

    let mut op: i32= e.bop;
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
            let mut neg_rhs: *i8= LLVMBuildNeg(ctx.llvm_builder, rhs, "neg");
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
        let mut l1: *i8= to_bool(lhs, ctx.llvm_builder, ctx.llvm_ctx);
        let mut r1: *i8= to_bool(rhs, ctx.llvm_builder, ctx.llvm_ctx);
        return LLVMBuildAnd(ctx.llvm_builder, l1, r1, "land");
    }
    if (op == bop_log_or) {
        let mut l1: *i8= to_bool(lhs, ctx.llvm_builder, ctx.llvm_ctx);
        let mut r1: *i8= to_bool(rhs, ctx.llvm_builder, ctx.llvm_ctx);
        return LLVMBuildOr(ctx.llvm_builder, l1, r1, "lor");
    }

    // Comparison
    let mut pred: i32= -1;
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

fn visit_assign(e: *parser.expr_node, ctx: *ir_context) *i8 {
    // Reject writes through *const pointers: covers simple deref (*p = v),
    // member access through const ptr (p->field = v), subscript through const ptr (p[i] = v),
    // and all compound forms (+=, -=, etc.) since they all go through visit_assign.
    if (e.lhs != (parser.expr_node*)0) {
        let mut lhs_e: *parser.expr_node= e.lhs;
        // Direct deref: *p
        if (lhs_e.kind == ek_unary && lhs_e.uop == uop_deref &&
                lhs_e.operand != (parser.expr_node*)0 && lhs_e.operand.kind == ek_identifier) {
            if (ctx_is_local_const_ptr(ctx, lhs_e.operand.str_val)) {
                printf("error at line %llu: write through *const pointer '%s'\n",
                       (u64)e.line, lhs_e.operand.str_val);
                ctx.had_error = true;
                return (i8*)0;
            }
        }
        // Member access through pointer: p->field (object is identifier)
        if (lhs_e.kind == ek_member && lhs_e.object != (parser.expr_node*)0 &&
                lhs_e.object.kind == ek_identifier) {
            if (ctx_is_local_const_ptr(ctx, lhs_e.object.str_val)) {
                printf("error at line %llu: write to field through *const pointer '%s'\n",
                       (u64)e.line, lhs_e.object.str_val);
                ctx.had_error = true;
                return (i8*)0;
            }
        }
        // Subscript through const pointer: p[i]
        if (lhs_e.kind == ek_subscript && lhs_e.object != (parser.expr_node*)0 &&
                lhs_e.object.kind == ek_identifier) {
            if (ctx_is_local_const_ptr(ctx, lhs_e.object.str_val)) {
                printf("error at line %llu: write through *const pointer subscript '%s'\n",
                       (u64)e.line, lhs_e.object.str_val);
                ctx.had_error = true;
                return (i8*)0;
            }
        }
    }

    let mut lhs_ptr: *i8= visit_lvalue(e.lhs, ctx);
    let mut rhs_val: *i8= visit_expr(e.rhs, ctx);

    if (lhs_ptr == (i8*)0 || rhs_val == (i8*)0) { return rhs_val; }

    // Compound assignments: load lhs, apply op, store
    let mut op: i32= e.bop;
    if (op != bop_assign) {
        let mut elem_type: *i8= lvalue_elem_type(e.lhs, ctx);
        if (elem_type == (i8*)0) {
            let mut lhs_type: *i8= LLVMTypeOf(lhs_ptr);
            if (LLVMGetTypeKind(lhs_type) == LLVMPointerTypeKind) {
                elem_type = LLVMGetElementType(lhs_type);
            }
            if (elem_type == (i8*)0) { elem_type = lhs_type; }
        }

        let mut cur: *i8= LLVMBuildLoad2(ctx.llvm_builder, elem_type, lhs_ptr, "load_for_op");
        rhs_val = coerce_int_val(rhs_val, elem_type, ctx.llvm_builder);

        let mut result: *i8= (i8*)0;
        let mut is_f: bool= llvm_is_float(elem_type);
        let mut uns_a: bool= false;
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
    let mut elem_t: *i8= lvalue_elem_type(e.lhs, ctx);
    if (elem_t != (i8*)0) {
        rhs_val = coerce_int_val(rhs_val, elem_t, ctx.llvm_builder);
    }
    let mut store_instr: *i8= LLVMBuildStore(ctx.llvm_builder, rhs_val, lhs_ptr);
    if (e.lhs != (parser.expr_node*)0 && e.lhs.kind == ek_identifier &&
            ctx_is_local_volatile(ctx, e.lhs.str_val)) {
        LLVMSetVolatile(store_instr, 1);
    }
    return rhs_val;
}

// Lower a GCC-style __sync_* call to a real LLVM atomic instruction.
// These names are compiler builtins, not linkable library symbols, so emitting a
// plain call produces an undefined reference at link time. Returns null when the
// callee is not a __sync_* builtin (caller falls through to normal call codegen).
fn emit_sync_builtin(name: *i8, e: *parser.expr_node, ctx: *ir_context) *i8 {
    if (name == (i8*)0) { return (i8*)0; }
    if (!(name[0] == '_' && name[1] == '_' && name[2] == 's' && name[3] == 'y' &&
          name[4] == 'n' && name[5] == 'c')) { return (i8*)0; }

    let mut seq: i32= LLVMAtomicOrderingSequentiallyConsistent;

    // __sync_synchronize() — full memory barrier
    if (strcmp(name, "__sync_synchronize") == 0) {
        LLVMBuildFence(ctx.llvm_builder, seq, 0, "");
        return LLVMConstInt(LLVMInt32TypeInContext(ctx.llvm_ctx), 0, 0);
    }

    // Remaining forms all take at least a pointer operand.
    if (e.args_len < 1 || e.args == (parser.expr_node**)0) { return (i8*)0; }
    let mut p: *i8= visit_expr(e.args[0], ctx);
    if (p == (i8*)0) { return (i8*)0; }

    // __sync_lock_release_N(ptr) — release store of 0
    if (strcmp(name, "__sync_lock_release_4") == 0 || strcmp(name, "__sync_lock_release_8") == 0) {
        let mut w32: bool= strcmp(name, "__sync_lock_release_4") == 0;
        let mut it: *i8= w32 ? LLVMInt32TypeInContext(ctx.llvm_ctx) : LLVMInt64TypeInContext(ctx.llvm_ctx);
        LLVMBuildAtomicRMW(ctx.llvm_builder, LLVMAtomicRMWBinOpXchg, p,
                           LLVMConstInt(it, 0, 0), LLVMAtomicOrderingRelease, 0);
        return LLVMConstInt(LLVMInt32TypeInContext(ctx.llvm_ctx), 0, 0);
    }

    if (e.args_len < 2) { return (i8*)0; }
    let mut v: *i8= visit_expr(e.args[1], ctx);
    if (v == (i8*)0) { return (i8*)0; }

    // __sync_val_compare_and_swap_N(ptr, expected, desired) — returns the old value
    if (strcmp(name, "__sync_val_compare_and_swap_4") == 0 ||
        strcmp(name, "__sync_val_compare_and_swap_8") == 0) {
        if (e.args_len < 3) { return (i8*)0; }
        let mut nv: *i8= visit_expr(e.args[2], ctx);
        if (nv == (i8*)0) { return (i8*)0; }
        let mut cx: *i8= LLVMBuildAtomicCmpXchg(ctx.llvm_builder, p, v, nv, seq, seq, 0);
        // cmpxchg yields { value, success }; the __sync_val_* form returns the value.
        return LLVMBuildExtractValue(ctx.llvm_builder, cx, 0, "cas_old");
    }

    // __sync_lock_test_and_set_N(ptr, val) — atomic exchange
    let mut op: i32= -1;
    if      (strcmp(name, "__sync_lock_test_and_set_4") == 0 ||
             strcmp(name, "__sync_lock_test_and_set_8") == 0) { op = LLVMAtomicRMWBinOpXchg; }
    else if (strcmp(name, "__sync_fetch_and_add_4") == 0 ||
             strcmp(name, "__sync_fetch_and_add_8") == 0)     { op = LLVMAtomicRMWBinOpAdd; }
    else if (strcmp(name, "__sync_fetch_and_sub_4") == 0 ||
             strcmp(name, "__sync_fetch_and_sub_8") == 0)     { op = LLVMAtomicRMWBinOpSub; }
    else if (strcmp(name, "__sync_fetch_and_and_4") == 0 ||
             strcmp(name, "__sync_fetch_and_and_8") == 0)     { op = LLVMAtomicRMWBinOpAnd; }
    else if (strcmp(name, "__sync_fetch_and_or_4") == 0 ||
             strcmp(name, "__sync_fetch_and_or_8") == 0)      { op = LLVMAtomicRMWBinOpOr; }
    else if (strcmp(name, "__sync_fetch_and_xor_4") == 0 ||
             strcmp(name, "__sync_fetch_and_xor_8") == 0)     { op = LLVMAtomicRMWBinOpXor; }
    if (op >= 0) {
        return LLVMBuildAtomicRMW(ctx.llvm_builder, op, p, v, seq, 0);
    }
    return (i8*)0;
}

fn visit_call(e: *parser.expr_node, ctx: *ir_context) *i8 {
    if (e.callee == (parser.expr_node*)0) { return (i8*)0; }

    // GCC __sync_* builtins must become real atomic instructions, not calls.
    if (e.callee.kind == ek_identifier && e.callee.str_val != (i8*)0) {
        let mut sync_v: *i8= emit_sync_builtin(e.callee.str_val, e, ctx);
        if (sync_v != (i8*)0) { return sync_v; }
    }

    // Method call: obj.method(args)
    if (e.callee.kind == ek_member) {
        let mut obj_expr: *parser.expr_node= e.callee.object;
        let mut method_name: *i8= e.callee.member_name;

        // Build fully-qualified method name
        // First visit obj to determine its type
        let mut obj_ptr: *i8= visit_lvalue(obj_expr, ctx);
        if (obj_ptr == (i8*)0) {
            obj_ptr = visit_expr(obj_expr, ctx);
        }
        // For pointer-to-struct locals (e.g., self: T* stored as alloca ptr),
        // obj_ptr is the alloca holding the struct pointer — load to get actual T*.
        if (obj_ptr != (i8*)0 && obj_expr != (parser.expr_node*)0 && obj_expr.kind == ek_identifier) {
            let mut local_t: *i8= ctx_lookup_local_type(ctx, obj_expr.str_val);
            if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMPointerTypeKind) {
                obj_ptr = LLVMBuildLoad2(ctx.llvm_builder, local_t, obj_ptr, "self_load");
            }
        }

        // Derive struct name from the local type via infer_expr_struct_type.
        // We rely solely on this path because in LLVM 15+ opaque-pointer mode
        // LLVMGetElementType on a ptr type returns garbage (UB), not null.
        let mut struct_name: *i8= (i8*)0;
        if (obj_expr != (parser.expr_node*)0) {
            let mut st: *i8= infer_expr_struct_type(obj_expr, ctx);
            if (st != (i8*)0) {
                struct_name = LLVMGetStructName(st);
            }
        }

        if (struct_name != (i8*)0 && method_name != (i8*)0) {
            // &memstr fat-pointer vtable dispatch: a.mmap(n), a.rmap(p), a.deinit()
            if ((strcmp(struct_name, "__memstr_fat__") == 0 || strcmp(struct_name, "memstr") == 0) && ctx.memstr_fat_type != (i8*)0) {
                // obj_ptr is the alloca holding the fat struct; load to get the fat value.
                let mut fat_val: *i8= LLVMBuildLoad2(ctx.llvm_builder, ctx.memstr_fat_type, obj_ptr, "fat");
                let mut ms_data: *i8= LLVMBuildExtractValue(ctx.llvm_builder, fat_val, 0, "ms_data");
                let mut ms_vtbl: *i8= LLVMBuildExtractValue(ctx.llvm_builder, fat_val, 1, "ms_vtbl");
                // 5-slot vtable: 0=mmap, 1=rsmap, 2=rmap, 3=free, 4=destroy
                let mut vslot: i32= -1;
                if (strcmp(method_name, "mmap")    == 0) { vslot = 0; }
                if (strcmp(method_name, "rsmap")   == 0) { vslot = 1; }
                if (strcmp(method_name, "rmap")    == 0) { vslot = 2; }
                if (strcmp(method_name, "free")    == 0) { vslot = 3; }
                if (strcmp(method_name, "destroy") == 0) { vslot = 4; }
                if (strcmp(method_name, "deinit")  == 0) { vslot = 4; }
                if (vslot >= 0 && ctx.memstr_vtable_type != (i8*)0) {
                    let mut idx_vals: [2]*i8;
                    idx_vals[0] = LLVMConstInt(LLVMInt32TypeInContext(ctx.llvm_ctx), 0, 0);
                    idx_vals[1] = LLVMConstInt(LLVMInt32TypeInContext(ctx.llvm_ctx), (u64)vslot, 0);
                    let mut slot_ptr: *i8= LLVMBuildGEP2(ctx.llvm_builder, ctx.memstr_vtable_type,
                                                  ms_vtbl, idx_vals, 2, "vtslot");
                    let mut fn_ptr: *i8= LLVMBuildLoad2(ctx.llvm_builder,
                                                 LLVMPointerTypeInContext(ctx.llvm_ctx, 0),
                                                 slot_ptr, "fnptr");
                    // Build call type: (ptr self [, extra args...]) -> return type
                    let mut ncall_args: i32= e.args_len + 1;
                    let mut call_args: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)ncall_args);
                    call_args[0] = ms_data;
                    let mut call_param_ts: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)ncall_args);
                    let mut ptr_t: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                    call_param_ts[0] = ptr_t;
                    let mut cai: i32= 0;
                    while (cai < e.args_len) {
                        let mut av: *i8= visit_expr(e.args[cai], ctx);
                        call_args[cai + 1] = av;
                        call_param_ts[cai + 1] = (av != (i8*)0) ? LLVMTypeOf(av) : ptr_t;
                        cai = cai + 1;
                    }
                    // Return types: mmap/rmap→ptr, rsmap→i1, free/destroy→void
                    let mut call_ret: *i8= LLVMVoidTypeInContext(ctx.llvm_ctx);
                    if (vslot == 0 || vslot == 2) { call_ret = ptr_t; }
                    else if (vslot == 1) { call_ret = LLVMInt1TypeInContext(ctx.llvm_ctx); }
                    let mut call_fty: *i8= LLVMFunctionType(call_ret, call_param_ts, ncall_args, 0);
                    let mut call_res: *i8= LLVMBuildCall2(ctx.llvm_builder, call_fty, fn_ptr,
                                                   call_args, ncall_args, "");
                    arc_free((i8*)call_args);
                    arc_free((i8*)call_param_ts);
                    return call_res;
                }
                return (i8*)0;
            }

            // Interface fat-pointer vtable dispatch: d.method() where d: SomeInterface
            let mut iface_vtbl_ty: *i8= st_map_get(&ctx.iface_vtable_types, struct_name);
            if (iface_vtbl_ty != (i8*)0) {
                let mut iface_st_ty: *i8= st_map_get(&ctx.struct_types, struct_name);
                if (iface_st_ty != (i8*)0) {
                    let mut iface_fat: *i8= LLVMBuildLoad2(ctx.llvm_builder, iface_st_ty, obj_ptr, "iface_fat");
                    let mut iface_data: *i8= LLVMBuildExtractValue(ctx.llvm_builder, iface_fat, 0, "iface_d");
                    let mut iface_vtbl: *i8= LLVMBuildExtractValue(ctx.llvm_builder, iface_fat, 1, "iface_v");
                    let mut sm_iface: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, struct_name);
                    let mut vslot_iv: i32= -1;
                    if (sm_iface != (struct_meta*)0) {
                        let mut mi_iv: i32= 0;
                        while (mi_iv < sm_iface.iface_method_names.len && vslot_iv == -1) {
                            if (strcmp(sm_iface.iface_method_names.data[mi_iv], method_name) == 0) {
                                vslot_iv = mi_iv;
                            }
                            mi_iv = mi_iv + 1;
                        }
                    }
                    if (vslot_iv >= 0) {
                        let mut ptr_t_iv: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                        let mut slot_ptr: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, iface_vtbl_ty, iface_vtbl, (u32)vslot_iv, "slot_p");
                        let mut fn_ptr_iv: *i8= LLVMBuildLoad2(ctx.llvm_builder, ptr_t_iv, slot_ptr, "fn_p");
                        let mut iface_fn_name: [512]i8;
                        snprintf(iface_fn_name, (u64)512, "%s__NS_%s", struct_name, method_name);
                        let mut iface_fn_ty: *i8= st_map_get(&ctx.global_func_types, iface_fn_name);
                        if (iface_fn_ty != (i8*)0) {
                            let mut nargs_iv: i32= e.args_len + 1;
                            let mut args_iv: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)nargs_iv);
                            args_iv[0] = iface_data;
                            let mut ai_iv: i32= 0;
                            while (ai_iv < e.args_len) {
                                args_iv[ai_iv + 1] = visit_expr(e.args[ai_iv], ctx);
                                ai_iv = ai_iv + 1;
                            }
                            let mut res_iv: *i8= LLVMBuildCall2(ctx.llvm_builder, iface_fn_ty, fn_ptr_iv, args_iv, nargs_iv, "");
                            arc_free((i8*)args_iv);
                            return res_iv;
                        }
                    }
                }
            }

            let mut mt_name: [512]i8;
            snprintf(mt_name, (u64)512, "%s__MT_%s", struct_name, method_name);
            let mut fn_ref: *i8= sv_map_get(&ctx.global_funcs,      mt_name);
            let mut fn_ty: *i8= st_map_get(&ctx.global_func_types, mt_name);

            // Fallback: try __NS_ prefix (istruc/namespace methods)
            if (fn_ref == (i8*)0 || fn_ty == (i8*)0) {
                snprintf(mt_name, (u64)512, "%s__NS_%s", struct_name, method_name);
                fn_ref    = sv_map_get(&ctx.global_funcs,      mt_name);
                fn_ty = st_map_get(&ctx.global_func_types, mt_name);
            }

            if (fn_ref != (i8*)0 && fn_ty != (i8*)0) {
                let mut nargs: i32= e.args_len + 1;
                let mut args: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)nargs);
                let mut nparams: u32= LLVMCountParamTypes(fn_ty);
                let mut param_ts: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)(nparams + 1));
                if (nparams > 0) { LLVMGetParamTypes(fn_ty, param_ts); }
                // If the first LLVM param is a struct value (not a pointer), the method uses
                // by-value self: load the struct and pass it instead of the raw pointer.
                let mut self_arg: *i8= obj_ptr;
                if (nparams > 0 && param_ts[0] != (i8*)0 &&
                        LLVMGetTypeKind(param_ts[0]) == LLVMStructTypeKind) {
                    let mut struct_t: *i8= st_map_get(&ctx.struct_types, struct_name);
                    if (struct_t != (i8*)0 && obj_ptr != (i8*)0) {
                        self_arg = LLVMBuildLoad2(ctx.llvm_builder, struct_t, obj_ptr, "self_load");
                    }
                }
                args[0]   = self_arg;
                let mut i: i32= 0;
                while (i < e.args_len) {
                    let mut av: *i8= visit_expr(e.args[i], ctx);
                    let mut pi: i32= i + 1;
                    if (av != (i8*)0 && (u32)pi < nparams) {
                        let mut param_kind: i32= LLVMGetTypeKind(param_ts[pi]);
                        let mut av_ty: *i8= LLVMTypeOf(av);
                        let mut av_kind: i32= LLVMGetTypeKind(av_ty);
                        if (param_kind == LLVMStructTypeKind && ctx.memstr_fat_type != (i8*)0 &&
                                param_ts[pi] == ctx.memstr_fat_type && av_kind == LLVMStructTypeKind &&
                                av_ty != ctx.memstr_fat_type) {
                            // Passing a concrete memstr struct as &memstr: build fat pointer.
                            let mut sname: *i8= LLVMGetStructName(av_ty);
                            let mut vtbl: *i8= (sname != (i8*)0) ? sv_map_get(&ctx.memstr_vtables, sname) : (i8*)0;
                            // Reuse source pointer of a load to avoid value-copying the allocator.
                            let mut data_ptr2: *i8= (i8*)0;
                            if (LLVMGetInstructionOpcode(av) == 27) {
                                data_ptr2 = LLVMGetOperand(av, (u32)0);
                            }
                            if (data_ptr2 == (i8*)0) {
                                let mut tmp: *i8= LLVMBuildAlloca(ctx.llvm_builder, av_ty, "ms_tmp");
                                LLVMBuildStore(ctx.llvm_builder, av, tmp);
                                data_ptr2 = tmp;
                            }
                            let mut fat: *i8= LLVMGetUndef(ctx.memstr_fat_type);
                            fat = LLVMBuildInsertValue(ctx.llvm_builder, fat, data_ptr2, 0, "fat_d");
                            let mut ptr_t: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                            let mut vp: *i8= (vtbl != (i8*)0) ? vtbl : LLVMConstPointerNull(ptr_t);
                            fat = LLVMBuildInsertValue(ctx.llvm_builder, fat, vp, 1, "fat_v");
                            av = fat;
                        } else if (param_kind == LLVMPointerTypeKind && av_kind == LLVMStructTypeKind) {
                            // Struct arg where pointer expected: wrap in alloca.
                            let mut tmp: *i8= LLVMBuildAlloca(ctx.llvm_builder, av_ty, "ref_tmp");
                            LLVMBuildStore(ctx.llvm_builder, av, tmp);
                            av = tmp;
                        } else {
                            av = coerce_int_val(av, param_ts[pi], ctx.llvm_builder);
                        }
                    }
                    args[i + 1] = av;
                    i = i + 1;
                }
                arc_free((i8*)param_ts);
                let mut result: *i8= LLVMBuildCall2(ctx.llvm_builder, fn_ty, fn_ref, args, nargs, "");
                arc_free((i8*)args);
                return result;
            }
        }

        // ADT variant method: e.method() where e is an ADT enum value
        if (struct_name != (i8*)0 && method_name != (i8*)0) {
            let mut adt_ed_ptr_vm: *i8= sv_map_get(&ctx.adt_enum_decls, struct_name);
            if (adt_ed_ptr_vm != (i8*)0) {
                let mut adt_ed_vm: *parser.enum_decl= (parser.enum_decl*)adt_ed_ptr_vm;
                let mut vi_vm: i32= 0;
                while (vi_vm < adt_ed_vm.variants_len) {
                    let mut vkind_vm: i32= (adt_ed_vm.variant_kinds != (i32*)0) ? adt_ed_vm.variant_kinds[vi_vm] : 0;
                    if (vkind_vm == 2 || vkind_vm == 3) {
                        let mut adtmt_name: [512]i8;
                        snprintf(adtmt_name, (u64)512, "%s__NS_%s__MT_%s", struct_name, adt_ed_vm.variant_names[vi_vm], method_name);
                        let mut fn_vm: *i8= sv_map_get(&ctx.global_funcs,      adtmt_name);
                        let mut fn_ty_vm: *i8= st_map_get(&ctx.global_func_types, adtmt_name);
                        if (fn_vm != (i8*)0 && fn_ty_vm != (i8*)0) {
                            let mut nargs_vm: i32= e.args_len + 1;
                            let mut args_vm: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)nargs_vm);
                            args_vm[0] = obj_ptr;
                            let mut i_vm: i32= 0;
                            while (i_vm < e.args_len) {
                                args_vm[i_vm + 1] = visit_expr(e.args[i_vm], ctx);
                                i_vm = i_vm + 1;
                            }
                            let mut result_vm: *i8= LLVMBuildCall2(ctx.llvm_builder, fn_ty_vm, fn_vm, args_vm, nargs_vm, "");
                            arc_free((i8*)args_vm);
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
            let mut adt_ed_ptr: *i8= sv_map_get(&ctx.adt_enum_decls, obj_expr.str_val);
            if (adt_ed_ptr != (i8*)0) {
                let mut adt_ed: *parser.enum_decl= (parser.enum_decl*)adt_ed_ptr;
                // Find the variant index
                let mut var_idx: i32= -1;
                let mut vi: i32= 0;
                while (vi < adt_ed.variants_len) {
                    if (strcmp(adt_ed.variant_names[vi], method_name) == 0) { var_idx = vi; }
                    vi = vi + 1;
                }
                if (var_idx >= 0) {
                    let mut enum_st: *i8= st_map_get(&ctx.struct_types, obj_expr.str_val);
                    if (enum_st != (i8*)0) {
                        let mut alloca: *i8= LLVMBuildAlloca(ctx.llvm_builder, enum_st, "adt_ctor");
                        LLVMBuildStore(ctx.llvm_builder, LLVMConstNull(enum_st), alloca);
                        // Store tag at field 0
                        let mut tag_ptr: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, enum_st, alloca, 0, "adt_tag");
                        let mut i32t: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
                        LLVMBuildStore(ctx.llvm_builder, LLVMConstInt(i32t, (u64)var_idx, 0), tag_ptr);
                        // Store args into payload at byte offsets (field 1 = [N x i8])
                        let mut pay_ptr: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, enum_st, alloca, 1, "adt_pay");
                        let mut byte_off: u64= 0;
                        let mut ai: i32= 0;
                        while (ai < e.args_len) {
                            let mut av: *i8= visit_expr(e.args[ai], ctx);
                            if (av != (i8*)0) {
                                let mut av_t: *i8= LLVMTypeOf(av);
                                let mut av_sz: u64= llvm_type_byte_size(av_t);
                                // GEP into payload bytes
                                let mut i8t: *i8= LLVMInt8TypeInContext(ctx.llvm_ctx);
                                let mut arr_t: *i8= LLVMArrayType2(i8t, 1);
                                let mut fptr: *i8= LLVMBuildGEP2(ctx.llvm_builder, i8t, pay_ptr, (i8**)0, 0, "pay_elem");
                                // Build GEP with explicit byte offset
                                let mut idx_v: *i8= LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), byte_off, 0);
                                let mut elem: *i8= LLVMBuildGEP2(ctx.llvm_builder, i8t, pay_ptr, &idx_v, 1, "pay_elem");
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
            let mut ns_fn_name: [512]i8;
            snprintf(ns_fn_name, (u64)512, "%s__NS_%s", obj_expr.str_val, method_name);
            let mut ns_fn: *i8= sv_map_get(&ctx.global_funcs,      ns_fn_name);
            let mut ns_fn_ty: *i8= st_map_get(&ctx.global_func_types, ns_fn_name);
            if (ns_fn != (i8*)0 && ns_fn_ty != (i8*)0) {
                let mut nargs: i32= e.args_len;
                let mut args: **i8= (i8**)0;
                if (nargs > 0) {
                    args = (i8**)arc_malloc(sizeof(i8*) * (u64)nargs);
                    let mut i: i32= 0;
                    while (i < nargs) { args[i] = visit_expr(e.args[i], ctx); i = i + 1; }
                    coerce_args_full(ns_fn_ty, args, nargs, ctx);
                }
                let mut result: *i8= LLVMBuildCall2(ctx.llvm_builder, ns_fn_ty, ns_fn, args, nargs, "");
                if (args != (i8**)0) { arc_free((i8*)args); }
                return result;
            }
        }

        // Try multi-level namespace call: e.g. std.hash.fnv_hash_bytes(...)
        // Build the fully-qualified name from the entire callee chain.
        if (e.callee != (parser.expr_node*)0 && method_name != (i8*)0) {
            let mut chain_fn_name: [512]i8;
            if (build_ns_name_from_chain(e.callee, chain_fn_name, 512)) {
                let mut chain_fn: *i8= sv_map_get(&ctx.global_funcs,      chain_fn_name);
                let mut chain_fn_ty: *i8= st_map_get(&ctx.global_func_types, chain_fn_name);
                if (chain_fn != (i8*)0 && chain_fn_ty != (i8*)0) {
                    let mut nargs_ch: i32= e.args_len;
                    let mut args_ch: **i8= (i8**)0;
                    if (nargs_ch > 0) {
                        args_ch = (i8**)arc_malloc(sizeof(i8*) * (u64)nargs_ch);
                        let mut ic: i32= 0;
                        while (ic < nargs_ch) { args_ch[ic] = visit_expr(e.args[ic], ctx); ic = ic + 1; }
                        coerce_args_full(chain_fn_ty, args_ch, nargs_ch, ctx);
                    }
                    let mut result_ch: *i8= LLVMBuildCall2(ctx.llvm_builder, chain_fn_ty, chain_fn, args_ch, nargs_ch, "");
                    if (args_ch != (i8**)0) { arc_free((i8*)args_ch); }
                    return result_ch;
                }
            }
        }

        // Function pointer field: obj.field(args) where field stores a fn pointer.
        // field_pointee[idx] holds the LLVM function type (not ptr-to-fn) when the field
        // is a function pointer.
        if (struct_name != (i8*)0 && method_name != (i8*)0) {
            let mut fidx_fp: i32= ctx_field_index(ctx, struct_name, method_name);
            if (fidx_fp >= 0) {
                let mut sm_fp: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, struct_name);
                if (sm_fp != (struct_meta*)0 && fidx_fp < sm_fp.field_pointee.len) {
                    let mut fn_ty_fp: *i8= sm_fp.field_pointee.data[fidx_fp];
                    if (fn_ty_fp != (i8*)0 && LLVMGetTypeKind(fn_ty_fp) == LLVMFunctionTypeKind) {
                        let mut struct_t_fp: *i8= st_map_get(&ctx.struct_types, struct_name);
                        if (struct_t_fp != (i8*)0) {
                            let mut field_ptr_fp: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, struct_t_fp,
                                                            obj_ptr, (u32)fidx_fp, "fp_field");
                            let mut ptr_t_fp: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                            let mut fn_ptr_fp: *i8= LLVMBuildLoad2(ctx.llvm_builder, ptr_t_fp, field_ptr_fp, "fp_val");
                            let mut nargs_fp: i32= e.args_len;
                            let mut args_fp: **i8= (i8**)0;
                            if (nargs_fp > 0) {
                                args_fp = (i8**)arc_malloc(sizeof(i8*) * (u64)nargs_fp);
                                let mut iai: i32= 0;
                                while (iai < nargs_fp) {
                                    args_fp[iai] = visit_expr(e.args[iai], ctx);
                                    iai = iai + 1;
                                }
                            }
                            let mut call_res_fp: *i8= LLVMBuildCall2(ctx.llvm_builder, fn_ty_fp,
                                                          fn_ptr_fp, args_fp, nargs_fp, "");
                            if (args_fp != (i8**)0) { arc_free((i8*)args_fp); }
                            return call_res_fp;
                        }
                    }
                }
            }
        }
        return (i8*)0;
    }

    // Regular function call
    let mut fn_ref: *i8= (i8*)0;
    let mut fn_ty: *i8= (i8*)0;
    let mut callee_name: *i8= (i8*)0;

    if (e.callee.kind == ek_identifier) {
        callee_name = e.callee.str_val;
        fn_ref    = find_func(callee_name, ctx);
        fn_ty = find_func_type(callee_name, ctx);

        if (fn_ref == (i8*)0) {
            // Try as method in current class
            if (ctx.current_class_name != (i8*)0) {
                let mut mt_name: [512]i8;
                snprintf(mt_name, (u64)512, "%s__MT_%s", ctx.current_class_name, callee_name);
                fn_ref    = sv_map_get(&ctx.global_funcs,      mt_name);
                fn_ty = st_map_get(&ctx.global_func_types, mt_name);
            }
        }

        if (fn_ref == (i8*)0) {
            // Try as local function-pointer variable (indirect call).
            // In LLVM opaque-pointer mode LLVMGetElementType returns null, so we use
            // the function type stored at declaration time in local_func_types.
            let mut lfn_ty: *i8= ctx_lookup_local_func_type(ctx, callee_name);
            if (lfn_ty != (i8*)0) {
                let mut local_alloca: *i8= ctx_lookup_local(ctx, callee_name);
                if (local_alloca != (i8*)0) {
                    let mut ptr_t: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                    let mut fp: *i8= LLVMBuildLoad2(ctx.llvm_builder, ptr_t, local_alloca, "fp");
                    // For depth > 1 (**fn, ***fn, etc.) each extra level needs one more load
                    let mut fp_depth: i32= ctx_lookup_local_func_depth(ctx, callee_name);
                    let mut di: i32= 1;
                    while (di < fp_depth) {
                        fp = LLVMBuildLoad2(ctx.llvm_builder, ptr_t, fp, "fp_deref");
                        di = di + 1;
                    }
                    let mut nargs2: i32= e.args_len;
                    let mut args2: **i8= (i8**)0;
                    if (nargs2 > 0) {
                        args2 = (i8**)arc_malloc(sizeof(i8*) * (u64)nargs2);
                        let mut i: i32= 0;
                        while (i < nargs2) {
                            args2[i] = visit_expr(e.args[i], ctx);
                            i = i + 1;
                        }
                    }
                    if (args2 != (i8**)0) {
                        coerce_args_to_fn(lfn_ty, args2, nargs2, ctx.llvm_builder);
                    }
                    let mut result2: *i8= LLVMBuildCall2(ctx.llvm_builder, lfn_ty, fp, args2, nargs2, "");
                    if (args2 != (i8**)0) { arc_free((i8*)args2); }
                    return result2;
                }
            }
        }
    } else {
        // (*name)() — explicit deref of a local function pointer.
        // The generic computed-callee path uses LLVMGetElementType which is broken
        // in LLVM 15+ opaque-pointer mode, so intercept this case early and use
        // the same loading logic as the direct identifier path.
        if (e.callee.kind == ek_unary && e.callee.uop == uop_deref &&
                e.callee.operand != (parser.expr_node*)0 &&
                e.callee.operand.kind == ek_identifier) {
            let mut deref_name: *i8= e.callee.operand.str_val;
            let mut lfn_ty2: *i8= ctx_lookup_local_func_type(ctx, deref_name);
            if (lfn_ty2 != (i8*)0) {
                let mut la2: *i8= ctx_lookup_local(ctx, deref_name);
                if (la2 != (i8*)0) {
                    let mut ptr_t2: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                    let mut fp2: *i8= LLVMBuildLoad2(ctx.llvm_builder, ptr_t2, la2, "fp");
                    let mut fp_depth2: i32= ctx_lookup_local_func_depth(ctx, deref_name);
                    let mut di2: i32= 1;
                    while (di2 < fp_depth2) {
                        fp2 = LLVMBuildLoad2(ctx.llvm_builder, ptr_t2, fp2, "fp_deref");
                        di2 = di2 + 1;
                    }
                    let mut nargs3: i32= e.args_len;
                    let mut args3: **i8= (i8**)0;
                    if (nargs3 > 0) {
                        args3 = (i8**)arc_malloc(sizeof(i8*) * (u64)nargs3);
                        let mut ii3: i32= 0;
                        while (ii3 < nargs3) {
                            args3[ii3] = visit_expr(e.args[ii3], ctx);
                            ii3 = ii3 + 1;
                        }
                    }
                    if (args3 != (i8**)0) { coerce_args_to_fn(lfn_ty2, args3, nargs3, ctx.llvm_builder); }
                    let mut result3: *i8= LLVMBuildCall2(ctx.llvm_builder, lfn_ty2, fp2, args3, nargs3, "");
                    if (args3 != (i8**)0) { arc_free((i8*)args3); }
                    return result3;
                }
            }
        }
        // Computed callee (lambda or function pointer expression)
        let mut fp: *i8= visit_expr(e.callee, ctx);
        if (fp == (i8*)0) { return (i8*)0; }
        // For ek_lambda callee, visit_expr returns the LLVM function value directly;
        // use LLVMGlobalGetValueType to obtain its function type (avoids the
        // LLVMGetElementType null-return in LLVM 15+ opaque-pointer mode).
        if (e.callee.kind == ek_lambda) {
            fn_ty = LLVMGlobalGetValueType(fp);
        } else if (e.callee.kind == ek_subscript && e.callee.object != (parser.expr_node*)0 &&
                   e.callee.object.kind == ek_identifier && e.callee.index != (parser.expr_node*)0 &&
                   e.callee.index.kind == ek_int_lit) {
            // ADT tuple subscript call: baz[0](...) — look up raw function type from ADT metadata
            let mut adt_obj_name: *i8= e.callee.object.str_val;
            let mut adt_obj_lt: *i8= ctx_lookup_local_type(ctx, adt_obj_name);
            if (adt_obj_lt != (i8*)0 && LLVMGetTypeKind(adt_obj_lt) == LLVMStructTypeKind) {
                let mut adt_obj_sn: *i8= LLVMGetStructName(adt_obj_lt);
                if (adt_obj_sn != (i8*)0) {
                    let mut adt_obj_ed_p: *i8= sv_map_get(&ctx.adt_enum_decls, adt_obj_sn);
                    if (adt_obj_ed_p != (i8*)0) {
                        let mut adt_fidx_call: i32= (i32)e.callee.index.int_val;
                        fn_ty = adt_tuple_field_fn_type((parser.enum_decl*)adt_obj_ed_p, adt_fidx_call, ctx);
                    }
                }
            }
            if (fn_ty == (i8*)0) {
                fn_ty = LLVMGlobalGetValueType(fp);
            }
        } else {
            fn_ty = LLVMGlobalGetValueType(fp);
            if (fn_ty == (i8*)0) {
                let mut fp_type: *i8= LLVMTypeOf(fp);
                let mut fk: i32= LLVMGetTypeKind(fp_type);
                if (fk == LLVMPointerTypeKind) { fn_ty = LLVMGetElementType(fp_type); }
            }
        }
        if (fn_ty == (i8*)0) { return (i8*)0; }
        let mut nargs: i32= e.args_len;
        let mut args: **i8= (i8**)0;
        if (nargs > 0) {
            args = (i8**)arc_malloc(sizeof(i8*) * (u64)nargs);
            let mut i: i32= 0;
            while (i < nargs) {
                args[i] = visit_expr(e.args[i], ctx);
                i = i + 1;
            }
        }
        let mut result: *i8= LLVMBuildCall2(ctx.llvm_builder, fn_ty, fp, args, nargs, "");
        if (args != (i8**)0) { arc_free((i8*)args); }
        return result;
    }

    // Generic monomorphization: if call has type_args and callee is a generic function
    if (fn_ref == (i8*)0 && callee_name != (i8*)0 && e.type_args_len > 0) {
        let mut gfd_ptr: *i8= sv_map_get(&ctx.generic_funcs, callee_name);
        if (gfd_ptr != (i8*)0) {
            let mut gfd: *parser.func_decl= (parser.func_decl*)gfd_ptr;
            // Build specialized name: callee__mono_T1_T2
            let mut mono_name: [512]i8;
            let mut mn_off: i32= snprintf(mono_name, (u64)512, "%s__mono", callee_name);
            let mut tai: i32= 0;
            while (tai < e.type_args_len) {
                let mut ta: *parser.type_node= e.type_args[tai];
                let mut ta_str: [64]i8;
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
                let mut tl: i32= (i32)strlen(ta_str);
                if (mn_off + tl < 510) {
                    let mut ci: i32= 0;
                    while (ci < tl) { mono_name[mn_off + ci] = ta_str[ci]; ci = ci + 1; }
                    mn_off = mn_off + tl;
                    mono_name[mn_off] = 0;
                }
                tai = tai + 1;
            }
            let mut mono_name_dup: *i8= lexer.str_dup(mono_name);

            // Check if already instantiated
            fn_ref    = sv_map_get(&ctx.global_funcs,      mono_name_dup);
            fn_ty = st_map_get(&ctx.global_func_types, mono_name_dup);

            if (fn_ref == (i8*)0 || fn_ty == (i8*)0) {
                // Bind type parameters
                let mut tp_i: i32= 0;
                while (tp_i < gfd.type_params_len && tp_i < e.type_args_len) {
                    let mut param_name: *i8= gfd.type_params[tp_i];
                    let mut ta: *parser.type_node= e.type_args[tp_i];
                    let mut ta_llvm: *i8= llvm_type_of(ta, ctx);
                    st_map_set(&ctx.type_param_bindings, param_name, ta_llvm);
                    tp_i = tp_i + 1;
                }

                // Temporarily rename and hide type params for prototype/body generation
                let mut saved_name: *i8= gfd.name;
                let mut saved_mangle: *i8= gfd.mangled_name;
                let mut saved_tp_len: i32= gfd.type_params_len;
                gfd.name            = mono_name_dup;
                gfd.mangled_name    = (i8*)0;
                gfd.type_params_len = 0; // suppress generic guard in visit_func_decl_*

                // Save builder/context state
                let mut saved_bb: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
                let mut saved_func: *i8= ctx.current_func;
                let mut saved_func_ty: *i8= ctx.current_func_type;
                let mut saved_ret_ty: *i8= ctx.current_ret_type;
                let mut saved_is_eu: bool= ctx.current_func_is_error_union;
                let mut saved_eu_ty: *i8= ctx.current_error_union_type;
                let mut saved_eu_is_val: bool= ctx.current_func_eu_is_value;
                let mut saved_eu_val_ty: *i8= ctx.current_eu_value_type;
                let mut saved_cls: *i8= ctx.current_class_name;

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
                ctx.current_func_eu_is_value  = saved_eu_is_val;
                ctx.current_eu_value_type     = saved_eu_val_ty;
                ctx.current_class_name        = saved_cls;
                LLVMPositionBuilderAtEnd(ctx.llvm_builder, saved_bb);

                // Clear type param bindings
                tp_i = 0;
                while (tp_i < gfd.type_params_len) {
                    st_map_set(&ctx.type_param_bindings, gfd.type_params[tp_i], (i8*)0);
                    tp_i = tp_i + 1;
                }

                fn_ref    = sv_map_get(&ctx.global_funcs,      mono_name_dup);
                fn_ty = st_map_get(&ctx.global_func_types, mono_name_dup);
            }
        }
    }

    // Comptime type params: call has ek_cstype args that provide type bindings
    // e.g. zero_val(i32) where fn zero_val(comptime T: type) T { ... }
    if (fn_ref == (i8*)0 && callee_name != (i8*)0) {
        let mut gfd_ct_ptr: *i8= sv_map_get(&ctx.generic_funcs, callee_name);
        if (gfd_ct_ptr != (i8*)0) {
            let mut gfd_ct: *parser.func_decl= (parser.func_decl*)gfd_ct_ptr;
            // Count ek_cstype args and non-cstype args
            let mut ct_type_count: i32= 0;
            let mut ct_i: i32= 0;
            while (ct_i < e.args_len) {
                if (e.args[ct_i] != (parser.expr_node*)0 && e.args[ct_i].kind == ek_cstype) {
                    ct_type_count = ct_type_count + 1;
                }
                ct_i = ct_i + 1;
            }
            // Only handle if there are ek_cstype args matching comptime type params
            // AND the number of type args from cstype == gfd_ct.type_params_len
            let mut real_arg_count: i32= e.args_len - ct_type_count;
            if (ct_type_count > 0 && ct_type_count <= gfd_ct.type_params_len) {
                // Build mono name and bind type params from ek_cstype args
                let mut ct_mono: [512]i8;
                let mut ct_off: i32= snprintf(ct_mono, (u64)512, "%s__mono", callee_name);
                let mut ct_ok: bool= true;
                let mut tp_ct: i32= 0;
                ct_i = 0;
                while (ct_i < e.args_len && tp_ct < gfd_ct.type_params_len) {
                    if (e.args[ct_i] != (parser.expr_node*)0 && e.args[ct_i].kind == ek_cstype) {
                        let mut ct_tn: *parser.type_node= e.args[ct_i].cast_type;
                        if (ct_tn == (parser.type_node*)0) { ct_ok = false; }
                        else {
                            let mut ct_llvm: *i8= llvm_type_of(ct_tn, ctx);
                            if (ct_llvm == (i8*)0) { ct_ok = false; }
                            else {
                                let mut tpname_ct: *i8= gfd_ct.type_params[tp_ct];
                                st_map_set(&ctx.type_param_bindings, tpname_ct, ct_llvm);
                                // Append suffix for name mangling
                                let mut tk_ct: i32= LLVMGetTypeKind(ct_llvm);
                                let mut ts_ct: [64]i8;
                                if (tk_ct == LLVMIntegerTypeKind) {
                                    let mut bw_ct: u32= LLVMGetIntTypeWidth(ct_llvm);
                                    snprintf(ts_ct, (u64)64, "_i%d", (i32)bw_ct);
                                } else if (tk_ct == LLVMFloatTypeKind) {
                                    snprintf(ts_ct, (u64)64, "_f32");
                                } else if (tk_ct == LLVMDoubleTypeKind) {
                                    snprintf(ts_ct, (u64)64, "_f64");
                                } else if (tk_ct == LLVMPointerTypeKind) {
                                    snprintf(ts_ct, (u64)64, "_ptr");
                                } else if (tk_ct == LLVMStructTypeKind) {
                                    let mut sn_ct: *i8= LLVMGetStructName(ct_llvm);
                                    if (sn_ct != (i8*)0) { snprintf(ts_ct, (u64)64, "_%s", sn_ct); }
                                    else { snprintf(ts_ct, (u64)64, "_struct"); }
                                } else {
                                    snprintf(ts_ct, (u64)64, "_T");
                                }
                                let mut tl_ct: i32= (i32)strlen(ts_ct);
                                if (ct_off + tl_ct < 510) {
                                    let mut ci_ct: i32= 0;
                                    while (ci_ct < tl_ct) { ct_mono[ct_off + ci_ct] = ts_ct[ci_ct]; ci_ct = ci_ct + 1; }
                                    ct_off = ct_off + tl_ct;
                                    ct_mono[ct_off] = 0;
                                }
                                tp_ct = tp_ct + 1;
                            }
                        }
                    }
                    ct_i = ct_i + 1;
                }
                if (ct_ok && tp_ct == ct_type_count) {
                    let mut ct_mdup: *i8= lexer.str_dup(ct_mono);
                    fn_ref = sv_map_get(&ctx.global_funcs,      ct_mdup);
                    fn_ty  = st_map_get(&ctx.global_func_types, ct_mdup);
                    if (fn_ref == (i8*)0 || fn_ty == (i8*)0) {
                        let mut saved_name_ct: *i8= gfd_ct.name;
                        let mut saved_mangle_ct: *i8= gfd_ct.mangled_name;
                        let mut saved_tplen_ct: i32= gfd_ct.type_params_len;
                        gfd_ct.name            = ct_mdup;
                        gfd_ct.mangled_name    = (i8*)0;
                        gfd_ct.type_params_len = 0;
                        let mut saved_bb_ct: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
                        let mut saved_func_ct: *i8= ctx.current_func;
                        let mut saved_fty_ct: *i8= ctx.current_func_type;
                        let mut saved_rty_ct: *i8= ctx.current_ret_type;
                        let mut saved_eu_ct: bool= ctx.current_func_is_error_union;
                        let mut saved_euty_ct: *i8= ctx.current_error_union_type;
                        let mut saved_eu_isval_ct: bool= ctx.current_func_eu_is_value;
                        let mut saved_eu_valty_ct: *i8= ctx.current_eu_value_type;
                        let mut saved_cls_ct: *i8= ctx.current_class_name;
                        visit_func_decl_prototype(gfd_ct, ctx);
                        visit_func_decl(gfd_ct, ctx);
                        gfd_ct.name            = saved_name_ct;
                        gfd_ct.mangled_name    = saved_mangle_ct;
                        gfd_ct.type_params_len = saved_tplen_ct;
                        ctx.current_func              = saved_func_ct;
                        ctx.current_func_type         = saved_fty_ct;
                        ctx.current_ret_type          = saved_rty_ct;
                        ctx.current_func_is_error_union = saved_eu_ct;
                        ctx.current_error_union_type  = saved_euty_ct;
                        ctx.current_func_eu_is_value  = saved_eu_isval_ct;
                        ctx.current_eu_value_type     = saved_eu_valty_ct;
                        ctx.current_class_name        = saved_cls_ct;
                        LLVMPositionBuilderAtEnd(ctx.llvm_builder, saved_bb_ct);
                        // Clear type param bindings
                        tp_ct = 0;
                        while (tp_ct < gfd_ct.type_params_len) {
                            st_map_set(&ctx.type_param_bindings, gfd_ct.type_params[tp_ct], (i8*)0);
                            tp_ct = tp_ct + 1;
                        }
                        fn_ref = sv_map_get(&ctx.global_funcs,      ct_mdup);
                        fn_ty  = st_map_get(&ctx.global_func_types, ct_mdup);
                    } else {
                        // Already instantiated — clear bindings
                        tp_ct = 0;
                        while (tp_ct < gfd_ct.type_params_len) {
                            st_map_set(&ctx.type_param_bindings, gfd_ct.type_params[tp_ct], (i8*)0);
                            tp_ct = tp_ct + 1;
                        }
                    }
                    // If resolved: build real_args (excluding ek_cstype nodes), then call
                    if (fn_ref != (i8*)0 && fn_ty != (i8*)0) {
                        let mut ct_real_args: **i8= (i8**)0;
                        if (real_arg_count > 0) {
                            ct_real_args = (i8**)arc_malloc(sizeof(i8*) * (u64)real_arg_count);
                            let mut rai: i32= 0;
                            ct_i = 0;
                            while (ct_i < e.args_len) {
                                if (e.args[ct_i] == (parser.expr_node*)0 || e.args[ct_i].kind != ek_cstype) {
                                    ct_real_args[rai] = visit_expr(e.args[ct_i], ctx);
                                    rai = rai + 1;
                                }
                                ct_i = ct_i + 1;
                            }
                            coerce_args_to_fn(fn_ty, ct_real_args, real_arg_count, ctx.llvm_builder);
                        }
                        let mut ct_result: *i8= LLVMBuildCall2(ctx.llvm_builder, fn_ty, fn_ref, ct_real_args, real_arg_count, "");
                        if (ct_real_args != (i8**)0) { arc_free((i8*)ct_real_args); }
                        return ct_result;
                    }
                } else {
                    // Failed — clear partial bindings
                    tp_ct = 0;
                    while (tp_ct < gfd_ct.type_params_len) {
                        st_map_set(&ctx.type_param_bindings, gfd_ct.type_params[tp_ct], (i8*)0);
                        tp_ct = tp_ct + 1;
                    }
                }
            }
        }
    }

    // Generic type inference: call has no type_args but callee is generic — infer from args
    if (fn_ref == (i8*)0 && callee_name != (i8*)0 && e.type_args_len == 0) {
        let mut gfd_ptr: *i8= sv_map_get(&ctx.generic_funcs, callee_name);
        if (gfd_ptr != (i8*)0) {
            let mut gfd: *parser.func_decl= (parser.func_decl*)gfd_ptr;
            // Evaluate args to infer types
            let mut nai: i32= e.args_len;
            let mut infer_vals: **i8= (i8**)0;
            if (nai > 0) {
                infer_vals = (i8**)arc_malloc(sizeof(i8*) * (u64)nai);
                let mut ii: i32= 0;
                while (ii < nai) {
                    infer_vals[ii] = visit_expr(e.args[ii], ctx);
                    ii = ii + 1;
                }
            }
            // Build mono_name by matching type params to arg types
            let mut mono_name_inf: [512]i8;
            let mut mn_off_inf: i32= snprintf(mono_name_inf, (u64)512, "%s__mono", callee_name);
            let mut tp_i: i32= 0;
            let mut infer_ok: bool= gfd.type_params_len > 0;
            while (tp_i < gfd.type_params_len) {
                let mut tpname: *i8= gfd.type_params[tp_i];
                // Find first param whose type node name matches this type param
                let mut inferred_ty: *i8= (i8*)0;
                let mut pi: i32= 0;
                while (pi < gfd.params_len && inferred_ty == (i8*)0) {
                    let mut pd: parser.param_decl= gfd.params[pi];
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
                    let mut tk: i32= LLVMGetTypeKind(inferred_ty);
                    let mut ta_s: [64]i8;
                    if (tk == LLVMIntegerTypeKind) {
                        let mut bw: u32= LLVMGetIntTypeWidth(inferred_ty);
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
                    let mut tl: i32= (i32)strlen(ta_s);
                    if (mn_off_inf + tl < 510) {
                        let mut ci: i32= 0;
                        while (ci < tl) { mono_name_inf[mn_off_inf + ci] = ta_s[ci]; ci = ci + 1; }
                        mn_off_inf = mn_off_inf + tl;
                        mono_name_inf[mn_off_inf] = 0;
                    }
                }
                tp_i = tp_i + 1;
            }
            if (infer_ok) {
                let mut mni_dup: *i8= lexer.str_dup(mono_name_inf);
                fn_ref    = sv_map_get(&ctx.global_funcs,      mni_dup);
                fn_ty = st_map_get(&ctx.global_func_types, mni_dup);
                if (fn_ref == (i8*)0 || fn_ty == (i8*)0) {
                    let mut saved_name2: *i8= gfd.name;
                    let mut saved_mangle2: *i8= gfd.mangled_name;
                    let mut saved_tp_len2: i32= gfd.type_params_len;
                    gfd.name            = mni_dup;
                    gfd.mangled_name    = (i8*)0;
                    gfd.type_params_len = 0;
                    let mut saved_bb2: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
                    let mut saved_func2: *i8= ctx.current_func;
                    let mut saved_fty2: *i8= ctx.current_func_type;
                    let mut saved_rty2: *i8= ctx.current_ret_type;
                    let mut saved_eu2: bool= ctx.current_func_is_error_union;
                    let mut saved_euty2: *i8= ctx.current_error_union_type;
                    let mut saved_eu_isval2: bool= ctx.current_func_eu_is_value;
                    let mut saved_eu_valty2: *i8= ctx.current_eu_value_type;
                    let mut saved_cls2: *i8= ctx.current_class_name;
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
                    ctx.current_func_eu_is_value  = saved_eu_isval2;
                    ctx.current_eu_value_type     = saved_eu_valty2;
                    ctx.current_class_name        = saved_cls2;
                    LLVMPositionBuilderAtEnd(ctx.llvm_builder, saved_bb2);
                    // Clear type param bindings
                    tp_i = 0;
                    while (tp_i < gfd.type_params_len) {
                        st_map_set(&ctx.type_param_bindings, gfd.type_params[tp_i], (i8*)0);
                        tp_i = tp_i + 1;
                    }
                    fn_ref    = sv_map_get(&ctx.global_funcs,      mni_dup);
                    fn_ty = st_map_get(&ctx.global_func_types, mni_dup);
                }
                // If monomorphization succeeded, use inferred_vals as pre-evaluated args
                if (fn_ref != (i8*)0 && fn_ty != (i8*)0) {
                    let mut ni2: i32= e.args_len;
                    if (infer_vals != (i8**)0) {
                        coerce_args_to_fn(fn_ty, infer_vals, ni2, ctx.llvm_builder);
                    }
                    let mut result: *i8= LLVMBuildCall2(ctx.llvm_builder, fn_ty, fn_ref, infer_vals, ni2, "");
                    if (infer_vals != (i8**)0) { arc_free((i8*)infer_vals); }
                    return result;
                }
            }
            if (infer_vals != (i8**)0) { arc_free((i8*)infer_vals); }
            // Clear any partial bindings
            tp_i = 0;
            while (tp_i < gfd.type_params_len) {
                st_map_set(&ctx.type_param_bindings, gfd.type_params[tp_i], (i8*)0);
                tp_i = tp_i + 1;
            }
        }
    }

    // anytype monomorphization: compile specialized version per concrete arg type
    if (fn_ref == (i8*)0 && callee_name != (i8*)0 && !ctx.in_anytype_mono) {
        let mut atfd_ptr: *i8= sv_map_get(&ctx.anytype_funcs, callee_name);
        if (atfd_ptr != (i8*)0) {
            let mut atfd: *parser.func_decl= (parser.func_decl*)atfd_ptr;
            // Evaluate args to get concrete types
            let mut at_nargs: i32= e.args_len;
            let mut at_vals: **i8= (i8**)0;
            if (at_nargs > 0) {
                at_vals = (i8**)arc_malloc(sizeof(i8*) * (u64)at_nargs);
                let mut aii: i32= 0;
                while (aii < at_nargs) {
                    at_vals[aii] = visit_expr(e.args[aii], ctx);
                    aii = aii + 1;
                }
            }
            // Build mangled mono name: funcname__at_paramname_TYPE...
            let mut at_mono_name: [512]i8;
            let mut at_off: i32= snprintf(at_mono_name, (u64)512, "%s", callee_name);
            let mut atpi2: i32= 0;
            while (atpi2 < atfd.params_len) {
                let mut ap: parser.param_decl= atfd.params[atpi2];
                if (ap.type != (parser.type_node*)0 && ap.type.is_anytype && atpi2 < at_nargs) {
                    let mut av: *i8= at_vals != (i8**)0 ? at_vals[atpi2] : (i8*)0;
                    let mut at_ty: *i8= av != (i8*)0 ? LLVMTypeOf(av) : (i8*)0;
                    if (at_ty != (i8*)0 && ap.name != (i8*)0) {
                        st_map_set(&ctx.anytype_param_bindings, ap.name, at_ty);
                        // Append suffix based on LLVM type kind
                        let mut tk2: i32= LLVMGetTypeKind(at_ty);
                        let mut ts2: [64]i8;
                        if (tk2 == LLVMIntegerTypeKind) {
                            let mut bw2: u32= LLVMGetIntTypeWidth(at_ty);
                            snprintf(ts2, (u64)64, "__at_%s_i%d", ap.name, (i32)bw2);
                        } else if (tk2 == LLVMFloatTypeKind) {
                            snprintf(ts2, (u64)64, "__at_%s_f32", ap.name);
                        } else if (tk2 == LLVMDoubleTypeKind) {
                            snprintf(ts2, (u64)64, "__at_%s_f64", ap.name);
                        } else if (tk2 == LLVMPointerTypeKind) {
                            snprintf(ts2, (u64)64, "__at_%s_ptr", ap.name);
                        } else if (tk2 == LLVMStructTypeKind) {
                            snprintf(ts2, (u64)64, "__at_%s_struct", ap.name);
                        } else {
                            snprintf(ts2, (u64)64, "__at_%s_T", ap.name);
                        }
                        let mut tslen: i32= (i32)strlen(ts2);
                        if (at_off + tslen < 510) {
                            let mut ci2: i32= 0;
                            while (ci2 < tslen) { at_mono_name[at_off + ci2] = ts2[ci2]; ci2 = ci2 + 1; }
                            at_off = at_off + tslen;
                            at_mono_name[at_off] = 0;
                        }
                    }
                }
                atpi2 = atpi2 + 1;
            }
            let mut at_mname: *i8= lexer.str_dup(at_mono_name);
            fn_ref = sv_map_get(&ctx.global_funcs, at_mname);
            fn_ty  = st_map_get(&ctx.global_func_types, at_mname);
            if (fn_ref == (i8*)0 || fn_ty == (i8*)0) {
                // Compile specialization
                let mut saved_atname: *i8= atfd.name;
                let mut saved_at_mangle: *i8= atfd.mangled_name;
                let mut saved_at_bb: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
                let mut saved_at_func: *i8= ctx.current_func;
                let mut saved_at_fty: *i8= ctx.current_func_type;
                let mut saved_at_rty: *i8= ctx.current_ret_type;
                let mut saved_at_eu: bool= ctx.current_func_is_error_union;
                let mut saved_at_euty: *i8= ctx.current_error_union_type;
                let mut saved_at_eu_isval: bool= ctx.current_func_eu_is_value;
                let mut saved_at_eu_valty: *i8= ctx.current_eu_value_type;
                let mut saved_at_cls: *i8= ctx.current_class_name;
                atfd.name         = at_mname;
                atfd.mangled_name = (i8*)0;
                ctx.in_anytype_mono = true;
                visit_func_decl_prototype(atfd, ctx);
                visit_func_decl(atfd, ctx);
                ctx.in_anytype_mono = false;
                atfd.name         = saved_atname;
                atfd.mangled_name = saved_at_mangle;
                ctx.current_func              = saved_at_func;
                ctx.current_func_type         = saved_at_fty;
                ctx.current_ret_type          = saved_at_rty;
                ctx.current_func_is_error_union = saved_at_eu;
                ctx.current_error_union_type  = saved_at_euty;
                ctx.current_func_eu_is_value  = saved_at_eu_isval;
                ctx.current_eu_value_type     = saved_at_eu_valty;
                ctx.current_class_name        = saved_at_cls;
                LLVMPositionBuilderAtEnd(ctx.llvm_builder, saved_at_bb);
                fn_ref = sv_map_get(&ctx.global_funcs, at_mname);
                fn_ty  = st_map_get(&ctx.global_func_types, at_mname);
            }
            // Clear anytype param bindings for next call
            atpi2 = 0;
            while (atpi2 < atfd.params_len) {
                let mut ap2: parser.param_decl= atfd.params[atpi2];
                if (ap2.type != (parser.type_node*)0 && ap2.type.is_anytype && ap2.name != (i8*)0) {
                    st_map_set(&ctx.anytype_param_bindings, ap2.name, (i8*)0);
                }
                atpi2 = atpi2 + 1;
            }
            if (fn_ref != (i8*)0 && fn_ty != (i8*)0) {
                if (at_vals != (i8**)0) {
                    coerce_args_to_fn(fn_ty, at_vals, at_nargs, ctx.llvm_builder);
                }
                let mut at_result: *i8= LLVMBuildCall2(ctx.llvm_builder, fn_ty, fn_ref, at_vals, at_nargs, "");
                if (at_vals != (i8**)0) { arc_free((i8*)at_vals); }
                return at_result;
            }
            if (at_vals != (i8**)0) { arc_free((i8*)at_vals); }
        }
    }

    if (fn_ref == (i8*)0 && callee_name != (i8*)0) {
        // Lazily synthesise __derive_Clone_StructName(StructType* self) -> StructType
        let mut clone_prefix: *i8= "__derive_Clone_";
        let mut clone_prefix_len: u64= (u64)strlen(clone_prefix);
        if (strncmp(callee_name, clone_prefix, clone_prefix_len) == 0) {
            let mut sname: *i8= callee_name + (i64)clone_prefix_len;
            let mut st: *i8= st_map_get(&ctx.struct_types, sname);
            if (st != (i8*)0) {
                let mut ptr_t: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                let mut param_types: [1]*i8;
                param_types[0] = ptr_t;
                fn_ty = LLVMFunctionType(st, param_types, 1, 0);
                fn_ref = LLVMAddFunction(ctx.llvm_mod, callee_name, fn_ty);
                let mut entry_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "entry");
                let mut saved_bb: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
                LLVMPositionBuilderAtEnd(ctx.llvm_builder, entry_bb);
                let mut self_param: *i8= LLVMGetParam(fn_ref, 0);
                let mut loaded: *i8= LLVMBuildLoad2(ctx.llvm_builder, st, self_param, "clone");
                LLVMBuildRet(ctx.llvm_builder, loaded);
                LLVMPositionBuilderAtEnd(ctx.llvm_builder, saved_bb);
                sv_map_set(&ctx.global_funcs,      lexer.str_dup(callee_name), fn_ref);
                st_map_set(&ctx.global_func_types, lexer.str_dup(callee_name), fn_ty);
            }
        }
    }

    if (fn_ref == (i8*)0 || fn_ty == (i8*)0) {
        // Unknown function — emit nothing (or emit an intrinsic call)
        return (i8*)0;
    }

    let mut nargs: i32= e.args_len;
    let mut args: **i8= (i8**)0;
    if (nargs > 0) {
        args = (i8**)arc_malloc(sizeof(i8*) * (u64)nargs);
        let mut i: i32= 0;
        while (i < nargs) {
            args[i] = visit_expr(e.args[i], ctx);
            i = i + 1;
        }
        coerce_args_full(fn_ty, args, nargs, ctx);
        // Interface fat-pointer coercion: if callee param is *InterfaceName and arg is a raw
        // concrete struct pointer, build a fat pointer { data_ptr, vtable_ptr } and pass a
        // pointer to that fat struct (since *Foo = ptr to fat { data, vtable }).
        let mut fd_ptr: *i8= (callee_name != (i8*)0) ? sv_map_get(&ctx.global_func_decls, callee_name) : (i8*)0;
        if (fd_ptr != (i8*)0) {
            let mut fd_call: *parser.func_decl= (parser.func_decl*)fd_ptr;
            let mut pi_ifc: i32= 0;
            while (pi_ifc < nargs && pi_ifc < fd_call.params_len) {
                let mut pt_ifc: *parser.type_node= fd_call.params[pi_ifc].type;
                if (pt_ifc != (parser.type_node*)0 && pt_ifc.pointer_depth > 0 && pt_ifc.name != (i8*)0) {
                    let mut iface_vt: *i8= st_map_get(&ctx.iface_vtable_types, pt_ifc.name);
                    if (iface_vt != (i8*)0 && args[pi_ifc] != (i8*)0) {
                        let mut av_kind: i32= LLVMGetTypeKind(LLVMTypeOf(args[pi_ifc]));
                        if (av_kind == LLVMPointerTypeKind) {
                            // Try to identify the concrete type from the argument expression
                            let mut arg_expr: *parser.expr_node= e.args[pi_ifc];
                            let mut concrete_name: *i8= (i8*)0;
                            if (arg_expr != (parser.expr_node*)0 && arg_expr.kind == ek_unary &&
                                    arg_expr.uop == uop_addr_of && arg_expr.operand != (parser.expr_node*)0) {
                                let mut st_inf: *i8= infer_expr_struct_type(arg_expr.operand, ctx);
                                if (st_inf != (i8*)0) { concrete_name = LLVMGetStructName(st_inf); }
                            }
                            if (concrete_name == (i8*)0) {
                                // Try identifier directly
                                let mut st_dir: *i8= (e.args[pi_ifc] != (parser.expr_node*)0) ?
                                    infer_expr_struct_type(e.args[pi_ifc], ctx) : (i8*)0;
                                if (st_dir != (i8*)0) { concrete_name = LLVMGetStructName(st_dir); }
                            }
                            if (concrete_name != (i8*)0) {
                                let mut vtbl_key: [512]i8;
                                snprintf(vtbl_key, (u64)512, "%s__IFACE__%s", concrete_name, pt_ifc.name);
                                let mut vtbl_gv: *i8= sv_map_get(&ctx.iface_concrete_vtables, vtbl_key);
                                if (vtbl_gv != (i8*)0) {
                                    let mut iface_st_ty: *i8= st_map_get(&ctx.struct_types, pt_ifc.name);
                                    if (iface_st_ty != (i8*)0) {
                                        let mut fat_ifc: *i8= LLVMGetUndef(iface_st_ty);
                                        fat_ifc = LLVMBuildInsertValue(ctx.llvm_builder, fat_ifc, args[pi_ifc], 0, "ifc_d");
                                        fat_ifc = LLVMBuildInsertValue(ctx.llvm_builder, fat_ifc, vtbl_gv, 1, "ifc_v");
                                        let mut fat_alloca: *i8= LLVMBuildAlloca(ctx.llvm_builder, iface_st_ty, "ifc_tmp");
                                        LLVMBuildStore(ctx.llvm_builder, fat_ifc, fat_alloca);
                                        args[pi_ifc] = fat_alloca;
                                    }
                                }
                            }
                        }
                    }
                }
                pi_ifc = pi_ifc + 1;
            }
        }
    }
    let mut result: *i8= LLVMBuildCall2(ctx.llvm_builder, fn_ty, fn_ref, args, nargs, "");
    if (args != (i8**)0) { arc_free((i8*)args); }
    return result;
}

// Gets or creates the __artemis_error_t LLVM struct type in the IR context.
fn get_error_struct_type(ctx: *ir_context, i32_t: *i8) *i8 {
    let mut err_struct_t: *i8= st_map_get(&ctx.struct_types, "__artemis_error_t");
    if (err_struct_t == (i8*)0) {
        err_struct_t = LLVMStructCreateNamed(ctx.llvm_ctx, "__artemis_error_t");
        let mut ptrt: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
        let mut flds: [2]*i8;
        flds[0] = i32_t;
        flds[1] = ptrt;
        LLVMStructSetBody(err_struct_t, flds, 2, 0);
        st_map_set(&ctx.struct_types, "__artemis_error_t", err_struct_t);
        let mut esm: struct_meta;
        esm.name = "__artemis_error_t";
        esm.is_union = false;
        esm.is_istruc = false;
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
fn get_error_payload_global(ctx: *ir_context) *i8 {
    let mut payload_gv: *i8= sv_map_get(&ctx.global_vars, "__artemis_error_payload");
    if (payload_gv == (i8*)0) {
        let mut ptrt: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
        payload_gv = LLVMAddGlobal(ctx.llvm_mod, ptrt, "__artemis_error_payload");
        LLVMSetInitializer(payload_gv, LLVMConstNull(ptrt));
        sv_map_set(&ctx.global_vars, "__artemis_error_payload", payload_gv);
    }
    return payload_gv;
}

// Emit error-variable binding (if any) and then visit the handler block.
fn visit_except_handler(e: *parser.expr_node, ctx: *ir_context, neg1: *i8, i32_t: *i8) void {
    if (e.member_name != (i8*)0) {
        let mut err_struct_t: *i8= get_error_struct_type(ctx, i32_t);
        let mut err_alloca: *i8= LLVMBuildAlloca(ctx.llvm_builder, err_struct_t, e.member_name);
        let mut code_gep: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, err_struct_t, err_alloca, 0, "err_code_ptr");
        LLVMBuildStore(ctx.llvm_builder, neg1, code_gep);
        let mut ptrt2: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
        let mut payload_gv: *i8= get_error_payload_global(ctx);
        let mut payload_val: *i8= LLVMBuildLoad2(ctx.llvm_builder, ptrt2, payload_gv, "err_payload");
        let mut payload_gep: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, err_struct_t, err_alloca, 1, "err_payload_ptr");
        LLVMBuildStore(ctx.llvm_builder, payload_val, payload_gep);
        ctx_declare_local(ctx, e.member_name, err_alloca, err_struct_t, (i8*)0, false);
    }
    visit_block_stmt((parser.block_stmt*)e.handler_block, ctx);
}

// Emit a runtime null-pointer guard when the SMT cannot prove ptr is non-null.
// If ptr_val is null at runtime, calls abort() and marks the block unreachable.
// After this call the builder is positioned in the "continue" block.
fn emit_null_guard(ptr_val: *i8, ctx: *ir_context) void {
    if (ptr_val == (i8*)0) { return; }
    let mut cur_bb: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
    if (cur_bb == (i8*)0) { return; }
    let mut fn_ref: *i8= LLVMGetBasicBlockParent(cur_bb);
    if (fn_ref == (i8*)0) { return; }

    let mut abort_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "null_abort");
    let mut ok_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "null_ok");

    // %cond = icmp eq ptr %ptr_val, null
    let mut null_val: *i8= LLVMConstNull(LLVMTypeOf(ptr_val));
    let mut cond: *i8= LLVMBuildICmp(ctx.llvm_builder, LLVMIntEQ, ptr_val, null_val, "null_cond");
    LLVMBuildCondBr(ctx.llvm_builder, cond, abort_bb, ok_bb);

    // abort block: call abort() then unreachable
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, abort_bb);
    let mut abort_fn: *i8= sv_map_get(&ctx.global_funcs, "abort");
    let mut abort_ft: *i8= st_map_get(&ctx.global_func_types, "abort");
    if (abort_fn == (i8*)0) {
        let mut void_t: *i8= LLVMVoidTypeInContext(ctx.llvm_ctx);
        abort_ft   = LLVMFunctionType(void_t, (i8**)0, 0, 0);
        abort_fn   = LLVMAddFunction(ctx.llvm_mod, "abort", abort_ft);
        sv_map_set(&ctx.global_funcs,      "abort", abort_fn);
        st_map_set(&ctx.global_func_types, "abort", abort_ft);
    }
    if (abort_fn != (i8*)0 && abort_ft != (i8*)0) {
        LLVMBuildCall2(ctx.llvm_builder, abort_ft, abort_fn, (i8**)0, 0, "");
    }
    LLVMBuildUnreachable(ctx.llvm_builder);

    // continue past the guard
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, ok_bb);
}

// Emit a runtime array bounds guard when SMT cannot prove index is in [0, arr_size).
// If idx_val >= arr_size at runtime, calls abort() and marks the block unreachable.
// After this call the builder is positioned in the "continue" block.
// arr_size is passed as i64; idx_val may be any integer type (sign-extended to i64).
fn emit_bounds_guard(idx_val: *i8, arr_size: i64, ctx: *ir_context) void {
    if (idx_val == (i8*)0 || arr_size <= 0) { return; }
    let mut cur_bb: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
    if (cur_bb == (i8*)0) { return; }
    let mut fn_ref: *i8= LLVMGetBasicBlockParent(cur_bb);
    if (fn_ref == (i8*)0) { return; }

    let mut i64t: *i8= LLVMInt64TypeInContext(ctx.llvm_ctx);

    // Extend idx to i64 for comparison (sign-extend if narrower, no-op if already i64).
    let mut idx64: *i8= idx_val;
    let mut idx_ty: *i8= LLVMTypeOf(idx_val);
    if (LLVMGetTypeKind(idx_ty) == LLVMIntegerTypeKind) {
        let mut w: i32= LLVMGetIntTypeWidth(idx_ty);
        if (w < 64) {
            idx64 = LLVMBuildSExt(ctx.llvm_builder, idx_val, i64t, "idx64");
        }
    }

    let mut size_c: *i8= LLVMConstInt(i64t, (u64)arr_size, 0);
    // icmp uge i64 %idx64, arr_size — true when out of bounds (treats idx as unsigned)
    let mut cond: *i8= LLVMBuildICmp(ctx.llvm_builder, LLVMIntUGE, idx64, size_c, "oob_cmp");

    let mut abort_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "oob_abort");
    let mut ok_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "bounds_ok");
    LLVMBuildCondBr(ctx.llvm_builder, cond, abort_bb, ok_bb);

    LLVMPositionBuilderAtEnd(ctx.llvm_builder, abort_bb);
    let mut abort_fn: *i8= sv_map_get(&ctx.global_funcs, "abort");
    let mut abort_ft: *i8= st_map_get(&ctx.global_func_types, "abort");
    if (abort_fn == (i8*)0) {
        let mut void_t: *i8= LLVMVoidTypeInContext(ctx.llvm_ctx);
        abort_ft   = LLVMFunctionType(void_t, (i8**)0, 0, 0);
        abort_fn   = LLVMAddFunction(ctx.llvm_mod, "abort", abort_ft);
        sv_map_set(&ctx.global_funcs,      "abort", abort_fn);
        st_map_set(&ctx.global_func_types, "abort", abort_ft);
    }
    if (abort_fn != (i8*)0 && abort_ft != (i8*)0) {
        LLVMBuildCall2(ctx.llvm_builder, abort_ft, abort_fn, (i8**)0, 0, "");
    }
    LLVMBuildUnreachable(ctx.llvm_builder);

    LLVMPositionBuilderAtEnd(ctx.llvm_builder, ok_bb);
}

// Main expression visitor.
fn visit_expr(e: *parser.expr_node, ctx: *ir_context) *i8 {
    if (e == (parser.expr_node*)0) { return (i8*)0; }

    let mut kind: i32= e.kind;

    if (kind == ek_int_lit) {
        let mut iv: i64= e.int_val;
        if (iv < (i64)-2147483648 || iv > (i64)2147483647) {
            return LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), (u64)iv, 1);
        }
        return LLVMConstInt(LLVMInt32TypeInContext(ctx.llvm_ctx), (u64)iv, 1);
    }

    if (kind == ek_float_lit) {
        let mut f64t: *i8= LLVMDoubleTypeInContext(ctx.llvm_ctx);
        return LLVMConstReal(f64t, e.flt_val);
    }

    if (kind == ek_string_lit) {
        if (e.str_val == (i8*)0) {
            return LLVMConstNull(LLVMPointerType(LLVMInt8TypeInContext(ctx.llvm_ctx), 0));
        }
        return LLVMBuildGlobalStringPtr(ctx.llvm_builder, e.str_val, "str");
    }

    if (kind == ek_char_lit) {
        let mut i8t: *i8= LLVMInt8TypeInContext(ctx.llvm_ctx);
        return LLVMConstInt(i8t, (u64)e.int_val, 0);
    }

    if (kind == ek_bool_lit) {
        let mut i1t: *i8= LLVMInt1TypeInContext(ctx.llvm_ctx);
        return LLVMConstInt(i1t, e.bool_val ? (u64)1 : (u64)0, 0);
    }

    if (kind == ek_null_lit) {
        let mut i8pt: *i8= LLVMPointerType(LLVMInt8TypeInContext(ctx.llvm_ctx), 0);
        return LLVMConstNull(i8pt);
    }

    if (kind == ek_error_lit) {
        // error.Variant(payload) — for !void: return -1; for !T: return { 1, payload }
        let mut i32_t: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
        let mut ptrt_e: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
        let mut payload_gv_e: *i8= get_error_payload_global(ctx);

        // Evaluate the payload once and publish it through __artemis_error_payload,
        // which is where a `catch |e|` handler reads e.payload from. Always write —
        // storing null when there is no payload keeps a previous error's payload
        // from leaking into this one.
        let mut payload_val: *i8= (i8*)0;
        if (e.operand != (parser.expr_node*)0) {
            payload_val = visit_expr(e.operand, ctx);
        }
        let mut payload_ptr: *i8= LLVMConstNull(ptrt_e);
        if (payload_val != (i8*)0 && LLVMGetTypeKind(LLVMTypeOf(payload_val)) == LLVMPointerTypeKind) {
            payload_ptr = payload_val;
        }
        LLVMBuildStore(ctx.llvm_builder, payload_ptr, payload_gv_e);

        if (ctx.current_func_eu_is_value && ctx.current_ret_type != (i8*)0) {
            // !T function: return { i32 1, payload_val } with payload in slot 1
            let mut eu_err: *i8= LLVMGetUndef(ctx.current_ret_type);
            eu_err = LLVMBuildInsertValue(ctx.llvm_builder, eu_err, LLVMConstInt(i32_t, 1, 0), 0, "eu_err");
            if (payload_val != (i8*)0) {
                // Coerce payload to the return struct's value slot type
                let mut slot_t: *i8= LLVMStructGetTypeAtIndex(ctx.current_ret_type, 1);
                let mut coerced: *i8= coerce_int_val(payload_val, slot_t, ctx.llvm_builder);
                eu_err = LLVMBuildInsertValue(ctx.llvm_builder, eu_err, coerced, 1, "eu_payload");
            }
            return eu_err;
        }
        // !void function: return -1 sentinel
        let mut minus1_e: i64= (i64)-1;
        return LLVMConstInt(i32_t, (u64)minus1_e, 1);
    }

    if (kind == ek_identifier) {
        let mut alloca: *i8= ctx_lookup_local(ctx, e.str_val);
        if (alloca != (i8*)0) {
            let mut elem_t: *i8= ctx_lookup_local_type(ctx, e.str_val);
            if (elem_t == (i8*)0) {
                let mut at: *i8= LLVMTypeOf(alloca);
                if (LLVMGetTypeKind(at) == LLVMPointerTypeKind) {
                    elem_t = LLVMGetElementType(at);
                }
            }
            if (elem_t != (i8*)0) {
                // Array decay: return ptr to first element rather than loading the whole array.
                if (LLVMGetTypeKind(elem_t) == LLVMArrayTypeKind) {
                    let mut zero: *i8= LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), 0, 0);
                    let mut idxs: [2]*i8;
                    idxs[0] = zero;
                    idxs[1] = zero;
                    return LLVMBuildGEP2(ctx.llvm_builder, elem_t, alloca, idxs, 2, "arr_decay");
                }
                let mut load_instr: *i8= LLVMBuildLoad2(ctx.llvm_builder, elem_t, alloca, e.str_val);
                if (ctx_is_local_volatile(ctx, e.str_val)) {
                    LLVMSetVolatile(load_instr, 1);
                }
                return load_instr;
            }
            return alloca;
        }
        // Global variable (namespace-qualified lookup)
        let mut gv: *i8= find_global_var(e.str_val, ctx);
        if (gv != (i8*)0) {
            let mut elem_t: *i8= LLVMGlobalGetValueType(gv);
            if (elem_t != (i8*)0) {
                if (LLVMGetTypeKind(elem_t) == LLVMFunctionTypeKind) { return gv; }
                return LLVMBuildLoad2(ctx.llvm_builder, elem_t, gv, e.str_val);
            }
            return gv;
        }
        // Global function reference
        let mut fn_ref: *i8= find_func(e.str_val, ctx);
        if (fn_ref != (i8*)0) { return fn_ref; }
        return (i8*)0;
    }

    if (kind == ek_unary) {
        if (e.uop == uop_addr_of) {
            return visit_lvalue(e.operand, ctx);
        }
        let mut val: *i8= visit_expr(e.operand, ctx);
        if (val == (i8*)0) { return (i8*)0; }
        let mut vt: *i8= LLVMTypeOf(val);

        if (e.uop == uop_neg) {
            if (llvm_is_float(vt)) { return LLVMBuildFNeg(ctx.llvm_builder, val, "fneg"); }
            return LLVMBuildNeg(ctx.llvm_builder, val, "neg");
        }
        if (e.uop == uop_log_not) {
            let mut b: *i8= to_bool(val, ctx.llvm_builder, ctx.llvm_ctx);
            let mut i1t: *i8= LLVMInt1TypeInContext(ctx.llvm_ctx);
            let mut one: *i8= LLVMConstInt(i1t, 1, 0);
            return LLVMBuildXor(ctx.llvm_builder, b, one, "not");
        }
        if (e.uop == uop_bit_not) {
            return LLVMBuildNot(ctx.llvm_builder, val, "bitnot");
        }
        if (e.uop == uop_deref) {
            let mut vkind: i32= LLVMGetTypeKind(vt);
            if (vkind == LLVMPointerTypeKind) {
                // Use context lookup to find pointee type; LLVMGetElementType is broken for opaque ptrs.
                let mut elem: *i8= (i8*)0;
                if (e.operand != (parser.expr_node*)0) {
                    if (e.operand.kind == ek_identifier) {
                        elem = ctx_lookup_deref_type(ctx, e.operand.str_val);
                    } else if (e.operand.kind == ek_member && e.operand.member_name != (i8*)0) {
                        let mut parent_st: *i8= infer_expr_struct_type(e.operand.object, ctx);
                        if (parent_st != (i8*)0) {
                            let mut pname: *i8= LLVMGetStructName(parent_st);
                            if (pname != (i8*)0) {
                                let mut fidx: i32= ctx_field_index(ctx, pname, e.operand.member_name);
                                if (fidx >= 0) {
                                    let mut sm: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, pname);
                                    if (sm != (struct_meta*)0 && fidx < sm.field_pointee.len) {
                                        elem = sm.field_pointee.data[fidx];
                                    }
                                }
                            }
                        }
                    } else if (e.operand.kind == ek_cast && e.operand.cast_type != (parser.type_node*)0) {
                        // *((T*)expr) — use the cast's pointee type as the load element type.
                        let mut ct: *parser.type_node= e.operand.cast_type;
                        if (ct.pointer_depth > 0) {
                            let mut stripped: parser.type_node;
                            stripped = *ct;
                            stripped.pointer_depth = stripped.pointer_depth - 1;
                            elem = llvm_type_of(&stripped, ctx);
                        }
                    }
                }
                if (elem == (i8*)0) { elem = LLVMInt8TypeInContext(ctx.llvm_ctx); }
                if (e.needs_rtcheck) { emit_null_guard(val, ctx); }
                return LLVMBuildLoad2(ctx.llvm_builder, elem, val, "deref");
            }
            return val;
        }
        if (e.uop == uop_pre_inc || e.uop == uop_pre_dec) {
            let mut ptr: *i8= visit_lvalue(e.operand, ctx);
            if (ptr == (i8*)0) { return val; }
            let mut et: *i8= val != (i8*)0 ? LLVMTypeOf(val) : lvalue_elem_type(e.operand, ctx);
            if (et == (i8*)0) { return val; }
            let mut cur: *i8= LLVMBuildLoad2(ctx.llvm_builder, et, ptr, "inc_load");
            let mut one: *i8= LLVMConstInt(et, 1, 0);
            let mut new_val: *i8= (i8*)0;
            if (e.uop == uop_pre_inc) {
                new_val = LLVMBuildAdd(ctx.llvm_builder, cur, one, "inc");
            } else {
                new_val = LLVMBuildSub(ctx.llvm_builder, cur, one, "dec");
            }
            LLVMBuildStore(ctx.llvm_builder, new_val, ptr);
            return new_val;
        }
        if (e.uop == uop_post_inc || e.uop == uop_post_dec) {
            let mut ptr: *i8= visit_lvalue(e.operand, ctx);
            if (ptr == (i8*)0) { return val; }
            let mut et: *i8= val != (i8*)0 ? LLVMTypeOf(val) : lvalue_elem_type(e.operand, ctx);
            if (et == (i8*)0) { return val; }
            let mut cur: *i8= LLVMBuildLoad2(ctx.llvm_builder, et, ptr, "post_load");
            let mut one: *i8= LLVMConstInt(et, 1, 0);
            let mut new_val: *i8= (i8*)0;
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
        let mut ptr: *i8= visit_lvalue(e, ctx);
        if (ptr != (i8*)0) {
            // Bounds guard (int_val > 0) is emitted inside visit_lvalue; only emit null guard
            // for pointer subscripts where the array size is not known (int_val == 0).
            if (e.needs_rtcheck && e.int_val == 0) { emit_null_guard(ptr, ctx); }
            // Use context-derived element type; LLVMGetElementType(ptr) is broken in opaque mode.
            let mut et: *i8= lvalue_elem_type(e, ctx);
            if (et != (i8*)0) {
                return LLVMBuildLoad2(ctx.llvm_builder, et, ptr, "idx_load");
            }
        }
        return (i8*)0;
    }

    if (kind == ek_member) {
        // Try namespace-qualified global variable access: e.g. std.hash.FNV_OFFSET
        if (e.member_name != (i8*)0) {
            let mut ns_chain: [512]i8;
            if (build_ns_name_from_chain(e, ns_chain, 512)) {
                let mut chain_gv: *i8= sv_map_get(&ctx.global_vars, ns_chain);
                if (chain_gv != (i8*)0) {
                    let mut elem_t: *i8= LLVMGlobalGetValueType(chain_gv);
                    if (elem_t != (i8*)0) {
                        if (LLVMGetTypeKind(elem_t) == LLVMFunctionTypeKind) { return chain_gv; }
                        return LLVMBuildLoad2(ctx.llvm_builder, elem_t, chain_gv, e.member_name);
                    }
                    return chain_gv;
                }
                // Also check global_funcs (namespace.function used as value)
                let mut chain_fn: *i8= sv_map_get(&ctx.global_funcs, ns_chain);
                if (chain_fn != (i8*)0) { return chain_fn; }
            }
        }
        // f(...).field — struct returned by value from a call. The result has no
        // address, so read the field out of the aggregate directly. Emitting the
        // call here (rather than via visit_lvalue + resolve_struct_base) also keeps
        // it to a single evaluation, which matters for calls with side effects.
        if (e.object != (parser.expr_node*)0 && e.object.kind == ek_call && e.member_name != (i8*)0) {
            let mut cv: *i8= visit_expr(e.object, ctx);
            if (cv == (i8*)0) { return (i8*)0; }
            let mut cvt: *i8= LLVMTypeOf(cv);
            if (cvt == (i8*)0 || LLVMGetTypeKind(cvt) != LLVMStructTypeKind) { return (i8*)0; }
            let mut csn: *i8= LLVMGetStructName(cvt);
            if (csn == (i8*)0) { return (i8*)0; }
            let mut cfi: i32= ctx_field_index(ctx, csn, e.member_name);
            if (cfi < 0 && ctx.current_namespace != (i8*)0) {
                let mut ns_csn: [512]i8;
                snprintf(ns_csn, (u64)512, "%s__NS_%s", ctx.current_namespace, csn);
                cfi = ctx_field_index(ctx, ns_csn, e.member_name);
            }
            if (cfi < 0) { return (i8*)0; }
            return LLVMBuildExtractValue(ctx.llvm_builder, cv, (u32)cfi, e.member_name);
        }

        let mut ptr: *i8= visit_lvalue(e, ctx);
        if (ptr == (i8*)0 || e.member_name == (i8*)0) { return (i8*)0; }
        if (e.needs_rtcheck) { emit_null_guard(ptr, ctx); }

        // ADT named field access: (*x).field — look up field type from variant metadata
        if (e.object != (parser.expr_node*)0 && e.object.kind == ek_unary && e.object.uop == uop_deref &&
                e.object.operand != (parser.expr_node*)0 && e.object.operand.kind == ek_identifier) {
            let mut local_t: *i8= ctx_lookup_local_type(ctx, e.object.operand.str_val);
            if (local_t != (i8*)0 && LLVMGetTypeKind(local_t) == LLVMStructTypeKind) {
                let mut sname_adt: *i8= LLVMGetStructName(local_t);
                if (sname_adt != (i8*)0 && sv_map_get(&ctx.adt_enum_decls, sname_adt) != (i8*)0) {
                    let mut adt_ed: *parser.enum_decl= (parser.enum_decl*)sv_map_get(&ctx.adt_enum_decls, sname_adt);
                    // Find the field type in any named/istruc variant
                    let mut vi: i32= 0;
                    while (vi < adt_ed.variants_len) {
                        let mut vkind: i32= (adt_ed.variant_kinds != (i32*)0) ? adt_ed.variant_kinds[vi] : 0;
                        let mut fc: i32= (adt_ed.variant_field_counts != (i32*)0) ? adt_ed.variant_field_counts[vi] : 0;
                        if ((vkind == 2 || vkind == 3) && fc > 0 && adt_ed.variant_field_names_flat != (i8**)0) {
                            let mut fi: i32= 0;
                            while (fi < fc) {
                                let mut vfn2: *i8= adt_ed.variant_field_names_flat[vi * 8 + fi];
                                if (vfn2 != (i8*)0 && strcmp(vfn2, e.member_name) == 0) {
                                    let mut ft: *parser.type_node= (adt_ed.variant_field_type_flat != (i8**)0)
                                        ? (parser.type_node*)adt_ed.variant_field_type_flat[vi * 8 + fi] : (parser.type_node*)0;
                                    let mut flt: *i8= (ft != (parser.type_node*)0) ? llvm_type_of(ft, ctx) : LLVMInt32TypeInContext(ctx.llvm_ctx);
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
            let mut deref_t3: *i8= ctx_lookup_deref_type(ctx, e.object.str_val);
            if (deref_t3 != (i8*)0 && LLVMGetTypeKind(deref_t3) == LLVMStructTypeKind) {
                let mut sname_adt3: *i8= LLVMGetStructName(deref_t3);
                if (sname_adt3 != (i8*)0) {
                    let mut adt_ed_ptr3: *i8= sv_map_get(&ctx.adt_enum_decls, sname_adt3);
                    if (adt_ed_ptr3 != (i8*)0) {
                        let mut adt_ed3: *parser.enum_decl= (parser.enum_decl*)adt_ed_ptr3;
                        let mut vi3: i32= 0;
                        while (vi3 < adt_ed3.variants_len) {
                            let mut vkind3: i32= (adt_ed3.variant_kinds != (i32*)0) ? adt_ed3.variant_kinds[vi3] : 0;
                            let mut fc3: i32= (adt_ed3.variant_field_counts != (i32*)0) ? adt_ed3.variant_field_counts[vi3] : 0;
                            if ((vkind3 == 2 || vkind3 == 3) && fc3 > 0 && adt_ed3.variant_field_names_flat != (i8**)0) {
                                let mut fi3: i32= 0;
                                while (fi3 < fc3) {
                                    let mut vfn3: *i8= adt_ed3.variant_field_names_flat[vi3 * 8 + fi3];
                                    if (vfn3 != (i8*)0 && strcmp(vfn3, e.member_name) == 0) {
                                        let mut ft3: *parser.type_node= (adt_ed3.variant_field_type_flat != (i8**)0)
                                            ? (parser.type_node*)adt_ed3.variant_field_type_flat[vi3 * 8 + fi3] : (parser.type_node*)0;
                                        let mut flt3: *i8= (ft3 != (parser.type_node*)0) ? llvm_type_of(ft3, ctx) : LLVMInt32TypeInContext(ctx.llvm_ctx);
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
        let mut struct_type: *i8= (i8*)0;
        resolve_struct_base(e.object, ctx, &struct_type);
        if (struct_type == (i8*)0) { return (i8*)0; }
        let mut sname: *i8= LLVMGetStructName(struct_type);
        if (sname == (i8*)0) { return (i8*)0; }
        let mut fidx: i32= ctx_field_index(ctx, sname, e.member_name);
        if (fidx < 0 && ctx.current_namespace != (i8*)0) {
            let mut ns_sname: [512]i8;
            snprintf(ns_sname, (u64)512, "%s__NS_%s", ctx.current_namespace, sname);
            fidx = ctx_field_index(ctx, ns_sname, e.member_name);
            if (fidx >= 0) { sname = lexer.str_dup(ns_sname); }
        }
        if (fidx < 0) { return (i8*)0; }
        let mut ft: *i8= ctx_field_type(ctx, sname, fidx);
        if (ft == (i8*)0) { return (i8*)0; }
        // Array field: return the GEP pointer directly (decays to pointer to first element).
        // Loading an array type would produce [N x T] as a value, which cannot be passed to
        // pointer parameters. The pointer is already the address of element [0].
        if (LLVMGetTypeKind(ft) == LLVMArrayTypeKind) { return ptr; }
        return LLVMBuildLoad2(ctx.llvm_builder, ft, ptr, "mem_load");
    }

    if (kind == ek_cast) {
        if (e.cast_type != (parser.type_node*)0 && e.operand != (parser.expr_node*)0) {
            let mut ct: *i8= llvm_type_of(e.cast_type, ctx);
            if (ct != (i8*)0 && LLVMGetTypeKind(ct) == LLVMIntegerTypeKind &&
                LLVMGetIntTypeWidth(ct) > 64) {
                // Wide integer cast: build directly from the literal string if possible.
                let mut lit_node: *parser.expr_node= (parser.expr_node*)0;
                let mut negate: bool= false;
                if (e.operand.kind == ek_int_lit) {
                    lit_node = e.operand;
                } else if (e.operand.kind == ek_unary && e.operand.uop == uop_neg &&
                           e.operand.operand != (parser.expr_node*)0 &&
                           e.operand.operand.kind == ek_int_lit) {
                    lit_node = e.operand.operand;
                    negate = true;
                }
                if (lit_node != (parser.expr_node*)0 && lit_node.str_val != (i8*)0) {
                    let mut sv: *i8= lit_node.str_val;
                    let mut radix: u8= 10;
                    if (sv[0] == '0' && (sv[1] == 'x' || sv[1] == 'X')) { radix = 16; sv = sv + 2; }
                    else if (sv[0] == '0' && (sv[1] == 'b' || sv[1] == 'B')) { radix = 2; sv = sv + 2; }
                    if (negate) {
                        let mut neg_len: u64= strlen(sv) + 2;
                        let mut neg_buf: *i8= (i8*)arc_malloc(neg_len);
                        neg_buf[0] = '-';
                        memcpy(neg_buf + 1, sv, strlen(sv) + 1);
                        let mut wide_v: *i8= LLVMConstIntOfString(ct, neg_buf, radix);
                        arc_free(neg_buf);
                        return wide_v;
                    }
                    return LLVMConstIntOfString(ct, sv, radix);
                }
            }
        }
        let mut val: *i8= visit_expr(e.operand, ctx);
        if (val == (i8*)0 || e.cast_type == (parser.type_node*)0) { return val; }
        let mut target_t: *i8= llvm_type_of(e.cast_type, ctx);
        if (target_t == (i8*)0) { return val; }
        let mut val_t: *i8= LLVMTypeOf(val);
        let mut vkind: i32= LLVMGetTypeKind(val_t);
        let mut tkind: i32= LLVMGetTypeKind(target_t);

        if (vkind == LLVMIntegerTypeKind && tkind == LLVMIntegerTypeKind) {
            let mut vw: i32= LLVMGetIntTypeWidth(val_t);
            let mut tw: i32= LLVMGetIntTypeWidth(target_t);
            if (vw == tw) { return val; }
            if (vw < tw) {
                let mut uns: bool= is_unsigned_type_node(e.cast_type);
                // Also use zext if the source is a locally-declared unsigned variable (e.g. bN vars).
                if (!uns && e.operand != (parser.expr_node*)0 &&
                    e.operand.kind == ek_identifier && e.operand.str_val != (i8*)0) {
                    uns = ctx_lookup_local_unsigned(ctx, e.operand.str_val);
                }
                // i1 (bool) must always zero-extend; sign-extending 1 → -1 is wrong.
                if (vw == 1 || uns) { return LLVMBuildZExt(ctx.llvm_builder, val, target_t, "zext"); }
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
            let mut uns: bool= is_unsigned_type_node(e.cast_type);
            if (uns) { return LLVMBuildUIToFP(ctx.llvm_builder, val, target_t, "uitofp"); }
            return LLVMBuildSIToFP(ctx.llvm_builder, val, target_t, "sitofp");
        }
        if (llvm_is_float(val_t) && tkind == LLVMIntegerTypeKind) {
            let mut uns: bool= is_unsigned_type_node(e.cast_type);
            if (uns) { return LLVMBuildFPToUI(ctx.llvm_builder, val, target_t, "fptou"); }
            return LLVMBuildFPToSI(ctx.llvm_builder, val, target_t, "fptosi");
        }
        if (llvm_is_float(val_t) && llvm_is_float(target_t)) {
            return LLVMBuildFPCast(ctx.llvm_builder, val, target_t, "fpcast");
        }
        // Struct → primitive: look for a conversion operator (e.g. operator_i32)
        if (vkind == LLVMStructTypeKind) {
            let mut sn: *i8= LLVMGetStructName(val_t);
            if (sn != (i8*)0) {
                let mut cop_name: [512]i8;
                let mut cop_fn: *i8= (i8*)0;
                let mut cop_fn_ty: *i8= (i8*)0;
                if (tkind == LLVMIntegerTypeKind) {
                    let mut cop_bw: u32= LLVMGetIntTypeWidth(target_t);
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
                    let mut self_ptr: *i8= visit_lvalue(e.operand, ctx);
                    if (self_ptr == (i8*)0) {
                        self_ptr = LLVMBuildAlloca(ctx.llvm_builder, val_t, "conv_tmp");
                        LLVMBuildStore(ctx.llvm_builder, val, self_ptr);
                    }
                    let mut cop_args: [1]*i8;
                    cop_args[0] = self_ptr;
                    return LLVMBuildCall2(ctx.llvm_builder, cop_fn_ty, cop_fn, cop_args, 1, "conv_op");
                }
            }
        }
        return val;
    }

    if (kind == ek_cast_as) {
        // `expr as Type` — same type-directed dispatch as C-style cast but via safe `as` keyword.
        let mut val: *i8= visit_expr(e.operand, ctx);
        if (val == (i8*)0 || e.cast_type == (parser.type_node*)0) { return val; }
        let mut target_t: *i8= llvm_type_of(e.cast_type, ctx);
        if (target_t == (i8*)0) { return val; }
        let mut val_t: *i8= LLVMTypeOf(val);
        let mut vkind: i32= LLVMGetTypeKind(val_t);
        let mut tkind: i32= LLVMGetTypeKind(target_t);

        if (vkind == LLVMIntegerTypeKind && tkind == LLVMIntegerTypeKind) {
            let mut vw: i32= LLVMGetIntTypeWidth(val_t);
            let mut tw: i32= LLVMGetIntTypeWidth(target_t);
            if (vw == tw) { return val; }
            if (vw < tw) {
                let mut uns: bool= is_unsigned_type_node(e.cast_type);
                // i1 (bool) must always zero-extend; sign-extending 1 → -1 is wrong.
                if (vw == 1 || uns) { return LLVMBuildZExt(ctx.llvm_builder, val, target_t, "zext"); }
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
            let mut uns: bool= is_unsigned_type_node(e.cast_type);
            if (uns) { return LLVMBuildUIToFP(ctx.llvm_builder, val, target_t, "uitofp"); }
            return LLVMBuildSIToFP(ctx.llvm_builder, val, target_t, "sitofp");
        }
        if (llvm_is_float(val_t) && tkind == LLVMIntegerTypeKind) {
            let mut uns: bool= is_unsigned_type_node(e.cast_type);
            if (uns) { return LLVMBuildFPToUI(ctx.llvm_builder, val, target_t, "fptou"); }
            return LLVMBuildFPToSI(ctx.llvm_builder, val, target_t, "fptosi");
        }
        if (llvm_is_float(val_t) && llvm_is_float(target_t)) {
            return LLVMBuildFPCast(ctx.llvm_builder, val, target_t, "fpcast");
        }
        return val;
    }

    if (kind == ek_match_expr) {
        // Allocate result slot: type determined from first arm if available, else i64.
        let mut i64_t: *i8= LLVMInt64TypeInContext(ctx.llvm_ctx);
        let mut slot_t: *i8= i64_t;
        let mut ms: *parser.match_stmt= (parser.match_stmt*)e.match_stmt_ptr;
        if (ms != (parser.match_stmt*)0 && ms.arms_len > 0 && ms.arms[0].body != (parser.ast_node*)0 && ms.arms[0].body.kind == nd_expr_stmt) {
            let mut first_arm_es: *parser.expr_stmt= (parser.expr_stmt*)ms.arms[0].body;
            if (first_arm_es.expr != (parser.expr_node*)0) {
                let mut probe_val: *i8= visit_expr(first_arm_es.expr, ctx);
                if (probe_val != (i8*)0) { slot_t = LLVMTypeOf(probe_val); }
            }
        }
        let mut result_slot: *i8= LLVMBuildAlloca(ctx.llvm_builder, slot_t, "match_result");
        LLVMBuildStore(ctx.llvm_builder, LLVMConstNull(slot_t), result_slot);
        let mut saved_slot: *i8= ctx.match_result_slot;
        let mut saved_slot_t: *i8= ctx.match_result_type;
        ctx.match_result_slot = result_slot;
        // Arms coerce their value to this type before storing, so a slot holding a
        // pointer/float/struct is not silently overwritten with an i64.
        ctx.match_result_type = slot_t;
        visit_match_stmt(ms, ctx);
        ctx.match_result_slot = saved_slot;
        ctx.match_result_type = saved_slot_t;
        return LLVMBuildLoad2(ctx.llvm_builder, slot_t, result_slot, "match_val");
    }

    if (kind == ek_range) {
        // Range literals are only valid as the iterable in a for-range loop.
        // If visit_expr is called on one directly, return a null value.
        return (i8*)0;
    }

    if (kind == ek_sizeof_e) {
        let mut i64_t: *i8= LLVMInt64TypeInContext(ctx.llvm_ctx);

        // @typeof(x) — returns the LLVM type-size (i64) of the type of expression x
        // In type position `@typeof(x)` resolves to x's actual type (see ir/types.arc
        // is_typeof). In value position there is no first-class type value to yield, so
        // it evaluates to the type's size — useful for layout arithmetic.
        if (e.str_val != (i8*)0 && strcmp(e.str_val, "typeof") == 0) {
            if (e.operand != (parser.expr_node*)0) {
                let mut typeof_v: *i8= visit_expr(e.operand, ctx);
                if (typeof_v != (i8*)0) { return LLVMSizeOf(LLVMTypeOf(typeof_v)); }
            }
            return LLVMConstInt(i64_t, 0, 0);
        }

        // @alignof(T) — compile-time alignment of type T
        if (e.str_val != (i8*)0 && strcmp(e.str_val, "alignof") == 0) {
            let mut al_t: *i8= (i8*)0;
            if (e.cast_type != (parser.type_node*)0) { al_t = llvm_type_of(e.cast_type, ctx); }
            else if (e.operand != (parser.expr_node*)0) {
                let mut al_v: *i8= visit_expr(e.operand, ctx);
                if (al_v != (i8*)0) { al_t = LLVMTypeOf(al_v); }
            }
            if (al_t == (i8*)0) { return LLVMConstInt(i64_t, 1, 0); }
            return LLVMAlignOf(al_t);
        }

        // @csizeof(T) — compile-time byte size (equivalent to sizeof)
        if (e.str_val != (i8*)0 && strcmp(e.str_val, "csizeof") == 0) {
            let mut cs_t: *i8= (i8*)0;
            if (e.cast_type != (parser.type_node*)0) { cs_t = llvm_type_of(e.cast_type, ctx); }
            else if (e.operand != (parser.expr_node*)0) {
                let mut cs_v: *i8= visit_expr(e.operand, ctx);
                if (cs_v != (i8*)0) { cs_t = LLVMTypeOf(cs_v); }
            }
            if (cs_t == (i8*)0) { return LLVMConstInt(i64_t, 1, 0); }
            return LLVMSizeOf(cs_t);
        }

        // @srsizeof(x) — shallow runtime size: size of x's immediate allocation (same as sizeof type)
        // For arrays and structs, use the declared type (not the evaluated expression, which
        // would give a pointer size due to array-to-pointer decay).
        if (e.str_val != (i8*)0 && strcmp(e.str_val, "srsizeof") == 0) {
            if (e.operand != (parser.expr_node*)0) {
                // Try to get the declared local type for simple identifiers first
                if (e.operand.kind == ek_identifier && e.operand.str_val != (i8*)0) {
                    let mut sr_local_t: *i8= ctx_lookup_local_type(ctx, e.operand.str_val);
                    if (sr_local_t != (i8*)0) { return LLVMSizeOf(sr_local_t); }
                }
                // Fallback: evaluate expression and use its type
                let mut sr_v: *i8= visit_expr(e.operand, ctx);
                if (sr_v != (i8*)0) { return LLVMSizeOf(LLVMTypeOf(sr_v)); }
            }
            return LLVMConstInt(i64_t, 0, 0);
        }

        // @drsizeof(x) — deep compile-time size: sizeof(x) + sizeof(*x) + sizeof(**x) ...
        // Follows static pointer types recursively using the context's deref_type tracking.
        if (e.str_val != (i8*)0 && strcmp(e.str_val, "drsizeof") == 0) {
            if (e.operand != (parser.expr_node*)0) {
                // For identifier operands, follow the pointer chain using deref_type metadata.
                if (e.operand.kind == ek_identifier && e.operand.str_val != (i8*)0) {
                    let mut dr_name: *i8= e.operand.str_val;
                    let mut dr_local_t: *i8= ctx_lookup_local_type(ctx, dr_name);
                    if (dr_local_t != (i8*)0) {
                        let mut total: *i8= LLVMSizeOf(dr_local_t);
                        // Follow one level of pointer via deref_type
                        let mut dr_deref_t: *i8= ctx_lookup_deref_type(ctx, dr_name);
                        if (dr_deref_t != (i8*)0) {
                            total = LLVMConstAdd(total, LLVMSizeOf(dr_deref_t));
                        }
                        return total;
                    }
                }
                // For type-annotated sizeof(@typeof(x)) style: evaluate and use shallow
                let mut dr_v: *i8= visit_expr(e.operand, ctx);
                if (dr_v != (i8*)0) {
                    let mut dr_t: *i8= LLVMTypeOf(dr_v);
                    let mut total_dr: *i8= LLVMSizeOf(dr_t);
                    if (LLVMGetTypeKind(dr_t) == LLVMPointerTypeKind) {
                        // Unknown pointed-to type at this point; just return ptr size
                    }
                    return total_dr;
                }
            }
            return LLVMConstInt(i64_t, 0, 0);
        }

        // Standard sizeof / bare ek_sizeof_e
        let mut sz_t: *i8= (i8*)0;
        if (e.cast_type != (parser.type_node*)0) {
            sz_t = llvm_type_of(e.cast_type, ctx);
        } else if (e.operand != (parser.expr_node*)0) {
            // sizeof(TypeName) is parsed as identifier operand when the parser can't
            // distinguish it from an expression (no variable declaration follows).
            // The C++ analysis pass rewrites this; we handle it here instead.
            if (e.operand.kind == ek_identifier && e.operand.str_val != (i8*)0) {
                // Check struct types first
                let mut struct_t: *i8= st_map_get(&ctx.struct_types, e.operand.str_val);
                if (struct_t != (i8*)0) { sz_t = struct_t; }
                // Check typedef aliases
                if (sz_t == (i8*)0) {
                    let mut alias_tn: *i8= typedef_map_get(&ctx.typedef_aliases, e.operand.str_val);
                    if (alias_tn != (i8*)0) {
                        sz_t = llvm_type_of((parser.type_node*)alias_tn, ctx);
                    }
                }
            }
            if (sz_t == (i8*)0) {
                let mut v: *i8= visit_expr(e.operand, ctx);
                if (v != (i8*)0) { sz_t = LLVMTypeOf(v); }
            }
        }
        if (sz_t == (i8*)0) {
            return LLVMConstInt(i64_t, 1, 0);
        }
        return LLVMSizeOf(sz_t);
    }

    if (kind == ek_typeinfo_e) {
        if (e.cast_type != (parser.type_node*)0) {
            return emit_typeinfo_global(e.cast_type, ctx);
        }
        return (i8*)0;
    }

    if (kind == ek_ternary) {
        let mut cond_val: *i8= visit_expr(e.cond, ctx);
        if (cond_val == (i8*)0) { return (i8*)0; }
        let mut cond_b: *i8= to_bool(cond_val, ctx.llvm_builder, ctx.llvm_ctx);

        let mut fn_ref: *i8= ctx.current_func;
        let mut then_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "tern_then");
        let mut else_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "tern_else");
        let mut merge_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "tern_merge");

        LLVMBuildCondBr(ctx.llvm_builder, cond_b, then_bb, else_bb);

        // Compute then/else values WITHOUT adding branches yet (branches after type coercion)
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, then_bb);
        let mut then_val: *i8= visit_expr(e.then_e, ctx);
        let mut then_end: *i8= LLVMGetInsertBlock(ctx.llvm_builder);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, else_bb);
        let mut else_val: *i8= visit_expr(e.else_e, ctx);
        let mut else_end: *i8= LLVMGetInsertBlock(ctx.llvm_builder);

        if (then_val == (i8*)0 || else_val == (i8*)0) {
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, then_end);
            LLVMBuildBr(ctx.llvm_builder, merge_bb);
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, else_end);
            LLVMBuildBr(ctx.llvm_builder, merge_bb);
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb);
            return then_val;
        }

        let mut phi_t: *i8= LLVMTypeOf(then_val);
        let mut else_t: *i8= LLVMTypeOf(else_val);
        // Coerce types for PHI BEFORE adding branches so extensions land before terminators
        if (phi_t != else_t) {
            let mut then_k: i32= LLVMGetTypeKind(phi_t);
            let mut else_k: i32= LLVMGetTypeKind(else_t);
            if (then_k == LLVMIntegerTypeKind && else_k == LLVMIntegerTypeKind) {
                // Widen the narrower branch; use ZExt for unsigned types, SExt for signed
                let mut tw: i32= LLVMGetIntTypeWidth(phi_t);
                let mut ew: i32= LLVMGetIntTypeWidth(else_t);
                let mut then_unsigned: bool= (e.then_e != (parser.expr_node*)0 && e.then_e.cast_type != (parser.type_node*)0) ? is_unsigned_type_node(e.then_e.cast_type) : false;
                let mut else_unsigned: bool= (e.else_e != (parser.expr_node*)0 && e.else_e.cast_type != (parser.type_node*)0) ? is_unsigned_type_node(e.else_e.cast_type) : false;
                if (tw > ew) {
                    LLVMPositionBuilderAtEnd(ctx.llvm_builder, else_end);
                    if (else_unsigned || then_unsigned) {
                        else_val = LLVMBuildZExt(ctx.llvm_builder, else_val, phi_t, "ext");
                    } else {
                        else_val = LLVMBuildSExt(ctx.llvm_builder, else_val, phi_t, "ext");
                    }
                    else_end = LLVMGetInsertBlock(ctx.llvm_builder);
                } else if (ew > tw) {
                    phi_t = else_t;
                    LLVMPositionBuilderAtEnd(ctx.llvm_builder, then_end);
                    if (then_unsigned || else_unsigned) {
                        then_val = LLVMBuildZExt(ctx.llvm_builder, then_val, phi_t, "ext");
                    } else {
                        then_val = LLVMBuildSExt(ctx.llvm_builder, then_val, phi_t, "ext");
                    }
                    then_end = LLVMGetInsertBlock(ctx.llvm_builder);
                }
            } else if (then_k == LLVMPointerTypeKind && else_k == LLVMIntegerTypeKind) {
                LLVMPositionBuilderAtEnd(ctx.llvm_builder, else_end);
                else_val = LLVMBuildIntToPtr(ctx.llvm_builder, else_val, phi_t, "i2p_tern");
                else_end = LLVMGetInsertBlock(ctx.llvm_builder);
            } else if (then_k == LLVMIntegerTypeKind && else_k == LLVMPointerTypeKind) {
                phi_t = else_t;
                LLVMPositionBuilderAtEnd(ctx.llvm_builder, then_end);
                then_val = LLVMBuildIntToPtr(ctx.llvm_builder, then_val, phi_t, "i2p_tern");
                then_end = LLVMGetInsertBlock(ctx.llvm_builder);
            }
        }
        // Now add branches (after coercion, so extensions land before terminators)
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, then_end);
        LLVMBuildBr(ctx.llvm_builder, merge_bb);
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, else_end);
        LLVMBuildBr(ctx.llvm_builder, merge_bb);
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb);
        let mut phi: *i8= LLVMBuildPhi(ctx.llvm_builder, phi_t, "tern");
        let mut incoming_vals: [2]*i8;
        let mut incoming_blocks: [2]*i8;
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
        let mut lhs_val: *i8= visit_expr(e.lhs, ctx);
        if (lhs_val == (i8*)0) { return (i8*)0; }

        let mut null_val: *i8= LLVMConstNull(LLVMTypeOf(lhs_val));
        let mut is_null: *i8= LLVMBuildICmp(ctx.llvm_builder, LLVMIntEQ, lhs_val, null_val, "is_null");

        let mut fn_ref: *i8= ctx.current_func;
        let mut null_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "coal_null");
        let mut nonnull_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "coal_nonnull");
        let mut merge_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "coal_merge");

        LLVMBuildCondBr(ctx.llvm_builder, is_null, null_bb, nonnull_bb);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, null_bb);
        let mut rhs_val: *i8= visit_expr(e.rhs, ctx);
        let mut null_end: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
        LLVMBuildBr(ctx.llvm_builder, merge_bb);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, nonnull_bb);
        let mut nonnull_end: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
        LLVMBuildBr(ctx.llvm_builder, merge_bb);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb);
        if (rhs_val == (i8*)0) { return lhs_val; }
        let mut phi_t: *i8= LLVMTypeOf(lhs_val);
        let mut phi: *i8= LLVMBuildPhi(ctx.llvm_builder, phi_t, "coal");
        let mut incoming_vals: [2]*i8;
        let mut incoming_blocks: [2]*i8;
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
            let mut enum_name: *i8= (i8*)0;
            let mut variant_name: *i8= (i8*)0;
            let mut obj_e: *parser.expr_node= e.object;
            if (obj_e.kind == ek_member && obj_e.object != (parser.expr_node*)0 && obj_e.object.kind == ek_identifier) {
                enum_name    = obj_e.object.str_val;
                variant_name = obj_e.member_name;
            } else if (obj_e.kind == ek_identifier) {
                enum_name    = obj_e.str_val;
                variant_name = (i8*)0; // plain variant
            }
            if (enum_name != (i8*)0 && variant_name != (i8*)0) {
                let mut adt_ed_ptr: *i8= sv_map_get(&ctx.adt_enum_decls, enum_name);
                let mut enum_st: *i8= st_map_get(&ctx.struct_types, enum_name);
                if (adt_ed_ptr != (i8*)0 && enum_st != (i8*)0) {
                    let mut adt_ed: *parser.enum_decl= (parser.enum_decl*)adt_ed_ptr;
                    // Find variant index
                    let mut var_idx: i32= -1;
                    let mut vi: i32= 0;
                    while (vi < adt_ed.variants_len) {
                        if (strcmp(adt_ed.variant_names[vi], variant_name) == 0) { var_idx = vi; }
                        vi = vi + 1;
                    }
                    if (var_idx >= 0) {
                        let mut alloca: *i8= LLVMBuildAlloca(ctx.llvm_builder, enum_st, "adt_finit");
                        LLVMBuildStore(ctx.llvm_builder, LLVMConstNull(enum_st), alloca);
                        // Store tag
                        let mut i32t: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
                        let mut tag_ptr: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, enum_st, alloca, 0, "adt_tag");
                        LLVMBuildStore(ctx.llvm_builder, LLVMConstInt(i32t, (u64)var_idx, 0), tag_ptr);
                        // Store named fields into payload by looking up field order in variant metadata
                        let mut vqname: [512]i8;
                        snprintf(vqname, (u64)512, "%s__%s", enum_name, variant_name);
                        let mut pay_ptr: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, enum_st, alloca, 1, "adt_pay");
                        let mut i8t: *i8= LLVMInt8TypeInContext(ctx.llvm_ctx);
                        // Compute per-field byte offsets from variant field type metadata
                        // NOTE: vsm is looked up AFTER each visit_expr because visit_expr can
                        // call get_error_struct_type -> struct_meta_vec_push, reallocating the
                        // backing array and invalidating any previously cached struct_meta*.
                        let mut fi: i32= 0;
                        while (fi < e.field_count) {
                            let mut fname: *i8= e.field_names[fi];
                            let mut fval: *i8= visit_expr(e.field_vals[fi], ctx);
                            let mut vsm: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, vqname);
                            if (fval != (i8*)0 && vsm != (struct_meta*)0) {
                                // Find field index in variant metadata
                                let mut field_idx: i32= -1;
                                let mut byte_off: u64= 0;
                                let mut si: i32= 0;
                                while (si < vsm.field_names.len) {
                                    if (fname != (i8*)0 && strcmp(vsm.field_names.data[si], fname) == 0) { field_idx = si; }
                                    if (field_idx < 0) {
                                        let mut fsz: u64= llvm_type_byte_size(vsm.field_types.data[si]);
                                        byte_off = byte_off + ((fsz + 7) & ~(u64)7);
                                    }
                                    si = si + 1;
                                }
                                if (field_idx >= 0) {
                                    let mut flt: *i8= vsm.field_types.data[field_idx];
                                    fval = coerce_int_val(fval, flt, ctx.llvm_builder);
                                    let mut idx_v: *i8= LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), byte_off, 0);
                                    let mut elem: *i8= LLVMBuildGEP2(ctx.llvm_builder, i8t, pay_ptr, &idx_v, 1, "pay_elem");
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
        let mut struct_t: *i8= llvm_type_of(e.init_type, ctx);
        if (struct_t == (i8*)0) { return (i8*)0; }

        // If the declaration already set defaults into a target alloca, use it so
        // unset fields preserve their default values instead of being zeroed.
        let mut alloca: *i8= ctx.class_init_alloca;
        if (alloca == (i8*)0) {
            alloca = LLVMBuildAlloca(ctx.llvm_builder, struct_t, "struct_init");
            LLVMBuildStore(ctx.llvm_builder, LLVMConstNull(struct_t), alloca);
        }

        let mut sname: *i8= LLVMGetStructName(struct_t);
        let mut i: i32= 0;
        while (i < e.field_count) {
            let mut fname: *i8= e.field_names[i];
            let mut fval: *i8= visit_expr(e.field_vals[i], ctx);
            if (sname != (i8*)0 && fname != (i8*)0 && fval != (i8*)0) {
                let mut fidx: i32= ctx_field_index(ctx, sname, fname);
                if (fidx >= 0) {
                    let mut fptr: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, struct_t, alloca, fidx, fname);
                    let mut elem_t: *i8= ctx_field_type(ctx, sname, fidx);
                    if (elem_t == (i8*)0) {
                        let mut ftype: *i8= LLVMTypeOf(fptr);
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

    // Annotations are compile-time only. Reaching here means the annotation appeared
    // in a value position (e.g. `let x = @foo(...)`), which is a compile error.
    if (kind == ek_annotation) {
        printf("error: annotation used in value position (annotations have no runtime value)\n");
        return (i8*)0;
    }

    // try expr: evaluate inner; propagate error if present; yield value on success
    if (kind == ek_try_expr) {
        if (e.operand == (parser.expr_node*)0) { return (i8*)0; }
        let mut inner: *i8= visit_expr(e.operand, ctx);
        if (inner == (i8*)0) { return (i8*)0; }
        let mut i32_t: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
        let mut inner_t: *i8= LLVMTypeOf(inner);
        let mut fn_ref: *i8= ctx.current_func;

        if (LLVMGetTypeKind(inner_t) == LLVMStructTypeKind) {
            // !T result: inner is { i32 is_err, T value }
            let mut is_err_v: *i8= LLVMBuildExtractValue(ctx.llvm_builder, inner, 0, "try_err_flag");
            let mut val_v: *i8= LLVMBuildExtractValue(ctx.llvm_builder, inner, 1, "try_val");
            let mut zero_t: *i8= LLVMConstInt(i32_t, 0, 0);
            let mut is_err: *i8= LLVMBuildICmp(ctx.llvm_builder, LLVMIntNE, is_err_v, zero_t, "try_is_err");
            let mut err_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "try_err");
            let mut ok_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "try_ok");
            LLVMBuildCondBr(ctx.llvm_builder, is_err, err_bb, ok_bb);
            // Error path: fire defers + errdefers, propagate error
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, err_bb);
            let mut try_di2: i32= ctx.defers.len - 1;
            while (try_di2 >= 0) {
                emit_deferred(&ctx.defers.data[try_di2], ctx);
                try_di2 = try_di2 - 1;
            }
            let mut try_ei2: i32= ctx.errdefers.len - 1;
            while (try_ei2 >= 0) {
                emit_deferred(&ctx.errdefers.data[try_ei2], ctx);
                try_ei2 = try_ei2 - 1;
            }
            let mut ret_t2: *i8= ctx.current_ret_type != (i8*)0 ? ctx.current_ret_type : i32_t;
            if (ctx.current_func_eu_is_value) {
                // Propagate as { i32 1, undef } in a !T caller
                let mut eu_perr: *i8= LLVMGetUndef(ret_t2);
                eu_perr = LLVMBuildInsertValue(ctx.llvm_builder, eu_perr, LLVMConstInt(i32_t, 1, 0), 0, "eu_perr");
                LLVMBuildRet(ctx.llvm_builder, eu_perr);
            } else {
                // Propagate as -1 in a !void caller
                let mut minus1_t: i64= (i64)-1;
                LLVMBuildRet(ctx.llvm_builder, coerce_int_val(LLVMConstInt(i32_t, (u64)minus1_t, 1), ret_t2, ctx.llvm_builder));
            }
            // OK path: yield the T value
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, ok_bb);
            return val_v;
        } else {
            // !void result (existing i32 ABI): inner is -1 on error, 0 on success
            let mut coerced: *i8= coerce_int_val(inner, i32_t, ctx.llvm_builder);
            let mut minus1: i64= (i64)-1;
            let mut neg1: *i8= LLVMConstInt(i32_t, (u64)minus1, 1);
            let mut is_err: *i8= LLVMBuildICmp(ctx.llvm_builder, LLVMIntEQ, coerced, neg1, "try_is_err");
            let mut err_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "try_err");
            let mut ok_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "try_ok");
            LLVMBuildCondBr(ctx.llvm_builder, is_err, err_bb, ok_bb);
            // Error path: fire defers + errdefers, then return -1
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, err_bb);
            let mut try_di: i32= ctx.defers.len - 1;
            while (try_di >= 0) {
                emit_deferred(&ctx.defers.data[try_di], ctx);
                try_di = try_di - 1;
            }
            let mut try_ei: i32= ctx.errdefers.len - 1;
            while (try_ei >= 0) {
                emit_deferred(&ctx.errdefers.data[try_ei], ctx);
                try_ei = try_ei - 1;
            }
            let mut ret_t: *i8= ctx.current_ret_type != (i8*)0 ? ctx.current_ret_type : i32_t;
            LLVMBuildRet(ctx.llvm_builder, coerce_int_val(neg1, ret_t, ctx.llvm_builder));
            // OK path: yield the value (0 for !void)
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, ok_bb);
            return coerced;
        }
    }

    // expr except |e| { handler }: evaluate expr; if error, run handler; else yield value
    if (kind == ek_except_expr) {
        if (e.object == (parser.expr_node*)0) { return (i8*)0; }
        let mut inner: *i8= visit_expr(e.object, ctx);
        if (inner == (i8*)0) { return (i8*)0; }
        let mut i32_t: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
        let mut inner_t: *i8= LLVMTypeOf(inner);
        let mut fn_ref: *i8= ctx.current_func;

        if (LLVMGetTypeKind(inner_t) == LLVMStructTypeKind) {
            // !T result: inner is { i32 is_err, T value }
            let mut is_err_v2: *i8= LLVMBuildExtractValue(ctx.llvm_builder, inner, 0, "exc_err_flag");
            let mut val_v2: *i8= LLVMBuildExtractValue(ctx.llvm_builder, inner, 1, "exc_val");
            let mut zero_e2: *i8= LLVMConstInt(i32_t, 0, 0);
            let mut is_err2: *i8= LLVMBuildICmp(ctx.llvm_builder, LLVMIntNE, is_err_v2, zero_e2, "exc_is_err");
            let mut err_bb2: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "exc_err");
            let mut ok_bb2: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "exc_ok");
            LLVMBuildCondBr(ctx.llvm_builder, is_err2, err_bb2, ok_bb2);
            // Error path: execute handler, passing error code as i32
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, err_bb2);
            if (e.handler_block != (i8*)0) {
                visit_except_handler(e, ctx, is_err_v2, i32_t);
            }
            let mut cur_bb2: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
            let mut term2: *i8= LLVMGetBasicBlockTerminator(cur_bb2);
            if (term2 == (i8*)0) { LLVMBuildBr(ctx.llvm_builder, ok_bb2); }
            // OK path: yield T value
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, ok_bb2);
            return val_v2;
        } else {
            // !void result (existing i32 ABI): -1 on error, 0 on success
            let mut coerced: *i8= coerce_int_val(inner, i32_t, ctx.llvm_builder);
            let mut minus1_exc: i64= (i64)-1;
            let mut neg1: *i8= LLVMConstInt(i32_t, (u64)minus1_exc, 1);
            let mut is_err: *i8= LLVMBuildICmp(ctx.llvm_builder, LLVMIntEQ, coerced, neg1, "exc_is_err");
            let mut err_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "exc_err");
            let mut ok_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "exc_ok");
            LLVMBuildCondBr(ctx.llvm_builder, is_err, err_bb, ok_bb);
            // Error path: execute handler block
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, err_bb);
            if (e.handler_block != (i8*)0) {
                visit_except_handler(e, ctx, neg1, i32_t);
            }
            // Only branch to ok_bb if block didn't already terminate
            let mut cur_bb: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
            let mut term: *i8= LLVMGetBasicBlockTerminator(cur_bb);
            if (term == (i8*)0) { LLVMBuildBr(ctx.llvm_builder, ok_bb); }
            // OK path: yield value
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, ok_bb);
            return coerced;
        }
    }

    // ---- ref expr: context-aware address-of or dereference ----
    // When target depth == 0 (no type annotation or value type): dereference operand
    //   to its base (non-pointer) value. ref 10 → 10; ref x (x:**int) → **x.
    // When target depth > 0: existing address-of / pointer-wrap behavior.
    if (kind == ek_ref_expr) {
        if (e.operand == (parser.expr_node*)0) { return (i8*)0; }
        let mut target_depth: i32= ctx.ref_target_depth;

        if (target_depth == 0) {
            // Depth-0 semantics: return the VALUE of the operand, fully dereferenced.
            if (e.operand.kind == ek_identifier && e.operand.str_val != (i8*)0) {
                let mut src_depth: i32= ctx_lookup_local_var_depth(ctx, e.operand.str_val);
                if (src_depth <= 0) {
                    // Variable at depth 0 (or not found): value IS the base value
                    return visit_expr(e.operand, ctx);
                }
                // Variable at depth > 0: load value, then dereference src_depth more times
                let mut val: *i8= visit_expr(e.operand, ctx);
                if (val == (i8*)0) { return (i8*)0; }
                let mut ptr_type_r: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                let mut base_ty: *i8= ctx_lookup_local_base_type(ctx, e.operand.str_val);
                if (base_ty == (i8*)0) { return val; }
                let mut cur: *i8= val;
                let mut lvl: i32= 0;
                while (lvl < src_depth) {
                    let mut load_ty: *i8= (lvl == src_depth - 1) ? base_ty : ptr_type_r;
                    cur = LLVMBuildLoad2(ctx.llvm_builder, load_ty, cur, "ref_deref");
                    lvl = lvl + 1;
                }
                return cur;
            }
            // Non-identifier operand (literal, expression): return value directly
            return visit_expr(e.operand, ctx);
        }

        // target_depth > 0: address-of / pointer-wrap behavior
        let mut ptr: *i8= visit_lvalue(e.operand, ctx);
        if (ptr == (i8*)0) {
            let mut val: *i8= visit_expr(e.operand, ctx);
            if (val == (i8*)0) { return (i8*)0; }
            let mut tmp: *i8= LLVMBuildAlloca(ctx.llvm_builder, LLVMTypeOf(val), "ref_tmp");
            LLVMBuildStore(ctx.llvm_builder, val, tmp);
            ptr = tmp;
        }
        if (target_depth <= 1) { return ptr; }
        let mut ptr_type: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
        let mut cur: *i8= ptr;
        let mut lvl: i32= 1;
        while (lvl < target_depth) {
            let mut next: *i8= LLVMBuildAlloca(ctx.llvm_builder, ptr_type, "ref_lvl");
            LLVMBuildStore(ctx.llvm_builder, cur, next);
            cur = next;
            lvl = lvl + 1;
        }
        return cur;
    }

    // ---- @shcopy(x) — explicit shallow copy (value semantics, already the default) ----
    if (kind == ek_shcopy) {
        if (e.operand == (parser.expr_node*)0) { return (i8*)0; }
        return visit_expr(e.operand, ctx);
    }

    // ---- @decopy(x) — deep copy ----
    // If the type has a __deep_copy__ method, call it; otherwise fall back to memcpy.
    if (kind == ek_decopy) {
        if (e.operand == (parser.expr_node*)0) { return (i8*)0; }
        let mut val: *i8= visit_expr(e.operand, ctx);
        if (val == (i8*)0) { return (i8*)0; }
        let mut vt: *i8= LLVMTypeOf(val);
        if (LLVMGetTypeKind(vt) == LLVMStructTypeKind) {
            let mut sname: *i8= LLVMGetStructName(vt);
            if (sname != (i8*)0) {
                let mut dc_name: [512]i8;
                snprintf(dc_name, (u64)512, "%s__NS___deep_copy__", sname);
                let mut dc_fn: *i8= sv_map_get(&ctx.global_funcs, dc_name);
                if (dc_fn != (i8*)0) {
                    let mut dc_ty: *i8= st_map_get(&ctx.global_func_types, dc_name);
                    let mut tmp: *i8= LLVMBuildAlloca(ctx.llvm_builder, vt, "dc_src");
                    LLVMBuildStore(ctx.llvm_builder, val, tmp);
                    let mut call_args: [1]*i8; call_args[0] = tmp;
                    return LLVMBuildCall2(ctx.llvm_builder, dc_ty, dc_fn, call_args, 1, "deep_copy");
                }
            }
            // Fallback: store value to a fresh alloca, then load — gives an
            // independent copy via SSA value semantics (shallow copy for structs
            // without a __deep_copy__ method).
            let mut cp: *i8= LLVMBuildAlloca(ctx.llvm_builder, vt, "dcpy_dst");
            LLVMBuildStore(ctx.llvm_builder, val, cp);
            return LLVMBuildLoad2(ctx.llvm_builder, vt, cp, "dcpy_val");
        }
        return val; // primitives: shallow == deep
    }

    // ---- @move(x) — move (copy value, then zero source) ----
    if (kind == ek_move_expr) {
        if (e.operand == (parser.expr_node*)0) { return (i8*)0; }
        let mut val: *i8= visit_expr(e.operand, ctx);
        if (val == (i8*)0) { return (i8*)0; }
        // Zero out the source lvalue if accessible
        let mut src_ptr: *i8= visit_lvalue(e.operand, ctx);
        if (src_ptr != (i8*)0) {
            let mut src_t: *i8= LLVMTypeOf(val);
            LLVMBuildStore(ctx.llvm_builder, LLVMConstNull(src_t), src_ptr);
        }
        return val;
    }

    // ---- quote {} — tokenstream literal (returns null ptr at runtime; meaningful at macro-expand time) ----
    if (kind == ek_quote) {
        let mut ptrt: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
        return LLVMConstPointerNull(ptrt);
    }

    // ---- @cstype(T) — first-class type value: returns i64 type ID constant ----
    // Encodes type information as a 64-bit integer: upper 32 bits = kind, lower 32 = bit width.
    // kind: 0=void, 1=int, 2=uint, 3=float, 4=bool, 5=pointer, 6=struct, 7=func_ptr
    if (kind == ek_cstype) {
        let mut i64t: *i8= LLVMInt64TypeInContext(ctx.llvm_ctx);
        if (e.cast_type == (parser.type_node*)0) { return LLVMConstInt(i64t, 0u, 0); }
        let mut tn: *parser.type_node= e.cast_type;
        let mut type_kind: i64= 0;
        let mut bw: i64= (i64)tn.bit_width;
        if (bw == 0) { bw = 32; }
        // Check pointer/func_ptr before primitive — *i32 has is_primitive=true but pointer_depth=1.
        if (tn.pointer_depth > 0) {
            type_kind = 5; bw = 64;
        } else if (tn.is_func_ptr) {
            type_kind = 7; bw = 64;
        } else if (tn.is_primitive) {
            // prim_type_t values: char_t=0, arb_int=1, arb_uint=2, arb_float=3, arb_bool=4, void_t=5
            if (tn.prim == 5)  { type_kind = 0; bw = 0; } // void
            else if (tn.prim == 4) { type_kind = 4; bw = 1; } // bool
            else if (tn.prim == 3) { type_kind = 3; }  // float
            else if (tn.prim == 1) { type_kind = 1; }  // signed int
            else if (tn.prim == 2) { type_kind = 2; }  // unsigned int
            else { type_kind = 1; } // fallback (char_t etc.)
        } else {
            type_kind = 6; bw = 0; // struct/named — size unknown without layout
        }
        let mut encoded: i64= (type_kind << 32) | (bw & 0xffffffff);
        return LLVMConstInt(i64t, (u64)encoded, 0);
    }

    // ---- lambda expression: [captures](params) RetType? { body } ----
    // Strategy: synthesize a module-level function. Captures are stored in module-level
    // globals BEFORE the function body is built, so the body can load from them.
    // By-value globals: __lambda_N_cap_NAME   (hold the captured value)
    // By-ref  globals: __lambda_N_capref_NAME (hold the *address* of the outer variable)
    if (kind == ek_lambda) {
        let mut cap_all_val: bool= (e.str_val != (i8*)0 && e.str_val[0] == 'v');
        let mut cap_all_ref: bool= (e.str_val != (i8*)0 && e.str_val[1] == 'r');

        let mut lam_idx: i32= ctx.static_local_count;
        ctx.static_local_count = ctx.static_local_count + 1;
        let mut lam_name: [128]i8;
        snprintf(lam_name, (u64)128, "__lambda_%d", lam_idx);

        // ---- STEP 1: at call site, create capture globals and store current values ----
        let mut call_site_bb: *i8= LLVMGetInsertBlock(ctx.llvm_builder);

        // Helper lambda to create/fill one capture global (used inline below)
        // We iterate the explicit list OR all scope locals, whichever applies.

        // Build a local list of (name, byref, alloca_ptr, elem_type) for all captures
        let mut capinfo_cap: i32= 32;
        let mut capinfo_names: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)capinfo_cap);
        let mut capinfo_byref: *i32= (i32*)arc_malloc(sizeof(i32) * (u64)capinfo_cap);
        let mut capinfo_ptrs: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)capinfo_cap);
        let mut capinfo_types: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)capinfo_cap);
        let mut capinfo_len: i32= 0;

        if (cap_all_val || cap_all_ref) {
            // Capture every local visible in the call-site scope
            let mut scope_i: i32= 0;
            while (scope_i < ctx.scopes.len) {
                let mut sf_len: i32= ctx.scopes.data[scope_i].alloca_ptrs.len;
                let mut si: i32= 0;
                while (si < sf_len) {
                    let mut vname_c: *i8= ctx.scopes.data[scope_i].alloca_ptrs.data[si].key;
                    let mut vptr_c: *i8= ctx.scopes.data[scope_i].alloca_ptrs.data[si].val;
                    if (vname_c != (i8*)0 && vptr_c != (i8*)0) {
                        let mut vtype_c: *i8= ctx_lookup_local_type(ctx, vname_c);
                        if (vtype_c != (i8*)0) {
                            if (capinfo_len >= capinfo_cap) {
                                capinfo_cap = capinfo_cap * 2;
                                capinfo_names = (i8**)arc_realloc((i8*)capinfo_names, sizeof(i8*) * (u64)capinfo_cap);
                                capinfo_byref = (i32*)arc_realloc((i8*)capinfo_byref, sizeof(i32) * (u64)capinfo_cap);
                                capinfo_ptrs  = (i8**)arc_realloc((i8*)capinfo_ptrs,  sizeof(i8*) * (u64)capinfo_cap);
                                capinfo_types = (i8**)arc_realloc((i8*)capinfo_types,  sizeof(i8*) * (u64)capinfo_cap);
                            }
                            capinfo_names[capinfo_len] = vname_c;
                            capinfo_byref[capinfo_len] = cap_all_ref ? 1 : 0;
                            capinfo_ptrs [capinfo_len] = vptr_c;
                            capinfo_types[capinfo_len] = vtype_c;
                            capinfo_len = capinfo_len + 1;
                        }
                    }
                    si = si + 1;
                }
                scope_i = scope_i + 1;
            }
        } else {
            // Explicit captures
            let mut ci_e: i32= 0;
            while (ci_e < e.lambda_cap_len) {
                let mut cname_e: *i8= (e.lambda_cap_names != (i8**)0 && e.lambda_cap_names[ci_e] != (i8*)0)
                                   ? e.lambda_cap_names[ci_e] : (i8*)0;
                let mut byref_e: bool= false;
                if (e.lambda_cap_byref != (i32*)0) { byref_e = e.lambda_cap_byref[ci_e] != 0; }
                if (cname_e != (i8*)0) {
                    let mut vptr_e: *i8= ctx_lookup_local(ctx, cname_e);
                    let mut vtype_e: *i8= ctx_lookup_local_type(ctx, cname_e);
                    if (vptr_e != (i8*)0 && vtype_e != (i8*)0) {
                        if (capinfo_len >= capinfo_cap) {
                            capinfo_cap = capinfo_cap * 2;
                            capinfo_names = (i8**)arc_realloc((i8*)capinfo_names, sizeof(i8*) * (u64)capinfo_cap);
                            capinfo_byref = (i32*)arc_realloc((i8*)capinfo_byref, sizeof(i32) * (u64)capinfo_cap);
                            capinfo_ptrs  = (i8**)arc_realloc((i8*)capinfo_ptrs,  sizeof(i8*) * (u64)capinfo_cap);
                            capinfo_types = (i8**)arc_realloc((i8*)capinfo_types,  sizeof(i8*) * (u64)capinfo_cap);
                        }
                        capinfo_names[capinfo_len] = cname_e;
                        capinfo_byref[capinfo_len] = byref_e ? 1 : 0;
                        capinfo_ptrs [capinfo_len] = vptr_e;
                        capinfo_types[capinfo_len] = vtype_e;
                        capinfo_len = capinfo_len + 1;
                    }
                }
                ci_e = ci_e + 1;
            }
        }

        // Create the globals and store current values (at call site)
        let mut ci_s: i32= 0;
        while (ci_s < capinfo_len) {
            let mut cn_s: *i8= capinfo_names[ci_s];
            let mut br_s: i32= capinfo_byref[ci_s];
            let mut ptr_s: *i8= capinfo_ptrs [ci_s];
            let mut type_s: *i8= capinfo_types[ci_s];
            let mut gn_s: [256]i8;
            if (br_s != 0) {
                snprintf(gn_s, (u64)256, "__lambda_%d_capref_%s", lam_idx, cn_s);
                let mut ptrt_s: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                let mut gv_s: *i8= sv_map_get(&ctx.global_vars, gn_s);
                if (gv_s == (i8*)0) {
                    gv_s = LLVMAddGlobal(ctx.llvm_mod, ptrt_s, gn_s);
                    LLVMSetInitializer(gv_s, LLVMConstNull(ptrt_s));
                    LLVMSetLinkage(gv_s, LLVMInternalLinkage);
                    sv_map_set(&ctx.global_vars, gn_s, gv_s);
                }
                LLVMBuildStore(ctx.llvm_builder, ptr_s, gv_s);
            } else {
                snprintf(gn_s, (u64)256, "__lambda_%d_cap_%s", lam_idx, cn_s);
                let mut cur_val_s: *i8= LLVMBuildLoad2(ctx.llvm_builder, type_s, ptr_s, "cap_load");
                let mut gv_s: *i8= sv_map_get(&ctx.global_vars, gn_s);
                if (gv_s == (i8*)0) {
                    gv_s = LLVMAddGlobal(ctx.llvm_mod, type_s, gn_s);
                    LLVMSetInitializer(gv_s, LLVMConstNull(type_s));
                    LLVMSetLinkage(gv_s, LLVMInternalLinkage);
                    sv_map_set(&ctx.global_vars, gn_s, gv_s);
                }
                LLVMBuildStore(ctx.llvm_builder, cur_val_s, gv_s);
            }
            ci_s = ci_s + 1;
        }

        // ---- STEP 2: build return type and param types ----
        let mut lret_t: *i8= (i8*)0;
        if (e.lambda_ret_type != (parser.type_node*)0) {
            lret_t = llvm_type_of(e.lambda_ret_type, ctx);
        }
        if (lret_t == (i8*)0) { lret_t = LLVMVoidTypeInContext(ctx.llvm_ctx); }

        let mut nparams: i32= e.lambda_param_len;
        let mut lpar_types: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)(nparams + 1));
        let mut lpi: i32= 0;
        while (lpi < nparams) {
            let mut pt: *i8= (i8*)0;
            if (e.lambda_param_types != (parser.type_node**)0 && e.lambda_param_types[lpi] != (parser.type_node*)0) {
                pt = llvm_type_of(e.lambda_param_types[lpi], ctx);
            }
            if (pt == (i8*)0) { pt = LLVMInt32TypeInContext(ctx.llvm_ctx); }
            lpar_types[lpi] = pt;
            lpi = lpi + 1;
        }

        let mut lft: *i8= LLVMFunctionType(lret_t, lpar_types, nparams, 0);
        let mut lfn: *i8= LLVMAddFunction(ctx.llvm_mod, lam_name, lft);
        LLVMSetLinkage(lfn, LLVMInternalLinkage);

        // ---- STEP 3: build function body ----
        let mut saved_fn: *i8= ctx.current_func;
        let mut saved_rt: *i8= ctx.current_ret_type;
        ctx.current_func     = lfn;
        ctx.current_ret_type = lret_t;

        let mut lam_entry: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, lfn, "entry");
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, lam_entry);
        ctx_push_scope(ctx);

        // Bind declared parameters
        let mut lpi2: i32= 0;
        while (lpi2 < nparams) {
            let mut pname: *i8= (e.lambda_param_names != (i8**)0 && e.lambda_param_names[lpi2] != (i8*)0)
                            ? e.lambda_param_names[lpi2] : "p";
            let mut pval: *i8= LLVMGetParam(lfn, (u32)lpi2);
            let mut palloca: *i8= LLVMBuildAlloca(ctx.llvm_builder, lpar_types[lpi2], pname);
            LLVMBuildStore(ctx.llvm_builder, pval, palloca);
            ctx_declare_local(ctx, pname, palloca, lpar_types[lpi2], (i8*)0, false);
            lpi2 = lpi2 + 1;
        }

        // Inject captures as locals (globals are already created above)
        let mut ci_b: i32= 0;
        while (ci_b < capinfo_len) {
            let mut cn_b: *i8= capinfo_names[ci_b];
            let mut br_b: i32= capinfo_byref[ci_b];
            let mut gn_b: [256]i8;
            if (br_b != 0) {
                snprintf(gn_b, (u64)256, "__lambda_%d_capref_%s", lam_idx, cn_b);
                let mut ptrt_b: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                let mut gv_b: *i8= sv_map_get(&ctx.global_vars, gn_b);
                if (gv_b != (i8*)0) {
                    // Load the stored address — that pointer IS the local variable's slot
                    let mut addr_b: *i8= LLVMBuildLoad2(ctx.llvm_builder, ptrt_b, gv_b, "cap_addr");
                    let mut deref_t_b: *i8= capinfo_types[ci_b];
                    ctx_declare_local(ctx, cn_b, addr_b, deref_t_b, (i8*)0, false);
                }
            } else {
                snprintf(gn_b, (u64)256, "__lambda_%d_cap_%s", lam_idx, cn_b);
                let mut gv_b: *i8= sv_map_get(&ctx.global_vars, gn_b);
                if (gv_b != (i8*)0) {
                    let mut gv_t_b: *i8= capinfo_types[ci_b];
                    let mut val_b: *i8= LLVMBuildLoad2(ctx.llvm_builder, gv_t_b, gv_b, "cap_val");
                    let mut alloc_b: *i8= LLVMBuildAlloca(ctx.llvm_builder, gv_t_b, cn_b);
                    LLVMBuildStore(ctx.llvm_builder, val_b, alloc_b);
                    ctx_declare_local(ctx, cn_b, alloc_b, gv_t_b, (i8*)0, false);
                }
            }
            ci_b = ci_b + 1;
        }

        // Emit body
        visit_block_stmt((parser.block_stmt*)e.lambda_body, ctx);

        // Ensure terminator
        let mut cur_lam_bb: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
        if (cur_lam_bb != (i8*)0) {
            let mut term_lam: *i8= LLVMGetBasicBlockTerminator(cur_lam_bb);
            if (term_lam == (i8*)0) {
                if (LLVMGetTypeKind(lret_t) == LLVMVoidTypeKind) {
                    LLVMBuildRetVoid(ctx.llvm_builder);
                } else {
                    printf("error: lambda may not return on all paths (line %d)\n", (i32)e.line);
                    ctx.had_error = true;
                    LLVMBuildRet(ctx.llvm_builder, LLVMConstNull(lret_t));
                }
            }
        }
        ctx_pop_scope(ctx);

        // ---- STEP 4: restore builder to call site ----
        ctx.current_func     = saved_fn;
        ctx.current_ret_type = saved_rt;
        if (call_site_bb != (i8*)0) {
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, call_site_bb);
        }

        arc_free((i8*)capinfo_names);
        arc_free((i8*)capinfo_byref);
        arc_free((i8*)capinfo_ptrs);
        arc_free((i8*)capinfo_types);
        arc_free((i8*)lpar_types);

        // Return the function pointer to the synthesized lambda function
        return lfn;
    }

    // @self() — returns ptr to the implicit 'self' local in the current method
    if (kind == ek_self_builtin) {
        let mut self_alloca: *i8= ctx_lookup_local(ctx, "self");
        if (self_alloca != (i8*)0) {
            let mut ptr_t: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
            return LLVMBuildLoad2(ctx.llvm_builder, ptr_t, self_alloca, "self_ptr");
        }
        return LLVMConstPointerNull(LLVMPointerTypeInContext(ctx.llvm_ctx, 0));
    }

    // @ifield() — returns the self-pointer alloca slot (a **Self, distinct from @self()
    // which loads and returns the *Self pointer value).
    // @ifield() — the *type metadata* of the enclosing container, i.e. a
    // *type_info for the istruc/struct this method belongs to. Returning the `self`
    // pointer here (which is what @self() yields) made the two builtins identical
    // and handed callers an object pointer where they expected type metadata.
    if (kind == ek_ifield) {
        let mut ptr_t_if: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
        let mut owner: *i8= ctx.current_namespace;
        if (owner == (i8*)0) {
            printf("error: @ifield() is only valid inside a method of a struct or istruc\n");
            ctx.had_error = true;
            return LLVMConstPointerNull(ptr_t_if);
        }
        // Build a type_node naming the enclosing type and reuse the @typeinfo path,
        // so @ifield() and @typeinfo(Owner) return the very same global.
        let mut owner_tn: parser.type_node;
        memset((i8*)&owner_tn, 0, sizeof(parser__NS_type_node));
        owner_tn.name         = owner;
        owner_tn.is_primitive = false;
        owner_tn.has_prim     = false;
        let mut ti_gv: *i8= emit_typeinfo_global(&owner_tn, ctx);
        if (ti_gv == (i8*)0) { return LLVMConstPointerNull(ptr_t_if); }
        return ti_gv;
    }

    // @typeof(x) — comptime type; at runtime yields sizeof(typeof(x)) as i64
    if (kind == ek_typeof_e) {
        if (e.operand != (parser.expr_node*)0) {
            let mut tv: *i8= visit_expr(e.operand, ctx);
            if (tv != (i8*)0) { return LLVMSizeOf(LLVMTypeOf(tv)); }
        }
        let mut i64t2: *i8= LLVMInt64TypeInContext(ctx.llvm_ctx);
        return LLVMConstInt(i64t2, 0u, 0);
    }

    // Anonymous struct literal: .{ .f=v, ... }
    // Synthesize an anonymous named struct type from field names+values and alloca it.
    if (kind == ek_anon_struct && e.field_count > 0 && e.field_names != (i8**)0 && e.field_vals != (parser.expr_node**)0) {
        let mut nf: i32= e.field_count;
        let mut ftypes: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)nf);
        let mut fvals: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)nf);
        let mut fi2: i32= 0;
        let mut valid: bool= true;
        while (fi2 < nf) {
            let mut fv2: *i8= visit_expr((parser.expr_node*)e.field_vals[fi2], ctx);
            if (fv2 == (i8*)0) { valid = false; }
            fvals[fi2] = fv2;
            ftypes[fi2] = (fv2 != (i8*)0) ? LLVMTypeOf(fv2) : LLVMInt32TypeInContext(ctx.llvm_ctx);
            fi2 = fi2 + 1;
        }
        if (!valid) { arc_free((i8*)ftypes); arc_free((i8*)fvals); return (i8*)0; }
        // Build a unique anonymous struct type name: __anon_LINENO
        let mut anon_name: [64]i8;
        snprintf(anon_name, (u64)64, "__anon_%llu", e.line);
        let mut anon_st: *i8= LLVMGetTypeByName2(ctx.llvm_ctx, anon_name);
        if (anon_st == (i8*)0) {
            anon_st = LLVMStructCreateNamed(ctx.llvm_ctx, anon_name);
            LLVMStructSetBody(anon_st, ftypes, nf, 0);
        }
        let mut anon_alloca: *i8= LLVMBuildAlloca(ctx.llvm_builder, anon_st, "anon_s");
        // Store each field
        let mut fi3: i32= 0;
        while (fi3 < nf) {
            let mut gep3: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, anon_st, anon_alloca, (u32)fi3, "anon_f");
            LLVMBuildStore(ctx.llvm_builder, fvals[fi3], gep3);
            fi3 = fi3 + 1;
        }
        // Register field metadata so .field access resolves correctly
        if (struct_meta_find(&ctx.struct_meta_tbl, anon_name) == (struct_meta*)0) {
            let mut anon_sm: struct_meta;
            anon_sm.name = lexer.str_dup(anon_name);
            name_list_init(&anon_sm.field_names);
            type_list_init(&anon_sm.field_types);
            bool_list_init(&anon_sm.field_unsigned);
            type_list_init(&anon_sm.field_pointee);
            name_list_init(&anon_sm.field_pointee_names);
            anon_sm.is_union = false;
            anon_sm.is_istruc = false;
            let mut fi4: i32= 0;
            while (fi4 < nf) {
                name_list_push(&anon_sm.field_names, e.field_names[fi4]);
                type_list_push(&anon_sm.field_types, ftypes[fi4]);
                bool_list_push(&anon_sm.field_unsigned, false);
                type_list_push(&anon_sm.field_pointee, (i8*)0);
                name_list_push(&anon_sm.field_pointee_names, (i8*)0);
                fi4 = fi4 + 1;
            }
            struct_meta_vec_push(&ctx.struct_meta_tbl, anon_sm);
        }
        arc_free((i8*)ftypes);
        arc_free((i8*)fvals);
        return LLVMBuildLoad2(ctx.llvm_builder, anon_st, anon_alloca, "anon_load");
    }

    // Any expression kind reaching here has no codegen rule. Falling through with a
    // bare null would surface later as a null LLVM operand at some unrelated
    // instruction, so report the real location instead.
    printf("error at line %llu: unsupported expression (kind %d) in value position\n", (u64)e.line, kind);
    ctx.had_error = true;
    return (i8*)0;
}

} // namespace ir
