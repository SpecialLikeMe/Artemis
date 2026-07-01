; ModuleID = 'tcon/std/005_alloc_free_list.arc'
source_filename = "tcon/std/005_alloc_free_list.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%free_list = type { ptr, i64, ptr }

declare ptr @malloc(i64)

declare void @free(ptr)

define void @free_list__MT___construct__(ptr %0, i64 %1) {
entry:
  %self.addr = alloca ptr, align 8
  store ptr %0, ptr %self.addr, align 8
  %capacity = alloca i64, align 8
  store i64 %1, ptr %capacity, align 4
  %capacity1 = load i64, ptr %capacity, align 4
  %selfload = load ptr, ptr %self.addr, align 8
  %fieldptr = getelementptr %free_list, ptr %selfload, i32 0, i32 1
  store i64 %capacity1, ptr %fieldptr, align 4
  %capacity2 = load i64, ptr %capacity, align 4
  %calltmp = call ptr @malloc(i64 %capacity2)
  %selfload3 = load ptr, ptr %self.addr, align 8
  %fieldptr4 = getelementptr %free_list, ptr %selfload3, i32 0, i32 0
  store ptr %calltmp, ptr %fieldptr4, align 8
  %capacity5 = load i64, ptr %capacity, align 4
  %selfload6 = load ptr, ptr %self.addr, align 8
  %fieldptr7 = getelementptr %free_list, ptr %selfload6, i32 0, i32 0
  %base = load ptr, ptr %fieldptr7, align 8
  store i64 %capacity5, ptr %base, align 4
  %selfload8 = load ptr, ptr %self.addr, align 8
  %fieldptr9 = getelementptr %free_list, ptr %selfload8, i32 0, i32 0
  %base10 = load ptr, ptr %fieldptr9, align 8
  %ptradd = getelementptr i8, ptr %base10, i32 8
  store i64 0, ptr %ptradd, align 4
  %selfload11 = load ptr, ptr %self.addr, align 8
  %fieldptr12 = getelementptr %free_list, ptr %selfload11, i32 0, i32 0
  %base13 = load ptr, ptr %fieldptr12, align 8
  %selfload14 = load ptr, ptr %self.addr, align 8
  %fieldptr15 = getelementptr %free_list, ptr %selfload14, i32 0, i32 2
  store ptr %base13, ptr %fieldptr15, align 8
  ret void
}

