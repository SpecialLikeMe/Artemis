extern i32 sprintf(i8* buf, const i8* fmt, ...);

i32 main() {
    i8 buf[32];
    i32 n = sprintf(buf, "%d", 12345);
    if (n != 5) { return 1; }
    return 0;
}
