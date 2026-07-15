; ModuleID = 'build/soa_trunc4.arc'
source_filename = "build/soa_trunc4.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%vec2f = type { i8, i8, i32 }
%__memstr_fat__ = type { ptr, ptr }
%vec3f = type { i8, i8, i8, i32 }

define void @vec2f__NS___construct__(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %vec2f, ptr %ptr_deref, i32 0, i32 2
  store i32 0, ptr %len, align 4
  ret void
}

define void @vec2f__NS_push(ptr %0, float %1, float %2, %__memstr_fat__ %3) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %xv = alloca float, align 4
  store float %1, ptr %xv, align 4
  %yv = alloca float, align 4
  store float %2, ptr %yv, align 4
  %a = alloca %__memstr_fat__, align 8
  store %__memstr_fat__ %3, ptr %a, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %x = getelementptr inbounds nuw %vec2f, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %y = getelementptr inbounds nuw %vec2f, ptr %ptr_deref1, i32 0, i32 1
  %ptr_deref2 = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %vec2f, ptr %ptr_deref2, i32 0, i32 2
  %ptr_deref3 = load ptr, ptr %self, align 8
  %len4 = getelementptr inbounds nuw %vec2f, ptr %ptr_deref3, i32 0, i32 2
  %ptr_deref5 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %len4, align 4
  %add = add i32 %mem_load, 1
  store i32 %add, ptr %len, align 4
  ret void
}

define void @vec2f__NS_remove_at(ptr %0, i32 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %i = alloca i32, align 4
  store i32 %1, ptr %i, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %x = getelementptr inbounds nuw %vec2f, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %y = getelementptr inbounds nuw %vec2f, ptr %ptr_deref1, i32 0, i32 1
  %ptr_deref2 = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %vec2f, ptr %ptr_deref2, i32 0, i32 2
  %ptr_deref3 = load ptr, ptr %self, align 8
  %len4 = getelementptr inbounds nuw %vec2f, ptr %ptr_deref3, i32 0, i32 2
  %ptr_deref5 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %len4, align 4
  %sub = sub i32 %mem_load, 1
  store i32 %sub, ptr %len, align 4
  ret void
}

define void @vec2f__NS_swap_erase(ptr %0, i32 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %i = alloca i32, align 4
  store i32 %1, ptr %i, align 4
  %last = alloca i32, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %vec2f, ptr %ptr_deref, i32 0, i32 2
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %len, align 4
  %sub = sub i32 %mem_load, 1
  store i32 %sub, ptr %last, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %x = getelementptr inbounds nuw %vec2f, ptr %ptr_deref2, i32 0, i32 0
  %ptr_deref3 = load ptr, ptr %self, align 8
  %y = getelementptr inbounds nuw %vec2f, ptr %ptr_deref3, i32 0, i32 1
  %ptr_deref4 = load ptr, ptr %self, align 8
  %x5 = getelementptr inbounds nuw %vec2f, ptr %ptr_deref4, i32 0, i32 0
  %ptr_deref6 = load ptr, ptr %self, align 8
  %x7 = getelementptr inbounds nuw %vec2f, ptr %ptr_deref6, i32 0, i32 0
  %ptr_deref8 = load ptr, ptr %self, align 8
  %y9 = getelementptr inbounds nuw %vec2f, ptr %ptr_deref8, i32 0, i32 1
  %ptr_deref10 = load ptr, ptr %self, align 8
  %y11 = getelementptr inbounds nuw %vec2f, ptr %ptr_deref10, i32 0, i32 1
  %ptr_deref12 = load ptr, ptr %self, align 8
  %len13 = getelementptr inbounds nuw %vec2f, ptr %ptr_deref12, i32 0, i32 2
  %ptr_deref14 = load ptr, ptr %self, align 8
  %len15 = getelementptr inbounds nuw %vec2f, ptr %ptr_deref14, i32 0, i32 2
  %ptr_deref16 = load ptr, ptr %self, align 8
  %mem_load17 = load i32, ptr %len15, align 4
  %sub18 = sub i32 %mem_load17, 1
  store i32 %sub18, ptr %len13, align 4
  ret void
}

define void @vec2f__NS_deinit(ptr %0, %__memstr_fat__ %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %a = alloca %__memstr_fat__, align 8
  store %__memstr_fat__ %1, ptr %a, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %x = getelementptr inbounds nuw %vec2f, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %y = getelementptr inbounds nuw %vec2f, ptr %ptr_deref1, i32 0, i32 1
  %ptr_deref2 = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %vec2f, ptr %ptr_deref2, i32 0, i32 2
  store i32 0, ptr %len, align 4
  ret void
}

define void @vec3f__NS___construct__(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %vec3f, ptr %ptr_deref, i32 0, i32 3
  store i32 0, ptr %len, align 4
  ret void
}

