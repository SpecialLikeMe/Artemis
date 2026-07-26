struct Node {
    let val: i32;
    let next: i32;
}

fn set_val(n: *Node, v: i32) void {
    (*n).val = v;
}

pub fn main() i32 {
    let mut nd: Node;
    nd.val = 0;
    set_val(&nd, 42);
    if (nd.val != 42) { return 1; }

    let mut nd2: Node;
    nd2.val = 10;
    let mut p: *Node= &nd2;
    (*p).val = (*p).val * 3;
    if (nd2.val != 30) { return 2; }
    return 0;
}
