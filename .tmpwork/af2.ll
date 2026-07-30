; ModuleID = '.tmpwork/af2.arc'
source_filename = ".tmpwork/af2.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%type_info = type { i32, [72 x i8] }
%type_info_field = type { ptr, i32, i32, i32 }
%memstr = type { ptr, ptr }
%__vtable__ = type { ptr, ptr, ptr, ptr, ptr }
%__anon3_P_i32_i64 = type { ptr, i32, i64 }

@type_info__Void = internal constant i32 0
@type_info__Bool = internal constant i32 1
@type_info__Int = internal constant i32 2
@type_info__Uint = internal constant i32 3
@type_info__Float = internal constant i32 4
@type_info__Char = internal constant i32 5
@type_info__Usize = internal constant i32 6
@type_info__Isize = internal constant i32 7
@type_info__Iofs = internal constant i32 8
@type_info__Pointer = internal constant i32 9
@type_info__Array = internal constant i32 10
@type_info__Slice = internal constant i32 11
@type_info__Struct = internal constant i32 12
@type_info__Istruc = internal constant i32 13
@type_info__Union = internal constant i32 14
@type_info__Enum = internal constant i32 15
@type_info__AdtEnum = internal constant i32 16
@type_info__Interface = internal constant i32 17
@type_info__Fn = internal constant i32 18
@type_info__Lambda = internal constant i32 19
@type_info__ErrorUnion = internal constant i32 20
@type_info__Optional = internal constant i32 21
@type_info__AnyType = internal constant i32 22
@type_info_num__SInt = internal constant i32 0
@type_info_num__UInt = internal constant i32 1
@type_info_num__Float = internal constant i32 2
@type_info_num__Usize = internal constant i32 3
@type_info_num__Isize = internal constant i32 4
@type_info_num__Iofs = internal constant i32 5
@__artemis_error_payload = global ptr null
@str = private unnamed_addr constant [39 x i8] c"  struct sz=%d align=%d nf=%d flds=%p\0A\00", align 1
@str.1 = private unnamed_addr constant [32 x i8] c"  [%d] off=%d size=%d align=%d\0A\00", align 1
@str.2 = private unnamed_addr constant [23 x i8] c"  not struct (tag=%d)\0A\00", align 1
@str.3 = private unnamed_addr constant [8 x i8] c"named:\0A\00", align 1
@__typeinfo_Mixed = global %type_info zeroinitializer
@__typeinfo_nm_Mixed = constant [6 x i8] c"Mixed\00"
@__typeinfo_fn_Mixed_0 = constant [2 x i8] c"a\00"
@__typeinfo_fn_Mixed_1 = constant [2 x i8] c"b\00"
@__typeinfo_fn_Mixed_2 = constant [2 x i8] c"c\00"
@__typeinfo_flds_Mixed = constant [3 x %type_info_field] [%type_info_field { ptr @__typeinfo_fn_Mixed_0, i32 0, i32 8, i32 8 }, %type_info_field { ptr @__typeinfo_fn_Mixed_1, i32 8, i32 4, i32 4 }, %type_info_field { ptr @__typeinfo_fn_Mixed_2, i32 12, i32 8, i32 4 }]
@str.4 = private unnamed_addr constant [3 x i8] c"hi\00", align 1
@str.5 = private unnamed_addr constant [7 x i8] c"anon:\0A\00", align 1
@__typeinfo___anon3_P_i32_i64 = global %type_info zeroinitializer
@__typeinfo_nm___anon3_P_i32_i64 = constant [18 x i8] c"__anon3_P_i32_i64\00"
@__typeinfo_fn___anon3_P_i32_i64_0 = constant [4 x i8] c"__0\00"
@__typeinfo_fn___anon3_P_i32_i64_1 = constant [4 x i8] c"__1\00"
@__typeinfo_fn___anon3_P_i32_i64_2 = constant [4 x i8] c"__2\00"
@__typeinfo_flds___anon3_P_i32_i64 = constant [3 x %type_info_field] [%type_info_field { ptr @__typeinfo_fn___anon3_P_i32_i64_0, i32 0, i32 8, i32 8 }, %type_info_field { ptr @__typeinfo_fn___anon3_P_i32_i64_1, i32 8, i32 4, i32 4 }, %type_info_field { ptr @__typeinfo_fn___anon3_P_i32_i64_2, i32 12, i32 8, i32 4 }]
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__artemis_init_typeinfo, ptr null }]

