namespace std {
namespace soa {
istruc box<T> {
    T val;
}
istruc soa_layout {
    i32    field_count;
}
soa_layout make_soa() {
    soa_layout layout;
    return layout;
}
} // soa
} // std
i32 main() { return 0; }
