// Test: std.regex — ECMAScript-compatible features
extern  std.regex;

pub fn main() i32 {
    // \d digit shorthand
    let mut rd: std.regex.regex_t("\\d+", 0u);
    if (!rd.is_valid())           { return 1; }
    if (!rd.test("123", 3))       { return 2; }
    if (rd.test("abc", 3))        { return 3; }

    // \w word character
    let mut rw: std.regex.regex_t("\\w+", 0u);
    if (!rw.test("hello_42", 8))  { return 4; }
    if (rw.test("!!!", 3))        { return 5; }

    // \s whitespace
    let mut rs: std.regex.regex_t("\\s+", 0u);
    if (!rs.test(" \t", 2))       { return 6; }
    if (rs.test("abc", 3))        { return 7; }

    // Negated class [^...]
    let mut rn: std.regex.regex_t("[^aeiou]+", 0u);
    if (!rn.test("str", 3))       { return 8; }
    if (rn.test("aaa", 3))        { return 9; }

    // Optional quantifier ?
    let mut rq: std.regex.regex_t("colou?r", 0u);
    if (!rq.test("color", 5))     { return 10; }
    if (!rq.test("colour", 6))    { return 11; }

    // Grouping with alternation
    let mut rg: std.regex.regex_t("(cat|dog)s?", 0u);
    if (!rg.test("cat", 3))       { return 12; }
    if (!rg.test("dogs", 4))      { return 13; }
    if (rg.test("bird", 4))       { return 14; }

    // CASELESS flag
    let mut rc: std.regex.regex_t("hello", std.regex.REGEX_CASELESS);
    if (!rc.test("HELLO", 5))     { return 15; }
    if (!rc.test("Hello", 5))     { return 16; }

    return 0;
}
