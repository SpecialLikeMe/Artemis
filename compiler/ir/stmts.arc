// Statement IR generation for the Artemis self-hosting compiler.

namespace ir {

// Forward declarations
fn visit_stmt(node: *parser.ast_node, ctx: *ir_context) void;
fn visit_block_stmt(blk: *parser.block_stmt, ctx: *ir_context) void;
fn constexpr_eval_expr(e: *parser.expr_node, ctx: *ir_context, out: *i64) bool;
// Forward declaration for decls.arc function (included after stmts.arc)
fn visit_top_level_decl(node: *parser.ast_node, ctx: *ir_context) void;

// Emit deferred items in reverse order (LIFO).
fn emit_deferred(scope: *defer_scope, ctx: *ir_context) void {
    if (scope == (defer_scope*)0) { return; }
    let mut i: i32= scope.len - 1;
    while (i >= 0) {
        if (ctx_is_terminated(ctx)) { break; }
        let mut di: defer_item= scope.data[i];
        if (di.is_block) {
            visit_block_stmt((parser.block_stmt*)di.ptr, ctx);
        } else {
            visit_expr((parser.expr_node*)di.ptr, ctx);
        }
        i = i - 1;
    }
}

fn visit_block_stmt(blk: *parser.block_stmt, ctx: *ir_context) void {
    ctx_push_scope(ctx);
    ctx_push_defer_scope(ctx);
    ctx_push_errdefer_scope(ctx);

    let mut i: i32= 0;
    while (i < blk.stmts_len) {
        if (ctx_is_terminated(ctx)) { break; }
        visit_stmt(blk.stmts[i], ctx);
        i = i + 1;
    }

    let mut ds: defer_scope= ctx_pop_defer_scope(ctx);
    ctx_pop_errdefer_scope(ctx);
    if (!ctx_is_terminated(ctx)) {
        emit_deferred(&ds, ctx);
    }
    ctx_pop_scope(ctx);
}

// ---- istruc default initialization helper ----

// Applies the default field values for istruc `sname` to the allocation at `alloca_ptr`.
// Recurses into nested istruc fields that have no explicit initializer.
fn apply_istruc_defaults(alloca_ptr: *i8, sname: *i8, alloca_t: *i8, ctx: *ir_context) void {
    let mut istruc_nd: *parser.namespace_decl= (parser.namespace_decl*)sv_map_get(&ctx.istruc_decls, sname);
    if (istruc_nd == (parser.namespace_decl*)0) { return; }
    if (!istruc_nd.is_istruc) { return; }
    if (istruc_nd.decls_len == 0) { return; }
    if (istruc_nd.decls[0] == (parser.ast_node*)0) { return; }
    if (istruc_nd.decls[0].kind != nd_struct_decl) { return; }
    let mut isd: *parser.struct_decl= (parser.struct_decl*)istruc_nd.decls[0];
    let mut fi: i32= 0;
    while (fi < isd.fields_len) {
        let mut fvd: *parser.var_decl= isd.fields[fi];
        if (fvd != (parser.var_decl*)0 && fvd.name != (i8*)0) {
            if (fvd.has_init && fvd.init != (parser.expr_node*)0) {
                let mut fidx: i32= ctx_field_index(ctx, sname, fvd.name);
                if (fidx >= 0) {
                    let mut fptr: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, alloca_t, alloca_ptr, (i32)fidx, fvd.name);
                    let mut fval: *i8= visit_expr(fvd.init, ctx);
                    if (fval != (i8*)0 && fptr != (i8*)0) {
                        let mut ft2: *i8= ctx_field_type(ctx, sname, fidx);
                        if (ft2 != (i8*)0) { fval = coerce_int_val(fval, ft2, ctx.llvm_builder); }
                        LLVMBuildStore(ctx.llvm_builder, fval, fptr);
                    }
                }
            } else if (!fvd.has_init && fvd.type != (parser.type_node*)0 &&
                       fvd.type.name != (i8*)0 && fvd.type.pointer_depth == 0) {
                // No explicit init — if the field type is an istruc, apply ITS defaults recursively.
                let mut nested_nd: *parser.namespace_decl= (parser.namespace_decl*)sv_map_get(&ctx.istruc_decls, fvd.type.name);
                if (nested_nd != (parser.namespace_decl*)0 && nested_nd.is_istruc) {
                    let mut fidx_n: i32= ctx_field_index(ctx, sname, fvd.name);
                    if (fidx_n >= 0) {
                        let mut nested_t: *i8= st_map_get(&ctx.struct_types, fvd.type.name);
                        if (nested_t != (i8*)0) {
                            let mut nested_ptr: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, alloca_t, alloca_ptr, (i32)fidx_n, fvd.name);
                            apply_istruc_defaults(nested_ptr, fvd.type.name, nested_t, ctx);
                        }
                    }
                }
            }
        }
        fi = fi + 1;
    }
}

// ---- Local variable declaration ----

