// Test: std.fs — file istruc read/write, temp file
extern  std.fs;
@unsafe extern fn printf(fmt: *i8, ...) i32;

pub fn main() i32 {
    let mut path: *i8= "_arc_test_016.tmp";

    let mut w: std.fs.file;
    let mut ok: bool= w.open(path, "wb");
    if (!ok) { printf("FAIL open write\n"); return 1; }

    let mut msg: *i8= "hello fs";
    let mut written: bool= w.write_str(msg);
    if (!written) { printf("FAIL write_str\n"); return 2; }
    w.close();

    // Read back
    let mut r: std.fs.file;
    ok = r.open(path, "rb");
    if (!ok) { printf("FAIL open read\n"); return 3; }

    let mut sz: i64= r.size();
    if (sz != 8) { printf("FAIL size\n"); return 4; }

    let mut buf: [32]i8;
    let mut n: u64= r.read_bytes(buf, (u64)32);
    if (n != 8) { printf("FAIL read_bytes count\n"); return 5; }
    buf[n] = 0;

    if (buf[0] != 'h' || buf[4] != 'o') { printf("FAIL read content\n"); return 6; }
    r.close();

    // Delete the temp file
    unlink(path);

    let mut fp: *void= fopen(path, "rb");
    if (fp != (void*)0) { fclose(fp); printf("FAIL delete\n"); return 7; }

    return 0;
}
