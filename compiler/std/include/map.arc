// std.map — Ordered key-value map (red-black tree, equivalent to C++ std.map).

namespace std {

// Red-black tree colors
comptime i32 MAP_RED   = 0;
comptime i32 MAP_BLACK = 1;

istruc map_node<K, V> {
    let mut key: K;
    let mut val: V;
    let mut color: i32;
    let mut left: *map_node<K,V>;
    let mut right: *map_node<K,V>;
    let mut parent: *map_node<K,V>;
}

istruc map<K, V> {
    let mut root: *map_node<K,V>;
    let mut nil_sentinel: *map_node<K,V>;  // sentinel nil node (BLACK, null children)
    let mut size_count: i32;

    fn make_node(self: *map, key: K, val: V, a: &memstr) *map_node<K,V> {
        let mut n: *map_node<K,V>= (map_node<K,V>*)a.mmap(sizeof(map_node<K,V>)) catch |e| { };
        (*n).key    = key;
        (*n).val    = val;
        (*n).color  = MAP_RED;
        (*n).left   = self.nil_sentinel;
        (*n).right  = self.nil_sentinel;
        (*n).parent = self.nil_sentinel;
        return n;
    }

    fn __construct__(self: *map, a: &memstr) void {
        self.nil_sentinel = (map_node<K,V>*)a.mmap(sizeof(map_node<K,V>)) catch |e| { };
        (*self.nil_sentinel).color  = MAP_BLACK;
        (*self.nil_sentinel).left   = self.nil_sentinel;
        (*self.nil_sentinel).right  = self.nil_sentinel;
        (*self.nil_sentinel).parent = self.nil_sentinel;
        self.root       = self.nil_sentinel;
        self.size_count = 0;
    }

    fn rotate_left(self: *map, x: *map_node<K,V>) void {
        let mut y: *map_node<K,V>= (*x).right;
        (*x).right = (*y).left;
        if ((*y).left != self.nil_sentinel) (*(*y).left).parent = x;
        (*y).parent = (*x).parent;
        if ((*x).parent == self.nil_sentinel) self.root = y;
        else if (x == (*(*x).parent).left) (*(*x).parent).left = y;
        else (*(*x).parent).right = y;
        (*y).left   = x;
        (*x).parent = y;
    }

    fn rotate_right(self: *map, y: *map_node<K,V>) void {
        let mut x: *map_node<K,V>= (*y).left;
        (*y).left = (*x).right;
        if ((*x).right != self.nil_sentinel) (*(*x).right).parent = y;
        (*x).parent = (*y).parent;
        if ((*y).parent == self.nil_sentinel) self.root = x;
        else if (y == (*(*y).parent).left) (*(*y).parent).left = x;
        else (*(*y).parent).right = x;
        (*x).right  = y;
        (*y).parent = x;
    }

    fn fix_insert(self: *map, z: *map_node<K,V>) void {
        while ((*(*z).parent).color == MAP_RED) {
            if ((*z).parent == (*(*(*z).parent).parent).left) {
                let mut y: *map_node<K,V>= (*(*(*z).parent).parent).right;
                if ((*y).color == MAP_RED) {
                    (*(*z).parent).color = MAP_BLACK;
                    (*y).color = MAP_BLACK;
                    (*(*(*z).parent).parent).color = MAP_RED;
                    z = (*(*z).parent).parent;
                } else {
                    if (z == (*(*z).parent).right) {
                        z = (*z).parent;
                        self.rotate_left(z);
                    }
                    (*(*z).parent).color = MAP_BLACK;
                    (*(*(*z).parent).parent).color = MAP_RED;
                    self.rotate_right((*(*z).parent).parent);
                }
            } else {
                let mut y: *map_node<K,V>= (*(*(*z).parent).parent).left;
                if ((*y).color == MAP_RED) {
                    (*(*z).parent).color = MAP_BLACK;
                    (*y).color = MAP_BLACK;
                    (*(*(*z).parent).parent).color = MAP_RED;
                    z = (*(*z).parent).parent;
                } else {
                    if (z == (*(*z).parent).left) {
                        z = (*z).parent;
                        self.rotate_right(z);
                    }
                    (*(*z).parent).color = MAP_BLACK;
                    (*(*(*z).parent).parent).color = MAP_RED;
                    self.rotate_left((*(*z).parent).parent);
                }
            }
        }
        (*self.root).color = MAP_BLACK;
    }

    fn insert(self: *map, key: K, val: V, a: &memstr) void {
        let mut z: *map_node<K,V>= self.make_node(key, val, a);
        let mut y: *map_node<K,V>= self.nil_sentinel;
        let mut x: *map_node<K,V>= self.root;
        while (x != self.nil_sentinel) {
            y = x;
            if (key < (*x).key)       x = (*x).left;
            else if (key > (*x).key)  x = (*x).right;
            else { (*x).val = val; return; } // update existing
        }
        (*z).parent = y;
        if (y == self.nil_sentinel)  self.root = z;
        else if (key < (*y).key)     (*y).left = z;
        else                         (*y).right = z;
        self.fix_insert(z);
        self.size_count = self.size_count + 1;
    }

    fn find_node(self: *map, key: K) *map_node<K,V> {
        let mut x: *map_node<K,V>= self.root;
        while (x != self.nil_sentinel) {
            if (key < (*x).key)       x = (*x).left;
            else if (key > (*x).key)  x = (*x).right;
            else return x;
        }
        return self.nil_sentinel;
    }

    fn contains(self: *map, key: K) bool { return self.find_node(key) != self.nil_sentinel; }

    fn get(self: *map, key: K) *V {
        let mut n: *map_node<K,V>= self.find_node(key);
        if (n == self.nil_sentinel) { return (V*)0; }
        return &(*n).val;
    }

    fn size(self: *map) i32     { return self.size_count; }
    fn is_empty(self: *map) bool { return self.size_count == 0; }

    // In-order traversal via callback
    fn inorder(self: *map, n: *map_node<K,V>, cb: void(K, V)*) void {
        if (n == self.nil_sentinel) { return; }
        self.inorder((*n).left, cb);
        cb((*n).key, (*n).val);
        self.inorder((*n).right, cb);
    }

    fn each(self: *map, cb: void(K, V)*) void { self.inorder(self.root, cb); }
}

} // std
