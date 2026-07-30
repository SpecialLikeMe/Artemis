; ModuleID = '.tmpwork/fw_t.arc'
source_filename = ".tmpwork/fw_t.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%type_info = type { i32, [72 x i8] }
%type_info_field = type { ptr, i32, i32, i32 }
%memstr = type { ptr, ptr }
%__vtable__ = type { ptr, ptr, ptr, ptr, ptr }
%__anon1_i32 = type { i32 }

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
@str = private unnamed_addr constant [7 x i8] c"(null)\00", align 1
@str.2 = private unnamed_addr constant [5 x i8] c"x=%d\00", align 1
@__typeinfo___anon1_i32 = global %type_info zeroinitializer
@__typeinfo_nm___anon1_i32 = constant [12 x i8] c"__anon1_i32\00"
@__typeinfo_fn___anon1_i32_0 = constant [4 x i8] c"__0\00"
@__typeinfo_flds___anon1_i32 = constant [1 x %type_info_field] [%type_info_field { ptr @__typeinfo_fn___anon1_i32_0, i32 0, i32 4, i32 4 }]
@str.3 = private unnamed_addr constant [31 x i8] c"  inside fwd: tag=%d fmt=[%s]\0A\00", align 1
@str.4 = private unnamed_addr constant [25 x i8] c"  inner afmt -> %d [%s]\0A\00", align 1
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
  store i64 %1, ptr %size, align 8
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
  %size10 = load i64, ptr %size, align 8
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
  store i64 %1, ptr %align, align 8
  %size = alloca i64, align 8
  store i64 %2, ptr %size, align 8
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
  %align10 = load i64, ptr %align, align 8
  %size11 = load i64, ptr %size, align 8
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
  %size = alloca i65, align 16
  store i65 %2, ptr %size, align 16
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
  %size11 = load i65, ptr %size, align 16
  %3 = call i8 %fp_val(ptr %mem_load9, ptr %data10, i65 %size11)
  ret i8 %3
}

define internal { i32, ptr } @memstr__NS_rmap(ptr %0, ptr %1, i65 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %data = alloca ptr, align 8
  store ptr %1, ptr %data, align 8
  %size = alloca i65, align 16
  store i65 %2, ptr %size, align 16
  %self_load = load ptr, ptr %self, align 8
  %data1 = load ptr, ptr %data, align 8
  %size2 = load i65, ptr %size, align 16
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
  %size17 = load i65, ptr %size, align 16
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
  store i64 %1, ptr %size, align 8
  %p = alloca ptr, align 8
  %self_load = load ptr, ptr %self, align 8
  %size1 = load i64, ptr %size, align 8
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
  store i64 0, ptr %i, align 8
  br label %while_cond

while_cond:                                       ; preds = %while_body, %try_ok
  %i3 = load i64, ptr %i, align 8
  %size4 = load i64, ptr %size, align 8
  %icmp = icmp ult i64 %i3, %size4
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i5 = load i64, ptr %i, align 8
  %ptr_load = load ptr, ptr %b, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %i5
  store i8 0, ptr %ptr_gep, align 1
  %i6 = load i64, ptr %i, align 8
  %add = add i64 %i6, 1
  store i64 %add, ptr %i, align 8
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %p7 = load ptr, ptr %p, align 8
  %eu_val = insertvalue { i32, ptr } { i32 0, ptr undef }, ptr %p7, 1
  ret { i32, ptr } %eu_val
}

declare i64 @fwrite(ptr, i64, i64, ptr)

declare ptr @__acrt_iob_func(i32)

declare ptr @malloc(i64)

declare void @free(ptr)

define internal i64 @fwrite.1(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %s = alloca i64, align 8
  store i64 %1, ptr %s, align 8
  %n = alloca i64, align 8
  store i64 %2, ptr %n, align 8
  %f = alloca ptr, align 8
  store ptr %3, ptr %f, align 8
  %r = alloca i64, align 8
  store i64 0, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %s2 = load i64, ptr %s, align 8
  %n3 = load i64, ptr %n, align 8
  %f4 = load ptr, ptr %f, align 8
  %4 = call i64 @fwrite(ptr %b1, i64 %s2, i64 %n3, ptr %f4)
  store i64 %4, ptr %r, align 8
  %r5 = load i64, ptr %r, align 8
  ret i64 %r5
}

define internal ptr @stdout_file() {
entry:
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %0 = call ptr @__acrt_iob_func(i32 1)
  store ptr %0, ptr %r, align 8
  %r1 = load ptr, ptr %r, align 8
  ret ptr %r1
}

define internal ptr @arc_malloc(i64 %0) {
entry:
  %n = alloca i64, align 8
  store i64 %0, ptr %n, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %n1 = load i64, ptr %n, align 8
  %1 = call ptr @malloc(i64 %n1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal void @arc_free(ptr %0) {
entry:
  %p = alloca ptr, align 8
  store ptr %0, ptr %p, align 8
  %p1 = load ptr, ptr %p, align 8
  call void @free(ptr %p1)
  ret void
}

define internal i64 @afmt_impl__NS_put(ptr %0, i64 %1, i64 %2, i8 %3) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %len = alloca i64, align 8
  store i64 %2, ptr %len, align 8
  %c = alloca i8, align 1
  store i8 %3, ptr %c, align 1
  %len1 = load i64, ptr %len, align 8
  %add = add i64 %len1, 1
  %cap2 = load i64, ptr %cap, align 8
  %icmp = icmp slt i64 %add, %cap2
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %len3 = load i64, ptr %len, align 8
  %ptr_load = load ptr, ptr %buf, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %len3
  %c4 = load i8, ptr %c, align 1
  store i8 %c4, ptr %ptr_gep, align 1
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  %len5 = load i64, ptr %len, align 8
  %add6 = add i64 %len5, 1
  ret i64 %add6
}

define internal i64 @afmt_impl__NS_put_str(ptr %0, i64 %1, i64 %2, ptr %3, i32 %4) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %len = alloca i64, align 8
  store i64 %2, ptr %len, align 8
  %s = alloca ptr, align 8
  store ptr %3, ptr %s, align 8
  %maxn = alloca i32, align 4
  store i32 %4, ptr %maxn, align 4
  %s1 = load ptr, ptr %s, align 8
  %icmp = icmp eq ptr %s1, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  store ptr @str, ptr %s, align 8
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  %n = alloca i64, align 8
  %len2 = load i64, ptr %len, align 8
  store i64 %len2, ptr %n, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge11, %if_merge
  %i3 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %s, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i3
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp4 = icmp ne i8 %idx_load, 0
  br i1 %icmp4, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %maxn5 = load i32, ptr %maxn, align 4
  %icmp6 = icmp sge i32 %maxn5, 0
  br i1 %icmp6, label %land_rhs, label %land_merge

while_exit:                                       ; preds = %if_then10, %while_cond
  %n20 = load i64, ptr %n, align 8
  ret i64 %n20

land_rhs:                                         ; preds = %while_body
  %i7 = load i32, ptr %i, align 4
  %maxn8 = load i32, ptr %maxn, align 4
  %icmp9 = icmp sge i32 %i7, %maxn8
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_body
  %land = phi i1 [ false, %while_body ], [ %icmp9, %land_rhs ]
  br i1 %land, label %if_then10, label %if_merge11

if_then10:                                        ; preds = %land_merge
  br label %while_exit

if_merge11:                                       ; preds = %land_merge
  %buf12 = load ptr, ptr %buf, align 8
  %cap13 = load i64, ptr %cap, align 8
  %n14 = load i64, ptr %n, align 8
  %i15 = load i32, ptr %i, align 4
  %ptr_load16 = load ptr, ptr %s, align 8
  %ptr_gep17 = getelementptr i8, ptr %ptr_load16, i32 %i15
  %idx_load18 = load i8, ptr %ptr_gep17, align 1
  %5 = call i64 @afmt_impl__NS_put(ptr %buf12, i64 %cap13, i64 %n14, i8 %idx_load18)
  store i64 %5, ptr %n, align 8
  %i19 = load i32, ptr %i, align 4
  %add = add i32 %i19, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond
}

