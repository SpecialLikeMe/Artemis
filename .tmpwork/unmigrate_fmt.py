"""Inverse of migrate_fmt.py: afmt/aprint/afprint back to snprintf/printf/fprintf.

Used only to bootstrap — the compiler fix needed to build the migrated sources has to
be compiled by a compiler that does not yet have it.
"""
import sys, re

CALLS = {'afmt': ('snprintf', 3), 'aprint': ('printf', 1), 'afprint': ('fprintf', 2)}
IDENT = re.compile(r'[A-Za-z0-9_]')

sys.path.insert(0, '.')
exec(open(__file__.replace('unmigrate_fmt.py', 'migrate_fmt.py')).read().split('def transform')[0].split('CALLS =')[0])


def find_call_end(s, open_idx):
    depth, i, n = 0, open_idx, len(s)
    while i < n:
        c = s[i]
        if c == '"' or c == "'":
            q = c; i += 1
            while i < n:
                if s[i] == '\\':
                    i += 2; continue
                if s[i] == q:
                    break
                i += 1
            if i >= n: return -1
        elif c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def transform(text):
    out, i, n, changed = [], 0, len(text), 0
    while i < n:
        c0 = text[i]
        if c0 == '"' or c0 == "'":
            q = c0; out.append(c0); i += 1
            while i < n:
                if text[i] == '\\':
                    out.append(text[i]); i += 1
                    if i < n: out.append(text[i]); i += 1
                    continue
                out.append(text[i])
                if text[i] == q:
                    i += 1; break
                i += 1
            continue
        if c0 == '/' and i + 1 < n and text[i + 1] == '/':
            while i < n and text[i] != '\n':
                out.append(text[i]); i += 1
            continue
        m = None
        for name in CALLS:
            if text.startswith(name, i):
                if i > 0 and IDENT.match(text[i - 1]):
                    continue
                j = i + len(name)
                if j < n and text[j] == '(':
                    m = name; break
        if m is not None:
            k = i - 1
            while k >= 0 and text[k] in ' \t':
                k -= 1
            if k >= 1 and text[k - 1:k + 1] == 'fn':
                pre = text[k - 2] if k >= 2 else ' '
                if not IDENT.match(pre):
                    m = None
        if m is None:
            out.append(text[i]); i += 1
            continue
        repl, fixed = CALLS[m]
        open_idx = i + len(m)
        close_idx = find_call_end(text, open_idx)
        if close_idx < 0:
            out.append(text[i]); i += 1
            continue
        inner = text[open_idx + 1:close_idx]
        # last top-level arg is the .{...}
        depth, split, j = 0, -1, 0
        starts = []
        while j < len(inner):
            ch = inner[j]
            if ch == '"' or ch == "'":
                q = ch; j += 1
                while j < len(inner):
                    if inner[j] == '\\':
                        j += 2; continue
                    if inner[j] == q:
                        break
                    j += 1
            elif ch in '([{':
                depth += 1
            elif ch in ')]}':
                depth -= 1
            elif ch == ',' and depth == 0:
                starts.append(j)
            j += 1
        if len(starts) < fixed:
            out.append(text[i]); i += 1
            continue
        head = inner[:starts[fixed - 1]]
        tail = inner[starts[fixed - 1] + 1:].strip()
        if not (tail.startswith('.{') and tail.endswith('}')):
            out.append(text[i]); i += 1
            continue
        varargs = tail[2:-1].strip()
        new = repl + '(' + head + (', ' + varargs if varargs else '') + ')'
        out.append(new); changed += 1
        i = close_idx + 1
    return ''.join(out), changed


total = 0
for path in sys.argv[1:]:
    raw = open(path, 'rb').read()
    crlf = b'\r\n' in raw
    text = raw.decode('utf-8')
    if crlf:
        text = text.replace('\r\n', '\n')
    new, ch = transform(text)
    if ch:
        if crlf:
            new = new.replace('\n', '\r\n')
        open(path, 'wb').write(new.encode('utf-8'))
        print('%4d  %s' % (ch, path))
        total += ch
print('total reverted: %d' % total)
