// std.sll — Singly linked list.

namespace std {

istruc sll_node<T> {
    let mut val: T;
    let mut next: *sll_node<T>;
}

istruc sll<T> {
    let mut head: *sll_node<T>;
    let mut tail: *sll_node<T>;
    let mut length: i32;

    fn __construct__(self: *sll) void {
        self.head = (sll_node<T>*)0;
        self.tail = (sll_node<T>*)0;
        self.length = 0;
    }

    fn make_node(self: *sll, val: T, a: &memstr) *sll_node<T> {
        let mut n: *sll_node<T>= (sll_node<T>*)a.mmap(sizeof(sll_node<T>));
        (*n).val  = val;
        (*n).next = (sll_node<T>*)0;
        return n;
    }

    fn push_front(self: *sll, val: T, a: &memstr) void {
        let mut n: *sll_node<T>= self.make_node(val, a);
        (*n).next = self.head;
        self.head = n;
        if (self.tail == (sll_node<T>*)0) { self.tail = n; }
        self.length = self.length + 1;
    }

    fn push_back(self: *sll, val: T, a: &memstr) void {
        let mut n: *sll_node<T>= self.make_node(val, a);
        if (self.tail != (sll_node<T>*)0) { (*self.tail).next = n; }
        else { self.head = n; }
        self.tail = n;
        self.length = self.length + 1;
    }

    fn pop_front(self: *sll) T {
        let mut val: T;
        if (self.head == (sll_node<T>*)0) { return val; }
        let mut n: *sll_node<T>= self.head;
        val = (*n).val;
        self.head = (*n).next;
        if (self.head == (sll_node<T>*)0) { self.tail = (sll_node<T>*)0; }
        self.length = self.length - 1;
        return val;
    }

    fn peek_front(self: *sll) *T {
        if (self.head == (sll_node<T>*)0) { return (T*)0; }
        return &(*self.head).val;
    }

    fn peek_back(self: *sll) *T {
        if (self.tail == (sll_node<T>*)0) { return (T*)0; }
        return &(*self.tail).val;
    }

    fn is_empty(self: *sll) bool { return self.head == (sll_node<T>*)0; }
    fn size(self: *sll) i32     { return self.length; }

    fn contains(self: *sll, val: T) bool {
        let mut n: *sll_node<T>= self.head;
        while (n != (sll_node<T>*)0) {
            if ((*n).val == val) { return true; }
            n = (*n).next;
        }
        return false;
    }

    fn remove_first(self: *sll, val: T) void {
        let mut prev: *sll_node<T>= (sll_node<T>*)0;
        let mut curr: *sll_node<T>= self.head;
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

    fn reverse(self: *sll) void {
        let mut prev: *sll_node<T>= (sll_node<T>*)0;
        let mut curr: *sll_node<T>= self.head;
        self.tail = self.head;
        while (curr != (sll_node<T>*)0) {
            let mut next: *sll_node<T>= (*curr).next;
            (*curr).next = prev;
            prev = curr;
            curr = next;
        }
        self.head = prev;
    }

    fn each(self: *sll, cb: void(T)*) void {
        let mut n: *sll_node<T>= self.head;
        while (n != (sll_node<T>*)0) { cb((*n).val); n = (*n).next; }
    }

    fn clear(self: *sll) void {
        self.head = (sll_node<T>*)0;
        self.tail = (sll_node<T>*)0;
        self.length = 0;
    }
}

} // std
