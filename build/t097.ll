; ModuleID = 'tcon/test/097_array_of_structs_sort.arc'
source_filename = "tcon/test/097_array_of_structs_sort.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%Num = type { i32 }

define void @bubble_sort(ptr %0, i32 %1) {
entry:
  %arr = alloca ptr, align 8
  store ptr %0, ptr %arr, align 8
  %n = alloca i32, align 4
  store i32 %1, ptr %n, align 4
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %for_cond

for_cond:                                         ; preds = %for_step, %entry
  %i1 = load i32, ptr %i, align 4
  %n2 = load i32, ptr %n, align 4
  %sub = sub i32 %n2, 1
  %icmp = icmp slt i32 %i1, %sub
  br i1 %icmp, label %for_body, label %for_exit

for_body:                                         ; preds = %for_cond
  %j = alloca i32, align 4
  store i32 0, ptr %j, align 4
  br label %for_cond3

for_step:                                         ; preds = %for_exit6
  %i56 = load i32, ptr %i, align 4
  %post_load57 = load i32, ptr %i, align 4
  %post_inc58 = add i32 %post_load57, 1
  store i32 %post_inc58, ptr %i, align 4
  br label %for_cond

for_exit:                                         ; preds = %for_cond
  ret void

for_cond3:                                        ; preds = %for_step5, %for_body
  %j7 = load i32, ptr %j, align 4
  %n8 = load i32, ptr %n, align 4
  %i9 = load i32, ptr %i, align 4
  %sub10 = sub i32 %n8, %i9
  %sub11 = sub i32 %sub10, 1
  %icmp12 = icmp slt i32 %j7, %sub11
  br i1 %icmp12, label %for_body4, label %for_exit6

for_body4:                                        ; preds = %for_cond3
  %j13 = load i32, ptr %j, align 4
  %ptr_load = load ptr, ptr %arr, align 8
  %ptr_gep = getelementptr %Num, ptr %ptr_load, i32 %j13
  %v = getelementptr inbounds nuw %Num, ptr %ptr_gep, i32 0, i32 0
  %j14 = load i32, ptr %j, align 4
  %ptr_load15 = load ptr, ptr %arr, align 8
  %ptr_gep16 = getelementptr %Num, ptr %ptr_load15, i32 %j14
  %mem_load = load i32, ptr %v, align 4
  %j17 = load i32, ptr %j, align 4
  %add = add i32 %j17, 1
  %ptr_load18 = load ptr, ptr %arr, align 8
  %ptr_gep19 = getelementptr %Num, ptr %ptr_load18, i32 %add
  %v20 = getelementptr inbounds nuw %Num, ptr %ptr_gep19, i32 0, i32 0
  %j21 = load i32, ptr %j, align 4
  %add22 = add i32 %j21, 1
  %ptr_load23 = load ptr, ptr %arr, align 8
  %ptr_gep24 = getelementptr %Num, ptr %ptr_load23, i32 %add22
  %mem_load25 = load i32, ptr %v20, align 4
  %icmp26 = icmp sgt i32 %mem_load, %mem_load25
  br i1 %icmp26, label %if_then, label %if_merge

for_step5:                                        ; preds = %if_merge
  %j55 = load i32, ptr %j, align 4
  %post_load = load i32, ptr %j, align 4
  %post_inc = add i32 %post_load, 1
  store i32 %post_inc, ptr %j, align 4
  br label %for_cond3

for_exit6:                                        ; preds = %for_cond3
  br label %for_step

if_then:                                          ; preds = %for_body4
  %tmp = alloca i32, align 4
  %j27 = load i32, ptr %j, align 4
  %ptr_load28 = load ptr, ptr %arr, align 8
  %ptr_gep29 = getelementptr %Num, ptr %ptr_load28, i32 %j27
  %v30 = getelementptr inbounds nuw %Num, ptr %ptr_gep29, i32 0, i32 0
  %j31 = load i32, ptr %j, align 4
  %ptr_load32 = load ptr, ptr %arr, align 8
  %ptr_gep33 = getelementptr %Num, ptr %ptr_load32, i32 %j31
  %mem_load34 = load i32, ptr %v30, align 4
  store i32 %mem_load34, ptr %tmp, align 4
  %j35 = load i32, ptr %j, align 4
  %ptr_load36 = load ptr, ptr %arr, align 8
  %ptr_gep37 = getelementptr %Num, ptr %ptr_load36, i32 %j35
  %v38 = getelementptr inbounds nuw %Num, ptr %ptr_gep37, i32 0, i32 0
  %j39 = load i32, ptr %j, align 4
  %add40 = add i32 %j39, 1
  %ptr_load41 = load ptr, ptr %arr, align 8
  %ptr_gep42 = getelementptr %Num, ptr %ptr_load41, i32 %add40
  %v43 = getelementptr inbounds nuw %Num, ptr %ptr_gep42, i32 0, i32 0
  %j44 = load i32, ptr %j, align 4
  %add45 = add i32 %j44, 1
  %ptr_load46 = load ptr, ptr %arr, align 8
  %ptr_gep47 = getelementptr %Num, ptr %ptr_load46, i32 %add45
  %mem_load48 = load i32, ptr %v43, align 4
  store i32 %mem_load48, ptr %v38, align 4
  %j49 = load i32, ptr %j, align 4
  %add50 = add i32 %j49, 1
  %ptr_load51 = load ptr, ptr %arr, align 8
  %ptr_gep52 = getelementptr %Num, ptr %ptr_load51, i32 %add50
  %v53 = getelementptr inbounds nuw %Num, ptr %ptr_gep52, i32 0, i32 0
  %tmp54 = load i32, ptr %tmp, align 4
  store i32 %tmp54, ptr %v53, align 4
  br label %if_merge

if_merge:                                         ; preds = %if_then, %for_body4
  br label %for_step5
}

