; ModuleID = 'tcon/time/matmul.arc'
source_filename = "tcon/time/matmul.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%memstr = type { ptr, ptr }
%__vtable__ = type { ptr, ptr, ptr, ptr, ptr }

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
@str = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@str.1 = private unnamed_addr constant [5 x i8] c"%lld\00", align 1
@str.2 = private unnamed_addr constant [3 x i8] c"%u\00", align 1
@str.3 = private unnamed_addr constant [5 x i8] c"%llu\00", align 1
@str.4 = private unnamed_addr constant [3 x i8] c"%f\00", align 1
@str.5 = private unnamed_addr constant [3 x i8] c"%f\00", align 1
@str.6 = private unnamed_addr constant [5 x i8] c"true\00", align 1
@str.7 = private unnamed_addr constant [6 x i8] c"false\00", align 1
@str.8 = private unnamed_addr constant [7 x i8] c"0x%llx\00", align 1
@str.9 = private unnamed_addr constant [3 x i8] c"%p\00", align 1
@str.10 = private unnamed_addr constant [3 x i8] c"%s\00", align 1
@str.11 = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 1
@str.12 = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@str.13 = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@str.14 = private unnamed_addr constant [5 x i8] c"%lld\00", align 1
@str.15 = private unnamed_addr constant [3 x i8] c"%u\00", align 1
@str.16 = private unnamed_addr constant [5 x i8] c"%llu\00", align 1
@str.17 = private unnamed_addr constant [3 x i8] c"%f\00", align 1
@str.18 = private unnamed_addr constant [7 x i8] c"0x%llx\00", align 1
@str.19 = private unnamed_addr constant [3 x i8] c"%p\00", align 1
@str.20 = private unnamed_addr constant [3 x i8] c"rb\00", align 1
@SZ = internal global i32 320
@a = internal global [102400 x double] zeroinitializer
@b = internal global [102400 x double] zeroinitializer
@c = internal global [102400 x double] zeroinitializer
@str.21 = private unnamed_addr constant [1 x i8] zeroinitializer, align 1

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

declare i32 @printf(ptr, ...)

declare i32 @fprintf(ptr, ptr, ...)

declare i32 @sprintf(ptr, ptr, ...)

declare i32 @snprintf(ptr, i64, ptr, ...)

declare i32 @scanf(ptr, ...)

declare i32 @sscanf(ptr, ptr, ...)

declare i32 @fscanf(ptr, ptr, ...)

declare i32 @puts(ptr)

declare i32 @putchar(i32)

declare i32 @getchar()

declare i32 @fflush(ptr)

declare ptr @fopen(ptr, ptr)

declare i32 @fclose(ptr)

declare i64 @fread(ptr, i64, i64, ptr)

declare i64 @fwrite(ptr, i64, i64, ptr)

declare i32 @fseek(ptr, i64, i32)

declare i64 @ftell(ptr)

declare i32 @feof(ptr)

declare i32 @ferror(ptr)

declare ptr @__acrt_iob_func(i32)

define internal ptr @fmt__NS_stream_out() {
entry:
  %0 = call ptr @__acrt_iob_func(i32 1)
  ret ptr %0
}

define internal ptr @fmt__NS_stream_err() {
entry:
  %0 = call ptr @__acrt_iob_func(i32 2)
  ret ptr %0
}

define internal void @fmt__NS_out_print(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %s, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i1
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp ne i8 %idx_load, 0
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i2 = load i32, ptr %i, align 4
  %ptr_load3 = load ptr, ptr %s, align 8
  %ptr_gep4 = getelementptr i8, ptr %ptr_load3, i32 %i2
  %idx_load5 = load i8, ptr %ptr_gep4, align 1
  %sext = sext i8 %idx_load5 to i32
  %1 = call i32 @putchar(i32 %sext)
  %i6 = load i32, ptr %i, align 4
  %add = add i32 %i6, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  ret void
}

define internal void @fmt__NS_out_println(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %s, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i1
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp ne i8 %idx_load, 0
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i2 = load i32, ptr %i, align 4
  %ptr_load3 = load ptr, ptr %s, align 8
  %ptr_gep4 = getelementptr i8, ptr %ptr_load3, i32 %i2
  %idx_load5 = load i8, ptr %ptr_gep4, align 1
  %sext = sext i8 %idx_load5 to i32
  %1 = call i32 @putchar(i32 %sext)
  %i6 = load i32, ptr %i, align 4
  %add = add i32 %i6, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %2 = call i32 @putchar(i32 10)
  ret void
}

define internal void @fmt__NS_out_print_i32(i32 %0) {
entry:
  %v = alloca i32, align 4
  store i32 %0, ptr %v, align 4
  %v1 = load i32, ptr %v, align 4
  %1 = call i32 (ptr, ...) @printf(ptr @str, i32 %v1)
  ret void
}

define internal void @fmt__NS_out_print_i64(i64 %0) {
entry:
  %v = alloca i64, align 8
  store i64 %0, ptr %v, align 8
  %v1 = load i64, ptr %v, align 8
  %1 = call i32 (ptr, ...) @printf(ptr @str.1, i64 %v1)
  ret void
}

define internal void @fmt__NS_out_print_u32(i32 %0) {
entry:
  %v = alloca i32, align 4
  store i32 %0, ptr %v, align 4
  %v1 = load i32, ptr %v, align 4
  %1 = call i32 (ptr, ...) @printf(ptr @str.2, i32 %v1)
  ret void
}

define internal void @fmt__NS_out_print_u64(i64 %0) {
entry:
  %v = alloca i64, align 8
  store i64 %0, ptr %v, align 8
  %v1 = load i64, ptr %v, align 8
  %1 = call i32 (ptr, ...) @printf(ptr @str.3, i64 %v1)
  ret void
}

define internal void @fmt__NS_out_print_f32(float %0) {
entry:
  %v = alloca float, align 4
  store float %0, ptr %v, align 4
  %v1 = load float, ptr %v, align 4
  %fpcast = fpext float %v1 to double
  %1 = call i32 (ptr, ...) @printf(ptr @str.4, double %fpcast)
  ret void
}

define internal void @fmt__NS_out_print_f64(double %0) {
entry:
  %v = alloca double, align 8
  store double %0, ptr %v, align 8
  %v1 = load double, ptr %v, align 8
  %1 = call i32 (ptr, ...) @printf(ptr @str.5, double %v1)
  ret void
}

