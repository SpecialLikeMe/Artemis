// Test: std.dll — doubly linked list with i32 values
extern std.dll;
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

memstr Bump {
    let mut base: *void; let mut used: u64; let mut cap: u64;
    fn __construct__(self: *Bump, n: u64) void { self.base=malloc(n); self.used=0; self.cap=n; }
    fn mmap(self: *Bump, align: usize, n: usize) !*void {
        let mut al: u64=(n+7)&~(u64)7;
        if (self.used+al>self.cap) { return (void*)0; }
        let mut p: *void=(void*)((u8*)self.base+self.used); self.used=self.used+al; return p;
    }
    fn rmap(self: *Bump, align: usize, p: *void, n: iofs) !*void { return error.Unsupported; }
    fn deinit(self: *Bump) !void { free(self.base); }
}

pub fn main() i32 {
    let mut a: Bump(16384);
    let mut list: std.dll<i32>();

    list.push_back(10, a);
    list.push_back(20, a);
    list.push_back(30, a);
    list.push_front(1, a);

    if (list.size() != 4)    { return 1; }
    if (list.is_empty())     { return 2; }

    let mut front: *i32= list.peek_front();
    if (front == (i32*)0 || *front != 1)   { return 3; }

    let mut back: *i32= list.peek_back();
    if (back == (i32*)0 || *back != 30)    { return 4; }

    let mut pf: i32= list.pop_front();
    if (pf != 1)             { return 5; }
    if (list.size() != 3)   { return 6; }

    let mut pb: i32= list.pop_back();
    if (pb != 30)            { return 7; }
    if (list.size() != 2)   { return 8; }

    list.clear();
    if (!list.is_empty())   { return 9; }
    if (list.size() != 0)   { return 10; }

    a.deinit();
    return 0;
}
