// std.arch.system — Portable syscall interface.
// Exposes a POSIX-convention API on all platforms (including Windows via emulation).

@ifdef _WIN32
// Windows API declarations (via kernel32/ntdll)
@unsafe extern fn VirtualAlloc(addr: *void, size: u64, type: u32, protect: u32) *void;
@unsafe extern fn VirtualFree(addr: *void, size: u64, type: u32) i32;
@unsafe extern fn GetCurrentProcessId() i32;
@unsafe extern fn ExitProcess(code: u32) void;
@unsafe extern fn GetLastError() i32;
@unsafe extern fn Sleep(ms: u32) i32;
@unsafe extern fn GetTickCount64() i64;
@unsafe extern fn QueryPerformanceCounter(count: *i64) i32;
@unsafe extern fn QueryPerformanceFrequency(freq: *i64) i32;
@unsafe extern fn WriteFile(handle: *void, buf: *void, n: u32, written: *u32, overlapped: *void) i32;
@unsafe extern fn GetStdHandle(id: u32) *void;
@unsafe extern fn CreateDirectoryA(path: *i8, sec: *void) i32;
@unsafe extern fn RemoveDirectoryA(path: *i8) i32;
@unsafe extern fn DeleteFileA(path: *i8) i32;
@unsafe extern fn MoveFileA(old_path: *i8, new_path: *i8) i32;
@else
// POSIX / libc functions
@unsafe extern fn mmap(addr: *void, len: u64, prot: i32, flags: i32, fd: i32, offset: i64) *void;
@unsafe extern fn munmap(addr: *void, len: u64) i32;
@unsafe extern fn sbrk(increment: i64) *void;
@unsafe extern fn getpid() i32;
@unsafe extern fn getppid() i32;
@unsafe extern fn getuid() u64;
@unsafe extern fn getgid() u64;
@unsafe extern fn kill(pid: i32, sig: i32) i32;
@unsafe extern fn clock_gettime(clk_id: i32, timespec: *void) i32;
@unsafe extern fn nanosleep(req: *void, rem: *void) i32;
@unsafe extern fn usleep(us: u32) i32;
@unsafe extern fn sleep(s: u32) i32;
@unsafe extern fn write(fd: i32, buf: *void, n: u64) i64;
@unsafe extern fn read(fd: i32, buf: *void, n: u64) i64;
@unsafe extern fn open(path: *i8, flags: i32, mode: i32) i32;
@unsafe extern fn close(fd: i32) i32;
@unsafe extern fn lseek(fd: i32, offset: i64, whence: i32) i64;
@unsafe extern fn unlink(path: *i8) i32;
@unsafe extern fn mkdir(path: *i8, mode: i32) i32;
@unsafe extern fn rmdir(path: *i8) i32;
@unsafe extern fn rename(old_p: *i8, new_p: *i8) i32;
@unsafe extern fn stat(path: *i8, statbuf: *void) i32;
@unsafe extern fn fstat(fd: i32, statbuf: *void) i32;
@unsafe extern fn access(path: *i8, mode: i32) i32;
@unsafe extern fn getcwd(buf: *i8, size: u64) *i8;
@unsafe extern fn chdir(path: *i8) i32;
@unsafe extern fn environ_ptr() **i8;
@endif

@unsafe extern fn exit(code: i32) void;
@unsafe extern fn abort() void;
@unsafe extern fn time(t: *i64) i64;
@unsafe extern fn printf(fmt: *i8, ...) i32;

