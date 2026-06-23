i32 first_char(char* s) {
    return s[0];
}

i32 main() {
    char* word = "hi";
    i32 c = first_char(word);
    if (c != 'h') { return 1; }
    return 0;
}