define internal i64 @memstr__NS_default_align(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  ret i64 16
}

define internal { i32, ptr } @memstr__NS_mmap(ptr %0, i64 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %size = alloca i64, align 8
  store i64 %1, ptr %size, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
  %fld_deref = load ptr, ptr %vtable, align 8
  %mmap = getelementptr inbounds nuw %__vtable__, ptr %fld_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %vtable2 = getelementptr inbounds nuw %memstr, ptr %ptr_deref1, i32 0, i32 1
  %fld_deref3 = load ptr, ptr %vtable2, align 8
  %mem_load = load ptr, ptr %mmap, align 8
  %icmp = icmp eq ptr %mem_load, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  store ptr null, ptr @__artemis_error_payload, align 8
  ret { i32, ptr } { i32 1, ptr undef }

if_merge:                                         ; preds = %entry
  %ptr_deref4 = load ptr, ptr %self, align 8
  %vtable5 = getelementptr inbounds nuw %memstr, ptr %ptr_deref4, i32 0, i32 1
  %ptr_deref6 = load ptr, ptr %self, align 8
  %fp_obj = load ptr, ptr %vtable5, align 8
  %fp_field = getelementptr inbounds nuw %__vtable__, ptr %fp_obj, i32 0, i32 0
  %fp_val = load ptr, ptr %fp_field, align 8
  %ptr_deref7 = load ptr, ptr %self, align 8
  %ptr = getelementptr inbounds nuw %memstr, ptr %ptr_deref7, i32 0, i32 0
  %ptr_deref8 = load ptr, ptr %self, align 8
  %mem_load9 = load ptr, ptr %ptr, align 8
  %self_load = load ptr, ptr %self, align 8
  %2 = call i64 @memstr__NS_default_align(ptr %self_load)
  %size10 = load i64, ptr %size, align 4
  %3 = call { i32, ptr } %fp_val(ptr %mem_load9, i64 %2, i64 %size10)
  %try_err_flag = extractvalue { i32, ptr } %3, 0
  %try_val = extractvalue { i32, ptr } %3, 1
  %try_is_err = icmp ne i32 %try_err_flag, 0
  br i1 %try_is_err, label %try_err, label %try_ok

try_err:                                          ; preds = %if_merge
  ret { i32, ptr } { i32 1, ptr undef }

try_ok:                                           ; preds = %if_merge
  %eu_val = insertvalue { i32, ptr } { i32 0, ptr undef }, ptr %try_val, 1
  ret { i32, ptr } %eu_val
}

define internal { i32, ptr } @memstr__NS_mmap_aligned(ptr %0, i64 %1, i64 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %align = alloca i64, align 8
  store i64 %1, ptr %align, align 4
  %size = alloca i64, align 8
  store i64 %2, ptr %size, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
  %fld_deref = load ptr, ptr %vtable, align 8
  %mmap = getelementptr inbounds nuw %__vtable__, ptr %fld_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %vtable2 = getelementptr inbounds nuw %memstr, ptr %ptr_deref1, i32 0, i32 1
  %fld_deref3 = load ptr, ptr %vtable2, align 8
  %mem_load = load ptr, ptr %mmap, align 8
  %icmp = icmp eq ptr %mem_load, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  store ptr null, ptr @__artemis_error_payload, align 8
  ret { i32, ptr } { i32 1, ptr undef }

if_merge:                                         ; preds = %entry
  %ptr_deref4 = load ptr, ptr %self, align 8
  %vtable5 = getelementptr inbounds nuw %memstr, ptr %ptr_deref4, i32 0, i32 1
  %ptr_deref6 = load ptr, ptr %self, align 8
  %fp_obj = load ptr, ptr %vtable5, align 8
  %fp_field = getelementptr inbounds nuw %__vtable__, ptr %fp_obj, i32 0, i32 0
  %fp_val = load ptr, ptr %fp_field, align 8
  %ptr_deref7 = load ptr, ptr %self, align 8
  %ptr = getelementptr inbounds nuw %memstr, ptr %ptr_deref7, i32 0, i32 0
  %ptr_deref8 = load ptr, ptr %self, align 8
  %mem_load9 = load ptr, ptr %ptr, align 8
  %align10 = load i64, ptr %align, align 4
  %size11 = load i64, ptr %size, align 4
  %3 = call { i32, ptr } %fp_val(ptr %mem_load9, i64 %align10, i64 %size11)
  %try_err_flag = extractvalue { i32, ptr } %3, 0
  %try_val = extractvalue { i32, ptr } %3, 1
  %try_is_err = icmp ne i32 %try_err_flag, 0
  br i1 %try_is_err, label %try_err, label %try_ok

try_err:                                          ; preds = %if_merge
  ret { i32, ptr } { i32 1, ptr undef }

try_ok:                                           ; preds = %if_merge
  %eu_val = insertvalue { i32, ptr } { i32 0, ptr undef }, ptr %try_val, 1
  ret { i32, ptr } %eu_val
}

