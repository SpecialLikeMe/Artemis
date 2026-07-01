// std.sll — Singly linked list.

namespace std {

istruc sll_node<T> {
    T            val;
    sll_node<T>* next;
}

istruc sll<T> {
    sll_node<T>* head;
    sll_node<T>* tail;
    i32          length;

    void __construct__(&self) {
        self.head = (sll_node<T>*)0;
        self.tail = (sll_node<T>*)0;
        self.length = 0;
    }

    private sll_node<T>* make_node(&self, T val, &memstr a) {
        sll_node<T>* n = (sll_node<T>*)a.mmap(sizeof(sll_node<T>));
        (*n).val  = val;
        (*n).next = (sll_node<T>*)0;
        return n;
    }

    void push_front(&self, T val, &memstr a) {
        sll_node<T>* n = self.make_node(val, a);
        (*n).next = self.head;
        self.head = n;
        if (self.tail == (sll_node<T>*)0) { self.tail = n; }
        self.length = self.length + 1;
    }

    void push_back(&self, T val, &memstr a) {
        sll_node<T>* n = self.make_node(val, a);
        if (self.tail != (sll_node<T>*)0) { (*self.tail).next = n; }
        else { self.head = n; }
        self.tail = n;
        self.length = self.length + 1;
    }

    T pop_front(&self) {
        sll_node<T>* n = self.head;
        T val = (*n).val;
        self.head = (*n).next;
        if (self.head == (sll_node<T>*)0) { self.tail = (sll_node<T>*)0; }
        self.length = self.length - 1;
        return val;
    }

    T* peek_front(&self) {
        if (self.head == (sll_node<T>*)0) { return (T*)0; }
        return &(*self.head).val;
    }

    T* peek_back(&self) {
        if (self.tail == (sll_node<T>*)0) { return (T*)0; }
        return &(*self.tail).val;
    }

    bool is_empty(&self) { return self.head == (sll_node<T>*)0; }
    i32  size(&self)     { return self.length; }

    bool contains(&self, T val) {
        sll_node<T>* n = self.head;
        while (n != (sll_node<T>*)0) {
            if ((*n).val == val) { return true; }
            n = (*n).next;
        }
        return false;
    }

    void remove_first(&self, T val) {
        sll_node<T>* prev = (sll_node<T>*)0;
        sll_node<T>* curr = self.head;
        while (curr != (sll_node<T>*)0) {
            if ((*curr).val == val) {
                if (prev == (sll_node<T>*)0) self.head = (*curr).next;
                else (*prev).next = (*curr).next;
                if ((*curr).next == (sll_node<T>*)0) self.tail = prev;
                self.length = self.length - 1;
                return;
            }
            prev = curr; curr = (*curr).next;
        }
    }

    void reverse(&self) {
        sll_node<T>* prev = (sll_node<T>*)0;
        sll_node<T>* curr = self.head;
        self.tail = self.head;
        while (curr != (sll_node<T>*)0) {
            sll_node<T>* next = (*curr).next;
            (*curr).next = prev;
            prev = curr;
            curr = next;
        }
        self.head = prev;
    }

    void each(&self, void(T)* cb) {
        sll_node<T>* n = self.head;
        while (n != (sll_node<T>*)0) { cb((*n).val); n = (*n).next; }
    }

    void clear(&self) {
        self.head = (sll_node<T>*)0;
        self.tail = (sll_node<T>*)0;
        self.length = 0;
    }
}

} // std
