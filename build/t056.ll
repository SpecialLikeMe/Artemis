; ModuleID = 'tcon/test/056_union_basic.arc'
source_filename = "tcon/test/056_union_basic.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%Val = type { [4 x i8] }

define i32 @main() {
entry:
  %v = alloca %Val, align 8
  store %Val zeroinitializer, ptr %v, align 1
  store i32 42, ptr %v, align 4
  %mem_load = load i32, ptr %v, align 4
  %icmp = icmp ne i32 %mem_load, 42
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  store i32 0, ptr %v, align 4
  %mem_load1 = load i32, ptr %v, align 4
  %icmp2 = icmp ne i32 %mem_load1, 0
  br i1 %icmp2, label %if_then3, label %if_merge4

if_then3:                                         ; preds = %if_merge
  ret i32 2

if_merge4:                                        ; preds = %if_merge
  ret i32 0
}
