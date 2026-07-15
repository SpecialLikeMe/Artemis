; ModuleID = 'tcon/test/130_func_ptr.arc'
source_filename = "tcon/test/130_func_ptr.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

define i32 @add(i32 %0, i32 %1) {
entry:
  %a = alloca i32, align 4
  store i32 %0, ptr %a, align 4
  %b = alloca i32, align 4
  store i32 %1, ptr %b, align 4
  %a1 = load i32, ptr %a, align 4
  %b2 = load i32, ptr %b, align 4
  %add = add i32 %a1, %b2
  ret i32 %add
}

define i32 @mul(i32 %0, i32 %1) {
entry:
  %a = alloca i32, align 4
  store i32 %0, ptr %a, align 4
  %b = alloca i32, align 4
  store i32 %1, ptr %b, align 4
  %a1 = load i32, ptr %a, align 4
  %b2 = load i32, ptr %b, align 4
  %mul = mul i32 %a1, %b2
  ret i32 %mul
}

define i32 @sub(i32 %0, i32 %1) {
entry:
  %a = alloca i32, align 4
  store i32 %0, ptr %a, align 4
  %b = alloca i32, align 4
  store i32 %1, ptr %b, align 4
  %a1 = load i32, ptr %a, align 4
  %b2 = load i32, ptr %b, align 4
  %sub = sub i32 %a1, %b2
  ret i32 %sub
}

define i32 @apply(ptr %0, i32 %1, i32 %2) {
entry:
  %op = alloca ptr, align 8
  store ptr %0, ptr %op, align 8
  %x = alloca i32, align 4
  store i32 %1, ptr %x, align 4
  %y = alloca i32, align 4
  store i32 %2, ptr %y, align 4
  ret i32 undef
}

define i32 @main() {
entry:
  %op = alloca ptr, align 8
  store ptr @add, ptr %op, align 8
  %fp = load ptr, ptr %op, align 8
  %0 = call i32 %fp(i32 3, i32 4)
  %icmp = icmp ne i32 %0, 7
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  store ptr @mul, ptr %op, align 8
  %fp1 = load ptr, ptr %op, align 8
  %1 = call i32 %fp1(i32 3, i32 4)
  %icmp2 = icmp ne i32 %1, 12
  br i1 %icmp2, label %if_then3, label %if_merge4

if_then3:                                         ; preds = %if_merge
  ret i32 2

if_merge4:                                        ; preds = %if_merge
  store ptr @sub, ptr %op, align 8
  %fp5 = load ptr, ptr %op, align 8
  %2 = call i32 %fp5(i32 10, i32 3)
  %icmp6 = icmp ne i32 %2, 7
  br i1 %icmp6, label %if_then7, label %if_merge8

if_then7:                                         ; preds = %if_merge4
  ret i32 3

if_merge8:                                        ; preds = %if_merge4
  %3 = call i32 @apply(ptr @add, i32 5, i32 6)
  %icmp9 = icmp ne i32 %3, 11
  br i1 %icmp9, label %if_then10, label %if_merge11

if_then10:                                        ; preds = %if_merge8
  ret i32 4

if_merge11:                                       ; preds = %if_merge8
  %4 = call i32 @apply(ptr @mul, i32 5, i32 6)
  %icmp12 = icmp ne i32 %4, 30
  br i1 %icmp12, label %if_then13, label %if_merge14

if_then13:                                        ; preds = %if_merge11
  ret i32 5

if_merge14:                                       ; preds = %if_merge11
  ret i32 0
}
