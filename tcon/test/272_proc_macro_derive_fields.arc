// PASS: derive macro on an istruc with multiple field types.
// Injected functions operate on the decorated struct's fields.

fn add_builder(&memstr alloc, tokenstream* input) *tokenstream derive {
    return quote {
        fn make_config(w: i32, h: i32) Config {
            let mut c: Config();
            c.width = w;
            c.height = h;
            return c;
        }
    };
}

fn add_validator(&memstr alloc, tokenstream* input) *tokenstream derive {
    return quote {
        fn config_is_valid(c: *Config) bool {
            return c.width > 0 && c.height > 0 && c.enabled;
        }
    };
}

#derive[add_builder]
#derive[add_validator]
istruc Config {
    let mut width: i32;
    let mut height: i32;
    let mut depth: i32;
    let mut scale: f32;
    let mut enabled: bool;
    fn __construct__(self: *Config) void {
        self.width = 640;
        self.height = 480;
        self.depth = 32;
        self.scale = 1.0;
        self.enabled = true;
    }
    fn area(self: *Config) i32 { return self.width * self.height; }
}

pub fn main() i32 {
    let mut c: Config();
    if (c.area() != 307200) { return 1; }
    if (!c.enabled) { return 2; }
    // Verify builder macro injected a factory function
    let mut c2: Config = make_config(1920, 1080);
    if (c2.area() != 2073600) { return 3; }
    // Verify validator macro injected a validation function
    if (!config_is_valid(&c)) { return 4; }
    c.enabled = false;
    if (config_is_valid(&c)) { return 5; }
    if (!config_is_valid(&c2)) { return 6; }
    return 0;
}
