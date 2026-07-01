#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <string>
#include <vector>
#include <algorithm>

#ifdef _WIN32
#  include <io.h>
#  define popen  _popen
#  define pclose _pclose
#else
#  include <unistd.h>
#  include <sys/wait.h>
#endif

static std::string artemis_bin(const std::string& exe_dir) {
#if defined(_MSC_VER)
    char* val = nullptr; size_t len = 0;
    _dupenv_s(&val, &len, "ARTEMIS_BIN");
    std::string r = val ? val : "";
    free(val);
    if (!r.empty()) return r;
#else
    const char* e = std::getenv("ARTEMIS_BIN");
    if (e) return e;
#endif
    // Try build/artemis.exe relative to the exe's parent directory.
    namespace fs = std::filesystem;
    if (!exe_dir.empty()) {
        fs::path candidate = fs::path(exe_dir).parent_path() / "build" / "artemis.exe";
        if (fs::exists(candidate)) return candidate.string();
        candidate = fs::path(exe_dir) / ".." / "build" / "artemis.exe";
        if (fs::exists(candidate)) return candidate.string();
    }
    return "artemis";
}

static int run_cmd(const std::string& cmd) {
    // Use popen to run silently (avoids nul/dev/null platform issues).
    // Append stderr redirect so compile errors don't pollute output.
#ifdef _WIN32
    std::string full = cmd + " 2>&1";
#else
    std::string full = cmd + " 2>&1";
#endif
    FILE* p = popen(full.c_str(), "r");
    if (!p) return 1;
    char buf[256];
    while (fgets(buf, sizeof(buf), p)) {}  // drain output
    int rc = pclose(p);
#ifndef _WIN32
    if (WIFEXITED(rc)) rc = WEXITSTATUS(rc);
    else               rc = 1;
#endif
    return rc;
}

// On Windows/cmd.exe, forward slashes in a leading path component are treated
// as switch prefixes. Convert to backslashes so the binary can be executed.
static std::string to_native_path(std::string p) {
#ifdef _WIN32
    for (char& c : p) if (c == '/') c = '\\';
#endif
    return p;
}

int main(int argc, char** argv) {
    namespace fs = std::filesystem;

    // Derive paths relative to the executable so the runner works from any CWD.
    std::string exe_dir;
    {
        fs::path ep = fs::path(argv[0]).parent_path();
        if (!ep.empty()) exe_dir = ep.string();
    }

    std::string test_dir;
    if (argc >= 2) {
        test_dir = argv[1];
    } else {
#ifndef ARC_DEFAULT_TEST_SUBDIR
#  define ARC_DEFAULT_TEST_SUBDIR "test"
#endif
        fs::path candidate = exe_dir.empty()
            ? fs::path(ARC_DEFAULT_TEST_SUBDIR)
            : (fs::path(exe_dir).parent_path() / "tcon" / ARC_DEFAULT_TEST_SUBDIR);
        if (!fs::is_directory(candidate))
            candidate = fs::path(ARC_DEFAULT_TEST_SUBDIR);
        test_dir = candidate.string();
    }

    std::string bin = artemis_bin(exe_dir);

    // Compute stdlib include path (repo_root/compiler/std/include)
    std::string std_include;
    {
        fs::path repo_root = fs::path(exe_dir).parent_path();
        fs::path candidate = repo_root / "compiler" / "std" / "include";
        if (fs::is_directory(candidate))
            std_include = " -I " + candidate.generic_string();
    }

    // Extra -I flags from command line (argv[2..])
    std::string extra_flags;
    for (int i = 2; i < argc; ++i) {
        extra_flags += " ";
        extra_flags += argv[i];
    }

    std::vector<fs::path> files;
    for (const auto& entry : fs::directory_iterator(test_dir)) {
        if (entry.path().extension() == ".arc")
            files.push_back(entry.path());
    }
    std::sort(files.begin(), files.end());

    int passed = 0, failed = 0;

    for (const auto& src : files) {
        std::string name   = src.stem().string();
        std::string srcstr = src.generic_string();

#ifdef _WIN32
        std::string outbin = srcstr + ".exe";
#else
        std::string outbin = srcstr + ".out";
#endif

        // Compile
        std::string compile_cmd = bin + std_include + extra_flags + " " + srcstr + " -o " + outbin;
        int crc = run_cmd(compile_cmd);
        if (crc != 0) {
            printf("FAIL::%d  %s  (compile error)\n", crc, name.c_str());
            ++failed;
            continue;
        }

        // Run — on Windows, cmd.exe needs backslashes for relative exe paths
        int rrc = run_cmd(to_native_path(outbin));
        fs::remove(outbin);

        if (rrc == 0) {
            printf("PASS       %s\n", name.c_str());
            ++passed;
        } else {
            printf("FAIL::%d  %s\n", rrc, name.c_str());
            ++failed;
        }
    }

    printf("\n%d passed, %d failed\n", passed, failed);
    return failed > 0 ? 1 : 0;
}
