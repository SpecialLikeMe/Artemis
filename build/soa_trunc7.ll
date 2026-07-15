; ModuleID = 'build/soa_trunc7.arc'
source_filename = "build/soa_trunc7.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%vec2f = type { i8, i8, i32 }
%__memstr_fat__ = type { ptr, ptr }
%vec3f = type { i8, i8, i8, i32 }
%particle = type { i8, i8, i8, i8, i8, i8, i8, i8, i32 }
%transform = type { i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i32 }

@soa__NS_SOA_MAX_FIELDS = global i32 64

declare ptr @memcpy(ptr, ptr, i64)

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

define void @particle__NS___construct__(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %particle, ptr %ptr_deref, i32 0, i32 8
  store i32 0, ptr %len, align 4
  ret void
}

define void @particle__NS_push(ptr %0, float %1, float %2, float %3, float %4, float %5, float %6, float %7, i32 %8, %__memstr_fat__ %9) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %x = alloca float, align 4
  store float %1, ptr %x, align 4
  %y = alloca float, align 4
  store float %2, ptr %y, align 4
  %z = alloca float, align 4
  store float %3, ptr %z, align 4
  %vx_ = alloca float, align 4
  store float %4, ptr %vx_, align 4
  %vy_ = alloca float, align 4
  store float %5, ptr %vy_, align 4
  %vz_ = alloca float, align 4
  store float %6, ptr %vz_, align 4
  %life_ = alloca float, align 4
  store float %7, ptr %life_, align 4
  %col_ = alloca i32, align 4
  store i32 %8, ptr %col_, align 4
  %a = alloca %__memstr_fat__, align 8
  store %__memstr_fat__ %9, ptr %a, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %px = getelementptr inbounds nuw %particle, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %py = getelementptr inbounds nuw %particle, ptr %ptr_deref1, i32 0, i32 1
  %ptr_deref2 = load ptr, ptr %self, align 8
  %pz = getelementptr inbounds nuw %particle, ptr %ptr_deref2, i32 0, i32 2
  %ptr_deref3 = load ptr, ptr %self, align 8
  %vx = getelementptr inbounds nuw %particle, ptr %ptr_deref3, i32 0, i32 3
  %ptr_deref4 = load ptr, ptr %self, align 8
  %vy = getelementptr inbounds nuw %particle, ptr %ptr_deref4, i32 0, i32 4
  %ptr_deref5 = load ptr, ptr %self, align 8
  %vz = getelementptr inbounds nuw %particle, ptr %ptr_deref5, i32 0, i32 5
  %ptr_deref6 = load ptr, ptr %self, align 8
  %life = getelementptr inbounds nuw %particle, ptr %ptr_deref6, i32 0, i32 6
  %ptr_deref7 = load ptr, ptr %self, align 8
  %color = getelementptr inbounds nuw %particle, ptr %ptr_deref7, i32 0, i32 7
  %ptr_deref8 = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %particle, ptr %ptr_deref8, i32 0, i32 8
  %ptr_deref9 = load ptr, ptr %self, align 8
  %len10 = getelementptr inbounds nuw %particle, ptr %ptr_deref9, i32 0, i32 8
  %ptr_deref11 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %len10, align 4
  %add = add i32 %mem_load, 1
  store i32 %add, ptr %len, align 4
  ret void
}