define internal i8 @memstr__NS_rsmap(ptr %0, ptr %1, i65 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %data = alloca ptr, align 8
  store ptr %1, ptr %data, align 8
  %size = alloca i65, align 8
  store i65 %2, ptr %size, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
  %fld_deref = load ptr, ptr %vtable, align 8
  %rsmap = getelementptr inbounds nuw %__vtable__, ptr %fld_deref, i32 0, i32 1
  %ptr_deref1 = load ptr, ptr %self, align 8
  %vtable2 = getelementptr inbounds nuw %memstr, ptr %ptr_deref1, i32 0, i32 1
  %fld_deref3 = load ptr, ptr %vtable2, align 8
  %mem_load = load ptr, ptr %rsmap, align 8
  %icmp = icmp eq ptr %mem_load, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i8 0

if_merge:                                         ; preds = %entry
  %ptr_deref4 = load ptr, ptr %self, align 8
  %vtable5 = getelementptr inbounds nuw %memstr, ptr %ptr_deref4, i32 0, i32 1
  %ptr_deref6 = load ptr, ptr %self, align 8
  %fp_obj = load ptr, ptr %vtable5, align 8
  %fp_field = getelementptr inbounds nuw %__vtable__, ptr %fp_obj, i32 0, i32 1
  %fp_val = load ptr, ptr %fp_field, align 8
  %ptr_deref7 = load ptr, ptr %self, align 8
  %ptr = getelementptr inbounds nuw %memstr, ptr %ptr_deref7, i32 0, i32 0
  %ptr_deref8 = load ptr, ptr %self, align 8
  %mem_load9 = load ptr, ptr %ptr, align 8
  %data10 = load ptr, ptr %data, align 8
  %size11 = load i65, ptr %size, align 4
  %3 = call i8 %fp_val(ptr %mem_load9, ptr %data10, i65 %size11)
  ret i8 %3
}

