// PASS: proc macro declared as a regular function with attr/derive marker parses without error.
// The macro body is not compiled to IR.

tokenstream* add_debug(&memstr alloc, tokenstream* input) attr {
    return quote{ debug };
}

tokenstream* my_derive(&memstr alloc, tokenstream* input) derive {
    return quote{ i32 x = 0; };
}

tokenstream* safe_macro(&memstr alloc, tokenstream* input) attr verify {
    return quote{ i32 y = 1; };
}

i32 main() {
    return 0;
}
