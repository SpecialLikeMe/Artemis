; ModuleID = 'tcon/test/137_adt_enum_plain.arc'
source_filename = "tcon/test/137_adt_enum_plain.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

@color__red = internal constant i32 0
@color__green = internal constant i32 1
@color__blue = internal constant i32 2

define i32 @main() {
entry:
  %c = alloca i32, align 4
  store i32 0, ptr %c, align 4
  %c1 = load i32, ptr %c, align 4
  %c2 = load i32, ptr %c, align 4
  ret i32 0
}
