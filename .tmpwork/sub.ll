; ModuleID = 'compiler/__sub.arc'
source_filename = "compiler/__sub.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%__vtable__ = type { ptr, ptr, ptr, ptr, ptr }
%type_info = type { i32, [72 x i8] }
%type_info_field = type { ptr, i32, i32, i32 }
%memstr = type { ptr, ptr }
%SysAlloc = type {}
%strbuf = type { ptr, i64, i64 }
%pp_table = type { [512 x ptr], [512 x ptr], i32 }
%__anon1_P = type { ptr }
%pp_func_table = type { [64 x ptr], [64 x i32], [64 x ptr], i32 }
%pp_stack = type { [64 x i8], [64 x i8], [64 x i8], i32 }
%__anon2_P_P = type { ptr, ptr }

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
@str.4 = private unnamed_addr constant [83 x i8] c"warning: preprocessor macro table full (512 entries); ignoring definition of '%s'\0A\00", align 1
@__typeinfo___anon1_P = global %type_info zeroinitializer
@__typeinfo_nm___anon1_P = constant [10 x i8] c"__anon1_P\00"
@__typeinfo_fn___anon1_P_0 = constant [4 x i8] c"__0\00"
@__typeinfo_flds___anon1_P = constant [1 x %type_info_field] [%type_info_field { ptr @__typeinfo_fn___anon1_P_0, i32 0, i32 8, i32 8 }]
@str.5 = private unnamed_addr constant [83 x i8] c"warning: function-like macro table full (64 entries); ignoring definition of '%s'\0A\00", align 1
@str.6 = private unnamed_addr constant [3 x i8] c"rb\00", align 1
@str.7 = private unnamed_addr constant [7 x i8] c"define\00", align 1
@str.8 = private unnamed_addr constant [6 x i8] c"undef\00", align 1
@str.9 = private unnamed_addr constant [6 x i8] c"ifdef\00", align 1
@str.10 = private unnamed_addr constant [7 x i8] c"ifndef\00", align 1
@str.11 = private unnamed_addr constant [8 x i8] c"elifdef\00", align 1
@str.12 = private unnamed_addr constant [9 x i8] c"elifndef\00", align 1
@str.13 = private unnamed_addr constant [5 x i8] c"else\00", align 1
@str.14 = private unnamed_addr constant [6 x i8] c"endif\00", align 1
@str.15 = private unnamed_addr constant [8 x i8] c"include\00", align 1
@str.16 = private unnamed_addr constant [6 x i8] c"embed\00", align 1
@str.17 = private unnamed_addr constant [6 x i8] c"error\00", align 1
@str.18 = private unnamed_addr constant [7 x i8] c"define\00", align 1
@str.19 = private unnamed_addr constant [6 x i8] c"undef\00", align 1
@str.20 = private unnamed_addr constant [6 x i8] c"ifdef\00", align 1
@str.21 = private unnamed_addr constant [7 x i8] c"ifndef\00", align 1
@str.22 = private unnamed_addr constant [6 x i8] c"ifdef\00", align 1
@str.23 = private unnamed_addr constant [8 x i8] c"elifdef\00", align 1
@str.24 = private unnamed_addr constant [9 x i8] c"elifndef\00", align 1
@str.25 = private unnamed_addr constant [8 x i8] c"elifdef\00", align 1
@str.26 = private unnamed_addr constant [5 x i8] c"else\00", align 1
@str.27 = private unnamed_addr constant [6 x i8] c"endif\00", align 1
@str.28 = private unnamed_addr constant [8 x i8] c"include\00", align 1
@str.29 = private unnamed_addr constant [6 x i8] c"embed\00", align 1
@str.30 = private unnamed_addr constant [6 x i8] c"%s/%s\00", align 1
@__typeinfo___anon2_P_P = global %type_info zeroinitializer
@__typeinfo_nm___anon2_P_P = constant [12 x i8] c"__anon2_P_P\00"
@__typeinfo_fn___anon2_P_P_0 = constant [4 x i8] c"__0\00"
@__typeinfo_fn___anon2_P_P_1 = constant [4 x i8] c"__1\00"
@__typeinfo_flds___anon2_P_P = constant [2 x %type_info_field] [%type_info_field { ptr @__typeinfo_fn___anon2_P_P_0, i32 0, i32 8, i32 8 }, %type_info_field { ptr @__typeinfo_fn___anon2_P_P_1, i32 8, i32 8, i32 8 }]
@str.31 = private unnamed_addr constant [2 x i8] c"1\00", align 1
@str.32 = private unnamed_addr constant [6 x i8] c"error\00", align 1
@str.33 = private unnamed_addr constant [24 x i8] c"preprocessor error: %s\0A\00", align 1
@str.34 = private unnamed_addr constant [11 x i8] c"std/%s.arc\00", align 1
@str.35 = private unnamed_addr constant [2 x i8] c"1\00", align 1
@str.36 = private unnamed_addr constant [28 x i8] c"- = @import(\22std/%s.arc\22);\0A\00", align 1
@str.37 = private unnamed_addr constant [9 x i8] c"aciso/%s\00", align 1
@str.38 = private unnamed_addr constant [2 x i8] c"1\00", align 1
@str.39 = private unnamed_addr constant [18 x i8] c"modules/%s/%s.arc\00", align 1
@str.40 = private unnamed_addr constant [6 x i8] c"%s/%s\00", align 1
@str.41 = private unnamed_addr constant [20 x i8] c"modules/%s/main.arc\00", align 1
@str.42 = private unnamed_addr constant [20 x i8] c"- = @import(\22%s\22);\0A\00", align 1
@str.43 = private unnamed_addr constant [12 x i8] c"__ARTEMIS__\00", align 1
@str.44 = private unnamed_addr constant [2 x i8] c"1\00", align 1
@str.45 = private unnamed_addr constant [8 x i8] c"windows\00", align 1
@str.46 = private unnamed_addr constant [6 x i8] c"mingw\00", align 1
@str.47 = private unnamed_addr constant [5 x i8] c"msvc\00", align 1
@str.48 = private unnamed_addr constant [7 x i8] c"_WIN32\00", align 1
@str.49 = private unnamed_addr constant [2 x i8] c"1\00", align 1
@str.50 = private unnamed_addr constant [7 x i8] c"_WIN64\00", align 1
@str.51 = private unnamed_addr constant [2 x i8] c"1\00", align 1
@str.52 = private unnamed_addr constant [7 x i8] c"darwin\00", align 1
@str.53 = private unnamed_addr constant [6 x i8] c"apple\00", align 1
@str.54 = private unnamed_addr constant [6 x i8] c"macos\00", align 1
@str.55 = private unnamed_addr constant [10 x i8] c"__APPLE__\00", align 1
@str.56 = private unnamed_addr constant [2 x i8] c"1\00", align 1
@str.57 = private unnamed_addr constant [9 x i8] c"__unix__\00", align 1
@str.58 = private unnamed_addr constant [2 x i8] c"1\00", align 1
@str.59 = private unnamed_addr constant [6 x i8] c"linux\00", align 1
@str.60 = private unnamed_addr constant [10 x i8] c"__linux__\00", align 1
@str.61 = private unnamed_addr constant [2 x i8] c"1\00", align 1
@str.62 = private unnamed_addr constant [9 x i8] c"__unix__\00", align 1
@str.63 = private unnamed_addr constant [2 x i8] c"1\00", align 1
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

define internal void @preproc__NS_strbuf_init(ptr %0) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %ptr_deref = load ptr, ptr %b, align 8
  %data = getelementptr inbounds nuw %strbuf, ptr %ptr_deref, i32 0, i32 0
  %1 = call ptr @arc_malloc.1(i64 1024)
  store ptr %1, ptr %data, align 8
  %ptr_deref1 = load ptr, ptr %b, align 8
  %len = getelementptr inbounds nuw %strbuf, ptr %ptr_deref1, i32 0, i32 1
  store i64 0, ptr %len, align 8
  %ptr_deref2 = load ptr, ptr %b, align 8
  %cap = getelementptr inbounds nuw %strbuf, ptr %ptr_deref2, i32 0, i32 2
  store i64 1024, ptr %cap, align 8
  ret void
}

define internal void @preproc__NS_strbuf_ensure(ptr %0, i64 %1) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %extra = alloca i64, align 8
  store i64 %1, ptr %extra, align 8
  %ptr_deref = load ptr, ptr %b, align 8
  %len = getelementptr inbounds nuw %strbuf, ptr %ptr_deref, i32 0, i32 1
  %ptr_deref1 = load ptr, ptr %b, align 8
  %mem_load = load i64, ptr %len, align 8
  %extra2 = load i64, ptr %extra, align 8
  %add = add i64 %mem_load, %extra2
  %ptr_deref3 = load ptr, ptr %b, align 8
  %cap = getelementptr inbounds nuw %strbuf, ptr %ptr_deref3, i32 0, i32 2
  %ptr_deref4 = load ptr, ptr %b, align 8
  %mem_load5 = load i64, ptr %cap, align 8
  %icmp = icmp slt i64 %add, %mem_load5
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret void

if_merge:                                         ; preds = %entry
  %nc = alloca i64, align 8
  %ptr_deref6 = load ptr, ptr %b, align 8
  %cap7 = getelementptr inbounds nuw %strbuf, ptr %ptr_deref6, i32 0, i32 2
  %ptr_deref8 = load ptr, ptr %b, align 8
  %mem_load9 = load i64, ptr %cap7, align 8
  %mul = mul i64 %mem_load9, 2
  %extra10 = load i64, ptr %extra, align 8
  %add11 = add i64 %mul, %extra10
  %add12 = add i64 %add11, 1
  store i64 %add12, ptr %nc, align 8
  %ptr_deref13 = load ptr, ptr %b, align 8
  %data = getelementptr inbounds nuw %strbuf, ptr %ptr_deref13, i32 0, i32 0
  %ptr_deref14 = load ptr, ptr %b, align 8
  %data15 = getelementptr inbounds nuw %strbuf, ptr %ptr_deref14, i32 0, i32 0
  %ptr_deref16 = load ptr, ptr %b, align 8
  %mem_load17 = load ptr, ptr %data15, align 8
  %nc18 = load i64, ptr %nc, align 8
  %2 = call ptr @arc_realloc.2(ptr %mem_load17, i64 %nc18)
  store ptr %2, ptr %data, align 8
  %ptr_deref19 = load ptr, ptr %b, align 8
  %cap20 = getelementptr inbounds nuw %strbuf, ptr %ptr_deref19, i32 0, i32 2
  %nc21 = load i64, ptr %nc, align 8
  store i64 %nc21, ptr %cap20, align 8
  ret void
}

define internal void @preproc__NS_strbuf_push(ptr %0, i8 %1) {
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
  %mem_load = load i64, ptr %len, align 8
  %ptr_load = load ptr, ptr %data, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %mem_load
  %c4 = load i8, ptr %c, align 1
  store i8 %c4, ptr %ptr_gep, align 1
  %ptr_deref5 = load ptr, ptr %b, align 8
  %len6 = getelementptr inbounds nuw %strbuf, ptr %ptr_deref5, i32 0, i32 1
  %ptr_deref7 = load ptr, ptr %b, align 8
  %len8 = getelementptr inbounds nuw %strbuf, ptr %ptr_deref7, i32 0, i32 1
  %ptr_deref9 = load ptr, ptr %b, align 8
  %mem_load10 = load i64, ptr %len8, align 8
  %add = add i64 %mem_load10, 1
  store i64 %add, ptr %len6, align 8
  ret void
}

define internal void @preproc__NS_strbuf_append(ptr %0, ptr %1, i64 %2) {
entry:
  %b = alloca ptr, align 8
  store ptr %0, ptr %b, align 8
  %s = alloca ptr, align 8
  store ptr %1, ptr %s, align 8
  %n = alloca i64, align 8
  store i64 %2, ptr %n, align 8
  %b1 = load ptr, ptr %b, align 8
  %n2 = load i64, ptr %n, align 8
  call void @preproc__NS_strbuf_ensure(ptr %b1, i64 %n2)
  %i = alloca i64, align 8
  store i64 0, ptr %i, align 8
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %i3 = load i64, ptr %i, align 8
  %n4 = load i64, ptr %n, align 8
  %icmp = icmp ult i64 %i3, %n4
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ptr_deref = load ptr, ptr %b, align 8
  %data = getelementptr inbounds nuw %strbuf, ptr %ptr_deref, i32 0, i32 0
  %ptr_deref5 = load ptr, ptr %b, align 8
  %len = getelementptr inbounds nuw %strbuf, ptr %ptr_deref5, i32 0, i32 1
  %ptr_deref6 = load ptr, ptr %b, align 8
  %mem_load = load i64, ptr %len, align 8
  %i7 = load i64, ptr %i, align 8
  %add = add i64 %mem_load, %i7
  %ptr_load = load ptr, ptr %data, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %add
  %i8 = load i64, ptr %i, align 8
  %ptr_load9 = load ptr, ptr %s, align 8
  %ptr_gep10 = getelementptr i8, ptr %ptr_load9, i64 %i8
  %idx_load = load i8, ptr %ptr_gep10, align 1
  store i8 %idx_load, ptr %ptr_gep, align 1
  %i11 = load i64, ptr %i, align 8
  %add12 = add i64 %i11, 1
  store i64 %add12, ptr %i, align 8
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %ptr_deref13 = load ptr, ptr %b, align 8
  %len14 = getelementptr inbounds nuw %strbuf, ptr %ptr_deref13, i32 0, i32 1
  %ptr_deref15 = load ptr, ptr %b, align 8
  %len16 = getelementptr inbounds nuw %strbuf, ptr %ptr_deref15, i32 0, i32 1
  %ptr_deref17 = load ptr, ptr %b, align 8
  %mem_load18 = load i64, ptr %len16, align 8
  %n19 = load i64, ptr %n, align 8
  %add20 = add i64 %mem_load18, %n19
  store i64 %add20, ptr %len14, align 8
  ret void
}

define internal void @preproc__NS_strbuf_append_cstr(ptr %0, ptr %1) {
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
  %s2 = load ptr, ptr %s, align 8
  %2 = call i64 @arc_strlen(ptr %s2)
  store i64 %2, ptr %n, align 8
  %b3 = load ptr, ptr %b, align 8
  %s4 = load ptr, ptr %s, align 8
  %n5 = load i64, ptr %n, align 8
  call void @preproc__NS_strbuf_append(ptr %b3, ptr %s4, i64 %n5)
  ret void
}

define internal ptr @preproc__NS_strbuf_finish(ptr %0) {
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
  %mem_load = load i64, ptr %len, align 8
  %ptr_load = load ptr, ptr %data, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %mem_load
  store i8 0, ptr %ptr_gep, align 1
  %ptr_deref4 = load ptr, ptr %b, align 8
  %data5 = getelementptr inbounds nuw %strbuf, ptr %ptr_deref4, i32 0, i32 0
  %ptr_deref6 = load ptr, ptr %b, align 8
  %mem_load7 = load ptr, ptr %data5, align 8
  ret ptr %mem_load7
}

define internal void @preproc__NS_pp_table_init(ptr %0) {
entry:
  %t = alloca ptr, align 8
  store ptr %0, ptr %t, align 8
  %ptr_deref = load ptr, ptr %t, align 8
  %count = getelementptr inbounds nuw %pp_table, ptr %ptr_deref, i32 0, i32 2
  store i32 0, ptr %count, align 4
  ret void
}

define internal i8 @preproc__NS_pp_defined(ptr %0, ptr %1) {
entry:
  %t = alloca ptr, align 8
  store ptr %0, ptr %t, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_deref = load ptr, ptr %t, align 8
  %count = getelementptr inbounds nuw %pp_table, ptr %ptr_deref, i32 0, i32 2
  %ptr_deref2 = load ptr, ptr %t, align 8
  %mem_load = load i32, ptr %count, align 4
  %icmp = icmp slt i32 %i1, %mem_load
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ptr_deref3 = load ptr, ptr %t, align 8
  %names = getelementptr inbounds nuw %pp_table, ptr %ptr_deref3, i32 0, i32 0
  %i4 = load i32, ptr %i, align 4
  %arr_gep = getelementptr [512 x ptr], ptr %names, i64 0, i32 %i4
  %idx_load = load ptr, ptr %arr_gep, align 8
  %name5 = load ptr, ptr %name, align 8
  %2 = call i32 @arc_strcmp(ptr %idx_load, ptr %name5)
  %icmp6 = icmp eq i32 %2, 0
  br i1 %icmp6, label %if_then, label %if_merge

while_exit:                                       ; preds = %while_cond
  ret i8 0

if_then:                                          ; preds = %while_body
  ret i8 1

if_merge:                                         ; preds = %while_body
  %i7 = load i32, ptr %i, align 4
  %add = add i32 %i7, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond
}

define internal ptr @preproc__NS_pp_get(ptr %0, ptr %1) {
entry:
  %t = alloca ptr, align 8
  store ptr %0, ptr %t, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_deref = load ptr, ptr %t, align 8
  %count = getelementptr inbounds nuw %pp_table, ptr %ptr_deref, i32 0, i32 2
  %ptr_deref2 = load ptr, ptr %t, align 8
  %mem_load = load i32, ptr %count, align 4
  %icmp = icmp slt i32 %i1, %mem_load
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ptr_deref3 = load ptr, ptr %t, align 8
  %names = getelementptr inbounds nuw %pp_table, ptr %ptr_deref3, i32 0, i32 0
  %i4 = load i32, ptr %i, align 4
  %arr_gep = getelementptr [512 x ptr], ptr %names, i64 0, i32 %i4
  %idx_load = load ptr, ptr %arr_gep, align 8
  %name5 = load ptr, ptr %name, align 8
  %2 = call i32 @arc_strcmp(ptr %idx_load, ptr %name5)
  %icmp6 = icmp eq i32 %2, 0
  br i1 %icmp6, label %if_then, label %if_merge

while_exit:                                       ; preds = %while_cond
  ret ptr null

if_then:                                          ; preds = %while_body
  %ptr_deref7 = load ptr, ptr %t, align 8
  %values = getelementptr inbounds nuw %pp_table, ptr %ptr_deref7, i32 0, i32 1
  %i8 = load i32, ptr %i, align 4
  %arr_gep9 = getelementptr [512 x ptr], ptr %values, i64 0, i32 %i8
  %idx_load10 = load ptr, ptr %arr_gep9, align 8
  ret ptr %idx_load10

if_merge:                                         ; preds = %while_body
  %i11 = load i32, ptr %i, align 4
  %add = add i32 %i11, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond
}

define internal void @preproc__NS_pp_set(ptr %0, ptr %1, ptr %2) {
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

while_cond:                                       ; preds = %if_merge, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_deref = load ptr, ptr %t, align 8
  %count = getelementptr inbounds nuw %pp_table, ptr %ptr_deref, i32 0, i32 2
  %ptr_deref2 = load ptr, ptr %t, align 8
  %mem_load = load i32, ptr %count, align 4
  %icmp = icmp slt i32 %i1, %mem_load
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ptr_deref3 = load ptr, ptr %t, align 8
  %names = getelementptr inbounds nuw %pp_table, ptr %ptr_deref3, i32 0, i32 0
  %i4 = load i32, ptr %i, align 4
  %arr_gep = getelementptr [512 x ptr], ptr %names, i64 0, i32 %i4
  %idx_load = load ptr, ptr %arr_gep, align 8
  %name5 = load ptr, ptr %name, align 8
  %3 = call i32 @arc_strcmp(ptr %idx_load, ptr %name5)
  %icmp6 = icmp eq i32 %3, 0
  br i1 %icmp6, label %if_then, label %if_merge

while_exit:                                       ; preds = %while_cond
  %ptr_deref12 = load ptr, ptr %t, align 8
  %count13 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref12, i32 0, i32 2
  %ptr_deref14 = load ptr, ptr %t, align 8
  %mem_load15 = load i32, ptr %count13, align 4
  %icmp16 = icmp slt i32 %mem_load15, 512
  br i1 %icmp16, label %if_then17, label %if_else

if_then:                                          ; preds = %while_body
  %ptr_deref7 = load ptr, ptr %t, align 8
  %values = getelementptr inbounds nuw %pp_table, ptr %ptr_deref7, i32 0, i32 1
  %i8 = load i32, ptr %i, align 4
  %arr_gep9 = getelementptr [512 x ptr], ptr %values, i64 0, i32 %i8
  %value10 = load ptr, ptr %value, align 8
  store ptr %value10, ptr %arr_gep9, align 8
  ret void

if_merge:                                         ; preds = %while_body
  %i11 = load i32, ptr %i, align 4
  %add = add i32 %i11, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond

if_then17:                                        ; preds = %while_exit
  %ptr_deref19 = load ptr, ptr %t, align 8
  %names20 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref19, i32 0, i32 0
  %ptr_deref21 = load ptr, ptr %t, align 8
  %count22 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref21, i32 0, i32 2
  %ptr_deref23 = load ptr, ptr %t, align 8
  %mem_load24 = load i32, ptr %count22, align 4
  %arr_gep25 = getelementptr [512 x ptr], ptr %names20, i64 0, i32 %mem_load24
  %name26 = load ptr, ptr %name, align 8
  store ptr %name26, ptr %arr_gep25, align 8
  %ptr_deref27 = load ptr, ptr %t, align 8
  %values28 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref27, i32 0, i32 1
  %ptr_deref29 = load ptr, ptr %t, align 8
  %count30 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref29, i32 0, i32 2
  %ptr_deref31 = load ptr, ptr %t, align 8
  %mem_load32 = load i32, ptr %count30, align 4
  %arr_gep33 = getelementptr [512 x ptr], ptr %values28, i64 0, i32 %mem_load32
  %value34 = load ptr, ptr %value, align 8
  store ptr %value34, ptr %arr_gep33, align 8
  %ptr_deref35 = load ptr, ptr %t, align 8
  %count36 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref35, i32 0, i32 2
  %ptr_deref37 = load ptr, ptr %t, align 8
  %count38 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref37, i32 0, i32 2
  %ptr_deref39 = load ptr, ptr %t, align 8
  %mem_load40 = load i32, ptr %count38, align 4
  %add41 = add i32 %mem_load40, 1
  store i32 %add41, ptr %count36, align 4
  br label %if_merge18

if_else:                                          ; preds = %while_exit
  %name42 = load ptr, ptr %name, align 8
  %anon_s = alloca %__anon1_P, align 8
  %anon_f = getelementptr inbounds nuw %__anon1_P, ptr %anon_s, i32 0, i32 0
  store ptr %name42, ptr %anon_f, align 8
  %anon_load = load %__anon1_P, ptr %anon_s, align 8
  %4 = call i32 @aprint__at_args_S__anon1_P(ptr @str.4, %__anon1_P %anon_load)
  br label %if_merge18

if_merge18:                                       ; preds = %if_else, %if_then17
  ret void
}

define internal void @preproc__NS_pp_undef(ptr %0, ptr %1) {
entry:
  %t = alloca ptr, align 8
  store ptr %0, ptr %t, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_deref = load ptr, ptr %t, align 8
  %count = getelementptr inbounds nuw %pp_table, ptr %ptr_deref, i32 0, i32 2
  %ptr_deref2 = load ptr, ptr %t, align 8
  %mem_load = load i32, ptr %count, align 4
  %icmp = icmp slt i32 %i1, %mem_load
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ptr_deref3 = load ptr, ptr %t, align 8
  %names = getelementptr inbounds nuw %pp_table, ptr %ptr_deref3, i32 0, i32 0
  %i4 = load i32, ptr %i, align 4
  %arr_gep = getelementptr [512 x ptr], ptr %names, i64 0, i32 %i4
  %idx_load = load ptr, ptr %arr_gep, align 8
  %name5 = load ptr, ptr %name, align 8
  %2 = call i32 @arc_strcmp(ptr %idx_load, ptr %name5)
  %icmp6 = icmp eq i32 %2, 0
  br i1 %icmp6, label %if_then, label %if_merge

while_exit:                                       ; preds = %while_cond
  ret void

if_then:                                          ; preds = %while_body
  %last = alloca i32, align 4
  %ptr_deref7 = load ptr, ptr %t, align 8
  %count8 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref7, i32 0, i32 2
  %ptr_deref9 = load ptr, ptr %t, align 8
  %mem_load10 = load i32, ptr %count8, align 4
  %sub = sub i32 %mem_load10, 1
  store i32 %sub, ptr %last, align 4
  %ptr_deref11 = load ptr, ptr %t, align 8
  %names12 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref11, i32 0, i32 0
  %i13 = load i32, ptr %i, align 4
  %arr_gep14 = getelementptr [512 x ptr], ptr %names12, i64 0, i32 %i13
  %ptr_deref15 = load ptr, ptr %t, align 8
  %names16 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref15, i32 0, i32 0
  %last17 = load i32, ptr %last, align 4
  %arr_gep18 = getelementptr [512 x ptr], ptr %names16, i64 0, i32 %last17
  %idx_load19 = load ptr, ptr %arr_gep18, align 8
  store ptr %idx_load19, ptr %arr_gep14, align 8
  %ptr_deref20 = load ptr, ptr %t, align 8
  %values = getelementptr inbounds nuw %pp_table, ptr %ptr_deref20, i32 0, i32 1
  %i21 = load i32, ptr %i, align 4
  %arr_gep22 = getelementptr [512 x ptr], ptr %values, i64 0, i32 %i21
  %ptr_deref23 = load ptr, ptr %t, align 8
  %values24 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref23, i32 0, i32 1
  %last25 = load i32, ptr %last, align 4
  %arr_gep26 = getelementptr [512 x ptr], ptr %values24, i64 0, i32 %last25
  %idx_load27 = load ptr, ptr %arr_gep26, align 8
  store ptr %idx_load27, ptr %arr_gep22, align 8
  %ptr_deref28 = load ptr, ptr %t, align 8
  %count29 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref28, i32 0, i32 2
  %ptr_deref30 = load ptr, ptr %t, align 8
  %count31 = getelementptr inbounds nuw %pp_table, ptr %ptr_deref30, i32 0, i32 2
  %ptr_deref32 = load ptr, ptr %t, align 8
  %mem_load33 = load i32, ptr %count31, align 4
  %sub34 = sub i32 %mem_load33, 1
  store i32 %sub34, ptr %count29, align 4
  ret void

if_merge:                                         ; preds = %while_body
  %i35 = load i32, ptr %i, align 4
  %add = add i32 %i35, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond
}

define internal void @preproc__NS_pp_func_table_init(ptr %0) {
entry:
  %t = alloca ptr, align 8
  store ptr %0, ptr %t, align 8
  %ptr_deref = load ptr, ptr %t, align 8
  %count = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref, i32 0, i32 3
  store i32 0, ptr %count, align 4
  ret void
}

define internal i8 @preproc__NS_pp_func_get(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %t = alloca ptr, align 8
  store ptr %0, ptr %t, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %out_arity = alloca ptr, align 8
  store ptr %2, ptr %out_arity, align 8
  %out_repl = alloca ptr, align 8
  store ptr %3, ptr %out_repl, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_deref = load ptr, ptr %t, align 8
  %count = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref, i32 0, i32 3
  %ptr_deref2 = load ptr, ptr %t, align 8
  %mem_load = load i32, ptr %count, align 4
  %icmp = icmp slt i32 %i1, %mem_load
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ptr_deref3 = load ptr, ptr %t, align 8
  %names = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref3, i32 0, i32 0
  %i4 = load i32, ptr %i, align 4
  %arr_gep = getelementptr [64 x ptr], ptr %names, i64 0, i32 %i4
  %idx_load = load ptr, ptr %arr_gep, align 8
  %name5 = load ptr, ptr %name, align 8
  %4 = call i32 @arc_strcmp(ptr %idx_load, ptr %name5)
  %icmp6 = icmp eq i32 %4, 0
  br i1 %icmp6, label %if_then, label %if_merge

while_exit:                                       ; preds = %while_cond
  ret i8 0

if_then:                                          ; preds = %while_body
  %out_arity7 = load ptr, ptr %out_arity, align 8
  %ptr_deref8 = load ptr, ptr %t, align 8
  %arities = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref8, i32 0, i32 1
  %i9 = load i32, ptr %i, align 4
  %arr_gep10 = getelementptr [64 x i32], ptr %arities, i64 0, i32 %i9
  %idx_load11 = load i32, ptr %arr_gep10, align 4
  store i32 %idx_load11, ptr %out_arity7, align 4
  %out_repl12 = load ptr, ptr %out_repl, align 8
  %ptr_deref13 = load ptr, ptr %t, align 8
  %replacements = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref13, i32 0, i32 2
  %i14 = load i32, ptr %i, align 4
  %arr_gep15 = getelementptr [64 x ptr], ptr %replacements, i64 0, i32 %i14
  %idx_load16 = load ptr, ptr %arr_gep15, align 8
  store ptr %idx_load16, ptr %out_repl12, align 8
  ret i8 1

if_merge:                                         ; preds = %while_body
  %i17 = load i32, ptr %i, align 4
  %add = add i32 %i17, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond
}

