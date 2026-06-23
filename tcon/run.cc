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

static std::string artemis_bin() {
#if defined(_MSC_VER)
    char* val = nullptr; size_t len = 0;
    _dupenv_s(&val, &len, "ARTEMIS_BIN");
    std::string r = val ? val : "artemis";
    free(val);
    return r;
#else
    const char* e = std::getenv("ARTEMIS_BIN");
    return e ? e : "artemis";
#endif
}

static int run_cmd(const std::string& cmd) {
    std::string full = "(" + cmd + ") 2>nul 1>nul";
#ifndef _WIN32
    full = "(" + cmd + ") >/dev/null 2>&1";
#endif
    int rc = std::system(full.c_str());
#ifndef _WIN32
    if (WIFEXITED(rc)) rc = WEXITSTATUS(rc);
    else               rc = 1;
#endif
    return rc;
}

int main(int argc, char** argv) {
    namespace fs = std::filesystem;

    std::string test_dir = "tcon/test";
    if (argc >= 2) test_dir = argv[1];

    std::string bin = artemis_bin();

    std::vector<fs::path> files;
    for (const auto& entry : fs::directory_iterator(test_dir)) {
        if (entry.path().extension() == ".arc")
            files.push_back(entry.path());
    }
    std::sort(files.begin(), files.end());

    int passed = 0, failed = 0;

    for (const auto& src : files) {
        std::string name   = src.stem().string();
        std::string srcstr = src.string();

#ifdef _WIN32
        std::string outbin = srcstr + ".exe";
#else
        std::string outbin = srcstr + ".out";
#endif

        // Compile
        std::string compile_cmd = bin + " " + srcstr + " -o " + outbin;
        int crc = run_cmd(compile_cmd);
        if (crc != 0) {
            printf("FAIL::%d  %s  (compile error)\n", crc, name.c_str());
            ++failed;
            continue;
        }

        // Run
        int rrc = run_cmd(outbin);
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
