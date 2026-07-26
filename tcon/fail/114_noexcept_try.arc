// FAIL: 'try' inside a  function is forbidden
auto maybe_fail() !i32 {
    return error.Oops;
}

fn run() i32  {
    let mut v: i32= try maybe_fail();  // must error
    return v;
}

fn main() i32 { return run(); }
