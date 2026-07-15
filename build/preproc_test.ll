; ModuleID = 'boot/compiler/preproc.arc'
source_filename = "boot/compiler/preproc.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%strbuf = type { ptr, i64, i64 }
%pp_table = type { [512 x ptr], [512 x ptr], i32 }
%pp_stack = type { [64 x i8], [64 x i8], [64 x i8], i32 }

define void @preproc__NS_strbuf_init(ptr %0) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %ptr_deref = load ptr, ptr %b, align 8
  %data = getelementptr inbounds nuw %strbuf, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %b, align 8
  %len = getelementptr inbounds nuw %strbuf, ptr %ptr_deref1, i32 0, i32 1
  store i64 0, ptr %len, align 4
  %ptr_deref2 = load ptr, ptr %b, align 8
  %cap = getelementptr inbounds nuw %strbuf, ptr %ptr_deref2, i32 0, i32 2
  store i64 1024, ptr %cap, align 4
  ret void
}

define void @preproc__NS_strbuf_ensure(ptr %0, i64 %1) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %extra = alloca i64, align 8
  store i64 %1, ptr %extra, align 4
  %ptr_deref = load ptr, ptr %b, align 8
  %len = getelementptr inbounds nuw %strbuf, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref1 = load ptr, ptr %b, align 8
  %mem_load = load i64, ptr %len, align 4
  %extra2 = load i64, ptr %extra, align 4
  %add = add i64 %mem_load, %extra2
  %ptr_deref3 = load ptr, ptr %b, align 8
  %cap = getelementptr inbounds nuw %strbuf, ptr %ptr_deref3, i32 0, i32 2
  %ptr_deref4 = load ptr, ptr %b, align 8
  %mem_load5 = load i64, ptr %cap, align 4
  %icmp = icmp slt i64 %add, %mem_load5
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret void

if_merge:                                         ; preds = %entry
  %nc = alloca i64, align 8
  %ptr_deref6 = load ptr, ptr %b, align 8
  %cap7 = getelementptr inbounds nuw %strbuf, ptr %ptr_deref6, i32 0, i32 2
  %ptr_deref8 = load ptr, ptr %b, align 8
  %mem_load9 = load i64, ptr %cap7, align 4
  %mul = mul i64 %mem_load9, 2
  %extra10 = load i64, ptr %extra, align 4
  %add11 = add i64 %mul, %extra10
  %add12 = add i64 %add11, 1
  store i64 %add12, ptr %nc, align 4
  %ptr_deref13 = load ptr, ptr %b, align 8
  %data = getelementptr inbounds nuw %strbuf, ptr %ptr_deref13, i32 0, i32 0
  %ptr_deref14 = load ptr, ptr %b, align 8
  %cap15 = getelementptr inbounds nuw %strbuf, ptr %ptr_deref14, i32 0, i32 2
  %nc16 = load i64, ptr %nc, align 4
  store i64 %nc16, ptr %cap15, align 4
  ret void
}

define void @preproc__NS_strbuf_push(ptr %0, i8 %1) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %c = alloca i8, align 1
  store i8 %1, ptr %c, align 1
  %b1 = load ptr, ptr %b, align 8
  call void @preproc__NS_strbuf_ensure(ptr %b1, i64 1)
  %ptr_deref = load ptr, ptr %b, align 8
  %data = getelementptr inbounds nuw %strbuf, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref2 = load ptr, ptr %b, align 8
  %len = getelementptr inbounds nuw %strbuf, ptr %ptr_deref2, i32 0, i32 1
  %ptr_deref3 = load ptr, ptr %b, align 8
  %mem_load = load i64, ptr %len, align 4
  %ptr_load = load ptr, ptr %data, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %mem_load
  %c4 = load i8, ptr %c, align 1
  %i2p = inttoptr i8 %c4 to ptr
  store ptr %i2p, ptr %ptr_gep, align 8
  %ptr_deref5 = load ptr, ptr %b, align 8
  %len6 = getelementptr inbounds nuw %strbuf, ptr %ptr_deref5, i32 0, i32 1
  %ptr_deref7 = load ptr, ptr %b, align 8
  %len8 = getelementptr inbounds nuw %strbuf, ptr %ptr_deref7, i32 0, i32 1
  %ptr_deref9 = load ptr, ptr %b, align 8
  %mem_load10 = load i64, ptr %len8, align 4
  %add = add i64 %mem_load10, 1
  store i64 %add, ptr %len6, align 4
  ret void
}

define void @preproc__NS_strbuf_append(ptr %0, ptr %1, i64 %2) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %s = alloca ptr, align 8
  store ptr %1, ptr %s, align 8
  %n = alloca i64, align 8
  store i64 %2, ptr %n, align 4
  %b1 = load ptr, ptr %b, align 8
  %n2 = load i64, ptr %n, align 4
  call void @preproc__NS_strbuf_ensure(ptr %b1, i64 %n2)
  %i = alloca i64, align 8
  store i64 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %i3 = load i64, ptr %i, align 4
  %n4 = load i64, ptr %n, align 4
  %icmp = icmp ult i64 %i3, %n4
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ptr_deref = load ptr, ptr %b, align 8
  %data = getelementptr inbounds nuw %strbuf, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref5 = load ptr, ptr %b, align 8
  %len = getelementptr inbounds nuw %strbuf, ptr %ptr_deref5, i32 0, i32 1
  %ptr_deref6 = load ptr, ptr %b, align 8
  %mem_load = load i64, ptr %len, align 4
  %i7 = load i64, ptr %i, align 4
  %add = add i64 %mem_load, %i7
  %ptr_load = load ptr, ptr %data, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %add
  %i8 = load i64, ptr %i, align 4
  %ptr_load9 = load ptr, ptr %s, align 8
  %ptr_gep10 = getelementptr i8, ptr %ptr_load9, i64 %i8
  %idx_load = load i8, ptr %ptr_gep10, align 1
  %i2p = inttoptr i8 %idx_load to ptr
  store ptr %i2p, ptr %ptr_gep, align 8
  %i11 = load i64, ptr %i, align 4
  %add12 = add i64 %i11, 1
  store i64 %add12, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %ptr_deref13 = load ptr, ptr %b, align 8
  %len14 = getelementptr inbounds nuw %strbuf, ptr %ptr_deref13, i32 0, i32 1
  %ptr_deref15 = load ptr, ptr %b, align 8
  %len16 = getelementptr inbounds nuw %strbuf, ptr %ptr_deref15, i32 0, i32 1
  %ptr_deref17 = load ptr, ptr %b, align 8
  %mem_load18 = load i64, ptr %len16, align 4
  %n19 = load i64, ptr %n, align 4
  %add20 = add i64 %mem_load18, %n19
  store i64 %add20, ptr %len14, align 4
  ret void
}