define internal void @fmt__NS_out_print_bool(i8 %0) {
entry:
  %b = alloca i8, align 1
  store i8 %0, ptr %b, align 1
  %b1 = load i8, ptr %b, align 1
  %tobool = icmp ne i8 %b1, 0
  br i1 %tobool, label %tern_then, label %tern_else

tern_then:                                        ; preds = %entry
  br label %tern_merge

tern_else:                                        ; preds = %entry
  br label %tern_merge

tern_merge:                                       ; preds = %tern_else, %tern_then
  %tern = phi ptr [ @str.6, %tern_then ], [ @str.7, %tern_else ]
  %1 = call i32 @puts(ptr %tern)
  ret void
}

define internal void @fmt__NS_out_print_char(i8 %0) {
entry:
  %c = alloca i8, align 1
  store i8 %0, ptr %c, align 1
  %c1 = load i8, ptr %c, align 1
  %sext = sext i8 %c1 to i32
  %1 = call i32 @putchar(i32 %sext)
  ret void
}

define internal void @fmt__NS_out_print_hex(i64 %0) {
entry:
  %v = alloca i64, align 8
  store i64 %0, ptr %v, align 8
  %v1 = load i64, ptr %v, align 8
  %1 = call i32 (ptr, ...) @printf(ptr @str.8, i64 %v1)
  ret void
}

define internal void @fmt__NS_out_print_ptr(ptr %0) {
entry:
  %p = alloca ptr, align 8
  store ptr %0, ptr %p, align 8
  %p1 = load ptr, ptr %p, align 8
  %1 = call i32 (ptr, ...) @printf(ptr @str.9, ptr %p1)
  ret void
}

define internal void @fmt__NS_out_flush() {
entry:
  %0 = call ptr @fmt__NS_stream_out()
  %1 = call i32 @fflush(ptr %0)
  ret void
}

define internal void @fmt__NS_err_print(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %1 = call ptr @fmt__NS_stream_err()
  %s1 = load ptr, ptr %s, align 8
  %2 = call i32 (ptr, ptr, ...) @fprintf(ptr %1, ptr @str.10, ptr %s1)
  ret void
}

define internal void @fmt__NS_err_println(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %1 = call ptr @fmt__NS_stream_err()
  %s1 = load ptr, ptr %s, align 8
  %2 = call i32 (ptr, ptr, ...) @fprintf(ptr %1, ptr @str.11, ptr %s1)
  ret void
}

define internal void @fmt__NS_err_print_i32(i32 %0) {
entry:
  %v = alloca i32, align 4
  store i32 %0, ptr %v, align 4
  %1 = call ptr @fmt__NS_stream_err()
  %v1 = load i32, ptr %v, align 4
  %2 = call i32 (ptr, ptr, ...) @fprintf(ptr %1, ptr @str.12, i32 %v1)
  ret void
}

define internal void @fmt__NS_err_flush() {
entry:
  %0 = call ptr @fmt__NS_stream_err()
  %1 = call i32 @fflush(ptr %0)
  ret void
}

define internal i32 @fmt__NS_fmt_i32(ptr %0, i64 %1, i32 %2) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %v = alloca i32, align 4
  store i32 %2, ptr %v, align 4
  %buf1 = load ptr, ptr %buf, align 8
  %cap2 = load i64, ptr %cap, align 8
  %v3 = load i32, ptr %v, align 4
  %3 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr %buf1, i64 %cap2, ptr @str.13, i32 %v3)
  ret i32 %3
}

define internal i32 @fmt__NS_fmt_i64(ptr %0, i64 %1, i64 %2) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %v = alloca i64, align 8
  store i64 %2, ptr %v, align 8
  %buf1 = load ptr, ptr %buf, align 8
  %cap2 = load i64, ptr %cap, align 8
  %v3 = load i64, ptr %v, align 8
  %3 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr %buf1, i64 %cap2, ptr @str.14, i64 %v3)
  ret i32 %3
}

define internal i32 @fmt__NS_fmt_u32(ptr %0, i64 %1, i32 %2) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %v = alloca i32, align 4
  store i32 %2, ptr %v, align 4
  %buf1 = load ptr, ptr %buf, align 8
  %cap2 = load i64, ptr %cap, align 8
  %v3 = load i32, ptr %v, align 4
  %3 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr %buf1, i64 %cap2, ptr @str.15, i32 %v3)
  ret i32 %3
}

define internal i32 @fmt__NS_fmt_u64(ptr %0, i64 %1, i64 %2) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %v = alloca i64, align 8
  store i64 %2, ptr %v, align 8
  %buf1 = load ptr, ptr %buf, align 8
  %cap2 = load i64, ptr %cap, align 8
  %v3 = load i64, ptr %v, align 8
  %3 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr %buf1, i64 %cap2, ptr @str.16, i64 %v3)
  ret i32 %3
}

define internal i32 @fmt__NS_fmt_f64(ptr %0, i64 %1, double %2) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %v = alloca double, align 8
  store double %2, ptr %v, align 8
  %buf1 = load ptr, ptr %buf, align 8
  %cap2 = load i64, ptr %cap, align 8
  %v3 = load double, ptr %v, align 8
  %3 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr %buf1, i64 %cap2, ptr @str.17, double %v3)
  ret i32 %3
}

define internal i32 @fmt__NS_fmt_hex(ptr %0, i64 %1, i64 %2) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %v = alloca i64, align 8
  store i64 %2, ptr %v, align 8
  %buf1 = load ptr, ptr %buf, align 8
  %cap2 = load i64, ptr %cap, align 8
  %v3 = load i64, ptr %v, align 8
  %3 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr %buf1, i64 %cap2, ptr @str.18, i64 %v3)
  ret i32 %3
}

define internal i32 @fmt__NS_fmt_ptr(ptr %0, i64 %1, ptr %2) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %p = alloca ptr, align 8
  store ptr %2, ptr %p, align 8
  %buf1 = load ptr, ptr %buf, align 8
  %cap2 = load i64, ptr %cap, align 8
  %p3 = load ptr, ptr %p, align 8
  %3 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr %buf1, i64 %cap2, ptr @str.19, ptr %p3)
  ret i32 %3
}

