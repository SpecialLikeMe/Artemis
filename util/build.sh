#!/usr/bin/env bash
# Build all Artemis executables from source.
# Cleans build/, then produces:
#   artemis_bootstrap  — C++ bootstrap compiler
#   artemis_tests      — C++ unit/integration test runner
#   artemis            — self-hosted compiler
#   aciso              — package manager / build system (Arc source)
#   run_tcon           — tcon test runner
#   run_std            — stdlib test runner
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# ------------------------------------------------------------------ platform
OS="$(uname -s)"
case "$OS" in
  MINGW*|MSYS*|CYGWIN*)
    GPP="C:/msys64/mingw64/bin/g++.exe"
    GCC="C:/msys64/mingw64/bin/gcc.exe"
    LLC="C:/msys64/mingw64/bin/llc.exe"
    LLVM_DIR="${LLVM_DIR:-C:/msys64/mingw64/lib/cmake/llvm}"
    LLVM_LIB_DIR="${LLVM_LIB_DIR:-C:/msys64/mingw64/lib}"
    LLVM_LIB="LLVM-22"
    EXE=".exe"
    STACK_FLAG="-Wl,--stack,67108864"
    CMAKE_GEN="MinGW Makefiles"
    JOBS="$(nproc 2>/dev/null || echo 4)"
    ;;
  Linux*)
    GPP="${GPP:-g++}"
    GCC="${GCC:-gcc}"
    LLC="${LLC:-llc}"
    LLVM_DIR="${LLVM_DIR:-/usr/lib/llvm-22/lib/cmake/llvm}"
    LLVM_LIB_DIR="${LLVM_LIB_DIR:-/usr/lib/llvm-22/lib}"
    LLVM_LIB="${LLVM_LIB:-LLVM-22}"
    EXE=""
    STACK_FLAG=""
    CMAKE_GEN="Unix Makefiles"
    JOBS="$(nproc 2>/dev/null || echo 4)"
    ;;
  Darwin*)
    GPP="${GPP:-g++}"
    GCC="${GCC:-gcc}"
    LLC="${LLC:-llc}"
    _LLVM_PREFIX="$(brew --prefix llvm 2>/dev/null || echo /usr/local/opt/llvm)"
    LLVM_DIR="${LLVM_DIR:-$_LLVM_PREFIX/lib/cmake/llvm}"
    LLVM_LIB_DIR="${LLVM_LIB_DIR:-$_LLVM_PREFIX/lib}"
    LLVM_LIB="${LLVM_LIB:-LLVM}"
    EXE=""
    STACK_FLAG=""
    CMAKE_GEN="Unix Makefiles"
    JOBS="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
    ;;
  *)
    echo "Unsupported platform: $OS" >&2
    exit 1
    ;;
esac

echo "==> Platform: $OS | jobs: $JOBS"

# ------------------------------------------------------------------ 1. Clean
echo "==> Cleaning build/"
rm -rf build
mkdir build

# ------------------------------------------------------------------ 2. CMake configure
echo "==> Configuring CMake ($CMAKE_GEN)"
cmake -B build -G "$CMAKE_GEN" \
  -DCMAKE_C_COMPILER="$GCC" \
  -DCMAKE_CXX_COMPILER="$GPP" \
  -DLLVM_DIR="$LLVM_DIR" \
  -DCMAKE_BUILD_TYPE=Release

# ------------------------------------------------------------------ 3. Bootstrap + tests via CMake
echo "==> Building artemis_bootstrap + artemis_tests"
cmake --build build --target artemis_bootstrap artemis_tests -j"$JOBS"

# ------------------------------------------------------------------ 4. llvm_init.c shim
echo "==> Compiling llvm_init.c"
"$GCC" -c boot/llvm_init.c -o build/llvm_init.o

# ------------------------------------------------------------------ 5. Self-host: artemis
echo "==> Self-hosting: artemis_bootstrap -> artemis_boot.ll"
"./build/artemis_bootstrap${EXE}" compiler/main.arc --unsafe -S \
  -I compiler/std/include -o build/artemis_boot.ll

echo "==> Assembling artemis_boot.ll -> artemis_boot.o"
"$LLC" -O2 -filetype=obj -o build/artemis_boot.o build/artemis_boot.ll

echo "==> Linking artemis${EXE}"
"$GPP" build/artemis_boot.o build/llvm_init.o \
  -o "build/artemis${EXE}" \
  -L"$LLVM_LIB_DIR" -l"$LLVM_LIB" -lstdc++ -lm ${STACK_FLAG:+$STACK_FLAG}

# ------------------------------------------------------------------ 6. aciso (Arc source)
echo "==> Compiling aciso/main.arc -> aciso_boot.ll"
"./build/artemis${EXE}" aciso/main.arc --unsafe -S \
  -I compiler/std/include -o build/aciso_boot.ll

echo "==> Assembling aciso_boot.ll -> aciso.o"
"$LLC" -O2 -filetype=obj -o build/aciso.o build/aciso_boot.ll

echo "==> Linking aciso${EXE}"
"$GPP" build/aciso.o -o "build/aciso${EXE}" \
  -lstdc++ -lm ${STACK_FLAG:+$STACK_FLAG}

# ------------------------------------------------------------------ 7. tcon test runners
echo "==> Building run_tcon${EXE}"
"$GPP" -std=c++20 -O2 tcon/run.cc -o "build/run_tcon${EXE}"

echo "==> Building run_std${EXE}"
"$GPP" -std=c++20 -O2 tcon/run_std.cc -o "build/run_std${EXE}"

# ------------------------------------------------------------------ done
echo ""
echo "==> Build complete!"
echo "    build/artemis${EXE}"
echo "    build/artemis_bootstrap${EXE}"
echo "    build/artemis_tests${EXE}"
echo "    build/aciso${EXE}"
echo "    build/run_tcon${EXE}"
echo "    build/run_std${EXE}"