fn visit_local_var_decl(d: *parser.var_decl, ctx: *ir_context) void {
    if (d.is_sta) { return; }
    if (d.type != (parser.type_node*)0 && d.type.is_sta) { return; }

    // static local: backed by a module-level global with a one-time init flag
    if (d.is_static_local) {
        let mut alloca_t: *i8= llvm_type_of(d.type, ctx);

        // Build unique names using a per-module counter
        let mut gname: [256]i8;
        let mut fname: [256]i8;
        ctx.static_local_count = ctx.static_local_count + 1;
        afmt(gname, (u64)256, "__stloc_%s_%d", .{ d.name, ctx.static_local_count });
        afmt(fname, (u64)256, "__stloc_%s_%d_init", .{ d.name, ctx.static_local_count });

        // Create or reuse the global variable
        let mut gv: *i8= LLVMGetNamedGlobal(ctx.llvm_mod, gname);
        if (gv == (i8*)0) {
            gv = LLVMAddGlobal(ctx.llvm_mod, alloca_t, gname);
            LLVMSetInitializer(gv, LLVMConstNull(alloca_t));
            LLVMSetLinkage(gv, 3); // internal linkage
        }

        // Create or reuse the i1 init-done flag global
        let mut i1_t: *i8= LLVMInt1TypeInContext(ctx.llvm_ctx);
        let mut fv: *i8= LLVMGetNamedGlobal(ctx.llvm_mod, fname);
        if (fv == (i8*)0) {
            fv = LLVMAddGlobal(ctx.llvm_mod, i1_t, fname);
            LLVMSetInitializer(fv, LLVMConstNull(i1_t));
            LLVMSetLinkage(fv, 3);
        }

        // Insert: if (!init_flag) { init_flag = true; *gv = init_val; }
        let mut cur_fn: *i8= ctx.current_func;
        let mut init_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, cur_fn, "stloc_init");
        let mut cont_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, cur_fn, "stloc_cont");
        let mut flag_val: *i8= LLVMBuildLoad2(ctx.llvm_builder, i1_t, fv, "stloc_flag");
        LLVMBuildCondBr(ctx.llvm_builder, flag_val, cont_bb, init_bb);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, init_bb);
        LLVMBuildStore(ctx.llvm_builder, LLVMConstInt(i1_t, (u64)1, false), fv);
        if (d.has_init && d.init != (parser.expr_node*)0) {
            let mut init_val: *i8= visit_expr(d.init, ctx);
            if (init_val != (i8*)0) {
                init_val = coerce_int_val(init_val, alloca_t, ctx.llvm_builder);
                LLVMBuildStore(ctx.llvm_builder, init_val, gv);
            }
        }
        LLVMBuildBr(ctx.llvm_builder, cont_bb);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, cont_bb);

        // Register the global as a local so name lookup returns it
        let mut is_uns_b: *i8= (i8*)0;
        let mut is_uns: bool= is_unsigned_type_node(d.type);
        let mut is_vol: bool= (d.type != (parser.type_node*)0) && d.type.is_volatile;
        let mut elem_t: *i8= alloca_t;
        if (LLVMGetTypeKind(alloca_t) == LLVMArrayTypeKind) {
            elem_t = LLVMGetElementType(alloca_t);
        }
        let mut deref_t: *i8= (i8*)0;
        if (d.type != (parser.type_node*)0 && !d.type.is_func_ptr && d.type.pointer_depth > 0) {
            let mut resolved: parser.type_node;
            resolved = *d.type;
            resolved.pointer_depth = resolved.pointer_depth - 1;
            deref_t = llvm_type_of(&resolved, ctx);
        }
        let mut local_t: *i8= (LLVMGetTypeKind(alloca_t) == LLVMArrayTypeKind) ? alloca_t : elem_t;
        if (is_vol) {
            ctx_declare_local_volatile(ctx, d.name, gv, local_t, deref_t, is_uns);
        } else {
            ctx_declare_local(ctx, d.name, gv, local_t, deref_t, is_uns);
        }
        if (d.type != (parser.type_node*)0 && d.type.ptr_data_const) {
            ctx_mark_local_const_ptr(ctx, d.name);
        }
        return;
    }

    let mut alloca_t: *i8= llvm_type_of(d.type, ctx);
    let mut elem_t: *i8= alloca_t;
    let mut tk: i32= LLVMGetTypeKind(alloca_t);
    if (tk == LLVMArrayTypeKind) {
        elem_t = LLVMGetElementType(alloca_t);
    }

    // Deref type for pointer variables
    let mut deref_t: *i8= (i8*)0;
    if (d.type != (parser.type_node*)0 && !d.type.is_func_ptr && d.type.pointer_depth > 0) {
        let mut resolved: parser.type_node;
        resolved = *d.type;
        resolved.pointer_depth = resolved.pointer_depth - 1;
        deref_t = llvm_type_of(&resolved, ctx);
    }

    // Auto type inference: if type resolved to void (e.g. `using let = auto;`),
    // evaluate init first to infer the actual type.
    let mut pre_init_val: *i8= (i8*)0;
    let mut used_pre_init: bool= false;
    if (tk == LLVMVoidTypeKind && d.has_init && d.init != (parser.expr_node*)0) {
        pre_init_val = visit_expr(d.init, ctx);
        if (pre_init_val != (i8*)0) {
            let mut inferred: *i8= LLVMTypeOf(pre_init_val);
            if (LLVMGetTypeKind(inferred) != LLVMVoidTypeKind) {
                alloca_t = inferred;
                elem_t   = alloca_t;
                tk       = LLVMGetTypeKind(alloca_t);
                used_pre_init = true;
                // @typeinfo(T) init: set deref_t to type_info so member access works
                if (d.init.kind == ek_typeinfo_e) {
                    ensure_typeinfo_types(ctx);
                    deref_t = st_map_get(&ctx.struct_types, "type_info");
                }
            }
        }
    }

    let mut alloca: *i8= LLVMBuildAlloca(ctx.llvm_builder, alloca_t, d.name);
    let mut is_uns: bool= is_unsigned_type_node(d.type);
    let mut is_vol: bool= (d.type != (parser.type_node*)0) && d.type.is_volatile;
    // For arrays, store the full array type so subscript GEP can safely get element type.
    let mut local_t: *i8= (tk == LLVMArrayTypeKind) ? alloca_t : elem_t;
    if (is_vol) {
        ctx_declare_local_volatile(ctx, d.name, alloca, local_t, deref_t, is_uns);
    } else {
        ctx_declare_local(ctx, d.name, alloca, local_t, deref_t, is_uns);
    }
    if (d.type != (parser.type_node*)0 && d.type.ptr_data_const) {
        ctx_mark_local_const_ptr(ctx, d.name);
    }

    // Store semantic pointer depth and base LLVM type so ref-deref can correctly
    // dereference multi-level pointers when ref is used with no type annotation.
    if (d.type != (parser.type_node*)0 && !d.type.is_func_ptr) {
        ctx_declare_local_var_depth(ctx, d.name, d.type.pointer_depth);
        if (d.type.pointer_depth > 0) {
            let mut base_tn: parser.type_node;
            base_tn = *d.type;
            base_tn.pointer_depth = 0;
            let mut base_llvm_ty: *i8= llvm_type_of(&base_tn, ctx);
            if (base_llvm_ty != (i8*)0) {
                ctx_declare_local_base_type(ctx, d.name, base_llvm_ty);
            }
        }
    }

    // For function pointer locals, store the function type so indirect calls work
    // in LLVM opaque-pointer mode (where LLVMGetElementType on ptr is null).
    if (d.type != (parser.type_node*)0 && d.type.is_func_ptr) {
        let mut fn_ty: *i8= llvm_func_type_of(d.type, ctx);
        if (fn_ty != (i8*)0) {
            ctx_declare_local_func_type(ctx, d.name, fn_ty);
            ctx_declare_local_func_depth(ctx, d.name, d.type.pointer_depth);
        }
    }

    // Propagate type to implicit struct literals: Vec2 v = .{.x=1, .y=2}
    if (d.has_init && d.init != (parser.expr_node*)0 &&
            d.init.kind == ek_class_init && d.init.is_implicit_init &&
            d.init.init_type == (parser.type_node*)0) {
        d.init.init_type = d.type;
    }

    // For struct literals, apply istruc field defaults BEFORE visiting the init
    // expression so that fields not explicitly set keep their default values.
    if (d.has_init && d.init != (parser.expr_node*)0 && d.init.kind == ek_class_init &&
            LLVMGetTypeKind(alloca_t) == LLVMStructTypeKind) {
        let mut sname_def: *i8= LLVMGetStructName(alloca_t);
        if (sname_def == (i8*)0 && d.type != (parser.type_node*)0) { sname_def = d.type.name; }
        if (sname_def != (i8*)0) {
            apply_istruc_defaults(alloca, sname_def, alloca_t, ctx);
        }
        ctx.class_init_alloca = alloca;
    }

    if (d.has_init) {
        // Thread the declared pointer depth into the context so that the ref_expr handler
        // can build the correct number of indirection levels (depth 1 = &x, depth 2 = &&x, ...).
        if (!used_pre_init && d.init != (parser.expr_node*)0 && d.init.kind == ek_ref_expr && d.type != (parser.type_node*)0) {
            ctx.ref_target_depth = d.type.pointer_depth;
        }
        let mut init_val: *i8= (i8*)0;
        if (used_pre_init) {
            init_val = pre_init_val;
        } else if (d.init != (parser.expr_node*)0 && d.init.kind == ek_int_lit &&
                   d.init.str_val != (i8*)0 &&
                   LLVMGetTypeKind(alloca_t) == LLVMIntegerTypeKind &&
                   LLVMGetIntTypeWidth(alloca_t) > 64) {
            // Wide positive integer literals (>64 bits): avoid i64 overflow truncation.
            let mut str_v: *i8= d.init.str_val;
            let mut radix: u8= 10;
            if (str_v[0] == '0' && (str_v[1] == 'x' || str_v[1] == 'X')) { radix = 16; str_v = str_v + 2; }
            else if (str_v[0] == '0' && (str_v[1] == 'b' || str_v[1] == 'B')) { radix = 2; str_v = str_v + 2; }
            init_val = LLVMConstIntOfString(alloca_t, str_v, radix);
        } else if (d.init != (parser.expr_node*)0 &&
                   d.init.kind == ek_unary && d.init.uop == uop_neg &&
                   d.init.operand != (parser.expr_node*)0 &&
                   d.init.operand.kind == ek_int_lit && d.init.operand.str_val != (i8*)0 &&
                   LLVMGetTypeKind(alloca_t) == LLVMIntegerTypeKind &&
                   LLVMGetIntTypeWidth(alloca_t) > 64) {
            // Wide negative integer literal: prefix magnitude string with '-' for LLVMConstIntOfString.
            let mut mag: *i8= d.init.operand.str_val;
            let mut radix: u8= 10;
            if (mag[0] == '0' && (mag[1] == 'x' || mag[1] == 'X')) { radix = 16; mag = mag + 2; }
            else if (mag[0] == '0' && (mag[1] == 'b' || mag[1] == 'B')) { radix = 2; mag = mag + 2; }
            let mut neg_len: u64= strlen(mag) + 2;
            let mut neg_buf: *i8= (i8*)arc_malloc(neg_len);
            neg_buf[0] = '-';
            memcpy(neg_buf + 1, mag, strlen(mag) + 1);
            init_val = LLVMConstIntOfString(alloca_t, neg_buf, radix);
            arc_free(neg_buf);
        } else {
            init_val = visit_expr(d.init, ctx);
        }
        ctx.ref_target_depth = 0;
        ctx.class_init_alloca = (i8*)0;
        if (init_val != (i8*)0) {
            // If the initializer was a lambda, register its function type for indirect calls
            if (d.init != (parser.expr_node*)0 && d.init.kind == ek_lambda) {
                let mut fn_t: *i8= LLVMGlobalGetValueType(init_val);
                if (fn_t != (i8*)0 && LLVMGetTypeKind(fn_t) == LLVMFunctionTypeKind) {
                    ctx_declare_local_func_type(ctx, d.name, fn_t);
                }
            }
            init_val = coerce_int_val(init_val, alloca_t, ctx.llvm_builder);
            LLVMBuildStore(ctx.llvm_builder, init_val, alloca);
        } else {
            LLVMBuildStore(ctx.llvm_builder, LLVMConstNull(alloca_t), alloca);
        }
    } else {
        LLVMBuildStore(ctx.llvm_builder, LLVMConstNull(alloca_t), alloca);
    }

    // Constructor call: TypeName varname(args...) or auto no-arg constructor
    if (d.has_ctor_parens || (!d.has_init && LLVMGetTypeKind(alloca_t) == LLVMStructTypeKind)) {
        let mut sname: *i8= (i8*)0;
        if (LLVMGetTypeKind(alloca_t) == LLVMStructTypeKind) {
            sname = LLVMGetStructName(alloca_t);
        }
        if (sname == (i8*)0 && d.type != (parser.type_node*)0) {
            sname = d.type.name;
        }
        if (sname != (i8*)0) {
            // Apply istruc field defaults (including nested istruc fields) recursively.
            apply_istruc_defaults(alloca, sname, alloca_t, ctx);

            let mut ctor_name: [512]i8;
            afmt(ctor_name, (u64)512, "%s__NS___construct__", .{ sname });
            let mut ctor_fn: *i8= sv_map_get(&ctx.global_funcs, ctor_name);
            let mut ctor_ft: *i8= st_map_get(&ctx.global_func_types, ctor_name);
            if (ctor_fn != (i8*)0 && ctor_ft != (i8*)0) {
                let mut nparams: u32= LLVMCountParamTypes(ctor_ft);
                // Only call constructor when explicitly requested with parens
                let mut call_ctor: bool= d.has_ctor_parens;
                if (call_ctor) {
                    let mut nctorargs: i32= d.ctor_args_len + 1;
                    let mut cargs: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)nctorargs);
                    cargs[0] = alloca;
                    let mut param_ts: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)(nparams + 1));
                    if (nparams > 0) { LLVMGetParamTypes(ctor_ft, param_ts); }
                    let mut ci: i32= 0;
                    while (ci < d.ctor_args_len) {
                        let mut av: *i8= visit_expr((parser.expr_node*)d.ctor_args[ci], ctx);
                        let mut pi: i32= ci + 1;
                        if (av != (i8*)0 && (u32)pi < nparams) {
                            let mut pk: i32= LLVMGetTypeKind(param_ts[pi]);
                            let mut av_ty: *i8= LLVMTypeOf(av);
                            let mut av_k: i32= LLVMGetTypeKind(av_ty);
                            if (pk == LLVMStructTypeKind && ctx.memstr_fat_type != (i8*)0 &&
                                    param_ts[pi] == ctx.memstr_fat_type && av_k == LLVMStructTypeKind &&
                                    av_ty != ctx.memstr_fat_type) {
                                let mut sname: *i8= LLVMGetStructName(av_ty);
                                let mut vtbl: *i8= (sname != (i8*)0) ? sv_map_get(&ctx.memstr_vtables, sname) : (i8*)0;
                                // Reuse source pointer of a load to avoid value-copying the allocator.
                                let mut dp: *i8= (i8*)0;
                                if (LLVMGetInstructionOpcode(av) == 27) { dp = LLVMGetOperand(av, (u32)0); }
                                if (dp == (i8*)0) {
                                    let mut tmp: *i8= LLVMBuildAlloca(ctx.llvm_builder, av_ty, "ms_tmp");
                                    LLVMBuildStore(ctx.llvm_builder, av, tmp);
                                    dp = tmp;
                                }
                                let mut fat: *i8= LLVMGetUndef(ctx.memstr_fat_type);
                                fat = LLVMBuildInsertValue(ctx.llvm_builder, fat, dp, 0, "fat_d");
                                let mut ptr_t: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
                                let mut vp: *i8= (vtbl != (i8*)0) ? vtbl : LLVMConstPointerNull(ptr_t);
                                fat = LLVMBuildInsertValue(ctx.llvm_builder, fat, vp, 1, "fat_v");
                                av = fat;
                            } else if (pk == LLVMPointerTypeKind && av_k == LLVMStructTypeKind) {
                                let mut tmp: *i8= LLVMBuildAlloca(ctx.llvm_builder, av_ty, "ref_tmp");
                                LLVMBuildStore(ctx.llvm_builder, av, tmp);
                                av = tmp;
                            } else {
                                av = coerce_int_val(av, param_ts[pi], ctx.llvm_builder);
                            }
                        }
                        cargs[ci + 1] = av;
                        ci = ci + 1;
                    }
                    arc_free((i8*)param_ts);
                    LLVMBuildCall2(ctx.llvm_builder, ctor_ft, ctor_fn, cargs, nctorargs, "");
                    arc_free((i8*)cargs);
                }
            }
        }
    }
}

// ---- if/else ----

fn visit_if_stmt(s: *parser.if_stmt, ctx: *ir_context) void {
    // comptime if: evaluate condition at compile time, emit only the taken branch.
    if (s.is_constexpr && s.cond != (parser.expr_node*)0) {
        let mut cval: i64= 0;
        let mut ok: bool= constexpr_eval_expr(s.cond, ctx, &cval);
        if (!ok) {
            // Fall through to runtime path if we can't evaluate at compile time
        } else {
            if (cval != 0) {
                if (s.then_body != (parser.ast_node*)0) { visit_stmt(s.then_body, ctx); }
            } else {
                if (s.else_body != (parser.ast_node*)0) { visit_stmt(s.else_body, ctx); }
            }
            return;
        }
    }

    let mut cond_val: *i8= visit_expr(s.cond, ctx);
    let mut raw_cond_val: *i8= cond_val;
    if (cond_val == (i8*)0) { return; }

    // Normalize to i1
    let mut cond_t: *i8= LLVMTypeOf(cond_val);
    let mut ck: i32= LLVMGetTypeKind(cond_t);
    let mut need_norm: bool= false;
    if (ck == LLVMIntegerTypeKind) {
        if (LLVMGetIntTypeWidth(cond_t) != 1) { need_norm = true; }
    } else {
        need_norm = true;
    }
    if (need_norm) {
        cond_val = LLVMBuildICmp(ctx.llvm_builder, LLVMIntNE,
                                       cond_val, LLVMConstNull(cond_t), "if_cond");
    }

    let mut fn_ref: *i8= ctx.current_func;
    let mut then_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "if_then");
    let mut else_bb_ptr: *i8= (i8*)0;
    if (s.else_body != (parser.ast_node*)0) {
        else_bb_ptr = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "if_else");
    }
    let mut merge_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "if_merge");

    let mut false_dst: *i8= else_bb_ptr != (i8*)0 ? else_bb_ptr : merge_bb;
    LLVMBuildCondBr(ctx.llvm_builder, cond_val, then_bb, false_dst);

    // Then branch
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, then_bb);
    ctx_push_scope(ctx);
    if (s.then_capture != (i8*)0) {
        let mut raw_t: *i8= LLVMTypeOf(raw_cond_val);
        let mut cap: *i8= LLVMBuildAlloca(ctx.llvm_builder, raw_t, s.then_capture);
        LLVMBuildStore(ctx.llvm_builder, raw_cond_val, cap);
        ctx_declare_local(ctx, s.then_capture, cap, raw_t, (i8*)0, false);
    }
    visit_stmt(s.then_body, ctx);
    ctx_pop_scope(ctx);
    let mut then_terminated: bool= ctx_is_terminated(ctx);
    if (!then_terminated) {
        LLVMBuildBr(ctx.llvm_builder, merge_bb);
    }

    // Else branch (if present)
    let mut else_terminated: bool= false;
    if (else_bb_ptr != (i8*)0) {
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, else_bb_ptr);
        ctx_push_scope(ctx);
        if (s.else_capture != (i8*)0) {
            let mut raw_t: *i8= LLVMTypeOf(raw_cond_val);
            let mut cap: *i8= LLVMBuildAlloca(ctx.llvm_builder, raw_t, s.else_capture);
            LLVMBuildStore(ctx.llvm_builder, raw_cond_val, cap);
            ctx_declare_local(ctx, s.else_capture, cap, raw_t, (i8*)0, false);
        }
        visit_stmt(s.else_body, ctx);
        ctx_pop_scope(ctx);
        else_terminated = ctx_is_terminated(ctx);
        if (!else_terminated) {
            LLVMBuildBr(ctx.llvm_builder, merge_bb);
        }
    }

    LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb);
    // Both branches terminated → merge_bb has no predecessors; mark unreachable
    // so ctx_is_terminated() is true at the function end.
    // Only applies when an else branch exists; without one, the false path arrives here.
    if (then_terminated && else_bb_ptr != (i8*)0 && else_terminated) {
        LLVMBuildUnreachable(ctx.llvm_builder);
    }
}

