; ModuleID = 'compiler/real_rep.arc'
source_filename = "compiler/real_rep.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%__vtable__ = type { ptr, ptr, ptr, ptr, ptr }
%type_info = type { i32, [72 x i8] }
%type_info_field = type { ptr, i32, i32, i32 }
%memstr = type { ptr, ptr }
%SysAlloc = type {}
%__anon2_P_i32 = type { ptr, i32 }
%__anon1_P = type { ptr }
%__anon0 = type {}

@type_info__Void = internal constant i32 0
@type_info__Bool = internal constant i32 1
@type_info__Int = internal constant i32 2
@type_info__Uint = internal constant i32 3
@type_info__Float = internal constant i32 4
@type_info__Char = internal constant i32 5
@type_info__Usize = internal constant i32 6
@type_info__Isize = internal constant i32 7
@type_info__Iofs = internal constant i32 8
@type_info__Pointer = internal constant i32 9
@type_info__Array = internal constant i32 10
@type_info__Slice = internal constant i32 11
@type_info__Struct = internal constant i32 12
@type_info__Istruc = internal constant i32 13
@type_info__Union = internal constant i32 14
@type_info__Enum = internal constant i32 15
@type_info__AdtEnum = internal constant i32 16
@type_info__Interface = internal constant i32 17
@type_info__Fn = internal constant i32 18
@type_info__Lambda = internal constant i32 19
@type_info__ErrorUnion = internal constant i32 20
@type_info__Optional = internal constant i32 21
@type_info__AnyType = internal constant i32 22
@type_info_num__SInt = internal constant i32 0
@type_info_num__UInt = internal constant i32 1
@type_info_num__Float = internal constant i32 2
@type_info_num__Usize = internal constant i32 3
@type_info_num__Isize = internal constant i32 4
@type_info_num__Iofs = internal constant i32 5
@__artemis_error_payload = global ptr null
@LLVMTypeKindEnum__LLVMVoidTypeKind = internal constant i32 0
@LLVMTypeKindEnum__LLVMHalfTypeKind = internal constant i32 1
@LLVMTypeKindEnum__LLVMFloatTypeKind = internal constant i32 2
@LLVMTypeKindEnum__LLVMDoubleTypeKind = internal constant i32 3
@LLVMTypeKindEnum__LLVMX86_FP80TypeKind = internal constant i32 4
@LLVMTypeKindEnum__LLVMFP128TypeKind = internal constant i32 5
@LLVMTypeKindEnum__LLVMPPC_FP128TypeKind = internal constant i32 6
@LLVMTypeKindEnum__LLVMLabelTypeKind = internal constant i32 7
@LLVMTypeKindEnum__LLVMIntegerTypeKind = internal constant i32 8
@LLVMTypeKindEnum__LLVMFunctionTypeKind = internal constant i32 9
@LLVMTypeKindEnum__LLVMStructTypeKind = internal constant i32 10
@LLVMTypeKindEnum__LLVMArrayTypeKind = internal constant i32 11
@LLVMTypeKindEnum__LLVMPointerTypeKind = internal constant i32 12
@LLVMTypeKindEnum__LLVMVectorTypeKind = internal constant i32 13
@LLVMTypeKindEnum__LLVMMetadataTypeKind = internal constant i32 14
@LLVMTypeKindEnum__LLVMBFloatTypeKind = internal constant i32 19
@LLVMAtomicOrderingEnum__LLVMAtomicOrderingNotAtomic = internal constant i32 0
@LLVMAtomicOrderingEnum__LLVMAtomicOrderingUnordered = internal constant i32 1
@LLVMAtomicOrderingEnum__LLVMAtomicOrderingMonotonic = internal constant i32 2
@LLVMAtomicOrderingEnum__LLVMAtomicOrderingAcquire = internal constant i32 4
@LLVMAtomicOrderingEnum__LLVMAtomicOrderingRelease = internal constant i32 5
@LLVMAtomicOrderingEnum__LLVMAtomicOrderingAcquireRelease = internal constant i32 6
@LLVMAtomicOrderingEnum__LLVMAtomicOrderingSequentiallyConsistent = internal constant i32 7
@LLVMAtomicRMWBinOpEnum__LLVMAtomicRMWBinOpXchg = internal constant i32 0
@LLVMAtomicRMWBinOpEnum__LLVMAtomicRMWBinOpAdd = internal constant i32 1
@LLVMAtomicRMWBinOpEnum__LLVMAtomicRMWBinOpSub = internal constant i32 2
@LLVMAtomicRMWBinOpEnum__LLVMAtomicRMWBinOpAnd = internal constant i32 3
@LLVMAtomicRMWBinOpEnum__LLVMAtomicRMWBinOpNand = internal constant i32 4
@LLVMAtomicRMWBinOpEnum__LLVMAtomicRMWBinOpOr = internal constant i32 5
@LLVMAtomicRMWBinOpEnum__LLVMAtomicRMWBinOpXor = internal constant i32 6
@LLVMAtomicRMWBinOpEnum__LLVMAtomicRMWBinOpMax = internal constant i32 7
@LLVMAtomicRMWBinOpEnum__LLVMAtomicRMWBinOpMin = internal constant i32 8
@LLVMAtomicRMWBinOpEnum__LLVMAtomicRMWBinOpUMax = internal constant i32 9
@LLVMAtomicRMWBinOpEnum__LLVMAtomicRMWBinOpUMin = internal constant i32 10
@LLVMIntPredicateEnum__LLVMIntEQ = internal constant i32 32
@LLVMIntPredicateEnum__LLVMIntNE = internal constant i32 33
@LLVMIntPredicateEnum__LLVMIntUGT = internal constant i32 34
@LLVMIntPredicateEnum__LLVMIntUGE = internal constant i32 35
@LLVMIntPredicateEnum__LLVMIntULT = internal constant i32 36
@LLVMIntPredicateEnum__LLVMIntULE = internal constant i32 37
@LLVMIntPredicateEnum__LLVMIntSGT = internal constant i32 38
@LLVMIntPredicateEnum__LLVMIntSGE = internal constant i32 39
@LLVMIntPredicateEnum__LLVMIntSLT = internal constant i32 40
@LLVMIntPredicateEnum__LLVMIntSLE = internal constant i32 41
@LLVMRealPredicateEnum__LLVMRealPredicateFalse = internal constant i32 0
@LLVMRealPredicateEnum__LLVMRealOEQ = internal constant i32 1
@LLVMRealPredicateEnum__LLVMRealOGT = internal constant i32 2
@LLVMRealPredicateEnum__LLVMRealOGE = internal constant i32 3
@LLVMRealPredicateEnum__LLVMRealOLT = internal constant i32 4
@LLVMRealPredicateEnum__LLVMRealOLE = internal constant i32 5
@LLVMRealPredicateEnum__LLVMRealONE = internal constant i32 6
@LLVMRealPredicateEnum__LLVMRealORD = internal constant i32 7
@LLVMRealPredicateEnum__LLVMRealUNO = internal constant i32 8
@LLVMRealPredicateEnum__LLVMRealUEQ = internal constant i32 9
@LLVMRealPredicateEnum__LLVMRealUGT = internal constant i32 10
@LLVMRealPredicateEnum__LLVMRealUGE = internal constant i32 11
@LLVMRealPredicateEnum__LLVMRealULT = internal constant i32 12
@LLVMRealPredicateEnum__LLVMRealULE = internal constant i32 13
@LLVMRealPredicateEnum__LLVMRealUNE = internal constant i32 14
@LLVMRealPredicateEnum__LLVMRealPredicateTrue = internal constant i32 15
@LLVMLinkageEnum__LLVMExternalLinkage = internal constant i32 0
@LLVMLinkageEnum__LLVMAppendingLinkage = internal constant i32 7
@LLVMLinkageEnum__LLVMInternalLinkage = internal constant i32 8
@LLVMLinkageEnum__LLVMPrivateLinkage = internal constant i32 9
@LLVMCodeGenFileTypeEnum__LLVMAssemblyFile = internal constant i32 0
@LLVMCodeGenFileTypeEnum__LLVMObjectFile = internal constant i32 1
@LLVMVerifierFailureActionEnum__LLVMAbortProcessAction = internal constant i32 0
@LLVMVerifierFailureActionEnum__LLVMPrintMessageAction = internal constant i32 1
@LLVMVerifierFailureActionEnum__LLVMReturnStatusAction = internal constant i32 2
@LLVMCodeGenOptLevelEnum__LLVMCodeGenLevelNone = internal constant i32 0
@LLVMCodeGenOptLevelEnum__LLVMCodeGenLevelLess = internal constant i32 1
@LLVMCodeGenOptLevelEnum__LLVMCodeGenLevelDefault = internal constant i32 2
@LLVMCodeGenOptLevelEnum__LLVMCodeGenLevelAggressive = internal constant i32 3
@LLVMRelocModeEnum__LLVMRelocDefault = internal constant i32 0
@LLVMRelocModeEnum__LLVMRelocStatic = internal constant i32 1
@LLVMRelocModeEnum__LLVMRelocPIC = internal constant i32 2
@LLVMRelocModeEnum__LLVMRelocDynamicNoPic = internal constant i32 3
@LLVMCodeModelEnum__LLVMCodeModelDefault = internal constant i32 0
@LLVMCodeModelEnum__LLVMCodeModelJITDefault = internal constant i32 1
@LLVMCodeModelEnum__LLVMCodeModelSmall = internal constant i32 2
@LLVMCodeModelEnum__LLVMCodeModelMedium = internal constant i32 3
@LLVMCodeModelEnum__LLVMCodeModelLarge = internal constant i32 4
@SysAlloc__vtable__ = constant %__vtable__ zeroinitializer
@str = private unnamed_addr constant [7 x i8] c"(null)\00", align 1
@str.4 = private unnamed_addr constant [9 x i8] c"%s at %d\00", align 1
@__typeinfo___anon2_P_i32 = global %type_info zeroinitializer
@__typeinfo_nm___anon2_P_i32 = constant [14 x i8] c"__anon2_P_i32\00"
@__typeinfo_fn___anon2_P_i32_0 = constant [4 x i8] c"__0\00"
@__typeinfo_fn___anon2_P_i32_1 = constant [4 x i8] c"__1\00"
@__typeinfo_flds___anon2_P_i32 = constant [2 x %type_info_field] [%type_info_field { ptr @__typeinfo_fn___anon2_P_i32_0, i32 0, i32 8, i32 8 }, %type_info_field { ptr @__typeinfo_fn___anon2_P_i32_1, i32 8, i32 4, i32 4 }]
@str.5 = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 1
@__typeinfo___anon1_P = global %type_info zeroinitializer
@__typeinfo_nm___anon1_P = constant [10 x i8] c"__anon1_P\00"
@__typeinfo_fn___anon1_P_0 = constant [4 x i8] c"__0\00"
@__typeinfo_flds___anon1_P = constant [1 x %type_info_field] [%type_info_field { ptr @__typeinfo_fn___anon1_P_0, i32 0, i32 8, i32 8 }]
@str.6 = private unnamed_addr constant [7 x i8] c"plain\0A\00", align 1
@__typeinfo___anon0 = global %type_info zeroinitializer
@__typeinfo_nm___anon0 = constant [8 x i8] c"__anon0\00"
@str.7 = private unnamed_addr constant [2 x i8] c"x\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__artemis_init_typeinfo, ptr null }]

define internal i64 @memstr__NS_default_align(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  ret i64 16
}

define internal { i32, ptr } @memstr__NS_mmap(ptr %0, i64 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %size = alloca i64, align 8
  store i64 %1, ptr %size, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
  %fld_deref = load ptr, ptr %vtable, align 8
  %mmap = getelementptr inbounds nuw %__vtable__, ptr %fld_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %vtable2 = getelementptr inbounds nuw %memstr, ptr %ptr_deref1, i32 0, i32 1
  %fld_deref3 = load ptr, ptr %vtable2, align 8
  %mem_load = load ptr, ptr %mmap, align 8
  %icmp = icmp eq ptr %mem_load, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  store ptr null, ptr @__artemis_error_payload, align 8
  ret { i32, ptr } { i32 1, ptr undef }

if_merge:                                         ; preds = %entry
  %ptr_deref4 = load ptr, ptr %self, align 8
  %vtable5 = getelementptr inbounds nuw %memstr, ptr %ptr_deref4, i32 0, i32 1
  %ptr_deref6 = load ptr, ptr %self, align 8
  %fp_obj = load ptr, ptr %vtable5, align 8
  %fp_field = getelementptr inbounds nuw %__vtable__, ptr %fp_obj, i32 0, i32 0
  %fp_val = load ptr, ptr %fp_field, align 8
  %ptr_deref7 = load ptr, ptr %self, align 8
  %ptr = getelementptr inbounds nuw %memstr, ptr %ptr_deref7, i32 0, i32 0
  %ptr_deref8 = load ptr, ptr %self, align 8
  %mem_load9 = load ptr, ptr %ptr, align 8
  %self_load = load ptr, ptr %self, align 8
  %2 = call i64 @memstr__NS_default_align(ptr %self_load)
  %size10 = load i64, ptr %size, align 8
  %3 = call { i32, ptr } %fp_val(ptr %mem_load9, i64 %2, i64 %size10)
  %try_err_flag = extractvalue { i32, ptr } %3, 0
  %try_val = extractvalue { i32, ptr } %3, 1
  %try_is_err = icmp ne i32 %try_err_flag, 0
  br i1 %try_is_err, label %try_err, label %try_ok

try_err:                                          ; preds = %if_merge
  ret { i32, ptr } { i32 1, ptr undef }

try_ok:                                           ; preds = %if_merge
  %eu_val = insertvalue { i32, ptr } { i32 0, ptr undef }, ptr %try_val, 1
  ret { i32, ptr } %eu_val
}

define internal { i32, ptr } @memstr__NS_mmap_aligned(ptr %0, i64 %1, i64 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %align = alloca i64, align 8
  store i64 %1, ptr %align, align 8
  %size = alloca i64, align 8
  store i64 %2, ptr %size, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
  %fld_deref = load ptr, ptr %vtable, align 8
  %mmap = getelementptr inbounds nuw %__vtable__, ptr %fld_deref, i32 0, i32 0
  %ptr_deref1 = load ptr, ptr %self, align 8
  %vtable2 = getelementptr inbounds nuw %memstr, ptr %ptr_deref1, i32 0, i32 1
  %fld_deref3 = load ptr, ptr %vtable2, align 8
  %mem_load = load ptr, ptr %mmap, align 8
  %icmp = icmp eq ptr %mem_load, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  store ptr null, ptr @__artemis_error_payload, align 8
  ret { i32, ptr } { i32 1, ptr undef }

if_merge:                                         ; preds = %entry
  %ptr_deref4 = load ptr, ptr %self, align 8
  %vtable5 = getelementptr inbounds nuw %memstr, ptr %ptr_deref4, i32 0, i32 1
  %ptr_deref6 = load ptr, ptr %self, align 8
  %fp_obj = load ptr, ptr %vtable5, align 8
  %fp_field = getelementptr inbounds nuw %__vtable__, ptr %fp_obj, i32 0, i32 0
  %fp_val = load ptr, ptr %fp_field, align 8
  %ptr_deref7 = load ptr, ptr %self, align 8
  %ptr = getelementptr inbounds nuw %memstr, ptr %ptr_deref7, i32 0, i32 0
  %ptr_deref8 = load ptr, ptr %self, align 8
  %mem_load9 = load ptr, ptr %ptr, align 8
  %align10 = load i64, ptr %align, align 8
  %size11 = load i64, ptr %size, align 8
  %3 = call { i32, ptr } %fp_val(ptr %mem_load9, i64 %align10, i64 %size11)
  %try_err_flag = extractvalue { i32, ptr } %3, 0
  %try_val = extractvalue { i32, ptr } %3, 1
  %try_is_err = icmp ne i32 %try_err_flag, 0
  br i1 %try_is_err, label %try_err, label %try_ok

try_err:                                          ; preds = %if_merge
  ret { i32, ptr } { i32 1, ptr undef }

try_ok:                                           ; preds = %if_merge
  %eu_val = insertvalue { i32, ptr } { i32 0, ptr undef }, ptr %try_val, 1
  ret { i32, ptr } %eu_val
}

define internal i8 @memstr__NS_rsmap(ptr %0, ptr %1, i65 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %data = alloca ptr, align 8
  store ptr %1, ptr %data, align 8
  %size = alloca i65, align 16
  store i65 %2, ptr %size, align 16
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
  %fld_deref = load ptr, ptr %vtable, align 8
  %rsmap = getelementptr inbounds nuw %__vtable__, ptr %fld_deref, i32 0, i32 1
  %ptr_deref1 = load ptr, ptr %self, align 8
  %vtable2 = getelementptr inbounds nuw %memstr, ptr %ptr_deref1, i32 0, i32 1
  %fld_deref3 = load ptr, ptr %vtable2, align 8
  %mem_load = load ptr, ptr %rsmap, align 8
  %icmp = icmp eq ptr %mem_load, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i8 0

if_merge:                                         ; preds = %entry
  %ptr_deref4 = load ptr, ptr %self, align 8
  %vtable5 = getelementptr inbounds nuw %memstr, ptr %ptr_deref4, i32 0, i32 1
  %ptr_deref6 = load ptr, ptr %self, align 8
  %fp_obj = load ptr, ptr %vtable5, align 8
  %fp_field = getelementptr inbounds nuw %__vtable__, ptr %fp_obj, i32 0, i32 1
  %fp_val = load ptr, ptr %fp_field, align 8
  %ptr_deref7 = load ptr, ptr %self, align 8
  %ptr = getelementptr inbounds nuw %memstr, ptr %ptr_deref7, i32 0, i32 0
  %ptr_deref8 = load ptr, ptr %self, align 8
  %mem_load9 = load ptr, ptr %ptr, align 8
  %data10 = load ptr, ptr %data, align 8
  %size11 = load i65, ptr %size, align 16
  %3 = call i8 %fp_val(ptr %mem_load9, ptr %data10, i65 %size11)
  ret i8 %3
}

define internal { i32, ptr } @memstr__NS_rmap(ptr %0, ptr %1, i65 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %data = alloca ptr, align 8
  store ptr %1, ptr %data, align 8
  %size = alloca i65, align 16
  store i65 %2, ptr %size, align 16
  %self_load = load ptr, ptr %self, align 8
  %data1 = load ptr, ptr %data, align 8
  %size2 = load i65, ptr %size, align 16
  %3 = call i8 @memstr__NS_rsmap(ptr %self_load, ptr %data1, i65 %size2)
  %if_cond = icmp ne i8 %3, 0
  br i1 %if_cond, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %data3 = load ptr, ptr %data, align 8
  %eu_val = insertvalue { i32, ptr } { i32 0, ptr undef }, ptr %data3, 1
  ret { i32, ptr } %eu_val

if_merge:                                         ; preds = %entry
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
  %fld_deref = load ptr, ptr %vtable, align 8
  %rmap = getelementptr inbounds nuw %__vtable__, ptr %fld_deref, i32 0, i32 2
  %ptr_deref4 = load ptr, ptr %self, align 8
  %vtable5 = getelementptr inbounds nuw %memstr, ptr %ptr_deref4, i32 0, i32 1
  %fld_deref6 = load ptr, ptr %vtable5, align 8
  %mem_load = load ptr, ptr %rmap, align 8
  %icmp = icmp eq ptr %mem_load, null
  br i1 %icmp, label %if_then7, label %if_merge8

if_then7:                                         ; preds = %if_merge
  store ptr null, ptr @__artemis_error_payload, align 8
  ret { i32, ptr } { i32 1, ptr undef }

if_merge8:                                        ; preds = %if_merge
  %ptr_deref9 = load ptr, ptr %self, align 8
  %vtable10 = getelementptr inbounds nuw %memstr, ptr %ptr_deref9, i32 0, i32 1
  %ptr_deref11 = load ptr, ptr %self, align 8
  %fp_obj = load ptr, ptr %vtable10, align 8
  %fp_field = getelementptr inbounds nuw %__vtable__, ptr %fp_obj, i32 0, i32 2
  %fp_val = load ptr, ptr %fp_field, align 8
  %ptr_deref12 = load ptr, ptr %self, align 8
  %ptr = getelementptr inbounds nuw %memstr, ptr %ptr_deref12, i32 0, i32 0
  %ptr_deref13 = load ptr, ptr %self, align 8
  %mem_load14 = load ptr, ptr %ptr, align 8
  %self_load15 = load ptr, ptr %self, align 8
  %4 = call i64 @memstr__NS_default_align(ptr %self_load15)
  %data16 = load ptr, ptr %data, align 8
  %size17 = load i65, ptr %size, align 16
  %5 = call { i32, ptr } %fp_val(ptr %mem_load14, i64 %4, ptr %data16, i65 %size17)
  %try_err_flag = extractvalue { i32, ptr } %5, 0
  %try_val = extractvalue { i32, ptr } %5, 1
  %try_is_err = icmp ne i32 %try_err_flag, 0
  br i1 %try_is_err, label %try_err, label %try_ok

try_err:                                          ; preds = %if_merge8
  ret { i32, ptr } { i32 1, ptr undef }

try_ok:                                           ; preds = %if_merge8
  %eu_val18 = insertvalue { i32, ptr } { i32 0, ptr undef }, ptr %try_val, 1
  ret { i32, ptr } %eu_val18
}

define internal i32 @memstr__NS_free(ptr %0, ptr %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %data = alloca ptr, align 8
  store ptr %1, ptr %data, align 8
  %data1 = load ptr, ptr %data, align 8
  %icmp = icmp eq ptr %data1, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 0

if_merge:                                         ; preds = %entry
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
  %fld_deref = load ptr, ptr %vtable, align 8
  %free = getelementptr inbounds nuw %__vtable__, ptr %fld_deref, i32 0, i32 3
  %ptr_deref2 = load ptr, ptr %self, align 8
  %vtable3 = getelementptr inbounds nuw %memstr, ptr %ptr_deref2, i32 0, i32 1
  %fld_deref4 = load ptr, ptr %vtable3, align 8
  %mem_load = load ptr, ptr %free, align 8
  %icmp5 = icmp eq ptr %mem_load, null
  br i1 %icmp5, label %if_then6, label %if_merge7

if_then6:                                         ; preds = %if_merge
  ret i32 0

if_merge7:                                        ; preds = %if_merge
  %ptr_deref8 = load ptr, ptr %self, align 8
  %vtable9 = getelementptr inbounds nuw %memstr, ptr %ptr_deref8, i32 0, i32 1
  %ptr_deref10 = load ptr, ptr %self, align 8
  %fp_obj = load ptr, ptr %vtable9, align 8
  %fp_field = getelementptr inbounds nuw %__vtable__, ptr %fp_obj, i32 0, i32 3
  %fp_val = load ptr, ptr %fp_field, align 8
  %ptr_deref11 = load ptr, ptr %self, align 8
  %ptr = getelementptr inbounds nuw %memstr, ptr %ptr_deref11, i32 0, i32 0
  %ptr_deref12 = load ptr, ptr %self, align 8
  %mem_load13 = load ptr, ptr %ptr, align 8
  %data14 = load ptr, ptr %data, align 8
  %2 = call i32 %fp_val(ptr %mem_load13, ptr %data14)
  %ts_is_err = icmp eq i32 %2, -1
  br i1 %ts_is_err, label %ts_err, label %ts_ok

ts_err:                                           ; preds = %if_merge7
  ret i32 -1

ts_ok:                                            ; preds = %if_merge7
  ret i32 0
}

define internal i32 @memstr__NS_destroy(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %ptr_deref = load ptr, ptr %self, align 8
  %vtable = getelementptr inbounds nuw %memstr, ptr %ptr_deref, i32 0, i32 1
  %fld_deref = load ptr, ptr %vtable, align 8
  %destroy = getelementptr inbounds nuw %__vtable__, ptr %fld_deref, i32 0, i32 4
  %ptr_deref1 = load ptr, ptr %self, align 8
  %vtable2 = getelementptr inbounds nuw %memstr, ptr %ptr_deref1, i32 0, i32 1
  %fld_deref3 = load ptr, ptr %vtable2, align 8
  %mem_load = load ptr, ptr %destroy, align 8
  %icmp = icmp eq ptr %mem_load, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 0

if_merge:                                         ; preds = %entry
  %ptr_deref4 = load ptr, ptr %self, align 8
  %vtable5 = getelementptr inbounds nuw %memstr, ptr %ptr_deref4, i32 0, i32 1
  %ptr_deref6 = load ptr, ptr %self, align 8
  %fp_obj = load ptr, ptr %vtable5, align 8
  %fp_field = getelementptr inbounds nuw %__vtable__, ptr %fp_obj, i32 0, i32 4
  %fp_val = load ptr, ptr %fp_field, align 8
  %ptr_deref7 = load ptr, ptr %self, align 8
  %ptr = getelementptr inbounds nuw %memstr, ptr %ptr_deref7, i32 0, i32 0
  %ptr_deref8 = load ptr, ptr %self, align 8
  %mem_load9 = load ptr, ptr %ptr, align 8
  %1 = call i32 %fp_val(ptr %mem_load9)
  %ts_is_err = icmp eq i32 %1, -1
  br i1 %ts_is_err, label %ts_err, label %ts_ok

ts_err:                                           ; preds = %if_merge
  ret i32 -1

ts_ok:                                            ; preds = %if_merge
  ret i32 0
}

define internal i32 @memstr__NS_deinit(ptr %0) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %self_load = load ptr, ptr %self, align 8
  %1 = call i32 @memstr__NS_destroy(ptr %self_load)
  %ts_is_err = icmp eq i32 %1, -1
  br i1 %ts_is_err, label %ts_err, label %ts_ok

ts_err:                                           ; preds = %entry
  ret i32 -1

ts_ok:                                            ; preds = %entry
  ret i32 0
}