namespace std {
namespace arch {
namespace system {

// --- Platform constants ---

@ifdef _WIN32
comptime i32 STDIN  = 0;  // STD_INPUT_HANDLE  = -10 (0xFFFFFFF6), simplified
comptime i32 STDOUT = 1;
comptime i32 STDERR = 2;

comptime u32 MEM_COMMIT   = 0x00001000;
comptime u32 MEM_RESERVE  = 0x00002000;
comptime u32 MEM_RELEASE  = 0x00008000;
comptime u32 PAGE_RW      = 0x04;
@else
comptime i32 PROT_NONE  = 0x0;
comptime i32 PROT_READ  = 0x1;
comptime i32 PROT_WRITE = 0x2;
comptime i32 PROT_EXEC  = 0x4;

comptime i32 MAP_PRIVATE   = 0x02;
comptime i32 MAP_ANONYMOUS = 0x20;
comptime i32 MAP_ANON      = 0x20;

comptime i32 SEEK_SET = 0;
comptime i32 SEEK_CUR = 1;
comptime i32 SEEK_END = 2;

comptime i32 O_RDONLY  = 0x0000;
comptime i32 O_WRONLY  = 0x0001;
comptime i32 O_RDWR    = 0x0002;
comptime i32 O_CREAT   = 0x0040;
comptime i32 O_TRUNC   = 0x0200;
comptime i32 O_APPEND  = 0x0400;

comptime i32 STDIN  = 0;
comptime i32 STDOUT = 1;
comptime i32 STDERR = 2;

comptime i32 CLOCK_REALTIME  = 0;
comptime i32 CLOCK_MONOTONIC = 1;

comptime i32 SIGTERM = 15;
comptime i32 SIGKILL = 9;
comptime i32 SIGINT  = 2;
@endif

// --- Portable OS-backed virtual memory allocator ---
memstr mmap_alloc {
    let mut total_allocated: u64;

    fn __construct__(self: *mmap_alloc) void { self.total_allocated = 0; }

    fn sys_alloc(self: *mmap_alloc, n: u64) *void {
@ifdef _WIN32
        let mut p: *void= VirtualAlloc((void*)0, n, MEM_COMMIT | MEM_RESERVE, PAGE_RW);
        if (p != (void*)0) self.total_allocated = self.total_allocated + n;
        return p;
@else
        let mut p: *void= mmap((void*)0, n, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
        if (p != (void*)0) self.total_allocated = self.total_allocated + n;
        return p;
@endif
    }

    fn sys_free(self: *mmap_alloc, p: *void, n: u64) void {
@ifdef _WIN32
        VirtualFree(p, 0, MEM_RELEASE);
@else
        munmap(p, n);
@endif
    }
}

// --- timespec ---
struct timespec_t {
    let tv_sec: i64;
    let tv_nsec: i64;
}

// --- high-res timer ---
fn monotonic_ns() i64 {
@ifdef _WIN32
    let mut count: i64= 0; let mut freq: i64= 0;
    QueryPerformanceCounter(&count);
    QueryPerformanceFrequency(&freq);
    if (freq == 0) return 0;
    return (count * 1000000000i64) / freq;
@else
    let mut ts: timespec_t;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000000000i64 + ts.tv_nsec;
@endif
}

fn realtime_ns() i64 {
@ifdef _WIN32
    return monotonic_ns(); // approximation on Windows
@else
    let mut ts: timespec_t;
    clock_gettime(CLOCK_REALTIME, &ts);
    return ts.tv_sec * 1000000000i64 + ts.tv_nsec;
@endif
}

fn sleep_ms(ms: u64) void {
@ifdef _WIN32
    Sleep((u32)ms);
@else
    let mut ts: timespec_t;
    ts.tv_sec  = (i64)(ms / 1000);
    ts.tv_nsec = (i64)((ms % 1000) * 1000000);
    nanosleep(&ts, (void*)0);
@endif
}

// --- process ---
fn quit(code: i32) void  { exit(code); }
fn panic_exit() void    { @unsafe { abort(); } }
fn pid() i32 {
@ifdef _WIN32
    return GetCurrentProcessId();
@else
    return getpid();
@endif
}

// --- raw write ---
fn write_stdout(buf: *i8, n: u64) void {
@ifdef _WIN32
    let mut h: *void= GetStdHandle((u32)0xFFFFFFF5); // STD_OUTPUT_HANDLE
    let mut written: u32= 0;
    WriteFile(h, (void*)buf, (u32)n, &written, (void*)0);
@else
    write(STDOUT, (void*)buf, n);
@endif
}

fn write_stderr(buf: *i8, n: u64) void {
@ifdef _WIN32
    let mut h: *void= GetStdHandle((u32)0xFFFFFFF4); // STD_ERROR_HANDLE
    let mut written: u32= 0;
    WriteFile(h, (void*)buf, (u32)n, &written, (void*)0);
@else
    write(STDERR, (void*)buf, n);
@endif
}

} // system
} // arch
} // std
