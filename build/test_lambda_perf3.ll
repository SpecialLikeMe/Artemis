; ModuleID = 'C:/Users/devon/AppData/Local/Temp/test_lambda_perf3.arc'
source_filename = "C:/Users/devon/AppData/Local/Temp/test_lambda_perf3.arc"
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
  %0 = call i32 @__lambda_0()
  %result = alloca i32, align 4
  store i32 %0, ptr %result, align 4
  %result1 = load i32, ptr %result, align 4
  %1 = call i32 (ptr, ...) @printf(ptr @str, i32 %result1)
  ret i32 0
}
