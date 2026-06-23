# Toolchain: Windows x86_64 (MinGW-w64 cross-compiler)
# Install: apt install gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64
#          or on macOS: brew install mingw-w64

set(CMAKE_SYSTEM_NAME  Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

find_program(_GCC  x86_64-w64-mingw32-gcc  HINTS /usr/bin /usr/local/bin)
find_program(_GXX  x86_64-w64-mingw32-g++  HINTS /usr/bin /usr/local/bin)
find_program(_RC   x86_64-w64-mingw32-windres HINTS /usr/bin /usr/local/bin)

if(NOT _GCC)
    message(FATAL_ERROR
        "x86_64-w64-mingw32-gcc not found.\n"
        "Install with: apt install gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64")
endif()

set(CMAKE_C_COMPILER   "${_GCC}")
set(CMAKE_CXX_COMPILER "${_GXX}")
if(_RC)
    set(CMAKE_RC_COMPILER "${_RC}")
endif()

set(CMAKE_FIND_ROOT_PATH  /usr/x86_64-w64-mingw32)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Statically link the MinGW runtime so the .exe runs without DLLs.
set(CMAKE_EXE_LINKER_FLAGS_INIT
    "-static-libgcc -static-libstdc++ -static-libwinpthread")
