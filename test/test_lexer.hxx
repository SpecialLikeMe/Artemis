#pragma once
#include "framework.hxx"
#include "../boot/compiler/lexer/main.hxx"
#include <stdexcept>
#include <string>
#include <vector>

static std::vector<token_t> lex(const std::string& src) {
    lexer l(src);
    return l.tokenize();
}

TEST(Lexer, EmptyInput) {
    auto toks = lex("");
    ASSERT_EQ(toks.size(), 1u);
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::eof));
}

TEST(Lexer, IntegerLiteral) {
    auto toks = lex("42");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::int_lit));
    ASSERT_EQ(toks[0].value, "42");
}

TEST(Lexer, HexLiteral) {
    auto toks = lex("0xFF");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::int_lit));
    ASSERT_CONTAINS(toks[0].value, "0x");
}

TEST(Lexer, BinaryLiteral) {
    auto toks = lex("0b1010");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::int_lit));
    ASSERT_CONTAINS(toks[0].value, "0b");
}

TEST(Lexer, FloatLiteral) {
    auto toks = lex("3.14");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::float_lit));
}

TEST(Lexer, StringLiteral) {
    auto toks = lex("\"hello\"");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::string_lit));
    ASSERT_EQ(toks[0].value, "hello");
}

TEST(Lexer, UnterminatedString) {
    ASSERT_THROWS(lex("\"unterminated"), std::runtime_error);
}

TEST(Lexer, CharLiteral) {
    auto toks = lex("'a'");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::char_lit));
    ASSERT_EQ(toks[0].value, "a");
}

TEST(Lexer, Keywords) {
    auto toks = lex("if else while for return");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::kw_if));
    ASSERT_EQ(static_cast<int>(toks[1].type), static_cast<int>(token_type::kw_else));
    ASSERT_EQ(static_cast<int>(toks[2].type), static_cast<int>(token_type::kw_while));
    ASSERT_EQ(static_cast<int>(toks[3].type), static_cast<int>(token_type::kw_for));
    ASSERT_EQ(static_cast<int>(toks[4].type), static_cast<int>(token_type::kw_return));
}

TEST(Lexer, ArbIntTypeKeywords) {
    auto toks = lex("i8 i16 i32 i64 i128 i9982 i1");
    for (int j = 0; j < 7; ++j)
        ASSERT_EQ(static_cast<int>(toks[j].type), static_cast<int>(token_type::kw_arb_int));
    ASSERT_EQ(toks[0].value, "8");
    ASSERT_EQ(toks[2].value, "32");
    ASSERT_EQ(toks[5].value, "9982");
}

TEST(Lexer, ArbUintTypeKeywords) {
    auto toks = lex("u8 u16 u32 u64 u512");
    for (int j = 0; j < 5; ++j)
        ASSERT_EQ(static_cast<int>(toks[j].type), static_cast<int>(token_type::kw_arb_uint));
    ASSERT_EQ(toks[2].value, "32");
}

TEST(Lexer, ArbFloatTypeKeywords) {
    auto toks = lex("f32 f64 f128 f187");
    for (int j = 0; j < 4; ++j)
        ASSERT_EQ(static_cast<int>(toks[j].type), static_cast<int>(token_type::kw_arb_float));
    ASSERT_EQ(toks[1].value, "64");
    ASSERT_EQ(toks[3].value, "187");
}

TEST(Lexer, ArbBoolTypeKeywords) {
    auto toks = lex("b1 b8 b32 b64 b128");
    for (int j = 0; j < 5; ++j)
        ASSERT_EQ(static_cast<int>(toks[j].type), static_cast<int>(token_type::kw_arb_bool));
    ASSERT_EQ(toks[0].value, "1");
    ASSERT_EQ(toks[2].value, "32");
}

TEST(Lexer, TypeWordAliases) {
    auto toks = lex("int uint float bool");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::kw_arb_int));
    ASSERT_EQ(toks[0].value, "32");
    ASSERT_EQ(static_cast<int>(toks[1].type), static_cast<int>(token_type::kw_arb_uint));
    ASSERT_EQ(toks[1].value, "32");
    ASSERT_EQ(static_cast<int>(toks[2].type), static_cast<int>(token_type::kw_arb_float));
    ASSERT_EQ(toks[2].value, "64");
    ASSERT_EQ(static_cast<int>(toks[3].type), static_cast<int>(token_type::kw_arb_bool));
    ASSERT_EQ(toks[3].value, "8");
}

TEST(Lexer, ArithmeticOperators) {
    auto toks = lex("+ - * / %");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::plus));
    ASSERT_EQ(static_cast<int>(toks[1].type), static_cast<int>(token_type::minus));
    ASSERT_EQ(static_cast<int>(toks[2].type), static_cast<int>(token_type::ast));
    ASSERT_EQ(static_cast<int>(toks[3].type), static_cast<int>(token_type::slash));
    ASSERT_EQ(static_cast<int>(toks[4].type), static_cast<int>(token_type::mod));
}

TEST(Lexer, BitwiseOperators) {
    auto toks = lex("& | ^ ~ << >>");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::addr));
    ASSERT_EQ(static_cast<int>(toks[1].type), static_cast<int>(token_type::bit_or));
    ASSERT_EQ(static_cast<int>(toks[2].type), static_cast<int>(token_type::bit_xor));
    ASSERT_EQ(static_cast<int>(toks[3].type), static_cast<int>(token_type::bit_not));
    ASSERT_EQ(static_cast<int>(toks[4].type), static_cast<int>(token_type::left));
    ASSERT_EQ(static_cast<int>(toks[5].type), static_cast<int>(token_type::right));
}

