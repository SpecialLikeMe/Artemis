i32 main() {
    i32 x = 10;
    x += 5;  if (x != 15) { return 1; }
    x -= 3;  if (x != 12) { return 2; }
    x *= 2;  if (x != 24) { return 3; }
    x /= 4;  if (x != 6)  { return 4; }
    x %= 4;  if (x != 2)  { return 5; }
    x <<= 3; if (x != 16) { return 6; }
    x >>= 1; if (x != 8)  { return 7; }
    x &= 3;  if (x != 0)  { return 8; }
    x |= 7;  if (x != 7)  { return 9; }
    x ^= 5;  if (x != 2)  { return 10; }
    return 0;
}
