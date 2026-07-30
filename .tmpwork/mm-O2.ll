; ModuleID = 'tcon/time/matmul.arc'
source_filename = "tcon/time/matmul.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

@__artemis_error_payload = local_unnamed_addr global ptr null
@str.5 = private unnamed_addr constant [3 x i8] c"%f\00", align 1
@a = internal unnamed_addr global [102400 x double] zeroinitializer
@b = internal unnamed_addr global [102400 x double] zeroinitializer
@c = internal unnamed_addr global [102400 x double] zeroinitializer

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr noundef readonly captures(none), ...) local_unnamed_addr #0

; Function Attrs: nofree nounwind
declare noundef i32 @putchar(i32 noundef) local_unnamed_addr #0

; Function Attrs: nofree nounwind
define noundef i32 @main() local_unnamed_addr #0 {
entry:
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(819200) @c, i8 0, i64 819200, i1 false)
  br label %while_cond2.preheader

while_cond2.preheader:                            ; preds = %entry, %while_exit4
  %indvar = phi i64 [ 0, %entry ], [ %indvar.next, %while_exit4 ]
  %0 = mul nuw nsw i64 %indvar, 320
  %broadcast.splatinsert = insertelement <8 x i64> poison, i64 %indvar, i64 0
  %broadcast.splat = shufflevector <8 x i64> %broadcast.splatinsert, <8 x i64> poison, <8 x i32> zeroinitializer
  %invariant.op = add <8 x i64> splat (i64 8), %broadcast.splat
  %invariant.op171 = add <8 x i64> splat (i64 16), %broadcast.splat
  %invariant.op173 = add <8 x i64> splat (i64 24), %broadcast.splat
  %invariant.op175 = add <8 x i64> splat (i64 32), %broadcast.splat
  %invariant.op177 = add <8 x i64> splat (i64 40), %broadcast.splat
  %invariant.op179 = add <8 x i64> splat (i64 48), %broadcast.splat
  %invariant.op181 = add <8 x i64> splat (i64 56), %broadcast.splat
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %while_cond2.preheader
  %index = phi i64 [ 0, %while_cond2.preheader ], [ %index.next.1, %vector.body ]
  %vec.ind = phi <8 x i64> [ <i64 0, i64 1, i64 2, i64 3, i64 4, i64 5, i64 6, i64 7>, %while_cond2.preheader ], [ %vec.ind.next.1, %vector.body ]
  %step.add = add <8 x i64> %vec.ind, splat (i64 8)
  %step.add.2 = add <8 x i64> %vec.ind, splat (i64 16)
  %step.add.3 = add <8 x i64> %vec.ind, splat (i64 24)
  %1 = add nuw nsw i64 %index, %0
  %2 = getelementptr double, ptr @a, i64 %1
  %3 = add nuw nsw <8 x i64> %vec.ind, %broadcast.splat
  %.reass = add <8 x i64> %vec.ind, %invariant.op
  %.reass172 = add <8 x i64> %vec.ind, %invariant.op171
  %.reass174 = add <8 x i64> %vec.ind, %invariant.op173
  %4 = trunc nuw nsw <8 x i64> %3 to <8 x i32>
  %5 = trunc nuw nsw <8 x i64> %.reass to <8 x i32>
  %6 = trunc nuw nsw <8 x i64> %.reass172 to <8 x i32>
  %7 = trunc nuw nsw <8 x i64> %.reass174 to <8 x i32>
  %8 = uitofp nneg <8 x i32> %4 to <8 x double>
  %9 = uitofp nneg <8 x i32> %5 to <8 x double>
  %10 = uitofp nneg <8 x i32> %6 to <8 x double>
  %11 = uitofp nneg <8 x i32> %7 to <8 x double>
  %12 = getelementptr i8, ptr %2, i64 64
  %13 = getelementptr i8, ptr %2, i64 128
  %14 = getelementptr i8, ptr %2, i64 192
  store <8 x double> %8, ptr %2, align 16
  store <8 x double> %9, ptr %12, align 16
  store <8 x double> %10, ptr %13, align 16
  store <8 x double> %11, ptr %14, align 16
  %15 = getelementptr double, ptr @b, i64 %1
  %16 = sub nsw <8 x i64> %broadcast.splat, %vec.ind
  %17 = sub nsw <8 x i64> %broadcast.splat, %step.add
  %18 = sub nsw <8 x i64> %broadcast.splat, %step.add.2
  %19 = sub nsw <8 x i64> %broadcast.splat, %step.add.3
  %20 = trunc nsw <8 x i64> %16 to <8 x i32>
  %21 = trunc nsw <8 x i64> %17 to <8 x i32>
  %22 = trunc nsw <8 x i64> %18 to <8 x i32>
  %23 = trunc nsw <8 x i64> %19 to <8 x i32>
  %24 = sitofp <8 x i32> %20 to <8 x double>
  %25 = sitofp <8 x i32> %21 to <8 x double>
  %26 = sitofp <8 x i32> %22 to <8 x double>
  %27 = sitofp <8 x i32> %23 to <8 x double>
  %28 = getelementptr i8, ptr %15, i64 64
  %29 = getelementptr i8, ptr %15, i64 128
  %30 = getelementptr i8, ptr %15, i64 192
  store <8 x double> %24, ptr %15, align 16
  store <8 x double> %25, ptr %28, align 16
  store <8 x double> %26, ptr %29, align 16
  store <8 x double> %27, ptr %30, align 16
  %index.next = or disjoint i64 %index, 32
  %vec.ind.next = add <8 x i64> %vec.ind, splat (i64 32)
  %step.add.1 = add <8 x i64> %vec.ind, splat (i64 40)
  %step.add.2.1 = add <8 x i64> %vec.ind, splat (i64 48)
  %step.add.3.1 = add <8 x i64> %vec.ind, splat (i64 56)
  %31 = add nuw nsw i64 %index.next, %0
  %32 = getelementptr double, ptr @a, i64 %31
  %.reass176 = add <8 x i64> %vec.ind, %invariant.op175
  %.reass178 = add <8 x i64> %vec.ind, %invariant.op177
  %.reass180 = add <8 x i64> %vec.ind, %invariant.op179
  %.reass182 = add <8 x i64> %vec.ind, %invariant.op181
  %33 = trunc nuw nsw <8 x i64> %.reass176 to <8 x i32>
  %34 = trunc nuw nsw <8 x i64> %.reass178 to <8 x i32>
  %35 = trunc nuw nsw <8 x i64> %.reass180 to <8 x i32>
  %36 = trunc nuw nsw <8 x i64> %.reass182 to <8 x i32>
  %37 = uitofp nneg <8 x i32> %33 to <8 x double>
  %38 = uitofp nneg <8 x i32> %34 to <8 x double>
  %39 = uitofp nneg <8 x i32> %35 to <8 x double>
  %40 = uitofp nneg <8 x i32> %36 to <8 x double>
  %41 = getelementptr i8, ptr %32, i64 64
  %42 = getelementptr i8, ptr %32, i64 128
  %43 = getelementptr i8, ptr %32, i64 192
  store <8 x double> %37, ptr %32, align 16
  store <8 x double> %38, ptr %41, align 16
  store <8 x double> %39, ptr %42, align 16
  store <8 x double> %40, ptr %43, align 16
  %44 = getelementptr double, ptr @b, i64 %31
  %45 = sub nsw <8 x i64> %broadcast.splat, %vec.ind.next
  %46 = sub nsw <8 x i64> %broadcast.splat, %step.add.1
  %47 = sub nsw <8 x i64> %broadcast.splat, %step.add.2.1
  %48 = sub nsw <8 x i64> %broadcast.splat, %step.add.3.1
  %49 = trunc nsw <8 x i64> %45 to <8 x i32>
  %50 = trunc nsw <8 x i64> %46 to <8 x i32>
  %51 = trunc nsw <8 x i64> %47 to <8 x i32>
  %52 = trunc nsw <8 x i64> %48 to <8 x i32>
  %53 = sitofp <8 x i32> %49 to <8 x double>
  %54 = sitofp <8 x i32> %50 to <8 x double>
  %55 = sitofp <8 x i32> %51 to <8 x double>
  %56 = sitofp <8 x i32> %52 to <8 x double>
  %57 = getelementptr i8, ptr %44, i64 64
  %58 = getelementptr i8, ptr %44, i64 128
  %59 = getelementptr i8, ptr %44, i64 192
  store <8 x double> %53, ptr %44, align 16
  store <8 x double> %54, ptr %57, align 16
  store <8 x double> %55, ptr %58, align 16
  store <8 x double> %56, ptr %59, align 16
  %index.next.1 = add nuw nsw i64 %index, 64
  %vec.ind.next.1 = add <8 x i64> %vec.ind, splat (i64 64)
  %60 = icmp eq i64 %index.next.1, 320
  br i1 %60, label %while_exit4, label %vector.body, !llvm.loop !0

