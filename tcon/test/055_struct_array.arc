struct Item {
    let id: i32;
    let value: i32;
}

pub fn main() i32 {
    let mut items: [3]Item;
    items[0].id = 1;  items[0].value = 10;
    items[1].id = 2;  items[1].value = 20;
    items[2].id = 3;  items[2].value = 30;

    let mut total: i32= 0;
    for (let mut i: i32 = 0; i < 3; i++) {
        total = total + items[i].value;
    }
    if (total != 60) { return 1; }
    if (items[1].id != 2) { return 2; }
    return 0;
}
