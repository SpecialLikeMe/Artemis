// Nested namespace access
namespace math {
    i32 base;

    i32 double_base() { return math.base * 2; }

    namespace consts {
        i32 pi_approx;
        i32 e_approx;
        i32 sum() { return math.consts.pi_approx + math.consts.e_approx; }
    }
}

i32 main() {
    math.base         = 7;
    math.consts.pi_approx = 3;
    math.consts.e_approx  = 2;

    if (math.double_base()    != 14) { return 1; }
    if (math.consts.sum()     != 5)  { return 2; }
    if (math.consts.pi_approx != 3)  { return 3; }

    return 0;
}
