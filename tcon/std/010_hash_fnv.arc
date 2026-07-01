// Test: std.hash — FNV-1a hashing
extern std.hash;
extern i32 printf(i8* fmt, ...);

i32 main() {
    // FNV-1a: known hash of empty string = hash::FNV_OFFSET
    u64 h0 = hash::fnv_hash_bytes((u8*)0, (u64)0);
    if (h0 != hash::FNV_OFFSET) { printf("FAIL fnv empty\n"); return 1; }

    // FNV-1a: hash of single byte 0x00
    u8 zero = 0;
    u64 h1 = hash::fnv_hash_bytes(&zero, (u64)1);
    u64 expected = hash::FNV_OFFSET * hash::FNV_PRIME;
    if (h1 != expected) { printf("FAIL fnv zero byte\n"); return 2; }

    // FNV-1a string hash is deterministic
    u64 ha = hash::fnv_hash_str("hello");
    u64 hb = hash::fnv_hash_str("hello");
    if (ha != hb) { printf("FAIL fnv deterministic\n"); return 3; }

    // Different strings produce different hashes
    u64 hc = hash::fnv_hash_str("world");
    if (ha == hc) { printf("FAIL fnv collision\n"); return 4; }

    // FNV-32 on same data is deterministic
    u8 data[4];
    data[0] = 1; data[1] = 2; data[2] = 3; data[3] = 4;
    u32 r1 = hash::fnv_hash32_bytes(data, (u64)4);
    u32 r2 = hash::fnv_hash32_bytes(data, (u64)4);
    if (r1 != r2) { printf("FAIL fnv32 deterministic\n"); return 5; }

    // fnv32 differs for different data
    data[0] = 9;
    u32 r3 = hash::fnv_hash32_bytes(data, (u64)4);
    if (r1 == r3) { printf("FAIL fnv32 collision\n"); return 6; }

    return 0;
}
