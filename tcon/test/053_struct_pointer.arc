struct Node {
    i32 val;
    i32 next;
}

void set_val(Node* n, i32 v) {
    n->val = v;
}

i32 main() {
    Node nd;
    nd.val = 0;
    set_val(&nd, 42);
    if (nd.val != 42) { return 1; }

    Node nd2;
    nd2.val = 10;
    Node* p = &nd2;
    p->val = p->val * 3;
    if (nd2.val != 30) { return 2; }
    return 0;
}