TEST(Lexer, ComparisonOperators) {
    auto toks = lex("== != < > <= >=");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::eq));
    ASSERT_EQ(static_cast<int>(toks[1].type), static_cast<int>(token_type::ne));
    ASSERT_EQ(static_cast<int>(toks[2].type), static_cast<int>(token_type::lt));
    ASSERT_EQ(static_cast<int>(toks[3].type), static_cast<int>(token_type::gt));
    ASSERT_EQ(static_cast<int>(toks[4].type), static_cast<int>(token_type::lte));
    ASSERT_EQ(static_cast<int>(toks[5].type), static_cast<int>(token_type::gte));
}

TEST(Lexer, LogicalOperators) {
    auto toks = lex("&& || !");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::and_));
    ASSERT_EQ(static_cast<int>(toks[1].type), static_cast<int>(token_type::or_));
    ASSERT_EQ(static_cast<int>(toks[2].type), static_cast<int>(token_type::not_));
}

TEST(Lexer, AssignmentOperators) {
    auto toks = lex("= += -= *= /= %=");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::assign));
    ASSERT_EQ(static_cast<int>(toks[1].type), static_cast<int>(token_type::plus_eq));
    ASSERT_EQ(static_cast<int>(toks[2].type), static_cast<int>(token_type::minus_eq));
    ASSERT_EQ(static_cast<int>(toks[3].type), static_cast<int>(token_type::star_eq));
    ASSERT_EQ(static_cast<int>(toks[4].type), static_cast<int>(token_type::slash_eq));
    ASSERT_EQ(static_cast<int>(toks[5].type), static_cast<int>(token_type::mod_eq));
}

TEST(Lexer, BitwiseAssignOps) {
    auto toks = lex("&= |= ^= <<= >>=");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::amp_eq));
    ASSERT_EQ(static_cast<int>(toks[1].type), static_cast<int>(token_type::pipe_eq));
    ASSERT_EQ(static_cast<int>(toks[2].type), static_cast<int>(token_type::caret_eq));
    ASSERT_EQ(static_cast<int>(toks[3].type), static_cast<int>(token_type::shl_eq));
    ASSERT_EQ(static_cast<int>(toks[4].type), static_cast<int>(token_type::shr_eq));
}

TEST(Lexer, Delimiters) {
    auto toks = lex("( ) { } [ ] ; ,");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::oparen));
    ASSERT_EQ(static_cast<int>(toks[1].type), static_cast<int>(token_type::cparen));
    ASSERT_EQ(static_cast<int>(toks[2].type), static_cast<int>(token_type::obrace));
    ASSERT_EQ(static_cast<int>(toks[3].type), static_cast<int>(token_type::cbrace));
    ASSERT_EQ(static_cast<int>(toks[4].type), static_cast<int>(token_type::obracket));
    ASSERT_EQ(static_cast<int>(toks[5].type), static_cast<int>(token_type::cbracket));
    ASSERT_EQ(static_cast<int>(toks[6].type), static_cast<int>(token_type::sm));
    ASSERT_EQ(static_cast<int>(toks[7].type), static_cast<int>(token_type::comma));
}

TEST(Lexer, AtToken) {
    auto toks = lex("@my_attr");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::at));
    ASSERT_EQ(static_cast<int>(toks[1].type), static_cast<int>(token_type::id));
    ASSERT_EQ(toks[1].value, "my_attr");
}

TEST(Lexer, HashToken) {
    auto toks = lex("#");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::hash));
}

TEST(Lexer, LineComment) {
    auto toks = lex("42 // this is a comment\n99");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::int_lit));
    ASSERT_EQ(toks[0].value, "42");
    ASSERT_EQ(static_cast<int>(toks[1].type), static_cast<int>(token_type::int_lit));
    ASSERT_EQ(toks[1].value, "99");
}

TEST(Lexer, BlockComment) {
    auto toks = lex("1 /* block */ 2");
    ASSERT_EQ(toks[0].value, "1");
    ASSERT_EQ(toks[1].value, "2");
}

TEST(Lexer, LineNumbers) {
    auto toks = lex("a\nb\nc");
    ASSERT_EQ(toks[0].line, 1);
    ASSERT_EQ(toks[1].line, 2);
    ASSERT_EQ(toks[2].line, 3);
}

TEST(Lexer, IdentifierVsKeyword) {
    auto toks = lex("if iff");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::kw_if));
    ASSERT_EQ(static_cast<int>(toks[1].type), static_cast<int>(token_type::id));
    ASSERT_EQ(toks[1].value, "iff");
}

TEST(Lexer, TrueAndFalse) {
    auto toks = lex("true false");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::kw_true));
    ASSERT_EQ(static_cast<int>(toks[1].type), static_cast<int>(token_type::kw_false));
}

TEST(Lexer, NullKeyword) {
    auto toks = lex("null");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::kw_null));
}

TEST(Lexer, StorageClassKeywords) {
    auto toks = lex("extern inline register");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::kw_extern));
    ASSERT_EQ(static_cast<int>(toks[1].type), static_cast<int>(token_type::kw_inline));
    ASSERT_EQ(static_cast<int>(toks[2].type), static_cast<int>(token_type::kw_register));
}

TEST(Lexer, IncrDecr) {
    auto toks = lex("++ --");
    ASSERT_EQ(static_cast<int>(toks[0].type), static_cast<int>(token_type::inc));
    ASSERT_EQ(static_cast<int>(toks[1].type), static_cast<int>(token_type::dec));
}
