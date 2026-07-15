// SMT claim: 100% low-level control — the language gives programmers unrestricted access
// to raw memory, pointers, casts, and bit manipulation.  The SMT does not block any of
// these operations; it merely annotates them (GOOD / UNKNOWN / BAD) and injects runtime
// guards where it cannot prove safety statically.  The programmer retains full control.
//
// Patterns exercised (all are SAFE at runtime; SMT emits no BAD verdicts here):
//   A — Raw pointer arithmetic and manual array traversal
//   B — void* / i8* casts and explicit byte-level access
//   C — Multi-level pointer indirection (i32**)
//   D — Bit manipulation (shift, mask, OR, XOR)
//   E — Explicit in-place struct mutation via pointer
//   F — Pointer comparison and sentinel-based iteration
extern i32 printf(i8* fmt, ...);

// ---- A: Raw pointer arithmetic ----
// UNKNOWN per dynamic step; SMT injects check at each dereference.
i32 ptr_sum(i32* start, i32 count) {
    i32 s = 0;
    i32* p = start;
    i32 i = 0;
    while (i < count) {
        s = s + (*p);   // UNKNOWN: pointer state = VALID but interval unknown
        p = p + 1;
        i = i + 1;
    }
    return s;
}

// ---- B: void* / i8* round-trip ----
// Write four bytes into a void* buffer and read back as i32.
i32 byte_roundtrip(i32 val) {
    i32 buf;
    void* vp = (void*)(&buf);
    i8* bp = (i8*)vp;
    // Write little-endian bytes manually (low-level direct access)
    bp[0] = (i8)(val & 0xFF);
    bp[1] = (i8)((val >> 8) & 0xFF);
    bp[2] = (i8)((val >> 16) & 0xFF);
    bp[3] = (i8)((val >> 24) & 0xFF);
    i32* ip = (i32*)vp;
    return (*ip);
}

// ---- C: Multi-level pointer indirection ----
void double_indirect_write(i32** pp, i32 val) {
    (*(*pp)) = val;   // GOOD: pp is &p, p is &x — both non-null (address-of)
}

// ---- D: Bit manipulation ----
u32 pack_nibbles(u32 a, u32 b, u32 c, u32 d) {
    return (a & 0xF) | ((b & 0xF) << 4) | ((c & 0xF) << 8) | ((d & 0xF) << 12);
}

u32 unpack_nibble(u32 packed, u32 which) {
    return (packed >> (which * 4)) & 0xF;
}

// ---- E: In-place struct mutation via pointer ----
struct Point { i32 x; i32 y; }

void translate(Point* p, i32 dx, i32 dy) {
    p.x = p.x + dx;
    p.y = p.y + dy;
}

// ---- F: In-place pointer writes and XOR bit-manipulation swap ----
void xor_swap(i32* a, i32* b) {
    (*a) = (*a) ^ (*b);
    (*b) = (*a) ^ (*b);
    (*a) = (*a) ^ (*b);
}

i32 main() {
    // A: raw pointer sum
    i32 data[6]; data[0]=1; data[1]=2; data[2]=3; data[3]=4; data[4]=5; data[5]=6;
    if (ptr_sum(data, 6) != 21) { printf("FAIL ptr_sum\n"); return 1; }
    if (ptr_sum(data, 3) != 6)  { printf("FAIL ptr_sum 3\n"); return 2; }

    // B: byte-level round-trip
    if (byte_roundtrip(0x1234) != 0x1234) { printf("FAIL byte_roundtrip\n"); return 3; }
    if (byte_roundtrip(0)       != 0)      { printf("FAIL byte_roundtrip 0\n"); return 4; }
    if (byte_roundtrip(-1)      != -1)     { printf("FAIL byte_roundtrip -1\n"); return 5; }

    // C: double indirection
    i32 x = 0;
    i32* p = &x;
    double_indirect_write(&p, 42);
    if (x != 42) { printf("FAIL double_indirect x=%d\n", x); return 6; }

    // D: nibble packing
    u32 packed = pack_nibbles(3, 7, 1, 0xF);
    if (unpack_nibble(packed, 0) != 3)    { printf("FAIL nibble 0\n"); return 7; }
    if (unpack_nibble(packed, 1) != 7)    { printf("FAIL nibble 1\n"); return 8; }
    if (unpack_nibble(packed, 2) != 1)    { printf("FAIL nibble 2\n"); return 9; }
    if (unpack_nibble(packed, 3) != 0xF)  { printf("FAIL nibble 3\n"); return 10; }

    // E: struct mutation via pointer
    Point pt; pt.x = 10; pt.y = 20;
    translate(&pt, 5, -3);
    if (pt.x != 15) { printf("FAIL translate x=%d\n", pt.x); return 11; }
    if (pt.y != 17) { printf("FAIL translate y=%d\n", pt.y); return 12; }

    // F: XOR swap and explicit write-through pointers
    i32 m = 5; i32 n = 9;
    xor_swap(&m, &n);
    if (m != 9 || n != 5) { printf("FAIL xor_swap m=%d n=%d\n", m, n); return 13; }
    // Write to array elements through direct pointer access
    i32 buf[4]; buf[0]=1; buf[1]=2; buf[2]=3; buf[3]=4;
    i32* pw = &buf[2];
    (*pw) = 99;        // write via pointer: buf[2] = 99
    if (buf[2] != 99) { printf("FAIL ptr_write buf2\n"); return 14; }
    if (buf[0]+buf[1]+buf[2]+buf[3] != 106) { printf("FAIL sum after write\n"); return 15; }

    return 0;
}
