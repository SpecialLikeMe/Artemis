# Toolchain: macOS x86_64
# Two supported setups:
#   1. Building natively on macOS — no special configuration needed beyond
#      setting the deployment target.
#   2. Cross-compiling from Linux using osxcross:
#        https://github.com/tpoechtrager/osxcross
#      Set OSXCROSS_ROOT to your osxcross installation prefix, e.g.:
#        cmake -DOSXCROSS_ROOT=/opt/osxcross ...

set(CMAKE_SYSTEM_NAME  Darwin)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

if(DEFINED ENV{OSXCROSS_ROOT} OR DEFINED OSXCROSS_ROOT)
    # ---- osxcross cross-compilation ----
    if(DEFINED ENV{OSXCROSS_ROOT})
        set(_OSXCROSS "$ENV{OSXCROSS_ROOT}")
    else()
        set(_OSXCROSS "${OSXCROSS_ROOT}")
    endif()

    set(_SDK_TARGET "x86_64-apple-darwin")
    set(CMAKE_C_COMPILER   "${_OSXCROSS}/bin/${_SDK_TARGET}-clang")
    set(CMAKE_CXX_COMPILER "${_OSXCROSS}/bin/${_SDK_TARGET}-clang++")
    set(CMAKE_AR           "${_OSXCROSS}/bin/${_SDK_TARGET}-ar")
    set(CMAKE_RANLIB       "${_OSXCROSS}/bin/${_SDK_TARGET}-ranlib")

    set(CMAKE_FIND_ROOT_PATH "${_OSXCROSS}/${_SDK_TARGET}")
    set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
    set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

else()
    # ---- Native macOS build ----
    # Use whatever Clang is on PATH (Xcode CLT or Homebrew).
    find_program(_CLANG   clang   HINTS /usr/bin /usr/local/bin /opt/homebrew/bin)
    find_program(_CLANGXX clang++ HINTS /usr/bin /usr/local/bin /opt/homebrew/bin)
    if(NOT _CLANG)
        message(FATAL_ERROR "clang not found. Install Xcode Command Line Tools: xcode-select --install")
    endif()
    set(CMAKE_C_COMPILER   "${_CLANG}")
    set(CMAKE_CXX_COMPILER "${_CLANGXX}")
endif()

# Minimum deployment target — keep in sync with CI and README.
set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15" CACHE STRING "macOS deployment target")
set(CMAKE_OSX_ARCHITECTURES    "x86_64" CACHE STRING "Build architectures")
