; ModuleID = '.tmpwork/fnptr.arc'
source_filename = ".tmpwork/fnptr.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%Wrap = type { ptr, ptr }
%VT = type { ptr }

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
@str = private unnamed_addr constant [8 x i8] c"ptr=%s\0A\00", align 1
@str.1 = private unnamed_addr constant [3 x i8] c"ok\00", align 1
@str.2 = private unnamed_addr constant [5 x i8] c"null\00", align 1

declare i32 @printf(ptr, ...)

declare ptr @malloc(i64)

define internal ptr @my_alloc(ptr %0, i64 %1) {
entry:
  %meta = alloca ptr, align 8
  store ptr %0, ptr %meta, align 8
  %n = alloca i64, align 8
  store i64 %1, ptr %n, align 4
  %p = alloca ptr, align 8
  store ptr null, ptr %p, align 8
  %n1 = load i64, ptr %n, align 4
  %2 = call ptr @malloc(i64 %n1)
  store ptr %2, ptr %p, align 8
  %p2 = load ptr, ptr %p, align 8
  ret ptr %p2
}

define internal ptr @Wrap__NS_go(ptr %0, i64 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %n = alloca i64, align 8
  store i64 %1, ptr %n, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %vt = getelementptr inbounds nuw %Wrap, ptr %ptr_deref, i32 0, i32 1
  %fp_field = getelementptr inbounds nuw %VT, ptr %vt, i32 0, i32 0
  %fp_val = load ptr, ptr %fp_field, align 8
  %ptr_deref1 = load ptr, ptr %self, align 8
  %ptr = getelementptr inbounds nuw %Wrap, ptr %ptr_deref1, i32 0, i32 0
  %ptr_deref2 = load ptr, ptr %self, align 8
  %mem_load = load ptr, ptr %ptr, align 8
  %n3 = load i64, ptr %n, align 4
  %2 = call ptr %fp_val(ptr %mem_load, i64 %n3)
  ret ptr %2
}

define i32 @main() {
entry:
  %v = alloca %VT, align 8
  store %VT zeroinitializer, ptr %v, align 8
  %alloc_fn = getelementptr inbounds nuw %VT, ptr %v, i32 0, i32 0
  store ptr @my_alloc, ptr %alloc_fn, align 8
  %w = alloca %Wrap, align 8
  store %Wrap zeroinitializer, ptr %w, align 8
  %ptr = getelementptr inbounds nuw %Wrap, ptr %w, i32 0, i32 0
  store ptr null, ptr %ptr, align 8
  %vt = getelementptr inbounds nuw %Wrap, ptr %w, i32 0, i32 1
  store ptr %v, ptr %vt, align 8
  %p = alloca ptr, align 8
  %0 = call ptr @Wrap__NS_go(ptr %w, i64 32)
  store ptr %0, ptr %p, align 8
  %p1 = load ptr, ptr %p, align 8
  %icmp = icmp ne ptr %p1, null
  br i1 %icmp, label %tern_then, label %tern_else

tern_then:                                        ; preds = %entry
  br label %tern_merge

tern_else:                                        ; preds = %entry
  br label %tern_merge

tern_merge:                                       ; preds = %tern_else, %tern_then
  %tern = phi ptr [ @str.1, %tern_then ], [ @str.2, %tern_else ]
  %1 = call i32 (ptr, ...) @printf(ptr @str, ptr %tern)
  %p2 = load ptr, ptr %p, align 8
  %icmp3 = icmp eq ptr %p2, null
  br i1 %icmp3, label %if_then, label %if_merge

if_then:                                          ; preds = %tern_merge
  ret i32 1

if_merge:                                         ; preds = %tern_merge
  ret i32 0
}