define internal ptr @fmt__NS_file_open(ptr %0, ptr %1) {
entry:
  %path = alloca ptr, align 8
  store ptr %0, ptr %path, align 8
  %mode = alloca ptr, align 8
  store ptr %1, ptr %mode, align 8
  %path1 = load ptr, ptr %path, align 8
  %mode2 = load ptr, ptr %mode, align 8
  %2 = call ptr @fopen(ptr %path1, ptr %mode2)
  ret ptr %2
}

define internal i32 @fmt__NS_file_close(ptr %0) {
entry:
  %fp = alloca ptr, align 8
  store ptr %0, ptr %fp, align 8
  %fp1 = load ptr, ptr %fp, align 8
  %1 = call i32 @fclose(ptr %fp1)
  ret i32 %1
}

define internal i64 @fmt__NS_file_read_bytes(ptr %0, ptr %1, i64 %2) {
entry:
  %fp = alloca ptr, align 8
  store ptr %0, ptr %fp, align 8
  %buf = alloca ptr, align 8
  store ptr %1, ptr %buf, align 8
  %n = alloca i64, align 8
  store i64 %2, ptr %n, align 8
  %buf1 = load ptr, ptr %buf, align 8
  %n2 = load i64, ptr %n, align 8
  %fp3 = load ptr, ptr %fp, align 8
  %3 = call i64 @fread(ptr %buf1, i64 1, i64 %n2, ptr %fp3)
  ret i64 %3
}

define internal i64 @fmt__NS_file_write_bytes(ptr %0, ptr %1, i64 %2) {
entry:
  %fp = alloca ptr, align 8
  store ptr %0, ptr %fp, align 8
  %buf = alloca ptr, align 8
  store ptr %1, ptr %buf, align 8
  %n = alloca i64, align 8
  store i64 %2, ptr %n, align 8
  %buf1 = load ptr, ptr %buf, align 8
  %n2 = load i64, ptr %n, align 8
  %fp3 = load ptr, ptr %fp, align 8
  %3 = call i64 @fwrite(ptr %buf1, i64 1, i64 %n2, ptr %fp3)
  ret i64 %3
}

define internal i8 @fmt__NS_file_at_eof(ptr %0) {
entry:
  %fp = alloca ptr, align 8
  store ptr %0, ptr %fp, align 8
  %fp1 = load ptr, ptr %fp, align 8
  %1 = call i32 @feof(ptr %fp1)
  %icmp = icmp ne i32 %1, 0
  %zext = zext i1 %icmp to i8
  ret i8 %zext
}

define internal i8 @fmt__NS_file_has_error(ptr %0) {
entry:
  %fp = alloca ptr, align 8
  store ptr %0, ptr %fp, align 8
  %fp1 = load ptr, ptr %fp, align 8
  %1 = call i32 @ferror(ptr %fp1)
  %icmp = icmp ne i32 %1, 0
  %zext = zext i1 %icmp to i8
  ret i8 %zext
}

define internal void @fmt__NS_file_seek_start(ptr %0, i64 %1) {
entry:
  %fp = alloca ptr, align 8
  store ptr %0, ptr %fp, align 8
  %off = alloca i64, align 8
  store i64 %1, ptr %off, align 8
  %fp1 = load ptr, ptr %fp, align 8
  %off2 = load i64, ptr %off, align 8
  %2 = call i32 @fseek(ptr %fp1, i64 %off2, i32 0)
  ret void
}

define internal void @fmt__NS_file_seek_cur(ptr %0, i64 %1) {
entry:
  %fp = alloca ptr, align 8
  store ptr %0, ptr %fp, align 8
  %off = alloca i64, align 8
  store i64 %1, ptr %off, align 8
  %fp1 = load ptr, ptr %fp, align 8
  %off2 = load i64, ptr %off, align 8
  %2 = call i32 @fseek(ptr %fp1, i64 %off2, i32 1)
  ret void
}

define internal void @fmt__NS_file_seek_end(ptr %0, i64 %1) {
entry:
  %fp = alloca ptr, align 8
  store ptr %0, ptr %fp, align 8
  %off = alloca i64, align 8
  store i64 %1, ptr %off, align 8
  %fp1 = load ptr, ptr %fp, align 8
  %off2 = load i64, ptr %off, align 8
  %2 = call i32 @fseek(ptr %fp1, i64 %off2, i32 2)
  ret void
}

define internal i64 @fmt__NS_file_tell(ptr %0) {
entry:
  %fp = alloca ptr, align 8
  store ptr %0, ptr %fp, align 8
  %fp1 = load ptr, ptr %fp, align 8
  %1 = call i64 @ftell(ptr %fp1)
  ret i64 %1
}

define internal void @fmt__NS_file_flush(ptr %0) {
entry:
  %fp = alloca ptr, align 8
  store ptr %0, ptr %fp, align 8
  %fp1 = load ptr, ptr %fp, align 8
  %1 = call i32 @fflush(ptr %fp1)
  ret void
}

define internal i64 @fmt__NS_file_read_all(ptr %0, ptr %1, i64 %2) {
entry:
  %path = alloca ptr, align 8
  store ptr %0, ptr %path, align 8
  %buf = alloca ptr, align 8
  store ptr %1, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %2, ptr %cap, align 8
  %fp = alloca ptr, align 8
  %path1 = load ptr, ptr %path, align 8
  %3 = call ptr @fopen(ptr %path1, ptr @str.20)
  store ptr %3, ptr %fp, align 8
  %fp2 = load ptr, ptr %fp, align 8
  %icmp = icmp eq ptr %fp2, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i64 -1

if_merge:                                         ; preds = %entry
  %fp3 = load ptr, ptr %fp, align 8
  %4 = call i32 @fseek(ptr %fp3, i64 0, i32 2)
  %sz = alloca i64, align 8
  %fp4 = load ptr, ptr %fp, align 8
  %5 = call i64 @ftell(ptr %fp4)
  store i64 %5, ptr %sz, align 8
  %fp5 = load ptr, ptr %fp, align 8
  %6 = call i32 @fseek(ptr %fp5, i64 0, i32 0)
  %sz6 = load i64, ptr %sz, align 8
  %icmp7 = icmp slt i64 %sz6, 0
  br i1 %icmp7, label %lor_merge, label %lor_rhs

lor_rhs:                                          ; preds = %if_merge
  %sz8 = load i64, ptr %sz, align 8
  %cap9 = load i64, ptr %cap, align 8
  %icmp10 = icmp uge i64 %sz8, %cap9
  br label %lor_merge

lor_merge:                                        ; preds = %lor_rhs, %if_merge
  %lor = phi i1 [ true, %if_merge ], [ %icmp10, %lor_rhs ]
  br i1 %lor, label %if_then11, label %if_merge12

if_then11:                                        ; preds = %lor_merge
  %fp13 = load ptr, ptr %fp, align 8
  %7 = call i32 @fclose(ptr %fp13)
  ret i64 -1

if_merge12:                                       ; preds = %lor_merge
  %n = alloca i64, align 8
  %buf14 = load ptr, ptr %buf, align 8
  %sz15 = load i64, ptr %sz, align 8
  %fp16 = load ptr, ptr %fp, align 8
  %8 = call i64 @fread(ptr %buf14, i64 1, i64 %sz15, ptr %fp16)
  store i64 %8, ptr %n, align 8
  %n17 = load i64, ptr %n, align 8
  %ptr_load = load ptr, ptr %buf, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %n17
  store i8 0, ptr %ptr_gep, align 1
  %fp18 = load ptr, ptr %fp, align 8
  %9 = call i32 @fclose(ptr %fp18)
  %n19 = load i64, ptr %n, align 8
  ret i64 %n19
}

