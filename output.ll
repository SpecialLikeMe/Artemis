; ModuleID = 'C:/Users/devon/AppData/Local/Temp/t_errdefer.arc'
source_filename = "C:/Users/devon/AppData/Local/Temp/t_errdefer.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

@fired = global i32 0

define { i32, ptr, i32 } @fail_fn() {
entry:
  store i32 1, ptr @fired, align 4
  ret { i32, ptr, i32 } { i32 -1902577010, ptr null, i32 undef }
}

define i32 @main() {
entry:
  %calltmp = call { i32, ptr, i32 } @fail_fn()
  %fired = load i32, ptr @fired, align 4
  %icmpne = icmp ne i32 %fired, 1
  br i1 %icmpne, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  ret i32 0
}
