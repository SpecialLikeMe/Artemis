; ModuleID = 'tcon/test/148_implicit_ctor.arc'
source_filename = "tcon/test/148_implicit_ctor.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%Point = type { i32, i32 }

define void @Point__NS___construct__(ptr %0, i32 %1, i32 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %a = alloca i32, align 4
  store i32 %1, ptr %a, align 4
  %b = alloca i32, align 4
  store i32 %2, ptr %b, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %x = getelementptr inbounds nuw %Point, ptr %ptr_deref, i32 0, i32 0
  %a1 = load i32, ptr %a, align 4
  store i32 %a1, ptr %x, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %y = getelementptr inbounds nuw %Point, ptr %ptr_deref2, i32 0, i32 1
  %b3 = load i32, ptr %b, align 4
  store i32 %b3, ptr %y, align 4
  ret void
}

define i32 @Point__NS_sum(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %x = getelementptr inbounds nuw %Point, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %x, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %y = getelementptr inbounds nuw %Point, ptr %ptr_deref2, i32 0, i32 1
  %ptr_deref3 = load ptr, ptr %self, align 8
  %mem_load4 = load i32, ptr %y, align 4
  %add = add i32 %mem_load, %mem_load4
  ret i32 %add
}

define i32 @main() {
entry:
  %p = alloca %Point, align 8
  store %Point zeroinitializer, ptr %p, align 4
  call void @Point__NS___construct__(ptr %p, i32 3, i32 4)
  %0 = call i32 @Point__NS_sum(ptr %p)
  %icmp = icmp ne i32 %0, 7
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %q = alloca %Point, align 8
  store %Point zeroinitializer, ptr %q, align 4
  call void @Point__NS___construct__(ptr %q, i32 10, i32 20)
  %1 = call i32 @Point__NS_sum(ptr %q)
  %icmp1 = icmp ne i32 %1, 30
  br i1 %icmp1, label %if_then2, label %if_merge3

if_then2:                                         ; preds = %if_merge
  ret i32 2

if_merge3:                                        ; preds = %if_merge
  ret i32 0
}
