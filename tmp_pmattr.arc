tokenstream* log_call(&memstr alloc, tokenstream* input) attr {
    return input;
}

#[log_call]
i32 add(i32 a, i32 b) {
    return a + b;
}

i32 main() {
    return add(1, 2) - 3;
}