// ---- while ----

fn visit_while_stmt(s: *parser.while_stmt, ctx: *ir_context) void {
    let mut fn_ref: *i8= ctx.current_func;
    let mut cond_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "while_cond");
    let mut body_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "while_body");
    let mut exit_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "while_exit");

    LLVMBuildBr(ctx.llvm_builder, cond_bb);

    LLVMPositionBuilderAtEnd(ctx.llvm_builder, cond_bb);
    let mut cond_val: *i8= visit_expr(s.cond, ctx);
    if (cond_val == (i8*)0) {
        LLVMBuildBr(ctx.llvm_builder, exit_bb);
    } else {
        let mut cond_t: *i8= LLVMTypeOf(cond_val);
        let mut cond_kind: i32= LLVMGetTypeKind(cond_t);
        let mut needs_norm_w: bool= false;
        if (cond_kind == LLVMIntegerTypeKind) {
            if (LLVMGetIntTypeWidth(cond_t) != 1) { needs_norm_w = true; }
        } else {
            needs_norm_w = true;
        }
        if (needs_norm_w) {
            cond_val = LLVMBuildICmp(ctx.llvm_builder, LLVMIntNE,
                                           cond_val, LLVMConstNull(cond_t), "while_cond");
        }
        LLVMBuildCondBr(ctx.llvm_builder, cond_val, body_bb, exit_bb);
    }

    LLVMPositionBuilderAtEnd(ctx.llvm_builder, body_bb);
    ctx_push_loop(ctx, exit_bb, cond_bb);
    visit_stmt(s.body, ctx);
    ctx_pop_loop(ctx);
    if (!ctx_is_terminated(ctx)) {
        LLVMBuildBr(ctx.llvm_builder, cond_bb);
    }

    LLVMPositionBuilderAtEnd(ctx.llvm_builder, exit_bb);
}

// ---- for ----

fn visit_for_stmt(s: *parser.for_stmt, ctx: *ir_context) void {
    ctx_push_scope(ctx);

    // Init
    if (s.init != (parser.ast_node*)0) {
        visit_stmt(s.init, ctx);
    }

    let mut fn_ref: *i8= ctx.current_func;
    let mut cond_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "for_cond");
    let mut body_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "for_body");
    let mut step_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "for_step");
    let mut exit_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "for_exit");

    LLVMBuildBr(ctx.llvm_builder, cond_bb);

    // Condition
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, cond_bb);
    if (s.cond != (parser.expr_node*)0) {
        let mut cond_val: *i8= visit_expr(s.cond, ctx);
        if (cond_val != (i8*)0) {
            let mut ct: *i8= LLVMTypeOf(cond_val);
            let mut ct_kind: i32= LLVMGetTypeKind(ct);
            let mut needs_norm_f: bool= false;
            if (ct_kind == LLVMIntegerTypeKind) {
                if (LLVMGetIntTypeWidth(ct) != 1) { needs_norm_f = true; }
            } else { needs_norm_f = true; }
            if (needs_norm_f) {
                cond_val = LLVMBuildICmp(ctx.llvm_builder, LLVMIntNE,
                                               cond_val, LLVMConstNull(ct), "for_cond");
            }
            LLVMBuildCondBr(ctx.llvm_builder, cond_val, body_bb, exit_bb);
        } else {
            LLVMBuildBr(ctx.llvm_builder, body_bb);
        }
    } else {
        LLVMBuildBr(ctx.llvm_builder, body_bb);
    }

    // Body
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, body_bb);
    ctx_push_loop(ctx, exit_bb, step_bb);
    visit_stmt(s.body, ctx);
    ctx_pop_loop(ctx);
    if (!ctx_is_terminated(ctx)) {
        LLVMBuildBr(ctx.llvm_builder, step_bb);
    }

    // Step
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, step_bb);
    if (s.step != (parser.expr_node*)0) {
        visit_expr(s.step, ctx);
    }
    LLVMBuildBr(ctx.llvm_builder, cond_bb);

    LLVMPositionBuilderAtEnd(ctx.llvm_builder, exit_bb);
    ctx_pop_scope(ctx);
}

// ---- for range ----

