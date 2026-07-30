import re, sys, os

# Rewrite a memstr's five operations to the new ABI:
#   mmap(self, n)            -> mmap(self, align: usize, n: usize) !*void
#   rsmap(self, p, n)        -> unchanged shape, bool
#   rmap(self, p, n)         -> rmap(self, align: usize, p, n: iofs) !*void
#   free(self, p)            -> !void
#   destroy(self) / deinit   -> !void
def migrate(path):
    src = open(path, encoding="utf-8").read()
    orig = src

    # mmap: insert the alignment parameter and make the return an error union.
    src = re.sub(
        r'fn mmap\(self:\s*\*(\w+),\s*(\w+):\s*u(?:64|size)\)\s*\*void',
        lambda m: f'fn mmap(self: *{m.group(1)}, align: usize, {m.group(2)}: usize) !*void',
        src)
    # rmap: alignment first, error-union return, size as iofs.
    src = re.sub(
        r'fn rmap\(self:\s*\*(\w+),\s*(\w+):\s*\*void,\s*(\w+):\s*(?:u64|iofs|usize)\)\s*(?:\*void|void)',
        lambda m: f'fn rmap(self: *{m.group(1)}, align: usize, {m.group(2)}: *void, {m.group(3)}: iofs) !*void',
        src)
    # free / destroy / deinit become fallible.
    src = re.sub(r'fn free\(self:\s*\*(\w+),\s*(\w+):\s*\*void\)\s*void',
                 lambda m: f'fn free(self: *{m.group(1)}, {m.group(2)}: *void) !void', src)
    src = re.sub(r'fn destroy\(self:\s*\*(\w+)\)\s*void',
                 lambda m: f'fn destroy(self: *{m.group(1)}) !void', src)
    src = re.sub(r'fn deinit\(self:\s*\*(\w+)\)\s*void',
                 lambda m: f'fn deinit(self: *{m.group(1)}) !void', src)
    # rsmap size type -> iofs (shape otherwise unchanged)
    src = re.sub(r'fn rsmap\(self:\s*\*(\w+),\s*(\w+):\s*\*void,\s*(\w+):\s*(?:u64|i64|usize)\)\s*bool',
                 lambda m: f'fn rsmap(self: *{m.group(1)}, {m.group(2)}: *void, {m.group(3)}: iofs) bool', src)

    if src != orig:
        open(path, "w", encoding="utf-8").write(src)
        return True
    return False

n = 0
for p in sys.argv[1:]:
    if migrate(p):
        n += 1
        print("migrated", os.path.relpath(p))
print("files changed:", n)
