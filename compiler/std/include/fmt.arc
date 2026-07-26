// std.fmt — Full I/O and formatting library.
// Access as: std.fmt.out_print(...), std.fmt.str_len(...), etc.

@unsafe extern fn printf(fmt: *i8, ...) i32;
@unsafe extern fn fprintf(stream: *void, fmt: *i8, ...) i32;
@unsafe extern fn sprintf(buf: *i8, fmt: *i8, ...) i32;
@unsafe extern fn snprintf(buf: *i8, n: u64, fmt: *i8, ...) i32;
@unsafe extern fn scanf(fmt: *i8, ...) i32;
@unsafe extern fn sscanf(buf: *i8, fmt: *i8, ...) i32;
@unsafe extern fn fscanf(stream: *void, fmt: *i8, ...) i32;
@unsafe extern fn puts(s: *i8) i32;
@unsafe extern fn putchar(c: i32) i32;
@unsafe extern fn getchar() i32;
@unsafe extern fn fflush(stream: *void) i32;
@unsafe extern fn fopen(path: *i8, mode: *i8) *void;
@unsafe extern fn fclose(fp: *void) i32;
@unsafe extern fn fread(buf: *void, sz: u64, n: u64, fp: *void) u64;
@unsafe extern fn fwrite(buf: *void, sz: u64, n: u64, fp: *void) u64;
@unsafe extern fn fseek(fp: *void, off: i64, whence: i32) i32;
@unsafe extern fn ftell(fp: *void) i64;
@unsafe extern fn feof(fp: *void) i32;
@unsafe extern fn ferror(fp: *void) i32;
// Standard streams. On POSIX these are real extern globals; the Windows CRT has no
// such symbols — `stderr`/`stdout` are macros over __acrt_iob_func(), so an extern
// global reference fails to link. Select the right accessor per platform.
@ifdef _WIN32
@unsafe extern fn __acrt_iob_func(index: u32) *void;
@else
@unsafe extern let stderr: *void;
@unsafe extern let stdout: *void;
@endif

// --- stdout output ---

