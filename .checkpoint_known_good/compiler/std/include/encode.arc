// std.encode — UTF-8, UTF-16, UTF-32 validation, codepoint decoding.
// Access as: std.encode.utf8_decode_one(...), std.encode.utf8_validate(...), etc.

// --- UTF-8 ---

namespace std {
namespace encode {
fn utf8_decode_one(buf: *u8, len: u64, pos: *u64) u32 {
    let mut i: u64= (*pos);
    if (i >= len) { return 0xFFFDu; }
    let mut byte0: u8= buf[i];
    if (byte0 < 0x80u) { (*pos) = i + 1; return (u32)byte0; }
    if (byte0 < 0xC0u) { (*pos) = i + 1; return 0xFFFDu; }
    let mut cp: u32; let mut extra: u32;
    if (byte0 < 0xE0u)      { cp = (u32)(byte0 & 0x1Fu); extra = 1u; }
    else if (byte0 < 0xF0u) { cp = (u32)(byte0 & 0x0Fu); extra = 2u; }
    else                  { cp = (u32)(byte0 & 0x07u); extra = 3u; }
    for (let mut j: u32 = 0u; j < extra; j = j + 1u) {
        i = i + 1;
        if (i >= len) { (*pos) = i; return 0xFFFDu; }
        let mut b: u8= buf[i];
        if ((b & 0xC0u) != 0x80u) { (*pos) = i; return 0xFFFDu; }
        cp = (cp << 6) | (u32)(b & 0x3Fu);
    }
    (*pos) = i + 1;
    return cp;
}

fn utf8_encode_one(cp: u32, buf: *u8) i32 {
    if (cp < 0x80u)    { buf[0] = (u8)cp; return 1; }
    if (cp < 0x800u)   { buf[0] = (u8)(0xC0u|(cp>>6)); buf[1]=(u8)(0x80u|(cp&0x3Fu)); return 2; }
    if (cp < 0x10000u) {
        buf[0]=(u8)(0xE0u|(cp>>12)); buf[1]=(u8)(0x80u|((cp>>6)&0x3Fu));
        buf[2]=(u8)(0x80u|(cp&0x3Fu)); return 3;
    }
    buf[0]=(u8)(0xF0u|(cp>>18)); buf[1]=(u8)(0x80u|((cp>>12)&0x3Fu));
    buf[2]=(u8)(0x80u|((cp>>6)&0x3Fu)); buf[3]=(u8)(0x80u|(cp&0x3Fu)); return 4;
}

fn utf8_validate(buf: *u8, len: u64) bool {
    let mut i: u64= 0;
    while (i < len) {
        let mut prev: u64= i;
        let mut cp: u32= utf8_decode_one(buf, len, &i);
        if (cp == 0xFFFDu && i == prev + 1) { return false; }
    }
    return true;
}

fn utf8_count(buf: *u8, len: u64) i32 {
    let mut n: i32= 0; let mut i: u64= 0;
    while (i < len) { utf8_decode_one(buf, len, &i); n = n + 1; }
    return n;
}

istruc utf8_string {
    let mut data: *u8;
    let mut byte_len: u64;
    let mut cap: u64;

    fn __construct__(self: *utf8_string) void { self.data=(u8*)0; self.byte_len=0; self.cap=0; }

    fn len_bytes(self: *utf8_string) i32 { return (i32)self.byte_len; }
    fn raw(self: *utf8_string) *u8       { return self.data; }
    fn c_str(self: *utf8_string) *i8     { return (i8*)self.data; }

    fn eq(self: *utf8_string, o: *utf8_string) bool {
        if (self.byte_len != (*o).byte_len) { return false; }
        for (let mut i: u64 = 0; i < self.byte_len; i = i + 1)
            if (self.data[i] != (*o).data[i]) { return false; }
        return true;
    }
}

// --- UTF-16 ---

fn utf16_decode_one(buf: *u16, len_units: u64, pos: *u64) u32 {
    let mut i: u64= (*pos);
    if (i >= len_units) { return 0xFFFDu; }
    let mut w0: u16= buf[i];
    if (w0 < 0xD800u || w0 > 0xDFFFu) { (*pos) = i + 1; return (u32)w0; }
    if (w0 >= 0xD800u && w0 <= 0xDBFFu) {
        if (i + 1 >= len_units) { (*pos) = i + 1; return 0xFFFDu; }
        let mut w1: u16= buf[i+1];
        if (w1 < 0xDC00u || w1 > 0xDFFFu) { (*pos) = i + 1; return 0xFFFDu; }
        (*pos) = i + 2;
        return 0x10000u + (((u32)(w0 - 0xD800u)) << 10) + (u32)(w1 - 0xDC00u);
    }
    (*pos) = i + 1; return 0xFFFDu;
}

fn utf16_encode_one(cp: u32, buf: *u16) i32 {
    if (cp < 0x10000u) { buf[0] = (u16)cp; return 1; }
    cp = cp - 0x10000u;
    buf[0] = (u16)(0xD800u + (cp >> 10));
    buf[1] = (u16)(0xDC00u + (cp & 0x3FFu));
    return 2;
}

istruc utf16_string {
    let mut data: *u16;
    let mut unit_len: u64;
    let mut cap: u64;

    fn __construct__(self: *utf16_string) void { self.data=(u16*)0; self.unit_len=0; self.cap=0; }

    fn len_units(self: *utf16_string) i32 { return (i32)self.unit_len; }
    fn raw(self: *utf16_string) *u16       { return self.data; }
    fn is_empty(self: *utf16_string) bool  { return self.unit_len == 0; }
}

// --- UTF-32 ---

istruc utf32_string {
    let mut data: *u32;
    let mut len: u64;
    let mut cap: u64;

    fn __construct__(self: *utf32_string) void { self.data=(u32*)0; self.len=0; self.cap=0; }

    fn length(self: *utf32_string) i32   { return (i32)self.len; }
    fn raw(self: *utf32_string) *u32      { return self.data; }
    fn is_empty(self: *utf32_string) bool { return self.len == 0; }
    fn char_at(self: *utf32_string, i: i32) u32 { let mut v: u32= self.data[i]; return v; }
}

} // namespace encode
} // namespace std