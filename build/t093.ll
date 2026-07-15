; ModuleID = 'tcon/test/093_union_size.arc'
source_filename = "tcon/test/093_union_size.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%Big = type { [8 x i8] }

define i32 @main() {
entry:
  %icmp = icmp slt i64 ptrtoint (ptr getelementptr (%Big, ptr null, i32 1) to i64), 8
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %icmp1 = icmp slt i64 ptrtoint (ptr getelementptr (%Big, ptr null, i32 1) to i64), ptrtoint (ptr getelementptr (i64, ptr null, i32 1) to i64)
  br i1 %icmp1, label %if_then2, label %if_merge3

if_then2:                                         ; preds = %if_merge
  ret i32 2

if_merge3:                                        ; preds = %if_merge
  ret i32 0
}
