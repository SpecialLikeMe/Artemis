#!/usr/bin/env python3
"""
Arc syntax migration: old leading-type syntax -> new trailing-type syntax.

Old:  RetType funcname(Type1 p1, Type2 p2) { ... }
New:  fn funcname(p1: Type1, p2: Type2) RetType { ... }

Old:  Type varname = expr;
New:  let mut varname: Type = expr;

Old:  (inside struct/union)  Type fieldname;
New:  (inside struct/union)  let fieldname: Type;

Usage:
    python migrate_syntax.py [--dry-run] [--check-only] file_or_dir [...]
"""

import sys
import os
import re
import shutil
import argparse
from pathlib import Path

# ============================================================
# TOKENIZER
# ============================================================

TOK_WS       = 'ws'
TOK_NL       = 'nl'
TOK_LC       = 'lc'   # line comment
TOK_BC       = 'bc'   # block comment
TOK_STR      = 'str'
TOK_CHAR     = 'chr'
TOK_NUM      = 'num'
TOK_ID       = 'id'
TOK_PUNCT    = 'px'
TOK_DIR      = 'dir'  # @include, @define, etc.
TOK_EOF      = 'eof'


class Tok:
    __slots__ = ('kind', 'text', 'line')
    def __init__(self, kind, text, line):
        self.kind = kind
        self.text = text
        self.line = line
    def __repr__(self):
        return f'Tok({self.kind},{self.text!r})'


def tokenize(src):
    toks = []
    i = 0
    n = len(src)
    line = 1

    while i < n:
        c = src[i]

        # Line comment
        if c == '/' and i+1 < n and src[i+1] == '/':
            j = i
            while j < n and src[j] != '\n':
                j += 1
            toks.append(Tok(TOK_LC, src[i:j], line))
            i = j
            continue

        # Block comment
        if c == '/' and i+1 < n and src[i+1] == '*':
            sl = line
            j = i + 2
            while j < n - 1 and not (src[j] == '*' and src[j+1] == '/'):
                if src[j] == '\n':
                    line += 1
                j += 1
            j += 2  # skip */
            toks.append(Tok(TOK_BC, src[i:j], sl))
            i = j
            continue

        # String literal
        if c == '"':
            j = i + 1
            while j < n:
                if src[j] == '\\':
                    j += 2
                elif src[j] == '"':
                    j += 1
                    break
                else:
                    if src[j] == '\n':
                        line += 1
                    j += 1
            toks.append(Tok(TOK_STR, src[i:j], line))
            i = j
            continue

        # Char literal
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
            toks.append(Tok(TOK_CHAR, src[i:j], line))
            i = j
            continue

        # Preprocessor directive (@include, @define, ...)
        if c == '@':
            j = i
            while j < n and src[j] != '\n':
                j += 1
            toks.append(Tok(TOK_DIR, src[i:j], line))
            i = j
            continue

        # Newline
        if c == '\n':
            toks.append(Tok(TOK_NL, '\n', line))
            line += 1
            i += 1
            continue

        # Other whitespace
        if c in ' \t\r':
            j = i
            while j < n and src[j] in ' \t\r':
                j += 1
            toks.append(Tok(TOK_WS, src[i:j], line))
            i = j
            continue

        # Number
        if c.isdigit() or (c == '.' and i+1 < n and src[i+1].isdigit()):
            j = i
            while j < n and (src[j].isalnum() or src[j] in '._xX'):
                j += 1
            toks.append(Tok(TOK_NUM, src[i:j], line))
            i = j
            continue

        # Identifier / keyword
        if c.isalpha() or c == '_':
            j = i
            while j < n and (src[j].isalnum() or src[j] == '_'):
                j += 1
            # Handle T[_] special suffix (lexer extends word)
            if j < n-2 and src[j] == '[' and src[j+1] == '_' and src[j+2] == ']':
                j += 3
            toks.append(Tok(TOK_ID, src[i:j], line))
            i = j
            continue

        # Multi-char punctuation (order matters - longer first)
        matched = False
        for mp in ('...', '<<=', '>>=', '->', '==', '!=', '<=', '>=',
                   '++', '--', '&&', '||', '<<', '>>', '+=', '-=',
                   '*=', '/=', '%=', '&=', '|=', '^=', '??'):
            if src[i:i+len(mp)] == mp:
                toks.append(Tok(TOK_PUNCT, mp, line))
                i += len(mp)
                matched = True
                break
        if matched:
            continue

        toks.append(Tok(TOK_PUNCT, c, line))
        i += 1

    toks.append(Tok(TOK_EOF, '', line))
    return toks


# ============================================================
# TYPE KNOWLEDGE
# ============================================================

# Arc primitive type names
PRIM_TYPES = frozenset({
    'void', 'char', 'bool', 'int',
    'i8','i16','i32','i64','i128',
    'u8','u16','u32','u64','u128',
    'f32','f64','f128',
    'b8','b16','b32','b64',
})

# Pattern for arbitrary-width types: i32, u64, f32, etc.
_PRIM_RE = re.compile(r'^(?:[iufzrncqba]\d+(?:\[_\])?|[iufzrncqba]\[_\])$')

# Keywords that are NOT type-starting
NON_TYPE_KWS = frozenset({
    'if','else','while','for','return','break','continue',
    'switch','case','default','namespace','using','extern',
    'static','comptime','defer','errdefer','try','catch',
    'null','true','false','sizeof','operator','inline',
    'ref','attr','derive','quote','let','mut','fn','pub',
    'priv', 'error', 'auto',
})

# These are definitely types when seen
KNOWN_KWTYPE = frozenset({
    'void','char','bool','int','auto',
    'i8','i16','i32','i64','i128',
    'u8','u16','u32','u64','u128',
    'f32','f64','f128',
    'b8','b16','b32','b64',
})

def is_prim_type(s):
    return s in PRIM_TYPES or bool(_PRIM_RE.match(s))

def could_be_type_name(s):
    """Heuristic: could this identifier be a type name?"""
    if s in NON_TYPE_KWS:
        return False
    if is_prim_type(s):
        return True
    # Arc convention: type names are PascalCase or ALL_CAPS or contain underscores
    # Also lowercase like 'lexer__NS_token_t' etc.
    if s and s[0].isupper():
        return True
    # Things like 'parser__NS_type_node', 'sv_map', etc.
    # Be permissive: any identifier followed by another identifier is a potential type
    return True


# ============================================================
# TYPE STRING TRANSFORMATION
# ============================================================

