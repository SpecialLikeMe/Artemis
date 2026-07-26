enum Month { Jan = 1, Feb, Mar, Apr, May, Jun,
              Jul, Aug, Sep, Oct, Nov, Dec }

pub fn main() i32 {
    if (Jan != 1)  { return 1; }
    if (Feb != 2)  { return 2; }
    if (Dec != 12) { return 3; }
    let mut q2_start: i32= Apr;
    let mut q2_end: i32= Jun;
    if (q2_end - q2_start != 2) { return 4; }
    return 0;
}
