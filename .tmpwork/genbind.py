import re, sys
p = 'compiler/bind/llvm.arc'
lines = open(p, encoding='utf-8').read().split("\n")
decl = re.compile(r'^@unsafe extern fn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\((.*)\)\s*([^;]*);\s*(//.*)?$')

def split_params(s):
    out, d, cur = [], 0, ""
    for ch in s:
        if ch in '(<': d += 1
        if ch in ')>': d -= 1
        if ch == ',' and d == 0: out.append(cur.strip()); cur = ""
        else: cur += ch
    if cur.strip(): out.append(cur.strip())
    return out

# Symbols that are LLVM header macros, not linkable — the driver calls the _shim forms.
MACROS = {"LLVMInitializeAllTargetInfos","LLVMInitializeAllTargets","LLVMInitializeAllTargetMCs",
          "LLVMInitializeAllAsmPrinters","LLVMInitializeAllAsmParsers",
          "LLVMInitializeNativeTarget","LLVMInitializeNativeAsmPrinter","LLVMInitializeNativeAsmParser"}

raws, wraps, kept, variadic = [], [], [], []
for ln in lines:
    m = decl.match(ln)
    if not m:
        kept.append(ln); continue
    name, params, ret, cmt = m.group(1), m.group(2).strip(), m.group(3).strip(), (m.group(4) or "")
    if name in MACROS:
        continue                                  # dropped: no such symbol
    ps = split_params(params)
    if any(x == "..." for x in ps) or any(":" not in x for x in ps if x):
        variadic.append(ln); continue             # cannot forward varargs
    args = [x.split(":")[0].strip() for x in ps]
    tail = (" " + cmt) if cmt else ""
    raws.append(f'@unsafe @link_name("{name}") extern fn raw_{name}({params}) {ret};{tail}')
    call = f"raw_{name}({', '.join(args)})"
    # The wrapper needs its own symbol: sharing the C name would make it call itself.
    sym = f'@link_name("arc_{name}") '
    if ret in ("void", ""):
        wraps.append(f'{sym}fn {name}({params}) void {{ @unsafe {{ {call}; }} }}')
    else:
        wraps.append(f'{sym}fn {name}({params}) {ret} {{ let mut r: {ret}; @unsafe {{ r = {call}; }} return r; }}')

hdr = '''// LLVM C API and C stdlib bindings for the Artemis self-hosting compiler.
//
// Each foreign symbol appears twice: `raw_<name>` bound to the real C symbol via
// @link_name, and a safe wrapper `<name>` that performs the call inside `@unsafe { }`.
// Call sites use the plain name and need no annotation.
//
// The wrapper carries its own @link_name ("arc_<name>"). Without it the wrapper and
// the raw binding would emit the same symbol: the wrapper would resolve to itself
// (infinite recursion) and shadow the real library definition.
//
// These wrappers are a trust assertion, not a proof — forwarding a raw pointer does
// not make the callee safe. They assert that the compiler's own use of these symbols
// (opaque LLVM handles it created, buffers it sized) is sound.
//
// The LLVMInitializeAll*/Native* families are header macros with no linkable symbol;
// boot/llvm_init.c provides *_shim functions and the driver calls those.
'''
out = [hdr, "// ---- Raw foreign symbols ----", ""] + raws + \
      ["", "// ---- Variadic foreign symbols (no va_list, so not wrappable) ----", ""] + variadic + \
      ["", "// ---- Safe wrappers ----", ""] + wraps + [""] + kept
open(p, 'w', encoding='utf-8').write("\n".join(out))
print(f"raws={len(raws)} wraps={len(wraps)} variadic={len(variadic)} dropped_macros={len(MACROS)}")