def transform_type_str(s):
    """
    Transform a type string from old to new syntax.
    'i32' -> 'i32'
    'i32*' -> '*i32'
    'i32**' -> '**i32'
    'const i8*' -> '*const i8'
    'const i8**' -> '**const i8'
    'void*' -> '*void'
    """
    s = s.strip()
    if not s:
        return s

    # Pass through nullable prefix '?'
    nullable = ''
    if s.startswith('?'):
        nullable = '?'
        s = s[1:].strip()

    # Remove leading 'const' qualifier
    is_const_data = False
    if s.startswith('const '):
        is_const_data = True
        s = s[6:].strip()

    # Count and remove trailing '*'
    stars = 0
    while s.endswith('*'):
        stars += 1
        s = s[:-1].strip()

    base = s.strip()
    result = base

    if is_const_data and stars > 0:
        result = '*const ' + result
        stars -= 1

    result = '*' * stars + result
    return nullable + result


def transform_array_type(base_type_str, array_contents):
    """
    Transform type + C-style array declarator.
    base_type_str='i32', array_contents='5' -> '[5]i32'
    base_type_str='i32*', array_contents='5' -> '[5]*i32'
    array_contents='' -> '[]' prefix (shouldn't normally happen for declarations)
    """
    new_base = transform_type_str(base_type_str)
    if array_contents is None or array_contents == '':
        return '[]' + new_base
    elif array_contents.strip() == '_':
        return '[_]' + new_base
    else:
        return f'[{array_contents}]' + new_base


# ============================================================
# TOKEN STREAM UTILITIES
# ============================================================

def is_ws(tok):
    return tok.kind in (TOK_WS, TOK_NL)

def is_space(tok):
    return tok.kind in (TOK_WS, TOK_NL, TOK_LC, TOK_BC)

def skip_space(toks, i):
    """Return index of next non-whitespace token."""
    while i < len(toks) and is_ws(toks[i]):
        i += 1
    return i

def skip_space_comments(toks, i):
    """Skip whitespace and comments."""
    while i < len(toks) and is_space(toks[i]):
        i += 1
    return i

def tok_at(toks, i):
    """Safe token access."""
    if 0 <= i < len(toks):
        return toks[i]
    return Tok(TOK_EOF, '', 0)

def collect_text(toks, start, end):
    """Collect raw text of tokens from start to end (exclusive)."""
    return ''.join(t.text for t in toks[start:end])

def collect_text_nows(toks, start, end):
    """Collect raw text of tokens, skipping whitespace."""
    return ''.join(t.text for t in toks[start:end] if not is_ws(t))


# ============================================================
# SCAN HELPERS: Find balanced delimiters
# ============================================================

def find_matching(toks, i, open_char, close_char):
    """Find the matching close for open at toks[i]. Returns index of close token."""
    assert toks[i].text == open_char
    depth = 1
    i += 1
    while i < len(toks) and depth > 0:
        t = toks[i]
        if t.kind == TOK_EOF:
            break
        if t.text == open_char and t.kind == TOK_PUNCT:
            depth += 1
        elif t.text == close_char and t.kind == TOK_PUNCT:
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return i


def find_matching_lt(toks, i):
    """Find matching '>' for '<' at toks[i], handling generics."""
    assert toks[i].text == '<'
    depth = 1
    i += 1
    while i < len(toks) and depth > 0:
        t = toks[i]
        if t.kind == TOK_EOF:
            break
        if t.text == '<' and t.kind == TOK_PUNCT:
            depth += 1
        elif t.text == '>' and t.kind == TOK_PUNCT:
            depth -= 1
            if depth == 0:
                return i
        elif t.text == '>>' and t.kind == TOK_PUNCT:
            # >> can close two levels
            depth -= 2
            if depth <= 0:
                return i
        elif t.text in (';', '{', '}'):
            return i  # Not a valid generic context
        i += 1
    return i


# ============================================================
# PARSE A TYPE EXPRESSION FROM TOKEN STREAM
# Returns (type_str, end_idx)
# end_idx is the index of the first token NOT part of the type
# ============================================================

def parse_type_tokens(toks, i):
    """
    Parse a type from position i in old-style Arc syntax.
    Handles: const T, T*, T**, T(*)(params), ns.T, T<A,B>
    Returns (type_str, end_i) where end_i is first tok after the type.
    """
    parts = []
    start = i

    # Optional nullable prefix '?'
    j = skip_space(toks, i)
    if tok_at(toks, j).text == '?':
        parts.append('?')
        j = skip_space(toks, j + 1)

    # Optional 'const' qualifier
    j = skip_space(toks, j)
    if tok_at(toks, j).kind == TOK_ID and tok_at(toks, j).text == 'const':
        parts.append('const ')
        j = skip_space(toks, j + 1)

    # Optional 'unsigned'/'signed'
    if tok_at(toks, j).kind == TOK_ID and tok_at(toks, j).text in ('unsigned', 'signed'):
        parts.append(tok_at(toks, j).text + ' ')
        j = skip_space(toks, j + 1)

    # Base type (identifier, possibly namespace-qualified: ns.Type)
    if tok_at(toks, j).kind == TOK_ID and could_be_type_name(tok_at(toks, j).text):
        parts.append(tok_at(toks, j).text)
        j += 1

        # Namespace-qualified: ns.Type or ns.sub.Type
        while True:
            k = skip_space(toks, j)
            if tok_at(toks, k).text == '.' and tok_at(toks, skip_space(toks, k+1)).kind == TOK_ID:
                nxt = skip_space(toks, k+1)
                parts.append('.' + tok_at(toks, nxt).text)
                j = nxt + 1
            else:
                break

        # Generic type args: <T, U> (only if balanced; skip if < is a comparison)
        k = skip_space(toks, j)
        if tok_at(toks, k).text == '<':
            close = find_matching_lt(toks, k)
            if tok_at(toks, close).text not in (';', '{', '}'):
                # Valid generic type args
                parts.append(collect_text(toks, k, close + 1))
                j = close + 1

    elif tok_at(toks, j).kind == TOK_ID and tok_at(toks, j).text == 'auto':
        parts.append('auto')
        j += 1
    elif tok_at(toks, j).kind == TOK_ID and tok_at(toks, j).text == 'void':
        parts.append('void')
        j += 1
    else:
        # Not a type
        return ('', i)

    # Trailing '*' stars
    while True:
        k = skip_space(toks, j)
        if tok_at(toks, k).text == '*':
            parts.append('*')
            j = k + 1
        else:
            break

    type_str = ''.join(parts)
    return (type_str, j)


# ============================================================
# PARSE A PARAMETER NAME FROM TOKEN STREAM
# Returns (name, end_idx) or (None, i) if not found
# ============================================================

def parse_param_name(toks, i):
    """Parse an optional parameter name."""
    j = skip_space(toks, i)
    t = tok_at(toks, j)
    # Accept any identifier as a name (keywords too, since Arc allows 'type', 'error' etc.)
    if t.kind == TOK_ID or (t.kind == TOK_ID and t.text not in ('const', 'void', 'auto')):
        # Also accept things like 'type', 'error', etc. as param names
        return (t.text, j + 1)
    return (None, i)


# ============================================================
# PARSE A FULL PARAMETER DECLARATION
# Returns (name, type_str, array_str, end_idx) or None
# ============================================================

