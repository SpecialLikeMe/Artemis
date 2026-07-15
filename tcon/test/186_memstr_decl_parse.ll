; ModuleID = 'tcon/test/186_memstr_decl_parse.arc'
source_filename = "tcon/test/186_memstr_decl_parse.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%BumpAlloc = type { ptr, i64, i64 }

declare ptr @malloc(i64)

declare void @free(ptr)

define void @BumpAlloc__NS___construct__(ptr %0, i64 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %capacity = alloca i64, align 8
  store i64 %1, ptr %capacity, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %base = getelementptr inbounds nuw %BumpAlloc, ptr %ptr_deref, i32 0, i32 0
  %capacity1 = load i64, ptr %capacity, align 4
  %2 = call ptr @malloc(i64 %capacity1)
  store ptr %2, ptr %base, align 8
  %ptr_deref2 = load ptr, ptr %self, align 8
  %used = getelementptr inbounds nuw %BumpAlloc, ptr %ptr_deref2, i32 0, i32 1
  store i64 0, ptr %used, align 4
  %ptr_deref3 = load ptr, ptr %self, align 8
  %cap = getelementptr inbounds nuw %BumpAlloc, ptr %ptr_deref3, i32 0, i32 2
  %capacity4 = load i64, ptr %capacity, align 4
  store i64 %capacity4, ptr %cap, align 4
  ret void
}

define ptr @BumpAlloc__NS_alloc_bytes(ptr %0, i64 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %n = alloca i64, align 8
  store i64 %1, ptr %n, align 4
  %aligned = alloca i64, align 8
  %n1 = load i64, ptr %n, align 4
  %add = add i64 %n1, 7
  %and = and i64 %add, -8
  store i64 %and, ptr %aligned, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %used = getelementptr inbounds nuw %BumpAlloc, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref2 = load ptr, ptr %self, align 8
  %mem_load = load i64, ptr %used, align 4
  %aligned3 = load i64, ptr %aligned, align 4
  %add4 = add i64 %mem_load, %aligned3
  %ptr_deref5 = load ptr, ptr %self, align 8
  %cap = getelementptr inbounds nuw %BumpAlloc, ptr %ptr_deref5, i32 0, i32 2
  %ptr_deref6 = load ptr, ptr %self, align 8
  %mem_load7 = load i64, ptr %cap, align 4
  %icmp = icmp sgt i64 %add4, %mem_load7
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret ptr null

if_merge:                                         ; preds = %entry
  %p = alloca ptr, align 8
  %ptr_deref8 = load ptr, ptr %self, align 8
  %base = getelementptr inbounds nuw %BumpAlloc, ptr %ptr_deref8, i32 0, i32 0
  %ptr_deref9 = load ptr, ptr %self, align 8
  %mem_load10 = load ptr, ptr %base, align 8
  %ptr_deref11 = load ptr, ptr %self, align 8
  %used12 = getelementptr inbounds nuw %BumpAlloc, ptr %ptr_deref11, i32 0, i32 1
  %ptr_deref13 = load ptr, ptr %self, align 8
  %mem_load14 = load i64, ptr %used12, align 4
  %ptr_add = getelementptr i8, ptr %mem_load10, i64 %mem_load14
  store ptr %ptr_add, ptr %p, align 8
  %ptr_deref15 = load ptr, ptr %self, align 8
  %used16 = getelementptr inbounds nuw %BumpAlloc, ptr %ptr_deref15, i32 0, i32 1
  %ptr_deref17 = load ptr, ptr %self, align 8
  %used18 = getelementptr inbounds nuw %BumpAlloc, ptr %ptr_deref17, i32 0, i32 1
  %ptr_deref19 = load ptr, ptr %self, align 8
  %mem_load20 = load i64, ptr %used18, align 4
  %aligned21 = load i64, ptr %aligned, align 4
  %add22 = add i64 %mem_load20, %aligned21
  store i64 %add22, ptr %used16, align 4
  %p23 = load ptr, ptr %p, align 8
  ret ptr %p23
}

define void @BumpAlloc__NS_deinit(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %base = getelementptr inbounds nuw %BumpAlloc, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load ptr, ptr %base, align 8
  call void @free(ptr %mem_load)
  ret void
}

define i32 @main() {
entry:
  %a = alloca %BumpAlloc, align 8
  store %BumpAlloc zeroinitializer, ptr %a, align 8
  call void @BumpAlloc__NS___construct__(ptr %a, i64 1024)
  %base = getelementptr inbounds nuw %BumpAlloc, ptr %a, i32 0, i32 0
  %mem_load = load ptr, ptr %base, align 8
  %icmp = icmp eq ptr %mem_load, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %p = alloca ptr, align 8
  %mul = mul i64 ptrtoint (ptr getelementptr (i32, ptr null, i32 1) to i64), 4
  %0 = call ptr @BumpAlloc__NS_alloc_bytes(ptr %a, i64 %mul)
  store ptr %0, ptr %p, align 8
  %p1 = load ptr, ptr %p, align 8
  %icmp2 = icmp eq ptr %p1, null
  br i1 %icmp2, label %if_then3, label %if_merge4

if_then3:                                         ; preds = %if_merge
  ret i32 2

if_merge4:                                        ; preds = %if_merge
  %ptr_load = load ptr, ptr %p, align 8
  %ptr_gep = getelementptr i32, ptr %ptr_load, i32 0
  store i32 10, ptr %ptr_gep, align 4
  %ptr_load5 = load ptr, ptr %p, align 8
  %ptr_gep6 = getelementptr i32, ptr %ptr_load5, i32 1
  store i32 20, ptr %ptr_gep6, align 4
  %ptr_load7 = load ptr, ptr %p, align 8
  %ptr_gep8 = getelementptr i32, ptr %ptr_load7, i32 2
  store i32 30, ptr %ptr_gep8, align 4
  %ptr_load9 = load ptr, ptr %p, align 8
  %ptr_gep10 = getelementptr i32, ptr %ptr_load9, i32 3
  store i32 40, ptr %ptr_gep10, align 4
  %sum = alloca i32, align 4
  %ptr_load11 = load ptr, ptr %p, align 8
  %ptr_gep12 = getelementptr i32, ptr %ptr_load11, i32 0
  %idx_load = load i32, ptr %ptr_gep12, align 4
  %ptr_load13 = load ptr, ptr %p, align 8
  %ptr_gep14 = getelementptr i32, ptr %ptr_load13, i32 1
  %idx_load15 = load i32, ptr %ptr_gep14, align 4
  %add = add i32 %idx_load, %idx_load15
  %ptr_load16 = load ptr, ptr %p, align 8
  %ptr_gep17 = getelementptr i32, ptr %ptr_load16, i32 2
  %idx_load18 = load i32, ptr %ptr_gep17, align 4
  %add19 = add i32 %add, %idx_load18
  %ptr_load20 = load ptr, ptr %p, align 8
  %ptr_gep21 = getelementptr i32, ptr %ptr_load20, i32 3
  %idx_load22 = load i32, ptr %ptr_gep21, align 4
  %add23 = add i32 %add19, %idx_load22
  store i32 %add23, ptr %sum, align 4
  %sum24 = load i32, ptr %sum, align 4
  %icmp25 = icmp ne i32 %sum24, 100
  br i1 %icmp25, label %if_then26, label %if_merge27

if_then26:                                        ; preds = %if_merge4
  ret i32 3

if_merge27:                                       ; preds = %if_merge4
  call void @BumpAlloc__NS_deinit(ptr %a)
  ret i32 0
}
