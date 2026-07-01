istruc Token {
    i32 id;
    i32 kind;
    i32 total(const Token* self) { return self.id + self.kind; }
}
i32 main() {
    Token t = Token { .id = 5, .kind = 6 };
    if (t.total() != 11) { return 1; }
    return 0;
}
