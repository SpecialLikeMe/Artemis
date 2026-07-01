// Test: std.fs — file istruc read/write, temp file
extern std.fs;
extern i32 printf(i8* fmt, ...);

i32 main() {
    i8* path = "_arc_test_016.tmp";

    file w;
    bool ok = w.open(path, "wb");
    if (!ok) { printf("FAIL open write\n"); return 1; }

    i8* msg = "hello fs";
    bool written = w.write_str(msg);
    if (!written) { printf("FAIL write_str\n"); return 2; }
    w.close();

    // Read back
    file r;
    ok = r.open(path, "rb");
    if (!ok) { printf("FAIL open read\n"); return 3; }

    i64 sz = r.size();
    if (sz != 8) { printf("FAIL size\n"); return 4; }

    i8 buf[32];
    u64 n = r.read_bytes(buf, (u64)32);
    if (n != 8) { printf("FAIL read_bytes count\n"); return 5; }
    buf[n] = 0;

    if (buf[0] != 'h' || buf[4] != 'o') { printf("FAIL read content\n"); return 6; }
    r.close();

    // Delete the temp file
    unlink(path);

    void* fp = fopen(path, "rb");
    if (fp != (void*)0) { fclose(fp); printf("FAIL delete\n"); return 7; }

    return 0;
}
