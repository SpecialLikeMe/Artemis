// Test: std.regex — basic NFA regex matching
extern  std.regex;
@unsafe extern fn printf(fmt: *i8, ...) i32;

pub @unsafe fn main() i32 {
    // Literal match
    let mut re1: std.regex.regex_t("hello", 0u);
    if (!re1.is_valid()) { printf("FAIL re1 invalid\n"); return 1; }
    if (!re1.test("hello", 5)) { printf("FAIL re1 test hello\n"); return 2; }
    if (re1.test("world", 5))  { printf("FAIL re1 test world\n"); return 3; }
    if (!re1.test("say hello world", 15)) { printf("FAIL re1 subst\n"); return 4; }

    // Dot any
    let mut re2: std.regex.regex_t("a.b", 0u);
    if (!re2.test("axb", 3)) { printf("FAIL re2 axb\n"); return 5; }
    if (!re2.test("azb", 3)) { printf("FAIL re2 azb\n"); return 6; }
    if (re2.test("ab", 2))   { printf("FAIL re2 ab\n"); return 7; }

    // Character class
    let mut re3: std.regex.regex_t("[a-z]+", 0u);
    if (!re3.test("abc", 3))  { printf("FAIL re3 abc\n"); return 8; }
    if (!re3.test("xyz", 3))  { printf("FAIL re3 xyz\n"); return 9; }
    if (re3.test("123", 3))   { printf("FAIL re3 123\n"); return 10; }

    // Star quantifier
    let mut re4: std.regex.regex_t("a*b", 0u);
    if (!re4.test("b", 1))    { printf("FAIL re4 b\n"); return 11; }
    if (!re4.test("ab", 2))   { printf("FAIL re4 ab\n"); return 12; }
    if (!re4.test("aaab", 4)) { printf("FAIL re4 aaab\n"); return 13; }

    // Plus quantifier
    let mut re5: std.regex.regex_t("a+b", 0u);
    if (re5.test("b", 1))     { printf("FAIL re5 b\n"); return 14; }
    if (!re5.test("ab", 2))   { printf("FAIL re5 ab\n"); return 15; }
    if (!re5.test("aaab", 4)) { printf("FAIL re5 aaab\n"); return 16; }

    // Anchors
    let mut re6: std.regex.regex_t("^abc$", 0u);
    if (!re6.test("abc", 3))  { printf("FAIL re6 abc\n"); return 17; }
    if (re6.test("xabc", 4))  { printf("FAIL re6 xabc\n"); return 18; }
    if (re6.test("abcx", 4))  { printf("FAIL re6 abcx\n"); return 19; }

    // Alternation
    let mut re7: std.regex.regex_t("cat|dog", 0u);
    if (!re7.test("cat", 3))  { printf("FAIL re7 cat\n"); return 20; }
    if (!re7.test("dog", 3))  { printf("FAIL re7 dog\n"); return 21; }
    if (re7.test("bird", 4))  { printf("FAIL re7 bird\n"); return 22; }

    // find_offset
    let mut off: i32= std.regex.find_offset("[0-9]+", "abc123def", 9, 0u);
    if (off != 3) { printf("FAIL find_offset: got %d expected 3\n", off); return 23; }

    return 0;
}
