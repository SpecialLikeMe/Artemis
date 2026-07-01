#!/usr/bin/env python3
"""
Update stdlib tests to use namespace-qualified names.
Applies to hash::, debug::, fmt::, encode::, math:: namespaces.
"""
import re, os

# Map: for each namespace, list all symbol prefixes that need qualification.
# These are matched as whole-word identifiers at the start of an expression
# (not already qualified with ::).

NS_SYMBOLS = {
    'hash': [
        'FNV_OFFSET', 'FNV_PRIME',
        'fnv_hash_bytes', 'fnv_hash_str', 'fnv_hash32_bytes',
        'wyhash_hash_bytes', 'wyhash_hash_str', 'wyhash_hash_i64',
        'wyhash_wymix', 'wyhash_hash_i32',
        'sha256_ctx', 'sha256_hash_bytes', 'sha256_hash_str',
        'sha256_digest',
    ],
    'debug': [
        'panic', 'panic_fmt', 'bounds_check', 'null_check',
        'assert', 'poison', 'is_poisoned', 'breakpoint',
        'poison_mark',
    ],
    'fmt': [
        'out_print', 'out_println', 'out_print_i32', 'out_print_i64',
        'out_print_u32', 'out_print_u64', 'out_print_f64',
        'out_print_char', 'out_print_bool', 'out_flush',
        'err_print', 'err_println', 'err_print_i32', 'err_flush',
        'fmt_i32', 'fmt_i64', 'fmt_u32', 'fmt_u64', 'fmt_f64',
        'fmt_hex', 'fmt_ptr', 'fmt_bool',
        'str_len', 'str_eq', 'str_copy', 'str_append',
        'str_starts_with', 'str_ends_with', 'str_find',
        'str_to_i32', 'str_to_i64', 'str_to_f64',
        'file_open', 'file_close', 'file_read_bytes', 'file_write_bytes',
        'file_read_all', 'file_write_all', 'file_seek', 'file_tell',
        'file_flush', 'file_size', 'file_remove',
    ],
    'encode': [
        'utf8_decode_one', 'utf8_encode_one', 'utf8_validate', 'utf8_count',
        'utf16_decode_one', 'utf16_encode_one',
        'utf8_string', 'utf16_string', 'utf32_string',
    ],
    'math': [
        'abs_i32', 'abs_i64', 'abs_f64',
        'min_i32', 'min_i64', 'min_f64',
        'max_i32', 'max_i64', 'max_f64',
        'clamp_i32', 'clamp_i64', 'clamp_f64',
        'is_power_of_two', 'next_power_of_two',
        'gcd', 'lcm',
        'floor_f64', 'ceil_f64', 'round_f64',
        'lerp_f64', 'sqrt_f64',
        'vec2', 'vec3', 'vec4', 'mat2', 'mat3', 'mat4',
    ],
}

def qualify_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    orig = content
    for ns, symbols in NS_SYMBOLS.items():
        for sym in symbols:
            # Replace bare `sym` with `ns::sym` but only if not already qualified
            # Negative lookbehind: not preceded by ::
            pattern = re.compile(r'(?<!:)\b' + re.escape(sym) + r'\b')
            content = pattern.sub(ns + '::' + sym, content)
    if content != orig:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'  qualified {path}')
        return True
    return False

import glob
tests = sorted(glob.glob('tcon/std/*.arc'))
total = 0
for t in tests:
    if qualify_file(t):
        total += 1
print(f'\nTotal files updated: {total}')