define internal { i32, ptr } @memstr__NS_rmap(ptr %0, ptr %1, i65 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %data = alloca ptr, align 8
  store ptr %1, ptr %data, align 8
  %size = alloca i65, align 8
  store i65 %2, ptr %size, align 4
  %self_load = load ptr, ptr %self, align 8
  %data1 = load ptr, ptr %data, align 8
  %size2 = load i65, ptr %size, align 4
  %3 = call i8 @memstr__NS_rsmap(ptr %self_load, ptr %data1, i65 %size2)
  %if_cond = icmp ne i8 %3, 0
  br i1 %if_cond, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %data3 = load ptr, ptr %data, align 8
  %eu_val = insertvalue { i32, ptr } { i32 0, ptr undef }, ptr %data3, 1
  ret { i32, ptr } %eu_val

if_merge:                                         ; preds = %entry
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
  %fld_deref = load ptr, ptr %vtable, align 8
  %rmap = getelementptr inbounds nuw %__vtable__, ptr %fld_deref, i32 0, i32 2
  %ptr_deref4 = load ptr, ptr %self, align 8
  %vtable5 = getelementptr inbounds nuw %memstr, ptr %ptr_deref4, i32 0, i32 1
  %fld_deref6 = load ptr, ptr %vtable5, align 8
  %mem_load = load ptr, ptr %rmap, align 8
  %icmp = icmp eq ptr %mem_load, null
  br i1 %icmp, label %if_then7, label %if_merge8

if_then7:                                         ; preds = %if_merge
  store ptr null, ptr @__artemis_error_payload, align 8
  ret { i32, ptr } { i32 1, ptr undef }

if_merge8:                                        ; preds = %if_merge
  %ptr_deref9 = load ptr, ptr %self, align 8
  %vtable10 = getelementptr inbounds nuw %memstr, ptr %ptr_deref9, i32 0, i32 1
  %ptr_deref11 = load ptr, ptr %self, align 8
  %fp_obj = load ptr, ptr %vtable10, align 8
  %fp_field = getelementptr inbounds nuw %__vtable__, ptr %fp_obj, i32 0, i32 2
  %fp_val = load ptr, ptr %fp_field, align 8
  %ptr_deref12 = load ptr, ptr %self, align 8
  %ptr = getelementptr inbounds nuw %memstr, ptr %ptr_deref12, i32 0, i32 0
  %ptr_deref13 = load ptr, ptr %self, align 8
  %mem_load14 = load ptr, ptr %ptr, align 8
  %self_load15 = load ptr, ptr %self, align 8
  %4 = call i64 @memstr__NS_default_align(ptr %self_load15)
  %data16 = load ptr, ptr %data, align 8
  %size17 = load i65, ptr %size, align 4
  %5 = call { i32, ptr } %fp_val(ptr %mem_load14, i64 %4, ptr %data16, i65 %size17)
  %try_err_flag = extractvalue { i32, ptr } %5, 0
  %try_val = extractvalue { i32, ptr } %5, 1
  %try_is_err = icmp ne i32 %try_err_flag, 0
  br i1 %try_is_err, label %try_err, label %try_ok

try_err:                                          ; preds = %if_merge8
  ret { i32, ptr } { i32 1, ptr undef }

try_ok:                                           ; preds = %if_merge8
  %eu_val18 = insertvalue { i32, ptr } { i32 0, ptr undef }, ptr %try_val, 1
  ret { i32, ptr } %eu_val18
}

define internal i32 @memstr__NS_free(ptr %0, ptr %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %data = alloca ptr, align 8
  store ptr %1, ptr %data, align 8
  %data1 = load ptr, ptr %data, align 8
  %icmp = icmp eq ptr %data1, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 0

if_merge:                                         ; preds = %entry
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
  %fld_deref = load ptr, ptr %vtable, align 8
  %free = getelementptr inbounds nuw %__vtable__, ptr %fld_deref, i32 0, i32 3
  %ptr_deref2 = load ptr, ptr %self, align 8
  %vtable3 = getelementptr inbounds nuw %memstr, ptr %ptr_deref2, i32 0, i32 1
  %fld_deref4 = load ptr, ptr %vtable3, align 8
  %mem_load = load ptr, ptr %free, align 8
  %icmp5 = icmp eq ptr %mem_load, null
  br i1 %icmp5, label %if_then6, label %if_merge7

if_then6:                                         ; preds = %if_merge
  ret i32 0

if_merge7:                                        ; preds = %if_merge
  %ptr_deref8 = load ptr, ptr %self, align 8
  %vtable9 = getelementptr inbounds nuw %memstr, ptr %ptr_deref8, i32 0, i32 1
  %ptr_deref10 = load ptr, ptr %self, align 8
  %fp_obj = load ptr, ptr %vtable9, align 8
  %fp_field = getelementptr inbounds nuw %__vtable__, ptr %fp_obj, i32 0, i32 3
  %fp_val = load ptr, ptr %fp_field, align 8
  %ptr_deref11 = load ptr, ptr %self, align 8
  %ptr = getelementptr inbounds nuw %memstr, ptr %ptr_deref11, i32 0, i32 0
  %ptr_deref12 = load ptr, ptr %self, align 8
  %mem_load13 = load ptr, ptr %ptr, align 8
  %data14 = load ptr, ptr %data, align 8
  %2 = call i32 %fp_val(ptr %mem_load13, ptr %data14)
  %ts_is_err = icmp eq i32 %2, -1
  br i1 %ts_is_err, label %ts_err, label %ts_ok

ts_err:                                           ; preds = %if_merge7
  ret i32 -1

ts_ok:                                            ; preds = %if_merge7
  ret i32 0
}

