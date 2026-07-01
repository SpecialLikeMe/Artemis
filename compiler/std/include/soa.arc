// std.soa — Structure-of-Arrays data structures and generic SoA helpers.
// Each major container is mirrored as a SoA variant for cache-optimal access.
// soa.vec<T> stores each field of T in a separate flat array.
// Because Artemis does not yet have reflection, users express the SoA shape
// manually via the typed SoA variants below, or by composing soa.array<T>.

namespace std {
namespace soa {

// ---- Generic parallel-array wrapper ----
// soa.array<T> is simply a dynamic array of T where the user is expected to
// keep parallel arrays for each field they care about. This gives the same
// allocation pattern as a true SoA without requiring compiler reflection.

istruc array<T> {
    T*  data;
    i32 len;
    i32 cap;

    void __construct__(&self) { self.data=(T*)0; self.len=0; self.cap=0; }

    void reserve(&self, i32 n, &memstr a) {
        if (n <= self.cap) { return; }
        T* nd = (T*)a.mmap((u64)(sizeof(T) * n));
        for (i32 i = 0; i < self.len; i = i + 1) nd[i] = self.data[i];
        if (self.data != (T*)0) { a.deinit(self.data); }
        self.data = nd; self.cap = n;
    }

    void push(&self, T val, &memstr a) {
        if (self.len >= self.cap) {
            i32 nc = self.cap == 0 ? 8 : self.cap * 2;
            self.reserve(nc, a);
        }
        self.data[self.len] = val;
        self.len = self.len + 1;
    }

    void remove_at(&self, i32 i) {
        for (i32 j = i; j < self.len - 1; j = j + 1)
            self.data[j] = self.data[j + 1];
        self.len = self.len - 1;
    }

    T   at(&self, i32 i)    { return self.data[i]; }
    T*  ptr_at(&self, i32 i)      { return self.data + i; }
    i32 length(&self)       { return self.len; }
    bool is_empty(&self)    { return self.len == 0; }

    void swap(&self, i32 i, i32 j) {
        T tmp = self.data[i]; self.data[i] = self.data[j]; self.data[j] = tmp;
    }

    void deinit(&self, &memstr a) {
        if (self.data != (T*)0) { a.deinit(self.data); }
        self.data = (T*)0; self.len = 0; self.cap = 0;
    }
}

// ---- soa.vec2f — SoA of f32 x/y pairs (e.g. 2D positions) ----

istruc vec2f {
    array<f32> x;
    array<f32> y;
    i32        len;

    void __construct__(&self) { self.len = 0; }

    void push(&self, f32 xv, f32 yv, &memstr a) {
        self.x.push(xv, a);
        self.y.push(yv, a);
        self.len = self.len + 1;
    }

    void remove_at(&self, i32 i) {
        self.x.remove_at(i); self.y.remove_at(i); self.len = self.len - 1;
    }

    // Swap-erase (O(1) removal preserving density, does not preserve order)
    void swap_erase(&self, i32 i) {
        i32 last = self.len - 1;
        self.x.swap(i, last); self.y.swap(i, last);
        self.x.len = self.x.len - 1;
        self.y.len = self.y.len - 1;
        self.len = self.len - 1;
    }

    void deinit(&self, &memstr a) { self.x.deinit(a); self.y.deinit(a); self.len = 0; }
}

// ---- soa.vec3f — SoA of f32 x/y/z triples (e.g. 3D positions) ----

istruc vec3f {
    array<f32> x;
    array<f32> y;
    array<f32> z;
    i32        len;

    void __construct__(&self) { self.len = 0; }

    void push(&self, f32 xv, f32 yv, f32 zv, &memstr a) {
        self.x.push(xv, a); self.y.push(yv, a); self.z.push(zv, a);
        self.len = self.len + 1;
    }

    void remove_at(&self, i32 i) {
        self.x.remove_at(i); self.y.remove_at(i); self.z.remove_at(i);
        self.len = self.len - 1;
    }

    void swap_erase(&self, i32 i) {
        i32 last = self.len - 1;
        self.x.swap(i,last); self.y.swap(i,last); self.z.swap(i,last);
        self.x.len=self.x.len-1; self.y.len=self.y.len-1; self.z.len=self.z.len-1;
        self.len = self.len - 1;
    }

    void deinit(&self, &memstr a) { self.x.deinit(a); self.y.deinit(a); self.z.deinit(a); self.len=0; }
}

// ---- soa.particle — SoA for a typical game-particle system ----
// position (x,y,z), velocity (vx,vy,vz), lifetime, color (rgba packed u32)

istruc particle {
    array<f32> px; array<f32> py; array<f32> pz;
    array<f32> vx; array<f32> vy; array<f32> vz;
    array<f32> life;
    array<u32> color;
    i32        len;

    void __construct__(&self) { self.len = 0; }

    void push(&self, f32 x, f32 y, f32 z,
              f32 vx_, f32 vy_, f32 vz_,
              f32 life_, u32 col_, &memstr a) {
        self.px.push(x,a);   self.py.push(y,a);   self.pz.push(z,a);
        self.vx.push(vx_,a); self.vy.push(vy_,a); self.vz.push(vz_,a);
        self.life.push(life_,a); self.color.push(col_,a);
        self.len = self.len + 1;
    }

    void swap_erase(&self, i32 i) {
        i32 last = self.len - 1;
        self.px.swap(i,last); self.py.swap(i,last); self.pz.swap(i,last);
        self.vx.swap(i,last); self.vy.swap(i,last); self.vz.swap(i,last);
        self.life.swap(i,last); self.color.swap(i,last);
        self.px.len=self.px.len-1; self.py.len=self.py.len-1; self.pz.len=self.pz.len-1;
        self.vx.len=self.vx.len-1; self.vy.len=self.vy.len-1; self.vz.len=self.vz.len-1;
        self.life.len=self.life.len-1; self.color.len=self.color.len-1;
        self.len = self.len - 1;
    }

    // Integrate: advance positions by velocity * dt, decrement lifetimes, remove dead
    void tick(&self, f32 dt) {
        i32 i = 0;
        while (i < self.len) {
            self.px.data[i] = self.px.data[i] + self.vx.data[i] * dt;
            self.py.data[i] = self.py.data[i] + self.vy.data[i] * dt;
            self.pz.data[i] = self.pz.data[i] + self.vz.data[i] * dt;
            self.life.data[i] = self.life.data[i] - dt;
            if (self.life.data[i] <= 0.0) { self.swap_erase(i); }
            else { i = i + 1; }
        }
    }

    void deinit(&self, &memstr a) {
        self.px.deinit(a); self.py.deinit(a); self.pz.deinit(a);
        self.vx.deinit(a); self.vy.deinit(a); self.vz.deinit(a);
        self.life.deinit(a); self.color.deinit(a); self.len=0;
    }
}

// ---- soa.transform — SoA for transform components (ECS-style) ----
// position (x,y,z), scale (sx,sy,sz), rotation quaternion (qx,qy,qz,qw)

istruc transform {
    array<f32> px; array<f32> py; array<f32> pz;
    array<f32> sx; array<f32> sy; array<f32> sz;
    array<f32> qx; array<f32> qy; array<f32> qz; array<f32> qw;
    i32        len;

    void __construct__(&self) { self.len = 0; }

    void push_identity(&self, &memstr a) {
        self.px.push(0.0,a); self.py.push(0.0,a); self.pz.push(0.0,a);
        self.sx.push(1.0,a); self.sy.push(1.0,a); self.sz.push(1.0,a);
        self.qx.push(0.0,a); self.qy.push(0.0,a); self.qz.push(0.0,a); self.qw.push(1.0,a);
        self.len = self.len + 1;
    }

    void swap_erase(&self, i32 i) {
        i32 last = self.len - 1;
        self.px.swap(i,last); self.py.swap(i,last); self.pz.swap(i,last);
        self.sx.swap(i,last); self.sy.swap(i,last); self.sz.swap(i,last);
        self.qx.swap(i,last); self.qy.swap(i,last); self.qz.swap(i,last); self.qw.swap(i,last);
        self.px.len=self.px.len-1; self.py.len=self.py.len-1; self.pz.len=self.pz.len-1;
        self.sx.len=self.sx.len-1; self.sy.len=self.sy.len-1; self.sz.len=self.sz.len-1;
        self.qx.len=self.qx.len-1; self.qy.len=self.qy.len-1;
        self.qz.len=self.qz.len-1; self.qw.len=self.qw.len-1;
        self.len = self.len - 1;
    }

    void deinit(&self, &memstr a) {
        self.px.deinit(a); self.py.deinit(a); self.pz.deinit(a);
        self.sx.deinit(a); self.sy.deinit(a); self.sz.deinit(a);
        self.qx.deinit(a); self.qy.deinit(a); self.qz.deinit(a); self.qw.deinit(a);
        self.len=0;
    }
}

// ---- soa.kv<K,V> — SoA key-value store (parallel arrays for keys and values) ----

istruc kv<K, V> {
    array<K> keys;
    array<V> vals;
    i32      len;

    void __construct__(&self) { self.len = 0; }

    void push(&self, K k, V v, &memstr a) {
        self.keys.push(k, a); self.vals.push(v, a); self.len = self.len + 1;
    }

    void remove_at(&self, i32 i) {
        self.keys.remove_at(i); self.vals.remove_at(i); self.len = self.len - 1;
    }

    void swap_erase(&self, i32 i) {
        i32 last = self.len - 1;
        self.keys.swap(i,last); self.vals.swap(i,last);
        self.keys.len=self.keys.len-1; self.vals.len=self.vals.len-1;
        self.len = self.len - 1;
    }

    void deinit(&self, &memstr a) { self.keys.deinit(a); self.vals.deinit(a); self.len=0; }
}

// ---- soa.zip_each — iterate two parallel arrays simultaneously ----
// Usage: soa.zip_each(xs.data, ys.data, n, callback_fn);
// The callback receives (f32 x, f32 y, i32 index) — use function pointers.

} // soa
} // std
