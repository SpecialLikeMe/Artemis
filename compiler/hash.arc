// compiler/hash.arc — string hashing for the compiler's symbol tables.
//
// The tables this serves (analysis/scope.arc's sym_table, ir/context.arc's sv_map /
// st_map / sb_map) keep their insertion-ordered entry array exactly as it was. This
// only adds an *index* over that array, because several passes walk those arrays in
// order — `ctx.global_funcs`, `ctx.using_ns_map` and each scope's `alloca_ptrs` are all
// iterated by index — and reordering them would change the compiler's output.
//
// The index is an intrusive chain: `head[bucket]` is the newest entry index in that
// bucket and `next[i]` is the next older entry in the same bucket. Indices along a
// chain are therefore strictly decreasing, which is what makes the shadowing rule fall
// out for free: walking a chain from its head visits entries newest-first, the same
// order the old backwards linear scan used.

fn str_hash32(s: *i8) u32 {
    if (s == (i8*)0) { return 0u; }
    let mut h: u32= 2166136261u;          // FNV-1a offset basis
    let mut i: i32= 0;
    while (s[i] != 0) {
        h = h ^ (u32)(u8)s[i];
        h = h * 16777619u;                // FNV-1a prime
        i = i + 1;
    }
    return h;
}

// Smallest power of two >= n, floored at 64 so tiny tables do not rehash constantly.
fn hash_cap_for(n: i32) i32 {
    let mut c: i32= 64;
    while (c < n && c < 0x10000000) { c = c * 2; }
    return c;
}
