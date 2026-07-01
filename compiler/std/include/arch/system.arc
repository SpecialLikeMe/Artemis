// std.arch.system — Portable syscall interface.
// Exposes a POSIX-convention API on all platforms (including Windows via emulation).

@ifdef _WIN32
// Windows API declarations (via kernel32/ntdll)
extern void*  VirtualAlloc(void* addr, u64 size, u32 type, u32 protect);
extern i32    VirtualFree(void* addr, u64 size, u32 type);
extern i32    GetCurrentProcessId();
extern void   ExitProcess(u32 code);
extern i32    GetLastError();
extern i32    Sleep(u32 ms);
extern i64    GetTickCount64();
extern i32    QueryPerformanceCounter(i64* count);
extern i32    QueryPerformanceFrequency(i64* freq);
extern i32    WriteFile(void* handle, void* buf, u32 n, u32* written, void* overlapped);
extern void*  GetStdHandle(u32 id);
extern i32    CreateDirectoryA(i8* path, void* sec);
extern i32    RemoveDirectoryA(i8* path);
extern i32    DeleteFileA(i8* path);
extern i32    MoveFileA(i8* old_path, i8* new_path);
@else
// POSIX / libc functions
extern void*  mmap(void* addr, u64 len, i32 prot, i32 flags, i32 fd, i64 offset);
extern i32    munmap(void* addr, u64 len);
extern void*  sbrk(i64 increment);
extern i32    getpid();
extern i32    getppid();
extern u64    getuid();
extern u64    getgid();
extern i32    kill(i32 pid, i32 sig);
extern i32    clock_gettime(i32 clk_id, void* timespec);
extern i32    nanosleep(void* req, void* rem);
extern i32    usleep(u32 us);
extern i32    sleep(u32 s);
extern i64    write(i32 fd, void* buf, u64 n);
extern i64    read(i32 fd, void* buf, u64 n);
extern i32    open(i8* path, i32 flags, i32 mode);
extern i32    close(i32 fd);
extern i64    lseek(i32 fd, i64 offset, i32 whence);
extern i32    unlink(i8* path);
extern i32    mkdir(i8* path, i32 mode);
extern i32    rmdir(i8* path);
extern i32    rename(i8* old_p, i8* new_p);
extern i32    stat(i8* path, void* statbuf);
extern i32    fstat(i32 fd, void* statbuf);
extern i32    access(i8* path, i32 mode);
extern i8*    getcwd(i8* buf, u64 size);
extern i32    chdir(i8* path);
extern i8**   environ_ptr();
@endif

extern void   exit(i32 code);
extern void   abort();
extern i64    time(i64* t);
extern i32    printf(i8* fmt, ...);

namespace std {
namespace arch {
namespace system {

// --- Platform constants ---

@ifdef _WIN32
constexpr i32 STDIN  = 0;  // STD_INPUT_HANDLE  = -10 (0xFFFFFFF6), simplified
constexpr i32 STDOUT = 1;
constexpr i32 STDERR = 2;

constexpr u32 MEM_COMMIT   = 0x00001000;
constexpr u32 MEM_RESERVE  = 0x00002000;
constexpr u32 MEM_RELEASE  = 0x00008000;
constexpr u32 PAGE_RW      = 0x04;
@else
constexpr i32 PROT_NONE  = 0x0;
constexpr i32 PROT_READ  = 0x1;
constexpr i32 PROT_WRITE = 0x2;
constexpr i32 PROT_EXEC  = 0x4;

constexpr i32 MAP_PRIVATE   = 0x02;
constexpr i32 MAP_ANONYMOUS = 0x20;
constexpr i32 MAP_ANON      = 0x20;

constexpr i32 SEEK_SET = 0;
constexpr i32 SEEK_CUR = 1;
constexpr i32 SEEK_END = 2;

constexpr i32 O_RDONLY  = 0x0000;
constexpr i32 O_WRONLY  = 0x0001;
constexpr i32 O_RDWR    = 0x0002;
constexpr i32 O_CREAT   = 0x0040;
constexpr i32 O_TRUNC   = 0x0200;
constexpr i32 O_APPEND  = 0x0400;

constexpr i32 STDIN  = 0;
constexpr i32 STDOUT = 1;
constexpr i32 STDERR = 2;

constexpr i32 CLOCK_REALTIME  = 0;
constexpr i32 CLOCK_MONOTONIC = 1;

constexpr i32 SIGTERM = 15;
constexpr i32 SIGKILL = 9;
constexpr i32 SIGINT  = 2;
@endif

// --- Portable OS-backed virtual memory allocator ---
memstr mmap_alloc {
    u64 total_allocated;

    void __construct__(&self) { self.total_allocated = 0; }

    void* sys_alloc(&self, u64 n) {
@ifdef _WIN32
        void* p = VirtualAlloc((void*)0, n, MEM_COMMIT | MEM_RESERVE, PAGE_RW);
        if (p != (void*)0) self.total_allocated = self.total_allocated + n;
        return p;
@else
        void* p = mmap((void*)0, n, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
        if (p != (void*)0) self.total_allocated = self.total_allocated + n;
        return p;
@endif
    }

    void sys_free(&self, void* p, u64 n) {
@ifdef _WIN32
        VirtualFree(p, 0, MEM_RELEASE);
@else
        munmap(p, n);
@endif
    }
}

// --- timespec ---
struct timespec_t {
    i64 tv_sec;
    i64 tv_nsec;
}

// --- high-res timer ---
i64 monotonic_ns() {
@ifdef _WIN32
    i64 count = 0; i64 freq = 0;
    QueryPerformanceCounter(&count);
    QueryPerformanceFrequency(&freq);
    if (freq == 0) return 0;
    return (count * 1000000000i64) / freq;
@else
    timespec_t ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000000000i64 + ts.tv_nsec;
@endif
}

i64 realtime_ns() {
@ifdef _WIN32
    return monotonic_ns(); // approximation on Windows
@else
    timespec_t ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    return ts.tv_sec * 1000000000i64 + ts.tv_nsec;
@endif
}

void sleep_ms(u64 ms) {
@ifdef _WIN32
    Sleep((u32)ms);
@else
    timespec_t ts;
    ts.tv_sec  = (i64)(ms / 1000);
    ts.tv_nsec = (i64)((ms % 1000) * 1000000);
    nanosleep(&ts, (void*)0);
@endif
}

// --- process ---
void quit(i32 code)  { exit(code); }
void panic_exit()    { abort(); }
i32  pid() {
@ifdef _WIN32
    return GetCurrentProcessId();
@else
    return getpid();
@endif
}

// --- raw write ---
void write_stdout(i8* buf, u64 n) {
@ifdef _WIN32
    void* h = GetStdHandle((u32)0xFFFFFFF5); // STD_OUTPUT_HANDLE
    u32 written = 0;
    WriteFile(h, (void*)buf, (u32)n, &written, (void*)0);
@else
    write(STDOUT, (void*)buf, n);
@endif
}

void write_stderr(i8* buf, u64 n) {
@ifdef _WIN32
    void* h = GetStdHandle((u32)0xFFFFFFF4); // STD_ERROR_HANDLE
    u32 written = 0;
    WriteFile(h, (void*)buf, (u32)n, &written, (void*)0);
@else
    write(STDERR, (void*)buf, n);
@endif
}

} // system
} // arch
} // std
