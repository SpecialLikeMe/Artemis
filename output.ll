; ModuleID = 'C:/Users/devon/AppData/Local/Temp/ta.arc'
source_filename = "C:/Users/devon/AppData/Local/Temp/ta.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

define i32 @main() {
entry:
  %x = alloca i32, align 4
  store i32 5, ptr %x, align 4
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %x1 = load i32, ptr %x, align 4
  %icmpsgt = icmp sgt i32 %x1, 3
  br i1 %icmpsgt, label %if_then, label %if_else

if_then:                                          ; preds = %entry
  store i32 1, ptr %r, align 4
  br label %if_merge

if_else:                                          ; preds = %entry
  store i32 2, ptr %r, align 4
  br label %if_merge

if_merge:                                         ; preds = %if_else, %if_then
  ret i32 0
}