define void @particle__NS_swap_erase(ptr %0, i32 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %i = alloca i32, align 4
  store i32 %1, ptr %i, align 4
  %last = alloca i32, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %particle, ptr %ptr_deref, i32 0, i32 8
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %len, align 4
  %sub = sub i32 %mem_load, 1
  store i32 %sub, ptr %last, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %px = getelementptr inbounds nuw %particle, ptr %ptr_deref2, i32 0, i32 0
  %ptr_deref3 = load ptr, ptr %self, align 8
  %py = getelementptr inbounds nuw %particle, ptr %ptr_deref3, i32 0, i32 1
  %ptr_deref4 = load ptr, ptr %self, align 8
  %pz = getelementptr inbounds nuw %particle, ptr %ptr_deref4, i32 0, i32 2
  %ptr_deref5 = load ptr, ptr %self, align 8
  %vx = getelementptr inbounds nuw %particle, ptr %ptr_deref5, i32 0, i32 3
  %ptr_deref6 = load ptr, ptr %self, align 8
  %vy = getelementptr inbounds nuw %particle, ptr %ptr_deref6, i32 0, i32 4
  %ptr_deref7 = load ptr, ptr %self, align 8
  %vz = getelementptr inbounds nuw %particle, ptr %ptr_deref7, i32 0, i32 5
  %ptr_deref8 = load ptr, ptr %self, align 8
  %life = getelementptr inbounds nuw %particle, ptr %ptr_deref8, i32 0, i32 6
  %ptr_deref9 = load ptr, ptr %self, align 8
  %color = getelementptr inbounds nuw %particle, ptr %ptr_deref9, i32 0, i32 7
  %ptr_deref10 = load ptr, ptr %self, align 8
  %px11 = getelementptr inbounds nuw %particle, ptr %ptr_deref10, i32 0, i32 0
  %ptr_deref12 = load ptr, ptr %self, align 8
  %px13 = getelementptr inbounds nuw %particle, ptr %ptr_deref12, i32 0, i32 0
  %ptr_deref14 = load ptr, ptr %self, align 8
  %py15 = getelementptr inbounds nuw %particle, ptr %ptr_deref14, i32 0, i32 1
  %ptr_deref16 = load ptr, ptr %self, align 8
  %py17 = getelementptr inbounds nuw %particle, ptr %ptr_deref16, i32 0, i32 1
  %ptr_deref18 = load ptr, ptr %self, align 8
  %pz19 = getelementptr inbounds nuw %particle, ptr %ptr_deref18, i32 0, i32 2
  %ptr_deref20 = load ptr, ptr %self, align 8
  %pz21 = getelementptr inbounds nuw %particle, ptr %ptr_deref20, i32 0, i32 2
  %ptr_deref22 = load ptr, ptr %self, align 8
  %vx23 = getelementptr inbounds nuw %particle, ptr %ptr_deref22, i32 0, i32 3
  %ptr_deref24 = load ptr, ptr %self, align 8
  %vx25 = getelementptr inbounds nuw %particle, ptr %ptr_deref24, i32 0, i32 3
  %ptr_deref26 = load ptr, ptr %self, align 8
  %vy27 = getelementptr inbounds nuw %particle, ptr %ptr_deref26, i32 0, i32 4
  %ptr_deref28 = load ptr, ptr %self, align 8
  %vy29 = getelementptr inbounds nuw %particle, ptr %ptr_deref28, i32 0, i32 4
  %ptr_deref30 = load ptr, ptr %self, align 8
  %vz31 = getelementptr inbounds nuw %particle, ptr %ptr_deref30, i32 0, i32 5
  %ptr_deref32 = load ptr, ptr %self, align 8
  %vz33 = getelementptr inbounds nuw %particle, ptr %ptr_deref32, i32 0, i32 5
  %ptr_deref34 = load ptr, ptr %self, align 8
  %life35 = getelementptr inbounds nuw %particle, ptr %ptr_deref34, i32 0, i32 6
  %ptr_deref36 = load ptr, ptr %self, align 8
  %life37 = getelementptr inbounds nuw %particle, ptr %ptr_deref36, i32 0, i32 6
  %ptr_deref38 = load ptr, ptr %self, align 8
  %color39 = getelementptr inbounds nuw %particle, ptr %ptr_deref38, i32 0, i32 7
  %ptr_deref40 = load ptr, ptr %self, align 8
  %color41 = getelementptr inbounds nuw %particle, ptr %ptr_deref40, i32 0, i32 7
  %ptr_deref42 = load ptr, ptr %self, align 8
  %len43 = getelementptr inbounds nuw %particle, ptr %ptr_deref42, i32 0, i32 8
  %ptr_deref44 = load ptr, ptr %self, align 8
  %len45 = getelementptr inbounds nuw %particle, ptr %ptr_deref44, i32 0, i32 8
  %ptr_deref46 = load ptr, ptr %self, align 8
  %mem_load47 = load i32, ptr %len45, align 4
  %sub48 = sub i32 %mem_load47, 1
  store i32 %sub48, ptr %len43, align 4
  ret void
}