define internal i32 @memstr__NS_destroy(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
  %fld_deref = load ptr, ptr %vtable, align 8
  %destroy = getelementptr inbounds nuw %__vtable__, ptr %fld_deref, i32 0, i32 4
  %ptr_deref1 = load ptr, ptr %self, align 8
  %vtable2 = getelementptr inbounds nuw %memstr, ptr %ptr_deref1, i32 0, i32 1
  %fld_deref3 = load ptr, ptr %vtable2, align 8
  %mem_load = load ptr, ptr %destroy, align 8
  %icmp = icmp eq ptr %mem_load, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 0

if_merge:                                         ; preds = %entry
  %ptr_deref4 = load ptr, ptr %self, align 8
  %vtable5 = getelementptr inbounds nuw %memstr, ptr %ptr_deref4, i32 0, i32 1
  %ptr_deref6 = load ptr, ptr %self, align 8
  %fp_obj = load ptr, ptr %vtable5, align 8
  %fp_field = getelementptr inbounds nuw %__vtable__, ptr %fp_obj, i32 0, i32 4
  %fp_val = load ptr, ptr %fp_field, align 8
  %ptr_deref7 = load ptr, ptr %self, align 8
  %ptr = getelementptr inbounds nuw %memstr, ptr %ptr_deref7, i32 0, i32 0
  %ptr_deref8 = load ptr, ptr %self, align 8
  %mem_load9 = load ptr, ptr %ptr, align 8
  %1 = call i32 %fp_val(ptr %mem_load9)
  %ts_is_err = icmp eq i32 %1, -1
  br i1 %ts_is_err, label %ts_err, label %ts_ok

ts_err:                                           ; preds = %if_merge
  ret i32 -1

ts_ok:                                            ; preds = %if_merge
  ret i32 0
}

define internal i32 @memstr__NS_deinit(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %self_load = load ptr, ptr %self, align 8
  %1 = call i32 @memstr__NS_destroy(ptr %self_load)
  %ts_is_err = icmp eq i32 %1, -1
  br i1 %ts_is_err, label %ts_err, label %ts_ok

ts_err:                                           ; preds = %entry
  ret i32 -1

ts_ok:                                            ; preds = %entry
  ret i32 0
}

define internal { i32, ptr } @memstr__NS_zeroed(ptr %0, i64 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %size = alloca i64, align 8
  store i64 %1, ptr %size, align 4
  %p = alloca ptr, align 8
  %self_load = load ptr, ptr %self, align 8
  %size1 = load i64, ptr %size, align 4
  %2 = call { i32, ptr } @memstr__NS_mmap(ptr %self_load, i64 %size1)
  %try_err_flag = extractvalue { i32, ptr } %2, 0
  %try_val = extractvalue { i32, ptr } %2, 1
  %try_is_err = icmp ne i32 %try_err_flag, 0
  br i1 %try_is_err, label %try_err, label %try_ok

try_err:                                          ; preds = %entry
  ret { i32, ptr } { i32 1, ptr undef }

try_ok:                                           ; preds = %entry
  store ptr %try_val, ptr %p, align 8
  %b = alloca ptr, align 8
  %p2 = load ptr, ptr %p, align 8
  store ptr %p2, ptr %b, align 8
  %i = alloca i64, align 8
  store i64 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %try_ok
  %i3 = load i64, ptr %i, align 4
  %size4 = load i64, ptr %size, align 4
  %icmp = icmp ult i64 %i3, %size4
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i5 = load i64, ptr %i, align 4
  %ptr_load = load ptr, ptr %b, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %i5
  store i8 0, ptr %ptr_gep, align 1
  %i6 = load i64, ptr %i, align 4
  %add = add i64 %i6, 1
  store i64 %add, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %p7 = load ptr, ptr %p, align 8
  %eu_val = insertvalue { i32, ptr } { i32 0, ptr undef }, ptr %p7, 1
  ret { i32, ptr } %eu_val
}

declare i32 @printf(ptr, ...)

