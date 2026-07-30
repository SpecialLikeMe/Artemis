; ModuleID = '.tmpwork/z.arc'
source_filename = ".tmpwork/z.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%memstr = type { ptr, ptr }
%__vtable__ = type { ptr, ptr, ptr, ptr, ptr }
%S = type { i32, i32 }

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

define i32 @main() {
entry:
  %s = alloca %S, align 8
  store %S zeroinitializer, ptr %s, align 4
  %a = getelementptr inbounds nuw %S, ptr %s, i32 0, i32 0
  %mem_load = load i32, ptr %a, align 4
  ret i32 %mem_load
}
