// FAIL: accessing a protected field from a free function (no friend mechanism)
istruc Shape {
    protected i32 area_cache;
    public void __construct__(Shape* self) { self.area_cache = 0; }
}
i32 get_cache(Shape* s) { return s->area_cache; }  // ERROR: area_cache is protected
i32 main() { return 0; }
