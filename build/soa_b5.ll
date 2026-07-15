; ModuleID = 'build/soa_b5.arc'
source_filename = "build/soa_b5.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%soa_layout = type { ptr, i64, [64 x ptr], i32, i32 }

@soa__NS_SOA_MAX_FIELDS = global i32 64

declare ptr @memcpy(ptr, ptr, i64)

define %soa_layout @soa__NS_make_soa() {
entry:
  %layout = alloca %soa_layout, align 8
  store %soa_layout zeroinitializer, ptr %layout, align 8
  %layout1 = load %soa_layout, ptr %layout, align 8
  ret %soa_layout %layout1
}

define i32 @main() {
entry:
  ret i32 0
}
