; ModuleID = 'boot/compiler/parser/main.arc'
source_filename = "boot/compiler/parser/main.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%node_vec = type { ptr, i32, i32 }
%block_stmt = type { i32, i64, ptr, i32 }
%parser_t = type { ptr, i32, i32, i8, ptr, i32, i32 }
%macro_def_t = type { ptr, ptr, i32, ptr, i32 }
%var_decl = type { i32, i64, ptr, ptr, ptr, i8, i8, i8, i8, i8, ptr, i32 }
%func_decl = type { i32, i64, ptr, ptr, ptr, i32, i8, ptr, i8, i8, ptr, i8, i8, ptr, i32, i8, ptr, ptr, i32 }
%expr_stmt = type { i32, i64, ptr }
%struct_decl = type { i32, i64, ptr, ptr, i32, i32, i8 }
%enum_decl = type { i32, i64, ptr, ptr, ptr, ptr, i32, i32, i8, ptr, ptr, ptr, ptr, ptr, ptr }
%typedef_decl = type { i32, i64, ptr, ptr }
%namespace_decl = type { i32, i64, ptr, ptr, i32, i32 }
%extern_c_block = type { i32, i64, ptr, i32, i32 }
%ast_node = type { i32, i64 }
%if_stmt = type { i32, i64, ptr, ptr, ptr, i8, ptr, ptr }
%while_stmt = type { i32, i64, ptr, ptr }
%for_stmt = type { i32, i64, ptr, ptr, ptr, ptr }
%switch_stmt = type { i32, i64, ptr, ptr, ptr, ptr, i32, i32 }
%return_stmt = type { i32, i64, ptr, i8 }
%defer_stmt = type { i32, i64, ptr, ptr, i8 }
%break_stmt = type { i32, i64 }
%continue_stmt = type { i32, i64 }
%try_expr_stmt = type { i32, i64, ptr }
%asm_stmt = type { i32, i64, ptr }
%program_node = type { i32, i64, ptr, i32, i32 }

@ast_kind__nd_block = internal constant i32 0
@ast_kind__nd_expr_stmt = internal constant i32 1
@ast_kind__nd_return_stmt = internal constant i32 2
@ast_kind__nd_break_stmt = internal constant i32 3
@ast_kind__nd_continue_stmt = internal constant i32 4
@ast_kind__nd_if_stmt = internal constant i32 5
@ast_kind__nd_while_stmt = internal constant i32 6
@ast_kind__nd_for_stmt = internal constant i32 7
@ast_kind__nd_for_range_stmt = internal constant i32 8
@ast_kind__nd_switch_stmt = internal constant i32 9
@ast_kind__nd_asm_stmt = internal constant i32 10
@ast_kind__nd_defer_stmt = internal constant i32 11
@ast_kind__nd_errdefer_stmt = internal constant i32 12
@ast_kind__nd_var_decl = internal constant i32 13
@ast_kind__nd_func_decl = internal constant i32 14
@ast_kind__nd_struct_decl = internal constant i32 15
@ast_kind__nd_class_decl = internal constant i32 16
@ast_kind__nd_enum_decl = internal constant i32 17
@ast_kind__nd_union_decl = internal constant i32 18
@ast_kind__nd_typedef_decl = internal constant i32 19
@ast_kind__nd_namespace_decl = internal constant i32 20
@ast_kind__nd_using_decl = internal constant i32 21
@ast_kind__nd_extern_c_block = internal constant i32 22
@ast_kind__nd_program = internal constant i32 23
@ast_kind__nd_try_expr_stmt = internal constant i32 24
@ast_kind__nd_res_block = internal constant i32 25
@str = private unnamed_addr constant [28 x i8] c"Expected '(' for macro call\00", align 1
@str.1 = private unnamed_addr constant [30 x i8] c"Expected ')' after macro args\00", align 1
@str.2 = private unnamed_addr constant [19 x i8] c"Expected type name\00", align 1
@str.3 = private unnamed_addr constant [30 x i8] c"Expected ']' after array size\00", align 1
@str.4 = private unnamed_addr constant [30 x i8] c"Expected ']' after array size\00", align 1
@str.5 = private unnamed_addr constant [36 x i8] c"Expected ')' after constructor args\00", align 1
@str.6 = private unnamed_addr constant [36 x i8] c"Expected '}' after constructor args\00", align 1
@str.7 = private unnamed_addr constant [40 x i8] c"Expected ';' after variable declaration\00", align 1
@str.8 = private unnamed_addr constant [30 x i8] c"Expected ')' after parameters\00", align 1
@str.9 = private unnamed_addr constant [26 x i8] c"Expected '(' in init list\00", align 1
@str.10 = private unnamed_addr constant [26 x i8] c"Expected ')' in init list\00", align 1
@str.11 = private unnamed_addr constant [33 x i8] c"Expected '(' after operator name\00", align 1
@str.12 = private unnamed_addr constant [26 x i8] c"Expected declaration name\00", align 1
@str.13 = private unnamed_addr constant [26 x i8] c"Expected declaration name\00", align 1
@str.14 = private unnamed_addr constant [31 x i8] c"Expected '{' after struct name\00", align 1
@str.15 = private unnamed_addr constant [20 x i8] c"Expected field name\00", align 1
@str.16 = private unnamed_addr constant [30 x i8] c"Expected ']' after array size\00", align 1
@str.17 = private unnamed_addr constant [25 x i8] c"Expected ';' after field\00", align 1
@str.18 = private unnamed_addr constant [31 x i8] c"Expected '}' after struct body\00", align 1
@str.19 = private unnamed_addr constant [29 x i8] c"Expected '{' after enum name\00", align 1
@str.20 = private unnamed_addr constant [22 x i8] c"Expected variant name\00", align 1
@str.21 = private unnamed_addr constant [30 x i8] c"Expected ')' in tuple variant\00", align 1
@str.22 = private unnamed_addr constant [11 x i8] c"field name\00", align 1
@str.23 = private unnamed_addr constant [32 x i8] c"Expected '}' after variant body\00", align 1
@str.24 = private unnamed_addr constant [35 x i8] c"Expected ',' between enum variants\00", align 1
@str.25 = private unnamed_addr constant [29 x i8] c"Expected '}' after enum body\00", align 1
@str.26 = private unnamed_addr constant [29 x i8] c"Expected '=' in typedef auto\00", align 1
@str.27 = private unnamed_addr constant [27 x i8] c"Expected ';' after typedef\00", align 1
@str.28 = private unnamed_addr constant [34 x i8] c"Expected '{' after namespace name\00", align 1
@str.29 = private unnamed_addr constant [34 x i8] c"Expected '}' after namespace body\00", align 1
@str.30 = private unnamed_addr constant [36 x i8] c"Expected '}' after extern \22C\22 block\00", align 1
@str.31 = private unnamed_addr constant [20 x i8] c"Expected class name\00", align 1
@str.32 = private unnamed_addr constant [30 x i8] c"Expected '{' after class name\00", align 1
@str.33 = private unnamed_addr constant [30 x i8] c"Expected '}' after class body\00", align 1
@str.34 = private unnamed_addr constant [34 x i8] c"Expected '=' in using declaration\00", align 1
@str.35 = private unnamed_addr constant [37 x i8] c"Expected ';' after using declaration\00", align 1
@str.36 = private unnamed_addr constant [38 x i8] c"Expected '{' after const_resolve name\00", align 1
@str.37 = private unnamed_addr constant [45 x i8] c"Expected closing delimiter for macro pattern\00", align 1
@str.38 = private unnamed_addr constant [38 x i8] c"Expected '}' after const_resolve body\00", align 1
@str.39 = private unnamed_addr constant [13 x i8] c"Expected '{'\00", align 1
@str.40 = private unnamed_addr constant [13 x i8] c"Expected '}'\00", align 1
@str.41 = private unnamed_addr constant [30 x i8] c"Expected ']' after array size\00", align 1
@str.42 = private unnamed_addr constant [36 x i8] c"Expected ')' after constructor args\00", align 1
@str.43 = private unnamed_addr constant [36 x i8] c"Expected '}' after constructor args\00", align 1
@str.44 = private unnamed_addr constant [40 x i8] c"Expected ';' after variable declaration\00", align 1
@str.45 = private unnamed_addr constant [29 x i8] c"Expected ')' after condition\00", align 1
@str.46 = private unnamed_addr constant [27 x i8] c"Expected '|' after capture\00", align 1
@str.47 = private unnamed_addr constant [27 x i8] c"Expected '|' after capture\00", align 1
@str.48 = private unnamed_addr constant [29 x i8] c"Expected ')' after condition\00", align 1
@str.49 = private unnamed_addr constant [13 x i8] c"Expected ';'\00", align 1
@str.50 = private unnamed_addr constant [20 x i8] c"Expected ';' in for\00", align 1
@str.51 = private unnamed_addr constant [31 x i8] c"Expected ')' after for clauses\00", align 1
@str.52 = private unnamed_addr constant [13 x i8] c"Expected ')'\00", align 1
@str.53 = private unnamed_addr constant [13 x i8] c"Expected '{'\00", align 1
@str.54 = private unnamed_addr constant [29 x i8] c"Expected 'case' or 'default'\00", align 1
@str.55 = private unnamed_addr constant [30 x i8] c"Expected ':' after case label\00", align 1
@str.56 = private unnamed_addr constant [26 x i8] c"Expected '}' after switch\00", align 1
@str.57 = private unnamed_addr constant [26 x i8] c"Expected ';' after return\00", align 1
@str.58 = private unnamed_addr constant [36 x i8] c"Expected ';' after defer expression\00", align 1
@str.59 = private unnamed_addr constant [13 x i8] c"Expected ';'\00", align 1
@str.60 = private unnamed_addr constant [13 x i8] c"Expected ';'\00", align 1
@str.61 = private unnamed_addr constant [34 x i8] c"Expected ';' after try expression\00", align 1
@str.62 = private unnamed_addr constant [31 x i8] c"Expected '{...}' after __asm__\00", align 1
@str.63 = private unnamed_addr constant [24 x i8] c"Expected ':' in ternary\00", align 1

define void @parser__NS_node_vec_init(ptr %0) {
entry:
  %v = alloca ptr, align 8
  store ptr %0, ptr %v, align 8
  %ptr_deref = load ptr, ptr %v, align 8
  %data = getelementptr inbounds nuw %node_vec, ptr %ptr_deref, i32 0, i32 0
  store ptr null, ptr %data, align 8
  %ptr_deref1 = load ptr, ptr %v, align 8
  %len = getelementptr inbounds nuw %node_vec, ptr %ptr_deref1, i32 0, i32 1
  store i32 0, ptr %len, align 4
  %ptr_deref2 = load ptr, ptr %v, align 8
  %cap = getelementptr inbounds nuw %node_vec, ptr %ptr_deref2, i32 0, i32 2
  store i32 0, ptr %cap, align 4
  ret void
}

define void @parser__NS_node_vec_push(ptr %0, ptr %1) {
entry:
  %v = alloca ptr, align 8
  store ptr %0, ptr %v, align 8
  %n = alloca ptr, align 8
  store ptr %1, ptr %n, align 8
  %ptr_deref = load ptr, ptr %v, align 8
  %len = getelementptr inbounds nuw %node_vec, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref1 = load ptr, ptr %v, align 8
  %mem_load = load i32, ptr %len, align 4
  %ptr_deref2 = load ptr, ptr %v, align 8
  %cap = getelementptr inbounds nuw %node_vec, ptr %ptr_deref2, i32 0, i32 2
  %ptr_deref3 = load ptr, ptr %v, align 8
  %mem_load4 = load i32, ptr %cap, align 4
  %icmp = icmp sge i32 %mem_load, %mem_load4
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %nc = alloca i32, align 4
  %ptr_deref5 = load ptr, ptr %v, align 8
  %cap6 = getelementptr inbounds nuw %node_vec, ptr %ptr_deref5, i32 0, i32 2
  %ptr_deref7 = load ptr, ptr %v, align 8
  %mem_load8 = load i32, ptr %cap6, align 4
  %icmp9 = icmp eq i32 %mem_load8, 0
  br i1 %icmp9, label %tern_then, label %tern_else

if_merge:                                         ; preds = %tern_merge, %entry
  %ptr_deref18 = load ptr, ptr %v, align 8
  %data19 = getelementptr inbounds nuw %node_vec, ptr %ptr_deref18, i32 0, i32 0
  %ptr_deref20 = load ptr, ptr %v, align 8
  %len21 = getelementptr inbounds nuw %node_vec, ptr %ptr_deref20, i32 0, i32 1
  %ptr_deref22 = load ptr, ptr %v, align 8
  %mem_load23 = load i32, ptr %len21, align 4
  %ptr_load = load ptr, ptr %data19, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load23
  %n24 = load ptr, ptr %n, align 8
  store ptr %n24, ptr %ptr_gep, align 8
  %ptr_deref25 = load ptr, ptr %v, align 8
  %len26 = getelementptr inbounds nuw %node_vec, ptr %ptr_deref25, i32 0, i32 1
  %ptr_deref27 = load ptr, ptr %v, align 8
  %len28 = getelementptr inbounds nuw %node_vec, ptr %ptr_deref27, i32 0, i32 1
  %ptr_deref29 = load ptr, ptr %v, align 8
  %mem_load30 = load i32, ptr %len28, align 4
  %add = add i32 %mem_load30, 1
  store i32 %add, ptr %len26, align 4
  ret void

tern_then:                                        ; preds = %if_then
  br label %tern_merge

tern_else:                                        ; preds = %if_then
  %ptr_deref10 = load ptr, ptr %v, align 8
  %cap11 = getelementptr inbounds nuw %node_vec, ptr %ptr_deref10, i32 0, i32 2
  %ptr_deref12 = load ptr, ptr %v, align 8
  %mem_load13 = load i32, ptr %cap11, align 4
  %mul = mul i32 %mem_load13, 2
  br label %tern_merge

tern_merge:                                       ; preds = %tern_else, %tern_then
  %tern = phi i64 [ 16, %tern_then ], [ %mul, %tern_else ]
  %trunc = trunc i64 %tern to i32
  store i32 %trunc, ptr %nc, align 4
  %ptr_deref14 = load ptr, ptr %v, align 8
  %data = getelementptr inbounds nuw %node_vec, ptr %ptr_deref14, i32 0, i32 0
  %ptr_deref15 = load ptr, ptr %v, align 8
  %cap16 = getelementptr inbounds nuw %node_vec, ptr %ptr_deref15, i32 0, i32 2
  %nc17 = load i32, ptr %nc, align 4
  store i32 %nc17, ptr %cap16, align 4
  br label %if_merge
}

define ptr @parser__NS_alloc_block_stmt() {
entry:
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ptr_deref = load ptr, ptr %n, align 8
  %kind = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref, i32 0, i32 0
  %nd_block = load i32, ptr @ast_kind__nd_block, align 4
  store i32 %nd_block, ptr %kind, align 4
  %n1 = load ptr, ptr %n, align 8
  ret ptr %n1
}

define void @parser__NS_block_stmt_push(ptr %0, ptr %1) {
entry:
  %blk = alloca ptr, align 8
  store ptr %0, ptr %blk, align 8
  %s = alloca ptr, align 8
  store ptr %1, ptr %s, align 8
  %old_len = alloca i32, align 4
  %ptr_deref = load ptr, ptr %blk, align 8
  %stmts_len = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref, i32 0, i32 3
  %ptr_deref1 = load ptr, ptr %blk, align 8
  %mem_load = load i32, ptr %stmts_len, align 4
  store i32 %mem_load, ptr %old_len, align 4
  %nc = alloca i32, align 4
  %old_len2 = load i32, ptr %old_len, align 4
  %icmp = icmp eq i32 %old_len2, 0
  br i1 %icmp, label %tern_then, label %tern_else

tern_then:                                        ; preds = %entry
  br label %tern_merge

tern_else:                                        ; preds = %entry
  %old_len3 = load i32, ptr %old_len, align 4
  %mul = mul i32 %old_len3, 2
  br label %tern_merge

tern_merge:                                       ; preds = %tern_else, %tern_then
  %tern = phi i64 [ 16, %tern_then ], [ %mul, %tern_else ]
  %trunc = trunc i64 %tern to i32
  store i32 %trunc, ptr %nc, align 4
  %old_len4 = load i32, ptr %old_len, align 4
  %icmp5 = icmp eq i32 %old_len4, 0
  br i1 %icmp5, label %if_then, label %if_else

if_then:                                          ; preds = %tern_merge
  %ptr_deref6 = load ptr, ptr %blk, align 8
  %stmts = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref6, i32 0, i32 2
  br label %if_merge

if_else:                                          ; preds = %tern_merge
  %ptr_deref7 = load ptr, ptr %blk, align 8
  %stmts8 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref7, i32 0, i32 2
  br label %if_merge

if_merge:                                         ; preds = %if_else, %if_then
  %ptr_deref9 = load ptr, ptr %blk, align 8
  %stmts10 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref9, i32 0, i32 2
  %ptr_deref11 = load ptr, ptr %blk, align 8
  %stmts_len12 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref11, i32 0, i32 3
  %ptr_deref13 = load ptr, ptr %blk, align 8
  %mem_load14 = load i32, ptr %stmts_len12, align 4
  %ptr_load = load ptr, ptr %stmts10, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load14
  %s15 = load ptr, ptr %s, align 8
  store ptr %s15, ptr %ptr_gep, align 8
  %ptr_deref16 = load ptr, ptr %blk, align 8
  %stmts_len17 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref16, i32 0, i32 3
  %ptr_deref18 = load ptr, ptr %blk, align 8
  %stmts_len19 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref18, i32 0, i32 3
  %ptr_deref20 = load ptr, ptr %blk, align 8
  %mem_load21 = load i32, ptr %stmts_len19, align 4
  %add = add i32 %mem_load21, 1
  store i32 %add, ptr %stmts_len17, align 4
  ret void
}

define void @parser_t__NS_init(ptr %0, ptr %1, i32 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %toks = alloca ptr, align 8
  store ptr %1, ptr %toks, align 8
  %len = alloca i32, align 4
  store i32 %2, ptr %len, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %tokens = getelementptr inbounds nuw %parser_t, ptr %ptr_deref, i32 0, i32 0
  %toks1 = load ptr, ptr %toks, align 8
  store ptr %toks1, ptr %tokens, align 8
  %ptr_deref2 = load ptr, ptr %self, align 8
  %tokens_len = getelementptr inbounds nuw %parser_t, ptr %ptr_deref2, i32 0, i32 1
  %len3 = load i32, ptr %len, align 4
  store i32 %len3, ptr %tokens_len, align 4
  %ptr_deref4 = load ptr, ptr %self, align 8
  %current = getelementptr inbounds nuw %parser_t, ptr %ptr_deref4, i32 0, i32 2
  store i32 0, ptr %current, align 4
  %ptr_deref5 = load ptr, ptr %self, align 8
  %had_parse_error = getelementptr inbounds nuw %parser_t, ptr %ptr_deref5, i32 0, i32 3
  store i8 0, ptr %had_parse_error, align 1
  %ptr_deref6 = load ptr, ptr %self, align 8
  %macros_cap = getelementptr inbounds nuw %parser_t, ptr %ptr_deref6, i32 0, i32 6
  store i32 8, ptr %macros_cap, align 4
  %ptr_deref7 = load ptr, ptr %self, align 8
  %macros_len = getelementptr inbounds nuw %parser_t, ptr %ptr_deref7, i32 0, i32 5
  store i32 0, ptr %macros_len, align 4
  %ptr_deref8 = load ptr, ptr %self, align 8
  %macros = getelementptr inbounds nuw %parser_t, ptr %ptr_deref8, i32 0, i32 4
  ret void
}

define i8 @parser_t__NS_peek_tok(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %current = getelementptr inbounds nuw %parser_t, ptr %ptr_deref, i32 0, i32 2
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %current, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %tokens_len = getelementptr inbounds nuw %parser_t, ptr %ptr_deref2, i32 0, i32 1
  %ptr_deref3 = load ptr, ptr %self, align 8
  %mem_load4 = load i32, ptr %tokens_len, align 4
  %icmp = icmp sge i32 %mem_load, %mem_load4
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %t = alloca i8, align 1
  store i8 0, ptr %t, align 1
  %t5 = load i8, ptr %t, align 1
  ret i8 %t5

if_merge:                                         ; preds = %entry
  %ptr_deref6 = load ptr, ptr %self, align 8
  %tokens = getelementptr inbounds nuw %parser_t, ptr %ptr_deref6, i32 0, i32 0
  %ptr_deref7 = load ptr, ptr %self, align 8
  %current8 = getelementptr inbounds nuw %parser_t, ptr %ptr_deref7, i32 0, i32 2
  %ptr_deref9 = load ptr, ptr %self, align 8
  %mem_load10 = load i32, ptr %current8, align 4
  %ptr_load = load ptr, ptr %tokens, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load10
  %idx_load = load ptr, ptr %ptr_gep, align 8
  %p2i = ptrtoint ptr %idx_load to i8
  ret i8 %p2i
}

define i8 @parser_t__NS_peek_at_tok(ptr %0, i32 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %offset = alloca i32, align 4
  store i32 %1, ptr %offset, align 4
  %idx = alloca i32, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %current = getelementptr inbounds nuw %parser_t, ptr %ptr_deref, i32 0, i32 2
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %current, align 4
  %offset2 = load i32, ptr %offset, align 4
  %add = add i32 %mem_load, %offset2
  store i32 %add, ptr %idx, align 4
  %idx3 = load i32, ptr %idx, align 4
  %ptr_deref4 = load ptr, ptr %self, align 8
  %tokens_len = getelementptr inbounds nuw %parser_t, ptr %ptr_deref4, i32 0, i32 1
  %ptr_deref5 = load ptr, ptr %self, align 8
  %mem_load6 = load i32, ptr %tokens_len, align 4
  %icmp = icmp sge i32 %idx3, %mem_load6
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %t = alloca i8, align 1
  store i8 0, ptr %t, align 1
  %t7 = load i8, ptr %t, align 1
  ret i8 %t7

if_merge:                                         ; preds = %entry
  %ptr_deref8 = load ptr, ptr %self, align 8
  %tokens = getelementptr inbounds nuw %parser_t, ptr %ptr_deref8, i32 0, i32 0
  %idx9 = load i32, ptr %idx, align 4
  %ptr_load = load ptr, ptr %tokens, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %idx9
  %idx_load = load ptr, ptr %ptr_gep, align 8
  %p2i = ptrtoint ptr %idx_load to i8
  ret i8 %p2i
}

define i8 @parser_t__NS_advance_tok(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %t = alloca i8, align 1
  %1 = call i8 @parser_t__NS_peek_tok(ptr %self)
  store i8 %1, ptr %t, align 1
  %ptr_deref = load ptr, ptr %self, align 8
  %current = getelementptr inbounds nuw %parser_t, ptr %ptr_deref, i32 0, i32 2
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %current, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %tokens_len = getelementptr inbounds nuw %parser_t, ptr %ptr_deref2, i32 0, i32 1
  %ptr_deref3 = load ptr, ptr %self, align 8
  %mem_load4 = load i32, ptr %tokens_len, align 4
  %icmp = icmp slt i32 %mem_load, %mem_load4
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %ptr_deref5 = load ptr, ptr %self, align 8
  %current6 = getelementptr inbounds nuw %parser_t, ptr %ptr_deref5, i32 0, i32 2
  %ptr_deref7 = load ptr, ptr %self, align 8
  %current8 = getelementptr inbounds nuw %parser_t, ptr %ptr_deref7, i32 0, i32 2
  %ptr_deref9 = load ptr, ptr %self, align 8
  %mem_load10 = load i32, ptr %current8, align 4
  %add = add i32 %mem_load10, 1
  store i32 %add, ptr %current6, align 4
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  %t11 = load i8, ptr %t, align 1
  ret i8 %t11
}

define i8 @parser_t__NS_previous_tok(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %current = getelementptr inbounds nuw %parser_t, ptr %ptr_deref, i32 0, i32 2
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %current, align 4
  %icmp = icmp sgt i32 %mem_load, 0
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %ptr_deref2 = load ptr, ptr %self, align 8
  %tokens = getelementptr inbounds nuw %parser_t, ptr %ptr_deref2, i32 0, i32 0
  %ptr_deref3 = load ptr, ptr %self, align 8
  %current4 = getelementptr inbounds nuw %parser_t, ptr %ptr_deref3, i32 0, i32 2
  %ptr_deref5 = load ptr, ptr %self, align 8
  %mem_load6 = load i32, ptr %current4, align 4
  %sub = sub i32 %mem_load6, 1
  %ptr_load = load ptr, ptr %tokens, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %sub
  %idx_load = load ptr, ptr %ptr_gep, align 8
  %p2i = ptrtoint ptr %idx_load to i8
  ret i8 %p2i

if_merge:                                         ; preds = %entry
  %1 = call i8 @parser_t__NS_peek_tok(ptr %self)
  ret i8 %1
}

define i32 @parser_t__NS_peek_type(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %_t = alloca i8, align 1
  %1 = call i8 @parser_t__NS_peek_tok(ptr %self)
  store i8 %1, ptr %_t, align 1
  ret i32 undef
}

define i64 @parser_t__NS_peek_line(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %_t = alloca i8, align 1
  %1 = call i8 @parser_t__NS_peek_tok(ptr %self)
  store i8 %1, ptr %_t, align 1
  ret i64 undef
}

define i32 @parser_t__NS_peek_at_type(ptr %0, i32 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %offset = alloca i32, align 4
  store i32 %1, ptr %offset, align 4
  %_t = alloca i8, align 1
  %offset1 = load i32, ptr %offset, align 4
  %2 = call i8 @parser_t__NS_peek_at_tok(ptr %self, i32 %offset1)
  store i8 %2, ptr %_t, align 1
  ret i32 undef
}

define i64 @parser_t__NS_advance_line_get(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %_t = alloca i8, align 1
  %1 = call i8 @parser_t__NS_advance_tok(ptr %self)
  store i8 %1, ptr %_t, align 1
  ret i64 undef
}

define ptr @parser_t__NS_advance_value_get(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %_t = alloca i8, align 1
  %1 = call i8 @parser_t__NS_advance_tok(ptr %self)
  store i8 %1, ptr %_t, align 1
  ret ptr undef
}

define i32 @parser_t__NS_prev_type(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %_t = alloca i8, align 1
  %1 = call i8 @parser_t__NS_previous_tok(ptr %self)
  store i8 %1, ptr %_t, align 1
  ret i32 undef
}

define i64 @parser_t__NS_prev_line(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %_t = alloca i8, align 1
  %1 = call i8 @parser_t__NS_previous_tok(ptr %self)
  store i8 %1, ptr %_t, align 1
  ret i64 undef
}

define ptr @parser_t__NS_consume_id_value(ptr %0, ptr %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %err_msg = alloca ptr, align 8
  store ptr %1, ptr %err_msg, align 8
  %_t = alloca i8, align 1
  %err_msg1 = load ptr, ptr %err_msg, align 8
  %2 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr %err_msg1)
  store i8 %2, ptr %_t, align 1
  ret ptr undef
}

define i8 @parser_t__NS_check_tok(ptr %0, i32 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %type = alloca i32, align 4
  store i32 %1, ptr %type, align 4
  %2 = call i32 @parser_t__NS_peek_type(ptr %self)
  %type1 = load i32, ptr %type, align 4
  %icmp = icmp eq i32 %2, %type1
  %zext = zext i1 %icmp to i8
  ret i8 %zext
}

define i8 @parser_t__NS_match_tok(ptr %0, i32 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %type = alloca i32, align 4
  store i32 %1, ptr %type, align 4
  %type1 = load i32, ptr %type, align 4
  %2 = call i8 @parser_t__NS_check_tok(ptr %self, i32 %type1)
  %if_cond = icmp ne i8 %2, 0
  br i1 %if_cond, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %3 = call i8 @parser_t__NS_advance_tok(ptr %self)
  ret i8 1

if_merge:                                         ; preds = %entry
  ret i8 0
}

define i8 @parser_t__NS_is_at_end_p(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %1 = call i32 @parser_t__NS_peek_type(ptr %self)
  ret i8 undef
}

define i8 @parser_t__NS_consume_tok(ptr %0, i32 %1, ptr %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %type = alloca i32, align 4
  store i32 %1, ptr %type, align 4
  %err_msg = alloca ptr, align 8
  store ptr %2, ptr %err_msg, align 8
  %type1 = load i32, ptr %type, align 4
  %3 = call i8 @parser_t__NS_check_tok(ptr %self, i32 %type1)
  %if_cond = icmp ne i8 %3, 0
  br i1 %if_cond, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %4 = call i8 @parser_t__NS_advance_tok(ptr %self)
  ret i8 %4

if_merge:                                         ; preds = %entry
  %cur = alloca i8, align 1
  %5 = call i8 @parser_t__NS_peek_tok(ptr %self)
  store i8 %5, ptr %cur, align 1
  %errbuf = alloca [512 x i8], align 1
  store [512 x i8] zeroinitializer, ptr %errbuf, align 1
  %ptr_deref = load ptr, ptr %self, align 8
  %had_parse_error = getelementptr inbounds nuw %parser_t, ptr %ptr_deref, i32 0, i32 3
  store i8 1, ptr %had_parse_error, align 1
  %cur2 = load i8, ptr %cur, align 1
  ret i8 %cur2
}

define void @parser_t__NS_synchronize(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %1 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %2 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool = icmp ne i8 %2, 0
  %not = xor i1 %tobool, true
  br i1 %not, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %prev = alloca i32, align 4
  %3 = call i32 @parser_t__NS_prev_type(ptr %self)
  store i32 %3, ptr %prev, align 4
  %prev1 = load i32, ptr %prev, align 4
  %cur = alloca i32, align 4
  %4 = call i32 @parser_t__NS_peek_type(ptr %self)
  store i32 %4, ptr %cur, align 4
  %cur2 = load i32, ptr %cur, align 4
  %cur3 = load i32, ptr %cur, align 4
  %cur4 = load i32, ptr %cur, align 4
  %cur5 = load i32, ptr %cur, align 4
  %cur6 = load i32, ptr %cur, align 4
  %cur7 = load i32, ptr %cur, align 4
  %cur8 = load i32, ptr %cur, align 4
  %5 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  ret void
}

define ptr @parser_t__NS_find_macro(ptr %0, ptr %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %mi = alloca i32, align 4
  store i32 0, ptr %mi, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %mi1 = load i32, ptr %mi, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %macros_len = getelementptr inbounds nuw %parser_t, ptr %ptr_deref, i32 0, i32 5
  %ptr_deref2 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %macros_len, align 4
  %icmp = icmp slt i32 %mi1, %mem_load
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %m = alloca ptr, align 8
  %ptr_deref3 = load ptr, ptr %self, align 8
  %macros = getelementptr inbounds nuw %parser_t, ptr %ptr_deref3, i32 0, i32 4
  %mi4 = load i32, ptr %mi, align 4
  %ptr_load = load ptr, ptr %macros, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mi4
  %idx_load = load ptr, ptr %ptr_gep, align 8
  store ptr %idx_load, ptr %m, align 8
  %mi5 = load i32, ptr %mi, align 4
  %add = add i32 %mi5, 1
  store i32 %add, ptr %mi, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  ret ptr null
}

define ptr @parser_t__NS_expand_macro_call(ptr %0, ptr %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %mdef = alloca ptr, align 8
  store ptr %1, ptr %mdef, align 8
  %arg_buf_cap = alloca i32, align 4
  store i32 128, ptr %arg_buf_cap, align 4
  %arg_buf = alloca ptr, align 8
  store ptr null, ptr %arg_buf, align 8
  %arg_buf_len = alloca i32, align 4
  store i32 0, ptr %arg_buf_len, align 4
  %arg_starts = alloca ptr, align 8
  store ptr null, ptr %arg_starts, align 8
  %arg_lens = alloca ptr, align 8
  store ptr null, ptr %arg_lens, align 8
  %arg_count = alloca i32, align 4
  store i32 0, ptr %arg_count, align 4
  %cur_arg_start = alloca i32, align 4
  store i32 0, ptr %cur_arg_start, align 4
  %2 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str)
  %depth_m = alloca i32, align 4
  store i32 0, ptr %depth_m, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %3 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool = icmp ne i8 %3, 0
  %not = xor i1 %tobool, true
  %depth_m1 = load i32, ptr %depth_m, align 4
  %icmp = icmp sgt i32 %depth_m1, 0
  %lor = or i1 %not, %icmp
  %4 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool2 = icmp ne i8 %4, 0
  %not3 = xor i1 %tobool2, true
  %land = and i1 %lor, %not3
  br i1 %land, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %at = alloca i8, align 1
  %5 = call i8 @parser_t__NS_peek_tok(ptr %self)
  store i8 %5, ptr %at, align 1
  %arg_buf_len4 = load i32, ptr %arg_buf_len, align 4
  %arg_buf_cap5 = load i32, ptr %arg_buf_cap, align 4
  %icmp6 = icmp sge i32 %arg_buf_len4, %arg_buf_cap5
  br i1 %icmp6, label %if_then, label %if_merge

while_exit:                                       ; preds = %while_cond
  %arg_count11 = load i32, ptr %arg_count, align 4
  %ptr_load12 = load ptr, ptr %arg_starts, align 8
  %ptr_gep13 = getelementptr i32, ptr %ptr_load12, i32 %arg_count11
  %cur_arg_start14 = load i32, ptr %cur_arg_start, align 4
  store i32 %cur_arg_start14, ptr %ptr_gep13, align 4
  %arg_count15 = load i32, ptr %arg_count, align 4
  %ptr_load16 = load ptr, ptr %arg_lens, align 8
  %ptr_gep17 = getelementptr i32, ptr %ptr_load16, i32 %arg_count15
  %arg_buf_len18 = load i32, ptr %arg_buf_len, align 4
  %cur_arg_start19 = load i32, ptr %cur_arg_start, align 4
  %sub = sub i32 %arg_buf_len18, %cur_arg_start19
  store i32 %sub, ptr %ptr_gep17, align 4
  %arg_buf_len20 = load i32, ptr %arg_buf_len, align 4
  %cur_arg_start21 = load i32, ptr %cur_arg_start, align 4
  %icmp22 = icmp sgt i32 %arg_buf_len20, %cur_arg_start21
  br i1 %icmp22, label %if_then23, label %if_merge24

