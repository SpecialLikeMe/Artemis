// std.encode — UTF-8, UTF-16, UTF-32 validation, codepoint decoding, string types.

namespace std {
namespace encode {

// --- UTF-8 ---

namespace utf8 {

// Decode one UTF-8 codepoint from buf[0..], return codepoint and advance *pos.
u32 decode_one(u8* buf, u64 len, u64* pos) {
    u64 i = (*pos);
    if (i >= len) { return 0xFFFD; }
    u8 b0 = buf[i];
    if (b0 < 0x80) { (*pos) = i + 1; return (u32)b0; }
    if (b0 < 0xC0) { (*pos) = i + 1; return 0xFFFD; }  // continuation byte
    u32 cp; u32 extra;
    if (b0 < 0xE0)      { cp = (u32)(b0 & 0x1F); extra = 1; }
    else if (b0 < 0xF0) { cp = (u32)(b0 & 0x0F); extra = 2; }
    else                 { cp = (u32)(b0 & 0x07); extra = 3; }
    for (u32 j = 0; j < extra; j = j + 1) {
        i = i + 1;
        if (i >= len) { (*pos) = i; return 0xFFFD; }
        u8 b = buf[i];
        if ((b & 0xC0) != 0x80) { (*pos) = i; return 0xFFFD; }
        cp = (cp << 6) | (u32)(b & 0x3F);
    }
    (*pos) = i + 1;
    return cp;
}

// Encode one codepoint into buf; return bytes written (1-4).
i32 encode_one(u32 cp, u8* buf) {
    if (cp < 0x80)    { buf[0] = (u8)cp; return 1; }
    if (cp < 0x800)   { buf[0] = (u8)(0xC0|(cp>>6)); buf[1]=(u8)(0x80|(cp&0x3F)); return 2; }
    if (cp < 0x10000) {
        buf[0]=(u8)(0xE0|(cp>>12)); buf[1]=(u8)(0x80|((cp>>6)&0x3F));
        buf[2]=(u8)(0x80|(cp&0x3F)); return 3;
    }
    buf[0]=(u8)(0xF0|(cp>>18)); buf[1]=(u8)(0x80|((cp>>12)&0x3F));
    buf[2]=(u8)(0x80|((cp>>6)&0x3F)); buf[3]=(u8)(0x80|(cp&0x3F)); return 4;
}

// Validate: returns true if all bytes are valid UTF-8.
bool validate(u8* buf, u64 len) {
    u64 i = 0;
    while (i < len) {
        u64 prev = i;
        u32 cp = decode_one(buf, len, &i);
        if (cp == 0xFFFD && i == prev + 1) { return false; }
    }
    return true;
}

// Count codepoints in a UTF-8 string.
i32 count(u8* buf, u64 len) {
    i32 n = 0; u64 i = 0;
    while (i < len) { decode_one(buf, len, &i); n = n + 1; }
    return n;
}

// --- UTF-8 string istruc ---
istruc string {
    u8* data;
    u64 byte_len;
    u64 cap;

    void __construct__(&self, i8* cstr, &memstr a) {
        u64 n = 0;
        while (cstr[n] != 0) { n = n + 1; }
        self.byte_len = n;
        self.cap      = n + 1;
        self.data     = (u8*)a.mmap(self.cap);
        for (u64 i = 0; i < n; i = i + 1) self.data[i] = (u8)cstr[i];
        self.data[n] = 0;
    }

    void __construct__(&self) { self.data=(u8*)0; self.byte_len=0; self.cap=0; }

    i32  len_bytes(&self)  { return (i32)self.byte_len; }
    i32  len_chars(&self)  { return count(self.data, self.byte_len); }
    u8*  raw(&self)        { return self.data; }
    i8*  c_str(&self)      { return (i8*)self.data; }
    bool is_valid(&self)   { return validate(self.data, self.byte_len); }

    bool eq(&self, string* o) {
        if (self.byte_len != (*o).byte_len) { return false; }
        for (u64 i = 0; i < self.byte_len; i = i + 1)
            if (self.data[i] != (*o).data[i]) { return false; }
        return true;
    }

    void append(&self, string* o, &memstr a) {
        u64 new_len = self.byte_len + (*o).byte_len;
        if (new_len + 1 > self.cap) {
            u8* nd = (u8*)a.mmap(new_len + 1);
            for (u64 i = 0; i < self.byte_len; i = i + 1) nd[i] = self.data[i];
            if (self.data != (u8*)0) a.deinit(self.data);
            self.data = nd; self.cap = new_len + 1;
        }
        for (u64 i = 0; i < (*o).byte_len; i = i + 1)
            self.data[self.byte_len + i] = (*o).data[i];
        self.byte_len = new_len;
        self.data[new_len] = 0;
    }

    void deinit(&self, &memstr a) {
        if (self.data != (u8*)0) { a.deinit(self.data); }
        self.data = (u8*)0; self.byte_len = 0; self.cap = 0;
    }
}

} // utf8

// --- UTF-16 ---

namespace utf16 {

u32 decode_one(u16* buf, u64 len_units, u64* pos) {
    u64 i = (*pos);
    if (i >= len_units) { return 0xFFFD; }
    u16 w0 = buf[i];
    if (w0 < 0xD800 || w0 > 0xDFFF) { (*pos) = i + 1; return (u32)w0; }
    if (w0 >= 0xD800 && w0 <= 0xDBFF) {
        if (i + 1 >= len_units) { (*pos) = i + 1; return 0xFFFD; }
        u16 w1 = buf[i+1];
        if (w1 < 0xDC00 || w1 > 0xDFFF) { (*pos) = i + 1; return 0xFFFD; }
        (*pos) = i + 2;
        return 0x10000 + (((u32)(w0 - 0xD800)) << 10) + (u32)(w1 - 0xDC00);
    }
    (*pos) = i + 1; return 0xFFFD;
}

i32 encode_one(u32 cp, u16* buf) {
    if (cp < 0x10000) { buf[0] = (u16)cp; return 1; }
    cp = cp - 0x10000;
    buf[0] = (u16)(0xD800 + (cp >> 10));
    buf[1] = (u16)(0xDC00 + (cp & 0x3FF));
    return 2;
}

istruc string {
    u16* data;
    u64  unit_len;
    u64  cap;

    void __construct__(&self) { self.data=(u16*)0; self.unit_len=0; self.cap=0; }

    i32  len_units(&self) { return (i32)self.unit_len; }
    u16* raw(&self)       { return self.data; }
    bool is_empty(&self)  { return self.unit_len == 0; }

    void deinit(&self, &memstr a) {
        if (self.data != (u16*)0) a.deinit(self.data);
        self.data = (u16*)0; self.unit_len = 0; self.cap = 0;
    }
}

} // utf16

// --- UTF-32 ---

namespace utf32 {

istruc string {
    u32* data;
    u64  len;
    u64  cap;

    void __construct__(&self) { self.data=(u32*)0; self.len=0; self.cap=0; }

    i32  length(&self)   { return (i32)self.len; }
    u32* raw(&self)      { return self.data; }
    bool is_empty(&self) { return self.len == 0; }

    u32 char_at(&self, i32 i) { return self.data[i]; }

    void deinit(&self, &memstr a) {
        if (self.data != (u32*)0) a.deinit(self.data);
        self.data = (u32*)0; self.len = 0; self.cap = 0;
    }
}

} // utf32

// --- Conversion utilities ---

// Convert UTF-8 byte string to UTF-32 string
utf32.string utf8_to_utf32(u8* src, u64 byte_len, &memstr a) {
    utf32.string r;
    // Allocate worst-case
    r.data = (u32*)a.mmap((u64)(sizeof(u32) * (byte_len + 1)));
    r.len  = 0; r.cap = byte_len + 1;
    u64 pos = 0;
    while (pos < byte_len) {
        r.data[r.len] = utf8.decode_one(src, byte_len, &pos);
        r.len = r.len + 1;
    }
    r.data[r.len] = 0;
    return r;
}

// Convert UTF-32 to UTF-8
utf8.string utf32_to_utf8(u32* src, u64 len, &memstr a) {
    utf8.string r;
    r.data = (u8*)a.mmap((u64)(len * 4 + 1));
    r.byte_len = 0; r.cap = len * 4 + 1;
    u8 tmp[4];
    for (u64 i = 0; i < len; i = i + 1) {
        i32 n = utf8.encode_one(src[i], tmp);
        for (i32 j = 0; j < n; j = j + 1) r.data[r.byte_len + (u64)j] = tmp[j];
        r.byte_len = r.byte_len + (u64)n;
    }
    r.data[r.byte_len] = 0;
    return r;
}

} // encode
} // std
