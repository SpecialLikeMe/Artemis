; ModuleID = 'tcon/test/115_define_regex_capture.arc'
source_filename = "tcon/test/115_define_regex_capture.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

define i32 @main() {
entry:
  %a = alloca i32, align 4
  store i32 10, ptr %a, align 4
  %b = alloca i32, align 4
  store i32 20, ptr %b, align 4
  %m = alloca i32, align 4
  store i32 0, ptr %m, align 4
  %m1 = load i32, ptr %m, align 4
  %icmp = icmp ne i32 %m1, 20
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %c = alloca i32, align 4
  store i32 99, ptr %c, align 4
  %d = alloca i32, align 4
  store i32 3, ptr %d, align 4
  %n = alloca i32, align 4
  store i32 0, ptr %n, align 4
  %n2 = load i32, ptr %n, align 4
  %icmp3 = icmp ne i32 %n2, 99
  br i1 %icmp3, label %if_then4, label %if_merge5

if_then4:                                         ; preds = %if_merge
  ret i32 2

if_merge5:                                        ; preds = %if_merge
  ret i32 0
}