define internal i32 @fmt__NS_str_len(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %n = alloca i32, align 4
  store i32 0, ptr %n, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %n1 = load i32, ptr %n, align 4
  %ptr_load = load ptr, ptr %s, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %n1
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp ne i8 %idx_load, 0
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %n2 = load i32, ptr %n, align 4
  %add = add i32 %n2, 1
  store i32 %add, ptr %n, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %n3 = load i32, ptr %n, align 4
  ret i32 %n3
}

define internal i8 @fmt__NS_str_eq(ptr %0, ptr %1) {
entry:
  %a = alloca ptr, align 8
  store ptr %0, ptr %a, align 8
  %b = alloca ptr, align 8
  store ptr %1, ptr %b, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %a, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i1
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp ne i8 %idx_load, 0
  br i1 %icmp, label %land_rhs, label %land_merge

while_body:                                       ; preds = %land_merge
  %i7 = load i32, ptr %i, align 4
  %ptr_load8 = load ptr, ptr %a, align 8
  %ptr_gep9 = getelementptr i8, ptr %ptr_load8, i32 %i7
  %idx_load10 = load i8, ptr %ptr_gep9, align 1
  %i11 = load i32, ptr %i, align 4
  %ptr_load12 = load ptr, ptr %b, align 8
  %ptr_gep13 = getelementptr i8, ptr %ptr_load12, i32 %i11
  %idx_load14 = load i8, ptr %ptr_gep13, align 1
  %icmp15 = icmp ne i8 %idx_load10, %idx_load14
  br i1 %icmp15, label %if_then, label %if_merge

while_exit:                                       ; preds = %land_merge
  %i17 = load i32, ptr %i, align 4
  %ptr_load18 = load ptr, ptr %a, align 8
  %ptr_gep19 = getelementptr i8, ptr %ptr_load18, i32 %i17
  %idx_load20 = load i8, ptr %ptr_gep19, align 1
  %i21 = load i32, ptr %i, align 4
  %ptr_load22 = load ptr, ptr %b, align 8
  %ptr_gep23 = getelementptr i8, ptr %ptr_load22, i32 %i21
  %idx_load24 = load i8, ptr %ptr_gep23, align 1
  %icmp25 = icmp eq i8 %idx_load20, %idx_load24
  %zext = zext i1 %icmp25 to i8
  ret i8 %zext

land_rhs:                                         ; preds = %while_cond
  %i2 = load i32, ptr %i, align 4
  %ptr_load3 = load ptr, ptr %b, align 8
  %ptr_gep4 = getelementptr i8, ptr %ptr_load3, i32 %i2
  %idx_load5 = load i8, ptr %ptr_gep4, align 1
  %icmp6 = icmp ne i8 %idx_load5, 0
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond
  %land = phi i1 [ false, %while_cond ], [ %icmp6, %land_rhs ]
  br i1 %land, label %while_body, label %while_exit

if_then:                                          ; preds = %while_body
  ret i8 0

if_merge:                                         ; preds = %while_body
  %i16 = load i32, ptr %i, align 4
  %add = add i32 %i16, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond
}

define internal void @fmt__NS_str_copy(ptr %0, ptr %1, i64 %2) {
entry:
  %dst = alloca ptr, align 8
  store ptr %0, ptr %dst, align 8
  %src = alloca ptr, align 8
  store ptr %1, ptr %src, align 8
  %cap = alloca i64, align 8
  store i64 %2, ptr %cap, align 8
  %i = alloca i64, align 8
  store i64 0, ptr %i, align 8
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %i1 = load i64, ptr %i, align 8
  %ptr_load = load ptr, ptr %src, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %i1
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp ne i8 %idx_load, 0
  br i1 %icmp, label %land_rhs, label %land_merge

while_body:                                       ; preds = %land_merge
  %i5 = load i64, ptr %i, align 8
  %ptr_load6 = load ptr, ptr %dst, align 8
  %ptr_gep7 = getelementptr i8, ptr %ptr_load6, i64 %i5
  %i8 = load i64, ptr %i, align 8
  %ptr_load9 = load ptr, ptr %src, align 8
  %ptr_gep10 = getelementptr i8, ptr %ptr_load9, i64 %i8
  %idx_load11 = load i8, ptr %ptr_gep10, align 1
  store i8 %idx_load11, ptr %ptr_gep7, align 1
  %i12 = load i64, ptr %i, align 8
  %add13 = add i64 %i12, 1
  store i64 %add13, ptr %i, align 8
  br label %while_cond

while_exit:                                       ; preds = %land_merge
  %i14 = load i64, ptr %i, align 8
  %ptr_load15 = load ptr, ptr %dst, align 8
  %ptr_gep16 = getelementptr i8, ptr %ptr_load15, i64 %i14
  store i8 0, ptr %ptr_gep16, align 1
  ret void

land_rhs:                                         ; preds = %while_cond
  %i2 = load i64, ptr %i, align 8
  %add = add i64 %i2, 1
  %cap3 = load i64, ptr %cap, align 8
  %icmp4 = icmp slt i64 %add, %cap3
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond
  %land = phi i1 [ false, %while_cond ], [ %icmp4, %land_rhs ]
  br i1 %land, label %while_body, label %while_exit
}