define internal i64 @afmt_impl__NS_put_uint(ptr %0, i64 %1, i64 %2, i64 %3, i64 %4, i8 %5) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %len = alloca i64, align 8
  store i64 %2, ptr %len, align 8
  %v = alloca i64, align 8
  store i64 %3, ptr %v, align 8
  %base = alloca i64, align 8
  store i64 %4, ptr %base, align 8
  %upper = alloca i8, align 1
  store i8 %5, ptr %upper, align 1
  %tmp = alloca [32 x i8], align 1
  store [32 x i8] zeroinitializer, ptr %tmp, align 1
  %n = alloca i32, align 4
  store i32 0, ptr %n, align 4
  %v1 = load i64, ptr %v, align 8
  %icmp = icmp eq i64 %v1, 0
  br i1 %icmp, label %if_then, label %if_else

if_then:                                          ; preds = %entry
  %arr_gep = getelementptr [32 x i8], ptr %tmp, i64 0, i32 0
  store i8 48, ptr %arr_gep, align 1
  store i32 1, ptr %n, align 4
  br label %if_merge

if_else:                                          ; preds = %entry
  %x = alloca i64, align 8
  %v2 = load i64, ptr %v, align 8
  store i64 %v2, ptr %x, align 8
  br label %while_cond

if_merge:                                         ; preds = %while_exit, %if_then
  %out = alloca i64, align 8
  %len27 = load i64, ptr %len, align 8
  store i64 %len27, ptr %out, align 8
  %i = alloca i32, align 4
  %n28 = load i32, ptr %n, align 4
  %sub29 = sub i32 %n28, 1
  store i32 %sub29, ptr %i, align 4
  br label %while_cond30

while_cond:                                       ; preds = %tern_merge, %if_else
  %x3 = load i64, ptr %x, align 8
  %icmp4 = icmp ugt i64 %x3, 0
  br i1 %icmp4, label %land_rhs, label %land_merge

while_body:                                       ; preds = %land_merge
  %d = alloca i64, align 8
  %x7 = load i64, ptr %x, align 8
  %base8 = load i64, ptr %base, align 8
  %urem = urem i64 %x7, %base8
  store i64 %urem, ptr %d, align 8
  %c = alloca i8, align 1
  %d9 = load i64, ptr %d, align 8
  %icmp10 = icmp ult i64 %d9, 10
  br i1 %icmp10, label %tern_then, label %tern_else

while_exit:                                       ; preds = %land_merge
  br label %if_merge

land_rhs:                                         ; preds = %while_cond
  %n5 = load i32, ptr %n, align 4
  %icmp6 = icmp slt i32 %n5, 32
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond
  %land = phi i1 [ false, %while_cond ], [ %icmp6, %land_rhs ]
  br i1 %land, label %while_body, label %while_exit

tern_then:                                        ; preds = %while_body
  %d11 = load i64, ptr %d, align 8
  %add = add i64 48, %d11
  %trunc = trunc i64 %add to i8
  br label %tern_merge

tern_else:                                        ; preds = %while_body
  %upper12 = load i8, ptr %upper, align 1
  %tobool = icmp ne i8 %upper12, 0
  br i1 %tobool, label %tern_then13, label %tern_else14

tern_merge:                                       ; preds = %tern_merge15, %tern_then
  %tern19 = phi i8 [ %trunc, %tern_then ], [ %trunc18, %tern_merge15 ]
  store i8 %tern19, ptr %c, align 1
  %n20 = load i32, ptr %n, align 4
  %arr_gep21 = getelementptr [32 x i8], ptr %tmp, i64 0, i32 %n20
  %c22 = load i8, ptr %c, align 1
  store i8 %c22, ptr %arr_gep21, align 1
  %n23 = load i32, ptr %n, align 4
  %add24 = add i32 %n23, 1
  store i32 %add24, ptr %n, align 4
  %x25 = load i64, ptr %x, align 8
  %base26 = load i64, ptr %base, align 8
  %udiv = udiv i64 %x25, %base26
  store i64 %udiv, ptr %x, align 8
  br label %while_cond

tern_then13:                                      ; preds = %tern_else
  br label %tern_merge15

tern_else14:                                      ; preds = %tern_else
  br label %tern_merge15

tern_merge15:                                     ; preds = %tern_else14, %tern_then13
  %tern = phi i8 [ 65, %tern_then13 ], [ 97, %tern_else14 ]
  %zext = zext i8 %tern to i64
  %d16 = load i64, ptr %d, align 8
  %sub = sub i64 %d16, 10
  %add17 = add i64 %zext, %sub
  %trunc18 = trunc i64 %add17 to i8
  br label %tern_merge

while_cond30:                                     ; preds = %bounds_ok, %if_merge
  %i33 = load i32, ptr %i, align 4
  %icmp34 = icmp sge i32 %i33, 0
  br i1 %icmp34, label %while_body31, label %while_exit32

while_body31:                                     ; preds = %while_cond30
  %buf35 = load ptr, ptr %buf, align 8
  %cap36 = load i64, ptr %cap, align 8
  %out37 = load i64, ptr %out, align 8
  %i38 = load i32, ptr %i, align 4
  %idx64 = sext i32 %i38 to i64
  %oob_cmp = icmp uge i64 %idx64, 32
  br i1 %oob_cmp, label %oob_abort, label %bounds_ok

while_exit32:                                     ; preds = %while_cond30
  %out42 = load i64, ptr %out, align 8
  ret i64 %out42

oob_abort:                                        ; preds = %while_body31
  call void @abort()
  unreachable

