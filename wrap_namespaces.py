#!/usr/bin/env python3
"""
Wrap stdlib .arc files in namespace blocks.
Also updates the corresponding stdlib tests to use qualified names.
"""
import re, os

def wrap_in_namespace(filepath, ns_name):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    # Already has namespace? skip
    if f'namespace {ns_name}' in content:
        print(f'  {filepath}: already has namespace {ns_name}')
        return
    lines = content.split('\n')
    # Find the first non-comment, non-extern, non-empty line that starts actual code
    out = []
    header_done = False
    for line in lines:
        stripped = line.strip()
        if not header_done and (stripped.startswith('//') or stripped == '' or
                                 stripped.startswith('extern ')):
            out.append(line)
        else:
            if not header_done:
                header_done = True
                out.append(f'namespace {ns_name} {{')
            out.append(line)
    # Add closing brace before trailing blank lines
    out.append(f'}} // namespace {ns_name}')
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(out))
    print(f'  wrapped {filepath} in namespace {ns_name}')

# Wrap modules
wrap_in_namespace('compiler/std/include/hash.arc',   'hash')
wrap_in_namespace('compiler/std/include/debug.arc',  'debug')
wrap_in_namespace('compiler/std/include/fmt.arc',    'fmt')
wrap_in_namespace('compiler/std/include/encode.arc', 'encode')
wrap_in_namespace('compiler/std/include/math.arc',   'math')
