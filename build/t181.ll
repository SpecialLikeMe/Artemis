; ModuleID = 'tcon/test/181_alloc_wrapper_basic.arc'
source_filename = "tcon/test/181_alloc_wrapper_basic.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

@HeapAlloc__NS_count = global i32 0

declare ptr @malloc(i64)

declare void @free(ptr)

define void @HeapAlloc__NS___construct__(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  ret void
}

define ptr @HeapAlloc__NS_alloc(ptr %0, i64 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %size = alloca i64, align 8
  store i64 %1, ptr %size, align 4
  %size1 = load i64, ptr %size, align 4
  %2 = call ptr @malloc(i64 %size1)
  ret ptr %2
}

define void @HeapAlloc__NS_dealloc(ptr %0, ptr %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr = alloca ptr, align 8
  store ptr %1, ptr %ptr, align 8
  %ptr1 = load ptr, ptr %ptr, align 8
  call void @free(ptr %ptr1)
  ret void
}

define i32 @HeapAlloc__NS_outstanding(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  ret i32 undef
}

define i32 @main() {
entry:
  %a = alloca i8, align 1
  store i8 0, ptr %a, align 1
  %p = alloca ptr, align 8
  store ptr null, ptr %p, align 8
  %p1 = load ptr, ptr %p, align 8
  %icmp = icmp eq ptr %p1, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %ptr_load = load ptr, ptr %p, align 8
  %ptr_gep = getelementptr i32, ptr %ptr_load, i64 0
  store i32 10, ptr %ptr_gep, align 4
  %ptr_load2 = load ptr, ptr %p, align 8
  %ptr_gep3 = getelementptr i32, ptr %ptr_load2, i64 1
  store i32 20, ptr %ptr_gep3, align 4
  %ptr_load4 = load ptr, ptr %p, align 8
  %ptr_gep5 = getelementptr i32, ptr %ptr_load4, i64 2
  store i32 30, ptr %ptr_gep5, align 4
  %sum = alloca i32, align 4
  %ptr_load6 = load ptr, ptr %p, align 8
  %ptr_gep7 = getelementptr i32, ptr %ptr_load6, i64 0
  %idx_load = load i32, ptr %ptr_gep7, align 4
  %ptr_load8 = load ptr, ptr %p, align 8
  %ptr_gep9 = getelementptr i32, ptr %ptr_load8, i64 1
  %idx_load10 = load i32, ptr %ptr_gep9, align 4
  %add = add i32 %idx_load, %idx_load10
  %ptr_load11 = load ptr, ptr %p, align 8
  %ptr_gep12 = getelementptr i32, ptr %ptr_load11, i64 2
  %idx_load13 = load i32, ptr %ptr_gep12, align 4
  %add14 = add i32 %add, %idx_load13
  store i32 %add14, ptr %sum, align 4
  %sum15 = load i32, ptr %sum, align 4
  %icmp16 = icmp ne i32 %sum15, 60
  br i1 %icmp16, label %if_then17, label %if_merge18

if_then17:                                        ; preds = %if_merge
  ret i32 3

if_merge18:                                       ; preds = %if_merge
  ret i32 0
}