bounds_ok:                                        ; preds = %while_body31
  %arr_gep39 = getelementptr [32 x i8], ptr %tmp, i64 0, i32 %i38
  %idx_load = load i8, ptr %arr_gep39, align 1
  %6 = call i64 @afmt_impl__NS_put(ptr %buf35, i64 %cap36, i64 %out37, i8 %idx_load)
  store i64 %6, ptr %out, align 8
  %i40 = load i32, ptr %i, align 4
  %sub41 = sub i32 %i40, 1
  store i32 %sub41, ptr %i, align 4
  br label %while_cond30
}

define internal i64 @afmt_impl__NS_put_int(ptr %0, i64 %1, i64 %2, i64 %3) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %len = alloca i64, align 8
  store i64 %2, ptr %len, align 8
  %v = alloca i64, align 8
  store i64 %3, ptr %v, align 8
  %out = alloca i64, align 8
  %len1 = load i64, ptr %len, align 8
  store i64 %len1, ptr %out, align 8
  %v2 = load i64, ptr %v, align 8
  %icmp = icmp slt i64 %v2, 0
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %buf3 = load ptr, ptr %buf, align 8
  %cap4 = load i64, ptr %cap, align 8
  %out5 = load i64, ptr %out, align 8
  %4 = call i64 @afmt_impl__NS_put(ptr %buf3, i64 %cap4, i64 %out5, i8 45)
  store i64 %4, ptr %out, align 8
  %mag = alloca i64, align 8
  %v6 = load i64, ptr %v, align 8
  %sub = sub i64 0, %v6
  store i64 %sub, ptr %mag, align 8
  %buf7 = load ptr, ptr %buf, align 8
  %cap8 = load i64, ptr %cap, align 8
  %out9 = load i64, ptr %out, align 8
  %mag10 = load i64, ptr %mag, align 8
  %5 = call i64 @afmt_impl__NS_put_uint(ptr %buf7, i64 %cap8, i64 %out9, i64 %mag10, i64 10, i8 0)
  ret i64 %5

if_merge:                                         ; preds = %entry
  %buf11 = load ptr, ptr %buf, align 8
  %cap12 = load i64, ptr %cap, align 8
  %out13 = load i64, ptr %out, align 8
  %v14 = load i64, ptr %v, align 8
  %6 = call i64 @afmt_impl__NS_put_uint(ptr %buf11, i64 %cap12, i64 %out13, i64 %v14, i64 10, i8 0)
  ret i64 %6
}

define internal i64 @afmt_impl__NS_put_f64(ptr %0, i64 %1, i64 %2, double %3) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %len = alloca i64, align 8
  store i64 %2, ptr %len, align 8
  %v = alloca double, align 8
  store double %3, ptr %v, align 8
  %out = alloca i64, align 8
  %len1 = load i64, ptr %len, align 8
  store i64 %len1, ptr %out, align 8
  %x = alloca double, align 8
  %v2 = load double, ptr %v, align 8
  store double %v2, ptr %x, align 8
  %x3 = load double, ptr %x, align 8
  %fcmp = fcmp olt double %x3, 0.000000e+00
  br i1 %fcmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %buf4 = load ptr, ptr %buf, align 8
  %cap5 = load i64, ptr %cap, align 8
  %out6 = load i64, ptr %out, align 8
  %4 = call i64 @afmt_impl__NS_put(ptr %buf4, i64 %cap5, i64 %out6, i8 45)
  store i64 %4, ptr %out, align 8
  %x7 = load double, ptr %x, align 8
  %fneg = fneg double %x7
  store double %fneg, ptr %x, align 8
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  %whole = alloca i64, align 8
  %x8 = load double, ptr %x, align 8
  %fptou = fptoui double %x8 to i64
  store i64 %fptou, ptr %whole, align 8
  %buf9 = load ptr, ptr %buf, align 8
  %cap10 = load i64, ptr %cap, align 8
  %out11 = load i64, ptr %out, align 8
  %whole12 = load i64, ptr %whole, align 8
  %5 = call i64 @afmt_impl__NS_put_uint(ptr %buf9, i64 %cap10, i64 %out11, i64 %whole12, i64 10, i8 0)
  store i64 %5, ptr %out, align 8
  %buf13 = load ptr, ptr %buf, align 8
  %cap14 = load i64, ptr %cap, align 8
  %out15 = load i64, ptr %out, align 8
  %6 = call i64 @afmt_impl__NS_put(ptr %buf13, i64 %cap14, i64 %out15, i8 46)
  store i64 %6, ptr %out, align 8
  %frac = alloca double, align 8
  %x16 = load double, ptr %x, align 8
  %whole17 = load i64, ptr %whole, align 8
  %sitofp = sitofp i64 %whole17 to double
  %fsub = fsub double %x16, %sitofp
  store double %fsub, ptr %frac, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge25, %if_merge
  %i18 = load i32, ptr %i, align 4
  %icmp = icmp slt i32 %i18, 6
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %frac19 = load double, ptr %frac, align 8
  %fmul = fmul double %frac19, 1.000000e+01
  store double %fmul, ptr %frac, align 8
  %d = alloca i64, align 8
  %frac20 = load double, ptr %frac, align 8
  %fptou21 = fptoui double %frac20 to i64
  store i64 %fptou21, ptr %d, align 8
  %d22 = load i64, ptr %d, align 8
  %icmp23 = icmp ugt i64 %d22, 9
  br i1 %icmp23, label %if_then24, label %if_merge25

while_exit:                                       ; preds = %while_cond
  %out36 = load i64, ptr %out, align 8
  ret i64 %out36

if_then24:                                        ; preds = %while_body
  store i64 9, ptr %d, align 8
  br label %if_merge25

if_merge25:                                       ; preds = %if_then24, %while_body
  %buf26 = load ptr, ptr %buf, align 8
  %cap27 = load i64, ptr %cap, align 8
  %out28 = load i64, ptr %out, align 8
  %d29 = load i64, ptr %d, align 8
  %add = add i64 48, %d29
  %trunc = trunc i64 %add to i8
  %7 = call i64 @afmt_impl__NS_put(ptr %buf26, i64 %cap27, i64 %out28, i8 %trunc)
  store i64 %7, ptr %out, align 8
  %frac30 = load double, ptr %frac, align 8
  %d31 = load i64, ptr %d, align 8
  %sitofp32 = sitofp i64 %d31 to double
  %fsub33 = fsub double %frac30, %sitofp32
  store double %fsub33, ptr %frac, align 8
  %i34 = load i32, ptr %i, align 4
  %add35 = add i32 %i34, 1
  store i32 %add35, ptr %i, align 4
  br label %while_cond
}

declare void @abort()