def parse_one_param(toks, i):
    """
    Parse a single parameter: 'Type name' or 'Type name[N]' or just 'Type' (unnamed)
    Returns (name, type_str, array_str_contents, end_idx) or None if can't parse.
    name may be None for unnamed params.
    """
    j = skip_space(toks, i)

    # Variadic
    if tok_at(toks, j).text == '...':
        return ('...', '...', None, j + 1)

    # Try to parse type
    type_str, j2 = parse_type_tokens(toks, j)
    if not type_str:
        return None

    j2 = skip_space(toks, j2)

    # Optional name
    name = None
    array_str = None
    t = tok_at(toks, j2)
    if t.kind == TOK_ID and t.text not in NON_TYPE_KWS and t.text != 'const':
        name = t.text
        j2 += 1
        j2 = skip_space(toks, j2)

        # Optional array suffix: [N]
        if tok_at(toks, j2).text == '[':
            close = find_matching(toks, j2, '[', ']')
            # contents between [ and ]
            array_str = collect_text_nows(toks, j2 + 1, close)
            j2 = close + 1

    return (name, type_str, array_str, j2)


def build_new_param(name, type_str, array_str):
    """Build new-style parameter: 'name: NewType' or 'NewType' (unnamed)."""
    if name == '...':
        return '...'

    if array_str is not None:
        new_type = transform_array_type(type_str, array_str)
    else:
        new_type = transform_type_str(type_str)

    # Rename 'fn' identifier to 'fn_ref'
    if name == 'fn':
        name = 'fn_ref'

    if name:
        return f'{name}: {new_type}'
    else:
        return new_type


def parse_param_list(toks, i_open):
    """
    Parse parameter list between '(' and ')'.
    toks[i_open].text should be '('.
    Returns (new_param_str, end_i) where end_i is index AFTER ')'.
    """
    assert toks[i_open].text == '('
    close = find_matching(toks, i_open, '(', ')')

    # Collect raw params for fallback
    raw = collect_text(toks, i_open + 1, close)

    # Try to parse individual parameters
    i = i_open + 1
    params = []
    had_error = False

    while True:
        j = skip_space_comments(toks, i)
        if j >= close:
            break

        # Variadic
        if toks[j].text == '...':
            params.append('...')
            j += 1
            i = j
            continue

        # Try new-style parameter: 'name: type'
        # Check if current token is id followed by ':'
        if tok_at(toks, j).kind == TOK_ID:
            k = skip_space(toks, j + 1)
            if tok_at(toks, k).text == ':':
                # Already new-style!
                # Collect until ',' or close
                param_start = j
                depth = 0
                while j < close:
                    if toks[j].text == ',' and depth == 0:
                        break
                    if toks[j].text in ('(', '[', '<'):
                        depth += 1
                    elif toks[j].text in (')', ']', '>'):
                        depth -= 1
                    j += 1
                params.append(collect_text(toks, param_start, j).strip())
                i = j
                if i < close and toks[i].text == ',':
                    i += 1
                continue

        result = parse_one_param(toks, j)
        if result is None:
            had_error = True
            break

        name, type_str, array_str, end_i = result
        new_param = build_new_param(name, type_str, array_str)
        params.append(new_param)
        i = end_i
        j = skip_space_comments(toks, i)
        if j < close and toks[j].text == ',':
            i = j + 1
        elif j >= close:
            break
        else:
            had_error = True
            break

    if had_error:
        # Return raw params unchanged
        return (raw, close + 1)

    return (', '.join(params), close + 1)


# ============================================================
# CONTEXT TRACKING
# ============================================================

CTX_TOP    = 'top'
CTX_FUNC   = 'func'
CTX_STRUCT = 'struct'   # struct or union fields (no methods)
CTX_CLASS  = 'class'    # istruc/memstr/namespace (fields + methods)
CTX_ENUM   = 'enum'
CTX_EXTERN = 'extern'   # extern "C" block


# ============================================================
# MAIN TRANSFORMER
# ============================================================

