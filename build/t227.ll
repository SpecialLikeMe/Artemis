; ModuleID = 'tcon/test/227_null_coal.arc'
source_filename = "tcon/test/227_null_coal.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

@g_val = global ptr null
@g_default_val = global i32 42

define ptr @maybe_ptr(i32 %0) {
entry:
  %give = alloca i32, align 4
  store i32 %0, ptr %give, align 4
  %give1 = load i32, ptr %give, align 4
  %if_cond = icmp ne i32 %give1, 0
  br i1 %if_cond, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret ptr @g_default_val

if_merge:                                         ; preds = %entry
  ret ptr null
}

define i32 @main() {
entry:
  %p = alloca ptr, align 8
  store ptr null, ptr %p, align 8
  %p1 = load ptr, ptr %p, align 8
  %deref = load i32, ptr %p1, align 4
  %icmp = icmp ne i32 %deref, 42
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %q = alloca ptr, align 8
  store ptr null, ptr %q, align 8
  %q2 = load ptr, ptr %q, align 8
  %deref3 = load i32, ptr %q2, align 4
  %icmp4 = icmp ne i32 %deref3, 42
  br i1 %icmp4, label %if_then5, label %if_merge6

if_then5:                                         ; preds = %if_merge
  ret i32 2

if_merge6:                                        ; preds = %if_merge
  ret i32 0
}