define void @preproc__NS_strbuf_append_cstr(ptr %0, ptr %1) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %s = alloca ptr, align 8
  store ptr %1, ptr %s, align 8
  %s1 = load ptr, ptr %s, align 8
  %icmp = icmp eq ptr %s1, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret void

if_merge:                                         ; preds = %entry
  %n = alloca i64, align 8
  store i64 0, ptr %n, align 4
  %b2 = load ptr, ptr %b, align 8
  %s3 = load ptr, ptr %s, align 8
  %n4 = load i64, ptr %n, align 4
  call void @preproc__NS_strbuf_append(ptr %b2, ptr %s3, i64 %n4)
  ret void
}

define ptr @preproc__NS_strbuf_finish(ptr %0) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %b1 = load ptr, ptr %b, align 8
  call void @preproc__NS_strbuf_ensure(ptr %b1, i64 1)
  %ptr_deref = load ptr, ptr %b, align 8
  %data = getelementptr inbounds nuw %strbuf, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref2 = load ptr, ptr %b, align 8
  %len = getelementptr inbounds nuw %strbuf, ptr %ptr_deref2, i32 0, i32 1
  %ptr_deref3 = load ptr, ptr %b, align 8
  %mem_load = load i64, ptr %len, align 4
  %ptr_load = load ptr, ptr %data, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %mem_load
  store ptr null, ptr %ptr_gep, align 8
  %ptr_deref4 = load ptr, ptr %b, align 8
  %data5 = getelementptr inbounds nuw %strbuf, ptr %ptr_deref4, i32 0, i32 0
  %ptr_deref6 = load ptr, ptr %b, align 8
  %mem_load7 = load ptr, ptr %data5, align 8
  ret ptr %mem_load7
}

define void @preproc__NS_pp_table_init(ptr %0) {
entry:
  %t = alloca ptr, align 8
  store ptr %0, ptr %t, align 8
  %ptr_deref = load ptr, ptr %t, align 8
  %count = getelementptr inbounds nuw %pp_table, ptr %ptr_deref, i32 0, i32 2
  store i32 0, ptr %count, align 4
  ret void
}

define i8 @preproc__NS_pp_defined(ptr %0, ptr %1) {
entry:
  %t = alloca ptr, align 8
  store ptr %0, ptr %t, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_deref = load ptr, ptr %t, align 8
  %count = getelementptr inbounds nuw %pp_table, ptr %ptr_deref, i32 0, i32 2
  %ptr_deref2 = load ptr, ptr %t, align 8
  %mem_load = load i32, ptr %count, align 4
  %icmp = icmp slt i32 %i1, %mem_load
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i3 = load i32, ptr %i, align 4
  %add = add i32 %i3, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  ret i8 0
}

define ptr @preproc__NS_pp_get(ptr %0, ptr %1) {
entry:
  %t = alloca ptr, align 8
  store ptr %0, ptr %t, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_deref = load ptr, ptr %t, align 8
  %count = getelementptr inbounds nuw %pp_table, ptr %ptr_deref, i32 0, i32 2
  %ptr_deref2 = load ptr, ptr %t, align 8
  %mem_load = load i32, ptr %count, align 4
  %icmp = icmp slt i32 %i1, %mem_load
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i3 = load i32, ptr %i, align 4
  %add = add i32 %i3, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  ret ptr null
}

define void @preproc__NS_pp_set(ptr %0, ptr %1, ptr %2) {
entry:
  %t = alloca ptr, align 8
  store ptr %0, ptr %t, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %value = alloca ptr, align 8
  store ptr %2, ptr %value, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_deref = load ptr, ptr %t, align 8
  %count = getelementptr inbounds nuw %pp_table, ptr %ptr_deref, i32 0, i32 2
  %ptr_deref2 = load ptr, ptr %t, align 8
  %mem_load = load i32, ptr %count, align 4
  %icmp = icmp slt i32 %i1, %mem_load
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i3 = load i32, ptr %i, align 4
  %add = add i32 %i3, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %ptr_deref4 = load ptr, ptr %t, align 8
  %count5 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref4, i32 0, i32 2
  %ptr_deref6 = load ptr, ptr %t, align 8
  %mem_load7 = load i32, ptr %count5, align 4
  %icmp8 = icmp slt i32 %mem_load7, 512
  br i1 %icmp8, label %if_then, label %if_merge

if_then:                                          ; preds = %while_exit
  %ptr_deref9 = load ptr, ptr %t, align 8
  %names = getelementptr inbounds nuw %pp_table, ptr %ptr_deref9, i32 0, i32 0
  %ptr_deref10 = load ptr, ptr %t, align 8
  %count11 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref10, i32 0, i32 2
  %ptr_deref12 = load ptr, ptr %t, align 8
  %mem_load13 = load i32, ptr %count11, align 4
  %arr_gep = getelementptr [512 x ptr], ptr %names, i64 0, i32 %mem_load13
  %name14 = load ptr, ptr %name, align 8
  store ptr %name14, ptr %arr_gep, align 8
  %ptr_deref15 = load ptr, ptr %t, align 8
  %values = getelementptr inbounds nuw %pp_table, ptr %ptr_deref15, i32 0, i32 1
  %ptr_deref16 = load ptr, ptr %t, align 8
  %count17 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref16, i32 0, i32 2
  %ptr_deref18 = load ptr, ptr %t, align 8
  %mem_load19 = load i32, ptr %count17, align 4
  %arr_gep20 = getelementptr [512 x ptr], ptr %values, i64 0, i32 %mem_load19
  %value21 = load ptr, ptr %value, align 8
  store ptr %value21, ptr %arr_gep20, align 8
  %ptr_deref22 = load ptr, ptr %t, align 8
  %count23 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref22, i32 0, i32 2
  %ptr_deref24 = load ptr, ptr %t, align 8
  %count25 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref24, i32 0, i32 2
  %ptr_deref26 = load ptr, ptr %t, align 8
  %mem_load27 = load i32, ptr %count25, align 4
  %add28 = add i32 %mem_load27, 1
  store i32 %add28, ptr %count23, align 4
  br label %if_merge

if_merge:                                         ; preds = %if_then, %while_exit
  ret void
}

