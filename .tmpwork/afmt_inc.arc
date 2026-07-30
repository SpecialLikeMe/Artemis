@unsafe @link_name("fwrite") extern fn raw_fw(b: *void, s: u64, n: u64, f: *void) u64;
@unsafe @link_name("__acrt_iob_func") extern fn raw_iob(i: u32) *void;
@unsafe @link_name("malloc") extern fn raw_ml(n: u64) *void;
@unsafe @link_name("free") extern fn raw_fr(p: *void) void;
fn fwrite(b: *void, s: u64, n: u64, f: *void) u64 { let mut r: u64; @unsafe { r = raw_fw(b,s,n,f); } return r; }
fn stdout_file() *void { let mut r: *void; @unsafe { r = raw_iob(1u); } return r; }
fn arc_malloc(n: u64) *void { let mut r: *void; @unsafe { r = raw_ml(n); } return r; }
fn arc_free(p: *i8) void { @unsafe { raw_fr((void*)p); } }
// compiler/fmt.arc — type-safe formatting without C varargs.
//
// C's printf family cannot be given a safe wrapper: Arc has no va_list, so a wrapper
// cannot forward its varargs. Instead of calling them, this formats in Arc.
//
// Arguments are passed as an anonymous struct:
//
//     afmt(buf, 256u, "%s: line %d", .{ name, line });
//
// The format specifier says what type each slot holds, and @typeinfo gives the
// struct's field offsets, so each argument is read at its own offset with the type
// the specifier implies. Nothing is guessed from the value itself.
//
// Supported: %s %d %i %u %lld %llu %ld %lu %x %llx %c %f %p %% and %.*s.
// Width/precision between '%' and the conversion is accepted and applied for %s.

namespace afmt_impl {

// Append one character, honouring the capacity. Returns the new length.
fn put(buf: *i8, cap: u64, len: u64, c: i8) u64 {
    if (len + 1u < cap) { buf[len] = c; }
    return len + 1u;
}

fn put_str(buf: *i8, cap: u64, len: u64, s: *i8, maxn: i32) u64 {
    if (s == (i8*)0) { s = "(null)"; }
    let mut n: u64= len;
    let mut i: i32= 0;
    while (s[i] != 0) {
        if (maxn >= 0 && i >= maxn) { break; }
        n = put(buf, cap, n, s[i]);
        i = i + 1;
    }
    return n;
}

// Unsigned integer in the given base. `upper` selects A-F over a-f.
fn put_uint(buf: *i8, cap: u64, len: u64, v: u64, base: u64, upper: bool) u64 {
    let mut tmp: [32]i8;
    let mut n: i32= 0;
    if (v == 0u) { tmp[0] = '0'; n = 1; }
    else {
        let mut x: u64= v;
        while (x > 0u && n < 32) {
            let mut d: u64= x % base;
            let mut c: i8= (d < 10u) ? (i8)((u64)'0' + d) : (i8)((u64)(upper ? 'A' : 'a') + (d - 10u));
            tmp[n] = c;
            n = n + 1;
            x = x / base;
        }
    }
    let mut out: u64= len;
    let mut i: i32= n - 1;
    while (i >= 0) { out = put(buf, cap, out, tmp[i]); i = i - 1; }
    return out;
}

fn put_int(buf: *i8, cap: u64, len: u64, v: i64) u64 {
    let mut out: u64= len;
    if (v < (i64)0) {
        out = put(buf, cap, out, '-');
        // Negate in u64 so i64 min does not overflow.
        let mut mag: u64= (u64)0 - (u64)v;
        return put_uint(buf, cap, out, mag, 10u, false);
    }
    return put_uint(buf, cap, out, (u64)v, 10u, false);
}

// Fixed-point float with 6 fractional digits, matching printf's %f default.
fn put_f64(buf: *i8, cap: u64, len: u64, v: f64) u64 {
    let mut out: u64= len;
    let mut x: f64= v;
    if (x < 0.0) { out = put(buf, cap, out, '-'); x = -x; }
    let mut whole: u64= (u64)x;
    out = put_uint(buf, cap, out, whole, 10u, false);
    out = put(buf, cap, out, '.');
    let mut frac: f64= x - (f64)whole;
    let mut i: i32= 0;
    while (i < 6) {
        frac = frac * 10.0;
        let mut d: u64= (u64)frac;
        if (d > 9u) { d = 9u; }
        out = put(buf, cap, out, (i8)((u64)'0' + d));
        frac = frac - (f64)d;
        i = i + 1;
    }
    return out;
}

} // namespace afmt_impl

