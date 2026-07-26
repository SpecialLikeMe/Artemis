// SMT claim: no borrow checker mental overhead or friction — no lifetime annotations,
// no ownership rules, no single-writer constraints enforced by the type system.
// The programmer writes natural C-style pointer code; the SMT tracks pointer states
// (VALID / NULL / FREED / MAYBE_NULL) independently per variable, without imposing
// Rust-style uniqueness or lifetime requirements.
//
// Patterns exercised (all compile and run correctly; SMT emits no BAD verdicts):
//   A — Multiple simultaneous aliases to the same object (would be &mut / RefCell in Rust)
//   B — Self-referential linked list (Node* next pointing within the same stack frame)
//   C — Pointer stored inside a struct, aliased externally
//   D — Swap-via-pointer (two pointers to the same array, cross-written)
//   E — Re-borrowing: p1 assigned from p2, both used after
@unsafe extern fn printf(fmt: *i8, ...) i32;

// ---- A: Multiple simultaneous mutable aliases ----
// In Rust this would require RefCell<i32> or unsafe raw pointers.
// In Artemis, p1 and p2 can both alias x; the SMT tracks both as VALID.
fn alias_sum(x: *i32) i32 {
    let mut p1: *i32= x;
    let mut p2: *i32= x;   // both alias x — no friction
    (*p1) = 10;
    (*p2) = (*p2) + 5;   // p1 and p2 alias; result is 15
    return (*x);
}

// ---- B: Self-referential singly-linked list on the stack ----
// In Rust, self-referential structs require Pin<Box<...>> and unsafe.
// Here, Node just holds a raw pointer to the next Node — no annotations needed.
struct Node { let val: i32; let next: *Node; }

fn list_sum(head: *Node) i32 {
    let mut s: i32= 0;
    let mut cur: *Node= head;
    while (cur != (Node*)0) {
        s = s + cur.val;
        cur = cur.next;
    }
    return s;
}

// ---- C: Pointer stored inside struct, aliased externally ----
struct Holder { let data: *i32; let n: i32; }

fn holder_sum(h: *Holder) i32 {
    let mut s: i32= 0; let mut i: i32= 0;
    while (i < h.n) { s = s + h.data[i]; i = i + 1; }
    return s;
}

// ---- D: Swap via pointers ----
fn swap(a: *i32, b: *i32) void {
    let mut tmp: i32= (*a);
    (*a) = (*b);
    (*b) = tmp;
}

// ---- E: Re-borrow — assign p1 from p2, use both ----
fn reborrow(arr: *i32) i32 {
    let mut p1: *i32= arr;         // p1 → arr[0..N]
    let mut p2: *i32= arr + 1;    // p2 → arr[1..N]
    let mut p3: *i32= p2;          // p3 re-borrows p2 — no friction
    (*p1) = 7;
    (*p3) = 13;            // writes arr[1]
    return (*p1) + (*p2);  // 7 + 13 = 20
}

pub @unsafe fn main() i32 {
    // A: simultaneous aliases
    let mut x: i32= 0;
    if (alias_sum(&x) != 15) { printf("FAIL alias_sum\n"); return 1; }

    // B: stack-allocated linked list — 3 nodes
    let mut n3: Node; n3.val = 30; n3.next = (Node*)0;
    let mut n2: Node; n2.val = 20; n2.next = &n3;
    let mut n1: Node; n1.val = 10; n1.next = &n2;
    if (list_sum(&n1) != 60) { printf("FAIL list_sum\n"); return 2; }

    // Single-node list
    let mut solo: Node; solo.val = 99; solo.next = (Node*)0;
    if (list_sum(&solo) != 99) { printf("FAIL list single\n"); return 3; }

    // Empty list
    if (list_sum((Node*)0) != 0) { printf("FAIL list empty\n"); return 4; }

    // C: pointer stored in struct
    let mut data: [4]i32; data[0]=1; data[1]=2; data[2]=3; data[3]=4;
    let mut h: Holder; h.data = data; h.n = 4;
    if (holder_sum(&h) != 10) { printf("FAIL holder_sum\n"); return 5; }

    // External alias of h.data still works
    let mut alias: *i32= h.data;
    alias[0] = 10;
    if (holder_sum(&h) != 19) { printf("FAIL holder alias\n"); return 6; }

    // D: swap
    let mut a: i32= 5; let mut b: i32= 9;
    swap(&a, &b);
    if (a != 9 || b != 5) { printf("FAIL swap a=%d b=%d\n", a, b); return 7; }

    // Swap same pointer (a, a) — no UB: tmp=a, a=a, a=tmp
    swap(&a, &a);
    if (a != 9) { printf("FAIL swap self\n"); return 8; }

    // E: reborrow
    let mut arr: [3]i32; arr[0]=0; arr[1]=0; arr[2]=0;
    if (reborrow(arr) != 20) { printf("FAIL reborrow\n"); return 9; }
    if (arr[0] != 7)  { printf("FAIL reborrow arr0\n"); return 10; }
    if (arr[1] != 13) { printf("FAIL reborrow arr1\n"); return 11; }

    return 0;
}
