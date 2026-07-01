#!/usr/bin/env python3
"""
Migrate &self / &const self in .arc files to explicit pointer params.
Replaces:
  (&self,   -> (ClassName* self,
  (&self)   -> (ClassName* self)
  (&const self, -> (const ClassName* self,
  (&const self) -> (const ClassName* self)
Tracks the innermost istruc/class name by brace depth.
"""
import re, sys, os, glob

def transform(content):
    lines = content.split('\n')
    out = []
    class_stack = []   # stack of (class_name, open_brace_depth)
    brace_depth = 0

    for line in lines:
        # Count braces to track scope (rough but works for non-nested istrucs)
        opens  = line.count('{')
        closes = line.count('}')

        # Check for istruc/class declaration before processing braces
        m = re.match(r'\s*(?:pub\s+|priv\s+|pub\s+)?istruc\s+(\w+)', line)
        if m:
            class_stack.append((m.group(1), brace_depth + opens - closes))

        # Perform substitution if inside a class
        if class_stack:
            cname = class_stack[-1][0]
            # &const self -> const ClassName* self  (must come before &self)
            line = re.sub(r'(?<!&)&\s*const\s+self\b', f'const {cname}* self', line)
            # &self -> ClassName* self  (negative lookbehind avoids touching &&)
            line = re.sub(r'(?<!&)&\s*self\b', f'{cname}* self', line)

        brace_depth += opens - closes

        # Pop class stack when we've closed past its depth
        while class_stack and brace_depth <= class_stack[-1][1] - 1:
            class_stack.pop()

        out.append(line)

    return '\n'.join(out)

def process_dir(d):
    changed = 0
    for path in glob.glob(os.path.join(d, '**', '*.arc'), recursive=True):
        with open(path, 'r', encoding='utf-8') as f:
            orig = f.read()
        new = transform(orig)
        if new != orig:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new)
            print(f'  patched {path}')
            changed += 1
    return changed

dirs = ['tcon', 'compiler/std']
total = 0
for d in dirs:
    total += process_dir(d)
print(f'\nTotal files patched: {total}')