define void @preproc__NS_pp_undef(ptr %0, ptr %1) {
entry:
  %t = alloca ptr, align 8
  store ptr %0, ptr %t, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_deref = load ptr, ptr %t, align 8
  %count = getelementptr inbounds nuw %pp_table, ptr %ptr_deref, i32 0, i32 2
  %ptr_deref2 = load ptr, ptr %t, align 8
  %mem_load = load i32, ptr %count, align 4
  %icmp = icmp slt i32 %i1, %mem_load
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i3 = load i32, ptr %i, align 4
  %add = add i32 %i3, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  ret void
}

define i8 @preproc__NS_pp_is_id_start(i8 %0) {
entry:
  %c = alloca i8, align 1
  store i8 %0, ptr %c, align 1
  %c1 = load i8, ptr %c, align 1
  %icmp = icmp sge i8 %c1, 97
  %c2 = load i8, ptr %c, align 1
  %icmp3 = icmp sle i8 %c2, 122
  %land = and i1 %icmp, %icmp3
  %c4 = load i8, ptr %c, align 1
  %icmp5 = icmp sge i8 %c4, 65
  %c6 = load i8, ptr %c, align 1
  %icmp7 = icmp sle i8 %c6, 90
  %land8 = and i1 %icmp5, %icmp7
  %lor = or i1 %land, %land8
  %c9 = load i8, ptr %c, align 1
  %icmp10 = icmp eq i8 %c9, 95
  %lor11 = or i1 %lor, %icmp10
  %zext = zext i1 %lor11 to i8
  ret i8 %zext
}

define i8 @preproc__NS_pp_is_id_cont(i8 %0) {
entry:
  %c = alloca i8, align 1
  store i8 %0, ptr %c, align 1
  %c1 = load i8, ptr %c, align 1
  %1 = call i8 @preproc__NS_pp_is_id_start(i8 %c1)
  %c2 = load i8, ptr %c, align 1
  %icmp = icmp sge i8 %c2, 48
  %c3 = load i8, ptr %c, align 1
  %icmp4 = icmp sle i8 %c3, 57
  %land = and i1 %icmp, %icmp4
  %zext = zext i1 %land to i8
  %tobool = icmp ne i8 %1, 0
  %tobool5 = icmp ne i8 %zext, 0
  %lor = or i1 %tobool, %tobool5
  %zext6 = zext i1 %lor to i8
  ret i8 %zext6
}

define ptr @preproc__NS_pp_substr_dup(ptr %0, i32 %1) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %len = alloca i32, align 4
  store i32 %1, ptr %len, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %i1 = load i32, ptr %i, align 4
  %len2 = load i32, ptr %len, align 4
  %icmp = icmp slt i32 %i1, %len2
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i3 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %r, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i3
  %i4 = load i32, ptr %i, align 4
  %ptr_load5 = load ptr, ptr %s, align 8
  %ptr_gep6 = getelementptr i8, ptr %ptr_load5, i32 %i4
  %idx_load = load i8, ptr %ptr_gep6, align 1
  store i8 %idx_load, ptr %ptr_gep, align 1
  %i7 = load i32, ptr %i, align 4
  %add = add i32 %i7, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %len8 = load i32, ptr %len, align 4
  %ptr_load9 = load ptr, ptr %r, align 8
  %ptr_gep10 = getelementptr i8, ptr %ptr_load9, i32 %len8
  store i8 0, ptr %ptr_gep10, align 1
  %r11 = load ptr, ptr %r, align 8
  ret ptr %r11
}

define ptr @preproc__NS_pp_extract_angle(ptr %0, ptr %1) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %out_len = alloca ptr, align 8
  store ptr %1, ptr %out_len, align 8
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %s1 = load ptr, ptr %s, align 8
  %deref = load i8, ptr %s1, align 1
  %icmp = icmp eq i8 %deref, 32
  %s2 = load ptr, ptr %s, align 8
  %deref3 = load i8, ptr %s2, align 1
  %icmp4 = icmp eq i8 %deref3, 9
  %lor = or i1 %icmp, %icmp4
  br i1 %lor, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %s5 = load ptr, ptr %s, align 8
  %ptr_add = getelementptr i8, ptr %s5, i64 1
  store ptr %ptr_add, ptr %s, align 8
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %s6 = load ptr, ptr %s, align 8
  %deref7 = load i8, ptr %s6, align 1
  %icmp8 = icmp ne i8 %deref7, 60
  br i1 %icmp8, label %if_then, label %if_merge

if_then:                                          ; preds = %while_exit
  %out_len9 = load ptr, ptr %out_len, align 8
  store i32 0, ptr %out_len9, align 4
  ret ptr null

if_merge:                                         ; preds = %while_exit
  %s10 = load ptr, ptr %s, align 8
  %ptr_add11 = getelementptr i8, ptr %s10, i64 1
  store ptr %ptr_add11, ptr %s, align 8
  %start = alloca ptr, align 8
  %s12 = load ptr, ptr %s, align 8
  store ptr %s12, ptr %start, align 8
  %depth = alloca i32, align 4
  store i32 1, ptr %depth, align 4
  %len = alloca i32, align 4
  store i32 0, ptr %len, align 4
  br label %while_cond13

while_cond13:                                     ; preds = %if_merge36, %if_merge
  %s16 = load ptr, ptr %s, align 8
  %deref17 = load i8, ptr %s16, align 1
  %icmp18 = icmp ne i8 %deref17, 0
  %depth19 = load i32, ptr %depth, align 4
  %icmp20 = icmp sgt i32 %depth19, 0
  %land = and i1 %icmp18, %icmp20
  br i1 %land, label %while_body14, label %while_exit15

while_body14:                                     ; preds = %while_cond13
  %s21 = load ptr, ptr %s, align 8
  %deref22 = load i8, ptr %s21, align 1
  %icmp23 = icmp eq i8 %deref22, 60
  br i1 %icmp23, label %if_then24, label %if_else

while_exit15:                                     ; preds = %while_cond13
  %out_len41 = load ptr, ptr %out_len, align 8
  %len42 = load i32, ptr %len, align 4
  store i32 %len42, ptr %out_len41, align 4
  %start43 = load ptr, ptr %start, align 8
  ret ptr %start43

if_then24:                                        ; preds = %while_body14
  %depth26 = load i32, ptr %depth, align 4
  %add = add i32 %depth26, 1
  store i32 %add, ptr %depth, align 4
  br label %if_merge25

if_else:                                          ; preds = %while_body14
  %s27 = load ptr, ptr %s, align 8
  %deref28 = load i8, ptr %s27, align 1
  %icmp29 = icmp eq i8 %deref28, 62
  br i1 %icmp29, label %if_then30, label %if_merge31