define void @particle__NS_tick(ptr %0, float %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %dt = alloca float, align 4
  store float %1, ptr %dt, align 4
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %particle, ptr %ptr_deref, i32 0, i32 8
  %ptr_deref2 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %len, align 4
  %icmp = icmp slt i32 %i1, %mem_load
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ptr_deref3 = load ptr, ptr %self, align 8
  %px = getelementptr inbounds nuw %particle, ptr %ptr_deref3, i32 0, i32 0
  %ptr_deref4 = load ptr, ptr %self, align 8
  %px5 = getelementptr inbounds nuw %particle, ptr %ptr_deref4, i32 0, i32 0
  %i6 = load i32, ptr %i, align 4
  %ptr_deref7 = load ptr, ptr %self, align 8
  %px8 = getelementptr inbounds nuw %particle, ptr %ptr_deref7, i32 0, i32 0
  %ptr_deref9 = load ptr, ptr %self, align 8
  %px10 = getelementptr inbounds nuw %particle, ptr %ptr_deref9, i32 0, i32 0
  %i11 = load i32, ptr %i, align 4
  %ptr_deref12 = load ptr, ptr %self, align 8
  %vx = getelementptr inbounds nuw %particle, ptr %ptr_deref12, i32 0, i32 3
  %ptr_deref13 = load ptr, ptr %self, align 8
  %vx14 = getelementptr inbounds nuw %particle, ptr %ptr_deref13, i32 0, i32 3
  %i15 = load i32, ptr %i, align 4
  %dt16 = load float, ptr %dt, align 4
  %ptr_deref17 = load ptr, ptr %self, align 8
  %py = getelementptr inbounds nuw %particle, ptr %ptr_deref17, i32 0, i32 1
  %ptr_deref18 = load ptr, ptr %self, align 8
  %py19 = getelementptr inbounds nuw %particle, ptr %ptr_deref18, i32 0, i32 1
  %i20 = load i32, ptr %i, align 4
  %ptr_deref21 = load ptr, ptr %self, align 8
  %py22 = getelementptr inbounds nuw %particle, ptr %ptr_deref21, i32 0, i32 1
  %ptr_deref23 = load ptr, ptr %self, align 8
  %py24 = getelementptr inbounds nuw %particle, ptr %ptr_deref23, i32 0, i32 1
  %i25 = load i32, ptr %i, align 4
  %ptr_deref26 = load ptr, ptr %self, align 8
  %vy = getelementptr inbounds nuw %particle, ptr %ptr_deref26, i32 0, i32 4
  %ptr_deref27 = load ptr, ptr %self, align 8
  %vy28 = getelementptr inbounds nuw %particle, ptr %ptr_deref27, i32 0, i32 4
  %i29 = load i32, ptr %i, align 4
  %dt30 = load float, ptr %dt, align 4
  %ptr_deref31 = load ptr, ptr %self, align 8
  %pz = getelementptr inbounds nuw %particle, ptr %ptr_deref31, i32 0, i32 2
  %ptr_deref32 = load ptr, ptr %self, align 8
  %pz33 = getelementptr inbounds nuw %particle, ptr %ptr_deref32, i32 0, i32 2
  %i34 = load i32, ptr %i, align 4
  %ptr_deref35 = load ptr, ptr %self, align 8
  %pz36 = getelementptr inbounds nuw %particle, ptr %ptr_deref35, i32 0, i32 2
  %ptr_deref37 = load ptr, ptr %self, align 8
  %pz38 = getelementptr inbounds nuw %particle, ptr %ptr_deref37, i32 0, i32 2
  %i39 = load i32, ptr %i, align 4
  %ptr_deref40 = load ptr, ptr %self, align 8
  %vz = getelementptr inbounds nuw %particle, ptr %ptr_deref40, i32 0, i32 5
  %ptr_deref41 = load ptr, ptr %self, align 8
  %vz42 = getelementptr inbounds nuw %particle, ptr %ptr_deref41, i32 0, i32 5
  %i43 = load i32, ptr %i, align 4
  %dt44 = load float, ptr %dt, align 4
  %ptr_deref45 = load ptr, ptr %self, align 8
  %life = getelementptr inbounds nuw %particle, ptr %ptr_deref45, i32 0, i32 6
  %ptr_deref46 = load ptr, ptr %self, align 8
  %life47 = getelementptr inbounds nuw %particle, ptr %ptr_deref46, i32 0, i32 6
  %i48 = load i32, ptr %i, align 4
  %ptr_deref49 = load ptr, ptr %self, align 8
  %life50 = getelementptr inbounds nuw %particle, ptr %ptr_deref49, i32 0, i32 6
  %ptr_deref51 = load ptr, ptr %self, align 8
  %life52 = getelementptr inbounds nuw %particle, ptr %ptr_deref51, i32 0, i32 6
  %i53 = load i32, ptr %i, align 4
  %dt54 = load float, ptr %dt, align 4
  %ptr_deref55 = load ptr, ptr %self, align 8
  %life56 = getelementptr inbounds nuw %particle, ptr %ptr_deref55, i32 0, i32 6
  %ptr_deref57 = load ptr, ptr %self, align 8
  %life58 = getelementptr inbounds nuw %particle, ptr %ptr_deref57, i32 0, i32 6
  %i59 = load i32, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  ret void
}

