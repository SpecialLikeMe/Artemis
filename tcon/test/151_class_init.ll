; ModuleID = 'tcon/test/151_class_init.arc'
source_filename = "tcon/test/151_class_init.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%Token = type { i32, i32 }

define i32 @Token__NS_total(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %id = getelementptr inbounds nuw %Token, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %id, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %kind = getelementptr inbounds nuw %Token, ptr %ptr_deref2, i32 0, i32 1
  %ptr_deref3 = load ptr, ptr %self, align 8
  %mem_load4 = load i32, ptr %kind, align 4
  %add = add i32 %mem_load, %mem_load4
  ret i32 %add
}

define i32 @main() {
entry:
  %t = alloca %Token, align 8
  %struct_init = alloca %Token, align 8
  store %Token zeroinitializer, ptr %struct_init, align 4
  %id = getelementptr inbounds nuw %Token, ptr %struct_init, i32 0, i32 0
  store i32 5, ptr %id, align 4
  %kind = getelementptr inbounds nuw %Token, ptr %struct_init, i32 0, i32 1
  store i32 6, ptr %kind, align 4
  %struct_val = load %Token, ptr %struct_init, align 4
  store %Token %struct_val, ptr %t, align 4
  %0 = call i32 @Token__NS_total(ptr %t)
  %icmp = icmp ne i32 %0, 11
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  ret i32 0
}
