; ModuleID = 'tcon/test/293_memstr_5slot_vtable.arc'
source_filename = "tcon/test/293_memstr_5slot_vtable.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%__vtable__ = type { ptr, ptr, ptr, ptr, ptr }
%TrackAlloc = type { i32, i32 }

@TrackAlloc__vtable__ = constant %__vtable__ { ptr @TrackAlloc__NS_mmap, ptr @TrackAlloc__NS_rsmap, ptr @TrackAlloc__NS_rmap, ptr @TrackAlloc__NS_free, ptr @TrackAlloc__NS_destroy }

declare ptr @malloc(i64)

declare ptr @realloc(ptr, i64)

declare void @free(ptr)

define internal void @TrackAlloc__NS___construct__(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %allocs = getelementptr inbounds nuw %TrackAlloc, ptr %ptr_deref, i32 0, i32 0
  store i32 0, ptr %allocs, align 4
  %ptr_deref1 = load ptr, ptr %self, align 8
  %frees = getelementptr inbounds nuw %TrackAlloc, ptr %ptr_deref1, i32 0, i32 1
  store i32 0, ptr %frees, align 4
  ret void
}

define internal ptr @TrackAlloc__NS_mmap(ptr %0, i64 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %n = alloca i64, align 8
  store i64 %1, ptr %n, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %allocs = getelementptr inbounds nuw %TrackAlloc, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %allocs2 = getelementptr inbounds nuw %TrackAlloc, ptr %ptr_deref1, i32 0, i32 0
  %ptr_deref3 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %allocs2, align 4
  %add = add i32 %mem_load, 1
  store i32 %add, ptr %allocs, align 4
  %n4 = load i64, ptr %n, align 4
  %2 = call ptr @malloc(i64 %n4)
  ret ptr %2
}

define internal i8 @TrackAlloc__NS_rsmap(ptr %0, ptr %1, i65 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %p = alloca ptr, align 8
  store ptr %1, ptr %p, align 8
  %n = alloca i65, align 8
  store i65 %2, ptr %n, align 4
  ret i8 0
}

define internal ptr @TrackAlloc__NS_rmap(ptr %0, ptr %1, i65 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %p = alloca ptr, align 8
  store ptr %1, ptr %p, align 8
  %n = alloca i65, align 8
  store i65 %2, ptr %n, align 4
  %p1 = load ptr, ptr %p, align 8
  %n2 = load i65, ptr %n, align 4
  %trunc = trunc i65 %n2 to i64
  %3 = call ptr @realloc(ptr %p1, i64 %trunc)
  ret ptr %3
}

define internal void @TrackAlloc__NS_free(ptr %0, ptr %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %p = alloca ptr, align 8
  store ptr %1, ptr %p, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %frees = getelementptr inbounds nuw %TrackAlloc, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref1 = load ptr, ptr %self, align 8
  %frees2 = getelementptr inbounds nuw %TrackAlloc, ptr %ptr_deref1, i32 0, i32 1
  %ptr_deref3 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %frees2, align 4
  %add = add i32 %mem_load, 1
  store i32 %add, ptr %frees, align 4
  %p4 = load ptr, ptr %p, align 8
  call void @free(ptr %p4)
  ret void
}

define internal void @TrackAlloc__NS_destroy(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  ret void
}

