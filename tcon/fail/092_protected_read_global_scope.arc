// FAIL: reading a protected member from global scope (no class context)
istruc Config { protected i32 timeout; }
Config global_cfg;
i32 main() {
    return global_cfg.timeout;  // ERROR: timeout is protected, no class context
}
