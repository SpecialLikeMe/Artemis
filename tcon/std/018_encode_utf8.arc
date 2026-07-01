// Test: std.encode — UTF-8 decode/encode/validate/count
extern std.encode;
extern i32 printf(i8* fmt, ...);

i32 main() {
    // ASCII decode
    u8 ascii[3]; ascii[0] = 'A'; ascii[1] = 'B'; ascii[2] = 'C';
    u64 pos = 0;
    u32 cp = encode::utf8_decode_one(ascii, (u64)3, &pos);
    if (cp != 65u) { printf("FAIL decode ASCII\n"); return 1; }
    if (pos != 1) { printf("FAIL decode pos\n"); return 2; }

    // Encode ASCII back
    u8 enc[4];
    i32 n = encode::utf8_encode_one(65u, enc);
    if (n != 1 || enc[0] != 65) { printf("FAIL encode ASCII\n"); return 3; }

    // Validate valid ASCII string
    u8 valid[5]; valid[0]='h'; valid[1]='i'; valid[2]='!'; valid[3]=0; valid[4]=0;
    if (!encode::utf8_validate(valid, (u64)3)) { printf("FAIL validate valid\n"); return 4; }

    // Validate invalid sequence (continuation byte without lead)
    u8 invalid[2]; invalid[0] = 0x80u; invalid[1] = 0x41u;
    if (encode::utf8_validate(invalid, (u64)2)) { printf("FAIL validate invalid\n"); return 5; }

    // Count codepoints
    u8 str[4]; str[0]='a'; str[1]='b'; str[2]='c'; str[3]=0;
    i32 cnt = encode::utf8_count(str, (u64)3);
    if (cnt != 3) { printf("FAIL count\n"); return 6; }

    // Two-byte encode/decode round-trip (U+00E9 = é)
    i32 enc_n = encode::utf8_encode_one(0xE9u, enc);
    if (enc_n != 2) { printf("FAIL encode 2-byte len\n"); return 7; }
    pos = 0;
    u32 cp2 = encode::utf8_decode_one(enc, (u64)2, &pos);
    if (cp2 != 0xE9u) { printf("FAIL decode 2-byte\n"); return 8; }

    return 0;
}
