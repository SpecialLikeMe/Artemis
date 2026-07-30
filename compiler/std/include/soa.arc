// std.soa — Structure-of-Arrays data structures and generic SoA helpers.
// Access as: std.soa.make_soa(...), std.soa.soa_layout, etc.

namespace std {
namespace soa {

// ---- Generic parallel-array wrapper ----
// soa.array<T> is simply a dynamic array of T where the user is expected to
// keep parallel arrays for each field they care about. This gives the same
// allocation pattern as a true SoA without requiring compiler reflection.

istruc array<T> {
    let mut data: *T;
    let mut len: i32;
    let mut cap: i32;

    fn __construct__(self: *array) void { self.data=(T*)0; self.len=0; self.cap=0; }

    fn reserve(array* self, i32 n, &memstr a) void {
        if (n <= self.cap) { return; }
        let mut nd: *T= (T*)a.mmap((u64)(sizeof(T) * n)) catch |e| { };
        for (let mut i: i32 = 0; i < self.len; i = i + 1) nd[i] = self.data[i];
        if (self.data != (T*)0) { a.free(self.data) catch |e| { }; }
        self.data = nd; self.cap = n;
    }

    fn push(array* self, T val, &memstr a) void {
        if (self.len >= self.cap) {
            let mut nc: i32= self.cap == 0 ? 8 : self.cap * 2;
            self.reserve(nc, a);
        }
        self.data[self.len] = val;
        self.len = self.len + 1;
    }

    fn remove_at(self: *array, i: i32) void {
        for (let mut j: i32 = i; j < self.len - 1; j = j + 1)
            self.data[j] = self.data[j + 1];
        self.len = self.len - 1;
    }

    fn at(self: *array, i: i32) T    { return self.data[i]; }
    fn ptr_at(self: *array, i: i32) *T      { return self.data + i; }
    fn length(self: *array) i32       { return self.len; }
    fn is_empty(self: *array) bool    { return self.len == 0; }

    fn swap(self: *array, i: i32, j: i32) void {
        let mut tmp: T= self.data[i]; self.data[i] = self.data[j]; self.data[j] = tmp;
    }

    fn deinit(array* self, &memstr a) void {
        if (self.data != (T*)0) { a.free(self.data) catch |e| { }; }
        self.data = (T*)0; self.len = 0; self.cap = 0;
    }
}

// ---- soa.vec2f — SoA of f32 x/y pairs (e.g. 2D positions) ----

istruc vec2f {
    let mut x: array<f32>;
    let mut y: array<f32>;
    let mut len: i32;

    fn __construct__(self: *vec2f) void { self.len = 0; }

    fn push(vec2f* self, f32 xv, f32 yv, &memstr a) void {
        self.x.push(xv, a);
        self.y.push(yv, a);
        self.len = self.len + 1;
    }

    fn remove_at(self: *vec2f, i: i32) void {
        self.x.remove_at(i); self.y.remove_at(i); self.len = self.len - 1;
    }

    // Swap-erase (O(1) removal preserving density, does not preserve order)
    fn swap_erase(self: *vec2f, i: i32) void {
        let mut last: i32= self.len - 1;
        self.x.swap(i, last); self.y.swap(i, last);
        self.x.len = self.x.len - 1;
        self.y.len = self.y.len - 1;
        self.len = self.len - 1;
    }

    fn deinit(vec2f* self, &memstr a) void { self.x.deinit(a); self.y.deinit(a); self.len = 0; }
}

// ---- soa.vec3f — SoA of f32 x/y/z triples (e.g. 3D positions) ----

istruc vec3f {
    let mut x: array<f32>;
    let mut y: array<f32>;
    let mut z: array<f32>;
    let mut len: i32;

    fn __construct__(self: *vec3f) void { self.len = 0; }

    fn push(vec3f* self, f32 xv, f32 yv, f32 zv, &memstr a) void {
        self.x.push(xv, a); self.y.push(yv, a); self.z.push(zv, a);
        self.len = self.len + 1;
    }

    fn remove_at(self: *vec3f, i: i32) void {
        self.x.remove_at(i); self.y.remove_at(i); self.z.remove_at(i);
        self.len = self.len - 1;
    }

    fn swap_erase(self: *vec3f, i: i32) void {
        let mut last: i32= self.len - 1;
        self.x.swap(i,last); self.y.swap(i,last); self.z.swap(i,last);
        self.x.len=self.x.len-1; self.y.len=self.y.len-1; self.z.len=self.z.len-1;
        self.len = self.len - 1;
    }

    fn deinit(vec3f* self, &memstr a) void { self.x.deinit(a); self.y.deinit(a); self.z.deinit(a); self.len=0; }
}

// ---- soa.particle — SoA for a typical game-particle system ----
// position (x,y,z), velocity (vx,vy,vz), lifetime, color (rgba packed u32)

istruc particle {
    let mut px: array<f32>; let mut py: array<f32>; let mut pz: array<f32>;
    let mut vx: array<f32>; let mut vy: array<f32>; let mut vz: array<f32>;
    let mut life: array<f32>;
    let mut color: array<u32>;
    let mut len: i32;

    fn __construct__(self: *particle) void { self.len = 0; }

    fn push(particle* self, f32 x, f32 y, f32 z,
              f32 vx_, f32 vy_, f32 vz_,
              f32 life_, u32 col_, &memstr a) void {
        self.px.push(x,a);   self.py.push(y,a);   self.pz.push(z,a);
        self.vx.push(vx_,a); self.vy.push(vy_,a); self.vz.push(vz_,a);
        self.life.push(life_,a); self.color.push(col_,a);
        self.len = self.len + 1;
    }

    fn swap_erase(self: *particle, i: i32) void {
        let mut last: i32= self.len - 1;
        self.px.swap(i,last); self.py.swap(i,last); self.pz.swap(i,last);
        self.vx.swap(i,last); self.vy.swap(i,last); self.vz.swap(i,last);
        self.life.swap(i,last); self.color.swap(i,last);
        self.px.len=self.px.len-1; self.py.len=self.py.len-1; self.pz.len=self.pz.len-1;
        self.vx.len=self.vx.len-1; self.vy.len=self.vy.len-1; self.vz.len=self.vz.len-1;
        self.life.len=self.life.len-1; self.color.len=self.color.len-1;
        self.len = self.len - 1;
    }

    // Integrate: advance positions by velocity * dt, decrement lifetimes, remove dead
    fn tick(self: *particle, dt: f32) void {
        let mut i: i32= 0;
        while (i < self.len) {
            self.px.data[i] = self.px.data[i] + self.vx.data[i] * dt;
            self.py.data[i] = self.py.data[i] + self.vy.data[i] * dt;
            self.pz.data[i] = self.pz.data[i] + self.vz.data[i] * dt;
            self.life.data[i] = self.life.data[i] - dt;
            if (self.life.data[i] <= 0.0) { self.swap_erase(i); }
            else { i = i + 1; }
        }
    }

    fn deinit(particle* self, &memstr a) void {
        self.px.deinit(a) catch |e| { }; self.py.deinit(a); self.pz.deinit(a);
        self.vx.deinit(a) catch |e| { }; self.vy.deinit(a); self.vz.deinit(a);
        self.life.deinit(a) catch |e| { }; self.color.deinit(a); self.len=0;
    }
}

// ---- soa.transform — SoA for transform components (ECS-style) ----
// position (x,y,z), scale (sx,sy,sz), rotation quaternion (qx,qy,qz,qw)

istruc transform {
    let mut px: array<f32>; let mut py: array<f32>; let mut pz: array<f32>;
    let mut sx: array<f32>; let mut sy: array<f32>; let mut sz: array<f32>;
    let mut qx: array<f32>; let mut qy: array<f32>; let mut qz: array<f32>; let mut qw: array<f32>;
    let mut len: i32;

    fn __construct__(self: *transform) void { self.len = 0; }

    fn push_identity(transform* self, &memstr a) void {
        self.px.push(0.0,a); self.py.push(0.0,a); self.pz.push(0.0,a);
        self.sx.push(1.0,a); self.sy.push(1.0,a); self.sz.push(1.0,a);
        self.qx.push(0.0,a); self.qy.push(0.0,a); self.qz.push(0.0,a); self.qw.push(1.0,a);
        self.len = self.len + 1;
    }

    fn swap_erase(self: *transform, i: i32) void {
        let mut last: i32= self.len - 1;
        self.px.swap(i,last); self.py.swap(i,last); self.pz.swap(i,last);
        self.sx.swap(i,last); self.sy.swap(i,last); self.sz.swap(i,last);
        self.qx.swap(i,last); self.qy.swap(i,last); self.qz.swap(i,last); self.qw.swap(i,last);
        self.px.len=self.px.len-1; self.py.len=self.py.len-1; self.pz.len=self.pz.len-1;
        self.sx.len=self.sx.len-1; self.sy.len=self.sy.len-1; self.sz.len=self.sz.len-1;
        self.qx.len=self.qx.len-1; self.qy.len=self.qy.len-1;
        self.qz.len=self.qz.len-1; self.qw.len=self.qw.len-1;
        self.len = self.len - 1;
    }

    fn deinit(transform* self, &memstr a) void {
        self.px.deinit(a) catch |e| { }; self.py.deinit(a); self.pz.deinit(a);
        self.sx.deinit(a) catch |e| { }; self.sy.deinit(a); self.sz.deinit(a);
        self.qx.deinit(a) catch |e| { }; self.qy.deinit(a); self.qz.deinit(a); self.qw.deinit(a);
        self.len=0;
    }
}

// ---- soa.kv<K,V> — SoA key-value store (parallel arrays for keys and values) ----

istruc kv<K, V> {
    let mut keys: array<K>;
    let mut vals: array<V>;
    let mut len: i32;

    fn __construct__(self: *kv) void { self.len = 0; }

    fn push(kv* self, K k, V v, &memstr a) void {
        self.keys.push(k, a); self.vals.push(v, a); self.len = self.len + 1;
    }

    fn remove_at(self: *kv, i: i32) void {
        self.keys.remove_at(i); self.vals.remove_at(i); self.len = self.len - 1;
    }

    fn swap_erase(self: *kv, i: i32) void {
        let mut last: i32= self.len - 1;
        self.keys.swap(i,last); self.vals.swap(i,last);
        self.keys.len=self.keys.len-1; self.vals.len=self.vals.len-1;
        self.len = self.len - 1;
    }

    fn deinit(kv* self, &memstr a) void { self.keys.deinit(a); self.vals.deinit(a); self.len=0; }
}

// ---- soa.zip_each — iterate two parallel arrays simultaneously ----
// Usage: soa.zip_each(xs.data, ys.data, n, callback_fn);
// The callback receives (f32 x, f32 y, i32 index) — use function pointers.

// ---- make_soa: type_info-driven AoS → SoA transposition ----
//
// Given:
//   - src:        void* pointing to an array of `count` structs, each of
//                 byte size described by ifo.size
//   - info:       type_info* from @typeinfo(YourType) — carries field metadata
//   - count:      number of elements in the source array
//   - scratch:    &memstr allocator used for the intermediate SoA block
//
// Returns a soa_layout whose `data` field is a heap-allocated block (via
// scratch) arranged as field_count contiguous flat arrays, one per field.
// soa_layout.field_ptrs[i] points at the flat array for field i.
// The source (src) is NOT modified.
//
// Layout of the returned block:
//   [ field0[0..count-1] | pad | field1[0..count-1] | pad | ... ]
//
// field_ptrs[] give the start address of each field's array within that block.

@unsafe extern fn memcpy(dst: *void, src: *void, n: u64) *void;

// Descriptor of a transposed SoA block.
comptime i32 SOA_MAX_FIELDS = 64;

istruc soa_layout {
    let mut block: *void;                        // raw allocation (pass to allocator to free)
    let mut block_size: u64;                   // total byte size of block
    let mut field_ptrs: [SOA_MAX_FIELDS]*void;   // field_ptrs[i] → flat array for field i
    let mut field_count: i32;                  // number of fields transposed
    let mut element_count: i32;                // number of elements per field array
}

// Transpose an array-of-structs into struct-of-arrays layout.
//
// `info` is the `@typeinfo(T)` of the element type. type_info is an ADT enum, so
// the struct metadata (field table, element size) lives in the Struct/Istruc
// variant payload rather than on type_info itself.
fn make_soa(src: *void, info: *type_info, count: i32, scratch: &memstr) soa_layout {
    @unsafe {
        let mut layout: soa_layout;
        layout.field_count   = 0;
        layout.element_count = count;
        layout.block         = (void*)0;
        layout.block_size    = 0;
    
        if (info == (type_info*)0 || count <= 0 || src == (void*)0) {
            return layout;
        }
    
        // Only aggregates have a field table; anything else has no SoA form.
        let mut fields: *type_info_field= (type_info_field*)0;
        let mut field_count: i32= 0;
        let mut elem_size: i64= 0;
        // ADT variant payloads are flattened into the variant's fields, so each
        // payload struct member binds as its own name.
        //   Struct(name, fields, field_count, size_bytes, align_bytes, is_tuple, is_packed)
        //   Istruc(name, fields, field_count, methods, method_count,
        //          interfaces, interface_count, size_bytes, align_bytes)
        match (*info) {
            type_info::Struct(s_name, s_fields, s_fcount, s_size, s_align, s_tuple, s_packed) => {
                fields      = s_fields;
                field_count = (i32)s_fcount;
                elem_size   = s_size;
            },
            type_info::Istruc(i_name, i_fields, i_fcount, i_meths, i_mcount,
                              i_ifaces, i_icount, i_size, i_align) => {
                fields      = i_fields;
                field_count = (i32)i_fcount;
                elem_size   = i_size;
            },
            _ => { return layout; },
        }
    
        if (fields == (type_info_field*)0 || field_count <= 0 || elem_size <= 0) {
            return layout;
        }
        if (field_count > SOA_MAX_FIELDS) {
            return layout;
        }
        layout.field_count = field_count;
    
        // Total allocation: sum of (field_size * count) per field, each row rounded up
        // to 16 bytes so every field array starts SIMD-aligned.
        let mut total: u64= 0;
        for (let mut f: i32 = 0; f < field_count; f = f + 1) {
            let mut row_bytes: u64= (u64)fields[f].size * (u64)count;
            row_bytes = (row_bytes + 15u) & ~15u;
            total = total + row_bytes;
        }
    
        let mut block: *u8= (u8*)scratch.mmap(total) catch |e| { };
        if (block == (u8*)0) {
            layout.field_count = 0;
            return layout;
        }
        layout.block      = (void*)block;
        layout.block_size = total;
    
        // Assign field_ptrs[] and zero each row.
        let mut offset: u64= 0;
        for (let mut f: i32 = 0; f < field_count; f = f + 1) {
            layout.field_ptrs[f] = (void*)(block + offset);
            let mut row_bytes: u64= ((u64)fields[f].size * (u64)count + 15u) & ~15u;
            for (let mut b: u64 = 0; b < row_bytes; b = b + 1) block[offset + b] = (u8)0;
            offset = offset + row_bytes;
        }
    
        // Scatter: copy each element's fields into the matching flat array.
        let mut src_bytes: *u8= (u8*)src;
        for (let mut elem: i32 = 0; elem < count; elem = elem + 1) {
            let mut elem_ptr: *u8= src_bytes + (i64)elem * elem_size;
            for (let mut f: i32 = 0; f < field_count; f = f + 1) {
                let mut fsz: i32= fields[f].size;
                let mut dst_row: *u8= (u8*)layout.field_ptrs[f];
                memcpy((void*)(dst_row + (i64)elem * (i64)fsz),
                       (void*)(elem_ptr + fields[f].offset), (u64)fsz);
            }
        }
    
        return layout;
    }
}
} // soa
} // std
