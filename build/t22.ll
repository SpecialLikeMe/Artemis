; ModuleID = 'tcon/std/022_json_basic.arc'
source_filename = "tcon/std/022_json_basic.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%__memstr_fat__ = type { ptr, ptr }
%json_val = type { i32, i8, i64, double, ptr, ptr, i32, ptr, i32 }
%lex = type { ptr, i32, i32 }
%json_pair = type { ptr, ptr }
%Bump = type { ptr, i64, i64 }

@json__NS_JSON_NULL = global i32 0
@json__NS_JSON_BOOL = global i32 1
@json__NS_JSON_INT = global i32 2
@json__NS_JSON_FLOAT = global i32 3
@json__NS_JSON_STRING = global i32 4
@json__NS_JSON_ARRAY = global i32 5
@json__NS_JSON_OBJECT = global i32 6
@Bump__vtable__ = constant { ptr, ptr, ptr } { ptr @Bump__NS_mmap, ptr @Bump__NS_rmap, ptr @Bump__NS_deinit }
@str = private unnamed_addr constant [3 x i8] c"42\00", align 1
@str.1 = private unnamed_addr constant [5 x i8] c"true\00", align 1
@str.2 = private unnamed_addr constant [8 x i8] c"[1,2,3]\00", align 1
@str.3 = private unnamed_addr constant [8 x i8] c"{\22n\22:7}\00", align 1
@str.4 = private unnamed_addr constant [2 x i8] c"n\00", align 1