define internal i32 @afmt_v(ptr %0, i64 %1, ptr %2, ptr %3, ptr %4, i32 %5) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %fmt = alloca ptr, align 8
  store ptr %2, ptr %fmt, align 8
  %argp = alloca ptr, align 8
  store ptr %3, ptr %argp, align 8
  %fields = alloca ptr, align 8
  store ptr %4, ptr %fields, align 8
  %nfields = alloca i32, align 4
  store i32 %5, ptr %nfields, align 4
  %len = alloca i64, align 8
  store i64 0, ptr %len, align 8
  %ai = alloca i32, align 4
  store i32 0, ptr %ai, align 4
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge189, %if_then157, %if_then22, %if_then, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %fmt, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i1
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp ne i8 %idx_load, 0
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i2 = load i32, ptr %i, align 4
  %ptr_load3 = load ptr, ptr %fmt, align 8
  %ptr_gep4 = getelementptr i8, ptr %ptr_load3, i32 %i2
  %idx_load5 = load i8, ptr %ptr_gep4, align 1
  %icmp6 = icmp ne i8 %idx_load5, 37
  br i1 %icmp6, label %if_then, label %if_merge

while_exit:                                       ; preds = %if_then150, %while_cond
  %cap336 = load i64, ptr %cap, align 8
  %icmp337 = icmp ugt i64 %cap336, 0
  br i1 %icmp337, label %if_then338, label %if_merge339

if_then:                                          ; preds = %while_body
  %buf7 = load ptr, ptr %buf, align 8
  %cap8 = load i64, ptr %cap, align 8
  %len9 = load i64, ptr %len, align 8
  %i10 = load i32, ptr %i, align 4
  %ptr_load11 = load ptr, ptr %fmt, align 8
  %ptr_gep12 = getelementptr i8, ptr %ptr_load11, i32 %i10
  %idx_load13 = load i8, ptr %ptr_gep12, align 1
  %6 = call i64 @afmt_impl__NS_put(ptr %buf7, i64 %cap8, i64 %len9, i8 %idx_load13)
  store i64 %6, ptr %len, align 8
  %i14 = load i32, ptr %i, align 4
  %add = add i32 %i14, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond

if_merge:                                         ; preds = %while_body
  %i15 = load i32, ptr %i, align 4
  %add16 = add i32 %i15, 1
  store i32 %add16, ptr %i, align 4
  %i17 = load i32, ptr %i, align 4
  %ptr_load18 = load ptr, ptr %fmt, align 8
  %ptr_gep19 = getelementptr i8, ptr %ptr_load18, i32 %i17
  %idx_load20 = load i8, ptr %ptr_gep19, align 1
  %icmp21 = icmp eq i8 %idx_load20, 37
  br i1 %icmp21, label %if_then22, label %if_merge23

if_then22:                                        ; preds = %if_merge
  %buf24 = load ptr, ptr %buf, align 8
  %cap25 = load i64, ptr %cap, align 8
  %len26 = load i64, ptr %len, align 8
  %7 = call i64 @afmt_impl__NS_put(ptr %buf24, i64 %cap25, i64 %len26, i8 37)
  store i64 %7, ptr %len, align 8
  %i27 = load i32, ptr %i, align 4
  %add28 = add i32 %i27, 1
  store i32 %add28, ptr %i, align 4
  br label %while_cond

if_merge23:                                       ; preds = %if_merge
  %prec = alloca i32, align 4
  store i32 -1, ptr %prec, align 4
  br label %while_cond29

while_cond29:                                     ; preds = %while_body30, %if_merge23
  %i32 = load i32, ptr %i, align 4
  %ptr_load33 = load ptr, ptr %fmt, align 8
  %ptr_gep34 = getelementptr i8, ptr %ptr_load33, i32 %i32
  %idx_load35 = load i8, ptr %ptr_gep34, align 1
  %icmp36 = icmp sge i8 %idx_load35, 48
  br i1 %icmp36, label %land_rhs, label %land_merge

while_body30:                                     ; preds = %lor_merge48
  %i55 = load i32, ptr %i, align 4
  %add56 = add i32 %i55, 1
  store i32 %add56, ptr %i, align 4
  br label %while_cond29

while_exit31:                                     ; preds = %lor_merge48
  %i57 = load i32, ptr %i, align 4
  %ptr_load58 = load ptr, ptr %fmt, align 8
  %ptr_gep59 = getelementptr i8, ptr %ptr_load58, i32 %i57
  %idx_load60 = load i8, ptr %ptr_gep59, align 1
  %icmp61 = icmp eq i8 %idx_load60, 46
  br i1 %icmp61, label %if_then62, label %if_merge63

land_rhs:                                         ; preds = %while_cond29
  %i37 = load i32, ptr %i, align 4
  %ptr_load38 = load ptr, ptr %fmt, align 8
  %ptr_gep39 = getelementptr i8, ptr %ptr_load38, i32 %i37
  %idx_load40 = load i8, ptr %ptr_gep39, align 1
  %icmp41 = icmp sle i8 %idx_load40, 57
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond29
  %land = phi i1 [ false, %while_cond29 ], [ %icmp41, %land_rhs ]
  br i1 %land, label %lor_merge, label %lor_rhs

lor_rhs:                                          ; preds = %land_merge
  %i42 = load i32, ptr %i, align 4
  %ptr_load43 = load ptr, ptr %fmt, align 8
  %ptr_gep44 = getelementptr i8, ptr %ptr_load43, i32 %i42
  %idx_load45 = load i8, ptr %ptr_gep44, align 1
  %icmp46 = icmp eq i8 %idx_load45, 45
  br label %lor_merge

lor_merge:                                        ; preds = %lor_rhs, %land_merge
  %lor = phi i1 [ true, %land_merge ], [ %icmp46, %lor_rhs ]
  br i1 %lor, label %lor_merge48, label %lor_rhs47

lor_rhs47:                                        ; preds = %lor_merge
  %i49 = load i32, ptr %i, align 4
  %ptr_load50 = load ptr, ptr %fmt, align 8
  %ptr_gep51 = getelementptr i8, ptr %ptr_load50, i32 %i49
  %idx_load52 = load i8, ptr %ptr_gep51, align 1
  %icmp53 = icmp eq i8 %idx_load52, 43
  br label %lor_merge48

lor_merge48:                                      ; preds = %lor_rhs47, %lor_merge
  %lor54 = phi i1 [ true, %lor_merge ], [ %icmp53, %lor_rhs47 ]
  br i1 %lor54, label %while_body30, label %while_exit31

if_then62:                                        ; preds = %while_exit31
  %i64 = load i32, ptr %i, align 4
  %add65 = add i32 %i64, 1
  store i32 %add65, ptr %i, align 4
  %i66 = load i32, ptr %i, align 4
  %ptr_load67 = load ptr, ptr %fmt, align 8
  %ptr_gep68 = getelementptr i8, ptr %ptr_load67, i32 %i66
  %idx_load69 = load i8, ptr %ptr_gep68, align 1
  %icmp70 = icmp eq i8 %idx_load69, 42
  br i1 %icmp70, label %if_then71, label %if_else

if_merge63:                                       ; preds = %if_merge72, %while_exit31
  %long_n = alloca i32, align 4
  store i32 0, ptr %long_n, align 4
  br label %while_cond114

if_then71:                                        ; preds = %if_then62
  %i73 = load i32, ptr %i, align 4
  %add74 = add i32 %i73, 1
  store i32 %add74, ptr %i, align 4
  %ai75 = load i32, ptr %ai, align 4
  %nfields76 = load i32, ptr %nfields, align 4
  %icmp77 = icmp slt i32 %ai75, %nfields76
  br i1 %icmp77, label %if_then78, label %if_merge79

