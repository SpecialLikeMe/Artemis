cmake_minimum_required(VERSION 3.20)
project(artemis VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ------------------------------------------------------------------ LLVM
find_package(LLVM REQUIRED CONFIG)
message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION} at ${LLVM_DIR}")

include_directories(${LLVM_INCLUDE_DIRS})
separate_arguments(LLVM_DEFS NATIVE_COMMAND ${LLVM_DEFINITIONS})
add_definitions(${LLVM_DEFS})

llvm_map_components_to_libnames(LLVM_LIBS
    core support analysis target nativecodegen passes
    irreader bitwriter x86codegen x86asmparser x86desc x86info)

# ------------------------------------------------------------------ warnings
set(WARN_FLAGS -Wall -Wextra -Wpedantic)

# ------------------------------------------------------------------ main executable: artemis
add_executable(artemis src/main.cpp)
target_include_directories(artemis PRIVATE ${CMAKE_SOURCE_DIR}/compiler)
target_link_libraries(artemis PRIVATE ${LLVM_LIBS})
target_compile_options(artemis PRIVATE ${WARN_FLAGS})

# ------------------------------------------------------------------ install: artemis + atc/atx aliases
install(TARGETS artemis DESTINATION bin)

if(WIN32)
    # On Windows create wrapper batch files alongside the binary.
    install(CODE "
        set(BIN_DIR \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/bin\")
        file(WRITE \"\${BIN_DIR}/atc.cmd\" \"@echo off\\r\\nartemis %*\\r\\n\")
        file(WRITE \"\${BIN_DIR}/atx.cmd\" \"@echo off\\r\\nartemis %*\\r\\n\")
        file(WRITE \"\${BIN_DIR}/arc.cmd\" \"@echo off\\r\\nartemis %*\\r\\n\")
    ")
else()
    # On POSIX create symlinks.
    install(CODE "
        set(BIN_DIR \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/bin\")
        foreach(alias atc atx arc)
            if(EXISTS \"\${BIN_DIR}/\${alias}\")
                file(REMOVE \"\${BIN_DIR}/\${alias}\")
            endif()
            execute_process(COMMAND \${CMAKE_COMMAND} -E create_symlink artemis \${alias}
                            WORKING_DIRECTORY \"\${BIN_DIR}\")
        endforeach()
    ")
endif()

# ------------------------------------------------------------------ test executable
enable_testing()

add_executable(artemis_tests test/runner.cpp)
target_include_directories(artemis_tests PRIVATE
    ${CMAKE_SOURCE_DIR}/compiler
    ${CMAKE_SOURCE_DIR}/test)
target_link_libraries(artemis_tests PRIVATE ${LLVM_LIBS})
target_compile_options(artemis_tests PRIVATE ${WARN_FLAGS})

add_test(NAME unit_and_integration
         COMMAND artemis_tests
         WORKING_DIRECTORY ${CMAKE_BINARY_DIR})

# Pass the built artemis binary path to tests via environment.
set_tests_properties(unit_and_integration PROPERTIES
    ENVIRONMENT "ARTEMIS_BIN=$<TARGET_FILE:artemis>")

# ------------------------------------------------------------------ AddressSanitizer (opt-in)
option(ENABLE_ASAN "Build with AddressSanitizer + UBSan" OFF)
if(ENABLE_ASAN)
    foreach(tgt artemis artemis_tests)
        target_compile_options(${tgt} PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer)
        target_link_options(${tgt}    PRIVATE -fsanitize=address,undefined)
    endforeach()
endif()

# ------------------------------------------------------------------ Debug / Release defaults
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

# ------------------------------------------------------------------ cross-compilation targets
# Each target builds the full artemis toolchain for a different host platform.
# Prerequisites:
#   Linux   : x86_64-linux-gnu-g++ (apt: gcc-x86-64-linux-gnu g++-x86-64-linux-gnu)
#   Windows : x86_64-w64-mingw32-g++ (apt: gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64)
#   macOS   : osxcross (https://github.com/tpoechtrager/osxcross) or a macOS SDK
# LLVM_DIR must point to LLVM built for/installed on the cross-compilation host.

include(ExternalProject)

set(_CROSS_BASE    "${CMAKE_BINARY_DIR}/cross")
set(_CROSS_SRC     "${CMAKE_SOURCE_DIR}")
set(_COMMON_ARGS
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DLLVM_DIR=${LLVM_DIR}
    -DENABLE_ASAN=OFF
)

ExternalProject_Add(artemis-linux
    SOURCE_DIR   "${_CROSS_SRC}"
    BINARY_DIR   "${_CROSS_BASE}/linux"
    CMAKE_ARGS
        ${_COMMON_ARGS}
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_SOURCE_DIR}/cmake/toolchains/linux-x86_64.cmake
    INSTALL_COMMAND ""
    EXCLUDE_FROM_ALL YES
    STEP_TARGETS    build
)

ExternalProject_Add(artemis-windows
    SOURCE_DIR   "${_CROSS_SRC}"
    BINARY_DIR   "${_CROSS_BASE}/windows"
    CMAKE_ARGS
        ${_COMMON_ARGS}
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_SOURCE_DIR}/cmake/toolchains/windows-x86_64.cmake
    INSTALL_COMMAND ""
    EXCLUDE_FROM_ALL YES
    STEP_TARGETS    build
)

ExternalProject_Add(artemis-macos
    SOURCE_DIR   "${_CROSS_SRC}"
    BINARY_DIR   "${_CROSS_BASE}/macos"
    CMAKE_ARGS
        ${_COMMON_ARGS}
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_SOURCE_DIR}/cmake/toolchains/macos-x86_64.cmake
    INSTALL_COMMAND ""
    EXCLUDE_FROM_ALL YES
    STEP_TARGETS    build
)

add_custom_target(cross-all
    COMMENT "Building artemis for Linux, Windows, and macOS"
    DEPENDS artemis-linux artemis-windows artemis-macos
)

# ------------------------------------------------------------------ CPack / installers
set(CPACK_PACKAGE_NAME             "artemis")
set(CPACK_PACKAGE_VERSION          "${PROJECT_VERSION}")
set(CPACK_PACKAGE_VENDOR           "Artemis Project")
set(CPACK_PACKAGE_CONTACT          "noreply@artemis-lang.org")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Artemis compiled language toolchain")
set(CPACK_PACKAGE_DESCRIPTION
    "Artemis is a compiled, statically-typed, C-like language that targets LLVM IR.\n"
    "The package includes the 'artemis' compiler driver plus the 'atc' and 'atx' aliases.")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "Artemis")
set(CPACK_STRIP_FILES               ON)

# Resource files (create a stub LICENSE if not present; real projects should have one).
if(EXISTS "${CMAKE_SOURCE_DIR}/LICENSE")
    set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE")
endif()
if(EXISTS "${CMAKE_SOURCE_DIR}/README.md")
    set(CPACK_RESOURCE_FILE_README "${CMAKE_SOURCE_DIR}/README.md")
endif()

# ---- Windows: NSIS installer ----
set(CPACK_NSIS_DISPLAY_NAME      "Artemis ${PROJECT_VERSION}")
set(CPACK_NSIS_PACKAGE_NAME      "Artemis")
set(CPACK_NSIS_INSTALL_ROOT      "$PROGRAMFILES64")
set(CPACK_NSIS_MODIFY_PATH        ON)
set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
set(CPACK_NSIS_MUI_ICON          "${CMAKE_SOURCE_DIR}/cmake/artemis.ico")
set(CPACK_NSIS_MUI_UNIICON       "${CMAKE_SOURCE_DIR}/cmake/artemis.ico")
# Add PATH entry so 'artemis', 'atc', 'atx' are available system-wide.
set(CPACK_NSIS_EXTRA_INSTALL_COMMANDS
    "WriteRegStr HKLM 'SYSTEM\\\\CurrentControlSet\\\\Control\\\\Session Manager\\\\Environment' 'ARTEMIS_HOME' '$INSTDIR'")

# ---- Linux: DEB + RPM ----
set(CPACK_DEBIAN_PACKAGE_MAINTAINER  "Artemis Project <noreply@artemis-lang.org>")
set(CPACK_DEBIAN_PACKAGE_SECTION     "devel")
set(CPACK_DEBIAN_PACKAGE_PRIORITY    "optional")
set(CPACK_DEBIAN_PACKAGE_DEPENDS     "libc6 (>= 2.17), libstdc++6 (>= 6)")
set(CPACK_DEBIAN_PACKAGE_HOMEPAGE    "https://github.com/your-org/artemis")
set(CPACK_RPM_PACKAGE_LICENSE        "MIT")
set(CPACK_RPM_PACKAGE_GROUP          "Development/Tools")
set(CPACK_RPM_PACKAGE_REQUIRES       "glibc >= 2.17, libstdc++ >= 6")
set(CPACK_RPM_PACKAGE_URL            "https://github.com/your-org/artemis")

# ---- macOS: drag-and-drop DMG ----
set(CPACK_DMG_VOLUME_NAME    "Artemis ${PROJECT_VERSION}")
set(CPACK_DMG_FORMAT         "UDZO")           # compressed
set(CPACK_BUNDLE_NAME        "Artemis")

# ---- Generator auto-select ----
if(NOT DEFINED CPACK_GENERATOR)
    if(WIN32)
        set(CPACK_GENERATOR "NSIS;ZIP")
    elseif(APPLE)
        set(CPACK_GENERATOR "DragNDrop;TGZ")
    else()
        set(CPACK_GENERATOR "DEB;RPM;TGZ")
    endif()
endif()

include(CPack)
