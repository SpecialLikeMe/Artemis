; ModuleID = 'tcon/test/100_kitchen_sink.arc'
source_filename = "tcon/test/100_kitchen_sink.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%Stack = type { [16 x i32], i32 }

@OpCode__Push = internal constant i32 0
@OpCode__Pop = internal constant i32 1

define void @stack_init(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %ptr_deref = load ptr, ptr %s, align 8
  %top = getelementptr inbounds nuw %Stack, ptr %ptr_deref, i32 0, i32 1
  store i32 0, ptr %top, align 4
  ret void
}

define void @stack_push(ptr %0, i32 %1) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %v = alloca i32, align 4
  store i32 %1, ptr %v, align 4
  %ptr_deref = load ptr, ptr %s, align 8
  %top = getelementptr inbounds nuw %Stack, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref1 = load ptr, ptr %s, align 8
  %mem_load = load i32, ptr %top, align 4
  %icmp = icmp slt i32 %mem_load, 16
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %ptr_deref2 = load ptr, ptr %s, align 8
  %data = getelementptr inbounds nuw %Stack, ptr %ptr_deref2, i32 0, i32 0
  %ptr_deref3 = load ptr, ptr %s, align 8
  %top4 = getelementptr inbounds nuw %Stack, ptr %ptr_deref3, i32 0, i32 1
  %ptr_deref5 = load ptr, ptr %s, align 8
  %mem_load6 = load i32, ptr %top4, align 4
  %arr_gep = getelementptr [16 x i32], ptr %data, i64 0, i32 %mem_load6
  %v7 = load i32, ptr %v, align 4
  store i32 %v7, ptr %arr_gep, align 4
  %ptr_deref8 = load ptr, ptr %s, align 8
  %top9 = getelementptr inbounds nuw %Stack, ptr %ptr_deref8, i32 0, i32 1
  %ptr_deref10 = load ptr, ptr %s, align 8
  %top11 = getelementptr inbounds nuw %Stack, ptr %ptr_deref10, i32 0, i32 1
  %ptr_deref12 = load ptr, ptr %s, align 8
  %mem_load13 = load i32, ptr %top11, align 4
  %add = add i32 %mem_load13, 1
  store i32 %add, ptr %top9, align 4
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  ret void
}

define i32 @stack_pop(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %ptr_deref = load ptr, ptr %s, align 8
  %top = getelementptr inbounds nuw %Stack, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref1 = load ptr, ptr %s, align 8
  %mem_load = load i32, ptr %top, align 4
  %icmp = icmp eq i32 %mem_load, 0
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 -1

if_merge:                                         ; preds = %entry
  %ptr_deref2 = load ptr, ptr %s, align 8
  %top3 = getelementptr inbounds nuw %Stack, ptr %ptr_deref2, i32 0, i32 1
  %ptr_deref4 = load ptr, ptr %s, align 8
  %top5 = getelementptr inbounds nuw %Stack, ptr %ptr_deref4, i32 0, i32 1
  %ptr_deref6 = load ptr, ptr %s, align 8
  %mem_load7 = load i32, ptr %top5, align 4
  %sub = sub i32 %mem_load7, 1
  store i32 %sub, ptr %top3, align 4
  %ptr_deref8 = load ptr, ptr %s, align 8
  %data = getelementptr inbounds nuw %Stack, ptr %ptr_deref8, i32 0, i32 0
  %ptr_deref9 = load ptr, ptr %s, align 8
  %top10 = getelementptr inbounds nuw %Stack, ptr %ptr_deref9, i32 0, i32 1
  %ptr_deref11 = load ptr, ptr %s, align 8
  %mem_load12 = load i32, ptr %top10, align 4
  %arr_gep = getelementptr [16 x i32], ptr %data, i64 0, i32 %mem_load12
  %idx_load = load i32, ptr %arr_gep, align 4
  ret i32 %idx_load
}

define i32 @stack_size(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %ptr_deref = load ptr, ptr %s, align 8
  %top = getelementptr inbounds nuw %Stack, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref1 = load ptr, ptr %s, align 8
  %mem_load = load i32, ptr %top, align 4
  ret i32 %mem_load
}

define i32 @run(i32 %0) {
entry:
  %ops = alloca i32, align 4
  store i32 %0, ptr %ops, align 4
  %s = alloca %Stack, align 8
  store %Stack zeroinitializer, ptr %s, align 4
  call void @stack_init(ptr %s)
  %i = alloca i32, align 4
  store i32 1, ptr %i, align 4
  br label %for_cond

for_cond:                                         ; preds = %for_step, %entry
  %i1 = load i32, ptr %i, align 4
  %ops2 = load i32, ptr %ops, align 4
  %icmp = icmp sle i32 %i1, %ops2
  br i1 %icmp, label %for_body, label %for_exit

for_body:                                         ; preds = %for_cond
  %i3 = load i32, ptr %i, align 4
  %i4 = load i32, ptr %i, align 4
  %mul = mul i32 %i3, %i4
  call void @stack_push(ptr %s, i32 %mul)
  br label %for_step

for_step:                                         ; preds = %for_body
  %i5 = load i32, ptr %i, align 4
  %post_load = load i32, ptr %i, align 4
  %post_inc = add i32 %post_load, 1
  store i32 %post_inc, ptr %i, align 4
  br label %for_cond

for_exit:                                         ; preds = %for_cond
  %sum = alloca i32, align 4
  store i32 0, ptr %sum, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %for_exit
  %1 = call i32 @stack_size(ptr %s)
  %icmp6 = icmp sgt i32 %1, 0
  br i1 %icmp6, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %sum7 = load i32, ptr %sum, align 4
  %2 = call i32 @stack_pop(ptr %s)
  %add = add i32 %sum7, %2
  store i32 %add, ptr %sum, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %sum8 = load i32, ptr %sum, align 4
  ret i32 %sum8
}

define i32 @main() {
entry:
  %0 = call i32 @run(i32 0)
  %icmp = icmp ne i32 %0, 0
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %1 = call i32 @run(i32 1)
  %icmp1 = icmp ne i32 %1, 1
  br i1 %icmp1, label %if_then2, label %if_merge3

if_then2:                                         ; preds = %if_merge
  ret i32 2

if_merge3:                                        ; preds = %if_merge
  %2 = call i32 @run(i32 3)
  %icmp4 = icmp ne i32 %2, 14
  br i1 %icmp4, label %if_then5, label %if_merge6

if_then5:                                         ; preds = %if_merge3
  ret i32 3

if_merge6:                                        ; preds = %if_merge3
  %3 = call i32 @run(i32 5)
  %icmp7 = icmp ne i32 %3, 55
  br i1 %icmp7, label %if_then8, label %if_merge9

if_then8:                                         ; preds = %if_merge6
  ret i32 4

if_merge9:                                        ; preds = %if_merge6
  %Push = load i32, ptr @OpCode__Push, align 4
  %icmp10 = icmp ne i32 %Push, 0
  br i1 %icmp10, label %if_then11, label %if_merge12

if_then11:                                        ; preds = %if_merge9
  ret i32 5

if_merge12:                                       ; preds = %if_merge9
  %Pop = load i32, ptr @OpCode__Pop, align 4
  %icmp13 = icmp ne i32 %Pop, 1
  br i1 %icmp13, label %if_then14, label %if_merge15

if_then14:                                        ; preds = %if_merge12
  ret i32 6

if_merge15:                                       ; preds = %if_merge12
  ret i32 0
}
