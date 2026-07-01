// Auto-generated test harness — do not edit
#include <cstdio>
#include <cstdlib>
#include <cstring>
#ifdef _WIN32
#  define popen  _popen
#  define pclose _pclose
#else
#  include <sys/wait.h>
#endif

struct RunResult { int code; char out[1 << 17]; };

static RunResult shell(const char *cmd) {
    RunResult r = {};
    char full[8192];
    snprintf(full, sizeof full, "(%s) 2>&1", cmd);
    FILE *p = popen(full, "r");
    if (!p) { r.code = -1; return r; }
    size_t n = fread(r.out, 1, sizeof r.out - 1, p);
    r.out[n] = '\0';
    r.code = pclose(p);
#ifndef _WIN32
    if (WIFEXITED(r.code)) r.code = WEXITSTATUS(r.code);
    else                   r.code = 1;
#endif
    return r;
}

int main(void) {
    const char *artemis = getenv("ARTEMIS_BIN");
    if (!artemis) artemis = "atc";

    const char *src = "base.mangled.arc";
    const char *opts[3] = {"-O0", "-O2", "-O3"};
    static int      codes[3];
    static RunResult runs[3];
    int fail = 0;

    for (int i = 0; i < 3; ++i) {
        char bin[512];
#ifdef _WIN32
        snprintf(bin, sizeof bin, "__test_base_%d.exe", i);
#else
        snprintf(bin, sizeof bin, "__test_base_%d.out", i);
#endif
        char cmd[4096];
        snprintf(cmd, sizeof cmd, "%s %s -o %s %s",
                 artemis, src, bin, opts[i]);
        RunResult cr = shell(cmd);
        if (cr.code != 0) {
            fprintf(stderr,
                    "FAIL  compile %s (exit %d):\n--- compiler output ---\n%s\n",
                    opts[i], cr.code, cr.out);
            codes[i] = -1; runs[i].code = -1; runs[i].out[0] = '\0';
            ++fail; continue;
        }
        char runbuf[512];
#ifdef _WIN32
        snprintf(runbuf, sizeof runbuf, ".\\%s", bin);
#else
        snprintf(runbuf, sizeof runbuf, "./%s", bin);
#endif
        runs[i] = shell(runbuf);
        codes[i] = runs[i].code;
        remove(bin);
    }

    /* All three opt levels must agree AND return exit-code 0 (all checks pass) */
    for (int i = 0; i < 3; ++i) {
        if (codes[i] != 0) {
            fprintf(stderr, "BEHAVIORAL FAIL [%s]: exit=%d (variant disagreement)\n",
                    opts[i], codes[i]);
            ++fail;
        }
    }
    for (int i = 1; i < 3; ++i) {
        if (codes[i] != codes[0] || strcmp(runs[i].out, runs[0].out) != 0) {
            fprintf(stderr, "OPTIMIZER DIVERGENCE [%s vs -O0]:\n", opts[i]);
            fprintf(stderr, "  exit: -O0=%d  %s=%d\n", codes[0], opts[i], codes[i]);
            if (strcmp(runs[i].out, runs[0].out) != 0) {
                fprintf(stderr, "  --- -O0 output ---\n%s\n", runs[0].out);
                fprintf(stderr, "  --- %s output ---\n%s\n", opts[i], runs[i].out);
            }
            ++fail;
        }
    }

    if (!fail) { puts("ALL PASSED"); return 0; }
    fprintf(stderr, "%d test(s) FAILED\n", fail);
    return 1;
}