define internal void @preproc__NS_pp_func_set(ptr %0, ptr %1, i32 %2, ptr %3) {
entry:
  %t = alloca ptr, align 8
  store ptr %0, ptr %t, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %arity = alloca i32, align 4
  store i32 %2, ptr %arity, align 4
  %repl = alloca ptr, align 8
  store ptr %3, ptr %repl, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_deref = load ptr, ptr %t, align 8
  %count = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref, i32 0, i32 3
  %ptr_deref2 = load ptr, ptr %t, align 8
  %mem_load = load i32, ptr %count, align 4
  %icmp = icmp slt i32 %i1, %mem_load
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %ptr_deref3 = load ptr, ptr %t, align 8
  %names = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref3, i32 0, i32 0
  %i4 = load i32, ptr %i, align 4
  %arr_gep = getelementptr [64 x ptr], ptr %names, i64 0, i32 %i4
  %idx_load = load ptr, ptr %arr_gep, align 8
  %name5 = load ptr, ptr %name, align 8
  %4 = call i32 @arc_strcmp(ptr %idx_load, ptr %name5)
  %icmp6 = icmp eq i32 %4, 0
  br i1 %icmp6, label %if_then, label %if_merge

while_exit:                                       ; preds = %while_cond
  %ptr_deref16 = load ptr, ptr %t, align 8
  %count17 = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref16, i32 0, i32 3
  %ptr_deref18 = load ptr, ptr %t, align 8
  %mem_load19 = load i32, ptr %count17, align 4
  %icmp20 = icmp slt i32 %mem_load19, 64
  br i1 %icmp20, label %if_then21, label %if_else

if_then:                                          ; preds = %while_body
  %ptr_deref7 = load ptr, ptr %t, align 8
  %arities = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref7, i32 0, i32 1
  %i8 = load i32, ptr %i, align 4
  %arr_gep9 = getelementptr [64 x i32], ptr %arities, i64 0, i32 %i8
  %arity10 = load i32, ptr %arity, align 4
  store i32 %arity10, ptr %arr_gep9, align 4
  %ptr_deref11 = load ptr, ptr %t, align 8
  %replacements = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref11, i32 0, i32 2
  %i12 = load i32, ptr %i, align 4
  %arr_gep13 = getelementptr [64 x ptr], ptr %replacements, i64 0, i32 %i12
  %repl14 = load ptr, ptr %repl, align 8
  store ptr %repl14, ptr %arr_gep13, align 8
  ret void

if_merge:                                         ; preds = %while_body
  %i15 = load i32, ptr %i, align 4
  %add = add i32 %i15, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond

if_then21:                                        ; preds = %while_exit
  %ptr_deref23 = load ptr, ptr %t, align 8
  %names24 = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref23, i32 0, i32 0
  %ptr_deref25 = load ptr, ptr %t, align 8
  %count26 = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref25, i32 0, i32 3
  %ptr_deref27 = load ptr, ptr %t, align 8
  %mem_load28 = load i32, ptr %count26, align 4
  %arr_gep29 = getelementptr [64 x ptr], ptr %names24, i64 0, i32 %mem_load28
  %name30 = load ptr, ptr %name, align 8
  store ptr %name30, ptr %arr_gep29, align 8
  %ptr_deref31 = load ptr, ptr %t, align 8
  %arities32 = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref31, i32 0, i32 1
  %ptr_deref33 = load ptr, ptr %t, align 8
  %count34 = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref33, i32 0, i32 3
  %ptr_deref35 = load ptr, ptr %t, align 8
  %mem_load36 = load i32, ptr %count34, align 4
  %arr_gep37 = getelementptr [64 x i32], ptr %arities32, i64 0, i32 %mem_load36
  %arity38 = load i32, ptr %arity, align 4
  store i32 %arity38, ptr %arr_gep37, align 4
  %ptr_deref39 = load ptr, ptr %t, align 8
  %replacements40 = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref39, i32 0, i32 2
  %ptr_deref41 = load ptr, ptr %t, align 8
  %count42 = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref41, i32 0, i32 3
  %ptr_deref43 = load ptr, ptr %t, align 8
  %mem_load44 = load i32, ptr %count42, align 4
  %arr_gep45 = getelementptr [64 x ptr], ptr %replacements40, i64 0, i32 %mem_load44
  %repl46 = load ptr, ptr %repl, align 8
  store ptr %repl46, ptr %arr_gep45, align 8
  %ptr_deref47 = load ptr, ptr %t, align 8
  %count48 = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref47, i32 0, i32 3
  %ptr_deref49 = load ptr, ptr %t, align 8
  %count50 = getelementptr inbounds nuw %pp_func_table, ptr %ptr_deref49, i32 0, i32 3
  %ptr_deref51 = load ptr, ptr %t, align 8
  %mem_load52 = load i32, ptr %count50, align 4
  %add53 = add i32 %mem_load52, 1
  store i32 %add53, ptr %count48, align 4
  br label %if_merge22

if_else:                                          ; preds = %while_exit
  %name54 = load ptr, ptr %name, align 8
  %anon_s = alloca %__anon1_P, align 8
  %anon_f = getelementptr inbounds nuw %__anon1_P, ptr %anon_s, i32 0, i32 0
  store ptr %name54, ptr %anon_f, align 8
  %anon_load = load %__anon1_P, ptr %anon_s, align 8
  %5 = call i32 @aprint__at_args_S__anon1_P(ptr @str.5, %__anon1_P %anon_load)
  br label %if_merge22

if_merge22:                                       ; preds = %if_else, %if_then21
  ret void
}

define internal i8 @preproc__NS_pp_is_func_pattern(ptr %0, ptr %1, ptr %2) {
entry:
  %pat = alloca ptr, align 8
  store ptr %0, ptr %pat, align 8
  %out_name = alloca ptr, align 8
  store ptr %1, ptr %out_name, align 8
  %out_arity = alloca ptr, align 8
  store ptr %2, ptr %out_arity, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  %escape_paren = alloca i32, align 4
  store i32 -1, ptr %escape_paren, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge, %entry
  %i1 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %pat, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i1
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp = icmp ne i8 %idx_load, 0
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i2 = load i32, ptr %i, align 4
  %ptr_load3 = load ptr, ptr %pat, align 8
  %ptr_gep4 = getelementptr i8, ptr %ptr_load3, i32 %i2
  %idx_load5 = load i8, ptr %ptr_gep4, align 1
  %icmp6 = icmp eq i8 %idx_load5, 92
  br i1 %icmp6, label %land_rhs, label %land_merge

while_exit:                                       ; preds = %if_then, %while_cond
  %escape_paren15 = load i32, ptr %escape_paren, align 4
  %icmp16 = icmp slt i32 %escape_paren15, 0
  br i1 %icmp16, label %if_then17, label %if_merge18

land_rhs:                                         ; preds = %while_body
  %i7 = load i32, ptr %i, align 4
  %add = add i32 %i7, 1
  %ptr_load8 = load ptr, ptr %pat, align 8
  %ptr_gep9 = getelementptr i8, ptr %ptr_load8, i32 %add
  %idx_load10 = load i8, ptr %ptr_gep9, align 1
  %icmp11 = icmp eq i8 %idx_load10, 40
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_body
  %land = phi i1 [ false, %while_body ], [ %icmp11, %land_rhs ]
  br i1 %land, label %if_then, label %if_merge

if_then:                                          ; preds = %land_merge
  %i12 = load i32, ptr %i, align 4
  store i32 %i12, ptr %escape_paren, align 4
  br label %while_exit

if_merge:                                         ; preds = %land_merge
  %i13 = load i32, ptr %i, align 4
  %add14 = add i32 %i13, 1
  store i32 %add14, ptr %i, align 4
  br label %while_cond

if_then17:                                        ; preds = %while_exit
  ret i8 0

if_merge18:                                       ; preds = %while_exit
  %out_name19 = load ptr, ptr %out_name, align 8
  %pat20 = load ptr, ptr %pat, align 8
  %escape_paren21 = load i32, ptr %escape_paren, align 4
  %3 = call ptr @preproc__NS_pp_substr_dup(ptr %pat20, i32 %escape_paren21)
  store ptr %3, ptr %out_name19, align 8
  %arity = alloca i32, align 4
  store i32 0, ptr %arity, align 4
  %escape_paren22 = load i32, ptr %escape_paren, align 4
  %add23 = add i32 %escape_paren22, 2
  store i32 %add23, ptr %i, align 4
  br label %while_cond24

while_cond24:                                     ; preds = %if_merge56, %if_merge18
  %i27 = load i32, ptr %i, align 4
  %ptr_load28 = load ptr, ptr %pat, align 8
  %ptr_gep29 = getelementptr i8, ptr %ptr_load28, i32 %i27
  %idx_load30 = load i8, ptr %ptr_gep29, align 1
  %icmp31 = icmp ne i8 %idx_load30, 0
  br i1 %icmp31, label %while_body25, label %while_exit26

while_body25:                                     ; preds = %while_cond24
  %i32 = load i32, ptr %i, align 4
  %ptr_load33 = load ptr, ptr %pat, align 8
  %ptr_gep34 = getelementptr i8, ptr %ptr_load33, i32 %i32
  %idx_load35 = load i8, ptr %ptr_gep34, align 1
  %icmp36 = icmp eq i8 %idx_load35, 40
  br i1 %icmp36, label %land_rhs37, label %land_merge38

while_exit26:                                     ; preds = %while_cond24
  %out_arity61 = load ptr, ptr %out_arity, align 8
  %arity62 = load i32, ptr %arity, align 4
  store i32 %arity62, ptr %out_arity61, align 4
  ret i8 1

land_rhs37:                                       ; preds = %while_body25
  %i39 = load i32, ptr %i, align 4
  %add40 = add i32 %i39, 1
  %ptr_load41 = load ptr, ptr %pat, align 8
  %ptr_gep42 = getelementptr i8, ptr %ptr_load41, i32 %add40
  %idx_load43 = load i8, ptr %ptr_gep42, align 1
  %icmp44 = icmp eq i8 %idx_load43, 91
  br label %land_merge38

land_merge38:                                     ; preds = %land_rhs37, %while_body25
  %land45 = phi i1 [ false, %while_body25 ], [ %icmp44, %land_rhs37 ]
  br i1 %land45, label %land_rhs46, label %land_merge47

land_rhs46:                                       ; preds = %land_merge38
  %i48 = load i32, ptr %i, align 4
  %add49 = add i32 %i48, 2
  %ptr_load50 = load ptr, ptr %pat, align 8
  %ptr_gep51 = getelementptr i8, ptr %ptr_load50, i32 %add49
  %idx_load52 = load i8, ptr %ptr_gep51, align 1
  %icmp53 = icmp eq i8 %idx_load52, 94
  br label %land_merge47

land_merge47:                                     ; preds = %land_rhs46, %land_merge38
  %land54 = phi i1 [ false, %land_merge38 ], [ %icmp53, %land_rhs46 ]
  br i1 %land54, label %if_then55, label %if_merge56

if_then55:                                        ; preds = %land_merge47
  %arity57 = load i32, ptr %arity, align 4
  %add58 = add i32 %arity57, 1
  store i32 %add58, ptr %arity, align 4
  br label %if_merge56

if_merge56:                                       ; preds = %if_then55, %land_merge47
  %i59 = load i32, ptr %i, align 4
  %add60 = add i32 %i59, 1
  store i32 %add60, ptr %i, align 4
  br label %while_cond24
}

define internal ptr @preproc__NS_pp_func_expand(ptr %0, ptr %1, ptr %2, i32 %3, i32 %4, ptr %5) {
entry:
  %ft = alloca ptr, align 8
  store ptr %0, ptr %ft, align 8
  %name = alloca ptr, align 8
  store ptr %1, ptr %name, align 8
  %line = alloca ptr, align 8
  store ptr %2, ptr %line, align 8
  %lparen_pos = alloca i32, align 4
  store i32 %3, ptr %lparen_pos, align 4
  %line_len = alloca i32, align 4
  store i32 %4, ptr %line_len, align 4
  %end_pos = alloca ptr, align 8
  store ptr %5, ptr %end_pos, align 8
  %arity = alloca i32, align 4
  store i32 0, ptr %arity, align 4
  %repl = alloca ptr, align 8
  store ptr null, ptr %repl, align 8
  %ft1 = load ptr, ptr %ft, align 8
  %name2 = load ptr, ptr %name, align 8
  %6 = call i8 @preproc__NS_pp_func_get(ptr %ft1, ptr %name2, ptr %arity, ptr %repl)
  %tobool = icmp ne i8 %6, 0
  %not = xor i1 %tobool, true
  br i1 %not, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  %end_pos3 = load ptr, ptr %end_pos, align 8
  %lparen_pos4 = load i32, ptr %lparen_pos, align 4
  store i32 %lparen_pos4, ptr %end_pos3, align 4
  ret ptr null

if_merge:                                         ; preds = %entry
  %args = alloca [8 x ptr], align 8
  store [8 x ptr] zeroinitializer, ptr %args, align 8
  %arg_lens = alloca [8 x i32], align 4
  store [8 x i32] zeroinitializer, ptr %arg_lens, align 4
  %nargs = alloca i32, align 4
  store i32 0, ptr %nargs, align 4
  %i = alloca i32, align 4
  %lparen_pos5 = load i32, ptr %lparen_pos, align 4
  %add = add i32 %lparen_pos5, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge121, %if_merge
  %i6 = load i32, ptr %i, align 4
  %line_len7 = load i32, ptr %line_len, align 4
  %icmp = icmp slt i32 %i6, %line_len7
  br i1 %icmp, label %land_rhs, label %land_merge

while_body:                                       ; preds = %land_merge
  br label %while_cond10

while_exit:                                       ; preds = %if_else120, %land_merge
  br label %while_cond124

land_rhs:                                         ; preds = %while_cond
  %nargs8 = load i32, ptr %nargs, align 4
  %icmp9 = icmp slt i32 %nargs8, 8
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond
  %land = phi i1 [ false, %while_cond ], [ %icmp9, %land_rhs ]
  br i1 %land, label %while_body, label %while_exit

while_cond10:                                     ; preds = %while_body11, %while_body
  %i13 = load i32, ptr %i, align 4
  %line_len14 = load i32, ptr %line_len, align 4
  %icmp15 = icmp slt i32 %i13, %line_len14
  br i1 %icmp15, label %land_rhs16, label %land_merge17

while_body11:                                     ; preds = %land_merge17
  %i26 = load i32, ptr %i, align 4
  %add27 = add i32 %i26, 1
  store i32 %add27, ptr %i, align 4
  br label %while_cond10

while_exit12:                                     ; preds = %land_merge17
  %arg_start = alloca i32, align 4
  %i28 = load i32, ptr %i, align 4
  store i32 %i28, ptr %arg_start, align 4
  %depth = alloca i32, align 4
  store i32 0, ptr %depth, align 4
  br label %while_cond29

land_rhs16:                                       ; preds = %while_cond10
  %i18 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %line, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i18
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp19 = icmp eq i8 %idx_load, 32
  br i1 %icmp19, label %lor_merge, label %lor_rhs

land_merge17:                                     ; preds = %lor_merge, %while_cond10
  %land25 = phi i1 [ false, %while_cond10 ], [ %lor, %lor_merge ]
  br i1 %land25, label %while_body11, label %while_exit12

lor_rhs:                                          ; preds = %land_rhs16
  %i20 = load i32, ptr %i, align 4
  %ptr_load21 = load ptr, ptr %line, align 8
  %ptr_gep22 = getelementptr i8, ptr %ptr_load21, i32 %i20
  %idx_load23 = load i8, ptr %ptr_gep22, align 1
  %icmp24 = icmp eq i8 %idx_load23, 9
  br label %lor_merge

lor_merge:                                        ; preds = %lor_rhs, %land_rhs16
  %lor = phi i1 [ true, %land_rhs16 ], [ %icmp24, %lor_rhs ]
  br label %land_merge17

while_cond29:                                     ; preds = %if_merge41, %while_exit12
  %i32 = load i32, ptr %i, align 4
  %line_len33 = load i32, ptr %line_len, align 4
  %icmp34 = icmp slt i32 %i32, %line_len33
  br i1 %icmp34, label %while_body30, label %while_exit31

while_body30:                                     ; preds = %while_cond29
  %i35 = load i32, ptr %i, align 4
  %ptr_load36 = load ptr, ptr %line, align 8
  %ptr_gep37 = getelementptr i8, ptr %ptr_load36, i32 %i35
  %idx_load38 = load i8, ptr %ptr_gep37, align 1
  %icmp39 = icmp eq i8 %idx_load38, 40
  br i1 %icmp39, label %if_then40, label %if_else

while_exit31:                                     ; preds = %if_then67, %if_then54, %while_cond29
  %arg_end = alloca i32, align 4
  %i71 = load i32, ptr %i, align 4
  store i32 %i71, ptr %arg_end, align 4
  br label %while_cond72

if_then40:                                        ; preds = %while_body30
  %depth42 = load i32, ptr %depth, align 4
  %add43 = add i32 %depth42, 1
  store i32 %add43, ptr %depth, align 4
  br label %if_merge41

if_else:                                          ; preds = %while_body30
  %i44 = load i32, ptr %i, align 4
  %ptr_load45 = load ptr, ptr %line, align 8
  %ptr_gep46 = getelementptr i8, ptr %ptr_load45, i32 %i44
  %idx_load47 = load i8, ptr %ptr_gep46, align 1
  %icmp48 = icmp eq i8 %idx_load47, 41
  br i1 %icmp48, label %if_then49, label %if_else50

if_merge41:                                       ; preds = %if_merge51, %if_then40
  %i69 = load i32, ptr %i, align 4
  %add70 = add i32 %i69, 1
  store i32 %add70, ptr %i, align 4
  br label %while_cond29

if_then49:                                        ; preds = %if_else
  %depth52 = load i32, ptr %depth, align 4
  %icmp53 = icmp eq i32 %depth52, 0
  br i1 %icmp53, label %if_then54, label %if_merge55

if_else50:                                        ; preds = %if_else
  %i57 = load i32, ptr %i, align 4
  %ptr_load58 = load ptr, ptr %line, align 8
  %ptr_gep59 = getelementptr i8, ptr %ptr_load58, i32 %i57
  %idx_load60 = load i8, ptr %ptr_gep59, align 1
  %icmp61 = icmp eq i8 %idx_load60, 44
  br i1 %icmp61, label %land_rhs62, label %land_merge63

if_merge51:                                       ; preds = %if_merge68, %if_merge55
  br label %if_merge41

if_then54:                                        ; preds = %if_then49
  br label %while_exit31

if_merge55:                                       ; preds = %if_then49
  %depth56 = load i32, ptr %depth, align 4
  %sub = sub i32 %depth56, 1
  store i32 %sub, ptr %depth, align 4
  br label %if_merge51

land_rhs62:                                       ; preds = %if_else50
  %depth64 = load i32, ptr %depth, align 4
  %icmp65 = icmp eq i32 %depth64, 0
  br label %land_merge63

land_merge63:                                     ; preds = %land_rhs62, %if_else50
  %land66 = phi i1 [ false, %if_else50 ], [ %icmp65, %land_rhs62 ]
  br i1 %land66, label %if_then67, label %if_merge68

if_then67:                                        ; preds = %land_merge63
  br label %while_exit31

if_merge68:                                       ; preds = %land_merge63
  br label %if_merge51

while_cond72:                                     ; preds = %while_body73, %while_exit31
  %arg_end75 = load i32, ptr %arg_end, align 4
  %arg_start76 = load i32, ptr %arg_start, align 4
  %icmp77 = icmp sgt i32 %arg_end75, %arg_start76
  br i1 %icmp77, label %land_rhs78, label %land_merge79

while_body73:                                     ; preds = %land_merge79
  %arg_end96 = load i32, ptr %arg_end, align 4
  %sub97 = sub i32 %arg_end96, 1
  store i32 %sub97, ptr %arg_end, align 4
  br label %while_cond72

while_exit74:                                     ; preds = %land_merge79
  %nargs98 = load i32, ptr %nargs, align 4
  %arr_gep = getelementptr [8 x ptr], ptr %args, i64 0, i32 %nargs98
  %line99 = load ptr, ptr %line, align 8
  %arg_start100 = load i32, ptr %arg_start, align 4
  %ptr_add = getelementptr i8, ptr %line99, i32 %arg_start100
  store ptr %ptr_add, ptr %arr_gep, align 8
  %nargs101 = load i32, ptr %nargs, align 4
  %arr_gep102 = getelementptr [8 x i32], ptr %arg_lens, i64 0, i32 %nargs101
  %arg_end103 = load i32, ptr %arg_end, align 4
  %arg_start104 = load i32, ptr %arg_start, align 4
  %sub105 = sub i32 %arg_end103, %arg_start104
  store i32 %sub105, ptr %arr_gep102, align 4
  %nargs106 = load i32, ptr %nargs, align 4
  %add107 = add i32 %nargs106, 1
  store i32 %add107, ptr %nargs, align 4
  %i108 = load i32, ptr %i, align 4
  %line_len109 = load i32, ptr %line_len, align 4
  %icmp110 = icmp slt i32 %i108, %line_len109
  br i1 %icmp110, label %land_rhs111, label %land_merge112

land_rhs78:                                       ; preds = %while_cond72
  %arg_end80 = load i32, ptr %arg_end, align 4
  %sub81 = sub i32 %arg_end80, 1
  %ptr_load82 = load ptr, ptr %line, align 8
  %ptr_gep83 = getelementptr i8, ptr %ptr_load82, i32 %sub81
  %idx_load84 = load i8, ptr %ptr_gep83, align 1
  %icmp85 = icmp eq i8 %idx_load84, 32
  br i1 %icmp85, label %lor_merge87, label %lor_rhs86

land_merge79:                                     ; preds = %lor_merge87, %while_cond72
  %land95 = phi i1 [ false, %while_cond72 ], [ %lor94, %lor_merge87 ]
  br i1 %land95, label %while_body73, label %while_exit74

lor_rhs86:                                        ; preds = %land_rhs78
  %arg_end88 = load i32, ptr %arg_end, align 4
  %sub89 = sub i32 %arg_end88, 1
  %ptr_load90 = load ptr, ptr %line, align 8
  %ptr_gep91 = getelementptr i8, ptr %ptr_load90, i32 %sub89
  %idx_load92 = load i8, ptr %ptr_gep91, align 1
  %icmp93 = icmp eq i8 %idx_load92, 9
  br label %lor_merge87

lor_merge87:                                      ; preds = %lor_rhs86, %land_rhs78
  %lor94 = phi i1 [ true, %land_rhs78 ], [ %icmp93, %lor_rhs86 ]
  br label %land_merge79

land_rhs111:                                      ; preds = %while_exit74
  %i113 = load i32, ptr %i, align 4
  %ptr_load114 = load ptr, ptr %line, align 8
  %ptr_gep115 = getelementptr i8, ptr %ptr_load114, i32 %i113
  %idx_load116 = load i8, ptr %ptr_gep115, align 1
  %icmp117 = icmp eq i8 %idx_load116, 44
  br label %land_merge112

land_merge112:                                    ; preds = %land_rhs111, %while_exit74
  %land118 = phi i1 [ false, %while_exit74 ], [ %icmp117, %land_rhs111 ]
  br i1 %land118, label %if_then119, label %if_else120

if_then119:                                       ; preds = %land_merge112
  %i122 = load i32, ptr %i, align 4
  %add123 = add i32 %i122, 1
  store i32 %add123, ptr %i, align 4
  br label %if_merge121

if_else120:                                       ; preds = %land_merge112
  br label %while_exit

if_merge121:                                      ; preds = %if_then119
  br label %while_cond

while_cond124:                                    ; preds = %while_body125, %while_exit
  %i127 = load i32, ptr %i, align 4
  %line_len128 = load i32, ptr %line_len, align 4
  %icmp129 = icmp slt i32 %i127, %line_len128
  br i1 %icmp129, label %land_rhs130, label %land_merge131

while_body125:                                    ; preds = %land_merge131
  %i138 = load i32, ptr %i, align 4
  %add139 = add i32 %i138, 1
  store i32 %add139, ptr %i, align 4
  br label %while_cond124

while_exit126:                                    ; preds = %land_merge131
  %i140 = load i32, ptr %i, align 4
  %line_len141 = load i32, ptr %line_len, align 4
  %icmp142 = icmp slt i32 %i140, %line_len141
  br i1 %icmp142, label %if_then143, label %if_merge144

land_rhs130:                                      ; preds = %while_cond124
  %i132 = load i32, ptr %i, align 4
  %ptr_load133 = load ptr, ptr %line, align 8
  %ptr_gep134 = getelementptr i8, ptr %ptr_load133, i32 %i132
  %idx_load135 = load i8, ptr %ptr_gep134, align 1
  %icmp136 = icmp ne i8 %idx_load135, 41
  br label %land_merge131

land_merge131:                                    ; preds = %land_rhs130, %while_cond124
  %land137 = phi i1 [ false, %while_cond124 ], [ %icmp136, %land_rhs130 ]
  br i1 %land137, label %while_body125, label %while_exit126

if_then143:                                       ; preds = %while_exit126
  %i145 = load i32, ptr %i, align 4
  %add146 = add i32 %i145, 1
  store i32 %add146, ptr %i, align 4
  br label %if_merge144

if_merge144:                                      ; preds = %if_then143, %while_exit126
  %end_pos147 = load ptr, ptr %end_pos, align 8
  %i148 = load i32, ptr %i, align 4
  store i32 %i148, ptr %end_pos147, align 4
  %out = alloca %strbuf, align 8
  store %strbuf zeroinitializer, ptr %out, align 8
  call void @preproc__NS_strbuf_init(ptr %out)
  %repl149 = load ptr, ptr %repl, align 8
  %icmp150 = icmp ne ptr %repl149, null
  br i1 %icmp150, label %if_then151, label %if_merge152

if_then151:                                       ; preds = %if_merge144
  %ri = alloca i32, align 4
  store i32 0, ptr %ri, align 4
  br label %while_cond153

if_merge152:                                      ; preds = %while_exit155, %if_merge144
  %7 = call ptr @preproc__NS_strbuf_finish(ptr %out)
  ret ptr %7

while_cond153:                                    ; preds = %if_merge186, %if_then151
  %ri156 = load i32, ptr %ri, align 4
  %ptr_load157 = load ptr, ptr %repl, align 8
  %ptr_gep158 = getelementptr i8, ptr %ptr_load157, i32 %ri156
  %idx_load159 = load i8, ptr %ptr_gep158, align 1
  %icmp160 = icmp ne i8 %idx_load159, 0
  br i1 %icmp160, label %while_body154, label %while_exit155

while_body154:                                    ; preds = %while_cond153
  %ri161 = load i32, ptr %ri, align 4
  %ptr_load162 = load ptr, ptr %repl, align 8
  %ptr_gep163 = getelementptr i8, ptr %ptr_load162, i32 %ri161
  %idx_load164 = load i8, ptr %ptr_gep163, align 1
  %icmp165 = icmp eq i8 %idx_load164, 37
  br i1 %icmp165, label %land_rhs166, label %land_merge167

while_exit155:                                    ; preds = %while_cond153
  br label %if_merge152

land_rhs166:                                      ; preds = %while_body154
  %ri168 = load i32, ptr %ri, align 4
  %add169 = add i32 %ri168, 1
  %ptr_load170 = load ptr, ptr %repl, align 8
  %ptr_gep171 = getelementptr i8, ptr %ptr_load170, i32 %add169
  %idx_load172 = load i8, ptr %ptr_gep171, align 1
  %icmp173 = icmp sge i8 %idx_load172, 49
  br label %land_merge167

land_merge167:                                    ; preds = %land_rhs166, %while_body154
  %land174 = phi i1 [ false, %while_body154 ], [ %icmp173, %land_rhs166 ]
  br i1 %land174, label %land_rhs175, label %land_merge176

land_rhs175:                                      ; preds = %land_merge167
  %ri177 = load i32, ptr %ri, align 4
  %add178 = add i32 %ri177, 1
  %ptr_load179 = load ptr, ptr %repl, align 8
  %ptr_gep180 = getelementptr i8, ptr %ptr_load179, i32 %add178
  %idx_load181 = load i8, ptr %ptr_gep180, align 1
  %icmp182 = icmp sle i8 %idx_load181, 57
  br label %land_merge176

land_merge176:                                    ; preds = %land_rhs175, %land_merge167
  %land183 = phi i1 [ false, %land_merge167 ], [ %icmp182, %land_rhs175 ]
  br i1 %land183, label %if_then184, label %if_else185

if_then184:                                       ; preds = %land_merge176
  %idx = alloca i32, align 4
  %ri187 = load i32, ptr %ri, align 4
  %add188 = add i32 %ri187, 1
  %ptr_load189 = load ptr, ptr %repl, align 8
  %ptr_gep190 = getelementptr i8, ptr %ptr_load189, i32 %add188
  %idx_load191 = load i8, ptr %ptr_gep190, align 1
  %sub192 = sub i8 %idx_load191, 49
  %sext = sext i8 %sub192 to i32
  store i32 %sext, ptr %idx, align 4
  %idx193 = load i32, ptr %idx, align 4
  %nargs194 = load i32, ptr %nargs, align 4
  %icmp195 = icmp slt i32 %idx193, %nargs194
  br i1 %icmp195, label %if_then196, label %if_merge197

if_else185:                                       ; preds = %land_merge176
  %ri210 = load i32, ptr %ri, align 4
  %ptr_load211 = load ptr, ptr %repl, align 8
  %ptr_gep212 = getelementptr i8, ptr %ptr_load211, i32 %ri210
  %idx_load213 = load i8, ptr %ptr_gep212, align 1
  call void @preproc__NS_strbuf_push(ptr %out, i8 %idx_load213)
  %ri214 = load i32, ptr %ri, align 4
  %add215 = add i32 %ri214, 1
  store i32 %add215, ptr %ri, align 4
  br label %if_merge186

if_merge186:                                      ; preds = %if_else185, %if_merge197
  br label %while_cond153

if_then196:                                       ; preds = %if_then184
  %idx198 = load i32, ptr %idx, align 4
  %idx64 = sext i32 %idx198 to i64
  %oob_cmp = icmp uge i64 %idx64, 8
  br i1 %oob_cmp, label %oob_abort, label %bounds_ok

if_merge197:                                      ; preds = %bounds_ok205, %if_then184
  %ri208 = load i32, ptr %ri, align 4
  %add209 = add i32 %ri208, 2
  store i32 %add209, ptr %ri, align 4
  br label %if_merge186

oob_abort:                                        ; preds = %if_then196
  call void @abort()
  unreachable

bounds_ok:                                        ; preds = %if_then196
  %arr_gep199 = getelementptr [8 x ptr], ptr %args, i64 0, i32 %idx198
  %idx_load200 = load ptr, ptr %arr_gep199, align 8
  %idx201 = load i32, ptr %idx, align 4
  %idx64202 = sext i32 %idx201 to i64
  %oob_cmp203 = icmp uge i64 %idx64202, 8
  br i1 %oob_cmp203, label %oob_abort204, label %bounds_ok205

oob_abort204:                                     ; preds = %bounds_ok
  call void @abort()
  unreachable

bounds_ok205:                                     ; preds = %bounds_ok
  %arr_gep206 = getelementptr [8 x i32], ptr %arg_lens, i64 0, i32 %idx201
  %idx_load207 = load i32, ptr %arr_gep206, align 4
  %zext = zext i32 %idx_load207 to i64
  call void @preproc__NS_strbuf_append(ptr %out, ptr %idx_load200, i64 %zext)
  br label %if_merge197
}

