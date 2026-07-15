; ModuleID = 'tcon/test/183_alloc_passed_to_func.arc'
source_filename = "tcon/test/183_alloc_passed_to_func.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%Alloc = type { i32, i32 }

declare ptr @malloc(i64)

declare void @free(ptr)

define void @Alloc__NS___construct__(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %total_allocs = getelementptr inbounds nuw %Alloc, ptr %ptr_deref, i32 0, i32 0
  store i32 0, ptr %total_allocs, align 4
  %ptr_deref1 = load ptr, ptr %self, align 8
  %total_frees = getelementptr inbounds nuw %Alloc, ptr %ptr_deref1, i32 0, i32 1
  store i32 0, ptr %total_frees, align 4
  ret void
}

define ptr @Alloc__NS_alloc(ptr %0, i64 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %n = alloca i64, align 8
  store i64 %1, ptr %n, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %total_allocs = getelementptr inbounds nuw %Alloc, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %total_allocs2 = getelementptr inbounds nuw %Alloc, ptr %ptr_deref1, i32 0, i32 0
  %ptr_deref3 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %total_allocs2, align 4
  %add = add i32 %mem_load, 1
  store i32 %add, ptr %total_allocs, align 4
  %n4 = load i64, ptr %n, align 4
  %2 = call ptr @malloc(i64 %n4)
  ret ptr %2
}

define void @Alloc__NS_dealloc(ptr %0, ptr %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %p = alloca ptr, align 8
  store ptr %1, ptr %p, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %total_frees = getelementptr inbounds nuw %Alloc, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref1 = load ptr, ptr %self, align 8
  %total_frees2 = getelementptr inbounds nuw %Alloc, ptr %ptr_deref1, i32 0, i32 1
  %ptr_deref3 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %total_frees2, align 4
  %add = add i32 %mem_load, 1
  store i32 %add, ptr %total_frees, align 4
  %p4 = load ptr, ptr %p, align 8
  call void @free(ptr %p4)
  ret void
}

define i32 @sum_allocated(ptr %0, i32 %1) {
entry:
  %a = alloca ptr, align 8
  store ptr %0, ptr %a, align 8
  %n = alloca i32, align 4
  store i32 %1, ptr %n, align 4
  %arr = alloca ptr, align 8
  %a1 = load ptr, ptr %a, align 8
  %n2 = load i32, ptr %n, align 4
  %zext = zext i32 %n2 to i64
  %mul = mul i64 ptrtoint (ptr getelementptr (i32, ptr null, i32 1) to i64), %zext
  %2 = call ptr @Alloc__NS_alloc(ptr %a1, i64 %mul)
  store ptr %2, ptr %arr, align 8
  %arr3 = load ptr, ptr %arr, align 8
  %icmp = icmp eq ptr %arr3, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 -1

if_merge:                                         ; preds = %entry
  %s = alloca i32, align 4
  store i32 0, ptr %s, align 4
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %for_cond

for_cond:                                         ; preds = %for_step, %if_merge
  %i4 = load i32, ptr %i, align 4
  %n5 = load i32, ptr %n, align 4
  %icmp6 = icmp slt i32 %i4, %n5
  br i1 %icmp6, label %for_body, label %for_exit

for_body:                                         ; preds = %for_cond
  %i7 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %arr, align 8
  %ptr_gep = getelementptr i32, ptr %ptr_load, i32 %i7
  %i8 = load i32, ptr %i, align 4
  %add = add i32 %i8, 1
  store i32 %add, ptr %ptr_gep, align 4
  %s9 = load i32, ptr %s, align 4
  %i10 = load i32, ptr %i, align 4
  %ptr_load11 = load ptr, ptr %arr, align 8
  %ptr_gep12 = getelementptr i32, ptr %ptr_load11, i32 %i10
  %idx_load = load i32, ptr %ptr_gep12, align 4
  %add13 = add i32 %s9, %idx_load
  store i32 %add13, ptr %s, align 4
  br label %for_step

for_step:                                         ; preds = %for_body
  %i14 = load i32, ptr %i, align 4
  %add15 = add i32 %i14, 1
  store i32 %add15, ptr %i, align 4
  br label %for_cond

for_exit:                                         ; preds = %for_cond
  %a16 = load ptr, ptr %a, align 8
  %arr17 = load ptr, ptr %arr, align 8
  call void @Alloc__NS_dealloc(ptr %a16, ptr %arr17)
  %s18 = load i32, ptr %s, align 4
  ret i32 %s18
}

define i32 @main() {
entry:
  %a = alloca %Alloc, align 8
  store %Alloc zeroinitializer, ptr %a, align 4
  call void @Alloc__NS___construct__(ptr %a)
  %result = alloca i32, align 4
  %0 = call i32 @sum_allocated(ptr %a, i32 5)
  store i32 %0, ptr %result, align 4
  %result1 = load i32, ptr %result, align 4
  %icmp = icmp ne i32 %result1, 15
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %total_allocs = getelementptr inbounds nuw %Alloc, ptr %a, i32 0, i32 0
  %mem_load = load i32, ptr %total_allocs, align 4
  %icmp2 = icmp ne i32 %mem_load, 1
  br i1 %icmp2, label %if_then3, label %if_merge4

if_then3:                                         ; preds = %if_merge
  ret i32 2

if_merge4:                                        ; preds = %if_merge
  %total_frees = getelementptr inbounds nuw %Alloc, ptr %a, i32 0, i32 1
  %mem_load5 = load i32, ptr %total_frees, align 4
  %icmp6 = icmp ne i32 %mem_load5, 1
  br i1 %icmp6, label %if_then7, label %if_merge8

if_then7:                                         ; preds = %if_merge4
  ret i32 3

if_merge8:                                        ; preds = %if_merge4
  %1 = call i32 @sum_allocated(ptr %a, i32 3)
  store i32 %1, ptr %result, align 4
  %result9 = load i32, ptr %result, align 4
  %icmp10 = icmp ne i32 %result9, 6
  br i1 %icmp10, label %if_then11, label %if_merge12

if_then11:                                        ; preds = %if_merge8
  ret i32 4

if_merge12:                                       ; preds = %if_merge8
  %total_allocs13 = getelementptr inbounds nuw %Alloc, ptr %a, i32 0, i32 0
  %mem_load14 = load i32, ptr %total_allocs13, align 4
  %icmp15 = icmp ne i32 %mem_load14, 2
  br i1 %icmp15, label %if_then16, label %if_merge17

if_then16:                                        ; preds = %if_merge12
  ret i32 5

if_merge17:                                       ; preds = %if_merge12
  %total_frees18 = getelementptr inbounds nuw %Alloc, ptr %a, i32 0, i32 1
  %mem_load19 = load i32, ptr %total_frees18, align 4
  %icmp20 = icmp ne i32 %mem_load19, 2
  br i1 %icmp20, label %if_then21, label %if_merge22

if_then21:                                        ; preds = %if_merge17
  ret i32 6

if_merge22:                                       ; preds = %if_merge17
  ret i32 0
}
