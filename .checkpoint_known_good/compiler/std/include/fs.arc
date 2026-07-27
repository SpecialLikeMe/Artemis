// std.fs — Full file system library (cross-platform via POSIX libc).

@unsafe extern fn fopen(path: *i8, mode: *i8) *void;
@unsafe extern fn fclose(fp: *void) i32;
@unsafe extern fn fread(buf: *void, sz: u64, n: u64, fp: *void) u64;
@unsafe extern fn fwrite(buf: *void, sz: u64, n: u64, fp: *void) u64;
@unsafe extern fn fseek(fp: *void, off: i64, whence: i32) i32;
@unsafe extern fn ftell(fp: *void) i64;
@unsafe extern fn feof(fp: *void) i32;
@unsafe extern fn ferror(fp: *void) i32;
@unsafe extern fn fflush(fp: *void) i32;
@unsafe extern fn open(path: *i8, flags: i32, mode: i32) i32;
@unsafe extern fn close(fd: i32) i32;
@unsafe extern fn unlink(path: *i8) i32;
@unsafe extern fn mkdir(path: *i8, mode: i32) i32;
@unsafe extern fn rmdir(path: *i8) i32;
@unsafe extern fn rename(old: *i8, newp: *i8) i32;
@unsafe extern fn stat(path: *i8, statbuf: *void) i32;
@unsafe extern fn fstat(fd: i32, statbuf: *void) i32;
@unsafe extern fn access(path: *i8, mode: i32) i32;
@unsafe extern fn getcwd(buf: *i8, size: u64) *i8;
@unsafe extern fn chdir(path: *i8) i32;
@unsafe extern fn opendir(path: *i8) *void;
@unsafe extern fn readdir(dir: *void) *void;
@unsafe extern fn closedir(dir: *void) i32;

namespace std {
namespace fs {

comptime i32 F_OK = 0;  // existence test
comptime i32 R_OK = 4;  // read permission
comptime i32 W_OK = 2;  // write permission
comptime i32 X_OK = 1;  // execute permission

// --- file handle ---

istruc file {
    let mut fp: *void;
    let mut open_flag: bool;

    fn __construct__(self: *file) void { self.fp = (void*)0; self.open_flag = false; }

    fn open(self: *file, path: *i8, mode: *i8) bool {
        @unsafe {
            self.fp       = fopen(path, mode);
            self.open_flag = self.fp != (void*)0;
            return self.open_flag;
        }
    }

    fn close(self: *file) void {
        @unsafe {
            if (self.open_flag) { fclose(self.fp); self.open_flag = false; }
        }
    }

    fn read_bytes(self: *file, buf: *void, n: u64) u64  { @unsafe { return fread(buf, (u64)1, n, self.fp); } }
    fn write_bytes(self: *file, buf: *void, n: u64) u64 { @unsafe { return fwrite(buf, (u64)1, n, self.fp); } }

    fn write_str(self: *file, s: *i8) bool {
        @unsafe {
            let mut n: i32= 0;
            while (s[n] != 0) { n = n + 1; }
            return fwrite(s, (u64)1, (u64)n, self.fp) == (u64)n;
        }
    }

    fn read_char(self: *file) i32 {
        @unsafe {
            let mut c: i8= 0;
            if (fread(&c, (u64)1, (u64)1, self.fp) == (u64)1) { return (i32)c; }
            return -1;
        }
    }

    fn read_line(self: *file, buf: *i8, cap: i32) bool {
        if (cap <= 0) { return false; }
        let mut i: i32= 0;
        while (i < cap - 1) {
            let mut c: i32= self.read_char();
            if (c == -1) { buf[i] = 0; return i > 0; }
            buf[i] = (i8)c; i = i + 1;
            if (c == '\n') { break; }
        }
        buf[i] = 0;
        return true;
    }

    fn seek_start(self: *file, off: i64) void { @unsafe { fseek(self.fp, off, 0); } }
    fn seek_cur(self: *file, off: i64) void   { @unsafe { fseek(self.fp, off, 1); } }
    fn seek_end(self: *file, off: i64) void   { @unsafe { fseek(self.fp, off, 2); } }
    fn tell(self: *file) i64                { @unsafe { return ftell(self.fp); } }

    fn size(self: *file) i64 {
        @unsafe {
            let mut cur: i64= self.tell();
            fseek(self.fp, (i64)0, 2);
            let mut sz: i64= self.tell();
            fseek(self.fp, cur, 0);
            return sz;
        }
    }

    fn at_eof(self: *file) bool    { @unsafe { return feof(self.fp) != 0; } }
    fn has_error(self: *file) bool { @unsafe { return ferror(self.fp) != 0; } }
    fn is_open(self: *file) bool   { return self.open_flag; }
    fn flush(self: *file) void           { @unsafe { fflush(self.fp); } }

    // Read entire file into a caller-provided buffer
    fn read_all(self: *file, buf: *i8, cap: u64) i64 {
        let mut sz: i64= self.size();
        if (sz < 0 || (u64)sz >= cap) { return -1; }
        self.seek_start((i64)0);
        let mut n: u64= self.read_bytes(buf, (u64)sz);
        buf[n] = 0;
        return (i64)n;
    }
}

// --- path utilities ---

namespace path {

fn exists(p: *i8) bool { @unsafe { return access(p, std.fs.F_OK) == 0; } }
fn is_readable(p: *i8) bool { @unsafe { return access(p, std.fs.R_OK) == 0; } }
fn is_writable(p: *i8) bool { @unsafe { return access(p, std.fs.W_OK) == 0; } }

fn basename_start(path: *i8) i32 {
    let mut i: i32= 0; let mut last_sep: i32= -1;
    while (path[i] != 0) {
        if (path[i] == '/' || path[i] == '\\') { last_sep = i; }
        i = i + 1;
    }
    return last_sep + 1;
}

fn extension_start(path: *i8) i32 {
    let mut i: i32= 0; let mut last_dot: i32= -1;
    while (path[i] != 0) {
        if (path[i] == '.') { last_dot = i; }
        i = i + 1;
    }
    return last_dot;
}

fn join(out: *i8, cap: u64, dir: *i8, name: *i8) void {
    let mut dl: i32= 0;
    while (dir[dl] != 0) { dl = dl + 1; }
    let mut i: u64= 0;
    while (i < (u64)dl && i + 1 < cap) { out[i] = dir[i]; i = i + 1; }
    if (i > 0 && out[i-1] != '/' && out[i-1] != '\\' && i + 1 < cap) {
        out[i] = '/'; i = i + 1;
    }
    let mut j: i32= 0;
    while (name[j] != 0 && i + 1 < cap) { out[i] = name[j]; i = i + 1; j = j + 1; }
    out[i] = 0;
}

} // path

// --- directory ---

fn make_dir(path: *i8) bool         { @unsafe { return mkdir(path, 0755) == 0; } }
fn remove_file(path: *i8) bool      { @unsafe { return unlink(path) == 0; } }
fn remove_dir(path: *i8) bool       { @unsafe { return rmdir(path) == 0; } }
fn rename_path(o: *i8, n: *i8) bool  { @unsafe { return rename(o, n) == 0; } }

fn cwd(buf: *i8, cap: u64) *i8 { @unsafe { return getcwd(buf, cap); } }
fn cd(path: *i8) bool          { @unsafe { return chdir(path) == 0; } }

} // fs
} // std
