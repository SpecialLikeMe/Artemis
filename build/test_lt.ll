; ModuleID = 'build/test_lt.arc'
source_filename = "build/test_lt.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%S = type { i64, i64 }

define void @foo(ptr %0, i64 %1) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %extra = alloca i64, align 8
  store i64 %1, ptr %extra, align 4
  %ptr_deref = load ptr, ptr %b, align 8
  %len = getelementptr inbounds nuw %S, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %b, align 8
  %mem_load = load i64, ptr %len, align 4
  %extra2 = load i64, ptr %extra, align 4
  %add = add i64 %mem_load, %extra2
  %ptr_deref3 = load ptr, ptr %b, align 8
  %cap = getelementptr inbounds nuw %S, ptr %ptr_deref3, i32 0, i32 1
  %ptr_deref4 = load ptr, ptr %b, align 8
  %mem_load5 = load i64, ptr %cap, align 4
  %icmp = icmp slt i64 %add, %mem_load5
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret void

if_merge:                                         ; preds = %entry
  ret void
}