if_else:                                          ; preds = %if_then62
  store i32 0, ptr %prec, align 4
  br label %while_cond90

if_merge72:                                       ; preds = %while_exit92, %if_merge79
  br label %if_merge63

if_then78:                                        ; preds = %if_then71
  %pp = alloca ptr, align 8
  %argp80 = load ptr, ptr %argp, align 8
  %ai81 = load i32, ptr %ai, align 4
  %ptr_load82 = load ptr, ptr %fields, align 8
  %ptr_gep83 = getelementptr %type_info_field, ptr %ptr_load82, i32 %ai81
  %offset = getelementptr inbounds nuw %type_info_field, ptr %ptr_gep83, i32 0, i32 1
  %ai84 = load i32, ptr %ai, align 4
  %ptr_load85 = load ptr, ptr %fields, align 8
  %ptr_gep86 = getelementptr %type_info_field, ptr %ptr_load85, i32 %ai84
  %mem_load = load i32, ptr %offset, align 4
  %ptr_add = getelementptr i8, ptr %argp80, i32 %mem_load
  store ptr %ptr_add, ptr %pp, align 8
  %pp87 = load ptr, ptr %pp, align 8
  %deref = load i32, ptr %pp87, align 4
  store i32 %deref, ptr %prec, align 4
  %ai88 = load i32, ptr %ai, align 4
  %add89 = add i32 %ai88, 1
  store i32 %add89, ptr %ai, align 4
  br label %if_merge79

if_merge79:                                       ; preds = %if_then78, %if_then71
  br label %if_merge72

while_cond90:                                     ; preds = %while_body91, %if_else
  %i93 = load i32, ptr %i, align 4
  %ptr_load94 = load ptr, ptr %fmt, align 8
  %ptr_gep95 = getelementptr i8, ptr %ptr_load94, i32 %i93
  %idx_load96 = load i8, ptr %ptr_gep95, align 1
  %icmp97 = icmp sge i8 %idx_load96, 48
  br i1 %icmp97, label %land_rhs98, label %land_merge99

while_body91:                                     ; preds = %land_merge99
  %prec106 = load i32, ptr %prec, align 4
  %mul = mul i32 %prec106, 10
  %i107 = load i32, ptr %i, align 4
  %ptr_load108 = load ptr, ptr %fmt, align 8
  %ptr_gep109 = getelementptr i8, ptr %ptr_load108, i32 %i107
  %idx_load110 = load i8, ptr %ptr_gep109, align 1
  %sub = sub i8 %idx_load110, 48
  %sext = sext i8 %sub to i32
  %add111 = add i32 %mul, %sext
  store i32 %add111, ptr %prec, align 4
  %i112 = load i32, ptr %i, align 4
  %add113 = add i32 %i112, 1
  store i32 %add113, ptr %i, align 4
  br label %while_cond90

while_exit92:                                     ; preds = %land_merge99
  br label %if_merge72

land_rhs98:                                       ; preds = %while_cond90
  %i100 = load i32, ptr %i, align 4
  %ptr_load101 = load ptr, ptr %fmt, align 8
  %ptr_gep102 = getelementptr i8, ptr %ptr_load101, i32 %i100
  %idx_load103 = load i8, ptr %ptr_gep102, align 1
  %icmp104 = icmp sle i8 %idx_load103, 57
  br label %land_merge99

land_merge99:                                     ; preds = %land_rhs98, %while_cond90
  %land105 = phi i1 [ false, %while_cond90 ], [ %icmp104, %land_rhs98 ]
  br i1 %land105, label %while_body91, label %while_exit92

while_cond114:                                    ; preds = %while_body115, %if_merge63
  %i117 = load i32, ptr %i, align 4
  %ptr_load118 = load ptr, ptr %fmt, align 8
  %ptr_gep119 = getelementptr i8, ptr %ptr_load118, i32 %i117
  %idx_load120 = load i8, ptr %ptr_gep119, align 1
  %icmp121 = icmp eq i8 %idx_load120, 108
  br i1 %icmp121, label %while_body115, label %while_exit116

while_body115:                                    ; preds = %while_cond114
  %long_n122 = load i32, ptr %long_n, align 4
  %add123 = add i32 %long_n122, 1
  store i32 %add123, ptr %long_n, align 4
  %i124 = load i32, ptr %i, align 4
  %add125 = add i32 %i124, 1
  store i32 %add125, ptr %i, align 4
  br label %while_cond114

while_exit116:                                    ; preds = %while_cond114
  br label %while_cond126

while_cond126:                                    ; preds = %while_body127, %while_exit116
  %i129 = load i32, ptr %i, align 4
  %ptr_load130 = load ptr, ptr %fmt, align 8
  %ptr_gep131 = getelementptr i8, ptr %ptr_load130, i32 %i129
  %idx_load132 = load i8, ptr %ptr_gep131, align 1
  %icmp133 = icmp eq i8 %idx_load132, 104
  br i1 %icmp133, label %lor_merge135, label %lor_rhs134

while_body127:                                    ; preds = %lor_merge135
  %i142 = load i32, ptr %i, align 4
  %add143 = add i32 %i142, 1
  store i32 %add143, ptr %i, align 4
  br label %while_cond126

while_exit128:                                    ; preds = %lor_merge135
  %conv = alloca i8, align 1
  %i144 = load i32, ptr %i, align 4
  %ptr_load145 = load ptr, ptr %fmt, align 8
  %ptr_gep146 = getelementptr i8, ptr %ptr_load145, i32 %i144
  %idx_load147 = load i8, ptr %ptr_gep146, align 1
  store i8 %idx_load147, ptr %conv, align 1
  %conv148 = load i8, ptr %conv, align 1
  %icmp149 = icmp eq i8 %conv148, 0
  br i1 %icmp149, label %if_then150, label %if_merge151

lor_rhs134:                                       ; preds = %while_cond126
  %i136 = load i32, ptr %i, align 4
  %ptr_load137 = load ptr, ptr %fmt, align 8
  %ptr_gep138 = getelementptr i8, ptr %ptr_load137, i32 %i136
  %idx_load139 = load i8, ptr %ptr_gep138, align 1
  %icmp140 = icmp eq i8 %idx_load139, 122
  br label %lor_merge135

lor_merge135:                                     ; preds = %lor_rhs134, %while_cond126
  %lor141 = phi i1 [ true, %while_cond126 ], [ %icmp140, %lor_rhs134 ]
  br i1 %lor141, label %while_body127, label %while_exit128

if_then150:                                       ; preds = %while_exit128
  br label %while_exit

if_merge151:                                      ; preds = %while_exit128
  %i152 = load i32, ptr %i, align 4
  %add153 = add i32 %i152, 1
  store i32 %add153, ptr %i, align 4
  %ai154 = load i32, ptr %ai, align 4
  %nfields155 = load i32, ptr %nfields, align 4
  %icmp156 = icmp sge i32 %ai154, %nfields155
  br i1 %icmp156, label %if_then157, label %if_merge158