define internal i8 @preproc__NS_pp_is_id_start(i8 %0) {
entry:
  %c = alloca i8, align 1
  store i8 %0, ptr %c, align 1
  %c1 = load i8, ptr %c, align 1
  %icmp = icmp sge i8 %c1, 97
  br i1 %icmp, label %land_rhs, label %land_merge

land_rhs:                                         ; preds = %entry
  %c2 = load i8, ptr %c, align 1
  %icmp3 = icmp sle i8 %c2, 122
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %entry
  %land = phi i1 [ false, %entry ], [ %icmp3, %land_rhs ]
  br i1 %land, label %lor_merge, label %lor_rhs

lor_rhs:                                          ; preds = %land_merge
  %c4 = load i8, ptr %c, align 1
  %icmp5 = icmp sge i8 %c4, 65
  br i1 %icmp5, label %land_rhs6, label %land_merge7

lor_merge:                                        ; preds = %land_merge7, %land_merge
  %lor = phi i1 [ true, %land_merge ], [ %land10, %land_merge7 ]
  br i1 %lor, label %lor_merge12, label %lor_rhs11

land_rhs6:                                        ; preds = %lor_rhs
  %c8 = load i8, ptr %c, align 1
  %icmp9 = icmp sle i8 %c8, 90
  br label %land_merge7

land_merge7:                                      ; preds = %land_rhs6, %lor_rhs
  %land10 = phi i1 [ false, %lor_rhs ], [ %icmp9, %land_rhs6 ]
  br label %lor_merge

lor_rhs11:                                        ; preds = %lor_merge
  %c13 = load i8, ptr %c, align 1
  %icmp14 = icmp eq i8 %c13, 95
  br label %lor_merge12

lor_merge12:                                      ; preds = %lor_rhs11, %lor_merge
  %lor15 = phi i1 [ true, %lor_merge ], [ %icmp14, %lor_rhs11 ]
  %zext = zext i1 %lor15 to i8
  ret i8 %zext
}

define internal i8 @preproc__NS_pp_is_id_cont(i8 %0) {
entry:
  %c = alloca i8, align 1
  store i8 %0, ptr %c, align 1
  %c1 = load i8, ptr %c, align 1
  %1 = call i8 @preproc__NS_pp_is_id_start(i8 %c1)
  %tobool = icmp ne i8 %1, 0
  br i1 %tobool, label %lor_merge, label %lor_rhs

lor_rhs:                                          ; preds = %entry
  %c2 = load i8, ptr %c, align 1
  %icmp = icmp sge i8 %c2, 48
  br i1 %icmp, label %land_rhs, label %land_merge

lor_merge:                                        ; preds = %land_merge, %entry
  %lor = phi i1 [ true, %entry ], [ %land, %land_merge ]
  %zext = zext i1 %lor to i8
  ret i8 %zext

land_rhs:                                         ; preds = %lor_rhs
  %c3 = load i8, ptr %c, align 1
  %icmp4 = icmp sle i8 %c3, 57
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %lor_rhs
  %land = phi i1 [ false, %lor_rhs ], [ %icmp4, %land_rhs ]
  br label %lor_merge
}

define internal ptr @preproc__NS_pp_substr_dup(ptr %0, i32 %1) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %len = alloca i32, align 4
  store i32 %1, ptr %len, align 4
  %r = alloca ptr, align 8
  %len1 = load i32, ptr %len, align 4
  %add = add i32 %len1, 1
  %zext = zext i32 %add to i64
  %2 = call ptr @arc_malloc.1(i64 %zext)
  store ptr %2, ptr %r, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %while_body, %entry
  %i2 = load i32, ptr %i, align 4
  %len3 = load i32, ptr %len, align 4
  %icmp = icmp slt i32 %i2, %len3
  br i1 %icmp, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %i4 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %r, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i4
  %i5 = load i32, ptr %i, align 4
  %ptr_load6 = load ptr, ptr %s, align 8
  %ptr_gep7 = getelementptr i8, ptr %ptr_load6, i32 %i5
  %idx_load = load i8, ptr %ptr_gep7, align 1
  store i8 %idx_load, ptr %ptr_gep, align 1
  %i8 = load i32, ptr %i, align 4
  %add9 = add i32 %i8, 1
  store i32 %add9, ptr %i, align 4
  br label %while_cond

while_exit:                                       ; preds = %while_cond
  %len10 = load i32, ptr %len, align 4
  %ptr_load11 = load ptr, ptr %r, align 8
  %ptr_gep12 = getelementptr i8, ptr %ptr_load11, i32 %len10
  store i8 0, ptr %ptr_gep12, align 1
  %r13 = load ptr, ptr %r, align 8
  ret ptr %r13
}

define internal ptr @preproc__NS_pp_extract_angle(ptr %0, ptr %1) {
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
  br i1 %icmp, label %lor_merge, label %lor_rhs

while_body:                                       ; preds = %lor_merge
  %s5 = load ptr, ptr %s, align 8
  %ptr_add = getelementptr i8, ptr %s5, i32 1
  store ptr %ptr_add, ptr %s, align 8
  br label %while_cond

while_exit:                                       ; preds = %lor_merge
  %s6 = load ptr, ptr %s, align 8
  %deref7 = load i8, ptr %s6, align 1
  %icmp8 = icmp ne i8 %deref7, 60
  br i1 %icmp8, label %if_then, label %if_merge

lor_rhs:                                          ; preds = %while_cond
  %s2 = load ptr, ptr %s, align 8
  %deref3 = load i8, ptr %s2, align 1
  %icmp4 = icmp eq i8 %deref3, 9
  br label %lor_merge

lor_merge:                                        ; preds = %lor_rhs, %while_cond
  %lor = phi i1 [ true, %while_cond ], [ %icmp4, %lor_rhs ]
  br i1 %lor, label %while_body, label %while_exit

if_then:                                          ; preds = %while_exit
  %out_len9 = load ptr, ptr %out_len, align 8
  store i32 0, ptr %out_len9, align 4
  ret ptr null

if_merge:                                         ; preds = %while_exit
  %s10 = load ptr, ptr %s, align 8
  %ptr_add11 = getelementptr i8, ptr %s10, i32 1
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
  br i1 %icmp18, label %land_rhs, label %land_merge

while_body14:                                     ; preds = %land_merge
  %s21 = load ptr, ptr %s, align 8
  %deref22 = load i8, ptr %s21, align 1
  %icmp23 = icmp eq i8 %deref22, 60
  br i1 %icmp23, label %if_then24, label %if_else

while_exit15:                                     ; preds = %land_merge
  %out_len41 = load ptr, ptr %out_len, align 8
  %len42 = load i32, ptr %len, align 4
  store i32 %len42, ptr %out_len41, align 4
  %start43 = load ptr, ptr %start, align 8
  ret ptr %start43

land_rhs:                                         ; preds = %while_cond13
  %depth19 = load i32, ptr %depth, align 4
  %icmp20 = icmp sgt i32 %depth19, 0
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond13
  %land = phi i1 [ false, %while_cond13 ], [ %icmp20, %land_rhs ]
  br i1 %land, label %while_body14, label %while_exit15

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
  %ptr_add40 = getelementptr i8, ptr %s39, i32 1
  store ptr %ptr_add40, ptr %s, align 8
  br label %if_merge36

if_merge36:                                       ; preds = %if_then35, %if_merge25
  br label %while_cond13
}

define internal ptr @preproc__NS_pp_extract_angle_smart(ptr %0, ptr %1) {
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
  br i1 %icmp, label %lor_merge, label %lor_rhs

while_body:                                       ; preds = %lor_merge
  %s5 = load ptr, ptr %s, align 8
  %ptr_add = getelementptr i8, ptr %s5, i32 1
  store ptr %ptr_add, ptr %s, align 8
  br label %while_cond

while_exit:                                       ; preds = %lor_merge
  %s6 = load ptr, ptr %s, align 8
  %deref7 = load i8, ptr %s6, align 1
  %icmp8 = icmp ne i8 %deref7, 60
  br i1 %icmp8, label %if_then, label %if_merge

lor_rhs:                                          ; preds = %while_cond
  %s2 = load ptr, ptr %s, align 8
  %deref3 = load i8, ptr %s2, align 1
  %icmp4 = icmp eq i8 %deref3, 9
  br label %lor_merge

lor_merge:                                        ; preds = %lor_rhs, %while_cond
  %lor = phi i1 [ true, %while_cond ], [ %icmp4, %lor_rhs ]
  br i1 %lor, label %while_body, label %while_exit

if_then:                                          ; preds = %while_exit
  %out_len9 = load ptr, ptr %out_len, align 8
  store i32 0, ptr %out_len9, align 4
  ret ptr null

if_merge:                                         ; preds = %while_exit
  %s10 = load ptr, ptr %s, align 8
  %ptr_add11 = getelementptr i8, ptr %s10, i32 1
  store ptr %ptr_add11, ptr %s, align 8
  %start = alloca ptr, align 8
  %s12 = load ptr, ptr %s, align 8
  store ptr %s12, ptr %start, align 8
  %line_end = alloca i32, align 4
  store i32 0, ptr %line_end, align 4
  br label %while_cond13

while_cond13:                                     ; preds = %while_body14, %if_merge
  %line_end16 = load i32, ptr %line_end, align 4
  %ptr_load = load ptr, ptr %s, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %line_end16
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp17 = icmp ne i8 %idx_load, 0
  br i1 %icmp17, label %land_rhs, label %land_merge

while_body14:                                     ; preds = %land_merge24
  %line_end31 = load i32, ptr %line_end, align 4
  %add = add i32 %line_end31, 1
  store i32 %add, ptr %line_end, align 4
  br label %while_cond13

while_exit15:                                     ; preds = %land_merge24
  %best = alloca i32, align 4
  store i32 -1, ptr %best, align 4
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond32

land_rhs:                                         ; preds = %while_cond13
  %line_end18 = load i32, ptr %line_end, align 4
  %ptr_load19 = load ptr, ptr %s, align 8
  %ptr_gep20 = getelementptr i8, ptr %ptr_load19, i32 %line_end18
  %idx_load21 = load i8, ptr %ptr_gep20, align 1
  %icmp22 = icmp ne i8 %idx_load21, 10
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond13
  %land = phi i1 [ false, %while_cond13 ], [ %icmp22, %land_rhs ]
  br i1 %land, label %land_rhs23, label %land_merge24

land_rhs23:                                       ; preds = %land_merge
  %line_end25 = load i32, ptr %line_end, align 4
  %ptr_load26 = load ptr, ptr %s, align 8
  %ptr_gep27 = getelementptr i8, ptr %ptr_load26, i32 %line_end25
  %idx_load28 = load i8, ptr %ptr_gep27, align 1
  %icmp29 = icmp ne i8 %idx_load28, 13
  br label %land_merge24

land_merge24:                                     ; preds = %land_rhs23, %land_merge
  %land30 = phi i1 [ false, %land_merge ], [ %icmp29, %land_rhs23 ]
  br i1 %land30, label %while_body14, label %while_exit15

while_cond32:                                     ; preds = %if_merge44, %while_exit15
  %i35 = load i32, ptr %i, align 4
  %line_end36 = load i32, ptr %line_end, align 4
  %icmp37 = icmp slt i32 %i35, %line_end36
  br i1 %icmp37, label %while_body33, label %while_exit34

while_body33:                                     ; preds = %while_cond32
  %i38 = load i32, ptr %i, align 4
  %ptr_load39 = load ptr, ptr %s, align 8
  %ptr_gep40 = getelementptr i8, ptr %ptr_load39, i32 %i38
  %idx_load41 = load i8, ptr %ptr_gep40, align 1
  %icmp42 = icmp eq i8 %idx_load41, 62
  br i1 %icmp42, label %if_then43, label %if_merge44

while_exit34:                                     ; preds = %if_then82, %while_cond32
  %best87 = load i32, ptr %best, align 4
  %icmp88 = icmp slt i32 %best87, 0
  br i1 %icmp88, label %if_then89, label %if_merge90

if_then43:                                        ; preds = %while_body33
  %j = alloca i32, align 4
  %i45 = load i32, ptr %i, align 4
  %add46 = add i32 %i45, 1
  store i32 %add46, ptr %j, align 4
  br label %while_cond47

if_merge44:                                       ; preds = %if_merge83, %while_body33
  %i85 = load i32, ptr %i, align 4
  %add86 = add i32 %i85, 1
  store i32 %add86, ptr %i, align 4
  br label %while_cond32

while_cond47:                                     ; preds = %while_body48, %if_then43
  %j50 = load i32, ptr %j, align 4
  %line_end51 = load i32, ptr %line_end, align 4
  %icmp52 = icmp slt i32 %j50, %line_end51
  br i1 %icmp52, label %land_rhs53, label %land_merge54

while_body48:                                     ; preds = %land_merge54
  %j69 = load i32, ptr %j, align 4
  %add70 = add i32 %j69, 1
  store i32 %add70, ptr %j, align 4
  br label %while_cond47

while_exit49:                                     ; preds = %land_merge54
  %j71 = load i32, ptr %j, align 4
  %line_end72 = load i32, ptr %line_end, align 4
  %icmp73 = icmp sge i32 %j71, %line_end72
  br i1 %icmp73, label %lor_merge75, label %lor_rhs74

land_rhs53:                                       ; preds = %while_cond47
  %j55 = load i32, ptr %j, align 4
  %ptr_load56 = load ptr, ptr %s, align 8
  %ptr_gep57 = getelementptr i8, ptr %ptr_load56, i32 %j55
  %idx_load58 = load i8, ptr %ptr_gep57, align 1
  %icmp59 = icmp eq i8 %idx_load58, 32
  br i1 %icmp59, label %lor_merge61, label %lor_rhs60

land_merge54:                                     ; preds = %lor_merge61, %while_cond47
  %land68 = phi i1 [ false, %while_cond47 ], [ %lor67, %lor_merge61 ]
  br i1 %land68, label %while_body48, label %while_exit49

lor_rhs60:                                        ; preds = %land_rhs53
  %j62 = load i32, ptr %j, align 4
  %ptr_load63 = load ptr, ptr %s, align 8
  %ptr_gep64 = getelementptr i8, ptr %ptr_load63, i32 %j62
  %idx_load65 = load i8, ptr %ptr_gep64, align 1
  %icmp66 = icmp eq i8 %idx_load65, 9
  br label %lor_merge61

lor_merge61:                                      ; preds = %lor_rhs60, %land_rhs53
  %lor67 = phi i1 [ true, %land_rhs53 ], [ %icmp66, %lor_rhs60 ]
  br label %land_merge54

lor_rhs74:                                        ; preds = %while_exit49
  %j76 = load i32, ptr %j, align 4
  %ptr_load77 = load ptr, ptr %s, align 8
  %ptr_gep78 = getelementptr i8, ptr %ptr_load77, i32 %j76
  %idx_load79 = load i8, ptr %ptr_gep78, align 1
  %icmp80 = icmp eq i8 %idx_load79, 60
  br label %lor_merge75

lor_merge75:                                      ; preds = %lor_rhs74, %while_exit49
  %lor81 = phi i1 [ true, %while_exit49 ], [ %icmp80, %lor_rhs74 ]
  br i1 %lor81, label %if_then82, label %if_merge83

if_then82:                                        ; preds = %lor_merge75
  %i84 = load i32, ptr %i, align 4
  store i32 %i84, ptr %best, align 4
  br label %while_exit34

if_merge83:                                       ; preds = %lor_merge75
  br label %if_merge44

if_then89:                                        ; preds = %while_exit34
  %line_end91 = load i32, ptr %line_end, align 4
  %sub = sub i32 %line_end91, 1
  store i32 %sub, ptr %i, align 4
  br label %while_cond92

if_merge90:                                       ; preds = %if_merge110, %while_exit34
  %best112 = load i32, ptr %best, align 4
  %icmp113 = icmp slt i32 %best112, 0
  br i1 %icmp113, label %if_then114, label %if_merge115

while_cond92:                                     ; preds = %while_body93, %if_then89
  %i95 = load i32, ptr %i, align 4
  %icmp96 = icmp sge i32 %i95, 0
  br i1 %icmp96, label %land_rhs97, label %land_merge98

while_body93:                                     ; preds = %land_merge98
  %i105 = load i32, ptr %i, align 4
  %sub106 = sub i32 %i105, 1
  store i32 %sub106, ptr %i, align 4
  br label %while_cond92

while_exit94:                                     ; preds = %land_merge98
  %i107 = load i32, ptr %i, align 4
  %icmp108 = icmp sge i32 %i107, 0
  br i1 %icmp108, label %if_then109, label %if_merge110

land_rhs97:                                       ; preds = %while_cond92
  %i99 = load i32, ptr %i, align 4
  %ptr_load100 = load ptr, ptr %s, align 8
  %ptr_gep101 = getelementptr i8, ptr %ptr_load100, i32 %i99
  %idx_load102 = load i8, ptr %ptr_gep101, align 1
  %icmp103 = icmp ne i8 %idx_load102, 62
  br label %land_merge98

land_merge98:                                     ; preds = %land_rhs97, %while_cond92
  %land104 = phi i1 [ false, %while_cond92 ], [ %icmp103, %land_rhs97 ]
  br i1 %land104, label %while_body93, label %while_exit94

if_then109:                                       ; preds = %while_exit94
  %i111 = load i32, ptr %i, align 4
  store i32 %i111, ptr %best, align 4
  br label %if_merge110

if_merge110:                                      ; preds = %if_then109, %while_exit94
  br label %if_merge90

if_then114:                                       ; preds = %if_merge90
  %out_len116 = load ptr, ptr %out_len, align 8
  store i32 0, ptr %out_len116, align 4
  ret ptr null

if_merge115:                                      ; preds = %if_merge90
  %out_len117 = load ptr, ptr %out_len, align 8
  %best118 = load i32, ptr %best, align 4
  store i32 %best118, ptr %out_len117, align 4
  %start119 = load ptr, ptr %start, align 8
  ret ptr %start119
}

