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

# ------------------------------------------------------------------ aciso build system / package manager
set(ACISO_SRCS
    aciso/main.cxx
    aciso/cmd_init.cxx
    aciso/cmd_pkg.cxx
    aciso/cmd_build.cxx
    aciso/cmd_targets.cxx
    aciso/cmd_symbols.cxx
    aciso/cmd_dev.cxx
    aciso/cmd_export.cxx
)
add_executable(aciso ${ACISO_SRCS})
target_include_directories(aciso PRIVATE ${CMAKE_SOURCE_DIR}/aciso)
target_compile_features(aciso PRIVATE cxx_std_20)
target_compile_options(aciso PRIVATE ${WARN_FLAGS})
if(WIN32)
    target_compile_definitions(aciso PRIVATE _CRT_SECURE_NO_WARNINGS)
endif()
if(UNIX)
    target_link_libraries(aciso PRIVATE stdc++fs)
endif()

# ------------------------------------------------------------------ install: artemis + aciso + aliases
install(TARGETS artemis aciso DESTINATION bin)

if(WIN32)
    # Create CMD wrapper scripts so aliases work in every shell context.
    # We normalise the install path to avoid mixed-slash issues on Windows,
    # then keep all file() calls inside CMake (no shell expansion of spaces).
    install(CODE "
        # Build a canonical, forward-slash path safe for CMake file() calls.
        set(_destdir \"\$ENV{DESTDIR}\")
        set(_prefix  \"\${CMAKE_INSTALL_PREFIX}\")
        if(_destdir)
            file(TO_CMAKE_PATH \"\${_destdir}\" _destdir)
        endif()
        file(TO_CMAKE_PATH \"\${_prefix}\" _prefix)
        set(BIN_DIR \"\${_destdir}\${_prefix}/bin\")
        cmake_path(NORMAL_PATH BIN_DIR OUTPUT_VARIABLE BIN_DIR)

        # artemis aliases
        foreach(_alias atc atx arc)
            file(WRITE \"\${BIN_DIR}/\${_alias}.cmd\"
                \"@echo off\\r\\n\\\"artemis\\\" %*\\r\\n\")
        endforeach()

        # aciso alias kept explicit so it survives any future renames
        file(WRITE \"\${BIN_DIR}/aciso.cmd\"
            \"@echo off\\r\\n\\\"aciso\\\" %*\\r\\n\")
    ")
else()
    # On POSIX create symlinks for the artemis aliases.
    # aciso is its own binary so no symlink is needed.
    install(CODE "
        set(_destdir \"\$ENV{DESTDIR}\")
        set(_prefix  \"\${CMAKE_INSTALL_PREFIX}\")
        file(TO_CMAKE_PATH \"\${_destdir}\${_prefix}/bin\" BIN_DIR)
        cmake_path(NORMAL_PATH BIN_DIR OUTPUT_VARIABLE BIN_DIR)

        foreach(_alias atc atx arc)
            set(_link \"\${BIN_DIR}/\${_alias}\")
            if(EXISTS \"\${_link}\" OR IS_SYMLINK \"\${_link}\")
                file(REMOVE \"\${_link}\")
            endif()
            execute_process(
                COMMAND \"\${CMAKE_COMMAND}\" -E create_symlink artemis \"\${_alias}\"
                WORKING_DIRECTORY \"\${BIN_DIR}\"
                RESULT_VARIABLE _rc)
            if(NOT _rc EQUAL 0)
                message(WARNING \"aciso installer: failed to create symlink \${_alias}\")
            endif()
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
    "The package includes the 'artemis' compiler driver, the 'atc'/'atx'/'arc' aliases,\n"
    "and 'aciso', the Artemis package manager and build system.")
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
# Set ARTEMIS_HOME so aciso can locate the artemis compiler at runtime.
# $INSTDIR is the NSIS install root (e.g. C:\Program Files\Artemis);
# artemis.exe and aciso.exe both live in $INSTDIR\bin.
# SendMessage flushes the env change to running processes without a reboot.
set(CPACK_NSIS_EXTRA_INSTALL_COMMANDS
    "WriteRegStr HKLM \
'SYSTEM\\\\CurrentControlSet\\\\Control\\\\Session Manager\\\\Environment' \
'ARTEMIS_HOME' '$INSTDIR'\n\
SendMessage \${HWND_BROADCAST} \${WM_WININICHANGE} 0 'STR:Environment' /TIMEOUT=5000")

# Remove ARTEMIS_HOME from the registry when the user uninstalls.
set(CPACK_NSIS_EXTRA_UNINSTALL_COMMANDS
    "DeleteRegValue HKLM \
'SYSTEM\\\\CurrentControlSet\\\\Control\\\\Session Manager\\\\Environment' \
'ARTEMIS_HOME'\n\
SendMessage \${HWND_BROADCAST} \${WM_WININICHANGE} 0 'STR:Environment' /TIMEOUT=5000")

# ---- Linux: DEB + RPM ----
set(CPACK_DEBIAN_PACKAGE_MAINTAINER  "Artemis Project <noreply@artemis-lang.org>")
set(CPACK_DEBIAN_PACKAGE_SECTION     "devel")
set(CPACK_DEBIAN_PACKAGE_PRIORITY    "optional")
set(CPACK_DEBIAN_PACKAGE_DEPENDS     "libc6 (>= 2.17), libstdc++6 (>= 6), git")
set(CPACK_DEBIAN_PACKAGE_HOMEPAGE    "https://github.com/your-org/artemis")
# git is a runtime dep for 'aciso install' (uses git clone to fetch packages)
set(CPACK_RPM_PACKAGE_LICENSE        "MIT")
set(CPACK_RPM_PACKAGE_GROUP          "Development/Tools")
set(CPACK_RPM_PACKAGE_REQUIRES       "glibc >= 2.17, libstdc++ >= 6, git")
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