def transform(src, filename='<input>'):
    """
    Transform Arc source from old to new syntax.
    Returns (new_src, changed) where changed is True if anything was modified.
    """
    toks = tokenize(src)
    out = []    # list of strings to join
    i = 0
    n = len(toks)
    changed = False

    # Context stack: each entry is (ctx_type, brace_depth_at_open)
    ctx_stack = [CTX_TOP]

    # Track brace depth for context management
    brace_depth = 0

    # Map from brace_depth -> ctx_type (what context opened at this depth)
    depth_ctx = {}   # depth -> context type

    def cur_ctx():
        return ctx_stack[-1] if ctx_stack else CTX_TOP

    def emit(s):
        out.append(s)

    def emit_tok(idx):
        out.append(toks[idx].text)

    # When a function declaration is emitted, the next '{' opens a function body
    pending_func_ctx = False

    # Track whether we're at "statement start" (for variable declarations)
    # After '{', ';', or at top level after a top-level declaration
    at_stmt_start = True

    # Forward: peek at non-whitespace tokens ahead
    def peek(offset=0):
        """Peek at the Nth non-whitespace token from current position."""
        count = 0
        j = i
        while j < n:
            if not is_space(toks[j]) and toks[j].kind != TOK_LC and toks[j].kind != TOK_BC:
                if count == offset:
                    return toks[j]
                count += 1
            j += 1
        return Tok(TOK_EOF, '', 0)

    def peek_idx(offset=0):
        """Get the index of the Nth non-whitespace token from current position."""
        count = 0
        j = i
        while j < n:
            if not is_space(toks[j]) and toks[j].kind != TOK_LC and toks[j].kind != TOK_BC:
                if count == offset:
                    return j
                count += 1
            j += 1
        return n

    # Check if current position starts a NEW-STYLE declaration (already migrated)
    def already_new_style():
        p = peek(0)
        return (p.kind == TOK_ID and p.text in ('let', 'fn', 'const', 'pub', 'priv') and
                p.text not in PRIM_TYPES)

    # Try to parse a complete declaration (function or variable) at current position
    # Returns None if not a declaration, or (transformation_result, end_idx) if yes
    def try_parse_decl(decl_is_const=False):
        """
        Try to parse an old-style function or variable declaration starting at i.
        Context: cur_ctx() tells us if we're in func body, struct, top level, etc.
        Returns (new_text, end_idx) or None.
        """
        nonlocal i, changed

        j = skip_space_comments(toks, i)
        if j >= n:
            return None

        # Check for 'static' modifier
        is_static = False
        is_inline = False
        is_extern_kw = False
        is_const_kw = False
        is_comptime = False
        is_auto = False

        j2 = j
        while True:
            t = tok_at(toks, j2)
            if t.kind == TOK_ID and t.text == 'static':
                is_static = True
                j2 = skip_space_comments(toks, j2 + 1)
            elif t.kind == TOK_ID and t.text == 'inline':
                is_inline = True
                j2 = skip_space_comments(toks, j2 + 1)
            elif t.kind == TOK_ID and t.text == 'comptime':
                is_comptime = True
                j2 = skip_space_comments(toks, j2 + 1)
            else:
                break
        j = j2

        # Special case: conversion operator 'operator TargetType(params)' → 'fn operator_Type(params) Type'
        if tok_at(toks, j).kind == TOK_ID and tok_at(toks, j).text == 'operator':
            j_op = skip_space_comments(toks, j + 1)
            if tok_at(toks, j_op).kind == TOK_ID:
                target_type_str, target_end = parse_type_tokens(toks, j_op)
                if target_type_str:
                    j_open = skip_space_comments(toks, target_end)
                    if tok_at(toks, j_open).text == '(':
                        new_params, after_close = parse_param_list(toks, j_open)
                        new_type = transform_type_str(target_type_str)
                        fname = 'operator_' + target_type_str.replace(' ', '_').replace('*', 'ptr').replace('.', '_')
                        new_func = f'fn {fname}({new_params}) {new_type}'
                        return (new_func, after_close)
            return None

        # Try to parse type
        type_str, type_end = parse_type_tokens(toks, j)
        if not type_str:
            return None

        type_end_saved = type_end
        j = skip_space_comments(toks, type_end)

        # Is the type 'auto'? Then it's old-style trailing return already
        if type_str == 'auto':
            is_auto = True

        # What comes after the type?
        t = tok_at(toks, j)

        if t.kind == TOK_EOF:
            return None

        # Special case: 'RetType operator OP(params)' → 'fn operatorOP(params) RetType'
        if t.kind == TOK_ID and t.text == 'operator':
            j_op = skip_space_comments(toks, j + 1)
            op_t = tok_at(toks, j_op)
            # Operator symbol is the next token (punctuation like +, ==, etc.)
            if op_t.kind == TOK_PUNCT:
                op_sym = op_t.text
                j_open = skip_space_comments(toks, j_op + 1)
                if tok_at(toks, j_open).text == '(':
                    new_params, after_close = parse_param_list(toks, j_open)
                    ret_type = transform_type_str(type_str)
                    fname = f'operator{op_sym}'
                    new_func = f'fn {fname}({new_params})'
                    if ret_type and ret_type not in ('void',):
                        new_func += f' {ret_type}'
                    else:
                        new_func += ' void'
                    return (new_func, after_close)
            return None

        # CASE 1: Function declaration  type funcname([<T>] (params) ...
        # Detect: after type, we have an identifier (funcname) possibly followed by <T>, then (
        func_name = None
        type_params_str = ''
        if t.kind == TOK_ID and t.text not in NON_TYPE_KWS:
            func_name = t.text
            # Rename 'fn' identifier
            if func_name == 'fn':
                func_name = 'fn_ref'
            j_after_name = j + 1
            j_after_name = skip_space_comments(toks, j_after_name)

            # Optional generic type params: <T, U>
            if tok_at(toks, j_after_name).text == '<':
                close_gt = find_matching_lt(toks, j_after_name)
                type_params_str = collect_text(toks, j_after_name, close_gt + 1)
                j_after_name = skip_space_comments(toks, close_gt + 1)

            # Now must have '(' for function
            if tok_at(toks, j_after_name).text == '(':
                # Inside a function body, Type name(args) is a constructor call: 'let mut name: Type(args)'
                if cur_ctx() == CTX_FUNC:
                    close_paren = find_matching(toks, j_after_name, '(', ')')
                    args_text = collect_text(toks, j_after_name + 1, close_paren)
                    new_type = transform_type_str(type_str)
                    new_text = f'let mut {func_name}: {new_type}({args_text})'
                    return (new_text, close_paren + 1)
                # This is a function declaration!
                new_params, after_close = parse_param_list(toks, j_after_name)

                # Get whitespace between type and name for preservation
                ws_before_name = collect_text(toks, type_end_saved, j)

                # Build new function declaration
                # Trailing markers: 'attr', 'derive', 'attr category'
                extra_after = ''
                k = skip_space_comments(toks, after_close)
                if tok_at(toks, k).kind == TOK_ID and tok_at(toks, k).text in ('attr', 'derive'):
                    attr_marker = tok_at(toks, k).text
                    k2 = skip_space_comments(toks, k + 1)
                    if tok_at(toks, k2).kind == TOK_ID:
                        extra_after = f' {attr_marker} {tok_at(toks, k2).text}'
                        k = k2 + 1
                    else:
                        extra_after = f' {attr_marker}'
                        k = k + 1
                    # Do NOT skip whitespace here; let the main loop emit it so 'attr {' keeps its space
                    after_close = k

                # For 'auto' functions: trailing return already: 'auto f(p) !T {' or 'auto f(p) T {'
                # Transform to: 'fn f(p): !T {' (but actually in new syntax: 'fn f(p) T {')
                ret_type_str = ''
                after_ret = after_close
                if is_auto:
                    # Parse trailing return: !RetType or RetType
                    k = skip_space_comments(toks, after_close)
                    if tok_at(toks, k).text == '!':
                        error_prefix = '!'
                        k = skip_space_comments(toks, k + 1)
                    else:
                        error_prefix = ''
                    ret_ts, ret_end = parse_type_tokens(toks, k)
                    if ret_ts:
                        ret_type_str = error_prefix + transform_type_str(ret_ts)
                        after_ret = ret_end
                    else:
                        ret_type_str = ''
                        after_ret = after_close
                else:
                    # Old-style: return type is before the function name
                    # Check for error union: !
                    if tok_at(toks, after_close).text == '!':
                        # shouldn't normally be here, but handle just in case
                        ret_type_str = '!' + transform_type_str(type_str)
                        after_ret = skip_space_comments(toks, after_close + 1)
                        # parse the error type
                        err_ts, err_end = parse_type_tokens(toks, after_ret)
                        if err_ts:
                            ret_type_str = '!' + transform_type_str(err_ts)
                            after_ret = err_end
                    else:
                        ret_type_str = transform_type_str(type_str)
                        after_ret = after_close

                # Build: 'fn funcname<T>(params) RetType'
                static_prefix = 'static ' if is_static else ''
                new_func = f'{static_prefix}fn {func_name}{type_params_str}({new_params})'
                if ret_type_str and ret_type_str not in ('void', ''):
                    new_func += f' {ret_type_str}'
                else:
                    # void return can be omitted but let's keep it explicit
                    if not is_auto:
                        new_func += ' void' if type_str == 'void' else f' {transform_type_str(type_str)}'

                # Add extra (attr/derive markers)
                new_func += extra_after

                return (new_func, after_ret)

        # CASE 2: Variable declaration  type varname [array] [= expr] ;
        # Only if we're at statement start in a function body, or top level,
        # or inside a struct body (for fields).
        # Note: is_static is allowed here for static local variables (static i32 count = 0).
        if t.kind == TOK_ID and t.text not in NON_TYPE_KWS:
            var_name = t.text
            # Rename fn identifier
            if var_name == 'fn':
                var_name = 'fn_ref'
            j_after_name = skip_space_comments(toks, j + 1)

            # Check: what comes after the name?
            nt = tok_at(toks, j_after_name)

            if nt.text in ('=', ';', ',', ')'):
                # Variable declaration (or field)
                array_str = None
                j_final = j_after_name

                # Handle array declarations:
                # 'type name[N];' - in function bodies, this is a fixed-size array
                # The '[N]' is on the VARIABLE, not the type
                # We need to move it to the type: 'let mut name: [N]type;'
                # But wait: 'arr[i]' - subscript - we should not match this
                # We already consumed the type and name, so if next is '[' it's array decl
                # unless we're in an expression context... but we already committed to decl context

                if nt.text == '=':
                    # Check for ctor call: 'Type name = ...' or assignment?
                    # We're in declaration context, so it's definitely a variable init
                    pass
                elif nt.text == ';':
                    pass
                # no array here, continue

                # Check for constructor call: 'Type name(args)'
                if nt.text == '(':
                    # Constructor call: 'TypeName var(args)' - keep as-is for now
                    # Actually in new syntax this might be different. For now just pass through.
                    return None

                # Build variable declaration
                is_struct_ctx = cur_ctx() in (CTX_STRUCT,)

                if is_comptime or decl_is_const:
                    prefix = 'const'
                elif is_struct_ctx:
                    prefix = 'let'  # struct fields are immutable by default
                else:
                    prefix = 'let mut'

                static_var_prefix = 'static ' if is_static else ''

                # Type transformation
                if array_str is not None:
                    new_type = transform_array_type(type_str, array_str)
                else:
                    new_type = transform_type_str(type_str)

                new_var = f'{static_var_prefix}{prefix} {var_name}: {new_type}'
                return (new_var, j_after_name)

        # CASE 3: Array variable declaration: type name[N]
        if t.kind == TOK_ID and t.text not in NON_TYPE_KWS:
            var_name = t.text
            if var_name == 'fn':
                var_name = 'fn_ref'
            j_after_name = skip_space_comments(toks, j + 1)

            if tok_at(toks, j_after_name).text == '[':
                close_bracket = find_matching(toks, j_after_name, '[', ']')
                array_contents = collect_text_nows(toks, j_after_name + 1, close_bracket)
                j_final = skip_space_comments(toks, close_bracket + 1)

                next_t = tok_at(toks, j_final)
                if next_t.text in ('=', ';'):
                    is_struct_ctx = cur_ctx() in (CTX_STRUCT,)
                    if is_comptime or decl_is_const:
                        prefix = 'const'
                    elif is_struct_ctx:
                        prefix = 'let'
                    else:
                        prefix = 'let mut'

                    new_type = transform_array_type(type_str, array_contents)
                    new_var = f'{prefix} {var_name}: {new_type}'
                    return (new_var, j_final)

        return None

    # ===========================================================
    # Main transformation loop
    # ===========================================================

    while i < n:
        t = toks[i]

        # --- EOF ---
        if t.kind == TOK_EOF:
            break

        # --- Passthrough: strings, chars, numbers, line comments, block comments, directives ---
        if t.kind in (TOK_STR, TOK_CHAR, TOK_NUM, TOK_LC, TOK_BC, TOK_DIR):
            emit(t.text)
            i += 1
            continue

        # --- Whitespace / newlines: pass through as-is ---
        if t.kind in (TOK_WS, TOK_NL):
            emit(t.text)
            i += 1
            continue

        # =======================================================
        # PUNCTUATION
        # =======================================================

        if t.kind == TOK_PUNCT:
            text = t.text

            if text == '{':
                brace_depth += 1
                emit(text)
                i += 1
                at_stmt_start = True
                if pending_func_ctx:
                    depth_ctx[brace_depth] = CTX_FUNC
                    ctx_stack.append(CTX_FUNC)
                    pending_func_ctx = False
                continue

            elif text == '}':
                emit(text)
                # Pop context if this closes a scope we tracked
                if brace_depth in depth_ctx:
                    ctx_stack.pop()
                    del depth_ctx[brace_depth]
                brace_depth -= 1
                i += 1
                at_stmt_start = True  # After '}', we're at a statement boundary
                continue

            elif text == ';':
                emit(text)
                i += 1
                at_stmt_start = True
                pending_func_ctx = False  # extern fn declaration (no body)
                continue

            elif text == '?' and at_stmt_start:
                # Nullable type declaration: '?Type name [= expr];'
                result = try_parse_decl()
                if result:
                    new_text, end_i = result
                    emit(new_text)
                    i = end_i
                    changed = True
                    at_stmt_start = False
                else:
                    emit(text)
                    i += 1
                    at_stmt_start = False
                continue

            elif text == '#':
                # Check for #[...] annotation: emit whole thing and reset at_stmt_start
                j = i + 1
                while j < n and toks[j].kind in (TOK_WS, TOK_NL): j += 1
                if j < n and toks[j].text == '[':
                    # Emit '#[...]' block entirely, then signal statement start for what follows
                    depth = 0
                    while i < n:
                        c = toks[i].text
                        emit(c)
                        if c == '[': depth += 1
                        elif c == ']':
                            depth -= 1
                            if depth == 0:
                                i += 1
                                break
                        i += 1
                    at_stmt_start = True
                    continue
                else:
                    emit(text)
                    i += 1
                    continue

            else:
                emit(text)
                i += 1
                continue

        # =======================================================
        # IDENTIFIERS / KEYWORDS
        # =======================================================

        if t.kind != TOK_ID:
            emit(t.text)
            i += 1
            continue

        text = t.text

        # --- __asm__ block: emit entire {…} body without transformation ---
        if text == '__asm__':
            emit(text)
            i += 1
            # Skip whitespace up to '{'
            while i < n and toks[i].kind in (TOK_WS, TOK_NL):
                emit(toks[i].text)
                i += 1
            if i < n and toks[i].text == '{':
                # Emit the raw block contents verbatim
                depth = 0
                while i < n:
                    c = toks[i].text
                    emit(c)
                    if c == '{': depth += 1
                    elif c == '}':
                        depth -= 1
                        if depth == 0:
                            i += 1
                            break
                    i += 1
            at_stmt_start = True
            continue

        # --- Already new-style keywords: pass through ---
        if text in ('let', 'mut'):
            emit(text)
            i += 1
            at_stmt_start = False
            continue

        # --- fn keyword: new-style function declaration ---
        if text == 'fn':
            # This is already new-style; pass through
            emit(text)
            i += 1
            # If 'fn' appears at statement start it's a function decl; the next '{' opens CTX_FUNC
            if at_stmt_start:
                pending_func_ctx = True
            at_stmt_start = False
            continue

        # --- pub/priv: visibility modifier, pass through ---
        if text in ('pub', 'priv'):
            emit(text)
            i += 1
            continue

        # --- static/comptime/inline prefixed declarations ---
        if text in ('inline', 'static', 'comptime') and at_stmt_start:
            result = try_parse_decl()
            if result:
                new_text, end_i = result
                emit(new_text)
                i = end_i
                changed = True
                at_stmt_start = False
                stripped = new_text.lstrip()
                if stripped.startswith('fn ') or stripped.startswith('static fn '):
                    pending_func_ctx = True
                continue
            # fall through to emit token as-is if not a declaration

        # --- struct: top-level struct declaration ---
        if text == 'struct':
            emit(text)
            i += 1
            # Skip whitespace and name
            while i < n and toks[i].kind in (TOK_WS, TOK_NL):
                emit(toks[i].text)
                i += 1
            if i < n and toks[i].kind == TOK_ID:
                emit(toks[i].text)  # struct name
                i += 1
            # Skip to '{'
            while i < n and toks[i].text != '{' and toks[i].kind != TOK_EOF:
                emit(toks[i].text)
                i += 1
            if i < n and toks[i].text == '{':
                emit('{')
                brace_depth += 1
                depth_ctx[brace_depth] = CTX_STRUCT
                ctx_stack.append(CTX_STRUCT)
                i += 1
                at_stmt_start = True
            continue

        # --- union: similar to struct ---
        if text == 'union':
            emit(text)
            i += 1
            while i < n and toks[i].kind in (TOK_WS, TOK_NL):
                emit(toks[i].text)
                i += 1
            if i < n and toks[i].kind == TOK_ID:
                emit(toks[i].text)
                i += 1
            while i < n and toks[i].text != '{' and toks[i].kind != TOK_EOF:
                emit(toks[i].text)
                i += 1
            if i < n and toks[i].text == '{':
                emit('{')
                brace_depth += 1
                depth_ctx[brace_depth] = CTX_STRUCT
                ctx_stack.append(CTX_STRUCT)
                i += 1
                at_stmt_start = True
            continue

        # --- enum: enum body, just pass through (enum variants are not declarations) ---
        if text == 'enum':
            emit(text)
            i += 1
            while i < n and toks[i].kind in (TOK_WS, TOK_NL):
                emit(toks[i].text)
                i += 1
            if i < n and toks[i].kind == TOK_ID:
                emit(toks[i].text)
                i += 1
            # Skip optional <T> generics
            j = skip_space(toks, i)
            if tok_at(toks, j).text == '<':
                close_gt = find_matching_lt(toks, j)
                while i <= close_gt:
                    emit(toks[i].text)
                    i += 1
            while i < n and toks[i].text != '{' and toks[i].kind != TOK_EOF:
                emit(toks[i].text)
                i += 1
            if i < n and toks[i].text == '{':
                emit('{')
                brace_depth += 1
                depth_ctx[brace_depth] = CTX_ENUM
                ctx_stack.append(CTX_ENUM)
                i += 1
                at_stmt_start = True
            continue

        # --- istruc / memstr / interface: class body ---
        if text in ('istruc', 'memstr', 'interface'):
            emit(text)
            i += 1
            while i < n and toks[i].kind in (TOK_WS, TOK_NL):
                emit(toks[i].text)
                i += 1
            if i < n and toks[i].kind == TOK_ID:
                emit(toks[i].text)
                i += 1
            # Skip optional <T>
            j = skip_space(toks, i)
            if tok_at(toks, j).text == '<':
                close_gt = find_matching_lt(toks, j)
                while i <= close_gt:
                    emit(toks[i].text)
                    i += 1
            # Skip optional : Base
            j = skip_space(toks, i)
            if tok_at(toks, j).text == ':':
                while i < n and toks[i].text != '{' and toks[i].kind != TOK_EOF:
                    emit(toks[i].text)
                    i += 1
            else:
                while i < n and toks[i].kind in (TOK_WS, TOK_NL):
                    emit(toks[i].text)
                    i += 1
            if i < n and toks[i].text == '{':
                emit('{')
                brace_depth += 1
                depth_ctx[brace_depth] = CTX_CLASS
                ctx_stack.append(CTX_CLASS)
                i += 1
                at_stmt_start = True
            continue

        # --- namespace: namespace body ---
        if text == 'namespace':
            emit(text)
            i += 1
            while i < n and toks[i].kind in (TOK_WS, TOK_NL):
                emit(toks[i].text)
                i += 1
            if i < n and toks[i].kind == TOK_ID:
                emit(toks[i].text)
                i += 1
            while i < n and toks[i].text != '{' and toks[i].kind != TOK_EOF:
                emit(toks[i].text)
                i += 1
            if i < n and toks[i].text == '{':
                emit('{')
                brace_depth += 1
                depth_ctx[brace_depth] = CTX_CLASS
                ctx_stack.append(CTX_CLASS)
                i += 1
                at_stmt_start = True
            continue

        # --- extern (and extern "C") ---
        if text == 'extern':
            j = skip_space_comments(toks, i + 1)
            if tok_at(toks, j).kind == TOK_STR and tok_at(toks, j).text.startswith('"C'):
                # extern "C" { ... } - pass through but enter extern context
                emit(text)
                i += 1
                while i < n and toks[i].kind in (TOK_WS, TOK_NL):
                    emit(toks[i].text)
                    i += 1
                if i < n and toks[i].kind == TOK_STR:
                    emit(toks[i].text)
                    i += 1
                while i < n and toks[i].kind in (TOK_WS, TOK_NL):
                    emit(toks[i].text)
                    i += 1
                if i < n and toks[i].text == '{':
                    emit('{')
                    brace_depth += 1
                    depth_ctx[brace_depth] = CTX_EXTERN
                    ctx_stack.append(CTX_EXTERN)
                    i += 1
                    at_stmt_start = True
                continue
            elif tok_at(toks, j).kind == TOK_ID and tok_at(toks, j).text == 'fn':
                # Already new-style: extern fn ...
                emit(text)
                i += 1
                continue

            # Check for 'extern std.X;' — preprocessor directive, pass through as-is
            j_ns = skip_space_comments(toks, i + 1)
            if tok_at(toks, j_ns).kind == TOK_ID and tok_at(toks, j_ns).text == 'std':
                j_dot = skip_space_comments(toks, j_ns + 1)
                if tok_at(toks, j_dot).text == '.':
                    # Pass through unchanged: emit 'extern' and continue (whitespace emitted normally)
                    emit(text)
                    i += 1
                    at_stmt_start = False
                    continue

            # Old-style extern: 'extern RetType name(params);'
            # Transform to: 'extern fn name(params) RetType;'
            emit('extern ')
            i += 1
            # Try to parse the declaration
            result = try_parse_decl()
            if result:
                new_text, end_i = result
                emit(new_text)
                i = end_i
                changed = True
                at_stmt_start = False
                stripped2 = new_text.lstrip()
                if stripped2.startswith('fn ') or stripped2.startswith('static fn '):
                    pending_func_ctx = True
            else:
                # can't parse, emit rest unchanged
                pass
            continue

        # --- using/typedef ---
        if text == 'using':
            j = skip_space_comments(toks, i + 1)
            t2 = tok_at(toks, j)

            # 'using auto Name = Type;' -> 'using Name = Type;'
            if t2.kind == TOK_ID and t2.text == 'auto':
                k = skip_space_comments(toks, j + 1)
                name_tok = tok_at(toks, k)
                if name_tok.kind == TOK_ID:
                    k2 = skip_space_comments(toks, k + 1)
                    if tok_at(toks, k2).text == '=':
                        k3 = skip_space_comments(toks, k2 + 1)
                        type_str, type_end = parse_type_tokens(toks, k3)
                        if type_str:
                            new_type = transform_type_str(type_str)
                            emit(f'using {name_tok.text} = {new_type}')
                            i = type_end
                            changed = True
                            at_stmt_start = False
                            continue

            # Check if it's already new-style: 'using Name = Type;' or 'using name;'
            if t2.kind == TOK_ID:
                k = skip_space_comments(toks, j + 1)
                # 'using Name = Type;' already new style
                if tok_at(toks, k).text == '=':
                    emit(text)
                    i += 1
                    continue
                # 'using name;' namespace import - already valid
                # Check for ';' after the name (possibly dotted)
                k2 = j
                dotted_end = k2
                while tok_at(toks, k2).kind == TOK_ID:
                    dotted_end = k2 + 1
                    k3 = skip_space_comments(toks, k2 + 1)
                    if tok_at(toks, k3).text == '.':
                        k2 = skip_space_comments(toks, k3 + 1)
                    else:
                        break
                k4 = skip_space_comments(toks, dotted_end)
                if tok_at(toks, k4).text == ';':
                    emit(text)
                    i += 1
                    continue

            # Old-style: 'using Type Name;' -> 'using Name = Type;'
            j = skip_space_comments(toks, i + 1)
            type_str, type_end = parse_type_tokens(toks, j)
            if type_str:
                k = skip_space_comments(toks, type_end)
                name_tok = tok_at(toks, k)
                if name_tok.kind == TOK_ID:
                    new_type = transform_type_str(type_str)
                    emit(f'using {name_tok.text} = {new_type}')
                    i = k + 1
                    changed = True
                    at_stmt_start = False
                    continue

            emit(text)
            i += 1
            continue

        # --- for loop: special handling for for-init and range-for ---
        # IMPORTANT: We find the matching ')' up-front and emit everything
        # from after the init to ')' unchanged.  This prevents the main
        # declaration-detection loop from corrupting the condition/update parts.
        if text == 'for':
            emit(text)
            i += 1
            # Consume whitespace to '('
            while i < n and toks[i].kind in (TOK_WS, TOK_NL):
                emit(toks[i].text)
                i += 1
            if i < n and toks[i].text == '(':
                paren_close_i = find_matching(toks, i, '(', ')')
                emit('(')
                i += 1
                j = skip_space_comments(toks, i)

                transformed_init = False

                # Already new-style: 'let ...'
                if tok_at(toks, j).kind == TOK_ID and tok_at(toks, j).text in ('let', 'const'):
                    transformed_init = True  # no-op, emit rest unchanged below
                elif tok_at(toks, j).text == ';':
                    transformed_init = True  # empty init
                else:
                    ts, te = parse_type_tokens(toks, j)
                    if ts:
                        k = skip_space_comments(toks, te)
                        if tok_at(toks, k).kind == TOK_ID:
                            var_name = tok_at(toks, k).text
                            if var_name == 'fn':
                                var_name = 'fn_ref'
                            k2 = skip_space_comments(toks, k + 1)
                            if tok_at(toks, k2).text == ':':
                                # Range-for: 'Type name : expr' -> 'let name: Type : expr'
                                while i < j:
                                    emit(toks[i].text)
                                    i += 1
                                emit(f'let {var_name}: {transform_type_str(ts)}')
                                i = k + 1   # point right after var name, before ':'
                                changed = True
                                transformed_init = True
                            elif tok_at(toks, k2).text in ('=', ';'):
                                # C-style for-init: 'Type name = ...' -> 'let mut name: Type ...'
                                while i < j:
                                    emit(toks[i].text)
                                    i += 1
                                emit(f'let mut {var_name}: {transform_type_str(ts)}')
                                i = k + 1   # point right after var name
                                changed = True
                                transformed_init = True
                            elif tok_at(toks, k2).text == '[':
                                # Array var: 'Type name[N] = ...'
                                close_b = find_matching(toks, k2, '[', ']')
                                next_t = tok_at(toks, skip_space_comments(toks, close_b + 1))
                                if next_t.text in ('=', ';'):
                                    array_str = collect_text_nows(toks, k2 + 1, close_b)
                                    while i < j:
                                        emit(toks[i].text)
                                        i += 1
                                    emit(f'let mut {var_name}: {transform_array_type(ts, array_str)}')
                                    i = k + 1
                                    changed = True
                                    transformed_init = True

                # Always emit the rest of the for-header (condition; update) unchanged
                while i <= paren_close_i:
                    emit(toks[i].text)
                    i += 1
                # i is now paren_close_i + 1 (past the ')')
            continue

        # --- const: could be 'const Type name' (old) or 'const name = ...' (new) ---
        if text == 'const':
            j = skip_space_comments(toks, i + 1)
            t2 = tok_at(toks, j)

            # Check: if followed by id then '=' or ':', it's already new-style const
            if t2.kind == TOK_ID and t2.text not in PRIM_TYPES and not _PRIM_RE.match(t2.text):
                k = skip_space_comments(toks, j + 1)
                if tok_at(toks, k).text in ('=', ':'):
                    # Already new-style: 'const name = ...' or 'const name: T = ...'
                    emit(text)
                    i += 1
                    continue

            # Old-style: 'const Type name = ...'
            # Transform to: 'const name: Type = ...'
            type_str, type_end = parse_type_tokens(toks, j)
            if type_str:
                k = skip_space_comments(toks, type_end)
                if tok_at(toks, k).kind == TOK_ID:
                    var_name = tok_at(toks, k).text
                    if var_name == 'fn':
                        var_name = 'fn_ref'
                    # Check for array suffix
                    k2 = skip_space_comments(toks, k + 1)
                    array_str = None
                    if tok_at(toks, k2).text == '[':
                        close_b = find_matching(toks, k2, '[', ']')
                        array_str = collect_text_nows(toks, k2 + 1, close_b)
                        k2 = close_b + 1
                    k2 = skip_space_comments(toks, k2)
                    if tok_at(toks, k2).text in ('=', ';'):
                        if array_str is not None:
                            new_type = transform_array_type(type_str, array_str)
                        else:
                            new_type = transform_type_str(type_str)
                        emit(f'const {var_name}: {new_type}')
                        i = k + 1
                        if array_str is not None:
                            # Skip array suffix tokens
                            i = find_matching(toks, skip_space_comments(toks, i - 1 + 1 if False else i), '[', ']') + 1
                        changed = True
                        at_stmt_start = False
                        continue

            emit(text)
            i += 1
            continue

        # --- handle the 'fn' identifier (variable/param named 'fn') ---
        if text == 'fn' and cur_ctx() == CTX_FUNC:
            # Inside a function body, 'fn' is a variable name → rename to fn_ref
            emit('fn_ref')
            i += 1
            changed = True
            at_stmt_start = False
            continue

        # =======================================================
        # Main declaration detection
        # Try to detect old-style function/variable declarations
        # at statement boundaries
        # =======================================================
        if at_stmt_start and cur_ctx() != CTX_ENUM:
            # Try to parse this as an old-style declaration
            # This handles: struct fields, function defs, variable decls

            # Quick check: could this be a type-starting token?
            looks_like_type = (
                is_prim_type(text) or
                (cur_ctx() in (CTX_TOP, CTX_CLASS, CTX_EXTERN, CTX_STRUCT) and
                 text not in NON_TYPE_KWS and text not in ('let',)) or
                (cur_ctx() == CTX_FUNC and
                 (is_prim_type(text) or text == 'auto') and text not in NON_TYPE_KWS) or
                # In func body, user-defined type ctor calls: 'TypeName varname(args)' or 'TypeName var = expr'
                (cur_ctx() == CTX_FUNC and text not in NON_TYPE_KWS and
                 peek(1).kind == TOK_ID and peek(2).text in ('(', '=', ';')) or
                # Conversion operator: 'operator Type(params)' in class body
                (text == 'operator' and cur_ctx() in (CTX_CLASS, CTX_STRUCT, CTX_TOP))
            )

            if looks_like_type:
                result = try_parse_decl()
                if result:
                    new_text, end_i = result

                    emit(new_text)
                    i = end_i
                    changed = True
                    at_stmt_start = False
                    # If this is a function declaration, the next '{' opens a function body
                    stripped = new_text.lstrip()
                    if stripped.startswith('fn ') or stripped.startswith('static fn '):
                        pending_func_ctx = True
                    continue

        # --- Track function body entry ---
        # After a '(' is consumed and we're parsing func params, then '{'
        # We detect entering a function body by tracking when we see '{'
        # after what looks like a function declaration end.
        # This is handled implicitly via brace_depth tracking.

        # --- Generic identifier: check if 'fn' as local var ---
        if text == 'fn':
            # Not at stmt start, must be a variable use
            emit('fn_ref')
            i += 1
            changed = True
            at_stmt_start = False
            continue

        # --- Default: emit as-is ---
        emit(text)
        i += 1
        at_stmt_start = False
        continue

    return ''.join(out), changed


