; ModuleID = 'build/t245_d7.arc'
source_filename = "build/t245_d7.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

@Counter__static_total = global i32 0

define i32 @Counter__NS_get_total() {
entry:
  ret i32 undef
}

define i32 @main() {
entry:
  %gt = alloca i32, align 4
  %0 = call i32 @Counter__NS_get_total()
  store i32 %0, ptr %gt, align 4
  %gt1 = load i32, ptr %gt, align 4
  %icmp = icmp ne i32 %gt1, 99
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  ret i32 0
}