fn visit_for_range_stmt(s: *parser.for_range_stmt, ctx: *ir_context) void {
    let mut fn_ref: *i8= ctx.current_func;
    let mut cond_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "range_cond");
    let mut body_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "range_body");
    let mut step_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "range_step");
    let mut exit_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "range_exit");

    // Need the lvalue of the range container to call begin()/end() methods on it
    let mut range_lval: *i8= (i8*)0;
    if (s.range != (parser.expr_node*)0) {
        range_lval = visit_lvalue(s.range, ctx);
    }
    let mut range_val: *i8= (i8*)0;
    if (range_lval != (i8*)0) {
        range_val = range_lval; // treat as pointer to container
    } else if (s.range != (parser.expr_node*)0) {
        range_val = visit_expr(s.range, ctx);
    }

    let mut elem_llvm_t: *i8;
    if (s.var_type != (parser.type_node*)0) {
        elem_llvm_t = llvm_type_of(s.var_type, ctx);
    } else {
        elem_llvm_t = LLVMInt8TypeInContext(ctx.llvm_ctx);
    }

    let mut i64t: *i8= LLVMInt64TypeInContext(ctx.llvm_ctx);
    let mut ptr_t: *i8= LLVMPointerTypeInContext(ctx.llvm_ctx, 0);
    let mut count_val: *i8= (i8*)0;

    // ---- Integer range path: for (let x : lo..hi) or lo..=hi ----
    if (s.range != (parser.expr_node*)0 && s.range.kind == ek_range) {
        let mut lo_val: *i8= visit_expr(s.range.lhs, ctx);
        let mut hi_val: *i8= visit_expr(s.range.rhs, ctx);
        let mut inclusive: bool= s.range.bool_val;

        let mut iter_t: *i8= elem_llvm_t;
        lo_val = coerce_int_val(lo_val, iter_t, ctx.llvm_builder);
        hi_val = coerce_int_val(hi_val, iter_t, ctx.llvm_builder);

        let mut var_name: *i8= s.var_name;
        if (var_name == (i8*)0) { var_name = "i"; }
        let mut iter_alloca: *i8= LLVMBuildAlloca(ctx.llvm_builder, iter_t, var_name);
        LLVMBuildStore(ctx.llvm_builder, lo_val, iter_alloca);

        LLVMBuildBr(ctx.llvm_builder, cond_bb);

        // Condition: i < hi  (exclusive) or i <= hi (inclusive)
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, cond_bb);
        let mut iter_cur: *i8= LLVMBuildLoad2(ctx.llvm_builder, iter_t, iter_alloca, "iter");
        let mut cond_v: *i8;
        if (inclusive) {
            cond_v = LLVMBuildICmp(ctx.llvm_builder, LLVMIntSLE, iter_cur, hi_val, "range_le");
        } else {
            cond_v = LLVMBuildICmp(ctx.llvm_builder, LLVMIntSLT, iter_cur, hi_val, "range_lt");
        }
        LLVMBuildCondBr(ctx.llvm_builder, cond_v, body_bb, exit_bb);

        // Body
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, body_bb);
        ctx_push_scope(ctx);
        ctx_declare_local(ctx, var_name, iter_alloca, iter_t, (i8*)0, false);
        ctx_push_loop(ctx, exit_bb, step_bb);
        visit_stmt(s.body, ctx);
        ctx_pop_loop(ctx);
        if (!ctx_is_terminated(ctx)) { LLVMBuildBr(ctx.llvm_builder, step_bb); }
        ctx_pop_scope(ctx);

        // Step: i++
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, step_bb);
        let mut iter_step: *i8= LLVMBuildLoad2(ctx.llvm_builder, iter_t, iter_alloca, "iter_s");
        let mut one: *i8= LLVMConstInt(iter_t, 1u, 0);
        let mut iter_next: *i8= LLVMBuildAdd(ctx.llvm_builder, iter_step, one, "iter_inc");
        LLVMBuildStore(ctx.llvm_builder, iter_next, iter_alloca);
        LLVMBuildBr(ctx.llvm_builder, cond_bb);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, exit_bb);
        return;
    }

    // ---- Fixed-size C array path ----
    // for (T x : arr) where arr is declared as T arr[N]
    if (s.range != (parser.expr_node*)0 && s.range.kind == ek_identifier && range_lval != (i8*)0) {
        let mut arr_type: *i8= ctx_lookup_local_type(ctx, s.range.str_val);
        if (arr_type != (i8*)0 && LLVMGetTypeKind(arr_type) == LLVMArrayTypeKind) {
            let mut arr_len: u32= LLVMGetArrayLength(arr_type);
            count_val = LLVMConstInt(i64t, (u64)arr_len, false);
            let mut elem_t: *i8= LLVMGetElementType(arr_type);
            if (elem_t != (i8*)0 && s.var_type == (parser.type_node*)0) {
                elem_llvm_t = elem_t;
            }
            // Decay array alloca to pointer to first element via two-index GEP
            let mut zero32: *i8= LLVMConstInt(LLVMInt32TypeInContext(ctx.llvm_ctx), 0u, false);
            let mut gep_idx: [2]*i8;
            gep_idx[0] = zero32;
            gep_idx[1] = zero32;
            range_val = LLVMBuildGEP2(ctx.llvm_builder, arr_type, range_lval, gep_idx, 2, "arr_decay");
        }
    }

    // ---- begin()/end() iterator protocol ----
    // If the container type has begin() and end() methods, use pointer iteration.
    // The loop becomes: it = begin(); end_it = end(); while (it != end_it) { x = *it; ...; ++it; }
    let mut use_iter_begin: *i8= (i8*)0; // begin pointer
    let mut use_iter_end: *i8= (i8*)0; // end pointer

    if (s.range != (parser.expr_node*)0) {
        let mut struct_t: *i8= infer_expr_struct_type(s.range, ctx);
        if (struct_t != (i8*)0) {
            let mut sname: *i8= LLVMGetStructName(struct_t);
            if (sname != (i8*)0) {
                // Look for begin method: SNAME__MT_begin or SNAME__NS_begin
                let mut begin_name: [256]i8;
                let mut end_name: [256]i8;
                afmt(begin_name, (u64)256, "%s__MT_begin", .{ sname });
                afmt(end_name, (u64)256, "%s__MT_end", .{ sname });
                let mut begin_fn: *i8= sv_map_get(&ctx.global_funcs,      begin_name);
                let mut begin_fn_ty: *i8= st_map_get(&ctx.global_func_types, begin_name);
                let mut end_fn: *i8= sv_map_get(&ctx.global_funcs,      end_name);
                let mut end_fn_ty: *i8= st_map_get(&ctx.global_func_types, end_name);
                // Fallback: istruc/namespace methods use __NS_ prefix
                if (begin_fn == (i8*)0 || begin_fn_ty == (i8*)0) {
                    afmt(begin_name, (u64)256, "%s__NS_begin", .{ sname });
                    afmt(end_name, (u64)256, "%s__NS_end", .{ sname });
                    begin_fn    = sv_map_get(&ctx.global_funcs,      begin_name);
                    begin_fn_ty = st_map_get(&ctx.global_func_types, begin_name);
                    end_fn      = sv_map_get(&ctx.global_funcs,      end_name);
                    end_fn_ty   = st_map_get(&ctx.global_func_types, end_name);
                }
                if (begin_fn != (i8*)0 && begin_fn_ty != (i8*)0 &&
                        end_fn != (i8*)0 && end_fn_ty != (i8*)0) {
                    // Ensure we have a pointer to the container for self param
                    let mut self_ptr: *i8= range_lval;
                    if (self_ptr == (i8*)0 && range_val != (i8*)0) {
                        // Materialize on stack
                        let mut tmp: *i8= LLVMBuildAlloca(ctx.llvm_builder, struct_t, "rng_tmp");
                        LLVMBuildStore(ctx.llvm_builder, range_val, tmp);
                        self_ptr = tmp;
                    }
                    if (self_ptr != (i8*)0) {
                        use_iter_begin = LLVMBuildCall2(ctx.llvm_builder, begin_fn_ty, begin_fn, &self_ptr, 1, "rng_begin");
                        use_iter_end   = LLVMBuildCall2(ctx.llvm_builder, end_fn_ty,   end_fn,   &self_ptr, 1, "rng_end");
                        // Infer elem type from container's data/buf field pointee metadata.
                        // In LLVM opaque-ptr mode we cannot call LLVMGetElementType on the
                        // iterator pointer, so we consult struct_meta instead.
                        if (s.var_type == (parser.type_node*)0 && use_iter_begin != (i8*)0) {
                            let mut inferred_elem: *i8= (i8*)0;
                            let mut sm_it: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, sname);
                            if (sm_it != (struct_meta*)0) {
                                let mut fi2: i32= 0;
                                while (fi2 < sm_it.field_names.len && inferred_elem == (i8*)0) {
                                    let mut fn2: *i8= sm_it.field_names.data[fi2];
                                    if (fn2 != (i8*)0 && (
                                            strcmp(fn2, "data") == 0 || strcmp(fn2, "buf") == 0 ||
                                            strcmp(fn2, "ptr") == 0 || strcmp(fn2, "buffer") == 0)) {
                                        // field_pointee holds the element type for *T data fields
                                        if (fi2 < sm_it.field_pointee.len && sm_it.field_pointee.data[fi2] != (i8*)0) {
                                            let mut pt2: *i8= sm_it.field_pointee.data[fi2];
                                            if (LLVMGetTypeKind(pt2) != LLVMPointerTypeKind &&
                                                    LLVMGetTypeKind(pt2) != LLVMVoidTypeKind) {
                                                inferred_elem = pt2;
                                            }
                                        }
                                    }
                                    fi2 = fi2 + 1;
                                }
                            }
                            if (inferred_elem != (i8*)0) {
                                elem_llvm_t = inferred_elem;
                            } else {
                                // Byte-granular fallback: GEP advances are correct, but loads
                                // will need an explicit cast. Better than wrong i32 size.
                                elem_llvm_t = LLVMInt8TypeInContext(ctx.llvm_ctx);
                            }
                        }
                    }
                }

                if (use_iter_begin == (i8*)0) {
                    // Fall back to length/data field protocol
                    let mut sm: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, sname);
                    if (sm != (struct_meta*)0) {
                        let mut range_is_ptr: bool= (range_val != (i8*)0 && LLVMGetTypeKind(LLVMTypeOf(range_val)) == LLVMPointerTypeKind);
                        let mut li: i32= 0;
                        while (li < sm.field_names.len && count_val == (i8*)0) {
                            if (strcmp(sm.field_names.data[li], "length") == 0 || strcmp(sm.field_names.data[li], "size") == 0 || strcmp(sm.field_names.data[li], "len") == 0) {
                                let mut ft: *i8= (li < sm.field_types.len) ? sm.field_types.data[li] : i64t;
                                if (ft == (i8*)0) { ft = i64t; }
                                if (range_is_ptr) {
                                    let mut gep: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, struct_t, range_val, (u32)li, "len_ptr");
                                    count_val = LLVMBuildLoad2(ctx.llvm_builder, ft, gep, "range_len");
                                } else if (range_val != (i8*)0) {
                                    count_val = LLVMBuildExtractValue(ctx.llvm_builder, range_val, (u32)li, "range_len");
                                }
                            }
                            li = li + 1;
                        }
                        let mut pi: i32= 0;
                        while (pi < sm.field_types.len) {
                            let mut fpt: *i8= sm.field_types.data[pi];
                            if (fpt != (i8*)0 && LLVMGetTypeKind(fpt) == LLVMPointerTypeKind) {
                                if (range_is_ptr) {
                                    let mut gep2: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, struct_t, range_val, (u32)pi, "data_ptr");
                                    range_val = LLVMBuildLoad2(ctx.llvm_builder, fpt, gep2, "range_data");
                                } else if (range_val != (i8*)0) {
                                    range_val = LLVMBuildExtractValue(ctx.llvm_builder, range_val, (u32)pi, "range_data");
                                }
                                break;
                            }
                            pi = pi + 1;
                        }
                    }
                }
            }
        }
    }

    // ---- begin/end pointer iterator path ----
    if (use_iter_begin != (i8*)0 && use_iter_end != (i8*)0) {
        // Store begin and end into allocas so we can mutate them
        let mut it_alloca: *i8= LLVMBuildAlloca(ctx.llvm_builder, ptr_t, "rng_it");
        let mut end_alloca: *i8= LLVMBuildAlloca(ctx.llvm_builder, ptr_t, "rng_end");
        LLVMBuildStore(ctx.llvm_builder, use_iter_begin, it_alloca);
        LLVMBuildStore(ctx.llvm_builder, use_iter_end,   end_alloca);

        let mut var_name: *i8= s.var_name;
        if (var_name == (i8*)0) { var_name = "elem"; }
        let mut elem_alloca: *i8= LLVMBuildAlloca(ctx.llvm_builder, elem_llvm_t, var_name);

        LLVMBuildBr(ctx.llvm_builder, cond_bb);

        // Cond: it != end
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, cond_bb);
        let mut it_cur: *i8= LLVMBuildLoad2(ctx.llvm_builder, ptr_t, it_alloca,  "it");
        let mut end_cur: *i8= LLVMBuildLoad2(ctx.llvm_builder, ptr_t, end_alloca, "end");
        let mut cond_v: *i8= LLVMBuildICmp(ctx.llvm_builder, LLVMIntNE, it_cur, end_cur, "it_ne_end");
        LLVMBuildCondBr(ctx.llvm_builder, cond_v, body_bb, exit_bb);

        // Body: *it
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, body_bb);
        ctx_push_scope(ctx);
        let mut it_body: *i8= LLVMBuildLoad2(ctx.llvm_builder, ptr_t, it_alloca, "it_body");
        let mut elem_v: *i8= LLVMBuildLoad2(ctx.llvm_builder, elem_llvm_t, it_body, "elem_deref");
        LLVMBuildStore(ctx.llvm_builder, elem_v, elem_alloca);
        ctx_declare_local(ctx, var_name, elem_alloca, elem_llvm_t, (i8*)0, false);
        ctx_push_loop(ctx, exit_bb, step_bb);
        visit_stmt(s.body, ctx);
        ctx_pop_loop(ctx);
        if (!ctx_is_terminated(ctx)) { LLVMBuildBr(ctx.llvm_builder, step_bb); }
        ctx_pop_scope(ctx);

        // Step: ++it
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, step_bb);
        let mut it_step: *i8= LLVMBuildLoad2(ctx.llvm_builder, ptr_t, it_alloca, "it_step");
        let mut one: *i8= LLVMConstInt(LLVMInt64TypeInContext(ctx.llvm_ctx), 1u, 0);
        let mut it_next: *i8= LLVMBuildGEP2(ctx.llvm_builder, elem_llvm_t, it_step, &one, 1, "it_inc");
        LLVMBuildStore(ctx.llvm_builder, it_next, it_alloca);
        LLVMBuildBr(ctx.llvm_builder, cond_bb);

        LLVMPositionBuilderAtEnd(ctx.llvm_builder, exit_bb);
        return;
    }

    // ---- index/count path (fallback) ----
    if (count_val == (i8*)0) {
        count_val = LLVMConstInt(i64t, 0u, 0);
    }
    count_val = coerce_int_val(count_val, i64t, ctx.llvm_builder);

    let mut idx_alloca: *i8= LLVMBuildAlloca(ctx.llvm_builder, i64t, "range_idx");
    LLVMBuildStore(ctx.llvm_builder, LLVMConstInt(i64t, 0u, 0), idx_alloca);

    let mut var_name: *i8= s.var_name;
    if (var_name == (i8*)0) { var_name = "elem"; }
    let mut elem_alloca: *i8= LLVMBuildAlloca(ctx.llvm_builder, elem_llvm_t, var_name);

    LLVMBuildBr(ctx.llvm_builder, cond_bb);

    // Condition: idx < count
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, cond_bb);
    let mut idx_cur: *i8= LLVMBuildLoad2(ctx.llvm_builder, i64t, idx_alloca, "idx");
    let mut cond_v: *i8= LLVMBuildICmp(ctx.llvm_builder, LLVMIntULT, idx_cur, count_val, "range_lt");
    LLVMBuildCondBr(ctx.llvm_builder, cond_v, body_bb, exit_bb);

    // Body: load element and run body
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, body_bb);
    ctx_push_scope(ctx);
    if (range_val != (i8*)0) {
        let mut elem_ptr: *i8= LLVMBuildGEP2(ctx.llvm_builder, elem_llvm_t, range_val, &idx_cur, 1, "elem_ptr");
        let mut elem_val: *i8= LLVMBuildLoad2(ctx.llvm_builder, elem_llvm_t, elem_ptr, "elem");
        LLVMBuildStore(ctx.llvm_builder, elem_val, elem_alloca);
    }
    ctx_declare_local(ctx, var_name, elem_alloca, elem_llvm_t, (i8*)0, false);
    ctx_push_loop(ctx, exit_bb, step_bb);
    visit_stmt(s.body, ctx);
    ctx_pop_loop(ctx);
    if (!ctx_is_terminated(ctx)) { LLVMBuildBr(ctx.llvm_builder, step_bb); }
    ctx_pop_scope(ctx);

    // Step: idx++
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, step_bb);
    let mut idx_new: *i8= LLVMBuildAdd(ctx.llvm_builder, idx_cur, LLVMConstInt(i64t, 1u, 0), "idx_inc");
    LLVMBuildStore(ctx.llvm_builder, idx_new, idx_alloca);
    LLVMBuildBr(ctx.llvm_builder, cond_bb);

    LLVMPositionBuilderAtEnd(ctx.llvm_builder, exit_bb);
}

// ---- switch ----

fn visit_switch_stmt(s: *parser.switch_stmt, ctx: *ir_context) void {
    let mut val: *i8= visit_expr(s.val, ctx);
    if (val == (i8*)0) { return; }

    let mut fn_ref: *i8= ctx.current_func;
    let mut exit_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "sw_exit");
    let mut default_bb: *i8= exit_bb;

    // Build body blocks
    let mut body_bbs: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)s.cases_len);
    let mut i: i32= 0;
    while (i < s.cases_len) {
        body_bbs[i] = LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "sw_case");
        if (s.case_is_default[i]) { default_bb = body_bbs[i]; }
        i = i + 1;
    }

    // Collect case constants BEFORE building the switch to avoid emitting loads
    // after the switch terminator (which would produce invalid IR).
    let mut case_consts: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)s.cases_len);
    let mut j: i32= 0;
    while (j < s.cases_len) {
        case_consts[j] = (i8*)0;
        if (!s.case_is_default[j]) {
            let mut cv_expr: *parser.expr_node= (parser.expr_node*)s.case_vals[j];
            if (cv_expr != (parser.expr_node*)0) {
                let mut cv: *i8= (i8*)0;
                // For identifier case values, try to get the constant without emitting loads.
                if (cv_expr.kind == ek_identifier) {
                    let mut gv: *i8= sv_map_get(&ctx.global_vars, cv_expr.str_val);
                    if (gv != (i8*)0) {
                        let mut init: *i8= LLVMGetInitializer(gv);
                        if (init != (i8*)0 && LLVMIsConstant(init)) { cv = init; }
                    }
                }
                // Fall back to visiting the expression (integer literals are already constant).
                if (cv == (i8*)0) { cv = visit_expr(cv_expr, ctx); }
                if (cv != (i8*)0 && LLVMIsConstant(cv)) {
                    case_consts[j] = coerce_int_val(cv, LLVMTypeOf(val), ctx.llvm_builder);
                }
            }
        }
        j = j + 1;
    }

    let mut sw: *i8= LLVMBuildSwitch(ctx.llvm_builder, val, default_bb, s.cases_len);

    // Add case entries (constants were already collected above).
    j = 0;
    while (j < s.cases_len) {
        if (!s.case_is_default[j] && case_consts[j] != (i8*)0) {
            LLVMAddCase(sw, case_consts[j], body_bbs[j]);
        }
        j = j + 1;
    }
    arc_free((i8*)case_consts);

    // Emit case bodies
    ctx_push_loop(ctx, exit_bb, exit_bb);
    let mut all_cases_ret: bool= true;   // true only when every case terminates via ret/unreachable
    let mut has_default: bool= false;
    let mut k: i32= 0;
    while (k < s.cases_len) {
        if (s.case_is_default[k]) { has_default = true; }
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, body_bbs[k]);
        if (s.case_bodies[k] != (parser.block_stmt*)0) {
            visit_block_stmt(s.case_bodies[k], ctx);
        }
        if (!ctx_is_terminated(ctx)) {
            all_cases_ret = false;
            // Fall through to the next case (C semantics); branch to exit only for the last case.
            let mut fall_target: *i8= (k + 1 < s.cases_len) ? body_bbs[k + 1] : exit_bb;
            LLVMBuildBr(ctx.llvm_builder, fall_target);
        } else {
            // Check if terminator is a branch (break) vs ret — break goes to exit_bb
            let mut bb_now: *i8= LLVMGetInsertBlock(ctx.llvm_builder);
            if (bb_now != (i8*)0) {
                let mut term: *i8= LLVMGetBasicBlockTerminator(bb_now);
                if (term != (i8*)0 && LLVMGetInstructionOpcode(term) != 1) {
                    // Not a ret (opcode 1) — must be br/break, so exit_bb is reachable
                    all_cases_ret = false;
                }
            }
        }
        k = k + 1;
    }
    ctx_pop_loop(ctx);

    arc_free((i8*)body_bbs);
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, exit_bb);
    // All cases (incl. default) returned → exit_bb has no predecessors; mark unreachable.
    if (all_cases_ret && has_default) {
        LLVMBuildUnreachable(ctx.llvm_builder);
    }
}