if_then:                                          ; preds = %while_body
  %arg_buf_cap7 = load i32, ptr %arg_buf_cap, align 4
  %mul = mul i32 %arg_buf_cap7, 2
  store i32 %mul, ptr %arg_buf_cap, align 4
  br label %if_merge

if_merge:                                         ; preds = %if_then, %while_body
  %arg_buf_len8 = load i32, ptr %arg_buf_len, align 4
  %ptr_load = load ptr, ptr %arg_buf, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %arg_buf_len8
  %at9 = load i8, ptr %at, align 1
  store i8 %at9, ptr %ptr_gep, align 1
  %arg_buf_len10 = load i32, ptr %arg_buf_len, align 4
  %add = add i32 %arg_buf_len10, 1
  store i32 %add, ptr %arg_buf_len, align 4
  %6 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %while_cond

if_then23:                                        ; preds = %while_exit
  %arg_count25 = load i32, ptr %arg_count, align 4
  %add26 = add i32 %arg_count25, 1
  store i32 %add26, ptr %arg_count, align 4
  br label %if_merge24

if_merge24:                                       ; preds = %if_then23, %while_exit
  %7 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.1)
  %exp_cap = alloca i32, align 4
  store i32 256, ptr %exp_cap, align 4
  %exp = alloca ptr, align 8
  store ptr null, ptr %exp, align 8
  %exp_len = alloca i32, align 4
  store i32 0, ptr %exp_len, align 4
  %tmpl = alloca ptr, align 8
  %ptr_deref = load ptr, ptr %mdef, align 8
  %template_toks = getelementptr inbounds nuw %macro_def_t, ptr %ptr_deref, i32 0, i32 3
  %ptr_deref27 = load ptr, ptr %mdef, align 8
  %mem_load = load ptr, ptr %template_toks, align 8
  store ptr %mem_load, ptr %tmpl, align 8
  %ti = alloca i32, align 4
  store i32 0, ptr %ti, align 4
  br label %while_cond28

while_cond28:                                     ; preds = %if_merge50, %if_merge24
  %ti31 = load i32, ptr %ti, align 4
  %ptr_deref32 = load ptr, ptr %mdef, align 8
  %template_len = getelementptr inbounds nuw %macro_def_t, ptr %ptr_deref32, i32 0, i32 4
  %ptr_deref33 = load ptr, ptr %mdef, align 8
  %mem_load34 = load i32, ptr %template_len, align 4
  %icmp35 = icmp slt i32 %ti31, %mem_load34
  br i1 %icmp35, label %while_body29, label %while_exit30

while_body29:                                     ; preds = %while_cond28
  %tt = alloca i8, align 1
  %ti36 = load i32, ptr %ti, align 4
  %ptr_load37 = load ptr, ptr %tmpl, align 8
  %ptr_gep38 = getelementptr i8, ptr %ptr_load37, i32 %ti36
  %idx_load = load i8, ptr %ptr_gep38, align 1
  store i8 %idx_load, ptr %tt, align 1
  %ti39 = load i32, ptr %ti, align 4
  %add40 = add i32 %ti39, 1
  %ptr_deref41 = load ptr, ptr %mdef, align 8
  %template_len42 = getelementptr inbounds nuw %macro_def_t, ptr %ptr_deref41, i32 0, i32 4
  %ptr_deref43 = load ptr, ptr %mdef, align 8
  %mem_load44 = load i32, ptr %template_len42, align 4
  %icmp45 = icmp slt i32 %add40, %mem_load44
  %exp_len46 = load i32, ptr %exp_len, align 4
  %exp_cap47 = load i32, ptr %exp_cap, align 4
  %icmp48 = icmp sge i32 %exp_len46, %exp_cap47
  br i1 %icmp48, label %if_then49, label %if_merge50

while_exit30:                                     ; preds = %while_cond28
  %exp_len61 = load i32, ptr %exp_len, align 4
  %exp_cap62 = load i32, ptr %exp_cap, align 4
  %icmp63 = icmp sge i32 %exp_len61, %exp_cap62
  br i1 %icmp63, label %if_then64, label %if_merge65

if_then49:                                        ; preds = %while_body29
  %exp_cap51 = load i32, ptr %exp_cap, align 4
  %mul52 = mul i32 %exp_cap51, 2
  store i32 %mul52, ptr %exp_cap, align 4
  br label %if_merge50

if_merge50:                                       ; preds = %if_then49, %while_body29
  %exp_len53 = load i32, ptr %exp_len, align 4
  %ptr_load54 = load ptr, ptr %exp, align 8
  %ptr_gep55 = getelementptr i8, ptr %ptr_load54, i32 %exp_len53
  %tt56 = load i8, ptr %tt, align 1
  store i8 %tt56, ptr %ptr_gep55, align 1
  %exp_len57 = load i32, ptr %exp_len, align 4
  %add58 = add i32 %exp_len57, 1
  store i32 %add58, ptr %exp_len, align 4
  %ti59 = load i32, ptr %ti, align 4
  %add60 = add i32 %ti59, 1
  store i32 %add60, ptr %ti, align 4
  br label %while_cond28

if_then64:                                        ; preds = %while_exit30
  %exp_cap66 = load i32, ptr %exp_cap, align 4
  %add67 = add i32 %exp_cap66, 1
  store i32 %add67, ptr %exp_cap, align 4
  br label %if_merge65

if_merge65:                                       ; preds = %if_then64, %while_exit30
  %eoft = alloca i8, align 1
  store i8 0, ptr %eoft, align 1
  %exp_len68 = load i32, ptr %exp_len, align 4
  %ptr_load69 = load ptr, ptr %exp, align 8
  %ptr_gep70 = getelementptr i8, ptr %ptr_load69, i32 %exp_len68
  %eoft71 = load i8, ptr %eoft, align 1
  store i8 %eoft71, ptr %ptr_gep70, align 1
  %exp_len72 = load i32, ptr %exp_len, align 4
  %add73 = add i32 %exp_len72, 1
  store i32 %add73, ptr %exp_len, align 4
  %sub74 = alloca %parser_t, align 8
  store %parser_t zeroinitializer, ptr %sub74, align 8
  %exp75 = load ptr, ptr %exp, align 8
  %exp_len76 = load i32, ptr %exp_len, align 4
  call void @parser_t__NS_init(ptr %sub74, ptr %exp75, i32 %exp_len76)
  %macros = getelementptr inbounds nuw %parser_t, ptr %sub74, i32 0, i32 4
  %ptr_deref77 = load ptr, ptr %self, align 8
  %macros78 = getelementptr inbounds nuw %parser_t, ptr %ptr_deref77, i32 0, i32 4
  %ptr_deref79 = load ptr, ptr %self, align 8
  %mem_load80 = load ptr, ptr %macros78, align 8
  store ptr %mem_load80, ptr %macros, align 8
  %macros_len = getelementptr inbounds nuw %parser_t, ptr %sub74, i32 0, i32 5
  %ptr_deref81 = load ptr, ptr %self, align 8
  %macros_len82 = getelementptr inbounds nuw %parser_t, ptr %ptr_deref81, i32 0, i32 5
  %ptr_deref83 = load ptr, ptr %self, align 8
  %mem_load84 = load i32, ptr %macros_len82, align 4
  store i32 %mem_load84, ptr %macros_len, align 4
  %macros_cap = getelementptr inbounds nuw %parser_t, ptr %sub74, i32 0, i32 6
  %ptr_deref85 = load ptr, ptr %self, align 8
  %macros_cap86 = getelementptr inbounds nuw %parser_t, ptr %ptr_deref85, i32 0, i32 6
  %ptr_deref87 = load ptr, ptr %self, align 8
  %mem_load88 = load i32, ptr %macros_cap86, align 4
  store i32 %mem_load88, ptr %macros_cap, align 4
  %result = alloca ptr, align 8
  %8 = call ptr @parser_t__NS_parse_expr(ptr %sub74)
  store ptr %8, ptr %result, align 8
  %result89 = load ptr, ptr %result, align 8
  ret ptr %result89
}

define i8 @parser_t__NS_is_type_start(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %tt = alloca i32, align 4
  %1 = call i32 @parser_t__NS_peek_type(ptr %self)
  store i32 %1, ptr %tt, align 4
  %tt1 = load i32, ptr %tt, align 4
  %tt2 = load i32, ptr %tt, align 4
  %2 = call i32 @parser_t__NS_peek_at_type(ptr %self, i32 1)
  %tt3 = load i32, ptr %tt, align 4
  %tt4 = load i32, ptr %tt, align 4
  %tt5 = load i32, ptr %tt, align 4
  %tt6 = load i32, ptr %tt, align 4
  %tt7 = load i32, ptr %tt, align 4
  %tt8 = load i32, ptr %tt, align 4
  %tt9 = load i32, ptr %tt, align 4
  %tt10 = load i32, ptr %tt, align 4
  %tt11 = load i32, ptr %tt, align 4
  %tt12 = load i32, ptr %tt, align 4
  %tt13 = load i32, ptr %tt, align 4
  %tt14 = load i32, ptr %tt, align 4
  %tt15 = load i32, ptr %tt, align 4
  %tt16 = load i32, ptr %tt, align 4
  %tt17 = load i32, ptr %tt, align 4
  %tt18 = load i32, ptr %tt, align 4
  %tt19 = load i32, ptr %tt, align 4
  %tt20 = load i32, ptr %tt, align 4
  %tt21 = load i32, ptr %tt, align 4
  %tt22 = load i32, ptr %tt, align 4
  %tt23 = load i32, ptr %tt, align 4
  %tt24 = load i32, ptr %tt, align 4
  %3 = call i32 @parser_t__NS_peek_at_type(ptr %self, i32 1)
  %tt25 = load i32, ptr %tt, align 4
  %4 = call i32 @parser_t__NS_peek_at_type(ptr %self, i32 1)
  %tt26 = load i32, ptr %tt, align 4
  %tt27 = load i32, ptr %tt, align 4
  %5 = call i32 @parser_t__NS_peek_at_type(ptr %self, i32 1)
  ret i8 0
}

define i8 @parser_t__NS_is_cast_start(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %1 = call i8 @parser_t__NS_is_type_start(ptr %self)
  %if_cond = icmp ne i8 %1, 0
  br i1 %if_cond, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i8 1

if_merge:                                         ; preds = %entry
  %tt = alloca i32, align 4
  %2 = call i32 @parser_t__NS_peek_type(ptr %self)
  store i32 %2, ptr %tt, align 4
  %tt1 = load i32, ptr %tt, align 4
  ret i8 0
}

define ptr @parser_t__NS_parse_type(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %t = alloca ptr, align 8
  store ptr null, ptr %t, align 8
  %1 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %1, 0
  br i1 %if_cond, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %2 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %inner = alloca ptr, align 8
  %3 = call ptr @parser_t__NS_parse_type(ptr %self)
  store ptr %3, ptr %inner, align 8
  %inner1 = load ptr, ptr %inner, align 8
  ret ptr %inner1

if_merge:                                         ; preds = %entry
  %4 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond2 = icmp ne i8 %4, 0
  br i1 %if_cond2, label %if_then3, label %if_merge4

if_then3:                                         ; preds = %if_merge
  %5 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %inner5 = alloca ptr, align 8
  %6 = call ptr @parser_t__NS_parse_type(ptr %self)
  store ptr %6, ptr %inner5, align 8
  %inner6 = load ptr, ptr %inner5, align 8
  ret ptr %inner6

if_merge4:                                        ; preds = %if_merge
  %parsing_storage = alloca i8, align 1
  store i8 1, ptr %parsing_storage, align 1
  br label %while_cond

while_cond:                                       ; preds = %if_merge11, %if_merge4
  %parsing_storage7 = load i8, ptr %parsing_storage, align 1
  %while_cond8 = icmp ne i8 %parsing_storage7, 0
  br i1 %while_cond8, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %7 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond9 = icmp ne i8 %7, 0
  br i1 %if_cond9, label %if_then10, label %if_else

while_exit:                                       ; preds = %while_cond
  %parsing_qual = alloca i8, align 1
  store i8 1, ptr %parsing_qual, align 1
  br label %while_cond24

if_then10:                                        ; preds = %while_body
  br label %if_merge11

if_else:                                          ; preds = %while_body
  %8 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond12 = icmp ne i8 %8, 0
  br i1 %if_cond12, label %if_then13, label %if_else14

if_merge11:                                       ; preds = %if_merge15, %if_then10
  br label %while_cond

if_then13:                                        ; preds = %if_else
  br label %if_merge15

if_else14:                                        ; preds = %if_else
  %9 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond16 = icmp ne i8 %9, 0
  br i1 %if_cond16, label %if_then17, label %if_else18

if_merge15:                                       ; preds = %if_merge19, %if_then13
  br label %if_merge11

if_then17:                                        ; preds = %if_else14
  br label %if_merge19

if_else18:                                        ; preds = %if_else14
  %10 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond20 = icmp ne i8 %10, 0
  br i1 %if_cond20, label %if_then21, label %if_else22

if_merge19:                                       ; preds = %if_merge23, %if_then17
  br label %if_merge15

if_then21:                                        ; preds = %if_else18
  br label %if_merge23

if_else22:                                        ; preds = %if_else18
  store i8 0, ptr %parsing_storage, align 1
  br label %if_merge23

if_merge23:                                       ; preds = %if_else22, %if_then21
  br label %if_merge19

while_cond24:                                     ; preds = %if_merge32, %while_exit
  %parsing_qual27 = load i8, ptr %parsing_qual, align 1
  %while_cond28 = icmp ne i8 %parsing_qual27, 0
  br i1 %while_cond28, label %while_body25, label %while_exit26

while_body25:                                     ; preds = %while_cond24
  %11 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond29 = icmp ne i8 %11, 0
  br i1 %if_cond29, label %if_then30, label %if_else31

while_exit26:                                     ; preds = %while_cond24
  %12 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond37 = icmp ne i8 %12, 0
  br i1 %if_cond37, label %if_then38, label %if_merge39

if_then30:                                        ; preds = %while_body25
  br label %if_merge32

if_else31:                                        ; preds = %while_body25
  %13 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond33 = icmp ne i8 %13, 0
  br i1 %if_cond33, label %if_then34, label %if_else35

if_merge32:                                       ; preds = %if_merge36, %if_then30
  br label %while_cond24

if_then34:                                        ; preds = %if_else31
  br label %if_merge36

if_else35:                                        ; preds = %if_else31
  store i8 0, ptr %parsing_qual, align 1
  br label %if_merge36

if_merge36:                                       ; preds = %if_else35, %if_then34
  br label %if_merge32

if_then38:                                        ; preds = %while_exit26
  br label %if_merge39

if_merge39:                                       ; preds = %if_then38, %while_exit26
  %14 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond40 = icmp ne i8 %14, 0
  br i1 %if_cond40, label %if_then41, label %if_merge42

if_then41:                                        ; preds = %if_merge39
  br label %if_merge42

if_merge42:                                       ; preds = %if_then41, %if_merge39
  %15 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond43 = icmp ne i8 %15, 0
  br i1 %if_cond43, label %if_then44, label %if_merge45

if_then44:                                        ; preds = %if_merge42
  %16 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %t46 = load ptr, ptr %t, align 8
  ret ptr %t46

if_merge45:                                       ; preds = %if_merge42
  %17 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond47 = icmp ne i8 %17, 0
  br i1 %if_cond47, label %if_then48, label %if_merge49

if_then48:                                        ; preds = %if_merge45
  %18 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %while_cond50

if_merge49:                                       ; preds = %if_merge45
  %found = alloca i8, align 1
  store i8 0, ptr %found, align 1
  %19 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond55 = icmp ne i8 %19, 0
  br i1 %if_cond55, label %if_then56, label %if_else57

while_cond50:                                     ; preds = %while_body51, %if_then48
  %20 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %while_cond53 = icmp ne i8 %20, 0
  br i1 %while_cond53, label %while_body51, label %while_exit52

while_body51:                                     ; preds = %while_cond50
  %21 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %while_cond50

while_exit52:                                     ; preds = %while_cond50
  %t54 = load ptr, ptr %t, align 8
  ret ptr %t54

if_then56:                                        ; preds = %if_merge49
  store i8 1, ptr %found, align 1
  br label %if_merge58

if_else57:                                        ; preds = %if_merge49
  %22 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond59 = icmp ne i8 %22, 0
  br i1 %if_cond59, label %if_then60, label %if_else61

if_merge58:                                       ; preds = %if_merge62, %if_then56
  %found81 = load i8, ptr %found, align 1
  %tobool = icmp ne i8 %found81, 0
  %not = xor i1 %tobool, true
  %23 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %trunc = trunc i8 %23 to i1
  %land = and i1 %not, %trunc
  br i1 %land, label %if_then82, label %if_merge83

if_then60:                                        ; preds = %if_else57
  store i8 1, ptr %found, align 1
  br label %if_merge62

if_else61:                                        ; preds = %if_else57
  %24 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond63 = icmp ne i8 %24, 0
  br i1 %if_cond63, label %if_then64, label %if_else65

if_merge62:                                       ; preds = %if_merge66, %if_then60
  br label %if_merge58

if_then64:                                        ; preds = %if_else61
  %w = alloca i8, align 1
  %25 = call i8 @parser_t__NS_advance_tok(ptr %self)
  store i8 %25, ptr %w, align 1
  store i8 1, ptr %found, align 1
  br label %if_merge66

if_else65:                                        ; preds = %if_else61
  %26 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond67 = icmp ne i8 %26, 0
  br i1 %if_cond67, label %if_then68, label %if_else69

if_merge66:                                       ; preds = %if_merge70, %if_then64
  br label %if_merge62

if_then68:                                        ; preds = %if_else65
  %w71 = alloca i8, align 1
  %27 = call i8 @parser_t__NS_advance_tok(ptr %self)
  store i8 %27, ptr %w71, align 1
  store i8 1, ptr %found, align 1
  br label %if_merge70

if_else69:                                        ; preds = %if_else65
  %28 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond72 = icmp ne i8 %28, 0
  br i1 %if_cond72, label %if_then73, label %if_else74

if_merge70:                                       ; preds = %if_merge75, %if_then68
  br label %if_merge66

if_then73:                                        ; preds = %if_else69
  %w76 = alloca i8, align 1
  %29 = call i8 @parser_t__NS_advance_tok(ptr %self)
  store i8 %29, ptr %w76, align 1
  store i8 1, ptr %found, align 1
  br label %if_merge75

if_else74:                                        ; preds = %if_else69
  %30 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond77 = icmp ne i8 %30, 0
  br i1 %if_cond77, label %if_then78, label %if_merge79

if_merge75:                                       ; preds = %if_merge79, %if_then73
  br label %if_merge70

if_then78:                                        ; preds = %if_else74
  %w80 = alloca i8, align 1
  %31 = call i8 @parser_t__NS_advance_tok(ptr %self)
  store i8 %31, ptr %w80, align 1
  store i8 1, ptr %found, align 1
  br label %if_merge79

if_merge79:                                       ; preds = %if_then78, %if_else74
  br label %if_merge75

if_then82:                                        ; preds = %if_merge58
  %32 = call i8 @parser_t__NS_advance_tok(ptr %self)
  store i8 1, ptr %found, align 1
  br label %if_merge83

if_merge83:                                       ; preds = %if_then82, %if_merge58
  %found84 = load i8, ptr %found, align 1
  %tobool85 = icmp ne i8 %found84, 0
  %not86 = xor i1 %tobool85, true
  br i1 %not86, label %if_then87, label %if_merge88

if_then87:                                        ; preds = %if_merge83
  %name_tok = alloca i8, align 1
  %33 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.2)
  store i8 %33, ptr %name_tok, align 1
  %ns_loop = alloca i8, align 1
  store i8 1, ptr %ns_loop, align 1
  br label %while_cond89

if_merge88:                                       ; preds = %if_merge99, %if_merge83
  br label %while_cond108

while_cond89:                                     ; preds = %while_body90, %if_then87
  %ns_loop92 = load i8, ptr %ns_loop, align 1
  %34 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool93 = icmp ne i8 %ns_loop92, 0
  %tobool94 = icmp ne i8 %34, 0
  %land95 = and i1 %tobool93, %tobool94
  br i1 %land95, label %while_body90, label %while_exit91

while_body90:                                     ; preds = %while_cond89
  %next_type = alloca i32, align 4
  %35 = call i32 @parser_t__NS_peek_at_type(ptr %self, i32 1)
  store i32 %35, ptr %next_type, align 4
  %next_type96 = load i32, ptr %next_type, align 4
  br label %while_cond89

while_exit91:                                     ; preds = %while_cond89
  %36 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond97 = icmp ne i8 %36, 0
  br i1 %if_cond97, label %if_then98, label %if_merge99

if_then98:                                        ; preds = %while_exit91
  %depth_g = alloca i32, align 4
  store i32 1, ptr %depth_g, align 4
  %37 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %while_cond100

if_merge99:                                       ; preds = %while_exit102, %while_exit91
  br label %if_merge88

while_cond100:                                    ; preds = %while_body101, %if_then98
  %depth_g103 = load i32, ptr %depth_g, align 4
  %icmp = icmp sgt i32 %depth_g103, 0
  %38 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool104 = icmp ne i8 %38, 0
  %not105 = xor i1 %tobool104, true
  %land106 = and i1 %icmp, %not105
  br i1 %land106, label %while_body101, label %while_exit102

while_body101:                                    ; preds = %while_cond100
  %tg = alloca i32, align 4
  %39 = call i32 @parser_t__NS_peek_type(ptr %self)
  store i32 %39, ptr %tg, align 4
  %tg107 = load i32, ptr %tg, align 4
  br label %while_cond100

while_exit102:                                    ; preds = %while_cond100
  br label %if_merge99

while_cond108:                                    ; preds = %while_body109, %if_merge88
  %40 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %while_cond111 = icmp ne i8 %40, 0
  br i1 %while_cond111, label %while_body109, label %while_exit110

while_body109:                                    ; preds = %while_cond108
  %41 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %while_cond108

while_exit110:                                    ; preds = %while_cond108
  %42 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond112 = icmp ne i8 %42, 0
  br i1 %if_cond112, label %if_then113, label %if_merge114

if_then113:                                       ; preds = %while_exit110
  %saved = alloca i32, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %current = getelementptr inbounds nuw %parser_t, ptr %ptr_deref, i32 0, i32 2
  %ptr_deref115 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %current, align 4
  store i32 %mem_load, ptr %saved, align 4
  %43 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %fp_params = alloca i8, align 1
  store i8 0, ptr %fp_params, align 1
  %fp_names = alloca i8, align 1
  store i8 0, ptr %fp_names, align 1
  %fp_variadic = alloca i8, align 1
  store i8 0, ptr %fp_variadic, align 1
  %ok = alloca i8, align 1
  store i8 1, ptr %ok, align 1
  %44 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool116 = icmp ne i8 %44, 0
  %not117 = xor i1 %tobool116, true
  br i1 %not117, label %if_then118, label %if_merge119

if_merge114:                                      ; preds = %if_merge133, %while_exit110
  %45 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond143 = icmp ne i8 %45, 0
  br i1 %if_cond143, label %if_then144, label %if_merge145

if_then118:                                       ; preds = %if_then113
  %parsing_fp = alloca i8, align 1
  store i8 1, ptr %parsing_fp, align 1
  br label %while_cond120

if_merge119:                                      ; preds = %while_exit122, %if_then113
  %ok128 = load i8, ptr %ok, align 1
  %46 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool129 = icmp ne i8 %ok128, 0
  %tobool130 = icmp ne i8 %46, 0
  %land131 = and i1 %tobool129, %tobool130
  br i1 %land131, label %if_then132, label %if_merge133

while_cond120:                                    ; preds = %while_body121, %if_then118
  %ok123 = load i8, ptr %ok, align 1
  %parsing_fp124 = load i8, ptr %parsing_fp, align 1
  %tobool125 = icmp ne i8 %ok123, 0
  %tobool126 = icmp ne i8 %parsing_fp124, 0
  %land127 = and i1 %tobool125, %tobool126
  br i1 %land127, label %while_body121, label %while_exit122

while_body121:                                    ; preds = %while_cond120
  %47 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %48 = call i32 @parser_t__NS_peek_at_type(ptr %self, i32 1)
  %49 = call i32 @parser_t__NS_peek_at_type(ptr %self, i32 2)
  br label %while_cond120

while_exit122:                                    ; preds = %while_cond120
  br label %if_merge119

if_then132:                                       ; preds = %if_merge119
  %50 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %51 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond134 = icmp ne i8 %51, 0
  br i1 %if_cond134, label %if_then135, label %if_merge136

if_merge133:                                      ; preds = %if_merge136, %if_merge119
  %ptr_deref140 = load ptr, ptr %self, align 8
  %current141 = getelementptr inbounds nuw %parser_t, ptr %ptr_deref140, i32 0, i32 2
  %saved142 = load i32, ptr %saved, align 4
  store i32 %saved142, ptr %current141, align 4
  br label %if_merge114

if_then135:                                       ; preds = %if_then132
  %52 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %fp_t = alloca ptr, align 8
  store ptr null, ptr %fp_t, align 8
  %t137 = load ptr, ptr %t, align 8
  %fp_variadic138 = load i8, ptr %fp_variadic, align 1
  %fp_t139 = load ptr, ptr %fp_t, align 8
  ret ptr %fp_t139

if_merge136:                                      ; preds = %if_then132
  br label %if_merge133

if_then144:                                       ; preds = %if_merge114
  %53 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool146 = icmp ne i8 %53, 0
  %not147 = xor i1 %tobool146, true
  br i1 %not147, label %if_then148, label %if_merge149

if_merge145:                                      ; preds = %if_merge149, %if_merge114
  %t151 = load ptr, ptr %t, align 8
  ret ptr %t151

if_then148:                                       ; preds = %if_then144
  %sz = alloca ptr, align 8
  %54 = call ptr @parser_t__NS_parse_expr(ptr %self)
  store ptr %54, ptr %sz, align 8
  %sz150 = load ptr, ptr %sz, align 8
  br label %if_merge149

if_merge149:                                      ; preds = %if_then148, %if_then144
  %55 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.3)
  br label %if_merge145
}

define ptr @parser_t__NS_parse_var_body(ptr %0, ptr %1, i8 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ty = alloca ptr, align 8
  store ptr %1, ptr %ty, align 8
  %name_tok = alloca i8, align 1
  store i8 %2, ptr %name_tok, align 1
  %vd = alloca ptr, align 8
  store ptr null, ptr %vd, align 8
  %ptr_deref = load ptr, ptr %vd, align 8
  %kind = getelementptr inbounds nuw %var_decl, ptr %ptr_deref, i32 0, i32 0
  %nd_var_decl = load i32, ptr @ast_kind__nd_var_decl, align 4
  store i32 %nd_var_decl, ptr %kind, align 4
  %ptr_deref1 = load ptr, ptr %vd, align 8
  %line = getelementptr inbounds nuw %var_decl, ptr %ptr_deref1, i32 0, i32 1
  %ptr_deref2 = load ptr, ptr %vd, align 8
  %type = getelementptr inbounds nuw %var_decl, ptr %ptr_deref2, i32 0, i32 2
  %ty3 = load ptr, ptr %ty, align 8
  store ptr %ty3, ptr %type, align 8
  %ptr_deref4 = load ptr, ptr %vd, align 8
  %name = getelementptr inbounds nuw %var_decl, ptr %ptr_deref4, i32 0, i32 3
  %3 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %3, 0
  br i1 %if_cond, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %4 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool = icmp ne i8 %4, 0
  %not = xor i1 %tobool, true
  br i1 %not, label %if_then5, label %if_merge6

if_merge:                                         ; preds = %if_merge6, %entry
  %5 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond7 = icmp ne i8 %5, 0
  br i1 %if_cond7, label %if_then8, label %if_else

if_then5:                                         ; preds = %if_then
  %6 = call ptr @parser_t__NS_parse_expr(ptr %self)
  br label %if_merge6

if_merge6:                                        ; preds = %if_then5, %if_then
  %7 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.4)
  br label %if_merge

if_then8:                                         ; preds = %if_merge
  %ptr_deref10 = load ptr, ptr %vd, align 8
  %has_ctor_parens = getelementptr inbounds nuw %var_decl, ptr %ptr_deref10, i32 0, i32 9
  store i8 1, ptr %has_ctor_parens, align 1
  %ctor_cap = alloca i32, align 4
  store i32 4, ptr %ctor_cap, align 4
  %ptr_deref11 = load ptr, ptr %vd, align 8
  %ctor_args = getelementptr inbounds nuw %var_decl, ptr %ptr_deref11, i32 0, i32 10
  %ptr_deref12 = load ptr, ptr %vd, align 8
  %ctor_args_len = getelementptr inbounds nuw %var_decl, ptr %ptr_deref12, i32 0, i32 11
  store i32 0, ptr %ctor_args_len, align 4
  %8 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool13 = icmp ne i8 %8, 0
  %not14 = xor i1 %tobool13, true
  br i1 %not14, label %if_then15, label %if_merge16

if_else:                                          ; preds = %if_merge
  %9 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond44 = icmp ne i8 %9, 0
  br i1 %if_cond44, label %if_then45, label %if_else46

if_merge9:                                        ; preds = %if_merge47, %if_merge16
  %10 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.7)
  %vd99 = load ptr, ptr %vd, align 8
  ret ptr %vd99

if_then15:                                        ; preds = %if_then8
  %p_ctor = alloca i8, align 1
  store i8 1, ptr %p_ctor, align 1
  br label %while_cond

if_merge16:                                       ; preds = %while_exit, %if_then8
  %11 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.5)
  br label %if_merge9

while_cond:                                       ; preds = %if_merge43, %if_then15
  %p_ctor17 = load i8, ptr %p_ctor, align 1
  %while_cond18 = icmp ne i8 %p_ctor17, 0
  br i1 %while_cond18, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ptr_deref19 = load ptr, ptr %vd, align 8
  %ctor_args_len20 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref19, i32 0, i32 11
  %ptr_deref21 = load ptr, ptr %vd, align 8
  %mem_load = load i32, ptr %ctor_args_len20, align 4
  %ctor_cap22 = load i32, ptr %ctor_cap, align 4
  %icmp = icmp sge i32 %mem_load, %ctor_cap22
  br i1 %icmp, label %if_then23, label %if_merge24

while_exit:                                       ; preds = %while_cond
  br label %if_merge16

if_then23:                                        ; preds = %while_body
  %ctor_cap25 = load i32, ptr %ctor_cap, align 4
  %mul = mul i32 %ctor_cap25, 2
  store i32 %mul, ptr %ctor_cap, align 4
  %ptr_deref26 = load ptr, ptr %vd, align 8
  %ctor_args27 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref26, i32 0, i32 10
  br label %if_merge24

if_merge24:                                       ; preds = %if_then23, %while_body
  %ptr_deref28 = load ptr, ptr %vd, align 8
  %ctor_args29 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref28, i32 0, i32 10
  %ptr_deref30 = load ptr, ptr %vd, align 8
  %ctor_args_len31 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref30, i32 0, i32 11
  %ptr_deref32 = load ptr, ptr %vd, align 8
  %mem_load33 = load i32, ptr %ctor_args_len31, align 4
  %ptr_load = load ptr, ptr %ctor_args29, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load33
  %12 = call ptr @parser_t__NS_parse_assignment(ptr %self)
  store ptr %12, ptr %ptr_gep, align 8
  %ptr_deref34 = load ptr, ptr %vd, align 8
  %ctor_args_len35 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref34, i32 0, i32 11
  %ptr_deref36 = load ptr, ptr %vd, align 8
  %ctor_args_len37 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref36, i32 0, i32 11
  %ptr_deref38 = load ptr, ptr %vd, align 8
  %mem_load39 = load i32, ptr %ctor_args_len37, align 4
  %add = add i32 %mem_load39, 1
  store i32 %add, ptr %ctor_args_len35, align 4
  %13 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %tobool40 = icmp ne i8 %13, 0
  %not41 = xor i1 %tobool40, true
  br i1 %not41, label %if_then42, label %if_merge43

if_then42:                                        ; preds = %if_merge24
  store i8 0, ptr %p_ctor, align 1
  br label %if_merge43

if_merge43:                                       ; preds = %if_then42, %if_merge24
  br label %while_cond

if_then45:                                        ; preds = %if_else
  %ptr_deref48 = load ptr, ptr %vd, align 8
  %has_ctor_parens49 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref48, i32 0, i32 9
  store i8 1, ptr %has_ctor_parens49, align 1
  %ctor_capB = alloca i32, align 4
  store i32 4, ptr %ctor_capB, align 4
  %ptr_deref50 = load ptr, ptr %vd, align 8
  %ctor_args51 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref50, i32 0, i32 10
  %ptr_deref52 = load ptr, ptr %vd, align 8
  %ctor_args_len53 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref52, i32 0, i32 11
  store i32 0, ptr %ctor_args_len53, align 4
  %14 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool54 = icmp ne i8 %14, 0
  %not55 = xor i1 %tobool54, true
  br i1 %not55, label %if_then56, label %if_merge57

if_else46:                                        ; preds = %if_else
  %15 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond94 = icmp ne i8 %15, 0
  br i1 %if_cond94, label %if_then95, label %if_merge96

if_merge47:                                       ; preds = %if_merge96, %if_merge57
  br label %if_merge9

if_then56:                                        ; preds = %if_then45
  %p_ctorB = alloca i8, align 1
  store i8 1, ptr %p_ctorB, align 1
  br label %while_cond58