if_merge25:                                       ; preds = %if_merge31, %if_then24
  %depth33 = load i32, ptr %depth, align 4
  %icmp34 = icmp sgt i32 %depth33, 0
  br i1 %icmp34, label %if_then35, label %if_merge36

if_then30:                                        ; preds = %if_else
  %depth32 = load i32, ptr %depth, align 4
  %sub = sub i32 %depth32, 1
  store i32 %sub, ptr %depth, align 4
  br label %if_merge31

if_merge31:                                       ; preds = %if_then30, %if_else
  br label %if_merge25

if_then35:                                        ; preds = %if_merge25
  %len37 = load i32, ptr %len, align 4
  %add38 = add i32 %len37, 1
  store i32 %add38, ptr %len, align 4
  %s39 = load ptr, ptr %s, align 8
  %ptr_add40 = getelementptr i8, ptr %s39, i64 1
  store ptr %ptr_add40, ptr %s, align 8
  br label %if_merge36

if_merge36:                                       ; preds = %if_then35, %if_merge25
  br label %while_cond13
}

define void @preproc__NS_pp_apply(ptr %0, ptr %1, i32 %2, ptr %3) {
entry:
  %t = alloca ptr, align 8
  store ptr %0, ptr %t, align 8
  %line = alloca ptr, align 8
  store ptr %1, ptr %line, align 8
  %line_len = alloca i32, align 4
  store i32 %2, ptr %line_len, align 4
  %out = alloca ptr, align 8
  store ptr %3, ptr %out, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge81, %if_merge108, %if_merge50, %entry
  %i1 = load i32, ptr %i, align 4
  %line_len2 = load i32, ptr %line_len, align 4
  %icmp = icmp slt i32 %i1, %line_len2
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %c = alloca i8, align 1
  %i3 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %line, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i3
  %idx_load = load i8, ptr %ptr_gep, align 1
  store i8 %idx_load, ptr %c, align 1
  %c4 = load i8, ptr %c, align 1
  %icmp5 = icmp eq i8 %c4, 34
  br i1 %icmp5, label %if_then, label %if_merge

while_exit:                                       ; preds = %while_cond
  ret void

if_then:                                          ; preds = %while_body
  %out6 = load ptr, ptr %out, align 8
  %c7 = load i8, ptr %c, align 1
  call void @preproc__NS_strbuf_push(ptr %out6, i8 %c7)
  %i8 = load i32, ptr %i, align 4
  %add = add i32 %i8, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond9

if_merge:                                         ; preds = %while_body
  %c58 = load i8, ptr %c, align 1
  %icmp59 = icmp eq i8 %c58, 47
  %i60 = load i32, ptr %i, align 4
  %add61 = add i32 %i60, 1
  %line_len62 = load i32, ptr %line_len, align 4
  %icmp63 = icmp slt i32 %add61, %line_len62
  %land64 = and i1 %icmp59, %icmp63
  %i65 = load i32, ptr %i, align 4
  %add66 = add i32 %i65, 1
  %ptr_load67 = load ptr, ptr %line, align 8
  %ptr_gep68 = getelementptr i8, ptr %ptr_load67, i32 %add66
  %idx_load69 = load i8, ptr %ptr_gep68, align 1
  %icmp70 = icmp eq i8 %idx_load69, 47
  %land71 = and i1 %land64, %icmp70
  br i1 %land71, label %if_then72, label %if_merge73

while_cond9:                                      ; preds = %if_merge31, %if_then
  %i12 = load i32, ptr %i, align 4
  %line_len13 = load i32, ptr %line_len, align 4
  %icmp14 = icmp slt i32 %i12, %line_len13
  %i15 = load i32, ptr %i, align 4
  %ptr_load16 = load ptr, ptr %line, align 8
  %ptr_gep17 = getelementptr i8, ptr %ptr_load16, i32 %i15
  %idx_load18 = load i8, ptr %ptr_gep17, align 1
  %icmp19 = icmp ne i8 %idx_load18, 34
  %land = and i1 %icmp14, %icmp19
  br i1 %land, label %while_body10, label %while_exit11

while_body10:                                     ; preds = %while_cond9
  %i20 = load i32, ptr %i, align 4
  %ptr_load21 = load ptr, ptr %line, align 8
  %ptr_gep22 = getelementptr i8, ptr %ptr_load21, i32 %i20
  %idx_load23 = load i8, ptr %ptr_gep22, align 1
  %icmp24 = icmp eq i8 %idx_load23, 92
  %i25 = load i32, ptr %i, align 4
  %add26 = add i32 %i25, 1
  %line_len27 = load i32, ptr %line_len, align 4
  %icmp28 = icmp slt i32 %add26, %line_len27
  %land29 = and i1 %icmp24, %icmp28
  br i1 %land29, label %if_then30, label %if_merge31

while_exit11:                                     ; preds = %while_cond9
  %i46 = load i32, ptr %i, align 4
  %line_len47 = load i32, ptr %line_len, align 4
  %icmp48 = icmp slt i32 %i46, %line_len47
  br i1 %icmp48, label %if_then49, label %if_merge50

if_then30:                                        ; preds = %while_body10
  %out32 = load ptr, ptr %out, align 8
  %i33 = load i32, ptr %i, align 4
  %ptr_load34 = load ptr, ptr %line, align 8
  %ptr_gep35 = getelementptr i8, ptr %ptr_load34, i32 %i33
  %idx_load36 = load i8, ptr %ptr_gep35, align 1
  call void @preproc__NS_strbuf_push(ptr %out32, i8 %idx_load36)
  %i37 = load i32, ptr %i, align 4
  %add38 = add i32 %i37, 1
  store i32 %add38, ptr %i, align 4
  br label %if_merge31

if_merge31:                                       ; preds = %if_then30, %while_body10
  %out39 = load ptr, ptr %out, align 8
  %i40 = load i32, ptr %i, align 4
  %ptr_load41 = load ptr, ptr %line, align 8
  %ptr_gep42 = getelementptr i8, ptr %ptr_load41, i32 %i40
  %idx_load43 = load i8, ptr %ptr_gep42, align 1
  call void @preproc__NS_strbuf_push(ptr %out39, i8 %idx_load43)
  %i44 = load i32, ptr %i, align 4
  %add45 = add i32 %i44, 1
  store i32 %add45, ptr %i, align 4
  br label %while_cond9

if_then49:                                        ; preds = %while_exit11
  %out51 = load ptr, ptr %out, align 8
  %i52 = load i32, ptr %i, align 4
  %ptr_load53 = load ptr, ptr %line, align 8
  %ptr_gep54 = getelementptr i8, ptr %ptr_load53, i32 %i52
  %idx_load55 = load i8, ptr %ptr_gep54, align 1
  call void @preproc__NS_strbuf_push(ptr %out51, i8 %idx_load55)
  %i56 = load i32, ptr %i, align 4
  %add57 = add i32 %i56, 1
  store i32 %add57, ptr %i, align 4
  br label %if_merge50

if_merge50:                                       ; preds = %if_then49, %while_exit11
  br label %while_cond

if_then72:                                        ; preds = %if_merge
  %out74 = load ptr, ptr %out, align 8
  %line75 = load ptr, ptr %line, align 8
  %i76 = load i32, ptr %i, align 4
  %ptr_add = getelementptr i8, ptr %line75, i32 %i76
  %line_len77 = load i32, ptr %line_len, align 4
  %i78 = load i32, ptr %i, align 4
  %sub = sub i32 %line_len77, %i78
  %zext = zext i32 %sub to i64
  call void @preproc__NS_strbuf_append(ptr %out74, ptr %ptr_add, i64 %zext)
  ret void

if_merge73:                                       ; preds = %if_merge
  %c79 = load i8, ptr %c, align 1
  %4 = call i8 @preproc__NS_pp_is_id_start(i8 %c79)
  %if_cond = icmp ne i8 %4, 0
  br i1 %if_cond, label %if_then80, label %if_merge81

if_then80:                                        ; preds = %if_merge73
  %j = alloca i32, align 4
  %i82 = load i32, ptr %i, align 4
  %add83 = add i32 %i82, 1
  store i32 %add83, ptr %j, align 4
  br label %while_cond84

if_merge81:                                       ; preds = %if_merge73
  %out120 = load ptr, ptr %out, align 8
  %c121 = load i8, ptr %c, align 1
  call void @preproc__NS_strbuf_push(ptr %out120, i8 %c121)
  %i122 = load i32, ptr %i, align 4
  %add123 = add i32 %i122, 1
  store i32 %add123, ptr %i, align 4
  br label %while_cond

while_cond84:                                     ; preds = %while_body85, %if_then80
  %j87 = load i32, ptr %j, align 4
  %line_len88 = load i32, ptr %line_len, align 4
  %icmp89 = icmp slt i32 %j87, %line_len88
  %j90 = load i32, ptr %j, align 4
  %ptr_load91 = load ptr, ptr %line, align 8
  %ptr_gep92 = getelementptr i8, ptr %ptr_load91, i32 %j90
  %idx_load93 = load i8, ptr %ptr_gep92, align 1
  %5 = call i8 @preproc__NS_pp_is_id_cont(i8 %idx_load93)
  %trunc = trunc i8 %5 to i1
  %land94 = and i1 %icmp89, %trunc
  br i1 %land94, label %while_body85, label %while_exit86

while_body85:                                     ; preds = %while_cond84
  %j95 = load i32, ptr %j, align 4
  %add96 = add i32 %j95, 1
  store i32 %add96, ptr %j, align 4
  br label %while_cond84

while_exit86:                                     ; preds = %while_cond84
  %id = alloca ptr, align 8
  %line97 = load ptr, ptr %line, align 8
  %i98 = load i32, ptr %i, align 4
  %ptr_add99 = getelementptr i8, ptr %line97, i32 %i98
  %j100 = load i32, ptr %j, align 4
  %i101 = load i32, ptr %i, align 4
  %sub102 = sub i32 %j100, %i101
  %6 = call ptr @preproc__NS_pp_substr_dup(ptr %ptr_add99, i32 %sub102)
  store ptr %6, ptr %id, align 8
  %repl = alloca ptr, align 8
  %t103 = load ptr, ptr %t, align 8
  %id104 = load ptr, ptr %id, align 8
  %7 = call ptr @preproc__NS_pp_get(ptr %t103, ptr %id104)
  store ptr %7, ptr %repl, align 8
  %repl105 = load ptr, ptr %repl, align 8
  %icmp106 = icmp ne ptr %repl105, null
  br i1 %icmp106, label %if_then107, label %if_else

if_then107:                                       ; preds = %while_exit86
  %out109 = load ptr, ptr %out, align 8
  %repl110 = load ptr, ptr %repl, align 8
  call void @preproc__NS_strbuf_append_cstr(ptr %out109, ptr %repl110)
  br label %if_merge108

if_else:                                          ; preds = %while_exit86
  %out111 = load ptr, ptr %out, align 8
  %line112 = load ptr, ptr %line, align 8
  %i113 = load i32, ptr %i, align 4
  %ptr_add114 = getelementptr i8, ptr %line112, i32 %i113
  %j115 = load i32, ptr %j, align 4
  %i116 = load i32, ptr %i, align 4
  %sub117 = sub i32 %j115, %i116
  %zext118 = zext i32 %sub117 to i64
  call void @preproc__NS_strbuf_append(ptr %out111, ptr %ptr_add114, i64 %zext118)
  br label %if_merge108

if_merge108:                                      ; preds = %if_else, %if_then107
  %j119 = load i32, ptr %j, align 4
  store i32 %j119, ptr %i, align 4
  br label %while_cond
}

