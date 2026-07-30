struct Q { let mut x: i32; let mut y: i32; }
fn bump(q: *Q, f: i32) void { q.x = q.x; }
pub fn main() i32 { let mut q: Q; q.x = 7; bump(&q, 1); if (q.x != 7) { return 1; } return 0; }
