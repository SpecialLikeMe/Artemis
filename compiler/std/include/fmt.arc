// std.fmt — Full I/O and formatting library.
// All functions are at global scope after extern std.fmt; — use prefixed names:
//   out_print / out_println / out_print_i32 / out_flush etc.
//   err_print / err_println / err_print_i32 / err_flush
//   fmt_i32 / fmt_i64 / fmt_u32 / fmt_u64 / fmt_f64 / fmt_hex / fmt_ptr
//   file_open / file_close / file_read_bytes / file_write_bytes / file_read_all etc.
//   str_len / str_eq / str_copy / str_append / str_starts_with / str_ends_with / str_find / str_to_i32 / str_to_i64

extern i32    printf(i8* fmt, ...);
extern i32    fprintf(void* stream, i8* fmt, ...);
extern i32    sprintf(i8* buf, i8* fmt, ...);
extern i32    snprintf(i8* buf, u64 n, i8* fmt, ...);
extern i32    scanf(i8* fmt, ...);
extern i32    sscanf(i8* buf, i8* fmt, ...);
extern i32    fscanf(void* stream, i8* fmt, ...);
extern i32    puts(i8* s);
extern i32    putchar(i32 c);
extern i32    getchar();
extern i32    fflush(void* stream);
extern void*  fopen(i8* path, i8* mode);
extern i32    fclose(void* fp);
extern u64    fread(void* buf, u64 sz, u64 n, void* fp);
extern u64    fwrite(void* buf, u64 sz, u64 n, void* fp);
extern i32    fseek(void* fp, i64 off, i32 whence);
extern i64    ftell(void* fp);
extern i32    feof(void* fp);
extern i32    ferror(void* fp);
extern i32    _write(i32 fd, void* buf, u32 n);

// --- stdout output ---

