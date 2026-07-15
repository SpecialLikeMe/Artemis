; ModuleID = 'tcon/test/057_union_overlay.arc'
source_filename = "tcon/test/057_union_overlay.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%Bytes = type { [4 x i8] }

define i32 @main() {
entry:
  %u = alloca %Bytes, align 8
  store %Bytes zeroinitializer, ptr %u, align 1
  store i32 1094861636, ptr %u, align 4
  %first = alloca i8, align 1
  %mem_load = load i8, ptr %u, align 1
  store i8 %mem_load, ptr %first, align 1
  %first1 = load i8, ptr %first, align 1
  %icmp = icmp ne i8 %first1, 68
  %first2 = load i8, ptr %first, align 1
  %icmp3 = icmp ne i8 %first2, 65
  %land = and i1 %icmp, %icmp3
  br i1 %land, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  ret i32 0
}