define internal void @fmt__NS_str_append(ptr %0, ptr %1, i64 %2) {
entry:
  %dst = alloca ptr, align 8
  store ptr %0, ptr %dst, align 8
  %src = alloca ptr, align 8
  store ptr %1, ptr %src, align 8
  %cap = alloca i64, align 8
  store i64 %2, ptr %cap, align 8
  %dl = alloca i32, align 4
  store i32 0, ptr %dl, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %dl1 = load i32, ptr %dl, align 4
  %ptr_load = load ptr, ptr %dst, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %dl1
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp ne i8 %idx_load, 0
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %dl2 = load i32, ptr %dl, align 4
  %add = add i32 %dl2, 1
  store i32 %add, ptr %dl, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond3

while_cond3:                                      ; preds = %while_body4, %while_exit
  %i6 = load i32, ptr %i, align 4
  %ptr_load7 = load ptr, ptr %src, align 8
  %ptr_gep8 = getelementptr i8, ptr %ptr_load7, i32 %i6
  %idx_load9 = load i8, ptr %ptr_gep8, align 1
  %icmp10 = icmp ne i8 %idx_load9, 0
  br i1 %icmp10, label %land_rhs, label %land_merge

while_body4:                                      ; preds = %land_merge
  %dl17 = load i32, ptr %dl, align 4
  %i18 = load i32, ptr %i, align 4
  %add19 = add i32 %dl17, %i18
  %ptr_load20 = load ptr, ptr %dst, align 8
  %ptr_gep21 = getelementptr i8, ptr %ptr_load20, i32 %add19
  %i22 = load i32, ptr %i, align 4
  %ptr_load23 = load ptr, ptr %src, align 8
  %ptr_gep24 = getelementptr i8, ptr %ptr_load23, i32 %i22
  %idx_load25 = load i8, ptr %ptr_gep24, align 1
  store i8 %idx_load25, ptr %ptr_gep21, align 1
  %i26 = load i32, ptr %i, align 4
  %add27 = add i32 %i26, 1
  store i32 %add27, ptr %i, align 4
  br label %while_cond3

while_exit5:                                      ; preds = %land_merge
  %dl28 = load i32, ptr %dl, align 4
  %i29 = load i32, ptr %i, align 4
  %add30 = add i32 %dl28, %i29
  %ptr_load31 = load ptr, ptr %dst, align 8
  %ptr_gep32 = getelementptr i8, ptr %ptr_load31, i32 %add30
  store i8 0, ptr %ptr_gep32, align 1
  ret void

land_rhs:                                         ; preds = %while_cond3
  %dl11 = load i32, ptr %dl, align 4
  %i12 = load i32, ptr %i, align 4
  %add13 = add i32 %dl11, %i12
  %add14 = add i32 %add13, 1
  %zext = zext i32 %add14 to i64
  %cap15 = load i64, ptr %cap, align 8
  %icmp16 = icmp ult i64 %zext, %cap15
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond3
  %land = phi i1 [ false, %while_cond3 ], [ %icmp16, %land_rhs ]
  br i1 %land, label %while_body4, label %while_exit5
}

define internal i8 @fmt__NS_str_starts_with(ptr %0, ptr %1) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %prefix = alloca ptr, align 8
  store ptr %1, ptr %prefix, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %prefix, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i1
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp ne i8 %idx_load, 0
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i2 = load i32, ptr %i, align 4
  %ptr_load3 = load ptr, ptr %s, align 8
  %ptr_gep4 = getelementptr i8, ptr %ptr_load3, i32 %i2
  %idx_load5 = load i8, ptr %ptr_gep4, align 1
  %i6 = load i32, ptr %i, align 4
  %ptr_load7 = load ptr, ptr %prefix, align 8
  %ptr_gep8 = getelementptr i8, ptr %ptr_load7, i32 %i6
  %idx_load9 = load i8, ptr %ptr_gep8, align 1
  %icmp10 = icmp ne i8 %idx_load5, %idx_load9
  br i1 %icmp10, label %if_then, label %if_merge

while_exit:                                       ; preds = %while_cond
  ret i8 1

if_then:                                          ; preds = %while_body
  ret i8 0

if_merge:                                         ; preds = %while_body
  %i11 = load i32, ptr %i, align 4
  %add = add i32 %i11, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond
}

define internal i8 @fmt__NS_str_ends_with(ptr %0, ptr %1) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %suffix = alloca ptr, align 8
  store ptr %1, ptr %suffix, align 8
  %sl = alloca i32, align 4
  store i32 0, ptr %sl, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %sl1 = load i32, ptr %sl, align 4
  %ptr_load = load ptr, ptr %s, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %sl1
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp ne i8 %idx_load, 0
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %sl2 = load i32, ptr %sl, align 4
  %add = add i32 %sl2, 1
  store i32 %add, ptr %sl, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %xl = alloca i32, align 4
  store i32 0, ptr %xl, align 4
  br label %while_cond3

while_cond3:                                      ; preds = %while_body4, %while_exit
  %xl6 = load i32, ptr %xl, align 4
  %ptr_load7 = load ptr, ptr %suffix, align 8
  %ptr_gep8 = getelementptr i8, ptr %ptr_load7, i32 %xl6
  %idx_load9 = load i8, ptr %ptr_gep8, align 1
  %icmp10 = icmp ne i8 %idx_load9, 0
  br i1 %icmp10, label %while_body4, label %while_exit5

while_body4:                                      ; preds = %while_cond3
  %xl11 = load i32, ptr %xl, align 4
  %add12 = add i32 %xl11, 1
  store i32 %add12, ptr %xl, align 4
  br label %while_cond3

while_exit5:                                      ; preds = %while_cond3
  %xl13 = load i32, ptr %xl, align 4
  %sl14 = load i32, ptr %sl, align 4
  %icmp15 = icmp sgt i32 %xl13, %sl14
  br i1 %icmp15, label %if_then, label %if_merge

if_then:                                          ; preds = %while_exit5
  ret i8 0

if_merge:                                         ; preds = %while_exit5
  %off = alloca i32, align 4
  %sl16 = load i32, ptr %sl, align 4
  %xl17 = load i32, ptr %xl, align 4
  %sub = sub i32 %sl16, %xl17
  store i32 %sub, ptr %off, align 4
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %for_cond

for_cond:                                         ; preds = %for_step, %if_merge
  %i18 = load i32, ptr %i, align 4
  %xl19 = load i32, ptr %xl, align 4
  %icmp20 = icmp slt i32 %i18, %xl19
  br i1 %icmp20, label %for_body, label %for_exit

