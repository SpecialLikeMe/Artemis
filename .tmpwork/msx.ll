; ModuleID = '.tmpwork/msx.arc'
source_filename = ".tmpwork/msx.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%__vtable__ = type { ptr, ptr, ptr, ptr, ptr }
%memstr = type { ptr, ptr }
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
@str = private unnamed_addr constant [6 x i8] c"r=%d\0A\00", align 1

define internal ptr @memstr__NS_mmap(ptr %0, i64 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %size = alloca i64, align 8
  store i64 %1, ptr %size, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
  ret ptr undef
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
  ret i8 undef
}

define internal ptr @memstr__NS_rmap(ptr %0, ptr %1, i65 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %data = alloca ptr, align 8
  store ptr %1, ptr %data, align 8
  %size = alloca i65, align 8
  store i65 %2, ptr %size, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref1 = load ptr, ptr %self, align 8
  %vtable2 = getelementptr inbounds nuw %memstr, ptr %ptr_deref1, i32 0, i32 1
  ret ptr undef
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
  ret void
}

define internal void @memstr__NS_destroy(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
  ret void
}

define internal void @memstr__NS_deinit(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
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
  store ptr null, ptr %p, align 8
  %p1 = load ptr, ptr %p, align 8
  %icmp = icmp eq ptr %p1, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %p2 = load ptr, ptr %p, align 8
  ret ptr %p2

if_merge:                                         ; preds = %entry
  %b = alloca ptr, align 8
  %p3 = load ptr, ptr %p, align 8
  store ptr %p3, ptr %b, align 8
  %i = alloca i64, align 8
  store i64 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %if_merge
  %i4 = load i64, ptr %i, align 4
  %size5 = load i64, ptr %size, align 4
  %icmp6 = icmp ult i64 %i4, %size5
  br i1 %icmp6, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i7 = load i64, ptr %i, align 4
  %ptr_load = load ptr, ptr %b, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %i7
  store i8 0, ptr %ptr_gep, align 1
  %i8 = load i64, ptr %i, align 4
  %add = add i64 %i8, 1
  store i64 %add, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %p9 = load ptr, ptr %p, align 8
  ret ptr %p9
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

define internal i32 @use_alloc(%memstr %0) {
entry:
  %a = alloca %memstr, align 8
  store %memstr %0, ptr %a, align 8
  %p = alloca ptr, align 8
  %1 = call ptr @memstr__NS_mmap(ptr %a, i64 16)
  store ptr %1, ptr %p, align 8
  %p1 = load ptr, ptr %p, align 8
  %icmp = icmp eq ptr %p1, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 -1

if_merge:                                         ; preds = %entry
  %ptr_load = load ptr, ptr %p, align 8
  %ptr_gep = getelementptr i32, ptr %ptr_load, i32 0
  store i32 99, ptr %ptr_gep, align 4
  %v = alloca i32, align 4
  %ptr_load2 = load ptr, ptr %p, align 8
  %ptr_gep3 = getelementptr i32, ptr %ptr_load2, i32 0
  %idx_load = load i32, ptr %ptr_gep3, align 4
  store i32 %idx_load, ptr %v, align 4
  %p4 = load ptr, ptr %p, align 8
  call void @memstr__NS_free(ptr %a, ptr %p4)
  %v5 = load i32, ptr %v, align 4
  ret i32 %v5
}

define i32 @main() {
entry:
  %s = alloca %Sys, align 8
  store %Sys zeroinitializer, ptr %s, align 1
  %r = alloca i32, align 4
  %s1 = load %Sys, ptr %s, align 1
  %fat_d = insertvalue %memstr undef, ptr %s, 0
  %fat_v = insertvalue %memstr %fat_d, ptr @Sys__vtable__, 1
  %0 = call i32 @use_alloc(%memstr %fat_v)
  store i32 %0, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  %1 = call i32 (ptr, ...) @printf(ptr @str, i32 %r2)
  %r3 = load i32, ptr %r, align 4
  %icmp = icmp ne i32 %r3, 99
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  ret i32 0
}
