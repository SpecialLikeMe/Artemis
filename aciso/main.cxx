#include "aciso.hxx"
#include <cstring>

// ---- forward declarations ----
void cmd_init(bool use_toml);
void cmd_deinit();

void cmd_install(const std::string& pkg_name, const std::string& url);
void cmd_uninstall(const std::string& pkg_name);
void cmd_update(const std::string& pkg_name);
void cmd_vald();
void cmd_audit();

void cmd_build(bool release);
void cmd_sbuild(const std::string& target_name);
void cmd_run();
void cmd_clean();
void cmd_cache();
void cmd_uncache();

void cmd_add(const std::string& filename);
void cmd_addf(const std::string& filename, const std::string& type);
void cmd_rmt(const std::string& target_name);
void cmd_lst();

void cmd_itarget(const std::string& symbol);
void cmd_utarget(const std::string& symbol);

void cmd_fmt(const std::string& path);
void cmd_sta(const std::string& path);
void cmd_test();
void cmd_bench();

void cmd_export(bool use_toml);
void cmd_conv(bool to_toml);

// ---- help ----

static void print_help() {
    std::cout <<
"aciso — Artemis package manager & build system\n"
"\n"
"USAGE: aciso <command> [args]\n"
"\n"
"INIT\n"
"  init [-t|-j]         Create aciso/acm config + src/main.arc (-t=toml, -j=json)\n"
"  deinit               Remove manifests (preserves source)\n"
"\n"
"PACKAGES\n"
"  install <name> <url> Clone URL, pull export files into modules/<name>/\n"
"  uninstall <name>     Remove package from modules/ and manifests\n"
"  update <name>        Re-download and reinstall package\n"
"  vald                 Check all declared packages exist in modules/\n"
"  audit                Verify SHA-256 hashes of installed packages\n"
"\n"
"BUILD\n"
"  build [--release]    Compile all targets (--release: only __RELEASE defined)\n"
"  run                  Build native executable and run it\n"
"  sbuild <target>      Build a single named target\n"
"  clean                Delete build/ directory\n"
"  cache                Pre-warm build cache\n"
"  uncache              Delete build cache\n"
"\n"
"TARGETS\n"
"  add <file.ext>       Detect type from extension and register target\n"
"  addf <file.ext> <t>  Register target with explicit type\n"
"  rmt <target>         Remove a named build target\n"
"  lst                  List all build targets\n"
"\n"
"SYMBOLS\n"
"  itarget <SYM>        Define preprocessor symbol\n"
"  utarget <SYM>        Undefine preprocessor symbol\n"
"\n"
"DEV TOOLS\n"
"  fmt [path]           Format .arc source (workspace if omitted)\n"
"  sta [path]           Static analysis (workspace if omitted)\n"
"  test                 Run all .arct test files, report failures\n"
"  bench                Run all .arcb bench files, report times\n"
"\n"
"PUBLISH\n"
"  export               Create export.[json|toml] for this package\n"
"  conv [-j|-t]         Convert config files between JSON and TOML\n"
"\n"
"OUTPUT TYPES:  exe  elf  mco  dll  so  dylib  static  wasm  wasi  ll  bc  obj\n"
"OUTPUT DIR:    build/  (configurable in aciso.json/.toml)\n";
}

// ---- main ----

int main(int argc, char** argv) {
    if (argc < 2) { print_help(); return 0; }

    std::string cmd = argv[1];

    if (cmd == "help" || cmd == "-h" || cmd == "--help") {
        print_help();
        return 0;
    }

    if (cmd == "init") {
        bool use_toml = false;
        bool use_json = false;
        for (int i = 2; i < argc; ++i) {
            if (std::strcmp(argv[i], "-t") == 0) use_toml = true;
            if (std::strcmp(argv[i], "-j") == 0) use_json = true;
        }
        (void)use_json;
        cmd_init(use_toml);
        return 0;
    }

    if (cmd == "deinit") { cmd_deinit(); return 0; }

    if (cmd == "install") {
        if (argc < 4) { err("usage: aciso install <name> <url>"); return 1; }
        cmd_install(argv[2], argv[3]);
        return 0;
    }

    if (cmd == "uninstall") {
        if (argc < 3) { err("usage: aciso uninstall <name>"); return 1; }
        cmd_uninstall(argv[2]);
        return 0;
    }

    if (cmd == "update") {
        if (argc < 3) { err("usage: aciso update <name>"); return 1; }
        cmd_update(argv[2]);
        return 0;
    }

    if (cmd == "vald")  { cmd_vald();  return 0; }
    if (cmd == "audit") { cmd_audit(); return 0; }

    if (cmd == "build") {
        bool release = (argc >= 3 && std::strcmp(argv[2], "--release") == 0);
        cmd_build(release);
        return 0;
    }

    if (cmd == "run")    { cmd_run();   return 0; }
    if (cmd == "clean")  { cmd_clean(); return 0; }
    if (cmd == "cache")  { cmd_cache(); return 0; }
    if (cmd == "uncache"){ cmd_uncache(); return 0; }

    if (cmd == "sbuild") {
        if (argc < 3) { err("usage: aciso sbuild <target>"); return 1; }
        cmd_sbuild(argv[2]);
        return 0;
    }

    if (cmd == "add") {
        if (argc < 3) { err("usage: aciso add <filename.ext>"); return 1; }
        cmd_add(argv[2]);
        return 0;
    }

    if (cmd == "addf") {
        if (argc < 4) { err("usage: aciso addf <filename.ext> <type>"); return 1; }
        cmd_addf(argv[2], argv[3]);
        return 0;
    }

    if (cmd == "rmt") {
        if (argc < 3) { err("usage: aciso rmt <target>"); return 1; }
        cmd_rmt(argv[2]);
        return 0;
    }

    if (cmd == "lst") { cmd_lst(); return 0; }

    if (cmd == "itarget") {
        if (argc < 3) { err("usage: aciso itarget <SYMBOL>"); return 1; }
        cmd_itarget(argv[2]);
        return 0;
    }

    if (cmd == "utarget") {
        if (argc < 3) { err("usage: aciso utarget <SYMBOL>"); return 1; }
        cmd_utarget(argv[2]);
        return 0;
    }

    if (cmd == "fmt") {
        cmd_fmt(argc >= 3 ? argv[2] : "");
        return 0;
    }

    if (cmd == "sta") {
        cmd_sta(argc >= 3 ? argv[2] : "");
        return 0;
    }

    if (cmd == "test")  { cmd_test();  return 0; }
    if (cmd == "bench") { cmd_bench(); return 0; }

    if (cmd == "export") {
        bool use_toml = project_uses_toml();
        cmd_export(use_toml);
        return 0;
    }

    if (cmd == "conv") {
        bool to_toml = false, to_json = false;
        for (int i = 2; i < argc; ++i) {
            if (std::strcmp(argv[i], "-t") == 0) to_toml = true;
            if (std::strcmp(argv[i], "-j") == 0) to_json = true;
        }
        if (!to_toml && !to_json) { err("usage: aciso conv [-j|-t]"); return 1; }
        cmd_conv(to_toml);
        return 0;
    }

    err("unknown command: " + cmd + "  (run 'aciso help' for usage)");
    return 1;
}