while_exit4:                                      ; preds = %vector.body
  %indvar.next = add nuw nsw i64 %indvar, 1
  %exitcond126.not = icmp eq i64 %indvar.next, 320
  br i1 %exitcond126.not, label %while_cond39.preheader, label %while_cond2.preheader

while_cond39.preheader:                           ; preds = %while_exit4, %while_exit41
  %indvars.iv139 = phi i64 [ %indvars.iv.next140, %while_exit41 ], [ 0, %while_exit4 ]
  %61 = mul nuw nsw i64 %indvars.iv139, 320
  %invariant.gep146 = getelementptr double, ptr @a, i64 %61
  %invariant.gep = getelementptr double, ptr @c, i64 %61
  br label %bounds_ok

while_exit41:                                     ; preds = %while_exit53.1
  %indvars.iv.next140 = add nuw nsw i64 %indvars.iv139, 1
  %exitcond143.not = icmp eq i64 %indvars.iv.next140, 320
  br i1 %exitcond143.not, label %bounds_ok99, label %while_cond39.preheader

bounds_ok:                                        ; preds = %while_exit53.1, %while_cond39.preheader
  %indvars.iv133 = phi i64 [ 0, %while_cond39.preheader ], [ %indvars.iv.next134.1, %while_exit53.1 ]
  %arr_gep84.idx = mul nuw nsw i64 %indvars.iv133, 2560
  %invariant.gep144 = getelementptr i8, ptr @b, i64 %arr_gep84.idx
  %gep147 = getelementptr double, ptr %invariant.gep146, i64 %indvars.iv133
  %idx_load = load double, ptr %gep147, align 16
  %broadcast.splatinsert149 = insertelement <8 x double> poison, double %idx_load, i64 0
  %broadcast.splat150 = shufflevector <8 x double> %broadcast.splatinsert149, <8 x double> poison, <8 x i32> zeroinitializer
  br label %vector.body151