define internal void @preproc__NS_pp_apply(ptr %0, ptr %1, ptr %2, i32 %3, ptr %4) {
entry:
  %t = alloca ptr, align 8
  store ptr %0, ptr %t, align 8
  %ft = alloca ptr, align 8
  store ptr %1, ptr %ft, align 8
  %line = alloca ptr, align 8
  store ptr %2, ptr %line, align 8
  %line_len = alloca i32, align 4
  store i32 %3, ptr %line_len, align 4
  %out = alloca ptr, align 8
  store ptr %4, ptr %out, align 8
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge230, %if_merge267, %if_then311, %if_then258, %while_exit155, %if_merge114, %if_merge52, %entry
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
  %c60 = load i8, ptr %c, align 1
  %icmp61 = icmp eq i8 %c60, 39
  br i1 %icmp61, label %if_then62, label %if_merge63

while_cond9:                                      ; preds = %if_merge33, %if_then
  %i12 = load i32, ptr %i, align 4
  %line_len13 = load i32, ptr %line_len, align 4
  %icmp14 = icmp slt i32 %i12, %line_len13
  br i1 %icmp14, label %land_rhs, label %land_merge

while_body10:                                     ; preds = %land_merge
  %i20 = load i32, ptr %i, align 4
  %ptr_load21 = load ptr, ptr %line, align 8
  %ptr_gep22 = getelementptr i8, ptr %ptr_load21, i32 %i20
  %idx_load23 = load i8, ptr %ptr_gep22, align 1
  %icmp24 = icmp eq i8 %idx_load23, 92
  br i1 %icmp24, label %land_rhs25, label %land_merge26

while_exit11:                                     ; preds = %land_merge
  %i48 = load i32, ptr %i, align 4
  %line_len49 = load i32, ptr %line_len, align 4
  %icmp50 = icmp slt i32 %i48, %line_len49
  br i1 %icmp50, label %if_then51, label %if_merge52

land_rhs:                                         ; preds = %while_cond9
  %i15 = load i32, ptr %i, align 4
  %ptr_load16 = load ptr, ptr %line, align 8
  %ptr_gep17 = getelementptr i8, ptr %ptr_load16, i32 %i15
  %idx_load18 = load i8, ptr %ptr_gep17, align 1
  %icmp19 = icmp ne i8 %idx_load18, 34
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond9
  %land = phi i1 [ false, %while_cond9 ], [ %icmp19, %land_rhs ]
  br i1 %land, label %while_body10, label %while_exit11

land_rhs25:                                       ; preds = %while_body10
  %i27 = load i32, ptr %i, align 4
  %add28 = add i32 %i27, 1
  %line_len29 = load i32, ptr %line_len, align 4
  %icmp30 = icmp slt i32 %add28, %line_len29
  br label %land_merge26

land_merge26:                                     ; preds = %land_rhs25, %while_body10
  %land31 = phi i1 [ false, %while_body10 ], [ %icmp30, %land_rhs25 ]
  br i1 %land31, label %if_then32, label %if_merge33

if_then32:                                        ; preds = %land_merge26
  %out34 = load ptr, ptr %out, align 8
  %i35 = load i32, ptr %i, align 4
  %ptr_load36 = load ptr, ptr %line, align 8
  %ptr_gep37 = getelementptr i8, ptr %ptr_load36, i32 %i35
  %idx_load38 = load i8, ptr %ptr_gep37, align 1
  call void @preproc__NS_strbuf_push(ptr %out34, i8 %idx_load38)
  %i39 = load i32, ptr %i, align 4
  %add40 = add i32 %i39, 1
  store i32 %add40, ptr %i, align 4
  br label %if_merge33

if_merge33:                                       ; preds = %if_then32, %land_merge26
  %out41 = load ptr, ptr %out, align 8
  %i42 = load i32, ptr %i, align 4
  %ptr_load43 = load ptr, ptr %line, align 8
  %ptr_gep44 = getelementptr i8, ptr %ptr_load43, i32 %i42
  %idx_load45 = load i8, ptr %ptr_gep44, align 1
  call void @preproc__NS_strbuf_push(ptr %out41, i8 %idx_load45)
  %i46 = load i32, ptr %i, align 4
  %add47 = add i32 %i46, 1
  store i32 %add47, ptr %i, align 4
  br label %while_cond9

if_then51:                                        ; preds = %while_exit11
  %out53 = load ptr, ptr %out, align 8
  %i54 = load i32, ptr %i, align 4
  %ptr_load55 = load ptr, ptr %line, align 8
  %ptr_gep56 = getelementptr i8, ptr %ptr_load55, i32 %i54
  %idx_load57 = load i8, ptr %ptr_gep56, align 1
  call void @preproc__NS_strbuf_push(ptr %out53, i8 %idx_load57)
  %i58 = load i32, ptr %i, align 4
  %add59 = add i32 %i58, 1
  store i32 %add59, ptr %i, align 4
  br label %if_merge52

if_merge52:                                       ; preds = %if_then51, %while_exit11
  br label %while_cond

if_then62:                                        ; preds = %if_merge
  %out64 = load ptr, ptr %out, align 8
  %c65 = load i8, ptr %c, align 1
  call void @preproc__NS_strbuf_push(ptr %out64, i8 %c65)
  %i66 = load i32, ptr %i, align 4
  %add67 = add i32 %i66, 1
  store i32 %add67, ptr %i, align 4
  br label %while_cond68

if_merge63:                                       ; preds = %if_merge
  %c122 = load i8, ptr %c, align 1
  %icmp123 = icmp eq i8 %c122, 47
  br i1 %icmp123, label %land_rhs124, label %land_merge125

while_cond68:                                     ; preds = %if_merge95, %if_then62
  %i71 = load i32, ptr %i, align 4
  %line_len72 = load i32, ptr %line_len, align 4
  %icmp73 = icmp slt i32 %i71, %line_len72
  br i1 %icmp73, label %land_rhs74, label %land_merge75

while_body69:                                     ; preds = %land_merge75
  %i82 = load i32, ptr %i, align 4
  %ptr_load83 = load ptr, ptr %line, align 8
  %ptr_gep84 = getelementptr i8, ptr %ptr_load83, i32 %i82
  %idx_load85 = load i8, ptr %ptr_gep84, align 1
  %icmp86 = icmp eq i8 %idx_load85, 92
  br i1 %icmp86, label %land_rhs87, label %land_merge88

while_exit70:                                     ; preds = %land_merge75
  %i110 = load i32, ptr %i, align 4
  %line_len111 = load i32, ptr %line_len, align 4
  %icmp112 = icmp slt i32 %i110, %line_len111
  br i1 %icmp112, label %if_then113, label %if_merge114

land_rhs74:                                       ; preds = %while_cond68
  %i76 = load i32, ptr %i, align 4
  %ptr_load77 = load ptr, ptr %line, align 8
  %ptr_gep78 = getelementptr i8, ptr %ptr_load77, i32 %i76
  %idx_load79 = load i8, ptr %ptr_gep78, align 1
  %icmp80 = icmp ne i8 %idx_load79, 39
  br label %land_merge75

land_merge75:                                     ; preds = %land_rhs74, %while_cond68
  %land81 = phi i1 [ false, %while_cond68 ], [ %icmp80, %land_rhs74 ]
  br i1 %land81, label %while_body69, label %while_exit70

land_rhs87:                                       ; preds = %while_body69
  %i89 = load i32, ptr %i, align 4
  %add90 = add i32 %i89, 1
  %line_len91 = load i32, ptr %line_len, align 4
  %icmp92 = icmp slt i32 %add90, %line_len91
  br label %land_merge88

land_merge88:                                     ; preds = %land_rhs87, %while_body69
  %land93 = phi i1 [ false, %while_body69 ], [ %icmp92, %land_rhs87 ]
  br i1 %land93, label %if_then94, label %if_merge95

if_then94:                                        ; preds = %land_merge88
  %out96 = load ptr, ptr %out, align 8
  %i97 = load i32, ptr %i, align 4
  %ptr_load98 = load ptr, ptr %line, align 8
  %ptr_gep99 = getelementptr i8, ptr %ptr_load98, i32 %i97
  %idx_load100 = load i8, ptr %ptr_gep99, align 1
  call void @preproc__NS_strbuf_push(ptr %out96, i8 %idx_load100)
  %i101 = load i32, ptr %i, align 4
  %add102 = add i32 %i101, 1
  store i32 %add102, ptr %i, align 4
  br label %if_merge95

if_merge95:                                       ; preds = %if_then94, %land_merge88
  %out103 = load ptr, ptr %out, align 8
  %i104 = load i32, ptr %i, align 4
  %ptr_load105 = load ptr, ptr %line, align 8
  %ptr_gep106 = getelementptr i8, ptr %ptr_load105, i32 %i104
  %idx_load107 = load i8, ptr %ptr_gep106, align 1
  call void @preproc__NS_strbuf_push(ptr %out103, i8 %idx_load107)
  %i108 = load i32, ptr %i, align 4
  %add109 = add i32 %i108, 1
  store i32 %add109, ptr %i, align 4
  br label %while_cond68

if_then113:                                       ; preds = %while_exit70
  %out115 = load ptr, ptr %out, align 8
  %i116 = load i32, ptr %i, align 4
  %ptr_load117 = load ptr, ptr %line, align 8
  %ptr_gep118 = getelementptr i8, ptr %ptr_load117, i32 %i116
  %idx_load119 = load i8, ptr %ptr_gep118, align 1
  call void @preproc__NS_strbuf_push(ptr %out115, i8 %idx_load119)
  %i120 = load i32, ptr %i, align 4
  %add121 = add i32 %i120, 1
  store i32 %add121, ptr %i, align 4
  br label %if_merge114

if_merge114:                                      ; preds = %if_then113, %while_exit70
  br label %while_cond

land_rhs124:                                      ; preds = %if_merge63
  %i126 = load i32, ptr %i, align 4
  %add127 = add i32 %i126, 1
  %line_len128 = load i32, ptr %line_len, align 4
  %icmp129 = icmp slt i32 %add127, %line_len128
  br label %land_merge125

land_merge125:                                    ; preds = %land_rhs124, %if_merge63
  %land130 = phi i1 [ false, %if_merge63 ], [ %icmp129, %land_rhs124 ]
  br i1 %land130, label %land_rhs131, label %land_merge132

land_rhs131:                                      ; preds = %land_merge125
  %i133 = load i32, ptr %i, align 4
  %add134 = add i32 %i133, 1
  %ptr_load135 = load ptr, ptr %line, align 8
  %ptr_gep136 = getelementptr i8, ptr %ptr_load135, i32 %add134
  %idx_load137 = load i8, ptr %ptr_gep136, align 1
  %icmp138 = icmp eq i8 %idx_load137, 42
  br label %land_merge132

land_merge132:                                    ; preds = %land_rhs131, %land_merge125
  %land139 = phi i1 [ false, %land_merge125 ], [ %icmp138, %land_rhs131 ]
  br i1 %land139, label %if_then140, label %if_merge141

if_then140:                                       ; preds = %land_merge132
  %out142 = load ptr, ptr %out, align 8
  %c143 = load i8, ptr %c, align 1
  call void @preproc__NS_strbuf_push(ptr %out142, i8 %c143)
  %i144 = load i32, ptr %i, align 4
  %add145 = add i32 %i144, 1
  store i32 %add145, ptr %i, align 4
  %out146 = load ptr, ptr %out, align 8
  %i147 = load i32, ptr %i, align 4
  %ptr_load148 = load ptr, ptr %line, align 8
  %ptr_gep149 = getelementptr i8, ptr %ptr_load148, i32 %i147
  %idx_load150 = load i8, ptr %ptr_gep149, align 1
  call void @preproc__NS_strbuf_push(ptr %out146, i8 %idx_load150)
  %i151 = load i32, ptr %i, align 4
  %add152 = add i32 %i151, 1
  store i32 %add152, ptr %i, align 4
  br label %while_cond153

if_merge141:                                      ; preds = %land_merge132
  %c203 = load i8, ptr %c, align 1
  %icmp204 = icmp eq i8 %c203, 47
  br i1 %icmp204, label %land_rhs205, label %land_merge206

while_cond153:                                    ; preds = %if_merge181, %if_then140
  %i156 = load i32, ptr %i, align 4
  %line_len157 = load i32, ptr %line_len, align 4
  %icmp158 = icmp slt i32 %i156, %line_len157
  br i1 %icmp158, label %while_body154, label %while_exit155

while_body154:                                    ; preds = %while_cond153
  %i159 = load i32, ptr %i, align 4
  %ptr_load160 = load ptr, ptr %line, align 8
  %ptr_gep161 = getelementptr i8, ptr %ptr_load160, i32 %i159
  %idx_load162 = load i8, ptr %ptr_gep161, align 1
  %icmp163 = icmp eq i8 %idx_load162, 42
  br i1 %icmp163, label %land_rhs164, label %land_merge165

while_exit155:                                    ; preds = %if_then180, %while_cond153
  br label %while_cond

land_rhs164:                                      ; preds = %while_body154
  %i166 = load i32, ptr %i, align 4
  %add167 = add i32 %i166, 1
  %line_len168 = load i32, ptr %line_len, align 4
  %icmp169 = icmp slt i32 %add167, %line_len168
  br label %land_merge165

land_merge165:                                    ; preds = %land_rhs164, %while_body154
  %land170 = phi i1 [ false, %while_body154 ], [ %icmp169, %land_rhs164 ]
  br i1 %land170, label %land_rhs171, label %land_merge172

land_rhs171:                                      ; preds = %land_merge165
  %i173 = load i32, ptr %i, align 4
  %add174 = add i32 %i173, 1
  %ptr_load175 = load ptr, ptr %line, align 8
  %ptr_gep176 = getelementptr i8, ptr %ptr_load175, i32 %add174
  %idx_load177 = load i8, ptr %ptr_gep176, align 1
  %icmp178 = icmp eq i8 %idx_load177, 47
  br label %land_merge172

land_merge172:                                    ; preds = %land_rhs171, %land_merge165
  %land179 = phi i1 [ false, %land_merge165 ], [ %icmp178, %land_rhs171 ]
  br i1 %land179, label %if_then180, label %if_merge181

if_then180:                                       ; preds = %land_merge172
  %out182 = load ptr, ptr %out, align 8
  %i183 = load i32, ptr %i, align 4
  %ptr_load184 = load ptr, ptr %line, align 8
  %ptr_gep185 = getelementptr i8, ptr %ptr_load184, i32 %i183
  %idx_load186 = load i8, ptr %ptr_gep185, align 1
  call void @preproc__NS_strbuf_push(ptr %out182, i8 %idx_load186)
  %i187 = load i32, ptr %i, align 4
  %add188 = add i32 %i187, 1
  store i32 %add188, ptr %i, align 4
  %out189 = load ptr, ptr %out, align 8
  %i190 = load i32, ptr %i, align 4
  %ptr_load191 = load ptr, ptr %line, align 8
  %ptr_gep192 = getelementptr i8, ptr %ptr_load191, i32 %i190
  %idx_load193 = load i8, ptr %ptr_gep192, align 1
  call void @preproc__NS_strbuf_push(ptr %out189, i8 %idx_load193)
  %i194 = load i32, ptr %i, align 4
  %add195 = add i32 %i194, 1
  store i32 %add195, ptr %i, align 4
  br label %while_exit155

if_merge181:                                      ; preds = %land_merge172
  %out196 = load ptr, ptr %out, align 8
  %i197 = load i32, ptr %i, align 4
  %ptr_load198 = load ptr, ptr %line, align 8
  %ptr_gep199 = getelementptr i8, ptr %ptr_load198, i32 %i197
  %idx_load200 = load i8, ptr %ptr_gep199, align 1
  call void @preproc__NS_strbuf_push(ptr %out196, i8 %idx_load200)
  %i201 = load i32, ptr %i, align 4
  %add202 = add i32 %i201, 1
  store i32 %add202, ptr %i, align 4
  br label %while_cond153

land_rhs205:                                      ; preds = %if_merge141
  %i207 = load i32, ptr %i, align 4
  %add208 = add i32 %i207, 1
  %line_len209 = load i32, ptr %line_len, align 4
  %icmp210 = icmp slt i32 %add208, %line_len209
  br label %land_merge206

land_merge206:                                    ; preds = %land_rhs205, %if_merge141
  %land211 = phi i1 [ false, %if_merge141 ], [ %icmp210, %land_rhs205 ]
  br i1 %land211, label %land_rhs212, label %land_merge213

land_rhs212:                                      ; preds = %land_merge206
  %i214 = load i32, ptr %i, align 4
  %add215 = add i32 %i214, 1
  %ptr_load216 = load ptr, ptr %line, align 8
  %ptr_gep217 = getelementptr i8, ptr %ptr_load216, i32 %add215
  %idx_load218 = load i8, ptr %ptr_gep217, align 1
  %icmp219 = icmp eq i8 %idx_load218, 47
  br label %land_merge213

land_merge213:                                    ; preds = %land_rhs212, %land_merge206
  %land220 = phi i1 [ false, %land_merge206 ], [ %icmp219, %land_rhs212 ]
  br i1 %land220, label %if_then221, label %if_merge222

if_then221:                                       ; preds = %land_merge213
  %out223 = load ptr, ptr %out, align 8
  %line224 = load ptr, ptr %line, align 8
  %i225 = load i32, ptr %i, align 4
  %ptr_add = getelementptr i8, ptr %line224, i32 %i225
  %line_len226 = load i32, ptr %line_len, align 4
  %i227 = load i32, ptr %i, align 4
  %sub = sub i32 %line_len226, %i227
  %zext = zext i32 %sub to i64
  call void @preproc__NS_strbuf_append(ptr %out223, ptr %ptr_add, i64 %zext)
  ret void

if_merge222:                                      ; preds = %land_merge213
  %c228 = load i8, ptr %c, align 1
  %5 = call i8 @preproc__NS_pp_is_id_start(i8 %c228)
  %if_cond = icmp ne i8 %5, 0
  br i1 %if_cond, label %if_then229, label %if_merge230

if_then229:                                       ; preds = %if_merge222
  %j = alloca i32, align 4
  %i231 = load i32, ptr %i, align 4
  %add232 = add i32 %i231, 1
  store i32 %add232, ptr %j, align 4
  br label %while_cond233

if_merge230:                                      ; preds = %if_merge222
  %out328 = load ptr, ptr %out, align 8
  %c329 = load i8, ptr %c, align 1
  call void @preproc__NS_strbuf_push(ptr %out328, i8 %c329)
  %i330 = load i32, ptr %i, align 4
  %add331 = add i32 %i330, 1
  store i32 %add331, ptr %i, align 4
  br label %while_cond

while_cond233:                                    ; preds = %while_body234, %if_then229
  %j236 = load i32, ptr %j, align 4
  %line_len237 = load i32, ptr %line_len, align 4
  %icmp238 = icmp slt i32 %j236, %line_len237
  br i1 %icmp238, label %land_rhs239, label %land_merge240

while_body234:                                    ; preds = %land_merge240
  %j246 = load i32, ptr %j, align 4
  %add247 = add i32 %j246, 1
  store i32 %add247, ptr %j, align 4
  br label %while_cond233

while_exit235:                                    ; preds = %land_merge240
  %id = alloca ptr, align 8
  %line248 = load ptr, ptr %line, align 8
  %i249 = load i32, ptr %i, align 4
  %ptr_add250 = getelementptr i8, ptr %line248, i32 %i249
  %j251 = load i32, ptr %j, align 4
  %i252 = load i32, ptr %i, align 4
  %sub253 = sub i32 %j251, %i252
  %6 = call ptr @preproc__NS_pp_substr_dup(ptr %ptr_add250, i32 %sub253)
  store ptr %6, ptr %id, align 8
  %repl = alloca ptr, align 8
  %t254 = load ptr, ptr %t, align 8
  %id255 = load ptr, ptr %id, align 8
  %7 = call ptr @preproc__NS_pp_get(ptr %t254, ptr %id255)
  store ptr %7, ptr %repl, align 8
  %repl256 = load ptr, ptr %repl, align 8
  %icmp257 = icmp ne ptr %repl256, null
  br i1 %icmp257, label %if_then258, label %if_merge259

land_rhs239:                                      ; preds = %while_cond233
  %j241 = load i32, ptr %j, align 4
  %ptr_load242 = load ptr, ptr %line, align 8
  %ptr_gep243 = getelementptr i8, ptr %ptr_load242, i32 %j241
  %idx_load244 = load i8, ptr %ptr_gep243, align 1
  %8 = call i8 @preproc__NS_pp_is_id_cont(i8 %idx_load244)
  %tobool = icmp ne i8 %8, 0
  br label %land_merge240

land_merge240:                                    ; preds = %land_rhs239, %while_cond233
  %land245 = phi i1 [ false, %while_cond233 ], [ %tobool, %land_rhs239 ]
  br i1 %land245, label %while_body234, label %while_exit235

if_then258:                                       ; preds = %while_exit235
  %id260 = load ptr, ptr %id, align 8
  call void @arc_free.3(ptr %id260)
  %out261 = load ptr, ptr %out, align 8
  %repl262 = load ptr, ptr %repl, align 8
  call void @preproc__NS_strbuf_append_cstr(ptr %out261, ptr %repl262)
  %j263 = load i32, ptr %j, align 4
  store i32 %j263, ptr %i, align 4
  br label %while_cond

if_merge259:                                      ; preds = %while_exit235
  %ft264 = load ptr, ptr %ft, align 8
  %icmp265 = icmp ne ptr %ft264, null
  br i1 %icmp265, label %if_then266, label %if_merge267

if_then266:                                       ; preds = %if_merge259
  %k = alloca i32, align 4
  %j268 = load i32, ptr %j, align 4
  store i32 %j268, ptr %k, align 4
  br label %while_cond269

if_merge267:                                      ; preds = %if_merge302, %if_merge259
  %id318 = load ptr, ptr %id, align 8
  call void @arc_free.3(ptr %id318)
  %out319 = load ptr, ptr %out, align 8
  %line320 = load ptr, ptr %line, align 8
  %i321 = load i32, ptr %i, align 4
  %ptr_add322 = getelementptr i8, ptr %line320, i32 %i321
  %j323 = load i32, ptr %j, align 4
  %i324 = load i32, ptr %i, align 4
  %sub325 = sub i32 %j323, %i324
  %zext326 = zext i32 %sub325 to i64
  call void @preproc__NS_strbuf_append(ptr %out319, ptr %ptr_add322, i64 %zext326)
  %j327 = load i32, ptr %j, align 4
  store i32 %j327, ptr %i, align 4
  br label %while_cond

while_cond269:                                    ; preds = %while_body270, %if_then266
  %k272 = load i32, ptr %k, align 4
  %line_len273 = load i32, ptr %line_len, align 4
  %icmp274 = icmp slt i32 %k272, %line_len273
  br i1 %icmp274, label %land_rhs275, label %land_merge276

while_body270:                                    ; preds = %land_merge276
  %k288 = load i32, ptr %k, align 4
  %add289 = add i32 %k288, 1
  store i32 %add289, ptr %k, align 4
  br label %while_cond269

while_exit271:                                    ; preds = %land_merge276
  %k290 = load i32, ptr %k, align 4
  %line_len291 = load i32, ptr %line_len, align 4
  %icmp292 = icmp slt i32 %k290, %line_len291
  br i1 %icmp292, label %land_rhs293, label %land_merge294

land_rhs275:                                      ; preds = %while_cond269
  %k277 = load i32, ptr %k, align 4
  %ptr_load278 = load ptr, ptr %line, align 8
  %ptr_gep279 = getelementptr i8, ptr %ptr_load278, i32 %k277
  %idx_load280 = load i8, ptr %ptr_gep279, align 1
  %icmp281 = icmp eq i8 %idx_load280, 32
  br i1 %icmp281, label %lor_merge, label %lor_rhs

land_merge276:                                    ; preds = %lor_merge, %while_cond269
  %land287 = phi i1 [ false, %while_cond269 ], [ %lor, %lor_merge ]
  br i1 %land287, label %while_body270, label %while_exit271

lor_rhs:                                          ; preds = %land_rhs275
  %k282 = load i32, ptr %k, align 4
  %ptr_load283 = load ptr, ptr %line, align 8
  %ptr_gep284 = getelementptr i8, ptr %ptr_load283, i32 %k282
  %idx_load285 = load i8, ptr %ptr_gep284, align 1
  %icmp286 = icmp eq i8 %idx_load285, 9
  br label %lor_merge

lor_merge:                                        ; preds = %lor_rhs, %land_rhs275
  %lor = phi i1 [ true, %land_rhs275 ], [ %icmp286, %lor_rhs ]
  br label %land_merge276

land_rhs293:                                      ; preds = %while_exit271
  %k295 = load i32, ptr %k, align 4
  %ptr_load296 = load ptr, ptr %line, align 8
  %ptr_gep297 = getelementptr i8, ptr %ptr_load296, i32 %k295
  %idx_load298 = load i8, ptr %ptr_gep297, align 1
  %icmp299 = icmp eq i8 %idx_load298, 40
  br label %land_merge294

land_merge294:                                    ; preds = %land_rhs293, %while_exit271
  %land300 = phi i1 [ false, %while_exit271 ], [ %icmp299, %land_rhs293 ]
  br i1 %land300, label %if_then301, label %if_merge302

if_then301:                                       ; preds = %land_merge294
  %end_pos = alloca i32, align 4
  %k303 = load i32, ptr %k, align 4
  store i32 %k303, ptr %end_pos, align 4
  %expanded = alloca ptr, align 8
  %ft304 = load ptr, ptr %ft, align 8
  %id305 = load ptr, ptr %id, align 8
  %line306 = load ptr, ptr %line, align 8
  %k307 = load i32, ptr %k, align 4
  %line_len308 = load i32, ptr %line_len, align 4
  %9 = call ptr @preproc__NS_pp_func_expand(ptr %ft304, ptr %id305, ptr %line306, i32 %k307, i32 %line_len308, ptr %end_pos)
  store ptr %9, ptr %expanded, align 8
  %expanded309 = load ptr, ptr %expanded, align 8
  %icmp310 = icmp ne ptr %expanded309, null
  br i1 %icmp310, label %if_then311, label %if_merge312

if_merge302:                                      ; preds = %if_merge312, %land_merge294
  br label %if_merge267

if_then311:                                       ; preds = %if_then301
  %id313 = load ptr, ptr %id, align 8
  call void @arc_free.3(ptr %id313)
  %out314 = load ptr, ptr %out, align 8
  %expanded315 = load ptr, ptr %expanded, align 8
  call void @preproc__NS_strbuf_append_cstr(ptr %out314, ptr %expanded315)
  %expanded316 = load ptr, ptr %expanded, align 8
  call void @arc_free.3(ptr %expanded316)
  %end_pos317 = load i32, ptr %end_pos, align 4
  store i32 %end_pos317, ptr %i, align 4
  br label %while_cond

if_merge312:                                      ; preds = %if_then301
  br label %if_merge302
}

define internal void @preproc__NS_pp_stack_init(ptr %0) {
entry:
  %s = alloca ptr, align 8
  store ptr %0, ptr %s, align 8
  %ptr_deref = load ptr, ptr %s, align 8
  %depth = getelementptr inbounds nuw %pp_stack, ptr %ptr_deref, i32 0, i32 3
  store i32 0, ptr %depth, align 4
  ret void
}

