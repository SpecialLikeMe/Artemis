// FAIL: reading a protected member from global scope (no class context)
istruc Config { protected i32 timeout; }
let mut global_cfg: Config;
fn main() i32 {
    return global_cfg.timeout;  // ERROR: timeout is protected, no class context
}