define internal { i32, ptr } @memstr__NS_zeroed(ptr %0, i64 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %size = alloca i64, align 8
  store i64 %1, ptr %size, align 8
  %p = alloca ptr, align 8
  %self_load = load ptr, ptr %self, align 8
  %size1 = load i64, ptr %size, align 8
  %2 = call { i32, ptr } @memstr__NS_mmap(ptr %self_load, i64 %size1)
  %try_err_flag = extractvalue { i32, ptr } %2, 0
  %try_val = extractvalue { i32, ptr } %2, 1
  %try_is_err = icmp ne i32 %try_err_flag, 0
  br i1 %try_is_err, label %try_err, label %try_ok

try_err:                                          ; preds = %entry
  ret { i32, ptr } { i32 1, ptr undef }

try_ok:                                           ; preds = %entry
  store ptr %try_val, ptr %p, align 8
  %b = alloca ptr, align 8
  %p2 = load ptr, ptr %p, align 8
  store ptr %p2, ptr %b, align 8
  %i = alloca i64, align 8
  store i64 0, ptr %i, align 8
  br label %while_cond

while_cond:                                       ; preds = %while_body, %try_ok
  %i3 = load i64, ptr %i, align 8
  %size4 = load i64, ptr %size, align 8
  %icmp = icmp ult i64 %i3, %size4
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i5 = load i64, ptr %i, align 8
  %ptr_load = load ptr, ptr %b, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %i5
  store i8 0, ptr %ptr_gep, align 1
  %i6 = load i64, ptr %i, align 8
  %add = add i64 %i6, 1
  store i64 %add, ptr %i, align 8
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %p7 = load ptr, ptr %p, align 8
  %eu_val = insertvalue { i32, ptr } { i32 0, ptr undef }, ptr %p7, 1
  ret { i32, ptr } %eu_val
}

declare ptr @LLVMContextCreate()

declare void @LLVMContextDispose(ptr)

declare ptr @LLVMModuleCreateWithNameInContext(ptr, ptr)

declare void @LLVMDisposeModule(ptr)

declare ptr @LLVMCreateBuilderInContext(ptr)

declare void @LLVMDisposeBuilder(ptr)

declare void @LLVMSetTarget(ptr, ptr)

declare void @LLVMSetDataLayout(ptr, ptr)

declare ptr @LLVMVoidTypeInContext(ptr)

declare ptr @LLVMInt1TypeInContext(ptr)

declare ptr @LLVMInt8TypeInContext(ptr)

declare ptr @LLVMInt16TypeInContext(ptr)

declare ptr @LLVMInt32TypeInContext(ptr)

declare ptr @LLVMInt64TypeInContext(ptr)

declare ptr @LLVMInt128TypeInContext(ptr)

declare ptr @LLVMIntTypeInContext(ptr, i32)

declare ptr @LLVMHalfTypeInContext(ptr)

declare ptr @LLVMFloatTypeInContext(ptr)

declare ptr @LLVMDoubleTypeInContext(ptr)

declare ptr @LLVMX86FP80TypeInContext(ptr)

declare ptr @LLVMFP128TypeInContext(ptr)

declare ptr @LLVMPointerType(ptr, i32)

declare ptr @LLVMPointerTypeInContext(ptr, i32)

declare ptr @LLVMArrayType(ptr, i32)

declare ptr @LLVMArrayType2(ptr, i64)

declare ptr @LLVMFunctionType(ptr, ptr, i32, i32)

declare ptr @LLVMStructCreateNamed(ptr, ptr)

declare void @LLVMStructSetBody(ptr, ptr, i32, i32)

declare ptr @LLVMStructTypeInContext(ptr, ptr, i32, i32)

declare i32 @LLVMGetTypeKind(ptr)

declare ptr @LLVMGetElementType(ptr)

declare i32 @LLVMGetArrayLength(ptr)

declare i32 @LLVMCountStructElementTypes(ptr)

declare ptr @LLVMGetStructName(ptr)

declare ptr @LLVMGetTypeByName2(ptr, ptr)

declare i32 @LLVMGetIntTypeWidth(ptr)

declare i32 @LLVMCountParamTypes(ptr)

declare void @LLVMGetParamTypes(ptr, ptr)

declare ptr @LLVMConstInt(ptr, i64, i32)

declare ptr @LLVMConstReal(ptr, double)

declare ptr @LLVMConstNull(ptr)

declare ptr @LLVMConstPointerNull(ptr)

declare ptr @LLVMGetUndef(ptr)

declare ptr @LLVMConstString(ptr, i32, i32)

declare ptr @LLVMConstStringInContext(ptr, ptr, i32, i32)

declare ptr @LLVMConstArray(ptr, ptr, i32)

declare ptr @LLVMConstStructInContext(ptr, ptr, i32, i32)

declare ptr @LLVMConstNamedStruct(ptr, ptr, i32)

declare ptr @LLVMConstBitCast(ptr, ptr)

declare ptr @LLVMConstTrunc(ptr, ptr)

declare ptr @LLVMConstAdd(ptr, ptr)

declare ptr @LLVMConstIntOfString(ptr, ptr, i8)

declare ptr @LLVMTypeOf(ptr)

declare i32 @LLVMIsConstant(ptr)

declare i32 @LLVMIsNull(ptr)

declare i32 @LLVMIsUndef(ptr)

declare void @LLVMSetValueName2(ptr, ptr, i64)

declare ptr @LLVMGetValueName2(ptr, ptr)

declare void @LLVMSetLinkage(ptr, i32)

declare void @LLVMSetGlobalConstant(ptr, i32)

declare void @LLVMSetInitializer(ptr, ptr)

declare ptr @LLVMAddGlobal(ptr, ptr, ptr)

declare ptr @LLVMGetNamedGlobal(ptr, ptr)

declare ptr @LLVMGlobalGetValueType(ptr)

declare ptr @LLVMGetInitializer(ptr)

declare ptr @LLVMAddFunction(ptr, ptr, ptr)

declare ptr @LLVMGetNamedFunction(ptr, ptr)

declare ptr @LLVMGetParam(ptr, i32)

declare i32 @LLVMCountParams(ptr)

declare ptr @LLVMGetFirstParam(ptr)

declare ptr @LLVMGetNextParam(ptr)

declare void @LLVMSetFunctionCallConv(ptr, i32)

declare ptr @LLVMAppendBasicBlockInContext(ptr, ptr, ptr)

declare ptr @LLVMAppendBasicBlock(ptr, ptr)

declare void @LLVMPositionBuilderAtEnd(ptr, ptr)

declare void @LLVMPositionBuilderBefore(ptr, ptr)

declare ptr @LLVMGetInsertBlock(ptr)

declare ptr @LLVMGetBasicBlockTerminator(ptr)

declare ptr @LLVMGetFirstBasicBlock(ptr)

declare ptr @LLVMGetLastInstruction(ptr)

declare ptr @LLVMGetBasicBlockParent(ptr)

declare i32 @LLVMGetInstructionOpcode(ptr)

declare ptr @LLVMGetOperand(ptr, i32)

declare void @LLVMMoveBasicBlockAfter(ptr, ptr)

