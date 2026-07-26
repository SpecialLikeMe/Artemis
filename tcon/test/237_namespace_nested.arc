// Nested namespace access
namespace math {
    let mut base: i32;

    fn double_base() i32 { return math.base * 2; }

    namespace consts {
        let mut pi_approx: i32;
        let mut e_approx: i32;
        fn sum() i32 { return math.consts.pi_approx + math.consts.e_approx; }
    }
}

pub fn main() i32 {
    math.base         = 7;
    math.consts.pi_approx = 3;
    math.consts.e_approx  = 2;

    if (math.double_base()    != 14) { return 1; }
    if (math.consts.sum()     != 5)  { return 2; }
    if (math.consts.pi_approx != 3)  { return 3; }

    return 0;
}