// ---- return ----

fn visit_return_stmt(s: *parser.return_stmt, ctx: *ir_context) void {
    let mut i32t: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);

    // Evaluate return value before emitting defers (may reference stack vars).
    let mut val: *i8= (i8*)0;
    if (s.has_val) {
        val = visit_expr(s.val, ctx);

        // For !T functions: if we got back a value that is already a struct (from ek_error_lit),
        // keep it as-is. Otherwise wrap the T value as { i32 0, T val }.
        if (ctx.current_func_eu_is_value && val != (i8*)0) {
            let mut vt: *i8= LLVMTypeOf(val);
            if (LLVMGetTypeKind(vt) == LLVMStructTypeKind) {
                // Already a { i32, T } struct (e.g. from error.X) — pass through
            } else {
                // Regular T value — wrap as success: { 0, val }
                let mut eu_ok: *i8= LLVMGetUndef(ctx.current_ret_type);
                eu_ok = LLVMBuildInsertValue(ctx.llvm_builder, eu_ok, LLVMConstInt(i32t, 0, 0), 0, "eu_ok");
                // Coerce val to the expected value type if needed
                let mut coerced_v: *i8= coerce_int_val(val, ctx.current_eu_value_type, ctx.llvm_builder);
                eu_ok = LLVMBuildInsertValue(ctx.llvm_builder, eu_ok, coerced_v, 1, "eu_val");
                val = eu_ok;
            }
        } else if (val != (i8*)0 && ctx.current_ret_type != (i8*)0 && !ctx.current_func_eu_is_value) {
            let mut ret_t: *i8= ctx.current_ret_type;
            let mut ret_k: i32= LLVMGetTypeKind(ret_t);
            let mut val_t: *i8= LLVMTypeOf(val);
            let mut val_k: i32= LLVMGetTypeKind(val_t);
            if (ret_k == LLVMStructTypeKind && val_k == LLVMPointerTypeKind) {
                val = LLVMBuildLoad2(ctx.llvm_builder, ret_t, val, "sret_load");
            } else {
                val = coerce_int_val(val, ret_t, ctx.llvm_builder);
            }
        }
    }

    // Emit all pending defers (innermost to outermost) before ret.
    let mut di: i32= ctx.defers.len - 1;
    while (di >= 0) {
        emit_deferred(&ctx.defers.data[di], ctx);
        di = di - 1;
    }

    // Emit errdefers if returning an error.
    let mut has_errdefer: bool= false;
    let mut ei_chk: i32= ctx.errdefers.len - 1;
    while (ei_chk >= 0) {
        if (ctx.errdefers.data[ei_chk].len > 0) { has_errdefer = true; }
        ei_chk = ei_chk - 1;
    }
    if (s.has_val && val != (i8*)0 && has_errdefer) {
        let mut val_t: *i8= LLVMTypeOf(val);
        let mut val_kind: i32= LLVMGetTypeKind(val_t);
        if (ctx.current_func_eu_is_value && val_kind == LLVMStructTypeKind) {
            // !T ABI: extract is_err flag from { i32, T }
            let mut is_err_flag: *i8= LLVMBuildExtractValue(ctx.llvm_builder, val, 0, "is_err_flag");
            let mut zero_ed: *i8= LLVMConstInt(i32t, 0, 0);
            let mut is_err_val: *i8= LLVMBuildICmp(ctx.llvm_builder, LLVMIntNE, is_err_flag, zero_ed, "is_err_ret");
            let mut fn_r: *i8= ctx.current_func;
            let mut err_bb_r: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_r, "err_exit");
            let mut ok_bb_r: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_r, "ok_exit");
            LLVMBuildCondBr(ctx.llvm_builder, is_err_val, err_bb_r, ok_bb_r);
            // Error exit: emit errdefers
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, err_bb_r);
            let mut ei: i32= ctx.errdefers.len - 1;
            while (ei >= 0) {
                emit_deferred(&ctx.errdefers.data[ei], ctx);
                ei = ei - 1;
            }
            LLVMBuildRet(ctx.llvm_builder, val);
            // OK exit: no errdefers
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, ok_bb_r);
            LLVMBuildRet(ctx.llvm_builder, val);
            return;
        } else if (val_kind == LLVMIntegerTypeKind) {
            // !void ABI: check for -1
            let mut coerced_ret: *i8= coerce_int_val(val, i32t, ctx.llvm_builder);
            let mut minus_one_e: i64= (i64)-1;
            let mut neg1_e: *i8= LLVMConstInt(i32t, (u64)minus_one_e, 1);
            let mut is_err_val: *i8= LLVMBuildICmp(ctx.llvm_builder, LLVMIntEQ, coerced_ret, neg1_e, "is_err_ret");
            let mut fn_r: *i8= ctx.current_func;
            let mut err_bb_r: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_r, "err_exit");
            let mut ok_bb_r: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_r, "ok_exit");
            LLVMBuildCondBr(ctx.llvm_builder, is_err_val, err_bb_r, ok_bb_r);
            // Error exit: emit errdefers
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, err_bb_r);
            let mut ei: i32= ctx.errdefers.len - 1;
            while (ei >= 0) {
                emit_deferred(&ctx.errdefers.data[ei], ctx);
                ei = ei - 1;
            }
            LLVMBuildRet(ctx.llvm_builder, val);
            // OK exit: no errdefers
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, ok_bb_r);
            LLVMBuildRet(ctx.llvm_builder, val);
            return;
        }
    }

    if (s.has_val) {
        if (val != (i8*)0) {
            LLVMBuildRet(ctx.llvm_builder, val);
        } else if (ctx.current_ret_type != (i8*)0) {
            LLVMBuildRet(ctx.llvm_builder, LLVMGetUndef(ctx.current_ret_type));
        } else {
            LLVMBuildRetVoid(ctx.llvm_builder);
        }
    } else {
        // Bare 'return;' in an error-union function means success
        if (ctx.current_func_eu_is_value) {
            // !T success: { 0, undef }
            let mut eu_bare: *i8= LLVMGetUndef(ctx.current_ret_type);
            eu_bare = LLVMBuildInsertValue(ctx.llvm_builder, eu_bare, LLVMConstInt(i32t, 0, 0), 0, "eu_ok_bare");
            eu_bare = LLVMBuildInsertValue(ctx.llvm_builder, eu_bare, LLVMGetUndef(ctx.current_eu_value_type), 1, "eu_val_bare");
            LLVMBuildRet(ctx.llvm_builder, eu_bare);
        } else if (ctx.current_func_is_error_union && ctx.current_ret_type != (i8*)0 &&
                LLVMGetTypeKind(ctx.current_ret_type) == LLVMIntegerTypeKind) {
            // !void success: 0
            LLVMBuildRet(ctx.llvm_builder, LLVMConstInt(ctx.current_ret_type, 0, 0));
        } else {
            // Bare 'return;' — error if the enclosing function's return type is non-void.
            if (ctx.current_ret_type != (i8*)0 &&
                    LLVMGetTypeKind(ctx.current_ret_type) != LLVMVoidTypeKind) {
                aprint("error at line %llu: 'return' with no value in non-void function\n", .{ s.line });
                ctx.had_error = true;
            }
            LLVMBuildRetVoid(ctx.llvm_builder);
        }
    }
}

// ---- defer ----

fn visit_defer_stmt_impl(s: *parser.defer_stmt, ctx: *ir_context) void {
    let mut is_err: bool= (s.kind == nd_errdefer_stmt);
    if (s.is_block) {
        if (is_err) { ctx_add_errdefer(ctx, s.blk, true); }
        else        { ctx_add_defer(ctx, s.blk, true); }
    } else if (s.expr != (parser.expr_node*)0) {
        if (is_err) { ctx_add_errdefer(ctx, (i8*)s.expr, false); }
        else        { ctx_add_defer(ctx, (i8*)s.expr, false); }
    }
}

// ---- Match statement ----