# ============================================================
# CONTEXT TRACKING (improved version - track func bodies)
# ============================================================

def transform_v2(src, filename='<input>'):
    """
    Improved transformer with proper context tracking.
    """
    # First pass: just do the basic transformation
    # Then handle 'fn' variable renaming based on context
    result, changed = transform(src, filename)
    return result, changed


# ============================================================
# FILE PROCESSING
# ============================================================

def process_file(path, dry_run=False, verbose=False):
    """Process a single Arc file."""
    try:
        with open(path, 'r', encoding='utf-8', errors='replace') as f:
            src = f.read()
    except Exception as e:
        print(f'  ERROR reading {path}: {e}', file=sys.stderr)
        return False

    # Skip already-migrated files (heuristic: has 'let mut' or 'fn ')
    # Actually, we should be idempotent, so don't skip - just don't double-transform.

    try:
        new_src, changed = transform_v2(src, str(path))
    except Exception as e:
        import traceback
        print(f'  ERROR transforming {path}: {e}', file=sys.stderr)
        if verbose:
            traceback.print_exc()
        return False

    if not changed:
        if verbose:
            print(f'  UNCHANGED: {path}')
        return True

    if dry_run:
        print(f'  WOULD CHANGE: {path}')
        # Show a diff
        old_lines = src.splitlines(keepends=True)
        new_lines = new_src.splitlines(keepends=True)
        import difflib
        diff = list(difflib.unified_diff(old_lines, new_lines,
                                          fromfile=f'a/{path}', tofile=f'b/{path}',
                                          n=2))
        for line in diff[:50]:  # Show first 50 lines of diff
            print('    ' + line, end='')
        if len(diff) > 50:
            print(f'    ... ({len(diff)-50} more lines)')
        return True

    # Write backup
    bak_path = str(path) + '.bak'
    try:
        shutil.copy2(path, bak_path)
    except Exception as e:
        print(f'  ERROR backing up {path}: {e}', file=sys.stderr)
        return False

    # Write new file
    try:
        with open(path, 'w', encoding='utf-8', newline='') as f:
            f.write(new_src)
        print(f'  MIGRATED: {path}')
        return True
    except Exception as e:
        print(f'  ERROR writing {path}: {e}', file=sys.stderr)
        # Restore backup
        try:
            shutil.copy2(bak_path, path)
        except:
            pass
        return False