define internal i8 @preproc__NS_pp_all_active(ptr %0) {
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

define internal i8 @preproc__NS_pp_parents_active(ptr %0) {
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

define internal ptr @preproc__NS_pp_read_file(ptr %0) {
entry:
  %path = alloca ptr, align 8
  store ptr %0, ptr %path, align 8
  %fp = alloca ptr, align 8
  %path1 = load ptr, ptr %path, align 8
  %1 = call ptr @arc_fopen(ptr %path1, ptr @str.6)
  store ptr %1, ptr %fp, align 8
  %fp2 = load ptr, ptr %fp, align 8
  %icmp = icmp eq ptr %fp2, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret ptr null

if_merge:                                         ; preds = %entry
  %fp3 = load ptr, ptr %fp, align 8
  %2 = call i32 @arc_fseek(ptr %fp3, i64 0, i32 2)
  %icmp4 = icmp ne i32 %2, 0
  br i1 %icmp4, label %if_then5, label %if_merge6

if_then5:                                         ; preds = %if_merge
  %fp7 = load ptr, ptr %fp, align 8
  %3 = call i32 @arc_fclose(ptr %fp7)
  ret ptr null

if_merge6:                                        ; preds = %if_merge
  %sz = alloca i64, align 8
  %fp8 = load ptr, ptr %fp, align 8
  %4 = call i64 @arc_ftell(ptr %fp8)
  store i64 %4, ptr %sz, align 8
  %sz9 = load i64, ptr %sz, align 8
  %icmp10 = icmp slt i64 %sz9, 0
  br i1 %icmp10, label %if_then11, label %if_merge12

if_then11:                                        ; preds = %if_merge6
  %fp13 = load ptr, ptr %fp, align 8
  %5 = call i32 @arc_fclose(ptr %fp13)
  ret ptr null

if_merge12:                                       ; preds = %if_merge6
  %fp14 = load ptr, ptr %fp, align 8
  %6 = call i32 @arc_fseek(ptr %fp14, i64 0, i32 0)
  %icmp15 = icmp ne i32 %6, 0
  br i1 %icmp15, label %if_then16, label %if_merge17

if_then16:                                        ; preds = %if_merge12
  %fp18 = load ptr, ptr %fp, align 8
  %7 = call i32 @arc_fclose(ptr %fp18)
  ret ptr null

if_merge17:                                       ; preds = %if_merge12
  %buf = alloca ptr, align 8
  %sz19 = load i64, ptr %sz, align 8
  %add = add i64 %sz19, 1
  %8 = call ptr @arc_malloc.1(i64 %add)
  store ptr %8, ptr %buf, align 8
  %buf20 = load ptr, ptr %buf, align 8
  %icmp21 = icmp eq ptr %buf20, null
  br i1 %icmp21, label %if_then22, label %if_merge23

if_then22:                                        ; preds = %if_merge17
  %fp24 = load ptr, ptr %fp, align 8
  %9 = call i32 @arc_fclose(ptr %fp24)
  ret ptr null

if_merge23:                                       ; preds = %if_merge17
  %n = alloca i64, align 8
  %buf25 = load ptr, ptr %buf, align 8
  %sz26 = load i64, ptr %sz, align 8
  %fp27 = load ptr, ptr %fp, align 8
  %10 = call i64 @arc_fread(ptr %buf25, i64 1, i64 %sz26, ptr %fp27)
  store i64 %10, ptr %n, align 8
  %n28 = load i64, ptr %n, align 8
  %sz29 = load i64, ptr %sz, align 8
  %icmp30 = icmp ugt i64 %n28, %sz29
  br i1 %icmp30, label %if_then31, label %if_merge32

if_then31:                                        ; preds = %if_merge23
  %sz33 = load i64, ptr %sz, align 8
  store i64 %sz33, ptr %n, align 8
  br label %if_merge32

if_merge32:                                       ; preds = %if_then31, %if_merge23
  %n34 = load i64, ptr %n, align 8
  %ptr_load = load ptr, ptr %buf, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i64 %n34
  store i8 0, ptr %ptr_gep, align 1
  %fp35 = load ptr, ptr %fp, align 8
  %11 = call i32 @arc_fclose(ptr %fp35)
  %buf36 = load ptr, ptr %buf, align 8
  ret ptr %buf36
}

define ptr @preproc__NS_preprocess_inner(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4, ptr %5) {
entry:
  %src = alloca ptr, align 8
  store ptr %0, ptr %src, align 8
  %base_dir = alloca ptr, align 8
  store ptr %1, ptr %base_dir, align 8
  %macros = alloca ptr, align 8
  store ptr %2, ptr %macros, align 8
  %funcs = alloca ptr, align 8
  store ptr %3, ptr %funcs, align 8
  %stdlib_path = alloca ptr, align 8
  store ptr %4, ptr %stdlib_path, align 8
  %included = alloca ptr, align 8
  store ptr %5, ptr %included, align 8
  %out = alloca %strbuf, align 8
  store %strbuf zeroinitializer, ptr %out, align 8
  %cs = alloca %pp_stack, align 8
  store %pp_stack zeroinitializer, ptr %cs, align 4
  call void @preproc__NS_strbuf_init(ptr %out)
  call void @preproc__NS_pp_stack_init(ptr %cs)
  %pos = alloca i32, align 4
  store i32 0, ptr %pos, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge79, %if_merge181, %entry
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
  %6 = call ptr @preproc__NS_strbuf_finish(ptr %out)
  ret ptr %6

while_cond3:                                      ; preds = %while_body4, %while_body
  %pos6 = load i32, ptr %pos, align 4
  %ptr_load7 = load ptr, ptr %src, align 8
  %ptr_gep8 = getelementptr i8, ptr %ptr_load7, i32 %pos6
  %idx_load9 = load i8, ptr %ptr_gep8, align 1
  %icmp10 = icmp ne i8 %idx_load9, 0
  br i1 %icmp10, label %land_rhs, label %land_merge

while_body4:                                      ; preds = %land_merge
  %pos16 = load i32, ptr %pos, align 4
  %add = add i32 %pos16, 1
  store i32 %add, ptr %pos, align 4
  br label %while_cond3

while_exit5:                                      ; preds = %land_merge
  %line_end = alloca i32, align 4
  %pos17 = load i32, ptr %pos, align 4
  store i32 %pos17, ptr %line_end, align 4
  %pos18 = load i32, ptr %pos, align 4
  %ptr_load19 = load ptr, ptr %src, align 8
  %ptr_gep20 = getelementptr i8, ptr %ptr_load19, i32 %pos18
  %idx_load21 = load i8, ptr %ptr_gep20, align 1
  %icmp22 = icmp eq i8 %idx_load21, 10
  br i1 %icmp22, label %if_then, label %if_merge

land_rhs:                                         ; preds = %while_cond3
  %pos11 = load i32, ptr %pos, align 4
  %ptr_load12 = load ptr, ptr %src, align 8
  %ptr_gep13 = getelementptr i8, ptr %ptr_load12, i32 %pos11
  %idx_load14 = load i8, ptr %ptr_gep13, align 1
  %icmp15 = icmp ne i8 %idx_load14, 10
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond3
  %land = phi i1 [ false, %while_cond3 ], [ %icmp15, %land_rhs ]
  br i1 %land, label %while_body4, label %while_exit5

if_then:                                          ; preds = %while_exit5
  %pos23 = load i32, ptr %pos, align 4
  %add24 = add i32 %pos23, 1
  store i32 %add24, ptr %pos, align 4
  br label %if_merge

if_merge:                                         ; preds = %if_then, %while_exit5
  %line_end25 = load i32, ptr %line_end, align 4
  %line_start26 = load i32, ptr %line_start, align 4
  %icmp27 = icmp sgt i32 %line_end25, %line_start26
  br i1 %icmp27, label %land_rhs28, label %land_merge29

land_rhs28:                                       ; preds = %if_merge
  %line_end30 = load i32, ptr %line_end, align 4
  %sub = sub i32 %line_end30, 1
  %ptr_load31 = load ptr, ptr %src, align 8
  %ptr_gep32 = getelementptr i8, ptr %ptr_load31, i32 %sub
  %idx_load33 = load i8, ptr %ptr_gep32, align 1
  %icmp34 = icmp eq i8 %idx_load33, 13
  br label %land_merge29

land_merge29:                                     ; preds = %land_rhs28, %if_merge
  %land35 = phi i1 [ false, %if_merge ], [ %icmp34, %land_rhs28 ]
  br i1 %land35, label %if_then36, label %if_merge37

if_then36:                                        ; preds = %land_merge29
  %line_end38 = load i32, ptr %line_end, align 4
  %sub39 = sub i32 %line_end38, 1
  store i32 %sub39, ptr %line_end, align 4
  br label %if_merge37

if_merge37:                                       ; preds = %if_then36, %land_merge29
  %line = alloca ptr, align 8
  %src40 = load ptr, ptr %src, align 8
  %line_start41 = load i32, ptr %line_start, align 4
  %ptr_add = getelementptr i8, ptr %src40, i32 %line_start41
  store ptr %ptr_add, ptr %line, align 8
  %line_len = alloca i32, align 4
  %line_end42 = load i32, ptr %line_end, align 4
  %line_start43 = load i32, ptr %line_start, align 4
  %sub44 = sub i32 %line_end42, %line_start43
  store i32 %sub44, ptr %line_len, align 4
  %ind = alloca i32, align 4
  store i32 0, ptr %ind, align 4
  br label %while_cond45

while_cond45:                                     ; preds = %while_body46, %if_merge37
  %ind48 = load i32, ptr %ind, align 4
  %line_len49 = load i32, ptr %line_len, align 4
  %icmp50 = icmp slt i32 %ind48, %line_len49
  br i1 %icmp50, label %land_rhs51, label %land_merge52

while_body46:                                     ; preds = %land_merge52
  %ind64 = load i32, ptr %ind, align 4
  %add65 = add i32 %ind64, 1
  store i32 %add65, ptr %ind, align 4
  br label %while_cond45

while_exit47:                                     ; preds = %land_merge52
  %is_dir = alloca i8, align 1
  %ind66 = load i32, ptr %ind, align 4
  %line_len67 = load i32, ptr %line_len, align 4
  %icmp68 = icmp slt i32 %ind66, %line_len67
  br i1 %icmp68, label %land_rhs69, label %land_merge70

land_rhs51:                                       ; preds = %while_cond45
  %ind53 = load i32, ptr %ind, align 4
  %ptr_load54 = load ptr, ptr %line, align 8
  %ptr_gep55 = getelementptr i8, ptr %ptr_load54, i32 %ind53
  %idx_load56 = load i8, ptr %ptr_gep55, align 1
  %icmp57 = icmp eq i8 %idx_load56, 32
  br i1 %icmp57, label %lor_merge, label %lor_rhs

land_merge52:                                     ; preds = %lor_merge, %while_cond45
  %land63 = phi i1 [ false, %while_cond45 ], [ %lor, %lor_merge ]
  br i1 %land63, label %while_body46, label %while_exit47

lor_rhs:                                          ; preds = %land_rhs51
  %ind58 = load i32, ptr %ind, align 4
  %ptr_load59 = load ptr, ptr %line, align 8
  %ptr_gep60 = getelementptr i8, ptr %ptr_load59, i32 %ind58
  %idx_load61 = load i8, ptr %ptr_gep60, align 1
  %icmp62 = icmp eq i8 %idx_load61, 9
  br label %lor_merge

lor_merge:                                        ; preds = %lor_rhs, %land_rhs51
  %lor = phi i1 [ true, %land_rhs51 ], [ %icmp62, %lor_rhs ]
  br label %land_merge52

land_rhs69:                                       ; preds = %while_exit47
  %ind71 = load i32, ptr %ind, align 4
  %ptr_load72 = load ptr, ptr %line, align 8
  %ptr_gep73 = getelementptr i8, ptr %ptr_load72, i32 %ind71
  %idx_load74 = load i8, ptr %ptr_gep73, align 1
  %icmp75 = icmp eq i8 %idx_load74, 64
  br label %land_merge70

land_merge70:                                     ; preds = %land_rhs69, %while_exit47
  %land76 = phi i1 [ false, %while_exit47 ], [ %icmp75, %land_rhs69 ]
  %zext = zext i1 %land76 to i8
  store i8 %zext, ptr %is_dir, align 1
  %is_dir77 = load i8, ptr %is_dir, align 1
  %if_cond = icmp ne i8 %is_dir77, 0
  br i1 %if_cond, label %if_then78, label %if_else

if_then78:                                        ; preds = %land_merge70
  %ks = alloca i32, align 4
  %ind80 = load i32, ptr %ind, align 4
  %add81 = add i32 %ind80, 1
  store i32 %add81, ptr %ks, align 4
  %ke = alloca i32, align 4
  %ks82 = load i32, ptr %ks, align 4
  store i32 %ks82, ptr %ke, align 4
  br label %while_cond83

if_else:                                          ; preds = %land_merge70
  %7 = call i8 @preproc__NS_pp_all_active(ptr %cs)
  %if_cond705 = icmp ne i8 %7, 0
  br i1 %if_cond705, label %if_then706, label %if_merge707

if_merge79:                                       ; preds = %if_merge707, %if_merge198
  br label %while_cond

while_cond83:                                     ; preds = %while_body84, %if_then78
  %ke86 = load i32, ptr %ke, align 4
  %line_len87 = load i32, ptr %line_len, align 4
  %icmp88 = icmp slt i32 %ke86, %line_len87
  br i1 %icmp88, label %land_rhs89, label %land_merge90

while_body84:                                     ; preds = %land_merge90
  %ke96 = load i32, ptr %ke, align 4
  %add97 = add i32 %ke96, 1
  store i32 %add97, ptr %ke, align 4
  br label %while_cond83

while_exit85:                                     ; preds = %land_merge90
  %kw = alloca ptr, align 8
  %line98 = load ptr, ptr %line, align 8
  %ks99 = load i32, ptr %ks, align 4
  %ptr_add100 = getelementptr i8, ptr %line98, i32 %ks99
  %ke101 = load i32, ptr %ke, align 4
  %ks102 = load i32, ptr %ks, align 4
  %sub103 = sub i32 %ke101, %ks102
  %8 = call ptr @preproc__NS_pp_substr_dup(ptr %ptr_add100, i32 %sub103)
  store ptr %8, ptr %kw, align 8
  %rest = alloca ptr, align 8
  %line104 = load ptr, ptr %line, align 8
  %ke105 = load i32, ptr %ke, align 4
  %ptr_add106 = getelementptr i8, ptr %line104, i32 %ke105
  store ptr %ptr_add106, ptr %rest, align 8
  br label %while_cond107

land_rhs89:                                       ; preds = %while_cond83
  %ke91 = load i32, ptr %ke, align 4
  %ptr_load92 = load ptr, ptr %line, align 8
  %ptr_gep93 = getelementptr i8, ptr %ptr_load92, i32 %ke91
  %idx_load94 = load i8, ptr %ptr_gep93, align 1
  %9 = call i8 @preproc__NS_pp_is_id_cont(i8 %idx_load94)
  %tobool = icmp ne i8 %9, 0
  br label %land_merge90

land_merge90:                                     ; preds = %land_rhs89, %while_cond83
  %land95 = phi i1 [ false, %while_cond83 ], [ %tobool, %land_rhs89 ]
  br i1 %land95, label %while_body84, label %while_exit85

while_cond107:                                    ; preds = %while_body108, %while_exit85
  %rest110 = load ptr, ptr %rest, align 8
  %deref = load i8, ptr %rest110, align 1
  %icmp111 = icmp eq i8 %deref, 32
  br i1 %icmp111, label %lor_merge113, label %lor_rhs112

while_body108:                                    ; preds = %lor_merge113
  %rest118 = load ptr, ptr %rest, align 8
  %ptr_add119 = getelementptr i8, ptr %rest118, i32 1
  store ptr %ptr_add119, ptr %rest, align 8
  br label %while_cond107

while_exit109:                                    ; preds = %lor_merge113
  %is_known_dir = alloca i8, align 1
  %kw120 = load ptr, ptr %kw, align 8
  %10 = call i32 @arc_strcmp(ptr %kw120, ptr @str.7)
  %icmp121 = icmp eq i32 %10, 0
  br i1 %icmp121, label %lor_merge123, label %lor_rhs122

lor_rhs112:                                       ; preds = %while_cond107
  %rest114 = load ptr, ptr %rest, align 8
  %deref115 = load i8, ptr %rest114, align 1
  %icmp116 = icmp eq i8 %deref115, 9
  br label %lor_merge113

lor_merge113:                                     ; preds = %lor_rhs112, %while_cond107
  %lor117 = phi i1 [ true, %while_cond107 ], [ %icmp116, %lor_rhs112 ]
  br i1 %lor117, label %while_body108, label %while_exit109

lor_rhs122:                                       ; preds = %while_exit109
  %kw124 = load ptr, ptr %kw, align 8
  %11 = call i32 @arc_strcmp(ptr %kw124, ptr @str.8)
  %icmp125 = icmp eq i32 %11, 0
  br label %lor_merge123

lor_merge123:                                     ; preds = %lor_rhs122, %while_exit109
  %lor126 = phi i1 [ true, %while_exit109 ], [ %icmp125, %lor_rhs122 ]
  br i1 %lor126, label %lor_merge128, label %lor_rhs127

lor_rhs127:                                       ; preds = %lor_merge123
  %kw129 = load ptr, ptr %kw, align 8
  %12 = call i32 @arc_strcmp(ptr %kw129, ptr @str.9)
  %icmp130 = icmp eq i32 %12, 0
  br label %lor_merge128

lor_merge128:                                     ; preds = %lor_rhs127, %lor_merge123
  %lor131 = phi i1 [ true, %lor_merge123 ], [ %icmp130, %lor_rhs127 ]
  br i1 %lor131, label %lor_merge133, label %lor_rhs132

lor_rhs132:                                       ; preds = %lor_merge128
  %kw134 = load ptr, ptr %kw, align 8
  %13 = call i32 @arc_strcmp(ptr %kw134, ptr @str.10)
  %icmp135 = icmp eq i32 %13, 0
  br label %lor_merge133

lor_merge133:                                     ; preds = %lor_rhs132, %lor_merge128
  %lor136 = phi i1 [ true, %lor_merge128 ], [ %icmp135, %lor_rhs132 ]
  br i1 %lor136, label %lor_merge138, label %lor_rhs137

lor_rhs137:                                       ; preds = %lor_merge133
  %kw139 = load ptr, ptr %kw, align 8
  %14 = call i32 @arc_strcmp(ptr %kw139, ptr @str.11)
  %icmp140 = icmp eq i32 %14, 0
  br label %lor_merge138

lor_merge138:                                     ; preds = %lor_rhs137, %lor_merge133
  %lor141 = phi i1 [ true, %lor_merge133 ], [ %icmp140, %lor_rhs137 ]
  br i1 %lor141, label %lor_merge143, label %lor_rhs142

lor_rhs142:                                       ; preds = %lor_merge138
  %kw144 = load ptr, ptr %kw, align 8
  %15 = call i32 @arc_strcmp(ptr %kw144, ptr @str.12)
  %icmp145 = icmp eq i32 %15, 0
  br label %lor_merge143

lor_merge143:                                     ; preds = %lor_rhs142, %lor_merge138
  %lor146 = phi i1 [ true, %lor_merge138 ], [ %icmp145, %lor_rhs142 ]
  br i1 %lor146, label %lor_merge148, label %lor_rhs147

lor_rhs147:                                       ; preds = %lor_merge143
  %kw149 = load ptr, ptr %kw, align 8
  %16 = call i32 @arc_strcmp(ptr %kw149, ptr @str.13)
  %icmp150 = icmp eq i32 %16, 0
  br label %lor_merge148

lor_merge148:                                     ; preds = %lor_rhs147, %lor_merge143
  %lor151 = phi i1 [ true, %lor_merge143 ], [ %icmp150, %lor_rhs147 ]
  br i1 %lor151, label %lor_merge153, label %lor_rhs152

lor_rhs152:                                       ; preds = %lor_merge148
  %kw154 = load ptr, ptr %kw, align 8
  %17 = call i32 @arc_strcmp(ptr %kw154, ptr @str.14)
  %icmp155 = icmp eq i32 %17, 0
  br label %lor_merge153

lor_merge153:                                     ; preds = %lor_rhs152, %lor_merge148
  %lor156 = phi i1 [ true, %lor_merge148 ], [ %icmp155, %lor_rhs152 ]
  br i1 %lor156, label %lor_merge158, label %lor_rhs157

lor_rhs157:                                       ; preds = %lor_merge153
  %kw159 = load ptr, ptr %kw, align 8
  %18 = call i32 @arc_strcmp(ptr %kw159, ptr @str.15)
  %icmp160 = icmp eq i32 %18, 0
  br label %lor_merge158

lor_merge158:                                     ; preds = %lor_rhs157, %lor_merge153
  %lor161 = phi i1 [ true, %lor_merge153 ], [ %icmp160, %lor_rhs157 ]
  br i1 %lor161, label %lor_merge163, label %lor_rhs162

lor_rhs162:                                       ; preds = %lor_merge158
  %kw164 = load ptr, ptr %kw, align 8
  %19 = call i32 @arc_strcmp(ptr %kw164, ptr @str.16)
  %icmp165 = icmp eq i32 %19, 0
  br label %lor_merge163

lor_merge163:                                     ; preds = %lor_rhs162, %lor_merge158
  %lor166 = phi i1 [ true, %lor_merge158 ], [ %icmp165, %lor_rhs162 ]
  br i1 %lor166, label %lor_merge168, label %lor_rhs167

lor_rhs167:                                       ; preds = %lor_merge163
  %kw169 = load ptr, ptr %kw, align 8
  %20 = call i32 @arc_strcmp(ptr %kw169, ptr @str.17)
  %icmp170 = icmp eq i32 %20, 0
  br label %lor_merge168

lor_merge168:                                     ; preds = %lor_rhs167, %lor_merge163
  %lor171 = phi i1 [ true, %lor_merge163 ], [ %icmp170, %lor_rhs167 ]
  %zext172 = zext i1 %lor171 to i8
  store i8 %zext172, ptr %is_known_dir, align 1
  %is_known_dir173 = load i8, ptr %is_known_dir, align 1
  %tobool174 = icmp ne i8 %is_known_dir173, 0
  %not = xor i1 %tobool174, true
  br i1 %not, label %if_then175, label %if_merge176

if_then175:                                       ; preds = %lor_merge168
  %kw177 = load ptr, ptr %kw, align 8
  call void @arc_free.3(ptr %kw177)
  %21 = call i8 @preproc__NS_pp_all_active(ptr %cs)
  %if_cond178 = icmp ne i8 %21, 0
  br i1 %if_cond178, label %if_then179, label %if_else180

if_merge176:                                      ; preds = %lor_merge168
  %kw194 = load ptr, ptr %kw, align 8
  %22 = call i32 @arc_strcmp(ptr %kw194, ptr @str.18)
  %icmp195 = icmp eq i32 %22, 0
  br i1 %icmp195, label %if_then196, label %if_else197

if_then179:                                       ; preds = %if_then175
  %li = alloca i32, align 4
  store i32 0, ptr %li, align 4
  br label %while_cond182

if_else180:                                       ; preds = %if_then175
  call void @preproc__NS_strbuf_push(ptr %out, i8 10)
  br label %if_merge181

if_merge181:                                      ; preds = %if_else180, %while_exit184
  br label %while_cond

while_cond182:                                    ; preds = %while_body183, %if_then179
  %li185 = load i32, ptr %li, align 4
  %line_len186 = load i32, ptr %line_len, align 4
  %icmp187 = icmp slt i32 %li185, %line_len186
  br i1 %icmp187, label %while_body183, label %while_exit184

while_body183:                                    ; preds = %while_cond182
  %li188 = load i32, ptr %li, align 4
  %ptr_load189 = load ptr, ptr %line, align 8
  %ptr_gep190 = getelementptr i8, ptr %ptr_load189, i32 %li188
  %idx_load191 = load i8, ptr %ptr_gep190, align 1
  call void @preproc__NS_strbuf_push(ptr %out, i8 %idx_load191)
  %li192 = load i32, ptr %li, align 4
  %add193 = add i32 %li192, 1
  store i32 %add193, ptr %li, align 4
  br label %while_cond182

while_exit184:                                    ; preds = %while_cond182
  call void @preproc__NS_strbuf_push(ptr %out, i8 10)
  br label %if_merge181

if_then196:                                       ; preds = %if_merge176
  %23 = call i8 @preproc__NS_pp_all_active(ptr %cs)
  %if_cond199 = icmp ne i8 %23, 0
  br i1 %if_cond199, label %if_then200, label %if_merge201

if_else197:                                       ; preds = %if_merge176
  %kw255 = load ptr, ptr %kw, align 8
  %24 = call i32 @arc_strcmp(ptr %kw255, ptr @str.19)
  %icmp256 = icmp eq i32 %24, 0
  br i1 %icmp256, label %if_then257, label %if_else258

if_merge198:                                      ; preds = %if_merge259, %if_merge201
  %kw704 = load ptr, ptr %kw, align 8
  call void @arc_free.3(ptr %kw704)
  call void @preproc__NS_strbuf_push(ptr %out, i8 10)
  br label %if_merge79

if_then200:                                       ; preds = %if_then196
  %plen = alloca i32, align 4
  store i32 0, ptr %plen, align 4
  %pstart = alloca ptr, align 8
  %rest202 = load ptr, ptr %rest, align 8
  %25 = call ptr @preproc__NS_pp_extract_angle(ptr %rest202, ptr %plen)
  store ptr %25, ptr %pstart, align 8
  %pstart203 = load ptr, ptr %pstart, align 8
  %icmp204 = icmp ne ptr %pstart203, null
  br i1 %icmp204, label %if_then205, label %if_merge206

if_merge201:                                      ; preds = %if_merge206, %if_then196
  br label %if_merge198

if_then205:                                       ; preds = %if_then200
  %pat = alloca ptr, align 8
  %pstart207 = load ptr, ptr %pstart, align 8
  %plen208 = load i32, ptr %plen, align 4
  %26 = call ptr @preproc__NS_pp_substr_dup(ptr %pstart207, i32 %plen208)
  store ptr %26, ptr %pat, align 8
  %after = alloca ptr, align 8
  %pstart209 = load ptr, ptr %pstart, align 8
  %plen210 = load i32, ptr %plen, align 4
  %ptr_add211 = getelementptr i8, ptr %pstart209, i32 %plen210
  %ptr_add212 = getelementptr i8, ptr %ptr_add211, i32 1
  store ptr %ptr_add212, ptr %after, align 8
  br label %while_cond213

if_merge206:                                      ; preds = %if_merge246, %if_then200
  br label %if_merge201

while_cond213:                                    ; preds = %while_body214, %if_then205
  %after216 = load ptr, ptr %after, align 8
  %deref217 = load i8, ptr %after216, align 1
  %icmp218 = icmp eq i8 %deref217, 32
  br i1 %icmp218, label %lor_merge220, label %lor_rhs219

while_body214:                                    ; preds = %lor_merge220
  %after225 = load ptr, ptr %after, align 8
  %ptr_add226 = getelementptr i8, ptr %after225, i32 1
  store ptr %ptr_add226, ptr %after, align 8
  br label %while_cond213

while_exit215:                                    ; preds = %lor_merge220
  %vlen = alloca i32, align 4
  store i32 0, ptr %vlen, align 4
  %vstart = alloca ptr, align 8
  %after227 = load ptr, ptr %after, align 8
  %27 = call ptr @preproc__NS_pp_extract_angle_smart(ptr %after227, ptr %vlen)
  store ptr %27, ptr %vstart, align 8
  %val = alloca ptr, align 8
  store ptr null, ptr %val, align 8
  %vstart228 = load ptr, ptr %vstart, align 8
  %icmp229 = icmp ne ptr %vstart228, null
  br i1 %icmp229, label %if_then230, label %if_else231

lor_rhs219:                                       ; preds = %while_cond213
  %after221 = load ptr, ptr %after, align 8
  %deref222 = load i8, ptr %after221, align 1
  %icmp223 = icmp eq i8 %deref222, 9
  br label %lor_merge220

lor_merge220:                                     ; preds = %lor_rhs219, %while_cond213
  %lor224 = phi i1 [ true, %while_cond213 ], [ %icmp223, %lor_rhs219 ]
  br i1 %lor224, label %while_body214, label %while_exit215

if_then230:                                       ; preds = %while_exit215
  %vstart233 = load ptr, ptr %vstart, align 8
  %vlen234 = load i32, ptr %vlen, align 4
  %28 = call ptr @preproc__NS_pp_substr_dup(ptr %vstart233, i32 %vlen234)
  store ptr %28, ptr %val, align 8
  br label %if_merge232

if_else231:                                       ; preds = %while_exit215
  %29 = call ptr @arc_malloc.1(i64 1)
  store ptr %29, ptr %val, align 8
  %ptr_load235 = load ptr, ptr %val, align 8
  %ptr_gep236 = getelementptr i8, ptr %ptr_load235, i32 0
  store i8 0, ptr %ptr_gep236, align 1
  br label %if_merge232

if_merge232:                                      ; preds = %if_else231, %if_then230
  %fname = alloca ptr, align 8
  store ptr null, ptr %fname, align 8
  %farity = alloca i32, align 4
  store i32 0, ptr %farity, align 4
  %funcs237 = load ptr, ptr %funcs, align 8
  %icmp238 = icmp ne ptr %funcs237, null
  br i1 %icmp238, label %land_rhs239, label %land_merge240

land_rhs239:                                      ; preds = %if_merge232
  %pat241 = load ptr, ptr %pat, align 8
  %30 = call i8 @preproc__NS_pp_is_func_pattern(ptr %pat241, ptr %fname, ptr %farity)
  %tobool242 = icmp ne i8 %30, 0
  br label %land_merge240

land_merge240:                                    ; preds = %land_rhs239, %if_merge232
  %land243 = phi i1 [ false, %if_merge232 ], [ %tobool242, %land_rhs239 ]
  br i1 %land243, label %if_then244, label %if_else245

if_then244:                                       ; preds = %land_merge240
  %funcs247 = load ptr, ptr %funcs, align 8
  %fname248 = load ptr, ptr %fname, align 8
  %farity249 = load i32, ptr %farity, align 4
  %val250 = load ptr, ptr %val, align 8
  call void @preproc__NS_pp_func_set(ptr %funcs247, ptr %fname248, i32 %farity249, ptr %val250)
  %pat251 = load ptr, ptr %pat, align 8
  call void @arc_free.3(ptr %pat251)
  br label %if_merge246

if_else245:                                       ; preds = %land_merge240
  %macros252 = load ptr, ptr %macros, align 8
  %pat253 = load ptr, ptr %pat, align 8
  %val254 = load ptr, ptr %val, align 8
  call void @preproc__NS_pp_set(ptr %macros252, ptr %pat253, ptr %val254)
  br label %if_merge246

if_merge246:                                      ; preds = %if_else245, %if_then244
  br label %if_merge206

if_then257:                                       ; preds = %if_else197
  %31 = call i8 @preproc__NS_pp_all_active(ptr %cs)
  %if_cond260 = icmp ne i8 %31, 0
  br i1 %if_cond260, label %if_then261, label %if_merge262

if_else258:                                       ; preds = %if_else197
  %kw326 = load ptr, ptr %kw, align 8
  %32 = call i32 @arc_strcmp(ptr %kw326, ptr @str.20)
  %icmp327 = icmp eq i32 %32, 0
  br i1 %icmp327, label %lor_merge329, label %lor_rhs328

if_merge259:                                      ; preds = %if_merge335, %if_merge262
  br label %if_merge198

if_then261:                                       ; preds = %if_then257
  %nlen = alloca i32, align 4
  store i32 0, ptr %nlen, align 4
  %nstart = alloca ptr, align 8
  %rest263 = load ptr, ptr %rest, align 8
  %33 = call ptr @preproc__NS_pp_extract_angle(ptr %rest263, ptr %nlen)
  store ptr %33, ptr %nstart, align 8
  %nstart264 = load ptr, ptr %nstart, align 8
  %icmp265 = icmp ne ptr %nstart264, null
  br i1 %icmp265, label %if_then266, label %if_else267

if_merge262:                                      ; preds = %if_merge268, %if_then257
  br label %if_merge259

if_then266:                                       ; preds = %if_then261
  %n = alloca ptr, align 8
  %nstart269 = load ptr, ptr %nstart, align 8
  %nlen270 = load i32, ptr %nlen, align 4
  %34 = call ptr @preproc__NS_pp_substr_dup(ptr %nstart269, i32 %nlen270)
  store ptr %34, ptr %n, align 8
  %macros271 = load ptr, ptr %macros, align 8
  %n272 = load ptr, ptr %n, align 8
  call void @preproc__NS_pp_undef(ptr %macros271, ptr %n272)
  %n273 = load ptr, ptr %n, align 8
  call void @arc_free.3(ptr %n273)
  br label %if_merge268

if_else267:                                       ; preds = %if_then261
  %j = alloca i32, align 4
  store i32 0, ptr %j, align 4
  br label %while_cond274

if_merge268:                                      ; preds = %if_merge319, %if_then266
  br label %if_merge262

while_cond274:                                    ; preds = %while_body275, %if_else267
  %j277 = load i32, ptr %j, align 4
  %ptr_load278 = load ptr, ptr %rest, align 8
  %ptr_gep279 = getelementptr i8, ptr %ptr_load278, i32 %j277
  %idx_load280 = load i8, ptr %ptr_gep279, align 1
  %icmp281 = icmp ne i8 %idx_load280, 0
  br i1 %icmp281, label %land_rhs282, label %land_merge283

while_body275:                                    ; preds = %land_merge307
  %j314 = load i32, ptr %j, align 4
  %add315 = add i32 %j314, 1
  store i32 %add315, ptr %j, align 4
  br label %while_cond274

while_exit276:                                    ; preds = %land_merge307
  %j316 = load i32, ptr %j, align 4
  %icmp317 = icmp sgt i32 %j316, 0
  br i1 %icmp317, label %if_then318, label %if_merge319

land_rhs282:                                      ; preds = %while_cond274
  %j284 = load i32, ptr %j, align 4
  %ptr_load285 = load ptr, ptr %rest, align 8
  %ptr_gep286 = getelementptr i8, ptr %ptr_load285, i32 %j284
  %idx_load287 = load i8, ptr %ptr_gep286, align 1
  %icmp288 = icmp ne i8 %idx_load287, 32
  br label %land_merge283

land_merge283:                                    ; preds = %land_rhs282, %while_cond274
  %land289 = phi i1 [ false, %while_cond274 ], [ %icmp288, %land_rhs282 ]
  br i1 %land289, label %land_rhs290, label %land_merge291

land_rhs290:                                      ; preds = %land_merge283
  %j292 = load i32, ptr %j, align 4
  %ptr_load293 = load ptr, ptr %rest, align 8
  %ptr_gep294 = getelementptr i8, ptr %ptr_load293, i32 %j292
  %idx_load295 = load i8, ptr %ptr_gep294, align 1
  %icmp296 = icmp ne i8 %idx_load295, 9
  br label %land_merge291

land_merge291:                                    ; preds = %land_rhs290, %land_merge283
  %land297 = phi i1 [ false, %land_merge283 ], [ %icmp296, %land_rhs290 ]
  br i1 %land297, label %land_rhs298, label %land_merge299

land_rhs298:                                      ; preds = %land_merge291
  %j300 = load i32, ptr %j, align 4
  %ptr_load301 = load ptr, ptr %rest, align 8
  %ptr_gep302 = getelementptr i8, ptr %ptr_load301, i32 %j300
  %idx_load303 = load i8, ptr %ptr_gep302, align 1
  %icmp304 = icmp ne i8 %idx_load303, 13
  br label %land_merge299

land_merge299:                                    ; preds = %land_rhs298, %land_merge291
  %land305 = phi i1 [ false, %land_merge291 ], [ %icmp304, %land_rhs298 ]
  br i1 %land305, label %land_rhs306, label %land_merge307

land_rhs306:                                      ; preds = %land_merge299
  %j308 = load i32, ptr %j, align 4
  %ptr_load309 = load ptr, ptr %rest, align 8
  %ptr_gep310 = getelementptr i8, ptr %ptr_load309, i32 %j308
  %idx_load311 = load i8, ptr %ptr_gep310, align 1
  %icmp312 = icmp ne i8 %idx_load311, 10
  br label %land_merge307

land_merge307:                                    ; preds = %land_rhs306, %land_merge299
  %land313 = phi i1 [ false, %land_merge299 ], [ %icmp312, %land_rhs306 ]
  br i1 %land313, label %while_body275, label %while_exit276

if_then318:                                       ; preds = %while_exit276
  %n320 = alloca ptr, align 8
  %rest321 = load ptr, ptr %rest, align 8
  %j322 = load i32, ptr %j, align 4
  %35 = call ptr @preproc__NS_pp_substr_dup(ptr %rest321, i32 %j322)
  store ptr %35, ptr %n320, align 8
  %macros323 = load ptr, ptr %macros, align 8
  %n324 = load ptr, ptr %n320, align 8
  call void @preproc__NS_pp_undef(ptr %macros323, ptr %n324)
  %n325 = load ptr, ptr %n320, align 8
  call void @arc_free.3(ptr %n325)
  br label %if_merge319

if_merge319:                                      ; preds = %if_then318, %while_exit276
  br label %if_merge268

lor_rhs328:                                       ; preds = %if_else258
  %kw330 = load ptr, ptr %kw, align 8
  %36 = call i32 @arc_strcmp(ptr %kw330, ptr @str.21)
  %icmp331 = icmp eq i32 %36, 0
  br label %lor_merge329

lor_merge329:                                     ; preds = %lor_rhs328, %if_else258
  %lor332 = phi i1 [ true, %if_else258 ], [ %icmp331, %lor_rhs328 ]
  br i1 %lor332, label %if_then333, label %if_else334

if_then333:                                       ; preds = %lor_merge329
  %nlen336 = alloca i32, align 4
  store i32 0, ptr %nlen336, align 4
  %nstart337 = alloca ptr, align 8
  %rest338 = load ptr, ptr %rest, align 8
  %37 = call ptr @preproc__NS_pp_extract_angle(ptr %rest338, ptr %nlen336)
  store ptr %37, ptr %nstart337, align 8
  %name = alloca ptr, align 8
  store ptr null, ptr %name, align 8
  %nstart339 = load ptr, ptr %nstart337, align 8
  %icmp340 = icmp ne ptr %nstart339, null
  br i1 %icmp340, label %if_then341, label %if_else342

if_else334:                                       ; preds = %lor_merge329
  %kw431 = load ptr, ptr %kw, align 8
  %38 = call i32 @arc_strcmp(ptr %kw431, ptr @str.23)
  %icmp432 = icmp eq i32 %38, 0
  br i1 %icmp432, label %lor_merge434, label %lor_rhs433

if_merge335:                                      ; preds = %if_merge440, %if_merge406
  br label %if_merge259

if_then341:                                       ; preds = %if_then333
  %nstart344 = load ptr, ptr %nstart337, align 8
  %nlen345 = load i32, ptr %nlen336, align 4
  %39 = call ptr @preproc__NS_pp_substr_dup(ptr %nstart344, i32 %nlen345)
  store ptr %39, ptr %name, align 8
  br label %if_merge343

if_else342:                                       ; preds = %if_then333
  %j346 = alloca i32, align 4
  store i32 0, ptr %j346, align 4
  br label %while_cond347

if_merge343:                                      ; preds = %while_exit349, %if_then341
  %def = alloca i8, align 1
  %macros391 = load ptr, ptr %macros, align 8
  %name392 = load ptr, ptr %name, align 8
  %40 = call i8 @preproc__NS_pp_defined(ptr %macros391, ptr %name392)
  store i8 %40, ptr %def, align 1
  %name393 = load ptr, ptr %name, align 8
  call void @arc_free.3(ptr %name393)
  %cond = alloca i8, align 1
  store i8 0, ptr %cond, align 1
  %kw394 = load ptr, ptr %kw, align 8
  %41 = call i32 @arc_strcmp(ptr %kw394, ptr @str.22)
  %icmp395 = icmp eq i32 %41, 0
  br i1 %icmp395, label %if_then396, label %if_else397

while_cond347:                                    ; preds = %while_body348, %if_else342
  %j350 = load i32, ptr %j346, align 4
  %ptr_load351 = load ptr, ptr %rest, align 8
  %ptr_gep352 = getelementptr i8, ptr %ptr_load351, i32 %j350
  %idx_load353 = load i8, ptr %ptr_gep352, align 1
  %icmp354 = icmp ne i8 %idx_load353, 0
  br i1 %icmp354, label %land_rhs355, label %land_merge356

while_body348:                                    ; preds = %land_merge380
  %j387 = load i32, ptr %j346, align 4
  %add388 = add i32 %j387, 1
  store i32 %add388, ptr %j346, align 4
  br label %while_cond347

while_exit349:                                    ; preds = %land_merge380
  %rest389 = load ptr, ptr %rest, align 8
  %j390 = load i32, ptr %j346, align 4
  %42 = call ptr @preproc__NS_pp_substr_dup(ptr %rest389, i32 %j390)
  store ptr %42, ptr %name, align 8
  br label %if_merge343

land_rhs355:                                      ; preds = %while_cond347
  %j357 = load i32, ptr %j346, align 4
  %ptr_load358 = load ptr, ptr %rest, align 8
  %ptr_gep359 = getelementptr i8, ptr %ptr_load358, i32 %j357
  %idx_load360 = load i8, ptr %ptr_gep359, align 1
  %icmp361 = icmp ne i8 %idx_load360, 32
  br label %land_merge356

land_merge356:                                    ; preds = %land_rhs355, %while_cond347
  %land362 = phi i1 [ false, %while_cond347 ], [ %icmp361, %land_rhs355 ]
  br i1 %land362, label %land_rhs363, label %land_merge364

land_rhs363:                                      ; preds = %land_merge356
  %j365 = load i32, ptr %j346, align 4
  %ptr_load366 = load ptr, ptr %rest, align 8
  %ptr_gep367 = getelementptr i8, ptr %ptr_load366, i32 %j365
  %idx_load368 = load i8, ptr %ptr_gep367, align 1
  %icmp369 = icmp ne i8 %idx_load368, 9
  br label %land_merge364

land_merge364:                                    ; preds = %land_rhs363, %land_merge356
  %land370 = phi i1 [ false, %land_merge356 ], [ %icmp369, %land_rhs363 ]
  br i1 %land370, label %land_rhs371, label %land_merge372

land_rhs371:                                      ; preds = %land_merge364
  %j373 = load i32, ptr %j346, align 4
  %ptr_load374 = load ptr, ptr %rest, align 8
  %ptr_gep375 = getelementptr i8, ptr %ptr_load374, i32 %j373
  %idx_load376 = load i8, ptr %ptr_gep375, align 1
  %icmp377 = icmp ne i8 %idx_load376, 13
  br label %land_merge372

land_merge372:                                    ; preds = %land_rhs371, %land_merge364
  %land378 = phi i1 [ false, %land_merge364 ], [ %icmp377, %land_rhs371 ]
  br i1 %land378, label %land_rhs379, label %land_merge380

land_rhs379:                                      ; preds = %land_merge372
  %j381 = load i32, ptr %j346, align 4
  %ptr_load382 = load ptr, ptr %rest, align 8
  %ptr_gep383 = getelementptr i8, ptr %ptr_load382, i32 %j381
  %idx_load384 = load i8, ptr %ptr_gep383, align 1
  %icmp385 = icmp ne i8 %idx_load384, 10
  br label %land_merge380

land_merge380:                                    ; preds = %land_rhs379, %land_merge372
  %land386 = phi i1 [ false, %land_merge372 ], [ %icmp385, %land_rhs379 ]
  br i1 %land386, label %while_body348, label %while_exit349

if_then396:                                       ; preds = %if_merge343
  %def399 = load i8, ptr %def, align 1
  store i8 %def399, ptr %cond, align 1
  br label %if_merge398

if_else397:                                       ; preds = %if_merge343
  %def400 = load i8, ptr %def, align 1
  %tobool401 = icmp ne i8 %def400, 0
  %not402 = xor i1 %tobool401, true
  %zext403 = zext i1 %not402 to i8
  store i8 %zext403, ptr %cond, align 1
  br label %if_merge398

if_merge398:                                      ; preds = %if_else397, %if_then396
  %depth = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 3
  %mem_load = load i32, ptr %depth, align 4
  %icmp404 = icmp slt i32 %mem_load, 64
  br i1 %icmp404, label %if_then405, label %if_merge406

if_then405:                                       ; preds = %if_merge398
  %active = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 0
  %depth407 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 3
  %mem_load408 = load i32, ptr %depth407, align 4
  %arr_gep = getelementptr [64 x i8], ptr %active, i64 0, i32 %mem_load408
  %cond409 = load i8, ptr %cond, align 1
  %tobool410 = icmp ne i8 %cond409, 0
  br i1 %tobool410, label %land_rhs411, label %land_merge412

if_merge406:                                      ; preds = %land_merge412, %if_merge398
  br label %if_merge335

land_rhs411:                                      ; preds = %if_then405
  %43 = call i8 @preproc__NS_pp_all_active(ptr %cs)
  %tobool413 = icmp ne i8 %43, 0
  br label %land_merge412

land_merge412:                                    ; preds = %land_rhs411, %if_then405
  %land414 = phi i1 [ false, %if_then405 ], [ %tobool413, %land_rhs411 ]
  %zext415 = zext i1 %land414 to i8
  store i8 %zext415, ptr %arr_gep, align 1
  %ever_active = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 1
  %depth416 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 3
  %mem_load417 = load i32, ptr %depth416, align 4
  %arr_gep418 = getelementptr [64 x i8], ptr %ever_active, i64 0, i32 %mem_load417
  %active419 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 0
  %depth420 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 3
  %mem_load421 = load i32, ptr %depth420, align 4
  %arr_gep422 = getelementptr [64 x i8], ptr %active419, i64 0, i32 %mem_load421
  %idx_load423 = load i8, ptr %arr_gep422, align 1
  store i8 %idx_load423, ptr %arr_gep418, align 1
  %done = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 2
  %depth424 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 3
  %mem_load425 = load i32, ptr %depth424, align 4
  %arr_gep426 = getelementptr [64 x i8], ptr %done, i64 0, i32 %mem_load425
  store i8 0, ptr %arr_gep426, align 1
  %depth427 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 3
  %depth428 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 3
  %mem_load429 = load i32, ptr %depth428, align 4
  %add430 = add i32 %mem_load429, 1
  store i32 %add430, ptr %depth427, align 4
  br label %if_merge406

lor_rhs433:                                       ; preds = %if_else334
  %kw435 = load ptr, ptr %kw, align 8
  %44 = call i32 @arc_strcmp(ptr %kw435, ptr @str.24)
  %icmp436 = icmp eq i32 %44, 0
  br label %lor_merge434

lor_merge434:                                     ; preds = %lor_rhs433, %if_else334
  %lor437 = phi i1 [ true, %if_else334 ], [ %icmp436, %lor_rhs433 ]
  br i1 %lor437, label %if_then438, label %if_else439

if_then438:                                       ; preds = %lor_merge434
  %depth441 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 3
  %mem_load442 = load i32, ptr %depth441, align 4
  %icmp443 = icmp sgt i32 %mem_load442, 0
  br i1 %icmp443, label %if_then444, label %if_merge445

if_else439:                                       ; preds = %lor_merge434
  %kw570 = load ptr, ptr %kw, align 8
  %45 = call i32 @arc_strcmp(ptr %kw570, ptr @str.26)
  %icmp571 = icmp eq i32 %45, 0
  br i1 %icmp571, label %if_then572, label %if_else573

if_merge440:                                      ; preds = %if_merge574, %if_merge445
  br label %if_merge335

if_then444:                                       ; preds = %if_then438
  %ti = alloca i32, align 4
  %depth446 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 3
  %mem_load447 = load i32, ptr %depth446, align 4
  %sub448 = sub i32 %mem_load447, 1
  store i32 %sub448, ptr %ti, align 4
  %ever_active449 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 1
  %ti450 = load i32, ptr %ti, align 4
  %arr_gep451 = getelementptr [64 x i8], ptr %ever_active449, i64 0, i32 %ti450
  %idx_load452 = load i8, ptr %arr_gep451, align 1
  %tobool453 = icmp ne i8 %idx_load452, 0
  %not454 = xor i1 %tobool453, true
  br i1 %not454, label %land_rhs455, label %land_merge456

if_merge445:                                      ; preds = %if_merge466, %if_then438
  br label %if_merge440

land_rhs455:                                      ; preds = %if_then444
  %done457 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 2
  %ti458 = load i32, ptr %ti, align 4
  %arr_gep459 = getelementptr [64 x i8], ptr %done457, i64 0, i32 %ti458
  %idx_load460 = load i8, ptr %arr_gep459, align 1
  %tobool461 = icmp ne i8 %idx_load460, 0
  %not462 = xor i1 %tobool461, true
  br label %land_merge456

land_merge456:                                    ; preds = %land_rhs455, %if_then444
  %land463 = phi i1 [ false, %if_then444 ], [ %not462, %land_rhs455 ]
  br i1 %land463, label %if_then464, label %if_else465

if_then464:                                       ; preds = %land_merge456
  %nlen467 = alloca i32, align 4
  store i32 0, ptr %nlen467, align 4
  %nstart468 = alloca ptr, align 8
  %rest469 = load ptr, ptr %rest, align 8
  %46 = call ptr @preproc__NS_pp_extract_angle(ptr %rest469, ptr %nlen467)
  store ptr %46, ptr %nstart468, align 8
  %name470 = alloca ptr, align 8
  store ptr null, ptr %name470, align 8
  %nstart471 = load ptr, ptr %nstart468, align 8
  %icmp472 = icmp ne ptr %nstart471, null
  br i1 %icmp472, label %if_then473, label %if_else474

if_else465:                                       ; preds = %land_merge456
  %active565 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 0
  %depth566 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 3
  %mem_load567 = load i32, ptr %depth566, align 4
  %sub568 = sub i32 %mem_load567, 1
  %arr_gep569 = getelementptr [64 x i8], ptr %active565, i64 0, i32 %sub568
  store i8 0, ptr %arr_gep569, align 1
  br label %if_merge466

if_merge466:                                      ; preds = %if_else465, %lor_merge557
  br label %if_merge445

if_then473:                                       ; preds = %if_then464
  %nstart476 = load ptr, ptr %nstart468, align 8
  %nlen477 = load i32, ptr %nlen467, align 4
  %47 = call ptr @preproc__NS_pp_substr_dup(ptr %nstart476, i32 %nlen477)
  store ptr %47, ptr %name470, align 8
  br label %if_merge475

if_else474:                                       ; preds = %if_then464
  %j478 = alloca i32, align 4
  store i32 0, ptr %j478, align 4
  br label %while_cond479

if_merge475:                                      ; preds = %while_exit481, %if_then473
  %def523 = alloca i8, align 1
  %macros524 = load ptr, ptr %macros, align 8
  %name525 = load ptr, ptr %name470, align 8
  %48 = call i8 @preproc__NS_pp_defined(ptr %macros524, ptr %name525)
  store i8 %48, ptr %def523, align 1
  %name526 = load ptr, ptr %name470, align 8
  call void @arc_free.3(ptr %name526)
  %cond527 = alloca i8, align 1
  store i8 0, ptr %cond527, align 1
  %kw528 = load ptr, ptr %kw, align 8
  %49 = call i32 @arc_strcmp(ptr %kw528, ptr @str.25)
  %icmp529 = icmp eq i32 %49, 0
  br i1 %icmp529, label %if_then530, label %if_else531

while_cond479:                                    ; preds = %while_body480, %if_else474
  %j482 = load i32, ptr %j478, align 4
  %ptr_load483 = load ptr, ptr %rest, align 8
  %ptr_gep484 = getelementptr i8, ptr %ptr_load483, i32 %j482
  %idx_load485 = load i8, ptr %ptr_gep484, align 1
  %icmp486 = icmp ne i8 %idx_load485, 0
  br i1 %icmp486, label %land_rhs487, label %land_merge488

while_body480:                                    ; preds = %land_merge512
  %j519 = load i32, ptr %j478, align 4
  %add520 = add i32 %j519, 1
  store i32 %add520, ptr %j478, align 4
  br label %while_cond479

while_exit481:                                    ; preds = %land_merge512
  %rest521 = load ptr, ptr %rest, align 8
  %j522 = load i32, ptr %j478, align 4
  %50 = call ptr @preproc__NS_pp_substr_dup(ptr %rest521, i32 %j522)
  store ptr %50, ptr %name470, align 8
  br label %if_merge475

land_rhs487:                                      ; preds = %while_cond479
  %j489 = load i32, ptr %j478, align 4
  %ptr_load490 = load ptr, ptr %rest, align 8
  %ptr_gep491 = getelementptr i8, ptr %ptr_load490, i32 %j489
  %idx_load492 = load i8, ptr %ptr_gep491, align 1
  %icmp493 = icmp ne i8 %idx_load492, 32
  br label %land_merge488

land_merge488:                                    ; preds = %land_rhs487, %while_cond479
  %land494 = phi i1 [ false, %while_cond479 ], [ %icmp493, %land_rhs487 ]
  br i1 %land494, label %land_rhs495, label %land_merge496

land_rhs495:                                      ; preds = %land_merge488
  %j497 = load i32, ptr %j478, align 4
  %ptr_load498 = load ptr, ptr %rest, align 8
  %ptr_gep499 = getelementptr i8, ptr %ptr_load498, i32 %j497
  %idx_load500 = load i8, ptr %ptr_gep499, align 1
  %icmp501 = icmp ne i8 %idx_load500, 9
  br label %land_merge496

land_merge496:                                    ; preds = %land_rhs495, %land_merge488
  %land502 = phi i1 [ false, %land_merge488 ], [ %icmp501, %land_rhs495 ]
  br i1 %land502, label %land_rhs503, label %land_merge504

land_rhs503:                                      ; preds = %land_merge496
  %j505 = load i32, ptr %j478, align 4
  %ptr_load506 = load ptr, ptr %rest, align 8
  %ptr_gep507 = getelementptr i8, ptr %ptr_load506, i32 %j505
  %idx_load508 = load i8, ptr %ptr_gep507, align 1
  %icmp509 = icmp ne i8 %idx_load508, 13
  br label %land_merge504

land_merge504:                                    ; preds = %land_rhs503, %land_merge496
  %land510 = phi i1 [ false, %land_merge496 ], [ %icmp509, %land_rhs503 ]
  br i1 %land510, label %land_rhs511, label %land_merge512

land_rhs511:                                      ; preds = %land_merge504
  %j513 = load i32, ptr %j478, align 4
  %ptr_load514 = load ptr, ptr %rest, align 8
  %ptr_gep515 = getelementptr i8, ptr %ptr_load514, i32 %j513
  %idx_load516 = load i8, ptr %ptr_gep515, align 1
  %icmp517 = icmp ne i8 %idx_load516, 10
  br label %land_merge512

land_merge512:                                    ; preds = %land_rhs511, %land_merge504
  %land518 = phi i1 [ false, %land_merge504 ], [ %icmp517, %land_rhs511 ]
  br i1 %land518, label %while_body480, label %while_exit481

if_then530:                                       ; preds = %if_merge475
  %def533 = load i8, ptr %def523, align 1
  store i8 %def533, ptr %cond527, align 1
  br label %if_merge532

if_else531:                                       ; preds = %if_merge475
  %def534 = load i8, ptr %def523, align 1
  %tobool535 = icmp ne i8 %def534, 0
  %not536 = xor i1 %tobool535, true
  %zext537 = zext i1 %not536 to i8
  store i8 %zext537, ptr %cond527, align 1
  br label %if_merge532

if_merge532:                                      ; preds = %if_else531, %if_then530
  %active538 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 0
  %ti539 = load i32, ptr %ti, align 4
  %arr_gep540 = getelementptr [64 x i8], ptr %active538, i64 0, i32 %ti539
  %cond541 = load i8, ptr %cond527, align 1
  %tobool542 = icmp ne i8 %cond541, 0
  br i1 %tobool542, label %land_rhs543, label %land_merge544

land_rhs543:                                      ; preds = %if_merge532
  %51 = call i8 @preproc__NS_pp_parents_active(ptr %cs)
  %tobool545 = icmp ne i8 %51, 0
  br label %land_merge544

land_merge544:                                    ; preds = %land_rhs543, %if_merge532
  %land546 = phi i1 [ false, %if_merge532 ], [ %tobool545, %land_rhs543 ]
  %zext547 = zext i1 %land546 to i8
  store i8 %zext547, ptr %arr_gep540, align 1
  %ever_active548 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 1
  %ti549 = load i32, ptr %ti, align 4
  %arr_gep550 = getelementptr [64 x i8], ptr %ever_active548, i64 0, i32 %ti549
  %ever_active551 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 1
  %ti552 = load i32, ptr %ti, align 4
  %arr_gep553 = getelementptr [64 x i8], ptr %ever_active551, i64 0, i32 %ti552
  %idx_load554 = load i8, ptr %arr_gep553, align 1
  %tobool555 = icmp ne i8 %idx_load554, 0
  br i1 %tobool555, label %lor_merge557, label %lor_rhs556

lor_rhs556:                                       ; preds = %land_merge544
  %active558 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 0
  %ti559 = load i32, ptr %ti, align 4
  %arr_gep560 = getelementptr [64 x i8], ptr %active558, i64 0, i32 %ti559
  %idx_load561 = load i8, ptr %arr_gep560, align 1
  %tobool562 = icmp ne i8 %idx_load561, 0
  br label %lor_merge557

lor_merge557:                                     ; preds = %lor_rhs556, %land_merge544
  %lor563 = phi i1 [ true, %land_merge544 ], [ %tobool562, %lor_rhs556 ]
  %zext564 = zext i1 %lor563 to i8
  store i8 %zext564, ptr %arr_gep550, align 1
  br label %if_merge466

if_then572:                                       ; preds = %if_else439
  %depth575 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 3
  %mem_load576 = load i32, ptr %depth575, align 4
  %icmp577 = icmp sgt i32 %mem_load576, 0
  br i1 %icmp577, label %if_then578, label %if_merge579

if_else573:                                       ; preds = %if_else439
  %kw617 = load ptr, ptr %kw, align 8
  %52 = call i32 @arc_strcmp(ptr %kw617, ptr @str.27)
  %icmp618 = icmp eq i32 %52, 0
  br i1 %icmp618, label %if_then619, label %if_else620

if_merge574:                                      ; preds = %if_merge621, %if_merge579
  br label %if_merge440

if_then578:                                       ; preds = %if_then572
  %ti580 = alloca i32, align 4
  %depth581 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 3
  %mem_load582 = load i32, ptr %depth581, align 4
  %sub583 = sub i32 %mem_load582, 1
  store i32 %sub583, ptr %ti580, align 4
  %ever_active584 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 1
  %ti585 = load i32, ptr %ti580, align 4
  %arr_gep586 = getelementptr [64 x i8], ptr %ever_active584, i64 0, i32 %ti585
  %idx_load587 = load i8, ptr %arr_gep586, align 1
  %tobool588 = icmp ne i8 %idx_load587, 0
  %not589 = xor i1 %tobool588, true
  br i1 %not589, label %land_rhs590, label %land_merge591

if_merge579:                                      ; preds = %if_merge601, %if_then572
  br label %if_merge574

land_rhs590:                                      ; preds = %if_then578
  %done592 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 2
  %ti593 = load i32, ptr %ti580, align 4
  %arr_gep594 = getelementptr [64 x i8], ptr %done592, i64 0, i32 %ti593
  %idx_load595 = load i8, ptr %arr_gep594, align 1
  %tobool596 = icmp ne i8 %idx_load595, 0
  %not597 = xor i1 %tobool596, true
  br label %land_merge591

land_merge591:                                    ; preds = %land_rhs590, %if_then578
  %land598 = phi i1 [ false, %if_then578 ], [ %not597, %land_rhs590 ]
  br i1 %land598, label %if_then599, label %if_else600

if_then599:                                       ; preds = %land_merge591
  %active602 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 0
  %ti603 = load i32, ptr %ti580, align 4
  %arr_gep604 = getelementptr [64 x i8], ptr %active602, i64 0, i32 %ti603
  %53 = call i8 @preproc__NS_pp_parents_active(ptr %cs)
  store i8 %53, ptr %arr_gep604, align 1
  %ever_active605 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 1
  %ti606 = load i32, ptr %ti580, align 4
  %arr_gep607 = getelementptr [64 x i8], ptr %ever_active605, i64 0, i32 %ti606
  store i8 1, ptr %arr_gep607, align 1
  %done608 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 2
  %ti609 = load i32, ptr %ti580, align 4
  %arr_gep610 = getelementptr [64 x i8], ptr %done608, i64 0, i32 %ti609
  store i8 1, ptr %arr_gep610, align 1
  br label %if_merge601

if_else600:                                       ; preds = %land_merge591
  %active611 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 0
  %ti612 = load i32, ptr %ti580, align 4
  %arr_gep613 = getelementptr [64 x i8], ptr %active611, i64 0, i32 %ti612
  store i8 0, ptr %arr_gep613, align 1
  %done614 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 2
  %ti615 = load i32, ptr %ti580, align 4
  %arr_gep616 = getelementptr [64 x i8], ptr %done614, i64 0, i32 %ti615
  store i8 1, ptr %arr_gep616, align 1
  br label %if_merge601

if_merge601:                                      ; preds = %if_else600, %if_then599
  br label %if_merge579

if_then619:                                       ; preds = %if_else573
  %depth622 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 3
  %mem_load623 = load i32, ptr %depth622, align 4
  %icmp624 = icmp sgt i32 %mem_load623, 0
  br i1 %icmp624, label %if_then625, label %if_merge626

if_else620:                                       ; preds = %if_else573
  %kw631 = load ptr, ptr %kw, align 8
  %54 = call i32 @arc_strcmp(ptr %kw631, ptr @str.28)
  %icmp632 = icmp eq i32 %54, 0
  br i1 %icmp632, label %lor_merge634, label %lor_rhs633

if_merge621:                                      ; preds = %if_merge640, %if_merge626
  br label %if_merge574

if_then625:                                       ; preds = %if_then619
  %depth627 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 3
  %depth628 = getelementptr inbounds nuw %pp_stack, ptr %cs, i32 0, i32 3
  %mem_load629 = load i32, ptr %depth628, align 4
  %sub630 = sub i32 %mem_load629, 1
  store i32 %sub630, ptr %depth627, align 4
  br label %if_merge626

if_merge626:                                      ; preds = %if_then625, %if_then619
  br label %if_merge621

lor_rhs633:                                       ; preds = %if_else620
  %kw635 = load ptr, ptr %kw, align 8
  %55 = call i32 @arc_strcmp(ptr %kw635, ptr @str.29)
  %icmp636 = icmp eq i32 %55, 0
  br label %lor_merge634

lor_merge634:                                     ; preds = %lor_rhs633, %if_else620
  %lor637 = phi i1 [ true, %if_else620 ], [ %icmp636, %lor_rhs633 ]
  br i1 %lor637, label %if_then638, label %if_else639

if_then638:                                       ; preds = %lor_merge634
  %56 = call i8 @preproc__NS_pp_all_active(ptr %cs)
  %tobool641 = icmp ne i8 %56, 0
  br i1 %tobool641, label %land_rhs642, label %land_merge643

if_else639:                                       ; preds = %lor_merge634
  %kw693 = load ptr, ptr %kw, align 8
  %57 = call i32 @arc_strcmp(ptr %kw693, ptr @str.32)
  %icmp694 = icmp eq i32 %57, 0
  br i1 %icmp694, label %if_then695, label %if_merge696

if_merge640:                                      ; preds = %if_merge696, %if_merge648
  br label %if_merge621

land_rhs642:                                      ; preds = %if_then638
  %base_dir644 = load ptr, ptr %base_dir, align 8
  %icmp645 = icmp ne ptr %base_dir644, null
  br label %land_merge643

land_merge643:                                    ; preds = %land_rhs642, %if_then638
  %land646 = phi i1 [ false, %if_then638 ], [ %icmp645, %land_rhs642 ]
  br i1 %land646, label %if_then647, label %if_merge648

if_then647:                                       ; preds = %land_merge643
  %flen = alloca i32, align 4
  store i32 0, ptr %flen, align 4
  %fstart = alloca ptr, align 8
  %rest649 = load ptr, ptr %rest, align 8
  %58 = call ptr @preproc__NS_pp_extract_angle(ptr %rest649, ptr %flen)
  store ptr %58, ptr %fstart, align 8
  %fstart650 = load ptr, ptr %fstart, align 8
  %icmp651 = icmp ne ptr %fstart650, null
  br i1 %icmp651, label %if_then652, label %if_merge653

if_merge648:                                      ; preds = %if_merge653, %land_merge643
  br label %if_merge640

if_then652:                                       ; preds = %if_then647
  %fname654 = alloca ptr, align 8
  %fstart655 = load ptr, ptr %fstart, align 8
  %flen656 = load i32, ptr %flen, align 4
  %59 = call ptr @preproc__NS_pp_substr_dup(ptr %fstart655, i32 %flen656)
  store ptr %59, ptr %fname654, align 8
  %fpath = alloca [2048 x i8], align 1
  store [2048 x i8] zeroinitializer, ptr %fpath, align 1
  %arr_decay = getelementptr [2048 x i8], ptr %fpath, i64 0, i64 0
  %base_dir657 = load ptr, ptr %base_dir, align 8
  %fname658 = load ptr, ptr %fname654, align 8
  %anon_s = alloca %__anon2_P_P, align 8
  %anon_f = getelementptr inbounds nuw %__anon2_P_P, ptr %anon_s, i32 0, i32 0
  store ptr %base_dir657, ptr %anon_f, align 8
  %anon_f659 = getelementptr inbounds nuw %__anon2_P_P, ptr %anon_s, i32 0, i32 1
  store ptr %fname658, ptr %anon_f659, align 8
  %anon_load = load %__anon2_P_P, ptr %anon_s, align 8
  %60 = call i32 @afmt__at_args_S__anon2_P_P(ptr %arr_decay, i64 2048, ptr @str.30, %__anon2_P_P %anon_load)
  %fname660 = load ptr, ptr %fname654, align 8
  call void @arc_free.3(ptr %fname660)
  %included661 = load ptr, ptr %included, align 8
  %icmp662 = icmp eq ptr %included661, null
  br i1 %icmp662, label %lor_merge664, label %lor_rhs663

if_merge653:                                      ; preds = %if_merge671, %if_then647
  br label %if_merge648

lor_rhs663:                                       ; preds = %if_then652
  %included665 = load ptr, ptr %included, align 8
  %arr_decay666 = getelementptr [2048 x i8], ptr %fpath, i64 0, i64 0
  %61 = call i8 @preproc__NS_pp_defined(ptr %included665, ptr %arr_decay666)
  %tobool667 = icmp ne i8 %61, 0
  %not668 = xor i1 %tobool667, true
  br label %lor_merge664

lor_merge664:                                     ; preds = %lor_rhs663, %if_then652
  %lor669 = phi i1 [ true, %if_then652 ], [ %not668, %lor_rhs663 ]
  br i1 %lor669, label %if_then670, label %if_merge671

if_then670:                                       ; preds = %lor_merge664
  %included672 = load ptr, ptr %included, align 8
  %icmp673 = icmp ne ptr %included672, null
  br i1 %icmp673, label %if_then674, label %if_merge675

if_merge671:                                      ; preds = %if_merge683, %lor_merge664
  br label %if_merge653

if_then674:                                       ; preds = %if_then670
  %included676 = load ptr, ptr %included, align 8
  %arr_decay677 = getelementptr [2048 x i8], ptr %fpath, i64 0, i64 0
  %arr_decay678 = getelementptr [2048 x i8], ptr %fpath, i64 0, i64 0
  %62 = call i64 @arc_strlen(ptr %arr_decay678)
  %trunc = trunc i64 %62 to i32
  %63 = call ptr @preproc__NS_pp_substr_dup(ptr %arr_decay677, i32 %trunc)
  call void @preproc__NS_pp_set(ptr %included676, ptr %63, ptr @str.31)
  br label %if_merge675

if_merge675:                                      ; preds = %if_then674, %if_then670
  %inc = alloca ptr, align 8
  %arr_decay679 = getelementptr [2048 x i8], ptr %fpath, i64 0, i64 0
  %64 = call ptr @preproc__NS_pp_read_file(ptr %arr_decay679)
  store ptr %64, ptr %inc, align 8
  %inc680 = load ptr, ptr %inc, align 8
  %icmp681 = icmp ne ptr %inc680, null
  br i1 %icmp681, label %if_then682, label %if_merge683

if_then682:                                       ; preds = %if_merge675
  %expanded = alloca ptr, align 8
  %inc684 = load ptr, ptr %inc, align 8
  %base_dir685 = load ptr, ptr %base_dir, align 8
  %macros686 = load ptr, ptr %macros, align 8
  %funcs687 = load ptr, ptr %funcs, align 8
  %stdlib_path688 = load ptr, ptr %stdlib_path, align 8
  %included689 = load ptr, ptr %included, align 8
  %65 = call ptr @preproc__NS_preprocess_inner(ptr %inc684, ptr %base_dir685, ptr %macros686, ptr %funcs687, ptr %stdlib_path688, ptr %included689)
  store ptr %65, ptr %expanded, align 8
  %expanded690 = load ptr, ptr %expanded, align 8
  call void @preproc__NS_strbuf_append_cstr(ptr %out, ptr %expanded690)
  %expanded691 = load ptr, ptr %expanded, align 8
  call void @arc_free.3(ptr %expanded691)
  %inc692 = load ptr, ptr %inc, align 8
  call void @arc_free.3(ptr %inc692)
  br label %if_merge683

if_merge683:                                      ; preds = %if_then682, %if_merge675
  br label %if_merge671

if_then695:                                       ; preds = %if_else639
  %66 = call i8 @preproc__NS_pp_all_active(ptr %cs)
  %if_cond697 = icmp ne i8 %66, 0
  br i1 %if_cond697, label %if_then698, label %if_merge699

if_merge696:                                      ; preds = %if_merge699, %if_else639
  br label %if_merge640

if_then698:                                       ; preds = %if_then695
  %rest700 = load ptr, ptr %rest, align 8
  %anon_s701 = alloca %__anon1_P, align 8
  %anon_f702 = getelementptr inbounds nuw %__anon1_P, ptr %anon_s701, i32 0, i32 0
  store ptr %rest700, ptr %anon_f702, align 8
  %anon_load703 = load %__anon1_P, ptr %anon_s701, align 8
  %67 = call i32 @aprint__at_args_S__anon1_P(ptr @str.33, %__anon1_P %anon_load703)
  call void @arc_exit(i32 1)
  br label %if_merge699

if_merge699:                                      ; preds = %if_then698, %if_then695
  br label %if_merge696

if_then706:                                       ; preds = %if_else
  %handled_std = alloca i8, align 1
  store i8 0, ptr %handled_std, align 1
  %std_nm_start = alloca i32, align 4
  store i32 0, ptr %std_nm_start, align 4
  %got_std_nm = alloca i8, align 1
  store i8 0, ptr %got_std_nm, align 1
  %ps = alloca i32, align 4
  %ind708 = load i32, ptr %ind, align 4
  store i32 %ind708, ptr %ps, align 4
  %line_len709 = load i32, ptr %line_len, align 4
  %ps710 = load i32, ptr %ps, align 4
  %sub711 = sub i32 %line_len709, %ps710
  %icmp712 = icmp sge i32 %sub711, 6
  br i1 %icmp712, label %land_rhs713, label %land_merge714

if_merge707:                                      ; preds = %if_merge1221, %if_else
  call void @preproc__NS_strbuf_push(ptr %out, i8 10)
  br label %if_merge79

land_rhs713:                                      ; preds = %if_then706
  %ps715 = load i32, ptr %ps, align 4
  %ptr_load716 = load ptr, ptr %line, align 8
  %ptr_gep717 = getelementptr i8, ptr %ptr_load716, i32 %ps715
  %idx_load718 = load i8, ptr %ptr_gep717, align 1
  %icmp719 = icmp eq i8 %idx_load718, 101
  br label %land_merge714

land_merge714:                                    ; preds = %land_rhs713, %if_then706
  %land720 = phi i1 [ false, %if_then706 ], [ %icmp719, %land_rhs713 ]
  br i1 %land720, label %land_rhs721, label %land_merge722

land_rhs721:                                      ; preds = %land_merge714
  %ps723 = load i32, ptr %ps, align 4
  %add724 = add i32 %ps723, 1
  %ptr_load725 = load ptr, ptr %line, align 8
  %ptr_gep726 = getelementptr i8, ptr %ptr_load725, i32 %add724
  %idx_load727 = load i8, ptr %ptr_gep726, align 1
  %icmp728 = icmp eq i8 %idx_load727, 120
  br label %land_merge722

land_merge722:                                    ; preds = %land_rhs721, %land_merge714
  %land729 = phi i1 [ false, %land_merge714 ], [ %icmp728, %land_rhs721 ]
  br i1 %land729, label %land_rhs730, label %land_merge731

land_rhs730:                                      ; preds = %land_merge722
  %ps732 = load i32, ptr %ps, align 4
  %add733 = add i32 %ps732, 2
  %ptr_load734 = load ptr, ptr %line, align 8
  %ptr_gep735 = getelementptr i8, ptr %ptr_load734, i32 %add733
  %idx_load736 = load i8, ptr %ptr_gep735, align 1
  %icmp737 = icmp eq i8 %idx_load736, 116
  br label %land_merge731

land_merge731:                                    ; preds = %land_rhs730, %land_merge722
  %land738 = phi i1 [ false, %land_merge722 ], [ %icmp737, %land_rhs730 ]
  br i1 %land738, label %land_rhs739, label %land_merge740

land_rhs739:                                      ; preds = %land_merge731
  %ps741 = load i32, ptr %ps, align 4
  %add742 = add i32 %ps741, 3
  %ptr_load743 = load ptr, ptr %line, align 8
  %ptr_gep744 = getelementptr i8, ptr %ptr_load743, i32 %add742
  %idx_load745 = load i8, ptr %ptr_gep744, align 1
  %icmp746 = icmp eq i8 %idx_load745, 101
  br label %land_merge740

land_merge740:                                    ; preds = %land_rhs739, %land_merge731
  %land747 = phi i1 [ false, %land_merge731 ], [ %icmp746, %land_rhs739 ]
  br i1 %land747, label %land_rhs748, label %land_merge749

land_rhs748:                                      ; preds = %land_merge740
  %ps750 = load i32, ptr %ps, align 4
  %add751 = add i32 %ps750, 4
  %ptr_load752 = load ptr, ptr %line, align 8
  %ptr_gep753 = getelementptr i8, ptr %ptr_load752, i32 %add751
  %idx_load754 = load i8, ptr %ptr_gep753, align 1
  %icmp755 = icmp eq i8 %idx_load754, 114
  br label %land_merge749

land_merge749:                                    ; preds = %land_rhs748, %land_merge740
  %land756 = phi i1 [ false, %land_merge740 ], [ %icmp755, %land_rhs748 ]
  br i1 %land756, label %land_rhs757, label %land_merge758

land_rhs757:                                      ; preds = %land_merge749
  %ps759 = load i32, ptr %ps, align 4
  %add760 = add i32 %ps759, 5
  %ptr_load761 = load ptr, ptr %line, align 8
  %ptr_gep762 = getelementptr i8, ptr %ptr_load761, i32 %add760
  %idx_load763 = load i8, ptr %ptr_gep762, align 1
  %icmp764 = icmp eq i8 %idx_load763, 110
  br label %land_merge758

land_merge758:                                    ; preds = %land_rhs757, %land_merge749
  %land765 = phi i1 [ false, %land_merge749 ], [ %icmp764, %land_rhs757 ]
  br i1 %land765, label %if_then766, label %if_merge767

if_then766:                                       ; preds = %land_merge758
  %ps768 = load i32, ptr %ps, align 4
  %add769 = add i32 %ps768, 6
  store i32 %add769, ptr %ps, align 4
  br label %while_cond770

if_merge767:                                      ; preds = %if_merge834, %land_merge758
  %got_std_nm837 = load i8, ptr %got_std_nm, align 1
  %tobool838 = icmp ne i8 %got_std_nm837, 0
  br i1 %tobool838, label %land_rhs839, label %land_merge840

while_cond770:                                    ; preds = %while_body771, %if_then766
  %ps773 = load i32, ptr %ps, align 4
  %line_len774 = load i32, ptr %line_len, align 4
  %icmp775 = icmp slt i32 %ps773, %line_len774
  br i1 %icmp775, label %land_rhs776, label %land_merge777

while_body771:                                    ; preds = %land_merge777
  %ps792 = load i32, ptr %ps, align 4
  %add793 = add i32 %ps792, 1
  store i32 %add793, ptr %ps, align 4
  br label %while_cond770

while_exit772:                                    ; preds = %land_merge777
  %line_len794 = load i32, ptr %line_len, align 4
  %ps795 = load i32, ptr %ps, align 4
  %sub796 = sub i32 %line_len794, %ps795
  %icmp797 = icmp sge i32 %sub796, 4
  br i1 %icmp797, label %land_rhs798, label %land_merge799

land_rhs776:                                      ; preds = %while_cond770
  %ps778 = load i32, ptr %ps, align 4
  %ptr_load779 = load ptr, ptr %line, align 8
  %ptr_gep780 = getelementptr i8, ptr %ptr_load779, i32 %ps778
  %idx_load781 = load i8, ptr %ptr_gep780, align 1
  %icmp782 = icmp eq i8 %idx_load781, 32
  br i1 %icmp782, label %lor_merge784, label %lor_rhs783

land_merge777:                                    ; preds = %lor_merge784, %while_cond770
  %land791 = phi i1 [ false, %while_cond770 ], [ %lor790, %lor_merge784 ]
  br i1 %land791, label %while_body771, label %while_exit772

lor_rhs783:                                       ; preds = %land_rhs776
  %ps785 = load i32, ptr %ps, align 4
  %ptr_load786 = load ptr, ptr %line, align 8
  %ptr_gep787 = getelementptr i8, ptr %ptr_load786, i32 %ps785
  %idx_load788 = load i8, ptr %ptr_gep787, align 1
  %icmp789 = icmp eq i8 %idx_load788, 9
  br label %lor_merge784

lor_merge784:                                     ; preds = %lor_rhs783, %land_rhs776
  %lor790 = phi i1 [ true, %land_rhs776 ], [ %icmp789, %lor_rhs783 ]
  br label %land_merge777

land_rhs798:                                      ; preds = %while_exit772
  %ps800 = load i32, ptr %ps, align 4
  %ptr_load801 = load ptr, ptr %line, align 8
  %ptr_gep802 = getelementptr i8, ptr %ptr_load801, i32 %ps800
  %idx_load803 = load i8, ptr %ptr_gep802, align 1
  %icmp804 = icmp eq i8 %idx_load803, 115
  br label %land_merge799

land_merge799:                                    ; preds = %land_rhs798, %while_exit772
  %land805 = phi i1 [ false, %while_exit772 ], [ %icmp804, %land_rhs798 ]
  br i1 %land805, label %land_rhs806, label %land_merge807

land_rhs806:                                      ; preds = %land_merge799
  %ps808 = load i32, ptr %ps, align 4
  %add809 = add i32 %ps808, 1
  %ptr_load810 = load ptr, ptr %line, align 8
  %ptr_gep811 = getelementptr i8, ptr %ptr_load810, i32 %add809
  %idx_load812 = load i8, ptr %ptr_gep811, align 1
  %icmp813 = icmp eq i8 %idx_load812, 116
  br label %land_merge807

land_merge807:                                    ; preds = %land_rhs806, %land_merge799
  %land814 = phi i1 [ false, %land_merge799 ], [ %icmp813, %land_rhs806 ]
  br i1 %land814, label %land_rhs815, label %land_merge816

land_rhs815:                                      ; preds = %land_merge807
  %ps817 = load i32, ptr %ps, align 4
  %add818 = add i32 %ps817, 2
  %ptr_load819 = load ptr, ptr %line, align 8
  %ptr_gep820 = getelementptr i8, ptr %ptr_load819, i32 %add818
  %idx_load821 = load i8, ptr %ptr_gep820, align 1
  %icmp822 = icmp eq i8 %idx_load821, 100
  br label %land_merge816

land_merge816:                                    ; preds = %land_rhs815, %land_merge807
  %land823 = phi i1 [ false, %land_merge807 ], [ %icmp822, %land_rhs815 ]
  br i1 %land823, label %land_rhs824, label %land_merge825

land_rhs824:                                      ; preds = %land_merge816
  %ps826 = load i32, ptr %ps, align 4
  %add827 = add i32 %ps826, 3
  %ptr_load828 = load ptr, ptr %line, align 8
  %ptr_gep829 = getelementptr i8, ptr %ptr_load828, i32 %add827
  %idx_load830 = load i8, ptr %ptr_gep829, align 1
  %icmp831 = icmp eq i8 %idx_load830, 46
  br label %land_merge825

land_merge825:                                    ; preds = %land_rhs824, %land_merge816
  %land832 = phi i1 [ false, %land_merge816 ], [ %icmp831, %land_rhs824 ]
  br i1 %land832, label %if_then833, label %if_merge834

if_then833:                                       ; preds = %land_merge825
  %ps835 = load i32, ptr %ps, align 4
  %add836 = add i32 %ps835, 4
  store i32 %add836, ptr %std_nm_start, align 4
  store i8 1, ptr %got_std_nm, align 1
  br label %if_merge834

if_merge834:                                      ; preds = %if_then833, %land_merge825
  br label %if_merge767

land_rhs839:                                      ; preds = %if_merge767
  %line_len841 = load i32, ptr %line_len, align 4
  %icmp842 = icmp sgt i32 %line_len841, 0
  br label %land_merge840

land_merge840:                                    ; preds = %land_rhs839, %if_merge767
  %land843 = phi i1 [ false, %if_merge767 ], [ %icmp842, %land_rhs839 ]
  br i1 %land843, label %land_rhs844, label %land_merge845

land_rhs844:                                      ; preds = %land_merge840
  %line_len846 = load i32, ptr %line_len, align 4
  %sub847 = sub i32 %line_len846, 1
  %ptr_load848 = load ptr, ptr %line, align 8
  %ptr_gep849 = getelementptr i8, ptr %ptr_load848, i32 %sub847
  %idx_load850 = load i8, ptr %ptr_gep849, align 1
  %icmp851 = icmp eq i8 %idx_load850, 59
  br label %land_merge845

land_merge845:                                    ; preds = %land_rhs844, %land_merge840
  %land852 = phi i1 [ false, %land_merge840 ], [ %icmp851, %land_rhs844 ]
  br i1 %land852, label %if_then853, label %if_merge854

if_then853:                                       ; preds = %land_merge845
  %name_start = alloca i32, align 4
  %std_nm_start855 = load i32, ptr %std_nm_start, align 4
  store i32 %std_nm_start855, ptr %name_start, align 4
  %name_end = alloca i32, align 4
  %line_len856 = load i32, ptr %line_len, align 4
  %sub857 = sub i32 %line_len856, 1
  store i32 %sub857, ptr %name_end, align 4
  br label %while_cond858

if_merge854:                                      ; preds = %if_merge888, %land_merge845
  %handled_std946 = load i8, ptr %handled_std, align 1
  %tobool947 = icmp ne i8 %handled_std946, 0
  %not948 = xor i1 %tobool947, true
  br i1 %not948, label %if_then949, label %if_merge950

while_cond858:                                    ; preds = %while_body859, %if_then853
  %name_end861 = load i32, ptr %name_end, align 4
  %name_start862 = load i32, ptr %name_start, align 4
  %icmp863 = icmp sgt i32 %name_end861, %name_start862
  br i1 %icmp863, label %land_rhs864, label %land_merge865

while_body859:                                    ; preds = %land_merge865
  %name_end882 = load i32, ptr %name_end, align 4
  %sub883 = sub i32 %name_end882, 1
  store i32 %sub883, ptr %name_end, align 4
  br label %while_cond858

while_exit860:                                    ; preds = %land_merge865
  %name_end884 = load i32, ptr %name_end, align 4
  %name_start885 = load i32, ptr %name_start, align 4
  %icmp886 = icmp sgt i32 %name_end884, %name_start885
  br i1 %icmp886, label %if_then887, label %if_merge888

land_rhs864:                                      ; preds = %while_cond858
  %name_end866 = load i32, ptr %name_end, align 4
  %sub867 = sub i32 %name_end866, 1
  %ptr_load868 = load ptr, ptr %line, align 8
  %ptr_gep869 = getelementptr i8, ptr %ptr_load868, i32 %sub867
  %idx_load870 = load i8, ptr %ptr_gep869, align 1
  %icmp871 = icmp eq i8 %idx_load870, 32
  br i1 %icmp871, label %lor_merge873, label %lor_rhs872

land_merge865:                                    ; preds = %lor_merge873, %while_cond858
  %land881 = phi i1 [ false, %while_cond858 ], [ %lor880, %lor_merge873 ]
  br i1 %land881, label %while_body859, label %while_exit860

lor_rhs872:                                       ; preds = %land_rhs864
  %name_end874 = load i32, ptr %name_end, align 4
  %sub875 = sub i32 %name_end874, 1
  %ptr_load876 = load ptr, ptr %line, align 8
  %ptr_gep877 = getelementptr i8, ptr %ptr_load876, i32 %sub875
  %idx_load878 = load i8, ptr %ptr_gep877, align 1
  %icmp879 = icmp eq i8 %idx_load878, 9
  br label %lor_merge873

lor_merge873:                                     ; preds = %lor_rhs872, %land_rhs864
  %lor880 = phi i1 [ true, %land_rhs864 ], [ %icmp879, %lor_rhs872 ]
  br label %land_merge865

if_then887:                                       ; preds = %while_exit860
  %modname = alloca ptr, align 8
  %line889 = load ptr, ptr %line, align 8
  %name_start890 = load i32, ptr %name_start, align 4
  %ptr_add891 = getelementptr i8, ptr %line889, i32 %name_start890
  %name_end892 = load i32, ptr %name_end, align 4
  %name_start893 = load i32, ptr %name_start, align 4
  %sub894 = sub i32 %name_end892, %name_start893
  %68 = call ptr @preproc__NS_pp_substr_dup(ptr %ptr_add891, i32 %sub894)
  store ptr %68, ptr %modname, align 8
  %di = alloca i32, align 4
  store i32 0, ptr %di, align 4
  br label %while_cond895

if_merge888:                                      ; preds = %if_merge930, %while_exit860
  br label %if_merge854

while_cond895:                                    ; preds = %if_merge909, %if_then887
  %di898 = load i32, ptr %di, align 4
  %ptr_load899 = load ptr, ptr %modname, align 8
  %ptr_gep900 = getelementptr i8, ptr %ptr_load899, i32 %di898
  %idx_load901 = load i8, ptr %ptr_gep900, align 1
  %icmp902 = icmp ne i8 %idx_load901, 0
  br i1 %icmp902, label %while_body896, label %while_exit897

while_body896:                                    ; preds = %while_cond895
  %di903 = load i32, ptr %di, align 4
  %ptr_load904 = load ptr, ptr %modname, align 8
  %ptr_gep905 = getelementptr i8, ptr %ptr_load904, i32 %di903
  %idx_load906 = load i8, ptr %ptr_gep905, align 1
  %icmp907 = icmp eq i8 %idx_load906, 46
  br i1 %icmp907, label %if_then908, label %if_merge909

while_exit897:                                    ; preds = %while_cond895
  %dedup_key = alloca [2048 x i8], align 1
  store [2048 x i8] zeroinitializer, ptr %dedup_key, align 1
  %arr_decay915 = getelementptr [2048 x i8], ptr %dedup_key, i64 0, i64 0
  %modname916 = load ptr, ptr %modname, align 8
  %anon_s917 = alloca %__anon1_P, align 8
  %anon_f918 = getelementptr inbounds nuw %__anon1_P, ptr %anon_s917, i32 0, i32 0
  store ptr %modname916, ptr %anon_f918, align 8
  %anon_load919 = load %__anon1_P, ptr %anon_s917, align 8
  %69 = call i32 @afmt__at_args_S__anon1_P(ptr %arr_decay915, i64 2048, ptr @str.34, %__anon1_P %anon_load919)
  %included920 = load ptr, ptr %included, align 8
  %icmp921 = icmp eq ptr %included920, null
  br i1 %icmp921, label %lor_merge923, label %lor_rhs922

if_then908:                                       ; preds = %while_body896
  %di910 = load i32, ptr %di, align 4
  %ptr_load911 = load ptr, ptr %modname, align 8
  %ptr_gep912 = getelementptr i8, ptr %ptr_load911, i32 %di910
  store i8 47, ptr %ptr_gep912, align 1
  br label %if_merge909

if_merge909:                                      ; preds = %if_then908, %while_body896
  %di913 = load i32, ptr %di, align 4
  %add914 = add i32 %di913, 1
  store i32 %add914, ptr %di, align 4
  br label %while_cond895

lor_rhs922:                                       ; preds = %while_exit897
  %included924 = load ptr, ptr %included, align 8
  %arr_decay925 = getelementptr [2048 x i8], ptr %dedup_key, i64 0, i64 0
  %70 = call i8 @preproc__NS_pp_defined(ptr %included924, ptr %arr_decay925)
  %tobool926 = icmp ne i8 %70, 0
  %not927 = xor i1 %tobool926, true
  br label %lor_merge923

lor_merge923:                                     ; preds = %lor_rhs922, %while_exit897
  %lor928 = phi i1 [ true, %while_exit897 ], [ %not927, %lor_rhs922 ]
  br i1 %lor928, label %if_then929, label %if_merge930

if_then929:                                       ; preds = %lor_merge923
  %included931 = load ptr, ptr %included, align 8
  %icmp932 = icmp ne ptr %included931, null
  br i1 %icmp932, label %if_then933, label %if_merge934

if_merge930:                                      ; preds = %if_merge934, %lor_merge923
  %modname945 = load ptr, ptr %modname, align 8
  call void @arc_free.3(ptr %modname945)
  store i8 1, ptr %handled_std, align 1
  br label %if_merge888

if_then933:                                       ; preds = %if_then929
  %included935 = load ptr, ptr %included, align 8
  %arr_decay936 = getelementptr [2048 x i8], ptr %dedup_key, i64 0, i64 0
  %arr_decay937 = getelementptr [2048 x i8], ptr %dedup_key, i64 0, i64 0
  %71 = call i64 @arc_strlen(ptr %arr_decay937)
  %trunc938 = trunc i64 %71 to i32
  %72 = call ptr @preproc__NS_pp_substr_dup(ptr %arr_decay936, i32 %trunc938)
  call void @preproc__NS_pp_set(ptr %included935, ptr %72, ptr @str.35)
  br label %if_merge934

if_merge934:                                      ; preds = %if_then933, %if_then929
  %import_line = alloca [2048 x i8], align 1
  store [2048 x i8] zeroinitializer, ptr %import_line, align 1
  %arr_decay939 = getelementptr [2048 x i8], ptr %import_line, i64 0, i64 0
  %modname940 = load ptr, ptr %modname, align 8
  %anon_s941 = alloca %__anon1_P, align 8
  %anon_f942 = getelementptr inbounds nuw %__anon1_P, ptr %anon_s941, i32 0, i32 0
  store ptr %modname940, ptr %anon_f942, align 8
  %anon_load943 = load %__anon1_P, ptr %anon_s941, align 8
  %73 = call i32 @afmt__at_args_S__anon1_P(ptr %arr_decay939, i64 2048, ptr @str.36, %__anon1_P %anon_load943)
  %arr_decay944 = getelementptr [2048 x i8], ptr %import_line, i64 0, i64 0
  call void @preproc__NS_strbuf_append_cstr(ptr %out, ptr %arr_decay944)
  br label %if_merge930

if_then949:                                       ; preds = %if_merge854
  %ac_nm_start = alloca i32, align 4
  store i32 0, ptr %ac_nm_start, align 4
  %got_ac = alloca i8, align 1
  store i8 0, ptr %got_ac, align 1
  %pa = alloca i32, align 4
  %ind951 = load i32, ptr %ind, align 4
  store i32 %ind951, ptr %pa, align 4
  %line_len952 = load i32, ptr %line_len, align 4
  %pa953 = load i32, ptr %pa, align 4
  %sub954 = sub i32 %line_len952, %pa953
  %icmp955 = icmp sge i32 %sub954, 6
  br i1 %icmp955, label %land_rhs956, label %land_merge957

if_merge950:                                      ; preds = %if_merge1115, %if_merge854
  %handled_std1217 = load i8, ptr %handled_std, align 1
  %tobool1218 = icmp ne i8 %handled_std1217, 0
  %not1219 = xor i1 %tobool1218, true
  br i1 %not1219, label %if_then1220, label %if_merge1221

land_rhs956:                                      ; preds = %if_then949
  %pa958 = load i32, ptr %pa, align 4
  %ptr_load959 = load ptr, ptr %line, align 8
  %ptr_gep960 = getelementptr i8, ptr %ptr_load959, i32 %pa958
  %idx_load961 = load i8, ptr %ptr_gep960, align 1
  %icmp962 = icmp eq i8 %idx_load961, 101
  br label %land_merge957

land_merge957:                                    ; preds = %land_rhs956, %if_then949
  %land963 = phi i1 [ false, %if_then949 ], [ %icmp962, %land_rhs956 ]
  br i1 %land963, label %land_rhs964, label %land_merge965

land_rhs964:                                      ; preds = %land_merge957
  %pa966 = load i32, ptr %pa, align 4
  %add967 = add i32 %pa966, 1
  %ptr_load968 = load ptr, ptr %line, align 8
  %ptr_gep969 = getelementptr i8, ptr %ptr_load968, i32 %add967
  %idx_load970 = load i8, ptr %ptr_gep969, align 1
  %icmp971 = icmp eq i8 %idx_load970, 120
  br label %land_merge965

land_merge965:                                    ; preds = %land_rhs964, %land_merge957
  %land972 = phi i1 [ false, %land_merge957 ], [ %icmp971, %land_rhs964 ]
  br i1 %land972, label %land_rhs973, label %land_merge974

land_rhs973:                                      ; preds = %land_merge965
  %pa975 = load i32, ptr %pa, align 4
  %add976 = add i32 %pa975, 2
  %ptr_load977 = load ptr, ptr %line, align 8
  %ptr_gep978 = getelementptr i8, ptr %ptr_load977, i32 %add976
  %idx_load979 = load i8, ptr %ptr_gep978, align 1
  %icmp980 = icmp eq i8 %idx_load979, 116
  br label %land_merge974

land_merge974:                                    ; preds = %land_rhs973, %land_merge965
  %land981 = phi i1 [ false, %land_merge965 ], [ %icmp980, %land_rhs973 ]
  br i1 %land981, label %land_rhs982, label %land_merge983

land_rhs982:                                      ; preds = %land_merge974
  %pa984 = load i32, ptr %pa, align 4
  %add985 = add i32 %pa984, 3
  %ptr_load986 = load ptr, ptr %line, align 8
  %ptr_gep987 = getelementptr i8, ptr %ptr_load986, i32 %add985
  %idx_load988 = load i8, ptr %ptr_gep987, align 1
  %icmp989 = icmp eq i8 %idx_load988, 101
  br label %land_merge983

land_merge983:                                    ; preds = %land_rhs982, %land_merge974
  %land990 = phi i1 [ false, %land_merge974 ], [ %icmp989, %land_rhs982 ]
  br i1 %land990, label %land_rhs991, label %land_merge992

land_rhs991:                                      ; preds = %land_merge983
  %pa993 = load i32, ptr %pa, align 4
  %add994 = add i32 %pa993, 4
  %ptr_load995 = load ptr, ptr %line, align 8
  %ptr_gep996 = getelementptr i8, ptr %ptr_load995, i32 %add994
  %idx_load997 = load i8, ptr %ptr_gep996, align 1
  %icmp998 = icmp eq i8 %idx_load997, 114
  br label %land_merge992

land_merge992:                                    ; preds = %land_rhs991, %land_merge983
  %land999 = phi i1 [ false, %land_merge983 ], [ %icmp998, %land_rhs991 ]
  br i1 %land999, label %land_rhs1000, label %land_merge1001

land_rhs1000:                                     ; preds = %land_merge992
  %pa1002 = load i32, ptr %pa, align 4
  %add1003 = add i32 %pa1002, 5
  %ptr_load1004 = load ptr, ptr %line, align 8
  %ptr_gep1005 = getelementptr i8, ptr %ptr_load1004, i32 %add1003
  %idx_load1006 = load i8, ptr %ptr_gep1005, align 1
  %icmp1007 = icmp eq i8 %idx_load1006, 110
  br label %land_merge1001

land_merge1001:                                   ; preds = %land_rhs1000, %land_merge992
  %land1008 = phi i1 [ false, %land_merge992 ], [ %icmp1007, %land_rhs1000 ]
  br i1 %land1008, label %if_then1009, label %if_merge1010

if_then1009:                                      ; preds = %land_merge1001
  %pa1011 = load i32, ptr %pa, align 4
  %add1012 = add i32 %pa1011, 6
  store i32 %add1012, ptr %pa, align 4
  br label %while_cond1013

if_merge1010:                                     ; preds = %if_merge1095, %land_merge1001
  %got_ac1098 = load i8, ptr %got_ac, align 1
  %tobool1099 = icmp ne i8 %got_ac1098, 0
  br i1 %tobool1099, label %land_rhs1100, label %land_merge1101

while_cond1013:                                   ; preds = %while_body1014, %if_then1009
  %pa1016 = load i32, ptr %pa, align 4
  %line_len1017 = load i32, ptr %line_len, align 4
  %icmp1018 = icmp slt i32 %pa1016, %line_len1017
  br i1 %icmp1018, label %land_rhs1019, label %land_merge1020

while_body1014:                                   ; preds = %land_merge1020
  %pa1035 = load i32, ptr %pa, align 4
  %add1036 = add i32 %pa1035, 1
  store i32 %add1036, ptr %pa, align 4
  br label %while_cond1013

while_exit1015:                                   ; preds = %land_merge1020
  %line_len1037 = load i32, ptr %line_len, align 4
  %pa1038 = load i32, ptr %pa, align 4
  %sub1039 = sub i32 %line_len1037, %pa1038
  %icmp1040 = icmp sge i32 %sub1039, 6
  br i1 %icmp1040, label %land_rhs1041, label %land_merge1042

land_rhs1019:                                     ; preds = %while_cond1013
  %pa1021 = load i32, ptr %pa, align 4
  %ptr_load1022 = load ptr, ptr %line, align 8
  %ptr_gep1023 = getelementptr i8, ptr %ptr_load1022, i32 %pa1021
  %idx_load1024 = load i8, ptr %ptr_gep1023, align 1
  %icmp1025 = icmp eq i8 %idx_load1024, 32
  br i1 %icmp1025, label %lor_merge1027, label %lor_rhs1026

land_merge1020:                                   ; preds = %lor_merge1027, %while_cond1013
  %land1034 = phi i1 [ false, %while_cond1013 ], [ %lor1033, %lor_merge1027 ]
  br i1 %land1034, label %while_body1014, label %while_exit1015

lor_rhs1026:                                      ; preds = %land_rhs1019
  %pa1028 = load i32, ptr %pa, align 4
  %ptr_load1029 = load ptr, ptr %line, align 8
  %ptr_gep1030 = getelementptr i8, ptr %ptr_load1029, i32 %pa1028
  %idx_load1031 = load i8, ptr %ptr_gep1030, align 1
  %icmp1032 = icmp eq i8 %idx_load1031, 9
  br label %lor_merge1027

lor_merge1027:                                    ; preds = %lor_rhs1026, %land_rhs1019
  %lor1033 = phi i1 [ true, %land_rhs1019 ], [ %icmp1032, %lor_rhs1026 ]
  br label %land_merge1020

land_rhs1041:                                     ; preds = %while_exit1015
  %pa1043 = load i32, ptr %pa, align 4
  %ptr_load1044 = load ptr, ptr %line, align 8
  %ptr_gep1045 = getelementptr i8, ptr %ptr_load1044, i32 %pa1043
  %idx_load1046 = load i8, ptr %ptr_gep1045, align 1
  %icmp1047 = icmp eq i8 %idx_load1046, 97
  br label %land_merge1042

land_merge1042:                                   ; preds = %land_rhs1041, %while_exit1015
  %land1048 = phi i1 [ false, %while_exit1015 ], [ %icmp1047, %land_rhs1041 ]
  br i1 %land1048, label %land_rhs1049, label %land_merge1050

land_rhs1049:                                     ; preds = %land_merge1042
  %pa1051 = load i32, ptr %pa, align 4
  %add1052 = add i32 %pa1051, 1
  %ptr_load1053 = load ptr, ptr %line, align 8
  %ptr_gep1054 = getelementptr i8, ptr %ptr_load1053, i32 %add1052
  %idx_load1055 = load i8, ptr %ptr_gep1054, align 1
  %icmp1056 = icmp eq i8 %idx_load1055, 99
  br label %land_merge1050

land_merge1050:                                   ; preds = %land_rhs1049, %land_merge1042
  %land1057 = phi i1 [ false, %land_merge1042 ], [ %icmp1056, %land_rhs1049 ]
  br i1 %land1057, label %land_rhs1058, label %land_merge1059

land_rhs1058:                                     ; preds = %land_merge1050
  %pa1060 = load i32, ptr %pa, align 4
  %add1061 = add i32 %pa1060, 2
  %ptr_load1062 = load ptr, ptr %line, align 8
  %ptr_gep1063 = getelementptr i8, ptr %ptr_load1062, i32 %add1061
  %idx_load1064 = load i8, ptr %ptr_gep1063, align 1
  %icmp1065 = icmp eq i8 %idx_load1064, 105
  br label %land_merge1059

land_merge1059:                                   ; preds = %land_rhs1058, %land_merge1050
  %land1066 = phi i1 [ false, %land_merge1050 ], [ %icmp1065, %land_rhs1058 ]
  br i1 %land1066, label %land_rhs1067, label %land_merge1068

land_rhs1067:                                     ; preds = %land_merge1059
  %pa1069 = load i32, ptr %pa, align 4
  %add1070 = add i32 %pa1069, 3
  %ptr_load1071 = load ptr, ptr %line, align 8
  %ptr_gep1072 = getelementptr i8, ptr %ptr_load1071, i32 %add1070
  %idx_load1073 = load i8, ptr %ptr_gep1072, align 1
  %icmp1074 = icmp eq i8 %idx_load1073, 115
  br label %land_merge1068

land_merge1068:                                   ; preds = %land_rhs1067, %land_merge1059
  %land1075 = phi i1 [ false, %land_merge1059 ], [ %icmp1074, %land_rhs1067 ]
  br i1 %land1075, label %land_rhs1076, label %land_merge1077

land_rhs1076:                                     ; preds = %land_merge1068
  %pa1078 = load i32, ptr %pa, align 4
  %add1079 = add i32 %pa1078, 4
  %ptr_load1080 = load ptr, ptr %line, align 8
  %ptr_gep1081 = getelementptr i8, ptr %ptr_load1080, i32 %add1079
  %idx_load1082 = load i8, ptr %ptr_gep1081, align 1
  %icmp1083 = icmp eq i8 %idx_load1082, 111
  br label %land_merge1077

land_merge1077:                                   ; preds = %land_rhs1076, %land_merge1068
  %land1084 = phi i1 [ false, %land_merge1068 ], [ %icmp1083, %land_rhs1076 ]
  br i1 %land1084, label %land_rhs1085, label %land_merge1086

land_rhs1085:                                     ; preds = %land_merge1077
  %pa1087 = load i32, ptr %pa, align 4
  %add1088 = add i32 %pa1087, 5
  %ptr_load1089 = load ptr, ptr %line, align 8
  %ptr_gep1090 = getelementptr i8, ptr %ptr_load1089, i32 %add1088
  %idx_load1091 = load i8, ptr %ptr_gep1090, align 1
  %icmp1092 = icmp eq i8 %idx_load1091, 46
  br label %land_merge1086

land_merge1086:                                   ; preds = %land_rhs1085, %land_merge1077
  %land1093 = phi i1 [ false, %land_merge1077 ], [ %icmp1092, %land_rhs1085 ]
  br i1 %land1093, label %if_then1094, label %if_merge1095

if_then1094:                                      ; preds = %land_merge1086
  %pa1096 = load i32, ptr %pa, align 4
  %add1097 = add i32 %pa1096, 6
  store i32 %add1097, ptr %ac_nm_start, align 4
  store i8 1, ptr %got_ac, align 1
  br label %if_merge1095

if_merge1095:                                     ; preds = %if_then1094, %land_merge1086
  br label %if_merge1010

land_rhs1100:                                     ; preds = %if_merge1010
  %line_len1102 = load i32, ptr %line_len, align 4
  %icmp1103 = icmp sgt i32 %line_len1102, 0
  br label %land_merge1101

land_merge1101:                                   ; preds = %land_rhs1100, %if_merge1010
  %land1104 = phi i1 [ false, %if_merge1010 ], [ %icmp1103, %land_rhs1100 ]
  br i1 %land1104, label %land_rhs1105, label %land_merge1106

land_rhs1105:                                     ; preds = %land_merge1101
  %line_len1107 = load i32, ptr %line_len, align 4
  %sub1108 = sub i32 %line_len1107, 1
  %ptr_load1109 = load ptr, ptr %line, align 8
  %ptr_gep1110 = getelementptr i8, ptr %ptr_load1109, i32 %sub1108
  %idx_load1111 = load i8, ptr %ptr_gep1110, align 1
  %icmp1112 = icmp eq i8 %idx_load1111, 59
  br label %land_merge1106

land_merge1106:                                   ; preds = %land_rhs1105, %land_merge1101
  %land1113 = phi i1 [ false, %land_merge1101 ], [ %icmp1112, %land_rhs1105 ]
  br i1 %land1113, label %if_then1114, label %if_merge1115

if_then1114:                                      ; preds = %land_merge1106
  %ac_name_start = alloca i32, align 4
  %ac_nm_start1116 = load i32, ptr %ac_nm_start, align 4
  store i32 %ac_nm_start1116, ptr %ac_name_start, align 4
  %ac_name_end = alloca i32, align 4
  %line_len1117 = load i32, ptr %line_len, align 4
  %sub1118 = sub i32 %line_len1117, 1
  store i32 %sub1118, ptr %ac_name_end, align 4
  br label %while_cond1119

if_merge1115:                                     ; preds = %if_merge1149, %land_merge1106
  br label %if_merge950

while_cond1119:                                   ; preds = %while_body1120, %if_then1114
  %ac_name_end1122 = load i32, ptr %ac_name_end, align 4
  %ac_name_start1123 = load i32, ptr %ac_name_start, align 4
  %icmp1124 = icmp sgt i32 %ac_name_end1122, %ac_name_start1123
  br i1 %icmp1124, label %land_rhs1125, label %land_merge1126

while_body1120:                                   ; preds = %land_merge1126
  %ac_name_end1143 = load i32, ptr %ac_name_end, align 4
  %sub1144 = sub i32 %ac_name_end1143, 1
  store i32 %sub1144, ptr %ac_name_end, align 4
  br label %while_cond1119

while_exit1121:                                   ; preds = %land_merge1126
  %ac_name_end1145 = load i32, ptr %ac_name_end, align 4
  %ac_name_start1146 = load i32, ptr %ac_name_start, align 4
  %icmp1147 = icmp sgt i32 %ac_name_end1145, %ac_name_start1146
  br i1 %icmp1147, label %if_then1148, label %if_merge1149

land_rhs1125:                                     ; preds = %while_cond1119
  %ac_name_end1127 = load i32, ptr %ac_name_end, align 4
  %sub1128 = sub i32 %ac_name_end1127, 1
  %ptr_load1129 = load ptr, ptr %line, align 8
  %ptr_gep1130 = getelementptr i8, ptr %ptr_load1129, i32 %sub1128
  %idx_load1131 = load i8, ptr %ptr_gep1130, align 1
  %icmp1132 = icmp eq i8 %idx_load1131, 32
  br i1 %icmp1132, label %lor_merge1134, label %lor_rhs1133

land_merge1126:                                   ; preds = %lor_merge1134, %while_cond1119
  %land1142 = phi i1 [ false, %while_cond1119 ], [ %lor1141, %lor_merge1134 ]
  br i1 %land1142, label %while_body1120, label %while_exit1121

lor_rhs1133:                                      ; preds = %land_rhs1125
  %ac_name_end1135 = load i32, ptr %ac_name_end, align 4
  %sub1136 = sub i32 %ac_name_end1135, 1
  %ptr_load1137 = load ptr, ptr %line, align 8
  %ptr_gep1138 = getelementptr i8, ptr %ptr_load1137, i32 %sub1136
  %idx_load1139 = load i8, ptr %ptr_gep1138, align 1
  %icmp1140 = icmp eq i8 %idx_load1139, 9
  br label %lor_merge1134

lor_merge1134:                                    ; preds = %lor_rhs1133, %land_rhs1125
  %lor1141 = phi i1 [ true, %land_rhs1125 ], [ %icmp1140, %lor_rhs1133 ]
  br label %land_merge1126

if_then1148:                                      ; preds = %while_exit1121
  %pkgname = alloca ptr, align 8
  %line1150 = load ptr, ptr %line, align 8
  %ac_name_start1151 = load i32, ptr %ac_name_start, align 4
  %ptr_add1152 = getelementptr i8, ptr %line1150, i32 %ac_name_start1151
  %ac_name_end1153 = load i32, ptr %ac_name_end, align 4
  %ac_name_start1154 = load i32, ptr %ac_name_start, align 4
  %sub1155 = sub i32 %ac_name_end1153, %ac_name_start1154
  %74 = call ptr @preproc__NS_pp_substr_dup(ptr %ptr_add1152, i32 %sub1155)
  store ptr %74, ptr %pkgname, align 8
  %dedup_key2 = alloca [512 x i8], align 1
  store [512 x i8] zeroinitializer, ptr %dedup_key2, align 1
  %arr_decay1156 = getelementptr [512 x i8], ptr %dedup_key2, i64 0, i64 0
  %pkgname1157 = load ptr, ptr %pkgname, align 8
  %anon_s1158 = alloca %__anon1_P, align 8
  %anon_f1159 = getelementptr inbounds nuw %__anon1_P, ptr %anon_s1158, i32 0, i32 0
  store ptr %pkgname1157, ptr %anon_f1159, align 8
  %anon_load1160 = load %__anon1_P, ptr %anon_s1158, align 8
  %75 = call i32 @afmt__at_args_S__anon1_P(ptr %arr_decay1156, i64 512, ptr @str.37, %__anon1_P %anon_load1160)
  %included1161 = load ptr, ptr %included, align 8
  %icmp1162 = icmp eq ptr %included1161, null
  br i1 %icmp1162, label %lor_merge1164, label %lor_rhs1163

if_merge1149:                                     ; preds = %if_merge1171, %while_exit1121
  br label %if_merge1115

lor_rhs1163:                                      ; preds = %if_then1148
  %included1165 = load ptr, ptr %included, align 8
  %arr_decay1166 = getelementptr [512 x i8], ptr %dedup_key2, i64 0, i64 0
  %76 = call i8 @preproc__NS_pp_defined(ptr %included1165, ptr %arr_decay1166)
  %tobool1167 = icmp ne i8 %76, 0
  %not1168 = xor i1 %tobool1167, true
  br label %lor_merge1164

lor_merge1164:                                    ; preds = %lor_rhs1163, %if_then1148
  %lor1169 = phi i1 [ true, %if_then1148 ], [ %not1168, %lor_rhs1163 ]
  br i1 %lor1169, label %if_then1170, label %if_merge1171

if_then1170:                                      ; preds = %lor_merge1164
  %included1172 = load ptr, ptr %included, align 8
  %icmp1173 = icmp ne ptr %included1172, null
  br i1 %icmp1173, label %if_then1174, label %if_merge1175

if_merge1171:                                     ; preds = %if_merge1190, %lor_merge1164
  %pkgname1216 = load ptr, ptr %pkgname, align 8
  call void @arc_free.3(ptr %pkgname1216)
  store i8 1, ptr %handled_std, align 1
  br label %if_merge1149

if_then1174:                                      ; preds = %if_then1170
  %included1176 = load ptr, ptr %included, align 8
  %arr_decay1177 = getelementptr [512 x i8], ptr %dedup_key2, i64 0, i64 0
  %arr_decay1178 = getelementptr [512 x i8], ptr %dedup_key2, i64 0, i64 0
  %77 = call i64 @arc_strlen(ptr %arr_decay1178)
  %trunc1179 = trunc i64 %77 to i32
  %78 = call ptr @preproc__NS_pp_substr_dup(ptr %arr_decay1177, i32 %trunc1179)
  call void @preproc__NS_pp_set(ptr %included1176, ptr %78, ptr @str.38)
  br label %if_merge1175

if_merge1175:                                     ; preds = %if_then1174, %if_then1170
  %arc_subpath = alloca [512 x i8], align 1
  store [512 x i8] zeroinitializer, ptr %arc_subpath, align 1
  %arr_decay1180 = getelementptr [512 x i8], ptr %arc_subpath, i64 0, i64 0
  %pkgname1181 = load ptr, ptr %pkgname, align 8
  %pkgname1182 = load ptr, ptr %pkgname, align 8
  %anon_s1183 = alloca %__anon2_P_P, align 8
  %anon_f1184 = getelementptr inbounds nuw %__anon2_P_P, ptr %anon_s1183, i32 0, i32 0
  store ptr %pkgname1181, ptr %anon_f1184, align 8
  %anon_f1185 = getelementptr inbounds nuw %__anon2_P_P, ptr %anon_s1183, i32 0, i32 1
  store ptr %pkgname1182, ptr %anon_f1185, align 8
  %anon_load1186 = load %__anon2_P_P, ptr %anon_s1183, align 8
  %79 = call i32 @afmt__at_args_S__anon2_P_P(ptr %arr_decay1180, i64 512, ptr @str.39, %__anon2_P_P %anon_load1186)
  %base_dir1187 = load ptr, ptr %base_dir, align 8
  %icmp1188 = icmp ne ptr %base_dir1187, null
  br i1 %icmp1188, label %if_then1189, label %if_merge1190

if_then1189:                                      ; preds = %if_merge1175
  %fpath2 = alloca [2048 x i8], align 1
  store [2048 x i8] zeroinitializer, ptr %fpath2, align 1
  %arr_decay1191 = getelementptr [2048 x i8], ptr %fpath2, i64 0, i64 0
  %base_dir1192 = load ptr, ptr %base_dir, align 8
  %arr_decay1193 = getelementptr [512 x i8], ptr %arc_subpath, i64 0, i64 0
  %anon_s1194 = alloca %__anon2_P_P, align 8
  %anon_f1195 = getelementptr inbounds nuw %__anon2_P_P, ptr %anon_s1194, i32 0, i32 0
  store ptr %base_dir1192, ptr %anon_f1195, align 8
  %anon_f1196 = getelementptr inbounds nuw %__anon2_P_P, ptr %anon_s1194, i32 0, i32 1
  store ptr %arr_decay1193, ptr %anon_f1196, align 8
  %anon_load1197 = load %__anon2_P_P, ptr %anon_s1194, align 8
  %80 = call i32 @afmt__at_args_S__anon2_P_P(ptr %arr_decay1191, i64 2048, ptr @str.40, %__anon2_P_P %anon_load1197)
  %probe = alloca ptr, align 8
  %arr_decay1198 = getelementptr [2048 x i8], ptr %fpath2, i64 0, i64 0
  %81 = call ptr @preproc__NS_pp_read_file(ptr %arr_decay1198)
  store ptr %81, ptr %probe, align 8
  %probe1199 = load ptr, ptr %probe, align 8
  %icmp1200 = icmp eq ptr %probe1199, null
  br i1 %icmp1200, label %if_then1201, label %if_else1202

if_merge1190:                                     ; preds = %if_merge1203, %if_merge1175
  %import_line2 = alloca [2048 x i8], align 1
  store [2048 x i8] zeroinitializer, ptr %import_line2, align 1
  %arr_decay1210 = getelementptr [2048 x i8], ptr %import_line2, i64 0, i64 0
  %arr_decay1211 = getelementptr [512 x i8], ptr %arc_subpath, i64 0, i64 0
  %anon_s1212 = alloca %__anon1_P, align 8
  %anon_f1213 = getelementptr inbounds nuw %__anon1_P, ptr %anon_s1212, i32 0, i32 0
  store ptr %arr_decay1211, ptr %anon_f1213, align 8
  %anon_load1214 = load %__anon1_P, ptr %anon_s1212, align 8
  %82 = call i32 @afmt__at_args_S__anon1_P(ptr %arr_decay1210, i64 2048, ptr @str.42, %__anon1_P %anon_load1214)
  %arr_decay1215 = getelementptr [2048 x i8], ptr %import_line2, i64 0, i64 0
  call void @preproc__NS_strbuf_append_cstr(ptr %out, ptr %arr_decay1215)
  br label %if_merge1171

if_then1201:                                      ; preds = %if_then1189
  %arr_decay1204 = getelementptr [512 x i8], ptr %arc_subpath, i64 0, i64 0
  %pkgname1205 = load ptr, ptr %pkgname, align 8
  %anon_s1206 = alloca %__anon1_P, align 8
  %anon_f1207 = getelementptr inbounds nuw %__anon1_P, ptr %anon_s1206, i32 0, i32 0
  store ptr %pkgname1205, ptr %anon_f1207, align 8
  %anon_load1208 = load %__anon1_P, ptr %anon_s1206, align 8
  %83 = call i32 @afmt__at_args_S__anon1_P(ptr %arr_decay1204, i64 512, ptr @str.41, %__anon1_P %anon_load1208)
  br label %if_merge1203

if_else1202:                                      ; preds = %if_then1189
  %probe1209 = load ptr, ptr %probe, align 8
  call void @arc_free.3(ptr %probe1209)
  br label %if_merge1203

if_merge1203:                                     ; preds = %if_else1202, %if_then1201
  br label %if_merge1190

if_then1220:                                      ; preds = %if_merge950
  %macros1222 = load ptr, ptr %macros, align 8
  %funcs1223 = load ptr, ptr %funcs, align 8
  %line1224 = load ptr, ptr %line, align 8
  %line_len1225 = load i32, ptr %line_len, align 4
  call void @preproc__NS_pp_apply(ptr %macros1222, ptr %funcs1223, ptr %line1224, i32 %line_len1225, ptr %out)
  br label %if_merge1221

if_merge1221:                                     ; preds = %if_then1220, %if_merge950
  br label %if_merge707
}

define internal i8 @preproc__NS_pp_triple_has(ptr %0, ptr %1) {
entry:
  %triple = alloca ptr, align 8
  store ptr %0, ptr %triple, align 8
  %needle = alloca ptr, align 8
  store ptr %1, ptr %needle, align 8
  %triple1 = load ptr, ptr %triple, align 8
  %icmp = icmp eq ptr %triple1, null
  br i1 %icmp, label %lor_merge, label %lor_rhs

lor_rhs:                                          ; preds = %entry
  %needle2 = load ptr, ptr %needle, align 8
  %icmp3 = icmp eq ptr %needle2, null
  br label %lor_merge

lor_merge:                                        ; preds = %lor_rhs, %entry
  %lor = phi i1 [ true, %entry ], [ %icmp3, %lor_rhs ]
  br i1 %lor, label %if_then, label %if_merge

if_then:                                          ; preds = %lor_merge
  ret i8 0

if_merge:                                         ; preds = %lor_merge
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  br label %while_cond

while_cond:                                       ; preds = %if_merge65, %if_merge
  %i4 = load i32, ptr %i, align 4
  %ptr_load = load ptr, ptr %triple, align 8
  %ptr_gep = getelementptr i8, ptr %ptr_load, i32 %i4
  %idx_load = load i8, ptr %ptr_gep, align 1
  %icmp5 = icmp ne i8 %idx_load, 0
  br i1 %icmp5, label %while_body, label %while_exit

while_body:                                       ; preds = %while_cond
  %j = alloca i32, align 4
  store i32 0, ptr %j, align 4
  br label %while_cond6

while_exit:                                       ; preds = %while_cond
  ret i8 0

while_cond6:                                      ; preds = %if_merge56, %while_body
  %j9 = load i32, ptr %j, align 4
  %ptr_load10 = load ptr, ptr %needle, align 8
  %ptr_gep11 = getelementptr i8, ptr %ptr_load10, i32 %j9
  %idx_load12 = load i8, ptr %ptr_gep11, align 1
  %icmp13 = icmp ne i8 %idx_load12, 0
  br i1 %icmp13, label %land_rhs, label %land_merge

while_body7:                                      ; preds = %land_merge
  %a = alloca i8, align 1
  %i20 = load i32, ptr %i, align 4
  %j21 = load i32, ptr %j, align 4
  %add22 = add i32 %i20, %j21
  %ptr_load23 = load ptr, ptr %triple, align 8
  %ptr_gep24 = getelementptr i8, ptr %ptr_load23, i32 %add22
  %idx_load25 = load i8, ptr %ptr_gep24, align 1
  store i8 %idx_load25, ptr %a, align 1
  %b = alloca i8, align 1
  %j26 = load i32, ptr %j, align 4
  %ptr_load27 = load ptr, ptr %needle, align 8
  %ptr_gep28 = getelementptr i8, ptr %ptr_load27, i32 %j26
  %idx_load29 = load i8, ptr %ptr_gep28, align 1
  store i8 %idx_load29, ptr %b, align 1
  %a30 = load i8, ptr %a, align 1
  %icmp31 = icmp sge i8 %a30, 65
  br i1 %icmp31, label %land_rhs32, label %land_merge33

while_exit8:                                      ; preds = %if_then55, %land_merge
  %j59 = load i32, ptr %j, align 4
  %ptr_load60 = load ptr, ptr %needle, align 8
  %ptr_gep61 = getelementptr i8, ptr %ptr_load60, i32 %j59
  %idx_load62 = load i8, ptr %ptr_gep61, align 1
  %icmp63 = icmp eq i8 %idx_load62, 0
  br i1 %icmp63, label %if_then64, label %if_merge65

land_rhs:                                         ; preds = %while_cond6
  %i14 = load i32, ptr %i, align 4
  %j15 = load i32, ptr %j, align 4
  %add = add i32 %i14, %j15
  %ptr_load16 = load ptr, ptr %triple, align 8
  %ptr_gep17 = getelementptr i8, ptr %ptr_load16, i32 %add
  %idx_load18 = load i8, ptr %ptr_gep17, align 1
  %icmp19 = icmp ne i8 %idx_load18, 0
  br label %land_merge

land_merge:                                       ; preds = %land_rhs, %while_cond6
  %land = phi i1 [ false, %while_cond6 ], [ %icmp19, %land_rhs ]
  br i1 %land, label %while_body7, label %while_exit8

land_rhs32:                                       ; preds = %while_body7
  %a34 = load i8, ptr %a, align 1
  %icmp35 = icmp sle i8 %a34, 90
  br label %land_merge33

land_merge33:                                     ; preds = %land_rhs32, %while_body7
  %land36 = phi i1 [ false, %while_body7 ], [ %icmp35, %land_rhs32 ]
  br i1 %land36, label %if_then37, label %if_merge38

if_then37:                                        ; preds = %land_merge33
  %a39 = load i8, ptr %a, align 1
  %add40 = add i8 %a39, 32
  store i8 %add40, ptr %a, align 1
  br label %if_merge38

if_merge38:                                       ; preds = %if_then37, %land_merge33
  %b41 = load i8, ptr %b, align 1
  %icmp42 = icmp sge i8 %b41, 65
  br i1 %icmp42, label %land_rhs43, label %land_merge44

land_rhs43:                                       ; preds = %if_merge38
  %b45 = load i8, ptr %b, align 1
  %icmp46 = icmp sle i8 %b45, 90
  br label %land_merge44

land_merge44:                                     ; preds = %land_rhs43, %if_merge38
  %land47 = phi i1 [ false, %if_merge38 ], [ %icmp46, %land_rhs43 ]
  br i1 %land47, label %if_then48, label %if_merge49

if_then48:                                        ; preds = %land_merge44
  %b50 = load i8, ptr %b, align 1
  %add51 = add i8 %b50, 32
  store i8 %add51, ptr %b, align 1
  br label %if_merge49

if_merge49:                                       ; preds = %if_then48, %land_merge44
  %a52 = load i8, ptr %a, align 1
  %b53 = load i8, ptr %b, align 1
  %icmp54 = icmp ne i8 %a52, %b53
  br i1 %icmp54, label %if_then55, label %if_merge56

if_then55:                                        ; preds = %if_merge49
  br label %while_exit8

if_merge56:                                       ; preds = %if_merge49
  %j57 = load i32, ptr %j, align 4
  %add58 = add i32 %j57, 1
  store i32 %add58, ptr %j, align 4
  br label %while_cond6

if_then64:                                        ; preds = %while_exit8
  ret i8 1

if_merge65:                                       ; preds = %while_exit8
  %i66 = load i32, ptr %i, align 4
  %add67 = add i32 %i66, 1
  store i32 %add67, ptr %i, align 4
  br label %while_cond
}

define internal void @preproc__NS_pp_define_platform(ptr %0) {
entry:
  %macros = alloca ptr, align 8
  store ptr %0, ptr %macros, align 8
  %macros1 = load ptr, ptr %macros, align 8
  call void @preproc__NS_pp_set(ptr %macros1, ptr @str.43, ptr @str.44)
  %triple = alloca ptr, align 8
  %1 = call ptr @arc_LLVMGetDefaultTargetTriple()
  store ptr %1, ptr %triple, align 8
  %triple2 = load ptr, ptr %triple, align 8
  %icmp = icmp eq ptr %triple2, null
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret void

if_merge:                                         ; preds = %entry
  %triple3 = load ptr, ptr %triple, align 8
  %2 = call i8 @preproc__NS_pp_triple_has(ptr %triple3, ptr @str.45)
  %tobool = icmp ne i8 %2, 0
  br i1 %tobool, label %lor_merge, label %lor_rhs

lor_rhs:                                          ; preds = %if_merge
  %triple4 = load ptr, ptr %triple, align 8
  %3 = call i8 @preproc__NS_pp_triple_has(ptr %triple4, ptr @str.46)
  %tobool5 = icmp ne i8 %3, 0
  br label %lor_merge

lor_merge:                                        ; preds = %lor_rhs, %if_merge
  %lor = phi i1 [ true, %if_merge ], [ %tobool5, %lor_rhs ]
  br i1 %lor, label %lor_merge7, label %lor_rhs6

lor_rhs6:                                         ; preds = %lor_merge
  %triple8 = load ptr, ptr %triple, align 8
  %4 = call i8 @preproc__NS_pp_triple_has(ptr %triple8, ptr @str.47)
  %tobool9 = icmp ne i8 %4, 0
  br label %lor_merge7

lor_merge7:                                       ; preds = %lor_rhs6, %lor_merge
  %lor10 = phi i1 [ true, %lor_merge ], [ %tobool9, %lor_rhs6 ]
  br i1 %lor10, label %if_then11, label %if_else

if_then11:                                        ; preds = %lor_merge7
  %macros13 = load ptr, ptr %macros, align 8
  call void @preproc__NS_pp_set(ptr %macros13, ptr @str.48, ptr @str.49)
  %macros14 = load ptr, ptr %macros, align 8
  call void @preproc__NS_pp_set(ptr %macros14, ptr @str.50, ptr @str.51)
  br label %if_merge12

if_else:                                          ; preds = %lor_merge7
  %triple15 = load ptr, ptr %triple, align 8
  %5 = call i8 @preproc__NS_pp_triple_has(ptr %triple15, ptr @str.52)
  %tobool16 = icmp ne i8 %5, 0
  br i1 %tobool16, label %lor_merge18, label %lor_rhs17

if_merge12:                                       ; preds = %if_merge29, %if_then11
  ret void

lor_rhs17:                                        ; preds = %if_else
  %triple19 = load ptr, ptr %triple, align 8
  %6 = call i8 @preproc__NS_pp_triple_has(ptr %triple19, ptr @str.53)
  %tobool20 = icmp ne i8 %6, 0
  br label %lor_merge18

lor_merge18:                                      ; preds = %lor_rhs17, %if_else
  %lor21 = phi i1 [ true, %if_else ], [ %tobool20, %lor_rhs17 ]
  br i1 %lor21, label %lor_merge23, label %lor_rhs22

lor_rhs22:                                        ; preds = %lor_merge18
  %triple24 = load ptr, ptr %triple, align 8
  %7 = call i8 @preproc__NS_pp_triple_has(ptr %triple24, ptr @str.54)
  %tobool25 = icmp ne i8 %7, 0
  br label %lor_merge23

lor_merge23:                                      ; preds = %lor_rhs22, %lor_merge18
  %lor26 = phi i1 [ true, %lor_merge18 ], [ %tobool25, %lor_rhs22 ]
  br i1 %lor26, label %if_then27, label %if_else28

if_then27:                                        ; preds = %lor_merge23
  %macros30 = load ptr, ptr %macros, align 8
  call void @preproc__NS_pp_set(ptr %macros30, ptr @str.55, ptr @str.56)
  %macros31 = load ptr, ptr %macros, align 8
  call void @preproc__NS_pp_set(ptr %macros31, ptr @str.57, ptr @str.58)
  br label %if_merge29

if_else28:                                        ; preds = %lor_merge23
  %triple32 = load ptr, ptr %triple, align 8
  %8 = call i8 @preproc__NS_pp_triple_has(ptr %triple32, ptr @str.59)
  %if_cond = icmp ne i8 %8, 0
  br i1 %if_cond, label %if_then33, label %if_merge34

if_merge29:                                       ; preds = %if_merge34, %if_then27
  br label %if_merge12

if_then33:                                        ; preds = %if_else28
  %macros35 = load ptr, ptr %macros, align 8
  call void @preproc__NS_pp_set(ptr %macros35, ptr @str.60, ptr @str.61)
  %macros36 = load ptr, ptr %macros, align 8
  call void @preproc__NS_pp_set(ptr %macros36, ptr @str.62, ptr @str.63)
  br label %if_merge34

if_merge34:                                       ; preds = %if_then33, %if_else28
  br label %if_merge29
}

define internal ptr @preproc__NS_preprocess(ptr %0, ptr %1, ptr %2) {
entry:
  %src = alloca ptr, align 8
  store ptr %0, ptr %src, align 8
  %src_path = alloca ptr, align 8
  store ptr %1, ptr %src_path, align 8
  %stdlib_path = alloca ptr, align 8
  store ptr %2, ptr %stdlib_path, align 8
  %macros = alloca %pp_table, align 8
  store %pp_table zeroinitializer, ptr %macros, align 8
  call void @preproc__NS_pp_table_init(ptr %macros)
  call void @preproc__NS_pp_define_platform(ptr %macros)
  %funcs = alloca %pp_func_table, align 8
  store %pp_func_table zeroinitializer, ptr %funcs, align 8
  call void @preproc__NS_pp_func_table_init(ptr %funcs)
  %included = alloca %pp_table, align 8
  store %pp_table zeroinitializer, ptr %included, align 8
  call void @preproc__NS_pp_table_init(ptr %included)
  %base_dir = alloca [2048 x i8], align 1
  store [2048 x i8] zeroinitializer, ptr %base_dir, align 1
  %arr_gep = getelementptr [2048 x i8], ptr %base_dir, i64 0, i32 0
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
  %arr_gep40 = getelementptr [2048 x i8], ptr %base_dir, i64 0, i32 0
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
  br i1 %icmp8, label %lor_merge, label %lor_rhs

while_exit:                                       ; preds = %while_cond
  %last_sep18 = load i32, ptr %last_sep, align 4
  %icmp19 = icmp sge i32 %last_sep18, 0
  br i1 %icmp19, label %if_then20, label %if_else

lor_rhs:                                          ; preds = %while_body
  %i9 = load i32, ptr %i, align 4
  %ptr_load10 = load ptr, ptr %src_path, align 8
  %ptr_gep11 = getelementptr i8, ptr %ptr_load10, i32 %i9
  %idx_load12 = load i8, ptr %ptr_gep11, align 1
  %icmp13 = icmp eq i8 %idx_load12, 92
  br label %lor_merge

lor_merge:                                        ; preds = %lor_rhs, %while_body
  %lor = phi i1 [ true, %while_body ], [ %icmp13, %lor_rhs ]
  br i1 %lor, label %if_then14, label %if_merge15

if_then14:                                        ; preds = %lor_merge
  %i16 = load i32, ptr %i, align 4
  store i32 %i16, ptr %last_sep, align 4
  br label %if_merge15

if_merge15:                                       ; preds = %if_then14, %lor_merge
  %i17 = load i32, ptr %i, align 4
  %add = add i32 %i17, 1
  store i32 %add, ptr %i, align 4
  br label %while_cond

if_then20:                                        ; preds = %while_exit
  %j = alloca i32, align 4
  store i32 0, ptr %j, align 4
  br label %while_cond22

if_else:                                          ; preds = %while_exit
  %arr_gep38 = getelementptr [2048 x i8], ptr %base_dir, i64 0, i32 0
  store i8 46, ptr %arr_gep38, align 1
  %arr_gep39 = getelementptr [2048 x i8], ptr %base_dir, i64 0, i32 1
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
  %stdlib_path45 = load ptr, ptr %stdlib_path, align 8
  %3 = call ptr @preproc__NS_preprocess_inner(ptr %src43, ptr %bd44, ptr %macros, ptr %funcs, ptr %stdlib_path45, ptr %included)
  ret ptr %3
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

define void @__artemis_init_typeinfo() {
entry:
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
  store i32 12, ptr @__typeinfo___anon2_P_P, align 4
  store ptr @__typeinfo_nm___anon2_P_P, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon2_P_P, i32 0, i32 1), align 8
  store i32 12, ptr @__typeinfo___anon2_P_P, align 4
  store ptr @__typeinfo_flds___anon2_P_P, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon2_P_P, i32 0, i32 1), i64 8), align 8
  store i32 12, ptr @__typeinfo___anon2_P_P, align 4
  store i64 2, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon2_P_P, i32 0, i32 1), i64 16), align 8
  store i32 12, ptr @__typeinfo___anon2_P_P, align 4
  store i64 16, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon2_P_P, i32 0, i32 1), i64 24), align 8
  store i32 12, ptr @__typeinfo___anon2_P_P, align 4
  store i64 8, ptr getelementptr (i8, ptr getelementptr inbounds nuw (%type_info, ptr @__typeinfo___anon2_P_P, i32 0, i32 1), i64 32), align 8
  ret void
}

define internal i32 @afmt__at_args_S__anon2_P_P(ptr %0, i64 %1, ptr %2, %__anon2_P_P %3) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %fmt = alloca ptr, align 8
  store ptr %2, ptr %fmt, align 8
  %args = alloca %__anon2_P_P, align 8
  store %__anon2_P_P %3, ptr %args, align 8
  %ti = alloca ptr, align 8
  store ptr @__typeinfo___anon2_P_P, ptr %ti, align 8
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

define internal i32 @afmt__at_args_S__anon1_P(ptr %0, i64 %1, ptr %2, %__anon1_P %3) {
entry:
  %buf = alloca ptr, align 8
  store ptr %0, ptr %buf, align 8
  %cap = alloca i64, align 8
  store i64 %1, ptr %cap, align 8
  %fmt = alloca ptr, align 8
  store ptr %2, ptr %fmt, align 8
  %args = alloca %__anon1_P, align 8
  store %__anon1_P %3, ptr %args, align 8
  %ti = alloca ptr, align 8
  store ptr @__typeinfo___anon1_P, ptr %ti, align 8
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

define i32 @main() {
entry:
  ret i32 0
}