if_merge57:                                       ; preds = %while_exit60, %if_then45
  %16 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.6)
  br label %if_merge47

while_cond58:                                     ; preds = %if_merge93, %if_then56
  %p_ctorB61 = load i8, ptr %p_ctorB, align 1
  %while_cond62 = icmp ne i8 %p_ctorB61, 0
  br i1 %while_cond62, label %while_body59, label %while_exit60

while_body59:                                     ; preds = %while_cond58
  %ptr_deref63 = load ptr, ptr %vd, align 8
  %ctor_args_len64 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref63, i32 0, i32 11
  %ptr_deref65 = load ptr, ptr %vd, align 8
  %mem_load66 = load i32, ptr %ctor_args_len64, align 4
  %ctor_capB67 = load i32, ptr %ctor_capB, align 4
  %icmp68 = icmp sge i32 %mem_load66, %ctor_capB67
  br i1 %icmp68, label %if_then69, label %if_merge70

while_exit60:                                     ; preds = %while_cond58
  br label %if_merge57

if_then69:                                        ; preds = %while_body59
  %ctor_capB71 = load i32, ptr %ctor_capB, align 4
  %mul72 = mul i32 %ctor_capB71, 2
  store i32 %mul72, ptr %ctor_capB, align 4
  %ptr_deref73 = load ptr, ptr %vd, align 8
  %ctor_args74 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref73, i32 0, i32 10
  br label %if_merge70

if_merge70:                                       ; preds = %if_then69, %while_body59
  %ptr_deref75 = load ptr, ptr %vd, align 8
  %ctor_args76 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref75, i32 0, i32 10
  %ptr_deref77 = load ptr, ptr %vd, align 8
  %ctor_args_len78 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref77, i32 0, i32 11
  %ptr_deref79 = load ptr, ptr %vd, align 8
  %mem_load80 = load i32, ptr %ctor_args_len78, align 4
  %ptr_load81 = load ptr, ptr %ctor_args76, align 8
  %ptr_gep82 = getelementptr i8, ptr %ptr_load81, i32 %mem_load80
  %17 = call ptr @parser_t__NS_parse_assignment(ptr %self)
  store ptr %17, ptr %ptr_gep82, align 8
  %ptr_deref83 = load ptr, ptr %vd, align 8
  %ctor_args_len84 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref83, i32 0, i32 11
  %ptr_deref85 = load ptr, ptr %vd, align 8
  %ctor_args_len86 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref85, i32 0, i32 11
  %ptr_deref87 = load ptr, ptr %vd, align 8
  %mem_load88 = load i32, ptr %ctor_args_len86, align 4
  %add89 = add i32 %mem_load88, 1
  store i32 %add89, ptr %ctor_args_len84, align 4
  %18 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %tobool90 = icmp ne i8 %18, 0
  %not91 = xor i1 %tobool90, true
  br i1 %not91, label %if_then92, label %if_merge93

if_then92:                                        ; preds = %if_merge70
  store i8 0, ptr %p_ctorB, align 1
  br label %if_merge93

if_merge93:                                       ; preds = %if_then92, %if_merge70
  br label %while_cond58

if_then95:                                        ; preds = %if_else46
  %ptr_deref97 = load ptr, ptr %vd, align 8
  %init = getelementptr inbounds nuw %var_decl, ptr %ptr_deref97, i32 0, i32 4
  %19 = call ptr @parser_t__NS_parse_expr(ptr %self)
  store ptr %19, ptr %init, align 8
  %ptr_deref98 = load ptr, ptr %vd, align 8
  %has_init = getelementptr inbounds nuw %var_decl, ptr %ptr_deref98, i32 0, i32 5
  store i8 1, ptr %has_init, align 1
  br label %if_merge96

if_merge96:                                       ; preds = %if_then95, %if_else46
  br label %if_merge47
}

define ptr @parser_t__NS_parse_func_body(ptr %0, ptr %1, i8 %2, i8 %3) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ret = alloca ptr, align 8
  store ptr %1, ptr %ret, align 8
  %name_tok = alloca i8, align 1
  store i8 %2, ptr %name_tok, align 1
  %extern_c = alloca i8, align 1
  store i8 %3, ptr %extern_c, align 1
  %fd = alloca ptr, align 8
  store ptr null, ptr %fd, align 8
  %ptr_deref = load ptr, ptr %fd, align 8
  %kind = getelementptr inbounds nuw %func_decl, ptr %ptr_deref, i32 0, i32 0
  %nd_func_decl = load i32, ptr @ast_kind__nd_func_decl, align 4
  store i32 %nd_func_decl, ptr %kind, align 4
  %ptr_deref1 = load ptr, ptr %fd, align 8
  %line = getelementptr inbounds nuw %func_decl, ptr %ptr_deref1, i32 0, i32 1
  %ptr_deref2 = load ptr, ptr %fd, align 8
  %ret_type = getelementptr inbounds nuw %func_decl, ptr %ptr_deref2, i32 0, i32 2
  %ret3 = load ptr, ptr %ret, align 8
  store ptr %ret3, ptr %ret_type, align 8
  %ptr_deref4 = load ptr, ptr %fd, align 8
  %name = getelementptr inbounds nuw %func_decl, ptr %ptr_deref4, i32 0, i32 3
  %ptr_deref5 = load ptr, ptr %fd, align 8
  %is_extern_c = getelementptr inbounds nuw %func_decl, ptr %ptr_deref5, i32 0, i32 9
  %extern_c6 = load i8, ptr %extern_c, align 1
  store i8 %extern_c6, ptr %is_extern_c, align 1
  %ret7 = load ptr, ptr %ret, align 8
  %icmp = icmp ne ptr %ret7, null
  %params_cap = alloca i32, align 4
  store i32 8, ptr %params_cap, align 4
  %ptr_deref8 = load ptr, ptr %fd, align 8
  %params = getelementptr inbounds nuw %func_decl, ptr %ptr_deref8, i32 0, i32 4
  %ptr_deref9 = load ptr, ptr %fd, align 8
  %params_len = getelementptr inbounds nuw %func_decl, ptr %ptr_deref9, i32 0, i32 5
  store i32 0, ptr %params_len, align 4
  %4 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool = icmp ne i8 %4, 0
  %not = xor i1 %tobool, true
  br i1 %not, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %parsing_params = alloca i8, align 1
  store i8 1, ptr %parsing_params, align 1
  br label %while_cond

if_merge:                                         ; preds = %while_exit, %entry
  %5 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.8)
  br label %while_cond12

while_cond:                                       ; preds = %while_body, %if_then
  %parsing_params10 = load i8, ptr %parsing_params, align 1
  %while_cond11 = icmp ne i8 %parsing_params10, 0
  br i1 %while_cond11, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %6 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %7 = call i32 @parser_t__NS_peek_at_type(ptr %self, i32 1)
  %8 = call i32 @parser_t__NS_peek_at_type(ptr %self, i32 2)
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  br label %if_merge

while_cond12:                                     ; preds = %while_body13, %if_merge
  %9 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %while_cond15 = icmp ne i8 %9, 0
  br i1 %while_cond15, label %while_body13, label %while_exit14

while_body13:                                     ; preds = %while_cond12
  %10 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %ptr_deref16 = load ptr, ptr %fd, align 8
  %is_noexcept = getelementptr inbounds nuw %func_decl, ptr %ptr_deref16, i32 0, i32 12
  store i8 1, ptr %is_noexcept, align 1
  br label %while_cond12

while_exit14:                                     ; preds = %while_cond12
  %pm_skipped = alloca i8, align 1
  store i8 0, ptr %pm_skipped, align 1
  br label %while_cond17

while_cond17:                                     ; preds = %while_body18, %while_exit14
  %11 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %while_cond20 = icmp ne i8 %11, 0
  br i1 %while_cond20, label %while_body18, label %while_exit19

while_body18:                                     ; preds = %while_cond17
  %12 = call i8 @parser_t__NS_advance_tok(ptr %self)
  store i8 1, ptr %pm_skipped, align 1
  br label %while_cond17

while_exit19:                                     ; preds = %while_cond17
  %pm_skipped21 = load i8, ptr %pm_skipped, align 1
  %if_cond = icmp ne i8 %pm_skipped21, 0
  br i1 %if_cond, label %if_then22, label %if_merge23

if_then22:                                        ; preds = %while_exit19
  %13 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond24 = icmp ne i8 %13, 0
  br i1 %if_cond24, label %if_then25, label %if_else

if_merge23:                                       ; preds = %while_exit19
  %ret49 = load ptr, ptr %ret, align 8
  %icmp50 = icmp ne ptr %ret49, null
  %init_self_name = alloca ptr, align 8
  store ptr null, ptr %init_self_name, align 8
  %ptr_deref51 = load ptr, ptr %fd, align 8
  %params_len52 = getelementptr inbounds nuw %func_decl, ptr %ptr_deref51, i32 0, i32 5
  %ptr_deref53 = load ptr, ptr %fd, align 8
  %mem_load = load i32, ptr %params_len52, align 4
  %icmp54 = icmp sgt i32 %mem_load, 0
  %ptr_deref55 = load ptr, ptr %fd, align 8
  %params56 = getelementptr inbounds nuw %func_decl, ptr %ptr_deref55, i32 0, i32 4
  %ptr_load = load ptr, ptr %params56, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 0
  %init_cap = alloca i32, align 4
  store i32 8, ptr %init_cap, align 4
  %init_fnames = alloca ptr, align 8
  store ptr null, ptr %init_fnames, align 8
  %init_fexprs = alloca ptr, align 8
  store ptr null, ptr %init_fexprs, align 8
  %init_len = alloca i32, align 4
  store i32 0, ptr %init_len, align 4
  %14 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond57 = icmp ne i8 %14, 0
  br i1 %if_cond57, label %if_then58, label %if_merge59

if_then25:                                        ; preds = %if_then22
  %pm_depth = alloca i32, align 4
  store i32 1, ptr %pm_depth, align 4
  %15 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %while_cond27

if_else:                                          ; preds = %if_then22
  %16 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond43 = icmp ne i8 %16, 0
  br i1 %if_cond43, label %if_then44, label %if_merge45

if_merge26:                                       ; preds = %if_merge45, %while_exit29
  %ptr_deref46 = load ptr, ptr %fd, align 8
  %body = getelementptr inbounds nuw %func_decl, ptr %ptr_deref46, i32 0, i32 7
  store ptr null, ptr %body, align 8
  %ptr_deref47 = load ptr, ptr %fd, align 8
  %has_body = getelementptr inbounds nuw %func_decl, ptr %ptr_deref47, i32 0, i32 8
  store i8 0, ptr %has_body, align 1
  %fd48 = load ptr, ptr %fd, align 8
  ret ptr %fd48

while_cond27:                                     ; preds = %if_merge37, %if_then25
  %pm_depth30 = load i32, ptr %pm_depth, align 4
  %icmp31 = icmp sgt i32 %pm_depth30, 0
  %17 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool32 = icmp ne i8 %17, 0
  %not33 = xor i1 %tobool32, true
  %land = and i1 %icmp31, %not33
  br i1 %land, label %while_body28, label %while_exit29

while_body28:                                     ; preds = %while_cond27
  %18 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond34 = icmp ne i8 %18, 0
  br i1 %if_cond34, label %if_then35, label %if_else36

while_exit29:                                     ; preds = %while_cond27
  br label %if_merge26

if_then35:                                        ; preds = %while_body28
  %pm_depth38 = load i32, ptr %pm_depth, align 4
  %add = add i32 %pm_depth38, 1
  store i32 %add, ptr %pm_depth, align 4
  br label %if_merge37

if_else36:                                        ; preds = %while_body28
  %19 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond39 = icmp ne i8 %19, 0
  br i1 %if_cond39, label %if_then40, label %if_merge41

if_merge37:                                       ; preds = %if_merge41, %if_then35
  %20 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %while_cond27

if_then40:                                        ; preds = %if_else36
  %pm_depth42 = load i32, ptr %pm_depth, align 4
  %sub = sub i32 %pm_depth42, 1
  store i32 %sub, ptr %pm_depth, align 4
  br label %if_merge41

if_merge41:                                       ; preds = %if_then40, %if_else36
  br label %if_merge37

if_then44:                                        ; preds = %if_else
  %21 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %if_merge45

if_merge45:                                       ; preds = %if_then44, %if_else
  br label %if_merge26

if_then58:                                        ; preds = %if_merge23
  %22 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %p_init = alloca i8, align 1
  store i8 1, ptr %p_init, align 1
  br label %while_cond60

if_merge59:                                       ; preds = %while_exit62, %if_merge23
  %23 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond90 = icmp ne i8 %23, 0
  br i1 %if_cond90, label %if_then91, label %if_else92

while_cond60:                                     ; preds = %if_merge89, %if_then58
  %p_init63 = load i8, ptr %p_init, align 1
  %24 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool64 = icmp ne i8 %24, 0
  %not65 = xor i1 %tobool64, true
  %zext = zext i1 %not65 to i8
  %tobool66 = icmp ne i8 %p_init63, 0
  %tobool67 = icmp ne i8 %zext, 0
  %land68 = and i1 %tobool66, %tobool67
  %25 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %trunc = trunc i8 %25 to i1
  %land69 = and i1 %land68, %trunc
  br i1 %land69, label %while_body61, label %while_exit62

while_body61:                                     ; preds = %while_cond60
  %fname = alloca ptr, align 8
  store ptr null, ptr %fname, align 8
  %26 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.9)
  %fval = alloca ptr, align 8
  %27 = call ptr @parser_t__NS_parse_assignment(ptr %self)
  store ptr %27, ptr %fval, align 8
  %28 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.10)
  %init_len70 = load i32, ptr %init_len, align 4
  %init_cap71 = load i32, ptr %init_cap, align 4
  %icmp72 = icmp sge i32 %init_len70, %init_cap71
  br i1 %icmp72, label %if_then73, label %if_merge74

while_exit62:                                     ; preds = %while_cond60
  br label %if_merge59

if_then73:                                        ; preds = %while_body61
  %init_cap75 = load i32, ptr %init_cap, align 4
  %mul = mul i32 %init_cap75, 2
  store i32 %mul, ptr %init_cap, align 4
  br label %if_merge74

if_merge74:                                       ; preds = %if_then73, %while_body61
  %init_len76 = load i32, ptr %init_len, align 4
  %ptr_load77 = load ptr, ptr %init_fnames, align 8
  %ptr_gep78 = getelementptr ptr, ptr %ptr_load77, i32 %init_len76
  %fname79 = load ptr, ptr %fname, align 8
  store ptr %fname79, ptr %ptr_gep78, align 8
  %init_len80 = load i32, ptr %init_len, align 4
  %ptr_load81 = load ptr, ptr %init_fexprs, align 8
  %ptr_gep82 = getelementptr ptr, ptr %ptr_load81, i32 %init_len80
  %fval83 = load ptr, ptr %fval, align 8
  store ptr %fval83, ptr %ptr_gep82, align 8
  %init_len84 = load i32, ptr %init_len, align 4
  %add85 = add i32 %init_len84, 1
  store i32 %add85, ptr %init_len, align 4
  %29 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %tobool86 = icmp ne i8 %29, 0
  %not87 = xor i1 %tobool86, true
  br i1 %not87, label %if_then88, label %if_merge89

if_then88:                                        ; preds = %if_merge74
  store i8 0, ptr %p_init, align 1
  br label %if_merge89

if_merge89:                                       ; preds = %if_then88, %if_merge74
  br label %while_cond60

if_then91:                                        ; preds = %if_merge59
  %ptr_deref94 = load ptr, ptr %fd, align 8
  %body95 = getelementptr inbounds nuw %func_decl, ptr %ptr_deref94, i32 0, i32 7
  store ptr null, ptr %body95, align 8
  %ptr_deref96 = load ptr, ptr %fd, align 8
  %has_body97 = getelementptr inbounds nuw %func_decl, ptr %ptr_deref96, i32 0, i32 8
  store i8 0, ptr %has_body97, align 1
  br label %if_merge93

if_else92:                                        ; preds = %if_merge59
  %blk_nd = alloca ptr, align 8
  %30 = call ptr @parser_t__NS_parse_block(ptr %self)
  store ptr %30, ptr %blk_nd, align 8
  %blk_nd98 = load ptr, ptr %blk_nd, align 8
  %icmp99 = icmp ne ptr %blk_nd98, null
  %init_len100 = load i32, ptr %init_len, align 4
  %icmp101 = icmp sgt i32 %init_len100, 0
  %land102 = and i1 %icmp99, %icmp101
  br i1 %land102, label %if_then103, label %if_merge104

if_merge93:                                       ; preds = %if_merge104, %if_then91
  %fd168 = load ptr, ptr %fd, align 8
  ret ptr %fd168

if_then103:                                       ; preds = %if_else92
  %new_len = alloca i32, align 4
  %ptr_deref105 = load ptr, ptr %blk_nd, align 8
  %stmts_len = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref105, i32 0, i32 3
  %ptr_deref106 = load ptr, ptr %blk_nd, align 8
  %mem_load107 = load i32, ptr %stmts_len, align 4
  %init_len108 = load i32, ptr %init_len, align 4
  %add109 = add i32 %mem_load107, %init_len108
  store i32 %add109, ptr %new_len, align 4
  %new_stmts = alloca ptr, align 8
  store ptr null, ptr %new_stmts, align 8
  %ii = alloca i32, align 4
  store i32 0, ptr %ii, align 4
  br label %while_cond110

if_merge104:                                      ; preds = %while_exit138, %if_else92
  %ptr_deref163 = load ptr, ptr %fd, align 8
  %body164 = getelementptr inbounds nuw %func_decl, ptr %ptr_deref163, i32 0, i32 7
  %blk_nd165 = load ptr, ptr %blk_nd, align 8
  store ptr %blk_nd165, ptr %body164, align 8
  %ptr_deref166 = load ptr, ptr %fd, align 8
  %has_body167 = getelementptr inbounds nuw %func_decl, ptr %ptr_deref166, i32 0, i32 8
  store i8 1, ptr %has_body167, align 1
  br label %if_merge93

while_cond110:                                    ; preds = %while_body111, %if_then103
  %ii113 = load i32, ptr %ii, align 4
  %init_len114 = load i32, ptr %init_len, align 4
  %icmp115 = icmp slt i32 %ii113, %init_len114
  br i1 %icmp115, label %while_body111, label %while_exit112

while_body111:                                    ; preds = %while_cond110
  %self_id = alloca ptr, align 8
  store ptr null, ptr %self_id, align 8
  %init_self_name116 = load ptr, ptr %init_self_name, align 8
  %mem_e = alloca ptr, align 8
  store ptr null, ptr %mem_e, align 8
  %self_id117 = load ptr, ptr %self_id, align 8
  %ii118 = load i32, ptr %ii, align 4
  %ptr_load119 = load ptr, ptr %init_fnames, align 8
  %ptr_gep120 = getelementptr ptr, ptr %ptr_load119, i32 %ii118
  %idx_load = load ptr, ptr %ptr_gep120, align 8
  %asgn = alloca ptr, align 8
  store ptr null, ptr %asgn, align 8
  %mem_e121 = load ptr, ptr %mem_e, align 8
  %ii122 = load i32, ptr %ii, align 4
  %ptr_load123 = load ptr, ptr %init_fexprs, align 8
  %ptr_gep124 = getelementptr ptr, ptr %ptr_load123, i32 %ii122
  %idx_load125 = load ptr, ptr %ptr_gep124, align 8
  %es = alloca ptr, align 8
  store ptr null, ptr %es, align 8
  %ptr_deref126 = load ptr, ptr %es, align 8
  %kind127 = getelementptr inbounds nuw %expr_stmt, ptr %ptr_deref126, i32 0, i32 0
  %nd_expr_stmt = load i32, ptr @ast_kind__nd_expr_stmt, align 4
  store i32 %nd_expr_stmt, ptr %kind127, align 4
  %ptr_deref128 = load ptr, ptr %es, align 8
  %expr = getelementptr inbounds nuw %expr_stmt, ptr %ptr_deref128, i32 0, i32 2
  %asgn129 = load ptr, ptr %asgn, align 8
  store ptr %asgn129, ptr %expr, align 8
  %ii130 = load i32, ptr %ii, align 4
  %ptr_load131 = load ptr, ptr %new_stmts, align 8
  %ptr_gep132 = getelementptr ptr, ptr %ptr_load131, i32 %ii130
  %es133 = load ptr, ptr %es, align 8
  store ptr %es133, ptr %ptr_gep132, align 8
  %ii134 = load i32, ptr %ii, align 4
  %add135 = add i32 %ii134, 1
  store i32 %add135, ptr %ii, align 4
  br label %while_cond110

while_exit112:                                    ; preds = %while_cond110
  %si = alloca i32, align 4
  store i32 0, ptr %si, align 4
  br label %while_cond136

while_cond136:                                    ; preds = %while_body137, %while_exit112
  %si139 = load i32, ptr %si, align 4
  %ptr_deref140 = load ptr, ptr %blk_nd, align 8
  %stmts_len141 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref140, i32 0, i32 3
  %ptr_deref142 = load ptr, ptr %blk_nd, align 8
  %mem_load143 = load i32, ptr %stmts_len141, align 4
  %icmp144 = icmp slt i32 %si139, %mem_load143
  br i1 %icmp144, label %while_body137, label %while_exit138

while_body137:                                    ; preds = %while_cond136
  %init_len145 = load i32, ptr %init_len, align 4
  %si146 = load i32, ptr %si, align 4
  %add147 = add i32 %init_len145, %si146
  %ptr_load148 = load ptr, ptr %new_stmts, align 8
  %ptr_gep149 = getelementptr ptr, ptr %ptr_load148, i32 %add147
  %ptr_deref150 = load ptr, ptr %blk_nd, align 8
  %stmts = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref150, i32 0, i32 2
  %si151 = load i32, ptr %si, align 4
  %ptr_load152 = load ptr, ptr %stmts, align 8
  %ptr_gep153 = getelementptr i8, ptr %ptr_load152, i32 %si151
  %idx_load154 = load ptr, ptr %ptr_gep153, align 8
  store ptr %idx_load154, ptr %ptr_gep149, align 8
  %si155 = load i32, ptr %si, align 4
  %add156 = add i32 %si155, 1
  store i32 %add156, ptr %si, align 4
  br label %while_cond136

while_exit138:                                    ; preds = %while_cond136
  %ptr_deref157 = load ptr, ptr %blk_nd, align 8
  %stmts158 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref157, i32 0, i32 2
  %new_stmts159 = load ptr, ptr %new_stmts, align 8
  store ptr %new_stmts159, ptr %stmts158, align 8
  %ptr_deref160 = load ptr, ptr %blk_nd, align 8
  %stmts_len161 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref160, i32 0, i32 3
  %new_len162 = load i32, ptr %new_len, align 4
  store i32 %new_len162, ptr %stmts_len161, align 4
  br label %if_merge104
}

define ptr @parser_t__NS_parse_func_or_var_decl(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %is_cexpr = alloca i8, align 1
  store i8 0, ptr %is_cexpr, align 1
  %is_ceval = alloca i8, align 1
  store i8 0, ptr %is_ceval, align 1
  %1 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %1, 0
  br i1 %if_cond, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %2 = call i8 @parser_t__NS_advance_tok(ptr %self)
  store i8 1, ptr %is_cexpr, align 1
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  %3 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond1 = icmp ne i8 %3, 0
  br i1 %if_cond1, label %if_then2, label %if_merge3

if_then2:                                         ; preds = %if_merge
  %4 = call i8 @parser_t__NS_advance_tok(ptr %self)
  store i8 1, ptr %is_ceval, align 1
  br label %if_merge3

if_merge3:                                        ; preds = %if_then2, %if_merge
  %ret = alloca ptr, align 8
  %5 = call ptr @parser_t__NS_parse_type(ptr %self)
  store ptr %5, ptr %ret, align 8
  %is_err_union = alloca i8, align 1
  store i8 0, ptr %is_err_union, align 1
  %err_type = alloca ptr, align 8
  store ptr null, ptr %err_type, align 8
  %6 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %7 = call i32 @parser_t__NS_peek_at_type(ptr %self, i32 1)
  %8 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond4 = icmp ne i8 %8, 0
  br i1 %if_cond4, label %if_then5, label %if_merge6

if_then5:                                         ; preds = %if_merge3
  %9 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %op_name = alloca [64 x i8], align 1
  store [64 x i8] zeroinitializer, ptr %op_name, align 1
  %tt2 = alloca i32, align 4
  %10 = call i32 @parser_t__NS_peek_type(ptr %self)
  store i32 %10, ptr %tt2, align 4
  %op_tok = alloca i8, align 1
  %11 = call i8 @parser_t__NS_advance_tok(ptr %self)
  store i8 %11, ptr %op_tok, align 1
  %tt3 = alloca i32, align 4
  %12 = call i32 @parser_t__NS_peek_type(ptr %self)
  store i32 %12, ptr %tt3, align 4
  %tt27 = load i32, ptr %tt2, align 4
  %tt28 = load i32, ptr %tt2, align 4
  %tt29 = load i32, ptr %tt2, align 4
  %tt210 = load i32, ptr %tt2, align 4
  %tt211 = load i32, ptr %tt2, align 4
  %tt212 = load i32, ptr %tt2, align 4
  %tt213 = load i32, ptr %tt2, align 4
  %tt214 = load i32, ptr %tt2, align 4
  %tt315 = load i32, ptr %tt3, align 4
  %name_tok2 = alloca i8, align 1
  store i8 0, ptr %name_tok2, align 1
  %13 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.11)
  %fd2 = alloca ptr, align 8
  %ret16 = load ptr, ptr %ret, align 8
  %name_tok217 = load i8, ptr %name_tok2, align 1
  %14 = call ptr @parser_t__NS_parse_func_body(ptr %self, ptr %ret16, i8 %name_tok217, i8 0)
  store ptr %14, ptr %fd2, align 8
  %is_err_union18 = load i8, ptr %is_err_union, align 1
  %if_cond19 = icmp ne i8 %is_err_union18, 0
  br i1 %if_cond19, label %if_then20, label %if_merge21

if_merge6:                                        ; preds = %if_merge3
  %name_tok = alloca i8, align 1
  %15 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.12)
  store i8 %15, ptr %name_tok, align 1
  %gtp_buf = alloca ptr, align 8
  store ptr null, ptr %gtp_buf, align 8
  %gtp_len = alloca i32, align 4
  store i32 0, ptr %gtp_len, align 4
  %16 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond26 = icmp ne i8 %16, 0
  br i1 %if_cond26, label %if_then27, label %if_merge28

if_then20:                                        ; preds = %if_then5
  %ptr_deref = load ptr, ptr %fd2, align 8
  %is_error_union = getelementptr inbounds nuw %func_decl, ptr %ptr_deref, i32 0, i32 15
  store i8 1, ptr %is_error_union, align 1
  %ptr_deref22 = load ptr, ptr %fd2, align 8
  %err_type23 = getelementptr inbounds nuw %func_decl, ptr %ptr_deref22, i32 0, i32 16
  %err_type24 = load ptr, ptr %err_type, align 8
  store ptr %err_type24, ptr %err_type23, align 8
  br label %if_merge21

if_merge21:                                       ; preds = %if_then20, %if_then5
  %fd225 = load ptr, ptr %fd2, align 8
  ret ptr %fd225

if_then27:                                        ; preds = %if_merge6
  %gtp_cap = alloca i32, align 4
  store i32 4, ptr %gtp_cap, align 4
  %17 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %depth_gf = alloca i32, align 4
  store i32 1, ptr %depth_gf, align 4
  br label %while_cond

if_merge28:                                       ; preds = %while_exit, %if_merge6
  %18 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond33 = icmp ne i8 %18, 0
  br i1 %if_cond33, label %if_then34, label %if_merge35

while_cond:                                       ; preds = %while_body, %if_then27
  %depth_gf29 = load i32, ptr %depth_gf, align 4
  %icmp = icmp sgt i32 %depth_gf29, 0
  %19 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool = icmp ne i8 %19, 0
  %not = xor i1 %tobool, true
  %land = and i1 %icmp, %not
  br i1 %land, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %tgf = alloca i32, align 4
  %20 = call i32 @parser_t__NS_peek_type(ptr %self)
  store i32 %20, ptr %tgf, align 4
  %tgf30 = load i32, ptr %tgf, align 4
  %depth_gf31 = load i32, ptr %depth_gf, align 4
  %icmp32 = icmp eq i32 %depth_gf31, 1
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  br label %if_merge28

if_then34:                                        ; preds = %if_merge28
  %fd = alloca ptr, align 8
  %ret36 = load ptr, ptr %ret, align 8
  %name_tok37 = load i8, ptr %name_tok, align 1
  %21 = call ptr @parser_t__NS_parse_func_body(ptr %self, ptr %ret36, i8 %name_tok37, i8 0)
  store ptr %21, ptr %fd, align 8
  %gtp_len38 = load i32, ptr %gtp_len, align 4
  %icmp39 = icmp sgt i32 %gtp_len38, 0
  br i1 %icmp39, label %if_then40, label %if_else

if_merge35:                                       ; preds = %if_merge28
  %gtp_buf60 = load ptr, ptr %gtp_buf, align 8
  %icmp61 = icmp ne ptr %gtp_buf60, null
  br i1 %icmp61, label %if_then62, label %if_merge63

if_then40:                                        ; preds = %if_then34
  %ptr_deref42 = load ptr, ptr %fd, align 8
  %type_params = getelementptr inbounds nuw %func_decl, ptr %ptr_deref42, i32 0, i32 13
  %gtp_buf43 = load ptr, ptr %gtp_buf, align 8
  store ptr %gtp_buf43, ptr %type_params, align 8
  %ptr_deref44 = load ptr, ptr %fd, align 8
  %type_params_len = getelementptr inbounds nuw %func_decl, ptr %ptr_deref44, i32 0, i32 14
  %gtp_len45 = load i32, ptr %gtp_len, align 4
  store i32 %gtp_len45, ptr %type_params_len, align 4
  br label %if_merge41

if_else:                                          ; preds = %if_then34
  %gtp_buf46 = load ptr, ptr %gtp_buf, align 8
  %icmp47 = icmp ne ptr %gtp_buf46, null
  br i1 %icmp47, label %if_then48, label %if_merge49

if_merge41:                                       ; preds = %if_merge49, %if_then40
  %is_err_union50 = load i8, ptr %is_err_union, align 1
  %if_cond51 = icmp ne i8 %is_err_union50, 0
  br i1 %if_cond51, label %if_then52, label %if_merge53

if_then48:                                        ; preds = %if_else
  br label %if_merge49

if_merge49:                                       ; preds = %if_then48, %if_else
  br label %if_merge41

if_then52:                                        ; preds = %if_merge41
  %ptr_deref54 = load ptr, ptr %fd, align 8
  %is_error_union55 = getelementptr inbounds nuw %func_decl, ptr %ptr_deref54, i32 0, i32 15
  store i8 1, ptr %is_error_union55, align 1
  %ptr_deref56 = load ptr, ptr %fd, align 8
  %err_type57 = getelementptr inbounds nuw %func_decl, ptr %ptr_deref56, i32 0, i32 16
  %err_type58 = load ptr, ptr %err_type, align 8
  store ptr %err_type58, ptr %err_type57, align 8
  br label %if_merge53

if_merge53:                                       ; preds = %if_then52, %if_merge41
  %fd59 = load ptr, ptr %fd, align 8
  ret ptr %fd59

if_then62:                                        ; preds = %if_merge35
  br label %if_merge63

if_merge63:                                       ; preds = %if_then62, %if_merge35
  %22 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %vd = alloca ptr, align 8
  %ret64 = load ptr, ptr %ret, align 8
  %name_tok65 = load i8, ptr %name_tok, align 1
  %23 = call ptr @parser_t__NS_parse_var_body(ptr %self, ptr %ret64, i8 %name_tok65)
  store ptr %23, ptr %vd, align 8
  %ptr_deref66 = load ptr, ptr %vd, align 8
  %is_constexpr = getelementptr inbounds nuw %var_decl, ptr %ptr_deref66, i32 0, i32 6
  %is_cexpr67 = load i8, ptr %is_cexpr, align 1
  store i8 %is_cexpr67, ptr %is_constexpr, align 1
  %ptr_deref68 = load ptr, ptr %vd, align 8
  %is_consteval = getelementptr inbounds nuw %var_decl, ptr %ptr_deref68, i32 0, i32 7
  %is_ceval69 = load i8, ptr %is_ceval, align 1
  store i8 %is_ceval69, ptr %is_consteval, align 1
  %vd70 = load ptr, ptr %vd, align 8
  ret ptr %vd70
}

define ptr @parser_t__NS_parse_func_or_var_decl_extern_c(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ret = alloca ptr, align 8
  %1 = call ptr @parser_t__NS_parse_type(ptr %self)
  store ptr %1, ptr %ret, align 8
  %name_tok = alloca i8, align 1
  %2 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.13)
  store i8 %2, ptr %name_tok, align 1
  %3 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %3, 0
  br i1 %if_cond, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %fd = alloca ptr, align 8
  %ret1 = load ptr, ptr %ret, align 8
  %name_tok2 = load i8, ptr %name_tok, align 1
  %4 = call ptr @parser_t__NS_parse_func_body(ptr %self, ptr %ret1, i8 %name_tok2, i8 1)
  store ptr %4, ptr %fd, align 8
  %ptr_deref = load ptr, ptr %fd, align 8
  %is_extern_c = getelementptr inbounds nuw %func_decl, ptr %ptr_deref, i32 0, i32 9
  store i8 1, ptr %is_extern_c, align 1
  %fd3 = load ptr, ptr %fd, align 8
  ret ptr %fd3

if_merge:                                         ; preds = %entry
  %ret4 = load ptr, ptr %ret, align 8
  %name_tok5 = load i8, ptr %name_tok, align 1
  %5 = call ptr @parser_t__NS_parse_var_body(ptr %self, ptr %ret4, i8 %name_tok5)
  ret ptr %5
}

