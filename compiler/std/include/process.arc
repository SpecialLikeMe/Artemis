// std.process — Child process spawning and environment access.
// Note: POSIX-only (Linux/macOS). Windows is not supported by this module.
@ifdef _WIN32
// On Windows, POSIX process APIs are unavailable.
// Use Windows-specific APIs (CreateProcess, etc.) if process spawning is needed.
@error "std.process is not supported on Windows — use platform-specific APIs instead"
@endif

@unsafe extern fn fork() i32;
@unsafe extern fn execve(path: *i8, argv: **i8, envp: **i8) i32;
@unsafe extern fn waitpid(pid: i32, status: *i32, options: i32) i32;
@unsafe extern fn exit(code: i32) void;
@unsafe extern fn pipe(fds: *i32) i32;
@unsafe extern fn dup2(oldfd: i32, newfd: i32) i32;
@unsafe extern fn close(fd: i32) i32;
@unsafe extern fn write(fd: i32, buf: *void, n: u64) i64;
@unsafe extern fn read(fd: i32, buf: *void, n: u64) i64;
@unsafe extern fn environ_ptr() **i8;
@unsafe extern fn getenv(name: *i8) *i8;

namespace std {
namespace process {

comptime i32 STDIN_FD  = 0;
comptime i32 STDOUT_FD = 1;
comptime i32 STDERR_FD = 2;
comptime i32 WNOHANG   = 1;

// --- exit status helpers ---

fn wif_exited(status: i32) bool  { return (status & 0x7F) == 0; }
fn wex_status(status: i32) i32  { return (status >> 8) & 0xFF; }
fn wif_signaled(status: i32) bool{ return !wif_exited(status) && (status & 0x7F) != 0x7F; }
fn wterm_sig(status: i32) i32   { return status & 0x7F; }

// --- environment ---

fn env_get(key: *i8) *i8 { return getenv(key); }

// Linear scan for key=value in environ
fn env_raw(key: *i8) *i8 {
    let mut env: **i8= environ_ptr();
    let mut kl: i32= 0;
    while (key[kl] != 0) { kl = kl + 1; }
    for (let mut i: i32 = 0; env[i] != (i8*)0; i = i + 1) {
        let mut e: *i8= env[i];
        let mut match: bool= true;
        for (let mut j: i32 = 0; j < kl; j = j + 1) {
            if (e[j] != key[j]) { match = false; break; }
        }
        if (match && e[kl] == '=') { return e + kl + 1; }
    }
    return (i8*)0;
}

// --- child process ---

istruc child {
    let mut pid: i32;
    let mut stdin_wr: i32;   // write end of child's stdin pipe
    let mut stdout_rd: i32;  // read end of child's stdout pipe
    let mut stderr_rd: i32;  // read end of child's stderr pipe

    // Spawn a child process. argv must be null-terminated.
    // Pipes stdin/stdout/stderr to the child.
    fn spawn(self: *child, path: *i8, argv: **i8) bool {
        let mut sin: [2]i32; let mut sout: [2]i32; let mut serr: [2]i32;
        if (pipe(sin) != 0 || pipe(sout) != 0 || pipe(serr) != 0) { return false; }

        let mut pid_val: i32= fork();
        if (pid_val < 0) { return false; }

        if (pid_val == 0) {
            // child
            dup2(sin[0], STDIN_FD);
            dup2(sout[1], STDOUT_FD);
            dup2(serr[1], STDERR_FD);
            close(sin[0]); close(sin[1]);
            close(sout[0]); close(sout[1]);
            close(serr[0]); close(serr[1]);
            execve(path, argv, environ_ptr());
            exit(127);
        }

        // parent
        close(sin[0]); close(sout[1]); close(serr[1]);
        self.pid       = pid_val;
        self.stdin_wr  = sin[1];
        self.stdout_rd = sout[0];
        self.stderr_rd = serr[0];
        return true;
    }

    fn write_stdin(self: *child, buf: *void, n: u64) i64 { return write(self.stdin_wr, buf, n); }
    fn read_stdout(self: *child, buf: *void, n: u64) i64 { return read(self.stdout_rd, buf, n); }
    fn read_stderr(self: *child, buf: *void, n: u64) i64 { return read(self.stderr_rd, buf, n); }

    fn close_stdin(self: *child) void { close(self.stdin_wr); self.stdin_wr = -1; }

    fn wait(self: *child) i32 {
        let mut status: i32= 0;
        waitpid(self.pid, &status, 0);
        return wex_status(status);
    }

    fn try_wait(self: *child, exit_code: *i32) bool {
        let mut status: i32= 0;
        let mut r: i32= waitpid(self.pid, &status, WNOHANG);
        if (r == self.pid) { (*exit_code) = wex_status(status); return true; }
        return false;
    }

    fn cleanup(self: *child) void {
        if (self.stdin_wr  >= 0) { close(self.stdin_wr); }
        if (self.stdout_rd >= 0) { close(self.stdout_rd); }
        if (self.stderr_rd >= 0) { close(self.stderr_rd); }
    }
}

// Convenience: run a command and capture stdout into a buffer.
fn run_capture(path: *i8, argv: **i8, out_buf: *i8, cap: u64) i32 {
    let mut c: child;
    if (!c.spawn(path, argv)) { return -1; }
    c.close_stdin();
    let mut total: u64= 0;
    while (total < cap - 1) {
        let mut n: i64= c.read_stdout(out_buf + total, cap - 1 - total);
        if (n <= 0) { break; }
        total = total + (u64)n;
    }
    out_buf[total] = 0;
    let mut code: i32= c.wait();
    c.cleanup();
    return code;
}

fn quit(code: i32) void { exit(code); }

} // process
} // std
