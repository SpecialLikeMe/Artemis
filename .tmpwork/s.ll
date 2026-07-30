; ModuleID = 'tcon/time/sieve.arc'
source_filename = "tcon/time/sieve.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

@__artemis_error_payload = local_unnamed_addr global ptr null
@str = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@flags = internal unnamed_addr global [10000000 x i8] zeroinitializer

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr noundef readonly captures(none), ...) local_unnamed_addr #0

; Function Attrs: nofree nounwind
declare noundef i32 @putchar(i32 noundef) local_unnamed_addr #0

; Function Attrs: nofree nounwind
define noundef i32 @main() local_unnamed_addr #0 {
entry:
  br label %while_body

while_body:                                       ; preds = %sieve.exit.1, %entry
  %r.09 = phi i32 [ 0, %entry ], [ %add4.1, %sieve.exit.1 ]
  %c.08 = phi i32 [ 0, %entry ], [ %add.1, %sieve.exit.1 ]
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(10000000) @flags, i8 1, i64 10000000, i1 false)
  br label %bounds_ok.i

bounds_ok.i:                                      ; preds = %if_merge.i.1, %while_body
  %indvars.iv44.i = phi i64 [ 2, %while_body ], [ %indvars.iv.next45.i.1, %if_merge.i.1 ]
  %indvars.iv.i = phi i64 [ 4, %while_body ], [ %indvars.iv.next.i.1, %if_merge.i.1 ]
  %add143940.i = phi i32 [ 0, %while_body ], [ %add1438.i.1, %if_merge.i.1 ]
  %arr_gep11.i = getelementptr i8, ptr @flags, i64 %indvars.iv44.i
  %idx_load.i = load i8, ptr %arr_gep11.i, align 2
  %icmp12.not.i = icmp eq i8 %idx_load.i, 0
  br i1 %icmp12.not.i, label %if_merge.i, label %if_then.i

if_then.i:                                        ; preds = %bounds_ok.i
  %add14.i = add i32 %add143940.i, 1
  %icmp2336.i = icmp samesign ult i64 %indvars.iv44.i, 5000000
  br i1 %icmp2336.i, label %while_body19.i, label %if_merge.i

if_merge.i:                                       ; preds = %while_body19.i, %if_then.i, %bounds_ok.i
  %add1438.i = phi i32 [ %add143940.i, %bounds_ok.i ], [ %add14.i, %if_then.i ], [ %add14.i, %while_body19.i ]
  %indvars.iv.next45.i = or disjoint i64 %indvars.iv44.i, 1
  %indvars.iv.next.i = or disjoint i64 %indvars.iv.i, 2
  %arr_gep11.i.1 = getelementptr i8, ptr @flags, i64 %indvars.iv.next45.i
  %idx_load.i.1 = load i8, ptr %arr_gep11.i.1, align 1
  %icmp12.not.i.1 = icmp eq i8 %idx_load.i.1, 0
  br i1 %icmp12.not.i.1, label %if_merge.i.1, label %if_then.i.1

if_then.i.1:                                      ; preds = %if_merge.i
  %add14.i.1 = add i32 %add1438.i, 1
  %icmp2336.i.1 = icmp samesign ult i64 %indvars.iv44.i, 5000000
  br i1 %icmp2336.i.1, label %while_body19.i.1, label %if_merge.i.1

while_body19.i.1:                                 ; preds = %if_then.i.1, %while_body19.i.1
  %indvars.iv46.i.1 = phi i64 [ %indvars.iv.next47.i.1, %while_body19.i.1 ], [ %indvars.iv.next.i, %if_then.i.1 ]
  %arr_gep25.i.1 = getelementptr i8, ptr @flags, i64 %indvars.iv46.i.1
  store i8 0, ptr %arr_gep25.i.1, align 1
  %indvars.iv.next47.i.1 = add nuw nsw i64 %indvars.iv46.i.1, %indvars.iv.next45.i
  %icmp23.i.1 = icmp samesign ult i64 %indvars.iv.next47.i.1, 10000000
  br i1 %icmp23.i.1, label %while_body19.i.1, label %if_merge.i.1

if_merge.i.1:                                     ; preds = %while_body19.i.1, %if_then.i.1, %if_merge.i
  %add1438.i.1 = phi i32 [ %add1438.i, %if_merge.i ], [ %add14.i.1, %if_then.i.1 ], [ %add14.i.1, %while_body19.i.1 ]
  %indvars.iv.next45.i.1 = add nuw nsw i64 %indvars.iv44.i, 2
  %indvars.iv.next.i.1 = add nuw nsw i64 %indvars.iv.i, 4
  %exitcond.not.i.1 = icmp eq i64 %indvars.iv.next45.i.1, 10000000
  br i1 %exitcond.not.i.1, label %sieve.exit, label %bounds_ok.i

while_body19.i:                                   ; preds = %if_then.i, %while_body19.i
  %indvars.iv46.i = phi i64 [ %indvars.iv.next47.i, %while_body19.i ], [ %indvars.iv.i, %if_then.i ]
  %arr_gep25.i = getelementptr i8, ptr @flags, i64 %indvars.iv46.i
  store i8 0, ptr %arr_gep25.i, align 2
  %indvars.iv.next47.i = add nuw nsw i64 %indvars.iv46.i, %indvars.iv44.i
  %icmp23.i = icmp samesign ult i64 %indvars.iv.next47.i, 10000000
  br i1 %icmp23.i, label %while_body19.i, label %if_merge.i

sieve.exit:                                       ; preds = %if_merge.i.1
  %add = add i32 %add1438.i.1, %c.08
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(10000000) @flags, i8 1, i64 10000000, i1 false)
  br label %bounds_ok.i.1

