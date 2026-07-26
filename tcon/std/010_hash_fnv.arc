// Test: std.hash — FNV-1a hashing
extern  std.hash;
@unsafe extern fn printf(fmt: *i8, ...) i32;

pub @unsafe fn main() i32 {
    // FNV-1a: known hash of empty string = std.hash.FNV_OFFSET
    let mut h0: u64= std.hash.fnv_hash_bytes((u8*)0, (u64)0);
    if (h0 != std.hash.FNV_OFFSET) { printf("FAIL fnv empty\n"); return 1; }

    // FNV-1a: hash of single byte 0x00
    let mut zero: u8= 0;
    let mut h1: u64= std.hash.fnv_hash_bytes(&zero, (u64)1);
    let mut expected: u64= std.hash.FNV_OFFSET * std.hash.FNV_PRIME;
    if (h1 != expected) { printf("FAIL fnv zero byte\n"); return 2; }

    // FNV-1a string hash is deterministic
    let mut ha: u64= std.hash.fnv_hash_str("hello");
    let mut hb: u64= std.hash.fnv_hash_str("hello");
    if (ha != hb) { printf("FAIL fnv deterministic\n"); return 3; }

    // Different strings produce different hashes
    let mut hc: u64= std.hash.fnv_hash_str("world");
    if (ha == hc) { printf("FAIL fnv collision\n"); return 4; }

    // FNV-32 on same data is deterministic
    let mut data: [4]u8;
    data[0] = 1; data[1] = 2; data[2] = 3; data[3] = 4;
    let mut r1: u32= std.hash.fnv_hash32_bytes(data, (u64)4);
    let mut r2: u32= std.hash.fnv_hash32_bytes(data, (u64)4);
    if (r1 != r2) { printf("FAIL fnv32 deterministic\n"); return 5; }

    // fnv32 differs for different data
    data[0] = 9;
    let mut r3: u32= std.hash.fnv_hash32_bytes(data, (u64)4);
    if (r1 == r3) { printf("FAIL fnv32 collision\n"); return 6; }

    return 0;
}
