// std.fs — Full file system library (cross-platform via POSIX libc).

extern void*  fopen(i8* path, i8* mode);
extern i32    fclose(void* fp);
extern u64    fread(void* buf, u64 sz, u64 n, void* fp);
extern u64    fwrite(void* buf, u64 sz, u64 n, void* fp);
extern i32    fseek(void* fp, i64 off, i32 whence);
extern i64    ftell(void* fp);
extern i32    feof(void* fp);
extern i32    ferror(void* fp);
extern i32    fflush(void* fp);
extern i32    open(i8* path, i32 flags, i32 mode);
extern i32    close(i32 fd);
extern i32    unlink(i8* path);
extern i32    mkdir(i8* path, i32 mode);
extern i32    rmdir(i8* path);
extern i32    rename(i8* old, i8* newp);
extern i32    stat(i8* path, void* statbuf);
extern i32    fstat(i32 fd, void* statbuf);
extern i32    access(i8* path, i32 mode);
extern i8*    getcwd(i8* buf, u64 size);
extern i32    chdir(i8* path);
extern void*  opendir(i8* path);
extern void*  readdir(void* dir);
extern i32    closedir(void* dir);

namespace std {
namespace fs {

constexpr i32 F_OK = 0;  // existence test
constexpr i32 R_OK = 4;  // read permission
constexpr i32 W_OK = 2;  // write permission
constexpr i32 X_OK = 1;  // execute permission

// --- file handle ---

istruc file {
    void* fp;
    bool  open_flag;

    void __construct__(&self) { self.fp = (void*)0; self.open_flag = false; }

    bool open(&self, i8* path, i8* mode) {
        self.fp       = fopen(path, mode);
        self.open_flag = self.fp != (void*)0;
        return self.open_flag;
    }

    void close(&self) {
        if (self.open_flag) { fclose(self.fp); self.open_flag = false; }
    }

    u64 read_bytes(&self, void* buf, u64 n)  { return fread(buf, 1, n, self.fp); }
    u64 write_bytes(&self, void* buf, u64 n) { return fwrite(buf, 1, n, self.fp); }

    bool write_str(&self, i8* s) {
        i32 n = 0;
        while (s[n] != 0) { n = n + 1; }
        return fwrite(s, 1, (u64)n, self.fp) == (u64)n;
    }

    i32 read_char(&self) {
        i8 c = 0;
        if (fread(&c, 1, 1, self.fp) == 1) { return (i32)c; }
        return -1;
    }

    bool read_line(&self, i8* buf, i32 cap) {
        i32 i = 0;
        while (i < cap - 1) {
            i32 c = self.read_char();
            if (c == -1) { buf[i] = 0; return i > 0; }
            buf[i] = (i8)c; i = i + 1;
            if (c == '\n') { break; }
        }
        buf[i] = 0;
        return true;
    }

    void seek_start(&self, i64 off) { fseek(self.fp, off, 0); }
    void seek_cur(&self, i64 off)   { fseek(self.fp, off, 1); }
    void seek_end(&self, i64 off)   { fseek(self.fp, off, 2); }
    i64  tell(&self)                { return ftell(self.fp); }

    i64 size(&self) {
        i64 cur = self.tell();
        fseek(self.fp, 0, 2);
        i64 sz = self.tell();
        fseek(self.fp, cur, 0);
        return sz;
    }

    bool at_eof(&self)    { return feof(self.fp) != 0; }
    bool has_error(&self) { return ferror(self.fp) != 0; }
    bool is_open(&self)   { return self.open_flag; }
    void flush(&self)           { fflush(self.fp); }

    // Read entire file into a caller-provided buffer
    i64 read_all(&self, i8* buf, u64 cap) {
        i64 sz = self.size();
        if (sz < 0 || (u64)sz >= cap) { return -1; }
        self.seek_start(0);
        u64 n = self.read_bytes(buf, (u64)sz);
        buf[n] = 0;
        return (i64)n;
    }
}

// --- path utilities ---

namespace path {

bool exists(i8* p) { return access(p, F_OK) == 0; }
bool is_readable(i8* p) { return access(p, R_OK) == 0; }
bool is_writable(i8* p) { return access(p, W_OK) == 0; }

i32 basename_start(i8* path) {
    i32 i = 0; i32 last_sep = -1;
    while (path[i] != 0) {
        if (path[i] == '/' || path[i] == '\\') { last_sep = i; }
        i = i + 1;
    }
    return last_sep + 1;
}

i32 extension_start(i8* path) {
    i32 i = 0; i32 last_dot = -1;
    while (path[i] != 0) {
        if (path[i] == '.') { last_dot = i; }
        i = i + 1;
    }
    return last_dot;
}

void join(i8* out, u64 cap, i8* dir, i8* name) {
    i32 dl = 0;
    while (dir[dl] != 0) { dl = dl + 1; }
    u64 i = 0;
    while (i < (u64)dl && i + 1 < cap) { out[i] = dir[i]; i = i + 1; }
    if (i > 0 && out[i-1] != '/' && out[i-1] != '\\' && i + 1 < cap) {
        out[i] = '/'; i = i + 1;
    }
    i32 j = 0;
    while (name[j] != 0 && i + 1 < cap) { out[i] = name[j]; i = i + 1; j = j + 1; }
    out[i] = 0;
}

} // path

// --- directory ---

bool make_dir(i8* path)         { return mkdir(path, 0755) == 0; }
bool remove_file(i8* path)      { return unlink(path) == 0; }
bool remove_dir(i8* path)       { return rmdir(path) == 0; }
bool rename_path(i8* o, i8* n)  { return rename(o, n) == 0; }

bool copy_file(i8* src, i8* dst, &memstr a) {
    file s; file d;
    if (!s.open(src, "rb")) { return false; }
    if (!d.open(dst, "wb")) { s.close(); return false; }
    i64 sz = s.size();
    if (sz <= 0) { s.close(); d.close(); return sz == 0; }
    void* buf = a.mmap((u64)sz);
    u64 n = s.read_bytes(buf, (u64)sz);
    d.write_bytes(buf, n);
    a.deinit(buf);
    s.close(); d.close();
    return n == (u64)sz;
}

i8* cwd(i8* buf, u64 cap) { return getcwd(buf, cap); }
bool cd(i8* path)          { return chdir(path) == 0; }

} // fs
} // std
