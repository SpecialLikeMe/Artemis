; ModuleID = 'tcon/test/139_istruc_init_list.arc'
source_filename = "tcon/test/139_istruc_init_list.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%Pair = type { i32, i32 }
%Triple = type { i32, i32, i32 }

define void @Pair__NS___construct__(ptr %0, i32 %1, i32 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %a = alloca i32, align 4
  store i32 %1, ptr %a, align 4
  %b = alloca i32, align 4
  store i32 %2, ptr %b, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %first = getelementptr inbounds nuw %Pair, ptr %ptr_deref, i32 0, i32 0
  %a1 = load i32, ptr %a, align 4
  %load_for_op = load i32, ptr %first, align 4
  store i32 %a1, ptr %first, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %second = getelementptr inbounds nuw %Pair, ptr %ptr_deref2, i32 0, i32 1
  %b3 = load i32, ptr %b, align 4
  %load_for_op4 = load i32, ptr %second, align 4
  store i32 %b3, ptr %second, align 4
  ret void
}

define i32 @Pair__NS_sum(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %first = getelementptr inbounds nuw %Pair, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %first, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %second = getelementptr inbounds nuw %Pair, ptr %ptr_deref2, i32 0, i32 1
  %ptr_deref3 = load ptr, ptr %self, align 8
  %mem_load4 = load i32, ptr %second, align 4
  %add = add i32 %mem_load, %mem_load4
  ret i32 %add
}

define i32 @Pair__NS_product(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %first = getelementptr inbounds nuw %Pair, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %first, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %second = getelementptr inbounds nuw %Pair, ptr %ptr_deref2, i32 0, i32 1
  %ptr_deref3 = load ptr, ptr %self, align 8
  %mem_load4 = load i32, ptr %second, align 4
  %mul = mul i32 %mem_load, %mem_load4
  ret i32 %mul
}

define void @Triple__NS___construct__(ptr %0, i32 %1, i32 %2, i32 %3) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %x = alloca i32, align 4
  store i32 %1, ptr %x, align 4
  %y = alloca i32, align 4
  store i32 %2, ptr %y, align 4
  %z = alloca i32, align 4
  store i32 %3, ptr %z, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %a = getelementptr inbounds nuw %Triple, ptr %ptr_deref, i32 0, i32 0
  %x1 = load i32, ptr %x, align 4
  %load_for_op = load i32, ptr %a, align 4
  store i32 %x1, ptr %a, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %b = getelementptr inbounds nuw %Triple, ptr %ptr_deref2, i32 0, i32 1
  %y3 = load i32, ptr %y, align 4
  %load_for_op4 = load i32, ptr %b, align 4
  store i32 %y3, ptr %b, align 4
  %ptr_deref5 = load ptr, ptr %self, align 8
  %c = getelementptr inbounds nuw %Triple, ptr %ptr_deref5, i32 0, i32 2
  %z6 = load i32, ptr %z, align 4
  %load_for_op7 = load i32, ptr %c, align 4
  store i32 %z6, ptr %c, align 4
  ret void
}

define i32 @Triple__NS_total(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %a = getelementptr inbounds nuw %Triple, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %a, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %b = getelementptr inbounds nuw %Triple, ptr %ptr_deref2, i32 0, i32 1
  %ptr_deref3 = load ptr, ptr %self, align 8
  %mem_load4 = load i32, ptr %b, align 4
  %add = add i32 %mem_load, %mem_load4
  %ptr_deref5 = load ptr, ptr %self, align 8
  %c = getelementptr inbounds nuw %Triple, ptr %ptr_deref5, i32 0, i32 2
  %ptr_deref6 = load ptr, ptr %self, align 8
  %mem_load7 = load i32, ptr %c, align 4
  %add8 = add i32 %add, %mem_load7
  ret i32 %add8
}

define i32 @main() {
entry:
  %p = alloca %Pair, align 8
  store %Pair zeroinitializer, ptr %p, align 4
  call void @Pair__NS___construct__(ptr %p, i32 3, i32 7)
  %first = getelementptr inbounds nuw %Pair, ptr %p, i32 0, i32 0
  %mem_load = load i32, ptr %first, align 4
  %icmp = icmp ne i32 %mem_load, 3
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %second = getelementptr inbounds nuw %Pair, ptr %p, i32 0, i32 1
  %mem_load1 = load i32, ptr %second, align 4
  %icmp2 = icmp ne i32 %mem_load1, 7
  br i1 %icmp2, label %if_then3, label %if_merge4

if_then3:                                         ; preds = %if_merge
  ret i32 2

if_merge4:                                        ; preds = %if_merge
  %0 = call i32 @Pair__NS_sum(ptr %p)
  %icmp5 = icmp ne i32 %0, 10
  br i1 %icmp5, label %if_then6, label %if_merge7

if_then6:                                         ; preds = %if_merge4
  ret i32 3

if_merge7:                                        ; preds = %if_merge4
  %1 = call i32 @Pair__NS_product(ptr %p)
  %icmp8 = icmp ne i32 %1, 21
  br i1 %icmp8, label %if_then9, label %if_merge10

if_then9:                                         ; preds = %if_merge7
  ret i32 4

if_merge10:                                       ; preds = %if_merge7
  %t = alloca %Triple, align 8
  store %Triple zeroinitializer, ptr %t, align 4
  call void @Triple__NS___construct__(ptr %t, i32 1, i32 2, i32 3)
  %a = getelementptr inbounds nuw %Triple, ptr %t, i32 0, i32 0
  %mem_load11 = load i32, ptr %a, align 4
  %icmp12 = icmp ne i32 %mem_load11, 1
  br i1 %icmp12, label %if_then13, label %if_merge14

if_then13:                                        ; preds = %if_merge10
  ret i32 5

if_merge14:                                       ; preds = %if_merge10
  %b = getelementptr inbounds nuw %Triple, ptr %t, i32 0, i32 1
  %mem_load15 = load i32, ptr %b, align 4
  %icmp16 = icmp ne i32 %mem_load15, 2
  br i1 %icmp16, label %if_then17, label %if_merge18

if_then17:                                        ; preds = %if_merge14
  ret i32 6

if_merge18:                                       ; preds = %if_merge14
  %c = getelementptr inbounds nuw %Triple, ptr %t, i32 0, i32 2
  %mem_load19 = load i32, ptr %c, align 4
  %icmp20 = icmp ne i32 %mem_load19, 3
  br i1 %icmp20, label %if_then21, label %if_merge22

if_then21:                                        ; preds = %if_merge18
  ret i32 7

if_merge22:                                       ; preds = %if_merge18
  %2 = call i32 @Triple__NS_total(ptr %t)
  %icmp23 = icmp ne i32 %2, 6
  br i1 %icmp23, label %if_then24, label %if_merge25

if_then24:                                        ; preds = %if_merge22
  ret i32 8

if_merge25:                                       ; preds = %if_merge22
  ret i32 0
}