define ptr @json__NS_parse_value(ptr %0, %__memstr_fat__ %1) {
entry:
  %l = alloca ptr, align 8
  store ptr %0, ptr %l, align 8
  %a = alloca %__memstr_fat__, align 8
  store %__memstr_fat__ %1, ptr %a, align 8
  %l1 = load ptr, ptr %l, align 8
  call void @lex__NS_skip_ws(ptr %l1)
  %c = alloca i8, align 1
  %l2 = load ptr, ptr %l, align 8
  %2 = call i8 @lex__NS_peek(ptr %l2)
  store i8 %2, ptr %c, align 1
  %v = alloca ptr, align 8
  %fat = load %__memstr_fat__, ptr %a, align 8
  %ms_data = extractvalue %__memstr_fat__ %fat, 0
  %ms_vtbl = extractvalue %__memstr_fat__ %fat, 1
  %vtslot = getelementptr { ptr, ptr, ptr }, ptr %ms_vtbl, i32 0, i32 0
  %fnptr = load ptr, ptr %vtslot, align 8
  %3 = call ptr %fnptr(ptr %ms_data, i64 ptrtoint (ptr getelementptr (%json_val, ptr null, i32 1) to i64))
  store ptr %3, ptr %v, align 8
  %c3 = load i8, ptr %c, align 1
  %icmp = icmp eq i8 %c3, 34
  br i1 %icmp, label %if_then, label %if_else

if_then:                                          ; preds = %entry
  %ptr_deref = load ptr, ptr %v, align 8
  %kind = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 0
  %JSON_STRING = load i32, ptr @json__NS_JSON_STRING, align 4
  store i32 %JSON_STRING, ptr %kind, align 4
  %ptr_deref4 = load ptr, ptr %v, align 8
  %s_val = getelementptr inbounds nuw %json_val, ptr %ptr_deref4, i32 0, i32 4
  %l5 = load ptr, ptr %l, align 8
  %a6 = load %__memstr_fat__, ptr %a, align 8
  %4 = call ptr @json__NS_parse_string_raw(ptr %l5, %__memstr_fat__ %a6)
  store ptr %4, ptr %s_val, align 8
  br label %if_merge

if_else:                                          ; preds = %entry
  %c7 = load i8, ptr %c, align 1
  %icmp8 = icmp eq i8 %c7, 123
  br i1 %icmp8, label %if_then9, label %if_else10

if_merge:                                         ; preds = %if_merge11, %if_then
  %v438 = load ptr, ptr %v, align 8
  ret ptr %v438

if_then9:                                         ; preds = %if_else
  %l12 = load ptr, ptr %l, align 8
  %a13 = load %__memstr_fat__, ptr %a, align 8
  %5 = call ptr @json__NS_parse_object(ptr %l12, %__memstr_fat__ %a13)
  ret ptr %5

if_else10:                                        ; preds = %if_else
  %c14 = load i8, ptr %c, align 1
  %icmp15 = icmp eq i8 %c14, 91
  br i1 %icmp15, label %if_then16, label %if_else17

if_merge11:                                       ; preds = %if_merge18
  br label %if_merge

if_then16:                                        ; preds = %if_else10
  %l19 = load ptr, ptr %l, align 8
  %a20 = load %__memstr_fat__, ptr %a, align 8
  %6 = call ptr @json__NS_parse_array(ptr %l19, %__memstr_fat__ %a20)
  ret ptr %6

if_else17:                                        ; preds = %if_else10
  %c21 = load i8, ptr %c, align 1
  %icmp22 = icmp eq i8 %c21, 116
  br i1 %icmp22, label %if_then23, label %if_else24

if_merge18:                                       ; preds = %if_merge25
  br label %if_merge11

if_then23:                                        ; preds = %if_else17
  %ptr_deref26 = load ptr, ptr %l, align 8
  %pos = getelementptr inbounds nuw %lex, ptr %ptr_deref26, i32 0, i32 1
  %ptr_deref27 = load ptr, ptr %l, align 8
  %pos28 = getelementptr inbounds nuw %lex, ptr %ptr_deref27, i32 0, i32 1
  %ptr_deref29 = load ptr, ptr %l, align 8
  %mem_load = load i32, ptr %pos28, align 4
  %add = add i32 %mem_load, 4
  store i32 %add, ptr %pos, align 4
  %ptr_deref30 = load ptr, ptr %v, align 8
  %kind31 = getelementptr inbounds nuw %json_val, ptr %ptr_deref30, i32 0, i32 0
  %JSON_BOOL = load i32, ptr @json__NS_JSON_BOOL, align 4
  store i32 %JSON_BOOL, ptr %kind31, align 4
  %ptr_deref32 = load ptr, ptr %v, align 8
  %b_val = getelementptr inbounds nuw %json_val, ptr %ptr_deref32, i32 0, i32 1
  store i8 1, ptr %b_val, align 1
  br label %if_merge25

if_else24:                                        ; preds = %if_else17
  %c33 = load i8, ptr %c, align 1
  %icmp34 = icmp eq i8 %c33, 102
  br i1 %icmp34, label %if_then35, label %if_else36

if_merge25:                                       ; preds = %if_merge37, %if_then23
  br label %if_merge18

if_then35:                                        ; preds = %if_else24
  %ptr_deref38 = load ptr, ptr %l, align 8
  %pos39 = getelementptr inbounds nuw %lex, ptr %ptr_deref38, i32 0, i32 1
  %ptr_deref40 = load ptr, ptr %l, align 8
  %pos41 = getelementptr inbounds nuw %lex, ptr %ptr_deref40, i32 0, i32 1
  %ptr_deref42 = load ptr, ptr %l, align 8
  %mem_load43 = load i32, ptr %pos41, align 4
  %add44 = add i32 %mem_load43, 5
  store i32 %add44, ptr %pos39, align 4
  %ptr_deref45 = load ptr, ptr %v, align 8
  %kind46 = getelementptr inbounds nuw %json_val, ptr %ptr_deref45, i32 0, i32 0
  %JSON_BOOL47 = load i32, ptr @json__NS_JSON_BOOL, align 4
  store i32 %JSON_BOOL47, ptr %kind46, align 4
  %ptr_deref48 = load ptr, ptr %v, align 8
  %b_val49 = getelementptr inbounds nuw %json_val, ptr %ptr_deref48, i32 0, i32 1
  store i8 0, ptr %b_val49, align 1
  br label %if_merge37

if_else36:                                        ; preds = %if_else24
  %c50 = load i8, ptr %c, align 1
  %icmp51 = icmp eq i8 %c50, 110
  br i1 %icmp51, label %if_then52, label %if_else53

if_merge37:                                       ; preds = %if_merge54, %if_then35
  br label %if_merge25

if_then52:                                        ; preds = %if_else36
  %ptr_deref55 = load ptr, ptr %l, align 8
  %pos56 = getelementptr inbounds nuw %lex, ptr %ptr_deref55, i32 0, i32 1
  %ptr_deref57 = load ptr, ptr %l, align 8
  %pos58 = getelementptr inbounds nuw %lex, ptr %ptr_deref57, i32 0, i32 1
  %ptr_deref59 = load ptr, ptr %l, align 8
  %mem_load60 = load i32, ptr %pos58, align 4
  %add61 = add i32 %mem_load60, 4
  store i32 %add61, ptr %pos56, align 4
  %ptr_deref62 = load ptr, ptr %v, align 8
  %kind63 = getelementptr inbounds nuw %json_val, ptr %ptr_deref62, i32 0, i32 0
  %JSON_NULL = load i32, ptr @json__NS_JSON_NULL, align 4
  store i32 %JSON_NULL, ptr %kind63, align 4
  br label %if_merge54

if_else53:                                        ; preds = %if_else36
  %start = alloca i32, align 4
  %ptr_deref64 = load ptr, ptr %l, align 8
  %pos65 = getelementptr inbounds nuw %lex, ptr %ptr_deref64, i32 0, i32 1
  %ptr_deref66 = load ptr, ptr %l, align 8
  %mem_load67 = load i32, ptr %pos65, align 4
  store i32 %mem_load67, ptr %start, align 4
  %is_float = alloca i8, align 1
  store i8 0, ptr %is_float, align 1
  %l68 = load ptr, ptr %l, align 8
  %7 = call i8 @lex__NS_peek(ptr %l68)
  %icmp69 = icmp eq i8 %7, 45
  br i1 %icmp69, label %if_then70, label %if_merge71

if_merge54:                                       ; preds = %if_merge322, %if_then52
  br label %if_merge37

if_then70:                                        ; preds = %if_else53
  %ptr_deref72 = load ptr, ptr %l, align 8
  %pos73 = getelementptr inbounds nuw %lex, ptr %ptr_deref72, i32 0, i32 1
  %ptr_deref74 = load ptr, ptr %l, align 8
  %pos75 = getelementptr inbounds nuw %lex, ptr %ptr_deref74, i32 0, i32 1
  %ptr_deref76 = load ptr, ptr %l, align 8
  %mem_load77 = load i32, ptr %pos75, align 4
  %add78 = add i32 %mem_load77, 1
  store i32 %add78, ptr %pos73, align 4
  br label %if_merge71

if_merge71:                                       ; preds = %if_then70, %if_else53
  br label %while_cond

while_cond:                                       ; preds = %while_body, %if_merge71
  %ptr_deref79 = load ptr, ptr %l, align 8
  %pos80 = getelementptr inbounds nuw %lex, ptr %ptr_deref79, i32 0, i32 1
  %ptr_deref81 = load ptr, ptr %l, align 8
  %mem_load82 = load i32, ptr %pos80, align 4
  %ptr_deref83 = load ptr, ptr %l, align 8
  %len = getelementptr inbounds nuw %lex, ptr %ptr_deref83, i32 0, i32 2
  %ptr_deref84 = load ptr, ptr %l, align 8
  %mem_load85 = load i32, ptr %len, align 4
  %icmp86 = icmp slt i32 %mem_load82, %mem_load85
  br i1 %icmp86, label %land_rhs, label %land_merge

while_body:                                       ; preds = %land_merge94
  %ptr_deref106 = load ptr, ptr %l, align 8
  %pos107 = getelementptr inbounds nuw %lex, ptr %ptr_deref106, i32 0, i32 1
  %ptr_deref108 = load ptr, ptr %l, align 8
  %pos109 = getelementptr inbounds nuw %lex, ptr %ptr_deref108, i32 0, i32 1
  %ptr_deref110 = load ptr, ptr %l, align 8
  %mem_load111 = load i32, ptr %pos109, align 4
  %add112 = add i32 %mem_load111, 1
  store i32 %add112, ptr %pos107, align 4
  br label %while_cond

while_exit:                                       ; preds = %land_merge94
  %ptr_deref113 = load ptr, ptr %l, align 8
  %pos114 = getelementptr inbounds nuw %lex, ptr %ptr_deref113, i32 0, i32 1
  %ptr_deref115 = load ptr, ptr %l, align 8
  %mem_load116 = load i32, ptr %pos114, align 4
  %ptr_deref117 = load ptr, ptr %l, align 8
  %len118 = getelementptr inbounds nuw %lex, ptr %ptr_deref117, i32 0, i32 2
  %ptr_deref119 = load ptr, ptr %l, align 8
  %mem_load120 = load i32, ptr %len118, align 4
  %icmp121 = icmp slt i32 %mem_load116, %mem_load120
  br i1 %icmp121, label %land_rhs122, label %land_merge123

land_rhs:                                         ; preds = %while_cond
  %ptr_deref87 = load ptr, ptr %l, align 8
  %src = getelementptr inbounds nuw %lex, ptr %ptr_deref87, i32 0, i32 0
  %ptr_deref88 = load ptr, ptr %l, align 8
  %pos89 = getelementptr inbounds nuw %lex, ptr %ptr_deref88, i32 0, i32 1
  %ptr_deref90 = load ptr, ptr %l, align 8
  %mem_load91 = load i32, ptr %pos89, align 4
  %ptr_load = load ptr, ptr %src, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load91
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp92 = icmp sge i8 %idx_load, 48
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond
  %land = phi i1 [ false, %while_cond ], [ %icmp92, %land_rhs ]
  br i1 %land, label %land_rhs93, label %land_merge94

land_rhs93:                                       ; preds = %land_merge
  %ptr_deref95 = load ptr, ptr %l, align 8
  %src96 = getelementptr inbounds nuw %lex, ptr %ptr_deref95, i32 0, i32 0
  %ptr_deref97 = load ptr, ptr %l, align 8
  %pos98 = getelementptr inbounds nuw %lex, ptr %ptr_deref97, i32 0, i32 1
  %ptr_deref99 = load ptr, ptr %l, align 8
  %mem_load100 = load i32, ptr %pos98, align 4
  %ptr_load101 = load ptr, ptr %src96, align 8
  %ptr_gep102 = getelementptr i8, ptr %ptr_load101, i32 %mem_load100
  %idx_load103 = load i8, ptr %ptr_gep102, align 1
  %icmp104 = icmp sle i8 %idx_load103, 57
  br label %land_merge94

land_merge94:                                     ; preds = %land_rhs93, %land_merge
  %land105 = phi i1 [ false, %land_merge ], [ %icmp104, %land_rhs93 ]
  br i1 %land105, label %while_body, label %while_exit

land_rhs122:                                      ; preds = %while_exit
  %ptr_deref124 = load ptr, ptr %l, align 8
  %src125 = getelementptr inbounds nuw %lex, ptr %ptr_deref124, i32 0, i32 0
  %ptr_deref126 = load ptr, ptr %l, align 8
  %pos127 = getelementptr inbounds nuw %lex, ptr %ptr_deref126, i32 0, i32 1
  %ptr_deref128 = load ptr, ptr %l, align 8
  %mem_load129 = load i32, ptr %pos127, align 4
  %ptr_load130 = load ptr, ptr %src125, align 8
  %ptr_gep131 = getelementptr i8, ptr %ptr_load130, i32 %mem_load129
  %idx_load132 = load i8, ptr %ptr_gep131, align 1
  %icmp133 = icmp eq i8 %idx_load132, 46
  br label %land_merge123

land_merge123:                                    ; preds = %land_rhs122, %while_exit
  %land134 = phi i1 [ false, %while_exit ], [ %icmp133, %land_rhs122 ]
  br i1 %land134, label %if_then135, label %if_merge136

if_then135:                                       ; preds = %land_merge123
  store i8 1, ptr %is_float, align 1
  %ptr_deref137 = load ptr, ptr %l, align 8
  %pos138 = getelementptr inbounds nuw %lex, ptr %ptr_deref137, i32 0, i32 1
  %ptr_deref139 = load ptr, ptr %l, align 8
  %pos140 = getelementptr inbounds nuw %lex, ptr %ptr_deref139, i32 0, i32 1
  %ptr_deref141 = load ptr, ptr %l, align 8
  %mem_load142 = load i32, ptr %pos140, align 4
  %add143 = add i32 %mem_load142, 1
  store i32 %add143, ptr %pos138, align 4
  br label %while_cond144

if_merge136:                                      ; preds = %while_exit146, %land_merge123
  %ptr_deref189 = load ptr, ptr %l, align 8
  %pos190 = getelementptr inbounds nuw %lex, ptr %ptr_deref189, i32 0, i32 1
  %ptr_deref191 = load ptr, ptr %l, align 8
  %mem_load192 = load i32, ptr %pos190, align 4
  %ptr_deref193 = load ptr, ptr %l, align 8
  %len194 = getelementptr inbounds nuw %lex, ptr %ptr_deref193, i32 0, i32 2
  %ptr_deref195 = load ptr, ptr %l, align 8
  %mem_load196 = load i32, ptr %len194, align 4
  %icmp197 = icmp slt i32 %mem_load192, %mem_load196
  br i1 %icmp197, label %land_rhs198, label %land_merge199

while_cond144:                                    ; preds = %while_body145, %if_then135
  %ptr_deref147 = load ptr, ptr %l, align 8
  %pos148 = getelementptr inbounds nuw %lex, ptr %ptr_deref147, i32 0, i32 1
  %ptr_deref149 = load ptr, ptr %l, align 8
  %mem_load150 = load i32, ptr %pos148, align 4
  %ptr_deref151 = load ptr, ptr %l, align 8
  %len152 = getelementptr inbounds nuw %lex, ptr %ptr_deref151, i32 0, i32 2
  %ptr_deref153 = load ptr, ptr %l, align 8
  %mem_load154 = load i32, ptr %len152, align 4
  %icmp155 = icmp slt i32 %mem_load150, %mem_load154
  br i1 %icmp155, label %land_rhs156, label %land_merge157

while_body145:                                    ; preds = %land_merge170
  %ptr_deref182 = load ptr, ptr %l, align 8
  %pos183 = getelementptr inbounds nuw %lex, ptr %ptr_deref182, i32 0, i32 1
  %ptr_deref184 = load ptr, ptr %l, align 8
  %pos185 = getelementptr inbounds nuw %lex, ptr %ptr_deref184, i32 0, i32 1
  %ptr_deref186 = load ptr, ptr %l, align 8
  %mem_load187 = load i32, ptr %pos185, align 4
  %add188 = add i32 %mem_load187, 1
  store i32 %add188, ptr %pos183, align 4
  br label %while_cond144

while_exit146:                                    ; preds = %land_merge170
  br label %if_merge136

land_rhs156:                                      ; preds = %while_cond144
  %ptr_deref158 = load ptr, ptr %l, align 8
  %src159 = getelementptr inbounds nuw %lex, ptr %ptr_deref158, i32 0, i32 0
  %ptr_deref160 = load ptr, ptr %l, align 8
  %pos161 = getelementptr inbounds nuw %lex, ptr %ptr_deref160, i32 0, i32 1
  %ptr_deref162 = load ptr, ptr %l, align 8
  %mem_load163 = load i32, ptr %pos161, align 4
  %ptr_load164 = load ptr, ptr %src159, align 8
  %ptr_gep165 = getelementptr i8, ptr %ptr_load164, i32 %mem_load163
  %idx_load166 = load i8, ptr %ptr_gep165, align 1
  %icmp167 = icmp sge i8 %idx_load166, 48
  br label %land_merge157

land_merge157:                                    ; preds = %land_rhs156, %while_cond144
  %land168 = phi i1 [ false, %while_cond144 ], [ %icmp167, %land_rhs156 ]
  br i1 %land168, label %land_rhs169, label %land_merge170

land_rhs169:                                      ; preds = %land_merge157
  %ptr_deref171 = load ptr, ptr %l, align 8
  %src172 = getelementptr inbounds nuw %lex, ptr %ptr_deref171, i32 0, i32 0
  %ptr_deref173 = load ptr, ptr %l, align 8
  %pos174 = getelementptr inbounds nuw %lex, ptr %ptr_deref173, i32 0, i32 1
  %ptr_deref175 = load ptr, ptr %l, align 8
  %mem_load176 = load i32, ptr %pos174, align 4
  %ptr_load177 = load ptr, ptr %src172, align 8
  %ptr_gep178 = getelementptr i8, ptr %ptr_load177, i32 %mem_load176
  %idx_load179 = load i8, ptr %ptr_gep178, align 1
  %icmp180 = icmp sle i8 %idx_load179, 57
  br label %land_merge170

land_merge170:                                    ; preds = %land_rhs169, %land_merge157
  %land181 = phi i1 [ false, %land_merge157 ], [ %icmp180, %land_rhs169 ]
  br i1 %land181, label %while_body145, label %while_exit146

land_rhs198:                                      ; preds = %if_merge136
  %ptr_deref200 = load ptr, ptr %l, align 8
  %src201 = getelementptr inbounds nuw %lex, ptr %ptr_deref200, i32 0, i32 0
  %ptr_deref202 = load ptr, ptr %l, align 8
  %pos203 = getelementptr inbounds nuw %lex, ptr %ptr_deref202, i32 0, i32 1
  %ptr_deref204 = load ptr, ptr %l, align 8
  %mem_load205 = load i32, ptr %pos203, align 4
  %ptr_load206 = load ptr, ptr %src201, align 8
  %ptr_gep207 = getelementptr i8, ptr %ptr_load206, i32 %mem_load205
  %idx_load208 = load i8, ptr %ptr_gep207, align 1
  %icmp209 = icmp eq i8 %idx_load208, 101
  br i1 %icmp209, label %lor_merge, label %lor_rhs

land_merge199:                                    ; preds = %lor_merge, %if_merge136
  %land220 = phi i1 [ false, %if_merge136 ], [ %lor, %lor_merge ]
  br i1 %land220, label %if_then221, label %if_merge222

lor_rhs:                                          ; preds = %land_rhs198
  %ptr_deref210 = load ptr, ptr %l, align 8
  %src211 = getelementptr inbounds nuw %lex, ptr %ptr_deref210, i32 0, i32 0
  %ptr_deref212 = load ptr, ptr %l, align 8
  %pos213 = getelementptr inbounds nuw %lex, ptr %ptr_deref212, i32 0, i32 1
  %ptr_deref214 = load ptr, ptr %l, align 8
  %mem_load215 = load i32, ptr %pos213, align 4
  %ptr_load216 = load ptr, ptr %src211, align 8
  %ptr_gep217 = getelementptr i8, ptr %ptr_load216, i32 %mem_load215
  %idx_load218 = load i8, ptr %ptr_gep217, align 1
  %icmp219 = icmp eq i8 %idx_load218, 69
  br label %lor_merge

lor_merge:                                        ; preds = %lor_rhs, %land_rhs198
  %lor = phi i1 [ true, %land_rhs198 ], [ %icmp219, %lor_rhs ]
  br label %land_merge199

if_then221:                                       ; preds = %land_merge199
  store i8 1, ptr %is_float, align 1
  %ptr_deref223 = load ptr, ptr %l, align 8
  %pos224 = getelementptr inbounds nuw %lex, ptr %ptr_deref223, i32 0, i32 1
  %ptr_deref225 = load ptr, ptr %l, align 8
  %pos226 = getelementptr inbounds nuw %lex, ptr %ptr_deref225, i32 0, i32 1
  %ptr_deref227 = load ptr, ptr %l, align 8
  %mem_load228 = load i32, ptr %pos226, align 4
  %add229 = add i32 %mem_load228, 1
  store i32 %add229, ptr %pos224, align 4
  %ptr_deref230 = load ptr, ptr %l, align 8
  %pos231 = getelementptr inbounds nuw %lex, ptr %ptr_deref230, i32 0, i32 1
  %ptr_deref232 = load ptr, ptr %l, align 8
  %mem_load233 = load i32, ptr %pos231, align 4
  %ptr_deref234 = load ptr, ptr %l, align 8
  %len235 = getelementptr inbounds nuw %lex, ptr %ptr_deref234, i32 0, i32 2
  %ptr_deref236 = load ptr, ptr %l, align 8
  %mem_load237 = load i32, ptr %len235, align 4
  %icmp238 = icmp slt i32 %mem_load233, %mem_load237
  br i1 %icmp238, label %land_rhs239, label %land_merge240

if_merge222:                                      ; preds = %while_exit276, %land_merge199
  %is_float319 = load i8, ptr %is_float, align 1
  %if_cond = icmp ne i8 %is_float319, 0
  br i1 %if_cond, label %if_then320, label %if_else321

land_rhs239:                                      ; preds = %if_then221
  %ptr_deref241 = load ptr, ptr %l, align 8
  %src242 = getelementptr inbounds nuw %lex, ptr %ptr_deref241, i32 0, i32 0
  %ptr_deref243 = load ptr, ptr %l, align 8
  %pos244 = getelementptr inbounds nuw %lex, ptr %ptr_deref243, i32 0, i32 1
  %ptr_deref245 = load ptr, ptr %l, align 8
  %mem_load246 = load i32, ptr %pos244, align 4
  %ptr_load247 = load ptr, ptr %src242, align 8
  %ptr_gep248 = getelementptr i8, ptr %ptr_load247, i32 %mem_load246
  %idx_load249 = load i8, ptr %ptr_gep248, align 1
  %icmp250 = icmp eq i8 %idx_load249, 43
  br i1 %icmp250, label %lor_merge252, label %lor_rhs251

land_merge240:                                    ; preds = %lor_merge252, %if_then221
  %land264 = phi i1 [ false, %if_then221 ], [ %lor263, %lor_merge252 ]
  br i1 %land264, label %if_then265, label %if_merge266

lor_rhs251:                                       ; preds = %land_rhs239
  %ptr_deref253 = load ptr, ptr %l, align 8
  %src254 = getelementptr inbounds nuw %lex, ptr %ptr_deref253, i32 0, i32 0
  %ptr_deref255 = load ptr, ptr %l, align 8
  %pos256 = getelementptr inbounds nuw %lex, ptr %ptr_deref255, i32 0, i32 1
  %ptr_deref257 = load ptr, ptr %l, align 8
  %mem_load258 = load i32, ptr %pos256, align 4
  %ptr_load259 = load ptr, ptr %src254, align 8
  %ptr_gep260 = getelementptr i8, ptr %ptr_load259, i32 %mem_load258
  %idx_load261 = load i8, ptr %ptr_gep260, align 1
  %icmp262 = icmp eq i8 %idx_load261, 45
  br label %lor_merge252

lor_merge252:                                     ; preds = %lor_rhs251, %land_rhs239
  %lor263 = phi i1 [ true, %land_rhs239 ], [ %icmp262, %lor_rhs251 ]
  br label %land_merge240

if_then265:                                       ; preds = %land_merge240
  %ptr_deref267 = load ptr, ptr %l, align 8
  %pos268 = getelementptr inbounds nuw %lex, ptr %ptr_deref267, i32 0, i32 1
  %ptr_deref269 = load ptr, ptr %l, align 8
  %pos270 = getelementptr inbounds nuw %lex, ptr %ptr_deref269, i32 0, i32 1
  %ptr_deref271 = load ptr, ptr %l, align 8
  %mem_load272 = load i32, ptr %pos270, align 4
  %add273 = add i32 %mem_load272, 1
  store i32 %add273, ptr %pos268, align 4
  br label %if_merge266

if_merge266:                                      ; preds = %if_then265, %land_merge240
  br label %while_cond274

while_cond274:                                    ; preds = %while_body275, %if_merge266
  %ptr_deref277 = load ptr, ptr %l, align 8
  %pos278 = getelementptr inbounds nuw %lex, ptr %ptr_deref277, i32 0, i32 1
  %ptr_deref279 = load ptr, ptr %l, align 8
  %mem_load280 = load i32, ptr %pos278, align 4
  %ptr_deref281 = load ptr, ptr %l, align 8
  %len282 = getelementptr inbounds nuw %lex, ptr %ptr_deref281, i32 0, i32 2
  %ptr_deref283 = load ptr, ptr %l, align 8
  %mem_load284 = load i32, ptr %len282, align 4
  %icmp285 = icmp slt i32 %mem_load280, %mem_load284
  br i1 %icmp285, label %land_rhs286, label %land_merge287

while_body275:                                    ; preds = %land_merge300
  %ptr_deref312 = load ptr, ptr %l, align 8
  %pos313 = getelementptr inbounds nuw %lex, ptr %ptr_deref312, i32 0, i32 1
  %ptr_deref314 = load ptr, ptr %l, align 8
  %pos315 = getelementptr inbounds nuw %lex, ptr %ptr_deref314, i32 0, i32 1
  %ptr_deref316 = load ptr, ptr %l, align 8
  %mem_load317 = load i32, ptr %pos315, align 4
  %add318 = add i32 %mem_load317, 1
  store i32 %add318, ptr %pos313, align 4
  br label %while_cond274

while_exit276:                                    ; preds = %land_merge300
  br label %if_merge222

land_rhs286:                                      ; preds = %while_cond274
  %ptr_deref288 = load ptr, ptr %l, align 8
  %src289 = getelementptr inbounds nuw %lex, ptr %ptr_deref288, i32 0, i32 0
  %ptr_deref290 = load ptr, ptr %l, align 8
  %pos291 = getelementptr inbounds nuw %lex, ptr %ptr_deref290, i32 0, i32 1
  %ptr_deref292 = load ptr, ptr %l, align 8
  %mem_load293 = load i32, ptr %pos291, align 4
  %ptr_load294 = load ptr, ptr %src289, align 8
  %ptr_gep295 = getelementptr i8, ptr %ptr_load294, i32 %mem_load293
  %idx_load296 = load i8, ptr %ptr_gep295, align 1
  %icmp297 = icmp sge i8 %idx_load296, 48
  br label %land_merge287

land_merge287:                                    ; preds = %land_rhs286, %while_cond274
  %land298 = phi i1 [ false, %while_cond274 ], [ %icmp297, %land_rhs286 ]
  br i1 %land298, label %land_rhs299, label %land_merge300

land_rhs299:                                      ; preds = %land_merge287
  %ptr_deref301 = load ptr, ptr %l, align 8
  %src302 = getelementptr inbounds nuw %lex, ptr %ptr_deref301, i32 0, i32 0
  %ptr_deref303 = load ptr, ptr %l, align 8
  %pos304 = getelementptr inbounds nuw %lex, ptr %ptr_deref303, i32 0, i32 1
  %ptr_deref305 = load ptr, ptr %l, align 8
  %mem_load306 = load i32, ptr %pos304, align 4
  %ptr_load307 = load ptr, ptr %src302, align 8
  %ptr_gep308 = getelementptr i8, ptr %ptr_load307, i32 %mem_load306
  %idx_load309 = load i8, ptr %ptr_gep308, align 1
  %icmp310 = icmp sle i8 %idx_load309, 57
  br label %land_merge300

land_merge300:                                    ; preds = %land_rhs299, %land_merge287
  %land311 = phi i1 [ false, %land_merge287 ], [ %icmp310, %land_rhs299 ]
  br i1 %land311, label %while_body275, label %while_exit276

if_then320:                                       ; preds = %if_merge222
  %ptr_deref323 = load ptr, ptr %v, align 8
  %kind324 = getelementptr inbounds nuw %json_val, ptr %ptr_deref323, i32 0, i32 0
  %JSON_FLOAT = load i32, ptr @json__NS_JSON_FLOAT, align 4
  store i32 %JSON_FLOAT, ptr %kind324, align 4
  %fv = alloca double, align 8
  store double 0.000000e+00, ptr %fv, align 8
  %frac = alloca double, align 8
  store double 1.000000e-01, ptr %frac, align 8
  %after_dot = alloca i8, align 1
  store i8 0, ptr %after_dot, align 1
  %neg = alloca i8, align 1
  store i8 0, ptr %neg, align 1
  %i = alloca i32, align 4
  %start325 = load i32, ptr %start, align 4
  store i32 %start325, ptr %i, align 4
  %ptr_deref326 = load ptr, ptr %l, align 8
  %src327 = getelementptr inbounds nuw %lex, ptr %ptr_deref326, i32 0, i32 0
  %i328 = load i32, ptr %i, align 4
  %ptr_load329 = load ptr, ptr %src327, align 8
  %ptr_gep330 = getelementptr i8, ptr %ptr_load329, i32 %i328
  %idx_load331 = load i8, ptr %ptr_gep330, align 1
  %icmp332 = icmp eq i8 %idx_load331, 45
  br i1 %icmp332, label %if_then333, label %if_merge334

if_else321:                                       ; preds = %if_merge222
  %ptr_deref392 = load ptr, ptr %v, align 8
  %kind393 = getelementptr inbounds nuw %json_val, ptr %ptr_deref392, i32 0, i32 0
  %JSON_INT = load i32, ptr @json__NS_JSON_INT, align 4
  store i32 %JSON_INT, ptr %kind393, align 4
  %iv = alloca i64, align 8
  store i64 0, ptr %iv, align 4
  %neg394 = alloca i8, align 1
  store i8 0, ptr %neg394, align 1
  %i395 = alloca i32, align 4
  %start396 = load i32, ptr %start, align 4
  store i32 %start396, ptr %i395, align 4
  %ptr_deref397 = load ptr, ptr %l, align 8
  %src398 = getelementptr inbounds nuw %lex, ptr %ptr_deref397, i32 0, i32 0
  %i399 = load i32, ptr %i395, align 4
  %ptr_load400 = load ptr, ptr %src398, align 8
  %ptr_gep401 = getelementptr i8, ptr %ptr_load400, i32 %i399
  %idx_load402 = load i8, ptr %ptr_gep401, align 1
  %icmp403 = icmp eq i8 %idx_load402, 45
  br i1 %icmp403, label %if_then404, label %if_merge405

if_merge322:                                      ; preds = %tern_merge433, %tern_merge
  br label %if_merge54

if_then333:                                       ; preds = %if_then320
  store i8 1, ptr %neg, align 1
  %i335 = load i32, ptr %i, align 4
  %add336 = add i32 %i335, 1
  store i32 %add336, ptr %i, align 4
  br label %if_merge334

if_merge334:                                      ; preds = %if_then333, %if_then320
  br label %while_cond337

while_cond337:                                    ; preds = %if_merge374, %if_then364, %if_merge334
  %i340 = load i32, ptr %i, align 4
  %ptr_deref341 = load ptr, ptr %l, align 8
  %pos342 = getelementptr inbounds nuw %lex, ptr %ptr_deref341, i32 0, i32 1
  %ptr_deref343 = load ptr, ptr %l, align 8
  %mem_load344 = load i32, ptr %pos342, align 4
  %icmp345 = icmp slt i32 %i340, %mem_load344
  br i1 %icmp345, label %while_body338, label %while_exit339

while_body338:                                    ; preds = %while_cond337
  %d = alloca i8, align 1
  %ptr_deref346 = load ptr, ptr %l, align 8
  %src347 = getelementptr inbounds nuw %lex, ptr %ptr_deref346, i32 0, i32 0
  %i348 = load i32, ptr %i, align 4
  %ptr_load349 = load ptr, ptr %src347, align 8
  %ptr_gep350 = getelementptr i8, ptr %ptr_load349, i32 %i348
  %idx_load351 = load i8, ptr %ptr_gep350, align 1
  store i8 %idx_load351, ptr %d, align 1
  %d352 = load i8, ptr %d, align 1
  %icmp353 = icmp eq i8 %d352, 46
  br i1 %icmp353, label %lor_merge355, label %lor_rhs354

while_exit339:                                    ; preds = %while_cond337
  %ptr_deref388 = load ptr, ptr %v, align 8
  %f_val = getelementptr inbounds nuw %json_val, ptr %ptr_deref388, i32 0, i32 3
  %neg389 = load i8, ptr %neg, align 1
  %tobool = icmp ne i8 %neg389, 0
  br i1 %tobool, label %tern_then, label %tern_else

lor_rhs354:                                       ; preds = %while_body338
  %d356 = load i8, ptr %d, align 1
  %icmp357 = icmp eq i8 %d356, 101
  br label %lor_merge355

lor_merge355:                                     ; preds = %lor_rhs354, %while_body338
  %lor358 = phi i1 [ true, %while_body338 ], [ %icmp357, %lor_rhs354 ]
  br i1 %lor358, label %lor_merge360, label %lor_rhs359

lor_rhs359:                                       ; preds = %lor_merge355
  %d361 = load i8, ptr %d, align 1
  %icmp362 = icmp eq i8 %d361, 69
  br label %lor_merge360

lor_merge360:                                     ; preds = %lor_rhs359, %lor_merge355
  %lor363 = phi i1 [ true, %lor_merge355 ], [ %icmp362, %lor_rhs359 ]
  br i1 %lor363, label %if_then364, label %if_merge365

if_then364:                                       ; preds = %lor_merge360
  %d366 = load i8, ptr %d, align 1
  %icmp367 = icmp eq i8 %d366, 46
  %zext = zext i1 %icmp367 to i8
  store i8 %zext, ptr %after_dot, align 1
  %i368 = load i32, ptr %i, align 4
  %add369 = add i32 %i368, 1
  store i32 %add369, ptr %i, align 4
  br label %while_cond337

if_merge365:                                      ; preds = %lor_merge360
  %after_dot370 = load i8, ptr %after_dot, align 1
  %if_cond371 = icmp ne i8 %after_dot370, 0
  br i1 %if_cond371, label %if_then372, label %if_else373

if_then372:                                       ; preds = %if_merge365
  %fv375 = load double, ptr %fv, align 8
  %d376 = load i8, ptr %d, align 1
  %sub = sub i8 %d376, 48
  %sitofp = sitofp i8 %sub to double
  %frac377 = load double, ptr %frac, align 8
  %fmul = fmul double %sitofp, %frac377
  %fadd = fadd double %fv375, %fmul
  store double %fadd, ptr %fv, align 8
  %frac378 = load double, ptr %frac, align 8
  %fmul379 = fmul double %frac378, 1.000000e-01
  store double %fmul379, ptr %frac, align 8
  br label %if_merge374

if_else373:                                       ; preds = %if_merge365
  %fv380 = load double, ptr %fv, align 8
  %fmul381 = fmul double %fv380, 1.000000e+01
  %d382 = load i8, ptr %d, align 1
  %sub383 = sub i8 %d382, 48
  %sitofp384 = sitofp i8 %sub383 to double
  %fadd385 = fadd double %fmul381, %sitofp384
  store double %fadd385, ptr %fv, align 8
  br label %if_merge374

if_merge374:                                      ; preds = %if_else373, %if_then372
  %i386 = load i32, ptr %i, align 4
  %add387 = add i32 %i386, 1
  store i32 %add387, ptr %i, align 4
  br label %while_cond337

tern_then:                                        ; preds = %while_exit339
  %fv390 = load double, ptr %fv, align 8
  %fneg = fneg double %fv390
  br label %tern_merge

tern_else:                                        ; preds = %while_exit339
  %fv391 = load double, ptr %fv, align 8
  br label %tern_merge

tern_merge:                                       ; preds = %tern_else, %tern_then
  %tern = phi double [ %fneg, %tern_then ], [ %fv391, %tern_else ]
  store double %tern, ptr %f_val, align 8
  br label %if_merge322

if_then404:                                       ; preds = %if_else321
  store i8 1, ptr %neg394, align 1
  %i406 = load i32, ptr %i395, align 4
  %add407 = add i32 %i406, 1
  store i32 %add407, ptr %i395, align 4
  br label %if_merge405

if_merge405:                                      ; preds = %if_then404, %if_else321
  br label %while_cond408

while_cond408:                                    ; preds = %while_body409, %if_merge405
  %i411 = load i32, ptr %i395, align 4
  %ptr_deref412 = load ptr, ptr %l, align 8
  %pos413 = getelementptr inbounds nuw %lex, ptr %ptr_deref412, i32 0, i32 1
  %ptr_deref414 = load ptr, ptr %l, align 8
  %mem_load415 = load i32, ptr %pos413, align 4
  %icmp416 = icmp slt i32 %i411, %mem_load415
  br i1 %icmp416, label %while_body409, label %while_exit410

while_body409:                                    ; preds = %while_cond408
  %iv417 = load i64, ptr %iv, align 4
  %mul = mul i64 %iv417, 10
  %ptr_deref418 = load ptr, ptr %l, align 8
  %src419 = getelementptr inbounds nuw %lex, ptr %ptr_deref418, i32 0, i32 0
  %i420 = load i32, ptr %i395, align 4
  %ptr_load421 = load ptr, ptr %src419, align 8
  %ptr_gep422 = getelementptr i8, ptr %ptr_load421, i32 %i420
  %idx_load423 = load i8, ptr %ptr_gep422, align 1
  %sub424 = sub i8 %idx_load423, 48
  %sext = sext i8 %sub424 to i64
  %add425 = add i64 %mul, %sext
  store i64 %add425, ptr %iv, align 4
  %i426 = load i32, ptr %i395, align 4
  %add427 = add i32 %i426, 1
  store i32 %add427, ptr %i395, align 4
  br label %while_cond408

while_exit410:                                    ; preds = %while_cond408
  %ptr_deref428 = load ptr, ptr %v, align 8
  %i_val = getelementptr inbounds nuw %json_val, ptr %ptr_deref428, i32 0, i32 2
  %neg429 = load i8, ptr %neg394, align 1
  %tobool430 = icmp ne i8 %neg429, 0
  br i1 %tobool430, label %tern_then431, label %tern_else432

tern_then431:                                     ; preds = %while_exit410
  %iv434 = load i64, ptr %iv, align 4
  %neg435 = sub i64 0, %iv434
  br label %tern_merge433

tern_else432:                                     ; preds = %while_exit410
  %iv436 = load i64, ptr %iv, align 4
  br label %tern_merge433

tern_merge433:                                    ; preds = %tern_else432, %tern_then431
  %tern437 = phi i64 [ %neg435, %tern_then431 ], [ %iv436, %tern_else432 ]
  store i64 %tern437, ptr %i_val, align 4
  br label %if_merge322
}

