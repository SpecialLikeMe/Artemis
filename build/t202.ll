; ModuleID = 'tcon/test/202_namespace_types.arc'
source_filename = "tcon/test/202_namespace_types.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%Point = type { i32, i32 }
%Rect = type { i32, i32, i32, i32 }

@geom__NS_ORIGIN_X = global i32 0
@geom__NS_ORIGIN_Y = global i32 0

define %Point @geom__NS_make_point(i32 %0, i32 %1) {
entry:
  %x = alloca i32, align 4
  store i32 %0, ptr %x, align 4
  %y = alloca i32, align 4
  store i32 %1, ptr %y, align 4
  %p = alloca %Point, align 8
  store %Point zeroinitializer, ptr %p, align 4
  %x1 = getelementptr inbounds nuw %Point, ptr %p, i32 0, i32 0
  %x2 = load i32, ptr %x, align 4
  store i32 %x2, ptr %x1, align 4
  %y3 = getelementptr inbounds nuw %Point, ptr %p, i32 0, i32 1
  %y4 = load i32, ptr %y, align 4
  store i32 %y4, ptr %y3, align 4
  %p5 = load %Point, ptr %p, align 4
  ret %Point %p5
}

define %Point @geom__NS_origin() {
entry:
  %p = alloca %Point, align 8
  store %Point zeroinitializer, ptr %p, align 4
  %x = getelementptr inbounds nuw %Point, ptr %p, i32 0, i32 0
  %y = getelementptr inbounds nuw %Point, ptr %p, i32 0, i32 1
  %p1 = load %Point, ptr %p, align 4
  ret %Point %p1
}

define i32 @geom__NS_rect_area(%Rect %0) {
entry:
  %r = alloca %Rect, align 8
  store %Rect %0, ptr %r, align 4
  %w = getelementptr inbounds nuw %Rect, ptr %r, i32 0, i32 2
  %mem_load = load i32, ptr %w, align 4
  %h = getelementptr inbounds nuw %Rect, ptr %r, i32 0, i32 3
  %mem_load1 = load i32, ptr %h, align 4
  %mul = mul i32 %mem_load, %mem_load1
  ret i32 %mul
}

define %Rect @geom__NS_make_rect(%Point %0, i32 %1, i32 %2) {
entry:
  %tl = alloca %Point, align 8
  store %Point %0, ptr %tl, align 4
  %w = alloca i32, align 4
  store i32 %1, ptr %w, align 4
  %h = alloca i32, align 4
  store i32 %2, ptr %h, align 4
  %r = alloca %Rect, align 8
  store %Rect zeroinitializer, ptr %r, align 4
  %x = getelementptr inbounds nuw %Rect, ptr %r, i32 0, i32 0
  %x1 = getelementptr inbounds nuw %Point, ptr %tl, i32 0, i32 0
  %mem_load = load i32, ptr %x1, align 4
  store i32 %mem_load, ptr %x, align 4
  %y = getelementptr inbounds nuw %Rect, ptr %r, i32 0, i32 1
  %y2 = getelementptr inbounds nuw %Point, ptr %tl, i32 0, i32 1
  %mem_load3 = load i32, ptr %y2, align 4
  store i32 %mem_load3, ptr %y, align 4
  %w4 = getelementptr inbounds nuw %Rect, ptr %r, i32 0, i32 2
  %w5 = load i32, ptr %w, align 4
  store i32 %w5, ptr %w4, align 4
  %h6 = getelementptr inbounds nuw %Rect, ptr %r, i32 0, i32 3
  %h7 = load i32, ptr %h, align 4
  store i32 %h7, ptr %h6, align 4
  %r8 = load %Rect, ptr %r, align 4
  ret %Rect %r8
}

define i32 @main() {
entry:
  %p = alloca i8, align 1
  %0 = call %Point @geom__NS_make_point(i32 3, i32 4)
  store %Point %0, ptr %p, align 4
  %o = alloca i8, align 1
  %1 = call %Point @geom__NS_origin()
  store %Point %1, ptr %o, align 4
  %tl = alloca i8, align 1
  %2 = call %Point @geom__NS_make_point(i32 1, i32 1)
  store %Point %2, ptr %tl, align 4
  %r = alloca i8, align 1
  %tl1 = load i8, ptr %tl, align 1
  %3 = call %Rect @geom__NS_make_rect(i8 %tl1, i32 5, i32 3)
  store %Rect %3, ptr %r, align 4
  %r2 = load i8, ptr %r, align 1
  %4 = call i32 @geom__NS_rect_area(i8 %r2)
  %icmp = icmp ne i32 %4, 15
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 5

if_merge:                                         ; preds = %entry
  ret i32 0
}
