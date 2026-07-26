#!/usr/bin/env python3
"""Simulate the preprocessor's angle-bracket include resolution to find what's at a given line."""
import sys
import os

TARGET_LINE = 2925
BASE = os.path.dirname(os.path.abspath(__file__))

def preprocess(filepath, base_dir):
    """Returns list of (source_file, source_lineno, text) tuples."""
    result = []
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except:
        return result

    for i, line in enumerate(lines, 1):
        stripped = line.lstrip()
        if stripped.startswith('@include'):
            rest = stripped[8:].lstrip()
            if rest.startswith('<'):
                end = rest.find('>')
                if end > 0:
                    inc_name = rest[1:end]
                    inc_path = os.path.join(base_dir, inc_name)
                    # Recurse
                    sub = preprocess(inc_path, base_dir)
                    result.extend(sub)
            # directive becomes blank line
            result.append((filepath, i, '\n'))
        else:
            result.append((filepath, i, line))
    return result

# Run from repo root
compiler_main = os.path.join(BASE, 'compiler', 'main.arc')
base_dir = os.path.join(BASE, 'compiler')

lines = preprocess(compiler_main, base_dir)

print(f"Total preprocessed lines: {len(lines)}")
print(f"\nContext around line {TARGET_LINE}:")
for idx, (src, srcline, text) in enumerate(lines[max(0, TARGET_LINE-5):TARGET_LINE+5], TARGET_LINE-4):
    marker = " --> " if idx == TARGET_LINE else "     "
    print(f"{marker}{idx:5d}  [{os.path.relpath(src, BASE)}:{srcline}]  {text}", end='')