if_then157:                                       ; preds = %if_merge151
  %buf159 = load ptr, ptr %buf, align 8
  %cap160 = load i64, ptr %cap, align 8
  %len161 = load i64, ptr %len, align 8
  %8 = call i64 @afmt_impl__NS_put(ptr %buf159, i64 %cap160, i64 %len161, i8 37)
  store i64 %8, ptr %len, align 8
  %buf162 = load ptr, ptr %buf, align 8
  %cap163 = load i64, ptr %cap, align 8
  %len164 = load i64, ptr %len, align 8
  %conv165 = load i8, ptr %conv, align 1
  %9 = call i64 @afmt_impl__NS_put(ptr %buf162, i64 %cap163, i64 %len164, i8 %conv165)
  store i64 %9, ptr %len, align 8
  br label %while_cond

if_merge158:                                      ; preds = %if_merge151
  %off = alloca ptr, align 8
  %argp166 = load ptr, ptr %argp, align 8
  %ai167 = load i32, ptr %ai, align 4
  %ptr_load168 = load ptr, ptr %fields, align 8
  %ptr_gep169 = getelementptr %type_info_field, ptr %ptr_load168, i32 %ai167
  %offset170 = getelementptr inbounds nuw %type_info_field, ptr %ptr_gep169, i32 0, i32 1
  %ai171 = load i32, ptr %ai, align 4
  %ptr_load172 = load ptr, ptr %fields, align 8
  %ptr_gep173 = getelementptr %type_info_field, ptr %ptr_load172, i32 %ai171
  %mem_load174 = load i32, ptr %offset170, align 4
  %ptr_add175 = getelementptr i8, ptr %argp166, i32 %mem_load174
  store ptr %ptr_add175, ptr %off, align 8
  %fsz = alloca i32, align 4
  %ai176 = load i32, ptr %ai, align 4
  %ptr_load177 = load ptr, ptr %fields, align 8
  %ptr_gep178 = getelementptr %type_info_field, ptr %ptr_load177, i32 %ai176
  %size = getelementptr inbounds nuw %type_info_field, ptr %ptr_gep178, i32 0, i32 2
  %ai179 = load i32, ptr %ai, align 4
  %ptr_load180 = load ptr, ptr %fields, align 8
  %ptr_gep181 = getelementptr %type_info_field, ptr %ptr_load180, i32 %ai179
  %mem_load182 = load i32, ptr %size, align 4
  store i32 %mem_load182, ptr %fsz, align 4
  %ai183 = load i32, ptr %ai, align 4
  %add184 = add i32 %ai183, 1
  store i32 %add184, ptr %ai, align 4
  %conv185 = load i8, ptr %conv, align 1
  %icmp186 = icmp eq i8 %conv185, 115
  br i1 %icmp186, label %if_then187, label %if_else188

if_then187:                                       ; preds = %if_merge158
  %sp = alloca ptr, align 8
  %off190 = load ptr, ptr %off, align 8
  store ptr %off190, ptr %sp, align 8
  %buf191 = load ptr, ptr %buf, align 8
  %cap192 = load i64, ptr %cap, align 8
  %len193 = load i64, ptr %len, align 8
  %sp194 = load ptr, ptr %sp, align 8
  %deref195 = load ptr, ptr %sp194, align 8
  %prec196 = load i32, ptr %prec, align 4
  %10 = call i64 @afmt_impl__NS_put_str(ptr %buf191, i64 %cap192, i64 %len193, ptr %deref195, i32 %prec196)
  store i64 %10, ptr %len, align 8
  br label %if_merge189

if_else188:                                       ; preds = %if_merge158
  %conv197 = load i8, ptr %conv, align 1
  %icmp198 = icmp eq i8 %conv197, 100
  br i1 %icmp198, label %lor_merge200, label %lor_rhs199

if_merge189:                                      ; preds = %if_merge206, %if_then187
  br label %while_cond

lor_rhs199:                                       ; preds = %if_else188
  %conv201 = load i8, ptr %conv, align 1
  %icmp202 = icmp eq i8 %conv201, 105
  br label %lor_merge200

lor_merge200:                                     ; preds = %lor_rhs199, %if_else188
  %lor203 = phi i1 [ true, %if_else188 ], [ %icmp202, %lor_rhs199 ]
  br i1 %lor203, label %if_then204, label %if_else205

if_then204:                                       ; preds = %lor_merge200
  %v = alloca i64, align 8
  %long_n207 = load i32, ptr %long_n, align 4
  %icmp208 = icmp sgt i32 %long_n207, 0
  br i1 %icmp208, label %lor_merge210, label %lor_rhs209

if_else205:                                       ; preds = %lor_merge200
  %conv223 = load i8, ptr %conv, align 1
  %icmp224 = icmp eq i8 %conv223, 117
  br i1 %icmp224, label %if_then225, label %if_else226

if_merge206:                                      ; preds = %if_merge227, %tern_merge
  br label %if_merge189

lor_rhs209:                                       ; preds = %if_then204
  %fsz211 = load i32, ptr %fsz, align 4
  %icmp212 = icmp eq i32 %fsz211, 8
  br label %lor_merge210

lor_merge210:                                     ; preds = %lor_rhs209, %if_then204
  %lor213 = phi i1 [ true, %if_then204 ], [ %icmp212, %lor_rhs209 ]
  br i1 %lor213, label %tern_then, label %tern_else

tern_then:                                        ; preds = %lor_merge210
  %off214 = load ptr, ptr %off, align 8
  %deref215 = load i64, ptr %off214, align 8
  br label %tern_merge

tern_else:                                        ; preds = %lor_merge210
  %off216 = load ptr, ptr %off, align 8
  %deref217 = load i32, ptr %off216, align 4
  %sext218 = sext i32 %deref217 to i64
  br label %tern_merge

tern_merge:                                       ; preds = %tern_else, %tern_then
  %tern = phi i64 [ %deref215, %tern_then ], [ %sext218, %tern_else ]
  store i64 %tern, ptr %v, align 8
  %buf219 = load ptr, ptr %buf, align 8
  %cap220 = load i64, ptr %cap, align 8
  %len221 = load i64, ptr %len, align 8
  %v222 = load i64, ptr %v, align 8
  %11 = call i64 @afmt_impl__NS_put_int(ptr %buf219, i64 %cap220, i64 %len221, i64 %v222)
  store i64 %11, ptr %len, align 8
  br label %if_merge206

if_then225:                                       ; preds = %if_else205
  %v228 = alloca i64, align 8
  %long_n229 = load i32, ptr %long_n, align 4
  %icmp230 = icmp sgt i32 %long_n229, 0
  br i1 %icmp230, label %lor_merge232, label %lor_rhs231

