// Test: std.sll — singly linked list with i32 values
extern std.sll;
@unsafe extern fn malloc(n: u64) *void;
@unsafe extern fn free(p: *void) void;

memstr Bump {
    let mut base: *void; let mut used: u64; let mut cap: u64;
    fn __construct__(self: *Bump, n: u64) void { self.base=malloc(n); self.used=0; self.cap=n; }
    fn mmap(self: *Bump, n: u64) *void {
        let mut al: u64=(n+7)&~(u64)7;
        if (self.used+al>self.cap) { return (void*)0; }
        let mut p: *void=(void*)((u8*)self.base+self.used); self.used=self.used+al; return p;
    }
    fn rmap(self: *Bump, p: *void, n: u64) void {}
    fn deinit(self: *Bump) void { free(self.base); }
}

pub fn main() i32 {
    let mut a: Bump(16384);
    let mut list: std.sll<i32>();

    list.push_back(10, a);
    list.push_back(20, a);
    list.push_back(30, a);
    list.push_front(1, a);

    if (list.size() != 4)         { return 1; }
    if (list.is_empty())          { return 2; }
    if (!list.contains(20))       { return 3; }
    if (list.contains(99))        { return 4; }

    let mut front: *i32= list.peek_front();
    if (front == (i32*)0 || *front != 1)  { return 5; }

    let mut back: *i32= list.peek_back();
    if (back == (i32*)0 || *back != 30) { return 6; }

    let mut popped: i32= list.pop_front();
    if (popped != 1)              { return 7; }
    if (list.size() != 3)        { return 8; }

    list.remove_first(20);
    if (list.size() != 2)        { return 9; }
    if (list.contains(20))       { return 10; }

    list.clear();
    if (!list.is_empty())        { return 11; }

    a.deinit();
    return 0;
}
