@unsafe extern fn malloc(n: u64) *void;
memstr S {
    fn mmap(self: *S, align: usize, n: usize) !*void { return malloc(n); }
    fn rsmap(self: *S, p: *void, n: iofs) bool { return false; }
}
pub fn main() i32 { return 0; }
