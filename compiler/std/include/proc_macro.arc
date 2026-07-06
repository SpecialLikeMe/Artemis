// std.proc_macro — Procedural macro support types and intrinsics.
//
// Usage:
//   use std.proc_macro;
//
//   proc_macro my_macro(tokenstream input) -> tokenstream {
//       // manipulate input.tokens, build output with quote{}
//       return quote{ ... };
//   }
//
//   #[my_macro]
//   istruc Foo { ... }

namespace std {

// A tokenstream is an opaque sequence of tokens passed to and returned from proc macros.
// The `tokens` field holds the raw token text; actual token objects are managed internally.
istruc tokenstream {
    i8*  tokens;  // null-terminated, space-separated token text
    i32  length;  // number of tokens in the stream

    void __construct__(tokenstream* self) {
        self.tokens = (i8*)0;
        self.length = 0;
    }

    // Return the number of tokens.
    i32 len(tokenstream* self) {
        return self.length;
    }

    // Return true if the stream is empty.
    bool is_empty(tokenstream* self) {
        return self.length == 0;
    }
}

} // namespace std
