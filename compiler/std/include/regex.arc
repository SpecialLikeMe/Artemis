// std.regex — ECMAScript-compatible regular expressions via PCRE2.
//
// PCRE2 must be available on the system:
//   Windows: install via vcpkg (vcpkg install pcre2:x64-windows)
//   Linux:   apt install libpcre2-dev
//   macOS:   brew install pcre2
//
// Link with -lpcre2-8 when compiling programs that use std.regex.
//
// Access as: std.regex.regex_t, std.regex.compile(...), etc.

// PCRE2 C API (pcre2.h equivalents, 8-bit / char variant)
extern void* pcre2_compile_8(i8* pattern, u64 len, u32 options,
                              i32* errcode, u64* erroffset, void* ctx);
extern void  pcre2_code_free_8(void* re);
extern void* pcre2_match_data_create_from_pattern_8(void* re, void* ctx);
extern void  pcre2_match_data_free_8(void* md);
extern i32   pcre2_match_8(void* re, i8* subject, u64 len, u64 startoff,
                            u32 options, void* md, void* ctx);
extern u64*  pcre2_get_ovector_pointer_8(void* md);
extern i32   pcre2_get_error_message_8(i32 errcode, i8* buf, u64 len);
extern u32   pcre2_get_ovector_count_8(void* md);

namespace std {
namespace regex {

// PCRE2 option flags (ECMAScript-compatible subset)
constexpr u32 REGEX_CASELESS  = 0x00000008u; // case-insensitive (PCRE2_CASELESS)
constexpr u32 REGEX_MULTILINE = 0x00000400u; // ^ and $ match line boundaries (PCRE2_MULTILINE)
constexpr u32 REGEX_DOTALL    = 0x00000020u; // . matches newlines (PCRE2_DOTALL)
constexpr u32 REGEX_UTF       = 0x00080000u; // treat pattern and subject as UTF-8 (PCRE2_UTF)
constexpr u32 REGEX_EXTENDED  = 0x00000080u; // ignore unescaped whitespace (PCRE2_EXTENDED)

constexpr i32 REGEX_ERROR_NOMATCH = -1; // no match (PCRE2_ERROR_NOMATCH)

// Maximum number of capture groups tracked in a single match.
constexpr i32 REGEX_MAX_CAPTURES = 32;

// Capture group result: start byte offset and length in the subject string.
struct capture_t {
    i32 start;  // byte offset of match start (-1 if group did not participate)
    i32 len;    // byte length of match (0 if zero-width)
}

// regex_t — compiled regular expression.
istruc regex_t {
    void* _code;     // opaque PCRE2 compiled pattern
    bool  _valid;    // false if compilation failed

    // Compile a pattern.  options is a bitwise OR of REGEX_* constants.
    // On failure _valid is false; call error() for a description.
    void __construct__(regex_t* self, i8* pattern, u32 options) {
        i32 errcode   = 0;
        u64 erroffset = 0;
        self._code  = pcre2_compile_8(pattern, (u64)-1, options, &errcode, &erroffset, (void*)0);
        self._valid = self._code != (void*)0;
    }

    // Free PCRE2 resources.
    void free(regex_t* self) {
        if (self._code != (void*)0) {
            pcre2_code_free_8(self._code);
            self._code = (void*)0;
        }
    }

    bool is_valid(regex_t* self) { return self._valid; }

    // Match subject against this pattern starting at byte offset `start`.
    // Returns true on match.  cap[] and cap_count are filled with capture groups.
    // cap[0] is always the whole match; cap[1..] are the sub-groups.
    bool match_at(regex_t* self, i8* subject, i32 slen, i32 start,
                  capture_t* cap, i32 cap_cap, i32* cap_count) {
        if (!self._valid) { (*cap_count) = 0; return false; }
        void* md = pcre2_match_data_create_from_pattern_8(self._code, (void*)0);
        i32 rc = pcre2_match_8(self._code, subject, (u64)slen,
                                (u64)start, 0u, md, (void*)0);
        if (rc <= 0) {
            pcre2_match_data_free_8(md);
            (*cap_count) = 0;
            return false;
        }
        u64* ov = pcre2_get_ovector_pointer_8(md);
        i32 n = rc < cap_cap ? rc : cap_cap;
        for (i32 i = 0; i < n; i = i + 1) {
            u64 s = ov[i * 2];
            u64 e = ov[i * 2 + 1];
            if (s == (u64)-1) { cap[i].start = -1; cap[i].len = 0; }
            else               { cap[i].start = (i32)s; cap[i].len = (i32)(e - s); }
        }
        (*cap_count) = n;
        pcre2_match_data_free_8(md);
        return true;
    }

    // Convenience: test whether subject matches anywhere (no captures).
    bool test(regex_t* self, i8* subject, i32 slen) {
        capture_t cap[1];
        i32 n = 0;
        return self.match_at(subject, slen, 0, cap, 1, &n);
    }

    // Find first match; fills cap[0] with whole match.  Returns true on match.
    bool find(regex_t* self, i8* subject, i32 slen,
              capture_t* cap, i32 cap_cap, i32* cap_count) {
        return self.match_at(subject, slen, 0, cap, cap_cap, cap_count);
    }
}

// Standalone helpers that compile a temporary regex and release it immediately.

// Returns true if subject matches pattern anywhere.
bool test(i8* pattern, i8* subject, i32 slen, u32 options) {
    regex_t re(pattern, options);
    if (!re.is_valid()) { return false; }
    bool result = re.test(subject, slen);
    re.free();
    return result;
}

// Returns start byte offset of first match, or -1 if no match.
i32 find_offset(i8* pattern, i8* subject, i32 slen, u32 options) {
    regex_t re(pattern, options);
    if (!re.is_valid()) { return -1; }
    capture_t cap[1];
    i32 n = 0;
    bool ok = re.find(subject, slen, cap, 1, &n);
    re.free();
    return ok ? cap[0].start : -1;
}

} // namespace regex
} // namespace std
