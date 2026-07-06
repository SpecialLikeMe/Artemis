; ModuleID = 'tcon/test/049_array_loop.arc'
source_filename = "tcon/test/049_array_loop.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

define i32 @main() {
entry:
  %arr = alloca [10 x i32], align 4
  store [10 x i32] zeroinitializer, ptr %arr, align 4
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %for_cond

for_cond:                                         ; preds = %for_step, %entry
  %i1 = load i32, ptr %i, align 4
  %icmp = icmp slt i32 %i1, 10
  br i1 %icmp, label %for_body, label %for_exit

for_body:                                         ; preds = %for_cond
  %i2 = load i32, ptr %i, align 4
  %arr_gep = getelementptr [10 x i32], ptr %arr, i64 0, i32 %i2
  %i3 = load i32, ptr %i, align 4
  %i4 = load i32, ptr %i, align 4
  %mul = mul i32 %i3, %i4
  store i32 %mul, ptr %arr_gep, align 4
  br label %for_step

for_step:                                         ; preds = %for_body
  %i5 = load i32, ptr %i, align 4
  %post_load = load i32, ptr %i, align 4
  %post_inc = add i32 %post_load, 1
  store i32 %post_inc, ptr %i, align 4
  br label %for_cond

for_exit:                                         ; preds = %for_cond
  %sum = alloca i32, align 4
  store i32 0, ptr %sum, align 4
  %i6 = alloca i32, align 4
  store i32 0, ptr %i6, align 4
  br label %for_cond7

for_cond7:                                        ; preds = %for_step9, %for_exit
  %i11 = load i32, ptr %i6, align 4
  %icmp12 = icmp slt i32 %i11, 10
  br i1 %icmp12, label %for_body8, label %for_exit10

for_body8:                                        ; preds = %for_cond7
  %sum13 = load i32, ptr %sum, align 4
  %i14 = load i32, ptr %i6, align 4
  %arr_gep15 = getelementptr [10 x i32], ptr %arr, i64 0, i32 %i14
  %idx_load = load i32, ptr %arr_gep15, align 4
  %add = add i32 %sum13, %idx_load
  store i32 %add, ptr %sum, align 4
  br label %for_step9

for_step9:                                        ; preds = %for_body8
  %i16 = load i32, ptr %i6, align 4
  %post_load17 = load i32, ptr %i6, align 4
  %post_inc18 = add i32 %post_load17, 1
  store i32 %post_inc18, ptr %i6, align 4
  br label %for_cond7

for_exit10:                                       ; preds = %for_cond7
  %sum19 = load i32, ptr %sum, align 4
  %icmp20 = icmp ne i32 %sum19, 285
  br i1 %icmp20, label %if_then, label %if_merge

if_then:                                          ; preds = %for_exit10
  ret i32 1

if_merge:                                         ; preds = %for_exit10
  ret i32 0
}