if_else226:                                       ; preds = %if_else205
  %conv248 = load i8, ptr %conv, align 1
  %icmp249 = icmp eq i8 %conv248, 120
  br i1 %icmp249, label %lor_merge251, label %lor_rhs250

if_merge227:                                      ; preds = %if_merge257, %tern_merge238
  br label %if_merge206

lor_rhs231:                                       ; preds = %if_then225
  %fsz233 = load i32, ptr %fsz, align 4
  %icmp234 = icmp eq i32 %fsz233, 8
  br label %lor_merge232

lor_merge232:                                     ; preds = %lor_rhs231, %if_then225
  %lor235 = phi i1 [ true, %if_then225 ], [ %icmp234, %lor_rhs231 ]
  br i1 %lor235, label %tern_then236, label %tern_else237

tern_then236:                                     ; preds = %lor_merge232
  %off239 = load ptr, ptr %off, align 8
  %deref240 = load i64, ptr %off239, align 8
  br label %tern_merge238

tern_else237:                                     ; preds = %lor_merge232
  %off241 = load ptr, ptr %off, align 8
  %deref242 = load i32, ptr %off241, align 4
  %zext = zext i32 %deref242 to i64
  br label %tern_merge238

tern_merge238:                                    ; preds = %tern_else237, %tern_then236
  %tern243 = phi i64 [ %deref240, %tern_then236 ], [ %zext, %tern_else237 ]
  store i64 %tern243, ptr %v228, align 8
  %buf244 = load ptr, ptr %buf, align 8
  %cap245 = load i64, ptr %cap, align 8
  %len246 = load i64, ptr %len, align 8
  %v247 = load i64, ptr %v228, align 8
  %12 = call i64 @afmt_impl__NS_put_uint(ptr %buf244, i64 %cap245, i64 %len246, i64 %v247, i64 10, i8 0)
  store i64 %12, ptr %len, align 8
  br label %if_merge227

lor_rhs250:                                       ; preds = %if_else226
  %conv252 = load i8, ptr %conv, align 1
  %icmp253 = icmp eq i8 %conv252, 88
  br label %lor_merge251

lor_merge251:                                     ; preds = %lor_rhs250, %if_else226
  %lor254 = phi i1 [ true, %if_else226 ], [ %icmp253, %lor_rhs250 ]
  br i1 %lor254, label %if_then255, label %if_else256

if_then255:                                       ; preds = %lor_merge251
  %v258 = alloca i64, align 8
  %long_n259 = load i32, ptr %long_n, align 4
  %icmp260 = icmp sgt i32 %long_n259, 0
  br i1 %icmp260, label %lor_merge262, label %lor_rhs261

if_else256:                                       ; preds = %lor_merge251
  %conv282 = load i8, ptr %conv, align 1
  %icmp283 = icmp eq i8 %conv282, 99
  br i1 %icmp283, label %if_then284, label %if_else285

if_merge257:                                      ; preds = %if_merge286, %tern_merge268
  br label %if_merge227

lor_rhs261:                                       ; preds = %if_then255
  %fsz263 = load i32, ptr %fsz, align 4
  %icmp264 = icmp eq i32 %fsz263, 8
  br label %lor_merge262

lor_merge262:                                     ; preds = %lor_rhs261, %if_then255
  %lor265 = phi i1 [ true, %if_then255 ], [ %icmp264, %lor_rhs261 ]
  br i1 %lor265, label %tern_then266, label %tern_else267

tern_then266:                                     ; preds = %lor_merge262
  %off269 = load ptr, ptr %off, align 8
  %deref270 = load i64, ptr %off269, align 8
  br label %tern_merge268

tern_else267:                                     ; preds = %lor_merge262
  %off271 = load ptr, ptr %off, align 8
  %deref272 = load i32, ptr %off271, align 4
  %zext273 = zext i32 %deref272 to i64
  br label %tern_merge268

tern_merge268:                                    ; preds = %tern_else267, %tern_then266
  %tern274 = phi i64 [ %deref270, %tern_then266 ], [ %zext273, %tern_else267 ]
  store i64 %tern274, ptr %v258, align 8
  %buf275 = load ptr, ptr %buf, align 8
  %cap276 = load i64, ptr %cap, align 8
  %len277 = load i64, ptr %len, align 8
  %v278 = load i64, ptr %v258, align 8
  %conv279 = load i8, ptr %conv, align 1
  %icmp280 = icmp eq i8 %conv279, 88
  %zext281 = zext i1 %icmp280 to i8
  %13 = call i64 @afmt_impl__NS_put_uint(ptr %buf275, i64 %cap276, i64 %len277, i64 %v278, i64 16, i8 %zext281)
  store i64 %13, ptr %len, align 8
  br label %if_merge257

if_then284:                                       ; preds = %if_else256
  %buf287 = load ptr, ptr %buf, align 8
  %cap288 = load i64, ptr %cap, align 8
  %len289 = load i64, ptr %len, align 8
  %off290 = load ptr, ptr %off, align 8
  %deref291 = load i32, ptr %off290, align 4
  %trunc = trunc i32 %deref291 to i8
  %14 = call i64 @afmt_impl__NS_put(ptr %buf287, i64 %cap288, i64 %len289, i8 %trunc)
  store i64 %14, ptr %len, align 8
  br label %if_merge286

if_else285:                                       ; preds = %if_else256
  %conv292 = load i8, ptr %conv, align 1
  %icmp293 = icmp eq i8 %conv292, 102
  br i1 %icmp293, label %lor_merge295, label %lor_rhs294

if_merge286:                                      ; preds = %if_merge306, %if_then284
  br label %if_merge257

lor_rhs294:                                       ; preds = %if_else285
  %conv296 = load i8, ptr %conv, align 1
  %icmp297 = icmp eq i8 %conv296, 103
  br label %lor_merge295

lor_merge295:                                     ; preds = %lor_rhs294, %if_else285
  %lor298 = phi i1 [ true, %if_else285 ], [ %icmp297, %lor_rhs294 ]
  br i1 %lor298, label %lor_merge300, label %lor_rhs299

lor_rhs299:                                       ; preds = %lor_merge295
  %conv301 = load i8, ptr %conv, align 1
  %icmp302 = icmp eq i8 %conv301, 101
  br label %lor_merge300

lor_merge300:                                     ; preds = %lor_rhs299, %lor_merge295
  %lor303 = phi i1 [ true, %lor_merge295 ], [ %icmp302, %lor_rhs299 ]
  br i1 %lor303, label %if_then304, label %if_else305

if_then304:                                       ; preds = %lor_merge300
  %buf307 = load ptr, ptr %buf, align 8
  %cap308 = load i64, ptr %cap, align 8
  %len309 = load i64, ptr %len, align 8
  %off310 = load ptr, ptr %off, align 8
  %deref311 = load double, ptr %off310, align 8
  %15 = call i64 @afmt_impl__NS_put_f64(ptr %buf307, i64 %cap308, i64 %len309, double %deref311)
  store i64 %15, ptr %len, align 8
  br label %if_merge306

