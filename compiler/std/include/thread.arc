// std.thread — OS-native threads, mutexes, condition variables, and semaphores.
// Cross-platform: pthreads on POSIX, Win32 threads on Windows.

// pthreads (POSIX / MinGW on Windows)
@unsafe extern fn pthread_create(void** tid, void* attr, *(void*)void* fn_ref, void* arg) i32;
@unsafe extern fn pthread_join(tid: *void, retval: **void) i32;
@unsafe extern fn pthread_detach(tid: *void) i32;
@unsafe extern fn pthread_exit(retval: *void) i32;
@unsafe extern fn pthread_self() *void;
@unsafe extern fn pthread_equal(a: *void, b: *void) i32;
@unsafe extern fn pthread_mutex_init(void* mtx, void* attr) i32;
@unsafe extern fn pthread_mutex_destroy(mtx: *void) i32;
@unsafe extern fn pthread_mutex_lock(mtx: *void) i32;
@unsafe extern fn pthread_mutex_trylock(mtx: *void) i32;
@unsafe extern fn pthread_mutex_unlock(mtx: *void) i32;
@unsafe extern fn pthread_cond_init(void* cond, void* attr) i32;
@unsafe extern fn pthread_cond_destroy(cond: *void) i32;
@unsafe extern fn pthread_cond_wait(cond: *void, mtx: *void) i32;
@unsafe extern fn pthread_cond_timedwait(cond: *void, mtx: *void, ts: *void) i32;
@unsafe extern fn pthread_cond_signal(cond: *void) i32;
@unsafe extern fn pthread_cond_broadcast(cond: *void) i32;
@unsafe extern fn sem_init(sem: *void, pshared: i32, val: u32) i32;
@unsafe extern fn sem_destroy(sem: *void) i32;
@unsafe extern fn sem_post(sem: *void) i32;
@unsafe extern fn sem_wait(sem: *void) i32;
@unsafe extern fn sem_trywait(sem: *void) i32;

