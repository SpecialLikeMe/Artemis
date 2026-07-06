// std.ifo — Compile-time type reflection (ifo_t / get_ifo_t)
//
// get_ifo_t(T) is a compiler intrinsic that returns a pointer to a statically
// allocated ifo_t describing the type T.  The struct layout is fixed so that
// tooling and generic code can inspect any type uniformly.
//
// Access as: std.ifo.ifo_t, std.ifo.ifo_field_t, etc.

namespace std {
namespace ifo {

// IFO_KIND_* — discriminant for ifo_t.kind
constexpr i32 IFO_KIND_PRIM    = 0;  // primitive (integer / float / bool / char / void)
constexpr i32 IFO_KIND_PTR     = 1;  // pointer
constexpr i32 IFO_KIND_STRUCT  = 2;  // struct
constexpr i32 IFO_KIND_UNION   = 3;  // union
constexpr i32 IFO_KIND_ENUM    = 4;  // enum
constexpr i32 IFO_KIND_ISTRUC  = 5;  // istruc (class)
constexpr i32 IFO_KIND_ARRAY   = 6;  // fixed-size array
constexpr i32 IFO_KIND_FUNC    = 7;  // function pointer
constexpr i32 IFO_KIND_UNKNOWN = 8;  // unresolved / generic parameter

// ifo_field_t — metadata for a single field in a struct/istruc/union.
// Populated by the compiler; fields are in declaration order.
struct ifo_field_t {
    i8* name;    // field name (null-terminated)
    i32 offset;  // byte offset within the parent type
    i32 size;    // byte size of this field
    i32 align;   // byte alignment of this field
}

// ifo_method_t — metadata for a single method in an istruc.
// Populated by the compiler for istruc types; method order matches declaration order.
struct ifo_method_t {
    i8* name;        // method name (null-terminated)
    i32 param_count; // number of parameters (including the self pointer)
    i32 ret_size;    // byte size of the return type (0 for void)
}

// ifo_t — complete type descriptor returned by get_ifo_t(T).
// All fields are set at compile time; the struct is statically allocated
// (you receive a pointer — do not free it).
struct ifo_t {
    i8*                           name;         // canonical type name, e.g. "i32", "MyStruct", "i32*"
    i32                           size;         // total byte size of T (sizeof equivalent)
    i32                           align;        // byte alignment of T
    i32                           kind;         // one of the IFO_KIND_* constants above
    i32                           bits;         // bit-width for primitives (0 for compound types)
    i32                           is_signed;    // 1 for signed integer primitives, 0 otherwise
    i32                           field_count;  // number of named fields (0 for prims/pointers)
    std.ifo.ifo_field_t*        fields;       // array of field descriptors (null when field_count == 0)
    std.ifo.ifo_t*              elem_type;    // for pointers/arrays: element type (null otherwise)
    i32                           method_count; // number of methods (0 for non-istruc types)
    std.ifo.ifo_method_t*       methods;      // array of method descriptors (null when method_count == 0)
}

// Helper: true if T is a numeric primitive (integer or float)
bool ifo_is_numeric(std.ifo.ifo_t* t) {
    return t.kind == IFO_KIND_PRIM && t.bits > 0;
}

// Helper: true if T is a signed integer
bool ifo_is_signed_int(std.ifo.ifo_t* t) {
    return t.kind == IFO_KIND_PRIM && t.is_signed != 0 && t.bits > 0;
}

// Helper: true if T is a pointer type
bool ifo_is_pointer(std.ifo.ifo_t* t) {
    return t.kind == IFO_KIND_PTR;
}

// Helper: find a field by name; returns null if not found.
std.ifo.ifo_field_t* ifo_find_field(std.ifo.ifo_t* t, i8* fname) {
    for (i32 i = 0; i < t.field_count; i = i + 1) {
        i8* fn = t.fields[i].name;
        i32 j = 0;
        bool eq = true;
        while (fn[j] != 0 || fname[j] != 0) {
            if (fn[j] != fname[j]) { eq = false; break; }
            j = j + 1;
        }
        if (eq) { return (t.fields + i); }
    }
    return (std.ifo.ifo_field_t*)0;
}

} // namespace ifo
} // namespace std
