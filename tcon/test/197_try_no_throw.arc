// Test error-union function that always succeeds — handler must not run
fn add(a: i32, b: i32) !i32 {
    return a + b;
}

pub fn main() i32 {
    let mut err_fired: i32= 0;

    add(3, 4) catch |e| {
        err_fired = 1;
    }

    if (err_fired != 0) { return 1; }
    return 0;
}