define internal void @dump(ptr %0) {
entry:
  %ti = alloca ptr, align 8
  store ptr %0, ptr %ti, align 8
  %ti1 = load ptr, ptr %ti, align 8
  %deref = load %type_info, ptr %ti1, align 4
  %__tag_x = extractvalue %type_info %deref, 0
  %vtag = load i32, ptr @type_info__Struct, align 4
  %tag_cmp = icmp eq i32 %__tag_x, %vtag
  %enum_tmp = alloca %type_info, align 8
  store %type_info %deref, ptr %enum_tmp, align 4
  %pay_p3 = getelementptr inbounds nuw %type_info, ptr %enum_tmp, i32 0, i32 1
  %fptr3 = getelementptr i8, ptr %pay_p3, i64 0
  %vf_x3 = load ptr, ptr %fptr3, align 8
  %nm = alloca ptr, align 8
  store ptr %vf_x3, ptr %nm, align 8
  %vf_and = and i1 %tag_cmp, true
  %fptr32 = getelementptr i8, ptr %pay_p3, i64 8
  %vf_x33 = load ptr, ptr %fptr32, align 8
  %flds = alloca ptr, align 8
  store ptr %vf_x33, ptr %flds, align 8
  %vf_and4 = and i1 %vf_and, true
  %fptr35 = getelementptr i8, ptr %pay_p3, i64 16
  %vf_x36 = load i64, ptr %fptr35, align 4
  %nf = alloca i64, align 8
  store i64 %vf_x36, ptr %nf, align 4
  %vf_and7 = and i1 %vf_and4, true
  %fptr38 = getelementptr i8, ptr %pay_p3, i64 24
  %vf_x39 = load i64, ptr %fptr38, align 4
  %sz = alloca i64, align 8
  store i64 %vf_x39, ptr %sz, align 4
  %vf_and10 = and i1 %vf_and7, true
  %fptr311 = getelementptr i8, ptr %pay_p3, i64 32
  %vf_x312 = load i64, ptr %fptr311, align 4
  %al = alloca i64, align 8
  store i64 %vf_x312, ptr %al, align 4
  %vf_and13 = and i1 %vf_and10, true
  %fptr314 = getelementptr i8, ptr %pay_p3, i64 40
  %vf_x315 = load i64, ptr %fptr314, align 4
  %tup = alloca i64, align 8
  store i64 %vf_x315, ptr %tup, align 4
  %vf_and16 = and i1 %vf_and13, true
  %fptr317 = getelementptr i8, ptr %pay_p3, i64 48
  %vf_x318 = load i64, ptr %fptr317, align 4
  %pk = alloca i64, align 8
  store i64 %vf_x318, ptr %pk, align 4
  %vf_and19 = and i1 %vf_and16, true
  br i1 %vf_and19, label %arm_body, label %arm_next

match_merge:                                      ; preds = %arm_body44, %arm_next, %while_exit
  ret void

arm_body:                                         ; preds = %entry
  %szv = alloca i32, align 4
  %sz20 = load i64, ptr %sz, align 4
  %trunc = trunc i64 %sz20 to i32
  store i32 %trunc, ptr %szv, align 4
  %alv = alloca i32, align 4
  %al21 = load i64, ptr %al, align 4
  %trunc22 = trunc i64 %al21 to i32
  store i32 %trunc22, ptr %alv, align 4
  %fp = alloca ptr, align 8
  %flds23 = load ptr, ptr %flds, align 8
  store ptr %flds23, ptr %fp, align 8
  %szv24 = load i32, ptr %szv, align 4
  %alv25 = load i32, ptr %alv, align 4
  %nf26 = load i64, ptr %nf, align 4
  %trunc27 = trunc i64 %nf26 to i32
  %fp28 = load ptr, ptr %fp, align 8
  %1 = call i32 (ptr, ...) @printf(ptr @str, i32 %szv24, i32 %alv25, i32 %trunc27, ptr %fp28)
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

arm_next:                                         ; preds = %entry
  br i1 true, label %arm_body44, label %match_merge

while_cond:                                       ; preds = %while_body, %arm_body
  %i29 = load i32, ptr %i, align 4
  %nf30 = load i64, ptr %nf, align 4
  %trunc31 = trunc i64 %nf30 to i32
  %icmp = icmp slt i32 %i29, %trunc31
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %o = alloca i32, align 4
  %i32 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %flds, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i32
  store i32 0, ptr %o, align 4
  %z = alloca i32, align 4
  %i33 = load i32, ptr %i, align 4
  %ptr_load34 = load ptr, ptr %flds, align 8
  %ptr_gep35 = getelementptr i8, ptr %ptr_load34, i32 %i33
  store i32 0, ptr %z, align 4
  %a2 = alloca i32, align 4
  %i36 = load i32, ptr %i, align 4
  %ptr_load37 = load ptr, ptr %flds, align 8
  %ptr_gep38 = getelementptr i8, ptr %ptr_load37, i32 %i36
  store i32 0, ptr %a2, align 4
  %i39 = load i32, ptr %i, align 4
  %o40 = load i32, ptr %o, align 4
  %z41 = load i32, ptr %z, align 4
  %a242 = load i32, ptr %a2, align 4
  %2 = call i32 (ptr, ...) @printf(ptr @str.1, i32 %i39, i32 %o40, i32 %z41, i32 %a242)
  %i43 = load i32, ptr %i, align 4
  %add = add i32 %i43, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  br label %match_merge

arm_body44:                                       ; preds = %arm_next
  %self_ptr = load ptr, ptr %ti, align 8
  %ptr_deref = load ptr, ptr %ti, align 8
  %__tag = getelementptr inbounds nuw %type_info, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref45 = load ptr, ptr %ti, align 8
  %mem_load = load i32, ptr %__tag, align 4
  %3 = call i32 (ptr, ...) @printf(ptr @str.2, i32 %mem_load)
  br label %match_merge
}

