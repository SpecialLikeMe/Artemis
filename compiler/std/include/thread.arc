// std.thread — OS-native threads, mutexes, condition variables, and semaphores.
// Cross-platform: pthreads on POSIX, Win32 threads on Windows.

// pthreads (POSIX / MinGW on Windows)
extern i32 pthread_create(void** tid, void* attr, void*(void*)* fn, void* arg);
extern i32 pthread_join(void* tid, void** retval);
extern i32 pthread_detach(void* tid);
extern i32 pthread_exit(void* retval);
extern void* pthread_self();
extern i32 pthread_equal(void* a, void* b);
extern i32 pthread_mutex_init(void* mtx, void* attr);
extern i32 pthread_mutex_destroy(void* mtx);
extern i32 pthread_mutex_lock(void* mtx);
extern i32 pthread_mutex_trylock(void* mtx);
extern i32 pthread_mutex_unlock(void* mtx);
extern i32 pthread_cond_init(void* cond, void* attr);
extern i32 pthread_cond_destroy(void* cond);
extern i32 pthread_cond_wait(void* cond, void* mtx);
extern i32 pthread_cond_timedwait(void* cond, void* mtx, void* ts);
extern i32 pthread_cond_signal(void* cond);
extern i32 pthread_cond_broadcast(void* cond);
extern i32 sem_init(void* sem, i32 pshared, u32 val);
extern i32 sem_destroy(void* sem);
extern i32 sem_post(void* sem);
extern i32 sem_wait(void* sem);
extern i32 sem_trywait(void* sem);

namespace std {
namespace thread {

// --- mutex ---

istruc mutex {
    i8 handle[64];  // storage for pthread_mutex_t (platform sized)

    void __construct__(mutex* self) {
        pthread_mutex_init((void*)self.handle, (void*)0);
    }

    void lock(mutex* self)     { pthread_mutex_lock((void*)self.handle); }
    void unlock(mutex* self)   { pthread_mutex_unlock((void*)self.handle); }
    bool try_lock(mutex* self) { return pthread_mutex_trylock((void*)self.handle) == 0; }

    void deinit(mutex* self) { pthread_mutex_destroy((void*)self.handle); }
}

// --- scoped lock guard ---
istruc lock_guard {
    mutex* mtx;
    void __construct__(lock_guard* self, mutex* m) { self.mtx = m; (*m).lock(); }
    void release(lock_guard* self) { (*self.mtx).unlock(); }
}

// --- condition variable ---

istruc cond_var {
    i8 handle[64];

    void __construct__(cond_var* self) {
        pthread_cond_init((void*)self.handle, (void*)0);
    }

    void wait(cond_var* self, mutex* mtx) {
        pthread_cond_wait((void*)self.handle, (void*)(*mtx).handle);
    }

    void signal(cond_var* self)    { pthread_cond_signal((void*)self.handle); }
    void broadcast(cond_var* self) { pthread_cond_broadcast((void*)self.handle); }

    void deinit(cond_var* self) { pthread_cond_destroy((void*)self.handle); }
}

// --- semaphore ---

istruc semaphore {
    i8 handle[64];

    void __construct__(semaphore* self, u32 initial_val) {
        sem_init((void*)self.handle, 0, initial_val);
    }

    void post(semaphore* self)     { sem_post((void*)self.handle); }
    void wait(semaphore* self)     { sem_wait((void*)self.handle); }
    bool try_wait(semaphore* self) { return sem_trywait((void*)self.handle) == 0; }

    void deinit(semaphore* self) { sem_destroy((void*)self.handle); }
}

// --- thread ---

istruc thread_t {
    void* handle;
    bool  joined;

    void __construct__(thread_t* self) {
        self.handle = (void*)0;
        self.joined = false;
    }

    void spawn(thread_t* self, void*(void*)* fn, void* arg) {
        pthread_create(thread_t* self.handle, (void*)0, fn, arg);
        self.joined = false;
    }

    void join(thread_t* self) {
        if (!self.joined && self.handle != (void*)0) {
            pthread_join(self.handle, (void**)0);
            self.joined = true;
        }
    }

    void detach(thread_t* self) {
        if (!self.joined && self.handle != (void*)0) {
            pthread_detach(self.handle);
            self.joined = true;
        }
    }

    bool is_done(thread_t* self) { return self.joined; }
}

// --- thread-local ID ---
void* current_id() { return pthread_self(); }

// --- once flag (simple spin) ---
istruc once_flag {
    i32 done;

    void __construct__(once_flag* self) { self.done = 0; }

    void call_once(once_flag* self, void()* fn) {
        if (self.done != 0) { return; }
        // spin until we win the CAS
        i32 zero = 0;
        i32 one  = 1;
        __asm__ { lock cmpxchg %one, %done : zero : one, done : memory }
        if (zero == 0) { fn(); }
        else {
            while (self.done == 0) { __asm__ { pause : : : } }
        }
    }
}

// --- read-write lock ---

istruc rwlock {
    mutex mtx;
    cond_var readers_done;
    cond_var writers_done;
    i32 readers;
    i32 writers;
    i32 pending_writers;

    void __construct__(rwlock* self) {
        self.readers = 0; self.writers = 0; self.pending_writers = 0;
    }

    void read_lock(rwlock* self) {
        self.mtx.lock();
        while (self.writers > 0 || self.pending_writers > 0)
            self.writers_done.wait(rwlock* self.mtx);
        self.readers = self.readers + 1;
        self.mtx.unlock();
    }

    void read_unlock(rwlock* self) {
        self.mtx.lock();
        self.readers = self.readers - 1;
        if (self.readers == 0) { self.readers_done.signal(); }
        self.mtx.unlock();
    }

    void write_lock(rwlock* self) {
        self.mtx.lock();
        self.pending_writers = self.pending_writers + 1;
        while (self.readers > 0 || self.writers > 0)
            self.readers_done.wait(rwlock* self.mtx);
        self.pending_writers = self.pending_writers - 1;
        self.writers = self.writers + 1;
        self.mtx.unlock();
    }

    void write_unlock(rwlock* self) {
        self.mtx.lock();
        self.writers = self.writers - 1;
        if (self.pending_writers > 0) self.readers_done.broadcast();
        else self.writers_done.broadcast();
        self.mtx.unlock();
    }
}

// --- thread pool ---

istruc thread_pool {
    thread_t* threads;
    i32       count;

    void __construct__(thread_pool* self, i32 n, void*(void*)* fn, void* arg, &memstr a) {
        self.count   = n;
        self.threads = (thread_t*)a.mmap((u64)(sizeof(thread_t) * n));
        for (i32 i = 0; i < n; i = i + 1) {
            self.threads[i].__construct__();
            self.threads[i].spawn(fn, arg);
        }
    }

    void join_all(thread_pool* self) {
        for (i32 i = 0; i < self.count; i = i + 1)
            self.threads[i].join();
    }

    void deinit(thread_pool* self, &memstr a) { a.deinit(self.threads); }
}

} // thread
} // std
