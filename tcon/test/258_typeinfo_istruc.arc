// PASS: @typeinfo() for istruc types reports correct kind and field count
istruc Point {
    i32 x;
    i32 y;
    void __construct__(Point* self, i32 xv, i32 yv) {
        self.x = xv;
        self.y = yv;
    }
    i32 sum(Point* self) { return self.x + self.y; }
}

i32 main() {
    // @typeinfo on an istruc should report IFO_KIND_STRUCT (2) or IFO_KIND_ISTRUC (5)
    type_info* tp = @typeinfo(Point);
    if (tp == (type_info*)0) { return 1; }
    // kind should be non-zero (it's a struct/istruc, not a primitive)
    if (tp.kind == 0) { return 2; }
    // field_count should be >= 2 (x and y, constructors may not be counted)
    if (tp.field_count < 2) { return 3; }
    // fields pointer should be non-null
    if (tp.fields == (type_info_field*)0) { return 4; }
    // size should be at least 8 bytes (two i32 fields)
    if (tp.size < 8) { return 5; }

    // Also verify that @typeinfo on a used istruc instance still works
    Point p(3, 4);
    type_info* tp2 = @typeinfo(Point);
    if (tp2 == (type_info*)0) { return 6; }
    if (tp2.field_count != tp.field_count) { return 7; }

    return 0;
}
