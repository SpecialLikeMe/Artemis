; ModuleID = 'tcon/test/285_adt_enum_fn_subscript.arc'
source_filename = "tcon/test/285_adt_enum_fn_subscript.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%foo = type { i32, [16 x i8] }

@foo__bar = internal constant i32 0
@foo__baz = internal constant i32 1

declare i32 @printf(ptr, ...)

define i32 @main() {
entry:
  %v = alloca %foo, align 8
  %adt_ctor = alloca %foo, align 8
  store %foo zeroinitializer, ptr %adt_ctor, align 4
  %adt_tag = getelementptr inbounds nuw %foo, ptr %adt_ctor, i32 0, i32 0
  store i32 0, ptr %adt_tag, align 4
  %adt_pay = getelementptr inbounds nuw %foo, ptr %adt_ctor, i32 0, i32 1
  %pay_elem = getelementptr i8, ptr %adt_pay
  %pay_elem1 = getelementptr i8, ptr %adt_pay, i64 0
  store ptr @__lambda_0, ptr %pay_elem1, align 8
  %adt_val = load %foo, ptr %adt_ctor, align 4
  store %foo %adt_val, ptr %v, align 4
  %r = alloca i32, align 4
  %dadt_pay = getelementptr inbounds nuw %foo, ptr %v, i32 0, i32 1
  %dadt_fld = getelementptr i8, ptr %dadt_pay, i64 0
  %idx_load = load ptr, ptr %dadt_fld, align 8
  %0 = call i32 %idx_load(i32 5)
  store i32 %0, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  %icmp = icmp ne i32 %r2, 10
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  ret i32 0
}

define internal i32 @__lambda_0(i32 %0) {
entry:
  %x = alloca i32, align 4
  store i32 %0, ptr %x, align 4
  %x1 = load i32, ptr %x, align 4
  %mul = mul i32 %x1, 2
  ret i32 %mul
}
