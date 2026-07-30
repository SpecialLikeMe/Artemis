@include <afmt_inc.arc>
@unsafe extern fn printf(f: *i8, ...) i32;
@unsafe extern fn snprintf(b: *i8, n: u64, f: *i8, ...) i32;
@unsafe extern fn strcmp(a: *i8, b: *i8) i32;
let mut fails: i32= 0;
fn chk(got: *i8, want: *i8, tag: *i8) void {
    let mut same: i32; @unsafe { same = strcmp(got, want); }
    if (same != 0) { @unsafe { printf("MISMATCH %s: got [%s] want [%s]\n", tag, got, want); } fails = fails + 1; }
}
pub fn main() i32 {
    let mut g: [256]i8;
    let mut w: [256]i8;
    let mut n: i32= 42;
    let mut neg: i32= -7;
    let mut big: i64= (i64)1234567890123;
    let mut u: u32= 4000000000u;
    let mut p: *void= (void*)g;

    afmt(g, 256u, "plain", .{});                          @unsafe { snprintf(w, 256u, "plain"); }                         chk(g, w, "plain");
    afmt(g, 256u, "s=%s|", .{ "hi" });               @unsafe { snprintf(w, 256u, "s=%s|", "hi"); }                   chk(g, w, "%s");
    afmt(g, 256u, "d=%d|", .{ n });                  @unsafe { snprintf(w, 256u, "d=%d|", n); }                      chk(g, w, "%d");
    afmt(g, 256u, "neg=%d|", .{ neg });              @unsafe { snprintf(w, 256u, "neg=%d|", neg); }                  chk(g, w, "%d neg");
    afmt(g, 256u, "ll=%lld|", .{ big });             @unsafe { snprintf(w, 256u, "ll=%lld|", big); }                 chk(g, w, "%lld");
    afmt(g, 256u, "u=%u|", .{ u });                  @unsafe { snprintf(w, 256u, "u=%u|", u); }                      chk(g, w, "%u");
    afmt(g, 256u, "x=%x|", .{ n });                  @unsafe { snprintf(w, 256u, "x=%x|", n); }                      chk(g, w, "%x");
    afmt(g, 256u, "c=%c|", .{ 'Z' });                @unsafe { snprintf(w, 256u, "c=%c|", 'Z'); }                    chk(g, w, "%c");
    afmt(g, 256u, "pct=%%|", .{});                        @unsafe { snprintf(w, 256u, "pct=%%|"); }                       chk(g, w, "%%");
    afmt(g, 256u, "mix %s/%d/%s!", .{ "a", n, "b" });@unsafe { snprintf(w, 256u, "mix %s/%d/%s!", "a", n, "b"); }    chk(g, w, "mixed");
    afmt(g, 256u, "prec=%.3s|", .{ "abcdef" });      @unsafe { snprintf(w, 256u, "prec=%.3s|", "abcdef"); }          chk(g, w, "%.3s");

    // return value = would-be length, like snprintf
    let mut r1: i32= afmt(g, 256u, "%s-%d", .{ "abc", n });
    let mut r2: i32; @unsafe { r2 = snprintf(w, 256u, "%s-%d", "abc", n); }
    if (r1 != r2) { @unsafe { printf("MISMATCH retlen: %d vs %d\n", r1, r2); } fails = fails + 1; }

    // truncation
    let mut small: [8]i8;
    let mut t1: i32= afmt(small, 8u, "%s", .{ "0123456789" });
    if (t1 != 10) { @unsafe { printf("MISMATCH trunc len %d\n", t1); } fails = fails + 1; }
    chk(small, "0123456", "trunc");

    aprint("aprint %s %d ok\n", .{ "works", n });
    if (fails == 0) { @unsafe { printf("ALL FMT OK\n"); } }
    return fails;
}
