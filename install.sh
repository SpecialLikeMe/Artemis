#!/usr/bin/env bash
# Artemis installer — Linux and macOS
# Usage:
#   ./install.sh              Install to /usr/local/bin (may require sudo)
#   ./install.sh --user       Install to ~/.local/bin (no sudo required)
#   ./install.sh --prefix /p  Install to /p/bin
#   ./install.sh --uninstall  Remove a previously installed Artemis

set -euo pipefail

# ------------------------------------------------------------------ colours
if [ -t 1 ]; then
    RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
    CYAN='\033[1;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; RESET=''
fi
info()    { printf "${CYAN}==> ${RESET}${BOLD}%s${RESET}\n" "$*"; }
success() { printf "${GREEN}✔  ${RESET}%s\n" "$*"; }
warn()    { printf "${YELLOW}!  ${RESET}%s\n" "$*"; }
die()     { printf "${RED}✘  ${RESET}%s\n" "$*" >&2; exit 1; }

# ------------------------------------------------------------------ args
PREFIX=/usr/local
USER_INSTALL=false
UNINSTALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --user)            USER_INSTALL=true ;;
        --prefix)          PREFIX="$2"; shift ;;
        --prefix=*)        PREFIX="${1#*=}" ;;
        --uninstall)       UNINSTALL=true ;;
        -h|--help)
            echo "Usage: $0 [--user] [--prefix <dir>] [--uninstall]"
            exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

if $USER_INSTALL; then
    PREFIX="${HOME}/.local"
fi

BINDIR="${PREFIX}/bin"

# ------------------------------------------------------------------ uninstall
if $UNINSTALL; then
    info "Uninstalling Artemis from ${BINDIR}"
    for name in artemis atc atx; do
        if [ -e "${BINDIR}/${name}" ] || [ -L "${BINDIR}/${name}" ]; then
            rm -f "${BINDIR}/${name}"
            success "Removed ${BINDIR}/${name}"
        fi
    done
    exit 0
fi

# ------------------------------------------------------------------ OS detect
OS="$(uname -s)"
case "$OS" in
    Linux)  PLATFORM=linux ;;
    Darwin) PLATFORM=macos ;;
    *)      die "Unsupported OS: $OS" ;;
esac
info "Detected platform: ${PLATFORM}"

# ------------------------------------------------------------------ find binary
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

find_binary() {
    # 1. Pre-built binary alongside this script
    if [ -x "${SCRIPT_DIR}/artemis" ]; then
        echo "${SCRIPT_DIR}/artemis"; return
    fi
    # 2. CMake build directory
    for d in "${SCRIPT_DIR}/build" "${SCRIPT_DIR}/build/Release" "${SCRIPT_DIR}/build/Debug"; do
        if [ -x "${d}/artemis" ]; then
            echo "${d}/artemis"; return
        fi
    done
    # 3. Cross-compile output for this platform
    if [ -x "${SCRIPT_DIR}/build/cross/${PLATFORM}/artemis" ]; then
        echo "${SCRIPT_DIR}/build/cross/${PLATFORM}/artemis"; return
    fi
    echo ""
}

BINARY="$(find_binary)"

# ------------------------------------------------------------------ build if needed
if [ -z "$BINARY" ]; then
    warn "Pre-built artemis binary not found — attempting to build from source."

    command -v cmake  >/dev/null 2>&1 || die "cmake not found. Install cmake 3.20+."
    command -v llvm-config >/dev/null 2>&1 || \
    command -v llvm-config-17 >/dev/null 2>&1 || \
    command -v llvm-config-18 >/dev/null 2>&1 || \
        die "LLVM not found. Install LLVM 17+ and ensure llvm-config is on PATH."

    LLVM_CMAKE_DIR="$(llvm-config --cmakedir 2>/dev/null || \
                      llvm-config-18 --cmakedir 2>/dev/null || \
                      llvm-config-17 --cmakedir)"

    info "Configuring build..."
    cmake -S "${SCRIPT_DIR}" -B "${SCRIPT_DIR}/_install_build" \
        -DCMAKE_BUILD_TYPE=Release \
        "-DLLVM_DIR=${LLVM_CMAKE_DIR}" \
        -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
        >/dev/null

    info "Building (this may take a minute)..."
    cmake --build "${SCRIPT_DIR}/_install_build" --target artemis --parallel \
        >/dev/null

    BINARY="${SCRIPT_DIR}/_install_build/artemis"
    [ -x "$BINARY" ] || die "Build failed — binary not produced."
fi

success "Using binary: ${BINARY}"

# ------------------------------------------------------------------ install
mkdir -p "${BINDIR}"

# Check write permission; re-invoke with sudo if needed and not user-install.
if [ ! -w "${BINDIR}" ] && ! $USER_INSTALL; then
    warn "${BINDIR} is not writable — retrying with sudo."
    exec sudo bash "$0" --prefix "${PREFIX}" "$@"
fi

info "Installing to ${BINDIR}"
cp -f "${BINARY}" "${BINDIR}/artemis"
chmod 755 "${BINDIR}/artemis"
success "Installed artemis"

# Create atc / atx symlinks.
for alias in atc atx; do
    ln -sf artemis "${BINDIR}/${alias}"
    success "Linked ${alias} → artemis"
done

# ------------------------------------------------------------------ PATH check
case ":${PATH}:" in
    *":${BINDIR}:"*) ;;
    *)
        warn "${BINDIR} is not on your PATH."
        echo ""
        echo "  Add this line to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
        echo ""
        printf "    ${BOLD}export PATH=\"%s:\$PATH\"${RESET}\n" "${BINDIR}"
        echo ""
        echo "  Then reload it:  source ~/.bashrc"
        ;;
esac

# ------------------------------------------------------------------ verify
if command -v artemis >/dev/null 2>&1; then
    success "artemis $(artemis --version 2>&1 | head -1) is ready."
else
    info "Installation complete. Open a new terminal or update PATH to use artemis."
fi