define i32 @main() {
entry:
  %a = alloca %TrackAlloc, align 8
  store %TrackAlloc zeroinitializer, ptr %a, align 4
  call void @TrackAlloc__NS___construct__(ptr %a)
  %p = alloca ptr, align 8
  %mul = mul i64 ptrtoint (ptr getelementptr (i32, ptr null, i32 1) to i64), 4
  %0 = call ptr @TrackAlloc__NS_mmap(ptr %a, i64 %mul)
  store ptr %0, ptr %p, align 8
  %p1 = load ptr, ptr %p, align 8
  %icmp = icmp eq ptr %p1, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %ptr_load = load ptr, ptr %p, align 8
  %ptr_gep = getelementptr i32, ptr %ptr_load, i32 0
  store i32 10, ptr %ptr_gep, align 4
  %ptr_load2 = load ptr, ptr %p, align 8
  %ptr_gep3 = getelementptr i32, ptr %ptr_load2, i32 1
  store i32 20, ptr %ptr_gep3, align 4
  %ptr_load4 = load ptr, ptr %p, align 8
  %ptr_gep5 = getelementptr i32, ptr %ptr_load4, i32 2
  store i32 30, ptr %ptr_gep5, align 4
  %ptr_load6 = load ptr, ptr %p, align 8
  %ptr_gep7 = getelementptr i32, ptr %ptr_load6, i32 3
  store i32 40, ptr %ptr_gep7, align 4
  %ptr_load8 = load ptr, ptr %p, align 8
  %ptr_gep9 = getelementptr i32, ptr %ptr_load8, i32 0
  %idx_load = load i32, ptr %ptr_gep9, align 4
  %ptr_load10 = load ptr, ptr %p, align 8
  %ptr_gep11 = getelementptr i32, ptr %ptr_load10, i32 1
  %idx_load12 = load i32, ptr %ptr_gep11, align 4
  %add = add i32 %idx_load, %idx_load12
  %ptr_load13 = load ptr, ptr %p, align 8
  %ptr_gep14 = getelementptr i32, ptr %ptr_load13, i32 2
  %idx_load15 = load i32, ptr %ptr_gep14, align 4
  %add16 = add i32 %add, %idx_load15
  %ptr_load17 = load ptr, ptr %p, align 8
  %ptr_gep18 = getelementptr i32, ptr %ptr_load17, i32 3
  %idx_load19 = load i32, ptr %ptr_gep18, align 4
  %add20 = add i32 %add16, %idx_load19
  %icmp21 = icmp ne i32 %add20, 100
  br i1 %icmp21, label %if_then22, label %if_merge23

if_then22:                                        ; preds = %if_merge
  ret i32 2

if_merge23:                                       ; preds = %if_merge
  %q = alloca ptr, align 8
  %mul24 = mul i64 ptrtoint (ptr getelementptr (i32, ptr null, i32 1) to i64), 2
  %1 = call ptr @TrackAlloc__NS_mmap(ptr %a, i64 %mul24)
  store ptr %1, ptr %q, align 8
  %q25 = load ptr, ptr %q, align 8
  %icmp26 = icmp eq ptr %q25, null
  br i1 %icmp26, label %if_then27, label %if_merge28

if_then27:                                        ; preds = %if_merge23
  ret i32 3

if_merge28:                                       ; preds = %if_merge23
  %ptr_load29 = load ptr, ptr %q, align 8
  %ptr_gep30 = getelementptr i32, ptr %ptr_load29, i32 0
  store i32 1, ptr %ptr_gep30, align 4
  %ptr_load31 = load ptr, ptr %q, align 8
  %ptr_gep32 = getelementptr i32, ptr %ptr_load31, i32 1
  store i32 2, ptr %ptr_gep32, align 4
  %p33 = load ptr, ptr %p, align 8
  call void @TrackAlloc__NS_free(ptr %a, ptr %p33)
  %q34 = load ptr, ptr %q, align 8
  call void @TrackAlloc__NS_free(ptr %a, ptr %q34)
  %allocs = getelementptr inbounds nuw %TrackAlloc, ptr %a, i32 0, i32 0
  %mem_load = load i32, ptr %allocs, align 4
  %icmp35 = icmp ne i32 %mem_load, 2
  br i1 %icmp35, label %if_then36, label %if_merge37

if_then36:                                        ; preds = %if_merge28
  ret i32 4

if_merge37:                                       ; preds = %if_merge28
  %frees = getelementptr inbounds nuw %TrackAlloc, ptr %a, i32 0, i32 1
  %mem_load38 = load i32, ptr %frees, align 4
  %icmp39 = icmp ne i32 %mem_load38, 2
  br i1 %icmp39, label %if_then40, label %if_merge41

if_then40:                                        ; preds = %if_merge37
  ret i32 5

if_merge41:                                       ; preds = %if_merge37
  call void @TrackAlloc__NS_destroy(ptr %a)
  ret i32 0
}