define internal ptr @json__NS_parse_string_raw(ptr %0, %__memstr_fat__ %1) {
entry:
  %l = alloca ptr, align 8
  store ptr %0, ptr %l, align 8
  %a = alloca %__memstr_fat__, align 8
  store %__memstr_fat__ %1, ptr %a, align 8
  %l1 = load ptr, ptr %l, align 8
  %2 = call i8 @lex__NS_next(ptr %l1)
  %start = alloca i32, align 4
  %ptr_deref = load ptr, ptr %l, align 8
  %pos = getelementptr inbounds nuw %lex, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref2 = load ptr, ptr %l, align 8
  %mem_load = load i32, ptr %pos, align 4
  store i32 %mem_load, ptr %start, align 4
  %end = alloca i32, align 4
  %start3 = load i32, ptr %start, align 4
  store i32 %start3, ptr %end, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %ptr_deref4 = load ptr, ptr %l, align 8
  %pos5 = getelementptr inbounds nuw %lex, ptr %ptr_deref4, i32 0, i32 1
  %ptr_deref6 = load ptr, ptr %l, align 8
  %mem_load7 = load i32, ptr %pos5, align 4
  %ptr_deref8 = load ptr, ptr %l, align 8
  %len = getelementptr inbounds nuw %lex, ptr %ptr_deref8, i32 0, i32 2
  %ptr_deref9 = load ptr, ptr %l, align 8
  %mem_load10 = load i32, ptr %len, align 4
  %icmp = icmp slt i32 %mem_load7, %mem_load10
  br i1 %icmp, label %land_rhs, label %land_merge

while_body:                                       ; preds = %land_merge
  %ptr_deref17 = load ptr, ptr %l, align 8
  %src18 = getelementptr inbounds nuw %lex, ptr %ptr_deref17, i32 0, i32 0
  %ptr_deref19 = load ptr, ptr %l, align 8
  %pos20 = getelementptr inbounds nuw %lex, ptr %ptr_deref19, i32 0, i32 1
  %ptr_deref21 = load ptr, ptr %l, align 8
  %mem_load22 = load i32, ptr %pos20, align 4
  %ptr_load23 = load ptr, ptr %src18, align 8
  %ptr_gep24 = getelementptr i8, ptr %ptr_load23, i32 %mem_load22
  %idx_load25 = load i8, ptr %ptr_gep24, align 1
  %icmp26 = icmp eq i8 %idx_load25, 92
  br i1 %icmp26, label %if_then, label %if_merge

while_exit:                                       ; preds = %land_merge
  %l44 = load ptr, ptr %l, align 8
  %3 = call i8 @lex__NS_next(ptr %l44)
  %n = alloca i32, align 4
  %end45 = load i32, ptr %end, align 4
  %start46 = load i32, ptr %start, align 4
  %sub = sub i32 %end45, %start46
  store i32 %sub, ptr %n, align 4
  %s = alloca ptr, align 8
  %fat = load %__memstr_fat__, ptr %a, align 8
  %ms_data = extractvalue %__memstr_fat__ %fat, 0
  %ms_vtbl = extractvalue %__memstr_fat__ %fat, 1
  %vtslot = getelementptr { ptr, ptr, ptr }, ptr %ms_vtbl, i32 0, i32 0
  %fnptr = load ptr, ptr %vtslot, align 8
  %n47 = load i32, ptr %n, align 4
  %add48 = add i32 %n47, 1
  %zext = zext i32 %add48 to i64
  %4 = call ptr %fnptr(ptr %ms_data, i64 %zext)
  store ptr %4, ptr %s, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %for_cond

land_rhs:                                         ; preds = %while_cond
  %ptr_deref11 = load ptr, ptr %l, align 8
  %src = getelementptr inbounds nuw %lex, ptr %ptr_deref11, i32 0, i32 0
  %ptr_deref12 = load ptr, ptr %l, align 8
  %pos13 = getelementptr inbounds nuw %lex, ptr %ptr_deref12, i32 0, i32 1
  %ptr_deref14 = load ptr, ptr %l, align 8
  %mem_load15 = load i32, ptr %pos13, align 4
  %ptr_load = load ptr, ptr %src, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load15
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp16 = icmp ne i8 %idx_load, 34
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond
  %land = phi i1 [ false, %while_cond ], [ %icmp16, %land_rhs ]
  br i1 %land, label %while_body, label %while_exit

if_then:                                          ; preds = %while_body
  %ptr_deref27 = load ptr, ptr %l, align 8
  %pos28 = getelementptr inbounds nuw %lex, ptr %ptr_deref27, i32 0, i32 1
  %ptr_deref29 = load ptr, ptr %l, align 8
  %pos30 = getelementptr inbounds nuw %lex, ptr %ptr_deref29, i32 0, i32 1
  %ptr_deref31 = load ptr, ptr %l, align 8
  %mem_load32 = load i32, ptr %pos30, align 4
  %add = add i32 %mem_load32, 1
  store i32 %add, ptr %pos28, align 4
  br label %if_merge

if_merge:                                         ; preds = %if_then, %while_body
  %ptr_deref33 = load ptr, ptr %l, align 8
  %pos34 = getelementptr inbounds nuw %lex, ptr %ptr_deref33, i32 0, i32 1
  %ptr_deref35 = load ptr, ptr %l, align 8
  %pos36 = getelementptr inbounds nuw %lex, ptr %ptr_deref35, i32 0, i32 1
  %ptr_deref37 = load ptr, ptr %l, align 8
  %mem_load38 = load i32, ptr %pos36, align 4
  %add39 = add i32 %mem_load38, 1
  store i32 %add39, ptr %pos34, align 4
  %ptr_deref40 = load ptr, ptr %l, align 8
  %pos41 = getelementptr inbounds nuw %lex, ptr %ptr_deref40, i32 0, i32 1
  %ptr_deref42 = load ptr, ptr %l, align 8
  %mem_load43 = load i32, ptr %pos41, align 4
  store i32 %mem_load43, ptr %end, align 4
  br label %while_cond

for_cond:                                         ; preds = %for_step, %while_exit
  %i49 = load i32, ptr %i, align 4
  %n50 = load i32, ptr %n, align 4
  %icmp51 = icmp slt i32 %i49, %n50
  br i1 %icmp51, label %for_body, label %for_exit

for_body:                                         ; preds = %for_cond
  %i52 = load i32, ptr %i, align 4
  %ptr_load53 = load ptr, ptr %s, align 8
  %ptr_gep54 = getelementptr i8, ptr %ptr_load53, i32 %i52
  %ptr_deref55 = load ptr, ptr %l, align 8
  %src56 = getelementptr inbounds nuw %lex, ptr %ptr_deref55, i32 0, i32 0
  %start57 = load i32, ptr %start, align 4
  %i58 = load i32, ptr %i, align 4
  %add59 = add i32 %start57, %i58
  %ptr_load60 = load ptr, ptr %src56, align 8
  %ptr_gep61 = getelementptr i8, ptr %ptr_load60, i32 %add59
  %idx_load62 = load i8, ptr %ptr_gep61, align 1
  store i8 %idx_load62, ptr %ptr_gep54, align 1
  br label %for_step

for_step:                                         ; preds = %for_body
  %i63 = load i32, ptr %i, align 4
  %add64 = add i32 %i63, 1
  store i32 %add64, ptr %i, align 4
  br label %for_cond

for_exit:                                         ; preds = %for_cond
  %n65 = load i32, ptr %n, align 4
  %ptr_load66 = load ptr, ptr %s, align 8
  %ptr_gep67 = getelementptr i8, ptr %ptr_load66, i32 %n65
  store i8 0, ptr %ptr_gep67, align 1
  %s68 = load ptr, ptr %s, align 8
  ret ptr %s68
}

