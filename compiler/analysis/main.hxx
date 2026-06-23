#pragma once
#include "scope.hxx"
#include "types.hxx"
#include "analyzer.hxx"

// Run full semantic analysis on a parsed program.
// Throws std::runtime_error on the first semantic error encountered.
inline void analyze(program_node* prog) {
    analyzer a;
    a.analyze(prog);
}
