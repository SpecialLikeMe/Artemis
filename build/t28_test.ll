; ModuleID = 'tcon/test/028_while_loop.arc'
source_filename = "tcon/test/028_while_loop.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

define i32 @main() {
entry:
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  %sum = alloca i32, align 4
  store i32 0, ptr %sum, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %i1 = load i32, ptr %i, align 4
  %icmpslt = icmp slt i32 %i1, 10
  br i1 %icmpslt, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %sum2 = load i32, ptr %sum, align 4
  %i3 = load i32, ptr %i, align 4
  %add = add i32 %sum2, %i3
  store i32 %add, ptr %sum, align 4
  %i4 = load i32, ptr %i, align 4
  %add5 = add i32 %i4, 1
  store i32 %add5, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %sum6 = load i32, ptr %sum, align 4
  %icmpne = icmp ne i32 %sum6, 45
  br i1 %icmpne, label %if_then, label %if_merge

if_then:                                          ; preds = %while_exit
  ret i32 1

if_merge:                                         ; preds = %while_exit
  %i7 = load i32, ptr %i, align 4
  %icmpne8 = icmp ne i32 %i7, 10
  br i1 %icmpne8, label %if_then9, label %if_merge10

if_then9:                                         ; preds = %if_merge
  ret i32 2

if_merge10:                                       ; preds = %if_merge
  ret i32 0
}