define ptr @parser_t__NS_parse_struct_decl(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ln = alloca i64, align 8
  %1 = call i64 @parser_t__NS_peek_line(ptr %self)
  store i64 %1, ptr %ln, align 4
  %2 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %sd = alloca ptr, align 8
  store ptr null, ptr %sd, align 8
  %ptr_deref = load ptr, ptr %sd, align 8
  %kind = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref, i32 0, i32 0
  %nd_struct_decl = load i32, ptr @ast_kind__nd_struct_decl, align 4
  store i32 %nd_struct_decl, ptr %kind, align 4
  %ptr_deref1 = load ptr, ptr %sd, align 8
  %line = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref1, i32 0, i32 1
  %ln2 = load i64, ptr %ln, align 4
  store i64 %ln2, ptr %line, align 4
  %ptr_deref3 = load ptr, ptr %sd, align 8
  %name = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref3, i32 0, i32 2
  %ptr_deref4 = load ptr, ptr %sd, align 8
  %fields_cap = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref4, i32 0, i32 5
  store i32 8, ptr %fields_cap, align 4
  %ptr_deref5 = load ptr, ptr %sd, align 8
  %fields = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref5, i32 0, i32 3
  %3 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.14)
  br label %while_cond

while_cond:                                       ; preds = %if_merge27, %entry
  %4 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool = icmp ne i8 %4, 0
  %not = xor i1 %tobool, true
  %5 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool6 = icmp ne i8 %5, 0
  %not7 = xor i1 %tobool6, true
  %land = and i1 %not, %not7
  br i1 %land, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ft = alloca ptr, align 8
  %6 = call ptr @parser_t__NS_parse_type(ptr %self)
  store ptr %6, ptr %ft, align 8
  %fname = alloca i8, align 1
  %7 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.15)
  store i8 %7, ptr %fname, align 1
  %vd = alloca ptr, align 8
  store ptr null, ptr %vd, align 8
  %ptr_deref8 = load ptr, ptr %vd, align 8
  %kind9 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref8, i32 0, i32 0
  %nd_var_decl = load i32, ptr @ast_kind__nd_var_decl, align 4
  store i32 %nd_var_decl, ptr %kind9, align 4
  %ptr_deref10 = load ptr, ptr %vd, align 8
  %line11 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref10, i32 0, i32 1
  %ptr_deref12 = load ptr, ptr %vd, align 8
  %type = getelementptr inbounds nuw %var_decl, ptr %ptr_deref12, i32 0, i32 2
  %ft13 = load ptr, ptr %ft, align 8
  store ptr %ft13, ptr %type, align 8
  %ptr_deref14 = load ptr, ptr %vd, align 8
  %name15 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref14, i32 0, i32 3
  %8 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %8, 0
  br i1 %if_cond, label %if_then, label %if_merge

while_exit:                                       ; preds = %while_cond
  %9 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.18)
  %sd49 = load ptr, ptr %sd, align 8
  ret ptr %sd49

if_then:                                          ; preds = %while_body
  %10 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool16 = icmp ne i8 %10, 0
  %not17 = xor i1 %tobool16, true
  br i1 %not17, label %if_then18, label %if_merge19

if_merge:                                         ; preds = %if_merge19, %while_body
  %11 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.17)
  %ptr_deref20 = load ptr, ptr %sd, align 8
  %fields_len = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref20, i32 0, i32 4
  %ptr_deref21 = load ptr, ptr %sd, align 8
  %mem_load = load i32, ptr %fields_len, align 4
  %ptr_deref22 = load ptr, ptr %sd, align 8
  %fields_cap23 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref22, i32 0, i32 5
  %ptr_deref24 = load ptr, ptr %sd, align 8
  %mem_load25 = load i32, ptr %fields_cap23, align 4
  %icmp = icmp sge i32 %mem_load, %mem_load25
  br i1 %icmp, label %if_then26, label %if_merge27

if_then18:                                        ; preds = %if_then
  %12 = call ptr @parser_t__NS_parse_expr(ptr %self)
  br label %if_merge19

if_merge19:                                       ; preds = %if_then18, %if_then
  %13 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.16)
  br label %if_merge

if_then26:                                        ; preds = %if_merge
  %ptr_deref28 = load ptr, ptr %sd, align 8
  %fields_cap29 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref28, i32 0, i32 5
  %ptr_deref30 = load ptr, ptr %sd, align 8
  %fields_cap31 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref30, i32 0, i32 5
  %ptr_deref32 = load ptr, ptr %sd, align 8
  %mem_load33 = load i32, ptr %fields_cap31, align 4
  %mul = mul i32 %mem_load33, 2
  store i32 %mul, ptr %fields_cap29, align 4
  %ptr_deref34 = load ptr, ptr %sd, align 8
  %fields35 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref34, i32 0, i32 3
  br label %if_merge27

if_merge27:                                       ; preds = %if_then26, %if_merge
  %ptr_deref36 = load ptr, ptr %sd, align 8
  %fields37 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref36, i32 0, i32 3
  %ptr_deref38 = load ptr, ptr %sd, align 8
  %fields_len39 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref38, i32 0, i32 4
  %ptr_deref40 = load ptr, ptr %sd, align 8
  %mem_load41 = load i32, ptr %fields_len39, align 4
  %ptr_load = load ptr, ptr %fields37, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load41
  %vd42 = load ptr, ptr %vd, align 8
  store ptr %vd42, ptr %ptr_gep, align 8
  %ptr_deref43 = load ptr, ptr %sd, align 8
  %fields_len44 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref43, i32 0, i32 4
  %ptr_deref45 = load ptr, ptr %sd, align 8
  %fields_len46 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref45, i32 0, i32 4
  %ptr_deref47 = load ptr, ptr %sd, align 8
  %mem_load48 = load i32, ptr %fields_len46, align 4
  %add = add i32 %mem_load48, 1
  store i32 %add, ptr %fields_len44, align 4
  br label %while_cond
}

define ptr @parser_t__NS_parse_enum_decl(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ln = alloca i64, align 8
  %1 = call i64 @parser_t__NS_peek_line(ptr %self)
  store i64 %1, ptr %ln, align 4
  %2 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %ed = alloca ptr, align 8
  store ptr null, ptr %ed, align 8
  %ptr_deref = load ptr, ptr %ed, align 8
  %kind = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref, i32 0, i32 0
  %nd_enum_decl = load i32, ptr @ast_kind__nd_enum_decl, align 4
  store i32 %nd_enum_decl, ptr %kind, align 4
  %ptr_deref1 = load ptr, ptr %ed, align 8
  %line = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref1, i32 0, i32 1
  %ln2 = load i64, ptr %ln, align 4
  store i64 %ln2, ptr %line, align 4
  %ptr_deref3 = load ptr, ptr %ed, align 8
  %name = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref3, i32 0, i32 2
  %ptr_deref4 = load ptr, ptr %ed, align 8
  %variants_cap = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref4, i32 0, i32 7
  store i32 16, ptr %variants_cap, align 4
  %ptr_deref5 = load ptr, ptr %ed, align 8
  %variant_names = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref5, i32 0, i32 3
  %ptr_deref6 = load ptr, ptr %ed, align 8
  %variant_vals = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref6, i32 0, i32 4
  %ptr_deref7 = load ptr, ptr %ed, align 8
  %variant_has_val = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref7, i32 0, i32 5
  %ptr_deref8 = load ptr, ptr %ed, align 8
  %variant_kinds = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref8, i32 0, i32 9
  %ptr_deref9 = load ptr, ptr %ed, align 8
  %variant_field_counts = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref9, i32 0, i32 10
  %ptr_deref10 = load ptr, ptr %ed, align 8
  %variant_field_names_flat = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref10, i32 0, i32 11
  %ptr_deref11 = load ptr, ptr %ed, align 8
  %variant_field_type_flat = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref11, i32 0, i32 12
  %ptr_deref12 = load ptr, ptr %ed, align 8
  %variant_method_flat = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref12, i32 0, i32 13
  %ptr_deref13 = load ptr, ptr %ed, align 8
  %variant_method_counts = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref13, i32 0, i32 14
  %3 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.19)
  %next_val = alloca i64, align 8
  store i64 0, ptr %next_val, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge320, %entry
  %4 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool = icmp ne i8 %4, 0
  %not = xor i1 %tobool, true
  %5 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool14 = icmp ne i8 %5, 0
  %not15 = xor i1 %tobool14, true
  %land = and i1 %not, %not15
  br i1 %land, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %var_name = alloca i8, align 1
  %6 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.20)
  store i8 %6, ptr %var_name, align 1
  %ptr_deref16 = load ptr, ptr %ed, align 8
  %variants_len = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref16, i32 0, i32 6
  %ptr_deref17 = load ptr, ptr %ed, align 8
  %mem_load = load i32, ptr %variants_len, align 4
  %ptr_deref18 = load ptr, ptr %ed, align 8
  %variants_cap19 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref18, i32 0, i32 7
  %ptr_deref20 = load ptr, ptr %ed, align 8
  %mem_load21 = load i32, ptr %variants_cap19, align 4
  %icmp = icmp sge i32 %mem_load, %mem_load21
  br i1 %icmp, label %if_then, label %if_merge

while_exit:                                       ; preds = %while_cond
  %7 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.25)
  %ed321 = load ptr, ptr %ed, align 8
  ret ptr %ed321

if_then:                                          ; preds = %while_body
  %ptr_deref22 = load ptr, ptr %ed, align 8
  %variants_cap23 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref22, i32 0, i32 7
  %ptr_deref24 = load ptr, ptr %ed, align 8
  %variants_cap25 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref24, i32 0, i32 7
  %ptr_deref26 = load ptr, ptr %ed, align 8
  %mem_load27 = load i32, ptr %variants_cap25, align 4
  %mul = mul i32 %mem_load27, 2
  store i32 %mul, ptr %variants_cap23, align 4
  %ptr_deref28 = load ptr, ptr %ed, align 8
  %variant_names29 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref28, i32 0, i32 3
  %ptr_deref30 = load ptr, ptr %ed, align 8
  %variant_vals31 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref30, i32 0, i32 4
  %ptr_deref32 = load ptr, ptr %ed, align 8
  %variant_has_val33 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref32, i32 0, i32 5
  %ptr_deref34 = load ptr, ptr %ed, align 8
  %variant_kinds35 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref34, i32 0, i32 9
  %ptr_deref36 = load ptr, ptr %ed, align 8
  %variant_field_counts37 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref36, i32 0, i32 10
  %ptr_deref38 = load ptr, ptr %ed, align 8
  %variant_field_names_flat39 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref38, i32 0, i32 11
  %ptr_deref40 = load ptr, ptr %ed, align 8
  %variant_field_type_flat41 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref40, i32 0, i32 12
  %ptr_deref42 = load ptr, ptr %ed, align 8
  %variant_method_flat43 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref42, i32 0, i32 13
  %ptr_deref44 = load ptr, ptr %ed, align 8
  %variant_method_counts45 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref44, i32 0, i32 14
  br label %if_merge

if_merge:                                         ; preds = %if_then, %while_body
  %vi = alloca i32, align 4
  %ptr_deref46 = load ptr, ptr %ed, align 8
  %variants_len47 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref46, i32 0, i32 6
  %ptr_deref48 = load ptr, ptr %ed, align 8
  %mem_load49 = load i32, ptr %variants_len47, align 4
  store i32 %mem_load49, ptr %vi, align 4
  %ptr_deref50 = load ptr, ptr %ed, align 8
  %variant_names51 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref50, i32 0, i32 3
  %vi52 = load i32, ptr %vi, align 4
  %ptr_load = load ptr, ptr %variant_names51, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %vi52
  %ptr_deref53 = load ptr, ptr %ed, align 8
  %variant_kinds54 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref53, i32 0, i32 9
  %vi55 = load i32, ptr %vi, align 4
  %ptr_load56 = load ptr, ptr %variant_kinds54, align 8
  %ptr_gep57 = getelementptr i8, ptr %ptr_load56, i32 %vi55
  store ptr null, ptr %ptr_gep57, align 8
  %ptr_deref58 = load ptr, ptr %ed, align 8
  %variant_field_counts59 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref58, i32 0, i32 10
  %vi60 = load i32, ptr %vi, align 4
  %ptr_load61 = load ptr, ptr %variant_field_counts59, align 8
  %ptr_gep62 = getelementptr i8, ptr %ptr_load61, i32 %vi60
  store ptr null, ptr %ptr_gep62, align 8
  %ptr_deref63 = load ptr, ptr %ed, align 8
  %variant_method_counts64 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref63, i32 0, i32 14
  %vi65 = load i32, ptr %vi, align 4
  %ptr_load66 = load ptr, ptr %variant_method_counts64, align 8
  %ptr_gep67 = getelementptr i8, ptr %ptr_load66, i32 %vi65
  store ptr null, ptr %ptr_gep67, align 8
  %si = alloca i32, align 4
  store i32 0, ptr %si, align 4
  br label %while_cond68

while_cond68:                                     ; preds = %while_body69, %if_merge
  %si71 = load i32, ptr %si, align 4
  %icmp72 = icmp slt i32 %si71, 8
  br i1 %icmp72, label %while_body69, label %while_exit70

while_body69:                                     ; preds = %while_cond68
  %ptr_deref73 = load ptr, ptr %ed, align 8
  %variant_field_names_flat74 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref73, i32 0, i32 11
  %vi75 = load i32, ptr %vi, align 4
  %mul76 = mul i32 %vi75, 8
  %si77 = load i32, ptr %si, align 4
  %add = add i32 %mul76, %si77
  %ptr_load78 = load ptr, ptr %variant_field_names_flat74, align 8
  %ptr_gep79 = getelementptr i8, ptr %ptr_load78, i32 %add
  store ptr null, ptr %ptr_gep79, align 8
  %ptr_deref80 = load ptr, ptr %ed, align 8
  %variant_field_type_flat81 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref80, i32 0, i32 12
  %vi82 = load i32, ptr %vi, align 4
  %mul83 = mul i32 %vi82, 8
  %si84 = load i32, ptr %si, align 4
  %add85 = add i32 %mul83, %si84
  %ptr_load86 = load ptr, ptr %variant_field_type_flat81, align 8
  %ptr_gep87 = getelementptr i8, ptr %ptr_load86, i32 %add85
  store ptr null, ptr %ptr_gep87, align 8
  %ptr_deref88 = load ptr, ptr %ed, align 8
  %variant_method_flat89 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref88, i32 0, i32 13
  %vi90 = load i32, ptr %vi, align 4
  %mul91 = mul i32 %vi90, 8
  %si92 = load i32, ptr %si, align 4
  %add93 = add i32 %mul91, %si92
  %ptr_load94 = load ptr, ptr %variant_method_flat89, align 8
  %ptr_gep95 = getelementptr i8, ptr %ptr_load94, i32 %add93
  store ptr null, ptr %ptr_gep95, align 8
  %si96 = load i32, ptr %si, align 4
  %add97 = add i32 %si96, 1
  store i32 %add97, ptr %si, align 4
  br label %while_cond68

while_exit70:                                     ; preds = %while_cond68
  %8 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %8, 0
  br i1 %if_cond, label %if_then98, label %if_merge99

if_then98:                                        ; preds = %while_exit70
  %9 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %ptr_deref100 = load ptr, ptr %ed, align 8
  %variant_kinds101 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref100, i32 0, i32 9
  %vi102 = load i32, ptr %vi, align 4
  %ptr_load103 = load ptr, ptr %variant_kinds101, align 8
  %ptr_gep104 = getelementptr i8, ptr %ptr_load103, i32 %vi102
  store ptr inttoptr (i64 1 to ptr), ptr %ptr_gep104, align 8
  %ptr_deref105 = load ptr, ptr %ed, align 8
  %is_adt = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref105, i32 0, i32 8
  store i8 1, ptr %is_adt, align 1
  %fc = alloca i32, align 4
  store i32 0, ptr %fc, align 4
  br label %while_cond106

if_merge99:                                       ; preds = %while_exit108, %while_exit70
  %has_dot_brace = alloca i8, align 1
  %10 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  store i8 %10, ptr %has_dot_brace, align 1
  %has_dot_brace142 = load i8, ptr %has_dot_brace, align 1
  %if_cond143 = icmp ne i8 %has_dot_brace142, 0
  br i1 %if_cond143, label %if_then144, label %if_merge145

while_cond106:                                    ; preds = %while_body107, %if_then98
  %11 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool109 = icmp ne i8 %11, 0
  %not110 = xor i1 %tobool109, true
  %12 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool111 = icmp ne i8 %12, 0
  %not112 = xor i1 %tobool111, true
  %land113 = and i1 %not110, %not112
  %fc114 = load i32, ptr %fc, align 4
  %icmp115 = icmp slt i32 %fc114, 8
  %land116 = and i1 %land113, %icmp115
  br i1 %land116, label %while_body107, label %while_exit108

while_body107:                                    ; preds = %while_cond106
  %ft = alloca ptr, align 8
  %13 = call ptr @parser_t__NS_parse_type(ptr %self)
  store ptr %13, ptr %ft, align 8
  %ptr_deref117 = load ptr, ptr %ed, align 8
  %variant_field_type_flat118 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref117, i32 0, i32 12
  %vi119 = load i32, ptr %vi, align 4
  %mul120 = mul i32 %vi119, 8
  %fc121 = load i32, ptr %fc, align 4
  %add122 = add i32 %mul120, %fc121
  %ptr_load123 = load ptr, ptr %variant_field_type_flat118, align 8
  %ptr_gep124 = getelementptr i8, ptr %ptr_load123, i32 %add122
  %ft125 = load ptr, ptr %ft, align 8
  store ptr %ft125, ptr %ptr_gep124, align 8
  %ptr_deref126 = load ptr, ptr %ed, align 8
  %variant_field_names_flat127 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref126, i32 0, i32 11
  %vi128 = load i32, ptr %vi, align 4
  %mul129 = mul i32 %vi128, 8
  %fc130 = load i32, ptr %fc, align 4
  %add131 = add i32 %mul129, %fc130
  %ptr_load132 = load ptr, ptr %variant_field_names_flat127, align 8
  %ptr_gep133 = getelementptr i8, ptr %ptr_load132, i32 %add131
  store ptr null, ptr %ptr_gep133, align 8
  %fc134 = load i32, ptr %fc, align 4
  %add135 = add i32 %fc134, 1
  store i32 %add135, ptr %fc, align 4
  %14 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  br label %while_cond106

while_exit108:                                    ; preds = %while_cond106
  %15 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.21)
  %ptr_deref136 = load ptr, ptr %ed, align 8
  %variant_field_counts137 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref136, i32 0, i32 10
  %vi138 = load i32, ptr %vi, align 4
  %ptr_load139 = load ptr, ptr %variant_field_counts137, align 8
  %ptr_gep140 = getelementptr i8, ptr %ptr_load139, i32 %vi138
  %fc141 = load i32, ptr %fc, align 4
  %i2p = inttoptr i32 %fc141 to ptr
  store ptr %i2p, ptr %ptr_gep140, align 8
  br label %if_merge99

if_then144:                                       ; preds = %if_merge99
  %16 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %if_merge145

if_merge145:                                      ; preds = %if_then144, %if_merge99
  %17 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond146 = icmp ne i8 %17, 0
  br i1 %if_cond146, label %if_then147, label %if_merge148

if_then147:                                       ; preds = %if_merge145
  %18 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %ptr_deref149 = load ptr, ptr %ed, align 8
  %is_adt150 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref149, i32 0, i32 8
  store i8 1, ptr %is_adt150, align 1
  %ptr_deref151 = load ptr, ptr %ed, align 8
  %variant_kinds152 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref151, i32 0, i32 9
  %vi153 = load i32, ptr %vi, align 4
  %ptr_load154 = load ptr, ptr %variant_kinds152, align 8
  %ptr_gep155 = getelementptr i8, ptr %ptr_load154, i32 %vi153
  %has_dot_brace156 = load i8, ptr %has_dot_brace, align 1
  %tobool157 = icmp ne i8 %has_dot_brace156, 0
  br i1 %tobool157, label %tern_then, label %tern_else

if_merge148:                                      ; preds = %while_exit162, %if_merge145
  %19 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond280 = icmp ne i8 %19, 0
  br i1 %if_cond280, label %if_then281, label %if_else282

tern_then:                                        ; preds = %if_then147
  br label %tern_merge

tern_else:                                        ; preds = %if_then147
  br label %tern_merge

tern_merge:                                       ; preds = %tern_else, %tern_then
  %tern = phi i64 [ 3, %tern_then ], [ 2, %tern_else ]
  %i2p158 = inttoptr i64 %tern to ptr
  store ptr %i2p158, ptr %ptr_gep155, align 8
  %fc159 = alloca i32, align 4
  store i32 0, ptr %fc159, align 4
  %depth_vs = alloca i32, align 4
  store i32 1, ptr %depth_vs, align 4
  br label %while_cond160

while_cond160:                                    ; preds = %if_merge170, %tern_merge
  %depth_vs163 = load i32, ptr %depth_vs, align 4
  %icmp164 = icmp sgt i32 %depth_vs163, 0
  %20 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool165 = icmp ne i8 %20, 0
  %not166 = xor i1 %tobool165, true
  %land167 = and i1 %icmp164, %not166
  br i1 %land167, label %while_body161, label %while_exit162

while_body161:                                    ; preds = %while_cond160
  %21 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond168 = icmp ne i8 %21, 0
  br i1 %if_cond168, label %if_then169, label %if_else

while_exit162:                                    ; preds = %if_else181, %while_cond160
  %22 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.23)
  %ptr_deref273 = load ptr, ptr %ed, align 8
  %variant_field_counts274 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref273, i32 0, i32 10
  %vi275 = load i32, ptr %vi, align 4
  %ptr_load276 = load ptr, ptr %variant_field_counts274, align 8
  %ptr_gep277 = getelementptr i8, ptr %ptr_load276, i32 %vi275
  %fc278 = load i32, ptr %fc159, align 4
  %i2p279 = inttoptr i32 %fc278 to ptr
  store ptr %i2p279, ptr %ptr_gep277, align 8
  br label %if_merge148

if_then169:                                       ; preds = %while_body161
  %depth_vs171 = load i32, ptr %depth_vs, align 4
  %add172 = add i32 %depth_vs171, 1
  store i32 %add172, ptr %depth_vs, align 4
  %23 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %if_merge170

if_else:                                          ; preds = %while_body161
  %24 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond173 = icmp ne i8 %24, 0
  br i1 %if_cond173, label %if_then174, label %if_else175

if_merge170:                                      ; preds = %if_merge176, %if_then169
  br label %while_cond160

if_then174:                                       ; preds = %if_else
  %depth_vs177 = load i32, ptr %depth_vs, align 4
  %sub = sub i32 %depth_vs177, 1
  store i32 %sub, ptr %depth_vs, align 4
  %depth_vs178 = load i32, ptr %depth_vs, align 4
  %icmp179 = icmp sgt i32 %depth_vs178, 0
  br i1 %icmp179, label %if_then180, label %if_else181

if_else175:                                       ; preds = %if_else
  %depth_vs183 = load i32, ptr %depth_vs, align 4
  %icmp184 = icmp eq i32 %depth_vs183, 1
  %25 = call i8 @parser_t__NS_is_type_start(ptr %self)
  %trunc = trunc i8 %25 to i1
  %land185 = and i1 %icmp184, %trunc
  %26 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool186 = icmp ne i8 %26, 0
  %not187 = xor i1 %tobool186, true
  %land188 = and i1 %land185, %not187
  br i1 %land188, label %if_then189, label %if_else190

if_merge176:                                      ; preds = %if_merge191, %if_merge182
  br label %if_merge170

if_then180:                                       ; preds = %if_then174
  %27 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %if_merge182

if_else181:                                       ; preds = %if_then174
  br label %while_exit162

if_merge182:                                      ; preds = %if_then180
  br label %if_merge176

if_then189:                                       ; preds = %if_else175
  %saved_pos = alloca i32, align 4
  %ptr_deref192 = load ptr, ptr %self, align 8
  %current = getelementptr inbounds nuw %parser_t, ptr %ptr_deref192, i32 0, i32 2
  %ptr_deref193 = load ptr, ptr %self, align 8
  %mem_load194 = load i32, ptr %current, align 4
  store i32 %mem_load194, ptr %saved_pos, align 4
  %ft195 = alloca ptr, align 8
  %28 = call ptr @parser_t__NS_parse_type(ptr %self)
  store ptr %28, ptr %ft195, align 8
  %29 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond196 = icmp ne i8 %29, 0
  br i1 %if_cond196, label %if_then197, label %if_else198

if_else190:                                       ; preds = %if_else175
  %depth_vs269 = load i32, ptr %depth_vs, align 4
  %icmp270 = icmp eq i32 %depth_vs269, 1
  %30 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %trunc271 = trunc i8 %30 to i1
  %land272 = and i1 %icmp270, %trunc271
  %31 = call i32 @parser_t__NS_peek_at_type(ptr %self, i32 1)
  br label %if_merge191

if_merge191:                                      ; preds = %if_else190, %if_merge199
  br label %if_merge176

if_then197:                                       ; preds = %if_then189
  %fname = alloca i8, align 1
  %32 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.22)
  store i8 %32, ptr %fname, align 1
  %33 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond200 = icmp ne i8 %33, 0
  br i1 %if_cond200, label %if_then201, label %if_else202

if_else198:                                       ; preds = %if_then189
  %ptr_deref266 = load ptr, ptr %self, align 8
  %current267 = getelementptr inbounds nuw %parser_t, ptr %ptr_deref266, i32 0, i32 2
  %saved_pos268 = load i32, ptr %saved_pos, align 4
  store i32 %saved_pos268, ptr %current267, align 4
  %34 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %if_merge199

if_merge199:                                      ; preds = %if_else198, %if_merge203
  br label %if_merge191

if_then201:                                       ; preds = %if_then197
  %35 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %fc204 = load i32, ptr %fc159, align 4
  %icmp205 = icmp slt i32 %fc204, 8
  br i1 %icmp205, label %if_then206, label %if_merge207

if_else202:                                       ; preds = %if_then197
  %36 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond227 = icmp ne i8 %36, 0
  br i1 %if_cond227, label %if_then228, label %if_else229

if_merge203:                                      ; preds = %if_merge230, %if_merge207
  br label %if_merge199

if_then206:                                       ; preds = %if_then201
  %ptr_deref208 = load ptr, ptr %ed, align 8
  %variant_field_names_flat209 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref208, i32 0, i32 11
  %vi210 = load i32, ptr %vi, align 4
  %mul211 = mul i32 %vi210, 8
  %fc212 = load i32, ptr %fc159, align 4
  %add213 = add i32 %mul211, %fc212
  %ptr_load214 = load ptr, ptr %variant_field_names_flat209, align 8
  %ptr_gep215 = getelementptr i8, ptr %ptr_load214, i32 %add213
  %ptr_deref216 = load ptr, ptr %ed, align 8
  %variant_field_type_flat217 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref216, i32 0, i32 12
  %vi218 = load i32, ptr %vi, align 4
  %mul219 = mul i32 %vi218, 8
  %fc220 = load i32, ptr %fc159, align 4
  %add221 = add i32 %mul219, %fc220
  %ptr_load222 = load ptr, ptr %variant_field_type_flat217, align 8
  %ptr_gep223 = getelementptr i8, ptr %ptr_load222, i32 %add221
  %ft224 = load ptr, ptr %ft195, align 8
  store ptr %ft224, ptr %ptr_gep223, align 8
  %fc225 = load i32, ptr %fc159, align 4
  %add226 = add i32 %fc225, 1
  store i32 %add226, ptr %fc159, align 4
  br label %if_merge207

if_merge207:                                      ; preds = %if_then206, %if_then201
  br label %if_merge203

if_then228:                                       ; preds = %if_else202
  %37 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %mfd = alloca ptr, align 8
  %ft231 = load ptr, ptr %ft195, align 8
  %fname232 = load i8, ptr %fname, align 1
  %38 = call ptr @parser_t__NS_parse_func_body(ptr %self, ptr %ft231, i8 %fname232, i8 0)
  store ptr %38, ptr %mfd, align 8
  %mfd233 = load ptr, ptr %mfd, align 8
  %icmp234 = icmp ne ptr %mfd233, null
  br i1 %icmp234, label %if_then235, label %if_merge236

if_else229:                                       ; preds = %if_else202
  %ptr_deref263 = load ptr, ptr %self, align 8
  %current264 = getelementptr inbounds nuw %parser_t, ptr %ptr_deref263, i32 0, i32 2
  %saved_pos265 = load i32, ptr %saved_pos, align 4
  store i32 %saved_pos265, ptr %current264, align 4
  %39 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %if_merge230

if_merge230:                                      ; preds = %if_else229, %if_merge236
  br label %if_merge203

if_then235:                                       ; preds = %if_then228
  %mc = alloca i32, align 4
  %ptr_deref237 = load ptr, ptr %ed, align 8
  %variant_method_counts238 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref237, i32 0, i32 14
  %vi239 = load i32, ptr %vi, align 4
  %ptr_load240 = load ptr, ptr %variant_method_counts238, align 8
  %ptr_gep241 = getelementptr i8, ptr %ptr_load240, i32 %vi239
  %idx_load = load ptr, ptr %ptr_gep241, align 8
  %p2i = ptrtoint ptr %idx_load to i32
  store i32 %p2i, ptr %mc, align 4
  %mc242 = load i32, ptr %mc, align 4
  %icmp243 = icmp slt i32 %mc242, 8
  br i1 %icmp243, label %if_then244, label %if_merge245

if_merge236:                                      ; preds = %if_merge245, %if_then228
  br label %if_merge230

if_then244:                                       ; preds = %if_then235
  %ptr_deref246 = load ptr, ptr %ed, align 8
  %variant_method_flat247 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref246, i32 0, i32 13
  %vi248 = load i32, ptr %vi, align 4
  %mul249 = mul i32 %vi248, 8
  %mc250 = load i32, ptr %mc, align 4
  %add251 = add i32 %mul249, %mc250
  %ptr_load252 = load ptr, ptr %variant_method_flat247, align 8
  %ptr_gep253 = getelementptr i8, ptr %ptr_load252, i32 %add251
  %mfd254 = load ptr, ptr %mfd, align 8
  store ptr %mfd254, ptr %ptr_gep253, align 8
  %ptr_deref255 = load ptr, ptr %ed, align 8
  %variant_method_counts256 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref255, i32 0, i32 14
  %vi257 = load i32, ptr %vi, align 4
  %ptr_load258 = load ptr, ptr %variant_method_counts256, align 8
  %ptr_gep259 = getelementptr i8, ptr %ptr_load258, i32 %vi257
  %mc260 = load i32, ptr %mc, align 4
  %add261 = add i32 %mc260, 1
  %i2p262 = inttoptr i32 %add261 to ptr
  store ptr %i2p262, ptr %ptr_gep259, align 8
  br label %if_merge245

if_merge245:                                      ; preds = %if_then244, %if_then235
  br label %if_merge236

if_then281:                                       ; preds = %if_merge148
  %val_expr = alloca ptr, align 8
  %40 = call ptr @parser_t__NS_parse_expr(ptr %self)
  store ptr %40, ptr %val_expr, align 8
  %ptr_deref284 = load ptr, ptr %ed, align 8
  %variant_vals285 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref284, i32 0, i32 4
  %vi286 = load i32, ptr %vi, align 4
  %ptr_load287 = load ptr, ptr %variant_vals285, align 8
  %ptr_gep288 = getelementptr i8, ptr %ptr_load287, i32 %vi286
  %next_val289 = load i64, ptr %next_val, align 4
  %i2p290 = inttoptr i64 %next_val289 to ptr
  store ptr %i2p290, ptr %ptr_gep288, align 8
  %ptr_deref291 = load ptr, ptr %ed, align 8
  %variant_has_val292 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref291, i32 0, i32 5
  %vi293 = load i32, ptr %vi, align 4
  %ptr_load294 = load ptr, ptr %variant_has_val292, align 8
  %ptr_gep295 = getelementptr i8, ptr %ptr_load294, i32 %vi293
  store ptr inttoptr (i1 true to ptr), ptr %ptr_gep295, align 8
  br label %if_merge283

if_else282:                                       ; preds = %if_merge148
  %ptr_deref296 = load ptr, ptr %ed, align 8
  %variant_vals297 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref296, i32 0, i32 4
  %vi298 = load i32, ptr %vi, align 4
  %ptr_load299 = load ptr, ptr %variant_vals297, align 8
  %ptr_gep300 = getelementptr i8, ptr %ptr_load299, i32 %vi298
  %next_val301 = load i64, ptr %next_val, align 4
  %i2p302 = inttoptr i64 %next_val301 to ptr
  store ptr %i2p302, ptr %ptr_gep300, align 8
  %ptr_deref303 = load ptr, ptr %ed, align 8
  %variant_has_val304 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref303, i32 0, i32 5
  %vi305 = load i32, ptr %vi, align 4
  %ptr_load306 = load ptr, ptr %variant_has_val304, align 8
  %ptr_gep307 = getelementptr i8, ptr %ptr_load306, i32 %vi305
  store ptr null, ptr %ptr_gep307, align 8
  br label %if_merge283

if_merge283:                                      ; preds = %if_else282, %if_then281
  %next_val308 = load i64, ptr %next_val, align 4
  %add309 = add i64 %next_val308, 1
  store i64 %add309, ptr %next_val, align 4
  %ptr_deref310 = load ptr, ptr %ed, align 8
  %variants_len311 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref310, i32 0, i32 6
  %ptr_deref312 = load ptr, ptr %ed, align 8
  %variants_len313 = getelementptr inbounds nuw %enum_decl, ptr %ptr_deref312, i32 0, i32 6
  %ptr_deref314 = load ptr, ptr %ed, align 8
  %mem_load315 = load i32, ptr %variants_len313, align 4
  %add316 = add i32 %mem_load315, 1
  store i32 %add316, ptr %variants_len311, align 4
  %41 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool317 = icmp ne i8 %41, 0
  %not318 = xor i1 %tobool317, true
  br i1 %not318, label %if_then319, label %if_merge320