define i32 @main() {
entry:
  %arr = alloca [5 x %Num], align 8
  store [5 x %Num] zeroinitializer, ptr %arr, align 4
  %arr_gep = getelementptr [5 x %Num], ptr %arr, i64 0, i64 0
  %v = getelementptr inbounds nuw %Num, ptr %arr_gep, i32 0, i32 0
  store i32 5, ptr %v, align 4
  %arr_gep1 = getelementptr [5 x %Num], ptr %arr, i64 0, i64 1
  %v2 = getelementptr inbounds nuw %Num, ptr %arr_gep1, i32 0, i32 0
  store i32 1, ptr %v2, align 4
  %arr_gep3 = getelementptr [5 x %Num], ptr %arr, i64 0, i64 2
  %v4 = getelementptr inbounds nuw %Num, ptr %arr_gep3, i32 0, i32 0
  store i32 4, ptr %v4, align 4
  %arr_gep5 = getelementptr [5 x %Num], ptr %arr, i64 0, i64 3
  %v6 = getelementptr inbounds nuw %Num, ptr %arr_gep5, i32 0, i32 0
  store i32 2, ptr %v6, align 4
  %arr_gep7 = getelementptr [5 x %Num], ptr %arr, i64 0, i64 4
  %v8 = getelementptr inbounds nuw %Num, ptr %arr_gep7, i32 0, i32 0
  store i32 3, ptr %v8, align 4
  %arr_decay = getelementptr [5 x %Num], ptr %arr, i64 0, i64 0
  call void @bubble_sort(ptr %arr_decay, i32 5)
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %for_cond

for_cond:                                         ; preds = %for_step, %entry
  %i9 = load i32, ptr %i, align 4
  %icmp = icmp slt i32 %i9, 5
  br i1 %icmp, label %for_body, label %for_exit

for_body:                                         ; preds = %for_cond
  %i10 = load i32, ptr %i, align 4
  %arr_gep11 = getelementptr [5 x %Num], ptr %arr, i64 0, i32 %i10
  %v12 = getelementptr inbounds nuw %Num, ptr %arr_gep11, i32 0, i32 0
  %i13 = load i32, ptr %i, align 4
  %arr_gep14 = getelementptr [5 x %Num], ptr %arr, i64 0, i32 %i13
  %mem_load = load i32, ptr %v12, align 4
  %i15 = load i32, ptr %i, align 4
  %add = add i32 %i15, 1
  %icmp16 = icmp ne i32 %mem_load, %add
  br i1 %icmp16, label %if_then, label %if_merge

for_step:                                         ; preds = %if_merge
  %i17 = load i32, ptr %i, align 4
  %post_load = load i32, ptr %i, align 4
  %post_inc = add i32 %post_load, 1
  store i32 %post_inc, ptr %i, align 4
  br label %for_cond

for_exit:                                         ; preds = %for_cond
  ret i32 0

if_then:                                          ; preds = %for_body
  ret i32 1

if_merge:                                         ; preds = %for_body
  br label %for_step
}
