"""Rewrite the compiler's C-varargs format calls to the type-safe afmt family.

    snprintf(b, n, f, a, b)  ->  afmt(b, n, f, .{ a, b })
    printf(f, a)             ->  aprint(f, .{ a })
    fprintf(s, f, a)         ->  afprint(s, f, .{ a })
    sprintf(b, f, a)         ->  afmt(b, <cap>, f, .{ a })   [reported, needs review]

Only rewrites a call when its parentheses balance and its arguments split cleanly at
top level. Anything else is left alone and reported, so a partial parse can never
silently mangle a call the way a regex would.
"""
import sys, os, re

# name -> (replacement, index of the last fixed arg before the varargs start)
CALLS = {
    'snprintf': ('afmt',    3),
    'printf':   ('aprint',  1),
    'fprintf':  ('afprint', 2),
}

IDENT = re.compile(r'[A-Za-z0-9_]')


def find_call_end(s, open_idx):
    """Given index of '(', return index of the matching ')' or -1."""
    depth = 0
    i = open_idx
    n = len(s)
    while i < n:
        c = s[i]
        if c == '"':
            i += 1
            while i < n:
                if s[i] == '\\':
                    i += 2
                    continue
                if s[i] == '"':
                    break
                i += 1
            if i >= n:
                return -1
        elif c == "'":
            i += 1
            while i < n:
                if s[i] == '\\':
                    i += 2
                    continue
                if s[i] == "'":
                    break
                i += 1
            if i >= n:
                return -1
        elif c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
            if depth == 0:
                return i
        elif c == '\n':
            pass
        i += 1
    return -1


def split_args(s):
    """Split a top-level argument list. Returns list of strings."""
    args, depth, cur, i, n = [], 0, [], 0, len(s)
    while i < n:
        c = s[i]
        if c == '"':
            cur.append(c); i += 1
            while i < n:
                cur.append(s[i])
                if s[i] == '\\':
                    i += 1
                    if i < n:
                        cur.append(s[i])
                    i += 1
                    continue
                if s[i] == '"':
                    i += 1
                    break
                i += 1
            continue
        if c == "'":
            cur.append(c); i += 1
            while i < n:
                cur.append(s[i])
                if s[i] == '\\':
                    i += 1
                    if i < n:
                        cur.append(s[i])
                    i += 1
                    continue
                if s[i] == "'":
                    i += 1
                    break
                i += 1
            continue
        if c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
        if c == ',' and depth == 0:
            args.append(''.join(cur)); cur = []; i += 1
            continue
        cur.append(c); i += 1
    tail = ''.join(cur)
    if tail.strip() or args:
        args.append(tail)
    return args


def transform(text, path, report):
    out = []
    i = 0
    n = len(text)
    changed = 0
    while i < n:
        c0 = text[i]
        # Copy string / char literals verbatim: a name inside @link_name("printf")
        # or inside a format string must never be treated as a call.
        if c0 == '"' or c0 == "'":
            q = c0
            out.append(c0); i += 1
            while i < n:
                if text[i] == '\\':
                    out.append(text[i]); i += 1
                    if i < n:
                        out.append(text[i]); i += 1
                    continue
                out.append(text[i])
                if text[i] == q:
                    i += 1
                    break
                i += 1
            continue
        # Copy line comments verbatim.
        if c0 == '/' and i + 1 < n and text[i + 1] == '/':
            while i < n and text[i] != '\n':
                out.append(text[i]); i += 1
            continue

        m = None
        for name in CALLS:
            if text.startswith(name, i):
                # must be a standalone identifier
                if i > 0 and IDENT.match(text[i - 1]):
                    continue
                j = i + len(name)
                if j < n and text[j] == '(':
                    m = name
                    break
        if m is not None:
            # `fn snprintf(...)` is a declaration, not a call.
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
            report.append((path, 'unbalanced', text[i:i + 60].replace('\n', ' ')))
            out.append(text[i]); i += 1
            continue

        inner = text[open_idx + 1:close_idx]
        args = split_args(inner)
        if len(args) < fixed:
            report.append((path, 'too-few-args', text[i:i + 60].replace('\n', ' ')))
            out.append(text[i]); i += 1
            continue

        head = args[:fixed]
        rest = args[fixed:]
        rest = [a for a in rest if a.strip() != '']
        if rest:
            varpart = '.{ ' + ', '.join(a.strip() for a in rest) + ' }'
        else:
            varpart = '.{}'
        new = repl + '(' + ', '.join(h.strip() for h in head) + ', ' + varpart + ')'
        out.append(new)
        changed += 1
        i = close_idx + 1
    return ''.join(out), changed


def main():
    files = sys.argv[1:]
    report = []
    total = 0
    for path in files:
        raw = open(path, 'rb').read()
        crlf = b'\r\n' in raw
        text = raw.decode('utf-8')
        if crlf:
            text = text.replace('\r\n', '\n')
        new, changed = transform(text, path, report)
        if changed:
            if crlf:
                new = new.replace('\n', '\r\n')
            open(path, 'wb').write(new.encode('utf-8'))
            print('%4d  %s' % (changed, path))
            total += changed
    print('total rewritten: %d' % total)
    if report:
        print('--- NOT rewritten ---')
        for r in report:
            print('  %s: %s: %s' % r)


main()