namespace std {
namespace thread {

// --- mutex ---

istruc mutex {
    let mut handle: [64]i8;  // storage for pthread_mutex_t (platform sized)

    fn __construct__(self: *mutex) void {
        pthread_mutex_init((void*)self.handle, (void*)0);
    }

    fn lock(self: *mutex) void     { pthread_mutex_lock((void*)self.handle); }
    fn unlock(self: *mutex) void   { pthread_mutex_unlock((void*)self.handle); }
    fn try_lock(self: *mutex) bool { return pthread_mutex_trylock((void*)self.handle) == 0; }

    fn deinit(self: *mutex) void { pthread_mutex_destroy((void*)self.handle); }
}

// --- scoped lock guard ---
istruc lock_guard {
    let mut mtx: *mutex;
    fn __construct__(self: *lock_guard, m: *mutex) void { self.mtx = m; (*m).lock(); }
    fn release(self: *lock_guard) void { (*self.mtx).unlock(); }
}

// --- condition variable ---

istruc cond_var {
    let mut handle: [64]i8;

    fn __construct__(self: *cond_var) void {
        pthread_cond_init((void*)self.handle, (void*)0);
    }

    fn wait(self: *cond_var, mtx: *mutex) void {
        pthread_cond_wait((void*)self.handle, (void*)(*mtx).handle);
    }

    fn signal(self: *cond_var) void    { pthread_cond_signal((void*)self.handle); }
    fn broadcast(self: *cond_var) void { pthread_cond_broadcast((void*)self.handle); }

    fn deinit(self: *cond_var) void { pthread_cond_destroy((void*)self.handle); }
}

// --- semaphore ---

istruc semaphore {
    let mut handle: [64]i8;

    fn __construct__(self: *semaphore, initial_val: u32) void {
        sem_init((void*)self.handle, 0, initial_val);
    }

    fn post(self: *semaphore) void     { sem_post((void*)self.handle); }
    fn wait(self: *semaphore) void     { sem_wait((void*)self.handle); }
    fn try_wait(self: *semaphore) bool { return sem_trywait((void*)self.handle) == 0; }

    fn deinit(self: *semaphore) void { sem_destroy((void*)self.handle); }
}

// --- thread ---

istruc thread_t {
    let mut handle: *void;
    let mut joined: bool;

    fn __construct__(self: *thread_t) void {
        self.handle = (void*)0;
        self.joined = false;
    }

    fn spawn(thread_t* self, void*(void*)* fn_ref, void* arg) void {
        pthread_create(thread_t* self.handle, (void*)0, fn_ref, arg);
        self.joined = false;
    }

    fn join(self: *thread_t) void {
        if (!self.joined && self.handle != (void*)0) {
            pthread_join(self.handle, (void**)0);
            self.joined = true;
        }
    }

    fn detach(self: *thread_t) void {
        if (!self.joined && self.handle != (void*)0) {
            pthread_detach(self.handle);
            self.joined = true;
        }
    }

    fn is_done(self: *thread_t) bool { return self.joined; }
}

// --- thread-local ID ---
fn current_id() *void { return pthread_self(); }

// --- once flag (simple spin) ---
istruc once_flag {
    let mut done: i32;

    fn __construct__(self: *once_flag) void { self.done = 0; }

    fn call_once(once_flag* self, void()* fn_ref) void {
        if (self.done != 0) { return; }
        // spin until we win the CAS
        let mut zero: i32= 0;
        let mut one: i32= 1;
        __asm__ { lock cmpxchg %one, %done : zero : one, done : memory }
        if (zero == 0) { fn_ref(); }
        else {
            while (self.done == 0) { __asm__ { pause : : : } }
        }
    }
}

// --- read-write lock ---

istruc rwlock {
    let mut mtx: mutex;
    let mut readers_done: cond_var;
    let mut writers_done: cond_var;
    let mut readers: i32;
    let mut writers: i32;
    let mut pending_writers: i32;

    fn __construct__(self: *rwlock) void {
        self.readers = 0; self.writers = 0; self.pending_writers = 0;
    }

    fn read_lock(self: *rwlock) void {
        self.mtx.lock();
        while (self.writers > 0 || self.pending_writers > 0)
            self.writers_done.wait(&self.mtx);
        self.readers = self.readers + 1;
        self.mtx.unlock();
    }

    fn read_unlock(self: *rwlock) void {
        self.mtx.lock();
        self.readers = self.readers - 1;
        if (self.readers == 0) { self.readers_done.signal(); }
        self.mtx.unlock();
    }

    fn write_lock(self: *rwlock) void {
        self.mtx.lock();
        self.pending_writers = self.pending_writers + 1;
        while (self.readers > 0 || self.writers > 0)
            self.readers_done.wait(&self.mtx);
        self.pending_writers = self.pending_writers - 1;
        self.writers = self.writers + 1;
        self.mtx.unlock();
    }

    fn write_unlock(self: *rwlock) void {
        self.mtx.lock();
        self.writers = self.writers - 1;
        if (self.pending_writers > 0) self.readers_done.broadcast();
        else self.writers_done.broadcast();
        self.mtx.unlock();
    }
}

// --- thread pool ---

istruc thread_pool {
    let mut threads: *thread_t;
    let mut count: i32;

    fn __construct__(thread_pool* self, i32 n, void*(void*)* fn_ref, void* arg, &memstr a) void {
        self.count   = n;
        self.threads = (thread_t*)a.mmap((u64)(sizeof(thread_t) * n));
        for (let mut i: i32 = 0; i < n; i = i + 1) {
            self.threads[i].__construct__();
            self.threads[i].spawn(fn_ref, arg);
        }
    }

    fn join_all(self: *thread_pool) void {
        for (let mut i: i32 = 0; i < self.count; i = i + 1)
            self.threads[i].join();
    }

    fn deinit(thread_pool* self, &memstr a) void { a.free(self.threads); }
}

} // thread
} // std
