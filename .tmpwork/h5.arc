@unsafe extern fn printf(f: *const i8, ...) i32;
struct Pt { let x: i32; let y: i32; }
fn sz(comptime T: type) u64 { return (u64)@csizeof(T); }
pub fn main() i32 {
    @unsafe { printf("i32 = %llu\n", sz(i32)); }
    @unsafe { printf("Pt  = %llu\n", sz(Pt)); }
    return 0;
}