define void @preproc__NS_pp_stack_init(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %ptr_deref = load ptr, ptr %s, align 8
  %depth = getelementptr inbounds nuw %pp_stack, ptr %ptr_deref, i32 0, i32 3
  store i32 0, ptr %depth, align 4
  ret void
}

define i8 @preproc__NS_pp_all_active(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_deref = load ptr, ptr %s, align 8
  %depth = getelementptr inbounds nuw %pp_stack, ptr %ptr_deref, i32 0, i32 3
  %ptr_deref2 = load ptr, ptr %s, align 8
  %mem_load = load i32, ptr %depth, align 4
  %icmp = icmp slt i32 %i1, %mem_load
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ptr_deref3 = load ptr, ptr %s, align 8
  %active = getelementptr inbounds nuw %pp_stack, ptr %ptr_deref3, i32 0, i32 0
  %i4 = load i32, ptr %i, align 4
  %arr_gep = getelementptr [64 x i8], ptr %active, i64 0, i32 %i4
  %idx_load = load i8, ptr %arr_gep, align 1
  %tobool = icmp ne i8 %idx_load, 0
  %not = xor i1 %tobool, true
  br i1 %not, label %if_then, label %if_merge

while_exit:                                       ; preds = %while_cond
  ret i8 1

if_then:                                          ; preds = %while_body
  ret i8 0

if_merge:                                         ; preds = %while_body
  %i5 = load i32, ptr %i, align 4
  %add = add i32 %i5, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond
}

