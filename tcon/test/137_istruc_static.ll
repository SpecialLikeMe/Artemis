; ModuleID = 'tcon/test/137_istruc_static.arc'
source_filename = "tcon/test/137_istruc_static.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%Counter = type { i32 }

define void @Counter__NS___construct__(ptr %0, i32 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %v = alloca i32, align 4
  store i32 %1, ptr %v, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %value = getelementptr inbounds nuw %Counter, ptr %ptr_deref, i32 0, i32 0
  %v1 = load i32, ptr %v, align 4
  store i32 %v1, ptr %value, align 4
  ret void
}

define i32 @Counter__NS_zero() {
entry:
  ret i32 0
}

define i32 @Counter__NS_add(i32 %0, i32 %1) {
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

define i32 @Counter__NS_get(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %value = getelementptr inbounds nuw %Counter, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %value, align 4
  ret i32 %mem_load
}

define void @Counter__NS_inc(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %value = getelementptr inbounds nuw %Counter, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %value2 = getelementptr inbounds nuw %Counter, ptr %ptr_deref1, i32 0, i32 0
  %ptr_deref3 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %value2, align 4
  %add = add i32 %mem_load, 1
  store i32 %add, ptr %value, align 4
  ret void
}

define i32 @main() {
entry:
  %0 = call i32 @Counter__NS_zero()
  %icmp = icmp ne i32 %0, 0
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %1 = call i32 @Counter__NS_add(i32 3, i32 4)
  %icmp1 = icmp ne i32 %1, 7
  br i1 %icmp1, label %if_then2, label %if_merge3

if_then2:                                         ; preds = %if_merge
  ret i32 2

if_merge3:                                        ; preds = %if_merge
  %2 = call i32 @Counter__NS_add(i32 10, i32 5)
  %icmp4 = icmp ne i32 %2, 15
  br i1 %icmp4, label %if_then5, label %if_merge6

if_then5:                                         ; preds = %if_merge3
  ret i32 3

if_merge6:                                        ; preds = %if_merge3
  %c = alloca %Counter, align 8
  store %Counter zeroinitializer, ptr %c, align 4
  call void @Counter__NS___construct__(ptr %c, i32 10)
  call void @Counter__NS_inc(ptr %c)
  %3 = call i32 @Counter__NS_get(ptr %c)
  %icmp7 = icmp ne i32 %3, 11
  br i1 %icmp7, label %if_then8, label %if_merge9

if_then8:                                         ; preds = %if_merge6
  ret i32 4

if_merge9:                                        ; preds = %if_merge6
  ret i32 0
}
