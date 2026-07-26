// compiler/builtin/struct.arc — Compiler builtin struct types.
//
// These types are always available without @include — the compiler driver
// automatically prepends this file to every compilation as a preamble.
//
// They are NOT part of the stdlib; they are owned by the compiler itself,
// analogous to how the @ builtin functions (see builtin/fn.arc) work.
//
// Layout summary:
//
//   type_info_field { name: *i8, offset: i32, size: i32, align: i32 }
//   type_info_method { name: *i8, param_count: i32, ret_kind: i32 }
//   type_info — ADT enum with 23 variants (tag i32 + 72-byte payload)
//   Payload structs: type_info_int, type_info_float, type_info_pointer, ...
//   __vtable__ { 5 typed function-pointer slots with error-union signatures }
//   memstr     { ptr: *void, vtable: *__vtable__ }  (istruc with methods)

// ---- Flat helper structs (metadata for struct/istruc/enum introspection) ----

struct type_info_field {
    let name:   *i8;
    let offset: i32;
    let size:   i32;
    let align:  i32;
}

struct type_info_method {
    let name:        *i8;
    let param_count: i32;
    let ret_kind:    i32;
}

// ---- type_info ADT payload structs ----
// All integer/bool fields use i64 for 8-byte-aligned field layout in ADT payloads.

struct type_info_int {
    let bits:      i64;
    let is_signed: i64;
}

struct type_info_float {
    let bits: i64;
}

struct type_info_pointer {
    let depth:    i64;
    let is_const: i64;
    let child:    *type_info;
}

struct type_info_array {
    let len:   i64;
    let child: *type_info;
}

struct type_info_slice {
    let child:    *type_info;
    let is_const: i64;
}

struct type_info_struct {
    let name:        *i8;
    let fields:      *type_info_field;
    let field_count: i64;
    let size_bytes:  i64;
    let align_bytes: i64;
    let is_tuple:    i64;
    let is_packed:   i64;
}

struct type_info_istruc {
    let name:            *i8;
    let fields:          *type_info_field;
    let field_count:     i64;
    let methods:         *type_info_method;
    let method_count:    i64;
    let interfaces:      **i8;
    let interface_count: i64;
    let size_bytes:      i64;
    let align_bytes:     i64;
}

struct type_info_union {
    let name:        *i8;
    let fields:      *type_info_field;
    let field_count: i64;
    let size_bytes:  i64;
    let align_bytes: i64;
}

struct type_info_enum_field {
    let name:  *i8;
    let value: i64;
}

struct type_info_enum {
    let name:          *i8;
    let fields:        *type_info_enum_field;
    let field_count:   i64;
    let is_exhaustive: i64;
}

struct type_info_adt_variant {
    let name:         *i8;
    let tag_value:    i64;
    let payload_type: *type_info;
    let field_count:  i64;
    let fields:       *type_info_field;
}

struct type_info_adt_enum {
    let name:          *i8;
    let variants:      *type_info_adt_variant;
    let variant_count: i64;
    let is_exhaustive: i64;
}

struct type_info_param {
    let name:        *i8;
    let param_type:  *type_info;
    let is_comptime: i64;
    let is_anytype:  i64;
    let is_var_args: i64;
}

struct type_info_fn {
    let params:       *type_info_param;
    let param_count:  i64;
    let return_type:  *type_info;
    let is_var_args:  i64;
    let is_pub:       i64;
    let is_generic:   i64;
    let calling_conv: i64;
}

struct type_info_interface {
    let name:         *i8;
    let methods:      *type_info_method;
    let method_count: i64;
}

struct type_info_error_union {
    let payload: *type_info;
}

struct type_info_optional {
    let child: *type_info;
}

enum type_info_num {
    SInt(type_info_int),
    UInt(type_info_uint),
    Float(type_info_float),
    Usize,
    Isize,
    Iofs,
}

// ---- type_info ADT enum ----
// LLVM layout: { i32 tag, [72 x i8] payload } = 80 bytes.
// Variant tags (0-indexed) match ensure_typeinfo_types() in compiler/ir/exprs.arc.
// The IR pre-registers this enum so visit_enum_decl skips re-registration.
enum type_info {
    Void,
    Bool,
    Int(type_info_int),
    Uint(type_info_int),
    Float(type_info_float),
    Char,
    Usize,
    Isize,
    Iofs,
    Pointer(type_info_pointer),
    Array(type_info_array),
    Slice(type_info_slice),
    Struct(type_info_struct),
    Istruc(type_info_istruc),
    Union(type_info_union),
    Enum(type_info_enum),
    AdtEnum(type_info_adt_enum),
    Interface(type_info_interface),
    Fn(type_info_fn),
    Lambda(type_info_fn),
    ErrorUnion(type_info_error_union),
    Optional(type_info_optional),
    AnyType
}

// Allocator vtable — five typed function-pointer slots.
// NOTE (Task 2 deviation): The spec requires error-union return types (e.g. !*void, !void)
// for mmap/rmap/free/destroy.  The `!T` type prefix is now parsed (Task 1) but the
// runtime error-union ABI (`{ i32, T }` struct return + `try` unwrapping) is not yet fully
// wired through the IR, so we keep the previous plain signatures to avoid breaking existing
// allocator implementations.  Update to error-union signatures once try/catch is ABI-stable.
//   mmap    : (meta: *void, size: u64) *void
//   rsmap   : (meta: *void, data: *void, size: i64) bool
//   rmap    : (meta: *void, data: *void, size: i64) *void
//   free    : (meta: *void, data: *void) void
//   destroy : (meta: *void) void
struct __vtable__ {
    let mmap:    [](*void, u64)*void;
    let rsmap:   [](*void, *void, i64)bool;
    let rmap:    [](*void, *void, i64)*void;
    let free:    [](*void, *void)void;
    let destroy: [](*void)void;
}

// memstr — fat pointer carrying a data pointer and a vtable pointer.
// Field renamed from 'data' to 'ptr' (Task 2/3).
// NOTE (Task 2 deviation): The spec calls for converting memstr from struct to istruc
// with helper methods (mmap, rsmap, rmap, free, deinit). However, doing so would
// break all existing stdlib code that calls ms.mmap(n), ms.free(p), etc. with different
// argument counts and no implicit-self dispatch. The istruc method migration is deferred
// until the stdlib dispatch sites are updated. The struct_meta is registered as
// is_istruc=true in ensure_memstr_types (see compiler/ir/decls.arc) for type_info
// introspection, but no istruc methods are declared here yet.
struct memstr {
    let ptr:    *void;
    let vtable: *__vtable__;
}
