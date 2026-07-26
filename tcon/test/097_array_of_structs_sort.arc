struct Num { let v: i32; }

fn bubble_sort(arr: *Num, n: i32) void {
    for (let mut i: i32 = 0; i < n - 1; i++) {
        for (let mut j: i32 = 0; j < n - i - 1; j++) {
            if (arr[j].v > arr[j+1].v) {
                let mut tmp: i32= arr[j].v;
                arr[j].v    = arr[j+1].v;
                arr[j+1].v  = tmp;
            }
        }
    }
}

pub fn main() i32 {
    let mut arr: [5]Num;
    arr[0].v = 5; arr[1].v = 1; arr[2].v = 4;
    arr[3].v = 2; arr[4].v = 3;
    bubble_sort(arr, 5);
    for (let mut i: i32 = 0; i < 5; i++) {
        if (arr[i].v != i + 1) { return 1; }
    }
    return 0;
}
