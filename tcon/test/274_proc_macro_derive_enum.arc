// PASS: derive proc macros on an istruc with multiple field types.
// Injected functions operate on the decorated type's fields.

fn add_lerp(&memstr alloc, tokenstream* input) *tokenstream derive {
    return quote {
        fn lerp_color(a: *Color, b: *Color, t_num: i32, t_den: i32) Color {
            let mut c: Color(
                a.r + (b.r - a.r) * t_num / t_den,
                a.g + (b.g - a.g) * t_num / t_den,
                a.b + (b.b - a.b) * t_num / t_den
            );
            return c;
        }
    };
}

fn add_luminance(&memstr alloc, tokenstream* input) *tokenstream derive {
    return quote {
        fn luminance(c: *Color) i32 {
            return (c.r * 299 + c.g * 587 + c.b * 114) / 1000;
        }
    };
}

#derive[add_lerp]
#derive[add_luminance]
istruc Color {
    let mut r: i32;
    let mut g: i32;
    let mut b: i32;
    fn __construct__(self: *Color, r: i32, g: i32, b: i32) void {
        self.r = r; self.g = g; self.b = b;
    }
    fn brightness(self: *Color) i32 {
        return (self.r + self.g + self.b) / 3;
    }
}

pub fn main() i32 {
    let mut black: Color(0, 0, 0);
    let mut white: Color(255, 255, 255);
    // lerp at 50% should be mid-gray (127 due to integer truncation)
    let mut mid: Color = lerp_color(&black, &white, 1, 2);
    if (mid.r != 127) { return 1; }
    if (mid.g != 127) { return 2; }
    if (mid.b != 127) { return 3; }
    // luminance of red vs green vs blue (green should be highest)
    let mut red: Color(255, 0, 0);
    let mut green: Color(0, 255, 0);
    let mut blue: Color(0, 0, 255);
    let mut lr: i32 = luminance(&red);
    let mut lg: i32 = luminance(&green);
    let mut lb: i32 = luminance(&blue);
    if (lg <= lr) { return 4; }
    if (lg <= lb) { return 5; }
    if (lr <= lb) { return 6; }
    return 0;
}
