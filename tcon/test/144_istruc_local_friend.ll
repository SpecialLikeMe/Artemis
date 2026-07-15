; ModuleID = 'tcon/test/144_istruc_local_friend.arc'
source_filename = "tcon/test/144_istruc_local_friend.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%Secret = type { i32 }

define void @Secret__NS___construct__(ptr %0, i32 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %v = alloca i32, align 4
  store i32 %1, ptr %v, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %value = getelementptr inbounds nuw %Secret, ptr %ptr_deref, i32 0, i32 0
  %v1 = load i32, ptr %v, align 4
  store i32 %v1, ptr %value, align 4
  ret void
}

define i32 @Secret__NS_get(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %value = getelementptr inbounds nuw %Secret, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %value, align 4
  ret i32 %mem_load
}

define i32 @peek(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %s1 = load ptr, ptr %s, align 8
  %1 = call i32 @Secret__NS_get(ptr %s1)
  ret i32 %1
}

define i32 @main() {
entry:
  %s = alloca %Secret, align 8
  store %Secret zeroinitializer, ptr %s, align 4
  call void @Secret__NS___construct__(ptr %s, i32 77)
  %0 = call i32 @Secret__NS_get(ptr %s)
  %icmp = icmp ne i32 %0, 77
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %1 = call i32 @peek(ptr %s)
  %icmp1 = icmp ne i32 %1, 77
  br i1 %icmp1, label %if_then2, label %if_merge3

if_then2:                                         ; preds = %if_merge
  ret i32 2

if_merge3:                                        ; preds = %if_merge
  ret i32 0
}