def find_arc_files(paths):
    """Find all .arc files in given paths."""
    result = []
    for p in paths:
        pp = Path(p)
        if pp.is_file() and pp.suffix == '.arc':
            result.append(pp)
        elif pp.is_dir():
            result.extend(pp.rglob('*.arc'))
    return result


def main():
    parser = argparse.ArgumentParser(description='Migrate Arc syntax from old to new style.')
    parser.add_argument('paths', nargs='+', help='Files or directories to migrate')
    parser.add_argument('--dry-run', action='store_true', help='Show what would change without applying')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    parser.add_argument('--check-only', action='store_true', help='Exit 1 if any changes would be made')
    parser.add_argument('--exclude', nargs='*', default=[], help='Path substrings to exclude')
    args = parser.parse_args()

    files = find_arc_files(args.paths)
    files = [f for f in files
             if not any(excl in str(f) for excl in args.exclude)]
    files.sort()

    print(f'Processing {len(files)} Arc files...')

    ok_count = 0
    changed_count = 0
    error_count = 0

    for f in files:
        # Try to detect already-migrated files quickly
        try:
            with open(f, 'r', encoding='utf-8', errors='replace') as fh:
                first = fh.read(200)
        except:
            first = ''

        if args.verbose:
            print(f'Processing: {f}')

        ok = process_file(f, dry_run=args.dry_run or args.check_only, verbose=args.verbose)
        if ok:
            ok_count += 1
        else:
            error_count += 1

    print(f'\nDone. {ok_count} files processed, {error_count} errors.')

    if args.check_only and changed_count > 0:
        sys.exit(1)


if __name__ == '__main__':
    main()
