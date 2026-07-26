#!/usr/bin/env python3
"""
Simple script: rename 'fn' as a standalone identifier to 'fn_ref'
in Arc source files. Skips content inside strings, char literals,
line comments, and block comments.

Usage:
    python fn_rename.py [--dry-run] file...
"""

import sys
import re
import shutil

def rename_fn(src):
    """
    Return (new_src, count) where count is the number of replacements.
    Renames standalone 'fn' identifiers to 'fn_ref', skipping
    content in strings, char literals, and comments.
    """
    out = []
    i = 0
    n = len(src)
    count = 0

    while i < n:
        c = src[i]

        # Line comment: // ... \n
        if c == '/' and i+1 < n and src[i+1] == '/':
            j = i
            while j < n and src[j] != '\n':
                j += 1
            out.append(src[i:j])
            i = j
            continue

        # Block comment: /* ... */
        if c == '/' and i+1 < n and src[i+1] == '*':
            j = i + 2
            while j < n - 1 and not (src[j] == '*' and src[j+1] == '/'):
                j += 1
            j += 2  # include */
            out.append(src[i:j])
            i = j
            continue

        # String literal: "..."
        if c == '"':
            j = i + 1
            while j < n:
                if src[j] == '\\':
                    j += 2
                elif src[j] == '"':
                    j += 1
                    break
                else:
                    j += 1
            out.append(src[i:j])
            i = j
            continue

        # Char literal: '...'
        if c == "'":
            j = i + 1
            while j < n:
                if src[j] == '\\':
                    j += 2
                elif src[j] == "'":
                    j += 1
                    break
                else:
                    j += 1
            out.append(src[i:j])
            i = j
            continue

        # Identifier: starts with letter or underscore
        if c.isalpha() or c == '_':
            j = i
            while j < n and (src[j].isalnum() or src[j] == '_'):
                j += 1
            word = src[i:j]
            if word == 'fn':
                out.append('fn_ref')
                count += 1
            else:
                out.append(word)
            i = j
            continue

        # Everything else: emit as-is
        out.append(c)
        i += 1

    return ''.join(out), count


def main():
    dry_run = '--dry-run' in sys.argv
    files = [f for f in sys.argv[1:] if not f.startswith('--')]

    for path in files:
        try:
            with open(path, 'r', encoding='utf-8') as f:
                src = f.read()
        except Exception as e:
            print(f'ERROR reading {path}: {e}', file=sys.stderr)
            continue

        new_src, count = rename_fn(src)
        if count == 0:
            print(f'UNCHANGED: {path} (0 replacements)')
            continue

        print(f'{"WOULD CHANGE" if dry_run else "CHANGED"}: {path} ({count} replacements)')

        if not dry_run:
            shutil.copy2(path, path + '.bak_fn')
            with open(path, 'w', encoding='utf-8', newline='') as f:
                f.write(new_src)


if __name__ == '__main__':
    main()