// Emit an i1 value representing whether `subj_val` matches `pat`.
// Binding patterns (pk_binding, pk_ident used as binding) alloca + store into the current scope.
fn emit_pat_match(pat: *parser.pat_node, subj_val: *i8, subj_type: *i8, ctx: *ir_context) *i8 {
    let mut i1_t: *i8= LLVMInt1TypeInContext(ctx.llvm_ctx);
    let mut true1: *i8= LLVMConstInt(i1_t, 1u, 0);
    let mut false1: *i8= LLVMConstInt(i1_t, 0u, 0);
    if (pat == (parser.pat_node*)0) { return true1; }
    let mut kind: i32= pat.kind;

    // pk_wildcard, pk_rest → always match
    if (kind == pk_wildcard || kind == pk_rest) { return true1; }

    // pk_literal → subject == literal
    if (kind == pk_literal) {
        let mut le: *parser.expr_node= (parser.expr_node*)pat.lit_expr;
        if (le == (parser.expr_node*)0) { return true1; }
        let mut lv: *i8= visit_expr(le, ctx);
        if (lv == (i8*)0) { return true1; }
        let mut sv2: *i8= coerce_int_val(subj_val, LLVMTypeOf(lv), ctx.llvm_builder);
        return LLVMBuildICmp(ctx.llvm_builder, LLVMIntEQ, sv2, lv, "match_lit");
    }

    // pk_neg → subject == neg_expr (neg_expr is already a ek_unary/uop_neg expression)
    if (kind == pk_neg) {
        let mut ne: *parser.expr_node= (parser.expr_node*)pat.neg_expr;
        if (ne == (parser.expr_node*)0) { return true1; }
        let mut nv: *i8= visit_expr(ne, ctx);
        if (nv == (i8*)0) { return true1; }
        let mut sv3: *i8= coerce_int_val(subj_val, LLVMTypeOf(nv), ctx.llvm_builder);
        return LLVMBuildICmp(ctx.llvm_builder, LLVMIntEQ, sv3, nv, "match_neg");
    }

    // pk_range: lo <= subject AND (subject < hi OR subject <= hi)
    // range_lo and range_hi are always expr_node* (stored as i8*)
    if (kind == pk_range) {
        let mut lo_v: *i8= (pat.range_lo != (i8*)0) ? visit_expr((parser.expr_node*)pat.range_lo, ctx) : (i8*)0;
        let mut hi_v: *i8= (pat.range_hi != (i8*)0) ? visit_expr((parser.expr_node*)pat.range_hi, ctx) : (i8*)0;
        if (lo_v == (i8*)0 && hi_v == (i8*)0) { return true1; }
        let mut sv4: *i8= subj_val;
        if (lo_v != (i8*)0) { sv4 = coerce_int_val(sv4, LLVMTypeOf(lo_v), ctx.llvm_builder); }
        else { sv4 = coerce_int_val(sv4, LLVMTypeOf(hi_v), ctx.llvm_builder); }
        let mut lo_ok: *i8= true1;
        if (lo_v != (i8*)0) {
            lo_ok = LLVMBuildICmp(ctx.llvm_builder, LLVMIntSLE, coerce_int_val(lo_v, LLVMTypeOf(sv4), ctx.llvm_builder), sv4, "rng_lo");
        }
        let mut hi_ok: *i8= true1;
        if (hi_v != (i8*)0) {
            let mut hi_op: i32= pat.range_inclusive ? LLVMIntSLE : LLVMIntSLT;
            hi_ok = LLVMBuildICmp(ctx.llvm_builder, hi_op, sv4, coerce_int_val(hi_v, LLVMTypeOf(sv4), ctx.llvm_builder), "rng_hi");
        }
        return LLVMBuildAnd(ctx.llvm_builder, lo_ok, hi_ok, "rng_match");
    }

    // pk_binding: evaluate sub_pat against subject; if match, bind name
    if (kind == pk_binding) {
        let mut sub5: *parser.pat_node= (parser.pat_node*)pat.sub_pat;
        let mut sub_ok: *i8= emit_pat_match(sub5, subj_val, subj_type, ctx);
        // Alloca the binding variable and store subject (binding always happens on match)
        if (pat.name != (i8*)0 && subj_type != (i8*)0) {
            let mut bind_al: *i8= LLVMBuildAlloca(ctx.llvm_builder, subj_type, pat.name);
            LLVMBuildStore(ctx.llvm_builder, subj_val, bind_al);
            ctx_declare_local(ctx, pat.name, bind_al, subj_type, (i8*)0, false);
        }
        return sub_ok;
    }

    // pk_or: lhs OR rhs
    if (kind == pk_or) {
        let mut lhs6: *parser.pat_node= (parser.pat_node*)pat.or_lhs;
        let mut rhs6: *parser.pat_node= (parser.pat_node*)pat.or_rhs;
        let mut lv6: *i8= emit_pat_match(lhs6, subj_val, subj_type, ctx);
        let mut rv6: *i8= emit_pat_match(rhs6, subj_val, subj_type, ctx);
        return LLVMBuildOr(ctx.llvm_builder, lv6, rv6, "or_match");
    }

    // pk_ident: try to match as enum variant constant; fallback to binding
    if (kind == pk_ident) {
        if (pat.name != (i8*)0) {
            let mut gv7: *i8= sv_map_get(&ctx.global_vars, pat.name);
            if (gv7 != (i8*)0) {
                // It's an enum variant — compare
                let mut gval: *i8= LLVMBuildLoad2(ctx.llvm_builder, LLVMInt32TypeInContext(ctx.llvm_ctx), gv7, "enum_val");
                let mut sv7: *i8= coerce_int_val(subj_val, LLVMTypeOf(gval), ctx.llvm_builder);
                return LLVMBuildICmp(ctx.llvm_builder, LLVMIntEQ, sv7, gval, "match_enum");
            }
            // Not a global constant: treat as a binding (wildcard + store)
            if (subj_type != (i8*)0) {
                let mut bind_al7: *i8= LLVMBuildAlloca(ctx.llvm_builder, subj_type, pat.name);
                LLVMBuildStore(ctx.llvm_builder, subj_val, bind_al7);
                ctx_declare_local(ctx, pat.name, bind_al7, subj_type, (i8*)0, false);
            }
        }
        return true1;
    }

    // pk_struct: match struct fields by name
    if (kind == pk_struct) {
        let mut tkind_s: i32= LLVMGetTypeKind(subj_type);
        let mut sname: *i8= (tkind_s == LLVMStructTypeKind) ? LLVMGetStructName(subj_type) : (i8*)0;
        let mut result: *i8= true1;
        let mut fi: i32= 0;
        while (fi < pat.fields_len) {
            let mut pf: *parser.pat_field= &pat.fields[fi];
            if (pf.name != (i8*)0 && sname != (i8*)0) {
                let mut fidx: i32= ctx_field_index(ctx, sname, pf.name);
                if (fidx >= 0) {
                    let mut fval: *i8= LLVMBuildExtractValue(ctx.llvm_builder, subj_val, (u32)fidx, "sf_ext");
                    let mut ftype: *i8= ctx_field_type(ctx, sname, fidx);
                    if (ftype == (i8*)0) { ftype = LLVMTypeOf(fval); }
                    let mut sub_pat: *parser.pat_node= (parser.pat_node*)pf.pat;
                    if (sub_pat != (parser.pat_node*)0) {
                        let mut sub_r: *i8= emit_pat_match(sub_pat, fval, ftype, ctx);
                        result = LLVMBuildAnd(ctx.llvm_builder, result, sub_r, "sf_and");
                    } else {
                        let mut bind_a: *i8= LLVMBuildAlloca(ctx.llvm_builder, ftype, pf.name);
                        LLVMBuildStore(ctx.llvm_builder, fval, bind_a);
                        ctx_declare_local(ctx, pf.name, bind_a, ftype, (i8*)0, false);
                    }
                }
            }
            fi = fi + 1;
        }
        return result;
    }

    // pk_tuple: ADT enum variant — check __tag, extract __payload fields
    if (kind == pk_tuple) {
        if (pat.name == (i8*)0 || subj_type == (i8*)0) { return true1; }
        let mut sname2: *i8= (LLVMGetTypeKind(subj_type) == LLVMStructTypeKind) ?
            LLVMGetStructName(subj_type) : (i8*)0;
        if (sname2 == (i8*)0) { return true1; }
        let mut tag_idx: i32= ctx_field_index(ctx, sname2, "__tag");
        if (tag_idx < 0) { return true1; }
        let mut tag_val: *i8= LLVMBuildExtractValue(ctx.llvm_builder, subj_val, (u32)tag_idx, "__tag_x");
        let mut vname_buf: [512]i8;
        afmt(vname_buf, 512u, "%s__%s", .{ sname2, pat.name });
        let mut vgv: *i8= sv_map_get(&ctx.global_vars, vname_buf);
        if (vgv == (i8*)0) { vgv = sv_map_get(&ctx.global_vars, pat.name); }
        if (vgv == (i8*)0) { return true1; }
        let mut i32_t: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
        let mut vtag: *i8= LLVMBuildLoad2(ctx.llvm_builder, i32_t, vgv, "vtag");
        let mut tag_match: *i8= LLVMBuildICmp(ctx.llvm_builder, LLVMIntEQ, tag_val, vtag, "tag_cmp");
        if (pat.fields_len == 0) { return tag_match; }
        // Store the full ADT value to an alloca so we can GEP into the payload bytes.
        // The payload byte offsets use 8-byte-aligned field packing (same as the constructor).
        let mut enum_alloca: *i8= LLVMBuildAlloca(ctx.llvm_builder, subj_type, "enum_tmp");
        LLVMBuildStore(ctx.llvm_builder, subj_val, enum_alloca);
        // GEP to payload (field 1 of the enum struct)
        let mut pay_ptr3: *i8= LLVMBuildStructGEP2(ctx.llvm_builder, subj_type, enum_alloca, 1, "pay_p3");
        let mut i8t3: *i8= LLVMInt8TypeInContext(ctx.llvm_ctx);
        let mut i64t3: *i8= LLVMInt64TypeInContext(ctx.llvm_ctx);
        // Look up variant field metadata to get field types and compute byte offsets.
        let mut vsmeta: *struct_meta= struct_meta_find(&ctx.struct_meta_tbl, vname_buf);
        if (vsmeta == (struct_meta*)0) { vsmeta = struct_meta_find(&ctx.struct_meta_tbl, pat.name); }
        let mut field_result: *i8= tag_match;
        let mut byte_off3: u64= 0;
        let mut fi3: i32= 0;
        while (fi3 < pat.fields_len) {
            let mut pf3: *parser.pat_field= &pat.fields[fi3];
            // Get the LLVM type for this field
            let mut vft: *i8= (vsmeta != (struct_meta*)0 && fi3 < vsmeta.field_types.len)
                ? vsmeta.field_types.data[fi3] : (i8*)0;
            if (vft == (i8*)0) { vft = ctx_field_type(ctx, vname_buf, fi3); }
            if (vft == (i8*)0) { vft = ctx_field_type(ctx, pat.name, fi3); }
            if (vft != (i8*)0) {
                // GEP into payload at byte_off3, load as vft
                let mut off_v3: *i8= LLVMConstInt(i64t3, byte_off3, 0);
                let mut fptr3: *i8= LLVMBuildGEP2(ctx.llvm_builder, i8t3, pay_ptr3, &off_v3, 1, "fptr3");
                let mut vfval: *i8= LLVMBuildLoad2(ctx.llvm_builder, vft, fptr3, "vf_x3");
                // Advance byte offset by field size aligned to 8
                let mut fsz3: u64= llvm_type_byte_size(vft);
                byte_off3 = byte_off3 + ((fsz3 + 7) & ~(u64)7);
                // A function-pointer payload needs its callee signature recorded, or
                // the binding cannot be called: in opaque-pointer mode the alloca's
                // type is just `ptr`, so the call site has no type to hand
                // LLVMBuildCall2 and emits a null operand. Resolve against *this*
                // variant rather than the first tuple variant, so multi-variant enums
                // pick up the right payload type.
                let mut fnty3: *i8= (i8*)0;
                let mut adt_ed_fp: *i8= sv_map_get(&ctx.adt_enum_decls, sname2);
                if (adt_ed_fp != (i8*)0) {
                    let mut ed_fp: *parser.enum_decl= (parser.enum_decl*)adt_ed_fp;
                    // pat.name arrives enum-qualified ("Op__Apply") while variant_names
                    // holds the bare variant ("Apply") — compare against both spellings.
                    let mut vshort: *i8= pat.name;
                    let mut sn_len: i32= (i32)strlen(sname2);
                    if (strncmp(pat.name, sname2, (u64)sn_len) == 0 &&
                        pat.name[sn_len] == '_' && pat.name[sn_len + 1] == '_') {
                        vshort = pat.name + sn_len + 2;
                    }
                    let mut vidx_fp: i32= -1;
                    let mut vsi: i32= 0;
                    while (vsi < ed_fp.variants_len && vidx_fp < 0) {
                        let mut vn_fp: *i8= (ed_fp.variant_names != (i8**)0) ? ed_fp.variant_names[vsi] : (i8*)0;
                        if (vn_fp != (i8*)0 && (strcmp(vn_fp, vshort) == 0 || strcmp(vn_fp, pat.name) == 0)) {
                            vidx_fp = vsi;
                        }
                        vsi = vsi + 1;
                    }
                    if (vidx_fp >= 0 && ed_fp.variant_field_type_flat != (i8**)0) {
                        let mut ftn_fp: *parser.type_node=
                            (parser.type_node*)ed_fp.variant_field_type_flat[vidx_fp * 8 + fi3];
                        if (ftn_fp != (parser.type_node*)0 && ftn_fp.is_func_ptr) {
                            let mut cand: *i8= llvm_func_type_of(ftn_fp, ctx);
                            if (cand != (i8*)0 && LLVMGetTypeKind(cand) == LLVMFunctionTypeKind) {
                                fnty3 = cand;
                            }
                        }
                    }
                }

                // Pointee type for a pointer payload field. Without it a binding like
                // `Struct(_, flds, ..)` is only `ptr`, so `flds[i].offset` has no struct
                // to index: codegen falls back to a byte GEP and a constant 0, and the
                // read silently yields zero instead of the field.
                let mut vptee3: *i8= (vsmeta != (struct_meta*)0 && fi3 < vsmeta.field_pointee.len)
                    ? vsmeta.field_pointee.data[fi3] : (i8*)0;

                let mut sub_pat3: *parser.pat_node= (parser.pat_node*)pf3.pat;
                if (sub_pat3 != (parser.pat_node*)0) {
                    let mut sub_r3: *i8= emit_pat_match(sub_pat3, vfval, vft, ctx);
                    field_result = LLVMBuildAnd(ctx.llvm_builder, field_result, sub_r3, "vf_and");
                    // `Variant(name)` parses the binding as a pk_ident sub-pattern with
                    // no field name, so attach the signature to that name here.
                    if (sub_pat3.kind == pk_ident && sub_pat3.name != (i8*)0) {
                        if (fnty3 != (i8*)0) {
                            ctx_declare_local_func_type(ctx, sub_pat3.name, fnty3);
                            ctx_declare_local_func_depth(ctx, sub_pat3.name, 1);
                        }
                        ctx_set_local_deref_type(ctx, sub_pat3.name, vptee3);
                    }
                } else if (pf3.name != (i8*)0) {
                    let mut bind_a3: *i8= LLVMBuildAlloca(ctx.llvm_builder, vft, pf3.name);
                    LLVMBuildStore(ctx.llvm_builder, vfval, bind_a3);
                    ctx_declare_local(ctx, pf3.name, bind_a3, vft, vptee3, false);
                    if (fnty3 != (i8*)0) {
                        ctx_declare_local_func_type(ctx, pf3.name, fnty3);
                        ctx_declare_local_func_depth(ctx, pf3.name, 1);
                    }
                }
            } else {
                // Unknown field type: skip but still advance by 8 bytes to maintain alignment
                byte_off3 = byte_off3 + 8;
            }
            fi3 = fi3 + 1;
        }
        return field_result;
    }

    return true1;
}