if_else305:                                       ; preds = %lor_merge300
  %conv312 = load i8, ptr %conv, align 1
  %icmp313 = icmp eq i8 %conv312, 112
  br i1 %icmp313, label %if_then314, label %if_else315

if_merge306:                                      ; preds = %if_merge316, %if_then304
  br label %if_merge286

if_then314:                                       ; preds = %if_else305
  %pv = alloca ptr, align 8
  %off317 = load ptr, ptr %off, align 8
  %deref318 = load ptr, ptr %off317, align 8
  store ptr %deref318, ptr %pv, align 8
  %buf319 = load ptr, ptr %buf, align 8
  %cap320 = load i64, ptr %cap, align 8
  %len321 = load i64, ptr %len, align 8
  %16 = call i64 @afmt_impl__NS_put(ptr %buf319, i64 %cap320, i64 %len321, i8 48)
  store i64 %16, ptr %len, align 8
  %buf322 = load ptr, ptr %buf, align 8
  %cap323 = load i64, ptr %cap, align 8
  %len324 = load i64, ptr %len, align 8
  %17 = call i64 @afmt_impl__NS_put(ptr %buf322, i64 %cap323, i64 %len324, i8 120)
  store i64 %17, ptr %len, align 8
  %buf325 = load ptr, ptr %buf, align 8
  %cap326 = load i64, ptr %cap, align 8
  %len327 = load i64, ptr %len, align 8
  %pv328 = load ptr, ptr %pv, align 8
  %p2i = ptrtoint ptr %pv328 to i64
  %18 = call i64 @afmt_impl__NS_put_uint(ptr %buf325, i64 %cap326, i64 %len327, i64 %p2i, i64 16, i8 0)
  store i64 %18, ptr %len, align 8
  br label %if_merge316

if_else315:                                       ; preds = %if_else305
  %buf329 = load ptr, ptr %buf, align 8
  %cap330 = load i64, ptr %cap, align 8
  %len331 = load i64, ptr %len, align 8
  %19 = call i64 @afmt_impl__NS_put(ptr %buf329, i64 %cap330, i64 %len331, i8 37)
  store i64 %19, ptr %len, align 8
  %buf332 = load ptr, ptr %buf, align 8
  %cap333 = load i64, ptr %cap, align 8
  %len334 = load i64, ptr %len, align 8
  %conv335 = load i8, ptr %conv, align 1
  %20 = call i64 @afmt_impl__NS_put(ptr %buf332, i64 %cap333, i64 %len334, i8 %conv335)
  store i64 %20, ptr %len, align 8
  br label %if_merge316

if_merge316:                                      ; preds = %if_else315, %if_then314
  br label %if_merge306

if_then338:                                       ; preds = %while_exit
  %term = alloca i64, align 8
  %len340 = load i64, ptr %len, align 8
  %cap341 = load i64, ptr %cap, align 8
  %icmp342 = icmp ult i64 %len340, %cap341
  br i1 %icmp342, label %tern_then343, label %tern_else344

if_merge339:                                      ; preds = %tern_merge345, %while_exit
  %len353 = load i64, ptr %len, align 8
  %trunc354 = trunc i64 %len353 to i32
  ret i32 %trunc354

tern_then343:                                     ; preds = %if_then338
  %len346 = load i64, ptr %len, align 8
  br label %tern_merge345

tern_else344:                                     ; preds = %if_then338
  %cap347 = load i64, ptr %cap, align 8
  %sub348 = sub i64 %cap347, 1
  br label %tern_merge345

tern_merge345:                                    ; preds = %tern_else344, %tern_then343
  %tern349 = phi i64 [ %len346, %tern_then343 ], [ %sub348, %tern_else344 ]
  store i64 %tern349, ptr %term, align 8
  %term350 = load i64, ptr %term, align 8
  %ptr_load351 = load ptr, ptr %buf, align 8
  %ptr_gep352 = getelementptr i8, ptr %ptr_load351, i64 %term350
  store i8 0, ptr %ptr_gep352, align 1
  br label %if_merge339
}

declare i32 @printf(ptr, ...)

define i32 @main() {
entry:
  %n = alloca i32, align 4
  store i32 7, ptr %n, align 4
  %n1 = load i32, ptr %n, align 4
  %anon_s = alloca %__anon1_i32, align 8
  %anon_f = getelementptr inbounds nuw %__anon1_i32, ptr %anon_s, i32 0, i32 0
  store i32 %n1, ptr %anon_f, align 4
  %anon_load = load %__anon1_i32, ptr %anon_s, align 4
  %0 = call i32 @fwd__at_args_S__anon1_i32(ptr @str.2, %__anon1_i32 %anon_load)
  ret i32 0
}

define internal i32 @fwd__at_args_S__anon1_i32(ptr %0, %__anon1_i32 %1) {
entry:
  %fmt = alloca ptr, align 8
  store ptr %0, ptr %fmt, align 8
  %args = alloca %__anon1_i32, align 8
  store %__anon1_i32 %1, ptr %args, align 4
  %b = alloca [64 x i8], align 1
  store [64 x i8] zeroinitializer, ptr %b, align 1
  %ti = alloca ptr, align 8
  store ptr @__typeinfo___anon1_i32, ptr %ti, align 8
  %self_ptr = load ptr, ptr %ti, align 8
  %ptr_deref = load ptr, ptr %ti, align 8
  %__tag = getelementptr inbounds nuw %type_info, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %ti, align 8
  %mem_load = load i32, ptr %__tag, align 4
  %fmt2 = load ptr, ptr %fmt, align 8
  %2 = call i32 (ptr, ...) @printf(ptr @str.3, i32 %mem_load, ptr %fmt2)
  %n = alloca i32, align 4
  store i32 0, ptr %n, align 4
  %n3 = load i32, ptr %n, align 4
  %arr_decay = getelementptr [64 x i8], ptr %b, i64 0, i64 0
  %3 = call i32 (ptr, ...) @printf(ptr @str.4, i32 %n3, ptr %arr_decay)
  %n4 = load i32, ptr %n, align 4
  ret i32 %n4
}

define void @__artemis_init_typeinfo() {
entry:
  store i32 12, ptr @__typeinfo___anon1_i32, align 4
  store ptr @__typeinfo_nm___anon1_i32, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon1_i32, i32 0, i32 1), align 8
  store i32 12, ptr @__typeinfo___anon1_i32, align 4
  store ptr @__typeinfo_flds___anon1_i32, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon1_i32, i32 0, i32 1), i64 8), align 8
  store i32 12, ptr @__typeinfo___anon1_i32, align 4
  store i64 1, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon1_i32, i32 0, i32 1), i64 16), align 8
  store i32 12, ptr @__typeinfo___anon1_i32, align 4
  store i64 4, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon1_i32, i32 0, i32 1), i64 24), align 8
  store i32 12, ptr @__typeinfo___anon1_i32, align 4
  store i64 4, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon1_i32, i32 0, i32 1), i64 32), align 8
  ret void
}