namespace std {
namespace fmt {

// FILE* for the standard streams, resolved per platform.
fn stream_out() *void {
@ifdef _WIN32
    return __acrt_iob_func(1u);
@else
    return stdout;
@endif
}
fn stream_err() *void {
@ifdef _WIN32
    return __acrt_iob_func(2u);
@else
    return stderr;
@endif
}
fn out_print(s: *i8) void {
    let mut i: i32= 0;
    while (s[i] != 0) { putchar((i32)s[i]); i = i + 1; }
}

fn out_println(s: *i8) void {
    let mut i: i32= 0;
    while (s[i] != 0) { putchar((i32)s[i]); i = i + 1; }
    putchar(10);
}

fn out_print_i32(v: i32) void  { printf("%d", v); }
fn out_print_i64(v: i64) void  { printf("%lld", v); }
fn out_print_u32(v: u32) void  { printf("%u", v); }
fn out_print_u64(v: u64) void  { printf("%llu", v); }
fn out_print_f32(v: f32) void  { printf("%f", (f64)v); }
fn out_print_f64(v: f64) void  { printf("%f", v); }
fn out_print_bool(b: bool) void{ puts(b ? "true" : "false"); }
fn out_print_char(c: i8) void  { putchar((i32)c); }
fn out_print_hex(v: u64) void  { printf("0x%llx", v); }
fn out_print_ptr(p: *void) void{ printf("%p", p); }
fn out_flush() void           { fflush(stream_out()); }

// --- stderr output (fd 2) ---

fn err_print(s: *i8) void {
    fprintf(stream_err(), "%s", s);
}
fn err_println(s: *i8) void {
    fprintf(stream_err(), "%s\n", s);
}
fn err_print_i32(v: i32) void  { fprintf(stream_err(), "%d", v); }
fn err_flush() void           { fflush(stream_err()); }

// --- buffer formatting ---

fn fmt_i32(buf: *i8, cap: u64, v: i32) i32  { return snprintf(buf, cap, "%d", v); }
fn fmt_i64(buf: *i8, cap: u64, v: i64) i32  { return snprintf(buf, cap, "%lld", v); }
fn fmt_u32(buf: *i8, cap: u64, v: u32) i32  { return snprintf(buf, cap, "%u", v); }
fn fmt_u64(buf: *i8, cap: u64, v: u64) i32  { return snprintf(buf, cap, "%llu", v); }
fn fmt_f64(buf: *i8, cap: u64, v: f64) i32  { return snprintf(buf, cap, "%f", v); }
fn fmt_hex(buf: *i8, cap: u64, v: u64) i32  { return snprintf(buf, cap, "0x%llx", v); }
fn fmt_ptr(buf: *i8, cap: u64, p: *void) i32{ return snprintf(buf, cap, "%p", p); }

// --- file I/O ---

fn file_open(path: *i8, mode: *i8) *void          { return fopen(path, mode); }
fn file_close(fp: *void) i32                    { return fclose(fp); }
fn file_read_bytes(fp: *void, buf: *void, n: u64) u64  { return fread(buf, (u64)1, n, fp); }
fn file_write_bytes(fp: *void, buf: *void, n: u64) u64 { return fwrite(buf, (u64)1, n, fp); }
fn file_at_eof(fp: *void) bool                   { return feof(fp) != 0; }
fn file_has_error(fp: *void) bool                { return ferror(fp) != 0; }
fn file_seek_start(fp: *void, off: i64) void      { fseek(fp, off, 0); }
fn file_seek_cur(fp: *void, off: i64) void        { fseek(fp, off, 1); }
fn file_seek_end(fp: *void, off: i64) void        { fseek(fp, off, 2); }
fn file_tell(fp: *void) i64                     { return ftell(fp); }
fn file_flush(fp: *void) void                    { fflush(fp); }

fn file_read_all(path: *i8, buf: *i8, cap: u64) i64 {
    let mut fp: *void= fopen(path, "rb");
    if (fp == (void*)0) { return -1; }
    fseek(fp, (i64)0, 2);
    let mut sz: i64= ftell(fp);
    fseek(fp, (i64)0, 0);
    if (sz < 0 || (u64)sz >= cap) { fclose(fp); return -1; }
    let mut n: u64= fread(buf, (u64)1, (u64)sz, fp);
    buf[n] = 0;
    fclose(fp);
    return (i64)n;
}

// --- string operations ---

fn str_len(s: *i8) i32 {
    let mut n: i32= 0;
    while (s[n] != 0) { n = n + 1; }
    return n;
}

fn str_eq(a: *i8, b: *i8) bool {
    let mut i: i32= 0;
    while (a[i] != 0 && b[i] != 0) { if (a[i] != b[i]) { return false; } i = i + 1; }
    return a[i] == b[i];
}

fn str_copy(dst: *i8, src: *i8, cap: u64) void {
    let mut i: u64= 0;
    while (src[i] != 0 && i + 1 < cap) { dst[i] = src[i]; i = i + 1; }
    dst[i] = 0;
}

fn str_append(dst: *i8, src: *i8, cap: u64) void {
    let mut dl: i32= 0; while (dst[dl] != 0) { dl = dl + 1; }
    let mut i: i32= 0;
    while (src[i] != 0 && (u64)(dl + i + 1) < cap) { dst[dl + i] = src[i]; i = i + 1; }
    dst[dl + i] = 0;
}

fn str_starts_with(s: *i8, prefix: *i8) bool {
    let mut i: i32= 0;
    while (prefix[i] != 0) { if (s[i] != prefix[i]) { return false; } i = i + 1; }
    return true;
}

fn str_ends_with(s: *i8, suffix: *i8) bool {
    let mut sl: i32= 0; while (s[sl] != 0) { sl = sl + 1; }
    let mut xl: i32= 0; while (suffix[xl] != 0) { xl = xl + 1; }
    if (xl > sl) { return false; }
    let mut off: i32= sl - xl;
    for (let mut i: i32 = 0; i < xl; i = i + 1) { if (s[off+i] != suffix[i]) { return false; } }
    return true;
}

fn str_find(haystack: *i8, needle: *i8) i32 {
    let mut hl: i32= 0; while (haystack[hl] != 0) { hl = hl + 1; }
    let mut nl: i32= 0; while (needle[nl] != 0) { nl = nl + 1; }
    for (let mut i: i32 = 0; i <= hl - nl; i = i + 1) {
        let mut found: bool= true;
        for (let mut j: i32 = 0; j < nl; j = j + 1) {
            if (haystack[i+j] != needle[j]) { found = false; break; }
        }
        if (found) { return i; }
    }
    return -1;
}

fn str_to_i32(s: *i8) i32 {
    let mut val: i32= 0; let mut sign: i32= 1; let mut i: i32= 0;
    if (s[0] == '-') { sign = -1; i = 1; }
    while (s[i] >= '0' && s[i] <= '9') { val = val * 10 + (i32)(s[i] - '0'); i = i + 1; }
    return sign * val;
}

fn str_to_i64(s: *i8) i64 {
    let mut val: i64= 0; let mut sign: i64= 1; let mut i: i32= 0;
    if (s[0] == '-') { sign = -1; i = 1; }
    while (s[i] >= '0' && s[i] <= '9') { val = val * 10 + (i64)(s[i] - '0'); i = i + 1; }
    return sign * val;
}

} // namespace fmt
} // namespace std