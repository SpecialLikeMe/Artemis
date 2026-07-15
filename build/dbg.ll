; ModuleID = 'C:/Temp/debug_test.arc'
source_filename = "C:/Temp/debug_test.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

define i32 @mode() {
entry:
  ret i32 1
}

define i32 @main() {
entry:
  %0 = call i32 @mode()
  %icmp = icmp ne i32 %0, 1
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  ret i32 0
}
