; ModuleID = 'tcon/test/141_defer_advanced.arc'
source_filename = "tcon/test/141_defer_advanced.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

@log = global [8 x i32] zeroinitializer
@log_idx = global i32 0

define void @push(i32 %0) {
entry:
  %v = alloca i32, align 4
  store i32 %0, ptr %v, align 4
  %log_idx = load i32, ptr @log_idx, align 4
  %arr_gep = getelementptr [8 x i32], ptr @log, i64 0, i32 %log_idx
  %v1 = load i32, ptr %v, align 4
  store i32 %v1, ptr %arr_gep, align 4
  %log_idx2 = load i32, ptr @log_idx, align 4
  %add = add i32 %log_idx2, 1
  store i32 %add, ptr @log_idx, align 4
  ret void
}

define void @inner() {
entry:
  call void @push(i32 1)
  call void @push(i32 2)
  call void @push(i32 11)
  call void @push(i32 10)
  ret void
}

define i32 @with_return(i32 %0) {
entry:
  %x = alloca i32, align 4
  store i32 %0, ptr %x, align 4
  %x1 = load i32, ptr %x, align 4
  %icmp = icmp sgt i32 %x1, 0
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  call void @push(i32 50)
  %x2 = load i32, ptr %x, align 4
  ret i32 %x2

if_merge:                                         ; preds = %entry
  call void @push(i32 60)
  ret i32 0
}

define i32 @main() {
entry:
  call void @inner()
  %idx_load = load i32, ptr @log, align 4
  %icmp = icmp ne i32 %idx_load, 1
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %idx_load1 = load i32, ptr getelementptr ([8 x i32], ptr @log, i64 0, i64 1), align 4
  %icmp2 = icmp ne i32 %idx_load1, 2
  br i1 %icmp2, label %if_then3, label %if_merge4

if_then3:                                         ; preds = %if_merge
  ret i32 2

if_merge4:                                        ; preds = %if_merge
  %idx_load5 = load i32, ptr getelementptr ([8 x i32], ptr @log, i64 0, i64 2), align 4
  %icmp6 = icmp ne i32 %idx_load5, 11
  br i1 %icmp6, label %if_then7, label %if_merge8

if_then7:                                         ; preds = %if_merge4
  ret i32 3

if_merge8:                                        ; preds = %if_merge4
  %idx_load9 = load i32, ptr getelementptr ([8 x i32], ptr @log, i64 0, i64 3), align 4
  %icmp10 = icmp ne i32 %idx_load9, 10
  br i1 %icmp10, label %if_then11, label %if_merge12

if_then11:                                        ; preds = %if_merge8
  ret i32 4

if_merge12:                                       ; preds = %if_merge8
  store i32 0, ptr @log_idx, align 4
  %0 = call i32 @with_return(i32 5)
  %idx_load13 = load i32, ptr @log, align 4
  %icmp14 = icmp ne i32 %idx_load13, 50
  br i1 %icmp14, label %if_then15, label %if_merge16

if_then15:                                        ; preds = %if_merge12
  ret i32 5

if_merge16:                                       ; preds = %if_merge12
  %idx_load17 = load i32, ptr getelementptr ([8 x i32], ptr @log, i64 0, i64 1), align 4
  %icmp18 = icmp ne i32 %idx_load17, 88
  br i1 %icmp18, label %if_then19, label %if_merge20

if_then19:                                        ; preds = %if_merge16
  ret i32 6

if_merge20:                                       ; preds = %if_merge16
  %idx_load21 = load i32, ptr getelementptr ([8 x i32], ptr @log, i64 0, i64 2), align 4
  %icmp22 = icmp ne i32 %idx_load21, 99
  br i1 %icmp22, label %if_then23, label %if_merge24

if_then23:                                        ; preds = %if_merge20
  ret i32 7

if_merge24:                                       ; preds = %if_merge20
  ret i32 0
}
