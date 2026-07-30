; ModuleID = '.tmpwork/h3.arc'
source_filename = ".tmpwork/h3.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%__vtable__ = type { ptr, ptr, ptr, ptr, ptr }
%memstr = type { ptr, ptr }
%Pt = type { i32, i32 }
%Sys = type {}

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
@Sys__vtable__ = constant %__vtable__ { ptr @Sys__NS_mmap, ptr @Sys__NS_rsmap, ptr @Sys__NS_rmap, ptr @Sys__NS_free, ptr @Sys__NS_destroy }
@str = private unnamed_addr constant [11 x i8] c"create=%d\0A\00", align 1

define internal ptr @memstr__NS_mmap(ptr %0, i64 %1) {
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
  ret ptr null

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
  %size10 = load i64, ptr %size, align 4
  %2 = call ptr %fp_val(ptr %mem_load9, i64 %size10)
  ret ptr %2
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
  %trunc = trunc i65 %size11 to i64
  %3 = call i1 %fp_val(ptr %mem_load9, ptr %data10, i64 %trunc)
  %zext = zext i1 %3 to i8
  ret i8 %zext
}

define internal ptr @memstr__NS_rmap(ptr %0, ptr %1, i65 %2) {
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
  ret ptr %data3

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
  ret ptr null

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
  %data15 = load ptr, ptr %data, align 8
  %size16 = load i65, ptr %size, align 4
  %trunc = trunc i65 %size16 to i64
  %4 = call ptr %fp_val(ptr %mem_load14, ptr %data15, i64 %trunc)
  ret ptr %4
}

define internal void @memstr__NS_free(ptr %0, ptr %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %data = alloca ptr, align 8
  store ptr %1, ptr %data, align 8
  %data1 = load ptr, ptr %data, align 8
  %icmp = icmp eq ptr %data1, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret void

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
  ret void

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
  call void %fp_val(ptr %mem_load13, ptr %data14)
  ret void
}

define internal void @memstr__NS_destroy(ptr %0) {
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
  ret void

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
  call void %fp_val(ptr %mem_load9)
  ret void
}

define internal void @memstr__NS_deinit(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %self_load = load ptr, ptr %self, align 8
  call void @memstr__NS_destroy(ptr %self_load)
  ret void
}

define internal ptr @memstr__NS_zeroed(ptr %0, i64 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %size = alloca i64, align 8
  store i64 %1, ptr %size, align 4
  %p = alloca ptr, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref1 = load ptr, ptr %self, align 8
  %fp_obj = load ptr, ptr %vtable, align 8
  %fp_field = getelementptr inbounds nuw %__vtable__, ptr %fp_obj, i32 0, i32 0
  %fp_val = load ptr, ptr %fp_field, align 8
  %ptr_deref2 = load ptr, ptr %self, align 8
  %ptr = getelementptr inbounds nuw %memstr, ptr %ptr_deref2, i32 0, i32 0
  %ptr_deref3 = load ptr, ptr %self, align 8
  %mem_load = load ptr, ptr %ptr, align 8
  %size4 = load i64, ptr %size, align 4
  %2 = call ptr %fp_val(ptr %mem_load, i64 %size4)
  store ptr %2, ptr %p, align 8
  %p5 = load ptr, ptr %p, align 8
  %icmp = icmp eq ptr %p5, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %p6 = load ptr, ptr %p, align 8
  ret ptr %p6

if_merge:                                         ; preds = %entry
  %b = alloca ptr, align 8
  %p7 = load ptr, ptr %p, align 8
  store ptr %p7, ptr %b, align 8
  %i = alloca i64, align 8
  store i64 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %if_merge
  %i8 = load i64, ptr %i, align 4
  %size9 = load i64, ptr %size, align 4
  %icmp10 = icmp ult i64 %i8, %size9
  br i1 %icmp10, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i11 = load i64, ptr %i, align 4
  %ptr_load = load ptr, ptr %b, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %i11
  store i8 0, ptr %ptr_gep, align 1
  %i12 = load i64, ptr %i, align 4
  %add = add i64 %i12, 1
  store i64 %add, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %p13 = load ptr, ptr %p, align 8
  ret ptr %p13
}