fn visit_match_stmt(ms: *parser.match_stmt, ctx: *ir_context) void {
    let mut fn_ref: *i8= ctx.current_func;
    if (fn_ref == (i8*)0) { return; }

    // Evaluate subject
    let mut subj_expr: *parser.expr_node= (parser.expr_node*)ms.subject;
    let mut subj_val: *i8= (subj_expr != (parser.expr_node*)0) ? visit_expr(subj_expr, ctx) : (i8*)0;
    let mut subj_type: *i8= (subj_val != (i8*)0) ? LLVMTypeOf(subj_val) : LLVMInt32TypeInContext(ctx.llvm_ctx);

    // Create merge block
    let mut merge_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "match_merge");
    // Track whether any arm BODY fell through to merge (not including "no match" paths)
    let mut any_body_fell_through: bool= false;

    let mut i: i32= 0;
    while (i < ms.arms_len) {
        let mut arm: *parser.match_arm= ms.arms[i];
        if (arm == (parser.match_arm*)0) { i = i + 1; continue; }

        // Blocks: check (current BB), body, next
        let mut arm_body_bb: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "arm_body");
        let mut arm_next_bb: *i8= (i + 1 < ms.arms_len) ?
            LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_ref, "arm_next") :
            merge_bb;

        // Evaluate pattern (may alloca bindings)
        ctx_push_scope(ctx);
        let mut match_cond: *i8= (subj_val != (i8*)0) ?
            emit_pat_match(arm.pat, subj_val, subj_type, ctx) :
            LLVMConstInt(LLVMInt1TypeInContext(ctx.llvm_ctx), 1u, 0);

        // Evaluate guard if present
        if (arm.guard != (i8*)0) {
            let mut guard_val: *i8= visit_expr((parser.expr_node*)arm.guard, ctx);
            if (guard_val != (i8*)0) {
                let mut gv_i1: *i8= coerce_int_val(guard_val, LLVMInt1TypeInContext(ctx.llvm_ctx), ctx.llvm_builder);
                match_cond = LLVMBuildAnd(ctx.llvm_builder, match_cond, gv_i1, "guarded");
            }
        }

        LLVMBuildCondBr(ctx.llvm_builder, match_cond, arm_body_bb, arm_next_bb);

        // Body block
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, arm_body_bb);
        // In match-expr mode with a bare expression arm, store result to slot
        if (ctx.match_result_slot != (i8*)0 && arm.body != (parser.ast_node*)0 && arm.body.kind == nd_expr_stmt) {
            let mut arm_es2: *parser.expr_stmt= (parser.expr_stmt*)arm.body;
            if (arm_es2.expr != (parser.expr_node*)0) {
                let mut arm_val: *i8= visit_expr(arm_es2.expr, ctx);
                if (arm_val != (i8*)0 && ctx.match_result_slot != (i8*)0) {
                    // Coerce to the slot's own allocated type. Coercing to the arm
                    // value's type would be a no-op and lets a mismatched arm store
                    // the wrong type into the slot. Only integers are convertible
                    // here; pointer/float/struct arms must already match the slot.
                    let mut slot_t: *i8= ctx.match_result_type;
                    let mut sv_val: *i8= arm_val;
                    if (slot_t != (i8*)0 && LLVMTypeOf(arm_val) != slot_t) {
                        if (LLVMGetTypeKind(slot_t) == LLVMIntegerTypeKind &&
                            LLVMGetTypeKind(LLVMTypeOf(arm_val)) == LLVMIntegerTypeKind) {
                            sv_val = coerce_int_val(arm_val, slot_t, ctx.llvm_builder);
                        }
                    }
                    LLVMBuildStore(ctx.llvm_builder, sv_val, ctx.match_result_slot);
                }
            }
        } else {
            visit_stmt(arm.body, ctx);
        }
        if (!ctx_is_terminated(ctx)) {
            LLVMBuildBr(ctx.llvm_builder, merge_bb);
            any_body_fell_through = true;
        }
        ctx_pop_scope(ctx);

        // Position at next arm's check block
        if (arm_next_bb != merge_bb) {
            LLVMPositionBuilderAtEnd(ctx.llvm_builder, arm_next_bb);
        }
        i = i + 1;
    }

    // Position at merge block
    LLVMPositionBuilderAtEnd(ctx.llvm_builder, merge_bb);
    // If no arm body fell through to merge, the merge block is unreachable.
    // Mark it so the caller's "may not return" check sees a terminator.
    if (!any_body_fell_through) {
        LLVMBuildUnreachable(ctx.llvm_builder);
    }
}

// ---- Main statement dispatcher ----

