; ModuleID = 'tcon/test/008_f32_arithmetic.arc'
source_filename = "tcon/test/008_f32_arithmetic.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

define i32 @main() {
entry:
  %a = alloca float, align 4
  store float 1.500000e+00, ptr %a, align 4
  %b = alloca float, align 4
  store float 2.500000e+00, ptr %b, align 4
  %c = alloca float, align 4
  %a1 = load float, ptr %a, align 4
  %b2 = load float, ptr %b, align 4
  %fadd = fadd float %a1, %b2
  store float %fadd, ptr %c, align 4
  %c3 = load float, ptr %c, align 4
  %fcmp = fcmp one float %c3, 4.000000e+00
  br i1 %fcmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %d = alloca float, align 4
  %b4 = load float, ptr %b, align 4
  %a5 = load float, ptr %a, align 4
  %fsub = fsub float %b4, %a5
  store float %fsub, ptr %d, align 4
  %d6 = load float, ptr %d, align 4
  %fcmp7 = fcmp one float %d6, 1.000000e+00
  br i1 %fcmp7, label %if_then8, label %if_merge9

if_then8:                                         ; preds = %if_merge
  ret i32 2

if_merge9:                                        ; preds = %if_merge
  %e = alloca float, align 4
  %a10 = load float, ptr %a, align 4
  %b11 = load float, ptr %b, align 4
  %fmul = fmul float %a10, %b11
  store float %fmul, ptr %e, align 4
  %e12 = load float, ptr %e, align 4
  %fcmp13 = fcmp one float %e12, 3.750000e+00
  br i1 %fcmp13, label %if_then14, label %if_merge15

if_then14:                                        ; preds = %if_merge9
  ret i32 3

if_merge15:                                       ; preds = %if_merge9
  ret i32 0
}
