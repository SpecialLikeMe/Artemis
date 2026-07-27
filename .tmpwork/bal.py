BS = chr(92)
def strip_lits(l):
    out, i, n = [], 0, len(l)
    while i < n:
        c = l[i]
        if c == '/' and i+1 < n and l[i+1] == '/':
            break
        if c == '"':
            i += 1
            while i < n and l[i] != '"':
                if l[i] == BS: i += 1
                i += 1
            i += 1; continue
        if c == "'":
            i += 1
            while i < n and l[i] != "'":
                if l[i] == BS: i += 1
                i += 1
            i += 1; continue
        out.append(c); i += 1
    return "".join(out)

import sys
for path in sys.argv[1:]:
    lines=open(path,encoding='utf-8').read().split("\n")
    d=0
    for l in lines:
        s=strip_lits(l)
        d += s.count('{')-s.count('}')
    print(f"{d:+3d}  {path}")