declare ptr @LLVMBuildAdd(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildSub(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildMul(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildUDiv(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildSDiv(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildURem(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildSRem(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildFAdd(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildFSub(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildFMul(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildFDiv(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildFRem(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildNeg(ptr, ptr, ptr)

declare ptr @LLVMBuildFNeg(ptr, ptr, ptr)

declare ptr @LLVMBuildNot(ptr, ptr, ptr)

declare ptr @LLVMBuildAnd(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildOr(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildXor(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildShl(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildLShr(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildAShr(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildICmp(ptr, i32, ptr, ptr, ptr)

declare ptr @LLVMBuildFCmp(ptr, i32, ptr, ptr, ptr)

declare ptr @LLVMBuildAlloca(ptr, ptr, ptr)

declare ptr @LLVMBuildLoad2(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildStore(ptr, ptr, ptr)

declare ptr @LLVMBuildGEP2(ptr, ptr, ptr, ptr, i32, ptr)

declare ptr @LLVMBuildInBoundsGEP2(ptr, ptr, ptr, ptr, i32, ptr)

declare ptr @LLVMBuildStructGEP2(ptr, ptr, ptr, i32, ptr)

declare ptr @LLVMBuildMemSet(ptr, ptr, ptr, ptr, i32)

declare ptr @LLVMBuildMemCpy(ptr, ptr, i32, ptr, i32, ptr)

declare ptr @LLVMBuildBr(ptr, ptr)

declare ptr @LLVMBuildCondBr(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildRet(ptr, ptr)

declare ptr @LLVMBuildRetVoid(ptr)

declare ptr @LLVMBuildUnreachable(ptr)

declare ptr @LLVMBuildCall2(ptr, ptr, ptr, ptr, i32, ptr)

declare ptr @LLVMGetInlineAsm(ptr, ptr, i64, ptr, i64, i32, i32, i32, i32)

declare ptr @LLVMBuildTrunc(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildZExt(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildSExt(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildFPToUI(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildFPToSI(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildUIToFP(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildSIToFP(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildFPTrunc(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildFPExt(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildFPCast(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildBitCast(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildIntToPtr(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildPtrToInt(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildPointerCast(ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildExtractValue(ptr, ptr, i32, ptr)

declare ptr @LLVMBuildInsertValue(ptr, ptr, ptr, i32, ptr)

declare ptr @LLVMBuildFence(ptr, i32, i32, ptr)

declare ptr @LLVMBuildAtomicRMW(ptr, i32, ptr, ptr, i32, i32)

declare ptr @LLVMBuildAtomicCmpXchg(ptr, ptr, ptr, ptr, i32, i32, i32)

declare ptr @LLVMBuildPhi(ptr, ptr, ptr)

declare void @LLVMAddIncoming(ptr, ptr, ptr, i32)

declare ptr @LLVMBuildSelect(ptr, ptr, ptr, ptr, ptr)

declare ptr @LLVMBuildSwitch(ptr, ptr, ptr, i32)

declare void @LLVMAddCase(ptr, ptr, ptr)

declare i32 @LLVMGetTargetFromTriple(ptr, ptr, ptr)

declare ptr @LLVMCreateTargetMachine(ptr, ptr, ptr, ptr, i32, i32, i32)

declare void @LLVMDisposeTargetMachine(ptr)

declare ptr @LLVMGetDefaultTargetTriple()

declare ptr @LLVMGetHostCPUName()

declare ptr @LLVMGetHostCPUFeatures()

declare void @LLVMDisposeMessage(ptr)

declare ptr @LLVMCreateTargetDataLayout(ptr)

declare ptr @LLVMCopyStringRepOfTargetData(ptr)

declare void @LLVMDisposeTargetData(ptr)

declare ptr @LLVMGetModuleDataLayout(ptr)

declare i64 @LLVMOffsetOfElement(ptr, ptr, i32)

declare i64 @LLVMABISizeOfType(ptr, ptr)

declare i32 @LLVMABIAlignmentOfType(ptr, ptr)

declare i32 @LLVMVerifyModule(ptr, i32, ptr)

declare i32 @LLVMTargetMachineEmitToFile(ptr, ptr, ptr, i32, ptr)

declare i32 @LLVMPrintModuleToFile(ptr, ptr, ptr)

declare ptr @LLVMPrintModuleToString(ptr)

declare ptr @LLVMCreatePassBuilderOptions()

declare void @LLVMDisposePassBuilderOptions(ptr)

declare ptr @LLVMRunPasses(ptr, ptr, ptr, ptr)

declare void @LLVMConsumeError(ptr)

declare ptr @LLVMGetErrorMessage(ptr)

declare void @LLVMDisposeErrorMessage(ptr)

declare ptr @LLVMBuildGlobalStringPtr(ptr, ptr, ptr)

declare ptr @LLVMBuildGlobalString(ptr, ptr, ptr)

declare ptr @LLVMSizeOf(ptr)

declare ptr @LLVMAlignOf(ptr)

declare ptr @LLVMStructGetTypeAtIndex(ptr, i32)

declare ptr @LLVMIsAConstant(ptr)

declare ptr @LLVMIsAConstantInt(ptr)

declare i64 @LLVMConstIntGetSExtValue(ptr)

declare i64 @LLVMConstIntGetZExtValue(ptr)

declare ptr @LLVMGetStructElementTypes_get(ptr, i32)

declare void @LLVMFunctionType_get_params(ptr, ptr, i32)

declare ptr @LLVMGetReturnType(ptr)

declare i32 @LLVMGetFunctionCallConv(ptr)

declare void @LLVMSetAlignment(ptr, i32)

declare void @LLVMSetVolatile(ptr, i32)

declare ptr @LLVMGetCalledFunctionType(ptr)

declare ptr @LLVMGetBasicBlocks_first(ptr)

declare ptr @LLVMGetNextBasicBlock(ptr)

declare i32 @LLVMCountBasicBlocks(ptr)

declare void @LLVMInitializeAllTargetInfos_shim()

declare void @LLVMInitializeAllTargets_shim()

declare void @LLVMInitializeAllTargetMCs_shim()

declare void @LLVMInitializeAllAsmPrinters_shim()

declare void @LLVMInitializeAllAsmParsers_shim()

declare ptr @malloc(i64)

declare ptr @realloc(ptr, i64)

declare void @free(ptr)

declare ptr @memset(ptr, i32, i64)

declare ptr @memcpy(ptr, ptr, i64)

declare ptr @memmove(ptr, ptr, i64)

declare i32 @memcmp(ptr, ptr, i64)

declare i32 @strcmp(ptr, ptr)

declare i32 @strncmp(ptr, ptr, i64)

declare i64 @strlen(ptr)

declare ptr @strcpy(ptr, ptr)

declare ptr @strcat(ptr, ptr)

declare ptr @strstr(ptr, ptr)

declare ptr @strchr(ptr, i32)

declare i32 @puts(ptr)

declare i32 @putchar(i32)

declare i32 @atoi(ptr)

declare i64 @atoll(ptr)

declare double @atof(ptr)

declare i64 @strtoll(ptr, ptr, i32)

declare i64 @strtoull(ptr, ptr, i32)

declare double @strtod(ptr, ptr)

declare void @exit(i32)

declare i32 @system(ptr)

declare i32 @remove(ptr)

declare ptr @fopen(ptr, ptr)

declare i32 @fclose(ptr)

declare i64 @fread(ptr, i64, i64, ptr)

declare i64 @fwrite(ptr, i64, i64, ptr)

declare i32 @fseek(ptr, i64, i32)

declare i64 @ftell(ptr)

declare i32 @feof(ptr)

declare i32 @fflush(ptr)

declare ptr @getenv(ptr)

declare i32 @getchar()

declare ptr @fgets(ptr, i32, ptr)

declare ptr @popen(ptr, ptr)

declare i32 @pclose(ptr)

declare ptr @stdout_file()

declare i32 @isalpha(i32)

declare i32 @isdigit(i32)

declare i32 @isalnum(i32)

declare i32 @isspace(i32)

declare i32 @isxdigit(i32)

declare i32 @tolower(i32)

declare i32 @toupper(i32)

declare i32 @GetModuleFileNameA(ptr, ptr, i32)

declare i32 @sprintf(ptr, ptr, ...)

declare i32 @snprintf(ptr, i64, ptr, ...)

declare i32 @printf(ptr, ...)

declare i32 @fprintf(ptr, ptr, ...)

define internal ptr @arc_LLVMContextCreate() {
entry:
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %0 = call ptr @LLVMContextCreate()
  store ptr %0, ptr %r, align 8
  %r1 = load ptr, ptr %r, align 8
  ret ptr %r1
}

define internal void @arc_LLVMContextDispose(ptr %0) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  call void @LLVMContextDispose(ptr %ctx1)
  ret void
}

define internal ptr @arc_LLVMModuleCreateWithNameInContext(ptr %0, ptr %1) {
entry:
  %name = alloca ptr, align 8
  store ptr %0, ptr %name, align 8
  %ctx = alloca ptr, align 8
  store ptr %1, ptr %ctx, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %name1 = load ptr, ptr %name, align 8
  %ctx2 = load ptr, ptr %ctx, align 8
  %2 = call ptr @LLVMModuleCreateWithNameInContext(ptr %name1, ptr %ctx2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal void @arc_LLVMDisposeModule(ptr %0) {
entry:
  %mod = alloca ptr, align 8
  store ptr %0, ptr %mod, align 8
  %mod1 = load ptr, ptr %mod, align 8
  call void @LLVMDisposeModule(ptr %mod1)
  ret void
}

define internal ptr @arc_LLVMCreateBuilderInContext(ptr %0) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %1 = call ptr @LLVMCreateBuilderInContext(ptr %ctx1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal void @arc_LLVMDisposeBuilder(ptr %0) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %b1 = load ptr, ptr %b, align 8
  call void @LLVMDisposeBuilder(ptr %b1)
  ret void
}

define internal void @arc_LLVMSetTarget(ptr %0, ptr %1) {
entry:
  %mod = alloca ptr, align 8
  store ptr %0, ptr %mod, align 8
  %triple = alloca ptr, align 8
  store ptr %1, ptr %triple, align 8
  %mod1 = load ptr, ptr %mod, align 8
  %triple2 = load ptr, ptr %triple, align 8
  call void @LLVMSetTarget(ptr %mod1, ptr %triple2)
  ret void
}

define internal void @arc_LLVMSetDataLayout(ptr %0, ptr %1) {
entry:
  %mod = alloca ptr, align 8
  store ptr %0, ptr %mod, align 8
  %dl = alloca ptr, align 8
  store ptr %1, ptr %dl, align 8
  %mod1 = load ptr, ptr %mod, align 8
  %dl2 = load ptr, ptr %dl, align 8
  call void @LLVMSetDataLayout(ptr %mod1, ptr %dl2)
  ret void
}

define internal ptr @arc_LLVMVoidTypeInContext(ptr %0) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %1 = call ptr @LLVMVoidTypeInContext(ptr %ctx1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMInt1TypeInContext(ptr %0) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %1 = call ptr @LLVMInt1TypeInContext(ptr %ctx1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMInt8TypeInContext(ptr %0) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %1 = call ptr @LLVMInt8TypeInContext(ptr %ctx1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMInt16TypeInContext(ptr %0) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %1 = call ptr @LLVMInt16TypeInContext(ptr %ctx1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMInt32TypeInContext(ptr %0) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %1 = call ptr @LLVMInt32TypeInContext(ptr %ctx1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMInt64TypeInContext(ptr %0) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %1 = call ptr @LLVMInt64TypeInContext(ptr %ctx1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMInt128TypeInContext(ptr %0) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %1 = call ptr @LLVMInt128TypeInContext(ptr %ctx1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMIntTypeInContext(ptr %0, i32 %1) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %bits = alloca i32, align 4
  store i32 %1, ptr %bits, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %bits2 = load i32, ptr %bits, align 4
  %2 = call ptr @LLVMIntTypeInContext(ptr %ctx1, i32 %bits2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_LLVMHalfTypeInContext(ptr %0) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %1 = call ptr @LLVMHalfTypeInContext(ptr %ctx1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMFloatTypeInContext(ptr %0) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %1 = call ptr @LLVMFloatTypeInContext(ptr %ctx1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMDoubleTypeInContext(ptr %0) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %1 = call ptr @LLVMDoubleTypeInContext(ptr %ctx1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMX86FP80TypeInContext(ptr %0) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %1 = call ptr @LLVMX86FP80TypeInContext(ptr %ctx1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMFP128TypeInContext(ptr %0) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %1 = call ptr @LLVMFP128TypeInContext(ptr %ctx1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMPointerType(ptr %0, i32 %1) {
entry:
  %elem = alloca ptr, align 8
  store ptr %0, ptr %elem, align 8
  %addrspace = alloca i32, align 4
  store i32 %1, ptr %addrspace, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %elem1 = load ptr, ptr %elem, align 8
  %addrspace2 = load i32, ptr %addrspace, align 4
  %2 = call ptr @LLVMPointerType(ptr %elem1, i32 %addrspace2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_LLVMPointerTypeInContext(ptr %0, i32 %1) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %addrspace = alloca i32, align 4
  store i32 %1, ptr %addrspace, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %addrspace2 = load i32, ptr %addrspace, align 4
  %2 = call ptr @LLVMPointerTypeInContext(ptr %ctx1, i32 %addrspace2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_LLVMArrayType(ptr %0, i32 %1) {
entry:
  %elem = alloca ptr, align 8
  store ptr %0, ptr %elem, align 8
  %count = alloca i32, align 4
  store i32 %1, ptr %count, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %elem1 = load ptr, ptr %elem, align 8
  %count2 = load i32, ptr %count, align 4
  %2 = call ptr @LLVMArrayType(ptr %elem1, i32 %count2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_LLVMArrayType2(ptr %0, i64 %1) {
entry:
  %elem = alloca ptr, align 8
  store ptr %0, ptr %elem, align 8
  %count = alloca i64, align 8
  store i64 %1, ptr %count, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %elem1 = load ptr, ptr %elem, align 8
  %count2 = load i64, ptr %count, align 8
  %2 = call ptr @LLVMArrayType2(ptr %elem1, i64 %count2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_LLVMFunctionType(ptr %0, ptr %1, i32 %2, i32 %3) {
entry:
  %ret = alloca ptr, align 8
  store ptr %0, ptr %ret, align 8
  %params = alloca ptr, align 8
  store ptr %1, ptr %params, align 8
  %nparams = alloca i32, align 4
  store i32 %2, ptr %nparams, align 4
  %variadic = alloca i32, align 4
  store i32 %3, ptr %variadic, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ret1 = load ptr, ptr %ret, align 8
  %params2 = load ptr, ptr %params, align 8
  %nparams3 = load i32, ptr %nparams, align 4
  %variadic4 = load i32, ptr %variadic, align 4
  %4 = call ptr @LLVMFunctionType(ptr %ret1, ptr %params2, i32 %nparams3, i32 %variadic4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMStructCreateNamed(ptr %0, ptr %1) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %name2 = load ptr, ptr %name, align 8
  %2 = call ptr @LLVMStructCreateNamed(ptr %ctx1, ptr %name2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal void @arc_LLVMStructSetBody(ptr %0, ptr %1, i32 %2, i32 %3) {
entry:
  %stype = alloca ptr, align 8
  store ptr %0, ptr %stype, align 8
  %fields = alloca ptr, align 8
  store ptr %1, ptr %fields, align 8
  %nfields = alloca i32, align 4
  store i32 %2, ptr %nfields, align 4
  %packed = alloca i32, align 4
  store i32 %3, ptr %packed, align 4
  %stype1 = load ptr, ptr %stype, align 8
  %fields2 = load ptr, ptr %fields, align 8
  %nfields3 = load i32, ptr %nfields, align 4
  %packed4 = load i32, ptr %packed, align 4
  call void @LLVMStructSetBody(ptr %stype1, ptr %fields2, i32 %nfields3, i32 %packed4)
  ret void
}

define internal ptr @arc_LLVMStructTypeInContext(ptr %0, ptr %1, i32 %2, i32 %3) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %fields = alloca ptr, align 8
  store ptr %1, ptr %fields, align 8
  %nfields = alloca i32, align 4
  store i32 %2, ptr %nfields, align 4
  %packed = alloca i32, align 4
  store i32 %3, ptr %packed, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %fields2 = load ptr, ptr %fields, align 8
  %nfields3 = load i32, ptr %nfields, align 4
  %packed4 = load i32, ptr %packed, align 4
  %4 = call ptr @LLVMStructTypeInContext(ptr %ctx1, ptr %fields2, i32 %nfields3, i32 %packed4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal i32 @arc_LLVMGetTypeKind(ptr %0) {
entry:
  %ty = alloca ptr, align 8
  store ptr %0, ptr %ty, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %ty1 = load ptr, ptr %ty, align 8
  %1 = call i32 @LLVMGetTypeKind(ptr %ty1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal ptr @arc_LLVMGetElementType(ptr %0) {
entry:
  %ty = alloca ptr, align 8
  store ptr %0, ptr %ty, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ty1 = load ptr, ptr %ty, align 8
  %1 = call ptr @LLVMGetElementType(ptr %ty1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal i32 @arc_LLVMGetArrayLength(ptr %0) {
entry:
  %ty = alloca ptr, align 8
  store ptr %0, ptr %ty, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %ty1 = load ptr, ptr %ty, align 8
  %1 = call i32 @LLVMGetArrayLength(ptr %ty1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i32 @arc_LLVMCountStructElementTypes(ptr %0) {
entry:
  %ty = alloca ptr, align 8
  store ptr %0, ptr %ty, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %ty1 = load ptr, ptr %ty, align 8
  %1 = call i32 @LLVMCountStructElementTypes(ptr %ty1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal ptr @arc_LLVMGetStructName(ptr %0) {
entry:
  %ty = alloca ptr, align 8
  store ptr %0, ptr %ty, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ty1 = load ptr, ptr %ty, align 8
  %1 = call ptr @LLVMGetStructName(ptr %ty1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMGetTypeByName2(ptr %0, ptr %1) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %name2 = load ptr, ptr %name, align 8
  %2 = call ptr @LLVMGetTypeByName2(ptr %ctx1, ptr %name2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal i32 @arc_LLVMGetIntTypeWidth(ptr %0) {
entry:
  %ty = alloca ptr, align 8
  store ptr %0, ptr %ty, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %ty1 = load ptr, ptr %ty, align 8
  %1 = call i32 @LLVMGetIntTypeWidth(ptr %ty1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i32 @arc_LLVMCountParamTypes(ptr %0) {
entry:
  %fnty = alloca ptr, align 8
  store ptr %0, ptr %fnty, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %fnty1 = load ptr, ptr %fnty, align 8
  %1 = call i32 @LLVMCountParamTypes(ptr %fnty1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal void @arc_LLVMGetParamTypes(ptr %0, ptr %1) {
entry:
  %fnty = alloca ptr, align 8
  store ptr %0, ptr %fnty, align 8
  %dest = alloca ptr, align 8
  store ptr %1, ptr %dest, align 8
  %fnty1 = load ptr, ptr %fnty, align 8
  %dest2 = load ptr, ptr %dest, align 8
  call void @LLVMGetParamTypes(ptr %fnty1, ptr %dest2)
  ret void
}

define internal ptr @arc_LLVMConstInt(ptr %0, i64 %1, i32 %2) {
entry:
  %ty = alloca ptr, align 8
  store ptr %0, ptr %ty, align 8
  %val = alloca i64, align 8
  store i64 %1, ptr %val, align 8
  %sign_extend = alloca i32, align 4
  store i32 %2, ptr %sign_extend, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ty1 = load ptr, ptr %ty, align 8
  %val2 = load i64, ptr %val, align 8
  %sign_extend3 = load i32, ptr %sign_extend, align 4
  %3 = call ptr @LLVMConstInt(ptr %ty1, i64 %val2, i32 %sign_extend3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_LLVMConstReal(ptr %0, double %1) {
entry:
  %ty = alloca ptr, align 8
  store ptr %0, ptr %ty, align 8
  %val = alloca double, align 8
  store double %1, ptr %val, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ty1 = load ptr, ptr %ty, align 8
  %val2 = load double, ptr %val, align 8
  %2 = call ptr @LLVMConstReal(ptr %ty1, double %val2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_LLVMConstNull(ptr %0) {
entry:
  %ty = alloca ptr, align 8
  store ptr %0, ptr %ty, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ty1 = load ptr, ptr %ty, align 8
  %1 = call ptr @LLVMConstNull(ptr %ty1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMConstPointerNull(ptr %0) {
entry:
  %ty = alloca ptr, align 8
  store ptr %0, ptr %ty, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ty1 = load ptr, ptr %ty, align 8
  %1 = call ptr @LLVMConstPointerNull(ptr %ty1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMGetUndef(ptr %0) {
entry:
  %ty = alloca ptr, align 8
  store ptr %0, ptr %ty, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ty1 = load ptr, ptr %ty, align 8
  %1 = call ptr @LLVMGetUndef(ptr %ty1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMConstString(ptr %0, i32 %1, i32 %2) {
entry:
  %str = alloca ptr, align 8
  store ptr %0, ptr %str, align 8
  %length = alloca i32, align 4
  store i32 %1, ptr %length, align 4
  %dont_null_terminate = alloca i32, align 4
  store i32 %2, ptr %dont_null_terminate, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %str1 = load ptr, ptr %str, align 8
  %length2 = load i32, ptr %length, align 4
  %dont_null_terminate3 = load i32, ptr %dont_null_terminate, align 4
  %3 = call ptr @LLVMConstString(ptr %str1, i32 %length2, i32 %dont_null_terminate3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_LLVMConstStringInContext(ptr %0, ptr %1, i32 %2, i32 %3) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %str = alloca ptr, align 8
  store ptr %1, ptr %str, align 8
  %length = alloca i32, align 4
  store i32 %2, ptr %length, align 4
  %dont_null_terminate = alloca i32, align 4
  store i32 %3, ptr %dont_null_terminate, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %str2 = load ptr, ptr %str, align 8
  %length3 = load i32, ptr %length, align 4
  %dont_null_terminate4 = load i32, ptr %dont_null_terminate, align 4
  %4 = call ptr @LLVMConstStringInContext(ptr %ctx1, ptr %str2, i32 %length3, i32 %dont_null_terminate4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMConstArray(ptr %0, ptr %1, i32 %2) {
entry:
  %elem_ty = alloca ptr, align 8
  store ptr %0, ptr %elem_ty, align 8
  %vals = alloca ptr, align 8
  store ptr %1, ptr %vals, align 8
  %nvals = alloca i32, align 4
  store i32 %2, ptr %nvals, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %elem_ty1 = load ptr, ptr %elem_ty, align 8
  %vals2 = load ptr, ptr %vals, align 8
  %nvals3 = load i32, ptr %nvals, align 4
  %3 = call ptr @LLVMConstArray(ptr %elem_ty1, ptr %vals2, i32 %nvals3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_LLVMConstStructInContext(ptr %0, ptr %1, i32 %2, i32 %3) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %vals = alloca ptr, align 8
  store ptr %1, ptr %vals, align 8
  %nvals = alloca i32, align 4
  store i32 %2, ptr %nvals, align 4
  %packed = alloca i32, align 4
  store i32 %3, ptr %packed, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %vals2 = load ptr, ptr %vals, align 8
  %nvals3 = load i32, ptr %nvals, align 4
  %packed4 = load i32, ptr %packed, align 4
  %4 = call ptr @LLVMConstStructInContext(ptr %ctx1, ptr %vals2, i32 %nvals3, i32 %packed4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMConstNamedStruct(ptr %0, ptr %1, i32 %2) {
entry:
  %sty = alloca ptr, align 8
  store ptr %0, ptr %sty, align 8
  %vals = alloca ptr, align 8
  store ptr %1, ptr %vals, align 8
  %nvals = alloca i32, align 4
  store i32 %2, ptr %nvals, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %sty1 = load ptr, ptr %sty, align 8
  %vals2 = load ptr, ptr %vals, align 8
  %nvals3 = load i32, ptr %nvals, align 4
  %3 = call ptr @LLVMConstNamedStruct(ptr %sty1, ptr %vals2, i32 %nvals3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_LLVMConstBitCast(ptr %0, ptr %1) {
entry:
  %val = alloca ptr, align 8
  store ptr %0, ptr %val, align 8
  %ty = alloca ptr, align 8
  store ptr %1, ptr %ty, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %val1 = load ptr, ptr %val, align 8
  %ty2 = load ptr, ptr %ty, align 8
  %2 = call ptr @LLVMConstBitCast(ptr %val1, ptr %ty2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_LLVMConstTrunc(ptr %0, ptr %1) {
entry:
  %val = alloca ptr, align 8
  store ptr %0, ptr %val, align 8
  %to_type = alloca ptr, align 8
  store ptr %1, ptr %to_type, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %val1 = load ptr, ptr %val, align 8
  %to_type2 = load ptr, ptr %to_type, align 8
  %2 = call ptr @LLVMConstTrunc(ptr %val1, ptr %to_type2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_LLVMConstAdd(ptr %0, ptr %1) {
entry:
  %lhs = alloca ptr, align 8
  store ptr %0, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %1, ptr %rhs, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %lhs1 = load ptr, ptr %lhs, align 8
  %rhs2 = load ptr, ptr %rhs, align 8
  %2 = call ptr @LLVMConstAdd(ptr %lhs1, ptr %rhs2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_LLVMConstIntOfString(ptr %0, ptr %1, i8 %2) {
entry:
  %ty = alloca ptr, align 8
  store ptr %0, ptr %ty, align 8
  %text = alloca ptr, align 8
  store ptr %1, ptr %text, align 8
  %radix = alloca i8, align 1
  store i8 %2, ptr %radix, align 1
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ty1 = load ptr, ptr %ty, align 8
  %text2 = load ptr, ptr %text, align 8
  %radix3 = load i8, ptr %radix, align 1
  %3 = call ptr @LLVMConstIntOfString(ptr %ty1, ptr %text2, i8 %radix3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_LLVMTypeOf(ptr %0) {
entry:
  %val = alloca ptr, align 8
  store ptr %0, ptr %val, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %val1 = load ptr, ptr %val, align 8
  %1 = call ptr @LLVMTypeOf(ptr %val1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal i32 @arc_LLVMIsConstant(ptr %0) {
entry:
  %val = alloca ptr, align 8
  store ptr %0, ptr %val, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %val1 = load ptr, ptr %val, align 8
  %1 = call i32 @LLVMIsConstant(ptr %val1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i32 @arc_LLVMIsNull(ptr %0) {
entry:
  %val = alloca ptr, align 8
  store ptr %0, ptr %val, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %val1 = load ptr, ptr %val, align 8
  %1 = call i32 @LLVMIsNull(ptr %val1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i32 @arc_LLVMIsUndef(ptr %0) {
entry:
  %val = alloca ptr, align 8
  store ptr %0, ptr %val, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %val1 = load ptr, ptr %val, align 8
  %1 = call i32 @LLVMIsUndef(ptr %val1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal void @arc_LLVMSetValueName2(ptr %0, ptr %1, i64 %2) {
entry:
  %val = alloca ptr, align 8
  store ptr %0, ptr %val, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %len = alloca i64, align 8
  store i64 %2, ptr %len, align 8
  %val1 = load ptr, ptr %val, align 8
  %name2 = load ptr, ptr %name, align 8
  %len3 = load i64, ptr %len, align 8
  call void @LLVMSetValueName2(ptr %val1, ptr %name2, i64 %len3)
  ret void
}

define internal ptr @arc_LLVMGetValueName2(ptr %0, ptr %1) {
entry:
  %val = alloca ptr, align 8
  store ptr %0, ptr %val, align 8
  %len = alloca ptr, align 8
  store ptr %1, ptr %len, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %val1 = load ptr, ptr %val, align 8
  %len2 = load ptr, ptr %len, align 8
  %2 = call ptr @LLVMGetValueName2(ptr %val1, ptr %len2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal void @arc_LLVMSetLinkage(ptr %0, i32 %1) {
entry:
  %val = alloca ptr, align 8
  store ptr %0, ptr %val, align 8
  %linkage = alloca i32, align 4
  store i32 %1, ptr %linkage, align 4
  %val1 = load ptr, ptr %val, align 8
  %linkage2 = load i32, ptr %linkage, align 4
  call void @LLVMSetLinkage(ptr %val1, i32 %linkage2)
  ret void
}

define internal void @arc_LLVMSetGlobalConstant(ptr %0, i32 %1) {
entry:
  %gv = alloca ptr, align 8
  store ptr %0, ptr %gv, align 8
  %is_constant = alloca i32, align 4
  store i32 %1, ptr %is_constant, align 4
  %gv1 = load ptr, ptr %gv, align 8
  %is_constant2 = load i32, ptr %is_constant, align 4
  call void @LLVMSetGlobalConstant(ptr %gv1, i32 %is_constant2)
  ret void
}

define internal void @arc_LLVMSetInitializer(ptr %0, ptr %1) {
entry:
  %gv = alloca ptr, align 8
  store ptr %0, ptr %gv, align 8
  %init = alloca ptr, align 8
  store ptr %1, ptr %init, align 8
  %gv1 = load ptr, ptr %gv, align 8
  %init2 = load ptr, ptr %init, align 8
  call void @LLVMSetInitializer(ptr %gv1, ptr %init2)
  ret void
}

define internal ptr @arc_LLVMAddGlobal(ptr %0, ptr %1, ptr %2) {
entry:
  %mod = alloca ptr, align 8
  store ptr %0, ptr %mod, align 8
  %ty = alloca ptr, align 8
  store ptr %1, ptr %ty, align 8
  %name = alloca ptr, align 8
  store ptr %2, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %mod1 = load ptr, ptr %mod, align 8
  %ty2 = load ptr, ptr %ty, align 8
  %name3 = load ptr, ptr %name, align 8
  %3 = call ptr @LLVMAddGlobal(ptr %mod1, ptr %ty2, ptr %name3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_LLVMGetNamedGlobal(ptr %0, ptr %1) {
entry:
  %mod = alloca ptr, align 8
  store ptr %0, ptr %mod, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %mod1 = load ptr, ptr %mod, align 8
  %name2 = load ptr, ptr %name, align 8
  %2 = call ptr @LLVMGetNamedGlobal(ptr %mod1, ptr %name2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_LLVMGlobalGetValueType(ptr %0) {
entry:
  %gv = alloca ptr, align 8
  store ptr %0, ptr %gv, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %gv1 = load ptr, ptr %gv, align 8
  %1 = call ptr @LLVMGlobalGetValueType(ptr %gv1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMGetInitializer(ptr %0) {
entry:
  %gv = alloca ptr, align 8
  store ptr %0, ptr %gv, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %gv1 = load ptr, ptr %gv, align 8
  %1 = call ptr @LLVMGetInitializer(ptr %gv1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMAddFunction(ptr %0, ptr %1, ptr %2) {
entry:
  %mod = alloca ptr, align 8
  store ptr %0, ptr %mod, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %fn_ty = alloca ptr, align 8
  store ptr %2, ptr %fn_ty, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %mod1 = load ptr, ptr %mod, align 8
  %name2 = load ptr, ptr %name, align 8
  %fn_ty3 = load ptr, ptr %fn_ty, align 8
  %3 = call ptr @LLVMAddFunction(ptr %mod1, ptr %name2, ptr %fn_ty3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_LLVMGetNamedFunction(ptr %0, ptr %1) {
entry:
  %mod = alloca ptr, align 8
  store ptr %0, ptr %mod, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %mod1 = load ptr, ptr %mod, align 8
  %name2 = load ptr, ptr %name, align 8
  %2 = call ptr @LLVMGetNamedFunction(ptr %mod1, ptr %name2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_LLVMGetParam(ptr %0, i32 %1) {
entry:
  %fn_ref = alloca ptr, align 8
  store ptr %0, ptr %fn_ref, align 8
  %idx = alloca i32, align 4
  store i32 %1, ptr %idx, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %fn_ref1 = load ptr, ptr %fn_ref, align 8
  %idx2 = load i32, ptr %idx, align 4
  %2 = call ptr @LLVMGetParam(ptr %fn_ref1, i32 %idx2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal i32 @arc_LLVMCountParams(ptr %0) {
entry:
  %fn_ref = alloca ptr, align 8
  store ptr %0, ptr %fn_ref, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %fn_ref1 = load ptr, ptr %fn_ref, align 8
  %1 = call i32 @LLVMCountParams(ptr %fn_ref1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal ptr @arc_LLVMGetFirstParam(ptr %0) {
entry:
  %fn_ref = alloca ptr, align 8
  store ptr %0, ptr %fn_ref, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %fn_ref1 = load ptr, ptr %fn_ref, align 8
  %1 = call ptr @LLVMGetFirstParam(ptr %fn_ref1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMGetNextParam(ptr %0) {
entry:
  %param = alloca ptr, align 8
  store ptr %0, ptr %param, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %param1 = load ptr, ptr %param, align 8
  %1 = call ptr @LLVMGetNextParam(ptr %param1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal void @arc_LLVMSetFunctionCallConv(ptr %0, i32 %1) {
entry:
  %fn_ref = alloca ptr, align 8
  store ptr %0, ptr %fn_ref, align 8
  %cc = alloca i32, align 4
  store i32 %1, ptr %cc, align 4
  %fn_ref1 = load ptr, ptr %fn_ref, align 8
  %cc2 = load i32, ptr %cc, align 4
  call void @LLVMSetFunctionCallConv(ptr %fn_ref1, i32 %cc2)
  ret void
}

define internal ptr @arc_LLVMAppendBasicBlockInContext(ptr %0, ptr %1, ptr %2) {
entry:
  %ctx = alloca ptr, align 8
  store ptr %0, ptr %ctx, align 8
  %fn_ref = alloca ptr, align 8
  store ptr %1, ptr %fn_ref, align 8
  %name = alloca ptr, align 8
  store ptr %2, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ctx1 = load ptr, ptr %ctx, align 8
  %fn_ref2 = load ptr, ptr %fn_ref, align 8
  %name3 = load ptr, ptr %name, align 8
  %3 = call ptr @LLVMAppendBasicBlockInContext(ptr %ctx1, ptr %fn_ref2, ptr %name3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_LLVMAppendBasicBlock(ptr %0, ptr %1) {
entry:
  %fn_ref = alloca ptr, align 8
  store ptr %0, ptr %fn_ref, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %fn_ref1 = load ptr, ptr %fn_ref, align 8
  %name2 = load ptr, ptr %name, align 8
  %2 = call ptr @LLVMAppendBasicBlock(ptr %fn_ref1, ptr %name2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal void @arc_LLVMPositionBuilderAtEnd(ptr %0, ptr %1) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %bb = alloca ptr, align 8
  store ptr %1, ptr %bb, align 8
  %b1 = load ptr, ptr %b, align 8
  %bb2 = load ptr, ptr %bb, align 8
  call void @LLVMPositionBuilderAtEnd(ptr %b1, ptr %bb2)
  ret void
}

define internal void @arc_LLVMPositionBuilderBefore(ptr %0, ptr %1) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %inst = alloca ptr, align 8
  store ptr %1, ptr %inst, align 8
  %b1 = load ptr, ptr %b, align 8
  %inst2 = load ptr, ptr %inst, align 8
  call void @LLVMPositionBuilderBefore(ptr %b1, ptr %inst2)
  ret void
}

define internal ptr @arc_LLVMGetInsertBlock(ptr %0) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %1 = call ptr @LLVMGetInsertBlock(ptr %b1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMGetBasicBlockTerminator(ptr %0) {
entry:
  %bb = alloca ptr, align 8
  store ptr %0, ptr %bb, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %bb1 = load ptr, ptr %bb, align 8
  %1 = call ptr @LLVMGetBasicBlockTerminator(ptr %bb1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMGetFirstBasicBlock(ptr %0) {
entry:
  %fn_ref = alloca ptr, align 8
  store ptr %0, ptr %fn_ref, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %fn_ref1 = load ptr, ptr %fn_ref, align 8
  %1 = call ptr @LLVMGetFirstBasicBlock(ptr %fn_ref1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMGetLastInstruction(ptr %0) {
entry:
  %bb = alloca ptr, align 8
  store ptr %0, ptr %bb, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %bb1 = load ptr, ptr %bb, align 8
  %1 = call ptr @LLVMGetLastInstruction(ptr %bb1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMGetBasicBlockParent(ptr %0) {
entry:
  %bb = alloca ptr, align 8
  store ptr %0, ptr %bb, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %bb1 = load ptr, ptr %bb, align 8
  %1 = call ptr @LLVMGetBasicBlockParent(ptr %bb1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal i32 @arc_LLVMGetInstructionOpcode(ptr %0) {
entry:
  %inst = alloca ptr, align 8
  store ptr %0, ptr %inst, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %inst1 = load ptr, ptr %inst, align 8
  %1 = call i32 @LLVMGetInstructionOpcode(ptr %inst1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal ptr @arc_LLVMGetOperand(ptr %0, i32 %1) {
entry:
  %val = alloca ptr, align 8
  store ptr %0, ptr %val, align 8
  %index = alloca i32, align 4
  store i32 %1, ptr %index, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %val1 = load ptr, ptr %val, align 8
  %index2 = load i32, ptr %index, align 4
  %2 = call ptr @LLVMGetOperand(ptr %val1, i32 %index2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal void @arc_LLVMMoveBasicBlockAfter(ptr %0, ptr %1) {
entry:
  %bb = alloca ptr, align 8
  store ptr %0, ptr %bb, align 8
  %move_after = alloca ptr, align 8
  store ptr %1, ptr %move_after, align 8
  %bb1 = load ptr, ptr %bb, align 8
  %move_after2 = load ptr, ptr %move_after, align 8
  call void @LLVMMoveBasicBlockAfter(ptr %bb1, ptr %move_after2)
  ret void
}

define internal ptr @arc_LLVMBuildAdd(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildAdd(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildSub(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildSub(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildMul(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildMul(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildUDiv(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildUDiv(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildSDiv(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildSDiv(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildURem(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildURem(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildSRem(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildSRem(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildFAdd(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildFAdd(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildFSub(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildFSub(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildFMul(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildFMul(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildFDiv(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildFDiv(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildFRem(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildFRem(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildNeg(ptr %0, ptr %1, ptr %2) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %name = alloca ptr, align 8
  store ptr %2, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %name3 = load ptr, ptr %name, align 8
  %3 = call ptr @LLVMBuildNeg(ptr %b1, ptr %val2, ptr %name3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_LLVMBuildFNeg(ptr %0, ptr %1, ptr %2) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %name = alloca ptr, align 8
  store ptr %2, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %name3 = load ptr, ptr %name, align 8
  %3 = call ptr @LLVMBuildFNeg(ptr %b1, ptr %val2, ptr %name3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_LLVMBuildNot(ptr %0, ptr %1, ptr %2) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %name = alloca ptr, align 8
  store ptr %2, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %name3 = load ptr, ptr %name, align 8
  %3 = call ptr @LLVMBuildNot(ptr %b1, ptr %val2, ptr %name3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_LLVMBuildAnd(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildAnd(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildOr(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildOr(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildXor(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildXor(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildShl(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildShl(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildLShr(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildLShr(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildAShr(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %lhs = alloca ptr, align 8
  store ptr %1, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %2, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %lhs2 = load ptr, ptr %lhs, align 8
  %rhs3 = load ptr, ptr %rhs, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildAShr(ptr %b1, ptr %lhs2, ptr %rhs3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildICmp(ptr %0, i32 %1, ptr %2, ptr %3, ptr %4) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %pred = alloca i32, align 4
  store i32 %1, ptr %pred, align 4
  %lhs = alloca ptr, align 8
  store ptr %2, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %3, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %4, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %pred2 = load i32, ptr %pred, align 4
  %lhs3 = load ptr, ptr %lhs, align 8
  %rhs4 = load ptr, ptr %rhs, align 8
  %name5 = load ptr, ptr %name, align 8
  %5 = call ptr @LLVMBuildICmp(ptr %b1, i32 %pred2, ptr %lhs3, ptr %rhs4, ptr %name5)
  store ptr %5, ptr %r, align 8
  %r6 = load ptr, ptr %r, align 8
  ret ptr %r6
}

define internal ptr @arc_LLVMBuildFCmp(ptr %0, i32 %1, ptr %2, ptr %3, ptr %4) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %pred = alloca i32, align 4
  store i32 %1, ptr %pred, align 4
  %lhs = alloca ptr, align 8
  store ptr %2, ptr %lhs, align 8
  %rhs = alloca ptr, align 8
  store ptr %3, ptr %rhs, align 8
  %name = alloca ptr, align 8
  store ptr %4, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %pred2 = load i32, ptr %pred, align 4
  %lhs3 = load ptr, ptr %lhs, align 8
  %rhs4 = load ptr, ptr %rhs, align 8
  %name5 = load ptr, ptr %name, align 8
  %5 = call ptr @LLVMBuildFCmp(ptr %b1, i32 %pred2, ptr %lhs3, ptr %rhs4, ptr %name5)
  store ptr %5, ptr %r, align 8
  %r6 = load ptr, ptr %r, align 8
  ret ptr %r6
}

define internal ptr @arc_LLVMBuildAlloca(ptr %0, ptr %1, ptr %2) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %ty = alloca ptr, align 8
  store ptr %1, ptr %ty, align 8
  %name = alloca ptr, align 8
  store ptr %2, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %ty2 = load ptr, ptr %ty, align 8
  %name3 = load ptr, ptr %name, align 8
  %3 = call ptr @LLVMBuildAlloca(ptr %b1, ptr %ty2, ptr %name3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_LLVMBuildLoad2(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %ty = alloca ptr, align 8
  store ptr %1, ptr %ty, align 8
  %ptr = alloca ptr, align 8
  store ptr %2, ptr %ptr, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %ty2 = load ptr, ptr %ty, align 8
  %ptr3 = load ptr, ptr %ptr, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildLoad2(ptr %b1, ptr %ty2, ptr %ptr3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildStore(ptr %0, ptr %1, ptr %2) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %ptr = alloca ptr, align 8
  store ptr %2, ptr %ptr, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %ptr3 = load ptr, ptr %ptr, align 8
  %3 = call ptr @LLVMBuildStore(ptr %b1, ptr %val2, ptr %ptr3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_LLVMBuildGEP2(ptr %0, ptr %1, ptr %2, ptr %3, i32 %4, ptr %5) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %ty = alloca ptr, align 8
  store ptr %1, ptr %ty, align 8
  %ptr = alloca ptr, align 8
  store ptr %2, ptr %ptr, align 8
  %indices = alloca ptr, align 8
  store ptr %3, ptr %indices, align 8
  %nidx = alloca i32, align 4
  store i32 %4, ptr %nidx, align 4
  %name = alloca ptr, align 8
  store ptr %5, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %ty2 = load ptr, ptr %ty, align 8
  %ptr3 = load ptr, ptr %ptr, align 8
  %indices4 = load ptr, ptr %indices, align 8
  %nidx5 = load i32, ptr %nidx, align 4
  %name6 = load ptr, ptr %name, align 8
  %6 = call ptr @LLVMBuildGEP2(ptr %b1, ptr %ty2, ptr %ptr3, ptr %indices4, i32 %nidx5, ptr %name6)
  store ptr %6, ptr %r, align 8
  %r7 = load ptr, ptr %r, align 8
  ret ptr %r7
}

define internal ptr @arc_LLVMBuildInBoundsGEP2(ptr %0, ptr %1, ptr %2, ptr %3, i32 %4, ptr %5) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %ty = alloca ptr, align 8
  store ptr %1, ptr %ty, align 8
  %ptr = alloca ptr, align 8
  store ptr %2, ptr %ptr, align 8
  %indices = alloca ptr, align 8
  store ptr %3, ptr %indices, align 8
  %nidx = alloca i32, align 4
  store i32 %4, ptr %nidx, align 4
  %name = alloca ptr, align 8
  store ptr %5, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %ty2 = load ptr, ptr %ty, align 8
  %ptr3 = load ptr, ptr %ptr, align 8
  %indices4 = load ptr, ptr %indices, align 8
  %nidx5 = load i32, ptr %nidx, align 4
  %name6 = load ptr, ptr %name, align 8
  %6 = call ptr @LLVMBuildInBoundsGEP2(ptr %b1, ptr %ty2, ptr %ptr3, ptr %indices4, i32 %nidx5, ptr %name6)
  store ptr %6, ptr %r, align 8
  %r7 = load ptr, ptr %r, align 8
  ret ptr %r7
}

define internal ptr @arc_LLVMBuildStructGEP2(ptr %0, ptr %1, ptr %2, i32 %3, ptr %4) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %ty = alloca ptr, align 8
  store ptr %1, ptr %ty, align 8
  %ptr = alloca ptr, align 8
  store ptr %2, ptr %ptr, align 8
  %idx = alloca i32, align 4
  store i32 %3, ptr %idx, align 4
  %name = alloca ptr, align 8
  store ptr %4, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %ty2 = load ptr, ptr %ty, align 8
  %ptr3 = load ptr, ptr %ptr, align 8
  %idx4 = load i32, ptr %idx, align 4
  %name5 = load ptr, ptr %name, align 8
  %5 = call ptr @LLVMBuildStructGEP2(ptr %b1, ptr %ty2, ptr %ptr3, i32 %idx4, ptr %name5)
  store ptr %5, ptr %r, align 8
  %r6 = load ptr, ptr %r, align 8
  ret ptr %r6
}

define internal ptr @arc_LLVMBuildMemSet(ptr %0, ptr %1, ptr %2, ptr %3, i32 %4) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %ptr = alloca ptr, align 8
  store ptr %1, ptr %ptr, align 8
  %val = alloca ptr, align 8
  store ptr %2, ptr %val, align 8
  %len = alloca ptr, align 8
  store ptr %3, ptr %len, align 8
  %align = alloca i32, align 4
  store i32 %4, ptr %align, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %ptr2 = load ptr, ptr %ptr, align 8
  %val3 = load ptr, ptr %val, align 8
  %len4 = load ptr, ptr %len, align 8
  %align5 = load i32, ptr %align, align 4
  %5 = call ptr @LLVMBuildMemSet(ptr %b1, ptr %ptr2, ptr %val3, ptr %len4, i32 %align5)
  store ptr %5, ptr %r, align 8
  %r6 = load ptr, ptr %r, align 8
  ret ptr %r6
}

define internal ptr @arc_LLVMBuildMemCpy(ptr %0, ptr %1, i32 %2, ptr %3, i32 %4, ptr %5) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %dst = alloca ptr, align 8
  store ptr %1, ptr %dst, align 8
  %dst_align = alloca i32, align 4
  store i32 %2, ptr %dst_align, align 4
  %src = alloca ptr, align 8
  store ptr %3, ptr %src, align 8
  %src_align = alloca i32, align 4
  store i32 %4, ptr %src_align, align 4
  %size = alloca ptr, align 8
  store ptr %5, ptr %size, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %dst2 = load ptr, ptr %dst, align 8
  %dst_align3 = load i32, ptr %dst_align, align 4
  %src4 = load ptr, ptr %src, align 8
  %src_align5 = load i32, ptr %src_align, align 4
  %size6 = load ptr, ptr %size, align 8
  %6 = call ptr @LLVMBuildMemCpy(ptr %b1, ptr %dst2, i32 %dst_align3, ptr %src4, i32 %src_align5, ptr %size6)
  store ptr %6, ptr %r, align 8
  %r7 = load ptr, ptr %r, align 8
  ret ptr %r7
}

define internal ptr @arc_LLVMBuildBr(ptr %0, ptr %1) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %dest = alloca ptr, align 8
  store ptr %1, ptr %dest, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %dest2 = load ptr, ptr %dest, align 8
  %2 = call ptr @LLVMBuildBr(ptr %b1, ptr %dest2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_LLVMBuildCondBr(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %cond = alloca ptr, align 8
  store ptr %1, ptr %cond, align 8
  %then_bb = alloca ptr, align 8
  store ptr %2, ptr %then_bb, align 8
  %else_bb = alloca ptr, align 8
  store ptr %3, ptr %else_bb, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %cond2 = load ptr, ptr %cond, align 8
  %then_bb3 = load ptr, ptr %then_bb, align 8
  %else_bb4 = load ptr, ptr %else_bb, align 8
  %4 = call ptr @LLVMBuildCondBr(ptr %b1, ptr %cond2, ptr %then_bb3, ptr %else_bb4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildRet(ptr %0, ptr %1) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %2 = call ptr @LLVMBuildRet(ptr %b1, ptr %val2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_LLVMBuildRetVoid(ptr %0) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %1 = call ptr @LLVMBuildRetVoid(ptr %b1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMBuildUnreachable(ptr %0) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %1 = call ptr @LLVMBuildUnreachable(ptr %b1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMBuildCall2(ptr %0, ptr %1, ptr %2, ptr %3, i32 %4, ptr %5) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %fn_ty = alloca ptr, align 8
  store ptr %1, ptr %fn_ty, align 8
  %fn_ref = alloca ptr, align 8
  store ptr %2, ptr %fn_ref, align 8
  %args = alloca ptr, align 8
  store ptr %3, ptr %args, align 8
  %nargs = alloca i32, align 4
  store i32 %4, ptr %nargs, align 4
  %name = alloca ptr, align 8
  store ptr %5, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %fn_ty2 = load ptr, ptr %fn_ty, align 8
  %fn_ref3 = load ptr, ptr %fn_ref, align 8
  %args4 = load ptr, ptr %args, align 8
  %nargs5 = load i32, ptr %nargs, align 4
  %name6 = load ptr, ptr %name, align 8
  %6 = call ptr @LLVMBuildCall2(ptr %b1, ptr %fn_ty2, ptr %fn_ref3, ptr %args4, i32 %nargs5, ptr %name6)
  store ptr %6, ptr %r, align 8
  %r7 = load ptr, ptr %r, align 8
  ret ptr %r7
}

define internal ptr @arc_LLVMGetInlineAsm(ptr %0, ptr %1, i64 %2, ptr %3, i64 %4, i32 %5, i32 %6, i32 %7, i32 %8) {
entry:
  %ty = alloca ptr, align 8
  store ptr %0, ptr %ty, align 8
  %asm_string = alloca ptr, align 8
  store ptr %1, ptr %asm_string, align 8
  %asm_len = alloca i64, align 8
  store i64 %2, ptr %asm_len, align 8
  %constraints = alloca ptr, align 8
  store ptr %3, ptr %constraints, align 8
  %con_len = alloca i64, align 8
  store i64 %4, ptr %con_len, align 8
  %has_side_effects = alloca i32, align 4
  store i32 %5, ptr %has_side_effects, align 4
  %is_align_stack = alloca i32, align 4
  store i32 %6, ptr %is_align_stack, align 4
  %dialect = alloca i32, align 4
  store i32 %7, ptr %dialect, align 4
  %can_throw = alloca i32, align 4
  store i32 %8, ptr %can_throw, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ty1 = load ptr, ptr %ty, align 8
  %asm_string2 = load ptr, ptr %asm_string, align 8
  %asm_len3 = load i64, ptr %asm_len, align 8
  %constraints4 = load ptr, ptr %constraints, align 8
  %con_len5 = load i64, ptr %con_len, align 8
  %has_side_effects6 = load i32, ptr %has_side_effects, align 4
  %is_align_stack7 = load i32, ptr %is_align_stack, align 4
  %dialect8 = load i32, ptr %dialect, align 4
  %can_throw9 = load i32, ptr %can_throw, align 4
  %9 = call ptr @LLVMGetInlineAsm(ptr %ty1, ptr %asm_string2, i64 %asm_len3, ptr %constraints4, i64 %con_len5, i32 %has_side_effects6, i32 %is_align_stack7, i32 %dialect8, i32 %can_throw9)
  store ptr %9, ptr %r, align 8
  %r10 = load ptr, ptr %r, align 8
  ret ptr %r10
}

define internal ptr @arc_LLVMBuildTrunc(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %dest_ty = alloca ptr, align 8
  store ptr %2, ptr %dest_ty, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %dest_ty3 = load ptr, ptr %dest_ty, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildTrunc(ptr %b1, ptr %val2, ptr %dest_ty3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildZExt(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %dest_ty = alloca ptr, align 8
  store ptr %2, ptr %dest_ty, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %dest_ty3 = load ptr, ptr %dest_ty, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildZExt(ptr %b1, ptr %val2, ptr %dest_ty3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildSExt(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %dest_ty = alloca ptr, align 8
  store ptr %2, ptr %dest_ty, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %dest_ty3 = load ptr, ptr %dest_ty, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildSExt(ptr %b1, ptr %val2, ptr %dest_ty3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildFPToUI(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %dest_ty = alloca ptr, align 8
  store ptr %2, ptr %dest_ty, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %dest_ty3 = load ptr, ptr %dest_ty, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildFPToUI(ptr %b1, ptr %val2, ptr %dest_ty3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildFPToSI(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %dest_ty = alloca ptr, align 8
  store ptr %2, ptr %dest_ty, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %dest_ty3 = load ptr, ptr %dest_ty, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildFPToSI(ptr %b1, ptr %val2, ptr %dest_ty3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildUIToFP(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %dest_ty = alloca ptr, align 8
  store ptr %2, ptr %dest_ty, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %dest_ty3 = load ptr, ptr %dest_ty, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildUIToFP(ptr %b1, ptr %val2, ptr %dest_ty3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildSIToFP(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %dest_ty = alloca ptr, align 8
  store ptr %2, ptr %dest_ty, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %dest_ty3 = load ptr, ptr %dest_ty, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildSIToFP(ptr %b1, ptr %val2, ptr %dest_ty3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildFPTrunc(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %dest_ty = alloca ptr, align 8
  store ptr %2, ptr %dest_ty, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %dest_ty3 = load ptr, ptr %dest_ty, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildFPTrunc(ptr %b1, ptr %val2, ptr %dest_ty3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildFPExt(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %dest_ty = alloca ptr, align 8
  store ptr %2, ptr %dest_ty, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %dest_ty3 = load ptr, ptr %dest_ty, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildFPExt(ptr %b1, ptr %val2, ptr %dest_ty3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildFPCast(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %dest_ty = alloca ptr, align 8
  store ptr %2, ptr %dest_ty, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %dest_ty3 = load ptr, ptr %dest_ty, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildFPCast(ptr %b1, ptr %val2, ptr %dest_ty3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildBitCast(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %dest_ty = alloca ptr, align 8
  store ptr %2, ptr %dest_ty, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %dest_ty3 = load ptr, ptr %dest_ty, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildBitCast(ptr %b1, ptr %val2, ptr %dest_ty3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildIntToPtr(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %dest_ty = alloca ptr, align 8
  store ptr %2, ptr %dest_ty, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %dest_ty3 = load ptr, ptr %dest_ty, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildIntToPtr(ptr %b1, ptr %val2, ptr %dest_ty3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildPtrToInt(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %dest_ty = alloca ptr, align 8
  store ptr %2, ptr %dest_ty, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %dest_ty3 = load ptr, ptr %dest_ty, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildPtrToInt(ptr %b1, ptr %val2, ptr %dest_ty3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildPointerCast(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %dest_ty = alloca ptr, align 8
  store ptr %2, ptr %dest_ty, align 8
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %dest_ty3 = load ptr, ptr %dest_ty, align 8
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildPointerCast(ptr %b1, ptr %val2, ptr %dest_ty3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildExtractValue(ptr %0, ptr %1, i32 %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %agg = alloca ptr, align 8
  store ptr %1, ptr %agg, align 8
  %idx = alloca i32, align 4
  store i32 %2, ptr %idx, align 4
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %agg2 = load ptr, ptr %agg, align 8
  %idx3 = load i32, ptr %idx, align 4
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildExtractValue(ptr %b1, ptr %agg2, i32 %idx3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildInsertValue(ptr %0, ptr %1, ptr %2, i32 %3, ptr %4) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %agg = alloca ptr, align 8
  store ptr %1, ptr %agg, align 8
  %val = alloca ptr, align 8
  store ptr %2, ptr %val, align 8
  %idx = alloca i32, align 4
  store i32 %3, ptr %idx, align 4
  %name = alloca ptr, align 8
  store ptr %4, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %agg2 = load ptr, ptr %agg, align 8
  %val3 = load ptr, ptr %val, align 8
  %idx4 = load i32, ptr %idx, align 4
  %name5 = load ptr, ptr %name, align 8
  %5 = call ptr @LLVMBuildInsertValue(ptr %b1, ptr %agg2, ptr %val3, i32 %idx4, ptr %name5)
  store ptr %5, ptr %r, align 8
  %r6 = load ptr, ptr %r, align 8
  ret ptr %r6
}

define internal ptr @arc_LLVMBuildFence(ptr %0, i32 %1, i32 %2, ptr %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %ordering = alloca i32, align 4
  store i32 %1, ptr %ordering, align 4
  %single_thread = alloca i32, align 4
  store i32 %2, ptr %single_thread, align 4
  %name = alloca ptr, align 8
  store ptr %3, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %ordering2 = load i32, ptr %ordering, align 4
  %single_thread3 = load i32, ptr %single_thread, align 4
  %name4 = load ptr, ptr %name, align 8
  %4 = call ptr @LLVMBuildFence(ptr %b1, i32 %ordering2, i32 %single_thread3, ptr %name4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal ptr @arc_LLVMBuildAtomicRMW(ptr %0, i32 %1, ptr %2, ptr %3, i32 %4, i32 %5) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %op = alloca i32, align 4
  store i32 %1, ptr %op, align 4
  %ptr = alloca ptr, align 8
  store ptr %2, ptr %ptr, align 8
  %val = alloca ptr, align 8
  store ptr %3, ptr %val, align 8
  %ordering = alloca i32, align 4
  store i32 %4, ptr %ordering, align 4
  %single_thread = alloca i32, align 4
  store i32 %5, ptr %single_thread, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %op2 = load i32, ptr %op, align 4
  %ptr3 = load ptr, ptr %ptr, align 8
  %val4 = load ptr, ptr %val, align 8
  %ordering5 = load i32, ptr %ordering, align 4
  %single_thread6 = load i32, ptr %single_thread, align 4
  %6 = call ptr @LLVMBuildAtomicRMW(ptr %b1, i32 %op2, ptr %ptr3, ptr %val4, i32 %ordering5, i32 %single_thread6)
  store ptr %6, ptr %r, align 8
  %r7 = load ptr, ptr %r, align 8
  ret ptr %r7
}

define internal ptr @arc_LLVMBuildAtomicCmpXchg(ptr %0, ptr %1, ptr %2, ptr %3, i32 %4, i32 %5, i32 %6) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %ptr = alloca ptr, align 8
  store ptr %1, ptr %ptr, align 8
  %cmp = alloca ptr, align 8
  store ptr %2, ptr %cmp, align 8
  %new_val = alloca ptr, align 8
  store ptr %3, ptr %new_val, align 8
  %success_ord = alloca i32, align 4
  store i32 %4, ptr %success_ord, align 4
  %failure_ord = alloca i32, align 4
  store i32 %5, ptr %failure_ord, align 4
  %single_thread = alloca i32, align 4
  store i32 %6, ptr %single_thread, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %ptr2 = load ptr, ptr %ptr, align 8
  %cmp3 = load ptr, ptr %cmp, align 8
  %new_val4 = load ptr, ptr %new_val, align 8
  %success_ord5 = load i32, ptr %success_ord, align 4
  %failure_ord6 = load i32, ptr %failure_ord, align 4
  %single_thread7 = load i32, ptr %single_thread, align 4
  %7 = call ptr @LLVMBuildAtomicCmpXchg(ptr %b1, ptr %ptr2, ptr %cmp3, ptr %new_val4, i32 %success_ord5, i32 %failure_ord6, i32 %single_thread7)
  store ptr %7, ptr %r, align 8
  %r8 = load ptr, ptr %r, align 8
  ret ptr %r8
}

define internal ptr @arc_LLVMBuildPhi(ptr %0, ptr %1, ptr %2) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %ty = alloca ptr, align 8
  store ptr %1, ptr %ty, align 8
  %name = alloca ptr, align 8
  store ptr %2, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %ty2 = load ptr, ptr %ty, align 8
  %name3 = load ptr, ptr %name, align 8
  %3 = call ptr @LLVMBuildPhi(ptr %b1, ptr %ty2, ptr %name3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal void @arc_LLVMAddIncoming(ptr %0, ptr %1, ptr %2, i32 %3) {
entry:
  %phi = alloca ptr, align 8
  store ptr %0, ptr %phi, align 8
  %vals = alloca ptr, align 8
  store ptr %1, ptr %vals, align 8
  %bbs = alloca ptr, align 8
  store ptr %2, ptr %bbs, align 8
  %count = alloca i32, align 4
  store i32 %3, ptr %count, align 4
  %phi1 = load ptr, ptr %phi, align 8
  %vals2 = load ptr, ptr %vals, align 8
  %bbs3 = load ptr, ptr %bbs, align 8
  %count4 = load i32, ptr %count, align 4
  call void @LLVMAddIncoming(ptr %phi1, ptr %vals2, ptr %bbs3, i32 %count4)
  ret void
}

define internal ptr @arc_LLVMBuildSelect(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %cond = alloca ptr, align 8
  store ptr %1, ptr %cond, align 8
  %then_val = alloca ptr, align 8
  store ptr %2, ptr %then_val, align 8
  %else_val = alloca ptr, align 8
  store ptr %3, ptr %else_val, align 8
  %name = alloca ptr, align 8
  store ptr %4, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %cond2 = load ptr, ptr %cond, align 8
  %then_val3 = load ptr, ptr %then_val, align 8
  %else_val4 = load ptr, ptr %else_val, align 8
  %name5 = load ptr, ptr %name, align 8
  %5 = call ptr @LLVMBuildSelect(ptr %b1, ptr %cond2, ptr %then_val3, ptr %else_val4, ptr %name5)
  store ptr %5, ptr %r, align 8
  %r6 = load ptr, ptr %r, align 8
  ret ptr %r6
}

define internal ptr @arc_LLVMBuildSwitch(ptr %0, ptr %1, ptr %2, i32 %3) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %val = alloca ptr, align 8
  store ptr %1, ptr %val, align 8
  %default_bb = alloca ptr, align 8
  store ptr %2, ptr %default_bb, align 8
  %num_cases = alloca i32, align 4
  store i32 %3, ptr %num_cases, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %val2 = load ptr, ptr %val, align 8
  %default_bb3 = load ptr, ptr %default_bb, align 8
  %num_cases4 = load i32, ptr %num_cases, align 4
  %4 = call ptr @LLVMBuildSwitch(ptr %b1, ptr %val2, ptr %default_bb3, i32 %num_cases4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal void @arc_LLVMAddCase(ptr %0, ptr %1, ptr %2) {
entry:
  %sw = alloca ptr, align 8
  store ptr %0, ptr %sw, align 8
  %on_val = alloca ptr, align 8
  store ptr %1, ptr %on_val, align 8
  %dest = alloca ptr, align 8
  store ptr %2, ptr %dest, align 8
  %sw1 = load ptr, ptr %sw, align 8
  %on_val2 = load ptr, ptr %on_val, align 8
  %dest3 = load ptr, ptr %dest, align 8
  call void @LLVMAddCase(ptr %sw1, ptr %on_val2, ptr %dest3)
  ret void
}

define internal i32 @arc_LLVMGetTargetFromTriple(ptr %0, ptr %1, ptr %2) {
entry:
  %triple = alloca ptr, align 8
  store ptr %0, ptr %triple, align 8
  %target_out = alloca ptr, align 8
  store ptr %1, ptr %target_out, align 8
  %err_out = alloca ptr, align 8
  store ptr %2, ptr %err_out, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %triple1 = load ptr, ptr %triple, align 8
  %target_out2 = load ptr, ptr %target_out, align 8
  %err_out3 = load ptr, ptr %err_out, align 8
  %3 = call i32 @LLVMGetTargetFromTriple(ptr %triple1, ptr %target_out2, ptr %err_out3)
  store i32 %3, ptr %r, align 4
  %r4 = load i32, ptr %r, align 4
  ret i32 %r4
}

define internal ptr @arc_LLVMCreateTargetMachine(ptr %0, ptr %1, ptr %2, ptr %3, i32 %4, i32 %5, i32 %6) {
entry:
  %target = alloca ptr, align 8
  store ptr %0, ptr %target, align 8
  %triple = alloca ptr, align 8
  store ptr %1, ptr %triple, align 8
  %cpu = alloca ptr, align 8
  store ptr %2, ptr %cpu, align 8
  %features = alloca ptr, align 8
  store ptr %3, ptr %features, align 8
  %opt_level = alloca i32, align 4
  store i32 %4, ptr %opt_level, align 4
  %reloc = alloca i32, align 4
  store i32 %5, ptr %reloc, align 4
  %code_model = alloca i32, align 4
  store i32 %6, ptr %code_model, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %target1 = load ptr, ptr %target, align 8
  %triple2 = load ptr, ptr %triple, align 8
  %cpu3 = load ptr, ptr %cpu, align 8
  %features4 = load ptr, ptr %features, align 8
  %opt_level5 = load i32, ptr %opt_level, align 4
  %reloc6 = load i32, ptr %reloc, align 4
  %code_model7 = load i32, ptr %code_model, align 4
  %7 = call ptr @LLVMCreateTargetMachine(ptr %target1, ptr %triple2, ptr %cpu3, ptr %features4, i32 %opt_level5, i32 %reloc6, i32 %code_model7)
  store ptr %7, ptr %r, align 8
  %r8 = load ptr, ptr %r, align 8
  ret ptr %r8
}

define internal void @arc_LLVMDisposeTargetMachine(ptr %0) {
entry:
  %tm = alloca ptr, align 8
  store ptr %0, ptr %tm, align 8
  %tm1 = load ptr, ptr %tm, align 8
  call void @LLVMDisposeTargetMachine(ptr %tm1)
  ret void
}

define internal ptr @arc_LLVMGetDefaultTargetTriple() {
entry:
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %0 = call ptr @LLVMGetDefaultTargetTriple()
  store ptr %0, ptr %r, align 8
  %r1 = load ptr, ptr %r, align 8
  ret ptr %r1
}

define internal ptr @arc_LLVMGetHostCPUName() {
entry:
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %0 = call ptr @LLVMGetHostCPUName()
  store ptr %0, ptr %r, align 8
  %r1 = load ptr, ptr %r, align 8
  ret ptr %r1
}

define internal ptr @arc_LLVMGetHostCPUFeatures() {
entry:
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %0 = call ptr @LLVMGetHostCPUFeatures()
  store ptr %0, ptr %r, align 8
  %r1 = load ptr, ptr %r, align 8
  ret ptr %r1
}

define internal void @arc_LLVMDisposeMessage(ptr %0) {
entry:
  %msg = alloca ptr, align 8
  store ptr %0, ptr %msg, align 8
  %msg1 = load ptr, ptr %msg, align 8
  call void @LLVMDisposeMessage(ptr %msg1)
  ret void
}

define internal ptr @arc_LLVMCreateTargetDataLayout(ptr %0) {
entry:
  %tm = alloca ptr, align 8
  store ptr %0, ptr %tm, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %tm1 = load ptr, ptr %tm, align 8
  %1 = call ptr @LLVMCreateTargetDataLayout(ptr %tm1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMCopyStringRepOfTargetData(ptr %0) {
entry:
  %td = alloca ptr, align 8
  store ptr %0, ptr %td, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %td1 = load ptr, ptr %td, align 8
  %1 = call ptr @LLVMCopyStringRepOfTargetData(ptr %td1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal void @arc_LLVMDisposeTargetData(ptr %0) {
entry:
  %td = alloca ptr, align 8
  store ptr %0, ptr %td, align 8
  %td1 = load ptr, ptr %td, align 8
  call void @LLVMDisposeTargetData(ptr %td1)
  ret void
}

define internal ptr @arc_LLVMGetModuleDataLayout(ptr %0) {
entry:
  %m = alloca ptr, align 8
  store ptr %0, ptr %m, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %m1 = load ptr, ptr %m, align 8
  %1 = call ptr @LLVMGetModuleDataLayout(ptr %m1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal i64 @arc_LLVMOffsetOfElement(ptr %0, ptr %1, i32 %2) {
entry:
  %td = alloca ptr, align 8
  store ptr %0, ptr %td, align 8
  %st = alloca ptr, align 8
  store ptr %1, ptr %st, align 8
  %elem = alloca i32, align 4
  store i32 %2, ptr %elem, align 4
  %r = alloca i64, align 8
  store i64 0, ptr %r, align 8
  %td1 = load ptr, ptr %td, align 8
  %st2 = load ptr, ptr %st, align 8
  %elem3 = load i32, ptr %elem, align 4
  %3 = call i64 @LLVMOffsetOfElement(ptr %td1, ptr %st2, i32 %elem3)
  store i64 %3, ptr %r, align 8
  %r4 = load i64, ptr %r, align 8
  ret i64 %r4
}

define internal i64 @arc_LLVMABISizeOfType(ptr %0, ptr %1) {
entry:
  %td = alloca ptr, align 8
  store ptr %0, ptr %td, align 8
  %ty = alloca ptr, align 8
  store ptr %1, ptr %ty, align 8
  %r = alloca i64, align 8
  store i64 0, ptr %r, align 8
  %td1 = load ptr, ptr %td, align 8
  %ty2 = load ptr, ptr %ty, align 8
  %2 = call i64 @LLVMABISizeOfType(ptr %td1, ptr %ty2)
  store i64 %2, ptr %r, align 8
  %r3 = load i64, ptr %r, align 8
  ret i64 %r3
}

define internal i32 @arc_LLVMABIAlignmentOfType(ptr %0, ptr %1) {
entry:
  %td = alloca ptr, align 8
  store ptr %0, ptr %td, align 8
  %ty = alloca ptr, align 8
  store ptr %1, ptr %ty, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %td1 = load ptr, ptr %td, align 8
  %ty2 = load ptr, ptr %ty, align 8
  %2 = call i32 @LLVMABIAlignmentOfType(ptr %td1, ptr %ty2)
  store i32 %2, ptr %r, align 4
  %r3 = load i32, ptr %r, align 4
  ret i32 %r3
}

define internal i32 @arc_LLVMVerifyModule(ptr %0, i32 %1, ptr %2) {
entry:
  %mod = alloca ptr, align 8
  store ptr %0, ptr %mod, align 8
  %action = alloca i32, align 4
  store i32 %1, ptr %action, align 4
  %msg_out = alloca ptr, align 8
  store ptr %2, ptr %msg_out, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %mod1 = load ptr, ptr %mod, align 8
  %action2 = load i32, ptr %action, align 4
  %msg_out3 = load ptr, ptr %msg_out, align 8
  %3 = call i32 @LLVMVerifyModule(ptr %mod1, i32 %action2, ptr %msg_out3)
  store i32 %3, ptr %r, align 4
  %r4 = load i32, ptr %r, align 4
  ret i32 %r4
}

define internal i32 @arc_LLVMTargetMachineEmitToFile(ptr %0, ptr %1, ptr %2, i32 %3, ptr %4) {
entry:
  %tm = alloca ptr, align 8
  store ptr %0, ptr %tm, align 8
  %mod = alloca ptr, align 8
  store ptr %1, ptr %mod, align 8
  %filename = alloca ptr, align 8
  store ptr %2, ptr %filename, align 8
  %filetype = alloca i32, align 4
  store i32 %3, ptr %filetype, align 4
  %err_out = alloca ptr, align 8
  store ptr %4, ptr %err_out, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %tm1 = load ptr, ptr %tm, align 8
  %mod2 = load ptr, ptr %mod, align 8
  %filename3 = load ptr, ptr %filename, align 8
  %filetype4 = load i32, ptr %filetype, align 4
  %err_out5 = load ptr, ptr %err_out, align 8
  %5 = call i32 @LLVMTargetMachineEmitToFile(ptr %tm1, ptr %mod2, ptr %filename3, i32 %filetype4, ptr %err_out5)
  store i32 %5, ptr %r, align 4
  %r6 = load i32, ptr %r, align 4
  ret i32 %r6
}

define internal i32 @arc_LLVMPrintModuleToFile(ptr %0, ptr %1, ptr %2) {
entry:
  %mod = alloca ptr, align 8
  store ptr %0, ptr %mod, align 8
  %filename = alloca ptr, align 8
  store ptr %1, ptr %filename, align 8
  %err_out = alloca ptr, align 8
  store ptr %2, ptr %err_out, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %mod1 = load ptr, ptr %mod, align 8
  %filename2 = load ptr, ptr %filename, align 8
  %err_out3 = load ptr, ptr %err_out, align 8
  %3 = call i32 @LLVMPrintModuleToFile(ptr %mod1, ptr %filename2, ptr %err_out3)
  store i32 %3, ptr %r, align 4
  %r4 = load i32, ptr %r, align 4
  ret i32 %r4
}

define internal ptr @arc_LLVMPrintModuleToString(ptr %0) {
entry:
  %mod = alloca ptr, align 8
  store ptr %0, ptr %mod, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %mod1 = load ptr, ptr %mod, align 8
  %1 = call ptr @LLVMPrintModuleToString(ptr %mod1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMCreatePassBuilderOptions() {
entry:
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %0 = call ptr @LLVMCreatePassBuilderOptions()
  store ptr %0, ptr %r, align 8
  %r1 = load ptr, ptr %r, align 8
  ret ptr %r1
}

define internal void @arc_LLVMDisposePassBuilderOptions(ptr %0) {
entry:
  %opts = alloca ptr, align 8
  store ptr %0, ptr %opts, align 8
  %opts1 = load ptr, ptr %opts, align 8
  call void @LLVMDisposePassBuilderOptions(ptr %opts1)
  ret void
}

define internal ptr @arc_LLVMRunPasses(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %mod = alloca ptr, align 8
  store ptr %0, ptr %mod, align 8
  %passes = alloca ptr, align 8
  store ptr %1, ptr %passes, align 8
  %tm = alloca ptr, align 8
  store ptr %2, ptr %tm, align 8
  %opts = alloca ptr, align 8
  store ptr %3, ptr %opts, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %mod1 = load ptr, ptr %mod, align 8
  %passes2 = load ptr, ptr %passes, align 8
  %tm3 = load ptr, ptr %tm, align 8
  %opts4 = load ptr, ptr %opts, align 8
  %4 = call ptr @LLVMRunPasses(ptr %mod1, ptr %passes2, ptr %tm3, ptr %opts4)
  store ptr %4, ptr %r, align 8
  %r5 = load ptr, ptr %r, align 8
  ret ptr %r5
}

define internal void @arc_LLVMConsumeError(ptr %0) {
entry:
  %err = alloca ptr, align 8
  store ptr %0, ptr %err, align 8
  %err1 = load ptr, ptr %err, align 8
  call void @LLVMConsumeError(ptr %err1)
  ret void
}

define internal ptr @arc_LLVMGetErrorMessage(ptr %0) {
entry:
  %err = alloca ptr, align 8
  store ptr %0, ptr %err, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %err1 = load ptr, ptr %err, align 8
  %1 = call ptr @LLVMGetErrorMessage(ptr %err1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal void @arc_LLVMDisposeErrorMessage(ptr %0) {
entry:
  %msg = alloca ptr, align 8
  store ptr %0, ptr %msg, align 8
  %msg1 = load ptr, ptr %msg, align 8
  call void @LLVMDisposeErrorMessage(ptr %msg1)
  ret void
}

define internal ptr @arc_LLVMBuildGlobalStringPtr(ptr %0, ptr %1, ptr %2) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %str = alloca ptr, align 8
  store ptr %1, ptr %str, align 8
  %name = alloca ptr, align 8
  store ptr %2, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %str2 = load ptr, ptr %str, align 8
  %name3 = load ptr, ptr %name, align 8
  %3 = call ptr @LLVMBuildGlobalStringPtr(ptr %b1, ptr %str2, ptr %name3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_LLVMBuildGlobalString(ptr %0, ptr %1, ptr %2) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %str = alloca ptr, align 8
  store ptr %1, ptr %str, align 8
  %name = alloca ptr, align 8
  store ptr %2, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %b1 = load ptr, ptr %b, align 8
  %str2 = load ptr, ptr %str, align 8
  %name3 = load ptr, ptr %name, align 8
  %3 = call ptr @LLVMBuildGlobalString(ptr %b1, ptr %str2, ptr %name3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_LLVMSizeOf(ptr %0) {
entry:
  %ty = alloca ptr, align 8
  store ptr %0, ptr %ty, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ty1 = load ptr, ptr %ty, align 8
  %1 = call ptr @LLVMSizeOf(ptr %ty1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMAlignOf(ptr %0) {
entry:
  %ty = alloca ptr, align 8
  store ptr %0, ptr %ty, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ty1 = load ptr, ptr %ty, align 8
  %1 = call ptr @LLVMAlignOf(ptr %ty1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMStructGetTypeAtIndex(ptr %0, i32 %1) {
entry:
  %sty = alloca ptr, align 8
  store ptr %0, ptr %sty, align 8
  %idx = alloca i32, align 4
  store i32 %1, ptr %idx, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %sty1 = load ptr, ptr %sty, align 8
  %idx2 = load i32, ptr %idx, align 4
  %2 = call ptr @LLVMStructGetTypeAtIndex(ptr %sty1, i32 %idx2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_LLVMIsAConstant(ptr %0) {
entry:
  %val = alloca ptr, align 8
  store ptr %0, ptr %val, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %val1 = load ptr, ptr %val, align 8
  %1 = call ptr @LLVMIsAConstant(ptr %val1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMIsAConstantInt(ptr %0) {
entry:
  %val = alloca ptr, align 8
  store ptr %0, ptr %val, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %val1 = load ptr, ptr %val, align 8
  %1 = call ptr @LLVMIsAConstantInt(ptr %val1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal i64 @arc_LLVMConstIntGetSExtValue(ptr %0) {
entry:
  %val = alloca ptr, align 8
  store ptr %0, ptr %val, align 8
  %r = alloca i64, align 8
  store i64 0, ptr %r, align 8
  %val1 = load ptr, ptr %val, align 8
  %1 = call i64 @LLVMConstIntGetSExtValue(ptr %val1)
  store i64 %1, ptr %r, align 8
  %r2 = load i64, ptr %r, align 8
  ret i64 %r2
}

define internal i64 @arc_LLVMConstIntGetZExtValue(ptr %0) {
entry:
  %val = alloca ptr, align 8
  store ptr %0, ptr %val, align 8
  %r = alloca i64, align 8
  store i64 0, ptr %r, align 8
  %val1 = load ptr, ptr %val, align 8
  %1 = call i64 @LLVMConstIntGetZExtValue(ptr %val1)
  store i64 %1, ptr %r, align 8
  %r2 = load i64, ptr %r, align 8
  ret i64 %r2
}

define internal ptr @arc_LLVMGetStructElementTypes_get(ptr %0, i32 %1) {
entry:
  %sty = alloca ptr, align 8
  store ptr %0, ptr %sty, align 8
  %idx = alloca i32, align 4
  store i32 %1, ptr %idx, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %sty1 = load ptr, ptr %sty, align 8
  %idx2 = load i32, ptr %idx, align 4
  %2 = call ptr @LLVMGetStructElementTypes_get(ptr %sty1, i32 %idx2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal void @arc_LLVMFunctionType_get_params(ptr %0, ptr %1, i32 %2) {
entry:
  %fnty = alloca ptr, align 8
  store ptr %0, ptr %fnty, align 8
  %dest = alloca ptr, align 8
  store ptr %1, ptr %dest, align 8
  %n = alloca i32, align 4
  store i32 %2, ptr %n, align 4
  %fnty1 = load ptr, ptr %fnty, align 8
  %dest2 = load ptr, ptr %dest, align 8
  %n3 = load i32, ptr %n, align 4
  call void @LLVMFunctionType_get_params(ptr %fnty1, ptr %dest2, i32 %n3)
  ret void
}

define internal ptr @arc_LLVMGetReturnType(ptr %0) {
entry:
  %fnty = alloca ptr, align 8
  store ptr %0, ptr %fnty, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %fnty1 = load ptr, ptr %fnty, align 8
  %1 = call ptr @LLVMGetReturnType(ptr %fnty1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal i32 @arc_LLVMGetFunctionCallConv(ptr %0) {
entry:
  %fn_ref = alloca ptr, align 8
  store ptr %0, ptr %fn_ref, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %fn_ref1 = load ptr, ptr %fn_ref, align 8
  %1 = call i32 @LLVMGetFunctionCallConv(ptr %fn_ref1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal void @arc_LLVMSetAlignment(ptr %0, i32 %1) {
entry:
  %val = alloca ptr, align 8
  store ptr %0, ptr %val, align 8
  %bytes = alloca i32, align 4
  store i32 %1, ptr %bytes, align 4
  %val1 = load ptr, ptr %val, align 8
  %bytes2 = load i32, ptr %bytes, align 4
  call void @LLVMSetAlignment(ptr %val1, i32 %bytes2)
  ret void
}

define internal void @arc_LLVMSetVolatile(ptr %0, i32 %1) {
entry:
  %memory_access_inst = alloca ptr, align 8
  store ptr %0, ptr %memory_access_inst, align 8
  %is_volatile = alloca i32, align 4
  store i32 %1, ptr %is_volatile, align 4
  %memory_access_inst1 = load ptr, ptr %memory_access_inst, align 8
  %is_volatile2 = load i32, ptr %is_volatile, align 4
  call void @LLVMSetVolatile(ptr %memory_access_inst1, i32 %is_volatile2)
  ret void
}

define internal ptr @arc_LLVMGetCalledFunctionType(ptr %0) {
entry:
  %call = alloca ptr, align 8
  store ptr %0, ptr %call, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %call1 = load ptr, ptr %call, align 8
  %1 = call ptr @LLVMGetCalledFunctionType(ptr %call1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMGetBasicBlocks_first(ptr %0) {
entry:
  %fn_ref = alloca ptr, align 8
  store ptr %0, ptr %fn_ref, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %fn_ref1 = load ptr, ptr %fn_ref, align 8
  %1 = call ptr @LLVMGetBasicBlocks_first(ptr %fn_ref1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_LLVMGetNextBasicBlock(ptr %0) {
entry:
  %bb = alloca ptr, align 8
  store ptr %0, ptr %bb, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %bb1 = load ptr, ptr %bb, align 8
  %1 = call ptr @LLVMGetNextBasicBlock(ptr %bb1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal i32 @arc_LLVMCountBasicBlocks(ptr %0) {
entry:
  %fn_ref = alloca ptr, align 8
  store ptr %0, ptr %fn_ref, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %fn_ref1 = load ptr, ptr %fn_ref, align 8
  %1 = call i32 @LLVMCountBasicBlocks(ptr %fn_ref1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal void @arc_LLVMInitializeAllTargetInfos_shim() {
entry:
  call void @LLVMInitializeAllTargetInfos_shim()
  ret void
}

define internal void @arc_LLVMInitializeAllTargets_shim() {
entry:
  call void @LLVMInitializeAllTargets_shim()
  ret void
}

define internal void @arc_LLVMInitializeAllTargetMCs_shim() {
entry:
  call void @LLVMInitializeAllTargetMCs_shim()
  ret void
}

define internal void @arc_LLVMInitializeAllAsmPrinters_shim() {
entry:
  call void @LLVMInitializeAllAsmPrinters_shim()
  ret void
}

define internal void @arc_LLVMInitializeAllAsmParsers_shim() {
entry:
  call void @LLVMInitializeAllAsmParsers_shim()
  ret void
}

define internal ptr @arc_malloc(i64 %0) {
entry:
  %size = alloca i64, align 8
  store i64 %0, ptr %size, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %size1 = load i64, ptr %size, align 8
  %1 = call ptr @malloc(i64 %size1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal ptr @arc_realloc(ptr %0, i64 %1) {
entry:
  %ptr = alloca ptr, align 8
  store ptr %0, ptr %ptr, align 8
  %size = alloca i64, align 8
  store i64 %1, ptr %size, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %ptr1 = load ptr, ptr %ptr, align 8
  %size2 = load i64, ptr %size, align 8
  %2 = call ptr @realloc(ptr %ptr1, i64 %size2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal void @arc_free(ptr %0) {
entry:
  %ptr = alloca ptr, align 8
  store ptr %0, ptr %ptr, align 8
  %ptr1 = load ptr, ptr %ptr, align 8
  call void @free(ptr %ptr1)
  ret void
}

define internal ptr @arc_memset(ptr %0, i32 %1, i64 %2) {
entry:
  %dst = alloca ptr, align 8
  store ptr %0, ptr %dst, align 8
  %val = alloca i32, align 4
  store i32 %1, ptr %val, align 4
  %n = alloca i64, align 8
  store i64 %2, ptr %n, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %dst1 = load ptr, ptr %dst, align 8
  %val2 = load i32, ptr %val, align 4
  %n3 = load i64, ptr %n, align 8
  %3 = call ptr @memset(ptr %dst1, i32 %val2, i64 %n3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_memcpy(ptr %0, ptr %1, i64 %2) {
entry:
  %dst = alloca ptr, align 8
  store ptr %0, ptr %dst, align 8
  %src = alloca ptr, align 8
  store ptr %1, ptr %src, align 8
  %n = alloca i64, align 8
  store i64 %2, ptr %n, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %dst1 = load ptr, ptr %dst, align 8
  %src2 = load ptr, ptr %src, align 8
  %n3 = load i64, ptr %n, align 8
  %3 = call ptr @memcpy(ptr %dst1, ptr %src2, i64 %n3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_memmove(ptr %0, ptr %1, i64 %2) {
entry:
  %dst = alloca ptr, align 8
  store ptr %0, ptr %dst, align 8
  %src = alloca ptr, align 8
  store ptr %1, ptr %src, align 8
  %n = alloca i64, align 8
  store i64 %2, ptr %n, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %dst1 = load ptr, ptr %dst, align 8
  %src2 = load ptr, ptr %src, align 8
  %n3 = load i64, ptr %n, align 8
  %3 = call ptr @memmove(ptr %dst1, ptr %src2, i64 %n3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal i32 @arc_memcmp(ptr %0, ptr %1, i64 %2) {
entry:
  %a = alloca ptr, align 8
  store ptr %0, ptr %a, align 8
  %b = alloca ptr, align 8
  store ptr %1, ptr %b, align 8
  %n = alloca i64, align 8
  store i64 %2, ptr %n, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %a1 = load ptr, ptr %a, align 8
  %b2 = load ptr, ptr %b, align 8
  %n3 = load i64, ptr %n, align 8
  %3 = call i32 @memcmp(ptr %a1, ptr %b2, i64 %n3)
  store i32 %3, ptr %r, align 4
  %r4 = load i32, ptr %r, align 4
  ret i32 %r4
}

define internal i32 @arc_strcmp(ptr %0, ptr %1) {
entry:
  %a = alloca ptr, align 8
  store ptr %0, ptr %a, align 8
  %b = alloca ptr, align 8
  store ptr %1, ptr %b, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %a1 = load ptr, ptr %a, align 8
  %b2 = load ptr, ptr %b, align 8
  %2 = call i32 @strcmp(ptr %a1, ptr %b2)
  store i32 %2, ptr %r, align 4
  %r3 = load i32, ptr %r, align 4
  ret i32 %r3
}

define internal i32 @arc_strncmp(ptr %0, ptr %1, i64 %2) {
entry:
  %a = alloca ptr, align 8
  store ptr %0, ptr %a, align 8
  %b = alloca ptr, align 8
  store ptr %1, ptr %b, align 8
  %n = alloca i64, align 8
  store i64 %2, ptr %n, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %a1 = load ptr, ptr %a, align 8
  %b2 = load ptr, ptr %b, align 8
  %n3 = load i64, ptr %n, align 8
  %3 = call i32 @strncmp(ptr %a1, ptr %b2, i64 %n3)
  store i32 %3, ptr %r, align 4
  %r4 = load i32, ptr %r, align 4
  ret i32 %r4
}

define internal i64 @arc_strlen(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %r = alloca i64, align 8
  store i64 0, ptr %r, align 8
  %s1 = load ptr, ptr %s, align 8
  %1 = call i64 @strlen(ptr %s1)
  store i64 %1, ptr %r, align 8
  %r2 = load i64, ptr %r, align 8
  ret i64 %r2
}

define internal ptr @arc_strcpy(ptr %0, ptr %1) {
entry:
  %dst = alloca ptr, align 8
  store ptr %0, ptr %dst, align 8
  %src = alloca ptr, align 8
  store ptr %1, ptr %src, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %dst1 = load ptr, ptr %dst, align 8
  %src2 = load ptr, ptr %src, align 8
  %2 = call ptr @strcpy(ptr %dst1, ptr %src2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_strcat(ptr %0, ptr %1) {
entry:
  %dst = alloca ptr, align 8
  store ptr %0, ptr %dst, align 8
  %src = alloca ptr, align 8
  store ptr %1, ptr %src, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %dst1 = load ptr, ptr %dst, align 8
  %src2 = load ptr, ptr %src, align 8
  %2 = call ptr @strcat(ptr %dst1, ptr %src2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_strstr(ptr %0, ptr %1) {
entry:
  %haystack = alloca ptr, align 8
  store ptr %0, ptr %haystack, align 8
  %needle = alloca ptr, align 8
  store ptr %1, ptr %needle, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %haystack1 = load ptr, ptr %haystack, align 8
  %needle2 = load ptr, ptr %needle, align 8
  %2 = call ptr @strstr(ptr %haystack1, ptr %needle2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal ptr @arc_strchr(ptr %0, i32 %1) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %c = alloca i32, align 4
  store i32 %1, ptr %c, align 4
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %s1 = load ptr, ptr %s, align 8
  %c2 = load i32, ptr %c, align 4
  %2 = call ptr @strchr(ptr %s1, i32 %c2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal i32 @arc_puts(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %s1 = load ptr, ptr %s, align 8
  %1 = call i32 @puts(ptr %s1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i32 @arc_putchar(i32 %0) {
entry:
  %c = alloca i32, align 4
  store i32 %0, ptr %c, align 4
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %c1 = load i32, ptr %c, align 4
  %1 = call i32 @putchar(i32 %c1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i32 @arc_atoi(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %s1 = load ptr, ptr %s, align 8
  %1 = call i32 @atoi(ptr %s1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i64 @arc_atoll(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %r = alloca i64, align 8
  store i64 0, ptr %r, align 8
  %s1 = load ptr, ptr %s, align 8
  %1 = call i64 @atoll(ptr %s1)
  store i64 %1, ptr %r, align 8
  %r2 = load i64, ptr %r, align 8
  ret i64 %r2
}

define internal double @arc_atof(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %r = alloca double, align 8
  store double 0.000000e+00, ptr %r, align 8
  %s1 = load ptr, ptr %s, align 8
  %1 = call double @atof(ptr %s1)
  store double %1, ptr %r, align 8
  %r2 = load double, ptr %r, align 8
  ret double %r2
}

define internal i64 @arc_strtoll(ptr %0, ptr %1, i32 %2) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %end = alloca ptr, align 8
  store ptr %1, ptr %end, align 8
  %base = alloca i32, align 4
  store i32 %2, ptr %base, align 4
  %r = alloca i64, align 8
  store i64 0, ptr %r, align 8
  %s1 = load ptr, ptr %s, align 8
  %end2 = load ptr, ptr %end, align 8
  %base3 = load i32, ptr %base, align 4
  %3 = call i64 @strtoll(ptr %s1, ptr %end2, i32 %base3)
  store i64 %3, ptr %r, align 8
  %r4 = load i64, ptr %r, align 8
  ret i64 %r4
}

define internal i64 @arc_strtoull(ptr %0, ptr %1, i32 %2) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %end = alloca ptr, align 8
  store ptr %1, ptr %end, align 8
  %base = alloca i32, align 4
  store i32 %2, ptr %base, align 4
  %r = alloca i64, align 8
  store i64 0, ptr %r, align 8
  %s1 = load ptr, ptr %s, align 8
  %end2 = load ptr, ptr %end, align 8
  %base3 = load i32, ptr %base, align 4
  %3 = call i64 @strtoull(ptr %s1, ptr %end2, i32 %base3)
  store i64 %3, ptr %r, align 8
  %r4 = load i64, ptr %r, align 8
  ret i64 %r4
}

define internal double @arc_strtod(ptr %0, ptr %1) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %end = alloca ptr, align 8
  store ptr %1, ptr %end, align 8
  %r = alloca double, align 8
  store double 0.000000e+00, ptr %r, align 8
  %s1 = load ptr, ptr %s, align 8
  %end2 = load ptr, ptr %end, align 8
  %2 = call double @strtod(ptr %s1, ptr %end2)
  store double %2, ptr %r, align 8
  %r3 = load double, ptr %r, align 8
  ret double %r3
}

define internal void @arc_exit(i32 %0) {
entry:
  %code = alloca i32, align 4
  store i32 %0, ptr %code, align 4
  %code1 = load i32, ptr %code, align 4
  call void @exit(i32 %code1)
  ret void
}

define internal i32 @arc_system(ptr %0) {
entry:
  %cmd = alloca ptr, align 8
  store ptr %0, ptr %cmd, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %cmd1 = load ptr, ptr %cmd, align 8
  %1 = call i32 @system(ptr %cmd1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i32 @arc_remove(ptr %0) {
entry:
  %path = alloca ptr, align 8
  store ptr %0, ptr %path, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %path1 = load ptr, ptr %path, align 8
  %1 = call i32 @remove(ptr %path1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal ptr @arc_fopen(ptr %0, ptr %1) {
entry:
  %path = alloca ptr, align 8
  store ptr %0, ptr %path, align 8
  %mode = alloca ptr, align 8
  store ptr %1, ptr %mode, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %path1 = load ptr, ptr %path, align 8
  %mode2 = load ptr, ptr %mode, align 8
  %2 = call ptr @fopen(ptr %path1, ptr %mode2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal i32 @arc_fclose(ptr %0) {
entry:
  %fp = alloca ptr, align 8
  store ptr %0, ptr %fp, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %fp1 = load ptr, ptr %fp, align 8
  %1 = call i32 @fclose(ptr %fp1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i64 @arc_fread(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %sz = alloca i64, align 8
  store i64 %1, ptr %sz, align 8
  %n = alloca i64, align 8
  store i64 %2, ptr %n, align 8
  %fp = alloca ptr, align 8
  store ptr %3, ptr %fp, align 8
  %r = alloca i64, align 8
  store i64 0, ptr %r, align 8
  %buf1 = load ptr, ptr %buf, align 8
  %sz2 = load i64, ptr %sz, align 8
  %n3 = load i64, ptr %n, align 8
  %fp4 = load ptr, ptr %fp, align 8
  %4 = call i64 @fread(ptr %buf1, i64 %sz2, i64 %n3, ptr %fp4)
  store i64 %4, ptr %r, align 8
  %r5 = load i64, ptr %r, align 8
  ret i64 %r5
}

define internal i64 @arc_fwrite(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %sz = alloca i64, align 8
  store i64 %1, ptr %sz, align 8
  %n = alloca i64, align 8
  store i64 %2, ptr %n, align 8
  %fp = alloca ptr, align 8
  store ptr %3, ptr %fp, align 8
  %r = alloca i64, align 8
  store i64 0, ptr %r, align 8
  %buf1 = load ptr, ptr %buf, align 8
  %sz2 = load i64, ptr %sz, align 8
  %n3 = load i64, ptr %n, align 8
  %fp4 = load ptr, ptr %fp, align 8
  %4 = call i64 @fwrite(ptr %buf1, i64 %sz2, i64 %n3, ptr %fp4)
  store i64 %4, ptr %r, align 8
  %r5 = load i64, ptr %r, align 8
  ret i64 %r5
}

define internal i32 @arc_fseek(ptr %0, i64 %1, i32 %2) {
entry:
  %fp = alloca ptr, align 8
  store ptr %0, ptr %fp, align 8
  %off = alloca i64, align 8
  store i64 %1, ptr %off, align 8
  %whence = alloca i32, align 4
  store i32 %2, ptr %whence, align 4
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %fp1 = load ptr, ptr %fp, align 8
  %off2 = load i64, ptr %off, align 8
  %whence3 = load i32, ptr %whence, align 4
  %3 = call i32 @fseek(ptr %fp1, i64 %off2, i32 %whence3)
  store i32 %3, ptr %r, align 4
  %r4 = load i32, ptr %r, align 4
  ret i32 %r4
}

define internal i64 @arc_ftell(ptr %0) {
entry:
  %fp = alloca ptr, align 8
  store ptr %0, ptr %fp, align 8
  %r = alloca i64, align 8
  store i64 0, ptr %r, align 8
  %fp1 = load ptr, ptr %fp, align 8
  %1 = call i64 @ftell(ptr %fp1)
  store i64 %1, ptr %r, align 8
  %r2 = load i64, ptr %r, align 8
  ret i64 %r2
}

define internal i32 @arc_feof(ptr %0) {
entry:
  %fp = alloca ptr, align 8
  store ptr %0, ptr %fp, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %fp1 = load ptr, ptr %fp, align 8
  %1 = call i32 @feof(ptr %fp1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i32 @arc_fflush(ptr %0) {
entry:
  %fp = alloca ptr, align 8
  store ptr %0, ptr %fp, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %fp1 = load ptr, ptr %fp, align 8
  %1 = call i32 @fflush(ptr %fp1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal ptr @arc_getenv(ptr %0) {
entry:
  %name = alloca ptr, align 8
  store ptr %0, ptr %name, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %name1 = load ptr, ptr %name, align 8
  %1 = call ptr @getenv(ptr %name1)
  store ptr %1, ptr %r, align 8
  %r2 = load ptr, ptr %r, align 8
  ret ptr %r2
}

define internal i32 @arc_getchar() {
entry:
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %0 = call i32 @getchar()
  store i32 %0, ptr %r, align 4
  %r1 = load i32, ptr %r, align 4
  ret i32 %r1
}

define internal ptr @arc_fgets(ptr %0, i32 %1, ptr %2) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %n = alloca i32, align 4
  store i32 %1, ptr %n, align 4
  %fp = alloca ptr, align 8
  store ptr %2, ptr %fp, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %buf1 = load ptr, ptr %buf, align 8
  %n2 = load i32, ptr %n, align 4
  %fp3 = load ptr, ptr %fp, align 8
  %3 = call ptr @fgets(ptr %buf1, i32 %n2, ptr %fp3)
  store ptr %3, ptr %r, align 8
  %r4 = load ptr, ptr %r, align 8
  ret ptr %r4
}

define internal ptr @arc_popen(ptr %0, ptr %1) {
entry:
  %cmd = alloca ptr, align 8
  store ptr %0, ptr %cmd, align 8
  %mode = alloca ptr, align 8
  store ptr %1, ptr %mode, align 8
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %cmd1 = load ptr, ptr %cmd, align 8
  %mode2 = load ptr, ptr %mode, align 8
  %2 = call ptr @popen(ptr %cmd1, ptr %mode2)
  store ptr %2, ptr %r, align 8
  %r3 = load ptr, ptr %r, align 8
  ret ptr %r3
}

define internal i32 @arc_pclose(ptr %0) {
entry:
  %fp = alloca ptr, align 8
  store ptr %0, ptr %fp, align 8
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %fp1 = load ptr, ptr %fp, align 8
  %1 = call i32 @pclose(ptr %fp1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal ptr @arc_stdout_file() {
entry:
  %r = alloca ptr, align 8
  store ptr null, ptr %r, align 8
  %0 = call ptr @stdout_file()
  store ptr %0, ptr %r, align 8
  %r1 = load ptr, ptr %r, align 8
  ret ptr %r1
}

define internal i32 @arc_isalpha(i32 %0) {
entry:
  %c = alloca i32, align 4
  store i32 %0, ptr %c, align 4
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %c1 = load i32, ptr %c, align 4
  %1 = call i32 @isalpha(i32 %c1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i32 @arc_isdigit(i32 %0) {
entry:
  %c = alloca i32, align 4
  store i32 %0, ptr %c, align 4
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %c1 = load i32, ptr %c, align 4
  %1 = call i32 @isdigit(i32 %c1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i32 @arc_isalnum(i32 %0) {
entry:
  %c = alloca i32, align 4
  store i32 %0, ptr %c, align 4
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %c1 = load i32, ptr %c, align 4
  %1 = call i32 @isalnum(i32 %c1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i32 @arc_isspace(i32 %0) {
entry:
  %c = alloca i32, align 4
  store i32 %0, ptr %c, align 4
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %c1 = load i32, ptr %c, align 4
  %1 = call i32 @isspace(i32 %c1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i32 @arc_isxdigit(i32 %0) {
entry:
  %c = alloca i32, align 4
  store i32 %0, ptr %c, align 4
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %c1 = load i32, ptr %c, align 4
  %1 = call i32 @isxdigit(i32 %c1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i32 @arc_tolower(i32 %0) {
entry:
  %c = alloca i32, align 4
  store i32 %0, ptr %c, align 4
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %c1 = load i32, ptr %c, align 4
  %1 = call i32 @tolower(i32 %c1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i32 @arc_toupper(i32 %0) {
entry:
  %c = alloca i32, align 4
  store i32 %0, ptr %c, align 4
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %c1 = load i32, ptr %c, align 4
  %1 = call i32 @toupper(i32 %c1)
  store i32 %1, ptr %r, align 4
  %r2 = load i32, ptr %r, align 4
  ret i32 %r2
}

define internal i32 @arc_GetModuleFileNameA(ptr %0, ptr %1, i32 %2) {
entry:
  %hmod = alloca ptr, align 8
  store ptr %0, ptr %hmod, align 8
  %filename = alloca ptr, align 8
  store ptr %1, ptr %filename, align 8
  %size = alloca i32, align 4
  store i32 %2, ptr %size, align 4
  %r = alloca i32, align 4
  store i32 0, ptr %r, align 4
  %hmod1 = load ptr, ptr %hmod, align 8
  %filename2 = load ptr, ptr %filename, align 8
  %size3 = load i32, ptr %size, align 4
  %3 = call i32 @GetModuleFileNameA(ptr %hmod1, ptr %filename2, i32 %size3)
  store i32 %3, ptr %r, align 4
  %r4 = load i32, ptr %r, align 4
  ret i32 %r4
}

define internal ptr @SysAlloc__NS_alloc_(ptr %0, i64 %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %n = alloca i64, align 8
  store i64 %1, ptr %n, align 8
  %n1 = load i64, ptr %n, align 8
  %2 = call ptr @arc_malloc(i64 %n1)
  ret ptr %2
}

define internal ptr @SysAlloc__NS_grow_(ptr %0, ptr %1, i64 %2) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %p = alloca ptr, align 8
  store ptr %1, ptr %p, align 8
  %n = alloca i64, align 8
  store i64 %2, ptr %n, align 8
  %p1 = load ptr, ptr %p, align 8
  %n2 = load i64, ptr %n, align 8
  %3 = call ptr @arc_realloc(ptr %p1, i64 %n2)
  ret ptr %3
}

define internal void @SysAlloc__NS_free_(ptr %0, ptr %1) {
entry:
  %self = alloca ptr, align 8
  store ptr %0, ptr %self, align 8
  %p = alloca ptr, align 8
  store ptr %1, ptr %p, align 8
  %p1 = load ptr, ptr %p, align 8
  call void @arc_free(ptr %p1)
  ret void
}

define internal ptr @arc_malloc.1(i64 %0) {
entry:
  %n = alloca i64, align 8
  store i64 %0, ptr %n, align 8
  %_s = alloca %SysAlloc, align 8
  store %SysAlloc zeroinitializer, ptr %_s, align 1
  %n1 = load i64, ptr %n, align 8
  %1 = call ptr @SysAlloc__NS_alloc_(ptr %_s, i64 %n1)
  ret ptr %1
}

define internal ptr @arc_realloc.2(ptr %0, i64 %1) {
entry:
  %p = alloca ptr, align 8
  store ptr %0, ptr %p, align 8
  %n = alloca i64, align 8
  store i64 %1, ptr %n, align 8
  %_s = alloca %SysAlloc, align 8
  store %SysAlloc zeroinitializer, ptr %_s, align 1
  %p1 = load ptr, ptr %p, align 8
  %n2 = load i64, ptr %n, align 8
  %2 = call ptr @SysAlloc__NS_grow_(ptr %_s, ptr %p1, i64 %n2)
  ret ptr %2
}

define internal void @arc_free.3(ptr %0) {
entry:
  %p = alloca ptr, align 8
  store ptr %0, ptr %p, align 8
  %_s = alloca %SysAlloc, align 8
  store %SysAlloc zeroinitializer, ptr %_s, align 1
  %p1 = load ptr, ptr %p, align 8
  call void @SysAlloc__NS_free_(ptr %_s, ptr %p1)
  ret void
}

define internal i64 @afmt_impl__NS_put(ptr %0, i64 %1, i64 %2, i8 %3) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %len = alloca i64, align 8
  store i64 %2, ptr %len, align 8
  %c = alloca i8, align 1
  store i8 %3, ptr %c, align 1
  %len1 = load i64, ptr %len, align 8
  %add = add i64 %len1, 1
  %cap2 = load i64, ptr %cap, align 8
  %icmp = icmp slt i64 %add, %cap2
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %len3 = load i64, ptr %len, align 8
  %ptr_load = load ptr, ptr %buf, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %len3
  %c4 = load i8, ptr %c, align 1
  store i8 %c4, ptr %ptr_gep, align 1
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  %len5 = load i64, ptr %len, align 8
  %add6 = add i64 %len5, 1
  ret i64 %add6
}

define internal i64 @afmt_impl__NS_put_str(ptr %0, i64 %1, i64 %2, ptr %3, i32 %4) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %len = alloca i64, align 8
  store i64 %2, ptr %len, align 8
  %s = alloca ptr, align 8
  store ptr %3, ptr %s, align 8
  %maxn = alloca i32, align 4
  store i32 %4, ptr %maxn, align 4
  %s1 = load ptr, ptr %s, align 8
  %icmp = icmp eq ptr %s1, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  store ptr @str, ptr %s, align 8
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  %n = alloca i64, align 8
  %len2 = load i64, ptr %len, align 8
  store i64 %len2, ptr %n, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge11, %if_merge
  %i3 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %s, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i3
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp4 = icmp ne i8 %idx_load, 0
  br i1 %icmp4, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %maxn5 = load i32, ptr %maxn, align 4
  %icmp6 = icmp sge i32 %maxn5, 0
  br i1 %icmp6, label %land_rhs, label %land_merge

while_exit:                                       ; preds = %if_then10, %while_cond
  %n20 = load i64, ptr %n, align 8
  ret i64 %n20

land_rhs:                                         ; preds = %while_body
  %i7 = load i32, ptr %i, align 4
  %maxn8 = load i32, ptr %maxn, align 4
  %icmp9 = icmp sge i32 %i7, %maxn8
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_body
  %land = phi i1 [ false, %while_body ], [ %icmp9, %land_rhs ]
  br i1 %land, label %if_then10, label %if_merge11

if_then10:                                        ; preds = %land_merge
  br label %while_exit

if_merge11:                                       ; preds = %land_merge
  %buf12 = load ptr, ptr %buf, align 8
  %cap13 = load i64, ptr %cap, align 8
  %n14 = load i64, ptr %n, align 8
  %i15 = load i32, ptr %i, align 4
  %ptr_load16 = load ptr, ptr %s, align 8
  %ptr_gep17 = getelementptr i8, ptr %ptr_load16, i32 %i15
  %idx_load18 = load i8, ptr %ptr_gep17, align 1
  %5 = call i64 @afmt_impl__NS_put(ptr %buf12, i64 %cap13, i64 %n14, i8 %idx_load18)
  store i64 %5, ptr %n, align 8
  %i19 = load i32, ptr %i, align 4
  %add = add i32 %i19, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond
}

define internal i64 @afmt_impl__NS_put_uint(ptr %0, i64 %1, i64 %2, i64 %3, i64 %4, i8 %5) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %len = alloca i64, align 8
  store i64 %2, ptr %len, align 8
  %v = alloca i64, align 8
  store i64 %3, ptr %v, align 8
  %base = alloca i64, align 8
  store i64 %4, ptr %base, align 8
  %upper = alloca i8, align 1
  store i8 %5, ptr %upper, align 1
  %tmp = alloca [32 x i8], align 1
  store [32 x i8] zeroinitializer, ptr %tmp, align 1
  %n = alloca i32, align 4
  store i32 0, ptr %n, align 4
  %v1 = load i64, ptr %v, align 8
  %icmp = icmp eq i64 %v1, 0
  br i1 %icmp, label %if_then, label %if_else

if_then:                                          ; preds = %entry
  %arr_gep = getelementptr [32 x i8], ptr %tmp, i64 0, i32 0
  store i8 48, ptr %arr_gep, align 1
  store i32 1, ptr %n, align 4
  br label %if_merge

if_else:                                          ; preds = %entry
  %x = alloca i64, align 8
  %v2 = load i64, ptr %v, align 8
  store i64 %v2, ptr %x, align 8
  br label %while_cond

if_merge:                                         ; preds = %while_exit, %if_then
  %out = alloca i64, align 8
  %len27 = load i64, ptr %len, align 8
  store i64 %len27, ptr %out, align 8
  %i = alloca i32, align 4
  %n28 = load i32, ptr %n, align 4
  %sub29 = sub i32 %n28, 1
  store i32 %sub29, ptr %i, align 4
  br label %while_cond30

while_cond:                                       ; preds = %tern_merge, %if_else
  %x3 = load i64, ptr %x, align 8
  %icmp4 = icmp ugt i64 %x3, 0
  br i1 %icmp4, label %land_rhs, label %land_merge

while_body:                                       ; preds = %land_merge
  %d = alloca i64, align 8
  %x7 = load i64, ptr %x, align 8
  %base8 = load i64, ptr %base, align 8
  %urem = urem i64 %x7, %base8
  store i64 %urem, ptr %d, align 8
  %c = alloca i8, align 1
  %d9 = load i64, ptr %d, align 8
  %icmp10 = icmp ult i64 %d9, 10
  br i1 %icmp10, label %tern_then, label %tern_else

while_exit:                                       ; preds = %land_merge
  br label %if_merge

land_rhs:                                         ; preds = %while_cond
  %n5 = load i32, ptr %n, align 4
  %icmp6 = icmp slt i32 %n5, 32
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond
  %land = phi i1 [ false, %while_cond ], [ %icmp6, %land_rhs ]
  br i1 %land, label %while_body, label %while_exit

tern_then:                                        ; preds = %while_body
  %d11 = load i64, ptr %d, align 8
  %add = add i64 48, %d11
  %trunc = trunc i64 %add to i8
  br label %tern_merge

tern_else:                                        ; preds = %while_body
  %upper12 = load i8, ptr %upper, align 1
  %tobool = icmp ne i8 %upper12, 0
  br i1 %tobool, label %tern_then13, label %tern_else14

tern_merge:                                       ; preds = %tern_merge15, %tern_then
  %tern19 = phi i8 [ %trunc, %tern_then ], [ %trunc18, %tern_merge15 ]
  store i8 %tern19, ptr %c, align 1
  %n20 = load i32, ptr %n, align 4
  %arr_gep21 = getelementptr [32 x i8], ptr %tmp, i64 0, i32 %n20
  %c22 = load i8, ptr %c, align 1
  store i8 %c22, ptr %arr_gep21, align 1
  %n23 = load i32, ptr %n, align 4
  %add24 = add i32 %n23, 1
  store i32 %add24, ptr %n, align 4
  %x25 = load i64, ptr %x, align 8
  %base26 = load i64, ptr %base, align 8
  %udiv = udiv i64 %x25, %base26
  store i64 %udiv, ptr %x, align 8
  br label %while_cond

tern_then13:                                      ; preds = %tern_else
  br label %tern_merge15

tern_else14:                                      ; preds = %tern_else
  br label %tern_merge15

tern_merge15:                                     ; preds = %tern_else14, %tern_then13
  %tern = phi i8 [ 65, %tern_then13 ], [ 97, %tern_else14 ]
  %zext = zext i8 %tern to i64
  %d16 = load i64, ptr %d, align 8
  %sub = sub i64 %d16, 10
  %add17 = add i64 %zext, %sub
  %trunc18 = trunc i64 %add17 to i8
  br label %tern_merge

while_cond30:                                     ; preds = %bounds_ok, %if_merge
  %i33 = load i32, ptr %i, align 4
  %icmp34 = icmp sge i32 %i33, 0
  br i1 %icmp34, label %while_body31, label %while_exit32

while_body31:                                     ; preds = %while_cond30
  %buf35 = load ptr, ptr %buf, align 8
  %cap36 = load i64, ptr %cap, align 8
  %out37 = load i64, ptr %out, align 8
  %i38 = load i32, ptr %i, align 4
  %idx64 = sext i32 %i38 to i64
  %oob_cmp = icmp uge i64 %idx64, 32
  br i1 %oob_cmp, label %oob_abort, label %bounds_ok

while_exit32:                                     ; preds = %while_cond30
  %out42 = load i64, ptr %out, align 8
  ret i64 %out42

oob_abort:                                        ; preds = %while_body31
  call void @abort()
  unreachable

bounds_ok:                                        ; preds = %while_body31
  %arr_gep39 = getelementptr [32 x i8], ptr %tmp, i64 0, i32 %i38
  %idx_load = load i8, ptr %arr_gep39, align 1
  %6 = call i64 @afmt_impl__NS_put(ptr %buf35, i64 %cap36, i64 %out37, i8 %idx_load)
  store i64 %6, ptr %out, align 8
  %i40 = load i32, ptr %i, align 4
  %sub41 = sub i32 %i40, 1
  store i32 %sub41, ptr %i, align 4
  br label %while_cond30
}

define internal i64 @afmt_impl__NS_put_int(ptr %0, i64 %1, i64 %2, i64 %3) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %len = alloca i64, align 8
  store i64 %2, ptr %len, align 8
  %v = alloca i64, align 8
  store i64 %3, ptr %v, align 8
  %out = alloca i64, align 8
  %len1 = load i64, ptr %len, align 8
  store i64 %len1, ptr %out, align 8
  %v2 = load i64, ptr %v, align 8
  %icmp = icmp slt i64 %v2, 0
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %buf3 = load ptr, ptr %buf, align 8
  %cap4 = load i64, ptr %cap, align 8
  %out5 = load i64, ptr %out, align 8
  %4 = call i64 @afmt_impl__NS_put(ptr %buf3, i64 %cap4, i64 %out5, i8 45)
  store i64 %4, ptr %out, align 8
  %mag = alloca i64, align 8
  %v6 = load i64, ptr %v, align 8
  %sub = sub i64 0, %v6
  store i64 %sub, ptr %mag, align 8
  %buf7 = load ptr, ptr %buf, align 8
  %cap8 = load i64, ptr %cap, align 8
  %out9 = load i64, ptr %out, align 8
  %mag10 = load i64, ptr %mag, align 8
  %5 = call i64 @afmt_impl__NS_put_uint(ptr %buf7, i64 %cap8, i64 %out9, i64 %mag10, i64 10, i8 0)
  ret i64 %5

if_merge:                                         ; preds = %entry
  %buf11 = load ptr, ptr %buf, align 8
  %cap12 = load i64, ptr %cap, align 8
  %out13 = load i64, ptr %out, align 8
  %v14 = load i64, ptr %v, align 8
  %6 = call i64 @afmt_impl__NS_put_uint(ptr %buf11, i64 %cap12, i64 %out13, i64 %v14, i64 10, i8 0)
  ret i64 %6
}

define internal i64 @afmt_impl__NS_put_f64(ptr %0, i64 %1, i64 %2, double %3) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %len = alloca i64, align 8
  store i64 %2, ptr %len, align 8
  %v = alloca double, align 8
  store double %3, ptr %v, align 8
  %out = alloca i64, align 8
  %len1 = load i64, ptr %len, align 8
  store i64 %len1, ptr %out, align 8
  %x = alloca double, align 8
  %v2 = load double, ptr %v, align 8
  store double %v2, ptr %x, align 8
  %x3 = load double, ptr %x, align 8
  %fcmp = fcmp olt double %x3, 0.000000e+00
  br i1 %fcmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %buf4 = load ptr, ptr %buf, align 8
  %cap5 = load i64, ptr %cap, align 8
  %out6 = load i64, ptr %out, align 8
  %4 = call i64 @afmt_impl__NS_put(ptr %buf4, i64 %cap5, i64 %out6, i8 45)
  store i64 %4, ptr %out, align 8
  %x7 = load double, ptr %x, align 8
  %fneg = fneg double %x7
  store double %fneg, ptr %x, align 8
  br label %if_merge

if_merge:                                         ; preds = %if_then, %entry
  %whole = alloca i64, align 8
  %x8 = load double, ptr %x, align 8
  %fptou = fptoui double %x8 to i64
  store i64 %fptou, ptr %whole, align 8
  %buf9 = load ptr, ptr %buf, align 8
  %cap10 = load i64, ptr %cap, align 8
  %out11 = load i64, ptr %out, align 8
  %whole12 = load i64, ptr %whole, align 8
  %5 = call i64 @afmt_impl__NS_put_uint(ptr %buf9, i64 %cap10, i64 %out11, i64 %whole12, i64 10, i8 0)
  store i64 %5, ptr %out, align 8
  %buf13 = load ptr, ptr %buf, align 8
  %cap14 = load i64, ptr %cap, align 8
  %out15 = load i64, ptr %out, align 8
  %6 = call i64 @afmt_impl__NS_put(ptr %buf13, i64 %cap14, i64 %out15, i8 46)
  store i64 %6, ptr %out, align 8
  %frac = alloca double, align 8
  %x16 = load double, ptr %x, align 8
  %whole17 = load i64, ptr %whole, align 8
  %sitofp = sitofp i64 %whole17 to double
  %fsub = fsub double %x16, %sitofp
  store double %fsub, ptr %frac, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge25, %if_merge
  %i18 = load i32, ptr %i, align 4
  %icmp = icmp slt i32 %i18, 6
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %frac19 = load double, ptr %frac, align 8
  %fmul = fmul double %frac19, 1.000000e+01
  store double %fmul, ptr %frac, align 8
  %d = alloca i64, align 8
  %frac20 = load double, ptr %frac, align 8
  %fptou21 = fptoui double %frac20 to i64
  store i64 %fptou21, ptr %d, align 8
  %d22 = load i64, ptr %d, align 8
  %icmp23 = icmp ugt i64 %d22, 9
  br i1 %icmp23, label %if_then24, label %if_merge25

while_exit:                                       ; preds = %while_cond
  %out36 = load i64, ptr %out, align 8
  ret i64 %out36

if_then24:                                        ; preds = %while_body
  store i64 9, ptr %d, align 8
  br label %if_merge25

if_merge25:                                       ; preds = %if_then24, %while_body
  %buf26 = load ptr, ptr %buf, align 8
  %cap27 = load i64, ptr %cap, align 8
  %out28 = load i64, ptr %out, align 8
  %d29 = load i64, ptr %d, align 8
  %add = add i64 48, %d29
  %trunc = trunc i64 %add to i8
  %7 = call i64 @afmt_impl__NS_put(ptr %buf26, i64 %cap27, i64 %out28, i8 %trunc)
  store i64 %7, ptr %out, align 8
  %frac30 = load double, ptr %frac, align 8
  %d31 = load i64, ptr %d, align 8
  %sitofp32 = sitofp i64 %d31 to double
  %fsub33 = fsub double %frac30, %sitofp32
  store double %fsub33, ptr %frac, align 8
  %i34 = load i32, ptr %i, align 4
  %add35 = add i32 %i34, 1
  store i32 %add35, ptr %i, align 4
  br label %while_cond
}

declare void @abort()

define internal i32 @afmt_v(ptr %0, i64 %1, ptr %2, ptr %3, ptr %4, i32 %5) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %fmt = alloca ptr, align 8
  store ptr %2, ptr %fmt, align 8
  %argp = alloca ptr, align 8
  store ptr %3, ptr %argp, align 8
  %fields = alloca ptr, align 8
  store ptr %4, ptr %fields, align 8
  %nfields = alloca i32, align 4
  store i32 %5, ptr %nfields, align 4
  %len = alloca i64, align 8
  store i64 0, ptr %len, align 8
  %ai = alloca i32, align 4
  store i32 0, ptr %ai, align 4
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge189, %if_then157, %if_then22, %if_then, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %fmt, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i1
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp ne i8 %idx_load, 0
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i2 = load i32, ptr %i, align 4
  %ptr_load3 = load ptr, ptr %fmt, align 8
  %ptr_gep4 = getelementptr i8, ptr %ptr_load3, i32 %i2
  %idx_load5 = load i8, ptr %ptr_gep4, align 1
  %icmp6 = icmp ne i8 %idx_load5, 37
  br i1 %icmp6, label %if_then, label %if_merge

while_exit:                                       ; preds = %if_then150, %while_cond
  %cap336 = load i64, ptr %cap, align 8
  %icmp337 = icmp ugt i64 %cap336, 0
  br i1 %icmp337, label %if_then338, label %if_merge339

if_then:                                          ; preds = %while_body
  %buf7 = load ptr, ptr %buf, align 8
  %cap8 = load i64, ptr %cap, align 8
  %len9 = load i64, ptr %len, align 8
  %i10 = load i32, ptr %i, align 4
  %ptr_load11 = load ptr, ptr %fmt, align 8
  %ptr_gep12 = getelementptr i8, ptr %ptr_load11, i32 %i10
  %idx_load13 = load i8, ptr %ptr_gep12, align 1
  %6 = call i64 @afmt_impl__NS_put(ptr %buf7, i64 %cap8, i64 %len9, i8 %idx_load13)
  store i64 %6, ptr %len, align 8
  %i14 = load i32, ptr %i, align 4
  %add = add i32 %i14, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond

if_merge:                                         ; preds = %while_body
  %i15 = load i32, ptr %i, align 4
  %add16 = add i32 %i15, 1
  store i32 %add16, ptr %i, align 4
  %i17 = load i32, ptr %i, align 4
  %ptr_load18 = load ptr, ptr %fmt, align 8
  %ptr_gep19 = getelementptr i8, ptr %ptr_load18, i32 %i17
  %idx_load20 = load i8, ptr %ptr_gep19, align 1
  %icmp21 = icmp eq i8 %idx_load20, 37
  br i1 %icmp21, label %if_then22, label %if_merge23

if_then22:                                        ; preds = %if_merge
  %buf24 = load ptr, ptr %buf, align 8
  %cap25 = load i64, ptr %cap, align 8
  %len26 = load i64, ptr %len, align 8
  %7 = call i64 @afmt_impl__NS_put(ptr %buf24, i64 %cap25, i64 %len26, i8 37)
  store i64 %7, ptr %len, align 8
  %i27 = load i32, ptr %i, align 4
  %add28 = add i32 %i27, 1
  store i32 %add28, ptr %i, align 4
  br label %while_cond

if_merge23:                                       ; preds = %if_merge
  %prec = alloca i32, align 4
  store i32 -1, ptr %prec, align 4
  br label %while_cond29

while_cond29:                                     ; preds = %while_body30, %if_merge23
  %i32 = load i32, ptr %i, align 4
  %ptr_load33 = load ptr, ptr %fmt, align 8
  %ptr_gep34 = getelementptr i8, ptr %ptr_load33, i32 %i32
  %idx_load35 = load i8, ptr %ptr_gep34, align 1
  %icmp36 = icmp sge i8 %idx_load35, 48
  br i1 %icmp36, label %land_rhs, label %land_merge

while_body30:                                     ; preds = %lor_merge48
  %i55 = load i32, ptr %i, align 4
  %add56 = add i32 %i55, 1
  store i32 %add56, ptr %i, align 4
  br label %while_cond29

while_exit31:                                     ; preds = %lor_merge48
  %i57 = load i32, ptr %i, align 4
  %ptr_load58 = load ptr, ptr %fmt, align 8
  %ptr_gep59 = getelementptr i8, ptr %ptr_load58, i32 %i57
  %idx_load60 = load i8, ptr %ptr_gep59, align 1
  %icmp61 = icmp eq i8 %idx_load60, 46
  br i1 %icmp61, label %if_then62, label %if_merge63

land_rhs:                                         ; preds = %while_cond29
  %i37 = load i32, ptr %i, align 4
  %ptr_load38 = load ptr, ptr %fmt, align 8
  %ptr_gep39 = getelementptr i8, ptr %ptr_load38, i32 %i37
  %idx_load40 = load i8, ptr %ptr_gep39, align 1
  %icmp41 = icmp sle i8 %idx_load40, 57
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond29
  %land = phi i1 [ false, %while_cond29 ], [ %icmp41, %land_rhs ]
  br i1 %land, label %lor_merge, label %lor_rhs

lor_rhs:                                          ; preds = %land_merge
  %i42 = load i32, ptr %i, align 4
  %ptr_load43 = load ptr, ptr %fmt, align 8
  %ptr_gep44 = getelementptr i8, ptr %ptr_load43, i32 %i42
  %idx_load45 = load i8, ptr %ptr_gep44, align 1
  %icmp46 = icmp eq i8 %idx_load45, 45
  br label %lor_merge

lor_merge:                                        ; preds = %lor_rhs, %land_merge
  %lor = phi i1 [ true, %land_merge ], [ %icmp46, %lor_rhs ]
  br i1 %lor, label %lor_merge48, label %lor_rhs47

lor_rhs47:                                        ; preds = %lor_merge
  %i49 = load i32, ptr %i, align 4
  %ptr_load50 = load ptr, ptr %fmt, align 8
  %ptr_gep51 = getelementptr i8, ptr %ptr_load50, i32 %i49
  %idx_load52 = load i8, ptr %ptr_gep51, align 1
  %icmp53 = icmp eq i8 %idx_load52, 43
  br label %lor_merge48

lor_merge48:                                      ; preds = %lor_rhs47, %lor_merge
  %lor54 = phi i1 [ true, %lor_merge ], [ %icmp53, %lor_rhs47 ]
  br i1 %lor54, label %while_body30, label %while_exit31

if_then62:                                        ; preds = %while_exit31
  %i64 = load i32, ptr %i, align 4
  %add65 = add i32 %i64, 1
  store i32 %add65, ptr %i, align 4
  %i66 = load i32, ptr %i, align 4
  %ptr_load67 = load ptr, ptr %fmt, align 8
  %ptr_gep68 = getelementptr i8, ptr %ptr_load67, i32 %i66
  %idx_load69 = load i8, ptr %ptr_gep68, align 1
  %icmp70 = icmp eq i8 %idx_load69, 42
  br i1 %icmp70, label %if_then71, label %if_else

if_merge63:                                       ; preds = %if_merge72, %while_exit31
  %long_n = alloca i32, align 4
  store i32 0, ptr %long_n, align 4
  br label %while_cond114

if_then71:                                        ; preds = %if_then62
  %i73 = load i32, ptr %i, align 4
  %add74 = add i32 %i73, 1
  store i32 %add74, ptr %i, align 4
  %ai75 = load i32, ptr %ai, align 4
  %nfields76 = load i32, ptr %nfields, align 4
  %icmp77 = icmp slt i32 %ai75, %nfields76
  br i1 %icmp77, label %if_then78, label %if_merge79

if_else:                                          ; preds = %if_then62
  store i32 0, ptr %prec, align 4
  br label %while_cond90

if_merge72:                                       ; preds = %while_exit92, %if_merge79
  br label %if_merge63

if_then78:                                        ; preds = %if_then71
  %pp = alloca ptr, align 8
  %argp80 = load ptr, ptr %argp, align 8
  %ai81 = load i32, ptr %ai, align 4
  %ptr_load82 = load ptr, ptr %fields, align 8
  %ptr_gep83 = getelementptr %type_info_field, ptr %ptr_load82, i32 %ai81
  %offset = getelementptr inbounds nuw %type_info_field, ptr %ptr_gep83, i32 0, i32 1
  %ai84 = load i32, ptr %ai, align 4
  %ptr_load85 = load ptr, ptr %fields, align 8
  %ptr_gep86 = getelementptr %type_info_field, ptr %ptr_load85, i32 %ai84
  %mem_load = load i32, ptr %offset, align 4
  %ptr_add = getelementptr i8, ptr %argp80, i32 %mem_load
  store ptr %ptr_add, ptr %pp, align 8
  %pp87 = load ptr, ptr %pp, align 8
  %deref = load i32, ptr %pp87, align 4
  store i32 %deref, ptr %prec, align 4
  %ai88 = load i32, ptr %ai, align 4
  %add89 = add i32 %ai88, 1
  store i32 %add89, ptr %ai, align 4
  br label %if_merge79

if_merge79:                                       ; preds = %if_then78, %if_then71
  br label %if_merge72

while_cond90:                                     ; preds = %while_body91, %if_else
  %i93 = load i32, ptr %i, align 4
  %ptr_load94 = load ptr, ptr %fmt, align 8
  %ptr_gep95 = getelementptr i8, ptr %ptr_load94, i32 %i93
  %idx_load96 = load i8, ptr %ptr_gep95, align 1
  %icmp97 = icmp sge i8 %idx_load96, 48
  br i1 %icmp97, label %land_rhs98, label %land_merge99

while_body91:                                     ; preds = %land_merge99
  %prec106 = load i32, ptr %prec, align 4
  %mul = mul i32 %prec106, 10
  %i107 = load i32, ptr %i, align 4
  %ptr_load108 = load ptr, ptr %fmt, align 8
  %ptr_gep109 = getelementptr i8, ptr %ptr_load108, i32 %i107
  %idx_load110 = load i8, ptr %ptr_gep109, align 1
  %sub = sub i8 %idx_load110, 48
  %sext = sext i8 %sub to i32
  %add111 = add i32 %mul, %sext
  store i32 %add111, ptr %prec, align 4
  %i112 = load i32, ptr %i, align 4
  %add113 = add i32 %i112, 1
  store i32 %add113, ptr %i, align 4
  br label %while_cond90

while_exit92:                                     ; preds = %land_merge99
  br label %if_merge72

land_rhs98:                                       ; preds = %while_cond90
  %i100 = load i32, ptr %i, align 4
  %ptr_load101 = load ptr, ptr %fmt, align 8
  %ptr_gep102 = getelementptr i8, ptr %ptr_load101, i32 %i100
  %idx_load103 = load i8, ptr %ptr_gep102, align 1
  %icmp104 = icmp sle i8 %idx_load103, 57
  br label %land_merge99

land_merge99:                                     ; preds = %land_rhs98, %while_cond90
  %land105 = phi i1 [ false, %while_cond90 ], [ %icmp104, %land_rhs98 ]
  br i1 %land105, label %while_body91, label %while_exit92

while_cond114:                                    ; preds = %while_body115, %if_merge63
  %i117 = load i32, ptr %i, align 4
  %ptr_load118 = load ptr, ptr %fmt, align 8
  %ptr_gep119 = getelementptr i8, ptr %ptr_load118, i32 %i117
  %idx_load120 = load i8, ptr %ptr_gep119, align 1
  %icmp121 = icmp eq i8 %idx_load120, 108
  br i1 %icmp121, label %while_body115, label %while_exit116

while_body115:                                    ; preds = %while_cond114
  %long_n122 = load i32, ptr %long_n, align 4
  %add123 = add i32 %long_n122, 1
  store i32 %add123, ptr %long_n, align 4
  %i124 = load i32, ptr %i, align 4
  %add125 = add i32 %i124, 1
  store i32 %add125, ptr %i, align 4
  br label %while_cond114

while_exit116:                                    ; preds = %while_cond114
  br label %while_cond126

while_cond126:                                    ; preds = %while_body127, %while_exit116
  %i129 = load i32, ptr %i, align 4
  %ptr_load130 = load ptr, ptr %fmt, align 8
  %ptr_gep131 = getelementptr i8, ptr %ptr_load130, i32 %i129
  %idx_load132 = load i8, ptr %ptr_gep131, align 1
  %icmp133 = icmp eq i8 %idx_load132, 104
  br i1 %icmp133, label %lor_merge135, label %lor_rhs134

while_body127:                                    ; preds = %lor_merge135
  %i142 = load i32, ptr %i, align 4
  %add143 = add i32 %i142, 1
  store i32 %add143, ptr %i, align 4
  br label %while_cond126

while_exit128:                                    ; preds = %lor_merge135
  %conv = alloca i8, align 1
  %i144 = load i32, ptr %i, align 4
  %ptr_load145 = load ptr, ptr %fmt, align 8
  %ptr_gep146 = getelementptr i8, ptr %ptr_load145, i32 %i144
  %idx_load147 = load i8, ptr %ptr_gep146, align 1
  store i8 %idx_load147, ptr %conv, align 1
  %conv148 = load i8, ptr %conv, align 1
  %icmp149 = icmp eq i8 %conv148, 0
  br i1 %icmp149, label %if_then150, label %if_merge151

lor_rhs134:                                       ; preds = %while_cond126
  %i136 = load i32, ptr %i, align 4
  %ptr_load137 = load ptr, ptr %fmt, align 8
  %ptr_gep138 = getelementptr i8, ptr %ptr_load137, i32 %i136
  %idx_load139 = load i8, ptr %ptr_gep138, align 1
  %icmp140 = icmp eq i8 %idx_load139, 122
  br label %lor_merge135

lor_merge135:                                     ; preds = %lor_rhs134, %while_cond126
  %lor141 = phi i1 [ true, %while_cond126 ], [ %icmp140, %lor_rhs134 ]
  br i1 %lor141, label %while_body127, label %while_exit128

if_then150:                                       ; preds = %while_exit128
  br label %while_exit

if_merge151:                                      ; preds = %while_exit128
  %i152 = load i32, ptr %i, align 4
  %add153 = add i32 %i152, 1
  store i32 %add153, ptr %i, align 4
  %ai154 = load i32, ptr %ai, align 4
  %nfields155 = load i32, ptr %nfields, align 4
  %icmp156 = icmp sge i32 %ai154, %nfields155
  br i1 %icmp156, label %if_then157, label %if_merge158

if_then157:                                       ; preds = %if_merge151
  %buf159 = load ptr, ptr %buf, align 8
  %cap160 = load i64, ptr %cap, align 8
  %len161 = load i64, ptr %len, align 8
  %8 = call i64 @afmt_impl__NS_put(ptr %buf159, i64 %cap160, i64 %len161, i8 37)
  store i64 %8, ptr %len, align 8
  %buf162 = load ptr, ptr %buf, align 8
  %cap163 = load i64, ptr %cap, align 8
  %len164 = load i64, ptr %len, align 8
  %conv165 = load i8, ptr %conv, align 1
  %9 = call i64 @afmt_impl__NS_put(ptr %buf162, i64 %cap163, i64 %len164, i8 %conv165)
  store i64 %9, ptr %len, align 8
  br label %while_cond

if_merge158:                                      ; preds = %if_merge151
  %off = alloca ptr, align 8
  %argp166 = load ptr, ptr %argp, align 8
  %ai167 = load i32, ptr %ai, align 4
  %ptr_load168 = load ptr, ptr %fields, align 8
  %ptr_gep169 = getelementptr %type_info_field, ptr %ptr_load168, i32 %ai167
  %offset170 = getelementptr inbounds nuw %type_info_field, ptr %ptr_gep169, i32 0, i32 1
  %ai171 = load i32, ptr %ai, align 4
  %ptr_load172 = load ptr, ptr %fields, align 8
  %ptr_gep173 = getelementptr %type_info_field, ptr %ptr_load172, i32 %ai171
  %mem_load174 = load i32, ptr %offset170, align 4
  %ptr_add175 = getelementptr i8, ptr %argp166, i32 %mem_load174
  store ptr %ptr_add175, ptr %off, align 8
  %fsz = alloca i32, align 4
  %ai176 = load i32, ptr %ai, align 4
  %ptr_load177 = load ptr, ptr %fields, align 8
  %ptr_gep178 = getelementptr %type_info_field, ptr %ptr_load177, i32 %ai176
  %size = getelementptr inbounds nuw %type_info_field, ptr %ptr_gep178, i32 0, i32 2
  %ai179 = load i32, ptr %ai, align 4
  %ptr_load180 = load ptr, ptr %fields, align 8
  %ptr_gep181 = getelementptr %type_info_field, ptr %ptr_load180, i32 %ai179
  %mem_load182 = load i32, ptr %size, align 4
  store i32 %mem_load182, ptr %fsz, align 4
  %ai183 = load i32, ptr %ai, align 4
  %add184 = add i32 %ai183, 1
  store i32 %add184, ptr %ai, align 4
  %conv185 = load i8, ptr %conv, align 1
  %icmp186 = icmp eq i8 %conv185, 115
  br i1 %icmp186, label %if_then187, label %if_else188

if_then187:                                       ; preds = %if_merge158
  %sp = alloca ptr, align 8
  %off190 = load ptr, ptr %off, align 8
  store ptr %off190, ptr %sp, align 8
  %buf191 = load ptr, ptr %buf, align 8
  %cap192 = load i64, ptr %cap, align 8
  %len193 = load i64, ptr %len, align 8
  %sp194 = load ptr, ptr %sp, align 8
  %deref195 = load ptr, ptr %sp194, align 8
  %prec196 = load i32, ptr %prec, align 4
  %10 = call i64 @afmt_impl__NS_put_str(ptr %buf191, i64 %cap192, i64 %len193, ptr %deref195, i32 %prec196)
  store i64 %10, ptr %len, align 8
  br label %if_merge189

if_else188:                                       ; preds = %if_merge158
  %conv197 = load i8, ptr %conv, align 1
  %icmp198 = icmp eq i8 %conv197, 100
  br i1 %icmp198, label %lor_merge200, label %lor_rhs199

if_merge189:                                      ; preds = %if_merge206, %if_then187
  br label %while_cond

lor_rhs199:                                       ; preds = %if_else188
  %conv201 = load i8, ptr %conv, align 1
  %icmp202 = icmp eq i8 %conv201, 105
  br label %lor_merge200

lor_merge200:                                     ; preds = %lor_rhs199, %if_else188
  %lor203 = phi i1 [ true, %if_else188 ], [ %icmp202, %lor_rhs199 ]
  br i1 %lor203, label %if_then204, label %if_else205

if_then204:                                       ; preds = %lor_merge200
  %v = alloca i64, align 8
  %long_n207 = load i32, ptr %long_n, align 4
  %icmp208 = icmp sgt i32 %long_n207, 0
  br i1 %icmp208, label %lor_merge210, label %lor_rhs209

if_else205:                                       ; preds = %lor_merge200
  %conv223 = load i8, ptr %conv, align 1
  %icmp224 = icmp eq i8 %conv223, 117
  br i1 %icmp224, label %if_then225, label %if_else226

if_merge206:                                      ; preds = %if_merge227, %tern_merge
  br label %if_merge189

lor_rhs209:                                       ; preds = %if_then204
  %fsz211 = load i32, ptr %fsz, align 4
  %icmp212 = icmp eq i32 %fsz211, 8
  br label %lor_merge210

lor_merge210:                                     ; preds = %lor_rhs209, %if_then204
  %lor213 = phi i1 [ true, %if_then204 ], [ %icmp212, %lor_rhs209 ]
  br i1 %lor213, label %tern_then, label %tern_else

tern_then:                                        ; preds = %lor_merge210
  %off214 = load ptr, ptr %off, align 8
  %deref215 = load i64, ptr %off214, align 8
  br label %tern_merge

tern_else:                                        ; preds = %lor_merge210
  %off216 = load ptr, ptr %off, align 8
  %deref217 = load i32, ptr %off216, align 4
  %sext218 = sext i32 %deref217 to i64
  br label %tern_merge

tern_merge:                                       ; preds = %tern_else, %tern_then
  %tern = phi i64 [ %deref215, %tern_then ], [ %sext218, %tern_else ]
  store i64 %tern, ptr %v, align 8
  %buf219 = load ptr, ptr %buf, align 8
  %cap220 = load i64, ptr %cap, align 8
  %len221 = load i64, ptr %len, align 8
  %v222 = load i64, ptr %v, align 8
  %11 = call i64 @afmt_impl__NS_put_int(ptr %buf219, i64 %cap220, i64 %len221, i64 %v222)
  store i64 %11, ptr %len, align 8
  br label %if_merge206

if_then225:                                       ; preds = %if_else205
  %v228 = alloca i64, align 8
  %long_n229 = load i32, ptr %long_n, align 4
  %icmp230 = icmp sgt i32 %long_n229, 0
  br i1 %icmp230, label %lor_merge232, label %lor_rhs231

if_else226:                                       ; preds = %if_else205
  %conv248 = load i8, ptr %conv, align 1
  %icmp249 = icmp eq i8 %conv248, 120
  br i1 %icmp249, label %lor_merge251, label %lor_rhs250

if_merge227:                                      ; preds = %if_merge257, %tern_merge238
  br label %if_merge206

lor_rhs231:                                       ; preds = %if_then225
  %fsz233 = load i32, ptr %fsz, align 4
  %icmp234 = icmp eq i32 %fsz233, 8
  br label %lor_merge232

lor_merge232:                                     ; preds = %lor_rhs231, %if_then225
  %lor235 = phi i1 [ true, %if_then225 ], [ %icmp234, %lor_rhs231 ]
  br i1 %lor235, label %tern_then236, label %tern_else237

tern_then236:                                     ; preds = %lor_merge232
  %off239 = load ptr, ptr %off, align 8
  %deref240 = load i64, ptr %off239, align 8
  br label %tern_merge238

tern_else237:                                     ; preds = %lor_merge232
  %off241 = load ptr, ptr %off, align 8
  %deref242 = load i32, ptr %off241, align 4
  %zext = zext i32 %deref242 to i64
  br label %tern_merge238

tern_merge238:                                    ; preds = %tern_else237, %tern_then236
  %tern243 = phi i64 [ %deref240, %tern_then236 ], [ %zext, %tern_else237 ]
  store i64 %tern243, ptr %v228, align 8
  %buf244 = load ptr, ptr %buf, align 8
  %cap245 = load i64, ptr %cap, align 8
  %len246 = load i64, ptr %len, align 8
  %v247 = load i64, ptr %v228, align 8
  %12 = call i64 @afmt_impl__NS_put_uint(ptr %buf244, i64 %cap245, i64 %len246, i64 %v247, i64 10, i8 0)
  store i64 %12, ptr %len, align 8
  br label %if_merge227

lor_rhs250:                                       ; preds = %if_else226
  %conv252 = load i8, ptr %conv, align 1
  %icmp253 = icmp eq i8 %conv252, 88
  br label %lor_merge251

lor_merge251:                                     ; preds = %lor_rhs250, %if_else226
  %lor254 = phi i1 [ true, %if_else226 ], [ %icmp253, %lor_rhs250 ]
  br i1 %lor254, label %if_then255, label %if_else256

if_then255:                                       ; preds = %lor_merge251
  %v258 = alloca i64, align 8
  %long_n259 = load i32, ptr %long_n, align 4
  %icmp260 = icmp sgt i32 %long_n259, 0
  br i1 %icmp260, label %lor_merge262, label %lor_rhs261

if_else256:                                       ; preds = %lor_merge251
  %conv282 = load i8, ptr %conv, align 1
  %icmp283 = icmp eq i8 %conv282, 99
  br i1 %icmp283, label %if_then284, label %if_else285

if_merge257:                                      ; preds = %if_merge286, %tern_merge268
  br label %if_merge227

lor_rhs261:                                       ; preds = %if_then255
  %fsz263 = load i32, ptr %fsz, align 4
  %icmp264 = icmp eq i32 %fsz263, 8
  br label %lor_merge262

lor_merge262:                                     ; preds = %lor_rhs261, %if_then255
  %lor265 = phi i1 [ true, %if_then255 ], [ %icmp264, %lor_rhs261 ]
  br i1 %lor265, label %tern_then266, label %tern_else267

tern_then266:                                     ; preds = %lor_merge262
  %off269 = load ptr, ptr %off, align 8
  %deref270 = load i64, ptr %off269, align 8
  br label %tern_merge268

tern_else267:                                     ; preds = %lor_merge262
  %off271 = load ptr, ptr %off, align 8
  %deref272 = load i32, ptr %off271, align 4
  %zext273 = zext i32 %deref272 to i64
  br label %tern_merge268

tern_merge268:                                    ; preds = %tern_else267, %tern_then266
  %tern274 = phi i64 [ %deref270, %tern_then266 ], [ %zext273, %tern_else267 ]
  store i64 %tern274, ptr %v258, align 8
  %buf275 = load ptr, ptr %buf, align 8
  %cap276 = load i64, ptr %cap, align 8
  %len277 = load i64, ptr %len, align 8
  %v278 = load i64, ptr %v258, align 8
  %conv279 = load i8, ptr %conv, align 1
  %icmp280 = icmp eq i8 %conv279, 88
  %zext281 = zext i1 %icmp280 to i8
  %13 = call i64 @afmt_impl__NS_put_uint(ptr %buf275, i64 %cap276, i64 %len277, i64 %v278, i64 16, i8 %zext281)
  store i64 %13, ptr %len, align 8
  br label %if_merge257

if_then284:                                       ; preds = %if_else256
  %buf287 = load ptr, ptr %buf, align 8
  %cap288 = load i64, ptr %cap, align 8
  %len289 = load i64, ptr %len, align 8
  %off290 = load ptr, ptr %off, align 8
  %deref291 = load i32, ptr %off290, align 4
  %trunc = trunc i32 %deref291 to i8
  %14 = call i64 @afmt_impl__NS_put(ptr %buf287, i64 %cap288, i64 %len289, i8 %trunc)
  store i64 %14, ptr %len, align 8
  br label %if_merge286

if_else285:                                       ; preds = %if_else256
  %conv292 = load i8, ptr %conv, align 1
  %icmp293 = icmp eq i8 %conv292, 102
  br i1 %icmp293, label %lor_merge295, label %lor_rhs294

if_merge286:                                      ; preds = %if_merge306, %if_then284
  br label %if_merge257

lor_rhs294:                                       ; preds = %if_else285
  %conv296 = load i8, ptr %conv, align 1
  %icmp297 = icmp eq i8 %conv296, 103
  br label %lor_merge295

lor_merge295:                                     ; preds = %lor_rhs294, %if_else285
  %lor298 = phi i1 [ true, %if_else285 ], [ %icmp297, %lor_rhs294 ]
  br i1 %lor298, label %lor_merge300, label %lor_rhs299

lor_rhs299:                                       ; preds = %lor_merge295
  %conv301 = load i8, ptr %conv, align 1
  %icmp302 = icmp eq i8 %conv301, 101
  br label %lor_merge300

lor_merge300:                                     ; preds = %lor_rhs299, %lor_merge295
  %lor303 = phi i1 [ true, %lor_merge295 ], [ %icmp302, %lor_rhs299 ]
  br i1 %lor303, label %if_then304, label %if_else305

if_then304:                                       ; preds = %lor_merge300
  %buf307 = load ptr, ptr %buf, align 8
  %cap308 = load i64, ptr %cap, align 8
  %len309 = load i64, ptr %len, align 8
  %off310 = load ptr, ptr %off, align 8
  %deref311 = load double, ptr %off310, align 8
  %15 = call i64 @afmt_impl__NS_put_f64(ptr %buf307, i64 %cap308, i64 %len309, double %deref311)
  store i64 %15, ptr %len, align 8
  br label %if_merge306

if_else305:                                       ; preds = %lor_merge300
  %conv312 = load i8, ptr %conv, align 1
  %icmp313 = icmp eq i8 %conv312, 112
  br i1 %icmp313, label %if_then314, label %if_else315

if_merge306:                                      ; preds = %if_merge316, %if_then304
  br label %if_merge286

if_then314:                                       ; preds = %if_else305
  %pv = alloca ptr, align 8
  %off317 = load ptr, ptr %off, align 8
  %deref318 = load ptr, ptr %off317, align 8
  store ptr %deref318, ptr %pv, align 8
  %buf319 = load ptr, ptr %buf, align 8
  %cap320 = load i64, ptr %cap, align 8
  %len321 = load i64, ptr %len, align 8
  %16 = call i64 @afmt_impl__NS_put(ptr %buf319, i64 %cap320, i64 %len321, i8 48)
  store i64 %16, ptr %len, align 8
  %buf322 = load ptr, ptr %buf, align 8
  %cap323 = load i64, ptr %cap, align 8
  %len324 = load i64, ptr %len, align 8
  %17 = call i64 @afmt_impl__NS_put(ptr %buf322, i64 %cap323, i64 %len324, i8 120)
  store i64 %17, ptr %len, align 8
  %buf325 = load ptr, ptr %buf, align 8
  %cap326 = load i64, ptr %cap, align 8
  %len327 = load i64, ptr %len, align 8
  %pv328 = load ptr, ptr %pv, align 8
  %p2i = ptrtoint ptr %pv328 to i64
  %18 = call i64 @afmt_impl__NS_put_uint(ptr %buf325, i64 %cap326, i64 %len327, i64 %p2i, i64 16, i8 0)
  store i64 %18, ptr %len, align 8
  br label %if_merge316

if_else315:                                       ; preds = %if_else305
  %buf329 = load ptr, ptr %buf, align 8
  %cap330 = load i64, ptr %cap, align 8
  %len331 = load i64, ptr %len, align 8
  %19 = call i64 @afmt_impl__NS_put(ptr %buf329, i64 %cap330, i64 %len331, i8 37)
  store i64 %19, ptr %len, align 8
  %buf332 = load ptr, ptr %buf, align 8
  %cap333 = load i64, ptr %cap, align 8
  %len334 = load i64, ptr %len, align 8
  %conv335 = load i8, ptr %conv, align 1
  %20 = call i64 @afmt_impl__NS_put(ptr %buf332, i64 %cap333, i64 %len334, i8 %conv335)
  store i64 %20, ptr %len, align 8
  br label %if_merge316

if_merge316:                                      ; preds = %if_else315, %if_then314
  br label %if_merge306

if_then338:                                       ; preds = %while_exit
  %term = alloca i64, align 8
  %len340 = load i64, ptr %len, align 8
  %cap341 = load i64, ptr %cap, align 8
  %icmp342 = icmp ult i64 %len340, %cap341
  br i1 %icmp342, label %tern_then343, label %tern_else344

if_merge339:                                      ; preds = %tern_merge345, %while_exit
  %len353 = load i64, ptr %len, align 8
  %trunc354 = trunc i64 %len353 to i32
  ret i32 %trunc354

tern_then343:                                     ; preds = %if_then338
  %len346 = load i64, ptr %len, align 8
  br label %tern_merge345

tern_else344:                                     ; preds = %if_then338
  %cap347 = load i64, ptr %cap, align 8
  %sub348 = sub i64 %cap347, 1
  br label %tern_merge345

tern_merge345:                                    ; preds = %tern_else344, %tern_then343
  %tern349 = phi i64 [ %len346, %tern_then343 ], [ %sub348, %tern_else344 ]
  store i64 %tern349, ptr %term, align 8
  %term350 = load i64, ptr %term, align 8
  %ptr_load351 = load ptr, ptr %buf, align 8
  %ptr_gep352 = getelementptr i8, ptr %ptr_load351, i64 %term350
  store i8 0, ptr %ptr_gep352, align 1
  br label %if_merge339
}

define internal void @demo__NS_go(ptr %0, i32 %1) {
entry:
  %name = alloca ptr, align 8
  store ptr %0, ptr %name, align 8
  %line = alloca i32, align 4
  store i32 %1, ptr %line, align 4
  %b = alloca [512 x i8], align 1
  store [512 x i8] zeroinitializer, ptr %b, align 1
  %arr_decay = getelementptr [512 x i8], ptr %b, i64 0, i64 0
  %name1 = load ptr, ptr %name, align 8
  %line2 = load i32, ptr %line, align 4
  %anon_s = alloca %__anon2_P_i32, align 8
  %anon_f = getelementptr inbounds nuw %__anon2_P_i32, ptr %anon_s, i32 0, i32 0
  store ptr %name1, ptr %anon_f, align 8
  %anon_f3 = getelementptr inbounds nuw %__anon2_P_i32, ptr %anon_s, i32 0, i32 1
  store i32 %line2, ptr %anon_f3, align 4
  %anon_load = load %__anon2_P_i32, ptr %anon_s, align 8
  %2 = call i32 @afmt__at_args_S__anon2_P_i32(ptr %arr_decay, i64 512, ptr @str.4, %__anon2_P_i32 %anon_load)
  %arr_decay4 = getelementptr [512 x i8], ptr %b, i64 0, i64 0
  %anon_s5 = alloca %__anon1_P, align 8
  %anon_f6 = getelementptr inbounds nuw %__anon1_P, ptr %anon_s5, i32 0, i32 0
  store ptr %arr_decay4, ptr %anon_f6, align 8
  %anon_load7 = load %__anon1_P, ptr %anon_s5, align 8
  %3 = call i32 @aprint__at_args_S__anon1_P(ptr @str.5, %__anon1_P %anon_load7)
  %4 = call i32 @aprint__at_args_S__anon0(ptr @str.6, %__anon0 undef)
  ret void
}

define internal i32 @afmt__at_args_S__anon2_P_i32(ptr %0, i64 %1, ptr %2, %__anon2_P_i32 %3) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %fmt = alloca ptr, align 8
  store ptr %2, ptr %fmt, align 8
  %args = alloca %__anon2_P_i32, align 8
  store %__anon2_P_i32 %3, ptr %args, align 8
  %ti = alloca ptr, align 8
  store ptr @__typeinfo___anon2_P_i32, ptr %ti, align 8
  %ti1 = load ptr, ptr %ti, align 8
  %deref = load %type_info, ptr %ti1, align 4
  %__tag_x = extractvalue %type_info %deref, 0
  %vtag = load i32, ptr @type_info__Struct, align 4
  %tag_cmp = icmp eq i32 %__tag_x, %vtag
  %enum_tmp = alloca %type_info, align 8
  store %type_info %deref, ptr %enum_tmp, align 4
  %pay_p3 = getelementptr inbounds nuw %type_info, ptr %enum_tmp, i32 0, i32 1
  %fptr3 = getelementptr i8, ptr %pay_p3, i64 0
  %vf_x3 = load ptr, ptr %fptr3, align 8
  %nm = alloca ptr, align 8
  store ptr %vf_x3, ptr %nm, align 8
  %vf_and = and i1 %tag_cmp, true
  %fptr32 = getelementptr i8, ptr %pay_p3, i64 8
  %vf_x33 = load ptr, ptr %fptr32, align 8
  %flds = alloca ptr, align 8
  store ptr %vf_x33, ptr %flds, align 8
  %vf_and4 = and i1 %vf_and, true
  %fptr35 = getelementptr i8, ptr %pay_p3, i64 16
  %vf_x36 = load i64, ptr %fptr35, align 8
  %nf = alloca i64, align 8
  store i64 %vf_x36, ptr %nf, align 8
  %vf_and7 = and i1 %vf_and4, true
  %fptr38 = getelementptr i8, ptr %pay_p3, i64 24
  %vf_x39 = load i64, ptr %fptr38, align 8
  %sz = alloca i64, align 8
  store i64 %vf_x39, ptr %sz, align 8
  %vf_and10 = and i1 %vf_and7, true
  %fptr311 = getelementptr i8, ptr %pay_p3, i64 32
  %vf_x312 = load i64, ptr %fptr311, align 8
  %al = alloca i64, align 8
  store i64 %vf_x312, ptr %al, align 8
  %vf_and13 = and i1 %vf_and10, true
  %fptr314 = getelementptr i8, ptr %pay_p3, i64 40
  %vf_x315 = load i64, ptr %fptr314, align 8
  %tup = alloca i64, align 8
  store i64 %vf_x315, ptr %tup, align 8
  %vf_and16 = and i1 %vf_and13, true
  %fptr317 = getelementptr i8, ptr %pay_p3, i64 48
  %vf_x318 = load i64, ptr %fptr317, align 8
  %pk = alloca i64, align 8
  store i64 %vf_x318, ptr %pk, align 8
  %vf_and19 = and i1 %vf_and16, true
  br i1 %vf_and19, label %arm_body, label %arm_next

match_merge:                                      ; preds = %arm_next
  unreachable

arm_body:                                         ; preds = %entry
  %argp = alloca ptr, align 8
  store ptr %args, ptr %argp, align 8
  %buf20 = load ptr, ptr %buf, align 8
  %cap21 = load i64, ptr %cap, align 8
  %fmt22 = load ptr, ptr %fmt, align 8
  %argp23 = load ptr, ptr %argp, align 8
  %flds24 = load ptr, ptr %flds, align 8
  %nf25 = load i64, ptr %nf, align 8
  %trunc = trunc i64 %nf25 to i32
  %4 = call i32 @afmt_v(ptr %buf20, i64 %cap21, ptr %fmt22, ptr %argp23, ptr %flds24, i32 %trunc)
  ret i32 %4

arm_next:                                         ; preds = %entry
  br i1 true, label %arm_body26, label %match_merge

arm_body26:                                       ; preds = %arm_next
  %buf27 = load ptr, ptr %buf, align 8
  %cap28 = load i64, ptr %cap, align 8
  %fmt29 = load ptr, ptr %fmt, align 8
  %5 = call i32 @afmt_v(ptr %buf27, i64 %cap28, ptr %fmt29, ptr null, ptr null, i32 0)
  ret i32 %5
}

define void @__artemis_init_typeinfo() {
entry:
  store i32 12, ptr @__typeinfo___anon2_P_i32, align 4
  store ptr @__typeinfo_nm___anon2_P_i32, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon2_P_i32, i32 0, i32 1), align 8
  store i32 12, ptr @__typeinfo___anon2_P_i32, align 4
  store ptr @__typeinfo_flds___anon2_P_i32, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon2_P_i32, i32 0, i32 1), i64 8), align 8
  store i32 12, ptr @__typeinfo___anon2_P_i32, align 4
  store i64 2, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon2_P_i32, i32 0, i32 1), i64 16), align 8
  store i32 12, ptr @__typeinfo___anon2_P_i32, align 4
  store i64 16, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon2_P_i32, i32 0, i32 1), i64 24), align 8
  store i32 12, ptr @__typeinfo___anon2_P_i32, align 4
  store i64 8, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon2_P_i32, i32 0, i32 1), i64 32), align 8
  store i32 12, ptr @__typeinfo___anon1_P, align 4
  store ptr @__typeinfo_nm___anon1_P, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon1_P, i32 0, i32 1), align 8
  store i32 12, ptr @__typeinfo___anon1_P, align 4
  store ptr @__typeinfo_flds___anon1_P, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon1_P, i32 0, i32 1), i64 8), align 8
  store i32 12, ptr @__typeinfo___anon1_P, align 4
  store i64 1, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon1_P, i32 0, i32 1), i64 16), align 8
  store i32 12, ptr @__typeinfo___anon1_P, align 4
  store i64 8, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon1_P, i32 0, i32 1), i64 24), align 8
  store i32 12, ptr @__typeinfo___anon1_P, align 4
  store i64 8, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon1_P, i32 0, i32 1), i64 32), align 8
  store i32 12, ptr @__typeinfo___anon0, align 4
  store ptr @__typeinfo_nm___anon0, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon0, i32 0, i32 1), align 8
  store i32 12, ptr @__typeinfo___anon0, align 4
  store i64 0, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon0, i32 0, i32 1), i64 16), align 8
  store i32 12, ptr @__typeinfo___anon0, align 4
  store i64 0, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon0, i32 0, i32 1), i64 24), align 8
  store i32 12, ptr @__typeinfo___anon0, align 4
  store i64 0, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon0, i32 0, i32 1), i64 32), align 8
  ret void
}

define internal i32 @aprint__at_args_S__anon1_P(ptr %0, %__anon1_P %1) {
entry:
  %fmt = alloca ptr, align 8
  store ptr %0, ptr %fmt, align 8
  %args = alloca %__anon1_P, align 8
  store %__anon1_P %1, ptr %args, align 8
  %ti = alloca ptr, align 8
  store ptr @__typeinfo___anon1_P, ptr %ti, align 8
  %argp = alloca ptr, align 8
  store ptr %args, ptr %argp, align 8
  %flds0 = alloca ptr, align 8
  store ptr null, ptr %flds0, align 8
  %nf0 = alloca i32, align 4
  store i32 0, ptr %nf0, align 4
  %ti1 = load ptr, ptr %ti, align 8
  %deref = load %type_info, ptr %ti1, align 4
  %__tag_x = extractvalue %type_info %deref, 0
  %vtag = load i32, ptr @type_info__Struct, align 4
  %tag_cmp = icmp eq i32 %__tag_x, %vtag
  %enum_tmp = alloca %type_info, align 8
  store %type_info %deref, ptr %enum_tmp, align 4
  %pay_p3 = getelementptr inbounds nuw %type_info, ptr %enum_tmp, i32 0, i32 1
  %fptr3 = getelementptr i8, ptr %pay_p3, i64 0
  %vf_x3 = load ptr, ptr %fptr3, align 8
  %nm = alloca ptr, align 8
  store ptr %vf_x3, ptr %nm, align 8
  %vf_and = and i1 %tag_cmp, true
  %fptr32 = getelementptr i8, ptr %pay_p3, i64 8
  %vf_x33 = load ptr, ptr %fptr32, align 8
  %flds = alloca ptr, align 8
  store ptr %vf_x33, ptr %flds, align 8
  %vf_and4 = and i1 %vf_and, true
  %fptr35 = getelementptr i8, ptr %pay_p3, i64 16
  %vf_x36 = load i64, ptr %fptr35, align 8
  %nf = alloca i64, align 8
  store i64 %vf_x36, ptr %nf, align 8
  %vf_and7 = and i1 %vf_and4, true
  %fptr38 = getelementptr i8, ptr %pay_p3, i64 24
  %vf_x39 = load i64, ptr %fptr38, align 8
  %sz = alloca i64, align 8
  store i64 %vf_x39, ptr %sz, align 8
  %vf_and10 = and i1 %vf_and7, true
  %fptr311 = getelementptr i8, ptr %pay_p3, i64 32
  %vf_x312 = load i64, ptr %fptr311, align 8
  %al = alloca i64, align 8
  store i64 %vf_x312, ptr %al, align 8
  %vf_and13 = and i1 %vf_and10, true
  %fptr314 = getelementptr i8, ptr %pay_p3, i64 40
  %vf_x315 = load i64, ptr %fptr314, align 8
  %tup = alloca i64, align 8
  store i64 %vf_x315, ptr %tup, align 8
  %vf_and16 = and i1 %vf_and13, true
  %fptr317 = getelementptr i8, ptr %pay_p3, i64 48
  %vf_x318 = load i64, ptr %fptr317, align 8
  %pk = alloca i64, align 8
  store i64 %vf_x318, ptr %pk, align 8
  %vf_and19 = and i1 %vf_and16, true
  br i1 %vf_and19, label %arm_body, label %arm_next

match_merge:                                      ; preds = %arm_body22, %arm_next, %arm_body
  %sbuf = alloca [4096 x i8], align 1
  store [4096 x i8] zeroinitializer, ptr %sbuf, align 1
  %n = alloca i32, align 4
  %arr_decay = getelementptr [4096 x i8], ptr %sbuf, i64 0, i64 0
  %fmt23 = load ptr, ptr %fmt, align 8
  %argp24 = load ptr, ptr %argp, align 8
  %flds025 = load ptr, ptr %flds0, align 8
  %nf026 = load i32, ptr %nf0, align 4
  %2 = call i32 @afmt_v(ptr %arr_decay, i64 4096, ptr %fmt23, ptr %argp24, ptr %flds025, i32 %nf026)
  store i32 %2, ptr %n, align 4
  %n27 = load i32, ptr %n, align 4
  %icmp = icmp slt i32 %n27, 0
  br i1 %icmp, label %if_then, label %if_merge

arm_body:                                         ; preds = %entry
  %flds20 = load ptr, ptr %flds, align 8
  store ptr %flds20, ptr %flds0, align 8
  %nf21 = load i64, ptr %nf, align 8
  %trunc = trunc i64 %nf21 to i32
  store i32 %trunc, ptr %nf0, align 4
  br label %match_merge

arm_next:                                         ; preds = %entry
  br i1 true, label %arm_body22, label %match_merge

arm_body22:                                       ; preds = %arm_next
  store ptr null, ptr %argp, align 8
  br label %match_merge

if_then:                                          ; preds = %match_merge
  %n28 = load i32, ptr %n, align 4
  ret i32 %n28

if_merge:                                         ; preds = %match_merge
  %n29 = load i32, ptr %n, align 4
  %zext = zext i32 %n29 to i64
  %icmp30 = icmp ult i64 %zext, 4096
  br i1 %icmp30, label %if_then31, label %if_merge32

if_then31:                                        ; preds = %if_merge
  %arr_decay33 = getelementptr [4096 x i8], ptr %sbuf, i64 0, i64 0
  %n34 = load i32, ptr %n, align 4
  %zext35 = zext i32 %n34 to i64
  %3 = call ptr @arc_stdout_file()
  %4 = call i64 @arc_fwrite(ptr %arr_decay33, i64 1, i64 %zext35, ptr %3)
  %n36 = load i32, ptr %n, align 4
  ret i32 %n36

if_merge32:                                       ; preds = %if_merge
  %need = alloca i64, align 8
  %n37 = load i32, ptr %n, align 4
  %zext38 = zext i32 %n37 to i64
  %add = add i64 %zext38, 1
  store i64 %add, ptr %need, align 8
  %hbuf = alloca ptr, align 8
  %need39 = load i64, ptr %need, align 8
  %5 = call ptr @arc_malloc.1(i64 %need39)
  store ptr %5, ptr %hbuf, align 8
  %hbuf40 = load ptr, ptr %hbuf, align 8
  %icmp41 = icmp eq ptr %hbuf40, null
  br i1 %icmp41, label %if_then42, label %if_merge43

if_then42:                                        ; preds = %if_merge32
  %arr_decay44 = getelementptr [4096 x i8], ptr %sbuf, i64 0, i64 0
  %6 = call ptr @arc_stdout_file()
  %7 = call i64 @arc_fwrite(ptr %arr_decay44, i64 1, i64 4095, ptr %6)
  %n45 = load i32, ptr %n, align 4
  ret i32 %n45

if_merge43:                                       ; preds = %if_merge32
  %n2 = alloca i32, align 4
  %hbuf46 = load ptr, ptr %hbuf, align 8
  %need47 = load i64, ptr %need, align 8
  %fmt48 = load ptr, ptr %fmt, align 8
  %argp49 = load ptr, ptr %argp, align 8
  %flds050 = load ptr, ptr %flds0, align 8
  %nf051 = load i32, ptr %nf0, align 4
  %8 = call i32 @afmt_v(ptr %hbuf46, i64 %need47, ptr %fmt48, ptr %argp49, ptr %flds050, i32 %nf051)
  store i32 %8, ptr %n2, align 4
  %hbuf52 = load ptr, ptr %hbuf, align 8
  %n253 = load i32, ptr %n2, align 4
  %zext54 = zext i32 %n253 to i64
  %9 = call ptr @arc_stdout_file()
  %10 = call i64 @arc_fwrite(ptr %hbuf52, i64 1, i64 %zext54, ptr %9)
  %hbuf55 = load ptr, ptr %hbuf, align 8
  call void @arc_free.3(ptr %hbuf55)
  %n256 = load i32, ptr %n2, align 4
  ret i32 %n256
}

define internal i32 @aprint__at_args_S__anon0(ptr %0, %__anon0 %1) {
entry:
  %fmt = alloca ptr, align 8
  store ptr %0, ptr %fmt, align 8
  %args = alloca %__anon0, align 8
  store %__anon0 %1, ptr %args, align 1
  %ti = alloca ptr, align 8
  store ptr @__typeinfo___anon0, ptr %ti, align 8
  %argp = alloca ptr, align 8
  store ptr %args, ptr %argp, align 8
  %flds0 = alloca ptr, align 8
  store ptr null, ptr %flds0, align 8
  %nf0 = alloca i32, align 4
  store i32 0, ptr %nf0, align 4
  %ti1 = load ptr, ptr %ti, align 8
  %deref = load %type_info, ptr %ti1, align 4
  %__tag_x = extractvalue %type_info %deref, 0
  %vtag = load i32, ptr @type_info__Struct, align 4
  %tag_cmp = icmp eq i32 %__tag_x, %vtag
  %enum_tmp = alloca %type_info, align 8
  store %type_info %deref, ptr %enum_tmp, align 4
  %pay_p3 = getelementptr inbounds nuw %type_info, ptr %enum_tmp, i32 0, i32 1
  %fptr3 = getelementptr i8, ptr %pay_p3, i64 0
  %vf_x3 = load ptr, ptr %fptr3, align 8
  %nm = alloca ptr, align 8
  store ptr %vf_x3, ptr %nm, align 8
  %vf_and = and i1 %tag_cmp, true
  %fptr32 = getelementptr i8, ptr %pay_p3, i64 8
  %vf_x33 = load ptr, ptr %fptr32, align 8
  %flds = alloca ptr, align 8
  store ptr %vf_x33, ptr %flds, align 8
  %vf_and4 = and i1 %vf_and, true
  %fptr35 = getelementptr i8, ptr %pay_p3, i64 16
  %vf_x36 = load i64, ptr %fptr35, align 8
  %nf = alloca i64, align 8
  store i64 %vf_x36, ptr %nf, align 8
  %vf_and7 = and i1 %vf_and4, true
  %fptr38 = getelementptr i8, ptr %pay_p3, i64 24
  %vf_x39 = load i64, ptr %fptr38, align 8
  %sz = alloca i64, align 8
  store i64 %vf_x39, ptr %sz, align 8
  %vf_and10 = and i1 %vf_and7, true
  %fptr311 = getelementptr i8, ptr %pay_p3, i64 32
  %vf_x312 = load i64, ptr %fptr311, align 8
  %al = alloca i64, align 8
  store i64 %vf_x312, ptr %al, align 8
  %vf_and13 = and i1 %vf_and10, true
  %fptr314 = getelementptr i8, ptr %pay_p3, i64 40
  %vf_x315 = load i64, ptr %fptr314, align 8
  %tup = alloca i64, align 8
  store i64 %vf_x315, ptr %tup, align 8
  %vf_and16 = and i1 %vf_and13, true
  %fptr317 = getelementptr i8, ptr %pay_p3, i64 48
  %vf_x318 = load i64, ptr %fptr317, align 8
  %pk = alloca i64, align 8
  store i64 %vf_x318, ptr %pk, align 8
  %vf_and19 = and i1 %vf_and16, true
  br i1 %vf_and19, label %arm_body, label %arm_next

match_merge:                                      ; preds = %arm_body22, %arm_next, %arm_body
  %sbuf = alloca [4096 x i8], align 1
  store [4096 x i8] zeroinitializer, ptr %sbuf, align 1
  %n = alloca i32, align 4
  %arr_decay = getelementptr [4096 x i8], ptr %sbuf, i64 0, i64 0
  %fmt23 = load ptr, ptr %fmt, align 8
  %argp24 = load ptr, ptr %argp, align 8
  %flds025 = load ptr, ptr %flds0, align 8
  %nf026 = load i32, ptr %nf0, align 4
  %2 = call i32 @afmt_v(ptr %arr_decay, i64 4096, ptr %fmt23, ptr %argp24, ptr %flds025, i32 %nf026)
  store i32 %2, ptr %n, align 4
  %n27 = load i32, ptr %n, align 4
  %icmp = icmp slt i32 %n27, 0
  br i1 %icmp, label %if_then, label %if_merge

arm_body:                                         ; preds = %entry
  %flds20 = load ptr, ptr %flds, align 8
  store ptr %flds20, ptr %flds0, align 8
  %nf21 = load i64, ptr %nf, align 8
  %trunc = trunc i64 %nf21 to i32
  store i32 %trunc, ptr %nf0, align 4
  br label %match_merge

arm_next:                                         ; preds = %entry
  br i1 true, label %arm_body22, label %match_merge

arm_body22:                                       ; preds = %arm_next
  store ptr null, ptr %argp, align 8
  br label %match_merge

if_then:                                          ; preds = %match_merge
  %n28 = load i32, ptr %n, align 4
  ret i32 %n28

if_merge:                                         ; preds = %match_merge
  %n29 = load i32, ptr %n, align 4
  %zext = zext i32 %n29 to i64
  %icmp30 = icmp ult i64 %zext, 4096
  br i1 %icmp30, label %if_then31, label %if_merge32

if_then31:                                        ; preds = %if_merge
  %arr_decay33 = getelementptr [4096 x i8], ptr %sbuf, i64 0, i64 0
  %n34 = load i32, ptr %n, align 4
  %zext35 = zext i32 %n34 to i64
  %3 = call ptr @arc_stdout_file()
  %4 = call i64 @arc_fwrite(ptr %arr_decay33, i64 1, i64 %zext35, ptr %3)
  %n36 = load i32, ptr %n, align 4
  ret i32 %n36

if_merge32:                                       ; preds = %if_merge
  %need = alloca i64, align 8
  %n37 = load i32, ptr %n, align 4
  %zext38 = zext i32 %n37 to i64
  %add = add i64 %zext38, 1
  store i64 %add, ptr %need, align 8
  %hbuf = alloca ptr, align 8
  %need39 = load i64, ptr %need, align 8
  %5 = call ptr @arc_malloc.1(i64 %need39)
  store ptr %5, ptr %hbuf, align 8
  %hbuf40 = load ptr, ptr %hbuf, align 8
  %icmp41 = icmp eq ptr %hbuf40, null
  br i1 %icmp41, label %if_then42, label %if_merge43

if_then42:                                        ; preds = %if_merge32
  %arr_decay44 = getelementptr [4096 x i8], ptr %sbuf, i64 0, i64 0
  %6 = call ptr @arc_stdout_file()
  %7 = call i64 @arc_fwrite(ptr %arr_decay44, i64 1, i64 4095, ptr %6)
  %n45 = load i32, ptr %n, align 4
  ret i32 %n45

if_merge43:                                       ; preds = %if_merge32
  %n2 = alloca i32, align 4
  %hbuf46 = load ptr, ptr %hbuf, align 8
  %need47 = load i64, ptr %need, align 8
  %fmt48 = load ptr, ptr %fmt, align 8
  %argp49 = load ptr, ptr %argp, align 8
  %flds050 = load ptr, ptr %flds0, align 8
  %nf051 = load i32, ptr %nf0, align 4
  %8 = call i32 @afmt_v(ptr %hbuf46, i64 %need47, ptr %fmt48, ptr %argp49, ptr %flds050, i32 %nf051)
  store i32 %8, ptr %n2, align 4
  %hbuf52 = load ptr, ptr %hbuf, align 8
  %n253 = load i32, ptr %n2, align 4
  %zext54 = zext i32 %n253 to i64
  %9 = call ptr @arc_stdout_file()
  %10 = call i64 @arc_fwrite(ptr %hbuf52, i64 1, i64 %zext54, ptr %9)
  %hbuf55 = load ptr, ptr %hbuf, align 8
  call void @arc_free.3(ptr %hbuf55)
  %n256 = load i32, ptr %n2, align 4
  ret i32 %n256
}

define i32 @main() {
entry:
  call void @demo__NS_go(ptr @str.7, i32 1)
  ret i32 0
}
