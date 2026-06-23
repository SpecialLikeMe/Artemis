void double_val(i32* p) {
    *p = *p * 2;
}

void swap(i32* a, i32* b) {
    i32 tmp = *a;
    *a = *b;
    *b = tmp;
}

i32 main() {
    i32 x = 5;
    double_val(&x);
    if (x != 10) { return 1; }

    i32 a = 3;
    i32 b = 7;
    swap(&a, &b);
    if (a != 7) { return 2; }
    if (b != 3) { return 3; }
    return 0;
}
