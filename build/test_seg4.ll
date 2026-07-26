; ModuleID = 'C:/Users/devon/AppData/Local/Temp/test_segfault4.arc'
source_filename = "C:/Users/devon/AppData/Local/Temp/test_segfault4.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

@str = private unnamed_addr constant [4 x i8] c"%i\0A\00", align 1

declare i32 @printf(ptr, ...)

define internal i32 @__lambda_0() {
entry:
  ret i32 42
}

define i32 @main() {
entry:
  %bar = alloca ptr, align 8
  %ref_lvl = alloca ptr, align 8
  store ptr @__lambda_0, ptr %ref_lvl, align 8
  store ptr %ref_lvl, ptr %bar, align 8
  %x = alloca ptr, align 8
  %fp = load ptr, ptr %bar, align 8
  %fp_deref = load ptr, ptr %fp, align 8
  %0 = call i32 %fp_deref()
  %i2p = inttoptr i32 %0 to ptr
  store ptr %i2p, ptr %x, align 8
  %y = alloca ptr, align 8
  %x1 = load ptr, ptr %x, align 8
  %deref = load i8, ptr %x1, align 1
  %i2p2 = inttoptr i8 %deref to ptr
  store ptr %i2p2, ptr %y, align 8
  %fp3 = load ptr, ptr %y, align 8
  %1 = call i32 %fp3()
  %2 = call i32 (ptr, ...) @printf(ptr @str, i32 %1)
  ret i32 0
}