for_body:                                         ; preds = %for_cond
  %off21 = load i32, ptr %off, align 4
  %i22 = load i32, ptr %i, align 4
  %add23 = add i32 %off21, %i22
  %ptr_load24 = load ptr, ptr %s, align 8
  %ptr_gep25 = getelementptr i8, ptr %ptr_load24, i32 %add23
  %idx_load26 = load i8, ptr %ptr_gep25, align 1
  %i27 = load i32, ptr %i, align 4
  %ptr_load28 = load ptr, ptr %suffix, align 8
  %ptr_gep29 = getelementptr i8, ptr %ptr_load28, i32 %i27
  %idx_load30 = load i8, ptr %ptr_gep29, align 1
  %icmp31 = icmp ne i8 %idx_load26, %idx_load30
  br i1 %icmp31, label %if_then32, label %if_merge33

for_step:                                         ; preds = %if_merge33
  %i34 = load i32, ptr %i, align 4
  %add35 = add i32 %i34, 1
  store i32 %add35, ptr %i, align 4
  br label %for_cond

for_exit:                                         ; preds = %for_cond
  ret i8 1

if_then32:                                        ; preds = %for_body
  ret i8 0

if_merge33:                                       ; preds = %for_body
  br label %for_step
}

define internal i32 @fmt__NS_str_find(ptr %0, ptr %1) {
entry:
  %haystack = alloca ptr, align 8
  store ptr %0, ptr %haystack, align 8
  %needle = alloca ptr, align 8
  store ptr %1, ptr %needle, align 8
  %hl = alloca i32, align 4
  store i32 0, ptr %hl, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %hl1 = load i32, ptr %hl, align 4
  %ptr_load = load ptr, ptr %haystack, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %hl1
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp ne i8 %idx_load, 0
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %hl2 = load i32, ptr %hl, align 4
  %add = add i32 %hl2, 1
  store i32 %add, ptr %hl, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %nl = alloca i32, align 4
  store i32 0, ptr %nl, align 4
  br label %while_cond3

while_cond3:                                      ; preds = %while_body4, %while_exit
  %nl6 = load i32, ptr %nl, align 4
  %ptr_load7 = load ptr, ptr %needle, align 8
  %ptr_gep8 = getelementptr i8, ptr %ptr_load7, i32 %nl6
  %idx_load9 = load i8, ptr %ptr_gep8, align 1
  %icmp10 = icmp ne i8 %idx_load9, 0
  br i1 %icmp10, label %while_body4, label %while_exit5

while_body4:                                      ; preds = %while_cond3
  %nl11 = load i32, ptr %nl, align 4
  %add12 = add i32 %nl11, 1
  store i32 %add12, ptr %nl, align 4
  br label %while_cond3

while_exit5:                                      ; preds = %while_cond3
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %for_cond

for_cond:                                         ; preds = %for_step, %while_exit5
  %i13 = load i32, ptr %i, align 4
  %hl14 = load i32, ptr %hl, align 4
  %nl15 = load i32, ptr %nl, align 4
  %sub = sub i32 %hl14, %nl15
  %icmp16 = icmp sle i32 %i13, %sub
  br i1 %icmp16, label %for_body, label %for_exit

for_body:                                         ; preds = %for_cond
  %found = alloca i8, align 1
  store i8 1, ptr %found, align 1
  %j = alloca i32, align 4
  store i32 0, ptr %j, align 4
  br label %for_cond17

for_step:                                         ; preds = %if_merge39
  %i41 = load i32, ptr %i, align 4
  %add42 = add i32 %i41, 1
  store i32 %add42, ptr %i, align 4
  br label %for_cond

for_exit:                                         ; preds = %for_cond
  ret i32 -1

for_cond17:                                       ; preds = %for_step19, %for_body
  %j21 = load i32, ptr %j, align 4
  %nl22 = load i32, ptr %nl, align 4
  %icmp23 = icmp slt i32 %j21, %nl22
  br i1 %icmp23, label %for_body18, label %for_exit20

for_body18:                                       ; preds = %for_cond17
  %i24 = load i32, ptr %i, align 4
  %j25 = load i32, ptr %j, align 4
  %add26 = add i32 %i24, %j25
  %ptr_load27 = load ptr, ptr %haystack, align 8
  %ptr_gep28 = getelementptr i8, ptr %ptr_load27, i32 %add26
  %idx_load29 = load i8, ptr %ptr_gep28, align 1
  %j30 = load i32, ptr %j, align 4
  %ptr_load31 = load ptr, ptr %needle, align 8
  %ptr_gep32 = getelementptr i8, ptr %ptr_load31, i32 %j30
  %idx_load33 = load i8, ptr %ptr_gep32, align 1
  %icmp34 = icmp ne i8 %idx_load29, %idx_load33
  br i1 %icmp34, label %if_then, label %if_merge

for_step19:                                       ; preds = %if_merge
  %j35 = load i32, ptr %j, align 4
  %add36 = add i32 %j35, 1
  store i32 %add36, ptr %j, align 4
  br label %for_cond17

for_exit20:                                       ; preds = %if_then, %for_cond17
  %found37 = load i8, ptr %found, align 1
  %if_cond = icmp ne i8 %found37, 0
  br i1 %if_cond, label %if_then38, label %if_merge39

if_then:                                          ; preds = %for_body18
  store i8 0, ptr %found, align 1
  br label %for_exit20

if_merge:                                         ; preds = %for_body18
  br label %for_step19

if_then38:                                        ; preds = %for_exit20
  %i40 = load i32, ptr %i, align 4
  ret i32 %i40

if_merge39:                                       ; preds = %for_exit20
  br label %for_step
}

