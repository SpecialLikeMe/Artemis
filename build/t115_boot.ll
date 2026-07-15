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
  %a1 = load i32, ptr %a, align 4
  %b2 = load i32, ptr %b, align 4
  %icmp = icmp sgt i32 %a1, %b2
  br i1 %icmp, label %tern_then, label %tern_else

tern_then:                                        ; preds = %entry
  %a3 = load i32, ptr %a, align 4
  br label %tern_merge

tern_else:                                        ; preds = %entry
  %b4 = load i32, ptr %b, align 4
  br label %tern_merge

tern_merge:                                       ; preds = %tern_else, %tern_then
  %tern = phi i32 [ %a3, %tern_then ], [ %b4, %tern_else ]
  store i32 %tern, ptr %m, align 4
  %m5 = load i32, ptr %m, align 4
  %icmp6 = icmp ne i32 %m5, 20
  br i1 %icmp6, label %if_then, label %if_merge

if_then:                                          ; preds = %tern_merge
  ret i32 1

if_merge:                                         ; preds = %tern_merge
  %c = alloca i32, align 4
  store i32 99, ptr %c, align 4
  %d = alloca i32, align 4
  store i32 3, ptr %d, align 4
  %n = alloca i32, align 4
  %c7 = load i32, ptr %c, align 4
  %d8 = load i32, ptr %d, align 4
  %icmp9 = icmp sgt i32 %c7, %d8
  br i1 %icmp9, label %tern_then10, label %tern_else11

tern_then10:                                      ; preds = %if_merge
  %c13 = load i32, ptr %c, align 4
  br label %tern_merge12

tern_else11:                                      ; preds = %if_merge
  %d14 = load i32, ptr %d, align 4
  br label %tern_merge12

tern_merge12:                                     ; preds = %tern_else11, %tern_then10
  %tern15 = phi i32 [ %c13, %tern_then10 ], [ %d14, %tern_else11 ]
  store i32 %tern15, ptr %n, align 4
  %n16 = load i32, ptr %n, align 4
  %icmp17 = icmp ne i32 %n16, 99
  br i1 %icmp17, label %if_then18, label %if_merge19

if_then18:                                        ; preds = %tern_merge12
  ret i32 2

if_merge19:                                       ; preds = %tern_merge12
  ret i32 0
}