// Format into `buf` (always NUL-terminated when cap > 0). Returns the number of
// characters that *would* have been written, like snprintf, so truncation is
// detectable by comparing against cap.
//
// `args` is an anonymous struct; `argp` is its address and `ti` its @typeinfo.
// Kept as an explicit helper so the public entry points stay thin.
fn afmt_v(buf: *i8, cap: u64, fmt: *i8, argp: *u8, fields: *type_info_field, nfields: i32) i32 {
    let mut len: u64= 0u;
    let mut ai: i32= 0;
    let mut i: i32= 0;

    while (fmt[i] != 0) {
        if (fmt[i] != '%') {
            len = afmt_impl.put(buf, cap, len, fmt[i]);
            i = i + 1;
            continue;
        }
        i = i + 1;                      // consume '%'
        if (fmt[i] == '%') { len = afmt_impl.put(buf, cap, len, '%'); i = i + 1; continue; }

        // Optional width / precision. Only '.*' (precision from an argument) and a
        // literal precision are meaningful here; plain width is skipped.
        let mut prec: i32= -1;
        while ((fmt[i] >= '0' && fmt[i] <= '9') || fmt[i] == '-' || fmt[i] == '+') { i = i + 1; }
        if (fmt[i] == '.') {
            i = i + 1;
            if (fmt[i] == '*') {
                i = i + 1;
                if (ai < nfields) {
                    let mut pp: *i32= (i32*)(argp + fields[ai].offset);
                    prec = *pp;
                    ai = ai + 1;
                }
            } else {
                prec = 0;
                while (fmt[i] >= '0' && fmt[i] <= '9') { prec = prec * 10 + (i32)(fmt[i] - '0'); i = i + 1; }
            }
        }

        // Length modifiers: l, ll, h, hh, z.
        let mut long_n: i32= 0;
        while (fmt[i] == 'l') { long_n = long_n + 1; i = i + 1; }
        while (fmt[i] == 'h' || fmt[i] == 'z') { i = i + 1; }

        let mut conv: i8= fmt[i];
        if (conv == 0) { break; }
        i = i + 1;

        if (ai >= nfields) {
            // More specifiers than arguments — emit the specifier literally rather
            // than reading past the end of the struct.
            len = afmt_impl.put(buf, cap, len, '%');
            len = afmt_impl.put(buf, cap, len, conv);
            continue;
        }
        let mut off: *u8= argp + fields[ai].offset;
        let mut fsz: i32= fields[ai].size;
        ai = ai + 1;

        if (conv == 's') {
            let mut sp: **i8= (i8**)off;
            len = afmt_impl.put_str(buf, cap, len, *sp, prec);
        } else if (conv == 'd' || conv == 'i') {
            let mut v: i64= (long_n > 0 || fsz == 8) ? *(i64*)(void*)off : (i64)(*(i32*)(void*)off);
            len = afmt_impl.put_int(buf, cap, len, v);
        } else if (conv == 'u') {
            let mut v: u64= (long_n > 0 || fsz == 8) ? *(u64*)(void*)off : (u64)(*(u32*)(void*)off);
            len = afmt_impl.put_uint(buf, cap, len, v, 10u, false);
        } else if (conv == 'x' || conv == 'X') {
            let mut v: u64= (long_n > 0 || fsz == 8) ? *(u64*)(void*)off : (u64)(*(u32*)(void*)off);
            len = afmt_impl.put_uint(buf, cap, len, v, 16u, conv == 'X');
        } else if (conv == 'c') {
            len = afmt_impl.put(buf, cap, len, (i8)(*(i32*)(void*)off));
        } else if (conv == 'f' || conv == 'g' || conv == 'e') {
            len = afmt_impl.put_f64(buf, cap, len, *(f64*)(void*)off);
        } else if (conv == 'p') {
            let mut pv: *void= *(void**)(void*)off;
            len = afmt_impl.put(buf, cap, len, '0');
            len = afmt_impl.put(buf, cap, len, 'x');
            len = afmt_impl.put_uint(buf, cap, len, (u64)pv, 16u, false);
        } else {
            len = afmt_impl.put(buf, cap, len, '%');
            len = afmt_impl.put(buf, cap, len, conv);
        }
    }

    if (cap > 0u) {
        let mut term: u64= (len < cap) ? len : cap - 1u;
        buf[term] = 0;
    }
    return (i32)len;
}