define internal i32 @fmt__NS_str_to_i32(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %val = alloca i32, align 4
  store i32 0, ptr %val, align 4
  %sign = alloca i32, align 4
  store i32 1, ptr %sign, align 4
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  %ptr_load = load ptr, ptr %s, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 0
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp eq i8 %idx_load, 45
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  store i32 -1, ptr %sign, align 4
  store i32 1, ptr %i, align 4
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  br label %while_cond

while_cond:                                       ; preds = %while_body, %if_merge
  %i1 = load i32, ptr %i, align 4
  %ptr_load2 = load ptr, ptr %s, align 8
  %ptr_gep3 = getelementptr i8, ptr %ptr_load2, i32 %i1
  %idx_load4 = load i8, ptr %ptr_gep3, align 1
  %icmp5 = icmp sge i8 %idx_load4, 48
  br i1 %icmp5, label %land_rhs, label %land_merge

while_body:                                       ; preds = %land_merge
  %val11 = load i32, ptr %val, align 4
  %mul = mul i32 %val11, 10
  %i12 = load i32, ptr %i, align 4
  %ptr_load13 = load ptr, ptr %s, align 8
  %ptr_gep14 = getelementptr i8, ptr %ptr_load13, i32 %i12
  %idx_load15 = load i8, ptr %ptr_gep14, align 1
  %sub = sub i8 %idx_load15, 48
  %sext = sext i8 %sub to i32
  %add = add i32 %mul, %sext
  store i32 %add, ptr %val, align 4
  %i16 = load i32, ptr %i, align 4
  %add17 = add i32 %i16, 1
  store i32 %add17, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %land_merge
  %sign18 = load i32, ptr %sign, align 4
  %val19 = load i32, ptr %val, align 4
  %mul20 = mul i32 %sign18, %val19
  ret i32 %mul20

land_rhs:                                         ; preds = %while_cond
  %i6 = load i32, ptr %i, align 4
  %ptr_load7 = load ptr, ptr %s, align 8
  %ptr_gep8 = getelementptr i8, ptr %ptr_load7, i32 %i6
  %idx_load9 = load i8, ptr %ptr_gep8, align 1
  %icmp10 = icmp sle i8 %idx_load9, 57
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond
  %land = phi i1 [ false, %while_cond ], [ %icmp10, %land_rhs ]
  br i1 %land, label %while_body, label %while_exit
}

define internal i64 @fmt__NS_str_to_i64(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %val = alloca i64, align 8
  store i64 0, ptr %val, align 8
  %sign = alloca i64, align 8
  store i64 1, ptr %sign, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  %ptr_load = load ptr, ptr %s, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 0
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp eq i8 %idx_load, 45
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  store i64 -1, ptr %sign, align 8
  store i32 1, ptr %i, align 4
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  br label %while_cond

while_cond:                                       ; preds = %while_body, %if_merge
  %i1 = load i32, ptr %i, align 4
  %ptr_load2 = load ptr, ptr %s, align 8
  %ptr_gep3 = getelementptr i8, ptr %ptr_load2, i32 %i1
  %idx_load4 = load i8, ptr %ptr_gep3, align 1
  %icmp5 = icmp sge i8 %idx_load4, 48
  br i1 %icmp5, label %land_rhs, label %land_merge

while_body:                                       ; preds = %land_merge
  %val11 = load i64, ptr %val, align 8
  %mul = mul i64 %val11, 10
  %i12 = load i32, ptr %i, align 4
  %ptr_load13 = load ptr, ptr %s, align 8
  %ptr_gep14 = getelementptr i8, ptr %ptr_load13, i32 %i12
  %idx_load15 = load i8, ptr %ptr_gep14, align 1
  %sub = sub i8 %idx_load15, 48
  %sext = sext i8 %sub to i64
  %add = add i64 %mul, %sext
  store i64 %add, ptr %val, align 8
  %i16 = load i32, ptr %i, align 4
  %add17 = add i32 %i16, 1
  store i32 %add17, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %land_merge
  %sign18 = load i64, ptr %sign, align 8
  %val19 = load i64, ptr %val, align 8
  %mul20 = mul i64 %sign18, %val19
  ret i64 %mul20

land_rhs:                                         ; preds = %while_cond
  %i6 = load i32, ptr %i, align 4
  %ptr_load7 = load ptr, ptr %s, align 8
  %ptr_gep8 = getelementptr i8, ptr %ptr_load7, i32 %i6
  %idx_load9 = load i8, ptr %ptr_gep8, align 1
  %icmp10 = icmp sle i8 %idx_load9, 57
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond
  %land = phi i1 [ false, %while_cond ], [ %icmp10, %land_rhs ]
  br i1 %land, label %while_body, label %while_exit
}

