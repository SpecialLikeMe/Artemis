// std.set — Ordered set (red-black tree, equivalent to C++ std::set).

namespace std {

constexpr i32 SET_RED   = 0;
constexpr i32 SET_BLACK = 1;

istruc set_node<K> {
    K           key;
    i32         color;
    set_node<K>* left;
    set_node<K>* right;
    set_node<K>* parent;
}

istruc set<K> {
    set_node<K>* root;
    set_node<K>* nil;
    i32          size_count;

    void __construct__(set* self, &memstr a) {
        self.nil       = (set_node<K>*)a.mmap(sizeof(set_node<K>));
        (*self.nil).color  = SET_BLACK;
        (*self.nil).left   = self.nil;
        (*self.nil).right  = self.nil;
        (*self.nil).parent = self.nil;
        self.root       = self.nil;
        self.size_count = 0;
    }

    private void rotate_left(set* self, set_node<K>* x) {
        set_node<K>* y = (*x).right;
        (*x).right = (*y).left;
        if ((*y).left != self.nil) (*(*y).left).parent = x;
        (*y).parent = (*x).parent;
        if ((*x).parent == self.nil)        self.root = y;
        else if (x == (*(*x).parent).left)  (*(*x).parent).left = y;
        else                                 (*(*x).parent).right = y;
        (*y).left   = x;
        (*x).parent = y;
    }

    private void rotate_right(set* self, set_node<K>* y) {
        set_node<K>* x = (*y).left;
        (*y).left = (*x).right;
        if ((*x).right != self.nil) (*(*x).right).parent = y;
        (*x).parent = (*y).parent;
        if ((*y).parent == self.nil)        self.root = x;
        else if (y == (*(*y).parent).left)  (*(*y).parent).left = x;
        else                                 (*(*y).parent).right = x;
        (*x).right  = y;
        (*y).parent = x;
    }

    private void fix_insert(set* self, set_node<K>* z) {
        while ((*(*z).parent).color == SET_RED) {
            if ((*z).parent == (*(*(*z).parent).parent).left) {
                set_node<K>* u = (*(*(*z).parent).parent).right;
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
                set_node<K>* u = (*(*(*z).parent).parent).left;
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

    void insert(set* self, K key, &memstr a) {
        if (self.contains(key)) { return; }
        set_node<K>* z = (set_node<K>*)a.mmap(sizeof(set_node<K>));
        (*z).key    = key;
        (*z).color  = SET_RED;
        (*z).left   = self.nil; (*z).right = self.nil; (*z).parent = self.nil;
        set_node<K>* y = self.nil;
        set_node<K>* x = self.root;
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

    private set_node<K>* find_node(set* self, K key) {
        set_node<K>* x = self.root;
        while (x != self.nil) {
            if (key < (*x).key)  x = (*x).left;
            else if (key > (*x).key) x = (*x).right;
            else return x;
        }
        return self.nil;
    }

    bool contains(set* self, K key) { return self.find_node(key) != self.nil; }

    i32  size(set* self)     { return self.size_count; }
    bool is_empty(set* self) { return self.size_count == 0; }

    private void inorder(set* self, set_node<K>* n, void(K)* cb) {
        if (n == self.nil) { return; }
        self.inorder((*n).left, cb);
        cb((*n).key);
        self.inorder((*n).right, cb);
    }

    void each(set* self, void(K)* cb) { self.inorder(self.root, cb); }
}

} // std