define i32 @main() {
entry:
  %0 = call i32 (ptr, ...) @printf(ptr @str.3)
  call void @dump(ptr @__typeinfo_Mixed)
  %n = alloca i32, align 4
  store i32 42, ptr %n, align 4
  %n1 = load i32, ptr %n, align 4
  %anon_s = alloca %__anon3_P_i32_i64, align 8
  %anon_f = getelementptr inbounds nuw %__anon3_P_i32_i64, ptr %anon_s, i32 0, i32 0
  store ptr @str.4, ptr %anon_f, align 8
  %anon_f2 = getelementptr inbounds nuw %__anon3_P_i32_i64, ptr %anon_s, i32 0, i32 1
  store i32 %n1, ptr %anon_f2, align 4
  %anon_f3 = getelementptr inbounds nuw %__anon3_P_i32_i64, ptr %anon_s, i32 0, i32 2
  store i64 7, ptr %anon_f3, align 4
  %anon_load = load %__anon3_P_i32_i64, ptr %anon_s, align 8
  call void @probe__at_args_S__anon3_P_i32_i64(%__anon3_P_i32_i64 %anon_load)
  ret i32 0
}

define void @__artemis_init_typeinfo() {
entry:
  store i32 12, ptr @__typeinfo_Mixed, align 4
  store ptr @__typeinfo_nm_Mixed, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo_Mixed, i32 0, i32 1), align 8
  store i32 12, ptr @__typeinfo_Mixed, align 4
  store ptr @__typeinfo_flds_Mixed, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo_Mixed, i32 0, i32 1), i64 8), align 8
  store i32 12, ptr @__typeinfo_Mixed, align 4
  store i64 3, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo_Mixed, i32 0, i32 1), i64 16), align 8
  store i32 12, ptr @__typeinfo_Mixed, align 4
  store i64 20, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo_Mixed, i32 0, i32 1), i64 24), align 8
  store i32 12, ptr @__typeinfo___anon3_P_i32_i64, align 4
  store ptr @__typeinfo_nm___anon3_P_i32_i64, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon3_P_i32_i64, i32 0, i32 1), align 8
  store i32 12, ptr @__typeinfo___anon3_P_i32_i64, align 4
  store ptr @__typeinfo_flds___anon3_P_i32_i64, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon3_P_i32_i64, i32 0, i32 1), i64 8), align 8
  store i32 12, ptr @__typeinfo___anon3_P_i32_i64, align 4
  store i64 3, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon3_P_i32_i64, i32 0, i32 1), i64 16), align 8
  store i32 12, ptr @__typeinfo___anon3_P_i32_i64, align 4
  store i64 20, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon3_P_i32_i64, i32 0, i32 1), i64 24), align 8
  ret void
}

define internal void @probe__at_args_S__anon3_P_i32_i64(%__anon3_P_i32_i64 %0) {
entry:
  %args = alloca %__anon3_P_i32_i64, align 8
  store %__anon3_P_i32_i64 %0, ptr %args, align 8
  %1 = call i32 (ptr, ...) @printf(ptr @str.5)
  call void @dump(ptr @__typeinfo___anon3_P_i32_i64)
  ret void
}
