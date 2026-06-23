// Artemis test runner — includes all test suites and executes them.
#include "framework.hxx"

// Unit tests
#include "test_lexer.hxx"
#include "test_parser.hxx"
#include "test_analyzer.hxx"
#include "test_ir.hxx"

// Integration / end-to-end tests
#include "integration.hxx"

int main() {
    return run_all_tests();
}