if_then319:                                       ; preds = %if_merge283
  %42 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.24)
  br label %if_merge320

if_merge320:                                      ; preds = %if_then319, %if_merge283
  br label %while_cond
}

define ptr @parser_t__NS_parse_typedef_decl(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ln = alloca i64, align 8
  %1 = call i64 @parser_t__NS_peek_line(ptr %self)
  store i64 %1, ptr %ln, align 4
  %2 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %td = alloca ptr, align 8
  store ptr null, ptr %td, align 8
  %ptr_deref = load ptr, ptr %td, align 8
  %kind = getelementptr inbounds nuw %typedef_decl, ptr %ptr_deref, i32 0, i32 0
  %nd_typedef_decl = load i32, ptr @ast_kind__nd_typedef_decl, align 4
  store i32 %nd_typedef_decl, ptr %kind, align 4
  %ptr_deref1 = load ptr, ptr %td, align 8
  %line = getelementptr inbounds nuw %typedef_decl, ptr %ptr_deref1, i32 0, i32 1
  %ln2 = load i64, ptr %ln, align 4
  store i64 %ln2, ptr %line, align 4
  %3 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %3, 0
  br i1 %if_cond, label %if_then, label %if_else

if_then:                                          ; preds = %entry
  %4 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %ptr_deref3 = load ptr, ptr %td, align 8
  %name = getelementptr inbounds nuw %typedef_decl, ptr %ptr_deref3, i32 0, i32 2
  %5 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.26)
  %ptr_deref4 = load ptr, ptr %td, align 8
  %target = getelementptr inbounds nuw %typedef_decl, ptr %ptr_deref4, i32 0, i32 3
  %6 = call ptr @parser_t__NS_parse_type(ptr %self)
  store ptr %6, ptr %target, align 8
  br label %if_merge

if_else:                                          ; preds = %entry
  %ptr_deref5 = load ptr, ptr %td, align 8
  %target6 = getelementptr inbounds nuw %typedef_decl, ptr %ptr_deref5, i32 0, i32 3
  %7 = call ptr @parser_t__NS_parse_type(ptr %self)
  store ptr %7, ptr %target6, align 8
  %ptr_deref7 = load ptr, ptr %td, align 8
  %name8 = getelementptr inbounds nuw %typedef_decl, ptr %ptr_deref7, i32 0, i32 2
  br label %if_merge

if_merge:                                         ; preds = %if_else, %if_then
  %8 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.27)
  %td9 = load ptr, ptr %td, align 8
  ret ptr %td9
}

define ptr @parser_t__NS_parse_namespace_decl(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ln = alloca i64, align 8
  %1 = call i64 @parser_t__NS_peek_line(ptr %self)
  store i64 %1, ptr %ln, align 4
  %2 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %nd = alloca ptr, align 8
  store ptr null, ptr %nd, align 8
  %ptr_deref = load ptr, ptr %nd, align 8
  %kind = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref, i32 0, i32 0
  %nd_namespace_decl = load i32, ptr @ast_kind__nd_namespace_decl, align 4
  store i32 %nd_namespace_decl, ptr %kind, align 4
  %ptr_deref1 = load ptr, ptr %nd, align 8
  %line = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref1, i32 0, i32 1
  %ln2 = load i64, ptr %ln, align 4
  store i64 %ln2, ptr %line, align 4
  %ptr_deref3 = load ptr, ptr %nd, align 8
  %name = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref3, i32 0, i32 2
  %ptr_deref4 = load ptr, ptr %nd, align 8
  %decls_cap = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref4, i32 0, i32 5
  store i32 16, ptr %decls_cap, align 4
  %ptr_deref5 = load ptr, ptr %nd, align 8
  %decls = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref5, i32 0, i32 3
  %3 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.28)
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %4 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool = icmp ne i8 %4, 0
  %not = xor i1 %tobool, true
  %5 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool6 = icmp ne i8 %5, 0
  %not7 = xor i1 %tobool6, true
  %land = and i1 %not, %not7
  br i1 %land, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %decl = alloca ptr, align 8
  %6 = call ptr @parser_t__NS_parse_top_level(ptr %self)
  store ptr %6, ptr %decl, align 8
  %decl8 = load ptr, ptr %decl, align 8
  %icmp = icmp ne ptr %decl8, null
  br i1 %icmp, label %if_then, label %if_merge

while_exit:                                       ; preds = %while_cond
  %7 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.29)
  %nd39 = load ptr, ptr %nd, align 8
  ret ptr %nd39

if_then:                                          ; preds = %while_body
  %ptr_deref9 = load ptr, ptr %nd, align 8
  %decls_len = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref9, i32 0, i32 4
  %ptr_deref10 = load ptr, ptr %nd, align 8
  %mem_load = load i32, ptr %decls_len, align 4
  %ptr_deref11 = load ptr, ptr %nd, align 8
  %decls_cap12 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref11, i32 0, i32 5
  %ptr_deref13 = load ptr, ptr %nd, align 8
  %mem_load14 = load i32, ptr %decls_cap12, align 4
  %icmp15 = icmp sge i32 %mem_load, %mem_load14
  br i1 %icmp15, label %if_then16, label %if_merge17

if_merge:                                         ; preds = %if_merge17, %while_body
  br label %while_cond

if_then16:                                        ; preds = %if_then
  %ptr_deref18 = load ptr, ptr %nd, align 8
  %decls_cap19 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref18, i32 0, i32 5
  %ptr_deref20 = load ptr, ptr %nd, align 8
  %decls_cap21 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref20, i32 0, i32 5
  %ptr_deref22 = load ptr, ptr %nd, align 8
  %mem_load23 = load i32, ptr %decls_cap21, align 4
  %mul = mul i32 %mem_load23, 2
  store i32 %mul, ptr %decls_cap19, align 4
  %ptr_deref24 = load ptr, ptr %nd, align 8
  %decls25 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref24, i32 0, i32 3
  br label %if_merge17

if_merge17:                                       ; preds = %if_then16, %if_then
  %ptr_deref26 = load ptr, ptr %nd, align 8
  %decls27 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref26, i32 0, i32 3
  %ptr_deref28 = load ptr, ptr %nd, align 8
  %decls_len29 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref28, i32 0, i32 4
  %ptr_deref30 = load ptr, ptr %nd, align 8
  %mem_load31 = load i32, ptr %decls_len29, align 4
  %ptr_load = load ptr, ptr %decls27, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load31
  %decl32 = load ptr, ptr %decl, align 8
  store ptr %decl32, ptr %ptr_gep, align 8
  %ptr_deref33 = load ptr, ptr %nd, align 8
  %decls_len34 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref33, i32 0, i32 4
  %ptr_deref35 = load ptr, ptr %nd, align 8
  %decls_len36 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref35, i32 0, i32 4
  %ptr_deref37 = load ptr, ptr %nd, align 8
  %mem_load38 = load i32, ptr %decls_len36, align 4
  %add = add i32 %mem_load38, 1
  store i32 %add, ptr %decls_len34, align 4
  br label %if_merge
}

define ptr @parser_t__NS_parse_extern_c_block(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ln = alloca i64, align 8
  %1 = call i64 @parser_t__NS_peek_line(ptr %self)
  store i64 %1, ptr %ln, align 4
  %2 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %blk = alloca ptr, align 8
  store ptr null, ptr %blk, align 8
  %ptr_deref = load ptr, ptr %blk, align 8
  %kind = getelementptr inbounds nuw %extern_c_block, ptr %ptr_deref, i32 0, i32 0
  %nd_extern_c_block = load i32, ptr @ast_kind__nd_extern_c_block, align 4
  store i32 %nd_extern_c_block, ptr %kind, align 4
  %ptr_deref1 = load ptr, ptr %blk, align 8
  %line = getelementptr inbounds nuw %extern_c_block, ptr %ptr_deref1, i32 0, i32 1
  %ln2 = load i64, ptr %ln, align 4
  store i64 %ln2, ptr %line, align 4
  %ptr_deref3 = load ptr, ptr %blk, align 8
  %decls_cap = getelementptr inbounds nuw %extern_c_block, ptr %ptr_deref3, i32 0, i32 4
  store i32 16, ptr %decls_cap, align 4
  %ptr_deref4 = load ptr, ptr %blk, align 8
  %decls = getelementptr inbounds nuw %extern_c_block, ptr %ptr_deref4, i32 0, i32 2
  %3 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %3, 0
  br i1 %if_cond, label %if_then, label %if_else

if_then:                                          ; preds = %entry
  br label %while_cond

if_else:                                          ; preds = %entry
  %decl40 = alloca ptr, align 8
  %4 = call ptr @parser_t__NS_parse_func_or_var_decl_extern_c(ptr %self)
  store ptr %4, ptr %decl40, align 8
  %ptr_deref41 = load ptr, ptr %blk, align 8
  %decls42 = getelementptr inbounds nuw %extern_c_block, ptr %ptr_deref41, i32 0, i32 2
  %ptr_load43 = load ptr, ptr %decls42, align 8
  %ptr_gep44 = getelementptr i8, ptr %ptr_load43, i64 0
  %decl45 = load ptr, ptr %decl40, align 8
  store ptr %decl45, ptr %ptr_gep44, align 8
  %ptr_deref46 = load ptr, ptr %blk, align 8
  %decls_len47 = getelementptr inbounds nuw %extern_c_block, ptr %ptr_deref46, i32 0, i32 3
  store i32 1, ptr %decls_len47, align 4
  br label %if_merge

if_merge:                                         ; preds = %if_else, %while_exit
  %blk48 = load ptr, ptr %blk, align 8
  ret ptr %blk48

while_cond:                                       ; preds = %if_merge9, %if_then
  %5 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool = icmp ne i8 %5, 0
  %not = xor i1 %tobool, true
  %6 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool5 = icmp ne i8 %6, 0
  %not6 = xor i1 %tobool5, true
  %land = and i1 %not, %not6
  br i1 %land, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %decl = alloca ptr, align 8
  %7 = call ptr @parser_t__NS_parse_func_or_var_decl_extern_c(ptr %self)
  store ptr %7, ptr %decl, align 8
  %decl7 = load ptr, ptr %decl, align 8
  %icmp = icmp ne ptr %decl7, null
  br i1 %icmp, label %if_then8, label %if_merge9

while_exit:                                       ; preds = %while_cond
  %8 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.30)
  br label %if_merge

if_then8:                                         ; preds = %while_body
  %ptr_deref10 = load ptr, ptr %blk, align 8
  %decls_len = getelementptr inbounds nuw %extern_c_block, ptr %ptr_deref10, i32 0, i32 3
  %ptr_deref11 = load ptr, ptr %blk, align 8
  %mem_load = load i32, ptr %decls_len, align 4
  %ptr_deref12 = load ptr, ptr %blk, align 8
  %decls_cap13 = getelementptr inbounds nuw %extern_c_block, ptr %ptr_deref12, i32 0, i32 4
  %ptr_deref14 = load ptr, ptr %blk, align 8
  %mem_load15 = load i32, ptr %decls_cap13, align 4
  %icmp16 = icmp sge i32 %mem_load, %mem_load15
  br i1 %icmp16, label %if_then17, label %if_merge18

if_merge9:                                        ; preds = %if_merge18, %while_body
  br label %while_cond

if_then17:                                        ; preds = %if_then8
  %ptr_deref19 = load ptr, ptr %blk, align 8
  %decls_cap20 = getelementptr inbounds nuw %extern_c_block, ptr %ptr_deref19, i32 0, i32 4
  %ptr_deref21 = load ptr, ptr %blk, align 8
  %decls_cap22 = getelementptr inbounds nuw %extern_c_block, ptr %ptr_deref21, i32 0, i32 4
  %ptr_deref23 = load ptr, ptr %blk, align 8
  %mem_load24 = load i32, ptr %decls_cap22, align 4
  %mul = mul i32 %mem_load24, 2
  store i32 %mul, ptr %decls_cap20, align 4
  %ptr_deref25 = load ptr, ptr %blk, align 8
  %decls26 = getelementptr inbounds nuw %extern_c_block, ptr %ptr_deref25, i32 0, i32 2
  br label %if_merge18

if_merge18:                                       ; preds = %if_then17, %if_then8
  %ptr_deref27 = load ptr, ptr %blk, align 8
  %decls28 = getelementptr inbounds nuw %extern_c_block, ptr %ptr_deref27, i32 0, i32 2
  %ptr_deref29 = load ptr, ptr %blk, align 8
  %decls_len30 = getelementptr inbounds nuw %extern_c_block, ptr %ptr_deref29, i32 0, i32 3
  %ptr_deref31 = load ptr, ptr %blk, align 8
  %mem_load32 = load i32, ptr %decls_len30, align 4
  %ptr_load = load ptr, ptr %decls28, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load32
  %decl33 = load ptr, ptr %decl, align 8
  store ptr %decl33, ptr %ptr_gep, align 8
  %ptr_deref34 = load ptr, ptr %blk, align 8
  %decls_len35 = getelementptr inbounds nuw %extern_c_block, ptr %ptr_deref34, i32 0, i32 3
  %ptr_deref36 = load ptr, ptr %blk, align 8
  %decls_len37 = getelementptr inbounds nuw %extern_c_block, ptr %ptr_deref36, i32 0, i32 3
  %ptr_deref38 = load ptr, ptr %blk, align 8
  %mem_load39 = load i32, ptr %decls_len37, align 4
  %add = add i32 %mem_load39, 1
  store i32 %add, ptr %decls_len35, align 4
  br label %if_merge9
}

define ptr @parser_t__NS_parse_class_decl_stub(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ln = alloca i64, align 8
  %1 = call i64 @parser_t__NS_peek_line(ptr %self)
  store i64 %1, ptr %ln, align 4
  %2 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %class_name = alloca i8, align 1
  %3 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.31)
  store i8 %3, ptr %class_name, align 1
  %4 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %4, 0
  br i1 %if_cond, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %depth = alloca i32, align 4
  store i32 0, ptr %depth, align 4
  %scanning = alloca i8, align 1
  store i8 1, ptr %scanning, align 1
  br label %while_cond

if_merge:                                         ; preds = %while_exit, %entry
  %5 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond16 = icmp ne i8 %5, 0
  br i1 %if_cond16, label %if_then17, label %if_merge18

while_cond:                                       ; preds = %if_merge6, %if_then
  %scanning1 = load i8, ptr %scanning, align 1
  %6 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool = icmp ne i8 %6, 0
  %not = xor i1 %tobool, true
  %zext = zext i1 %not to i8
  %tobool2 = icmp ne i8 %scanning1, 0
  %tobool3 = icmp ne i8 %zext, 0
  %land = and i1 %tobool2, %tobool3
  br i1 %land, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %7 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond4 = icmp ne i8 %7, 0
  br i1 %if_cond4, label %if_then5, label %if_else

while_exit:                                       ; preds = %while_cond
  br label %if_merge

if_then5:                                         ; preds = %while_body
  %depth7 = load i32, ptr %depth, align 4
  %add = add i32 %depth7, 1
  store i32 %add, ptr %depth, align 4
  %8 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %if_merge6

if_else:                                          ; preds = %while_body
  %9 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond8 = icmp ne i8 %9, 0
  br i1 %if_cond8, label %if_then9, label %if_else10

if_merge6:                                        ; preds = %if_merge11, %if_then5
  br label %while_cond

if_then9:                                         ; preds = %if_else
  %depth12 = load i32, ptr %depth, align 4
  %sub = sub i32 %depth12, 1
  store i32 %sub, ptr %depth, align 4
  %10 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %depth13 = load i32, ptr %depth, align 4
  %icmp = icmp sle i32 %depth13, 0
  br i1 %icmp, label %if_then14, label %if_merge15

if_else10:                                        ; preds = %if_else
  %11 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %if_merge11

if_merge11:                                       ; preds = %if_else10, %if_merge15
  br label %if_merge6

if_then14:                                        ; preds = %if_then9
  store i8 0, ptr %scanning, align 1
  br label %if_merge15

if_merge15:                                       ; preds = %if_then14, %if_then9
  br label %if_merge11

if_then17:                                        ; preds = %if_merge
  br label %while_cond19

if_merge18:                                       ; preds = %while_exit21, %if_merge
  %nd = alloca ptr, align 8
  store ptr null, ptr %nd, align 8
  %ptr_deref = load ptr, ptr %nd, align 8
  %kind = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref, i32 0, i32 0
  %nd_namespace_decl = load i32, ptr @ast_kind__nd_namespace_decl, align 4
  store i32 %nd_namespace_decl, ptr %kind, align 4
  %ptr_deref27 = load ptr, ptr %nd, align 8
  %line = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref27, i32 0, i32 1
  %ln28 = load i64, ptr %ln, align 4
  store i64 %ln28, ptr %line, align 4
  %ptr_deref29 = load ptr, ptr %nd, align 8
  %name = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref29, i32 0, i32 2
  %ptr_deref30 = load ptr, ptr %nd, align 8
  %decls_cap = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref30, i32 0, i32 5
  store i32 16, ptr %decls_cap, align 4
  %ptr_deref31 = load ptr, ptr %nd, align 8
  %decls = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref31, i32 0, i32 3
  %12 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.32)
  br label %while_cond32

while_cond19:                                     ; preds = %if_merge26, %if_then17
  %13 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %while_cond22 = icmp ne i8 %13, 0
  br i1 %while_cond22, label %while_body20, label %while_exit21

while_body20:                                     ; preds = %while_cond19
  %14 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %15 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %tobool23 = icmp ne i8 %15, 0
  %not24 = xor i1 %tobool23, true
  br i1 %not24, label %if_then25, label %if_merge26

while_exit21:                                     ; preds = %if_then25, %while_cond19
  br label %if_merge18

if_then25:                                        ; preds = %while_body20
  br label %while_exit21

if_merge26:                                       ; preds = %while_body20
  br label %while_cond19

while_cond32:                                     ; preds = %if_merge62, %if_merge18
  %16 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool35 = icmp ne i8 %16, 0
  %not36 = xor i1 %tobool35, true
  %17 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool37 = icmp ne i8 %17, 0
  %not38 = xor i1 %tobool37, true
  %land39 = and i1 %not36, %not38
  br i1 %land39, label %while_body33, label %while_exit34

while_body33:                                     ; preds = %while_cond32
  %skip_mod = alloca i8, align 1
  store i8 1, ptr %skip_mod, align 1
  br label %while_cond40

while_exit34:                                     ; preds = %if_then51, %while_cond32
  %18 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.33)
  %19 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %sd = alloca ptr, align 8
  store ptr null, ptr %sd, align 8
  %ptr_deref94 = load ptr, ptr %sd, align 8
  %kind95 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref94, i32 0, i32 0
  %nd_struct_decl = load i32, ptr @ast_kind__nd_struct_decl, align 4
  store i32 %nd_struct_decl, ptr %kind95, align 4
  %ptr_deref96 = load ptr, ptr %sd, align 8
  %line97 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref96, i32 0, i32 1
  %ln98 = load i64, ptr %ln, align 4
  store i64 %ln98, ptr %line97, align 4
  %ptr_deref99 = load ptr, ptr %sd, align 8
  %name100 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref99, i32 0, i32 2
  %ptr_deref101 = load ptr, ptr %sd, align 8
  %fields_cap = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref101, i32 0, i32 5
  store i32 8, ptr %fields_cap, align 4
  %ptr_deref102 = load ptr, ptr %sd, align 8
  %fields = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref102, i32 0, i32 3
  %ptr_deref103 = load ptr, ptr %sd, align 8
  %fields_len = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref103, i32 0, i32 4
  store i32 0, ptr %fields_len, align 4
  %out = alloca ptr, align 8
  store ptr null, ptr %out, align 8
  %ptr_deref104 = load ptr, ptr %out, align 8
  %kind105 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref104, i32 0, i32 0
  %nd_namespace_decl106 = load i32, ptr @ast_kind__nd_namespace_decl, align 4
  store i32 %nd_namespace_decl106, ptr %kind105, align 4
  %ptr_deref107 = load ptr, ptr %out, align 8
  %line108 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref107, i32 0, i32 1
  %ln109 = load i64, ptr %ln, align 4
  store i64 %ln109, ptr %line108, align 4
  %ptr_deref110 = load ptr, ptr %out, align 8
  %name111 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref110, i32 0, i32 2
  %ptr_deref112 = load ptr, ptr %nd, align 8
  %name113 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref112, i32 0, i32 2
  %ptr_deref114 = load ptr, ptr %nd, align 8
  %mem_load115 = load ptr, ptr %name113, align 8
  store ptr %mem_load115, ptr %name111, align 8
  %ptr_deref116 = load ptr, ptr %out, align 8
  %decls_cap117 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref116, i32 0, i32 5
  %ptr_deref118 = load ptr, ptr %nd, align 8
  %decls_len119 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref118, i32 0, i32 4
  %ptr_deref120 = load ptr, ptr %nd, align 8
  %mem_load121 = load i32, ptr %decls_len119, align 4
  %add122 = add i32 %mem_load121, 4
  store i32 %add122, ptr %decls_cap117, align 4
  %ptr_deref123 = load ptr, ptr %out, align 8
  %decls124 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref123, i32 0, i32 3
  %ptr_deref125 = load ptr, ptr %out, align 8
  %decls_len126 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref125, i32 0, i32 4
  store i32 0, ptr %decls_len126, align 4
  %ptr_deref127 = load ptr, ptr %out, align 8
  %decls128 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref127, i32 0, i32 3
  %ptr_load129 = load ptr, ptr %decls128, align 8
  %ptr_gep130 = getelementptr i8, ptr %ptr_load129, i64 0
  %sd131 = load ptr, ptr %sd, align 8
  store ptr %sd131, ptr %ptr_gep130, align 8
  %ptr_deref132 = load ptr, ptr %out, align 8
  %decls_len133 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref132, i32 0, i32 4
  store i32 1, ptr %decls_len133, align 4
  %pi = alloca i32, align 4
  store i32 0, ptr %pi, align 4
  br label %while_cond134

while_cond40:                                     ; preds = %while_body41, %while_body33
  %skip_mod43 = load i8, ptr %skip_mod, align 1
  %while_cond44 = icmp ne i8 %skip_mod43, 0
  br i1 %while_cond44, label %while_body41, label %while_exit42

while_body41:                                     ; preds = %while_cond40
  %tt = alloca i32, align 4
  %20 = call i32 @parser_t__NS_peek_type(ptr %self)
  store i32 %20, ptr %tt, align 4
  %tt45 = load i32, ptr %tt, align 4
  %tt46 = load i32, ptr %tt, align 4
  %tt47 = load i32, ptr %tt, align 4
  %tt48 = load i32, ptr %tt, align 4
  %tt49 = load i32, ptr %tt, align 4
  br label %while_cond40

while_exit42:                                     ; preds = %while_cond40
  %21 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond50 = icmp ne i8 %21, 0
  br i1 %if_cond50, label %if_then51, label %if_merge52

if_then51:                                        ; preds = %while_exit42
  br label %while_exit34

if_merge52:                                       ; preds = %while_exit42
  %22 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond53 = icmp ne i8 %22, 0
  br i1 %if_cond53, label %if_then54, label %if_merge55

if_then54:                                        ; preds = %if_merge52
  %op_nt = alloca i32, align 4
  %23 = call i32 @parser_t__NS_peek_at_type(ptr %self, i32 1)
  store i32 %23, ptr %op_nt, align 4
  %op_nt56 = load i32, ptr %op_nt, align 4
  %op_nt57 = load i32, ptr %op_nt, align 4
  %op_nt58 = load i32, ptr %op_nt, align 4
  br label %if_merge55

if_merge55:                                       ; preds = %if_then54, %if_merge52
  %member = alloca ptr, align 8
  %24 = call ptr @parser_t__NS_parse_func_or_var_decl(ptr %self)
  store ptr %24, ptr %member, align 8
  %member59 = load ptr, ptr %member, align 8
  %icmp60 = icmp ne ptr %member59, null
  br i1 %icmp60, label %if_then61, label %if_merge62

if_then61:                                        ; preds = %if_merge55
  %ptr_deref63 = load ptr, ptr %nd, align 8
  %decls_len = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref63, i32 0, i32 4
  %ptr_deref64 = load ptr, ptr %nd, align 8
  %mem_load = load i32, ptr %decls_len, align 4
  %ptr_deref65 = load ptr, ptr %nd, align 8
  %decls_cap66 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref65, i32 0, i32 5
  %ptr_deref67 = load ptr, ptr %nd, align 8
  %mem_load68 = load i32, ptr %decls_cap66, align 4
  %icmp69 = icmp sge i32 %mem_load, %mem_load68
  br i1 %icmp69, label %if_then70, label %if_merge71

if_merge62:                                       ; preds = %if_merge71, %if_merge55
  br label %while_cond32

if_then70:                                        ; preds = %if_then61
  %ptr_deref72 = load ptr, ptr %nd, align 8
  %decls_cap73 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref72, i32 0, i32 5
  %ptr_deref74 = load ptr, ptr %nd, align 8
  %decls_cap75 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref74, i32 0, i32 5
  %ptr_deref76 = load ptr, ptr %nd, align 8
  %mem_load77 = load i32, ptr %decls_cap75, align 4
  %mul = mul i32 %mem_load77, 2
  store i32 %mul, ptr %decls_cap73, align 4
  %ptr_deref78 = load ptr, ptr %nd, align 8
  %decls79 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref78, i32 0, i32 3
  br label %if_merge71

if_merge71:                                       ; preds = %if_then70, %if_then61
  %ptr_deref80 = load ptr, ptr %nd, align 8
  %decls81 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref80, i32 0, i32 3
  %ptr_deref82 = load ptr, ptr %nd, align 8
  %decls_len83 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref82, i32 0, i32 4
  %ptr_deref84 = load ptr, ptr %nd, align 8
  %mem_load85 = load i32, ptr %decls_len83, align 4
  %ptr_load = load ptr, ptr %decls81, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load85
  %member86 = load ptr, ptr %member, align 8
  store ptr %member86, ptr %ptr_gep, align 8
  %ptr_deref87 = load ptr, ptr %nd, align 8
  %decls_len88 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref87, i32 0, i32 4
  %ptr_deref89 = load ptr, ptr %nd, align 8
  %decls_len90 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref89, i32 0, i32 4
  %ptr_deref91 = load ptr, ptr %nd, align 8
  %mem_load92 = load i32, ptr %decls_len90, align 4
  %add93 = add i32 %mem_load92, 1
  store i32 %add93, ptr %decls_len88, align 4
  br label %if_merge62

while_cond134:                                    ; preds = %if_merge158, %while_exit34
  %pi137 = load i32, ptr %pi, align 4
  %ptr_deref138 = load ptr, ptr %nd, align 8
  %decls_len139 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref138, i32 0, i32 4
  %ptr_deref140 = load ptr, ptr %nd, align 8
  %mem_load141 = load i32, ptr %decls_len139, align 4
  %icmp142 = icmp slt i32 %pi137, %mem_load141
  br i1 %icmp142, label %while_body135, label %while_exit136

while_body135:                                    ; preds = %while_cond134
  %m = alloca ptr, align 8
  %ptr_deref143 = load ptr, ptr %nd, align 8
  %decls144 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref143, i32 0, i32 3
  %pi145 = load i32, ptr %pi, align 4
  %ptr_load146 = load ptr, ptr %decls144, align 8
  %ptr_gep147 = getelementptr i8, ptr %ptr_load146, i32 %pi145
  %idx_load = load ptr, ptr %ptr_gep147, align 8
  store ptr %idx_load, ptr %m, align 8
  %m148 = load ptr, ptr %m, align 8
  %icmp149 = icmp ne ptr %m148, null
  %ptr_deref150 = load ptr, ptr %m, align 8
  %kind151 = getelementptr inbounds nuw %ast_node, ptr %ptr_deref150, i32 0, i32 0
  %ptr_deref152 = load ptr, ptr %m, align 8
  %mem_load153 = load i32, ptr %kind151, align 4
  %nd_var_decl = load i32, ptr @ast_kind__nd_var_decl, align 4
  %icmp154 = icmp eq i32 %mem_load153, %nd_var_decl
  %land155 = and i1 %icmp149, %icmp154
  br i1 %land155, label %if_then156, label %if_else157

while_exit136:                                    ; preds = %while_cond134
  %out237 = load ptr, ptr %out, align 8
  ret ptr %out237

if_then156:                                       ; preds = %while_body135
  %ptr_deref159 = load ptr, ptr %sd, align 8
  %fields_len160 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref159, i32 0, i32 4
  %ptr_deref161 = load ptr, ptr %sd, align 8
  %mem_load162 = load i32, ptr %fields_len160, align 4
  %ptr_deref163 = load ptr, ptr %sd, align 8
  %fields_cap164 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref163, i32 0, i32 5
  %ptr_deref165 = load ptr, ptr %sd, align 8
  %mem_load166 = load i32, ptr %fields_cap164, align 4
  %icmp167 = icmp sge i32 %mem_load162, %mem_load166
  br i1 %icmp167, label %if_then168, label %if_merge169

if_else157:                                       ; preds = %while_body135
  %m195 = load ptr, ptr %m, align 8
  %icmp196 = icmp ne ptr %m195, null
  br i1 %icmp196, label %if_then197, label %if_merge198

if_merge158:                                      ; preds = %if_merge198, %if_merge169
  %pi235 = load i32, ptr %pi, align 4
  %add236 = add i32 %pi235, 1
  store i32 %add236, ptr %pi, align 4
  br label %while_cond134

if_then168:                                       ; preds = %if_then156
  %ptr_deref170 = load ptr, ptr %sd, align 8
  %fields_cap171 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref170, i32 0, i32 5
  %ptr_deref172 = load ptr, ptr %sd, align 8
  %fields_cap173 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref172, i32 0, i32 5
  %ptr_deref174 = load ptr, ptr %sd, align 8
  %mem_load175 = load i32, ptr %fields_cap173, align 4
  %mul176 = mul i32 %mem_load175, 2
  store i32 %mul176, ptr %fields_cap171, align 4
  %ptr_deref177 = load ptr, ptr %sd, align 8
  %fields178 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref177, i32 0, i32 3
  br label %if_merge169

if_merge169:                                      ; preds = %if_then168, %if_then156
  %ptr_deref179 = load ptr, ptr %sd, align 8
  %fields180 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref179, i32 0, i32 3
  %ptr_deref181 = load ptr, ptr %sd, align 8
  %fields_len182 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref181, i32 0, i32 4
  %ptr_deref183 = load ptr, ptr %sd, align 8
  %mem_load184 = load i32, ptr %fields_len182, align 4
  %ptr_load185 = load ptr, ptr %fields180, align 8
  %ptr_gep186 = getelementptr i8, ptr %ptr_load185, i32 %mem_load184
  %m187 = load ptr, ptr %m, align 8
  store ptr %m187, ptr %ptr_gep186, align 8
  %ptr_deref188 = load ptr, ptr %sd, align 8
  %fields_len189 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref188, i32 0, i32 4
  %ptr_deref190 = load ptr, ptr %sd, align 8
  %fields_len191 = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref190, i32 0, i32 4
  %ptr_deref192 = load ptr, ptr %sd, align 8
  %mem_load193 = load i32, ptr %fields_len191, align 4
  %add194 = add i32 %mem_load193, 1
  store i32 %add194, ptr %fields_len189, align 4
  br label %if_merge158

if_then197:                                       ; preds = %if_else157
  %ptr_deref199 = load ptr, ptr %out, align 8
  %decls_len200 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref199, i32 0, i32 4
  %ptr_deref201 = load ptr, ptr %out, align 8
  %mem_load202 = load i32, ptr %decls_len200, align 4
  %ptr_deref203 = load ptr, ptr %out, align 8
  %decls_cap204 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref203, i32 0, i32 5
  %ptr_deref205 = load ptr, ptr %out, align 8
  %mem_load206 = load i32, ptr %decls_cap204, align 4
  %icmp207 = icmp sge i32 %mem_load202, %mem_load206
  br i1 %icmp207, label %if_then208, label %if_merge209

if_merge198:                                      ; preds = %if_merge209, %if_else157
  br label %if_merge158

if_then208:                                       ; preds = %if_then197
  %ptr_deref210 = load ptr, ptr %out, align 8
  %decls_cap211 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref210, i32 0, i32 5
  %ptr_deref212 = load ptr, ptr %out, align 8
  %decls_cap213 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref212, i32 0, i32 5
  %ptr_deref214 = load ptr, ptr %out, align 8
  %mem_load215 = load i32, ptr %decls_cap213, align 4
  %mul216 = mul i32 %mem_load215, 2
  store i32 %mul216, ptr %decls_cap211, align 4
  %ptr_deref217 = load ptr, ptr %out, align 8
  %decls218 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref217, i32 0, i32 3
  br label %if_merge209

if_merge209:                                      ; preds = %if_then208, %if_then197
  %ptr_deref219 = load ptr, ptr %out, align 8
  %decls220 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref219, i32 0, i32 3
  %ptr_deref221 = load ptr, ptr %out, align 8
  %decls_len222 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref221, i32 0, i32 4
  %ptr_deref223 = load ptr, ptr %out, align 8
  %mem_load224 = load i32, ptr %decls_len222, align 4
  %ptr_load225 = load ptr, ptr %decls220, align 8
  %ptr_gep226 = getelementptr i8, ptr %ptr_load225, i32 %mem_load224
  %m227 = load ptr, ptr %m, align 8
  store ptr %m227, ptr %ptr_gep226, align 8
  %ptr_deref228 = load ptr, ptr %out, align 8
  %decls_len229 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref228, i32 0, i32 4
  %ptr_deref230 = load ptr, ptr %out, align 8
  %decls_len231 = getelementptr inbounds nuw %namespace_decl, ptr %ptr_deref230, i32 0, i32 4
  %ptr_deref232 = load ptr, ptr %out, align 8
  %mem_load233 = load i32, ptr %decls_len231, align 4
  %add234 = add i32 %mem_load233, 1
  store i32 %add234, ptr %decls_len229, align 4
  br label %if_merge198
}

