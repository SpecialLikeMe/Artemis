// std.map — Ordered key-value map (red-black tree, equivalent to C++ std::map).

namespace std {

// Red-black tree colors
constexpr i32 MAP_RED   = 0;
constexpr i32 MAP_BLACK = 1;

istruc map_node<K, V> {
    K           key;
    V           val;
    i32         color;
    map_node<K,V>* left;
    map_node<K,V>* right;
    map_node<K,V>* parent;
}

istruc map<K, V> {
    map_node<K,V>* root;
    map_node<K,V>* nil_sentinel;  // sentinel nil node (BLACK, null children)
    i32            size_count;

    private map_node<K,V>* make_node(&self, K key, V val, &memstr a) {
        map_node<K,V>* n = (map_node<K,V>*)a.mmap(sizeof(map_node<K,V>));
        (*n).key    = key;
        (*n).val    = val;
        (*n).color  = MAP_RED;
        (*n).left   = self.nil_sentinel;
        (*n).right  = self.nil_sentinel;
        (*n).parent = self.nil_sentinel;
        return n;
    }

    void __construct__(&self, &memstr a) {
        self.nil_sentinel = (map_node<K,V>*)a.mmap(sizeof(map_node<K,V>));
        (*self.nil_sentinel).color  = MAP_BLACK;
        (*self.nil_sentinel).left   = self.nil_sentinel;
        (*self.nil_sentinel).right  = self.nil_sentinel;
        (*self.nil_sentinel).parent = self.nil_sentinel;
        self.root       = self.nil_sentinel;
        self.size_count = 0;
    }

    private void rotate_left(&self, map_node<K,V>* x) {
        map_node<K,V>* y = (*x).right;
        (*x).right = (*y).left;
        if ((*y).left != self.nil_sentinel) (*(*y).left).parent = x;
        (*y).parent = (*x).parent;
        if ((*x).parent == self.nil_sentinel) self.root = y;
        else if (x == (*(*x).parent).left) (*(*x).parent).left = y;
        else (*(*x).parent).right = y;
        (*y).left   = x;
        (*x).parent = y;
    }

    private void rotate_right(&self, map_node<K,V>* y) {
        map_node<K,V>* x = (*y).left;
        (*y).left = (*x).right;
        if ((*x).right != self.nil_sentinel) (*(*x).right).parent = y;
        (*x).parent = (*y).parent;
        if ((*y).parent == self.nil_sentinel) self.root = x;
        else if (y == (*(*y).parent).left) (*(*y).parent).left = x;
        else (*(*y).parent).right = x;
        (*x).right  = y;
        (*y).parent = x;
    }

    private void fix_insert(&self, map_node<K,V>* z) {
        while ((*(*z).parent).color == MAP_RED) {
            if ((*z).parent == (*(*(*z).parent).parent).left) {
                map_node<K,V>* y = (*(*(*z).parent).parent).right;
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
                map_node<K,V>* y = (*(*(*z).parent).parent).left;
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

    void insert(&self, K key, V val, &memstr a) {
        map_node<K,V>* z = self.make_node(key, val, a);
        map_node<K,V>* y = self.nil_sentinel;
        map_node<K,V>* x = self.root;
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

    private map_node<K,V>* find_node(&self, K key) {
        map_node<K,V>* x = self.root;
        while (x != self.nil_sentinel) {
            if (key < (*x).key)       x = (*x).left;
            else if (key > (*x).key)  x = (*x).right;
            else return x;
        }
        return self.nil_sentinel;
    }

    bool contains(&self, K key) { return self.find_node(key) != self.nil_sentinel; }

    V* get(&self, K key) {
        map_node<K,V>* n = self.find_node(key);
        if (n == self.nil_sentinel) { return (V*)0; }
        return &(*n).val;
    }

    i32  size(&self)     { return self.size_count; }
    bool is_empty(&self) { return self.size_count == 0; }

    // In-order traversal via callback
    private void inorder(&self, map_node<K,V>* n, void(K, V)* cb) {
        if (n == self.nil_sentinel) { return; }
        self.inorder((*n).left, cb);
        cb((*n).key, (*n).val);
        self.inorder((*n).right, cb);
    }

    void each(&self, void(K, V)* cb) { self.inorder(self.root, cb); }
}

} // std