define ptr @free_list__MT_alloc_bytes(ptr %0, i64 %1) {
entry:
  %self.addr = alloca ptr, align 8
  store ptr %0, ptr %self.addr, align 8
  %n = alloca i64, align 8
  store i64 %1, ptr %n, align 4
  %header = alloca i64, align 8
  store i64 16, ptr %header, align 4
  %total = alloca i64, align 8
  %n1 = load i64, ptr %n, align 4
  %header2 = load i64, ptr %header, align 4
  %add = add i64 %n1, %header2
  store i64 %add, ptr %total, align 4
  %rem = alloca i64, align 8
  %total3 = load i64, ptr %total, align 4
  %srem = srem i64 %total3, 8
  store i64 %srem, ptr %rem, align 4
  %rem4 = load i64, ptr %rem, align 4
  %itrunc = trunc i64 %rem4 to i32
  %icmpne = icmp ne i32 %itrunc, 0
  br i1 %icmpne, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %total5 = load i64, ptr %total, align 4
  %rem6 = load i64, ptr %rem, align 4
  %sub = sub i64 8, %rem6
  %add7 = add i64 %total5, %sub
  store i64 %add7, ptr %total, align 4
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  %prev = alloca ptr, align 8
  store ptr null, ptr %prev, align 8
  %curr = alloca ptr, align 8
  %selfload = load ptr, ptr %self.addr, align 8
  %fieldptr = getelementptr %free_list, ptr %selfload, i32 0, i32 2
  %free_head = load ptr, ptr %fieldptr, align 8
  store ptr %free_head, ptr %curr, align 8
  br label %while_cond

while_cond:                                       ; preds = %if_merge17, %if_merge
  %curr8 = load ptr, ptr %curr, align 8
  %icmpne9 = icmp ne ptr %curr8, null
  br i1 %icmpne9, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %curr_size = alloca i64, align 8
  %curr10 = load ptr, ptr %curr, align 8
  %dereftmp = load i8, ptr %curr10, align 1
  %isext = sext i8 %dereftmp to i64
  store i64 %isext, ptr %curr_size, align 4
  %curr_next = alloca i64, align 8
  %curr11 = load ptr, ptr %curr, align 8
  %ptradd = getelementptr i8, ptr %curr11, i32 8
  %dereftmp12 = load i8, ptr %ptradd, align 1
  %isext13 = sext i8 %dereftmp12 to i64
  store i64 %isext13, ptr %curr_next, align 4
  %curr_size14 = load i64, ptr %curr_size, align 4
  %total15 = load i64, ptr %total, align 4
  %icmpge = icmp sge i64 %curr_size14, %total15
  br i1 %icmpge, label %if_then16, label %if_merge17

while_exit:                                       ; preds = %while_cond
  ret ptr null

if_then16:                                        ; preds = %while_body
  %curr_size18 = load i64, ptr %curr_size, align 4
  %total19 = load i64, ptr %total, align 4
  %add20 = add i64 %total19, 24
  %icmpge21 = icmp sge i64 %curr_size18, %add20
  br i1 %icmpge21, label %if_then22, label %if_else

if_merge17:                                       ; preds = %while_body
  %curr60 = load ptr, ptr %curr, align 8
  store ptr %curr60, ptr %prev, align 8
  %curr_next61 = load i64, ptr %curr_next, align 4
  %inttoptr62 = inttoptr i64 %curr_next61 to ptr
  store ptr %inttoptr62, ptr %curr, align 8
  br label %while_cond

if_then22:                                        ; preds = %if_then16
  %rest = alloca ptr, align 8
  %curr24 = load ptr, ptr %curr, align 8
  %total25 = load i64, ptr %total, align 4
  %ptradd26 = getelementptr i8, ptr %curr24, i64 %total25
  store ptr %ptradd26, ptr %rest, align 8
  %curr_size27 = load i64, ptr %curr_size, align 4
  %total28 = load i64, ptr %total, align 4
  %sub29 = sub i64 %curr_size27, %total28
  %rest30 = load ptr, ptr %rest, align 8
  store i64 %sub29, ptr %rest30, align 4
  %curr_next31 = load i64, ptr %curr_next, align 4
  %rest32 = load ptr, ptr %rest, align 8
  %ptradd33 = getelementptr i8, ptr %rest32, i32 8
  store i64 %curr_next31, ptr %ptradd33, align 4
  %total34 = load i64, ptr %total, align 4
  %curr35 = load ptr, ptr %curr, align 8
  store i64 %total34, ptr %curr35, align 4
  %prev36 = load ptr, ptr %prev, align 8
  %icmpeq = icmp eq ptr %prev36, null
  br i1 %icmpeq, label %if_then37, label %if_else38

if_else:                                          ; preds = %if_then16
  %prev46 = load ptr, ptr %prev, align 8
  %icmpeq47 = icmp eq ptr %prev46, null
  br i1 %icmpeq47, label %if_then48, label %if_else49

if_merge23:                                       ; preds = %if_merge50, %if_merge39
  %curr57 = load ptr, ptr %curr, align 8
  %header58 = load i64, ptr %header, align 4
  %ptradd59 = getelementptr i8, ptr %curr57, i64 %header58
  ret ptr %ptradd59

if_then37:                                        ; preds = %if_then22
  %rest40 = load ptr, ptr %rest, align 8
  %selfload41 = load ptr, ptr %self.addr, align 8
  %fieldptr42 = getelementptr %free_list, ptr %selfload41, i32 0, i32 2
  store ptr %rest40, ptr %fieldptr42, align 8
  br label %if_merge39

if_else38:                                        ; preds = %if_then22
  %rest43 = load ptr, ptr %rest, align 8
  %ptrtoint = ptrtoint ptr %rest43 to i64
  %prev44 = load ptr, ptr %prev, align 8
  %ptradd45 = getelementptr i8, ptr %prev44, i32 8
  store i64 %ptrtoint, ptr %ptradd45, align 4
  br label %if_merge39

if_merge39:                                       ; preds = %if_else38, %if_then37
  br label %if_merge23

if_then48:                                        ; preds = %if_else
  %curr_next51 = load i64, ptr %curr_next, align 4
  %inttoptr = inttoptr i64 %curr_next51 to ptr
  %selfload52 = load ptr, ptr %self.addr, align 8
  %fieldptr53 = getelementptr %free_list, ptr %selfload52, i32 0, i32 2
  store ptr %inttoptr, ptr %fieldptr53, align 8
  br label %if_merge50

if_else49:                                        ; preds = %if_else
  %curr_next54 = load i64, ptr %curr_next, align 4
  %prev55 = load ptr, ptr %prev, align 8
  %ptradd56 = getelementptr i8, ptr %prev55, i32 8
  store i64 %curr_next54, ptr %ptradd56, align 4
  br label %if_merge50

if_merge50:                                       ; preds = %if_else49, %if_then48
  br label %if_merge23
}