define ptr @parser_t__NS_parse_top_level(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %1 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %1, 0
  br i1 %if_cond, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %2 = call ptr @parser_t__NS_parse_struct_decl(ptr %self)
  ret ptr %2

if_merge:                                         ; preds = %entry
  %3 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond1 = icmp ne i8 %3, 0
  br i1 %if_cond1, label %if_then2, label %if_merge3

if_then2:                                         ; preds = %if_merge
  %ud = alloca ptr, align 8
  %4 = call ptr @parser_t__NS_parse_struct_decl(ptr %self)
  store ptr %4, ptr %ud, align 8
  %ud4 = load ptr, ptr %ud, align 8
  %icmp = icmp ne ptr %ud4, null
  br i1 %icmp, label %if_then5, label %if_merge6

if_merge3:                                        ; preds = %if_merge
  %5 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond8 = icmp ne i8 %5, 0
  br i1 %if_cond8, label %if_then9, label %if_merge10

if_then5:                                         ; preds = %if_then2
  %ptr_deref = load ptr, ptr %ud, align 8
  %is_union = getelementptr inbounds nuw %struct_decl, ptr %ptr_deref, i32 0, i32 6
  store i8 1, ptr %is_union, align 1
  br label %if_merge6

if_merge6:                                        ; preds = %if_then5, %if_then2
  %ud7 = load ptr, ptr %ud, align 8
  ret ptr %ud7

if_then9:                                         ; preds = %if_merge3
  %6 = call ptr @parser_t__NS_parse_enum_decl(ptr %self)
  ret ptr %6

if_merge10:                                       ; preds = %if_merge3
  %7 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond11 = icmp ne i8 %7, 0
  br i1 %if_cond11, label %if_then12, label %if_merge13

if_then12:                                        ; preds = %if_merge10
  %8 = call ptr @parser_t__NS_parse_typedef_decl(ptr %self)
  ret ptr %8

if_merge13:                                       ; preds = %if_merge10
  %9 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond14 = icmp ne i8 %9, 0
  br i1 %if_cond14, label %if_then15, label %if_merge16

if_then15:                                        ; preds = %if_merge13
  %10 = call ptr @parser_t__NS_parse_class_decl_stub(ptr %self)
  ret ptr %10

if_merge16:                                       ; preds = %if_merge13
  %11 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond17 = icmp ne i8 %11, 0
  br i1 %if_cond17, label %if_then18, label %if_merge19

if_then18:                                        ; preds = %if_merge16
  %12 = call ptr @parser_t__NS_parse_class_decl_stub(ptr %self)
  ret ptr %12

if_merge19:                                       ; preds = %if_merge16
  %13 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond20 = icmp ne i8 %13, 0
  br i1 %if_cond20, label %if_then21, label %if_merge22

if_then21:                                        ; preds = %if_merge19
  %14 = call ptr @parser_t__NS_parse_extern_c_block(ptr %self)
  ret ptr %14

if_merge22:                                       ; preds = %if_merge19
  %15 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond23 = icmp ne i8 %15, 0
  br i1 %if_cond23, label %if_then24, label %if_merge25

if_then24:                                        ; preds = %if_merge22
  %16 = call ptr @parser_t__NS_parse_namespace_decl(ptr %self)
  ret ptr %16

if_merge25:                                       ; preds = %if_merge22
  %17 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond26 = icmp ne i8 %17, 0
  br i1 %if_cond26, label %if_then27, label %if_merge28

if_then27:                                        ; preds = %if_merge25
  br label %while_cond

if_merge28:                                       ; preds = %if_merge25
  %18 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond35 = icmp ne i8 %18, 0
  br i1 %if_cond35, label %if_then36, label %if_merge37

while_cond:                                       ; preds = %while_body, %if_then27
  %19 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool = icmp ne i8 %19, 0
  %not = xor i1 %tobool, true
  %20 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool29 = icmp ne i8 %20, 0
  %not30 = xor i1 %tobool29, true
  %land = and i1 %not, %not30
  br i1 %land, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %21 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %22 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool31 = icmp ne i8 %22, 0
  %not32 = xor i1 %tobool31, true
  br i1 %not32, label %if_then33, label %if_merge34

if_then33:                                        ; preds = %while_exit
  %23 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %if_merge34

if_merge34:                                       ; preds = %if_then33, %while_exit
  %24 = call ptr @parser_t__NS_parse_top_level(ptr %self)
  ret ptr %24

if_then36:                                        ; preds = %if_merge28
  %25 = call ptr @parser_t__NS_parse_class_decl_stub(ptr %self)
  ret ptr %25

if_merge37:                                       ; preds = %if_merge28
  %26 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond38 = icmp ne i8 %26, 0
  br i1 %if_cond38, label %if_then39, label %if_merge40

if_then39:                                        ; preds = %if_merge37
  %27 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %td = alloca ptr, align 8
  store ptr null, ptr %td, align 8
  %ptr_deref41 = load ptr, ptr %td, align 8
  %kind = getelementptr inbounds nuw %typedef_decl, ptr %ptr_deref41, i32 0, i32 0
  %nd_typedef_decl = load i32, ptr @ast_kind__nd_typedef_decl, align 4
  store i32 %nd_typedef_decl, ptr %kind, align 4
  %ptr_deref42 = load ptr, ptr %td, align 8
  %name = getelementptr inbounds nuw %typedef_decl, ptr %ptr_deref42, i32 0, i32 2
  %28 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.34)
  %ptr_deref43 = load ptr, ptr %td, align 8
  %target = getelementptr inbounds nuw %typedef_decl, ptr %ptr_deref43, i32 0, i32 3
  %29 = call ptr @parser_t__NS_parse_type(ptr %self)
  store ptr %29, ptr %target, align 8
  %30 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.35)
  %td44 = load ptr, ptr %td, align 8
  ret ptr %td44

if_merge40:                                       ; preds = %if_merge37
  %31 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond45 = icmp ne i8 %31, 0
  br i1 %if_cond45, label %if_then46, label %if_merge47

if_then46:                                        ; preds = %if_merge40
  %32 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %macro_name = alloca ptr, align 8
  store ptr null, ptr %macro_name, align 8
  %33 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond48 = icmp ne i8 %33, 0
  br i1 %if_cond48, label %if_then49, label %if_merge50

if_merge47:                                       ; preds = %if_merge40
  %34 = call ptr @parser_t__NS_parse_func_or_var_decl(ptr %self)
  ret ptr %34

if_then49:                                        ; preds = %if_then46
  %nm_tok = alloca i8, align 1
  %35 = call i8 @parser_t__NS_advance_tok(ptr %self)
  store i8 %35, ptr %nm_tok, align 1
  br label %if_merge50

if_merge50:                                       ; preds = %if_then49, %if_then46
  %macro_name51 = load ptr, ptr %macro_name, align 8
  %icmp52 = icmp eq ptr %macro_name51, null
  br i1 %icmp52, label %if_then53, label %if_merge54

if_then53:                                        ; preds = %if_merge50
  ret ptr null

if_merge54:                                       ; preds = %if_merge50
  %36 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.36)
  br label %while_cond55

while_cond55:                                     ; preds = %if_merge197, %if_merge54
  %37 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool58 = icmp ne i8 %37, 0
  %not59 = xor i1 %tobool58, true
  %38 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool60 = icmp ne i8 %38, 0
  %not61 = xor i1 %tobool60, true
  %land62 = and i1 %not59, %not61
  br i1 %land62, label %while_body56, label %while_exit57

while_body56:                                     ; preds = %while_cond55
  %param_names_buf = alloca [16 x ptr], align 8
  store [16 x ptr] zeroinitializer, ptr %param_names_buf, align 8
  %param_count = alloca i32, align 4
  store i32 0, ptr %param_count, align 4
  %pat_open = alloca i32, align 4
  %39 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool63 = icmp ne i8 %39, 0
  br i1 %tobool63, label %tern_then, label %tern_else

while_exit57:                                     ; preds = %while_cond55
  %40 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.38)
  ret ptr null

tern_then:                                        ; preds = %while_body56
  br label %tern_merge

tern_else:                                        ; preds = %while_body56
  %41 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool64 = icmp ne i8 %41, 0
  br i1 %tobool64, label %tern_then65, label %tern_else66

tern_merge:                                       ; preds = %tern_merge67, %tern_then
  store i32 0, ptr %pat_open, align 4
  %pat_close = alloca i32, align 4
  %pat_open68 = load i32, ptr %pat_open, align 4
  store i32 0, ptr %pat_close, align 4
  %pat_open69 = load i32, ptr %pat_open, align 4
  %icmp70 = icmp ne i32 %pat_open69, -1
  br i1 %icmp70, label %if_then71, label %if_merge72

tern_then65:                                      ; preds = %tern_else
  br label %tern_merge67

tern_else66:                                      ; preds = %tern_else
  br label %tern_merge67

tern_merge67:                                     ; preds = %tern_else66, %tern_then65
  br label %tern_merge

if_then71:                                        ; preds = %tern_merge
  %42 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %while_cond73

if_merge72:                                       ; preds = %while_exit75, %tern_merge
  %43 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond110 = icmp ne i8 %43, 0
  br i1 %if_cond110, label %if_then111, label %if_merge112

while_cond73:                                     ; preds = %if_merge108, %if_then71
  %pat_close76 = load i32, ptr %pat_close, align 4
  %44 = call i8 @parser_t__NS_check_tok(ptr %self, i32 %pat_close76)
  %tobool77 = icmp ne i8 %44, 0
  %not78 = xor i1 %tobool77, true
  %45 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool79 = icmp ne i8 %45, 0
  %not80 = xor i1 %tobool79, true
  %land81 = and i1 %not78, %not80
  br i1 %land81, label %while_body74, label %while_exit75

while_body74:                                     ; preds = %while_cond73
  %46 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond82 = icmp ne i8 %46, 0
  br i1 %if_cond82, label %if_then83, label %if_else

while_exit75:                                     ; preds = %while_cond73
  %pat_close109 = load i32, ptr %pat_close, align 4
  %47 = call i8 @parser_t__NS_consume_tok(ptr %self, i32 %pat_close109, ptr @str.37)
  br label %if_merge72

if_then83:                                        ; preds = %while_body74
  %48 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %pname = alloca ptr, align 8
  store ptr null, ptr %pname, align 8
  %49 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond85 = icmp ne i8 %49, 0
  br i1 %if_cond85, label %if_then86, label %if_merge87

if_else:                                          ; preds = %while_body74
  %50 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %if_merge84

if_merge84:                                       ; preds = %if_else, %if_merge97
  %51 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %pat_close101 = load i32, ptr %pat_close, align 4
  %52 = call i8 @parser_t__NS_check_tok(ptr %self, i32 %pat_close101)
  %tobool102 = icmp ne i8 %52, 0
  %not103 = xor i1 %tobool102, true
  %zext = zext i1 %not103 to i8
  %tobool104 = icmp ne i8 %51, 0
  %tobool105 = icmp ne i8 %zext, 0
  %land106 = and i1 %tobool104, %tobool105
  br i1 %land106, label %if_then107, label %if_merge108

if_then86:                                        ; preds = %if_then83
  %pn_tok = alloca i8, align 1
  %53 = call i8 @parser_t__NS_advance_tok(ptr %self)
  store i8 %53, ptr %pn_tok, align 1
  br label %if_merge87

if_merge87:                                       ; preds = %if_then86, %if_then83
  %54 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond88 = icmp ne i8 %54, 0
  br i1 %if_cond88, label %if_then89, label %if_merge90

if_then89:                                        ; preds = %if_merge87
  %55 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %56 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %if_merge90

if_merge90:                                       ; preds = %if_then89, %if_merge87
  %pname91 = load ptr, ptr %pname, align 8
  %icmp92 = icmp ne ptr %pname91, null
  %param_count93 = load i32, ptr %param_count, align 4
  %icmp94 = icmp slt i32 %param_count93, 16
  %land95 = and i1 %icmp92, %icmp94
  br i1 %land95, label %if_then96, label %if_merge97

if_then96:                                        ; preds = %if_merge90
  %param_count98 = load i32, ptr %param_count, align 4
  %arr_gep = getelementptr [16 x ptr], ptr %param_names_buf, i64 0, i32 %param_count98
  %pname99 = load ptr, ptr %pname, align 8
  store ptr %pname99, ptr %arr_gep, align 8
  %param_count100 = load i32, ptr %param_count, align 4
  %add = add i32 %param_count100, 1
  store i32 %add, ptr %param_count, align 4
  br label %if_merge97

if_merge97:                                       ; preds = %if_then96, %if_merge90
  br label %if_merge84

if_then107:                                       ; preds = %if_merge84
  %57 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %if_merge108

if_merge108:                                      ; preds = %if_then107, %if_merge84
  br label %while_cond73

if_then111:                                       ; preds = %if_merge72
  %58 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %if_merge112

if_merge112:                                      ; preds = %if_then111, %if_merge72
  %59 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond113 = icmp ne i8 %59, 0
  br i1 %if_cond113, label %if_then114, label %if_merge115

if_then114:                                       ; preds = %if_merge112
  %60 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %if_merge115

if_merge115:                                      ; preds = %if_then114, %if_merge112
  %tpl_cap = alloca i32, align 4
  store i32 64, ptr %tpl_cap, align 4
  %tpl = alloca ptr, align 8
  store ptr null, ptr %tpl, align 8
  %tpl_len = alloca i32, align 4
  store i32 0, ptr %tpl_len, align 4
  %61 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond116 = icmp ne i8 %61, 0
  br i1 %if_cond116, label %if_then117, label %if_merge118

if_then117:                                       ; preds = %if_merge115
  %62 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %depth_t = alloca i32, align 4
  store i32 1, ptr %depth_t, align 4
  br label %while_cond119

if_merge118:                                      ; preds = %while_exit121, %if_merge115
  %mdef = alloca ptr, align 8
  store ptr null, ptr %mdef, align 8
  %ptr_deref137 = load ptr, ptr %mdef, align 8
  %name138 = getelementptr inbounds nuw %macro_def_t, ptr %ptr_deref137, i32 0, i32 0
  %macro_name139 = load ptr, ptr %macro_name, align 8
  store ptr %macro_name139, ptr %name138, align 8
  %ptr_deref140 = load ptr, ptr %mdef, align 8
  %param_count141 = getelementptr inbounds nuw %macro_def_t, ptr %ptr_deref140, i32 0, i32 2
  %param_count142 = load i32, ptr %param_count, align 4
  store i32 %param_count142, ptr %param_count141, align 4
  %ptr_deref143 = load ptr, ptr %mdef, align 8
  %template_toks = getelementptr inbounds nuw %macro_def_t, ptr %ptr_deref143, i32 0, i32 3
  %tpl144 = load ptr, ptr %tpl, align 8
  store ptr %tpl144, ptr %template_toks, align 8
  %ptr_deref145 = load ptr, ptr %mdef, align 8
  %template_len = getelementptr inbounds nuw %macro_def_t, ptr %ptr_deref145, i32 0, i32 4
  %tpl_len146 = load i32, ptr %tpl_len, align 4
  store i32 %tpl_len146, ptr %template_len, align 4
  %ptr_deref147 = load ptr, ptr %mdef, align 8
  %param_names = getelementptr inbounds nuw %macro_def_t, ptr %ptr_deref147, i32 0, i32 1
  %pi = alloca i32, align 4
  store i32 0, ptr %pi, align 4
  br label %while_cond148

while_cond119:                                    ; preds = %if_merge131, %if_then117
  %depth_t122 = load i32, ptr %depth_t, align 4
  %icmp123 = icmp sgt i32 %depth_t122, 0
  %63 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool124 = icmp ne i8 %63, 0
  %not125 = xor i1 %tobool124, true
  %land126 = and i1 %icmp123, %not125
  br i1 %land126, label %while_body120, label %while_exit121

while_body120:                                    ; preds = %while_cond119
  %cur = alloca i8, align 1
  %64 = call i8 @parser_t__NS_peek_tok(ptr %self)
  store i8 %64, ptr %cur, align 1
  %tpl_len127 = load i32, ptr %tpl_len, align 4
  %tpl_cap128 = load i32, ptr %tpl_cap, align 4
  %icmp129 = icmp sge i32 %tpl_len127, %tpl_cap128
  br i1 %icmp129, label %if_then130, label %if_merge131

while_exit121:                                    ; preds = %while_cond119
  br label %if_merge118

if_then130:                                       ; preds = %while_body120
  %tpl_cap132 = load i32, ptr %tpl_cap, align 4
  %mul = mul i32 %tpl_cap132, 2
  store i32 %mul, ptr %tpl_cap, align 4
  br label %if_merge131

if_merge131:                                      ; preds = %if_then130, %while_body120
  %tpl_len133 = load i32, ptr %tpl_len, align 4
  %ptr_load = load ptr, ptr %tpl, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %tpl_len133
  %cur134 = load i8, ptr %cur, align 1
  store i8 %cur134, ptr %ptr_gep, align 1
  %tpl_len135 = load i32, ptr %tpl_len, align 4
  %add136 = add i32 %tpl_len135, 1
  store i32 %add136, ptr %tpl_len, align 4
  %65 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %while_cond119

while_cond148:                                    ; preds = %while_body149, %if_merge118
  %pi151 = load i32, ptr %pi, align 4
  %param_count152 = load i32, ptr %param_count, align 4
  %icmp153 = icmp slt i32 %pi151, %param_count152
  br i1 %icmp153, label %while_body149, label %while_exit150

while_body149:                                    ; preds = %while_cond148
  %ptr_deref154 = load ptr, ptr %mdef, align 8
  %param_names155 = getelementptr inbounds nuw %macro_def_t, ptr %ptr_deref154, i32 0, i32 1
  %pi156 = load i32, ptr %pi, align 4
  %ptr_load157 = load ptr, ptr %param_names155, align 8
  %ptr_gep158 = getelementptr i8, ptr %ptr_load157, i32 %pi156
  %pi159 = load i32, ptr %pi, align 4
  %arr_gep160 = getelementptr [16 x ptr], ptr %param_names_buf, i64 0, i32 %pi159
  %idx_load = load ptr, ptr %arr_gep160, align 8
  store ptr %idx_load, ptr %ptr_gep158, align 8
  %pi161 = load i32, ptr %pi, align 4
  %add162 = add i32 %pi161, 1
  store i32 %add162, ptr %pi, align 4
  br label %while_cond148

while_exit150:                                    ; preds = %while_cond148
  %ptr_deref163 = load ptr, ptr %self, align 8
  %macros_len = getelementptr inbounds nuw %parser_t, ptr %ptr_deref163, i32 0, i32 5
  %ptr_deref164 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %macros_len, align 4
  %ptr_deref165 = load ptr, ptr %self, align 8
  %macros_cap = getelementptr inbounds nuw %parser_t, ptr %ptr_deref165, i32 0, i32 6
  %ptr_deref166 = load ptr, ptr %self, align 8
  %mem_load167 = load i32, ptr %macros_cap, align 4
  %icmp168 = icmp sge i32 %mem_load, %mem_load167
  br i1 %icmp168, label %if_then169, label %if_merge170

if_then169:                                       ; preds = %while_exit150
  %ptr_deref171 = load ptr, ptr %self, align 8
  %macros_cap172 = getelementptr inbounds nuw %parser_t, ptr %ptr_deref171, i32 0, i32 6
  %ptr_deref173 = load ptr, ptr %self, align 8
  %macros_cap174 = getelementptr inbounds nuw %parser_t, ptr %ptr_deref173, i32 0, i32 6
  %ptr_deref175 = load ptr, ptr %self, align 8
  %mem_load176 = load i32, ptr %macros_cap174, align 4
  %mul177 = mul i32 %mem_load176, 2
  store i32 %mul177, ptr %macros_cap172, align 4
  %ptr_deref178 = load ptr, ptr %self, align 8
  %macros = getelementptr inbounds nuw %parser_t, ptr %ptr_deref178, i32 0, i32 4
  br label %if_merge170

if_merge170:                                      ; preds = %if_then169, %while_exit150
  %ptr_deref179 = load ptr, ptr %self, align 8
  %macros180 = getelementptr inbounds nuw %parser_t, ptr %ptr_deref179, i32 0, i32 4
  %ptr_deref181 = load ptr, ptr %self, align 8
  %macros_len182 = getelementptr inbounds nuw %parser_t, ptr %ptr_deref181, i32 0, i32 5
  %ptr_deref183 = load ptr, ptr %self, align 8
  %mem_load184 = load i32, ptr %macros_len182, align 4
  %ptr_load185 = load ptr, ptr %macros180, align 8
  %ptr_gep186 = getelementptr i8, ptr %ptr_load185, i32 %mem_load184
  %mdef187 = load ptr, ptr %mdef, align 8
  store ptr %mdef187, ptr %ptr_gep186, align 8
  %ptr_deref188 = load ptr, ptr %self, align 8
  %macros_len189 = getelementptr inbounds nuw %parser_t, ptr %ptr_deref188, i32 0, i32 5
  %ptr_deref190 = load ptr, ptr %self, align 8
  %macros_len191 = getelementptr inbounds nuw %parser_t, ptr %ptr_deref190, i32 0, i32 5
  %ptr_deref192 = load ptr, ptr %self, align 8
  %mem_load193 = load i32, ptr %macros_len191, align 4
  %add194 = add i32 %mem_load193, 1
  store i32 %add194, ptr %macros_len189, align 4
  %66 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond195 = icmp ne i8 %66, 0
  br i1 %if_cond195, label %if_then196, label %if_merge197

if_then196:                                       ; preds = %if_merge170
  %67 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %if_merge197

if_merge197:                                      ; preds = %if_then196, %if_merge170
  br label %while_cond55
}

define ptr @parser_t__NS_parse_block(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ln = alloca i64, align 8
  %1 = call i64 @parser_t__NS_peek_line(ptr %self)
  store i64 %1, ptr %ln, align 4
  %2 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.39)
  %blk = alloca ptr, align 8
  store ptr null, ptr %blk, align 8
  %ptr_deref = load ptr, ptr %blk, align 8
  %kind = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref, i32 0, i32 0
  %nd_block = load i32, ptr @ast_kind__nd_block, align 4
  store i32 %nd_block, ptr %kind, align 4
  %ptr_deref1 = load ptr, ptr %blk, align 8
  %line = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref1, i32 0, i32 1
  %ln2 = load i64, ptr %ln, align 4
  store i64 %ln2, ptr %line, align 4
  %stmts_cap = alloca i32, align 4
  store i32 16, ptr %stmts_cap, align 4
  %ptr_deref3 = load ptr, ptr %blk, align 8
  %stmts = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref3, i32 0, i32 2
  %ptr_deref4 = load ptr, ptr %blk, align 8
  %stmts_len = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref4, i32 0, i32 3
  store i32 0, ptr %stmts_len, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %3 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool = icmp ne i8 %3, 0
  %not = xor i1 %tobool, true
  %4 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool5 = icmp ne i8 %4, 0
  %not6 = xor i1 %tobool5, true
  %land = and i1 %not, %not6
  br i1 %land, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %s = alloca ptr, align 8
  %5 = call ptr @parser_t__NS_parse_stmt(ptr %self)
  store ptr %5, ptr %s, align 8
  %s7 = load ptr, ptr %s, align 8
  %icmp = icmp ne ptr %s7, null
  br i1 %icmp, label %if_then, label %if_merge

while_exit:                                       ; preds = %while_cond
  %6 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.40)
  %blk31 = load ptr, ptr %blk, align 8
  ret ptr %blk31

if_then:                                          ; preds = %while_body
  %ptr_deref8 = load ptr, ptr %blk, align 8
  %stmts_len9 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref8, i32 0, i32 3
  %ptr_deref10 = load ptr, ptr %blk, align 8
  %mem_load = load i32, ptr %stmts_len9, align 4
  %stmts_cap11 = load i32, ptr %stmts_cap, align 4
  %icmp12 = icmp sge i32 %mem_load, %stmts_cap11
  br i1 %icmp12, label %if_then13, label %if_merge14

if_merge:                                         ; preds = %if_merge14, %while_body
  br label %while_cond

if_then13:                                        ; preds = %if_then
  %stmts_cap15 = load i32, ptr %stmts_cap, align 4
  %mul = mul i32 %stmts_cap15, 2
  store i32 %mul, ptr %stmts_cap, align 4
  %ptr_deref16 = load ptr, ptr %blk, align 8
  %stmts17 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref16, i32 0, i32 2
  br label %if_merge14

if_merge14:                                       ; preds = %if_then13, %if_then
  %ptr_deref18 = load ptr, ptr %blk, align 8
  %stmts19 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref18, i32 0, i32 2
  %ptr_deref20 = load ptr, ptr %blk, align 8
  %stmts_len21 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref20, i32 0, i32 3
  %ptr_deref22 = load ptr, ptr %blk, align 8
  %mem_load23 = load i32, ptr %stmts_len21, align 4
  %ptr_load = load ptr, ptr %stmts19, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load23
  %s24 = load ptr, ptr %s, align 8
  store ptr %s24, ptr %ptr_gep, align 8
  %ptr_deref25 = load ptr, ptr %blk, align 8
  %stmts_len26 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref25, i32 0, i32 3
  %ptr_deref27 = load ptr, ptr %blk, align 8
  %stmts_len28 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref27, i32 0, i32 3
  %ptr_deref29 = load ptr, ptr %blk, align 8
  %mem_load30 = load i32, ptr %stmts_len28, align 4
  %add = add i32 %mem_load30, 1
  store i32 %add, ptr %stmts_len26, align 4
  br label %if_merge
}

define ptr @parser_t__NS_parse_local_var_decl(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %t = alloca ptr, align 8
  %1 = call ptr @parser_t__NS_parse_type(ptr %self)
  store ptr %1, ptr %t, align 8
  %2 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool = icmp ne i8 %2, 0
  %not = xor i1 %tobool, true
  br i1 %not, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %ptr_deref = load ptr, ptr %self, align 8
  %had_parse_error = getelementptr inbounds nuw %parser_t, ptr %ptr_deref, i32 0, i32 3
  store i8 1, ptr %had_parse_error, align 1
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  %name_tok = alloca i8, align 1
  %3 = call i8 @parser_t__NS_advance_tok(ptr %self)
  store i8 %3, ptr %name_tok, align 1
  %4 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %vd = alloca ptr, align 8
  store ptr null, ptr %vd, align 8
  %ptr_deref1 = load ptr, ptr %vd, align 8
  %kind = getelementptr inbounds nuw %var_decl, ptr %ptr_deref1, i32 0, i32 0
  %nd_var_decl = load i32, ptr @ast_kind__nd_var_decl, align 4
  store i32 %nd_var_decl, ptr %kind, align 4
  %ptr_deref2 = load ptr, ptr %vd, align 8
  %line = getelementptr inbounds nuw %var_decl, ptr %ptr_deref2, i32 0, i32 1
  %ptr_deref3 = load ptr, ptr %vd, align 8
  %type = getelementptr inbounds nuw %var_decl, ptr %ptr_deref3, i32 0, i32 2
  %t4 = load ptr, ptr %t, align 8
  store ptr %t4, ptr %type, align 8
  %ptr_deref5 = load ptr, ptr %vd, align 8
  %name = getelementptr inbounds nuw %var_decl, ptr %ptr_deref5, i32 0, i32 3
  %ptr_deref6 = load ptr, ptr %vd, align 8
  %is_sta = getelementptr inbounds nuw %var_decl, ptr %ptr_deref6, i32 0, i32 8
  %5 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %5, 0
  br i1 %if_cond, label %if_then7, label %if_merge8

if_then7:                                         ; preds = %if_merge
  %6 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool9 = icmp ne i8 %6, 0
  %not10 = xor i1 %tobool9, true
  br i1 %not10, label %if_then11, label %if_merge12

if_merge8:                                        ; preds = %if_merge12, %if_merge
  %7 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond13 = icmp ne i8 %7, 0
  br i1 %if_cond13, label %if_then14, label %if_else

if_then11:                                        ; preds = %if_then7
  %8 = call ptr @parser_t__NS_parse_expr(ptr %self)
  br label %if_merge12

if_merge12:                                       ; preds = %if_then11, %if_then7
  %9 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.41)
  br label %if_merge8

if_then14:                                        ; preds = %if_merge8
  %ptr_deref16 = load ptr, ptr %vd, align 8
  %has_ctor_parens = getelementptr inbounds nuw %var_decl, ptr %ptr_deref16, i32 0, i32 9
  store i8 1, ptr %has_ctor_parens, align 1
  %ctor_cap2 = alloca i32, align 4
  store i32 4, ptr %ctor_cap2, align 4
  %ptr_deref17 = load ptr, ptr %vd, align 8
  %ctor_args = getelementptr inbounds nuw %var_decl, ptr %ptr_deref17, i32 0, i32 10
  %ptr_deref18 = load ptr, ptr %vd, align 8
  %ctor_args_len = getelementptr inbounds nuw %var_decl, ptr %ptr_deref18, i32 0, i32 11
  store i32 0, ptr %ctor_args_len, align 4
  %10 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool19 = icmp ne i8 %10, 0
  %not20 = xor i1 %tobool19, true
  br i1 %not20, label %if_then21, label %if_merge22

if_else:                                          ; preds = %if_merge8
  %11 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond50 = icmp ne i8 %11, 0
  br i1 %if_cond50, label %if_then51, label %if_else52

if_merge15:                                       ; preds = %if_merge53, %if_merge22
  %12 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.44)
  %vd105 = load ptr, ptr %vd, align 8
  ret ptr %vd105

if_then21:                                        ; preds = %if_then14
  %p_ctor2 = alloca i8, align 1
  store i8 1, ptr %p_ctor2, align 1
  br label %while_cond

if_merge22:                                       ; preds = %while_exit, %if_then14
  %13 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.42)
  br label %if_merge15

while_cond:                                       ; preds = %if_merge49, %if_then21
  %p_ctor223 = load i8, ptr %p_ctor2, align 1
  %while_cond24 = icmp ne i8 %p_ctor223, 0
  br i1 %while_cond24, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ptr_deref25 = load ptr, ptr %vd, align 8
  %ctor_args_len26 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref25, i32 0, i32 11
  %ptr_deref27 = load ptr, ptr %vd, align 8
  %mem_load = load i32, ptr %ctor_args_len26, align 4
  %ctor_cap228 = load i32, ptr %ctor_cap2, align 4
  %icmp = icmp sge i32 %mem_load, %ctor_cap228
  br i1 %icmp, label %if_then29, label %if_merge30

while_exit:                                       ; preds = %while_cond
  br label %if_merge22

if_then29:                                        ; preds = %while_body
  %ctor_cap231 = load i32, ptr %ctor_cap2, align 4
  %mul = mul i32 %ctor_cap231, 2
  store i32 %mul, ptr %ctor_cap2, align 4
  %ptr_deref32 = load ptr, ptr %vd, align 8
  %ctor_args33 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref32, i32 0, i32 10
  br label %if_merge30

if_merge30:                                       ; preds = %if_then29, %while_body
  %ptr_deref34 = load ptr, ptr %vd, align 8
  %ctor_args35 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref34, i32 0, i32 10
  %ptr_deref36 = load ptr, ptr %vd, align 8
  %ctor_args_len37 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref36, i32 0, i32 11
  %ptr_deref38 = load ptr, ptr %vd, align 8
  %mem_load39 = load i32, ptr %ctor_args_len37, align 4
  %ptr_load = load ptr, ptr %ctor_args35, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load39
  %14 = call ptr @parser_t__NS_parse_assignment(ptr %self)
  store ptr %14, ptr %ptr_gep, align 8
  %ptr_deref40 = load ptr, ptr %vd, align 8
  %ctor_args_len41 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref40, i32 0, i32 11
  %ptr_deref42 = load ptr, ptr %vd, align 8
  %ctor_args_len43 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref42, i32 0, i32 11
  %ptr_deref44 = load ptr, ptr %vd, align 8
  %mem_load45 = load i32, ptr %ctor_args_len43, align 4
  %add = add i32 %mem_load45, 1
  store i32 %add, ptr %ctor_args_len41, align 4
  %15 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %tobool46 = icmp ne i8 %15, 0
  %not47 = xor i1 %tobool46, true
  br i1 %not47, label %if_then48, label %if_merge49

if_then48:                                        ; preds = %if_merge30
  store i8 0, ptr %p_ctor2, align 1
  br label %if_merge49

if_merge49:                                       ; preds = %if_then48, %if_merge30
  br label %while_cond

if_then51:                                        ; preds = %if_else
  %ptr_deref54 = load ptr, ptr %vd, align 8
  %has_ctor_parens55 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref54, i32 0, i32 9
  store i8 1, ptr %has_ctor_parens55, align 1
  %ctor_cap3 = alloca i32, align 4
  store i32 4, ptr %ctor_cap3, align 4
  %ptr_deref56 = load ptr, ptr %vd, align 8
  %ctor_args57 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref56, i32 0, i32 10
  %ptr_deref58 = load ptr, ptr %vd, align 8
  %ctor_args_len59 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref58, i32 0, i32 11
  store i32 0, ptr %ctor_args_len59, align 4
  %16 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool60 = icmp ne i8 %16, 0
  %not61 = xor i1 %tobool60, true
  br i1 %not61, label %if_then62, label %if_merge63

if_else52:                                        ; preds = %if_else
  %17 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond100 = icmp ne i8 %17, 0
  br i1 %if_cond100, label %if_then101, label %if_merge102

