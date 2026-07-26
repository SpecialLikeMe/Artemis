// PASS: nested istruc field defaults should be applied recursively
// when a field's type is itself an istruc with default values

istruc Inner {
    let mut val: i32 = 5;
    let mut tag: i32 = 99;
    fn get(self: *Inner) i32 { return self.val; }
}

istruc Outer {
    let mut inner: Inner;
    let mut extra: i32 = 10;
    fn total(self: *Outer) i32 { return self.inner.get() + self.extra; }
}

istruc DeepInner {
    let mut n: i32 = 7;
}

istruc Middle {
    let mut deep: DeepInner;
    let mut m: i32 = 3;
}

istruc Top {
    let mut mid: Middle;
    let mut t: i32 = 1;
    fn sum(self: *Top) i32 {
        return self.mid.deep.n + self.mid.m + self.t;
    }
}

pub fn main() i32 {
    let mut o: Outer;
    // inner.val=5 (Inner default), extra=10 (Outer default)
    if (o.total() != 15) { return 1; }

    o.inner.val = 20;
    o.extra = 3;
    if (o.total() != 23) { return 2; }
    if (o.inner.tag != 99) { return 3; }

    let mut top: Top;
    // deep.n=7, mid.m=3, t=1 → sum=11
    if (top.sum() != 11) { return 4; }

    return 0;
}