define void @particle__NS_deinit(ptr %0, %__memstr_fat__ %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %a = alloca %__memstr_fat__, align 8
  store %__memstr_fat__ %1, ptr %a, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %px = getelementptr inbounds nuw %particle, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %py = getelementptr inbounds nuw %particle, ptr %ptr_deref1, i32 0, i32 1
  %ptr_deref2 = load ptr, ptr %self, align 8
  %pz = getelementptr inbounds nuw %particle, ptr %ptr_deref2, i32 0, i32 2
  %ptr_deref3 = load ptr, ptr %self, align 8
  %vx = getelementptr inbounds nuw %particle, ptr %ptr_deref3, i32 0, i32 3
  %ptr_deref4 = load ptr, ptr %self, align 8
  %vy = getelementptr inbounds nuw %particle, ptr %ptr_deref4, i32 0, i32 4
  %ptr_deref5 = load ptr, ptr %self, align 8
  %vz = getelementptr inbounds nuw %particle, ptr %ptr_deref5, i32 0, i32 5
  %ptr_deref6 = load ptr, ptr %self, align 8
  %life = getelementptr inbounds nuw %particle, ptr %ptr_deref6, i32 0, i32 6
  %ptr_deref7 = load ptr, ptr %self, align 8
  %color = getelementptr inbounds nuw %particle, ptr %ptr_deref7, i32 0, i32 7
  %ptr_deref8 = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %particle, ptr %ptr_deref8, i32 0, i32 8
  store i32 0, ptr %len, align 4
  ret void
}

define void @transform__NS___construct__(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %transform, ptr %ptr_deref, i32 0, i32 10
  store i32 0, ptr %len, align 4
  ret void
}

define void @transform__NS_push_identity(ptr %0, %__memstr_fat__ %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %a = alloca %__memstr_fat__, align 8
  store %__memstr_fat__ %1, ptr %a, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %px = getelementptr inbounds nuw %transform, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %py = getelementptr inbounds nuw %transform, ptr %ptr_deref1, i32 0, i32 1
  %ptr_deref2 = load ptr, ptr %self, align 8
  %pz = getelementptr inbounds nuw %transform, ptr %ptr_deref2, i32 0, i32 2
  %ptr_deref3 = load ptr, ptr %self, align 8
  %sx = getelementptr inbounds nuw %transform, ptr %ptr_deref3, i32 0, i32 3
  %ptr_deref4 = load ptr, ptr %self, align 8
  %sy = getelementptr inbounds nuw %transform, ptr %ptr_deref4, i32 0, i32 4
  %ptr_deref5 = load ptr, ptr %self, align 8
  %sz = getelementptr inbounds nuw %transform, ptr %ptr_deref5, i32 0, i32 5
  %ptr_deref6 = load ptr, ptr %self, align 8
  %qx = getelementptr inbounds nuw %transform, ptr %ptr_deref6, i32 0, i32 6
  %ptr_deref7 = load ptr, ptr %self, align 8
  %qy = getelementptr inbounds nuw %transform, ptr %ptr_deref7, i32 0, i32 7
  %ptr_deref8 = load ptr, ptr %self, align 8
  %qz = getelementptr inbounds nuw %transform, ptr %ptr_deref8, i32 0, i32 8
  %ptr_deref9 = load ptr, ptr %self, align 8
  %qw = getelementptr inbounds nuw %transform, ptr %ptr_deref9, i32 0, i32 9
  %ptr_deref10 = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %transform, ptr %ptr_deref10, i32 0, i32 10
  %ptr_deref11 = load ptr, ptr %self, align 8
  %len12 = getelementptr inbounds nuw %transform, ptr %ptr_deref11, i32 0, i32 10
  %ptr_deref13 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %len12, align 4
  %add = add i32 %mem_load, 1
  store i32 %add, ptr %len, align 4
  ret void
}

