// Test: std.regex — ECMAScript-compatible features
extern std.regex;

i32 main() {
    // \d digit shorthand
    regex_t rd("\\d+", 0u);
    if (!rd.is_valid())           { return 1; }
    if (!rd.test("123", 3))       { return 2; }
    if (rd.test("abc", 3))        { return 3; }

    // \w word character
    regex_t rw("\\w+", 0u);
    if (!rw.test("hello_42", 8))  { return 4; }
    if (rw.test("!!!", 3))        { return 5; }

    // \s whitespace
    regex_t rs("\\s+", 0u);
    if (!rs.test(" \t", 2))       { return 6; }
    if (rs.test("abc", 3))        { return 7; }

    // Negated class [^...]
    regex_t rn("[^aeiou]+", 0u);
    if (!rn.test("str", 3))       { return 8; }
    if (rn.test("aaa", 3))        { return 9; }

    // Optional quantifier ?
    regex_t rq("colou?r", 0u);
    if (!rq.test("color", 5))     { return 10; }
    if (!rq.test("colour", 6))    { return 11; }

    // Grouping with alternation
    regex_t rg("(cat|dog)s?", 0u);
    if (!rg.test("cat", 3))       { return 12; }
    if (!rg.test("dogs", 4))      { return 13; }
    if (rg.test("bird", 4))       { return 14; }

    // CASELESS flag
    regex_t rc("hello", std.regex.REGEX_CASELESS);
    if (!rc.test("HELLO", 5))     { return 15; }
    if (!rc.test("Hello", 5))     { return 16; }

    return 0;
}