define internal ptr @json__NS_parse_array(ptr %0, %__memstr_fat__ %1) {
entry:
  %l = alloca ptr, align 8
  store ptr %0, ptr %l, align 8
  %a = alloca %__memstr_fat__, align 8
  store %__memstr_fat__ %1, ptr %a, align 8
  %l1 = load ptr, ptr %l, align 8
  %2 = call i8 @lex__NS_next(ptr %l1)
  %v = alloca ptr, align 8
  %fat = load %__memstr_fat__, ptr %a, align 8
  %ms_data = extractvalue %__memstr_fat__ %fat, 0
  %ms_vtbl = extractvalue %__memstr_fat__ %fat, 1
  %vtslot = getelementptr { ptr, ptr, ptr }, ptr %ms_vtbl, i32 0, i32 0
  %fnptr = load ptr, ptr %vtslot, align 8
  %3 = call ptr %fnptr(ptr %ms_data, i64 ptrtoint (ptr getelementptr (%json_val, ptr null, i32 1) to i64))
  store ptr %3, ptr %v, align 8
  %ptr_deref = load ptr, ptr %v, align 8
  %kind = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 0
  %JSON_ARRAY = load i32, ptr @json__NS_JSON_ARRAY, align 4
  store i32 %JSON_ARRAY, ptr %kind, align 4
  %ptr_deref2 = load ptr, ptr %v, align 8
  %arr_len = getelementptr inbounds nuw %json_val, ptr %ptr_deref2, i32 0, i32 6
  store i32 0, ptr %arr_len, align 4
  %ptr_deref3 = load ptr, ptr %v, align 8
  %arr_items = getelementptr inbounds nuw %json_val, ptr %ptr_deref3, i32 0, i32 5
  store ptr null, ptr %arr_items, align 8
  %l4 = load ptr, ptr %l, align 8
  call void @lex__NS_skip_ws(ptr %l4)
  %l5 = load ptr, ptr %l, align 8
  %4 = call i8 @lex__NS_peek(ptr %l5)
  %icmp = icmp eq i8 %4, 93
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %l6 = load ptr, ptr %l, align 8
  %5 = call i8 @lex__NS_next(ptr %l6)
  %v7 = load ptr, ptr %v, align 8
  ret ptr %v7

if_merge:                                         ; preds = %entry
  %items = alloca [256 x ptr], align 8
  store [256 x ptr] zeroinitializer, ptr %items, align 8
  %count = alloca i32, align 4
  store i32 0, ptr %count, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge16, %if_merge
  br i1 true, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %count8 = load i32, ptr %count, align 4
  %arr_gep = getelementptr [256 x ptr], ptr %items, i64 0, i32 %count8
  %l9 = load ptr, ptr %l, align 8
  %a10 = load %__memstr_fat__, ptr %a, align 8
  %6 = call ptr @json__NS_parse_value(ptr %l9, %__memstr_fat__ %a10)
  store ptr %6, ptr %arr_gep, align 8
  %count11 = load i32, ptr %count, align 4
  %add = add i32 %count11, 1
  store i32 %add, ptr %count, align 4
  %l12 = load ptr, ptr %l, align 8
  call void @lex__NS_skip_ws(ptr %l12)
  %l13 = load ptr, ptr %l, align 8
  %7 = call i8 @lex__NS_peek(ptr %l13)
  %icmp14 = icmp eq i8 %7, 44
  br i1 %icmp14, label %if_then15, label %if_else

while_exit:                                       ; preds = %if_else, %while_cond
  %l19 = load ptr, ptr %l, align 8
  %8 = call i8 @lex__NS_next(ptr %l19)
  %ptr_deref20 = load ptr, ptr %v, align 8
  %arr_items21 = getelementptr inbounds nuw %json_val, ptr %ptr_deref20, i32 0, i32 5
  %fat22 = load %__memstr_fat__, ptr %a, align 8
  %ms_data23 = extractvalue %__memstr_fat__ %fat22, 0
  %ms_vtbl24 = extractvalue %__memstr_fat__ %fat22, 1
  %vtslot25 = getelementptr { ptr, ptr, ptr }, ptr %ms_vtbl24, i32 0, i32 0
  %fnptr26 = load ptr, ptr %vtslot25, align 8
  %count27 = load i32, ptr %count, align 4
  %sext = sext i32 %count27 to i64
  %mul = mul i64 ptrtoint (ptr getelementptr (ptr, ptr null, i32 1) to i64), %sext
  %9 = call ptr %fnptr26(ptr %ms_data23, i64 %mul)
  store ptr %9, ptr %arr_items21, align 8
  %ptr_deref28 = load ptr, ptr %v, align 8
  %arr_len29 = getelementptr inbounds nuw %json_val, ptr %ptr_deref28, i32 0, i32 6
  %count30 = load i32, ptr %count, align 4
  store i32 %count30, ptr %arr_len29, align 4
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %for_cond

if_then15:                                        ; preds = %while_body
  %l17 = load ptr, ptr %l, align 8
  %10 = call i8 @lex__NS_next(ptr %l17)
  %l18 = load ptr, ptr %l, align 8
  call void @lex__NS_skip_ws(ptr %l18)
  br label %if_merge16

if_else:                                          ; preds = %while_body
  br label %while_exit

if_merge16:                                       ; preds = %if_then15
  br label %while_cond

for_cond:                                         ; preds = %for_step, %while_exit
  %i31 = load i32, ptr %i, align 4
  %count32 = load i32, ptr %count, align 4
  %icmp33 = icmp slt i32 %i31, %count32
  br i1 %icmp33, label %for_body, label %for_exit

for_body:                                         ; preds = %for_cond
  %ptr_deref34 = load ptr, ptr %v, align 8
  %arr_items35 = getelementptr inbounds nuw %json_val, ptr %ptr_deref34, i32 0, i32 5
  %i36 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %arr_items35, align 8
  %ptr_gep = getelementptr ptr, ptr %ptr_load, i32 %i36
  %i37 = load i32, ptr %i, align 4
  %arr_gep38 = getelementptr [256 x ptr], ptr %items, i64 0, i32 %i37
  %idx_load = load ptr, ptr %arr_gep38, align 8
  store ptr %idx_load, ptr %ptr_gep, align 8
  br label %for_step

for_step:                                         ; preds = %for_body
  %i39 = load i32, ptr %i, align 4
  %add40 = add i32 %i39, 1
  store i32 %add40, ptr %i, align 4
  br label %for_cond

for_exit:                                         ; preds = %for_cond
  %v41 = load ptr, ptr %v, align 8
  ret ptr %v41
}

