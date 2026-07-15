; ModuleID = 'tcon/test/189_namespace_basic.arc'
source_filename = "tcon/test/189_namespace_basic.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

@str = private unnamed_addr constant [6 x i8] c"hello\00", align 1

define i32 @Math__NS_add(i32 %0, i32 %1) {
entry:
  %a = alloca i32, align 4
  store i32 %0, ptr %a, align 4
  %b = alloca i32, align 4
  store i32 %1, ptr %b, align 4
  %a1 = load i32, ptr %a, align 4
  %b2 = load i32, ptr %b, align 4
  %add = add i32 %a1, %b2
  ret i32 %add
}

define i32 @Math__NS_mul(i32 %0, i32 %1) {
entry:
  %a = alloca i32, align 4
  store i32 %0, ptr %a, align 4
  %b = alloca i32, align 4
  store i32 %1, ptr %b, align 4
  %a1 = load i32, ptr %a, align 4
  %b2 = load i32, ptr %b, align 4
  %mul = mul i32 %a1, %b2
  ret i32 %mul
}

define i32 @Math__NS_abs_val(i32 %0) {
entry:
  %x = alloca i32, align 4
  store i32 %0, ptr %x, align 4
  %x1 = load i32, ptr %x, align 4
  %icmp = icmp slt i32 %x1, 0
  br i1 %icmp, label %tern_then, label %tern_else

tern_then:                                        ; preds = %entry
  %x2 = load i32, ptr %x, align 4
  %neg = sub i32 0, %x2
  br label %tern_merge

tern_else:                                        ; preds = %entry
  %x3 = load i32, ptr %x, align 4
  br label %tern_merge

tern_merge:                                       ; preds = %tern_else, %tern_then
  %tern = phi i32 [ %neg, %tern_then ], [ %x3, %tern_else ]
  ret i32 %tern
}

define i32 @Math__NS_max_val(i32 %0, i32 %1) {
entry:
  %a = alloca i32, align 4
  store i32 %0, ptr %a, align 4
  %b = alloca i32, align 4
  store i32 %1, ptr %b, align 4
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
  ret i32 %tern
}

define i32 @Str__NS_length(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %n = alloca i32, align 4
  store i32 0, ptr %n, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %n1 = load i32, ptr %n, align 4
  %ptr_load = load ptr, ptr %s, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %n1
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp ne i8 %idx_load, 0
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %n2 = load i32, ptr %n, align 4
  %add = add i32 %n2, 1
  store i32 %add, ptr %n, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %n3 = load i32, ptr %n, align 4
  ret i32 %n3
}

define i32 @main() {
entry:
  %0 = call i32 @Math__NS_add(i64 3, i64 4)
  %icmp = icmp ne i32 %0, 7
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %1 = call i32 @Math__NS_mul(i64 6, i64 7)
  %icmp1 = icmp ne i32 %1, 42
  br i1 %icmp1, label %if_then2, label %if_merge3

if_then2:                                         ; preds = %if_merge
  ret i32 2

if_merge3:                                        ; preds = %if_merge
  %2 = call i32 @Math__NS_abs_val(i64 -9)
  %icmp4 = icmp ne i32 %2, 9
  br i1 %icmp4, label %if_then5, label %if_merge6

if_then5:                                         ; preds = %if_merge3
  ret i32 3

if_merge6:                                        ; preds = %if_merge3
  %3 = call i32 @Math__NS_max_val(i64 10, i64 20)
  %icmp7 = icmp ne i32 %3, 20
  br i1 %icmp7, label %if_then8, label %if_merge9

if_then8:                                         ; preds = %if_merge6
  ret i32 4

if_merge9:                                        ; preds = %if_merge6
  %hello = alloca ptr, align 8
  store ptr @str, ptr %hello, align 8
  %hello10 = load ptr, ptr %hello, align 8
  %4 = call i32 @Str__NS_length(ptr %hello10)
  %icmp11 = icmp ne i32 %4, 5
  br i1 %icmp11, label %if_then12, label %if_merge13

if_then12:                                        ; preds = %if_merge9
  ret i32 5

if_merge13:                                       ; preds = %if_merge9
  %x = alloca i32, align 4
  %5 = call i32 @Math__NS_mul(i64 2, i64 3)
  %6 = call i32 @Math__NS_abs_val(i64 -1)
  %7 = call i32 @Math__NS_add(i32 %5, i32 %6)
  store i32 %7, ptr %x, align 4
  %x14 = load i32, ptr %x, align 4
  %icmp15 = icmp ne i32 %x14, 7
  br i1 %icmp15, label %if_then16, label %if_merge17

if_then16:                                        ; preds = %if_merge13
  ret i32 6

if_merge17:                                       ; preds = %if_merge13
  ret i32 0
}
