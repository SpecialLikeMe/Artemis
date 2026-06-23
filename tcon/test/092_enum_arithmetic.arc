enum Month { Jan = 1, Feb, Mar, Apr, May, Jun,
              Jul, Aug, Sep, Oct, Nov, Dec }

i32 main() {
    if (Jan != 1)  { return 1; }
    if (Feb != 2)  { return 2; }
    if (Dec != 12) { return 3; }
    i32 q2_start = Apr;
    i32 q2_end   = Jun;
    if (q2_end - q2_start != 2) { return 4; }
    return 0;
}
