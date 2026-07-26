// Static local variables: persist across function calls
fn counter() i32 {
    let mut count: static i32= 0;
    count = count + 1;
    return count;
}

fn fib_memo(n: i32) i32 {
    // Static locals in different functions are independent
    let mut last_n: static i32= -1;
    let mut last_result: static i32= 0;
    if (n == last_n) { return last_result; }
    let mut r: i32= 0;
    if (n <= 1) { r = n; }
    else { r = fib_memo(n - 1) + fib_memo(n - 2); }
    last_n = n;
    last_result = r;
    return r;
}

pub fn main() i32 {
    // counter() should increment each call
    if (counter() != 1) { return 1; }
    if (counter() != 2) { return 2; }
    if (counter() != 3) { return 3; }

    // static local initialized only once even after multiple calls
    if (fib_memo(10) != 55) { return 4; }
    if (fib_memo(10) != 55) { return 5; }
    if (fib_memo(7)  != 13) { return 6; }

    return 0;
}