define i8 @preproc__NS_pp_parents_active(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_deref = load ptr, ptr %s, align 8
  %depth = getelementptr inbounds nuw %pp_stack, ptr %ptr_deref, i32 0, i32 3
  %ptr_deref2 = load ptr, ptr %s, align 8
  %mem_load = load i32, ptr %depth, align 4
  %sub = sub i32 %mem_load, 1
  %icmp = icmp slt i32 %i1, %sub
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ptr_deref3 = load ptr, ptr %s, align 8
  %active = getelementptr inbounds nuw %pp_stack, ptr %ptr_deref3, i32 0, i32 0
  %i4 = load i32, ptr %i, align 4
  %arr_gep = getelementptr [64 x i8], ptr %active, i64 0, i32 %i4
  %idx_load = load i8, ptr %arr_gep, align 1
  %tobool = icmp ne i8 %idx_load, 0
  %not = xor i1 %tobool, true
  br i1 %not, label %if_then, label %if_merge

while_exit:                                       ; preds = %while_cond
  ret i8 1

if_then:                                          ; preds = %while_body
  ret i8 0

if_merge:                                         ; preds = %while_body
  %i5 = load i32, ptr %i, align 4
  %add = add i32 %i5, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond
}

define ptr @preproc__NS_pp_read_file(ptr %0) {
entry:
  %path = alloca ptr, align 8
  store ptr %0, ptr %path, align 8
  %fp = alloca ptr, align 8
  store ptr null, ptr %fp, align 8
  %fp1 = load ptr, ptr %fp, align 8
  %icmp = icmp eq ptr %fp1, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret ptr null

if_merge:                                         ; preds = %entry
  %sz = alloca i64, align 8
  store i64 0, ptr %sz, align 4
  %sz2 = load i64, ptr %sz, align 4
  %icmp3 = icmp slt i64 %sz2, 0
  br i1 %icmp3, label %if_then4, label %if_merge5

if_then4:                                         ; preds = %if_merge
  ret ptr null

if_merge5:                                        ; preds = %if_merge
  %buf = alloca ptr, align 8
  store ptr null, ptr %buf, align 8
  %n = alloca i64, align 8
  store i64 0, ptr %n, align 4
  %n6 = load i64, ptr %n, align 4
  %ptr_load = load ptr, ptr %buf, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %n6
  store i8 0, ptr %ptr_gep, align 1
  %buf7 = load ptr, ptr %buf, align 8
  ret ptr %buf7
}

