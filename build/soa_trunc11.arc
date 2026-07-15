namespace std {
namespace soa {
comptime i32 SOA_MAX_FIELDS = 64;
istruc soa_layout {
    void*  block;
    u64    block_size;
    void*  field_ptrs[SOA_MAX_FIELDS];
    i32    field_count;
    i32    element_count;
}
} // soa
} // std
i32 main() { return 0; }
