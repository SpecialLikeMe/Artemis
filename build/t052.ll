; ModuleID = 'tcon/test/052_struct_func.arc'
source_filename = "tcon/test/052_struct_func.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%Vec2 = type { float, float }

define float @dot(%Vec2 %0, %Vec2 %1) {
entry:
  %a = alloca %Vec2, align 8
  store %Vec2 %0, ptr %a, align 4
  %b = alloca %Vec2, align 8
  store %Vec2 %1, ptr %b, align 4
  %x = getelementptr inbounds nuw %Vec2, ptr %a, i32 0, i32 0
  %mem_load = load float, ptr %x, align 4
  %x1 = getelementptr inbounds nuw %Vec2, ptr %b, i32 0, i32 0
  %mem_load2 = load float, ptr %x1, align 4
  %fmul = fmul float %mem_load, %mem_load2
  %y = getelementptr inbounds nuw %Vec2, ptr %a, i32 0, i32 1
  %mem_load3 = load float, ptr %y, align 4
  %y4 = getelementptr inbounds nuw %Vec2, ptr %b, i32 0, i32 1
  %mem_load5 = load float, ptr %y4, align 4
  %fmul6 = fmul float %mem_load3, %mem_load5
  %fadd = fadd float %fmul, %fmul6
  ret float %fadd
}

define i32 @main() {
entry:
  %u = alloca %Vec2, align 8
  store %Vec2 zeroinitializer, ptr %u, align 4
  %x = getelementptr inbounds nuw %Vec2, ptr %u, i32 0, i32 0
  store float 1.000000e+00, ptr %x, align 4
  %y = getelementptr inbounds nuw %Vec2, ptr %u, i32 0, i32 1
  store float 0.000000e+00, ptr %y, align 4
  %v = alloca %Vec2, align 8
  store %Vec2 zeroinitializer, ptr %v, align 4
  %x1 = getelementptr inbounds nuw %Vec2, ptr %v, i32 0, i32 0
  store float 0.000000e+00, ptr %x1, align 4
  %y2 = getelementptr inbounds nuw %Vec2, ptr %v, i32 0, i32 1
  store float 1.000000e+00, ptr %y2, align 4
  %d = alloca float, align 4
  %u3 = load %Vec2, ptr %u, align 4
  %v4 = load %Vec2, ptr %v, align 4
  %0 = call float @dot(%Vec2 %u3, %Vec2 %v4)
  store float %0, ptr %d, align 4
  %d5 = load float, ptr %d, align 4
  %fcmp = fcmp one float %d5, 0.000000e+00
  br i1 %fcmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %w = alloca %Vec2, align 8
  store %Vec2 zeroinitializer, ptr %w, align 4
  %x6 = getelementptr inbounds nuw %Vec2, ptr %w, i32 0, i32 0
  store float 3.000000e+00, ptr %x6, align 4
  %y7 = getelementptr inbounds nuw %Vec2, ptr %w, i32 0, i32 1
  store float 4.000000e+00, ptr %y7, align 4
  %d2 = alloca float, align 4
  %w8 = load %Vec2, ptr %w, align 4
  %w9 = load %Vec2, ptr %w, align 4
  %1 = call float @dot(%Vec2 %w8, %Vec2 %w9)
  store float %1, ptr %d2, align 4
  %d210 = load float, ptr %d2, align 4
  %fcmp11 = fcmp one float %d210, 2.500000e+01
  br i1 %fcmp11, label %if_then12, label %if_merge13

if_then12:                                        ; preds = %if_merge
  ret i32 2

if_merge13:                                       ; preds = %if_merge
  ret i32 0
}
