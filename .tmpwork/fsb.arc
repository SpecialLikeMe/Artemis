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

}
}