define void @vec3f__NS_push(ptr %0, float %1, float %2, float %3, %__memstr_fat__ %4) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %xv = alloca float, align 4
  store float %1, ptr %xv, align 4
  %yv = alloca float, align 4
  store float %2, ptr %yv, align 4
  %zv = alloca float, align 4
  store float %3, ptr %zv, align 4
  %a = alloca %__memstr_fat__, align 8
  store %__memstr_fat__ %4, ptr %a, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %x = getelementptr inbounds nuw %vec3f, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %y = getelementptr inbounds nuw %vec3f, ptr %ptr_deref1, i32 0, i32 1
  %ptr_deref2 = load ptr, ptr %self, align 8
  %z = getelementptr inbounds nuw %vec3f, ptr %ptr_deref2, i32 0, i32 2
  %ptr_deref3 = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %vec3f, ptr %ptr_deref3, i32 0, i32 3
  %ptr_deref4 = load ptr, ptr %self, align 8
  %len5 = getelementptr inbounds nuw %vec3f, ptr %ptr_deref4, i32 0, i32 3
  %ptr_deref6 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %len5, align 4
  %add = add i32 %mem_load, 1
  store i32 %add, ptr %len, align 4
  ret void
}

define void @vec3f__NS_remove_at(ptr %0, i32 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %i = alloca i32, align 4
  store i32 %1, ptr %i, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %x = getelementptr inbounds nuw %vec3f, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %y = getelementptr inbounds nuw %vec3f, ptr %ptr_deref1, i32 0, i32 1
  %ptr_deref2 = load ptr, ptr %self, align 8
  %z = getelementptr inbounds nuw %vec3f, ptr %ptr_deref2, i32 0, i32 2
  %ptr_deref3 = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %vec3f, ptr %ptr_deref3, i32 0, i32 3
  %ptr_deref4 = load ptr, ptr %self, align 8
  %len5 = getelementptr inbounds nuw %vec3f, ptr %ptr_deref4, i32 0, i32 3
  %ptr_deref6 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %len5, align 4
  %sub = sub i32 %mem_load, 1
  store i32 %sub, ptr %len, align 4
  ret void
}

define void @vec3f__NS_swap_erase(ptr %0, i32 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %i = alloca i32, align 4
  store i32 %1, ptr %i, align 4
  %last = alloca i32, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %vec3f, ptr %ptr_deref, i32 0, i32 3
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %len, align 4
  %sub = sub i32 %mem_load, 1
  store i32 %sub, ptr %last, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %x = getelementptr inbounds nuw %vec3f, ptr %ptr_deref2, i32 0, i32 0
  %ptr_deref3 = load ptr, ptr %self, align 8
  %y = getelementptr inbounds nuw %vec3f, ptr %ptr_deref3, i32 0, i32 1
  %ptr_deref4 = load ptr, ptr %self, align 8
  %z = getelementptr inbounds nuw %vec3f, ptr %ptr_deref4, i32 0, i32 2
  %ptr_deref5 = load ptr, ptr %self, align 8
  %x6 = getelementptr inbounds nuw %vec3f, ptr %ptr_deref5, i32 0, i32 0
  %ptr_deref7 = load ptr, ptr %self, align 8
  %x8 = getelementptr inbounds nuw %vec3f, ptr %ptr_deref7, i32 0, i32 0
  %ptr_deref9 = load ptr, ptr %self, align 8
  %y10 = getelementptr inbounds nuw %vec3f, ptr %ptr_deref9, i32 0, i32 1
  %ptr_deref11 = load ptr, ptr %self, align 8
  %y12 = getelementptr inbounds nuw %vec3f, ptr %ptr_deref11, i32 0, i32 1
  %ptr_deref13 = load ptr, ptr %self, align 8
  %z14 = getelementptr inbounds nuw %vec3f, ptr %ptr_deref13, i32 0, i32 2
  %ptr_deref15 = load ptr, ptr %self, align 8
  %z16 = getelementptr inbounds nuw %vec3f, ptr %ptr_deref15, i32 0, i32 2
  %ptr_deref17 = load ptr, ptr %self, align 8
  %len18 = getelementptr inbounds nuw %vec3f, ptr %ptr_deref17, i32 0, i32 3
  %ptr_deref19 = load ptr, ptr %self, align 8
  %len20 = getelementptr inbounds nuw %vec3f, ptr %ptr_deref19, i32 0, i32 3
  %ptr_deref21 = load ptr, ptr %self, align 8
  %mem_load22 = load i32, ptr %len20, align 4
  %sub23 = sub i32 %mem_load22, 1
  store i32 %sub23, ptr %len18, align 4
  ret void
}

define void @vec3f__NS_deinit(ptr %0, %__memstr_fat__ %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %a = alloca %__memstr_fat__, align 8
  store %__memstr_fat__ %1, ptr %a, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %x = getelementptr inbounds nuw %vec3f, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %y = getelementptr inbounds nuw %vec3f, ptr %ptr_deref1, i32 0, i32 1
  %ptr_deref2 = load ptr, ptr %self, align 8
  %z = getelementptr inbounds nuw %vec3f, ptr %ptr_deref2, i32 0, i32 2
  %ptr_deref3 = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %vec3f, ptr %ptr_deref3, i32 0, i32 3
  store i32 0, ptr %len, align 4
  ret void
}

define i32 @main() {
entry:
  ret i32 0
}
