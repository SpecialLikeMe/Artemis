; ModuleID = 'tcon/test/205_macro_simple.arc'
source_filename = "tcon/test/205_macro_simple.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(ptr, ...)

define i32 @main() {
entry:
  %val = alloca i32, align 4
  store i32 0, ptr %val, align 4
  %val1 = load i32, ptr %val, align 4
  %icmp = icmp ne i32 %val1, 42
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  ret i32 0
}
