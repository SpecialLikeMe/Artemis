// std.fmt — Full I/O and formatting library.

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
extern void*  stdin_ptr();
extern void*  stdout_ptr();
extern void*  stderr_ptr();

namespace std {
namespace fmt {

namespace out {

void print(i8* s) {
    i32 i = 0;
    while (s[i] != 0) { putchar((i32)s[i]); i = i + 1; }
}

void println(i8* s) { print(s); putchar(10); }

void print_i32(i32 v) { printf("%d", v); }
void print_i64(i64 v) { printf("%lld", v); }
void print_u32(u32 v) { printf("%u", v); }
void print_u64(u64 v) { printf("%llu", v); }
void print_f32(f32 v) { printf("%f", (f64)v); }
void print_f64(f64 v) { printf("%f", v); }
void print_bool(bool b) { puts(b ? "true" : "false"); }
void print_char(i8 c) { putchar((i32)c); }
void print_hex(u64 v) { printf("0x%llx", v); }
void print_ptr(void* p) { printf("%p", p); }
void flush() { fflush(stdout_ptr()); }

} // out

namespace err {

void print(i8* s) {
    fprintf(stderr_ptr(), "%s", s);
}

void println(i8* s) {
    fprintf(stderr_ptr(), "%s\n", s);
}

void print_i32(i32 v) { fprintf(stderr_ptr(), "%d", v); }
void flush() { fflush(stderr_ptr()); }

} // err

// --- string formatting into a user-provided buffer ---

i32 fmt_i32(i8* buf, u64 cap, i32 v)  { return snprintf(buf, cap, "%d", v); }
i32 fmt_i64(i8* buf, u64 cap, i64 v)  { return snprintf(buf, cap, "%lld", v); }
i32 fmt_u32(i8* buf, u64 cap, u32 v)  { return snprintf(buf, cap, "%u", v); }
i32 fmt_u64(i8* buf, u64 cap, u64 v)  { return snprintf(buf, cap, "%llu", v); }
i32 fmt_f64(i8* buf, u64 cap, f64 v)  { return snprintf(buf, cap, "%f", v); }
i32 fmt_hex(i8* buf, u64 cap, u64 v)  { return snprintf(buf, cap, "0x%llx", v); }
i32 fmt_ptr(i8* buf, u64 cap, void* p){ return snprintf(buf, cap, "%p", p); }

// --- file I/O wrappers ---

namespace file {

void* open(i8* path, i8* mode) { return fopen(path, mode); }
i32   close(void* fp)          { return fclose(fp); }

u64 read_bytes(void* fp, void* buf, u64 n) {
    return fread(buf, 1, n, fp);
}

u64 write_bytes(void* fp, void* buf, u64 n) {
    return fwrite(buf, 1, n, fp);
}

bool at_eof(void* fp)   { return feof(fp) != 0; }
bool has_error(void* fp) { return ferror(fp) != 0; }

void seek_start(void* fp, i64 off) { fseek(fp, off, 0); }
void seek_cur(void* fp, i64 off)   { fseek(fp, off, 1); }
void seek_end(void* fp, i64 off)   { fseek(fp, off, 2); }
i64  tell(void* fp)                { return ftell(fp); }
void flush(void* fp)               { fflush(fp); }

// Read whole file into a caller-provided buffer; returns bytes read or -1
i64 read_all(i8* path, i8* buf, u64 cap) {
    void* fp = fopen(path, "rb");
    if (fp == (void*)0) { return -1; }
    fseek(fp, 0, 2);
    i64 sz = ftell(fp);
    fseek(fp, 0, 0);
    if (sz < 0 || (u64)sz >= cap) { fclose(fp); return -1; }
    u64 n = fread(buf, 1, (u64)sz, fp);
    buf[n] = 0;
    fclose(fp);
    return (i64)n;
}

} // file

// --- simple string ops ---

namespace str {

i32 len(i8* s) {
    i32 n = 0;
    while (s[n] != 0) { n = n + 1; }
    return n;
}

bool eq(i8* a, i8* b) {
    i32 i = 0;
    while (a[i] != 0 && b[i] != 0) { if (a[i] != b[i]) { return false; } i = i + 1; }
    return a[i] == b[i];
}

void copy(i8* dst, i8* src, u64 cap) {
    u64 i = 0;
    while (src[i] != 0 && i + 1 < cap) { dst[i] = src[i]; i = i + 1; }
    dst[i] = 0;
}

void append(i8* dst, i8* src, u64 cap) {
    i32 dl = len(dst);
    i32 i  = 0;
    while (src[i] != 0 && (u64)(dl + i + 1) < cap) { dst[dl + i] = src[i]; i = i + 1; }
    dst[dl + i] = 0;
}

bool starts_with(i8* s, i8* prefix) {
    i32 i = 0;
    while (prefix[i] != 0) { if (s[i] != prefix[i]) { return false; } i = i + 1; }
    return true;
}

bool ends_with(i8* s, i8* suffix) {
    i32 sl = len(s);
    i32 xl = len(suffix);
    if (xl > sl) { return false; }
    i32 off = sl - xl;
    for (i32 i = 0; i < xl; i = i + 1) { if (s[off+i] != suffix[i]) { return false; } }
    return true;
}

i32 find(i8* haystack, i8* needle) {
    i32 hl = len(haystack);
    i32 nl = len(needle);
    for (i32 i = 0; i <= hl - nl; i = i + 1) {
        bool match = true;
        for (i32 j = 0; j < nl; j = j + 1) {
            if (haystack[i+j] != needle[j]) { match = false; break; }
        }
        if (match) { return i; }
    }
    return -1;
}

i32 to_i32(i8* s) {
    i32 val = 0; i32 sign = 1; i32 i = 0;
    if (s[0] == '-') { sign = -1; i = 1; }
    while (s[i] >= '0' && s[i] <= '9') { val = val * 10 + (i32)(s[i] - '0'); i = i + 1; }
    return sign * val;
}

i64 to_i64(i8* s) {
    i64 val = 0; i64 sign = 1; i32 i = 0;
    if (s[0] == '-') { sign = -1; i = 1; }
    while (s[i] >= '0' && s[i] <= '9') { val = val * 10 + (i64)(s[i] - '0'); i = i + 1; }
    return sign * val;
}

} // str

} // fmt
} // std
