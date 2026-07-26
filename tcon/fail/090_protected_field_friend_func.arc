// FAIL: accessing a protected field from a free function (no friend mechanism)
istruc Shape {
    protected i32 area_cache;
    public void __construct__(Shape* self) { self.area_cache = 0; }
}
fn get_cache(s: *Shape) i32 { return s->area_cache; }  // ERROR: area_cache is protected
fn main() i32 { return 0; }