bounds_ok.i.1:                                    ; preds = %if_merge.i.1.1, %sieve.exit
  %indvars.iv44.i.1 = phi i64 [ 2, %sieve.exit ], [ %indvars.iv.next45.i.1.1, %if_merge.i.1.1 ]
  %indvars.iv.i.1 = phi i64 [ 4, %sieve.exit ], [ %indvars.iv.next.i.1.1, %if_merge.i.1.1 ]
  %add143940.i.1 = phi i32 [ 0, %sieve.exit ], [ %add1438.i.1.1, %if_merge.i.1.1 ]
  %arr_gep11.i.110 = getelementptr i8, ptr @flags, i64 %indvars.iv44.i.1
  %idx_load.i.111 = load i8, ptr %arr_gep11.i.110, align 2
  %icmp12.not.i.112 = icmp eq i8 %idx_load.i.111, 0
  br i1 %icmp12.not.i.112, label %if_merge.i.126, label %if_then.i.115

if_then.i.115:                                    ; preds = %bounds_ok.i.1
  %add14.i.113 = add i32 %add143940.i.1, 1
  %icmp2336.i.114 = icmp samesign ult i64 %indvars.iv44.i.1, 5000000
  br i1 %icmp2336.i.114, label %while_body19.i.121, label %if_merge.i.126

while_body19.i.121:                               ; preds = %if_then.i.115, %while_body19.i.121
  %indvars.iv46.i.117 = phi i64 [ %indvars.iv.next47.i.119, %while_body19.i.121 ], [ %indvars.iv.i.1, %if_then.i.115 ]
  %arr_gep25.i.118 = getelementptr i8, ptr @flags, i64 %indvars.iv46.i.117
  store i8 0, ptr %arr_gep25.i.118, align 2
  %indvars.iv.next47.i.119 = add nuw nsw i64 %indvars.iv46.i.117, %indvars.iv44.i.1
  %icmp23.i.120 = icmp samesign ult i64 %indvars.iv.next47.i.119, 10000000
  br i1 %icmp23.i.120, label %while_body19.i.121, label %if_merge.i.126

if_merge.i.126:                                   ; preds = %while_body19.i.121, %if_then.i.115, %bounds_ok.i.1
  %add1438.i.123 = phi i32 [ %add143940.i.1, %bounds_ok.i.1 ], [ %add14.i.113, %if_then.i.115 ], [ %add14.i.113, %while_body19.i.121 ]
  %indvars.iv.next45.i.124 = or disjoint i64 %indvars.iv44.i.1, 1
  %indvars.iv.next.i.125 = or disjoint i64 %indvars.iv.i.1, 2
  %arr_gep11.i.1.1 = getelementptr i8, ptr @flags, i64 %indvars.iv.next45.i.124
  %idx_load.i.1.1 = load i8, ptr %arr_gep11.i.1.1, align 1
  %icmp12.not.i.1.1 = icmp eq i8 %idx_load.i.1.1, 0
  br i1 %icmp12.not.i.1.1, label %if_merge.i.1.1, label %if_then.i.1.1

if_then.i.1.1:                                    ; preds = %if_merge.i.126
  %add14.i.1.1 = add i32 %add1438.i.123, 1
  %icmp2336.i.1.1 = icmp samesign ult i64 %indvars.iv44.i.1, 5000000
  br i1 %icmp2336.i.1.1, label %while_body19.i.1.1, label %if_merge.i.1.1

while_body19.i.1.1:                               ; preds = %if_then.i.1.1, %while_body19.i.1.1
  %indvars.iv46.i.1.1 = phi i64 [ %indvars.iv.next47.i.1.1, %while_body19.i.1.1 ], [ %indvars.iv.next.i.125, %if_then.i.1.1 ]
  %arr_gep25.i.1.1 = getelementptr i8, ptr @flags, i64 %indvars.iv46.i.1.1
  store i8 0, ptr %arr_gep25.i.1.1, align 1
  %indvars.iv.next47.i.1.1 = add nuw nsw i64 %indvars.iv46.i.1.1, %indvars.iv.next45.i.124
  %icmp23.i.1.1 = icmp samesign ult i64 %indvars.iv.next47.i.1.1, 10000000
  br i1 %icmp23.i.1.1, label %while_body19.i.1.1, label %if_merge.i.1.1

if_merge.i.1.1:                                   ; preds = %while_body19.i.1.1, %if_then.i.1.1, %if_merge.i.126
  %add1438.i.1.1 = phi i32 [ %add1438.i.123, %if_merge.i.126 ], [ %add14.i.1.1, %if_then.i.1.1 ], [ %add14.i.1.1, %while_body19.i.1.1 ]
  %indvars.iv.next45.i.1.1 = add nuw nsw i64 %indvars.iv44.i.1, 2
  %indvars.iv.next.i.1.1 = add nuw nsw i64 %indvars.iv.i.1, 4
  %exitcond.not.i.1.1 = icmp eq i64 %indvars.iv.next45.i.1.1, 10000000
  br i1 %exitcond.not.i.1.1, label %sieve.exit.1, label %bounds_ok.i.1

sieve.exit.1:                                     ; preds = %if_merge.i.1.1
  %add.1 = add i32 %add1438.i.1.1, %add
  %add4.1 = add nuw nsw i32 %r.09, 2
  %exitcond.not.1 = icmp eq i32 %add4.1, 8
  br i1 %exitcond.not.1, label %while_exit, label %while_body

while_exit:                                       ; preds = %sieve.exit.1
  %0 = tail call i32 (ptr, ...) @printf(ptr nonnull dereferenceable(1) @str, i32 %add.1)
  %1 = tail call i32 @putchar(i32 10)
  ret i32 0
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #1

attributes #0 = { nofree nounwind }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: write) }
