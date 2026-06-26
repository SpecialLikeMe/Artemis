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
    for name in artemis aciso atc atx arc; do
        target="${BINDIR}/${name}"
        if [ -e "${target}" ] || [ -L "${target}" ]; then
            rm -f "${target}"
            success "Removed ${target}"
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

# ------------------------------------------------------------------ find binaries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Usage: find_tool <name>
# Searches pre-built locations in preference order; prints path or empty string.
find_tool() {
    local name="$1"
    local candidates=(
        "${SCRIPT_DIR}/${name}"
        "${SCRIPT_DIR}/build/${name}"
        "${SCRIPT_DIR}/build/Release/${name}"
        "${SCRIPT_DIR}/build/Debug/${name}"
        "${SCRIPT_DIR}/build/cross/${PLATFORM}/${name}"
    )
    for c in "${candidates[@]}"; do
        if [ -x "${c}" ]; then echo "${c}"; return; fi
    done
    echo ""
}

ARTEMIS_BIN="$(find_tool artemis)"
ACISO_BIN="$(find_tool aciso)"

# ------------------------------------------------------------------ build if needed
if [ -z "${ARTEMIS_BIN}" ] || [ -z "${ACISO_BIN}" ]; then
    warn "One or more pre-built binaries not found — building from source."

    command -v cmake >/dev/null 2>&1 || die "cmake not found. Install cmake 3.20+."
    command -v llvm-config >/dev/null 2>&1 || \
    command -v llvm-config-18 >/dev/null 2>&1 || \
    command -v llvm-config-17 >/dev/null 2>&1 || \
        die "LLVM not found. Install LLVM 17+ and ensure llvm-config is on PATH."

    LLVM_CMAKE_DIR="$(llvm-config --cmakedir 2>/dev/null || \
                      llvm-config-18 --cmakedir 2>/dev/null || \
                      llvm-config-17 --cmakedir)"

    BUILD_DIR="${SCRIPT_DIR}/_install_build"

    info "Configuring build..."
    cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}" \
        -DCMAKE_BUILD_TYPE=Release \
        "-DLLVM_DIR=${LLVM_CMAKE_DIR}" \
        "-DCMAKE_INSTALL_PREFIX=${PREFIX}" \
        >/dev/null

    info "Building (this may take a minute)..."
    cmake --build "${BUILD_DIR}" \
        --target artemis --target aciso \
        --parallel \
        >/dev/null

    ARTEMIS_BIN="${BUILD_DIR}/artemis"
    ACISO_BIN="${BUILD_DIR}/aciso"

    [ -x "${ARTEMIS_BIN}" ] || die "Build failed — artemis binary not produced."
    [ -x "${ACISO_BIN}"   ] || die "Build failed — aciso binary not produced."
fi

success "Using artemis: ${ARTEMIS_BIN}"
success "Using aciso:   ${ACISO_BIN}"

# ------------------------------------------------------------------ install
mkdir -p "${BINDIR}"

# Check write permission; re-invoke with sudo if needed and not user-install.
if [ ! -w "${BINDIR}" ] && ! $USER_INSTALL; then
    warn "${BINDIR} is not writable — retrying with sudo."
    exec sudo bash "$0" --prefix "${PREFIX}"
fi

info "Installing to ${BINDIR}"

cp -f "${ARTEMIS_BIN}" "${BINDIR}/artemis"
chmod 755 "${BINDIR}/artemis"
success "Installed artemis"

cp -f "${ACISO_BIN}" "${BINDIR}/aciso"
chmod 755 "${BINDIR}/aciso"
success "Installed aciso"

# Create artemis aliases (atc, atx, arc).
for alias in atc atx arc; do
    ln -sf artemis "${BINDIR}/${alias}"
    success "Linked ${alias} → artemis"
done

# ------------------------------------------------------------------ ARTEMIS_HOME hint
# aciso uses ARTEMIS_HOME to locate the artemis compiler when it is not on PATH.
# Point it at PREFIX so aciso can find PREFIX/bin/artemis.
export ARTEMIS_HOME="${PREFIX}"
PROFILE_LINE="export ARTEMIS_HOME=\"${PREFIX}\""

# ------------------------------------------------------------------ PATH check
MISSING_PATH=false
case ":${PATH}:" in
    *":${BINDIR}:"*) ;;
    *) MISSING_PATH=true ;;
esac

if $MISSING_PATH; then
    warn "${BINDIR} is not on your PATH."
    echo ""
    echo "  Add these lines to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
    echo ""
    printf "    ${BOLD}export PATH=\"%s:\$PATH\"${RESET}\n" "${BINDIR}"
    printf "    ${BOLD}%s${RESET}\n" "${PROFILE_LINE}"
    echo ""
    echo "  Then reload it:  source ~/.bashrc"
    echo ""
else
    warn "ARTEMIS_HOME is not set permanently."
    echo ""
    echo "  Add this line to your shell profile for aciso to locate the compiler:"
    echo ""
    printf "    ${BOLD}%s${RESET}\n" "${PROFILE_LINE}"
    echo ""
fi

# ------------------------------------------------------------------ verify
OK=true
if command -v artemis >/dev/null 2>&1; then
    success "artemis $(artemis --version 2>&1 | head -1) is ready."
else
    info "artemis installed — open a new terminal or reload PATH to use it."
    OK=false
fi

if command -v aciso >/dev/null 2>&1; then
    success "aciso is ready."
else
    info "aciso installed — open a new terminal or reload PATH to use it."
    OK=false
fi

if $OK; then
    success "Artemis toolchain installation complete."
fi
