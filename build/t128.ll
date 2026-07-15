; ModuleID = 'tcon/test/128_extern_c_block.arc'
source_filename = "tcon/test/128_extern_c_block.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

declare i32 @abs(i32)

declare i64 @llabs(i64)

define i32 @arc_double(i32 %0) {
entry:
  %x = alloca i32, align 4
  store i32 %0, ptr %x, align 4
  %x1 = load i32, ptr %x, align 4
  %mul = mul i32 %x1, 2
  ret i32 %mul
}

define i32 @arc_negate(i32 %0) {
entry:
  %x = alloca i32, align 4
  store i32 %0, ptr %x, align 4
  %x1 = load i32, ptr %x, align 4
  %neg = sub i32 0, %x1
  ret i32 %neg
}

define i32 @main() {
entry:
  %0 = call i32 @abs(i32 -9)
  %icmp = icmp ne i32 %0, 9
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %1 = call i64 @llabs(i64 -100)
  %icmp1 = icmp ne i64 %1, 100
  br i1 %icmp1, label %if_then2, label %if_merge3

if_then2:                                         ; preds = %if_merge
  ret i32 2

if_merge3:                                        ; preds = %if_merge
  %2 = call i32 @arc_double(i32 5)
  %icmp4 = icmp ne i32 %2, 10
  br i1 %icmp4, label %if_then5, label %if_merge6

if_then5:                                         ; preds = %if_merge3
  ret i32 3

if_merge6:                                        ; preds = %if_merge3
  %3 = call i32 @arc_negate(i32 7)
  %icmp7 = icmp ne i32 %3, -7
  br i1 %icmp7, label %if_then8, label %if_merge9

if_then8:                                         ; preds = %if_merge6
  ret i32 4

if_merge9:                                        ; preds = %if_merge6
  ret i32 0
}
