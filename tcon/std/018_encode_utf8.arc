// Test: std.encode — UTF-8 decode/encode/validate/count
extern  std.encode;
@unsafe extern fn printf(fmt: *i8, ...) i32;

pub @unsafe fn main() i32 {
    // ASCII decode
    let mut ascii: [3]u8; ascii[0] = 'A'; ascii[1] = 'B'; ascii[2] = 'C';
    let mut pos: u64= 0;
    let mut cp: u32= std.encode.utf8_decode_one(ascii, (u64)3, &pos);
    if (cp != 65u) { printf("FAIL decode ASCII\n"); return 1; }
    if (pos != 1) { printf("FAIL decode pos\n"); return 2; }

    // Encode ASCII back
    let mut enc: [4]u8;
    let mut n: i32= std.encode.utf8_encode_one(65u, enc);
    if (n != 1 || enc[0] != 65) { printf("FAIL encode ASCII\n"); return 3; }

    // Validate valid ASCII string
    let mut valid: [5]u8; valid[0]='h'; valid[1]='i'; valid[2]='!'; valid[3]=0; valid[4]=0;
    if (!std.encode.utf8_validate(valid, (u64)3)) { printf("FAIL validate valid\n"); return 4; }

    // Validate invalid sequence (continuation byte without lead)
    let mut invalid: [2]u8; invalid[0] = 0x80u; invalid[1] = 0x41u;
    if (std.encode.utf8_validate(invalid, (u64)2)) { printf("FAIL validate invalid\n"); return 5; }

    // Count codepoints
    let mut str: [4]u8; str[0]='a'; str[1]='b'; str[2]='c'; str[3]=0;
    let mut cnt: i32= std.encode.utf8_count(str, (u64)3);
    if (cnt != 3) { printf("FAIL count\n"); return 6; }

    // Two-byte encode/decode round-trip (U+00E9 = é)
    let mut enc_n: i32= std.encode.utf8_encode_one(0xE9u, enc);
    if (enc_n != 2) { printf("FAIL encode 2-byte len\n"); return 7; }
    pos = 0;
    let mut cp2: u32= std.encode.utf8_decode_one(enc, (u64)2, &pos);
    if (cp2 != 0xE9u) { printf("FAIL decode 2-byte\n"); return 8; }

    return 0;
}