vector.body151:                                   ; preds = %vector.body151, %bounds_ok
  %index152 = phi i64 [ 0, %bounds_ok ], [ %index.next160.1, %vector.body151 ]
  %62 = getelementptr double, ptr %invariant.gep, i64 %index152
  %63 = getelementptr i8, ptr %62, i64 64
  %64 = getelementptr i8, ptr %62, i64 128
  %65 = getelementptr i8, ptr %62, i64 192
  %wide.load = load <8 x double>, ptr %62, align 16
  %wide.load153 = load <8 x double>, ptr %63, align 16
  %wide.load154 = load <8 x double>, ptr %64, align 16
  %wide.load155 = load <8 x double>, ptr %65, align 16
  %66 = getelementptr double, ptr %invariant.gep144, i64 %index152
  %67 = getelementptr i8, ptr %66, i64 64
  %68 = getelementptr i8, ptr %66, i64 128
  %69 = getelementptr i8, ptr %66, i64 192
  %wide.load156 = load <8 x double>, ptr %66, align 16
  %wide.load157 = load <8 x double>, ptr %67, align 16
  %wide.load158 = load <8 x double>, ptr %68, align 16
  %wide.load159 = load <8 x double>, ptr %69, align 16
  %70 = fmul <8 x double> %broadcast.splat150, %wide.load156
  %71 = fmul <8 x double> %broadcast.splat150, %wide.load157
  %72 = fmul <8 x double> %broadcast.splat150, %wide.load158
  %73 = fmul <8 x double> %broadcast.splat150, %wide.load159
  %74 = fadd <8 x double> %wide.load, %70
  %75 = fadd <8 x double> %wide.load153, %71
  %76 = fadd <8 x double> %wide.load154, %72
  %77 = fadd <8 x double> %wide.load155, %73
  store <8 x double> %74, ptr %62, align 16
  store <8 x double> %75, ptr %63, align 16
  store <8 x double> %76, ptr %64, align 16
  store <8 x double> %77, ptr %65, align 16
  %index.next160 = or disjoint i64 %index152, 32
  %78 = getelementptr double, ptr %invariant.gep, i64 %index.next160
  %79 = getelementptr i8, ptr %78, i64 64
  %80 = getelementptr i8, ptr %78, i64 128
  %81 = getelementptr i8, ptr %78, i64 192
  %wide.load.1 = load <8 x double>, ptr %78, align 16
  %wide.load153.1 = load <8 x double>, ptr %79, align 16
  %wide.load154.1 = load <8 x double>, ptr %80, align 16
  %wide.load155.1 = load <8 x double>, ptr %81, align 16
  %82 = getelementptr double, ptr %invariant.gep144, i64 %index.next160
  %83 = getelementptr i8, ptr %82, i64 64
  %84 = getelementptr i8, ptr %82, i64 128
  %85 = getelementptr i8, ptr %82, i64 192
  %wide.load156.1 = load <8 x double>, ptr %82, align 16
  %wide.load157.1 = load <8 x double>, ptr %83, align 16
  %wide.load158.1 = load <8 x double>, ptr %84, align 16
  %wide.load159.1 = load <8 x double>, ptr %85, align 16
  %86 = fmul <8 x double> %broadcast.splat150, %wide.load156.1
  %87 = fmul <8 x double> %broadcast.splat150, %wide.load157.1
  %88 = fmul <8 x double> %broadcast.splat150, %wide.load158.1
  %89 = fmul <8 x double> %broadcast.splat150, %wide.load159.1
  %90 = fadd <8 x double> %wide.load.1, %86
  %91 = fadd <8 x double> %wide.load153.1, %87
  %92 = fadd <8 x double> %wide.load154.1, %88
  %93 = fadd <8 x double> %wide.load155.1, %89
  store <8 x double> %90, ptr %78, align 16
  store <8 x double> %91, ptr %79, align 16
  store <8 x double> %92, ptr %80, align 16
  store <8 x double> %93, ptr %81, align 16
  %index.next160.1 = add nuw nsw i64 %index152, 64
  %94 = icmp eq i64 %index.next160.1, 320
  br i1 %94, label %while_exit53, label %vector.body151, !llvm.loop !3

