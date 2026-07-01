// std.process — Child process spawning and environment access.

extern i32  fork();
extern i32  execve(i8* path, i8** argv, i8** envp);
extern i32  waitpid(i32 pid, i32* status, i32 options);
extern void exit(i32 code);
extern i32  pipe(i32* fds);
extern i32  dup2(i32 oldfd, i32 newfd);
extern i32  close(i32 fd);
extern i64  write(i32 fd, void* buf, u64 n);
extern i64  read(i32 fd, void* buf, u64 n);
extern i8** environ_ptr();
extern i8*  getenv(i8* name);

namespace std {
namespace process {

constexpr i32 STDIN_FD  = 0;
constexpr i32 STDOUT_FD = 1;
constexpr i32 STDERR_FD = 2;
constexpr i32 WNOHANG   = 1;

// --- exit status helpers ---

bool wif_exited(i32 status)  { return (status & 0x7F) == 0; }
i32  wex_status(i32 status)  { return (status >> 8) & 0xFF; }
bool wif_signaled(i32 status){ return !wif_exited(status) && (status & 0x7F) != 0x7F; }
i32  wterm_sig(i32 status)   { return status & 0x7F; }

// --- environment ---

i8* env_get(i8* key) { return getenv(key); }

// Linear scan for key=value in environ
i8* env_raw(i8* key) {
    i8** env = environ_ptr();
    i32 kl = 0;
    while (key[kl] != 0) { kl = kl + 1; }
    for (i32 i = 0; env[i] != (i8*)0; i = i + 1) {
        i8* e = env[i];
        bool match = true;
        for (i32 j = 0; j < kl; j = j + 1) {
            if (e[j] != key[j]) { match = false; break; }
        }
        if (match && e[kl] == '=') { return e + kl + 1; }
    }
    return (i8*)0;
}

// --- child process ---

istruc child {
    i32 pid;
    i32 stdin_wr;   // write end of child's stdin pipe
    i32 stdout_rd;  // read end of child's stdout pipe
    i32 stderr_rd;  // read end of child's stderr pipe

    // Spawn a child process. argv must be null-terminated.
    // Pipes stdin/stdout/stderr to the child.
    bool spawn(child* self, i8* path, i8** argv) {
        i32 sin[2]; i32 sout[2]; i32 serr[2];
        if (pipe(sin) != 0 || pipe(sout) != 0 || pipe(serr) != 0) { return false; }

        i32 pid_val = fork();
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

    i64 write_stdin(child* self, void* buf, u64 n) { return write(self.stdin_wr, buf, n); }
    i64 read_stdout(child* self, void* buf, u64 n) { return read(self.stdout_rd, buf, n); }
    i64 read_stderr(child* self, void* buf, u64 n) { return read(self.stderr_rd, buf, n); }

    void close_stdin(child* self) { close(self.stdin_wr); self.stdin_wr = -1; }

    i32 wait(child* self) {
        i32 status = 0;
        waitpid(self.pid, &status, 0);
        return wex_status(status);
    }

    bool try_wait(child* self, i32* exit_code) {
        i32 status = 0;
        i32 r = waitpid(self.pid, &status, WNOHANG);
        if (r == self.pid) { (*exit_code) = wex_status(status); return true; }
        return false;
    }

    void cleanup(child* self) {
        if (self.stdin_wr  >= 0) { close(self.stdin_wr); }
        if (self.stdout_rd >= 0) { close(self.stdout_rd); }
        if (self.stderr_rd >= 0) { close(self.stderr_rd); }
    }
}

// Convenience: run a command and capture stdout into a buffer.
i32 run_capture(i8* path, i8** argv, i8* out_buf, u64 cap) {
    child c;
    if (!c.spawn(path, argv)) { return -1; }
    c.close_stdin();
    u64 total = 0;
    while (total < cap - 1) {
        i64 n = c.read_stdout(out_buf + total, cap - 1 - total);
        if (n <= 0) { break; }
        total = total + (u64)n;
    }
    out_buf[total] = 0;
    i32 code = c.wait();
    c.cleanup();
    return code;
}

void quit(i32 code) { exit(code); }

} // process
} // std
