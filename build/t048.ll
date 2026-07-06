; ModuleID = 'tcon/test/048_array_basic.arc'
source_filename = "tcon/test/048_array_basic.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

define i32 @main() {
entry:
  %arr = alloca [5 x i32], align 4
  store [5 x i32] zeroinitializer, ptr %arr, align 4
  %arr_gep = getelementptr [5 x i32], ptr %arr, i64 0, i64 0
  store i32 10, ptr %arr_gep, align 4
  %arr_gep1 = getelementptr [5 x i32], ptr %arr, i64 0, i64 1
  store i32 20, ptr %arr_gep1, align 4
  %arr_gep2 = getelementptr [5 x i32], ptr %arr, i64 0, i64 2
  store i32 30, ptr %arr_gep2, align 4
  %arr_gep3 = getelementptr [5 x i32], ptr %arr, i64 0, i64 3
  store i32 40, ptr %arr_gep3, align 4
  %arr_gep4 = getelementptr [5 x i32], ptr %arr, i64 0, i64 4
  store i32 50, ptr %arr_gep4, align 4
  %sum = alloca i32, align 4
  %arr_gep5 = getelementptr [5 x i32], ptr %arr, i64 0, i64 0
  %idx_load = load i32, ptr %arr_gep5, align 4
  %arr_gep6 = getelementptr [5 x i32], ptr %arr, i64 0, i64 1
  %idx_load7 = load i32, ptr %arr_gep6, align 4
  %add = add i32 %idx_load, %idx_load7
  %arr_gep8 = getelementptr [5 x i32], ptr %arr, i64 0, i64 2
  %idx_load9 = load i32, ptr %arr_gep8, align 4
  %add10 = add i32 %add, %idx_load9
  %arr_gep11 = getelementptr [5 x i32], ptr %arr, i64 0, i64 3
  %idx_load12 = load i32, ptr %arr_gep11, align 4
  %add13 = add i32 %add10, %idx_load12
  %arr_gep14 = getelementptr [5 x i32], ptr %arr, i64 0, i64 4
  %idx_load15 = load i32, ptr %arr_gep14, align 4
  %add16 = add i32 %add13, %idx_load15
  store i32 %add16, ptr %sum, align 4
  %sum17 = load i32, ptr %sum, align 4
  %icmp = icmp ne i32 %sum17, 150
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %arr_gep18 = getelementptr [5 x i32], ptr %arr, i64 0, i64 2
  store i32 99, ptr %arr_gep18, align 4
  %arr_gep19 = getelementptr [5 x i32], ptr %arr, i64 0, i64 2
  %idx_load20 = load i32, ptr %arr_gep19, align 4
  %icmp21 = icmp ne i32 %idx_load20, 99
  br i1 %icmp21, label %if_then22, label %if_merge23

if_then22:                                        ; preds = %if_merge
  ret i32 2

if_merge23:                                       ; preds = %if_merge
  ret i32 0
}