if_merge53:                                       ; preds = %if_merge102, %if_merge63
  br label %if_merge15

if_then62:                                        ; preds = %if_then51
  %p_ctor3 = alloca i8, align 1
  store i8 1, ptr %p_ctor3, align 1
  br label %while_cond64

if_merge63:                                       ; preds = %while_exit66, %if_then51
  %18 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.43)
  br label %if_merge53

while_cond64:                                     ; preds = %if_merge99, %if_then62
  %p_ctor367 = load i8, ptr %p_ctor3, align 1
  %while_cond68 = icmp ne i8 %p_ctor367, 0
  br i1 %while_cond68, label %while_body65, label %while_exit66

while_body65:                                     ; preds = %while_cond64
  %ptr_deref69 = load ptr, ptr %vd, align 8
  %ctor_args_len70 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref69, i32 0, i32 11
  %ptr_deref71 = load ptr, ptr %vd, align 8
  %mem_load72 = load i32, ptr %ctor_args_len70, align 4
  %ctor_cap373 = load i32, ptr %ctor_cap3, align 4
  %icmp74 = icmp sge i32 %mem_load72, %ctor_cap373
  br i1 %icmp74, label %if_then75, label %if_merge76

while_exit66:                                     ; preds = %while_cond64
  br label %if_merge63

if_then75:                                        ; preds = %while_body65
  %ctor_cap377 = load i32, ptr %ctor_cap3, align 4
  %mul78 = mul i32 %ctor_cap377, 2
  store i32 %mul78, ptr %ctor_cap3, align 4
  %ptr_deref79 = load ptr, ptr %vd, align 8
  %ctor_args80 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref79, i32 0, i32 10
  br label %if_merge76

if_merge76:                                       ; preds = %if_then75, %while_body65
  %ptr_deref81 = load ptr, ptr %vd, align 8
  %ctor_args82 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref81, i32 0, i32 10
  %ptr_deref83 = load ptr, ptr %vd, align 8
  %ctor_args_len84 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref83, i32 0, i32 11
  %ptr_deref85 = load ptr, ptr %vd, align 8
  %mem_load86 = load i32, ptr %ctor_args_len84, align 4
  %ptr_load87 = load ptr, ptr %ctor_args82, align 8
  %ptr_gep88 = getelementptr i8, ptr %ptr_load87, i32 %mem_load86
  %19 = call ptr @parser_t__NS_parse_assignment(ptr %self)
  store ptr %19, ptr %ptr_gep88, align 8
  %ptr_deref89 = load ptr, ptr %vd, align 8
  %ctor_args_len90 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref89, i32 0, i32 11
  %ptr_deref91 = load ptr, ptr %vd, align 8
  %ctor_args_len92 = getelementptr inbounds nuw %var_decl, ptr %ptr_deref91, i32 0, i32 11
  %ptr_deref93 = load ptr, ptr %vd, align 8
  %mem_load94 = load i32, ptr %ctor_args_len92, align 4
  %add95 = add i32 %mem_load94, 1
  store i32 %add95, ptr %ctor_args_len90, align 4
  %20 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %tobool96 = icmp ne i8 %20, 0
  %not97 = xor i1 %tobool96, true
  br i1 %not97, label %if_then98, label %if_merge99

if_then98:                                        ; preds = %if_merge76
  store i8 0, ptr %p_ctor3, align 1
  br label %if_merge99

if_merge99:                                       ; preds = %if_then98, %if_merge76
  br label %while_cond64

if_then101:                                       ; preds = %if_else52
  %ptr_deref103 = load ptr, ptr %vd, align 8
  %init = getelementptr inbounds nuw %var_decl, ptr %ptr_deref103, i32 0, i32 4
  %21 = call ptr @parser_t__NS_parse_expr(ptr %self)
  store ptr %21, ptr %init, align 8
  %ptr_deref104 = load ptr, ptr %vd, align 8
  %has_init = getelementptr inbounds nuw %var_decl, ptr %ptr_deref104, i32 0, i32 5
  store i8 1, ptr %has_init, align 1
  br label %if_merge102

if_merge102:                                      ; preds = %if_then101, %if_else52
  br label %if_merge53
}

define ptr @parser_t__NS_parse_if_stmt(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ptr_deref = load ptr, ptr %n, align 8
  %kind = getelementptr inbounds nuw %if_stmt, ptr %ptr_deref, i32 0, i32 0
  %nd_if_stmt = load i32, ptr @ast_kind__nd_if_stmt, align 4
  store i32 %nd_if_stmt, ptr %kind, align 4
  %ptr_deref1 = load ptr, ptr %n, align 8
  %line = getelementptr inbounds nuw %if_stmt, ptr %ptr_deref1, i32 0, i32 1
  %1 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %1, ptr %line, align 4
  %2 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %2, 0
  br i1 %if_cond, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %3 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %ptr_deref2 = load ptr, ptr %n, align 8
  %is_constexpr = getelementptr inbounds nuw %if_stmt, ptr %ptr_deref2, i32 0, i32 5
  store i8 1, ptr %is_constexpr, align 1
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  %has_parens = alloca i8, align 1
  %4 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  store i8 %4, ptr %has_parens, align 1
  %ptr_deref3 = load ptr, ptr %n, align 8
  %cond = getelementptr inbounds nuw %if_stmt, ptr %ptr_deref3, i32 0, i32 2
  %5 = call ptr @parser_t__NS_parse_expr(ptr %self)
  store ptr %5, ptr %cond, align 8
  %has_parens4 = load i8, ptr %has_parens, align 1
  %if_cond5 = icmp ne i8 %has_parens4, 0
  br i1 %if_cond5, label %if_then6, label %if_merge7

if_then6:                                         ; preds = %if_merge
  %6 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.45)
  br label %if_merge7

if_merge7:                                        ; preds = %if_then6, %if_merge
  %7 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond8 = icmp ne i8 %7, 0
  br i1 %if_cond8, label %if_then9, label %if_merge10

if_then9:                                         ; preds = %if_merge7
  %ptr_deref11 = load ptr, ptr %n, align 8
  %then_capture = getelementptr inbounds nuw %if_stmt, ptr %ptr_deref11, i32 0, i32 6
  %8 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.46)
  br label %if_merge10

if_merge10:                                       ; preds = %if_then9, %if_merge7
  %ptr_deref12 = load ptr, ptr %n, align 8
  %then_body = getelementptr inbounds nuw %if_stmt, ptr %ptr_deref12, i32 0, i32 3
  %9 = call ptr @parser_t__NS_parse_stmt(ptr %self)
  store ptr %9, ptr %then_body, align 8
  %10 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond13 = icmp ne i8 %10, 0
  br i1 %if_cond13, label %if_then14, label %if_merge15

if_then14:                                        ; preds = %if_merge10
  %11 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond16 = icmp ne i8 %11, 0
  br i1 %if_cond16, label %if_then17, label %if_merge18

if_merge15:                                       ; preds = %if_merge18, %if_merge10
  %n21 = load ptr, ptr %n, align 8
  ret ptr %n21

if_then17:                                        ; preds = %if_then14
  %ptr_deref19 = load ptr, ptr %n, align 8
  %else_capture = getelementptr inbounds nuw %if_stmt, ptr %ptr_deref19, i32 0, i32 7
  %12 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.47)
  br label %if_merge18

if_merge18:                                       ; preds = %if_then17, %if_then14
  %ptr_deref20 = load ptr, ptr %n, align 8
  %else_body = getelementptr inbounds nuw %if_stmt, ptr %ptr_deref20, i32 0, i32 4
  %13 = call ptr @parser_t__NS_parse_stmt(ptr %self)
  store ptr %13, ptr %else_body, align 8
  br label %if_merge15
}

define ptr @parser_t__NS_parse_while_stmt(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ptr_deref = load ptr, ptr %n, align 8
  %kind = getelementptr inbounds nuw %while_stmt, ptr %ptr_deref, i32 0, i32 0
  %nd_while_stmt = load i32, ptr @ast_kind__nd_while_stmt, align 4
  store i32 %nd_while_stmt, ptr %kind, align 4
  %ptr_deref1 = load ptr, ptr %n, align 8
  %line = getelementptr inbounds nuw %while_stmt, ptr %ptr_deref1, i32 0, i32 1
  %1 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %1, ptr %line, align 4
  %has_parens = alloca i8, align 1
  %2 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  store i8 %2, ptr %has_parens, align 1
  %ptr_deref2 = load ptr, ptr %n, align 8
  %cond = getelementptr inbounds nuw %while_stmt, ptr %ptr_deref2, i32 0, i32 2
  %3 = call ptr @parser_t__NS_parse_expr(ptr %self)
  store ptr %3, ptr %cond, align 8
  %has_parens3 = load i8, ptr %has_parens, align 1
  %if_cond = icmp ne i8 %has_parens3, 0
  br i1 %if_cond, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %4 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.48)
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  %ptr_deref4 = load ptr, ptr %n, align 8
  %body = getelementptr inbounds nuw %while_stmt, ptr %ptr_deref4, i32 0, i32 3
  %5 = call ptr @parser_t__NS_parse_stmt(ptr %self)
  store ptr %5, ptr %body, align 8
  %n5 = load ptr, ptr %n, align 8
  ret ptr %n5
}

define ptr @parser_t__NS_parse_for_stmt(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ln = alloca i64, align 8
  %1 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %1, ptr %ln, align 4
  %has_parens = alloca i8, align 1
  %2 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  store i8 %2, ptr %has_parens, align 1
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ptr_deref = load ptr, ptr %n, align 8
  %kind = getelementptr inbounds nuw %for_stmt, ptr %ptr_deref, i32 0, i32 0
  %nd_for_stmt = load i32, ptr @ast_kind__nd_for_stmt, align 4
  store i32 %nd_for_stmt, ptr %kind, align 4
  %ptr_deref1 = load ptr, ptr %n, align 8
  %line = getelementptr inbounds nuw %for_stmt, ptr %ptr_deref1, i32 0, i32 1
  %ln2 = load i64, ptr %ln, align 4
  store i64 %ln2, ptr %line, align 4
  %3 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool = icmp ne i8 %3, 0
  %not = xor i1 %tobool, true
  br i1 %not, label %if_then, label %if_else

if_then:                                          ; preds = %entry
  %4 = call i8 @parser_t__NS_is_type_start(ptr %self)
  %if_cond = icmp ne i8 %4, 0
  br i1 %if_cond, label %if_then3, label %if_else4

if_else:                                          ; preds = %entry
  %5 = call i8 @parser_t__NS_advance_tok(ptr %self)
  br label %if_merge

if_merge:                                         ; preds = %if_else, %if_merge5
  %6 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool13 = icmp ne i8 %6, 0
  %not14 = xor i1 %tobool13, true
  br i1 %not14, label %if_then15, label %if_merge16

if_then3:                                         ; preds = %if_then
  %ptr_deref6 = load ptr, ptr %n, align 8
  %init = getelementptr inbounds nuw %for_stmt, ptr %ptr_deref6, i32 0, i32 2
  %7 = call ptr @parser_t__NS_parse_local_var_decl(ptr %self)
  store ptr %7, ptr %init, align 8
  br label %if_merge5

if_else4:                                         ; preds = %if_then
  %es = alloca ptr, align 8
  store ptr null, ptr %es, align 8
  %ptr_deref7 = load ptr, ptr %es, align 8
  %kind8 = getelementptr inbounds nuw %expr_stmt, ptr %ptr_deref7, i32 0, i32 0
  %nd_expr_stmt = load i32, ptr @ast_kind__nd_expr_stmt, align 4
  store i32 %nd_expr_stmt, ptr %kind8, align 4
  %ptr_deref9 = load ptr, ptr %es, align 8
  %expr = getelementptr inbounds nuw %expr_stmt, ptr %ptr_deref9, i32 0, i32 2
  %8 = call ptr @parser_t__NS_parse_expr(ptr %self)
  store ptr %8, ptr %expr, align 8
  %9 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.49)
  %ptr_deref10 = load ptr, ptr %n, align 8
  %init11 = getelementptr inbounds nuw %for_stmt, ptr %ptr_deref10, i32 0, i32 2
  %es12 = load ptr, ptr %es, align 8
  store ptr %es12, ptr %init11, align 8
  br label %if_merge5

if_merge5:                                        ; preds = %if_else4, %if_then3
  br label %if_merge

if_then15:                                        ; preds = %if_merge
  %ptr_deref17 = load ptr, ptr %n, align 8
  %cond = getelementptr inbounds nuw %for_stmt, ptr %ptr_deref17, i32 0, i32 3
  %10 = call ptr @parser_t__NS_parse_expr(ptr %self)
  store ptr %10, ptr %cond, align 8
  br label %if_merge16

if_merge16:                                       ; preds = %if_then15, %if_merge
  %11 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.50)
  %no_step = alloca i8, align 1
  %has_parens18 = load i8, ptr %has_parens, align 1
  %tobool19 = icmp ne i8 %has_parens18, 0
  br i1 %tobool19, label %tern_then, label %tern_else

tern_then:                                        ; preds = %if_merge16
  %12 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  br label %tern_merge

tern_else:                                        ; preds = %if_merge16
  %13 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  br label %tern_merge

tern_merge:                                       ; preds = %tern_else, %tern_then
  %tern = phi i8 [ %12, %tern_then ], [ %13, %tern_else ]
  store i8 %tern, ptr %no_step, align 1
  %no_step20 = load i8, ptr %no_step, align 1
  %tobool21 = icmp ne i8 %no_step20, 0
  %not22 = xor i1 %tobool21, true
  br i1 %not22, label %if_then23, label %if_merge24

if_then23:                                        ; preds = %tern_merge
  %ptr_deref25 = load ptr, ptr %n, align 8
  %step = getelementptr inbounds nuw %for_stmt, ptr %ptr_deref25, i32 0, i32 4
  %14 = call ptr @parser_t__NS_parse_expr(ptr %self)
  store ptr %14, ptr %step, align 8
  br label %if_merge24

if_merge24:                                       ; preds = %if_then23, %tern_merge
  %has_parens26 = load i8, ptr %has_parens, align 1
  %if_cond27 = icmp ne i8 %has_parens26, 0
  br i1 %if_cond27, label %if_then28, label %if_merge29

if_then28:                                        ; preds = %if_merge24
  %15 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.51)
  br label %if_merge29

if_merge29:                                       ; preds = %if_then28, %if_merge24
  %ptr_deref30 = load ptr, ptr %n, align 8
  %body = getelementptr inbounds nuw %for_stmt, ptr %ptr_deref30, i32 0, i32 5
  %16 = call ptr @parser_t__NS_parse_stmt(ptr %self)
  store ptr %16, ptr %body, align 8
  %n31 = load ptr, ptr %n, align 8
  ret ptr %n31
}

define ptr @parser_t__NS_parse_switch_stmt(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ptr_deref = load ptr, ptr %n, align 8
  %kind = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref, i32 0, i32 0
  %nd_switch_stmt = load i32, ptr @ast_kind__nd_switch_stmt, align 4
  store i32 %nd_switch_stmt, ptr %kind, align 4
  %ptr_deref1 = load ptr, ptr %n, align 8
  %line = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref1, i32 0, i32 1
  %1 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %1, ptr %line, align 4
  %has_parens = alloca i8, align 1
  %2 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  store i8 %2, ptr %has_parens, align 1
  %ptr_deref2 = load ptr, ptr %n, align 8
  %val = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref2, i32 0, i32 2
  %3 = call ptr @parser_t__NS_parse_expr(ptr %self)
  store ptr %3, ptr %val, align 8
  %has_parens3 = load i8, ptr %has_parens, align 1
  %if_cond = icmp ne i8 %has_parens3, 0
  br i1 %if_cond, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %4 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.52)
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  %5 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.53)
  %cases_cap = alloca i32, align 4
  store i32 8, ptr %cases_cap, align 4
  %ptr_deref4 = load ptr, ptr %n, align 8
  %case_vals = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref4, i32 0, i32 3
  %ptr_deref5 = load ptr, ptr %n, align 8
  %case_bodies = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref5, i32 0, i32 4
  %ptr_deref6 = load ptr, ptr %n, align 8
  %case_is_default = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref6, i32 0, i32 5
  %ptr_deref7 = load ptr, ptr %n, align 8
  %cases_len = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref7, i32 0, i32 6
  store i32 0, ptr %cases_len, align 4
  %ptr_deref8 = load ptr, ptr %n, align 8
  %cases_cap9 = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref8, i32 0, i32 7
  %cases_cap10 = load i32, ptr %cases_cap, align 4
  store i32 %cases_cap10, ptr %cases_cap9, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge68, %if_merge
  %6 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool = icmp ne i8 %6, 0
  %not = xor i1 %tobool, true
  %7 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool11 = icmp ne i8 %7, 0
  %not12 = xor i1 %tobool11, true
  %land = and i1 %not, %not12
  br i1 %land, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %is_default = alloca i8, align 1
  store i8 0, ptr %is_default, align 1
  %case_val = alloca ptr, align 8
  store ptr null, ptr %case_val, align 8
  %8 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %if_cond13 = icmp ne i8 %8, 0
  br i1 %if_cond13, label %if_then14, label %if_else

while_exit:                                       ; preds = %while_cond
  %9 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.56)
  %n116 = load ptr, ptr %n, align 8
  ret ptr %n116

if_then14:                                        ; preds = %while_body
  %10 = call ptr @parser_t__NS_parse_expr(ptr %self)
  store ptr %10, ptr %case_val, align 8
  br label %if_merge15

if_else:                                          ; preds = %while_body
  %11 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.54)
  store i8 1, ptr %is_default, align 1
  br label %if_merge15

if_merge15:                                       ; preds = %if_else, %if_then14
  %12 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.55)
  %body = alloca ptr, align 8
  store ptr null, ptr %body, align 8
  %ptr_deref16 = load ptr, ptr %body, align 8
  %kind17 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref16, i32 0, i32 0
  %nd_block = load i32, ptr @ast_kind__nd_block, align 4
  store i32 %nd_block, ptr %kind17, align 4
  %body_cap = alloca i32, align 4
  store i32 8, ptr %body_cap, align 4
  %ptr_deref18 = load ptr, ptr %body, align 8
  %stmts = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref18, i32 0, i32 2
  br label %while_cond19

while_cond19:                                     ; preds = %if_merge35, %if_merge15
  %13 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool22 = icmp ne i8 %13, 0
  %not23 = xor i1 %tobool22, true
  %14 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool24 = icmp ne i8 %14, 0
  %not25 = xor i1 %tobool24, true
  %land26 = and i1 %not23, %not25
  %15 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool27 = icmp ne i8 %15, 0
  %not28 = xor i1 %tobool27, true
  %land29 = and i1 %land26, %not28
  %16 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool30 = icmp ne i8 %16, 0
  %not31 = xor i1 %tobool30, true
  %land32 = and i1 %land29, %not31
  br i1 %land32, label %while_body20, label %while_exit21

while_body20:                                     ; preds = %while_cond19
  %s = alloca ptr, align 8
  %17 = call ptr @parser_t__NS_parse_stmt(ptr %self)
  store ptr %17, ptr %s, align 8
  %s33 = load ptr, ptr %s, align 8
  %icmp = icmp ne ptr %s33, null
  br i1 %icmp, label %if_then34, label %if_merge35

while_exit21:                                     ; preds = %while_cond19
  %ptr_deref58 = load ptr, ptr %n, align 8
  %cases_len59 = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref58, i32 0, i32 6
  %ptr_deref60 = load ptr, ptr %n, align 8
  %mem_load61 = load i32, ptr %cases_len59, align 4
  %ptr_deref62 = load ptr, ptr %n, align 8
  %cases_cap63 = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref62, i32 0, i32 7
  %ptr_deref64 = load ptr, ptr %n, align 8
  %mem_load65 = load i32, ptr %cases_cap63, align 4
  %icmp66 = icmp sge i32 %mem_load61, %mem_load65
  br i1 %icmp66, label %if_then67, label %if_merge68

if_then34:                                        ; preds = %while_body20
  %ptr_deref36 = load ptr, ptr %body, align 8
  %stmts_len = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref36, i32 0, i32 3
  %ptr_deref37 = load ptr, ptr %body, align 8
  %mem_load = load i32, ptr %stmts_len, align 4
  %body_cap38 = load i32, ptr %body_cap, align 4
  %icmp39 = icmp sge i32 %mem_load, %body_cap38
  br i1 %icmp39, label %if_then40, label %if_merge41

if_merge35:                                       ; preds = %if_merge41, %while_body20
  br label %while_cond19

if_then40:                                        ; preds = %if_then34
  %body_cap42 = load i32, ptr %body_cap, align 4
  %mul = mul i32 %body_cap42, 2
  store i32 %mul, ptr %body_cap, align 4
  %ptr_deref43 = load ptr, ptr %body, align 8
  %stmts44 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref43, i32 0, i32 2
  br label %if_merge41

if_merge41:                                       ; preds = %if_then40, %if_then34
  %ptr_deref45 = load ptr, ptr %body, align 8
  %stmts46 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref45, i32 0, i32 2
  %ptr_deref47 = load ptr, ptr %body, align 8
  %stmts_len48 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref47, i32 0, i32 3
  %ptr_deref49 = load ptr, ptr %body, align 8
  %mem_load50 = load i32, ptr %stmts_len48, align 4
  %ptr_load = load ptr, ptr %stmts46, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load50
  %s51 = load ptr, ptr %s, align 8
  store ptr %s51, ptr %ptr_gep, align 8
  %ptr_deref52 = load ptr, ptr %body, align 8
  %stmts_len53 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref52, i32 0, i32 3
  %ptr_deref54 = load ptr, ptr %body, align 8
  %stmts_len55 = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref54, i32 0, i32 3
  %ptr_deref56 = load ptr, ptr %body, align 8
  %mem_load57 = load i32, ptr %stmts_len55, align 4
  %add = add i32 %mem_load57, 1
  store i32 %add, ptr %stmts_len53, align 4
  br label %if_merge35

if_then67:                                        ; preds = %while_exit21
  %ptr_deref69 = load ptr, ptr %n, align 8
  %cases_cap70 = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref69, i32 0, i32 7
  %ptr_deref71 = load ptr, ptr %n, align 8
  %cases_cap72 = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref71, i32 0, i32 7
  %ptr_deref73 = load ptr, ptr %n, align 8
  %mem_load74 = load i32, ptr %cases_cap72, align 4
  %mul75 = mul i32 %mem_load74, 2
  store i32 %mul75, ptr %cases_cap70, align 4
  %ptr_deref76 = load ptr, ptr %n, align 8
  %case_vals77 = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref76, i32 0, i32 3
  %ptr_deref78 = load ptr, ptr %n, align 8
  %case_bodies79 = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref78, i32 0, i32 4
  %ptr_deref80 = load ptr, ptr %n, align 8
  %case_is_default81 = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref80, i32 0, i32 5
  br label %if_merge68

if_merge68:                                       ; preds = %if_then67, %while_exit21
  %ptr_deref82 = load ptr, ptr %n, align 8
  %case_vals83 = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref82, i32 0, i32 3
  %ptr_deref84 = load ptr, ptr %n, align 8
  %cases_len85 = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref84, i32 0, i32 6
  %ptr_deref86 = load ptr, ptr %n, align 8
  %mem_load87 = load i32, ptr %cases_len85, align 4
  %ptr_load88 = load ptr, ptr %case_vals83, align 8
  %ptr_gep89 = getelementptr i8, ptr %ptr_load88, i32 %mem_load87
  %case_val90 = load ptr, ptr %case_val, align 8
  store ptr %case_val90, ptr %ptr_gep89, align 8
  %ptr_deref91 = load ptr, ptr %n, align 8
  %case_bodies92 = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref91, i32 0, i32 4
  %ptr_deref93 = load ptr, ptr %n, align 8
  %cases_len94 = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref93, i32 0, i32 6
  %ptr_deref95 = load ptr, ptr %n, align 8
  %mem_load96 = load i32, ptr %cases_len94, align 4
  %ptr_load97 = load ptr, ptr %case_bodies92, align 8
  %ptr_gep98 = getelementptr i8, ptr %ptr_load97, i32 %mem_load96
  %body99 = load ptr, ptr %body, align 8
  store ptr %body99, ptr %ptr_gep98, align 8
  %ptr_deref100 = load ptr, ptr %n, align 8
  %case_is_default101 = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref100, i32 0, i32 5
  %ptr_deref102 = load ptr, ptr %n, align 8
  %cases_len103 = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref102, i32 0, i32 6
  %ptr_deref104 = load ptr, ptr %n, align 8
  %mem_load105 = load i32, ptr %cases_len103, align 4
  %ptr_load106 = load ptr, ptr %case_is_default101, align 8
  %ptr_gep107 = getelementptr i8, ptr %ptr_load106, i32 %mem_load105
  %is_default108 = load i8, ptr %is_default, align 1
  %i2p = inttoptr i8 %is_default108 to ptr
  store ptr %i2p, ptr %ptr_gep107, align 8
  %ptr_deref109 = load ptr, ptr %n, align 8
  %cases_len110 = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref109, i32 0, i32 6
  %ptr_deref111 = load ptr, ptr %n, align 8
  %cases_len112 = getelementptr inbounds nuw %switch_stmt, ptr %ptr_deref111, i32 0, i32 6
  %ptr_deref113 = load ptr, ptr %n, align 8
  %mem_load114 = load i32, ptr %cases_len112, align 4
  %add115 = add i32 %mem_load114, 1
  store i32 %add115, ptr %cases_len110, align 4
  br label %while_cond
}

define ptr @parser_t__NS_parse_return_stmt(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ptr_deref = load ptr, ptr %n, align 8
  %kind = getelementptr inbounds nuw %return_stmt, ptr %ptr_deref, i32 0, i32 0
  %nd_return_stmt = load i32, ptr @ast_kind__nd_return_stmt, align 4
  store i32 %nd_return_stmt, ptr %kind, align 4
  %ptr_deref1 = load ptr, ptr %n, align 8
  %line = getelementptr inbounds nuw %return_stmt, ptr %ptr_deref1, i32 0, i32 1
  %1 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %1, ptr %line, align 4
  %2 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool = icmp ne i8 %2, 0
  %not = xor i1 %tobool, true
  br i1 %not, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %ptr_deref2 = load ptr, ptr %n, align 8
  %val = getelementptr inbounds nuw %return_stmt, ptr %ptr_deref2, i32 0, i32 2
  %3 = call ptr @parser_t__NS_parse_expr(ptr %self)
  store ptr %3, ptr %val, align 8
  %ptr_deref3 = load ptr, ptr %n, align 8
  %has_val = getelementptr inbounds nuw %return_stmt, ptr %ptr_deref3, i32 0, i32 3
  store i8 1, ptr %has_val, align 1
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  %4 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.57)
  %n4 = load ptr, ptr %n, align 8
  ret ptr %n4
}

define ptr @parser_t__NS_parse_defer_stmt(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ptr_deref = load ptr, ptr %n, align 8
  %kind = getelementptr inbounds nuw %defer_stmt, ptr %ptr_deref, i32 0, i32 0
  %1 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %tobool = icmp ne i8 %1, 0
  br i1 %tobool, label %tern_then, label %tern_else

tern_then:                                        ; preds = %entry
  %nd_errdefer_stmt = load i32, ptr @ast_kind__nd_errdefer_stmt, align 4
  br label %tern_merge

tern_else:                                        ; preds = %entry
  %nd_defer_stmt = load i32, ptr @ast_kind__nd_defer_stmt, align 4
  br label %tern_merge

tern_merge:                                       ; preds = %tern_else, %tern_then
  %tern = phi i32 [ %nd_errdefer_stmt, %tern_then ], [ %nd_defer_stmt, %tern_else ]
  store i32 %tern, ptr %kind, align 4
  %ptr_deref1 = load ptr, ptr %n, align 8
  %line = getelementptr inbounds nuw %defer_stmt, ptr %ptr_deref1, i32 0, i32 1
  %2 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %2, ptr %line, align 4
  %3 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %3, 0
  br i1 %if_cond, label %if_then, label %if_else

if_then:                                          ; preds = %tern_merge
  %ptr_deref2 = load ptr, ptr %n, align 8
  %blk = getelementptr inbounds nuw %defer_stmt, ptr %ptr_deref2, i32 0, i32 3
  %4 = call ptr @parser_t__NS_parse_block(ptr %self)
  store ptr %4, ptr %blk, align 8
  %ptr_deref3 = load ptr, ptr %n, align 8
  %is_block = getelementptr inbounds nuw %defer_stmt, ptr %ptr_deref3, i32 0, i32 4
  store i8 1, ptr %is_block, align 1
  br label %if_merge

if_else:                                          ; preds = %tern_merge
  %ptr_deref4 = load ptr, ptr %n, align 8
  %expr = getelementptr inbounds nuw %defer_stmt, ptr %ptr_deref4, i32 0, i32 2
  %5 = call ptr @parser_t__NS_parse_expr(ptr %self)
  store ptr %5, ptr %expr, align 8
  %6 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.58)
  br label %if_merge

if_merge:                                         ; preds = %if_else, %if_then
  %n5 = load ptr, ptr %n, align 8
  ret ptr %n5
}

define ptr @parser_t__NS_parse_stmt(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %1 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %1, 0
  br i1 %if_cond, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %blk = alloca ptr, align 8
  store ptr null, ptr %blk, align 8
  %ptr_deref = load ptr, ptr %blk, align 8
  %kind = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref, i32 0, i32 0
  %nd_block = load i32, ptr @ast_kind__nd_block, align 4
  store i32 %nd_block, ptr %kind, align 4
  %ptr_deref1 = load ptr, ptr %blk, align 8
  %line = getelementptr inbounds nuw %block_stmt, ptr %ptr_deref1, i32 0, i32 1
  %2 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %2, ptr %line, align 4
  %blk2 = load ptr, ptr %blk, align 8
  ret ptr %blk2

if_merge:                                         ; preds = %entry
  %3 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond3 = icmp ne i8 %3, 0
  br i1 %if_cond3, label %if_then4, label %if_merge5

if_then4:                                         ; preds = %if_merge
  %4 = call ptr @parser_t__NS_parse_block(ptr %self)
  ret ptr %4

if_merge5:                                        ; preds = %if_merge
  %5 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond6 = icmp ne i8 %5, 0
  br i1 %if_cond6, label %if_then7, label %if_merge8

if_then7:                                         ; preds = %if_merge5
  %6 = call ptr @parser_t__NS_parse_if_stmt(ptr %self)
  ret ptr %6

if_merge8:                                        ; preds = %if_merge5
  %7 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond9 = icmp ne i8 %7, 0
  br i1 %if_cond9, label %if_then10, label %if_merge11

if_then10:                                        ; preds = %if_merge8
  %8 = call ptr @parser_t__NS_parse_while_stmt(ptr %self)
  ret ptr %8

if_merge11:                                       ; preds = %if_merge8
  %9 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond12 = icmp ne i8 %9, 0
  br i1 %if_cond12, label %if_then13, label %if_merge14

if_then13:                                        ; preds = %if_merge11
  %10 = call ptr @parser_t__NS_parse_for_stmt(ptr %self)
  ret ptr %10

if_merge14:                                       ; preds = %if_merge11
  %11 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond15 = icmp ne i8 %11, 0
  br i1 %if_cond15, label %if_then16, label %if_merge17

if_then16:                                        ; preds = %if_merge14
  %12 = call ptr @parser_t__NS_parse_switch_stmt(ptr %self)
  ret ptr %12

if_merge17:                                       ; preds = %if_merge14
  %13 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond18 = icmp ne i8 %13, 0
  br i1 %if_cond18, label %if_then19, label %if_merge20

if_then19:                                        ; preds = %if_merge17
  %14 = call ptr @parser_t__NS_parse_return_stmt(ptr %self)
  ret ptr %14

if_merge20:                                       ; preds = %if_merge17
  %15 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond21 = icmp ne i8 %15, 0
  br i1 %if_cond21, label %if_then22, label %if_merge23

if_then22:                                        ; preds = %if_merge20
  %16 = call ptr @parser_t__NS_parse_defer_stmt(ptr %self)
  ret ptr %16

if_merge23:                                       ; preds = %if_merge20
  %17 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond24 = icmp ne i8 %17, 0
  br i1 %if_cond24, label %if_then25, label %if_merge26

if_then25:                                        ; preds = %if_merge23
  %18 = call ptr @parser_t__NS_parse_defer_stmt(ptr %self)
  ret ptr %18

if_merge26:                                       ; preds = %if_merge23
  %19 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond27 = icmp ne i8 %19, 0
  br i1 %if_cond27, label %if_then28, label %if_merge29

if_then28:                                        ; preds = %if_merge26
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ptr_deref30 = load ptr, ptr %n, align 8
  %kind31 = getelementptr inbounds nuw %break_stmt, ptr %ptr_deref30, i32 0, i32 0
  %nd_break_stmt = load i32, ptr @ast_kind__nd_break_stmt, align 4
  store i32 %nd_break_stmt, ptr %kind31, align 4
  %ptr_deref32 = load ptr, ptr %n, align 8
  %line33 = getelementptr inbounds nuw %break_stmt, ptr %ptr_deref32, i32 0, i32 1
  %20 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %20, ptr %line33, align 4
  %21 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.59)
  %n34 = load ptr, ptr %n, align 8
  ret ptr %n34

if_merge29:                                       ; preds = %if_merge26
  %22 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond35 = icmp ne i8 %22, 0
  br i1 %if_cond35, label %if_then36, label %if_merge37

