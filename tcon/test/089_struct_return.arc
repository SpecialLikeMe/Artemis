struct MinMax {
    let min: i32;
    let max: i32;
}

fn find_minmax(a: i32, b: i32) MinMax {
    let mut r: MinMax;
    if (a < b) { r.min = a; r.max = b; }
    else       { r.min = b; r.max = a; }
    return r;
}

pub fn main() i32 {
    let mut mm: MinMax= find_minmax(7, 3);
    if (mm.min != 3) { return 1; }
    if (mm.max != 7) { return 2; }

    let mut mm2: MinMax= find_minmax(5, 5);
    if (mm2.min != 5) { return 3; }
    if (mm2.max != 5) { return 4; }
    return 0;
}
