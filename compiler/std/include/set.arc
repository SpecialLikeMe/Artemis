// std.set — Ordered set (red-black tree, equivalent to C++ std.set).

namespace std {

comptime i32 SET_RED   = 0;
comptime i32 SET_BLACK = 1;

istruc set_node<K> {
    let mut key: K;
    let mut color: i32;
    let mut left: *set_node<K>;
    let mut right: *set_node<K>;
    let mut parent: *set_node<K>;
}

istruc set<K> {
    let mut root: *set_node<K>;
    let mut nil: *set_node<K>;
    let mut size_count: i32;

    fn __construct__(self: *set, a: &memstr) void {
        self.nil       = (set_node<K>*)a.mmap(sizeof(set_node<K>)) catch |e| { };
        (*self.nil).color  = SET_BLACK;
        (*self.nil).left   = self.nil;
        (*self.nil).right  = self.nil;
        (*self.nil).parent = self.nil;
        self.root       = self.nil;
        self.size_count = 0;
    }

    fn rotate_left(self: *set, x: *set_node<K>) void {
        let mut y: *set_node<K>= (*x).right;
        (*x).right = (*y).left;
        if ((*y).left != self.nil) (*(*y).left).parent = x;
        (*y).parent = (*x).parent;
        if ((*x).parent == self.nil)        self.root = y;
        else if (x == (*(*x).parent).left)  (*(*x).parent).left = y;
        else                                 (*(*x).parent).right = y;
        (*y).left   = x;
        (*x).parent = y;
    }

    fn rotate_right(self: *set, y: *set_node<K>) void {
        let mut x: *set_node<K>= (*y).left;
        (*y).left = (*x).right;
        if ((*x).right != self.nil) (*(*x).right).parent = y;
        (*x).parent = (*y).parent;
        if ((*y).parent == self.nil)        self.root = x;
        else if (y == (*(*y).parent).left)  (*(*y).parent).left = x;
        else                                 (*(*y).parent).right = x;
        (*x).right  = y;
        (*y).parent = x;
    }

    fn fix_insert(self: *set, z: *set_node<K>) void {
        while ((*(*z).parent).color == SET_RED) {
            if ((*z).parent == (*(*(*z).parent).parent).left) {
                let mut u: *set_node<K>= (*(*(*z).parent).parent).right;
                if ((*u).color == SET_RED) {
                    (*(*z).parent).color = SET_BLACK;
                    (*u).color = SET_BLACK;
                    (*(*(*z).parent).parent).color = SET_RED;
                    z = (*(*z).parent).parent;
                } else {
                    if (z == (*(*z).parent).right) { z = (*z).parent; self.rotate_left(z); }
                    (*(*z).parent).color = SET_BLACK;
                    (*(*(*z).parent).parent).color = SET_RED;
                    self.rotate_right((*(*z).parent).parent);
                }
            } else {
                let mut u: *set_node<K>= (*(*(*z).parent).parent).left;
                if ((*u).color == SET_RED) {
                    (*(*z).parent).color = SET_BLACK;
                    (*u).color = SET_BLACK;
                    (*(*(*z).parent).parent).color = SET_RED;
                    z = (*(*z).parent).parent;
                } else {
                    if (z == (*(*z).parent).left) { z = (*z).parent; self.rotate_right(z); }
                    (*(*z).parent).color = SET_BLACK;
                    (*(*(*z).parent).parent).color = SET_RED;
                    self.rotate_left((*(*z).parent).parent);
                }
            }
        }
        (*self.root).color = SET_BLACK;
    }

    fn insert(self: *set, key: K, a: &memstr) void {
        if (self.contains(key)) { return; }
        let mut z: *set_node<K>= (set_node<K>*)a.mmap(sizeof(set_node<K>)) catch |e| { };
        (*z).key    = key;
        (*z).color  = SET_RED;
        (*z).left   = self.nil; (*z).right = self.nil; (*z).parent = self.nil;
        let mut y: *set_node<K>= self.nil;
        let mut x: *set_node<K>= self.root;
        while (x != self.nil) {
            y = x;
            if (key < (*x).key)  x = (*x).left;
            else                 x = (*x).right;
        }
        (*z).parent = y;
        if (y == self.nil)        self.root = z;
        else if (key < (*y).key)  (*y).left = z;
        else                      (*y).right = z;
        self.fix_insert(z);
        self.size_count = self.size_count + 1;
    }

    fn find_node(self: *set, key: K) *set_node<K> {
        let mut x: *set_node<K>= self.root;
        while (x != self.nil) {
            if (key < (*x).key)  x = (*x).left;
            else if (key > (*x).key) x = (*x).right;
            else return x;
        }
        return self.nil;
    }

    fn contains(self: *set, key: K) bool { return self.find_node(key) != self.nil; }

    fn size(self: *set) i32     { return self.size_count; }
    fn is_empty(self: *set) bool { return self.size_count == 0; }

    fn inorder(self: *set, n: *set_node<K>, cb: void(K)*) void {
        if (n == self.nil) { return; }
        self.inorder((*n).left, cb);
        cb((*n).key);
        self.inorder((*n).right, cb);
    }

    fn each(self: *set, cb: void(K)*) void { self.inorder(self.root, cb); }
}

} // std
