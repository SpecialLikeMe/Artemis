@unsafe extern fn memset(ptr: *void, val: i32, n: u64) *void;

pub @unsafe fn main() i32 {
    let mut arr: [8]i32;
    memset(arr, 0, sizeof(i32) * 8);
    for (let mut i: i32 = 0; i < 8; i++) {
        if (arr[i] != 0) { return 1; }
    }
    return 0;
}
