struct Num { i32 v; }

void bubble_sort(Num* arr, i32 n) {
    for (i32 i = 0; i < n - 1; i++) {
        for (i32 j = 0; j < n - i - 1; j++) {
            if (arr[j].v > arr[j+1].v) {
                i32 tmp     = arr[j].v;
                arr[j].v    = arr[j+1].v;
                arr[j+1].v  = tmp;
            }
        }
    }
}

i32 main() {
    Num arr[5];
    arr[0].v = 5; arr[1].v = 1; arr[2].v = 4;
    arr[3].v = 2; arr[4].v = 3;
    bubble_sort(arr, 5);
    for (i32 i = 0; i < 5; i++) {
        if (arr[i].v != i + 1) { return 1; }
    }
    return 0;
}
