; ModuleID = 'tcon/test/230_unsigned_ops.arc'
source_filename = "tcon/test/230_unsigned_ops.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

@gvar_a = global i32 0
@gvar_b = global i32 2

define i32 @div_u32(i32 %0, i32 %1) {
entry:
  %a = alloca i32, align 4
  store i32 %0, ptr %a, align 4
  %b = alloca i32, align 4
  store i32 %1, ptr %b, align 4
  %a1 = load i32, ptr %a, align 4
  %b2 = load i32, ptr %b, align 4
  %udiv = udiv i32 %a1, %b2
  ret i32 %udiv
}

define i32 @rem_u32(i32 %0, i32 %1) {
entry:
  %a = alloca i32, align 4
  store i32 %0, ptr %a, align 4
  %b = alloca i32, align 4
  store i32 %1, ptr %b, align 4
  %a1 = load i32, ptr %a, align 4
  %b2 = load i32, ptr %b, align 4
  %urem = urem i32 %a1, %b2
  ret i32 %urem
}

define i8 @lt_u32(i32 %0, i32 %1) {
entry:
  %a = alloca i32, align 4
  store i32 %0, ptr %a, align 4
  %b = alloca i32, align 4
  store i32 %1, ptr %b, align 4
  %a1 = load i32, ptr %a, align 4
  %b2 = load i32, ptr %b, align 4
  %icmp = icmp ult i32 %a1, %b2
  %zext = zext i1 %icmp to i8
  ret i8 %zext
}

define i32 @main() {
entry:
  %big = alloca i32, align 4
  store i32 -2147483648, ptr %big, align 4
  %d = alloca i32, align 4
  %big1 = load i32, ptr %big, align 4
  %0 = call i32 @div_u32(i32 %big1, i32 2)
  store i32 %0, ptr %d, align 4
  %d2 = load i32, ptr %d, align 4
  %icmp = icmp ne i32 %d2, 1073741824
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %r = alloca i32, align 4
  %1 = call i32 @rem_u32(i32 -2147483647, i32 2)
  store i32 %1, ptr %r, align 4
  %r3 = load i32, ptr %r, align 4
  %icmp4 = icmp ne i32 %r3, 1
  br i1 %icmp4, label %if_then5, label %if_merge6

if_then5:                                         ; preds = %if_merge
  ret i32 2

if_merge6:                                        ; preds = %if_merge
  %cmp = alloca i8, align 1
  %big7 = load i32, ptr %big, align 4
  %2 = call i8 @lt_u32(i32 %big7, i32 2)
  store i8 %2, ptr %cmp, align 1
  %cmp8 = load i8, ptr %cmp, align 1
  %if_cond = icmp ne i8 %cmp8, 0
  br i1 %if_cond, label %if_then9, label %if_merge10

if_then9:                                         ; preds = %if_merge6
  ret i32 3

if_merge10:                                       ; preds = %if_merge6
  %ld = alloca i32, align 4
  %big11 = load i32, ptr %big, align 4
  %udiv = udiv i32 %big11, 2
  store i32 %udiv, ptr %ld, align 4
  %ld12 = load i32, ptr %ld, align 4
  %icmp13 = icmp ne i32 %ld12, 1073741824
  br i1 %icmp13, label %if_then14, label %if_merge15

if_then14:                                        ; preds = %if_merge10
  ret i32 4

if_merge15:                                       ; preds = %if_merge10
  %big16 = load i32, ptr %big, align 4
  store i32 %big16, ptr @gvar_a, align 4
  %gd = alloca i32, align 4
  %gvar_a = load i32, ptr @gvar_a, align 4
  %gvar_b = load i32, ptr @gvar_b, align 4
  %sdiv = sdiv i32 %gvar_a, %gvar_b
  store i32 %sdiv, ptr %gd, align 4
  %gd17 = load i32, ptr %gd, align 4
  %icmp18 = icmp ne i32 %gd17, 1073741824
  br i1 %icmp18, label %if_then19, label %if_merge20

if_then19:                                        ; preds = %if_merge15
  ret i32 5

if_merge20:                                       ; preds = %if_merge15
  %z = alloca i32, align 4
  %big21 = load i32, ptr %big, align 4
  %udiv22 = udiv i32 %big21, 2
  %mul = mul i32 %udiv22, 2
  store i32 %mul, ptr %z, align 4
  %z23 = load i32, ptr %z, align 4
  %icmp24 = icmp ne i32 %z23, -2147483648
  br i1 %icmp24, label %if_then25, label %if_merge26

if_then25:                                        ; preds = %if_merge20
  ret i32 6

if_merge26:                                       ; preds = %if_merge20
  ret i32 0
}
