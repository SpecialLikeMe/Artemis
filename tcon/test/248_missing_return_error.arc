// EXPECT_FAIL
// Non-void function missing return → compiler must emit error
i32 bad_func() {
    i32 x = 5;
}

i32 main() {
    return bad_func();
}
