// std.encode — UTF-8, UTF-16, UTF-32 validation, codepoint decoding.
// All functions/types at global scope after extern std.encode;
//   utf8_decode_one / utf8_encode_one / utf8_validate / utf8_count
//   utf16_decode_one / utf16_encode_one
//   utf8_string / utf16_string / utf32_string

// --- UTF-8 ---

namespace encode {
u32 utf8_decode_one(u8* buf, u64 len, u64* pos) {
    u64 i = (*pos);
    if (i >= len) { return 0xFFFDu; }
    u8 b0 = buf[i];
    if (b0 < 0x80u) { (*pos) = i + 1; return (u32)b0; }
    if (b0 < 0xC0u) { (*pos) = i + 1; return 0xFFFDu; }
    u32 cp; u32 extra;
    if (b0 < 0xE0u)      { cp = (u32)(b0 & 0x1Fu); extra = 1u; }
    else if (b0 < 0xF0u) { cp = (u32)(b0 & 0x0Fu); extra = 2u; }
    else                  { cp = (u32)(b0 & 0x07u); extra = 3u; }
    for (u32 j = 0u; j < extra; j = j + 1u) {
        i = i + 1;
        if (i >= len) { (*pos) = i; return 0xFFFDu; }
        u8 b = buf[i];
        if ((b & 0xC0u) != 0x80u) { (*pos) = i; return 0xFFFDu; }
        cp = (cp << 6) | (u32)(b & 0x3Fu);
    }
    (*pos) = i + 1;
    return cp;
}

i32 utf8_encode_one(u32 cp, u8* buf) {
    if (cp < 0x80u)    { buf[0] = (u8)cp; return 1; }
    if (cp < 0x800u)   { buf[0] = (u8)(0xC0u|(cp>>6)); buf[1]=(u8)(0x80u|(cp&0x3Fu)); return 2; }
    if (cp < 0x10000u) {
        buf[0]=(u8)(0xE0u|(cp>>12)); buf[1]=(u8)(0x80u|((cp>>6)&0x3Fu));
        buf[2]=(u8)(0x80u|(cp&0x3Fu)); return 3;
    }
    buf[0]=(u8)(0xF0u|(cp>>18)); buf[1]=(u8)(0x80u|((cp>>12)&0x3Fu));
    buf[2]=(u8)(0x80u|((cp>>6)&0x3Fu)); buf[3]=(u8)(0x80u|(cp&0x3Fu)); return 4;
}

bool utf8_validate(u8* buf, u64 len) {
    u64 i = 0;
    while (i < len) {
        u64 prev = i;
        u32 cp = utf8_decode_one(buf, len, &i);
        if (cp == 0xFFFDu && i == prev + 1) { return false; }
    }
    return true;
}

i32 utf8_count(u8* buf, u64 len) {
    i32 n = 0; u64 i = 0;
    while (i < len) { utf8_decode_one(buf, len, &i); n = n + 1; }
    return n;
}

istruc utf8_string {
    u8* data;
    u64 byte_len;
    u64 cap;

    void __construct__(utf8_string* self) { self.data=(u8*)0; self.byte_len=0; self.cap=0; }

    i32  len_bytes(utf8_string* self) { return (i32)self.byte_len; }
    u8*  raw(utf8_string* self)       { return self.data; }
    i8*  c_str(utf8_string* self)     { return (i8*)self.data; }

    bool eq(utf8_string* self, utf8_string* o) {
        if (self.byte_len != (*o).byte_len) { return false; }
        for (u64 i = 0; i < self.byte_len; i = i + 1)
            if (self.data[i] != (*o).data[i]) { return false; }
        return true;
    }
}

// --- UTF-16 ---

u32 utf16_decode_one(u16* buf, u64 len_units, u64* pos) {
    u64 i = (*pos);
    if (i >= len_units) { return 0xFFFDu; }
    u16 w0 = buf[i];
    if (w0 < 0xD800u || w0 > 0xDFFFu) { (*pos) = i + 1; return (u32)w0; }
    if (w0 >= 0xD800u && w0 <= 0xDBFFu) {
        if (i + 1 >= len_units) { (*pos) = i + 1; return 0xFFFDu; }
        u16 w1 = buf[i+1];
        if (w1 < 0xDC00u || w1 > 0xDFFFu) { (*pos) = i + 1; return 0xFFFDu; }
        (*pos) = i + 2;
        return 0x10000u + (((u32)(w0 - 0xD800u)) << 10) + (u32)(w1 - 0xDC00u);
    }
    (*pos) = i + 1; return 0xFFFDu;
}

i32 utf16_encode_one(u32 cp, u16* buf) {
    if (cp < 0x10000u) { buf[0] = (u16)cp; return 1; }
    cp = cp - 0x10000u;
    buf[0] = (u16)(0xD800u + (cp >> 10));
    buf[1] = (u16)(0xDC00u + (cp & 0x3FFu));
    return 2;
}

istruc utf16_string {
    u16* data;
    u64  unit_len;
    u64  cap;

    void __construct__(utf16_string* self) { self.data=(u16*)0; self.unit_len=0; self.cap=0; }

    i32  len_units(utf16_string* self) { return (i32)self.unit_len; }
    u16* raw(utf16_string* self)       { return self.data; }
    bool is_empty(utf16_string* self)  { return self.unit_len == 0; }
}

// --- UTF-32 ---

istruc utf32_string {
    u32* data;
    u64  len;
    u64  cap;

    void __construct__(utf32_string* self) { self.data=(u32*)0; self.len=0; self.cap=0; }

    i32  length(utf32_string* self)   { return (i32)self.len; }
    u32* raw(utf32_string* self)      { return self.data; }
    bool is_empty(utf32_string* self) { return self.len == 0; }
    u32  char_at(utf32_string* self, i32 i) { u32 v = self.data[i]; return v; }
}

} // namespace encode