// Test: std.hash — wyhash
extern std.hash;
extern i32 printf(i8* fmt, ...);

i32 main() {
    // wyhash is deterministic with same seed
    u64 h1 = hash::wyhash_hash_str("artemis", (u64)0);
    u64 h2 = hash::wyhash_hash_str("artemis", (u64)0);
    if (h1 != h2) { printf("FAIL wyhash deterministic\n"); return 1; }

    // Different strings differ
    u64 h3 = hash::wyhash_hash_str("compiler", (u64)0);
    if (h1 == h3) { printf("FAIL wyhash collision\n"); return 2; }

    // Different seeds produce different hashes
    u64 h4 = hash::wyhash_hash_str("artemis", (u64)1);
    if (h1 == h4) { printf("FAIL wyhash seed\n"); return 3; }

    // hash::wyhash_hash_i64 deterministic
    u64 r1 = hash::wyhash_hash_i64((i64)42, (u64)0);
    u64 r2 = hash::wyhash_hash_i64((i64)42, (u64)0);
    if (r1 != r2) { printf("FAIL wyhash_i64 deterministic\n"); return 4; }

    // Different i64 values differ
    u64 r3 = hash::wyhash_hash_i64((i64)43, (u64)0);
    if (r1 == r3) { printf("FAIL wyhash_i64 collision\n"); return 5; }

    return 0;
}
