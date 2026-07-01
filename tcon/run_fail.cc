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
    namespace fs = std::filesystem;
    if (!exe_dir.empty()) {
        fs::path candidate = fs::path(exe_dir).parent_path() / "build" / "artemis.exe";
        if (fs::exists(candidate)) return candidate.string();
        candidate = fs::path(exe_dir) / ".." / "build" / "artemis.exe";
        if (fs::exists(candidate)) return candidate.string();
    }
    return "artemis";
}

static int run_cmd_silent(const std::string& cmd) {
    std::string full = cmd + " 2>&1";
    FILE* p = popen(full.c_str(), "r");
    if (!p) return 1;
    char buf[256];
    while (fgets(buf, sizeof(buf), p)) {}
    int rc = pclose(p);
#ifndef _WIN32
    if (WIFEXITED(rc)) rc = WEXITSTATUS(rc);
    else               rc = 1;
#endif
    return rc;
}

int main(int argc, char** argv) {
    namespace fs = std::filesystem;

    std::string exe_dir;
    {
        fs::path ep = fs::path(argv[0]).parent_path();
        if (!ep.empty()) exe_dir = ep.string();
    }

    std::string test_dir;
    if (argc >= 2) {
        test_dir = argv[1];
    } else {
        fs::path candidate = exe_dir.empty() ? fs::path("fail") : (fs::path(exe_dir) / "fail");
        test_dir = fs::is_directory(candidate) ? candidate.string() : "fail";
    }

    std::string bin = artemis_bin(exe_dir);

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

        // Compile — we expect a NON-ZERO exit code (compiler must reject the code)
        std::string compile_cmd = bin + " " + srcstr + " -o " + srcstr + ".fail.exe";
        int crc = run_cmd_silent(compile_cmd);

        if (crc != 0) {
            printf("PASS       %s\n", name.c_str());
            ++passed;
        } else {
            // Compiler accepted invalid code — clean up and report failure
            fs::remove(srcstr + ".fail.exe");
            printf("FAIL       %s  (should not compile)\n", name.c_str());
            ++failed;
        }
    }

    printf("\n%d passed, %d failed\n", passed, failed);
    return failed > 0 ? 1 : 0;
}