// ---- Public entry points ----
//
// These replace snprintf/printf. Arguments go in an anonymous struct, so the compiler
// records each one's type and offset and the formatter reads them back with the type
// the specifier names — no C varargs, and therefore no unsafe context needed.
//
//     afmt(buf, 256u, "%s: line %d", .{ name, line });
//     aprint("%s: line %d\n", .{ name, line });

// snprintf replacement. Returns the length that would have been written.
fn afmt(buf: *i8, cap: u64, fmt: *i8, args: anytype) i32 {
    let mut ti: *type_info= @typeinfo(@typeof(args));
    match (*ti) {
        type_info::Struct(nm, flds, nf, sz, al, tup, pk) => {
            let mut argp: *u8= (u8*)&args;
            return afmt_v(buf, cap, fmt, argp, flds, (i32)nf);
        },
        _ => {
            // Not an argument struct (e.g. `.{}` lowered away) — format with no arguments.
            return afmt_v(buf, cap, fmt, (u8*)0, (type_info_field*)0, 0);
        }
    }
}

// fprintf replacement: format, then write the bytes to `f`.
fn afprint(f: *void, fmt: *i8, args: anytype) i32 {
    let mut ti: *type_info= @typeinfo(@typeof(args));
    let mut argp: *u8= (u8*)&args;
    let mut flds0: *type_info_field= (type_info_field*)0;
    let mut nf0: i32= 0;
    match (*ti) {
        type_info::Struct(nm, flds, nf, sz, al, tup, pk) => {
            flds0 = flds;
            nf0   = (i32)nf;
        },
        _ => { argp = (u8*)0; }
    }
    let mut sbuf: [4096]i8;
    let mut n: i32= afmt_v(sbuf, 4096u, fmt, argp, flds0, nf0);
    if (n < 0) { return n; }
    if ((u64)n < 4096u) {
        fwrite((void*)sbuf, 1u, (u64)n, f);
        return n;
    }
    let mut need: u64= (u64)n + 1u;
    let mut hbuf: *i8= (i8*)arc_malloc(need);
    if (hbuf == (i8*)0) {
        fwrite((void*)sbuf, 1u, 4095u, f);
        return n;
    }
    let mut n2: i32= afmt_v(hbuf, need, fmt, argp, flds0, nf0);
    fwrite((void*)hbuf, 1u, (u64)n2, f);
    arc_free(hbuf);
    return n2;
}

// printf replacement: format, then write the bytes to stdout.
//
// Formats into a stack buffer first and falls back to the heap only when the result does
// not fit, so the common case does not allocate. Output goes through fwrite rather than
// puts because the formatted text may contain NULs and is not implicitly newline-terminated.
// Note this resolves the argument struct itself and calls afmt_v, rather than
// delegating to afmt. afmt is generic over `args`, and calling one generic from inside
// another is not supported by the backend, so delegating would silently format nothing.
fn aprint(fmt: *i8, args: anytype) i32 {
    let mut ti: *type_info= @typeinfo(@typeof(args));
    let mut argp: *u8= (u8*)&args;
    let mut flds0: *type_info_field= (type_info_field*)0;
    let mut nf0: i32= 0;
    match (*ti) {
        type_info::Struct(nm, flds, nf, sz, al, tup, pk) => {
            flds0 = flds;
            nf0   = (i32)nf;
        },
        _ => { argp = (u8*)0; }
    }
    let mut sbuf: [4096]i8;
    let mut n: i32= afmt_v(sbuf, 4096u, fmt, argp, flds0, nf0);
    if (n < 0) { return n; }
    if ((u64)n < 4096u) {
        fwrite((void*)sbuf, 1u, (u64)n, stdout_file());
        return n;
    }
    // Truncated: redo into an exactly-sized heap buffer.
    let mut need: u64= (u64)n + 1u;
    let mut hbuf: *i8= (i8*)arc_malloc(need);
    if (hbuf == (i8*)0) {
        fwrite((void*)sbuf, 1u, 4095u, stdout_file());
        return n;
    }
    let mut n2: i32= afmt_v(hbuf, need, fmt, argp, flds0, nf0);
    fwrite((void*)hbuf, 1u, (u64)n2, stdout_file());
    arc_free(hbuf);
    return n2;
}
