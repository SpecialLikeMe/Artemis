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
//
// Every slot takes the allocator's own metadata pointer (`meta`), which memstr
// supplies from its `ptr` field so callers never handle it.
//
// mmap and rmap take an explicit alignment so an allocator can satisfy the exact
// requirement instead of conservatively over-aligning every request.
//
// Fallible slots return error unions: allocation failure is a value the caller must
// handle, not a null pointer that propagates silently.
//
//   mmap    : (align: usize, meta: *void, size: usize)              !*void
//   rsmap   : (meta: *void, data: *void, size: iofs)                bool
//   rmap    : (align: usize, meta: *void, data: *void, size: iofs)  !*void
//   free    : (meta: *void, data: *void)                            !void
//   destroy : (meta: *void)                                         !void
//
// rsmap returns a plain bool by design: "could not resize in place" is an ordinary
// outcome the caller acts on, not an error condition.
struct __vtable__ {
    let mmap:    [](usize, *void, usize)!*void;
    let rsmap:   [](*void, *void, iofs)bool;
    let rmap:    [](usize, *void, *void, iofs)!*void;
    let free:    [](*void, *void)!void;
    let destroy: [](*void)!void;
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

    // Default alignment for untyped byte allocations: the widest scalar alignment,
    // matching what malloc guarantees. Typed helpers use @alignof instead.
    // (declared as a method so it stays inside the builtin, not a global)
    fn default_align(self: *memstr) usize { return (usize)16; }

    // ---- The five vtable operations ----
    // Each forwards to its slot, supplying the allocator's metadata pointer.
    //
    // A memstr may implement only the operations that make sense for it (a bump
    // allocator has no per-object free), leaving those slots null. Calling an
    // unimplemented operation reports it rather than jumping through null.

    fn mmap(self: *memstr, size: usize) !*void {
        if (self.vtable.mmap == (void*)0) { return error.Unsupported; }
        return try self.vtable.mmap(self.default_align(), self.ptr, size);
    }

    // Allocate `size` bytes aligned to `align`.
    fn mmap_aligned(self: *memstr, align: usize, size: usize) !*void {
        if (self.vtable.mmap == (void*)0) { return error.Unsupported; }
        return try self.vtable.mmap(align, self.ptr, size);
    }

    // Resize in place. False means it could not be done, and the memory is unchanged.
    // This is an outcome, not an error, so it stays a plain bool.
    fn rsmap(self: *memstr, data: *void, size: iofs) bool {
        if (self.vtable.rsmap == (void*)0) { return false; }
        return self.vtable.rsmap(self.ptr, data, size);
    }

    // Resize, moving the allocation if an in-place resize is not possible.
    fn rmap(self: *memstr, data: *void, size: iofs) !*void {
        if (self.rsmap(data, size)) { return data; }
        if (self.vtable.rmap == (void*)0) { return error.Unsupported; }
        return try self.vtable.rmap(self.default_align(), self.ptr, data, size);
    }

    fn free(self: *memstr, data: *void) !void {
        if (data == (void*)0) { return; }             // freeing null is a no-op
        if (self.vtable.free == (void*)0) { return; } // allocator has no per-object free
        try self.vtable.free(self.ptr, data);
    }

    // Release everything the allocator is holding.
    fn destroy(self: *memstr) !void {
        if (self.vtable.destroy == (void*)0) { return; }
        try self.vtable.destroy(self.ptr);
    }

    fn deinit(self: *memstr) !void {   // spelling used by `defer a.deinit()`
        try self.destroy();
    }

    // ---- Human-usable layer ----

    // Allocate storage for one T, aligned for T, and return a typed pointer.
    // This is where the alignment parameter earns its keep: the allocator gets the
    // exact requirement rather than the conservative default.
    fn create(self: *memstr, comptime T: type) !*T {
        let mut raw: *void= try self.mmap_aligned((usize)@alignof(T), (usize)@csizeof(T));
        return (T*)raw;
    }

    // Allocate storage for `n` contiguous T.
    fn create_n(self: *memstr, comptime T: type, n: usize) !*T {
        let mut raw: *void= try self.mmap_aligned((usize)@alignof(T), (usize)@csizeof(T) * n);
        return (T*)raw;
    }

    // Allocate `size` bytes and zero them.
    fn zeroed(self: *memstr, size: usize) !*void {
        let mut p: *void= try self.mmap(size);
        let mut b: *u8= (u8*)p;
        let mut i: usize= 0;
        while (i < size) { b[i] = (u8)0; i = i + 1; }
        return p;
    }
}