define i32 @main() {
entry:
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_exit4, %entry
  %i1 = load i32, ptr %i, align 4
  %SZ = load i32, ptr @SZ, align 4
  %icmp = icmp slt i32 %i1, %SZ
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %j = alloca i32, align 4
  store i32 0, ptr %j, align 4
  br label %while_cond2

while_exit:                                       ; preds = %while_cond
  store i32 0, ptr %i, align 4
  br label %while_cond33

while_cond2:                                      ; preds = %while_body3, %while_body
  %j5 = load i32, ptr %j, align 4
  %SZ6 = load i32, ptr @SZ, align 4
  %icmp7 = icmp slt i32 %j5, %SZ6
  br i1 %icmp7, label %while_body3, label %while_exit4

while_body3:                                      ; preds = %while_cond2
  %i8 = load i32, ptr %i, align 4
  %SZ9 = load i32, ptr @SZ, align 4
  %mul = mul i32 %i8, %SZ9
  %j10 = load i32, ptr %j, align 4
  %add = add i32 %mul, %j10
  %arr_gep = getelementptr [102400 x double], ptr @a, i64 0, i32 %add
  %i11 = load i32, ptr %i, align 4
  %j12 = load i32, ptr %j, align 4
  %add13 = add i32 %i11, %j12
  %sitofp = sitofp i32 %add13 to double
  store double %sitofp, ptr %arr_gep, align 8
  %i14 = load i32, ptr %i, align 4
  %SZ15 = load i32, ptr @SZ, align 4
  %mul16 = mul i32 %i14, %SZ15
  %j17 = load i32, ptr %j, align 4
  %add18 = add i32 %mul16, %j17
  %arr_gep19 = getelementptr [102400 x double], ptr @b, i64 0, i32 %add18
  %i20 = load i32, ptr %i, align 4
  %j21 = load i32, ptr %j, align 4
  %sub = sub i32 %i20, %j21
  %sitofp22 = sitofp i32 %sub to double
  store double %sitofp22, ptr %arr_gep19, align 8
  %i23 = load i32, ptr %i, align 4
  %SZ24 = load i32, ptr @SZ, align 4
  %mul25 = mul i32 %i23, %SZ24
  %j26 = load i32, ptr %j, align 4
  %add27 = add i32 %mul25, %j26
  %arr_gep28 = getelementptr [102400 x double], ptr @c, i64 0, i32 %add27
  store double 0.000000e+00, ptr %arr_gep28, align 8
  %j29 = load i32, ptr %j, align 4
  %add30 = add i32 %j29, 1
  store i32 %add30, ptr %j, align 4
  br label %while_cond2

while_exit4:                                      ; preds = %while_cond2
  %i31 = load i32, ptr %i, align 4
  %add32 = add i32 %i31, 1
  store i32 %add32, ptr %i, align 4
  br label %while_cond

while_cond33:                                     ; preds = %while_exit41, %while_exit
  %i36 = load i32, ptr %i, align 4
  %SZ37 = load i32, ptr @SZ, align 4
  %icmp38 = icmp slt i32 %i36, %SZ37
  br i1 %icmp38, label %while_body34, label %while_exit35

while_body34:                                     ; preds = %while_cond33
  %k = alloca i32, align 4
  store i32 0, ptr %k, align 4
  br label %while_cond39

while_exit35:                                     ; preds = %while_cond33
  %SZ92 = load i32, ptr @SZ, align 4
  %SZ93 = load i32, ptr @SZ, align 4
  %mul94 = mul i32 %SZ92, %SZ93
  %sub95 = sub i32 %mul94, 1
  %idx6496 = sext i32 %sub95 to i64
  %oob_cmp97 = icmp uge i64 %idx6496, 102400
  br i1 %oob_cmp97, label %oob_abort98, label %bounds_ok99

while_cond39:                                     ; preds = %while_exit53, %while_body34
  %k42 = load i32, ptr %k, align 4
  %SZ43 = load i32, ptr @SZ, align 4
  %icmp44 = icmp slt i32 %k42, %SZ43
  br i1 %icmp44, label %while_body40, label %while_exit41

while_body40:                                     ; preds = %while_cond39
  %aik = alloca double, align 8
  %i45 = load i32, ptr %i, align 4
  %SZ46 = load i32, ptr @SZ, align 4
  %mul47 = mul i32 %i45, %SZ46
  %k48 = load i32, ptr %k, align 4
  %add49 = add i32 %mul47, %k48
  %idx64 = sext i32 %add49 to i64
  %oob_cmp = icmp uge i64 %idx64, 102400
  br i1 %oob_cmp, label %oob_abort, label %bounds_ok

while_exit41:                                     ; preds = %while_cond39
  %i90 = load i32, ptr %i, align 4
  %add91 = add i32 %i90, 1
  store i32 %add91, ptr %i, align 4
  br label %while_cond33

oob_abort:                                        ; preds = %while_body40
  call void @abort()
  unreachable

bounds_ok:                                        ; preds = %while_body40
  %arr_gep50 = getelementptr [102400 x double], ptr @a, i64 0, i32 %add49
  %idx_load = load double, ptr %arr_gep50, align 8
  store double %idx_load, ptr %aik, align 8
  %j2 = alloca i32, align 4
  store i32 0, ptr %j2, align 4
  br label %while_cond51

while_cond51:                                     ; preds = %bounds_ok83, %bounds_ok
  %j254 = load i32, ptr %j2, align 4
  %SZ55 = load i32, ptr @SZ, align 4
  %icmp56 = icmp slt i32 %j254, %SZ55
  br i1 %icmp56, label %while_body52, label %while_exit53

while_body52:                                     ; preds = %while_cond51
  %i57 = load i32, ptr %i, align 4
  %SZ58 = load i32, ptr @SZ, align 4
  %mul59 = mul i32 %i57, %SZ58
  %j260 = load i32, ptr %j2, align 4
  %add61 = add i32 %mul59, %j260
  %arr_gep62 = getelementptr [102400 x double], ptr @c, i64 0, i32 %add61
  %i63 = load i32, ptr %i, align 4
  %SZ64 = load i32, ptr @SZ, align 4
  %mul65 = mul i32 %i63, %SZ64
  %j266 = load i32, ptr %j2, align 4
  %add67 = add i32 %mul65, %j266
  %idx6468 = sext i32 %add67 to i64
  %oob_cmp69 = icmp uge i64 %idx6468, 102400
  br i1 %oob_cmp69, label %oob_abort70, label %bounds_ok71

while_exit53:                                     ; preds = %while_cond51
  %k88 = load i32, ptr %k, align 4
  %add89 = add i32 %k88, 1
  store i32 %add89, ptr %k, align 4
  br label %while_cond39

oob_abort70:                                      ; preds = %while_body52
  call void @abort()
  unreachable

bounds_ok71:                                      ; preds = %while_body52
  %arr_gep72 = getelementptr [102400 x double], ptr @c, i64 0, i32 %add67
  %idx_load73 = load double, ptr %arr_gep72, align 8
  %aik74 = load double, ptr %aik, align 8
  %k75 = load i32, ptr %k, align 4
  %SZ76 = load i32, ptr @SZ, align 4
  %mul77 = mul i32 %k75, %SZ76
  %j278 = load i32, ptr %j2, align 4
  %add79 = add i32 %mul77, %j278
  %idx6480 = sext i32 %add79 to i64
  %oob_cmp81 = icmp uge i64 %idx6480, 102400
  br i1 %oob_cmp81, label %oob_abort82, label %bounds_ok83

oob_abort82:                                      ; preds = %bounds_ok71
  call void @abort()
  unreachable

bounds_ok83:                                      ; preds = %bounds_ok71
  %arr_gep84 = getelementptr [102400 x double], ptr @b, i64 0, i32 %add79
  %idx_load85 = load double, ptr %arr_gep84, align 8
  %fmul = fmul double %aik74, %idx_load85
  %fadd = fadd double %idx_load73, %fmul
  store double %fadd, ptr %arr_gep62, align 8
  %j286 = load i32, ptr %j2, align 4
  %add87 = add i32 %j286, 1
  store i32 %add87, ptr %j2, align 4
  br label %while_cond51

oob_abort98:                                      ; preds = %while_exit35
  call void @abort()
  unreachable

bounds_ok99:                                      ; preds = %while_exit35
  %arr_gep100 = getelementptr [102400 x double], ptr @c, i64 0, i32 %sub95
  %idx_load101 = load double, ptr %arr_gep100, align 8
  call void @fmt__NS_out_print_f64(double %idx_load101)
  call void @fmt__NS_out_println(ptr @str.21)
  ret i32 0
}

declare void @abort()
