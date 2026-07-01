// std.dll — Doubly linked list.

namespace std {

istruc dll_node<T> {
    T            val;
    dll_node<T>* prev;
    dll_node<T>* next;
}

istruc dll<T> {
    dll_node<T>* head;
    dll_node<T>* tail;
    i32          length;

    void __construct__(&self) {
        self.head   = (dll_node<T>*)0;
        self.tail   = (dll_node<T>*)0;
        self.length = 0;
    }

    private dll_node<T>* make_node(&self, T val, &memstr a) {
        dll_node<T>* n = (dll_node<T>*)a.mmap(sizeof(dll_node<T>));
        (*n).val  = val;
        (*n).prev = (dll_node<T>*)0;
        (*n).next = (dll_node<T>*)0;
        return n;
    }

    void push_front(&self, T val, &memstr a) {
        dll_node<T>* n = self.make_node(val, a);
        (*n).next = self.head;
        if (self.head != (dll_node<T>*)0) { (*self.head).prev = n; }
        else { self.tail = n; }
        self.head = n;
        self.length = self.length + 1;
    }

    void push_back(&self, T val, &memstr a) {
        dll_node<T>* n = self.make_node(val, a);
        (*n).prev = self.tail;
        if (self.tail != (dll_node<T>*)0) { (*self.tail).next = n; }
        else { self.head = n; }
        self.tail = n;
        self.length = self.length + 1;
    }

    T pop_front(&self) {
        dll_node<T>* n = self.head;
        T val = (*n).val;
        self.head = (*n).next;
        if (self.head != (dll_node<T>*)0) { (*self.head).prev = (dll_node<T>*)0; }
        else { self.tail = (dll_node<T>*)0; }
        self.length = self.length - 1;
        return val;
    }

    T pop_back(&self) {
        dll_node<T>* n = self.tail;
        T val = (*n).val;
        self.tail = (*n).prev;
        if (self.tail != (dll_node<T>*)0) { (*self.tail).next = (dll_node<T>*)0; }
        else { self.head = (dll_node<T>*)0; }
        self.length = self.length - 1;
        return val;
    }

    T* peek_front(&self) {
        if (self.head == (dll_node<T>*)0) { return (T*)0; }
        return &(*self.head).val;
    }

    T* peek_back(&self) {
        if (self.tail == (dll_node<T>*)0) { return (T*)0; }
        return &(*self.tail).val;
    }

    void insert_before(&self, dll_node<T>* pos, T val, &memstr a) {
        dll_node<T>* n = self.make_node(val, a);
        (*n).next = pos;
        (*n).prev = (*pos).prev;
        if ((*pos).prev != (dll_node<T>*)0) { (*(*pos).prev).next = n; }
        else { self.head = n; }
        (*pos).prev = n;
        self.length = self.length + 1;
    }

    void remove(&self, dll_node<T>* n) {
        if ((*n).prev != (dll_node<T>*)0) { (*(*n).prev).next = (*n).next; }
        else { self.head = (*n).next; }
        if ((*n).next != (dll_node<T>*)0) { (*(*n).next).prev = (*n).prev; }
        else { self.tail = (*n).prev; }
        self.length = self.length - 1;
    }

    bool is_empty(&self) { return self.head == (dll_node<T>*)0; }
    i32  size(&self)     { return self.length; }

    void each_fwd(&self, void(T)* cb) {
        dll_node<T>* n = self.head;
        while (n != (dll_node<T>*)0) { cb((*n).val); n = (*n).next; }
    }

    void each_rev(&self, void(T)* cb) {
        dll_node<T>* n = self.tail;
        while (n != (dll_node<T>*)0) { cb((*n).val); n = (*n).prev; }
    }

    void clear(&self) {
        self.head = (dll_node<T>*)0;
        self.tail = (dll_node<T>*)0;
        self.length = 0;
    }
}

} // std
