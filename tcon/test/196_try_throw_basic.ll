; ModuleID = 'tcon/test/196_try_throw_basic.arc'
source_filename = "tcon/test/196_try_throw_basic.arc"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-w64-windows-gnu"

%__artemis_error_t = type { i32, ptr }

@__artemis_error_payload = global ptr null

define i32 @maybe_divide(i32 %0, i32 %1) {
entry:
  %a = alloca i32, align 4
  store i32 %0, ptr %a, align 4
  %b = alloca i32, align 4
  store i32 %1, ptr %b, align 4
  %b1 = load i32, ptr %b, align 4
  %icmp = icmp eq i32 %b1, 0
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %entry
  ret i32 -1

if_merge:                                         ; preds = %entry
  %a2 = load i32, ptr %a, align 4
  %b3 = load i32, ptr %b, align 4
  %sdiv = sdiv i32 %a2, %b3
  ret i32 %sdiv
}

define i32 @main() {
entry:
  %err_fired = alloca i32, align 4
  store i32 0, ptr %err_fired, align 4
  %0 = call i32 @maybe_divide(i32 10, i32 0)
  %exc_is_err = icmp eq i32 %0, -1
  br i1 %exc_is_err, label %exc_err, label %exc_ok

exc_err:                                          ; preds = %entry
  %e = alloca %__artemis_error_t, align 8
  %err_code_ptr = getelementptr inbounds nuw %__artemis_error_t, ptr %e, i32 0, i32 0
  store i32 -1, ptr %err_code_ptr, align 4
  %err_payload = load ptr, ptr @__artemis_error_payload, align 8
  %err_payload_ptr = getelementptr inbounds nuw %__artemis_error_t, ptr %e, i32 0, i32 1
  store ptr %err_payload, ptr %err_payload_ptr, align 8
  br label %exc_ok

exc_ok:                                           ; preds = %exc_err, %entry
  %err_fired1 = load i32, ptr %err_fired, align 4
  %icmp = icmp ne i32 %err_fired1, 1
  br i1 %icmp, label %if_then, label %if_merge

if_then:                                          ; preds = %exc_ok
  ret i32 1

if_merge:                                         ; preds = %exc_ok
  %1 = call i32 @maybe_divide(i32 10, i32 2)
  %exc_is_err2 = icmp eq i32 %1, -1
  br i1 %exc_is_err2, label %exc_err3, label %exc_ok4

exc_err3:                                         ; preds = %if_merge
  %e5 = alloca %__artemis_error_t, align 8
  %err_code_ptr6 = getelementptr inbounds nuw %__artemis_error_t, ptr %e5, i32 0, i32 0
  store i32 -1, ptr %err_code_ptr6, align 4
  %err_payload7 = load ptr, ptr @__artemis_error_payload, align 8
  %err_payload_ptr8 = getelementptr inbounds nuw %__artemis_error_t, ptr %e5, i32 0, i32 1
  store ptr %err_payload7, ptr %err_payload_ptr8, align 8
  br label %exc_ok4

exc_ok4:                                          ; preds = %exc_err3, %if_merge
  %err_fired9 = load i32, ptr %err_fired, align 4
  %icmp10 = icmp ne i32 %err_fired9, 1
  br i1 %icmp10, label %if_then11, label %if_merge12

if_then11:                                        ; preds = %exc_ok4
  ret i32 2

if_merge12:                                       ; preds = %exc_ok4
  ret i32 0
}
