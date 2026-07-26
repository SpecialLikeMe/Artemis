; ModuleID = 'C:/Users/devon/AppData/Local/Temp/test_fp_ptr.arc'
source_filename = "C:/Users/devon/AppData/Local/Temp/test_fp_ptr.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

define i32 @add(i32 %0) {
entry:
  %x = alloca i32, align 4
  store i32 %0, ptr %x, align 4
  %x1 = load i32, ptr %x, align 4
  ret i32 %x1
}

define i32 @main() {
entry:
  %bar = alloca ptr, align 8
  store ptr @add, ptr %bar, align 8
  %fp = load ptr, ptr %bar, align 8
  %0 = call i32 %fp(i32 0)
  ret i32 %0
}
