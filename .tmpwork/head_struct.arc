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

// memstr — the allocator fat pointer: a metadata pointer plus its vtable.
//
// This is a compiler builtin and carries its own helper methods; it is not a stdlib
// type and must not be split behind a wrapper. The five vtable operations keep their
// names (mmap/rsmap/rmap/free/destroy) and forward through the vtable; the remaining
// methods are the human-usable layer on top of them.
istruc memstr {
    let ptr:    *void;
    let vtable: *__vtable__;

    // ---- The five vtable operations ----
    // Each forwards to its slot, passing the allocator's own metadata pointer as the
    // implicit first argument so callers never handle it.
    //
    // A memstr may implement only the operations that make sense for it (a bump
    // allocator has no per-object free), leaving those slots null. Calling an
    // unimplemented operation is a no-op, not a crash.

    fn mmap(self: *memstr, size: u64) *void {
        if (self.vtable.mmap == (void*)0) { return (void*)0; }
        return self.vtable.mmap(self.ptr, size);
    }

    // Resize in place. Returns false if it could not be done, in which case the
    // memory is guaranteed unchanged.
    fn rsmap(self: *memstr, data: *void, size: iofs) bool {
        if (self.vtable.rsmap == (void*)0) { return false; }
        return self.vtable.rsmap(self.ptr, data, size);
    }

    // Resize, moving the allocation if an in-place resize is not possible.
    // Returns the (possibly new) pointer, or null on failure.
    fn rmap(self: *memstr, data: *void, size: iofs) *void {
        if (self.rsmap(data, size)) { return data; }
        if (self.vtable.rmap == (void*)0) { return (void*)0; }
        return self.vtable.rmap(self.ptr, data, size);
    }

    fn free(self: *memstr, data: *void) void {
        if (data == (void*)0) { return; }            // freeing null is a no-op
        if (self.vtable.free == (void*)0) { return; } // allocator has no per-object free
        self.vtable.free(self.ptr, data);
    }

    // Release everything the allocator is holding.
    fn destroy(self: *memstr) void {
        if (self.vtable.destroy == (void*)0) { return; }
        self.vtable.destroy(self.ptr);
    }

    fn deinit(self: *memstr) void {   // spelling used by `defer a.deinit()`
        self.destroy();
    }

    // ---- Human-usable layer ----

    // Allocate storage for one T and return a typed pointer, or null.
    // This is the type-safe form of mmap: the size comes from the type.
    fn create(self: *memstr, comptime T: type) *T {
        return (T*)self.vtable.mmap(self.ptr, (u64)@csizeof(T));
    }

    // Allocate storage for `n` contiguous T.
    fn create_n(self: *memstr, comptime T: type, n: u64) *T {
        return (T*)self.vtable.mmap(self.ptr, (u64)@csizeof(T) * n);
    }

    // Allocate `size` bytes and zero them.
    fn zeroed(self: *memstr, size: u64) *void {
        let mut p: *void= self.vtable.mmap(self.ptr, size);
        if (p == (void*)0) { return p; }
        let mut b: *u8= (u8*)p;
        let mut i: u64= 0;
        while (i < size) { b[i] = (u8)0; i = i + 1; }
        return p;
    }

    // True when the last allocation request could not be served. Callers that want a
    // hard failure can branch on this instead of comparing against null themselves.
    fn failed(self: *memstr, p: *void) bool { return p == (void*)0; }
}
