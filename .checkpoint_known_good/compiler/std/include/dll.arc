// std.dll — Doubly linked list.

namespace std {

istruc dll_node<T> {
    let mut val: T;
    let mut prev: *dll_node<T>;
    let mut next: *dll_node<T>;
}

istruc dll<T> {
    let mut head: *dll_node<T>;
    let mut tail: *dll_node<T>;
    let mut length: i32;

    fn __construct__(self: *dll) void {
        self.head   = (dll_node<T>*)0;
        self.tail   = (dll_node<T>*)0;
        self.length = 0;
    }

    fn make_node(self: *dll, val: T, a: &memstr) *dll_node<T> {
        let mut n: *dll_node<T>= (dll_node<T>*)a.mmap(sizeof(dll_node<T>));
        (*n).val  = val;
        (*n).prev = (dll_node<T>*)0;
        (*n).next = (dll_node<T>*)0;
        return n;
    }

    fn push_front(self: *dll, val: T, a: &memstr) void {
        let mut n: *dll_node<T>= self.make_node(val, a);
        (*n).next = self.head;
        if (self.head != (dll_node<T>*)0) { (*self.head).prev = n; }
        else { self.tail = n; }
        self.head = n;
        self.length = self.length + 1;
    }

    fn push_back(self: *dll, val: T, a: &memstr) void {
        let mut n: *dll_node<T>= self.make_node(val, a);
        (*n).prev = self.tail;
        if (self.tail != (dll_node<T>*)0) { (*self.tail).next = n; }
        else { self.head = n; }
        self.tail = n;
        self.length = self.length + 1;
    }

    fn pop_front(self: *dll) T {
        let mut val: T;
        if (self.head == (dll_node<T>*)0) { return val; }
        let mut n: *dll_node<T>= self.head;
        val = (*n).val;
        self.head = (*n).next;
        if (self.head != (dll_node<T>*)0) { (*self.head).prev = (dll_node<T>*)0; }
        else { self.tail = (dll_node<T>*)0; }
        self.length = self.length - 1;
        return val;
    }

    fn pop_back(self: *dll) T {
        let mut val: T;
        if (self.tail == (dll_node<T>*)0) { return val; }
        let mut n: *dll_node<T>= self.tail;
        val = (*n).val;
        self.tail = (*n).prev;
        if (self.tail != (dll_node<T>*)0) { (*self.tail).next = (dll_node<T>*)0; }
        else { self.head = (dll_node<T>*)0; }
        self.length = self.length - 1;
        return val;
    }

    fn peek_front(self: *dll) *T {
        if (self.head == (dll_node<T>*)0) { return (T*)0; }
        return &(*self.head).val;
    }

    fn peek_back(self: *dll) *T {
        if (self.tail == (dll_node<T>*)0) { return (T*)0; }
        return &(*self.tail).val;
    }

    fn insert_before(self: *dll, pos: *dll_node<T>, val: T, a: &memstr) void {
        let mut n: *dll_node<T>= self.make_node(val, a);
        (*n).next = pos;
        (*n).prev = (*pos).prev;
        if ((*pos).prev != (dll_node<T>*)0) { (*(*pos).prev).next = n; }
        else { self.head = n; }
        (*pos).prev = n;
        self.length = self.length + 1;
    }

    fn remove(self: *dll, n: *dll_node<T>) void {
        if ((*n).prev != (dll_node<T>*)0) { (*(*n).prev).next = (*n).next; }
        else { self.head = (*n).next; }
        if ((*n).next != (dll_node<T>*)0) { (*(*n).next).prev = (*n).prev; }
        else { self.tail = (*n).prev; }
        self.length = self.length - 1;
    }

    fn is_empty(self: *dll) bool { return self.head == (dll_node<T>*)0; }
    fn size(self: *dll) i32     { return self.length; }

    fn each_fwd(self: *dll, cb: void(T)*) void {
        let mut n: *dll_node<T>= self.head;
        while (n != (dll_node<T>*)0) { cb((*n).val); n = (*n).next; }
    }

    fn each_rev(self: *dll, cb: void(T)*) void {
        let mut n: *dll_node<T>= self.tail;
        while (n != (dll_node<T>*)0) { cb((*n).val); n = (*n).prev; }
    }

    fn clear(self: *dll) void {
        self.head = (dll_node<T>*)0;
        self.tail = (dll_node<T>*)0;
        self.length = 0;
    }
}

} // std
