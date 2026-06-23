# Toolchain: Linux x86_64 (GNU cross-compiler)
# Install: apt install gcc-x86-64-linux-gnu g++-x86-64-linux-gnu
#          or just use the native compiler when building on Linux.

set(CMAKE_SYSTEM_NAME  Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Prefer the explicit GNU cross-compiler; fall back to the native toolchain
# when the build machine is already Linux x86_64.
find_program(_GCC  x86_64-linux-gnu-gcc  HINTS /usr/bin /usr/local/bin)
find_program(_GXX  x86_64-linux-gnu-g++  HINTS /usr/bin /usr/local/bin)

if(_GCC)
    set(CMAKE_C_COMPILER   "${_GCC}")
else()
    set(CMAKE_C_COMPILER   gcc)
endif()

if(_GXX)
    set(CMAKE_CXX_COMPILER "${_GXX}")
else()
    set(CMAKE_CXX_COMPILER g++)
endif()

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Static runtime so the binary runs without matching libstdc++ on the target.
set(CMAKE_EXE_LINKER_FLAGS_INIT "-static-libgcc -static-libstdc++")
