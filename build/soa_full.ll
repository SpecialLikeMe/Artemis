; ModuleID = 'build/soa_full.arc'
source_filename = "build/soa_full.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%soa_layout = type { ptr, i64, [64 x ptr], i32, i32 }
%__memstr_fat__ = type { ptr, ptr }
%type_info = type { ptr, i32, i32, i32, i32, i32, i32, ptr, ptr, i32, ptr }
%type_info_field = type { ptr, i32, i32, i32 }
%vec2f = type { i8, i8, i32 }
%vec3f = type { i8, i8, i8, i32 }
%particle = type { i8, i8, i8, i8, i8, i8, i8, i8, i32 }
%transform = type { i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i32 }

@soa__NS_SOA_MAX_FIELDS = global i32 64

declare ptr @memcpy(ptr, ptr, i64)

define %soa_layout @soa__NS_make_soa(ptr %0, ptr %1, i32 %2, %__memstr_fat__ %3) {
entry:
  %src = alloca ptr, align 8
  store ptr %0, ptr %src, align 8
  %info = alloca ptr, align 8
  store ptr %1, ptr %info, align 8
  %count = alloca i32, align 4
  store i32 %2, ptr %count, align 4
  %scratch = alloca %__memstr_fat__, align 8
  store %__memstr_fat__ %3, ptr %scratch, align 8
  %layout = alloca %soa_layout, align 8
  store %soa_layout zeroinitializer, ptr %layout, align 8
  %field_count = getelementptr inbounds nuw %soa_layout, ptr %layout, i32 0, i32 3
  %ptr_deref = load ptr, ptr %info, align 8
  %field_count1 = getelementptr inbounds nuw %type_info, ptr %ptr_deref, i32 0, i32 6
  %ptr_deref2 = load ptr, ptr %info, align 8
  %mem_load = load i32, ptr %field_count1, align 4
  store i32 %mem_load, ptr %field_count, align 4
  %element_count = getelementptr inbounds nuw %soa_layout, ptr %layout, i32 0, i32 4
  %count3 = load i32, ptr %count, align 4
  store i32 %count3, ptr %element_count, align 4
  %block = getelementptr inbounds nuw %soa_layout, ptr %layout, i32 0, i32 0
  store ptr null, ptr %block, align 8
  %block_size = getelementptr inbounds nuw %soa_layout, ptr %layout, i32 0, i32 1
  store i64 0, ptr %block_size, align 4
  %ptr_deref4 = load ptr, ptr %info, align 8
  %field_count5 = getelementptr inbounds nuw %type_info, ptr %ptr_deref4, i32 0, i32 6
  %ptr_deref6 = load ptr, ptr %info, align 8
  %mem_load7 = load i32, ptr %field_count5, align 4
  %icmp = icmp sle i32 %mem_load7, 0
  br i1 %icmp, label %lor_merge, label %lor_rhs

lor_rhs:                                          ; preds = %entry
  %count8 = load i32, ptr %count, align 4
  %icmp9 = icmp sle i32 %count8, 0
  br label %lor_merge

lor_merge:                                        ; preds = %lor_rhs, %entry
  %lor = phi i1 [ true, %entry ], [ %icmp9, %lor_rhs ]
  br i1 %lor, label %lor_merge11, label %lor_rhs10

lor_rhs10:                                        ; preds = %lor_merge
  %src12 = load ptr, ptr %src, align 8
  %icmp13 = icmp eq ptr %src12, null
  br label %lor_merge11

lor_merge11:                                      ; preds = %lor_rhs10, %lor_merge
  %lor14 = phi i1 [ true, %lor_merge ], [ %icmp13, %lor_rhs10 ]
  br i1 %lor14, label %if_then, label %if_merge

if_then:                                          ; preds = %lor_merge11
  %layout15 = load %soa_layout, ptr %layout, align 8
  ret %soa_layout %layout15

if_merge:                                         ; preds = %lor_merge11
  %ptr_deref16 = load ptr, ptr %info, align 8
  %field_count17 = getelementptr inbounds nuw %type_info, ptr %ptr_deref16, i32 0, i32 6
  %ptr_deref18 = load ptr, ptr %info, align 8
  %mem_load19 = load i32, ptr %field_count17, align 4
  %SOA_MAX_FIELDS = load i32, ptr @soa__NS_SOA_MAX_FIELDS, align 4
  %icmp20 = icmp sgt i32 %mem_load19, %SOA_MAX_FIELDS
  br i1 %icmp20, label %if_then21, label %if_merge22

if_then21:                                        ; preds = %if_merge
  %layout23 = load %soa_layout, ptr %layout, align 8
  ret %soa_layout %layout23

if_merge22:                                       ; preds = %if_merge
  %total = alloca i64, align 8
  store i64 0, ptr %total, align 4
  %f = alloca i32, align 4
  store i32 0, ptr %f, align 4
  br label %for_cond

for_cond:                                         ; preds = %for_step, %if_merge22
  %f24 = load i32, ptr %f, align 4
  %ptr_deref25 = load ptr, ptr %info, align 8
  %field_count26 = getelementptr inbounds nuw %type_info, ptr %ptr_deref25, i32 0, i32 6
  %ptr_deref27 = load ptr, ptr %info, align 8
  %mem_load28 = load i32, ptr %field_count26, align 4
  %icmp29 = icmp slt i32 %f24, %mem_load28
  br i1 %icmp29, label %for_body, label %for_exit

for_body:                                         ; preds = %for_cond
  %field_sz = alloca i64, align 8
  %ptr_deref30 = load ptr, ptr %info, align 8
  %fields = getelementptr inbounds nuw %type_info, ptr %ptr_deref30, i32 0, i32 7
  %f31 = load i32, ptr %f, align 4
  %ptr_load = load ptr, ptr %fields, align 8
  %ptr_gep = getelementptr %type_info_field, ptr %ptr_load, i32 %f31
  %size = getelementptr inbounds nuw %type_info_field, ptr %ptr_gep, i32 0, i32 2
  %ptr_deref32 = load ptr, ptr %info, align 8
  %fields33 = getelementptr inbounds nuw %type_info, ptr %ptr_deref32, i32 0, i32 7
  %f34 = load i32, ptr %f, align 4
  %ptr_load35 = load ptr, ptr %fields33, align 8
  %ptr_gep36 = getelementptr %type_info_field, ptr %ptr_load35, i32 %f34
  %mem_load37 = load i32, ptr %size, align 4
  %zext = zext i32 %mem_load37 to i64
  store i64 %zext, ptr %field_sz, align 4
  %row_bytes = alloca i64, align 8
  %field_sz38 = load i64, ptr %field_sz, align 4
  %count39 = load i32, ptr %count, align 4
  %zext40 = zext i32 %count39 to i64
  %mul = mul i64 %field_sz38, %zext40
  store i64 %mul, ptr %row_bytes, align 4
  %row_bytes41 = load i64, ptr %row_bytes, align 4
  %add = add i64 %row_bytes41, 15
  %and = and i64 %add, -16
  store i64 %and, ptr %row_bytes, align 4
  %total42 = load i64, ptr %total, align 4
  %row_bytes43 = load i64, ptr %row_bytes, align 4
  %add44 = add i64 %total42, %row_bytes43
  store i64 %add44, ptr %total, align 4
  br label %for_step

for_step:                                         ; preds = %for_body
  %f45 = load i32, ptr %f, align 4
  %add46 = add i32 %f45, 1
  store i32 %add46, ptr %f, align 4
  br label %for_cond

for_exit:                                         ; preds = %for_cond
  %block47 = alloca ptr, align 8
  %fat = load %__memstr_fat__, ptr %scratch, align 8
  %ms_data = extractvalue %__memstr_fat__ %fat, 0
  %ms_vtbl = extractvalue %__memstr_fat__ %fat, 1
  %vtslot = getelementptr { ptr, ptr, ptr }, ptr %ms_vtbl, i32 0, i32 0
  %fnptr = load ptr, ptr %vtslot, align 8
  %total48 = load i64, ptr %total, align 4
  %4 = call ptr %fnptr(ptr %ms_data, i64 %total48)
  store ptr %4, ptr %block47, align 8
  %block49 = getelementptr inbounds nuw %soa_layout, ptr %layout, i32 0, i32 0
  %block50 = load ptr, ptr %block47, align 8
  store ptr %block50, ptr %block49, align 8
  %block_size51 = getelementptr inbounds nuw %soa_layout, ptr %layout, i32 0, i32 1
  %total52 = load i64, ptr %total, align 4
  store i64 %total52, ptr %block_size51, align 4
  %offset = alloca i64, align 8
  store i64 0, ptr %offset, align 4
  %f53 = alloca i32, align 4
  store i32 0, ptr %f53, align 4
  br label %for_cond54

for_cond54:                                       ; preds = %for_step56, %for_exit
  %f58 = load i32, ptr %f53, align 4
  %ptr_deref59 = load ptr, ptr %info, align 8
  %field_count60 = getelementptr inbounds nuw %type_info, ptr %ptr_deref59, i32 0, i32 6
  %ptr_deref61 = load ptr, ptr %info, align 8
  %mem_load62 = load i32, ptr %field_count60, align 4
  %icmp63 = icmp slt i32 %f58, %mem_load62
  br i1 %icmp63, label %for_body55, label %for_exit57

for_body55:                                       ; preds = %for_cond54
  %field_ptrs = getelementptr inbounds nuw %soa_layout, ptr %layout, i32 0, i32 2
  %f64 = load i32, ptr %f53, align 4
  %arr_gep = getelementptr [64 x ptr], ptr %field_ptrs, i64 0, i32 %f64
  %block65 = load ptr, ptr %block47, align 8
  %offset66 = load i64, ptr %offset, align 4
  %ptr_add = getelementptr i8, ptr %block65, i64 %offset66
  store ptr %ptr_add, ptr %arr_gep, align 8
  %field_sz67 = alloca i64, align 8
  %ptr_deref68 = load ptr, ptr %info, align 8
  %fields69 = getelementptr inbounds nuw %type_info, ptr %ptr_deref68, i32 0, i32 7
  %f70 = load i32, ptr %f53, align 4
  %ptr_load71 = load ptr, ptr %fields69, align 8
  %ptr_gep72 = getelementptr %type_info_field, ptr %ptr_load71, i32 %f70
  %size73 = getelementptr inbounds nuw %type_info_field, ptr %ptr_gep72, i32 0, i32 2
  %ptr_deref74 = load ptr, ptr %info, align 8
  %fields75 = getelementptr inbounds nuw %type_info, ptr %ptr_deref74, i32 0, i32 7
  %f76 = load i32, ptr %f53, align 4
  %ptr_load77 = load ptr, ptr %fields75, align 8
  %ptr_gep78 = getelementptr %type_info_field, ptr %ptr_load77, i32 %f76
  %mem_load79 = load i32, ptr %size73, align 4
  %zext80 = zext i32 %mem_load79 to i64
  store i64 %zext80, ptr %field_sz67, align 4
  %row_bytes81 = alloca i64, align 8
  %field_sz82 = load i64, ptr %field_sz67, align 4
  %count83 = load i32, ptr %count, align 4
  %zext84 = zext i32 %count83 to i64
  %mul85 = mul i64 %field_sz82, %zext84
  %add86 = add i64 %mul85, 15
  %and87 = and i64 %add86, -16
  store i64 %and87, ptr %row_bytes81, align 4
  %b = alloca i64, align 8
  store i64 0, ptr %b, align 4
  br label %for_cond88

for_step56:                                       ; preds = %for_exit91
  %f105 = load i32, ptr %f53, align 4
  %add106 = add i32 %f105, 1
  store i32 %add106, ptr %f53, align 4
  br label %for_cond54

for_exit57:                                       ; preds = %for_cond54
  %src_bytes = alloca ptr, align 8
  %src107 = load ptr, ptr %src, align 8
  store ptr %src107, ptr %src_bytes, align 8
  %elem = alloca i32, align 4
  store i32 0, ptr %elem, align 4
  br label %for_cond108

for_cond88:                                       ; preds = %for_step90, %for_body55
  %b92 = load i64, ptr %b, align 4
  %row_bytes93 = load i64, ptr %row_bytes81, align 4
  %icmp94 = icmp ult i64 %b92, %row_bytes93
  br i1 %icmp94, label %for_body89, label %for_exit91

for_body89:                                       ; preds = %for_cond88
  %offset95 = load i64, ptr %offset, align 4
  %b96 = load i64, ptr %b, align 4
  %add97 = add i64 %offset95, %b96
  %ptr_load98 = load ptr, ptr %block47, align 8
  %ptr_gep99 = getelementptr i8, ptr %ptr_load98, i64 %add97
  store i8 0, ptr %ptr_gep99, align 1
  br label %for_step90

for_step90:                                       ; preds = %for_body89
  %b100 = load i64, ptr %b, align 4
  %add101 = add i64 %b100, 1
  store i64 %add101, ptr %b, align 4
  br label %for_cond88

for_exit91:                                       ; preds = %for_cond88
  %offset102 = load i64, ptr %offset, align 4
  %row_bytes103 = load i64, ptr %row_bytes81, align 4
  %add104 = add i64 %offset102, %row_bytes103
  store i64 %add104, ptr %offset, align 4
  br label %for_step56

for_cond108:                                      ; preds = %for_step110, %for_exit57
  %elem112 = load i32, ptr %elem, align 4
  %count113 = load i32, ptr %count, align 4
  %icmp114 = icmp slt i32 %elem112, %count113
  br i1 %icmp114, label %for_body109, label %for_exit111

for_body109:                                      ; preds = %for_cond108
  %elem_ptr = alloca ptr, align 8
  %src_bytes115 = load ptr, ptr %src_bytes, align 8
  %elem116 = load i32, ptr %elem, align 4
  %sext = sext i32 %elem116 to i64
  %ptr_deref117 = load ptr, ptr %info, align 8
  %size118 = getelementptr inbounds nuw %type_info, ptr %ptr_deref117, i32 0, i32 1
  %ptr_deref119 = load ptr, ptr %info, align 8
  %mem_load120 = load i32, ptr %size118, align 4
  %sext121 = sext i32 %mem_load120 to i64
  %mul122 = mul i64 %sext, %sext121
  %ptr_add123 = getelementptr i8, ptr %src_bytes115, i64 %mul122
  store ptr %ptr_add123, ptr %elem_ptr, align 8
  %f124 = alloca i32, align 4
  store i32 0, ptr %f124, align 4
  br label %for_cond125

for_step110:                                      ; preds = %for_exit128
  %elem177 = load i32, ptr %elem, align 4
  %add178 = add i32 %elem177, 1
  store i32 %add178, ptr %elem, align 4
  br label %for_cond108

for_exit111:                                      ; preds = %for_cond108
  %layout179 = load %soa_layout, ptr %layout, align 8
  ret %soa_layout %layout179

for_cond125:                                      ; preds = %for_step127, %for_body109
  %f129 = load i32, ptr %f124, align 4
  %ptr_deref130 = load ptr, ptr %info, align 8
  %field_count131 = getelementptr inbounds nuw %type_info, ptr %ptr_deref130, i32 0, i32 6
  %ptr_deref132 = load ptr, ptr %info, align 8
  %mem_load133 = load i32, ptr %field_count131, align 4
  %icmp134 = icmp slt i32 %f129, %mem_load133
  br i1 %icmp134, label %for_body126, label %for_exit128

for_body126:                                      ; preds = %for_cond125
  %foff = alloca i32, align 4
  %ptr_deref135 = load ptr, ptr %info, align 8
  %fields136 = getelementptr inbounds nuw %type_info, ptr %ptr_deref135, i32 0, i32 7
  %f137 = load i32, ptr %f124, align 4
  %ptr_load138 = load ptr, ptr %fields136, align 8
  %ptr_gep139 = getelementptr %type_info_field, ptr %ptr_load138, i32 %f137
  %offset140 = getelementptr inbounds nuw %type_info_field, ptr %ptr_gep139, i32 0, i32 1
  %ptr_deref141 = load ptr, ptr %info, align 8
  %fields142 = getelementptr inbounds nuw %type_info, ptr %ptr_deref141, i32 0, i32 7
  %f143 = load i32, ptr %f124, align 4
  %ptr_load144 = load ptr, ptr %fields142, align 8
  %ptr_gep145 = getelementptr %type_info_field, ptr %ptr_load144, i32 %f143
  %mem_load146 = load i32, ptr %offset140, align 4
  store i32 %mem_load146, ptr %foff, align 4
  %fsz = alloca i32, align 4
  %ptr_deref147 = load ptr, ptr %info, align 8
  %fields148 = getelementptr inbounds nuw %type_info, ptr %ptr_deref147, i32 0, i32 7
  %f149 = load i32, ptr %f124, align 4
  %ptr_load150 = load ptr, ptr %fields148, align 8
  %ptr_gep151 = getelementptr %type_info_field, ptr %ptr_load150, i32 %f149
  %size152 = getelementptr inbounds nuw %type_info_field, ptr %ptr_gep151, i32 0, i32 2
  %ptr_deref153 = load ptr, ptr %info, align 8
  %fields154 = getelementptr inbounds nuw %type_info, ptr %ptr_deref153, i32 0, i32 7
  %f155 = load i32, ptr %f124, align 4
  %ptr_load156 = load ptr, ptr %fields154, align 8
  %ptr_gep157 = getelementptr %type_info_field, ptr %ptr_load156, i32 %f155
  %mem_load158 = load i32, ptr %size152, align 4
  store i32 %mem_load158, ptr %fsz, align 4
  %dst_row = alloca ptr, align 8
  %field_ptrs159 = getelementptr inbounds nuw %soa_layout, ptr %layout, i32 0, i32 2
  %f160 = load i32, ptr %f124, align 4
  %arr_gep161 = getelementptr [64 x ptr], ptr %field_ptrs159, i64 0, i32 %f160
  %idx_load = load ptr, ptr %arr_gep161, align 8
  store ptr %idx_load, ptr %dst_row, align 8
  %src_field = alloca ptr, align 8
  %elem_ptr162 = load ptr, ptr %elem_ptr, align 8
  %foff163 = load i32, ptr %foff, align 4
  %ptr_add164 = getelementptr i8, ptr %elem_ptr162, i32 %foff163
  store ptr %ptr_add164, ptr %src_field, align 8
  %dst_row165 = load ptr, ptr %dst_row, align 8
  %elem166 = load i32, ptr %elem, align 4
  %sext167 = sext i32 %elem166 to i64
  %fsz168 = load i32, ptr %fsz, align 4
  %sext169 = sext i32 %fsz168 to i64
  %mul170 = mul i64 %sext167, %sext169
  %ptr_add171 = getelementptr i8, ptr %dst_row165, i64 %mul170
  %src_field172 = load ptr, ptr %src_field, align 8
  %fsz173 = load i32, ptr %fsz, align 4
  %zext174 = zext i32 %fsz173 to i64
  %5 = call ptr @memcpy(ptr %ptr_add171, ptr %src_field172, i64 %zext174)
  br label %for_step127

for_step127:                                      ; preds = %for_body126
  %f175 = load i32, ptr %f124, align 4
  %add176 = add i32 %f175, 1
  store i32 %add176, ptr %f124, align 4
  br label %for_cond125

for_exit128:                                      ; preds = %for_cond125
  br label %for_step110
}

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