define ptr @preproc__NS_preprocess_inner(ptr %0, ptr %1, ptr %2) {
entry:
  %src = alloca ptr, align 8
  store ptr %0, ptr %src, align 8
  %base_dir = alloca ptr, align 8
  store ptr %1, ptr %base_dir, align 8
  %macros = alloca ptr, align 8
  store ptr %2, ptr %macros, align 8
  %out = alloca %strbuf, align 8
  store %strbuf zeroinitializer, ptr %out, align 8
  %cs = alloca %pp_stack, align 8
  store %pp_stack zeroinitializer, ptr %cs, align 4
  call void @preproc__NS_strbuf_init(ptr %out)
  call void @preproc__NS_pp_stack_init(ptr %cs)
  %pos = alloca i32, align 4
  store i32 0, ptr %pos, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge73, %entry
  %pos1 = load i32, ptr %pos, align 4
  %ptr_load = load ptr, ptr %src, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %pos1
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp ne i8 %idx_load, 0
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %line_start = alloca i32, align 4
  %pos2 = load i32, ptr %pos, align 4
  store i32 %pos2, ptr %line_start, align 4
  br label %while_cond3

while_exit:                                       ; preds = %while_cond
  %3 = call ptr @preproc__NS_strbuf_finish(ptr %out)
  ret ptr %3

while_cond3:                                      ; preds = %while_body4, %while_body
  %pos6 = load i32, ptr %pos, align 4
  %ptr_load7 = load ptr, ptr %src, align 8
  %ptr_gep8 = getelementptr i8, ptr %ptr_load7, i32 %pos6
  %idx_load9 = load i8, ptr %ptr_gep8, align 1
  %icmp10 = icmp ne i8 %idx_load9, 0
  %pos11 = load i32, ptr %pos, align 4
  %ptr_load12 = load ptr, ptr %src, align 8
  %ptr_gep13 = getelementptr i8, ptr %ptr_load12, i32 %pos11
  %idx_load14 = load i8, ptr %ptr_gep13, align 1
  %icmp15 = icmp ne i8 %idx_load14, 10
  %land = and i1 %icmp10, %icmp15
  br i1 %land, label %while_body4, label %while_exit5

while_body4:                                      ; preds = %while_cond3
  %pos16 = load i32, ptr %pos, align 4
  %add = add i32 %pos16, 1
  store i32 %add, ptr %pos, align 4
  br label %while_cond3

while_exit5:                                      ; preds = %while_cond3
  %line_end = alloca i32, align 4
  %pos17 = load i32, ptr %pos, align 4
  store i32 %pos17, ptr %line_end, align 4
  %pos18 = load i32, ptr %pos, align 4
  %ptr_load19 = load ptr, ptr %src, align 8
  %ptr_gep20 = getelementptr i8, ptr %ptr_load19, i32 %pos18
  %idx_load21 = load i8, ptr %ptr_gep20, align 1
  %icmp22 = icmp eq i8 %idx_load21, 10
  br i1 %icmp22, label %if_then, label %if_merge

if_then:                                          ; preds = %while_exit5
  %pos23 = load i32, ptr %pos, align 4
  %add24 = add i32 %pos23, 1
  store i32 %add24, ptr %pos, align 4
  br label %if_merge

if_merge:                                         ; preds = %if_then, %while_exit5
  %line_end25 = load i32, ptr %line_end, align 4
  %line_start26 = load i32, ptr %line_start, align 4
  %icmp27 = icmp sgt i32 %line_end25, %line_start26
  %line_end28 = load i32, ptr %line_end, align 4
  %sub = sub i32 %line_end28, 1
  %ptr_load29 = load ptr, ptr %src, align 8
  %ptr_gep30 = getelementptr i8, ptr %ptr_load29, i32 %sub
  %idx_load31 = load i8, ptr %ptr_gep30, align 1
  %icmp32 = icmp eq i8 %idx_load31, 13
  %land33 = and i1 %icmp27, %icmp32
  br i1 %land33, label %if_then34, label %if_merge35

if_then34:                                        ; preds = %if_merge
  %line_end36 = load i32, ptr %line_end, align 4
  %sub37 = sub i32 %line_end36, 1
  store i32 %sub37, ptr %line_end, align 4
  br label %if_merge35

if_merge35:                                       ; preds = %if_then34, %if_merge
  %line = alloca ptr, align 8
  %src38 = load ptr, ptr %src, align 8
  %line_start39 = load i32, ptr %line_start, align 4
  %ptr_add = getelementptr i8, ptr %src38, i32 %line_start39
  store ptr %ptr_add, ptr %line, align 8
  %line_len = alloca i32, align 4
  %line_end40 = load i32, ptr %line_end, align 4
  %line_start41 = load i32, ptr %line_start, align 4
  %sub42 = sub i32 %line_end40, %line_start41
  store i32 %sub42, ptr %line_len, align 4
  %ind = alloca i32, align 4
  store i32 0, ptr %ind, align 4
  br label %while_cond43

while_cond43:                                     ; preds = %while_body44, %if_merge35
  %ind46 = load i32, ptr %ind, align 4
  %line_len47 = load i32, ptr %line_len, align 4
  %icmp48 = icmp slt i32 %ind46, %line_len47
  %ind49 = load i32, ptr %ind, align 4
  %ptr_load50 = load ptr, ptr %line, align 8
  %ptr_gep51 = getelementptr i8, ptr %ptr_load50, i32 %ind49
  %idx_load52 = load i8, ptr %ptr_gep51, align 1
  %icmp53 = icmp eq i8 %idx_load52, 32
  %ind54 = load i32, ptr %ind, align 4
  %ptr_load55 = load ptr, ptr %line, align 8
  %ptr_gep56 = getelementptr i8, ptr %ptr_load55, i32 %ind54
  %idx_load57 = load i8, ptr %ptr_gep56, align 1
  %icmp58 = icmp eq i8 %idx_load57, 9
  %lor = or i1 %icmp53, %icmp58
  %land59 = and i1 %icmp48, %lor
  br i1 %land59, label %while_body44, label %while_exit45

while_body44:                                     ; preds = %while_cond43
  %ind60 = load i32, ptr %ind, align 4
  %add61 = add i32 %ind60, 1
  store i32 %add61, ptr %ind, align 4
  br label %while_cond43

while_exit45:                                     ; preds = %while_cond43
  %is_dir = alloca i8, align 1
  %ind62 = load i32, ptr %ind, align 4
  %line_len63 = load i32, ptr %line_len, align 4
  %icmp64 = icmp slt i32 %ind62, %line_len63
  %ind65 = load i32, ptr %ind, align 4
  %ptr_load66 = load ptr, ptr %line, align 8
  %ptr_gep67 = getelementptr i8, ptr %ptr_load66, i32 %ind65
  %idx_load68 = load i8, ptr %ptr_gep67, align 1
  %icmp69 = icmp eq i8 %idx_load68, 64
  %land70 = and i1 %icmp64, %icmp69
  %zext = zext i1 %land70 to i8
  store i8 %zext, ptr %is_dir, align 1
  %is_dir71 = load i8, ptr %is_dir, align 1
  %if_cond = icmp ne i8 %is_dir71, 0
  br i1 %if_cond, label %if_then72, label %if_else

if_then72:                                        ; preds = %while_exit45
  %ks = alloca i32, align 4
  %ind74 = load i32, ptr %ind, align 4
  %add75 = add i32 %ind74, 1
  store i32 %add75, ptr %ks, align 4
  %ke = alloca i32, align 4
  %ks76 = load i32, ptr %ks, align 4
  store i32 %ks76, ptr %ke, align 4
  br label %while_cond77

if_else:                                          ; preds = %while_exit45
  %4 = call i8 @preproc__NS_pp_all_active(ptr %cs)
  %if_cond110 = icmp ne i8 %4, 0
  br i1 %if_cond110, label %if_then111, label %if_merge112

if_merge73:                                       ; preds = %if_merge112, %while_exit101
  br label %while_cond

while_cond77:                                     ; preds = %while_body78, %if_then72
  %ke80 = load i32, ptr %ke, align 4
  %line_len81 = load i32, ptr %line_len, align 4
  %icmp82 = icmp slt i32 %ke80, %line_len81
  %ke83 = load i32, ptr %ke, align 4
  %ptr_load84 = load ptr, ptr %line, align 8
  %ptr_gep85 = getelementptr i8, ptr %ptr_load84, i32 %ke83
  %idx_load86 = load i8, ptr %ptr_gep85, align 1
  %5 = call i8 @preproc__NS_pp_is_id_cont(i8 %idx_load86)
  %trunc = trunc i8 %5 to i1
  %land87 = and i1 %icmp82, %trunc
  br i1 %land87, label %while_body78, label %while_exit79

while_body78:                                     ; preds = %while_cond77
  %ke88 = load i32, ptr %ke, align 4
  %add89 = add i32 %ke88, 1
  store i32 %add89, ptr %ke, align 4
  br label %while_cond77

while_exit79:                                     ; preds = %while_cond77
  %kw = alloca ptr, align 8
  %line90 = load ptr, ptr %line, align 8
  %ks91 = load i32, ptr %ks, align 4
  %ptr_add92 = getelementptr i8, ptr %line90, i32 %ks91
  %ke93 = load i32, ptr %ke, align 4
  %ks94 = load i32, ptr %ks, align 4
  %sub95 = sub i32 %ke93, %ks94
  %6 = call ptr @preproc__NS_pp_substr_dup(ptr %ptr_add92, i32 %sub95)
  store ptr %6, ptr %kw, align 8
  %rest = alloca ptr, align 8
  %line96 = load ptr, ptr %line, align 8
  %ke97 = load i32, ptr %ke, align 4
  %ptr_add98 = getelementptr i8, ptr %line96, i32 %ke97
  store ptr %ptr_add98, ptr %rest, align 8
  br label %while_cond99

while_cond99:                                     ; preds = %while_body100, %while_exit79
  %rest102 = load ptr, ptr %rest, align 8
  %deref = load i8, ptr %rest102, align 1
  %icmp103 = icmp eq i8 %deref, 32
  %rest104 = load ptr, ptr %rest, align 8
  %deref105 = load i8, ptr %rest104, align 1
  %icmp106 = icmp eq i8 %deref105, 9
  %lor107 = or i1 %icmp103, %icmp106
  br i1 %lor107, label %while_body100, label %while_exit101

while_body100:                                    ; preds = %while_cond99
  %rest108 = load ptr, ptr %rest, align 8
  %ptr_add109 = getelementptr i8, ptr %rest108, i64 1
  store ptr %ptr_add109, ptr %rest, align 8
  br label %while_cond99

while_exit101:                                    ; preds = %while_cond99
  call void @preproc__NS_strbuf_push(ptr %out, i8 10)
  br label %if_merge73

if_then111:                                       ; preds = %if_else
  %macros113 = load ptr, ptr %macros, align 8
  %line114 = load ptr, ptr %line, align 8
  %line_len115 = load i32, ptr %line_len, align 4
  call void @preproc__NS_pp_apply(ptr %macros113, ptr %line114, i32 %line_len115, ptr %out)
  br label %if_merge112

if_merge112:                                      ; preds = %if_then111, %if_else
  call void @preproc__NS_strbuf_push(ptr %out, i8 10)
  br label %if_merge73
}

