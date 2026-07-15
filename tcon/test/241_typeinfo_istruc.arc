// PASS: @typeinfo on an istruc — returns valid type_info with kind=5 and field info.
istruc Point {
    i32 x;
    i32 y;
    void __construct__(Point* self, i32 px, i32 py) {
        self.x = px;
        self.y = py;
    }
}

i32 main() {
    type_info* ti = @typeinfo(Point);
    if (ti == (type_info*)0)      { return 1; }
    if (ti.kind != 5)             { return 2; }  // 5 = istruc
    if (ti.field_count < 2)       { return 3; }
    if (ti.fields == (type_info_field*)0) { return 4; }
    if (ti.size < 8)              { return 5; }  // at least two i32s

    return 0;
}