define internal ptr @json__NS_parse_object(ptr %0, %__memstr_fat__ %1) {
entry:
  %l = alloca ptr, align 8
  store ptr %0, ptr %l, align 8
  %a = alloca %__memstr_fat__, align 8
  store %__memstr_fat__ %1, ptr %a, align 8
  %l1 = load ptr, ptr %l, align 8
  %2 = call i8 @lex__NS_next(ptr %l1)
  %v = alloca ptr, align 8
  %fat = load %__memstr_fat__, ptr %a, align 8
  %ms_data = extractvalue %__memstr_fat__ %fat, 0
  %ms_vtbl = extractvalue %__memstr_fat__ %fat, 1
  %vtslot = getelementptr { ptr, ptr, ptr }, ptr %ms_vtbl, i32 0, i32 0
  %fnptr = load ptr, ptr %vtslot, align 8
  %3 = call ptr %fnptr(ptr %ms_data, i64 ptrtoint (ptr getelementptr (%json_val, ptr null, i32 1) to i64))
  store ptr %3, ptr %v, align 8
  %ptr_deref = load ptr, ptr %v, align 8
  %kind = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 0
  %JSON_OBJECT = load i32, ptr @json__NS_JSON_OBJECT, align 4
  store i32 %JSON_OBJECT, ptr %kind, align 4
  %ptr_deref2 = load ptr, ptr %v, align 8
  %obj_len = getelementptr inbounds nuw %json_val, ptr %ptr_deref2, i32 0, i32 8
  store i32 0, ptr %obj_len, align 4
  %ptr_deref3 = load ptr, ptr %v, align 8
  %obj_pairs = getelementptr inbounds nuw %json_val, ptr %ptr_deref3, i32 0, i32 7
  store ptr null, ptr %obj_pairs, align 8
  %l4 = load ptr, ptr %l, align 8
  call void @lex__NS_skip_ws(ptr %l4)
  %l5 = load ptr, ptr %l, align 8
  %4 = call i8 @lex__NS_peek(ptr %l5)
  %icmp = icmp eq i8 %4, 125
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %l6 = load ptr, ptr %l, align 8
  %5 = call i8 @lex__NS_next(ptr %l6)
  %v7 = load ptr, ptr %v, align 8
  ret ptr %v7

if_merge:                                         ; preds = %entry
  %pairs = alloca [256 x %json_pair], align 8
  store [256 x %json_pair] zeroinitializer, ptr %pairs, align 8
  %count = alloca i32, align 4
  store i32 0, ptr %count, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge28, %if_merge
  br i1 true, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %l8 = load ptr, ptr %l, align 8
  call void @lex__NS_skip_ws(ptr %l8)
  %key = alloca ptr, align 8
  %l9 = load ptr, ptr %l, align 8
  %a10 = load %__memstr_fat__, ptr %a, align 8
  %6 = call ptr @json__NS_parse_string_raw(ptr %l9, %__memstr_fat__ %a10)
  store ptr %6, ptr %key, align 8
  %l11 = load ptr, ptr %l, align 8
  call void @lex__NS_skip_ws(ptr %l11)
  %l12 = load ptr, ptr %l, align 8
  %7 = call i8 @lex__NS_next(ptr %l12)
  %l13 = load ptr, ptr %l, align 8
  call void @lex__NS_skip_ws(ptr %l13)
  %val = alloca ptr, align 8
  %l14 = load ptr, ptr %l, align 8
  %a15 = load %__memstr_fat__, ptr %a, align 8
  %8 = call ptr @json__NS_parse_value(ptr %l14, %__memstr_fat__ %a15)
  store ptr %8, ptr %val, align 8
  %count16 = load i32, ptr %count, align 4
  %arr_gep = getelementptr [256 x %json_pair], ptr %pairs, i64 0, i32 %count16
  %key17 = getelementptr inbounds nuw %json_pair, ptr %arr_gep, i32 0, i32 0
  %key18 = load ptr, ptr %key, align 8
  store ptr %key18, ptr %key17, align 8
  %count19 = load i32, ptr %count, align 4
  %arr_gep20 = getelementptr [256 x %json_pair], ptr %pairs, i64 0, i32 %count19
  %val21 = getelementptr inbounds nuw %json_pair, ptr %arr_gep20, i32 0, i32 1
  %val22 = load ptr, ptr %val, align 8
  store ptr %val22, ptr %val21, align 8
  %count23 = load i32, ptr %count, align 4
  %add = add i32 %count23, 1
  store i32 %add, ptr %count, align 4
  %l24 = load ptr, ptr %l, align 8
  call void @lex__NS_skip_ws(ptr %l24)
  %l25 = load ptr, ptr %l, align 8
  %9 = call i8 @lex__NS_peek(ptr %l25)
  %icmp26 = icmp eq i8 %9, 44
  br i1 %icmp26, label %if_then27, label %if_else

while_exit:                                       ; preds = %if_else, %while_cond
  %l30 = load ptr, ptr %l, align 8
  %10 = call i8 @lex__NS_next(ptr %l30)
  %ptr_deref31 = load ptr, ptr %v, align 8
  %obj_pairs32 = getelementptr inbounds nuw %json_val, ptr %ptr_deref31, i32 0, i32 7
  %fat33 = load %__memstr_fat__, ptr %a, align 8
  %ms_data34 = extractvalue %__memstr_fat__ %fat33, 0
  %ms_vtbl35 = extractvalue %__memstr_fat__ %fat33, 1
  %vtslot36 = getelementptr { ptr, ptr, ptr }, ptr %ms_vtbl35, i32 0, i32 0
  %fnptr37 = load ptr, ptr %vtslot36, align 8
  %count38 = load i32, ptr %count, align 4
  %sext = sext i32 %count38 to i64
  %mul = mul i64 ptrtoint (ptr getelementptr (%json_pair, ptr null, i32 1) to i64), %sext
  %11 = call ptr %fnptr37(ptr %ms_data34, i64 %mul)
  store ptr %11, ptr %obj_pairs32, align 8
  %ptr_deref39 = load ptr, ptr %v, align 8
  %obj_len40 = getelementptr inbounds nuw %json_val, ptr %ptr_deref39, i32 0, i32 8
  %count41 = load i32, ptr %count, align 4
  store i32 %count41, ptr %obj_len40, align 4
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %for_cond

if_then27:                                        ; preds = %while_body
  %l29 = load ptr, ptr %l, align 8
  %12 = call i8 @lex__NS_next(ptr %l29)
  br label %if_merge28

if_else:                                          ; preds = %while_body
  br label %while_exit

if_merge28:                                       ; preds = %if_then27
  br label %while_cond

for_cond:                                         ; preds = %for_step, %while_exit
  %i42 = load i32, ptr %i, align 4
  %count43 = load i32, ptr %count, align 4
  %icmp44 = icmp slt i32 %i42, %count43
  br i1 %icmp44, label %for_body, label %for_exit

for_body:                                         ; preds = %for_cond
  %ptr_deref45 = load ptr, ptr %v, align 8
  %obj_pairs46 = getelementptr inbounds nuw %json_val, ptr %ptr_deref45, i32 0, i32 7
  %i47 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %obj_pairs46, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i47
  %i48 = load i32, ptr %i, align 4
  %arr_gep49 = getelementptr [256 x %json_pair], ptr %pairs, i64 0, i32 %i48
  %idx_load = load %json_pair, ptr %arr_gep49, align 8
  store %json_pair %idx_load, ptr %ptr_gep, align 8
  br label %for_step

for_step:                                         ; preds = %for_body
  %i50 = load i32, ptr %i, align 4
  %add51 = add i32 %i50, 1
  store i32 %add51, ptr %i, align 4
  br label %for_cond

for_exit:                                         ; preds = %for_cond
  %v52 = load ptr, ptr %v, align 8
  ret ptr %v52
}

