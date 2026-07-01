// FAIL: accessing a non-existent field in a union
union Num { i32 i; f32 f; }
i32 main() {
    Num n;
    return n.d;  // ERROR: no field 'd' in union Num
}
