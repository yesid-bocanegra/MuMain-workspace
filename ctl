#!/usr/bin/env bash
# mumain-ctl: Project control script
#
# The project MUST build natively on macOS (arm64), Linux (x64), and Windows (x64).
# All platforms are first-class build targets. No platform is optional.
#
# Usage: ./ctl <command>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}▶${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Platform detection — selects the appropriate CMake preset for the current OS.
# The project MUST compile on all three platforms. If the build fails, fix the
# code — do not skip the build step or suppress the error.
detect_platform() {
    case "$(uname -s)" in
        Darwin)
            CONFIGURE_PRESET="macos-arm64"
            BUILD_PRESET="macos-arm64-debug"
            ;;
        Linux)
            CONFIGURE_PRESET="linux-x64"
            BUILD_PRESET="linux-x64-debug"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            CONFIGURE_PRESET="windows-x64"
            BUILD_PRESET="windows-x64-debug"
            ;;
        *)
            log_error "Unsupported platform: $(uname -s)"
            exit 1
            ;;
    esac
    NCPU=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
}

show_help() {
    cat << 'EOF'
mumain-ctl: Project control script

The project MUST build natively on macOS (arm64), Linux (x64), and Windows (x64).
All platforms are first-class targets. Build failures are blockers, not warnings.

USAGE:
    ./ctl <command>

DEVELOPMENT COMMANDS:
    build           Native build using platform-appropriate CMake preset
    rebuild         Clean then build from scratch
    test            Run unit + stability tests via ctest
    lint            Run static analysis (cppcheck)
    tidy            Run clang-tidy portability checks (sizeof bugs, etc.)
    format          Auto-format C++ source files (clang-format)
    format-check    Check C++ formatting without modifying
    clean           Clean all build artifacts
    check           Full quality gate: build + tests + format-check + lint + tidy
                    THIS MUST PASS before any commit. Build failures are not skippable.

COMPONENTS:  mumain

EXAMPLES:
    ./ctl build                 # Native build (auto-detects macOS/Linux/Windows)
    ./ctl rebuild               # Clean then build from scratch
    ./ctl check                 # Full quality gate — run before every commit
    ./ctl format                # Auto-format all C++ source files
    ./ctl test                  # Run test suite

EOF
}

# =============================================================================
# DEVELOPMENT COMMANDS
# =============================================================================

cmd_build() {
    detect_platform
    log_info "Building mumain natively ($CONFIGURE_PRESET)..."
    (cd MuMain && cmake --preset "$CONFIGURE_PRESET" && cmake --build --preset "$BUILD_PRESET" -j"$NCPU")
    log_success "Build complete ($BUILD_PRESET)"
}

cmd_test() {
    detect_platform
    log_info "Running mumain tests ($BUILD_PRESET)..."
    ctest --test-dir "MuMain/out/build/$CONFIGURE_PRESET" -C Debug --output-on-failure
    log_success "Tests complete"
}

cmd_lint() {
    log_info "Linting mumain..."
    make -C MuMain lint
    log_success "Lint complete"
}

cmd_format() {
    log_info "Formatting mumain..."
    make -C MuMain format
    log_success "Format complete"
}

cmd_format_check() {
    log_info "Checking mumain formatting..."
    make -C MuMain format-check
    log_success "Format check passed"
}

cmd_clean() {
    log_info "Cleaning mumain build artifacts..."
    rm -rf MuMain/out MuMain/build MuMain/build-test MuMain/build-mingw 2>/dev/null || {
        # macOS APFS race: rmdir can fail briefly after unlinking contents
        sleep 1
        rm -rf MuMain/out MuMain/build MuMain/build-test MuMain/build-mingw
    }
    log_success "Clean complete"
}

cmd_rebuild() {
    cmd_clean
    cmd_build
}

cmd_tidy() {
    log_info "Running clang-tidy portability gate..."
    make -C MuMain tidy-gate
    log_success "clang-tidy gate passed"
}

cmd_check() {
    detect_platform
    log_info "Running mumain quality gate ($CONFIGURE_PRESET)..."
    log_warn "MANDATORY: Native build MUST succeed. Fix compilation errors — do not skip."

    python3 MuMain/scripts/check-win32-guards.py \
        && (cd MuMain && cmake --preset "$CONFIGURE_PRESET") \
        && (cd MuMain && cmake --build --preset "$BUILD_PRESET" -j"$NCPU") \
        && ctest --test-dir "MuMain/out/build/$CONFIGURE_PRESET" -C Debug --output-on-failure \
        && make -C MuMain format-check \
        && make -C MuMain lint \
        && make -C MuMain tidy-gate

    log_success "Quality gate passed ($BUILD_PRESET)"
}

# =============================================================================
# MAIN
# =============================================================================

case "${1:-help}" in
    build)          cmd_build ;;
    rebuild)        cmd_rebuild ;;
    test)           cmd_test ;;
    lint)           cmd_lint ;;
    tidy)           cmd_tidy ;;
    format)         cmd_format ;;
    format-check)   cmd_format_check ;;
    clean)          cmd_clean ;;
    check)          cmd_check ;;
    help|--help|-h) show_help ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