define internal i8 @memstr__NS_failed(ptr %0, ptr %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %p = alloca ptr, align 8
  store ptr %1, ptr %p, align 8
  %p1 = load ptr, ptr %p, align 8
  %icmp = icmp eq ptr %p1, null
  %zext = zext i1 %icmp to i8
  ret i8 %zext
}

declare ptr @malloc(i64)

declare void @free(ptr)

declare i32 @printf(ptr, ...)

define internal ptr @Sys__NS_mmap(ptr %0, i64 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %n = alloca i64, align 8
  store i64 %1, ptr %n, align 4
  %n1 = load i64, ptr %n, align 4
  %2 = call ptr @malloc(i64 %n1)
  ret ptr %2
}

define internal i8 @Sys__NS_rsmap(ptr %0, ptr %1, i65 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %p = alloca ptr, align 8
  store ptr %1, ptr %p, align 8
  %n = alloca i65, align 8
  store i65 %2, ptr %n, align 4
  ret i8 0
}

define internal ptr @Sys__NS_rmap(ptr %0, ptr %1, i65 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %p = alloca ptr, align 8
  store ptr %1, ptr %p, align 8
  %n = alloca i65, align 8
  store i65 %2, ptr %n, align 4
  %n1 = load i65, ptr %n, align 4
  %trunc = trunc i65 %n1 to i64
  %3 = call ptr @malloc(i64 %trunc)
  ret ptr %3
}

define internal void @Sys__NS_free(ptr %0, ptr %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %p = alloca ptr, align 8
  store ptr %1, ptr %p, align 8
  %p1 = load ptr, ptr %p, align 8
  call void @free(ptr %p1)
  ret void
}

define internal void @Sys__NS_destroy(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  ret void
}

define internal i32 @t_create(%memstr %0) {
entry:
  %a = alloca %memstr, align 8
  store %memstr %0, ptr %a, align 8
  %p = alloca ptr, align 8
  store ptr null, ptr %p, align 8
  %p1 = load ptr, ptr %p, align 8
  %icmp = icmp eq ptr %p1, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 -1

if_merge:                                         ; preds = %entry
  %ptr_deref = load ptr, ptr %p, align 8
  %x = getelementptr inbounds nuw %Pt, ptr %ptr_deref, i32 0, i32 0
  store i32 3, ptr %x, align 4
  %ptr_deref2 = load ptr, ptr %p, align 8
  %y = getelementptr inbounds nuw %Pt, ptr %ptr_deref2, i32 0, i32 1
  store i32 4, ptr %y, align 4
  %v = alloca i32, align 4
  %ptr_deref3 = load ptr, ptr %p, align 8
  %x4 = getelementptr inbounds nuw %Pt, ptr %ptr_deref3, i32 0, i32 0
  %ptr_deref5 = load ptr, ptr %p, align 8
  %mem_load = load i32, ptr %x4, align 4
  %ptr_deref6 = load ptr, ptr %p, align 8
  %y7 = getelementptr inbounds nuw %Pt, ptr %ptr_deref6, i32 0, i32 1
  %ptr_deref8 = load ptr, ptr %p, align 8
  %mem_load9 = load i32, ptr %y7, align 4
  %add = add i32 %mem_load, %mem_load9
  store i32 %add, ptr %v, align 4
  %p10 = load ptr, ptr %p, align 8
  call void @memstr__NS_free(ptr %a, ptr %p10)
  %v11 = load i32, ptr %v, align 4
  ret i32 %v11
}

define i32 @main() {
entry:
  %s = alloca %Sys, align 8
  store %Sys zeroinitializer, ptr %s, align 1
  %r = alloca i32, align 4
  %s1 = load %Sys, ptr %s, align 1
  %fat_d = insertvalue %memstr undef, ptr %s, 0
  %fat_v = insertvalue %memstr %fat_d, ptr @Sys__vtable__, 1
  %0 = call i32 @t_create(%memstr %fat_v)
  store i32 %0, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  %1 = call i32 (ptr, ...) @printf(ptr @str, i32 %r2)
  ret i32 0
}
