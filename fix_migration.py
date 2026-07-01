#!/usr/bin/env python3
"""
Fix migration artifacts: &ClassName* self. -> && self.
These were produced by migrate_self.py incorrectly replacing the second & in && with a class name.
"""
import re, os, glob

# Pattern: & (class name) * self . — needs to be && self.
# The class name is one or more word chars
pattern = re.compile(r'&([A-Za-z_][A-Za-z_0-9]*)\* self\.')

def fix_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    # Replace &ClassName* self. with && self.
    new_content = pattern.sub(r'&& self.', content)
    if new_content != content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f'  fixed {path}')
        return True
    return False

total = 0
for d in ['tcon', 'compiler/std']:
    for path in glob.glob(os.path.join(d, '**', '*.arc'), recursive=True):
        if fix_file(path):
            total += 1
print(f'\nTotal files fixed: {total}')
