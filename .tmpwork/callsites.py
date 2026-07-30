import re, sys, os

ALLOC_RE = re.compile(r'\b(\w+(?:\.\w+)*)\.(mmap|mmap_aligned|rmap|free|destroy|deinit|zeroed|create|create_n)\s*\(')

def find_call(line, m):
    """Return (start, end) of the full call expression starting at m."""
    i = m.end() - 1           # at '('
    d = 0
    while i < len(line):
        if line[i] == '(': d += 1
        elif line[i] == ')':
            d -= 1
            if d == 0: return (m.start(), i + 1)
        i += 1
    return None

def migrate(path):
    lines = open(path, encoding="utf-8").read().split("\n")
    out, changed = [], False
    for ln in lines:
        st = ln.strip()
        # skip declarations
        if re.match(r'\s*(pub\s+|priv\s+|static\s+)*fn\s+', ln) or 'catch' in ln or 'try ' in ln:
            out.append(ln); continue
        m = ALLOC_RE.search(ln)
        if not m:
            out.append(ln); continue
        span = find_call(ln, m)
        if not span:
            out.append(ln); continue
        s, e = span
        call = ln[s:e]
        rest = ln[e:].strip()
        # rsmap returns plain bool — never fallible
        if '.rsmap(' in call:
            out.append(ln); continue
        if rest.startswith(';'):
            # statement position: the result is discarded
            out.append(ln[:e] + " catch |e| { }" + ln[e:])
        else:
            # value position: wrap so the expression still yields the pointer
            out.append(ln[:s] + "(" + call + " catch |e| { return (void*)0; })" + ln[e:])
        changed = True
    if changed:
        open(path, "w", encoding="utf-8").write("\n".join(out))
    return changed

n = 0
for p in sys.argv[1:]:
    if migrate(p): n += 1; print("  ", os.path.relpath(p))
print("changed:", n)
