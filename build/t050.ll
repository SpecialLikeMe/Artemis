; ModuleID = 'tcon/test/050_array_pointer.arc'
source_filename = "tcon/test/050_array_pointer.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

define i32 @sum_array(ptr %0, i32 %1) {
entry:
  %arr = alloca ptr, align 8
  store ptr %0, ptr %arr, align 8
  %n = alloca i32, align 4
  store i32 %1, ptr %n, align 4
  %s = alloca i32, align 4
  store i32 0, ptr %s, align 4
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %for_cond

for_cond:                                         ; preds = %for_step, %entry
  %i1 = load i32, ptr %i, align 4
  %n2 = load i32, ptr %n, align 4
  %icmp = icmp slt i32 %i1, %n2
  br i1 %icmp, label %for_body, label %for_exit

for_body:                                         ; preds = %for_cond
  %s3 = load i32, ptr %s, align 4
  %i4 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %arr, align 8
  %ptr_gep = getelementptr i32, ptr %ptr_load, i32 %i4
  %idx_load = load i32, ptr %ptr_gep, align 4
  %add = add i32 %s3, %idx_load
  store i32 %add, ptr %s, align 4
  br label %for_step

for_step:                                         ; preds = %for_body
  %i5 = load i32, ptr %i, align 4
  %post_load = load i32, ptr %i, align 4
  %post_inc = add i32 %post_load, 1
  store i32 %post_inc, ptr %i, align 4
  br label %for_cond

for_exit:                                         ; preds = %for_cond
  %s6 = load i32, ptr %s, align 4
  ret i32 %s6
}

define i32 @main() {
entry:
  %a = alloca [5 x i32], align 4
  store [5 x i32] zeroinitializer, ptr %a, align 4
  %arr_gep = getelementptr [5 x i32], ptr %a, i64 0, i64 0
  store i32 1, ptr %arr_gep, align 4
  %arr_gep1 = getelementptr [5 x i32], ptr %a, i64 0, i64 1
  store i32 2, ptr %arr_gep1, align 4
  %arr_gep2 = getelementptr [5 x i32], ptr %a, i64 0, i64 2
  store i32 3, ptr %arr_gep2, align 4
  %arr_gep3 = getelementptr [5 x i32], ptr %a, i64 0, i64 3
  store i32 4, ptr %arr_gep3, align 4
  %arr_gep4 = getelementptr [5 x i32], ptr %a, i64 0, i64 4
  store i32 5, ptr %arr_gep4, align 4
  %s = alloca i32, align 4
  %arr_decay = getelementptr [5 x i32], ptr %a, i64 0, i64 0
  %0 = call i32 @sum_array(ptr %arr_decay, i32 5)
  store i32 %0, ptr %s, align 4
  %s5 = load i32, ptr %s, align 4
  %icmp = icmp ne i32 %s5, 15
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  ret i32 0
}