define void @free_list__MT_free_ptr(ptr %0, ptr %1) {
entry:
  %self.addr = alloca ptr, align 8
  store ptr %0, ptr %self.addr, align 8
  %p = alloca ptr, align 8
  store ptr %1, ptr %p, align 8
  %p1 = load ptr, ptr %p, align 8
  %icmpeq = icmp eq ptr %p1, null
  br i1 %icmpeq, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret void

if_merge:                                         ; preds = %entry
  %h = alloca ptr, align 8
  %p2 = load ptr, ptr %p, align 8
  %ptradd = getelementptr i8, ptr %p2, i64 -16
  store ptr %ptradd, ptr %h, align 8
  %selfload = load ptr, ptr %self.addr, align 8
  %fieldptr = getelementptr %free_list, ptr %selfload, i32 0, i32 2
  %free_head = load ptr, ptr %fieldptr, align 8
  %ptrtoint = ptrtoint ptr %free_head to i64
  %h3 = load ptr, ptr %h, align 8
  %ptradd4 = getelementptr i8, ptr %h3, i32 8
  store i64 %ptrtoint, ptr %ptradd4, align 4
  %h5 = load ptr, ptr %h, align 8
  %selfload6 = load ptr, ptr %self.addr, align 8
  %fieldptr7 = getelementptr %free_list, ptr %selfload6, i32 0, i32 2
  store ptr %h5, ptr %fieldptr7, align 8
  %curr = alloca ptr, align 8
  %selfload8 = load ptr, ptr %self.addr, align 8
  %fieldptr9 = getelementptr %free_list, ptr %selfload8, i32 0, i32 2
  %free_head10 = load ptr, ptr %fieldptr9, align 8
  store ptr %free_head10, ptr %curr, align 8
  br label %while_cond

while_cond:                                       ; preds = %if_merge29, %if_merge
  %curr11 = load ptr, ptr %curr, align 8
  %icmpne = icmp ne ptr %curr11, null
  br i1 %icmpne, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %curr_size = alloca i64, align 8
  %curr12 = load ptr, ptr %curr, align 8
  %dereftmp = load i8, ptr %curr12, align 1
  %isext = sext i8 %dereftmp to i64
  store i64 %isext, ptr %curr_size, align 4
  %curr_next = alloca i64, align 8
  %curr13 = load ptr, ptr %curr, align 8
  %ptradd14 = getelementptr i8, ptr %curr13, i32 8
  %dereftmp15 = load i8, ptr %ptradd14, align 1
  %isext16 = sext i8 %dereftmp15 to i64
  store i64 %isext16, ptr %curr_next, align 4
  %curr_next17 = load i64, ptr %curr_next, align 4
  %icmpeq18 = icmp eq i64 %curr_next17, 0
  br i1 %icmpeq18, label %if_then19, label %if_merge20

while_exit:                                       ; preds = %if_then19, %while_cond
  ret void

if_then19:                                        ; preds = %while_body
  br label %while_exit

if_merge20:                                       ; preds = %while_body
  %next = alloca ptr, align 8
  %curr_next21 = load i64, ptr %curr_next, align 4
  %inttoptr = inttoptr i64 %curr_next21 to ptr
  store ptr %inttoptr, ptr %next, align 8
  %expected = alloca ptr, align 8
  %curr22 = load ptr, ptr %curr, align 8
  %curr_size23 = load i64, ptr %curr_size, align 4
  %ptradd24 = getelementptr i8, ptr %curr22, i64 %curr_size23
  store ptr %ptradd24, ptr %expected, align 8
  %expected25 = load ptr, ptr %expected, align 8
  %next26 = load ptr, ptr %next, align 8
  %icmpeq27 = icmp eq ptr %expected25, %next26
  br i1 %icmpeq27, label %if_then28, label %if_else

if_then28:                                        ; preds = %if_merge20
  %next_size = alloca i64, align 8
  %next30 = load ptr, ptr %next, align 8
  %dereftmp31 = load i8, ptr %next30, align 1
  %isext32 = sext i8 %dereftmp31 to i64
  store i64 %isext32, ptr %next_size, align 4
  %next_next = alloca i64, align 8
  %next33 = load ptr, ptr %next, align 8
  %ptradd34 = getelementptr i8, ptr %next33, i32 8
  %dereftmp35 = load i8, ptr %ptradd34, align 1
  %isext36 = sext i8 %dereftmp35 to i64
  store i64 %isext36, ptr %next_next, align 4
  %curr_size37 = load i64, ptr %curr_size, align 4
  %next_size38 = load i64, ptr %next_size, align 4
  %add = add i64 %curr_size37, %next_size38
  %curr39 = load ptr, ptr %curr, align 8
  store i64 %add, ptr %curr39, align 4
  %next_next40 = load i64, ptr %next_next, align 4
  %curr41 = load ptr, ptr %curr, align 8
  %ptradd42 = getelementptr i8, ptr %curr41, i32 8
  store i64 %next_next40, ptr %ptradd42, align 4
  br label %if_merge29

if_else:                                          ; preds = %if_merge20
  %next43 = load ptr, ptr %next, align 8
  store ptr %next43, ptr %curr, align 8
  br label %if_merge29

if_merge29:                                       ; preds = %if_else, %if_then28
  br label %while_cond
}