define internal ptr @json__NS_parse(ptr %0, i32 %1, %__memstr_fat__ %2) {
entry:
  %src = alloca ptr, align 8
  store ptr %0, ptr %src, align 8
  %len = alloca i32, align 4
  store i32 %1, ptr %len, align 4
  %a = alloca %__memstr_fat__, align 8
  store %__memstr_fat__ %2, ptr %a, align 8
  %l = alloca ptr, align 8
  store ptr null, ptr %l, align 8
  %a1 = load %__memstr_fat__, ptr %a, align 8
  %3 = call ptr @json__NS_parse_value(ptr %l, %__memstr_fat__ %a1)
  ret ptr %3
}

define internal ptr @json__NS_parse_str(ptr %0, %__memstr_fat__ %1) {
entry:
  %src = alloca ptr, align 8
  store ptr %0, ptr %src, align 8
  %a = alloca %__memstr_fat__, align 8
  store %__memstr_fat__ %1, ptr %a, align 8
  %n = alloca i32, align 4
  store i32 0, ptr %n, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %n1 = load i32, ptr %n, align 4
  %ptr_load = load ptr, ptr %src, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %n1
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp ne i8 %idx_load, 0
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %n2 = load i32, ptr %n, align 4
  %add = add i32 %n2, 1
  store i32 %add, ptr %n, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %src3 = load ptr, ptr %src, align 8
  %n4 = load i32, ptr %n, align 4
  %a5 = load %__memstr_fat__, ptr %a, align 8
  %2 = call ptr @json__NS_parse(ptr %src3, i32 %n4, %__memstr_fat__ %a5)
  ret ptr %2
}

define internal i8 @json__NS_is_null(ptr %0) {
entry:
  %v = alloca ptr, align 8
  store ptr %0, ptr %v, align 8
  %ptr_deref = load ptr, ptr %v, align 8
  %kind = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %v, align 8
  %mem_load = load i32, ptr %kind, align 4
  %JSON_NULL = load i32, ptr @json__NS_JSON_NULL, align 4
  %icmp = icmp eq i32 %mem_load, %JSON_NULL
  %zext = zext i1 %icmp to i8
  ret i8 %zext
}

define internal i8 @json__NS_is_bool(ptr %0) {
entry:
  %v = alloca ptr, align 8
  store ptr %0, ptr %v, align 8
  %ptr_deref = load ptr, ptr %v, align 8
  %kind = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %v, align 8
  %mem_load = load i32, ptr %kind, align 4
  %JSON_BOOL = load i32, ptr @json__NS_JSON_BOOL, align 4
  %icmp = icmp eq i32 %mem_load, %JSON_BOOL
  %zext = zext i1 %icmp to i8
  ret i8 %zext
}

define internal i8 @json__NS_is_int(ptr %0) {
entry:
  %v = alloca ptr, align 8
  store ptr %0, ptr %v, align 8
  %ptr_deref = load ptr, ptr %v, align 8
  %kind = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %v, align 8
  %mem_load = load i32, ptr %kind, align 4
  %JSON_INT = load i32, ptr @json__NS_JSON_INT, align 4
  %icmp = icmp eq i32 %mem_load, %JSON_INT
  %zext = zext i1 %icmp to i8
  ret i8 %zext
}

define internal i8 @json__NS_is_float(ptr %0) {
entry:
  %v = alloca ptr, align 8
  store ptr %0, ptr %v, align 8
  %ptr_deref = load ptr, ptr %v, align 8
  %kind = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %v, align 8
  %mem_load = load i32, ptr %kind, align 4
  %JSON_FLOAT = load i32, ptr @json__NS_JSON_FLOAT, align 4
  %icmp = icmp eq i32 %mem_load, %JSON_FLOAT
  %zext = zext i1 %icmp to i8
  ret i8 %zext
}

define internal i8 @json__NS_is_string(ptr %0) {
entry:
  %v = alloca ptr, align 8
  store ptr %0, ptr %v, align 8
  %ptr_deref = load ptr, ptr %v, align 8
  %kind = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %v, align 8
  %mem_load = load i32, ptr %kind, align 4
  %JSON_STRING = load i32, ptr @json__NS_JSON_STRING, align 4
  %icmp = icmp eq i32 %mem_load, %JSON_STRING
  %zext = zext i1 %icmp to i8
  ret i8 %zext
}

define internal i8 @json__NS_is_array(ptr %0) {
entry:
  %v = alloca ptr, align 8
  store ptr %0, ptr %v, align 8
  %ptr_deref = load ptr, ptr %v, align 8
  %kind = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %v, align 8
  %mem_load = load i32, ptr %kind, align 4
  %JSON_ARRAY = load i32, ptr @json__NS_JSON_ARRAY, align 4
  %icmp = icmp eq i32 %mem_load, %JSON_ARRAY
  %zext = zext i1 %icmp to i8
  ret i8 %zext
}

define internal i8 @json__NS_is_object(ptr %0) {
entry:
  %v = alloca ptr, align 8
  store ptr %0, ptr %v, align 8
  %ptr_deref = load ptr, ptr %v, align 8
  %kind = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %v, align 8
  %mem_load = load i32, ptr %kind, align 4
  %JSON_OBJECT = load i32, ptr @json__NS_JSON_OBJECT, align 4
  %icmp = icmp eq i32 %mem_load, %JSON_OBJECT
  %zext = zext i1 %icmp to i8
  ret i8 %zext
}

define internal i8 @json__NS_as_bool(ptr %0) {
entry:
  %v = alloca ptr, align 8
  store ptr %0, ptr %v, align 8
  %ptr_deref = load ptr, ptr %v, align 8
  %b_val = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref1 = load ptr, ptr %v, align 8
  %mem_load = load i8, ptr %b_val, align 1
  ret i8 %mem_load
}

define internal i64 @json__NS_as_int(ptr %0) {
entry:
  %v = alloca ptr, align 8
  store ptr %0, ptr %v, align 8
  %ptr_deref = load ptr, ptr %v, align 8
  %i_val = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 2
  %ptr_deref1 = load ptr, ptr %v, align 8
  %mem_load = load i64, ptr %i_val, align 4
  ret i64 %mem_load
}

define internal double @json__NS_as_float(ptr %0) {
entry:
  %v = alloca ptr, align 8
  store ptr %0, ptr %v, align 8
  %ptr_deref = load ptr, ptr %v, align 8
  %f_val = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 3
  %ptr_deref1 = load ptr, ptr %v, align 8
  %mem_load = load double, ptr %f_val, align 8
  ret double %mem_load
}

define internal ptr @json__NS_as_string(ptr %0) {
entry:
  %v = alloca ptr, align 8
  store ptr %0, ptr %v, align 8
  %ptr_deref = load ptr, ptr %v, align 8
  %s_val = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 4
  %ptr_deref1 = load ptr, ptr %v, align 8
  %mem_load = load ptr, ptr %s_val, align 8
  ret ptr %mem_load
}

define internal ptr @json__NS_array_at(ptr %0, i32 %1) {
entry:
  %v = alloca ptr, align 8
  store ptr %0, ptr %v, align 8
  %i = alloca i32, align 4
  store i32 %1, ptr %i, align 4
  %ptr_deref = load ptr, ptr %v, align 8
  %arr_items = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 5
  %i1 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %arr_items, align 8
  %ptr_gep = getelementptr ptr, ptr %ptr_load, i32 %i1
  %idx_load = load ptr, ptr %ptr_gep, align 8
  ret ptr %idx_load
}

define internal i32 @json__NS_array_len(ptr %0) {
entry:
  %v = alloca ptr, align 8
  store ptr %0, ptr %v, align 8
  %ptr_deref = load ptr, ptr %v, align 8
  %arr_len = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 6
  %ptr_deref1 = load ptr, ptr %v, align 8
  %mem_load = load i32, ptr %arr_len, align 4
  ret i32 %mem_load
}

define internal ptr @json__NS_object_get(ptr %0, ptr %1) {
entry:
  %v = alloca ptr, align 8
  store ptr %0, ptr %v, align 8
  %key = alloca ptr, align 8
  store ptr %1, ptr %key, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %for_cond

for_cond:                                         ; preds = %for_step, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_deref = load ptr, ptr %v, align 8
  %obj_len = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 8
  %ptr_deref2 = load ptr, ptr %v, align 8
  %mem_load = load i32, ptr %obj_len, align 4
  %icmp = icmp slt i32 %i1, %mem_load
  br i1 %icmp, label %for_body, label %for_exit

for_body:                                         ; preds = %for_cond
  %k = alloca ptr, align 8
  %ptr_deref3 = load ptr, ptr %v, align 8
  %obj_pairs = getelementptr inbounds nuw %json_val, ptr %ptr_deref3, i32 0, i32 7
  %i4 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %obj_pairs, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i4
  store ptr null, ptr %k, align 8
  %j = alloca i32, align 4
  store i32 0, ptr %j, align 4
  %eq = alloca i8, align 1
  store i8 1, ptr %eq, align 1
  br label %while_cond

for_step:                                         ; preds = %if_merge38
  %i44 = load i32, ptr %i, align 4
  %add45 = add i32 %i44, 1
  store i32 %add45, ptr %i, align 4
  br label %for_cond

for_exit:                                         ; preds = %for_cond
  ret ptr null

while_cond:                                       ; preds = %if_merge, %for_body
  %j5 = load i32, ptr %j, align 4
  %ptr_load6 = load ptr, ptr %k, align 8
  %ptr_gep7 = getelementptr i8, ptr %ptr_load6, i32 %j5
  %idx_load = load i8, ptr %ptr_gep7, align 1
  %icmp8 = icmp ne i8 %idx_load, 0
  br i1 %icmp8, label %land_rhs, label %land_merge

while_body:                                       ; preds = %land_merge
  %j14 = load i32, ptr %j, align 4
  %ptr_load15 = load ptr, ptr %k, align 8
  %ptr_gep16 = getelementptr i8, ptr %ptr_load15, i32 %j14
  %idx_load17 = load i8, ptr %ptr_gep16, align 1
  %j18 = load i32, ptr %j, align 4
  %ptr_load19 = load ptr, ptr %key, align 8
  %ptr_gep20 = getelementptr i8, ptr %ptr_load19, i32 %j18
  %idx_load21 = load i8, ptr %ptr_gep20, align 1
  %icmp22 = icmp ne i8 %idx_load17, %idx_load21
  br i1 %icmp22, label %if_then, label %if_merge

while_exit:                                       ; preds = %if_then, %land_merge
  %eq24 = load i8, ptr %eq, align 1
  %tobool = icmp ne i8 %eq24, 0
  br i1 %tobool, label %land_rhs25, label %land_merge26

land_rhs:                                         ; preds = %while_cond
  %j9 = load i32, ptr %j, align 4
  %ptr_load10 = load ptr, ptr %key, align 8
  %ptr_gep11 = getelementptr i8, ptr %ptr_load10, i32 %j9
  %idx_load12 = load i8, ptr %ptr_gep11, align 1
  %icmp13 = icmp ne i8 %idx_load12, 0
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond
  %land = phi i1 [ false, %while_cond ], [ %icmp13, %land_rhs ]
  br i1 %land, label %while_body, label %while_exit

if_then:                                          ; preds = %while_body
  store i8 0, ptr %eq, align 1
  br label %while_exit

if_merge:                                         ; preds = %while_body
  %j23 = load i32, ptr %j, align 4
  %add = add i32 %j23, 1
  store i32 %add, ptr %j, align 4
  br label %while_cond

land_rhs25:                                       ; preds = %while_exit
  %j27 = load i32, ptr %j, align 4
  %ptr_load28 = load ptr, ptr %k, align 8
  %ptr_gep29 = getelementptr i8, ptr %ptr_load28, i32 %j27
  %idx_load30 = load i8, ptr %ptr_gep29, align 1
  %j31 = load i32, ptr %j, align 4
  %ptr_load32 = load ptr, ptr %key, align 8
  %ptr_gep33 = getelementptr i8, ptr %ptr_load32, i32 %j31
  %idx_load34 = load i8, ptr %ptr_gep33, align 1
  %icmp35 = icmp eq i8 %idx_load30, %idx_load34
  br label %land_merge26

land_merge26:                                     ; preds = %land_rhs25, %while_exit
  %land36 = phi i1 [ false, %while_exit ], [ %icmp35, %land_rhs25 ]
  br i1 %land36, label %if_then37, label %if_merge38

if_then37:                                        ; preds = %land_merge26
  %ptr_deref39 = load ptr, ptr %v, align 8
  %obj_pairs40 = getelementptr inbounds nuw %json_val, ptr %ptr_deref39, i32 0, i32 7
  %i41 = load i32, ptr %i, align 4
  %ptr_load42 = load ptr, ptr %obj_pairs40, align 8
  %ptr_gep43 = getelementptr i8, ptr %ptr_load42, i32 %i41
  ret ptr undef

if_merge38:                                       ; preds = %land_merge26
  br label %for_step
}