fn visit_stmt(node: *parser.ast_node, ctx: *ir_context) void {
    if (node == (parser.ast_node*)0) { return; }
    let mut kind: i32= node.kind;

    if (kind == nd_block) {
        visit_block_stmt((parser.block_stmt*)node, ctx);
        return;
    }
    if (kind == nd_expr_stmt) {
        let mut es: *parser.expr_stmt= (parser.expr_stmt*)node;
        // Macro expansion may produce a nd_var_decl embedded as the expr
        if (es.expr != (parser.expr_node*)0 && es.expr.kind == nd_var_decl) {
            visit_local_var_decl((parser.var_decl*)es.expr, ctx);
        } else {
            visit_expr(es.expr, ctx);
        }
        return;
    }
    if (kind == nd_var_decl) {
        visit_local_var_decl((parser.var_decl*)node, ctx);
        return;
    }
    if (kind == nd_return_stmt) {
        visit_return_stmt((parser.return_stmt*)node, ctx);
        return;
    }
    if (kind == nd_break_stmt) {
        let mut bb: *i8= ctx_current_break(ctx);
        if (bb != (i8*)0) {
            LLVMBuildBr(ctx.llvm_builder, bb);
        }
        return;
    }
    if (kind == nd_continue_stmt) {
        let mut bb: *i8= ctx_current_continue(ctx);
        if (bb != (i8*)0) {
            LLVMBuildBr(ctx.llvm_builder, bb);
        }
        return;
    }
    if (kind == nd_if_stmt) {
        visit_if_stmt((parser.if_stmt*)node, ctx);
        return;
    }
    if (kind == nd_while_stmt) {
        visit_while_stmt((parser.while_stmt*)node, ctx);
        return;
    }
    if (kind == nd_for_stmt) {
        visit_for_stmt((parser.for_stmt*)node, ctx);
        return;
    }
    if (kind == nd_for_range_stmt) {
        visit_for_range_stmt((parser.for_range_stmt*)node, ctx);
        return;
    }
    if (kind == nd_switch_stmt) {
        visit_switch_stmt((parser.switch_stmt*)node, ctx);
        return;
    }
    if (kind == nd_match_stmt) {
        visit_match_stmt((parser.match_stmt*)node, ctx);
        return;
    }
    if (kind == nd_defer_stmt || kind == nd_errdefer_stmt) {
        visit_defer_stmt_impl((parser.defer_stmt*)node, ctx);
        return;
    }
    if (kind == nd_asm_stmt) {
        let mut as: *parser.asm_stmt= (parser.asm_stmt*)node;
        let mut raw: *i8= as.raw_instructions;
        if (raw == (i8*)0) { return; }
        let mut raw_len: i64= (i64)strlen(raw);

        // Allocate flat buffers for each part (instructions, sec1, sec2, sec3)
        let mut part0: *i8= (i8*)arc_malloc((u64)1536);
        let mut part1: *i8= (i8*)arc_malloc((u64)512);
        let mut part2: *i8= (i8*)arc_malloc((u64)512);
        let mut part3: *i8= (i8*)arc_malloc((u64)512);
        part0[0] = 0; part1[0] = 0; part2[0] = 0; part3[0] = 0;
        let mut nparts: i32= 0;
        let mut poff: i32= 0;
        let mut in_q: bool= false;
        let mut ri: i64= 0;
        while (ri < raw_len && nparts < 4) {
            let mut c: i8= raw[ri];
            if (c == '"') { in_q = !in_q; }
            if (c == ':' && !in_q) {
                let mut cur_part: *i8= (nparts == 0 ? part0 : (nparts == 1 ? part1 : (nparts == 2 ? part2 : part3)));
                cur_part[poff] = 0;
                nparts = nparts + 1; poff = 0;
                let mut np: *i8= (nparts == 0 ? part0 : (nparts == 1 ? part1 : (nparts == 2 ? part2 : part3)));
                np[0] = 0;
            } else {
                let mut cur_part: *i8= (nparts == 0 ? part0 : (nparts == 1 ? part1 : (nparts == 2 ? part2 : part3)));
                let mut lim: i32= (nparts == 0 ? 1535 : 511);
                if (poff < lim) { cur_part[poff] = c; poff = poff + 1; }
            }
            ri = ri + 1;
        }
        {
            let mut cur_part: *i8= (nparts == 0 ? part0 : (nparts == 1 ? part1 : (nparts == 2 ? part2 : part3)));
            cur_part[poff] = 0; nparts = nparts + 1;
        }
        if (nparts < 2) {
            arc_free(part0); arc_free(part1); arc_free(part2); arc_free(part3); return;
        }

        // Flat storage for constraints/varnames: 4 entries each, 64 bytes per entry
        let mut in_cstr_buf: *i8= (i8*)arc_malloc((u64)256); // 4*64
        let mut in_var_buf: *i8= (i8*)arc_malloc((u64)256);
        let mut out_cstr_buf: *i8= (i8*)arc_malloc((u64)256);
        let mut out_var_buf: *i8= (i8*)arc_malloc((u64)256);
        let mut clob_buf: *i8= (i8*)arc_malloc((u64)256);
        let mut in_cnt: i32= 0; let mut out_cnt: i32= 0; let mut clob_cnt: i32= 0;

        // Helper macros inline: get pointer to entry i in a flat 64-byte-stride buffer
        // in_cstr(i) = in_cstr_buf + i*64
        // Parse sections: sec1→part1, sec2→part2, sec3→part3
        let mut sec: i32= 1;
        while (sec < nparts && sec <= 3) {
            let mut sp: *i8= (sec == 1 ? part1 : (sec == 2 ? part2 : part3));
            let mut sp_len: i64= (i64)strlen(sp);
            let mut si: i64= 0;
            while (si < sp_len) {
                while (si < sp_len && (sp[si] == ' ' || sp[si] == '\t' || sp[si] == '\n' || sp[si] == '\r' || sp[si] == ',')) { si = si + 1; }
                if (si >= sp_len) { break; }
                if (sp[si] == '"') {
                    si = si + 1;
                    let mut cstr: [64]i8; let mut ci: i32= 0; let mut is_out: bool= false;
                    if (si < sp_len && sp[si] == '=') { is_out = true; si = si + 1; }
                    while (si < sp_len && sp[si] != '"' && ci < 63) { cstr[ci] = sp[si]; ci = ci + 1; si = si + 1; }
                    cstr[ci] = 0;
                    if (si < sp_len && sp[si] == '"') { si = si + 1; }
                    while (si < sp_len && (sp[si] == ' ' || sp[si] == '\t')) { si = si + 1; }
                    if (si < sp_len && sp[si] == '(') {
                        si = si + 1;
                        let mut vname: [64]i8; let mut vi: i32= 0;
                        while (si < sp_len && sp[si] != ')' && vi < 63) { vname[vi] = sp[si]; vi = vi + 1; si = si + 1; }
                        vname[vi] = 0;
                        if (si < sp_len && sp[si] == ')') { si = si + 1; }
                        if (is_out || sec == 2) {
                            if (out_cnt < 4) {
                                afmt(out_cstr_buf + out_cnt * 64, (u64)64, "%s", .{ cstr });
                                afmt(out_var_buf  + out_cnt * 64, (u64)64, "%s", .{ vname });
                                out_cnt = out_cnt + 1;
                            }
                        } else {
                            if (in_cnt < 4) {
                                afmt(in_cstr_buf + in_cnt * 64, (u64)64, "%s", .{ cstr });
                                afmt(in_var_buf  + in_cnt * 64, (u64)64, "%s", .{ vname });
                                in_cnt = in_cnt + 1;
                            }
                        }
                    } else {
                        if (clob_cnt < 4) { afmt(clob_buf + clob_cnt * 64, (u64)64, "%s", .{ cstr }); clob_cnt = clob_cnt + 1; }
                    }
                } else if (sp[si] != 0) {
                    let mut tok: [64]i8; let mut ti: i32= 0;
                    while (si < sp_len && sp[si] != ' ' && sp[si] != '\t' && sp[si] != ',' && sp[si] != '\n' && ti < 63) { tok[ti] = sp[si]; ti = ti + 1; si = si + 1; }
                    tok[ti] = 0;
                    if (ti > 0 && clob_cnt < 4) { afmt(clob_buf + clob_cnt * 64, (u64)64, "%s", .{ tok }); clob_cnt = clob_cnt + 1; }
                } else { si = si + 1; }
            }
            sec = sec + 1;
        }

        // Build substituted instruction string from part0
        let mut instr_subst: *i8= (i8*)arc_malloc((u64)2048);
        let mut is_off: i32= 0;
        let mut ip: *i8= part0;
        let mut ip_len: i64= (i64)strlen(ip);
        let mut ii: i64= 0;
        while (ii < ip_len && is_off < 2045) {
            if (ip[ii] == '%') {
                ii = ii + 1;
                let mut vn: [64]i8; let mut vni: i32= 0;
                while (ii < ip_len && (isalpha((i32)ip[ii]) || isdigit((i32)ip[ii]) || ip[ii] == '_') && vni < 63) { vn[vni] = ip[ii]; vni = vni + 1; ii = ii + 1; }
                vn[vni] = 0;
                let mut idx: i32= -1;
                let mut ki: i32= 0;
                while (ki < out_cnt && idx < 0) { if (strcmp(out_var_buf + ki*64, vn) == 0) { idx = ki; } ki = ki + 1; }
                ki = 0;
                while (ki < in_cnt && idx < 0) { if (strcmp(in_var_buf + ki*64, vn) == 0) { idx = out_cnt + ki; } ki = ki + 1; }
                if (idx >= 0) {
                    let mut repl: [16]i8; afmt(repl, (u64)16, "$%d", .{ idx });
                    let mut rl: i64= (i64)strlen(repl); let mut ri2: i64= 0;
                    while (ri2 < rl && is_off < 2045) { instr_subst[is_off] = repl[ri2]; is_off = is_off + 1; ri2 = ri2 + 1; }
                } else {
                    instr_subst[is_off] = '%'; is_off = is_off + 1;
                    let mut vni2: i64= 0;
                    while (vni2 < (i64)vni && is_off < 2045) { instr_subst[is_off] = vn[vni2]; is_off = is_off + 1; vni2 = vni2 + 1; }
                }
            } else if (ip[ii] == '$') {
                if (is_off + 1 < 2045) { instr_subst[is_off] = '$'; instr_subst[is_off+1] = '$'; is_off = is_off + 2; }
                ii = ii + 1;
            } else if (ip[ii] == '\n') {
                // Pass actual newline byte — LLVMGetInlineAsm expects raw bytes
                if (is_off < 2045) { instr_subst[is_off] = '\n'; is_off = is_off + 1; }
                ii = ii + 1;
            } else { instr_subst[is_off] = ip[ii]; is_off = is_off + 1; ii = ii + 1; }
        }
        instr_subst[is_off] = 0;

        // Build constraint string
        let mut con_str: *i8= (i8*)arc_malloc((u64)512);
        con_str[0] = 0; let mut co: i32= 0;
        let mut oci: i32= 0;
        while (oci < out_cnt) {
            if (co > 0) { con_str[co] = ','; co = co + 1; }
            con_str[co] = '='; co = co + 1;
            let mut ocs: *i8= out_cstr_buf + oci*64;
            let mut ocl: i64= (i64)strlen(ocs); let mut j: i64= 0;
            while (j < ocl && co < 510) { con_str[co] = ocs[j]; co = co + 1; j = j + 1; }
            oci = oci + 1;
        }
        let mut ici: i32= 0;
        while (ici < in_cnt) {
            if (co > 0) { con_str[co] = ','; co = co + 1; }
            let mut ics: *i8= in_cstr_buf + ici*64;
            let mut icl: i64= (i64)strlen(ics); let mut j: i64= 0;
            while (j < icl && co < 510) { con_str[co] = ics[j]; co = co + 1; j = j + 1; }
            ici = ici + 1;
        }
        let mut cli: i32= 0;
        while (cli < clob_cnt) {
            if (co > 0) { con_str[co] = ','; co = co + 1; }
            if (co + 3 < 510) { con_str[co] = '~'; con_str[co+1] = '{'; co = co + 2; }
            let mut cs: *i8= clob_buf + cli*64;
            let mut cl: i64= (i64)strlen(cs); let mut j: i64= 0;
            while (j < cl && co < 508) { con_str[co] = cs[j]; co = co + 1; j = j + 1; }
            if (co < 510) { con_str[co] = '}'; co = co + 1; }
            cli = cli + 1;
        }
        con_str[co] = 0;

        // Collect input LLVM values and types
        let mut in_vals: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)(in_cnt > 0 ? in_cnt : 1));
        let mut in_types_a: **i8= (i8**)arc_malloc(sizeof(i8*) * (u64)(in_cnt > 0 ? in_cnt : 1));
        let mut ivi: i32= 0;
        while (ivi < in_cnt) {
            let mut ivn: *i8= in_var_buf + ivi*64;
            let mut iv: *i8= ctx_lookup_local(ctx, ivn);
            let mut it: *i8= ctx_lookup_local_type(ctx, ivn);
            if (iv != (i8*)0 && it != (i8*)0) {
                in_vals[ivi]    = LLVMBuildLoad2(ctx.llvm_builder, it, iv, ivn);
                in_types_a[ivi] = it;
            } else { in_vals[ivi] = (i8*)0; in_types_a[ivi] = LLVMInt32TypeInContext(ctx.llvm_ctx); }
            ivi = ivi + 1;
        }
        let mut ret_t: *i8= (out_cnt == 1) ? (i8*)0 : LLVMVoidTypeInContext(ctx.llvm_ctx);
        if (out_cnt == 1) {
            let mut ovt: *i8= ctx_lookup_local_type(ctx, out_var_buf);
            ret_t = (ovt != (i8*)0) ? ovt : LLVMInt32TypeInContext(ctx.llvm_ctx);
        }
        let mut fn_ty: *i8= LLVMFunctionType(ret_t, in_types_a, in_cnt, 0);
        let mut istr_len: i64= (i64)strlen(instr_subst);
        let mut cstr_len: i64= (i64)strlen(con_str);
        let mut asm_val: *i8= LLVMGetInlineAsm(fn_ty, instr_subst, (u64)istr_len, con_str, (u64)cstr_len, 1, 0, 1, 0);
        let mut call_res: *i8= LLVMBuildCall2(ctx.llvm_builder, fn_ty, asm_val, in_vals, in_cnt, out_cnt > 0 ? "asm_out" : "");
        if (out_cnt == 1 && call_res != (i8*)0) {
            let mut ov: *i8= ctx_lookup_local(ctx, out_var_buf);
            if (ov != (i8*)0) { LLVMBuildStore(ctx.llvm_builder, call_res, ov); }
        }
        arc_free(part0); arc_free(part1); arc_free(part2); arc_free(part3);
        arc_free(in_cstr_buf); arc_free(in_var_buf); arc_free(out_cstr_buf); arc_free(out_var_buf); arc_free(clob_buf);
        arc_free(instr_subst); arc_free(con_str); arc_free(in_vals); arc_free(in_types_a);
        return;
    }
    if (kind == nd_try_expr_stmt) {
        let mut ts: *parser.try_expr_stmt= (parser.try_expr_stmt*)node;
        let mut tv: *i8= visit_expr(ts.expr, ctx);
        if (tv == (i8*)0) { return; }
        let mut tv_t: *i8= LLVMTypeOf(tv);
        let mut i32_t_s: *i8= LLVMInt32TypeInContext(ctx.llvm_ctx);
        let mut fn_s: *i8= ctx.current_func;
        let mut err_bb_s: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_s, "ts_err");
        let mut ok_bb_s: *i8= LLVMAppendBasicBlockInContext(ctx.llvm_ctx, fn_s, "ts_ok");
        let mut is_err_s: *i8= (i8*)0;

        if (LLVMGetTypeKind(tv_t) == LLVMStructTypeKind) {
            // !T result: extract is_err flag from { i32, T }
            let mut ts_err_flag: *i8= LLVMBuildExtractValue(ctx.llvm_builder, tv, 0, "ts_err_flag");
            let mut ts_zero: *i8= LLVMConstInt(i32_t_s, 0, 0);
            is_err_s = LLVMBuildICmp(ctx.llvm_builder, LLVMIntNE, ts_err_flag, ts_zero, "ts_is_err");
        } else if (LLVMGetTypeKind(tv_t) == LLVMIntegerTypeKind) {
            // !void result: check for -1
            let mut coerced_s: *i8= coerce_int_val(tv, i32_t_s, ctx.llvm_builder);
            let mut minus1_s: i64= (i64)-1;
            let mut neg1_s: *i8= LLVMConstInt(i32_t_s, (u64)minus1_s, 1);
            is_err_s = LLVMBuildICmp(ctx.llvm_builder, LLVMIntEQ, coerced_s, neg1_s, "ts_is_err");
        } else {
            // Unknown type — skip
            return;
        }

        LLVMBuildCondBr(ctx.llvm_builder, is_err_s, err_bb_s, ok_bb_s);
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, err_bb_s);
        let mut ts_di: i32= ctx.defers.len - 1;
        while (ts_di >= 0) {
            emit_deferred(&ctx.defers.data[ts_di], ctx);
            ts_di = ts_di - 1;
        }
        let mut ts_ei: i32= ctx.errdefers.len - 1;
        while (ts_ei >= 0) {
            emit_deferred(&ctx.errdefers.data[ts_ei], ctx);
            ts_ei = ts_ei - 1;
        }
        let mut ts_ret: *i8= ctx.current_ret_type != (i8*)0 ? ctx.current_ret_type : i32_t_s;
        if (ctx.current_func_eu_is_value) {
            // Propagate error as { i32 1, undef } in !T caller
            let mut eu_terr: *i8= LLVMGetUndef(ts_ret);
            eu_terr = LLVMBuildInsertValue(ctx.llvm_builder, eu_terr, LLVMConstInt(i32_t_s, 1, 0), 0, "eu_terr");
            LLVMBuildRet(ctx.llvm_builder, eu_terr);
        } else {
            // Propagate as -1 in !void caller
            let mut minus1_s2: i64= (i64)-1;
            let mut neg1_s2: *i8= LLVMConstInt(i32_t_s, (u64)minus1_s2, 1);
            LLVMBuildRet(ctx.llvm_builder, coerce_int_val(neg1_s2, ts_ret, ctx.llvm_builder));
        }
        LLVMPositionBuilderAtEnd(ctx.llvm_builder, ok_bb_s);
        return;
    }
    // Inline type declarations inside a function body (e.g., anonymous istruc per-instance init).
    // Forward to the top-level declaration visitor which registers the type in ctx.struct_types.
    if (kind == nd_namespace_decl || kind == nd_struct_decl || kind == nd_enum_decl || kind == nd_typedef_decl) {
        visit_top_level_decl(node, ctx);
        return;
    }
    // `using SomeName;` inside a function body — register namespace prefix for name resolution.
    if (kind == nd_using_decl) {
        let mut ud: *parser.typedef_decl= (parser.typedef_decl*)node;
        if (ud.is_namespace_using && ud.ns_using_name != (i8*)0) {
            ctx_add_using_ns(ctx, ud.ns_using_name);
        }
        return;
    }
    // Other statement kinds ignored silently.
}

} // namespace ir