namespace fmt {
void out_print(i8* s) {
    i32 i = 0;
    while (s[i] != 0) { putchar((i32)s[i]); i = i + 1; }
}

void out_println(i8* s) {
    i32 i = 0;
    while (s[i] != 0) { putchar((i32)s[i]); i = i + 1; }
    putchar(10);
}

void out_print_i32(i32 v)  { printf("%d", v); }
void out_print_i64(i64 v)  { printf("%lld", v); }
void out_print_u32(u32 v)  { printf("%u", v); }
void out_print_u64(u64 v)  { printf("%llu", v); }
void out_print_f32(f32 v)  { printf("%f", (f64)v); }
void out_print_f64(f64 v)  { printf("%f", v); }
void out_print_bool(bool b){ puts(b ? "true" : "false"); }
void out_print_char(i8 c)  { putchar((i32)c); }
void out_print_hex(u64 v)  { printf("0x%llx", v); }
void out_print_ptr(void* p){ printf("%p", p); }
void out_flush()           { fflush((void*)0); }

// --- stderr output (fd 2) ---

void err_print(i8* s) {
    i32 i = 0;
    while (s[i] != 0) { i = i + 1; }
    _write(2, (void*)s, (u32)i);
}
void err_println(i8* s) {
    err_print(s);
    i8 nl = 10;
    _write(2, (void*)(&nl), (u32)1);
}
void err_print_i32(i32 v)  { printf("%d", v); }
void err_flush()           { fflush((void*)0); }

// --- buffer formatting ---

i32 fmt_i32(i8* buf, u64 cap, i32 v)  { return snprintf(buf, cap, "%d", v); }
i32 fmt_i64(i8* buf, u64 cap, i64 v)  { return snprintf(buf, cap, "%lld", v); }
i32 fmt_u32(i8* buf, u64 cap, u32 v)  { return snprintf(buf, cap, "%u", v); }
i32 fmt_u64(i8* buf, u64 cap, u64 v)  { return snprintf(buf, cap, "%llu", v); }
i32 fmt_f64(i8* buf, u64 cap, f64 v)  { return snprintf(buf, cap, "%f", v); }
i32 fmt_hex(i8* buf, u64 cap, u64 v)  { return snprintf(buf, cap, "0x%llx", v); }
i32 fmt_ptr(i8* buf, u64 cap, void* p){ return snprintf(buf, cap, "%p", p); }

// --- file I/O ---

void* file_open(i8* path, i8* mode)          { return fopen(path, mode); }
i32   file_close(void* fp)                    { return fclose(fp); }
u64   file_read_bytes(void* fp, void* buf, u64 n)  { return fread(buf, (u64)1, n, fp); }
u64   file_write_bytes(void* fp, void* buf, u64 n) { return fwrite(buf, (u64)1, n, fp); }
bool  file_at_eof(void* fp)                   { return feof(fp) != 0; }
bool  file_has_error(void* fp)                { return ferror(fp) != 0; }
void  file_seek_start(void* fp, i64 off)      { fseek(fp, off, 0); }
void  file_seek_cur(void* fp, i64 off)        { fseek(fp, off, 1); }
void  file_seek_end(void* fp, i64 off)        { fseek(fp, off, 2); }
i64   file_tell(void* fp)                     { return ftell(fp); }
void  file_flush(void* fp)                    { fflush(fp); }

i64 file_read_all(i8* path, i8* buf, u64 cap) {
    void* fp = fopen(path, "rb");
    if (fp == (void*)0) { return -1; }
    fseek(fp, (i64)0, 2);
    i64 sz = ftell(fp);
    fseek(fp, (i64)0, 0);
    if (sz < 0 || (u64)sz >= cap) { fclose(fp); return -1; }
    u64 n = fread(buf, (u64)1, (u64)sz, fp);
    buf[n] = 0;
    fclose(fp);
    return (i64)n;
}

// --- string operations ---

i32 str_len(i8* s) {
    i32 n = 0;
    while (s[n] != 0) { n = n + 1; }
    return n;
}

bool str_eq(i8* a, i8* b) {
    i32 i = 0;
    while (a[i] != 0 && b[i] != 0) { if (a[i] != b[i]) { return false; } i = i + 1; }
    return a[i] == b[i];
}

void str_copy(i8* dst, i8* src, u64 cap) {
    u64 i = 0;
    while (src[i] != 0 && i + 1 < cap) { dst[i] = src[i]; i = i + 1; }
    dst[i] = 0;
}

void str_append(i8* dst, i8* src, u64 cap) {
    i32 dl = 0; while (dst[dl] != 0) { dl = dl + 1; }
    i32 i  = 0;
    while (src[i] != 0 && (u64)(dl + i + 1) < cap) { dst[dl + i] = src[i]; i = i + 1; }
    dst[dl + i] = 0;
}

bool str_starts_with(i8* s, i8* prefix) {
    i32 i = 0;
    while (prefix[i] != 0) { if (s[i] != prefix[i]) { return false; } i = i + 1; }
    return true;
}

bool str_ends_with(i8* s, i8* suffix) {
    i32 sl = 0; while (s[sl] != 0) { sl = sl + 1; }
    i32 xl = 0; while (suffix[xl] != 0) { xl = xl + 1; }
    if (xl > sl) { return false; }
    i32 off = sl - xl;
    for (i32 i = 0; i < xl; i = i + 1) { if (s[off+i] != suffix[i]) { return false; } }
    return true;
}

i32 str_find(i8* haystack, i8* needle) {
    i32 hl = 0; while (haystack[hl] != 0) { hl = hl + 1; }
    i32 nl = 0; while (needle[nl] != 0) { nl = nl + 1; }
    for (i32 i = 0; i <= hl - nl; i = i + 1) {
        bool match = true;
        for (i32 j = 0; j < nl; j = j + 1) {
            if (haystack[i+j] != needle[j]) { match = false; break; }
        }
        if (match) { return i; }
    }
    return -1;
}

i32 str_to_i32(i8* s) {
    i32 val = 0; i32 sign = 1; i32 i = 0;
    if (s[0] == '-') { sign = -1; i = 1; }
    while (s[i] >= '0' && s[i] <= '9') { val = val * 10 + (i32)(s[i] - '0'); i = i + 1; }
    return sign * val;
}

i64 str_to_i64(i8* s) {
    i64 val = 0; i64 sign = 1; i32 i = 0;
    if (s[0] == '-') { sign = -1; i = 1; }
    while (s[i] >= '0' && s[i] <= '9') { val = val * 10 + (i64)(s[i] - '0'); i = i + 1; }
    return sign * val;
}

} // namespace fmt