if_then36:                                        ; preds = %if_merge29
  %n38 = alloca ptr, align 8
  store ptr null, ptr %n38, align 8
  %ptr_deref39 = load ptr, ptr %n38, align 8
  %kind40 = getelementptr inbounds nuw %continue_stmt, ptr %ptr_deref39, i32 0, i32 0
  %nd_continue_stmt = load i32, ptr @ast_kind__nd_continue_stmt, align 4
  store i32 %nd_continue_stmt, ptr %kind40, align 4
  %ptr_deref41 = load ptr, ptr %n38, align 8
  %line42 = getelementptr inbounds nuw %continue_stmt, ptr %ptr_deref41, i32 0, i32 1
  %23 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %23, ptr %line42, align 4
  %24 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.60)
  %n43 = load ptr, ptr %n38, align 8
  ret ptr %n43

if_merge37:                                       ; preds = %if_merge29
  %25 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond44 = icmp ne i8 %25, 0
  br i1 %if_cond44, label %if_then45, label %if_merge46

if_then45:                                        ; preds = %if_merge37
  %n47 = alloca ptr, align 8
  store ptr null, ptr %n47, align 8
  %ptr_deref48 = load ptr, ptr %n47, align 8
  %kind49 = getelementptr inbounds nuw %try_expr_stmt, ptr %ptr_deref48, i32 0, i32 0
  %nd_try_expr_stmt = load i32, ptr @ast_kind__nd_try_expr_stmt, align 4
  store i32 %nd_try_expr_stmt, ptr %kind49, align 4
  %ptr_deref50 = load ptr, ptr %n47, align 8
  %line51 = getelementptr inbounds nuw %try_expr_stmt, ptr %ptr_deref50, i32 0, i32 1
  %26 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %26, ptr %line51, align 4
  %ptr_deref52 = load ptr, ptr %n47, align 8
  %expr = getelementptr inbounds nuw %try_expr_stmt, ptr %ptr_deref52, i32 0, i32 2
  %27 = call ptr @parser_t__NS_parse_expr(ptr %self)
  store ptr %27, ptr %expr, align 8
  %28 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.61)
  %n53 = load ptr, ptr %n47, align 8
  ret ptr %n53

if_merge46:                                       ; preds = %if_merge37
  %29 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond54 = icmp ne i8 %29, 0
  br i1 %if_cond54, label %if_then55, label %if_merge56

if_then55:                                        ; preds = %if_merge46
  %30 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %31 = call i8 @parser_t__NS_is_type_start(ptr %self)
  %if_cond57 = icmp ne i8 %31, 0
  br i1 %if_cond57, label %if_then58, label %if_merge59

if_merge56:                                       ; preds = %if_merge46
  %32 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond62 = icmp ne i8 %32, 0
  br i1 %if_cond62, label %if_then63, label %if_merge64

if_then58:                                        ; preds = %if_then55
  %vd = alloca ptr, align 8
  %33 = call ptr @parser_t__NS_parse_local_var_decl(ptr %self)
  store ptr %33, ptr %vd, align 8
  %ptr_deref60 = load ptr, ptr %vd, align 8
  %is_constexpr = getelementptr inbounds nuw %var_decl, ptr %ptr_deref60, i32 0, i32 6
  store i8 1, ptr %is_constexpr, align 1
  %vd61 = load ptr, ptr %vd, align 8
  ret ptr %vd61

if_merge59:                                       ; preds = %if_then55
  %34 = call ptr @parser_t__NS_parse_stmt(ptr %self)
  ret ptr %34

if_then63:                                        ; preds = %if_merge56
  %35 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %vd65 = alloca ptr, align 8
  %36 = call ptr @parser_t__NS_parse_local_var_decl(ptr %self)
  store ptr %36, ptr %vd65, align 8
  %ptr_deref66 = load ptr, ptr %vd65, align 8
  %is_consteval = getelementptr inbounds nuw %var_decl, ptr %ptr_deref66, i32 0, i32 7
  store i8 1, ptr %is_consteval, align 1
  %vd67 = load ptr, ptr %vd65, align 8
  ret ptr %vd67

if_merge64:                                       ; preds = %if_merge56
  %37 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond68 = icmp ne i8 %37, 0
  br i1 %if_cond68, label %if_then69, label %if_merge70

if_then69:                                        ; preds = %if_merge64
  %n71 = alloca ptr, align 8
  store ptr null, ptr %n71, align 8
  %ptr_deref72 = load ptr, ptr %n71, align 8
  %kind73 = getelementptr inbounds nuw %asm_stmt, ptr %ptr_deref72, i32 0, i32 0
  %nd_asm_stmt = load i32, ptr @ast_kind__nd_asm_stmt, align 4
  store i32 %nd_asm_stmt, ptr %kind73, align 4
  %ptr_deref74 = load ptr, ptr %n71, align 8
  %line75 = getelementptr inbounds nuw %asm_stmt, ptr %ptr_deref74, i32 0, i32 1
  %38 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %38, ptr %line75, align 4
  %body_tok = alloca i8, align 1
  %39 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.62)
  store i8 %39, ptr %body_tok, align 1
  %ptr_deref76 = load ptr, ptr %n71, align 8
  %raw_instructions = getelementptr inbounds nuw %asm_stmt, ptr %ptr_deref76, i32 0, i32 2
  %n77 = load ptr, ptr %n71, align 8
  ret ptr %n77

if_merge70:                                       ; preds = %if_merge64
  %40 = call i8 @parser_t__NS_is_type_start(ptr %self)
  %if_cond78 = icmp ne i8 %40, 0
  br i1 %if_cond78, label %if_then79, label %if_merge80

if_then79:                                        ; preds = %if_merge70
  %41 = call ptr @parser_t__NS_parse_local_var_decl(ptr %self)
  ret ptr %41

if_merge80:                                       ; preds = %if_merge70
  %es = alloca ptr, align 8
  store ptr null, ptr %es, align 8
  %ptr_deref81 = load ptr, ptr %es, align 8
  %kind82 = getelementptr inbounds nuw %expr_stmt, ptr %ptr_deref81, i32 0, i32 0
  %nd_expr_stmt = load i32, ptr @ast_kind__nd_expr_stmt, align 4
  store i32 %nd_expr_stmt, ptr %kind82, align 4
  %ptr_deref83 = load ptr, ptr %es, align 8
  %line84 = getelementptr inbounds nuw %expr_stmt, ptr %ptr_deref83, i32 0, i32 1
  %42 = call i64 @parser_t__NS_peek_line(ptr %self)
  store i64 %42, ptr %line84, align 4
  %ptr_deref85 = load ptr, ptr %es, align 8
  %expr86 = getelementptr inbounds nuw %expr_stmt, ptr %ptr_deref85, i32 0, i32 2
  %43 = call ptr @parser_t__NS_parse_expr(ptr %self)
  store ptr %43, ptr %expr86, align 8
  %ptr_deref87 = load ptr, ptr %es, align 8
  %expr88 = getelementptr inbounds nuw %expr_stmt, ptr %ptr_deref87, i32 0, i32 2
  %ptr_deref89 = load ptr, ptr %es, align 8
  %mem_load = load ptr, ptr %expr88, align 8
  %icmp = icmp ne ptr %mem_load, null
  %ptr_deref90 = load ptr, ptr %es, align 8
  %expr91 = getelementptr inbounds nuw %expr_stmt, ptr %ptr_deref90, i32 0, i32 2
  %es92 = load ptr, ptr %es, align 8
  ret ptr %es92
}

define ptr @parser_t__NS_parse_expr(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %1 = call ptr @parser_t__NS_parse_assignment(ptr %self)
  ret ptr %1
}

define ptr @parser_t__NS_parse_assignment(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %lhs = alloca ptr, align 8
  %1 = call ptr @parser_t__NS_parse_null_coal(ptr %self)
  store ptr %1, ptr %lhs, align 8
  %bop = alloca i32, align 4
  store i32 -1, ptr %bop, align 4
  %tt = alloca i32, align 4
  %2 = call i32 @parser_t__NS_peek_type(ptr %self)
  store i32 %2, ptr %tt, align 4
  %tt1 = load i32, ptr %tt, align 4
  %bop2 = load i32, ptr %bop, align 4
  %icmp = icmp sge i32 %bop2, 0
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %ln = alloca i64, align 8
  %3 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %3, ptr %ln, align 4
  %rhs = alloca ptr, align 8
  %4 = call ptr @parser_t__NS_parse_assignment(ptr %self)
  store ptr %4, ptr %rhs, align 8
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ln3 = load i64, ptr %ln, align 4
  %lhs4 = load ptr, ptr %lhs, align 8
  %rhs5 = load ptr, ptr %rhs, align 8
  %bop6 = load i32, ptr %bop, align 4
  %n7 = load ptr, ptr %n, align 8
  ret ptr %n7

if_merge:                                         ; preds = %entry
  %lhs8 = load ptr, ptr %lhs, align 8
  ret ptr %lhs8
}

define ptr @parser_t__NS_parse_null_coal(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %lhs = alloca ptr, align 8
  %1 = call ptr @parser_t__NS_parse_ternary(ptr %self)
  store ptr %1, ptr %lhs, align 8
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %2 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %while_cond1 = icmp ne i8 %2, 0
  br i1 %while_cond1, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %3 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %4 = call i64 @parser_t__NS_prev_line(ptr %self)
  %lhs2 = load ptr, ptr %lhs, align 8
  %5 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %5, 0
  br i1 %if_cond, label %if_then, label %if_else

while_exit:                                       ; preds = %while_cond
  %lhs4 = load ptr, ptr %lhs, align 8
  ret ptr %lhs4

if_then:                                          ; preds = %while_body
  %6 = call ptr @parser_t__NS_parse_block(ptr %self)
  br label %if_merge

if_else:                                          ; preds = %while_body
  %7 = call ptr @parser_t__NS_parse_ternary(ptr %self)
  br label %if_merge

if_merge:                                         ; preds = %if_else, %if_then
  %n3 = load ptr, ptr %n, align 8
  store ptr %n3, ptr %lhs, align 8
  br label %while_cond
}

define ptr @parser_t__NS_parse_ternary(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %cond = alloca ptr, align 8
  %1 = call ptr @parser_t__NS_parse_or(ptr %self)
  store ptr %1, ptr %cond, align 8
  %2 = call i8 @parser_t__NS_match_tok(ptr %self, <null operand!>)
  %tobool = icmp ne i8 %2, 0
  %not = xor i1 %tobool, true
  br i1 %not, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %cond1 = load ptr, ptr %cond, align 8
  ret ptr %cond1

if_merge:                                         ; preds = %entry
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %3 = call i64 @parser_t__NS_prev_line(ptr %self)
  %cond2 = load ptr, ptr %cond, align 8
  %4 = call ptr @parser_t__NS_parse_expr(ptr %self)
  %5 = call i8 @parser_t__NS_consume_tok(ptr %self, <null operand!>, ptr @str.63)
  %6 = call ptr @parser_t__NS_parse_ternary(ptr %self)
  %n3 = load ptr, ptr %n, align 8
  ret ptr %n3
}

define ptr @parser_t__NS_parse_or(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %lhs = alloca ptr, align 8
  %1 = call ptr @parser_t__NS_parse_and(ptr %self)
  store ptr %1, ptr %lhs, align 8
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %2 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %while_cond1 = icmp ne i8 %2, 0
  br i1 %while_cond1, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ln = alloca i64, align 8
  %3 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %3, ptr %ln, align 4
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ln2 = load i64, ptr %ln, align 4
  %lhs3 = load ptr, ptr %lhs, align 8
  %4 = call ptr @parser_t__NS_parse_and(ptr %self)
  %n4 = load ptr, ptr %n, align 8
  store ptr %n4, ptr %lhs, align 8
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %lhs5 = load ptr, ptr %lhs, align 8
  ret ptr %lhs5
}

define ptr @parser_t__NS_parse_and(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %lhs = alloca ptr, align 8
  %1 = call ptr @parser_t__NS_parse_bitor(ptr %self)
  store ptr %1, ptr %lhs, align 8
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %2 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %while_cond1 = icmp ne i8 %2, 0
  br i1 %while_cond1, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ln = alloca i64, align 8
  %3 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %3, ptr %ln, align 4
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ln2 = load i64, ptr %ln, align 4
  %lhs3 = load ptr, ptr %lhs, align 8
  %4 = call ptr @parser_t__NS_parse_bitor(ptr %self)
  %n4 = load ptr, ptr %n, align 8
  store ptr %n4, ptr %lhs, align 8
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %lhs5 = load ptr, ptr %lhs, align 8
  ret ptr %lhs5
}

define ptr @parser_t__NS_parse_bitor(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %lhs = alloca ptr, align 8
  %1 = call ptr @parser_t__NS_parse_bitxor(ptr %self)
  store ptr %1, ptr %lhs, align 8
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %2 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %while_cond1 = icmp ne i8 %2, 0
  br i1 %while_cond1, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ln = alloca i64, align 8
  %3 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %3, ptr %ln, align 4
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ln2 = load i64, ptr %ln, align 4
  %lhs3 = load ptr, ptr %lhs, align 8
  %4 = call ptr @parser_t__NS_parse_bitxor(ptr %self)
  %n4 = load ptr, ptr %n, align 8
  store ptr %n4, ptr %lhs, align 8
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %lhs5 = load ptr, ptr %lhs, align 8
  ret ptr %lhs5
}

define ptr @parser_t__NS_parse_bitxor(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %lhs = alloca ptr, align 8
  %1 = call ptr @parser_t__NS_parse_bitand(ptr %self)
  store ptr %1, ptr %lhs, align 8
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %2 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %while_cond1 = icmp ne i8 %2, 0
  br i1 %while_cond1, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ln = alloca i64, align 8
  %3 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %3, ptr %ln, align 4
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ln2 = load i64, ptr %ln, align 4
  %lhs3 = load ptr, ptr %lhs, align 8
  %4 = call ptr @parser_t__NS_parse_bitand(ptr %self)
  %n4 = load ptr, ptr %n, align 8
  store ptr %n4, ptr %lhs, align 8
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %lhs5 = load ptr, ptr %lhs, align 8
  ret ptr %lhs5
}

define ptr @parser_t__NS_parse_bitand(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %lhs = alloca ptr, align 8
  %1 = call ptr @parser_t__NS_parse_equality(ptr %self)
  store ptr %1, ptr %lhs, align 8
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %2 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %while_cond1 = icmp ne i8 %2, 0
  br i1 %while_cond1, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ln = alloca i64, align 8
  %3 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %3, ptr %ln, align 4
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ln2 = load i64, ptr %ln, align 4
  %lhs3 = load ptr, ptr %lhs, align 8
  %4 = call ptr @parser_t__NS_parse_equality(ptr %self)
  %n4 = load ptr, ptr %n, align 8
  store ptr %n4, ptr %lhs, align 8
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %lhs5 = load ptr, ptr %lhs, align 8
  ret ptr %lhs5
}

define ptr @parser_t__NS_parse_equality(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %lhs = alloca ptr, align 8
  %1 = call ptr @parser_t__NS_parse_compare(ptr %self)
  store ptr %1, ptr %lhs, align 8
  %running = alloca i8, align 1
  store i8 1, ptr %running, align 1
  br label %while_cond

while_cond:                                       ; preds = %if_merge9, %entry
  %running1 = load i8, ptr %running, align 1
  %while_cond2 = icmp ne i8 %running1, 0
  br i1 %while_cond2, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %bop = alloca i32, align 4
  store i32 -1, ptr %bop, align 4
  %2 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %2, 0
  br i1 %if_cond, label %if_then, label %if_else

while_exit:                                       ; preds = %while_cond
  %lhs14 = load ptr, ptr %lhs, align 8
  ret ptr %lhs14

if_then:                                          ; preds = %while_body
  br label %if_merge

if_else:                                          ; preds = %while_body
  %3 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond3 = icmp ne i8 %3, 0
  br i1 %if_cond3, label %if_then4, label %if_merge5

if_merge:                                         ; preds = %if_merge5, %if_then
  %bop6 = load i32, ptr %bop, align 4
  %icmp = icmp slt i32 %bop6, 0
  br i1 %icmp, label %if_then7, label %if_else8

if_then4:                                         ; preds = %if_else
  br label %if_merge5

if_merge5:                                        ; preds = %if_then4, %if_else
  br label %if_merge

if_then7:                                         ; preds = %if_merge
  store i8 0, ptr %running, align 1
  br label %if_merge9

if_else8:                                         ; preds = %if_merge
  %ln = alloca i64, align 8
  %4 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %4, ptr %ln, align 4
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ln10 = load i64, ptr %ln, align 4
  %lhs11 = load ptr, ptr %lhs, align 8
  %bop12 = load i32, ptr %bop, align 4
  %5 = call ptr @parser_t__NS_parse_compare(ptr %self)
  %n13 = load ptr, ptr %n, align 8
  store ptr %n13, ptr %lhs, align 8
  br label %if_merge9

if_merge9:                                        ; preds = %if_else8, %if_then7
  br label %while_cond
}

define ptr @parser_t__NS_parse_compare(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %lhs = alloca ptr, align 8
  %1 = call ptr @parser_t__NS_parse_shift(ptr %self)
  store ptr %1, ptr %lhs, align 8
  %running = alloca i8, align 1
  store i8 1, ptr %running, align 1
  br label %while_cond

while_cond:                                       ; preds = %if_merge17, %entry
  %running1 = load i8, ptr %running, align 1
  %while_cond2 = icmp ne i8 %running1, 0
  br i1 %while_cond2, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %bop = alloca i32, align 4
  store i32 -1, ptr %bop, align 4
  %2 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %2, 0
  br i1 %if_cond, label %if_then, label %if_else

while_exit:                                       ; preds = %while_cond
  %lhs22 = load ptr, ptr %lhs, align 8
  ret ptr %lhs22

if_then:                                          ; preds = %while_body
  br label %if_merge

if_else:                                          ; preds = %while_body
  %3 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond3 = icmp ne i8 %3, 0
  br i1 %if_cond3, label %if_then4, label %if_else5

if_merge:                                         ; preds = %if_merge6, %if_then
  %bop14 = load i32, ptr %bop, align 4
  %icmp = icmp slt i32 %bop14, 0
  br i1 %icmp, label %if_then15, label %if_else16

if_then4:                                         ; preds = %if_else
  br label %if_merge6

if_else5:                                         ; preds = %if_else
  %4 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond7 = icmp ne i8 %4, 0
  br i1 %if_cond7, label %if_then8, label %if_else9

if_merge6:                                        ; preds = %if_merge10, %if_then4
  br label %if_merge

if_then8:                                         ; preds = %if_else5
  br label %if_merge10

if_else9:                                         ; preds = %if_else5
  %5 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond11 = icmp ne i8 %5, 0
  br i1 %if_cond11, label %if_then12, label %if_merge13

if_merge10:                                       ; preds = %if_merge13, %if_then8
  br label %if_merge6

if_then12:                                        ; preds = %if_else9
  br label %if_merge13

if_merge13:                                       ; preds = %if_then12, %if_else9
  br label %if_merge10

if_then15:                                        ; preds = %if_merge
  store i8 0, ptr %running, align 1
  br label %if_merge17

if_else16:                                        ; preds = %if_merge
  %ln = alloca i64, align 8
  %6 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %6, ptr %ln, align 4
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ln18 = load i64, ptr %ln, align 4
  %lhs19 = load ptr, ptr %lhs, align 8
  %bop20 = load i32, ptr %bop, align 4
  %7 = call ptr @parser_t__NS_parse_shift(ptr %self)
  %n21 = load ptr, ptr %n, align 8
  store ptr %n21, ptr %lhs, align 8
  br label %if_merge17

if_merge17:                                       ; preds = %if_else16, %if_then15
  br label %while_cond
}

define ptr @parser_t__NS_parse_shift(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %lhs = alloca ptr, align 8
  %1 = call ptr @parser_t__NS_parse_add(ptr %self)
  store ptr %1, ptr %lhs, align 8
  %running = alloca i8, align 1
  store i8 1, ptr %running, align 1
  br label %while_cond

while_cond:                                       ; preds = %if_merge9, %entry
  %running1 = load i8, ptr %running, align 1
  %while_cond2 = icmp ne i8 %running1, 0
  br i1 %while_cond2, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %bop = alloca i32, align 4
  store i32 -1, ptr %bop, align 4
  %2 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %2, 0
  br i1 %if_cond, label %if_then, label %if_else

while_exit:                                       ; preds = %while_cond
  %lhs14 = load ptr, ptr %lhs, align 8
  ret ptr %lhs14

if_then:                                          ; preds = %while_body
  br label %if_merge

if_else:                                          ; preds = %while_body
  %3 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond3 = icmp ne i8 %3, 0
  br i1 %if_cond3, label %if_then4, label %if_merge5

if_merge:                                         ; preds = %if_merge5, %if_then
  %bop6 = load i32, ptr %bop, align 4
  %icmp = icmp slt i32 %bop6, 0
  br i1 %icmp, label %if_then7, label %if_else8

if_then4:                                         ; preds = %if_else
  br label %if_merge5

if_merge5:                                        ; preds = %if_then4, %if_else
  br label %if_merge

if_then7:                                         ; preds = %if_merge
  store i8 0, ptr %running, align 1
  br label %if_merge9

if_else8:                                         ; preds = %if_merge
  %ln = alloca i64, align 8
  %4 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %4, ptr %ln, align 4
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ln10 = load i64, ptr %ln, align 4
  %lhs11 = load ptr, ptr %lhs, align 8
  %bop12 = load i32, ptr %bop, align 4
  %5 = call ptr @parser_t__NS_parse_add(ptr %self)
  %n13 = load ptr, ptr %n, align 8
  store ptr %n13, ptr %lhs, align 8
  br label %if_merge9

if_merge9:                                        ; preds = %if_else8, %if_then7
  br label %while_cond
}

define ptr @parser_t__NS_parse_add(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %lhs = alloca ptr, align 8
  %1 = call ptr @parser_t__NS_parse_mul(ptr %self)
  store ptr %1, ptr %lhs, align 8
  %running = alloca i8, align 1
  store i8 1, ptr %running, align 1
  br label %while_cond

while_cond:                                       ; preds = %if_merge9, %entry
  %running1 = load i8, ptr %running, align 1
  %while_cond2 = icmp ne i8 %running1, 0
  br i1 %while_cond2, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %bop = alloca i32, align 4
  store i32 -1, ptr %bop, align 4
  %2 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %2, 0
  br i1 %if_cond, label %if_then, label %if_else

while_exit:                                       ; preds = %while_cond
  %lhs14 = load ptr, ptr %lhs, align 8
  ret ptr %lhs14

if_then:                                          ; preds = %while_body
  br label %if_merge

if_else:                                          ; preds = %while_body
  %3 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond3 = icmp ne i8 %3, 0
  br i1 %if_cond3, label %if_then4, label %if_merge5

if_merge:                                         ; preds = %if_merge5, %if_then
  %bop6 = load i32, ptr %bop, align 4
  %icmp = icmp slt i32 %bop6, 0
  br i1 %icmp, label %if_then7, label %if_else8

if_then4:                                         ; preds = %if_else
  br label %if_merge5

if_merge5:                                        ; preds = %if_then4, %if_else
  br label %if_merge

if_then7:                                         ; preds = %if_merge
  store i8 0, ptr %running, align 1
  br label %if_merge9

if_else8:                                         ; preds = %if_merge
  %ln = alloca i64, align 8
  %4 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %4, ptr %ln, align 4
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ln10 = load i64, ptr %ln, align 4
  %lhs11 = load ptr, ptr %lhs, align 8
  %bop12 = load i32, ptr %bop, align 4
  %5 = call ptr @parser_t__NS_parse_mul(ptr %self)
  %n13 = load ptr, ptr %n, align 8
  store ptr %n13, ptr %lhs, align 8
  br label %if_merge9

if_merge9:                                        ; preds = %if_else8, %if_then7
  br label %while_cond
}

define ptr @parser_t__NS_parse_mul(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %lhs = alloca ptr, align 8
  %1 = call ptr @parser_t__NS_parse_unary(ptr %self)
  store ptr %1, ptr %lhs, align 8
  %running = alloca i8, align 1
  store i8 1, ptr %running, align 1
  br label %while_cond

while_cond:                                       ; preds = %if_merge13, %entry
  %running1 = load i8, ptr %running, align 1
  %while_cond2 = icmp ne i8 %running1, 0
  br i1 %while_cond2, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %bop = alloca i32, align 4
  store i32 -1, ptr %bop, align 4
  %2 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond = icmp ne i8 %2, 0
  br i1 %if_cond, label %if_then, label %if_else

while_exit:                                       ; preds = %while_cond
  %lhs18 = load ptr, ptr %lhs, align 8
  ret ptr %lhs18

if_then:                                          ; preds = %while_body
  br label %if_merge

if_else:                                          ; preds = %while_body
  %3 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond3 = icmp ne i8 %3, 0
  br i1 %if_cond3, label %if_then4, label %if_else5

if_merge:                                         ; preds = %if_merge6, %if_then
  %bop10 = load i32, ptr %bop, align 4
  %icmp = icmp slt i32 %bop10, 0
  br i1 %icmp, label %if_then11, label %if_else12

if_then4:                                         ; preds = %if_else
  br label %if_merge6

if_else5:                                         ; preds = %if_else
  %4 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %if_cond7 = icmp ne i8 %4, 0
  br i1 %if_cond7, label %if_then8, label %if_merge9

if_merge6:                                        ; preds = %if_merge9, %if_then4
  br label %if_merge

if_then8:                                         ; preds = %if_else5
  br label %if_merge9

if_merge9:                                        ; preds = %if_then8, %if_else5
  br label %if_merge6

if_then11:                                        ; preds = %if_merge
  store i8 0, ptr %running, align 1
  br label %if_merge13

if_else12:                                        ; preds = %if_merge
  %ln = alloca i64, align 8
  %5 = call i64 @parser_t__NS_advance_line_get(ptr %self)
  store i64 %5, ptr %ln, align 4
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ln14 = load i64, ptr %ln, align 4
  %lhs15 = load ptr, ptr %lhs, align 8
  %bop16 = load i32, ptr %bop, align 4
  %6 = call ptr @parser_t__NS_parse_unary(ptr %self)
  %n17 = load ptr, ptr %n, align 8
  store ptr %n17, ptr %lhs, align 8
  br label %if_merge13

if_merge13:                                       ; preds = %if_else12, %if_then11
  br label %while_cond
}

define ptr @parser_t__NS_parse_unary(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %tt = alloca i32, align 4
  %1 = call i32 @parser_t__NS_peek_type(ptr %self)
  store i32 %1, ptr %tt, align 4
  %ln = alloca i64, align 8
  %2 = call i64 @parser_t__NS_peek_line(ptr %self)
  store i64 %2, ptr %ln, align 4
  %tt1 = load i32, ptr %tt, align 4
  %tt2 = load i32, ptr %tt, align 4
  %tt3 = load i32, ptr %tt, align 4
  %tt4 = load i32, ptr %tt, align 4
  %tt5 = load i32, ptr %tt, align 4
  %tt6 = load i32, ptr %tt, align 4
  %tt7 = load i32, ptr %tt, align 4
  %tt8 = load i32, ptr %tt, align 4
  %tt9 = load i32, ptr %tt, align 4
  %tt10 = load i32, ptr %tt, align 4
  %tt11 = load i32, ptr %tt, align 4
  %tt12 = load i32, ptr %tt, align 4
  %tt13 = load i32, ptr %tt, align 4
  %3 = call ptr @parser_t__NS_parse_postfix(ptr %self)
  ret ptr %3
}

define ptr @parser_t__NS_parse_postfix(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %lhs = alloca ptr, align 8
  %1 = call ptr @parser_t__NS_parse_primary(ptr %self)
  store ptr %1, ptr %lhs, align 8
  %running = alloca i8, align 1
  store i8 1, ptr %running, align 1
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %running1 = load i8, ptr %running, align 1
  %while_cond2 = icmp ne i8 %running1, 0
  br i1 %while_cond2, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %2 = call i8 @parser_t__NS_check_tok(ptr %self, <null operand!>)
  %3 = call i32 @parser_t__NS_peek_at_type(ptr %self, i32 1)
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %lhs3 = load ptr, ptr %lhs, align 8
  ret ptr %lhs3
}

define ptr @parser_t__NS_parse_primary(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %tok = alloca i8, align 1
  %1 = call i8 @parser_t__NS_peek_tok(ptr %self)
  store i8 %1, ptr %tok, align 1
  %tt = alloca i32, align 4
  store i32 0, ptr %tt, align 4
  %ln = alloca i64, align 8
  store i64 0, ptr %ln, align 4
  %tt1 = load i32, ptr %tt, align 4
  %tt2 = load i32, ptr %tt, align 4
  %tt3 = load i32, ptr %tt, align 4
  %tt4 = load i32, ptr %tt, align 4
  %tt5 = load i32, ptr %tt, align 4
  %tt6 = load i32, ptr %tt, align 4
  %tt7 = load i32, ptr %tt, align 4
  %tt8 = load i32, ptr %tt, align 4
  %tt9 = load i32, ptr %tt, align 4
  %tt10 = load i32, ptr %tt, align 4
  %tt11 = load i32, ptr %tt, align 4
  %2 = call i32 @parser_t__NS_peek_at_type(ptr %self, i32 1)
  %ptr_deref = load ptr, ptr %self, align 8
  %had_parse_error = getelementptr inbounds nuw %parser_t, ptr %ptr_deref, i32 0, i32 3
  store i8 1, ptr %had_parse_error, align 1
  %3 = call i8 @parser_t__NS_advance_tok(ptr %self)
  %n = alloca ptr, align 8
  store ptr null, ptr %n, align 8
  %ln12 = load i64, ptr %ln, align 4
  %n13 = load ptr, ptr %n, align 8
  ret ptr %n13
}

define ptr @parser_t__NS_parse(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %prog = alloca ptr, align 8
  store ptr null, ptr %prog, align 8
  %ptr_deref = load ptr, ptr %prog, align 8
  %kind = getelementptr inbounds nuw %program_node, ptr %ptr_deref, i32 0, i32 0
  %nd_program = load i32, ptr @ast_kind__nd_program, align 4
  store i32 %nd_program, ptr %kind, align 4
  %ptr_deref1 = load ptr, ptr %prog, align 8
  %decls_cap = getelementptr inbounds nuw %program_node, ptr %ptr_deref1, i32 0, i32 4
  store i32 64, ptr %decls_cap, align 4
  %ptr_deref2 = load ptr, ptr %prog, align 8
  %decls = getelementptr inbounds nuw %program_node, ptr %ptr_deref2, i32 0, i32 2
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %1 = call i8 @parser_t__NS_is_at_end_p(ptr %self)
  %tobool = icmp ne i8 %1, 0
  %not = xor i1 %tobool, true
  br i1 %not, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %decl = alloca ptr, align 8
  %2 = call ptr @parser_t__NS_parse_top_level(ptr %self)
  store ptr %2, ptr %decl, align 8
  %decl3 = load ptr, ptr %decl, align 8
  %icmp = icmp ne ptr %decl3, null
  br i1 %icmp, label %if_then, label %if_merge

while_exit:                                       ; preds = %while_cond
  %prog34 = load ptr, ptr %prog, align 8
  ret ptr %prog34

if_then:                                          ; preds = %while_body
  %ptr_deref4 = load ptr, ptr %prog, align 8
  %decls_len = getelementptr inbounds nuw %program_node, ptr %ptr_deref4, i32 0, i32 3
  %ptr_deref5 = load ptr, ptr %prog, align 8
  %mem_load = load i32, ptr %decls_len, align 4
  %ptr_deref6 = load ptr, ptr %prog, align 8
  %decls_cap7 = getelementptr inbounds nuw %program_node, ptr %ptr_deref6, i32 0, i32 4
  %ptr_deref8 = load ptr, ptr %prog, align 8
  %mem_load9 = load i32, ptr %decls_cap7, align 4
  %icmp10 = icmp sge i32 %mem_load, %mem_load9
  br i1 %icmp10, label %if_then11, label %if_merge12

if_merge:                                         ; preds = %if_merge12, %while_body
  br label %while_cond

if_then11:                                        ; preds = %if_then
  %ptr_deref13 = load ptr, ptr %prog, align 8
  %decls_cap14 = getelementptr inbounds nuw %program_node, ptr %ptr_deref13, i32 0, i32 4
  %ptr_deref15 = load ptr, ptr %prog, align 8
  %decls_cap16 = getelementptr inbounds nuw %program_node, ptr %ptr_deref15, i32 0, i32 4
  %ptr_deref17 = load ptr, ptr %prog, align 8
  %mem_load18 = load i32, ptr %decls_cap16, align 4
  %mul = mul i32 %mem_load18, 2
  store i32 %mul, ptr %decls_cap14, align 4
  %ptr_deref19 = load ptr, ptr %prog, align 8
  %decls20 = getelementptr inbounds nuw %program_node, ptr %ptr_deref19, i32 0, i32 2
  br label %if_merge12

if_merge12:                                       ; preds = %if_then11, %if_then
  %ptr_deref21 = load ptr, ptr %prog, align 8
  %decls22 = getelementptr inbounds nuw %program_node, ptr %ptr_deref21, i32 0, i32 2
  %ptr_deref23 = load ptr, ptr %prog, align 8
  %decls_len24 = getelementptr inbounds nuw %program_node, ptr %ptr_deref23, i32 0, i32 3
  %ptr_deref25 = load ptr, ptr %prog, align 8
  %mem_load26 = load i32, ptr %decls_len24, align 4
  %ptr_load = load ptr, ptr %decls22, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load26
  %decl27 = load ptr, ptr %decl, align 8
  store ptr %decl27, ptr %ptr_gep, align 8
  %ptr_deref28 = load ptr, ptr %prog, align 8
  %decls_len29 = getelementptr inbounds nuw %program_node, ptr %ptr_deref28, i32 0, i32 3
  %ptr_deref30 = load ptr, ptr %prog, align 8
  %decls_len31 = getelementptr inbounds nuw %program_node, ptr %ptr_deref30, i32 0, i32 3
  %ptr_deref32 = load ptr, ptr %prog, align 8
  %mem_load33 = load i32, ptr %decls_len31, align 4
  %add = add i32 %mem_load33, 1
  store i32 %add, ptr %decls_len29, align 4
  br label %if_merge
}
