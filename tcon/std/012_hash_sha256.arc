// Test: std.hash — SHA-256
extern  std.hash;
@unsafe extern fn printf(fmt: *i8, ...) i32;

pub @unsafe fn main() i32 {
    // SHA-256 of empty string:
    // e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    let mut d: std.hash.sha256_digest= std.hash.sha256_hash_str("");
    if (d.bytes[0] != 0xe3) { printf("FAIL sha256 empty[0]\n"); return 1; }
    if (d.bytes[1] != 0xb0) { printf("FAIL sha256 empty[1]\n"); return 2; }
    if (d.bytes[2] != 0xc4) { printf("FAIL sha256 empty[2]\n"); return 3; }
    if (d.bytes[3] != 0x42) { printf("FAIL sha256 empty[3]\n"); return 4; }
    if (d.bytes[31] != 0x55) { printf("FAIL sha256 empty[31]\n"); return 5; }

    // SHA-256 is deterministic
    let mut d2: std.hash.sha256_digest= std.hash.sha256_hash_str("");
    for (let mut i: i32 = 0; i < 32; i = i + 1) {
        if (d.bytes[i] != d2.bytes[i]) { printf("FAIL sha256 deterministic\n"); return 6; }
    }

    // Different inputs differ
    let mut d3: std.hash.sha256_digest= std.hash.sha256_hash_str("a");
    if (d.bytes[0] == d3.bytes[0] && d.bytes[1] == d3.bytes[1]) {
        printf("FAIL sha256 collision\n"); return 7;
    }

    return 0;
}
