#pragma once
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include <functional>
#include <stdexcept>
#include <sstream>

// ------------------------------------------------------------------ registry

struct test_case {
    const char*           suite;
    const char*           name;
    std::function<void()> fn;
};

inline std::vector<test_case>& test_registry() {
    static std::vector<test_case> reg;
    return reg;
}

struct test_registrar {
    test_registrar(const char* suite, const char* name, std::function<void()> fn) {
        test_registry().push_back({suite, name, std::move(fn)});
    }
};

// ------------------------------------------------------------------ assertions

struct assertion_error : std::runtime_error {
    assertion_error(const char* file, int line, std::string msg)
        : std::runtime_error(std::string(file) + ":" + std::to_string(line) + ": " + msg) {}
};

#define ASSERT_TRUE(cond) \
    do { if (!(cond)) throw assertion_error(__FILE__, __LINE__, \
        "ASSERT_TRUE failed: " #cond); } while(0)

#define ASSERT_FALSE(cond) \
    do { if (cond) throw assertion_error(__FILE__, __LINE__, \
        "ASSERT_FALSE failed: " #cond); } while(0)

#define ASSERT_EQ(a, b) \
    do { \
        auto _a = (a); auto _b = (b); \
        if (!(_a == _b)) { \
            std::ostringstream _ss; \
            _ss << "ASSERT_EQ failed: " #a " == " #b " (" << _a << " != " << _b << ")"; \
            throw assertion_error(__FILE__, __LINE__, _ss.str()); \
        } \
    } while(0)

#define ASSERT_NE(a, b) \
    do { \
        auto _a = (a); auto _b = (b); \
        if (_a == _b) { \
            std::ostringstream _ss; \
            _ss << "ASSERT_NE failed: " #a " != " #b " (both == " << _a << ")"; \
            throw assertion_error(__FILE__, __LINE__, _ss.str()); \
        } \
    } while(0)

#define ASSERT_CONTAINS(haystack, needle) \
    do { \
        std::string _h = (haystack); std::string _n = (needle); \
        if (_h.find(_n) == std::string::npos) \
            throw assertion_error(__FILE__, __LINE__, \
                "ASSERT_CONTAINS: \"" + _n + "\" not in \"" + _h + "\""); \
    } while(0)

#define ASSERT_THROWS(expr, exc_type) \
    do { \
        bool _threw = false; \
        try { expr; } catch (const exc_type&) { _threw = true; } \
        if (!_threw) throw assertion_error(__FILE__, __LINE__, \
            "ASSERT_THROWS: expected " #exc_type " from: " #expr); \
    } while(0)

// ------------------------------------------------------------------ TEST macro

#define TEST(suite, name) \
    static void _test_##suite##_##name(); \
    static test_registrar _reg_##suite##_##name(#suite, #name, _test_##suite##_##name); \
    static void _test_##suite##_##name()

// ------------------------------------------------------------------ runner

inline int run_all_tests() {
    auto& tests = test_registry();
    int passed = 0, failed = 0;

    for (auto& t : tests) {
        printf("[ RUN  ] %s.%s\n", t.suite, t.name); fflush(stdout);
        try {
            t.fn();
            printf("[ PASS ] %s.%s\n", t.suite, t.name); fflush(stdout);
            ++passed;
        } catch (const assertion_error& e) {
            printf("[ FAIL ] %s.%s\n  %s\n", t.suite, t.name, e.what());
            ++failed;
        } catch (const std::exception& e) {
            printf("[ FAIL ] %s.%s\n  exception: %s\n", t.suite, t.name, e.what());
            ++failed;
        } catch (...) {
            printf("[ FAIL ] %s.%s\n  unknown exception\n", t.suite, t.name);
            ++failed;
        }
    }

    printf("\n%d passed, %d failed, %d total\n", passed, failed, passed + failed);
    return failed == 0 ? 0 : 1;
}