define void @transform__NS_swap_erase(ptr %0, i32 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %i = alloca i32, align 4
  store i32 %1, ptr %i, align 4
  %last = alloca i32, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %transform, ptr %ptr_deref, i32 0, i32 10
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %len, align 4
  %sub = sub i32 %mem_load, 1
  store i32 %sub, ptr %last, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %px = getelementptr inbounds nuw %transform, ptr %ptr_deref2, i32 0, i32 0
  %ptr_deref3 = load ptr, ptr %self, align 8
  %py = getelementptr inbounds nuw %transform, ptr %ptr_deref3, i32 0, i32 1
  %ptr_deref4 = load ptr, ptr %self, align 8
  %pz = getelementptr inbounds nuw %transform, ptr %ptr_deref4, i32 0, i32 2
  %ptr_deref5 = load ptr, ptr %self, align 8
  %sx = getelementptr inbounds nuw %transform, ptr %ptr_deref5, i32 0, i32 3
  %ptr_deref6 = load ptr, ptr %self, align 8
  %sy = getelementptr inbounds nuw %transform, ptr %ptr_deref6, i32 0, i32 4
  %ptr_deref7 = load ptr, ptr %self, align 8
  %sz = getelementptr inbounds nuw %transform, ptr %ptr_deref7, i32 0, i32 5
  %ptr_deref8 = load ptr, ptr %self, align 8
  %qx = getelementptr inbounds nuw %transform, ptr %ptr_deref8, i32 0, i32 6
  %ptr_deref9 = load ptr, ptr %self, align 8
  %qy = getelementptr inbounds nuw %transform, ptr %ptr_deref9, i32 0, i32 7
  %ptr_deref10 = load ptr, ptr %self, align 8
  %qz = getelementptr inbounds nuw %transform, ptr %ptr_deref10, i32 0, i32 8
  %ptr_deref11 = load ptr, ptr %self, align 8
  %qw = getelementptr inbounds nuw %transform, ptr %ptr_deref11, i32 0, i32 9
  %ptr_deref12 = load ptr, ptr %self, align 8
  %px13 = getelementptr inbounds nuw %transform, ptr %ptr_deref12, i32 0, i32 0
  %ptr_deref14 = load ptr, ptr %self, align 8
  %px15 = getelementptr inbounds nuw %transform, ptr %ptr_deref14, i32 0, i32 0
  %ptr_deref16 = load ptr, ptr %self, align 8
  %py17 = getelementptr inbounds nuw %transform, ptr %ptr_deref16, i32 0, i32 1
  %ptr_deref18 = load ptr, ptr %self, align 8
  %py19 = getelementptr inbounds nuw %transform, ptr %ptr_deref18, i32 0, i32 1
  %ptr_deref20 = load ptr, ptr %self, align 8
  %pz21 = getelementptr inbounds nuw %transform, ptr %ptr_deref20, i32 0, i32 2
  %ptr_deref22 = load ptr, ptr %self, align 8
  %pz23 = getelementptr inbounds nuw %transform, ptr %ptr_deref22, i32 0, i32 2
  %ptr_deref24 = load ptr, ptr %self, align 8
  %sx25 = getelementptr inbounds nuw %transform, ptr %ptr_deref24, i32 0, i32 3
  %ptr_deref26 = load ptr, ptr %self, align 8
  %sx27 = getelementptr inbounds nuw %transform, ptr %ptr_deref26, i32 0, i32 3
  %ptr_deref28 = load ptr, ptr %self, align 8
  %sy29 = getelementptr inbounds nuw %transform, ptr %ptr_deref28, i32 0, i32 4
  %ptr_deref30 = load ptr, ptr %self, align 8
  %sy31 = getelementptr inbounds nuw %transform, ptr %ptr_deref30, i32 0, i32 4
  %ptr_deref32 = load ptr, ptr %self, align 8
  %sz33 = getelementptr inbounds nuw %transform, ptr %ptr_deref32, i32 0, i32 5
  %ptr_deref34 = load ptr, ptr %self, align 8
  %sz35 = getelementptr inbounds nuw %transform, ptr %ptr_deref34, i32 0, i32 5
  %ptr_deref36 = load ptr, ptr %self, align 8
  %qx37 = getelementptr inbounds nuw %transform, ptr %ptr_deref36, i32 0, i32 6
  %ptr_deref38 = load ptr, ptr %self, align 8
  %qx39 = getelementptr inbounds nuw %transform, ptr %ptr_deref38, i32 0, i32 6
  %ptr_deref40 = load ptr, ptr %self, align 8
  %qy41 = getelementptr inbounds nuw %transform, ptr %ptr_deref40, i32 0, i32 7
  %ptr_deref42 = load ptr, ptr %self, align 8
  %qy43 = getelementptr inbounds nuw %transform, ptr %ptr_deref42, i32 0, i32 7
  %ptr_deref44 = load ptr, ptr %self, align 8
  %qz45 = getelementptr inbounds nuw %transform, ptr %ptr_deref44, i32 0, i32 8
  %ptr_deref46 = load ptr, ptr %self, align 8
  %qz47 = getelementptr inbounds nuw %transform, ptr %ptr_deref46, i32 0, i32 8
  %ptr_deref48 = load ptr, ptr %self, align 8
  %qw49 = getelementptr inbounds nuw %transform, ptr %ptr_deref48, i32 0, i32 9
  %ptr_deref50 = load ptr, ptr %self, align 8
  %qw51 = getelementptr inbounds nuw %transform, ptr %ptr_deref50, i32 0, i32 9
  %ptr_deref52 = load ptr, ptr %self, align 8
  %len53 = getelementptr inbounds nuw %transform, ptr %ptr_deref52, i32 0, i32 10
  %ptr_deref54 = load ptr, ptr %self, align 8
  %len55 = getelementptr inbounds nuw %transform, ptr %ptr_deref54, i32 0, i32 10
  %ptr_deref56 = load ptr, ptr %self, align 8
  %mem_load57 = load i32, ptr %len55, align 4
  %sub58 = sub i32 %mem_load57, 1
  store i32 %sub58, ptr %len53, align 4
  ret void
}