define internal void @lex__NS___construct__(ptr %0, ptr %1, i32 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %s = alloca ptr, align 8
  store ptr %1, ptr %s, align 8
  %n = alloca i32, align 4
  store i32 %2, ptr %n, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %src = getelementptr inbounds nuw %lex, ptr %ptr_deref, i32 0, i32 0
  %s1 = load ptr, ptr %s, align 8
  store ptr %s1, ptr %src, align 8
  %ptr_deref2 = load ptr, ptr %self, align 8
  %pos = getelementptr inbounds nuw %lex, ptr %ptr_deref2, i32 0, i32 1
  store i32 0, ptr %pos, align 4
  %ptr_deref3 = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %lex, ptr %ptr_deref3, i32 0, i32 2
  %n4 = load i32, ptr %n, align 4
  store i32 %n4, ptr %len, align 4
  ret void
}

define internal void @lex__NS_skip_ws(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %ptr_deref = load ptr, ptr %self, align 8
  %pos = getelementptr inbounds nuw %lex, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %pos, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %lex, ptr %ptr_deref2, i32 0, i32 2
  %ptr_deref3 = load ptr, ptr %self, align 8
  %mem_load4 = load i32, ptr %len, align 4
  %icmp = icmp slt i32 %mem_load, %mem_load4
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %c = alloca i8, align 1
  %ptr_deref5 = load ptr, ptr %self, align 8
  %src = getelementptr inbounds nuw %lex, ptr %ptr_deref5, i32 0, i32 0
  %ptr_deref6 = load ptr, ptr %self, align 8
  %pos7 = getelementptr inbounds nuw %lex, ptr %ptr_deref6, i32 0, i32 1
  %ptr_deref8 = load ptr, ptr %self, align 8
  %mem_load9 = load i32, ptr %pos7, align 4
  %ptr_load = load ptr, ptr %src, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load9
  %idx_load = load i8, ptr %ptr_gep, align 1
  store i8 %idx_load, ptr %c, align 1
  %c10 = load i8, ptr %c, align 1
  %icmp11 = icmp eq i8 %c10, 32
  br i1 %icmp11, label %lor_merge, label %lor_rhs

while_exit:                                       ; preds = %if_else, %while_cond
  ret void

lor_rhs:                                          ; preds = %while_body
  %c12 = load i8, ptr %c, align 1
  %icmp13 = icmp eq i8 %c12, 9
  br label %lor_merge

lor_merge:                                        ; preds = %lor_rhs, %while_body
  %lor = phi i1 [ true, %while_body ], [ %icmp13, %lor_rhs ]
  br i1 %lor, label %lor_merge15, label %lor_rhs14

lor_rhs14:                                        ; preds = %lor_merge
  %c16 = load i8, ptr %c, align 1
  %icmp17 = icmp eq i8 %c16, 13
  br label %lor_merge15

lor_merge15:                                      ; preds = %lor_rhs14, %lor_merge
  %lor18 = phi i1 [ true, %lor_merge ], [ %icmp17, %lor_rhs14 ]
  br i1 %lor18, label %lor_merge20, label %lor_rhs19

lor_rhs19:                                        ; preds = %lor_merge15
  %c21 = load i8, ptr %c, align 1
  %icmp22 = icmp eq i8 %c21, 10
  br label %lor_merge20

lor_merge20:                                      ; preds = %lor_rhs19, %lor_merge15
  %lor23 = phi i1 [ true, %lor_merge15 ], [ %icmp22, %lor_rhs19 ]
  br i1 %lor23, label %if_then, label %if_else

if_then:                                          ; preds = %lor_merge20
  %ptr_deref24 = load ptr, ptr %self, align 8
  %pos25 = getelementptr inbounds nuw %lex, ptr %ptr_deref24, i32 0, i32 1
  %ptr_deref26 = load ptr, ptr %self, align 8
  %pos27 = getelementptr inbounds nuw %lex, ptr %ptr_deref26, i32 0, i32 1
  %ptr_deref28 = load ptr, ptr %self, align 8
  %mem_load29 = load i32, ptr %pos27, align 4
  %add = add i32 %mem_load29, 1
  store i32 %add, ptr %pos25, align 4
  br label %if_merge

if_else:                                          ; preds = %lor_merge20
  br label %while_exit

if_merge:                                         ; preds = %if_then
  br label %while_cond
}

define internal i8 @lex__NS_at_end(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %pos = getelementptr inbounds nuw %lex, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %pos, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %lex, ptr %ptr_deref2, i32 0, i32 2
  %ptr_deref3 = load ptr, ptr %self, align 8
  %mem_load4 = load i32, ptr %len, align 4
  %icmp = icmp sge i32 %mem_load, %mem_load4
  %zext = zext i1 %icmp to i8
  ret i8 %zext
}

define internal i8 @lex__NS_peek(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %pos = getelementptr inbounds nuw %lex, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %pos, align 4
  %ptr_deref2 = load ptr, ptr %self, align 8
  %len = getelementptr inbounds nuw %lex, ptr %ptr_deref2, i32 0, i32 2
  %ptr_deref3 = load ptr, ptr %self, align 8
  %mem_load4 = load i32, ptr %len, align 4
  %icmp = icmp slt i32 %mem_load, %mem_load4
  br i1 %icmp, label %tern_then, label %tern_else

tern_then:                                        ; preds = %entry
  %ptr_deref5 = load ptr, ptr %self, align 8
  %src = getelementptr inbounds nuw %lex, ptr %ptr_deref5, i32 0, i32 0
  %ptr_deref6 = load ptr, ptr %self, align 8
  %pos7 = getelementptr inbounds nuw %lex, ptr %ptr_deref6, i32 0, i32 1
  %ptr_deref8 = load ptr, ptr %self, align 8
  %mem_load9 = load i32, ptr %pos7, align 4
  %ptr_load = load ptr, ptr %src, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load9
  %idx_load = load i8, ptr %ptr_gep, align 1
  %ext = sext i8 %idx_load to i32
  br label %tern_merge

tern_else:                                        ; preds = %entry
  br label %tern_merge

tern_merge:                                       ; preds = %tern_else, %tern_then
  %tern = phi i32 [ %ext, %tern_then ], [ 0, %tern_else ]
  %trunc = trunc i32 %tern to i8
  ret i8 %trunc
}

define internal i8 @lex__NS_next(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %c = alloca i8, align 1
  %ptr_deref = load ptr, ptr %self, align 8
  %src = getelementptr inbounds nuw %lex, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %pos = getelementptr inbounds nuw %lex, ptr %ptr_deref1, i32 0, i32 1
  %ptr_deref2 = load ptr, ptr %self, align 8
  %mem_load = load i32, ptr %pos, align 4
  %ptr_load = load ptr, ptr %src, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %mem_load
  %idx_load = load i8, ptr %ptr_gep, align 1
  store i8 %idx_load, ptr %c, align 1
  %ptr_deref3 = load ptr, ptr %self, align 8
  %pos4 = getelementptr inbounds nuw %lex, ptr %ptr_deref3, i32 0, i32 1
  %ptr_deref5 = load ptr, ptr %self, align 8
  %pos6 = getelementptr inbounds nuw %lex, ptr %ptr_deref5, i32 0, i32 1
  %ptr_deref7 = load ptr, ptr %self, align 8
  %mem_load8 = load i32, ptr %pos6, align 4
  %add = add i32 %mem_load8, 1
  store i32 %add, ptr %pos4, align 4
  %c9 = load i8, ptr %c, align 1
  ret i8 %c9
}

declare ptr @malloc(i64)

declare void @free(ptr)

declare i64 @strlen(ptr)

define internal void @Bump__NS___construct__(ptr %0, i64 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %n = alloca i64, align 8
  store i64 %1, ptr %n, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %base = getelementptr inbounds nuw %Bump, ptr %ptr_deref, i32 0, i32 0
  %n1 = load i64, ptr %n, align 4
  %2 = call ptr @malloc(i64 %n1)
  store ptr %2, ptr %base, align 8
  %ptr_deref2 = load ptr, ptr %self, align 8
  %used = getelementptr inbounds nuw %Bump, ptr %ptr_deref2, i32 0, i32 1
  store i64 0, ptr %used, align 4
  %ptr_deref3 = load ptr, ptr %self, align 8
  %cap = getelementptr inbounds nuw %Bump, ptr %ptr_deref3, i32 0, i32 2
  %n4 = load i64, ptr %n, align 4
  store i64 %n4, ptr %cap, align 4
  ret void
}

define internal ptr @Bump__NS_mmap(ptr %0, i64 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %n = alloca i64, align 8
  store i64 %1, ptr %n, align 4
  %al = alloca i64, align 8
  %n1 = load i64, ptr %n, align 4
  %add = add i64 %n1, 7
  %and = and i64 %add, -8
  store i64 %and, ptr %al, align 4
  %ptr_deref = load ptr, ptr %self, align 8
  %used = getelementptr inbounds nuw %Bump, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref2 = load ptr, ptr %self, align 8
  %mem_load = load i64, ptr %used, align 4
  %al3 = load i64, ptr %al, align 4
  %add4 = add i64 %mem_load, %al3
  %ptr_deref5 = load ptr, ptr %self, align 8
  %cap = getelementptr inbounds nuw %Bump, ptr %ptr_deref5, i32 0, i32 2
  %ptr_deref6 = load ptr, ptr %self, align 8
  %mem_load7 = load i64, ptr %cap, align 4
  %icmp = icmp sgt i64 %add4, %mem_load7
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret ptr null

if_merge:                                         ; preds = %entry
  %p = alloca ptr, align 8
  %ptr_deref8 = load ptr, ptr %self, align 8
  %base = getelementptr inbounds nuw %Bump, ptr %ptr_deref8, i32 0, i32 0
  %ptr_deref9 = load ptr, ptr %self, align 8
  %mem_load10 = load ptr, ptr %base, align 8
  %ptr_deref11 = load ptr, ptr %self, align 8
  %used12 = getelementptr inbounds nuw %Bump, ptr %ptr_deref11, i32 0, i32 1
  %ptr_deref13 = load ptr, ptr %self, align 8
  %mem_load14 = load i64, ptr %used12, align 4
  %ptr_add = getelementptr i8, ptr %mem_load10, i64 %mem_load14
  store ptr %ptr_add, ptr %p, align 8
  %ptr_deref15 = load ptr, ptr %self, align 8
  %used16 = getelementptr inbounds nuw %Bump, ptr %ptr_deref15, i32 0, i32 1
  %ptr_deref17 = load ptr, ptr %self, align 8
  %used18 = getelementptr inbounds nuw %Bump, ptr %ptr_deref17, i32 0, i32 1
  %ptr_deref19 = load ptr, ptr %self, align 8
  %mem_load20 = load i64, ptr %used18, align 4
  %al21 = load i64, ptr %al, align 4
  %add22 = add i64 %mem_load20, %al21
  store i64 %add22, ptr %used16, align 4
  %p23 = load ptr, ptr %p, align 8
  ret ptr %p23
}

