; ModuleID = 'build/soa_trunc11.arc'
source_filename = "build/soa_trunc11.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

@soa__NS_SOA_MAX_FIELDS = global i32 64

define i32 @main() {
entry:
  ret i32 0
}