define void @transform__NS_deinit(ptr %0, %__memstr_fat__ %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %a = alloca %__memstr_fat__, align 8
  store %__memstr_fat__ %1, ptr %a, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %px = getelementptr inbounds nuw %transform, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %py = getelementptr inbounds nuw %transform, ptr %ptr_deref1, i32 0, i32 1
  %ptr_deref2 = load ptr, ptr %self, align 8
  %pz = getelementptr inbounds nuw %transform, ptr %ptr_deref2, i32 0, i32 2
  %ptr_deref3 = load ptr, ptr %self, align 8
  %sx = getelementptr inbounds nuw %transform, ptr %ptr_deref3, i32 0, i32 3
  %ptr_deref4 = load ptr, ptr %self, align 8
  %sy = getelementptr inbounds nuw %transform, ptr %ptr_deref4, i32 0, i32 4
  %ptr_deref5 = load ptr, ptr %self, align 8
  %sz = getelementptr inbounds nuw %transform, ptr %ptr_deref5, i32 0, i32 5
  %ptr_deref6 = load ptr, ptr %self, align 8
  %qx = getelementptr inbounds nuw %transform, ptr %ptr_deref6, i32 0, i32 6
  %ptr_deref7 = load ptr, ptr %self, align 8
  %qy = getelementptr inbounds nuw %transform, ptr %ptr_deref7, i32 0, i32 7
  %ptr_deref8 = load ptr, ptr %self, align 8
  %qz = getelementptr inbounds nuw %transform, ptr %ptr_deref8, i32 0, i32 8
  %ptr_deref9 = load ptr, ptr %self, align 8
  %qw = getelementptr inbounds nuw %transform, ptr %ptr_deref9, i32 0, i32 9
  %ptr_deref10 = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %transform, ptr %ptr_deref10, i32 0, i32 10
  store i32 0, ptr %len, align 4
  ret void
}

define i32 @main() {
entry:
  ret i32 0
}