define internal void @Bump__NS_rmap(ptr %0, ptr %1, i64 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %p = alloca ptr, align 8
  store ptr %1, ptr %p, align 8
  %n = alloca i64, align 8
  store i64 %2, ptr %n, align 4
  ret void
}

define internal void @Bump__NS_deinit(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %base = getelementptr inbounds nuw %Bump, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %mem_load = load ptr, ptr %base, align 8
  call void @free(ptr %mem_load)
  ret void
}

define i32 @main() {
entry:
  %a = alloca %Bump, align 8
  store %Bump zeroinitializer, ptr %a, align 8
  call void @Bump__NS___construct__(ptr %a, i64 65536)
  %s1 = alloca ptr, align 8
  store ptr @str, ptr %s1, align 8
  %v1 = alloca ptr, align 8
  %s11 = load ptr, ptr %s1, align 8
  %s12 = load ptr, ptr %s1, align 8
  %0 = call i64 @strlen(ptr %s12)
  %trunc = trunc i64 %0 to i32
  %a3 = load %Bump, ptr %a, align 8
  %ms_tmp = alloca %Bump, align 8
  store %Bump %a3, ptr %ms_tmp, align 8
  %fat_d = insertvalue %__memstr_fat__ undef, ptr %ms_tmp, 0
  %fat_v = insertvalue %__memstr_fat__ %fat_d, ptr @Bump__vtable__, 1
  %1 = call ptr @json__NS_parse(ptr %s11, i32 %trunc, %__memstr_fat__ %fat_v)
  store ptr %1, ptr %v1, align 8
  %v14 = load ptr, ptr %v1, align 8
  %icmp = icmp eq ptr %v14, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 1

if_merge:                                         ; preds = %entry
  %ptr_deref = load ptr, ptr %v1, align 8
  %kind = getelementptr inbounds nuw %json_val, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref5 = load ptr, ptr %v1, align 8
  %mem_load = load i32, ptr %kind, align 4
  %icmp6 = icmp ne i32 %mem_load, 2
  br i1 %icmp6, label %if_then7, label %if_merge8

if_then7:                                         ; preds = %if_merge
  ret i32 2

if_merge8:                                        ; preds = %if_merge
  %ptr_deref9 = load ptr, ptr %v1, align 8
  %i_val = getelementptr inbounds nuw %json_val, ptr %ptr_deref9, i32 0, i32 2
  %ptr_deref10 = load ptr, ptr %v1, align 8
  %mem_load11 = load i64, ptr %i_val, align 4
  %icmp12 = icmp ne i64 %mem_load11, 42
  br i1 %icmp12, label %if_then13, label %if_merge14

if_then13:                                        ; preds = %if_merge8
  ret i32 3

if_merge14:                                       ; preds = %if_merge8
  %s2 = alloca ptr, align 8
  store ptr @str.1, ptr %s2, align 8
  %v2 = alloca ptr, align 8
  %s215 = load ptr, ptr %s2, align 8
  %s216 = load ptr, ptr %s2, align 8
  %2 = call i64 @strlen(ptr %s216)
  %trunc17 = trunc i64 %2 to i32
  %a18 = load %Bump, ptr %a, align 8
  %ms_tmp19 = alloca %Bump, align 8
  store %Bump %a18, ptr %ms_tmp19, align 8
  %fat_d20 = insertvalue %__memstr_fat__ undef, ptr %ms_tmp19, 0
  %fat_v21 = insertvalue %__memstr_fat__ %fat_d20, ptr @Bump__vtable__, 1
  %3 = call ptr @json__NS_parse(ptr %s215, i32 %trunc17, %__memstr_fat__ %fat_v21)
  store ptr %3, ptr %v2, align 8
  %v222 = load ptr, ptr %v2, align 8
  %icmp23 = icmp eq ptr %v222, null
  br i1 %icmp23, label %lor_merge, label %lor_rhs

lor_rhs:                                          ; preds = %if_merge14
  %ptr_deref24 = load ptr, ptr %v2, align 8
  %kind25 = getelementptr inbounds nuw %json_val, ptr %ptr_deref24, i32 0, i32 0
  %ptr_deref26 = load ptr, ptr %v2, align 8
  %mem_load27 = load i32, ptr %kind25, align 4
  %icmp28 = icmp ne i32 %mem_load27, 1
  br label %lor_merge

lor_merge:                                        ; preds = %lor_rhs, %if_merge14
  %lor = phi i1 [ true, %if_merge14 ], [ %icmp28, %lor_rhs ]
  br i1 %lor, label %if_then29, label %if_merge30

if_then29:                                        ; preds = %lor_merge
  ret i32 4

if_merge30:                                       ; preds = %lor_merge
  %ptr_deref31 = load ptr, ptr %v2, align 8
  %b_val = getelementptr inbounds nuw %json_val, ptr %ptr_deref31, i32 0, i32 1
  %ptr_deref32 = load ptr, ptr %v2, align 8
  %mem_load33 = load i8, ptr %b_val, align 1
  %tobool = icmp ne i8 %mem_load33, 0
  %not = xor i1 %tobool, true
  br i1 %not, label %if_then34, label %if_merge35

if_then34:                                        ; preds = %if_merge30
  ret i32 5

if_merge35:                                       ; preds = %if_merge30
  %s3 = alloca ptr, align 8
  store ptr @str.2, ptr %s3, align 8
  %v3 = alloca ptr, align 8
  %s336 = load ptr, ptr %s3, align 8
  %s337 = load ptr, ptr %s3, align 8
  %4 = call i64 @strlen(ptr %s337)
  %trunc38 = trunc i64 %4 to i32
  %a39 = load %Bump, ptr %a, align 8
  %ms_tmp40 = alloca %Bump, align 8
  store %Bump %a39, ptr %ms_tmp40, align 8
  %fat_d41 = insertvalue %__memstr_fat__ undef, ptr %ms_tmp40, 0
  %fat_v42 = insertvalue %__memstr_fat__ %fat_d41, ptr @Bump__vtable__, 1
  %5 = call ptr @json__NS_parse(ptr %s336, i32 %trunc38, %__memstr_fat__ %fat_v42)
  store ptr %5, ptr %v3, align 8
  %v343 = load ptr, ptr %v3, align 8
  %icmp44 = icmp eq ptr %v343, null
  br i1 %icmp44, label %lor_merge46, label %lor_rhs45

lor_rhs45:                                        ; preds = %if_merge35
  %ptr_deref47 = load ptr, ptr %v3, align 8
  %kind48 = getelementptr inbounds nuw %json_val, ptr %ptr_deref47, i32 0, i32 0
  %ptr_deref49 = load ptr, ptr %v3, align 8
  %mem_load50 = load i32, ptr %kind48, align 4
  %icmp51 = icmp ne i32 %mem_load50, 5
  br label %lor_merge46

lor_merge46:                                      ; preds = %lor_rhs45, %if_merge35
  %lor52 = phi i1 [ true, %if_merge35 ], [ %icmp51, %lor_rhs45 ]
  br i1 %lor52, label %if_then53, label %if_merge54

if_then53:                                        ; preds = %lor_merge46
  ret i32 6

if_merge54:                                       ; preds = %lor_merge46
  %ptr_deref55 = load ptr, ptr %v3, align 8
  %arr_len = getelementptr inbounds nuw %json_val, ptr %ptr_deref55, i32 0, i32 6
  %ptr_deref56 = load ptr, ptr %v3, align 8
  %mem_load57 = load i32, ptr %arr_len, align 4
  %icmp58 = icmp ne i32 %mem_load57, 3
  br i1 %icmp58, label %if_then59, label %if_merge60

if_then59:                                        ; preds = %if_merge54
  ret i32 7

if_merge60:                                       ; preds = %if_merge54
  %ptr_deref61 = load ptr, ptr %v3, align 8
  %arr_items = getelementptr inbounds nuw %json_val, ptr %ptr_deref61, i32 0, i32 5
  %ptr_load = load ptr, ptr %arr_items, align 8
  %ptr_gep = getelementptr ptr, ptr %ptr_load, i32 0
  %ptr_deref62 = load ptr, ptr %v3, align 8
  %arr_items63 = getelementptr inbounds nuw %json_val, ptr %ptr_deref62, i32 0, i32 5
  %ptr_load64 = load ptr, ptr %arr_items63, align 8
  %ptr_gep65 = getelementptr ptr, ptr %ptr_load64, i32 2
  %s4 = alloca ptr, align 8
  store ptr @str.3, ptr %s4, align 8
  %v4 = alloca ptr, align 8
  %s466 = load ptr, ptr %s4, align 8
  %s467 = load ptr, ptr %s4, align 8
  %6 = call i64 @strlen(ptr %s467)
  %trunc68 = trunc i64 %6 to i32
  %a69 = load %Bump, ptr %a, align 8
  %ms_tmp70 = alloca %Bump, align 8
  store %Bump %a69, ptr %ms_tmp70, align 8
  %fat_d71 = insertvalue %__memstr_fat__ undef, ptr %ms_tmp70, 0
  %fat_v72 = insertvalue %__memstr_fat__ %fat_d71, ptr @Bump__vtable__, 1
  %7 = call ptr @json__NS_parse(ptr %s466, i32 %trunc68, %__memstr_fat__ %fat_v72)
  store ptr %7, ptr %v4, align 8
  %v473 = load ptr, ptr %v4, align 8
  %icmp74 = icmp eq ptr %v473, null
  br i1 %icmp74, label %lor_merge76, label %lor_rhs75

lor_rhs75:                                        ; preds = %if_merge60
  %ptr_deref77 = load ptr, ptr %v4, align 8
  %kind78 = getelementptr inbounds nuw %json_val, ptr %ptr_deref77, i32 0, i32 0
  %ptr_deref79 = load ptr, ptr %v4, align 8
  %mem_load80 = load i32, ptr %kind78, align 4
  %icmp81 = icmp ne i32 %mem_load80, 6
  br label %lor_merge76

lor_merge76:                                      ; preds = %lor_rhs75, %if_merge60
  %lor82 = phi i1 [ true, %if_merge60 ], [ %icmp81, %lor_rhs75 ]
  br i1 %lor82, label %if_then83, label %if_merge84

if_then83:                                        ; preds = %lor_merge76
  ret i32 10

if_merge84:                                       ; preds = %lor_merge76
  %gv = alloca ptr, align 8
  %v485 = load ptr, ptr %v4, align 8
  %8 = call ptr @json__NS_object_get(ptr %v485, ptr @str.4)
  store ptr %8, ptr %gv, align 8
  %gv86 = load ptr, ptr %gv, align 8
  %icmp87 = icmp eq ptr %gv86, null
  br i1 %icmp87, label %lor_merge89, label %lor_rhs88

lor_rhs88:                                        ; preds = %if_merge84
  %ptr_deref90 = load ptr, ptr %gv, align 8
  %i_val91 = getelementptr inbounds nuw %json_val, ptr %ptr_deref90, i32 0, i32 2
  %ptr_deref92 = load ptr, ptr %gv, align 8
  %mem_load93 = load i64, ptr %i_val91, align 4
  %icmp94 = icmp ne i64 %mem_load93, 7
  br label %lor_merge89

lor_merge89:                                      ; preds = %lor_rhs88, %if_merge84
  %lor95 = phi i1 [ true, %if_merge84 ], [ %icmp94, %lor_rhs88 ]
  br i1 %lor95, label %if_then96, label %if_merge97

if_then96:                                        ; preds = %lor_merge89
  ret i32 11

if_merge97:                                       ; preds = %lor_merge89
  call void @Bump__NS_deinit(ptr %a)
  ret i32 0
}
