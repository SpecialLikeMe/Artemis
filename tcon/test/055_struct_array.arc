struct Item {
    i32 id;
    i32 value;
}

i32 main() {
    Item items[3];
    items[0].id = 1;  items[0].value = 10;
    items[1].id = 2;  items[1].value = 20;
    items[2].id = 3;  items[2].value = 30;

    i32 total = 0;
    for (i32 i = 0; i < 3; i++) {
        total = total + items[i].value;
    }
    if (total != 60) { return 1; }
    if (items[1].id != 2) { return 2; }
    return 0;
}