define ptr @preproc__NS_preprocess(ptr %0, ptr %1) {
entry:
  %src = alloca ptr, align 8
  store ptr %0, ptr %src, align 8
  %src_path = alloca ptr, align 8
  store ptr %1, ptr %src_path, align 8
  %macros = alloca %pp_table, align 8
  store %pp_table zeroinitializer, ptr %macros, align 8
  call void @preproc__NS_pp_table_init(ptr %macros)
  %base_dir = alloca [2048 x i8], align 1
  store [2048 x i8] zeroinitializer, ptr %base_dir, align 1
  %arr_gep = getelementptr [2048 x i8], ptr %base_dir, i64 0, i64 0
  store i8 0, ptr %arr_gep, align 1
  %src_path1 = load ptr, ptr %src_path, align 8
  %icmp = icmp ne ptr %src_path1, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  %last_sep = alloca i32, align 4
  store i32 -1, ptr %last_sep, align 4
  br label %while_cond

if_merge:                                         ; preds = %if_merge21, %entry
  %bd = alloca ptr, align 8
  %arr_gep40 = getelementptr [2048 x i8], ptr %base_dir, i64 0, i64 0
  %idx_load41 = load i8, ptr %arr_gep40, align 1
  %icmp42 = icmp ne i8 %idx_load41, 0
  br i1 %icmp42, label %tern_then, label %tern_else

while_cond:                                       ; preds = %if_merge15, %if_then
  %i2 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %src_path, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i2
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp3 = icmp ne i8 %idx_load, 0
  br i1 %icmp3, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i4 = load i32, ptr %i, align 4
  %ptr_load5 = load ptr, ptr %src_path, align 8
  %ptr_gep6 = getelementptr i8, ptr %ptr_load5, i32 %i4
  %idx_load7 = load i8, ptr %ptr_gep6, align 1
  %icmp8 = icmp eq i8 %idx_load7, 47
  %i9 = load i32, ptr %i, align 4
  %ptr_load10 = load ptr, ptr %src_path, align 8
  %ptr_gep11 = getelementptr i8, ptr %ptr_load10, i32 %i9
  %idx_load12 = load i8, ptr %ptr_gep11, align 1
  %icmp13 = icmp eq i8 %idx_load12, 92
  %lor = or i1 %icmp8, %icmp13
  br i1 %lor, label %if_then14, label %if_merge15

while_exit:                                       ; preds = %while_cond
  %last_sep18 = load i32, ptr %last_sep, align 4
  %icmp19 = icmp sge i32 %last_sep18, 0
  br i1 %icmp19, label %if_then20, label %if_else

if_then14:                                        ; preds = %while_body
  %i16 = load i32, ptr %i, align 4
  store i32 %i16, ptr %last_sep, align 4
  br label %if_merge15

if_merge15:                                       ; preds = %if_then14, %while_body
  %i17 = load i32, ptr %i, align 4
  %add = add i32 %i17, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond

if_then20:                                        ; preds = %while_exit
  %j = alloca i32, align 4
  store i32 0, ptr %j, align 4
  br label %while_cond22

if_else:                                          ; preds = %while_exit
  %arr_gep38 = getelementptr [2048 x i8], ptr %base_dir, i64 0, i64 0
  store i8 46, ptr %arr_gep38, align 1
  %arr_gep39 = getelementptr [2048 x i8], ptr %base_dir, i64 0, i64 1
  store i8 0, ptr %arr_gep39, align 1
  br label %if_merge21

if_merge21:                                       ; preds = %if_else, %while_exit24
  br label %if_merge

while_cond22:                                     ; preds = %while_body23, %if_then20
  %j25 = load i32, ptr %j, align 4
  %last_sep26 = load i32, ptr %last_sep, align 4
  %icmp27 = icmp slt i32 %j25, %last_sep26
  br i1 %icmp27, label %while_body23, label %while_exit24

while_body23:                                     ; preds = %while_cond22
  %j28 = load i32, ptr %j, align 4
  %arr_gep29 = getelementptr [2048 x i8], ptr %base_dir, i64 0, i32 %j28
  %j30 = load i32, ptr %j, align 4
  %ptr_load31 = load ptr, ptr %src_path, align 8
  %ptr_gep32 = getelementptr i8, ptr %ptr_load31, i32 %j30
  %idx_load33 = load i8, ptr %ptr_gep32, align 1
  store i8 %idx_load33, ptr %arr_gep29, align 1
  %j34 = load i32, ptr %j, align 4
  %add35 = add i32 %j34, 1
  store i32 %add35, ptr %j, align 4
  br label %while_cond22

while_exit24:                                     ; preds = %while_cond22
  %last_sep36 = load i32, ptr %last_sep, align 4
  %arr_gep37 = getelementptr [2048 x i8], ptr %base_dir, i64 0, i32 %last_sep36
  store i8 0, ptr %arr_gep37, align 1
  br label %if_merge21

tern_then:                                        ; preds = %if_merge
  %arr_decay = getelementptr [2048 x i8], ptr %base_dir, i64 0, i64 0
  br label %tern_merge

tern_else:                                        ; preds = %if_merge
  br label %tern_merge

tern_merge:                                       ; preds = %tern_else, %tern_then
  %tern = phi ptr [ %arr_decay, %tern_then ], [ null, %tern_else ]
  store ptr %tern, ptr %bd, align 8
  %src43 = load ptr, ptr %src, align 8
  %bd44 = load ptr, ptr %bd, align 8
  %2 = call ptr @preproc__NS_preprocess_inner(ptr %src43, ptr %bd44, ptr %macros)
  ret ptr %2
}