while_exit53:                                     ; preds = %vector.body151
  %indvars.iv.next134 = or disjoint i64 %indvars.iv133, 1
  %arr_gep84.idx.1 = mul nuw nsw i64 %indvars.iv.next134, 2560
  %invariant.gep144.1 = getelementptr i8, ptr @b, i64 %arr_gep84.idx.1
  %gep147.1 = getelementptr double, ptr %invariant.gep146, i64 %indvars.iv.next134
  %idx_load.1 = load double, ptr %gep147.1, align 8
  %broadcast.splatinsert149.1 = insertelement <8 x double> poison, double %idx_load.1, i64 0
  %broadcast.splat150.1 = shufflevector <8 x double> %broadcast.splatinsert149.1, <8 x double> poison, <8 x i32> zeroinitializer
  br label %vector.body151.1

vector.body151.1:                                 ; preds = %vector.body151.1, %while_exit53
  %index152.1 = phi i64 [ 0, %while_exit53 ], [ %index.next160.1.1, %vector.body151.1 ]
  %95 = getelementptr double, ptr %invariant.gep, i64 %index152.1
  %96 = getelementptr i8, ptr %95, i64 64
  %97 = getelementptr i8, ptr %95, i64 128
  %98 = getelementptr i8, ptr %95, i64 192
  %wide.load.1162 = load <8 x double>, ptr %95, align 16
  %wide.load153.1163 = load <8 x double>, ptr %96, align 16
  %wide.load154.1164 = load <8 x double>, ptr %97, align 16
  %wide.load155.1165 = load <8 x double>, ptr %98, align 16
  %99 = getelementptr double, ptr %invariant.gep144.1, i64 %index152.1
  %100 = getelementptr i8, ptr %99, i64 64
  %101 = getelementptr i8, ptr %99, i64 128
  %102 = getelementptr i8, ptr %99, i64 192
  %wide.load156.1166 = load <8 x double>, ptr %99, align 16
  %wide.load157.1167 = load <8 x double>, ptr %100, align 16
  %wide.load158.1168 = load <8 x double>, ptr %101, align 16
  %wide.load159.1169 = load <8 x double>, ptr %102, align 16
  %103 = fmul <8 x double> %broadcast.splat150.1, %wide.load156.1166
  %104 = fmul <8 x double> %broadcast.splat150.1, %wide.load157.1167
  %105 = fmul <8 x double> %broadcast.splat150.1, %wide.load158.1168
  %106 = fmul <8 x double> %broadcast.splat150.1, %wide.load159.1169
  %107 = fadd <8 x double> %wide.load.1162, %103
  %108 = fadd <8 x double> %wide.load153.1163, %104
  %109 = fadd <8 x double> %wide.load154.1164, %105
  %110 = fadd <8 x double> %wide.load155.1165, %106
  store <8 x double> %107, ptr %95, align 16
  store <8 x double> %108, ptr %96, align 16
  store <8 x double> %109, ptr %97, align 16
  store <8 x double> %110, ptr %98, align 16
  %index.next160.1170 = or disjoint i64 %index152.1, 32
  %111 = getelementptr double, ptr %invariant.gep, i64 %index.next160.1170
  %112 = getelementptr i8, ptr %111, i64 64
  %113 = getelementptr i8, ptr %111, i64 128
  %114 = getelementptr i8, ptr %111, i64 192
  %wide.load.1.1 = load <8 x double>, ptr %111, align 16
  %wide.load153.1.1 = load <8 x double>, ptr %112, align 16
  %wide.load154.1.1 = load <8 x double>, ptr %113, align 16
  %wide.load155.1.1 = load <8 x double>, ptr %114, align 16
  %115 = getelementptr double, ptr %invariant.gep144.1, i64 %index.next160.1170
  %116 = getelementptr i8, ptr %115, i64 64
  %117 = getelementptr i8, ptr %115, i64 128
  %118 = getelementptr i8, ptr %115, i64 192
  %wide.load156.1.1 = load <8 x double>, ptr %115, align 16
  %wide.load157.1.1 = load <8 x double>, ptr %116, align 16
  %wide.load158.1.1 = load <8 x double>, ptr %117, align 16
  %wide.load159.1.1 = load <8 x double>, ptr %118, align 16
  %119 = fmul <8 x double> %broadcast.splat150.1, %wide.load156.1.1
  %120 = fmul <8 x double> %broadcast.splat150.1, %wide.load157.1.1
  %121 = fmul <8 x double> %broadcast.splat150.1, %wide.load158.1.1
  %122 = fmul <8 x double> %broadcast.splat150.1, %wide.load159.1.1
  %123 = fadd <8 x double> %wide.load.1.1, %119
  %124 = fadd <8 x double> %wide.load153.1.1, %120
  %125 = fadd <8 x double> %wide.load154.1.1, %121
  %126 = fadd <8 x double> %wide.load155.1.1, %122
  store <8 x double> %123, ptr %111, align 16
  store <8 x double> %124, ptr %112, align 16
  store <8 x double> %125, ptr %113, align 16
  store <8 x double> %126, ptr %114, align 16
  %index.next160.1.1 = add nuw nsw i64 %index152.1, 64
  %127 = icmp eq i64 %index.next160.1.1, 320
  br i1 %127, label %while_exit53.1, label %vector.body151.1, !llvm.loop !3

while_exit53.1:                                   ; preds = %vector.body151.1
  %indvars.iv.next134.1 = add nuw nsw i64 %indvars.iv133, 2
  %exitcond138.not.1 = icmp eq i64 %indvars.iv.next134.1, 320
  br i1 %exitcond138.not.1, label %while_exit41, label %bounds_ok

bounds_ok99:                                      ; preds = %while_exit41
  %idx_load101 = load double, ptr getelementptr inbounds nuw (i8, ptr @c, i64 819192), align 8
  %128 = tail call i32 (ptr, ...) @printf(ptr nonnull dereferenceable(1) @str.5, double %idx_load101)
  %129 = tail call i32 @putchar(i32 10)
  ret i32 0
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #1

attributes #0 = { nofree nounwind }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: write) }

!0 = distinct !{!0, !1, !2}
!1 = !{!"llvm.loop.isvectorized", i32 1}
!2 = !{!"llvm.loop.unroll.runtime.disable"}
!3 = distinct !{!3, !1, !2}