define void @free_list__MT_deinit(ptr %0) {
entry:
  %self.addr = alloca ptr, align 8
  store ptr %0, ptr %self.addr, align 8
  %selfload = load ptr, ptr %self.addr, align 8
  %fieldptr = getelementptr %free_list, ptr %selfload, i32 0, i32 0
  %base = load ptr, ptr %fieldptr, align 8
  call void @free(ptr %base)
  ret void
}

define i32 @main() {
entry:
  %fl = alloca %free_list, align 8
  store %free_list zeroinitializer, ptr %fl, align 8
  call void @free_list__MT___construct__(ptr %fl, i64 4096)
  %fieldptr = getelementptr %free_list, ptr %fl, i32 0, i32 0
  %base = load ptr, ptr %fieldptr, align 8
  %icmpeq = icmp eq ptr %base, null
  br i1 %icmpeq, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %a = alloca ptr, align 8
  %mtcall = call ptr @free_list__MT_alloc_bytes(ptr %fl, i64 64)
  store ptr %mtcall, ptr %a, align 8
  %a1 = load ptr, ptr %a, align 8
  %icmpeq2 = icmp eq ptr %a1, null
  br i1 %icmpeq2, label %if_then3, label %if_merge4

if_then3:                                         ; preds = %if_merge
  ret i32 2

if_merge4:                                        ; preds = %if_merge
  %b = alloca ptr, align 8
  %mtcall5 = call ptr @free_list__MT_alloc_bytes(ptr %fl, i64 128)
  store ptr %mtcall5, ptr %b, align 8
  %b6 = load ptr, ptr %b, align 8
  %icmpeq7 = icmp eq ptr %b6, null
  br i1 %icmpeq7, label %if_then8, label %if_merge9

if_then8:                                         ; preds = %if_merge4
  ret i32 3

if_merge9:                                        ; preds = %if_merge4
  %c = alloca ptr, align 8
  %mtcall10 = call ptr @free_list__MT_alloc_bytes(ptr %fl, i64 32)
  store ptr %mtcall10, ptr %c, align 8
  %c11 = load ptr, ptr %c, align 8
  %icmpeq12 = icmp eq ptr %c11, null
  br i1 %icmpeq12, label %if_then13, label %if_merge14

if_then13:                                        ; preds = %if_merge9
  ret i32 4

if_merge14:                                       ; preds = %if_merge9
  %a15 = load ptr, ptr %a, align 8
  %elemptr = getelementptr i32, ptr %a15, i32 0
  store i32 111, ptr %elemptr, align 4
  %b16 = load ptr, ptr %b, align 8
  %elemptr17 = getelementptr i32, ptr %b16, i32 0
  store i32 222, ptr %elemptr17, align 4
  %c18 = load ptr, ptr %c, align 8
  %elemptr19 = getelementptr i32, ptr %c18, i32 0
  store i32 333, ptr %elemptr19, align 4
  %a20 = load ptr, ptr %a, align 8
  %elemptr21 = getelementptr i32, ptr %a20, i32 0
  %elem = load i32, ptr %elemptr21, align 4
  %icmpne = icmp ne i32 %elem, 111
  br i1 %icmpne, label %if_then22, label %if_merge23

if_then22:                                        ; preds = %if_merge14
  ret i32 5

if_merge23:                                       ; preds = %if_merge14
  %b24 = load ptr, ptr %b, align 8
  %elemptr25 = getelementptr i32, ptr %b24, i32 0
  %elem26 = load i32, ptr %elemptr25, align 4
  %icmpne27 = icmp ne i32 %elem26, 222
  br i1 %icmpne27, label %if_then28, label %if_merge29

if_then28:                                        ; preds = %if_merge23
  ret i32 6

if_merge29:                                       ; preds = %if_merge23
  %c30 = load ptr, ptr %c, align 8
  %elemptr31 = getelementptr i32, ptr %c30, i32 0
  %elem32 = load i32, ptr %elemptr31, align 4
  %icmpne33 = icmp ne i32 %elem32, 333
  br i1 %icmpne33, label %if_then34, label %if_merge35

if_then34:                                        ; preds = %if_merge29
  ret i32 7

if_merge35:                                       ; preds = %if_merge29
  %b36 = load ptr, ptr %b, align 8
  call void @free_list__MT_free_ptr(ptr %fl, ptr %b36)
  %d = alloca ptr, align 8
  %mtcall37 = call ptr @free_list__MT_alloc_bytes(ptr %fl, i64 64)
  store ptr %mtcall37, ptr %d, align 8
  %d38 = load ptr, ptr %d, align 8
  %icmpeq39 = icmp eq ptr %d38, null
  br i1 %icmpeq39, label %if_then40, label %if_merge41

if_then40:                                        ; preds = %if_merge35
  ret i32 8

if_merge41:                                       ; preds = %if_merge35
  %d42 = load ptr, ptr %d, align 8
  %elemptr43 = getelementptr i32, ptr %d42, i32 0
  store i32 444, ptr %elemptr43, align 4
  %a44 = load ptr, ptr %a, align 8
  call void @free_list__MT_free_ptr(ptr %fl, ptr %a44)
  %c45 = load ptr, ptr %c, align 8
  call void @free_list__MT_free_ptr(ptr %fl, ptr %c45)
  %d46 = load ptr, ptr %d, align 8
  call void @free_list__MT_free_ptr(ptr %fl, ptr %d46)
  %e = alloca ptr, align 8
  %mtcall47 = call ptr @free_list__MT_alloc_bytes(ptr %fl, i64 512)
  store ptr %mtcall47, ptr %e, align 8
  %e48 = load ptr, ptr %e, align 8
  %icmpeq49 = icmp eq ptr %e48, null
  br i1 %icmpeq49, label %if_then50, label %if_merge51

if_then50:                                        ; preds = %if_merge41
  ret i32 9

if_merge51:                                       ; preds = %if_merge41
  call void @free_list__MT_deinit(ptr %fl)
  ret i32 0
}
